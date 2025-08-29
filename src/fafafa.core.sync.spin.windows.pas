unit fafafa.core.sync.spin.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.spin.base, fafafa.core.atomic;

type
  // 前向声明
  TSpinLock = class;

  // RAII 自旋锁守卫实现
  TSpinLockGuard = class(TInterfacedObject, ISpinLockGuard)
  private
    FSpinLock: ISpinLock;
    FIsValid: Boolean;
    FReleased: Boolean;
  public
    constructor Create(ASpinLock: ISpinLock; AIsValid: Boolean);
    destructor Destroy; override;

    // ISpinLockGuard 接口实现
    function IsValid: Boolean;
    function GetSpinLock: ISpinLock;
    procedure Release;
  end;

  // 增强的自旋锁结构，支持统计和调试功能
  TSpinLock = class(TInterfacedObject, ISpinLock, ISpinLockWithStats, ISpinLockDebug)
  private
    // 核心数据
    FFlag: atomic_flag;                   // 1 byte - 原子标志
    FMaxSpins: Integer;                   // 4 bytes - 最大自旋次数
    FPolicy: TSpinLockPolicy;             // ~20 bytes - 策略配置

    // 错误处理
    FLastError: TWaitError;               // 4 bytes - 最后错误
    FErrorTracking: Boolean;              // 1 byte - 错误跟踪开关

    // 统计数据（原子操作保证线程安全）
    FStats: TSpinLockStats;               // 统计信息
    FStatsEnabled: Boolean;               // 统计开关
    FLastAcquireSpins: Integer;           // 上次获取自旋次数
    FLastAcquireTimeUs: QWord;            // 上次获取耗时

    {$IFDEF DEBUG}
    // Debug 数据（使用原子操作保证线程安全）
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

  // 初始化原子标志为清除状态
  atomic_flag_clear(FFlag, memory_order_relaxed);

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
  inherited Destroy;
end;

procedure TSpinLock.Acquire;
var
  spins: Integer;
  backoffMs: Integer;
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

  // 使用策略配置的退避策略
  spins := 0;
  backoffMs := 1; // 初始退避时间

  while atomic_flag_test_and_set(FFlag, memory_order_acquire) do
  begin
    Inc(spins);

    if spins <= FMaxSpins then
    begin
      // 阶段1: CPU pause 指令，减少总线争用
      asm pause end;
    end
    else if spins <= FMaxSpins * 2 then
    begin
      // 阶段2: 让出当前线程时间片
      Windows.SwitchToThread;
    end
    else if spins <= FMaxSpins * 3 then
    begin
      // 阶段3: 让出时间片给其他线程
      Sleep(0);
    end
    else
    begin
      // 阶段4: 根据策略进行退避
      case FPolicy.BackoffStrategy of
        sbsLinear: begin
          // 线性退避：每次增加1ms，最大到 MaxBackoffMs
          if backoffMs < FPolicy.MaxBackoffMs then
            Inc(backoffMs);
          Sleep(backoffMs);
        end;
        sbsExponential: begin
          // 指数退避：每次翻倍，最大到 MaxBackoffMs
          if backoffMs < FPolicy.MaxBackoffMs then
            backoffMs := backoffMs * 2;
          if backoffMs > FPolicy.MaxBackoffMs then
            backoffMs := FPolicy.MaxBackoffMs;
          Sleep(backoffMs);
        end;
        sbsAdaptive: begin
          // 自适应：前期指数，后期线性
          if spins < FMaxSpins * 5 then
          begin
            // 前期指数退避
            if backoffMs < FPolicy.MaxBackoffMs div 2 then
              backoffMs := backoffMs * 2;
          end
          else
          begin
            // 后期线性退避
            if backoffMs < FPolicy.MaxBackoffMs then
              Inc(backoffMs);
          end;
          if backoffMs > FPolicy.MaxBackoffMs then
            backoffMs := FPolicy.MaxBackoffMs;
          Sleep(backoffMs);
        end;
      end;
    end;
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
  // 使用原子操作读取当前拥有者和持有计数
  if TThreadID(InterlockedRead64(Int64(FOwnerThread))) <> currentThread then
  begin
    SetLastError(weNotOwner);
    raise ELockError.Create('SpinLock released by non-owner thread (debug check)');
  end;
  if InterlockedRead(FHoldCount) <= 0 then
  begin
    SetLastError(weAlreadyReleased);
    raise ELockError.Create('SpinLock released when not held (debug check)');
  end;

  // 使用原子操作更新持有计数和拥有者
  if InterlockedDecrement(FHoldCount) = 0 then
  begin
    InterlockedExchange64(Int64(FOwnerThread), 0);
    InterlockedExchange64(Int64(FAcquireTime), 0);
  end;
  {$ENDIF}

  atomic_flag_clear(FFlag, memory_order_release);
end;

function TSpinLock.TryAcquire: Boolean;
{$IFDEF DEBUG}
var
  currentThread: TThreadID;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  currentThread := GetCurrentThreadId;
  if TThreadID(InterlockedRead64(Int64(FOwnerThread))) = currentThread then
    raise ELockError.Create('SpinLock reentrancy detected (debug check)');
  {$ENDIF}

  Result := not atomic_flag_test_and_set(FFlag, memory_order_acquire);

  {$IFDEF DEBUG}
  if Result then
  begin
    InterlockedExchange64(Int64(FOwnerThread), Int64(currentThread));
    InterlockedIncrement(FHoldCount);
  end;
  {$ENDIF}

  // 更新统计信息（无自旋的快速获取）
  if FStatsEnabled and Result then
    UpdateStats(0, 0);
end;

function TSpinLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: DWORD;
  ElapsedMs: DWORD;
  spins: Integer;
  backoffMs: Integer;
  maxSpins: Integer;
  startTimeUs, endTimeUs: QWord;
  {$IFDEF DEBUG}
  currentThread: TThreadID;
  {$ENDIF}
begin
  if ATimeoutMs = 0 then
  begin
    // 直接尝试获取锁，不调用 TryAcquire 避免潜在的递归问题
    Result := not atomic_flag_test_and_set(FFlag, memory_order_acquire);

    {$IFDEF DEBUG}
    if Result then
    begin
      InterlockedExchange64(Int64(FOwnerThread), Int64(GetCurrentThreadId));
      InterlockedIncrement(FHoldCount);
    end;
    {$ENDIF}

    // 更新统计信息（无自旋的快速获取）
    if FStatsEnabled and Result then
      UpdateStats(0, 0);

    Exit;
  end;

  {$IFDEF DEBUG}
  currentThread := GetCurrentThreadId;
  if TThreadID(InterlockedRead64(Int64(FOwnerThread))) = currentThread then
    raise ELockError.Create('SpinLock reentrancy detected (debug check)');
  {$ENDIF}

  // 记录开始时间（用于统计）
  if FStatsEnabled then
    startTimeUs := GetTickCountUs;

  StartTime := GetTickCount;
  spins := 0;
  backoffMs := 1;
  maxSpins := FMaxSpins;

  repeat
    Result := not atomic_flag_test_and_set(FFlag, memory_order_acquire);
    if Result then
    begin
      {$IFDEF DEBUG}
      InterlockedExchange64(Int64(FOwnerThread), Int64(currentThread));
      InterlockedIncrement(FHoldCount);
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
    ElapsedMs := GetTickCount - StartTime;
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

    // 使用与 Acquire 相同的退避策略
    if spins <= maxSpins then
    begin
      // 阶段1: CPU pause 指令
      asm pause end;
    end
    else if spins <= maxSpins * 2 then
    begin
      // 阶段2: 让出当前线程时间片
      Windows.SwitchToThread;
    end
    else if spins <= maxSpins * 3 then
    begin
      // 阶段3: 让出时间片
      Sleep(0);
    end
    else
    begin
      // 阶段4: 根据策略进行退避
      case FPolicy.BackoffStrategy of
        sbsLinear: begin
          if backoffMs < FPolicy.MaxBackoffMs then
            Inc(backoffMs);
        end;
        sbsExponential: begin
          if backoffMs < FPolicy.MaxBackoffMs then
            backoffMs := backoffMs * 2;
          if backoffMs > FPolicy.MaxBackoffMs then
            backoffMs := FPolicy.MaxBackoffMs;
        end;
        sbsAdaptive: begin
          if spins < maxSpins * 5 then
          begin
            if backoffMs < FPolicy.MaxBackoffMs div 2 then
              backoffMs := backoffMs * 2;
          end
          else
          begin
            if backoffMs < FPolicy.MaxBackoffMs then
              Inc(backoffMs);
          end;
          if backoffMs > FPolicy.MaxBackoffMs then
            backoffMs := FPolicy.MaxBackoffMs;
        end;
      end;

      // 确保不超过剩余时间
      if backoffMs > (ATimeoutMs - ElapsedMs) then
        backoffMs := ATimeoutMs - ElapsedMs;

      if backoffMs > 0 then
        Sleep(backoffMs);
    end;
  until False;
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
  if (TThreadID(InterlockedRead64(Int64(FOwnerThread))) = GetCurrentThreadId) and
     (QWord(InterlockedRead64(Int64(FAcquireTime))) > 0) then
  begin
    Result := (currentTime - QWord(InterlockedRead64(Int64(FAcquireTime)))) > FPolicy.DeadlockTimeoutMs;
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
  if (TThreadID(InterlockedRead64(Int64(FOwnerThread))) = GetCurrentThreadId) and
     (QWord(InterlockedRead64(Int64(FAcquireTime))) > 0) then
  begin
    currentTime := GetTickCount64;
    Result := currentTime - QWord(InterlockedRead64(Int64(FAcquireTime)));
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
var
  freq, counter: Int64;
begin
  if QueryPerformanceFrequency(freq) and QueryPerformanceCounter(counter) then
    Result := (counter * 1000000) div freq
  else
    Result := GetTickCount64 * 1000; // 降级到毫秒精度
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

// ===== TSpinLockGuard 实现 =====

constructor TSpinLockGuard.Create(ASpinLock: ISpinLock; AIsValid: Boolean);
begin
  inherited Create;
  FSpinLock := ASpinLock;
  FIsValid := AIsValid;
  FReleased := False;
end;

destructor TSpinLockGuard.Destroy;
begin
  if FIsValid and not FReleased then
    FSpinLock.Release;
  inherited Destroy;
end;

function TSpinLockGuard.IsValid: Boolean;
begin
  Result := FIsValid and not FReleased;
end;

function TSpinLockGuard.GetSpinLock: ISpinLock;
begin
  Result := FSpinLock;
end;

procedure TSpinLockGuard.Release;
begin
  if FIsValid and not FReleased then
  begin
    FSpinLock.Release;
    FReleased := True;
  end;
end;

end.
