unit fafafa.core.sync.mutex.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.mutex.base;

type
  // 前向声明
  TMutex = class;

  // RAII 互斥锁守护实现
  TMutexGuard = class(TInterfacedObject, IMutexGuard)
  private
    FMutex: TMutex;
    FLocked: Boolean;
  public
    constructor Create(AMutex: TMutex; ATryLock: Boolean = False);
    destructor Destroy; override;
    function IsLocked: Boolean;
  end;

  // 标准可重入互斥锁实现（使用 PTHREAD_MUTEX_RECURSIVE）
  TMutex = class(TInterfacedObject, IMutex)
  private
    FMutex: pthread_mutex_t;
    FLastError: TWaitError;
    FOwnerThreadId: TThreadID;
  public
    constructor Create;
    destructor Destroy; override;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    // ISynchronizable
    function GetLastError: TWaitError;
    // IMutex
    function GetHandle: Pointer;
    function GetHoldCount: Integer;
    function IsHeldByCurrentThread: Boolean;
    // RAII 支持
    function Lock: IMutexGuard;
    function TryLock: IMutexGuard;
  end;

  // 非重入互斥锁实现（使用 PTHREAD_MUTEX_NORMAL）
  TNonReentrantMutex = class(TInterfacedObject, INonReentrantMutex)
  private
    FMutex: pthread_mutex_t;
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    // ISynchronizable
    function GetLastError: TWaitError;
    // INonReentrantMutex
    function GetHandle: Pointer;
  end;

implementation

{ TMutexGuard - RAII 互斥锁守护实现 }

constructor TMutexGuard.Create(AMutex: TMutex; ATryLock: Boolean);
begin
  inherited Create;
  FMutex := AMutex;
  FLocked := False;

  if ATryLock then
  begin
    FLocked := FMutex.TryAcquire;
  end
  else
  begin
    FMutex.Acquire;
    FLocked := True;
  end;
end;

destructor TMutexGuard.Destroy;
begin
  if FLocked then
    FMutex.Release;
  inherited Destroy;
end;

function TMutexGuard.IsLocked: Boolean;
begin
  Result := FLocked;
end;

{ TMutex }

constructor TMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;

  FLastError := weNone;
  // 初始化互斥锁属性
  if pthread_mutexattr_init(@Attr) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to initialize mutex attributes');
  end;

  // 设置为递归互斥锁（可重入）- 符合主流标准
  if pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_RECURSIVE) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    FLastError := weSystemError;
    raise ELockError.Create('Failed to set mutex type to recursive');
  end;

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, @Attr) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    FLastError := weSystemError;
    raise ELockError.Create('Failed to initialize mutex');
  end;

  pthread_mutexattr_destroy(@Attr);
  FOwnerThreadId := 0; // 初始无持有者
end;

destructor TMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TMutex.Acquire;
begin
  // 使用递归互斥锁，支持同一线程多次获取
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to acquire mutex');
  end
  else
  begin
    FLastError := weNone;
  end;
end;

procedure TMutex.Release;
begin
  // 使用递归互斥锁，自动处理重入计数
  if pthread_mutex_unlock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to release mutex');
  end
  else
  begin
    FLastError := weNone;
  end;
end;

function TMutex.TryAcquire: Boolean;
begin
  // 使用递归互斥锁，支持同一线程多次获取
  Result := pthread_mutex_trylock(@FMutex) = 0;

  if Result then
    FLastError := weNone
  else
    FLastError := weTimeout; // TryAcquire 失败通常是因为锁被占用
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var startTick: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);
  startTick := GetTickCount64;
  while GetTickCount64 - startTick < ATimeoutMs do
  begin
    if TryAcquire then Exit(True);
    Sleep(1);
  end;
  Result := False;
end;

function TMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;



function TMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;

function TMutex.GetHoldCount: Integer;
begin
  // 注意：pthread 递归锁没有直接获取重入次数的API
  // 这里返回简化的实现：总是返回0
  // 在实际应用中，可能需要维护额外的状态信息
  Result := 0;
end;

function TMutex.IsHeldByCurrentThread: Boolean;
begin
  // 注意：pthread 递归锁没有直接检查持有者的API
  // 这里返回简化的实现：总是返回 False
  // 在实际应用中，可能需要维护额外的状态信息
  Result := False;
end;

function TMutex.Lock: IMutexGuard;
begin
  Result := TMutexGuard.Create(Self, False);
end;

function TMutex.TryLock: IMutexGuard;
begin
  Result := TMutexGuard.Create(Self, True);
  if not TMutexGuard(Result).IsLocked then
    Result := nil; // 获取锁失败，返回 nil
end;

{ TNonReentrantMutex - 非重入互斥锁实现 }

constructor TNonReentrantMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;

  FLastError := weNone;
  if pthread_mutexattr_init(@Attr) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to initialize mutex attributes');
  end;

  // 设置为普通互斥锁（不可重入）
  if pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_NORMAL) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    FLastError := weSystemError;
    raise ELockError.Create('Failed to set mutex type to normal');
  end;

  if pthread_mutex_init(@FMutex, @Attr) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    FLastError := weSystemError;
    raise ELockError.Create('Failed to initialize mutex');
  end;

  pthread_mutexattr_destroy(@Attr);
end;

destructor TNonReentrantMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TNonReentrantMutex.Acquire;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to acquire non-reentrant mutex');
  end
  else
  begin
    FLastError := weNone;
  end;
end;

procedure TNonReentrantMutex.Release;
begin
  if pthread_mutex_unlock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to release non-reentrant mutex');
  end
  else
  begin
    FLastError := weNone;
  end;
end;

function TNonReentrantMutex.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FMutex) = 0;

  if Result then
    FLastError := weNone
  else
    FLastError := weTimeout;
end;

function TNonReentrantMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var startTick: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);
  startTick := GetTickCount64;
  while GetTickCount64 - startTick < ATimeoutMs do
  begin
    if TryAcquire then Exit(True);
    Sleep(1);
  end;
  Result := False;
end;

function TNonReentrantMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNonReentrantMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;

end.
