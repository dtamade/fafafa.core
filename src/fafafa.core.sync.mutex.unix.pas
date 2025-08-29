unit fafafa.core.sync.mutex.unix;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.atomic,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.time.cpu;

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
    FOwnerThreadId: LongInt; // 原子变量：0=未锁定，非0=持有锁的线程ID
  public
    constructor Create;
    destructor Destroy; override;

    // ITryLock 继承的方法
    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;  // 重写超时版本

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
    FFutex: Int32;  // 使用 Int32 以配合 fafafa.core.atomic
    FOwnerTid: Int32;  // 使用 Int32 以配合 fafafa.core.atomic

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
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;  // 重写超时版本

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
  atomic_store(FOwnerThreadId, 0); // 0 表示未锁定

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
  CurrentThreadId: LongInt;
begin
  CurrentThreadId := LongInt(GetCurrentThreadId);

  // 先检查重入（原子读取）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
    raise ELockError.Create('Non-reentrant mutex: reentrancy detected');

  // 使用 pthread_mutex 获取锁
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to acquire mutex');

  try
    // 再次检查重入（防止竞态条件）
    if atomic_load(FOwnerThreadId) = CurrentThreadId then
    begin
      pthread_mutex_unlock(@FMutex);
      raise ELockError.Create('Non-reentrant mutex: reentrancy detected');
    end;
    // 原子设置所有权
    atomic_store(FOwnerThreadId, CurrentThreadId);
  except
    pthread_mutex_unlock(@FMutex);
    raise;
  end;
end;

procedure TMutex.Release;
var
  CurrentThreadId: LongInt;
begin
  CurrentThreadId := LongInt(GetCurrentThreadId);

  // 检查所有权（原子读取）
  if atomic_load(FOwnerThreadId) <> CurrentThreadId then
    raise ELockError.Create('Mutex not owned by current thread');

  // 原子清除所有权信息
  atomic_store(FOwnerThreadId, 0);

  // 释放 pthread_mutex
  if pthread_mutex_unlock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to release mutex');
end;

function TMutex.TryAcquire: Boolean;
var
  CurrentThreadId: LongInt;
begin
  CurrentThreadId := LongInt(GetCurrentThreadId);

  // 先检查重入（原子读取）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
    Exit(False);

  // 使用 pthread_mutex_trylock
  if pthread_mutex_trylock(@FMutex) = 0 then
  begin
    try
      // 再次检查重入（防止竞态条件）
      if atomic_load(FOwnerThreadId) = CurrentThreadId then
      begin
        // 检测到重入，释放刚获取的锁并返回失败
        pthread_mutex_unlock(@FMutex);
        Result := False;
      end
      else
      begin
        // 原子设置所有权
        atomic_store(FOwnerThreadId, CurrentThreadId);
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

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  CurrentThreadId: LongInt;
begin
  CurrentThreadId := LongInt(GetCurrentThreadId);

  // 对于不可重入锁，检查重入（原子读取）
  // 如果是重入，直接返回失败，不进行等待（因为同一线程永远不会释放自己持有的锁）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
    Exit(False);

  // 调用基类的优化超时实现
  Result := inherited TryAcquire(ATimeoutMs);
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
  atomic_store(FFutex, FUTEX_UNLOCKED);
  atomic_store(FOwnerTid, 0);
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
  // 使用更兼容的方式获取线程ID
  // 在某些交叉编译环境中，fpgettid 可能不可用
  // 使用 GetCurrentThreadId 作为替代方案
  Result := pid_t(GetCurrentThreadId);
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
  CurrentTid: Int32;
  Expected: Int32;
begin
  CurrentTid := Int32(GetCurrentTid);

  for SpinCount := 1 to MaxSpins do
  begin
    // 尝试原子获取锁（使用框架的原子操作）
    Expected := FUTEX_UNLOCKED;
    if atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED) then
    begin
      atomic_store(FOwnerTid, CurrentTid);
      Exit(True);
    end;

    // 使用跨平台的 CPU 暂停指令
    CpuRelax;
  end;

  Result := False;
end;

procedure TFutexMutex.Acquire;
var
  CurrentTid: Int32;
  OldValue: Int32;
  Expected: Int32;
begin
  CurrentTid := Int32(GetCurrentTid);

  // 快速路径：尝试直接获取未锁定的锁（使用框架的原子操作）
  Expected := FUTEX_UNLOCKED;
  if atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED) then
  begin
    atomic_store(FOwnerTid, CurrentTid);
    Exit;
  end;

  // 慢速路径：自旋 + futex 等待
  if SpinTryAcquire then
    Exit;

  // 设置等待者标志并进入 futex 等待
  repeat
    // 在设置等待者标志前检查重入（使用原子读取）
    if atomic_load(FOwnerTid) = CurrentTid then
      raise ELockError.Create('Non-reentrant mutex: reentrancy detected');

    OldValue := atomic_exchange(FFutex, FUTEX_LOCKED_WITH_WAITERS);
    if OldValue = FUTEX_UNLOCKED then
    begin
      atomic_store(FOwnerTid, CurrentTid);
      Exit;
    end;

    // 等待 futex 唤醒
    FutexWait(FUTEX_LOCKED_WITH_WAITERS);
  until False;
end;

procedure TFutexMutex.Release;
var
  CurrentTid: Int32;
  OldValue: Int32;
begin
  CurrentTid := Int32(GetCurrentTid);

  // 检查所有权（使用原子读取）
  if atomic_load(FOwnerTid) <> CurrentTid then
    raise ELockError.Create('Mutex not owned by current thread');

  // 清除所有权（使用原子写入）
  atomic_store(FOwnerTid, 0);

  // 原子释放锁（使用框架的原子操作）
  OldValue := atomic_exchange(FFutex, FUTEX_UNLOCKED);

  // 如果有等待者，唤醒一个
  if OldValue = FUTEX_LOCKED_WITH_WAITERS then
    FutexWake(1);
end;

function TFutexMutex.TryAcquire: Boolean;
var
  CurrentTid: Int32;
  Expected: Int32;
begin
  CurrentTid := Int32(GetCurrentTid);

  // 先检查重入（原子读取）
  if atomic_load(FOwnerTid) = CurrentTid then
  begin
    // 检测到重入，直接返回失败
    Result := False;
    Exit;
  end;

  // 尝试原子获取锁（使用框架的原子操作）
  Expected := FUTEX_UNLOCKED;
  if atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED) then
  begin
    atomic_store(FOwnerTid, CurrentTid);
    Result := True;
  end
  else
  begin
    Result := False; // 锁被其他线程持有
  end;
end;

function TFutexMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  CurrentTid: Int32;
begin
  CurrentTid := Int32(GetCurrentTid);

  // 对于不可重入锁，检查重入
  // 如果是重入，直接返回失败，不进行等待（因为同一线程永远不会释放自己持有的锁）
  if atomic_load(FOwnerTid) = CurrentTid then
    Exit(False);

  // 调用基类的优化超时实现
  Result := inherited TryAcquire(ATimeoutMs);
end;

function TFutexMutex.GetHandle: Pointer;
begin
  Result := @FFutex;
end;

{$ENDIF}

end.
