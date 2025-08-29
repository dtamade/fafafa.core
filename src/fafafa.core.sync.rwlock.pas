unit fafafa.core.sync.rwlock;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.rwlock.base
  {$IFDEF WINDOWS}, fafafa.core.sync.rwlock.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.rwlock.unix{$ENDIF};

type
  // 重新导出类型，统一命名为 RWLock
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

end.
