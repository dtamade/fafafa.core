unit fafafa.core.sync.rwlock;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.rwlock.base
  {$IFDEF WINDOWS}, fafafa.core.sync.rwlock.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.rwlock.unix{$ENDIF};

type
  // 重新导出类型，统一命名�?RWLock
  TLockResult = fafafa.core.sync.rwlock.base.TLockResult;
  IRWLockReadGuard = fafafa.core.sync.rwlock.base.IRWLockReadGuard;
  IRWLockWriteGuard = fafafa.core.sync.rwlock.base.IRWLockWriteGuard;
  IRWLock = fafafa.core.sync.rwlock.base.IRWLock;

  {$IFDEF WINDOWS}
  TRWLock = fafafa.core.sync.rwlock.windows.TRWLock;
  {$ENDIF}

  {$IFDEF UNIX}
  TRWLock = fafafa.core.sync.rwlock.unix.TRWLock;
  {$ENDIF}

// 创建平台特定的 RWLock 实例
function MakeRWLock: IRWLock;
function MakeRWLock(const Options: TRWLockOptions): IRWLock; overload;

// 配置选项工厂函数
function DefaultRWLockOptions: TRWLockOptions;
function FairRWLockOptions: TRWLockOptions;
function WriterPriorityRWLockOptions: TRWLockOptions;

{**
 * FastRWLockOptions - 高性能 RWLock 选项
 *
 * @description
 *   关闭重入支持、毒化检测等高级特性，获得最佳性能。
 *   适用于简单场景，性能可提升 30-50%。
 *
 * @trade_offs
 *   - 不支持同一线程重复获取锁（会死锁）
 *   - 不检测锁毒化状态
 *   - 适合性能优先的简单场景
 *
 * @usage
 *   var RWLock := MakeRWLock(FastRWLockOptions);
 *}
function FastRWLockOptions: TRWLockOptions;

implementation

function MakeRWLock: IRWLock;
begin
  Result := MakeRWLock(DefaultRWLockOptions);
end;

function MakeRWLock(const Options: TRWLockOptions): IRWLock;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.rwlock.unix.TRWLock.Create(Options);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.rwlock.windows.TRWLock.Create(Options);
  {$ENDIF}
end;

function DefaultRWLockOptions: TRWLockOptions;
begin
  Result.AllowReentrancy := True;
  Result.FairMode := False;
  Result.WriterPriority := False;
  Result.MaxReaders := 1024;
  Result.SpinCount := 4000;
  Result.EnablePoisoning := True;    // ✅ 默认启用毒化检测（Rust-style Poisoning）
  Result.ReaderBiasEnabled := True;  // ✅ 默认启用读偏向优化
end;

function FairRWLockOptions: TRWLockOptions;
begin
  Result := DefaultRWLockOptions;
  Result.FairMode := True;
end;

function WriterPriorityRWLockOptions: TRWLockOptions;
begin
  Result := DefaultRWLockOptions;
  Result.WriterPriority := True;
end;

function FastRWLockOptions: TRWLockOptions;
begin
  // 高性能配置：关闭所有高级特性
  Result.Fairness := WriterPreferred;
  Result.AllowReentrancy := False;    // ✅ 关闭重入支持（避免管理器锁开销）
  Result.FairMode := False;
  Result.WriterPriority := False;
  Result.MaxReaders := MaxInt;        // ✅ 无限制（避免 MaxReaders 检查）
  Result.SpinCount := 100;            // ✅ 较少自旋（快速进入阻塞）
  Result.EnablePoisoning := False;    // ✅ 关闭毒化检测
  Result.ReaderBiasEnabled := True;   // 保持读偏向优化
end;

end.
