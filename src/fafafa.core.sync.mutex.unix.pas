unit fafafa.core.sync.mutex.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.mutex.base;

{$IFDEF LINUX}
const
  SYS_futex = 202;  // Linux x86_64 futex 系统调用号

function fpSyscall(sysnr: clong; arg1, arg2, arg3, arg4, arg5, arg6: clong): clong; cdecl; external name 'syscall';
function fpgettid: pid_t; cdecl; external name 'gettid';
{$ENDIF}

type

  { 传统互斥锁实现 - 使用 pthread（兼容所有 Unix 系统）}
  TMutex = class(TTryLock, IMutex)
  private
    FMutex: pthread_mutex_t;
    FOwnerThreadId: TThreadID;
    FIsLocked: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    // ITryLock 继承的方法
    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;

    // IMutex 特有方法
    function GetHandle: Pointer;
  end;

{$IFDEF FAFAFA_CORE_USE_FUTEX}

const
  // futex 操作类型（Linux/FreeBSD）
  FUTEX_WAIT = 0;
  FUTEX_WAKE = 1;
  FUTEX_PRIVATE_FLAG = 128;
  FUTEX_WAIT_PRIVATE = FUTEX_WAIT or FUTEX_PRIVATE_FLAG;
  FUTEX_WAKE_PRIVATE = FUTEX_WAKE or FUTEX_PRIVATE_FLAG;

  // futex 状态值
  FUTEX_UNLOCKED = 0;                    // 未锁定
  FUTEX_LOCKED = 1;                      // 已锁定，无等待者
  FUTEX_LOCKED_WITH_WAITERS = 2;         // 已锁定，有等待者

type

  { 现代互斥锁实现 - 使用 futex（Linux/FreeBSD）}
  TFutexMutex = class(TTryLock, IMutex)
  private
    FFutex: LongInt;
    FOwnerTid: pid_t;

    // futex 系统调用封装
    function FutexWait(ExpectedValue: LongInt; TimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function FutexWake(NumWaiters: LongInt = 1): Boolean;
    function GetCurrentTid: pid_t; inline;
    function SpinTryAcquire(MaxSpins: Integer = 1000): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    // ITryLock 继承的方法
    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;

    // IMutex 特有方法
    function GetHandle: Pointer;
  end;
{$ENDIF}

function MakeMutex: IMutex; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function MakeMutex: IMutex;
begin
  {$IFDEF FAFAFA_CORE_USE_FUTEX}
  Result := TFutexMutex.Create;
  {$ELSE}
  Result := TMutex.Create;
  {$ENDIF}
end;

{ TMutex - 传统 pthread 实现 }

constructor TMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;
  FOwnerThreadId := 0;
  FIsLocked := False;

  // 初始化互斥锁属性
  if pthread_mutexattr_init(@Attr) <> 0 then
    raise ELockError.Create('Failed to initialize mutex attributes');

  try
    // 设置为标准互斥锁（不可重入）
    if pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_NORMAL) <> 0 then
      raise ELockError.Create('Failed to set mutex type to normal');

    // 初始化互斥锁
    if pthread_mutex_init(@FMutex, @Attr) <> 0 then
      raise ELockError.Create('Failed to initialize mutex');
  finally
    pthread_mutexattr_destroy(@Attr);
  end;
end;

destructor TMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TMutex.Acquire;
var
  CurrentThreadId: TThreadID;
begin
  CurrentThreadId := GetCurrentThreadId;

  // 使用 pthread_mutex + 重入检查
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to acquire mutex');

  try
    if FIsLocked and (FOwnerThreadId = CurrentThreadId) then
    begin
      // 检测到重入，需要先释放锁再抛异常
      pthread_mutex_unlock(@FMutex);
      raise ELockError.Create('Non-reentrant mutex: reentrancy detected');
    end;
    FOwnerThreadId := CurrentThreadId;
    FIsLocked := True;
  except
    pthread_mutex_unlock(@FMutex);
    raise;
  end;
end;

procedure TMutex.Release;
begin
  // 检查所有权（不需要额外锁保护，因为锁已经被当前线程持有）
  if not FIsLocked or (FOwnerThreadId <> GetCurrentThreadId) then
    raise ELockError.Create('Mutex not owned by current thread');

  FOwnerThreadId := 0;
  FIsLocked := False;

  // 直接释放锁
  if pthread_mutex_unlock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to release mutex');
end;

function TMutex.TryAcquire: Boolean;
var
  CurrentThreadId: TThreadID;
begin
  CurrentThreadId := GetCurrentThreadId;

  // 使用 pthread_mutex_trylock + 重入检查
  if pthread_mutex_trylock(@FMutex) = 0 then
  begin
    try
      if FIsLocked and (FOwnerThreadId = CurrentThreadId) then
      begin
        // 检测到重入
        pthread_mutex_unlock(@FMutex);
        Result := False;
      end
      else
      begin
        FOwnerThreadId := CurrentThreadId;
        FIsLocked := True;
        Result := True;
      end;
    except
      pthread_mutex_unlock(@FMutex);
      Result := False;
    end;
  end
  else
  begin
    Result := False;
  end;
end;

function TMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;

{$IFDEF FAFAFA_CORE_USE_FUTEX}
{ TFutexMutex - 现代 futex 实现 }

constructor TFutexMutex.Create;
begin
  inherited Create;
  FFutex := FUTEX_UNLOCKED;
  FOwnerTid := 0;
end;

destructor TFutexMutex.Destroy;
begin
  // futex 无需显式销毁
  inherited Destroy;
end;

{ TFutexMutex 的辅助方法 }

function TFutexMutex.GetCurrentTid: pid_t;
begin
  {$IFDEF LINUX}
  Result := fpgettid;
  {$ELSE}
  Result := GetThreadID;
  {$ENDIF}
end;

function TFutexMutex.FutexWait(ExpectedValue: LongInt; TimeoutMs: Cardinal): Boolean;
var
  TimeSpec: TTimeSpec;
  TimeSpecPtr: PTimeSpec;
  Res: cint;
begin
  {$IFDEF LINUX}
  if TimeoutMs = High(Cardinal) then
    TimeSpecPtr := nil
  else
  begin
    TimeSpec.tv_sec := TimeoutMs div 1000;
    TimeSpec.tv_nsec := (TimeoutMs mod 1000) * 1000000;
    TimeSpecPtr := @TimeSpec;
  end;

  // 调用 futex 系统调用
  Res := fpSyscall(SYS_futex,
    clong(PtrUInt(@FFutex)),    // futex 地址
    FUTEX_WAIT_PRIVATE,         // 操作类型（私有，性能更好）
    ExpectedValue,              // 期望值
    clong(PtrUInt(TimeSpecPtr)), // 超时
    0, 0);

  Result := (Res = 0) or (fpgeterrno = ESysEINTR);  // 成功或被信号中断
  {$ELSE}
  // 非 Linux 系统的回退实现
  Sleep(1);
  Result := True;
  {$ENDIF}
end;

function TFutexMutex.FutexWake(NumWaiters: LongInt): Boolean;
var
  Res: cint;
begin
  {$IFDEF LINUX}
  Res := fpSyscall(SYS_futex,
    clong(PtrUInt(@FFutex)),    // futex 地址
    FUTEX_WAKE_PRIVATE,         // 操作类型（私有，性能更好）
    NumWaiters,                 // 唤醒数量
    0, 0, 0);

  Result := Res >= 0;
  {$ELSE}
  // 非 Linux 系统的回退实现
  Result := True;
  {$ENDIF}
end;

function TFutexMutex.SpinTryAcquire(MaxSpins: Integer): Boolean;
var
  SpinCount: Integer;
  CurrentTid: pid_t;
begin
  CurrentTid := GetCurrentTid;

  for SpinCount := 1 to MaxSpins do
  begin
    // 尝试原子获取锁
    if InterlockedCompareExchange(FFutex, FUTEX_LOCKED, FUTEX_UNLOCKED) = FUTEX_UNLOCKED then
    begin
      FOwnerTid := CurrentTid;
      Exit(True);
    end;

    // CPU 暂停指令，减少功耗和总线竞争
    asm
      pause;
    end;
  end;

  Result := False;
end;

procedure TFutexMutex.Acquire;
var
  CurrentTid: pid_t;
  OldValue: LongInt;
begin
  CurrentTid := GetCurrentTid;

  // 快速路径：尝试直接获取未锁定的锁
  if InterlockedCompareExchange(FFutex, FUTEX_LOCKED, FUTEX_UNLOCKED) = FUTEX_UNLOCKED then
  begin
    FOwnerTid := CurrentTid;
    Exit;
  end;

  // 检查重入（在快速路径失败后检查，避免竞态条件）
  if FOwnerTid = CurrentTid then
    raise ELockError.Create('Non-reentrant mutex: reentrancy detected');

  // 慢速路径：自旋 + futex 等待
  if SpinTryAcquire then
    Exit;

  // 设置等待者标志并进入 futex 等待
  repeat
    OldValue := InterlockedExchange(FFutex, FUTEX_LOCKED_WITH_WAITERS);
    if OldValue = FUTEX_UNLOCKED then
    begin
      FOwnerTid := CurrentTid;
      Exit;
    end;

    // 等待 futex 唤醒
    FutexWait(FUTEX_LOCKED_WITH_WAITERS);
  until False;
end;

procedure TFutexMutex.Release;
var
  CurrentTid: pid_t;
  OldValue: LongInt;
begin
  CurrentTid := GetCurrentTid;

  // 检查所有权
  if FOwnerTid <> CurrentTid then
    raise ELockError.Create('Mutex not owned by current thread');

  FOwnerTid := 0;

  // 原子释放锁
  OldValue := InterlockedExchange(FFutex, FUTEX_UNLOCKED);

  // 如果有等待者，唤醒一个
  if OldValue = FUTEX_LOCKED_WITH_WAITERS then
    FutexWake(1);
end;

function TFutexMutex.TryAcquire: Boolean;
var
  CurrentTid: pid_t;
begin
  CurrentTid := GetCurrentTid;

  // 尝试原子获取锁
  if InterlockedCompareExchange(FFutex, FUTEX_LOCKED, FUTEX_UNLOCKED) = FUTEX_UNLOCKED then
  begin
    FOwnerTid := CurrentTid;
    Result := True;
  end
  else
  begin
    // 检查重入（在获取失败后检查，避免竞态条件）
    if FOwnerTid = CurrentTid then
      Result := False  // 重入检测，返回失败
    else
      Result := False; // 锁被其他线程持有
  end;
end;

function TFutexMutex.GetHandle: Pointer;
begin
  Result := @FFutex;
end;

{$ENDIF}

end.
