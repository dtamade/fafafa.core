unit fafafa.core.sync.adaptivelock;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TAdaptiveLock - 自适应互斥锁

  特点：
  - 低竞争时使用自旋等待（低延迟）
  - 高竞争时切换到阻塞等待（节省 CPU）
  - 自动根据历史竞争情况调整策略

  三段式等待策略：
  1. 自旋阶段：快速循环尝试获取锁
  2. 让步阶段：调用 yield 让出 CPU
  3. 阻塞阶段：进入内核等待

  使用示例：
    var
      L: TAdaptiveLock;
    begin
      L.Init;

      L.Acquire;
      try
        // 临界区
      finally
        L.Release;
      end;

      L.Done;
    end;

  适用场景：
  - 混合负载（有时高竞争有时低竞争）
  - 临界区时间不确定的场景
  - 需要平衡延迟和 CPU 使用的场景
}

interface

uses
  SysUtils, Classes,
  {$IFDEF UNIX}
  BaseUnix, Unix, UnixType, pthreads,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.atomic;

{$IFDEF UNIX}
const
  ADAPTIVE_CLOCK_REALTIME = 0;

function adaptive_clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt' name 'clock_gettime';
{$ENDIF}

type
  IAdaptiveLock = interface
    ['{C2D3E4F5-A6B7-8901-2345-6789ABCDEF01}']
    procedure Acquire;
    function TryAcquire: Boolean;
    function TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;
    procedure Release;
    function IsLocked: Boolean;
  end;

  { TAdaptiveLock - 自适应锁实现 }

  TAdaptiveLock = record
  private const
    SPIN_COUNT_INITIAL = 100;    // 初始自旋次数
    SPIN_COUNT_MIN = 10;         // 最小自旋次数
    SPIN_COUNT_MAX = 1000;       // 最大自旋次数
    YIELD_COUNT = 10;            // 让步次数
    ADAPTATION_RATE = 2;         // 自适应调整速率
  private
    FLocked: Int32;              // 0 = 未锁定, 1 = 已锁定
    FSpinCount: Int32;           // 当前自旋次数
    FContentionCount: Int32;     // 竞争计数
    {$IFDEF UNIX}
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    {$ENDIF}
    {$IFDEF WINDOWS}
    FCS: TRTLCriticalSection;
    FCondVar: TRTLConditionVariable;
    {$ENDIF}
    FInitialized: Boolean;

    procedure Lock; inline;
    procedure Unlock; inline;
    procedure WaitCond; inline;
    function WaitCondTimeout(ATimeoutMs: Cardinal): Boolean; inline;
    procedure NotifyOne; inline;
    procedure SpinWait(ACount: Integer); inline;
    procedure YieldCPU; inline;
    procedure AdaptSpinCount(AContended: Boolean);
  public
    {** 初始化 *}
    procedure Init;

    {** 释放资源 *}
    procedure Done;

    {** 获取锁（阻塞，自适应等待） *}
    procedure Acquire;

    {** 尝试获取锁（非阻塞）
        @return 成功返回 True *}
    function TryAcquire: Boolean;

    {** 尝试获取锁（带超时）
        @return 成功返回 True，超时返回 False *}
    function TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;

    {** 释放锁 *}
    procedure Release;

    {** 检查是否已锁定 *}
    function IsLocked: Boolean;

    {** 获取当前自旋计数（诊断用） *}
    function GetSpinCount: Integer;

    {** 获取竞争计数（诊断用） *}
    function GetContentionCount: Integer;

    property SpinCount: Integer read GetSpinCount;
    property ContentionCount: Integer read GetContentionCount;
  end;

{ 工厂函数 }
function MakeAdaptiveLock: IAdaptiveLock;

implementation

type
  { TAdaptiveLockImpl - 接口实现包装 }
  TAdaptiveLockImpl = class(TInterfacedObject, IAdaptiveLock)
  private
    FLock: TAdaptiveLock;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Acquire;
    function TryAcquire: Boolean;
    function TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;
    procedure Release;
    function IsLocked: Boolean;
  end;

{ TAdaptiveLockImpl }

constructor TAdaptiveLockImpl.Create;
begin
  inherited Create;
  FLock.Init;
end;

destructor TAdaptiveLockImpl.Destroy;
begin
  FLock.Done;
  inherited;
end;

procedure TAdaptiveLockImpl.Acquire;
begin
  FLock.Acquire;
end;

function TAdaptiveLockImpl.TryAcquire: Boolean;
begin
  Result := FLock.TryAcquire;
end;

function TAdaptiveLockImpl.TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;
begin
  Result := FLock.TryAcquireTimeout(ATimeoutMs);
end;

procedure TAdaptiveLockImpl.Release;
begin
  FLock.Release;
end;

function TAdaptiveLockImpl.IsLocked: Boolean;
begin
  Result := FLock.IsLocked;
end;

function MakeAdaptiveLock: IAdaptiveLock;
begin
  Result := TAdaptiveLockImpl.Create;
end;

{ TAdaptiveLock }

procedure TAdaptiveLock.Lock;
begin
  {$IFDEF UNIX}
  pthread_mutex_lock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  EnterCriticalSection(FCS);
  {$ENDIF}
end;

procedure TAdaptiveLock.Unlock;
begin
  {$IFDEF UNIX}
  pthread_mutex_unlock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  LeaveCriticalSection(FCS);
  {$ENDIF}
end;

procedure TAdaptiveLock.WaitCond;
begin
  {$IFDEF UNIX}
  pthread_cond_wait(@FCond, @FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  SleepConditionVariableCS(FCondVar, FCS, INFINITE);
  {$ENDIF}
end;

function TAdaptiveLock.WaitCondTimeout(ATimeoutMs: Cardinal): Boolean;
{$IFDEF UNIX}
var
  AbsTime: timespec;
  Now: timespec;
  Rc: Integer;
{$ENDIF}
begin
  {$IFDEF UNIX}
  adaptive_clock_gettime(ADAPTIVE_CLOCK_REALTIME, @Now);
  AbsTime.tv_sec := Now.tv_sec + (ATimeoutMs div 1000);
  AbsTime.tv_nsec := Now.tv_nsec + ((ATimeoutMs mod 1000) * 1000000);
  if AbsTime.tv_nsec >= 1000000000 then
  begin
    Inc(AbsTime.tv_sec);
    Dec(AbsTime.tv_nsec, 1000000000);
  end;
  Rc := pthread_cond_timedwait(@FCond, @FMutex, @AbsTime);
  Result := Rc <> ESysETIMEDOUT;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := SleepConditionVariableCS(FCondVar, FCS, ATimeoutMs);
  {$ENDIF}
end;

procedure TAdaptiveLock.NotifyOne;
begin
  {$IFDEF UNIX}
  pthread_cond_signal(@FCond);
  {$ENDIF}
  {$IFDEF WINDOWS}
  WakeConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TAdaptiveLock.SpinWait(ACount: Integer);
var
  i: Integer;
begin
  for i := 1 to ACount do
  begin
    {$IFDEF CPUX86_64}
    asm
      pause
    end;
    {$ELSE}
    // 其他架构使用空操作
    {$ENDIF}
  end;
end;

procedure TAdaptiveLock.YieldCPU;
begin
  {$IFDEF UNIX}
  fpNanoSleep(@pTimespec(nil)^, nil);  // sched_yield
  {$ENDIF}
  {$IFDEF WINDOWS}
  SwitchToThread;
  {$ENDIF}
end;

procedure TAdaptiveLock.AdaptSpinCount(AContended: Boolean);
var
  NewCount: Int32;
begin
  if AContended then
  begin
    // 高竞争：减少自旋
    NewCount := FSpinCount div ADAPTATION_RATE;
    if NewCount < SPIN_COUNT_MIN then
      NewCount := SPIN_COUNT_MIN;
  end
  else
  begin
    // 低竞争：增加自旋
    NewCount := FSpinCount * ADAPTATION_RATE;
    if NewCount > SPIN_COUNT_MAX then
      NewCount := SPIN_COUNT_MAX;
  end;
  atomic_store(FSpinCount, NewCount, mo_relaxed);
end;

procedure TAdaptiveLock.Init;
begin
  if FInitialized then
    Exit;

  FLocked := 0;
  FSpinCount := SPIN_COUNT_INITIAL;
  FContentionCount := 0;
  FInitialized := True;

  {$IFDEF UNIX}
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise Exception.Create('AdaptiveLock: failed to initialize mutex');
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise Exception.Create('AdaptiveLock: failed to initialize condition');
  end;
  {$ENDIF}
  {$IFDEF WINDOWS}
  InitializeCriticalSection(FCS);
  InitializeConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TAdaptiveLock.Done;
begin
  if not FInitialized then
    Exit;

  Lock;
  try
    {$IFDEF UNIX}
    pthread_cond_broadcast(@FCond);
    {$ENDIF}
    {$IFDEF WINDOWS}
    WakeAllConditionVariable(FCondVar);
    {$ENDIF}
  finally
    Unlock;
  end;

  {$IFDEF UNIX}
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  DeleteCriticalSection(FCS);
  {$ENDIF}

  FInitialized := False;
end;

procedure TAdaptiveLock.Acquire;
var
  SpinIter, YieldIter: Integer;
  CurrentSpinCount: Int32;
  Contended: Boolean;
  Expected: Int32;
begin
  Contended := False;
  CurrentSpinCount := atomic_load(FSpinCount, mo_relaxed);

  // 阶段 1：自旋等待
  for SpinIter := 1 to CurrentSpinCount do
  begin
    Expected := 0;
    if atomic_compare_exchange_weak(FLocked, Expected, 1, mo_acquire, mo_relaxed) then
    begin
      AdaptSpinCount(False);  // 无竞争
      Exit;
    end;
    SpinWait(1);
  end;

  Contended := True;

  // 阶段 2：让步等待
  for YieldIter := 1 to YIELD_COUNT do
  begin
    Expected := 0;
    if atomic_compare_exchange_weak(FLocked, Expected, 1, mo_acquire, mo_relaxed) then
    begin
      AdaptSpinCount(True);  // 有竞争但自旋成功
      Exit;
    end;
    YieldCPU;
  end;

  // 阶段 3：阻塞等待
  atomic_fetch_add(FContentionCount, 1, mo_relaxed);
  Lock;
  try
    while True do
    begin
      Expected := 0;
      if atomic_compare_exchange_weak(FLocked, Expected, 1, mo_acquire, mo_relaxed) then
      begin
        AdaptSpinCount(True);  // 高竞争
        Exit;
      end;
      WaitCond;
    end;
  finally
    Unlock;
  end;
end;

function TAdaptiveLock.TryAcquire: Boolean;
var
  Expected: Int32;
begin
  Expected := 0;
  Result := atomic_compare_exchange_strong(FLocked, Expected, 1, mo_acquire, mo_relaxed);
end;

function TAdaptiveLock.TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;
var
  SpinIter, YieldIter: Integer;
  CurrentSpinCount: Int32;
  Expected: Int32;
begin
  CurrentSpinCount := atomic_load(FSpinCount, mo_relaxed);

  // 快速路径：自旋尝试
  for SpinIter := 1 to CurrentSpinCount do
  begin
    Expected := 0;
    if atomic_compare_exchange_weak(FLocked, Expected, 1, mo_acquire, mo_relaxed) then
      Exit(True);
    SpinWait(1);
  end;

  // 让步尝试
  for YieldIter := 1 to YIELD_COUNT do
  begin
    Expected := 0;
    if atomic_compare_exchange_weak(FLocked, Expected, 1, mo_acquire, mo_relaxed) then
      Exit(True);
    YieldCPU;
  end;

  // 阻塞等待（带超时）
  Lock;
  try
    while True do
    begin
      Expected := 0;
      if atomic_compare_exchange_weak(FLocked, Expected, 1, mo_acquire, mo_relaxed) then
        Exit(True);
      if not WaitCondTimeout(ATimeoutMs) then
        Exit(False);
    end;
  finally
    Unlock;
  end;
end;

procedure TAdaptiveLock.Release;
begin
  atomic_store(FLocked, 0, mo_release);

  // 通知一个等待者
  Lock;
  try
    NotifyOne;
  finally
    Unlock;
  end;
end;

function TAdaptiveLock.IsLocked: Boolean;
begin
  Result := atomic_load(FLocked, mo_acquire) <> 0;
end;

function TAdaptiveLock.GetSpinCount: Integer;
begin
  Result := atomic_load(FSpinCount, mo_relaxed);
end;

function TAdaptiveLock.GetContentionCount: Integer;
begin
  Result := atomic_load(FContentionCount, mo_relaxed);
end;

end.
