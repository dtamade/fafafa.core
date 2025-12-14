unit fafafa.core.sync.mutex.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.time.cpu
  {$IFDEF FAFAFA_CORE_USE_FUTEX}
  , fafafa.core.atomic
  {$ENDIF};

{$IFDEF LINUX}
const
  SYS_futex = 202;  // Linux x86_64 futex 系统调用�?

function fpSyscall(sysnr: clong; arg1, arg2, arg3, arg4, arg5, arg6: clong): clong; cdecl; external name 'syscall';
function fpgettid: pid_t; cdecl; external name 'gettid';
{$ENDIF}

type

  { 传统互斥锁实现 - 使用 pthread（兼容所有 Unix 系统）}
  TMutex = class(TTryLock, IMutex)
  private
    FMutex: pthread_mutex_t;
    FHasOwner: Boolean;
    FOwner: pthread_t;
    // Poisoning 状态
    FPoisoned: Boolean;
    FPoisoningThreadId: TThreadID;
    FPoisoningException: string;
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

    // Poisoning 支持
    function IsPoisoned: Boolean;
    procedure ClearPoison;
    procedure MarkPoisoned(const AExceptionMessage: string);
  end;

{$IFDEF FAFAFA_CORE_USE_FUTEX}

const
  // futex 操作类型（Linux/FreeBSD�?
  FUTEX_WAIT = 0;
  FUTEX_WAKE = 1;
  FUTEX_PRIVATE_FLAG = 128;
  FUTEX_WAIT_PRIVATE = FUTEX_WAIT or FUTEX_PRIVATE_FLAG;
  FUTEX_WAKE_PRIVATE = FUTEX_WAKE or FUTEX_PRIVATE_FLAG;

  // futex 状态�?
  FUTEX_UNLOCKED = 0;                    // 未锁�?
  FUTEX_LOCKED = 1;                      // 已锁定，无等待�?
  FUTEX_LOCKED_WITH_WAITERS = 2;         // 已锁定，有等待�?

type

  { 现代互斥锁实现 - 使用 futex（Linux/FreeBSD）}
  TFutexMutex = class(TTryLock, IMutex)
  private
    FFutex: Int32;  // 使用 Int32 以配置 fafafa.core.atomic
    FHasOwner: Boolean;  // 是否有持有者
    FOwner: pthread_t;   // 当前持有者线程 ID
    // Poisoning 状态
    FPoisoned: Boolean;
    FPoisoningThreadId: TThreadID;
    FPoisoningException: string;

    // futex 系统调用封装
    function FutexWait(ExpectedValue: LongInt; TimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function FutexWake(NumWaiters: LongInt = 1): Boolean;
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

    // Poisoning 支持
    function IsPoisoned: Boolean;
    procedure ClearPoison;
    procedure MarkPoisoned(const AExceptionMessage: string);
  end;
{$ENDIF}

function MakeMutex: IMutex; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function MakeMutex: IMutex;
begin
  {$IFDEF FAFAFA_CORE_USE_FUTEX}
  // 使用现代 futex 实现（高性能）
  Result := TFutexMutex.Create;
  {$ELSE}
  // 回退到 pthread_mutex 实现
  Result := TMutex.Create;
  {$ENDIF}
end;

{ TMutex - 传统 pthread 实现 }

constructor TMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;
  FHasOwner := False;
  FPoisoned := False;
  FPoisoningThreadId := 0;
  FPoisoningException := '';

  // 初始化互斥锁属�?
  if pthread_mutexattr_init(@Attr) <> 0 then
    raise ELockError.Create('Failed to initialize mutex attributes');

  try
    // 设置�?error-checking 互斥锁（检测同线程重复获取），避免死锁
    if pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_ERRORCHECK) <> 0 then
      raise ELockError.Create('Failed to set mutex type to error-check');

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
  Cur: pthread_t;
begin
  // 非重入：同一线程重复获取直接抛异常
  Cur := pthread_self();
  if FHasOwner and (pthread_equal(FOwner, Cur) <> 0) then
    raise EDeadlockError.Create('Re-entrant acquire on non-reentrant mutex');

  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to acquire mutex');

  FOwner := Cur;
  FHasOwner := True;

  // Poisoning 检查：获取锁后检查是否被毒化
  if FPoisoned then
  begin
    // 释放锁后再抛异常，避免死锁
    FHasOwner := False;
    pthread_mutex_unlock(@FMutex);
    raise EMutexPoisonError.Create(FPoisoningThreadId, FPoisoningException);
  end;
end;

procedure TMutex.Release;
begin
  FHasOwner := False;
  if pthread_mutex_unlock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to release mutex');
end;

function TMutex.TryAcquire: Boolean;
var
  Cur: pthread_t;
begin
  Cur := pthread_self();
  if FHasOwner and (pthread_equal(FOwner, Cur) <> 0) then
    raise EDeadlockError.Create('Re-entrant try-acquire on non-reentrant mutex');

  Result := pthread_mutex_trylock(@FMutex) = 0;
  if Result then
  begin
    FOwner := Cur;
    FHasOwner := True;
    // Poisoning 检查：获取锁后检查是否被毒化
    if FPoisoned then
    begin
      // 释放锁后再抛异常，避免死锁
      FHasOwner := False;
      pthread_mutex_unlock(@FMutex);
      raise EMutexPoisonError.Create(FPoisoningThreadId, FPoisoningException);
    end;
  end;
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := inherited TryAcquire(ATimeoutMs);
end;

function TMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;

function TMutex.IsPoisoned: Boolean;
begin
  Result := FPoisoned;
end;

procedure TMutex.ClearPoison;
begin
  FPoisoned := False;
  FPoisoningThreadId := 0;
  FPoisoningException := '';
end;

procedure TMutex.MarkPoisoned(const AExceptionMessage: string);
begin
  FPoisoned := True;
  FPoisoningThreadId := GetThreadID;
  FPoisoningException := AExceptionMessage;
end;

{$IFDEF FAFAFA_CORE_USE_FUTEX}
{ TFutexMutex - 现代 futex 实现 }

constructor TFutexMutex.Create;
begin
  inherited Create;
  atomic_store(FFutex, FUTEX_UNLOCKED);
  FHasOwner := False;
  FPoisoned := False;
  FPoisoningThreadId := 0;
  FPoisoningException := '';
end;

destructor TFutexMutex.Destroy;
begin
  // futex 无需显式销�?
  inherited Destroy;
end;

{ TFutexMutex 的辅助方�?}

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

  // 调用 futex 系统调用 - 使用更兼容的参数
  Res := fpSyscall(SYS_futex,
    clong(PtrUInt(@FFutex)),    // futex 地址
    FUTEX_WAIT,                 // 使用标准 FUTEX_WAIT（更兼容�?
    ExpectedValue,              // 期望�?
    clong(PtrUInt(TimeSpecPtr)), // 超时
    0, 0);

  Result := (Res = 0) or (fpgeterrno = ESysEINTR);  // 成功或被信号中断
  {$ELSE}
  // �?Linux 系统的回退实现
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
    FUTEX_WAKE,                 // 使用标准 FUTEX_WAKE（更兼容�?
    NumWaiters,                 // 唤醒数量
    0, 0, 0);

  Result := Res >= 0;
  {$ELSE}
  // �?Linux 系统的回退实现
  Result := True;
  {$ENDIF}
end;

function TFutexMutex.SpinTryAcquire(MaxSpins: Integer): Boolean;
var
  SpinCount: Integer;
  Expected: Int32;
begin
  for SpinCount := 1 to MaxSpins do
  begin
    // 尝试原子获取�?
    Expected := FUTEX_UNLOCKED;
    if atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED) then
      Exit(True);

    // 高性能自旋策略：前期纯自旋，后期适度退�?
    if SpinCount <= 1000 then
      CpuRelax  // �?000次纯自旋（最快）
    else if SpinCount <= 4000 then
    begin
      // 中期：双重暂�?
      CpuRelax; CpuRelax;
    end
    else
    begin
      // 后期：更多暂�?+ 偶尔让出CPU
      CpuRelax; CpuRelax; CpuRelax; CpuRelax;
      if (SpinCount and 127) = 0 then  // �?28次循环让出CPU
      begin
        {$IFDEF LINUX}
        fpSyscall(24, 0, 0, 0, 0, 0, 0); // sched_yield
        {$ELSE}
        Sleep(0);
        {$ENDIF}
      end;
    end;
  end;

  Result := False;
end;

procedure TFutexMutex.Acquire;
var
  C: Int32;
  Cur: pthread_t;
begin
  // 非重入检查：同一线程重复获取抛异常
  Cur := pthread_self();
  if FHasOwner and (pthread_equal(FOwner, Cur) <> 0) then
    raise EDeadlockError.Create('Re-entrant acquire on non-reentrant mutex');

  // 快速路径：尝试 CAS 获取锁 (UNLOCKED -> LOCKED)
  C := InterlockedCompareExchange(FFutex, FUTEX_LOCKED, FUTEX_UNLOCKED);
  if C = FUTEX_UNLOCKED then
  begin
    FOwner := Cur;
    FHasOwner := True;
    // Poisoning 检查
    if FPoisoned then
    begin
      FHasOwner := False;
      if InterlockedDecrement(FFutex) <> FUTEX_UNLOCKED then
      begin
        atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
        FutexWake(1);
      end;
      raise EMutexPoisonError.Create(FPoisoningThreadId, FPoisoningException);
    end;
    Exit;  // 成功获取
  end;

  // 慢速路径：短自旋
  if SpinTryAcquire(40) then
  begin
    FOwner := Cur;
    FHasOwner := True;
    // Poisoning 检查
    if FPoisoned then
    begin
      FHasOwner := False;
      if InterlockedDecrement(FFutex) <> FUTEX_UNLOCKED then
      begin
        atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
        FutexWake(1);
      end;
      raise EMutexPoisonError.Create(FPoisoningThreadId, FPoisoningException);
    end;
    Exit;
  end;

  // Futex 等待循环 - 使用简化的算法
  // 如果锁已被持有，设为 LOCKED_WITH_WAITERS 并等待
  if C <> FUTEX_LOCKED_WITH_WAITERS then
    C := InterlockedExchange(FFutex, FUTEX_LOCKED_WITH_WAITERS);

  while C <> FUTEX_UNLOCKED do
  begin
    // 等待 futex 唤醒
    FutexWait(FUTEX_LOCKED_WITH_WAITERS);
    // 被唤醒后设为 LOCKED_WITH_WAITERS 并获取旧值
    C := InterlockedExchange(FFutex, FUTEX_LOCKED_WITH_WAITERS);
  end;
  // C = FUTEX_UNLOCKED 且我们已设为 LOCKED_WITH_WAITERS，成功获取锁
  FOwner := Cur;
  FHasOwner := True;

  // Poisoning 检查：获取锁后检查是否被毒化
  if FPoisoned then
  begin
    // 释放锁后再抛异常，避免死锁
    FHasOwner := False;
    if InterlockedDecrement(FFutex) <> FUTEX_UNLOCKED then
    begin
      atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
      FutexWake(1);
    end;
    raise EMutexPoisonError.Create(FPoisoningThreadId, FPoisoningException);
  end;
end;

procedure TFutexMutex.Release;
begin
  FHasOwner := False;
  // 原子减 1
  if InterlockedDecrement(FFutex) <> FUTEX_UNLOCKED then
  begin
    // 之前是 LOCKED_WITH_WAITERS，现在是 LOCKED，需要设为 UNLOCKED 并唤醒
    atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
    FutexWake(1);
  end;
end;

function TFutexMutex.TryAcquire: Boolean;
var
  Expected: Int32;
  Cur: pthread_t;
begin
  // 非重入检查：同一线程重复获取抛异常
  Cur := pthread_self();
  if FHasOwner and (pthread_equal(FOwner, Cur) <> 0) then
    raise EDeadlockError.Create('Re-entrant try-acquire on non-reentrant mutex');

  // 尝试原子获取锁
  Expected := FUTEX_UNLOCKED;
  Result := atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED);
  if Result then
  begin
    FOwner := Cur;
    FHasOwner := True;
    // Poisoning 检查：获取锁后检查是否被毒化
    if FPoisoned then
    begin
      // 释放锁后再抛异常，避免死锁
      FHasOwner := False;
      if InterlockedDecrement(FFutex) <> FUTEX_UNLOCKED then
      begin
        atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
        FutexWake(1);
      end;
      raise EMutexPoisonError.Create(FPoisoningThreadId, FPoisoningException);
    end;
  end;
end;

function TFutexMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := inherited TryAcquire(ATimeoutMs);
// 删除了复杂的超时逻辑，使用基类实�?
end;

function TFutexMutex.GetHandle: Pointer;
begin
  Result := @FFutex;
end;

function TFutexMutex.IsPoisoned: Boolean;
begin
  Result := FPoisoned;
end;

procedure TFutexMutex.ClearPoison;
begin
  FPoisoned := False;
  FPoisoningThreadId := 0;
  FPoisoningException := '';
end;

procedure TFutexMutex.MarkPoisoned(const AExceptionMessage: string);
begin
  FPoisoned := True;
  FPoisoningThreadId := GetThreadID;
  FPoisoningException := AExceptionMessage;
end;

{$ENDIF}

end.
