unit optimized_atomic_test;

{**
 * 优化版本的原子操作实现
 *
 * @desc 基于性能分析结果的优化版本，减少不必要的内存屏障开销
 * @author fafafa.core team
 * @version 1.0.0
 * @since 2025-08-31
 *}

{$mode objfpc}{$H+}

interface

type
  memory_order = (
    memory_order_relaxed,
    memory_order_consume,
    memory_order_acquire,
    memory_order_release,
    memory_order_acq_rel,
    memory_order_seq_cst
  );

// 优化版本的原子操作 - 默认使用 relaxed 内存序
function optimized_atomic_load(var obj: Int32; order: memory_order = memory_order_relaxed): Int32; inline;
procedure optimized_atomic_store(var obj: Int32; desired: Int32; order: memory_order = memory_order_relaxed); inline;
function optimized_atomic_exchange(var obj: Int32; desired: Int32; order: memory_order = memory_order_relaxed): Int32; inline;
function optimized_atomic_fetch_add(var obj: Int32; arg: Int32; order: memory_order = memory_order_relaxed): Int32; inline;

// 快速版本 - 直接使用 RTL，无内存屏障
function fast_atomic_load(var obj: Int32): Int32; inline;
procedure fast_atomic_store(var obj: Int32; desired: Int32); inline;
function fast_atomic_exchange(var obj: Int32; desired: Int32): Int32; inline;
function fast_atomic_fetch_add(var obj: Int32; arg: Int32): Int32; inline;

// 智能版本 - 根据操作类型选择合适的内存序
function smart_atomic_load(var obj: Int32): Int32; inline;
procedure smart_atomic_store(var obj: Int32; desired: Int32); inline;
function smart_atomic_exchange(var obj: Int32; desired: Int32): Int32; inline;
function smart_atomic_fetch_add(var obj: Int32; arg: Int32): Int32; inline;

implementation

// 轻量级内存屏障实现
procedure lightweight_acquire_fence; inline;
begin
  // 在 x86/x64 上，大多数操作已经有 acquire 语义，只需编译器屏障
  {$IFDEF CPUX86_64}
  asm
    // 编译器屏障，防止指令重排
  end;
  {$ELSE}
  ReadBarrier;
  {$ENDIF}
end;

procedure lightweight_release_fence; inline;
begin
  // 在 x86/x64 上，大多数操作已经有 release 语义，只需编译器屏障
  {$IFDEF CPUX86_64}
  asm
    // 编译器屏障，防止指令重排
  end;
  {$ELSE}
  WriteBarrier;
  {$ENDIF}
end;

procedure lightweight_seq_cst_fence; inline;
begin
  {$IFDEF CPUX86_64}
  asm
    mfence;
  end;
  {$ELSE}
  ReadBarrier;
  WriteBarrier;
  {$ENDIF}
end;

// === 优化版本实现 ===

function optimized_atomic_load(var obj: Int32; order: memory_order): Int32;
begin
  case order of
    memory_order_relaxed:
      Result := obj; // 直接读取，无屏障
    memory_order_acquire:
      begin
        Result := obj;
        lightweight_acquire_fence;
      end;
    memory_order_seq_cst:
      begin
        Result := obj;
        lightweight_seq_cst_fence;
      end;
    else
      Result := obj; // 其他情况默认 relaxed
  end;
end;

procedure optimized_atomic_store(var obj: Int32; desired: Int32; order: memory_order);
begin
  case order of
    memory_order_relaxed:
      obj := desired; // 直接写入，无屏障
    memory_order_release:
      begin
        lightweight_release_fence;
        obj := desired;
      end;
    memory_order_seq_cst:
      begin
        lightweight_release_fence;
        obj := desired;
        lightweight_seq_cst_fence;
      end;
    else
      obj := desired; // 其他情况默认 relaxed
  end;
end;

function optimized_atomic_exchange(var obj: Int32; desired: Int32; order: memory_order): Int32;
begin
  Result := InterlockedExchange(obj, desired);
  case order of
    memory_order_acquire,
    memory_order_acq_rel:
      lightweight_acquire_fence;
    memory_order_seq_cst:
      lightweight_seq_cst_fence;
    // relaxed 和其他情况不需要额外屏障
  end;
end;

function optimized_atomic_fetch_add(var obj: Int32; arg: Int32; order: memory_order): Int32;
begin
  Result := InterlockedExchangeAdd(obj, arg);
  case order of
    memory_order_acquire,
    memory_order_acq_rel:
      lightweight_acquire_fence;
    memory_order_seq_cst:
      lightweight_seq_cst_fence;
    // relaxed 和其他情况不需要额外屏障
  end;
end;

// === 快速版本实现（无内存屏障）===

function fast_atomic_load(var obj: Int32): Int32;
begin
  Result := obj; // 在 x86/x64 上，32位读取是原子的
end;

procedure fast_atomic_store(var obj: Int32; desired: Int32);
begin
  obj := desired; // 在 x86/x64 上，32位写入是原子的
end;

function fast_atomic_exchange(var obj: Int32; desired: Int32): Int32;
begin
  Result := InterlockedExchange(obj, desired);
end;

function fast_atomic_fetch_add(var obj: Int32; arg: Int32): Int32;
begin
  Result := InterlockedExchangeAdd(obj, arg);
end;

// === 智能版本实现（根据操作选择合适的内存序）===

function smart_atomic_load(var obj: Int32): Int32;
begin
  // Load 操作通常只需要 acquire 语义
  Result := obj;
  lightweight_acquire_fence;
end;

procedure smart_atomic_store(var obj: Int32; desired: Int32);
begin
  // Store 操作通常只需要 release 语义
  lightweight_release_fence;
  obj := desired;
end;

function smart_atomic_exchange(var obj: Int32; desired: Int32): Int32;
begin
  // Exchange 操作通常需要 acq_rel 语义
  Result := InterlockedExchange(obj, desired);
  lightweight_acquire_fence;
end;

function smart_atomic_fetch_add(var obj: Int32; arg: Int32): Int32;
begin
  // FetchAdd 操作通常需要 acq_rel 语义
  Result := InterlockedExchangeAdd(obj, arg);
  lightweight_acquire_fence;
end;

end.
