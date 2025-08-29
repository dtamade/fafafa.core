unit fafafa.core.sync.spin.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.spin.base, fafafa.core.atomic;

type
  // 前向声明
  TSpinLock = class;

  // 优化的自旋锁结构，考虑缓存行对齐和性能
  TSpinLock = class(TInterfacedObject, ISpinLock, ISpinLockWithStats, ISpinLockDebug)
  private
    // ===== 热路径数据（第一缓存行，64字节）=====
    FSpinLock: pthread_spinlock_t;        // 8 bytes - 核心锁对象（最关键）
    FMaxSpins: Integer;                   // 4 bytes - 最大自旋次数（热路径）
    FStatsEnabled: Boolean;               // 1 byte - 统计开关（热路径判断）
    FErrorTracking: Boolean;              // 1 byte - 错误跟踪开关
    FLastError: TWaitError;               // 4 bytes - 最后错误

    // 填充到缓存行边界（确保下面的数据在新缓存行）
    FPadding1: array[0..CACHE_LINE_SIZE-19] of Byte;  // 填充剩余空间到缓存行边界

    // ===== 策略和配置数据（第二缓存行）=====
    FPolicy: TSpinLockPolicy;             // ~20 bytes - 策略配置
    FLastAcquireSpins: Integer;           // 4 bytes - 上次获取自旋次数
    FLastAcquireTimeUs: QWord;            // 8 bytes - 上次获取耗时

    // ===== 统计数据（冷路径，可能跨缓存行）=====
    FStats: TSpinLockStats;               // 统计信息（64字节）

    {$IFDEF DEBUG}
    // ===== Debug 数据（最冷路径）=====
    FOwnerThread: TThreadID;              // 8 bytes - 拥有者线程（原子读写）
    FHoldCount: Integer;                  // 4 bytes - 持有计数（原子操作）
    FAcquireTime: QWord;                  // 8 bytes - 获取时间戳（原子读写）
    {$ENDIF}
  public
    constructor Create(const APolicy: TSpinLockPolicy);
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function GetLastError: TWaitError;

    // ISpinLock 改进方法
    function GetMaxSpins: Integer;
    procedure SetMaxSpins(ASpins: Integer);

    // 新的状态查询方法
    function IsCurrentThreadOwner: Boolean;
    function GetLockState: Integer;

    // 错误处理方法 (继承自 ISynchronizable)
    // GetLastError 继承自 ISynchronizable，无需重复声明
    function GetErrorMessage(AError: TWaitError): string;
    procedure ClearLastError;

    // RAII 支持
    function Lock: ISpinLockGuard;
    function TryLock: ISpinLockGuard; overload;
    function TryLock(ATimeoutMs: Cardinal): ISpinLockGuard; overload;

    {$IFDEF DEBUG}
    // Debug 方法
    function GetOwnerThread: TThreadID;
    function GetHoldDurationMs: Cardinal;
    function IsDeadlockDetectionEnabled: Boolean;
    {$ENDIF}

    // ISpinLockWithStats 接口方法
    function GetStats: TSpinLockStats;
    function GetContentionRate: Double;
    function GetSpinEfficiency: Double;
    function GetAverageWaitTime: Double;
    procedure ResetStats;
    procedure EnableStats(AEnable: Boolean);
    function IsStatsEnabled: Boolean;

    // ISpinLockDebug 接口方法
    function GetDebugInfo: string;
    function GetCurrentSpins: Integer;
    function GetHoldCount: Integer;
    function GetLastAcquireSpins: Integer;
    function GetLastAcquireTimeUs: QWord;
    function CheckPotentialDeadlock: Boolean;
    function GetDeadlockInfo: string;

  private
    // 内部错误处理
    procedure SetLastError(AError: TWaitError);
    function CheckDeadlock: Boolean;

    // 内部统计辅助方法
    procedure UpdateStats(ASpinCount: Integer; AWaitTimeUs: QWord);
    function GetTickCountUs: QWord;

    // 优化的退避策略实现（与Windows统一）
    procedure PerformBackoff(ASpinCount: Integer; var ABackoffState: Integer);
  end;

implementation



{ TSpinLock }

constructor TSpinLock.Create(const APolicy: TSpinLockPolicy);
begin
  inherited Create;
  FPolicy := APolicy;
  FMaxSpins := APolicy.MaxSpins;
  FLastError := weNone;
  FErrorTracking := APolicy.EnableErrorTracking;

  // 初始化统计数据
  FStatsEnabled := APolicy.EnableStats;
  FillChar(FStats, SizeOf(FStats), 0);
  FLastAcquireSpins := 0;
  FLastAcquireTimeUs := 0;

  // 初始化 pthread 自旋锁
  if pthread_spin_init(@FSpinLock, PTHREAD_PROCESS_PRIVATE) <> 0 then
  begin
    SetLastError(weSystemError);
    raise ELockError.Create('Failed to initialize pthread spinlock');
  end;

  {$IFDEF DEBUG}
  FOwnerThread := 0;
  FHoldCount := 0;
  FAcquireTime := 0;
  {$ENDIF}
end;

destructor TSpinLock.Destroy;
begin
  {$IFDEF DEBUG}
  if FHoldCount > 0 then
    raise ELockError.Create('SpinLock destroyed while still held (debug check)');
  {$ENDIF}
  // 销毁 pthread 自旋锁
  pthread_spin_destroy(@FSpinLock);
  inherited Destroy;
end;

procedure TSpinLock.Acquire;
var
  spins: Integer;
  backoffState: Integer;
  startTimeUs, endTimeUs: QWord;
  {$IFDEF DEBUG}
  currentThread: TThreadID;
  startTime: QWord;
  {$ENDIF}
begin
  ClearLastError;

  // 记录开始时间（用于统计）
  if FStatsEnabled then
    startTimeUs := GetTickCountUs;

  {$IFDEF DEBUG}
  currentThread := GetCurrentThreadId;
  startTime := GetTickCount64;

  if TThreadID(InterlockedRead64(Int64(FOwnerThread))) = currentThread then
  begin
    SetLastError(weReentrancy);
    raise ELockError.Create('SpinLock reentrancy detected (debug check)');
  end;

  // 死锁检测
  if FPolicy.EnableDeadlockDetection and CheckDeadlock then
  begin
    SetLastError(weDeadlock);
    raise ELockError.Create('Potential deadlock detected');
  end;
  {$ENDIF}

  // 优化的自旋循环（与Windows统一）
  spins := 0;
  backoffState := 0;

  // 优化的自旋循环：统一的退避策略
  while pthread_spin_trylock(@FSpinLock) <> 0 do
  begin
    Inc(spins);
    PerformBackoff(spins, backoffState);
  end;

  {$IFDEF DEBUG}
  // 使用原子操作设置 Debug 数据，确保线程安全
  InterlockedExchange64(Int64(FOwnerThread), Int64(currentThread));
  InterlockedIncrement(FHoldCount);
  InterlockedExchange64(Int64(FAcquireTime), Int64(GetTickCount64));
  {$ENDIF}

  // 更新统计信息
  if FStatsEnabled then
  begin
    endTimeUs := GetTickCountUs;
    UpdateStats(spins, endTimeUs - startTimeUs);
  end;
end;

procedure TSpinLock.Release;
{$IFDEF DEBUG}
var
  currentThread: TThreadID;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  currentThread := GetCurrentThreadId;
  if FOwnerThread <> currentThread then
  begin
    SetLastError(weNotOwner);
    raise ELockError.Create('SpinLock released by non-owner thread (debug check)');
  end;
  if FHoldCount <= 0 then
  begin
    SetLastError(weAlreadyReleased);
    raise ELockError.Create('SpinLock released when not held (debug check)');
  end;

  Dec(FHoldCount);
  if FHoldCount = 0 then
  begin
    FOwnerThread := 0;
    FAcquireTime := 0;
  end;
  {$ENDIF}

  // 释放 pthread 自旋锁
  if pthread_spin_unlock(@FSpinLock) <> 0 then
  begin
    SetLastError(weSystemError);
    raise ELockError.Create('Failed to release pthread spinlock');
  end;
end;

function TSpinLock.TryAcquire: Boolean;
{$IFDEF DEBUG}
var
  currentThread: TThreadID;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  currentThread := GetCurrentThreadId;
  if FOwnerThread = currentThread then
    raise ELockError.Create('SpinLock reentrancy detected (debug check)');
  {$ENDIF}

  Result := pthread_spin_trylock(@FSpinLock) = 0;

  {$IFDEF DEBUG}
  if Result then
  begin
    FOwnerThread := currentThread;
    Inc(FHoldCount);
  end;
  {$ENDIF}

  // 更新统计信息（无自旋的快速获取）
  if FStatsEnabled and Result then
    UpdateStats(0, 0);
end;

function TSpinLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime, ElapsedMs: QWord;
  TimeSpec: TTimeSpec;
  R: cint;
  spins: Integer;
  sleepUs: Integer;
  startTimeUs, endTimeUs: QWord;
  {$IFDEF DEBUG}
  currentThread: TThreadID;
  {$ENDIF}
begin
  if ATimeoutMs = 0 then
  begin
    // 直接尝试获取锁，不调用 TryAcquire 避免潜在的递归问题
    Result := pthread_spin_trylock(@FSpinLock) = 0;

    {$IFDEF DEBUG}
    if Result then
    begin
      FOwnerThread := GetCurrentThreadId;
      Inc(FHoldCount);
    end;
    {$ENDIF}

    // 更新统计信息（无自旋的快速获取）
    if FStatsEnabled and Result then
      UpdateStats(0, 0);

    Exit;
  end;

  {$IFDEF DEBUG}
  currentThread := GetCurrentThreadId;
  if FOwnerThread = currentThread then
    raise ELockError.Create('SpinLock reentrancy detected (debug check)');
  {$ENDIF}

  // 记录开始时间（用于统计）
  if FStatsEnabled then
    startTimeUs := GetTickCountUs;

  StartTime := GetTickCount64;
  spins := 0;
  sleepUs := 50; // 从50微秒开始

  repeat
    Result := pthread_spin_trylock(@FSpinLock) = 0;
    if Result then
    begin
      {$IFDEF DEBUG}
      FOwnerThread := currentThread;
      Inc(FHoldCount);
      {$ENDIF}

      // 更新统计信息
      if FStatsEnabled then
      begin
        endTimeUs := GetTickCountUs;
        UpdateStats(spins, endTimeUs - startTimeUs);
      end;

      Exit;
    end;

    // 检查超时
    ElapsedMs := GetTickCount64 - StartTime;
    if ElapsedMs >= ATimeoutMs then
    begin
      // 超时时也更新统计信息（失败的获取）
      if FStatsEnabled then
      begin
        endTimeUs := GetTickCountUs;
        UpdateStats(spins, endTimeUs - startTimeUs);
      end;
      Exit(False);
    end;

    Inc(spins);

    if spins <= FMaxSpins then
    begin
      // 阶段1: 纯自旋，不让出CPU
      // 空循环，让CPU继续尝试
    end
    else if spins <= FMaxSpins * 2 then
    begin
      // 阶段2: 让出CPU给其他线程（使用短暂睡眠代替）
      TimeSpec.tv_sec := 0;
      TimeSpec.tv_nsec := 1000; // 1微秒
      fpnanosleep(@TimeSpec, nil);
    end
    else
    begin
      // 阶段3: 根据策略进行退避
      case FPolicy.BackoffStrategy of
        sbsLinear: begin
          TimeSpec.tv_sec := 0;
          TimeSpec.tv_nsec := sleepUs * 1000;
        end;
        sbsExponential, sbsAdaptive: begin
          TimeSpec.tv_sec := 0;
          TimeSpec.tv_nsec := sleepUs * 1000;
          // 指数退避，最大基于策略配置
          if sleepUs < (FPolicy.MaxBackoffMs * 1000) then
            sleepUs := sleepUs * 2;
        end;
      end;

      // 处理 EINTR 重试
      repeat
        R := fpnanosleep(@TimeSpec, nil);
        if R = 0 then Break;
        if fpgeterrno <> ESysEINTR then Break;
      until False;
    end;
  until False;

  // 如果到达这里，说明获取成功
  Result := True;

  {$IFDEF DEBUG}
  FOwnerThread := currentThread;
  Inc(FHoldCount);
  {$ENDIF}
end;

function TSpinLock.GetLastError: TWaitError;
begin
  // SpinLock 通常不需要复杂的错误状态，返回无错误
  Result := weNone;
end;

// ===== ISpinLock 简化方法实现 =====

function TSpinLock.GetMaxSpins: Integer;
begin
  Result := FMaxSpins;
end;

procedure TSpinLock.SetMaxSpins(ASpins: Integer);
begin
  FMaxSpins := ASpins;
  FPolicy.MaxSpins := ASpins;
end;



// ===== 新的状态查询方法（线程安全） =====

function TSpinLock.IsCurrentThreadOwner: Boolean;
{$IFDEF DEBUG}
var
  CurrentOwner: TThreadID;
  CurrentHoldCount: Integer;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  // 使用原子操作读取状态，避免竞态条件
  CurrentOwner := TThreadID(InterlockedRead64(Int64(FOwnerThread)));
  CurrentHoldCount := InterlockedRead(FHoldCount);
  Result := (CurrentOwner = GetCurrentThreadId) and (CurrentHoldCount > 0);
  {$ELSE}
  // 非 Debug 模式下无法准确判断，返回 False
  Result := False;
  {$ENDIF}
end;

function TSpinLock.GetLockState: Integer;
{$IFDEF DEBUG}
var
  CurrentHoldCount: Integer;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  // 使用原子操作读取持有计数，避免竞态条件
  CurrentHoldCount := InterlockedRead(FHoldCount);
  if CurrentHoldCount > 0 then
    Result := 1  // 已锁定
  else
    Result := 0; // 未锁定
  {$ELSE}
  // 非 Debug 模式下无法准确判断
  Result := -1; // 未知状态
  {$ENDIF}
end;

// ===== 错误处理方法 =====

function TSpinLock.GetErrorMessage(AError: TWaitError): string;
begin
  Result := SpinLockErrorToString(AError);
end;

procedure TSpinLock.ClearLastError;
begin
  FLastError := weNone;
end;

procedure TSpinLock.SetLastError(AError: TWaitError);
begin
  if FErrorTracking then
    FLastError := AError;
end;

function TSpinLock.CheckDeadlock: Boolean;
{$IFDEF DEBUG}
var
  currentTime: QWord;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  if not FPolicy.EnableDeadlockDetection then
  begin
    Result := False;
    Exit;
  end;

  currentTime := GetTickCount64;
  // 简单的死锁检测：如果当前线程已经持有锁超过阈值时间
  if (FOwnerThread = GetCurrentThreadId) and (FAcquireTime > 0) then
  begin
    Result := (currentTime - FAcquireTime) > FPolicy.DeadlockTimeoutMs;
  end
  else
    Result := False;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

{$IFDEF DEBUG}
function TSpinLock.GetOwnerThread: TThreadID;
begin
  Result := FOwnerThread;
end;

function TSpinLock.GetHoldDurationMs: Cardinal;
var
  currentTime: QWord;
begin
  if (FOwnerThread = GetCurrentThreadId) and (FAcquireTime > 0) then
  begin
    currentTime := GetTickCount64;
    Result := currentTime - FAcquireTime;
  end
  else
    Result := 0;
end;

function TSpinLock.IsDeadlockDetectionEnabled: Boolean;
begin
  Result := FPolicy.EnableDeadlockDetection;
end;
{$ENDIF}

// ===== ISpinLockWithStats 接口实现 =====

function TSpinLock.GetStats: TSpinLockStats;
begin
  Result := FStats;
end;

function TSpinLock.GetContentionRate: Double;
begin
  if FStats.AcquireCount = 0 then
    Result := 0.0
  else
    Result := (FStats.ContentionCount * 100.0) / FStats.AcquireCount;
end;

function TSpinLock.GetSpinEfficiency: Double;
begin
  if FStats.TotalSpinCount = 0 then
    Result := 100.0
  else if FStats.AcquireCount = 0 then
    Result := 0.0
  else
    Result := (FStats.AcquireCount * 100.0) / FStats.TotalSpinCount;
end;

function TSpinLock.GetAverageWaitTime: Double;
begin
  if FStats.AcquireCount = 0 then
    Result := 0.0
  else
    Result := FStats.TotalWaitTimeUs / FStats.AcquireCount;
end;

procedure TSpinLock.ResetStats;
begin
  FillChar(FStats, SizeOf(FStats), 0);
  FLastAcquireSpins := 0;
  FLastAcquireTimeUs := 0;
end;

procedure TSpinLock.EnableStats(AEnable: Boolean);
begin
  FStatsEnabled := AEnable;
  if not AEnable then
    ResetStats;
end;

function TSpinLock.IsStatsEnabled: Boolean;
begin
  Result := FStatsEnabled;
end;

// ===== ISpinLockDebug 接口实现 =====

function TSpinLock.GetDebugInfo: string;
begin
  Result := Format('SpinLock[MaxSpins=%d, Policy=%d, Stats=%s, Owner=%d]',
    [FMaxSpins, Ord(FPolicy.BackoffStrategy),
     BoolToStr(FStatsEnabled, True),
     {$IFDEF DEBUG}FOwnerThread{$ELSE}0{$ENDIF}]);
end;

function TSpinLock.GetCurrentSpins: Integer;
begin
  // 返回当前正在进行的自旋次数（简化实现）
  Result := 0; // 实际实现需要在自旋过程中跟踪
end;

function TSpinLock.GetHoldCount: Integer;
begin
  {$IFDEF DEBUG}
  Result := FHoldCount;
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

function TSpinLock.GetLastAcquireSpins: Integer;
begin
  Result := FLastAcquireSpins;
end;

function TSpinLock.GetLastAcquireTimeUs: QWord;
begin
  Result := FLastAcquireTimeUs;
end;

function TSpinLock.CheckPotentialDeadlock: Boolean;
begin
  Result := CheckDeadlock;
end;

function TSpinLock.GetDeadlockInfo: string;
begin
  if FPolicy.EnableDeadlockDetection then
    Result := Format('Deadlock detection enabled, timeout=%dms', [FPolicy.DeadlockTimeoutMs])
  else
    Result := 'Deadlock detection disabled';
end;

// ===== 内部辅助方法实现 =====

procedure TSpinLock.UpdateStats(ASpinCount: Integer; AWaitTimeUs: QWord);
begin
  if not FStatsEnabled then Exit;

  // 使用原子操作更新统计信息
  InterlockedIncrement64(FStats.AcquireCount);

  if ASpinCount > 0 then
  begin
    InterlockedIncrement64(FStats.ContentionCount);
    InterlockedExchangeAdd64(FStats.TotalSpinCount, ASpinCount);

    if ASpinCount > FStats.MaxSpinsPerAcquire then
      FStats.MaxSpinsPerAcquire := ASpinCount;
  end;

  InterlockedExchangeAdd64(FStats.TotalWaitTimeUs, AWaitTimeUs);

  if AWaitTimeUs > FStats.MaxWaitTimeUs then
    FStats.MaxWaitTimeUs := AWaitTimeUs;

  // 计算平均值
  if FStats.AcquireCount > 0 then
  begin
    FStats.AvgSpinsPerAcquire := FStats.TotalSpinCount / FStats.AcquireCount;
    FStats.AvgWaitTimeUs := FStats.TotalWaitTimeUs / FStats.AcquireCount;
  end;

  // 记录最后一次的数据
  FLastAcquireSpins := ASpinCount;
  FLastAcquireTimeUs := AWaitTimeUs;
end;

function TSpinLock.GetTickCountUs: QWord;
begin
  // 简化实现：使用毫秒精度转换为微秒
  // 在实际应用中可以使用更高精度的时间函数
  Result := GetTickCount64 * 1000;
end;

// ===== 优化的退避策略实现（与Windows统一）=====

procedure TSpinLock.PerformBackoff(ASpinCount: Integer; var ABackoffState: Integer);
var
  sleepMs: Integer;
  TimeSpec: TTimeSpec;
begin
  if ASpinCount <= SPIN_PHASE1_THRESHOLD then
  begin
    // 阶段1: 纯自旋，最高效
    // 什么都不做，让CPU继续尝试
  end
  else if ASpinCount <= SPIN_PHASE2_THRESHOLD then
  begin
    // 阶段2: 短暂让步，使用纳秒级睡眠
    TimeSpec.tv_sec := 0;
    TimeSpec.tv_nsec := 1000; // 1微秒
    fpnanosleep(@TimeSpec, nil);
  end
  else if ASpinCount <= SPIN_PHASE3_THRESHOLD then
  begin
    // 阶段3: 让出时间片给其他线程
    TimeSpec.tv_sec := 0;
    TimeSpec.tv_nsec := 10000; // 10微秒
    fpnanosleep(@TimeSpec, nil);
  end
  else
  begin
    // 阶段4: 策略退避，使用状态变量避免重复计算
    case FPolicy.BackoffStrategy of
      sbsNone: begin
        // 无退避，继续自旋
      end;
      sbsLinear: begin
        // 线性退避：1, 2, 3, 4, ... 最大到 MaxBackoffMs
        sleepMs := (ASpinCount - SPIN_PHASE3_THRESHOLD) div 32 + 1;
        if sleepMs > FPolicy.MaxBackoffMs then
          sleepMs := FPolicy.MaxBackoffMs;
        TimeSpec.tv_sec := sleepMs div 1000;
        TimeSpec.tv_nsec := (sleepMs mod 1000) * 1000000;
        fpnanosleep(@TimeSpec, nil);
      end;
      sbsExponential: begin
        // 指数退避：1, 2, 4, 8, 16, ... 最大到 MaxBackoffMs
        if ABackoffState = 0 then ABackoffState := 1;
        sleepMs := ABackoffState;
        if sleepMs > FPolicy.MaxBackoffMs then
          sleepMs := FPolicy.MaxBackoffMs
        else if ASpinCount mod 32 = 0 then // 每32次自旋翻倍一次
          ABackoffState := ABackoffState * 2;
        TimeSpec.tv_sec := sleepMs div 1000;
        TimeSpec.tv_nsec := (sleepMs mod 1000) * 1000000;
        fpnanosleep(@TimeSpec, nil);
      end;
      sbsAdaptive: begin
        // 自适应：前期指数，后期线性
        if ASpinCount < SPIN_PHASE3_THRESHOLD * 2 then
        begin
          // 前期指数退避
          if ABackoffState = 0 then ABackoffState := 1;
          sleepMs := ABackoffState;
          if sleepMs < FPolicy.MaxBackoffMs div 2 then
          begin
            if ASpinCount mod 16 = 0 then
              ABackoffState := ABackoffState * 2;
          end;
        end
        else
        begin
          // 后期线性退避
          sleepMs := (ASpinCount - SPIN_PHASE3_THRESHOLD * 2) div 64 + 1;
          if sleepMs > FPolicy.MaxBackoffMs then
            sleepMs := FPolicy.MaxBackoffMs;
        end;
        TimeSpec.tv_sec := sleepMs div 1000;
        TimeSpec.tv_nsec := (sleepMs mod 1000) * 1000000;
        fpnanosleep(@TimeSpec, nil);
      end;
    end;
  end;
end;

// ===== RAII 方法实现 =====

function TSpinLock.Lock: ISpinLockGuard;
begin
  Acquire;
  Result := TSpinLockGuard.Create(Self, True);
end;

function TSpinLock.TryLock: ISpinLockGuard;
begin
  Result := TSpinLockGuard.Create(Self, TryAcquire);
end;

function TSpinLock.TryLock(ATimeoutMs: Cardinal): ISpinLockGuard;
begin
  Result := TSpinLockGuard.Create(Self, TryAcquire(ATimeoutMs));
end;

end.
