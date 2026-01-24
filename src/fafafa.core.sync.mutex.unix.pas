unit fafafa.core.sync.mutex.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.time.cpu,
  fafafa.core.atomic;  // ✅ P1-1 Fix: 统一使用框架内的原子操作

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
    FUseNormalType: Boolean;  // 是否使用 PTHREAD_MUTEX_NORMAL 类型（用于 CondVar）
    // Poisoning 状态 - 使用 volatile 语义
    FPoisoned: LongInt;  // 使用 LongInt 支持原子操作 (0=false, 1=true)
    FPoisoningThreadId: TThreadID;
    FPoisoningException: string;
    FPoisonLock: pthread_mutex_t;  // 保护 poison 状态的轻量锁
  public
    constructor Create(AUseNormalType: Boolean = False); reintroduce;
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

  // ✅ P2-1 Fix: 自旋策略常量（消除魔法数字）
  SPIN_PHASE1_THRESHOLD = 1000;         // 第一阶段纯自旋上限
  SPIN_PHASE2_THRESHOLD = 4000;         // 第二阶段双重暂停上限
  SPIN_YIELD_INTERVAL_MASK = 127;       // 让出 CPU 的间隔掩码（每128次）
  SPIN_SHORT_COUNT = 40;                // 短自旋次数（用于 Acquire）
  SPIN_DEFAULT_MAX = 1000;              // 默认最大自旋次数

type

  { 现代互斥锁实现 - 使用 futex（Linux/FreeBSD）}
  TFutexMutex = class(TTryLock, IMutex)
  private
    FFutex: Int32;  // 使用 Int32 以配置 fafafa.core.atomic
    FHasOwner: Boolean;  // 是否有持有者
    FOwner: pthread_t;   // 当前持有者线程 ID
    // Poisoning 状态 - 使用 volatile 语义
    FPoisoned: LongInt;  // 使用 LongInt 支持原子操作 (0=false, 1=true)
    FPoisoningThreadId: TThreadID;
    FPoisoningException: string;
    FPoisonLock: pthread_mutex_t;  // 保护 poison 状态的轻量锁

    // futex 系统调用封装
    function FutexWait(ExpectedValue: LongInt; TimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function FutexWake(NumWaiters: LongInt = 1): Boolean;
    function SpinTryAcquire(MaxSpins: Integer = SPIN_DEFAULT_MAX): Boolean;
  public
    constructor Create; reintroduce;
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

{** 创建 pthread_mutex_t 版本的 mutex，用于与 pthread_cond_* 函数配合使用 *}
function MakePthreadMutex: IMutex; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** 创建 futex 版本的 mutex（高性能，仅 Linux），用于基准测试对比 *}
function MakeFutexMutex: IMutex; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

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

function MakePthreadMutex: IMutex;
begin
  // 使用 PTHREAD_MUTEX_NORMAL 类型，与 pthread_cond_* 兼容
  Result := TMutex.Create(True);
end;

function MakeFutexMutex: IMutex;
begin
  {$IFDEF FAFAFA_CORE_USE_FUTEX}
  // 使用 futex 实现（高性能）
  Result := TFutexMutex.Create;
  {$ELSE}
  // futex 不可用时回退到 pthread_mutex
  Result := TMutex.Create;
  {$ENDIF}
end;

{ TMutex - 传统 pthread 实现 }

constructor TMutex.Create(AUseNormalType: Boolean);
var
  Attr: pthread_mutexattr_t;
  LMutexType: cint;
begin
  inherited Create;
  FHasOwner := False;
  FUseNormalType := AUseNormalType;
  FPoisoned := 0;
  FPoisoningThreadId := 0;
  FPoisoningException := '';

  // 初始化 poison 状态保护锁
  if pthread_mutex_init(@FPoisonLock, nil) <> 0 then
    raise ELockError.Create('Failed to initialize poison lock');

  // 初始化互斥锁属性
  if pthread_mutexattr_init(@Attr) <> 0 then
  begin
    pthread_mutex_destroy(@FPoisonLock);
    raise ELockError.Create('Failed to initialize mutex attributes');
  end;

  try
    // 根据参数选择 mutex 类型
    if AUseNormalType then
      LMutexType := PTHREAD_MUTEX_NORMAL  // 用于 CondVar（无所有者检查）
    else
      LMutexType := PTHREAD_MUTEX_ERRORCHECK;  // 默认（检测同线程重复获取）
    
    if pthread_mutexattr_settype(@Attr, LMutexType) <> 0 then
    begin
      pthread_mutex_destroy(@FPoisonLock);
      raise ELockError.Create('Failed to set mutex type');
    end;

    // 初始化互斥锁
    if pthread_mutex_init(@FMutex, @Attr) <> 0 then
    begin
      pthread_mutex_destroy(@FPoisonLock);
      raise ELockError.Create('Failed to initialize mutex');
    end;
  finally
    pthread_mutexattr_destroy(@Attr);
  end;
end;

destructor TMutex.Destroy;
var
  RC: cint;
begin
  // ✅ P2-3 Fix: 增强析构安全检查
  // 安全检查：确保锁未被持有
  RC := pthread_mutex_trylock(@FMutex);
  if RC = 0 then
  begin
    // 成功获取说明没有人持有，立即释放
    pthread_mutex_unlock(@FMutex);
  end
  else if RC = ESysEBUSY then
  begin
    // 锁被持有，记录警告但继续销毁（避免资源泄漏）
    // 生产环境也应记录，便于调试内存问题
    {$IFDEF DEBUG}
    WriteLn(StdErr, 'Warning: Destroying mutex while it is held');
    {$ENDIF}
    // 尝试强制清理状态（防御性）
    FHasOwner := False;
  end;

  // 销毁互斥锁（忽略返回值，避免析构异常）
  pthread_mutex_destroy(@FMutex);
  pthread_mutex_destroy(@FPoisonLock);
  inherited Destroy;
end;

procedure TMutex.Acquire;
var
  Cur: pthread_t;
  RC: cint;
begin
  // 使用 PTHREAD_MUTEX_ERRORCHECK 类型的原子检测，避免竞态条件
  // pthread_mutex_lock 对于 ERRORCHECK 类型会在同线程重入时返回 EDEADLK
  RC := pthread_mutex_lock(@FMutex);
  if RC <> 0 then
  begin
    if RC = ESysEDEADLK then
      raise EDeadlockError.Create('Re-entrant acquire on non-reentrant mutex')
    else
      raise ELockError.Create('Failed to acquire mutex');
  end;

  // 锁已获取，安全更新 owner 状态
  Cur := pthread_self();
  FOwner := Cur;
  FHasOwner := True;

  // Poisoning 检查：获取锁后检查是否被毒化
  if FPoisoned <> 0 then
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
  RC: cint;
begin
  // 使用 PTHREAD_MUTEX_ERRORCHECK 类型的原子检测，避免竞态条件
  // pthread_mutex_trylock 对于 ERRORCHECK 类型会在同线程重入时返回 EDEADLK
  RC := pthread_mutex_trylock(@FMutex);
  if RC = ESysEDEADLK then
    raise EDeadlockError.Create('Re-entrant try-acquire on non-reentrant mutex');

  Result := (RC = 0);
  if Result then
  begin
    // 锁已获取，安全更新 owner 状态
    Cur := pthread_self();
    FOwner := Cur;
    FHasOwner := True;
    // Poisoning 检查：获取锁后检查是否被毒化
    if FPoisoned <> 0 then
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
  // ✅ P1-1 Fix: 使用框架内 atomic 操作，确保内存可见性
  Result := atomic_load(FPoisoned, mo_acquire) <> 0;
end;

procedure TMutex.ClearPoison;
begin
  // 使用锁保护字符串操作
  pthread_mutex_lock(@FPoisonLock);
  try
    FPoisoned := 0;
    FPoisoningThreadId := 0;
    FPoisoningException := '';
  finally
    pthread_mutex_unlock(@FPoisonLock);
  end;
end;

procedure TMutex.MarkPoisoned(const AExceptionMessage: string);
begin
  // 使用锁保护字符串操作，避免内存损坏
  pthread_mutex_lock(@FPoisonLock);
  try
    if FPoisoned = 0 then
    begin
      FPoisoningThreadId := GetThreadID;
      FPoisoningException := AExceptionMessage;
      // ✅ P1-1 Fix: 使用框架内 atomic 操作，确保其他字段已更新后再设置标志
      atomic_store(FPoisoned, LongInt(1), mo_release);
    end;
  finally
    pthread_mutex_unlock(@FPoisonLock);
  end;
end;

{$IFDEF FAFAFA_CORE_USE_FUTEX}
{ TFutexMutex - 现代 futex 实现 }

{$PUSH}
{$WARN 4055 OFF} // pointer/ordinal conversions for futex syscalls

constructor TFutexMutex.Create;
begin
  inherited Create;
  atomic_store(FFutex, FUTEX_UNLOCKED);
  FHasOwner := False;
  FPoisoned := 0;
  FPoisoningThreadId := 0;
  FPoisoningException := '';

  // 初始化 poison 状态保护锁
  if pthread_mutex_init(@FPoisonLock, nil) <> 0 then
    raise ELockError.Create('Failed to initialize poison lock');
end;

destructor TFutexMutex.Destroy;
var
  FutexValue: Int32;
begin
  // ✅ P2-3 Fix: 增强析构安全检查
  // 安全检查：确保 futex 未被持有
  FutexValue := atomic_load(FFutex);
  if FutexValue <> FUTEX_UNLOCKED then
  begin
    {$IFDEF DEBUG}
    WriteLn(StdErr, 'Warning: Destroying futex mutex while it is held');
    {$ENDIF}
    // 尝试强制清理状态（防御性）
    FHasOwner := False;
  end;

  // 销毁 poison 锁（忽略返回值，避免析构异常）
  pthread_mutex_destroy(@FPoisonLock);
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

    // ✅ P2-1 Fix: 使用命名常量替代魔法数字
    // 高性能自旋策略：前期纯自旋，后期适度退�?
    if SpinCount <= SPIN_PHASE1_THRESHOLD then
      CpuRelax  // 第一阶段纯自旋（最快）
    else if SpinCount <= SPIN_PHASE2_THRESHOLD then
    begin
      // 中期：双重暂�?
      CpuRelax; CpuRelax;
    end
    else
    begin
      // 后期：更多暂�?+ 偶尔让出CPU
      CpuRelax; CpuRelax; CpuRelax; CpuRelax;
      if (SpinCount and SPIN_YIELD_INTERVAL_MASK) = 0 then
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
  Cur := pthread_self();

  // 快速路径：尝试 CAS 获取锁 (UNLOCKED -> LOCKED)
  C := InterlockedCompareExchange(FFutex, FUTEX_LOCKED, FUTEX_UNLOCKED);
  if C = FUTEX_UNLOCKED then
  begin
    // 获锁成功，检查是否为重入（在锁内安全检查）
    if FHasOwner and (pthread_equal(FOwner, Cur) <> 0) then
    begin
      // 检测到重入，释放锁并抛异常
      atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
      raise EDeadlockError.Create('Re-entrant acquire on non-reentrant mutex');
    end;
    FOwner := Cur;
    FHasOwner := True;
    // Poisoning 检查
    if FPoisoned <> 0 then
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

  // ✅ P2-1 Fix: 使用命名常量替代魔法数字
  // 慢速路径：短自旋
  if SpinTryAcquire(SPIN_SHORT_COUNT) then
  begin
    // 获锁成功，检查是否为重入
    if FHasOwner and (pthread_equal(FOwner, Cur) <> 0) then
    begin
      atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
      raise EDeadlockError.Create('Re-entrant acquire on non-reentrant mutex');
    end;
    FOwner := Cur;
    FHasOwner := True;
    // Poisoning 检查
    if FPoisoned <> 0 then
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
  // 检查是否为重入
  if FHasOwner and (pthread_equal(FOwner, Cur) <> 0) then
  begin
    atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
    FutexWake(1);
    raise EDeadlockError.Create('Re-entrant acquire on non-reentrant mutex');
  end;
  FOwner := Cur;
  FHasOwner := True;

  // Poisoning 检查：获取锁后检查是否被毒化
  if FPoisoned <> 0 then
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
  Cur := pthread_self();

  // 尝试原子获取锁
  Expected := FUTEX_UNLOCKED;
  Result := atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED);
  if Result then
  begin
    // 获锁成功，检查是否为重入（在锁内安全检查）
    if FHasOwner and (pthread_equal(FOwner, Cur) <> 0) then
    begin
      // 检测到重入，释放锁并抛异常
      atomic_store(FFutex, FUTEX_UNLOCKED, mo_release);
      raise EDeadlockError.Create('Re-entrant try-acquire on non-reentrant mutex');
    end;
    FOwner := Cur;
    FHasOwner := True;
    // Poisoning 检查：获取锁后检查是否被毒化
    if FPoisoned <> 0 then
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
// 删除了复杂的超时逻辑，使用基类实现
end;

function TFutexMutex.GetHandle: Pointer;
begin
  Result := @FFutex;
end;

function TFutexMutex.IsPoisoned: Boolean;
begin
  // ✅ P1-1 Fix: 使用框架内 atomic 操作，确保内存可见性
  Result := atomic_load(FPoisoned, mo_acquire) <> 0;
end;

procedure TFutexMutex.ClearPoison;
begin
  // 使用锁保护字符串操作
  pthread_mutex_lock(@FPoisonLock);
  try
    FPoisoned := 0;
    FPoisoningThreadId := 0;
    FPoisoningException := '';
  finally
    pthread_mutex_unlock(@FPoisonLock);
  end;
end;

procedure TFutexMutex.MarkPoisoned(const AExceptionMessage: string);
begin
  // 使用锁保护字符串操作，避免内存损坏
  pthread_mutex_lock(@FPoisonLock);
  try
    if FPoisoned = 0 then
    begin
      FPoisoningThreadId := GetThreadID;
      FPoisoningException := AExceptionMessage;
      // ✅ P1-1 Fix: 使用框架内 atomic 操作，确保其他字段已更新后再设置标志
      atomic_store(FPoisoned, LongInt(1), mo_release);
    end;
  finally
    pthread_mutex_unlock(@FPoisonLock);
  end;
end;

{$POP}

{$ENDIF}

end.
