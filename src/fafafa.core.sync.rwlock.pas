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
function CreateRWLock: IRWLock;

implementation

function CreateRWLock: IRWLock;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.rwlock.unix.TRWLock.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.rwlock.windows.TRWLock.Create;
  {$ENDIF}
end;

end.
