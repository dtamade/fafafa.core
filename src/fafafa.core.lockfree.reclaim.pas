unit fafafa.core.lockfree.reclaim;

{**
 * fafafa.core.lockfree.reclaim - 可插拔的无锁内存回收骨架
 *
 * 说明：
 *   - 默认实现为“立即回收（Immediate Reclaim）”，保持与现有代码行为一致。
 *   - 通过宏 FAFAFA_LOCKFREE_EPOCH 启用 Epoch 模式（占位，后续完善）。
 *   - 暴露统一的 Guard/Retire/Drain 接口，便于在各结构中打钩。
 *
 * 对标：
 *   - Rust crossbeam-epoch（Guard + retire）
 *   - Java/Go 由 GC 负责，但我们提供显式的 retire 钩子，便于未来扩展到 Hazard/Epoch。
 *}

{$I fafafa.core.settings.inc}

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.atomic;

type
  TLFDisposer = procedure(p: Pointer);

// 进入/退出无锁临界区（Epoch 模式使用；Immediate 模式为 no-op）
function lf_enter: Pointer; inline;
procedure lf_exit(guard: Pointer); inline;

// 延迟回收：在安全时机调用 disposer(p)
procedure lf_retire(p: Pointer; disposer: TLFDisposer); inline;

// 可选：线程注销（Epoch 模式下标记为非活跃）。Immediate 模式为 no-op
procedure lf_unregister(guard: Pointer); inline;

// 可选：提示一个静默点，帮助推进全局 epoch（实现可选择忽略）
procedure lf_quiescent; inline;

// 主动清理：用于析构/测试时确保已退休对象被释放
procedure lf_drain; inline;

implementation

{$IFDEF FAFAFA_LOCKFREE_EPOCH}
// 最小可用 Epoch 回收实现（无注销，线程首次调用自动注册）
// 说明：
// - 每线程在 lf_enter/lf_exit 标记活跃并记录其可见的全局 epoch
// - retire 将节点挂入该线程的退休链表（携带 epoch 戳）
// - 回收条件：所有活跃线程的 epoch > node.epoch（跨过一个静默期），方可释放

type
  PRetired = ^TRetired;
  TRetired = record
    ptr: Pointer;
    disposer: TLFDisposer;
    epoch: Int64;
    next: PRetired;
  end;

  PParticipant = ^TParticipant;
  TParticipant = record
    next: PParticipant;
    active: Int32;     // 0/1
    epoch: Int64;      // 进入时捕获的全局 epoch
    retired: PRetired; // 单链表
    retiredCount: Integer;
  end;

var
  gParticipantsHead: Pointer; // PParticipant（无锁栈头）
  gEpoch: Int64 = 0;

threadvar
  TLSParticipant: PParticipant;

function AtomicPushParticipant(node: PParticipant): Boolean; inline;
var
  oldHead: Pointer;
begin
  repeat
    oldHead := atomic_load(gParticipantsHead, mo_relaxed);
    node^.next := PParticipant(oldHead);
  until atomic_compare_exchange_strong(gParticipantsHead, oldHead, node);
  Result := True;
end;

function RegisterParticipant: PParticipant; inline;
begin
  if TLSParticipant <> nil then Exit(TLSParticipant);
  GetMem(Result, SizeOf(TParticipant));
  FillChar(Result^, SizeOf(TParticipant), 0);
  AtomicPushParticipant(Result);
  TLSParticipant := Result;
end;

function lf_enter: Pointer; inline;
var
  p: PParticipant;
begin
  p := RegisterParticipant;
  p^.active := 1;
  p^.epoch := atomic_load_64(gEpoch, mo_acquire);
  Result := p;
end;

procedure lf_exit(guard: Pointer); inline;
begin
  if guard <> nil then
    PParticipant(guard)^.active := 0;
end;

procedure lf_unregister(guard: Pointer); inline;
var
  p, cur, prev: PParticipant;
begin
  p := PParticipant(guard);
  if p = nil then Exit;
  // 标记非活跃
  p^.active := 0;
  // 从全局单链表移除（无锁近似：如果失败则保留，后续扫描忽略 active=0 即可）
  prev := nil;
  cur := PParticipant(atomic_load(gParticipantsHead, mo_acquire));
  while cur <> nil do
  begin
    if cur = p then
    begin
      if prev = nil then
        atomic_compare_exchange_strong(gParticipantsHead, Pointer(cur), Pointer(cur^.next))
      else
        prev^.next := cur^.next;
      Break;
    end;
    prev := cur; cur := cur^.next;
  end;
end;

procedure lf_quiescent; inline;
begin
  // 简单地推进全局 epoch；实际实现可按采样/阈值控制
  atomic_fetch_add_64(gEpoch, 1);
end;

procedure PushRetired(pp: PParticipant; p: Pointer; disposer: TLFDisposer; e: Int64); inline;
var
  r: PRetired;
begin
  if (p = nil) or not Assigned(disposer) then Exit;
  GetMem(r, SizeOf(TRetired));
  r^.ptr := p; r^.disposer := disposer; r^.epoch := e;
  r^.next := pp^.retired;
  pp^.retired := r;
  Inc(pp^.retiredCount);
end;

function MinActiveEpoch: Int64;
var
  cur: PParticipant;
  minE: Int64;
begin
  minE := atomic_load_64(gEpoch, mo_relaxed);
  cur := PParticipant(atomic_load(gParticipantsHead, mo_acquire));
  while cur <> nil do
  begin
    if cur^.active <> 0 then
      if cur^.epoch < minE then minE := cur^.epoch;
    cur := cur^.next;
  end;
  Result := minE;
end;

procedure CollectFor(pp: PParticipant);
var
  cur, prev, keepHead: PRetired;
  safeEpoch: Int64;
begin
  safeEpoch := MinActiveEpoch - 1;
  prev := nil; cur := pp^.retired; keepHead := cur;
  while cur <> nil do
  begin
    if cur^.epoch <= safeEpoch then
    begin
      // remove and free
      if prev = nil then pp^.retired := cur^.next else prev^.next := cur^.next;
      keepHead := pp^.retired;
      cur^.disposer(cur^.ptr);
      FreeMem(cur);
      Dec(pp^.retiredCount);
      if prev = nil then cur := pp^.retired else cur := prev^.next;
      Continue;
    end;
    prev := cur; cur := cur^.next;
  end;
end;

procedure MaybeAdvanceAndCollect(pp: PParticipant); inline;
begin
  if pp^.retiredCount >= 64 then
  begin
    atomic_fetch_add_64(gEpoch, 1);
    CollectFor(pp);
  end;
end;

procedure lf_retire(p: Pointer; disposer: TLFDisposer); inline;
var
  pp: PParticipant;
  e: Int64;
begin
  pp := RegisterParticipant;
  e := atomic_load_64(gEpoch, mo_relaxed);
  PushRetired(pp, p, disposer, e);
  MaybeAdvanceAndCollect(pp);
end;

procedure lf_drain; inline;
var
  cur: PParticipant;
begin
  cur := PParticipant(atomic_load(gParticipantsHead, mo_acquire));
  while cur <> nil do
  begin
    CollectFor(cur);
    cur := cur^.next;
  end;
end;

{$ELSE}
// Immediate 模式：保持原有语义（立即释放）

function lf_enter: Pointer; inline;
begin
  Result := nil;
end;

procedure lf_exit(guard: Pointer); inline;
begin
end;

procedure lf_unregister(guard: Pointer); inline;
begin
  // Immediate: nothing
end;

procedure lf_quiescent; inline;
begin
  // Immediate: nothing
end;

procedure lf_retire(p: Pointer; disposer: TLFDisposer); inline;
begin
  if Assigned(disposer) and (p <> nil) then
    disposer(p);
end;

procedure lf_drain; inline;
begin
end;

{$ENDIF}

end.

