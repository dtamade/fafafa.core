unit fafafa.core.sync.mutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.mutex.base
  {$IFDEF WINDOWS}, fafafa.core.sync.mutex.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.mutex.unix{$ENDIF};

type
  // 标准可重入互斥锁接口（主流标准）
  IMutex = fafafa.core.sync.mutex.base.IMutex;

  // 非重入互斥锁接口（特殊用途）
  INonReentrantMutex = fafafa.core.sync.mutex.base.INonReentrantMutex;

  // RAII 互斥锁守护接口
  IMutexGuard = fafafa.core.sync.mutex.base.IMutexGuard;

  {$IFDEF WINDOWS}
  TMutex = fafafa.core.sync.mutex.windows.TMutex;
  TNonReentrantMutex = fafafa.core.sync.mutex.windows.TNonReentrantMutex;
  {$ENDIF}

  {$IFDEF UNIX}
  TMutex = fafafa.core.sync.mutex.unix.TMutex;
  TNonReentrantMutex = fafafa.core.sync.mutex.unix.TNonReentrantMutex;
  {$ENDIF}

// 工厂函数
function MakeMutex: IMutex; overload;  // 标准可重入互斥锁
function MakeNonReentrantMutex: INonReentrantMutex; overload;  // 非重入互斥锁

implementation

function MakeMutex: IMutex;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.mutex.unix.TMutex.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.mutex.windows.TMutex.Create;
  {$ENDIF}
end;

function MakeNonReentrantMutex: INonReentrantMutex;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.mutex.unix.TNonReentrantMutex.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.mutex.windows.TNonReentrantMutex.Create;
  {$ENDIF}
end;

{$IFDEF WINDOWS}
function MakeMutex(ASpinCount: DWORD): IMutex;
begin
  // 注意：新的 TMutex 使用 CRITICAL_SECTION，不再支持 SpinCount 参数
  // 这里忽略 ASpinCount 参数，使用默认构造函数
  Result := fafafa.core.sync.mutex.windows.TMutex.Create;
end;
{$ENDIF}

end.

