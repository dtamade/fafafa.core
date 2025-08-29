unit fafafa.core.sync.mutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.mutex.base
  {$IFDEF WINDOWS}, fafafa.core.sync.mutex.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.mutex.unix{$ENDIF};

type
  // 标准互斥锁接口（不可重入）
  IMutex = fafafa.core.sync.mutex.base.IMutex;

  // 平台特定实现
  {$IFDEF WINDOWS}
  TMutex = fafafa.core.sync.mutex.windows.TMutex;  // Windows SRWLOCK 实现
  {$ENDIF}
  {$IFDEF UNIX}
  TMutex = fafafa.core.sync.mutex.unix.TMutex;     // Unix 统一实现（futex/pthread）
  {$ENDIF}

function MakeMutex: IMutex;
function MutexGuard: ILockGuard;

implementation

function MakeMutex: IMutex;
begin
  {$IFDEF MSWINDOWS}
    Result := fafafa.core.sync.mutex.windows.MakeMutex();
  {$ELSE}
    Result := fafafa.core.sync.mutex.unix.MakeMutex();
  {$ENDIF}
end;

function MutexGuard: ILockGuard;
begin
  Result := MakeLockGuard(MakeMutex);
end;

end.
