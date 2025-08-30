unit fafafa.core.sync.mutex.unix;

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
  SYS_futex = 202;  // Linux x86_64 futex 系统调用号

function fpSyscall(sysnr: clong; arg1, arg2, arg3, arg4, arg5, arg6: clong): clong; cdecl; external name 'syscall';
function fpgettid: pid_t; cdecl; external name 'gettid';
{$ENDIF}

type

  { 传统互斥锁实现 - 使用 pthread（兼容所有 Unix 系统）}
  TMutex = class(TTryLock, IMutex)
  private
    FMutex: pthread_mutex_t;
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
  end;
{$ENDIF}

function MakeMutex: IMutex; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function MakeMutex: IMutex;
begin
  // 暂时使用 pthread_mutex 实现，因为 futex 实现在多线程下性能不佳
  // TODO: 修复 futex 实现后再启用
  Result := TMutex.Create;

  {$IFDEF FAFAFA_CORE_USE_FUTEX}
  // Result := TFutexMutex.Create;  // 暂时禁用
  {$ENDIF}
end;

{ TMutex - 传统 pthread 实现 }

constructor TMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;

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
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to acquire mutex');
end;

procedure TMutex.Release;
begin
  if pthread_mutex_unlock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to release mutex');
end;

function TMutex.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FMutex) = 0;
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
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
end;

destructor TFutexMutex.Destroy;
begin
  // futex 无需显式销毁
  inherited Destroy;
end;

{ TFutexMutex 的辅助方法 }

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
    FUTEX_WAIT,                 // 使用标准 FUTEX_WAIT（更兼容）
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
    FUTEX_WAKE,                 // 使用标准 FUTEX_WAKE（更兼容）
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
  Expected: Int32;
begin
  for SpinCount := 1 to MaxSpins do
  begin
    // 尝试原子获取锁
    Expected := FUTEX_UNLOCKED;
    if atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED) then
      Exit(True);

    // 高性能自旋策略：前期纯自旋，后期适度退避
    if SpinCount <= 1000 then
      CpuRelax  // 前1000次纯自旋（最快）
    else if SpinCount <= 4000 then
    begin
      // 中期：双重暂停
      CpuRelax; CpuRelax;
    end
    else
    begin
      // 后期：更多暂停 + 偶尔让出CPU
      CpuRelax; CpuRelax; CpuRelax; CpuRelax;
      if (SpinCount and 127) = 0 then  // 每128次循环让出CPU
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
  OldValue: Int32;
  Expected: Int32;
begin
  // 快速路径：尝试直接获取未锁定的锁
  Expected := FUTEX_UNLOCKED;
  if atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED) then
    Exit;

  // 慢速路径：自旋 + futex 等待
  if SpinTryAcquire(8000) then  // 大幅增加自旋次数，减少 futex 系统调用
    Exit;

  // 设置等待者标志并进入 futex 等待
  repeat
    OldValue := atomic_exchange(FFutex, FUTEX_LOCKED_WITH_WAITERS);
    if OldValue = FUTEX_UNLOCKED then
      Exit;

    // 等待 futex 唤醒
    FutexWait(FUTEX_LOCKED_WITH_WAITERS);
  until False;
end;

procedure TFutexMutex.Release;
var
  OldValue: Int32;
begin
  // 原子释放锁
  OldValue := atomic_exchange(FFutex, FUTEX_UNLOCKED);

  // 如果有等待者，唤醒一个
  if OldValue = FUTEX_LOCKED_WITH_WAITERS then
    FutexWake(1);
end;

function TFutexMutex.TryAcquire: Boolean;
var
  Expected: Int32;
begin
  // 尝试原子获取锁
  Expected := FUTEX_UNLOCKED;
  Result := atomic_compare_exchange_strong(FFutex, Expected, FUTEX_LOCKED);
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

{$ENDIF}

end.
