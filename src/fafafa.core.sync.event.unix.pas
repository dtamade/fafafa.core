unit fafafa.core.sync.event.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  {$IFDEF HAS_CLOCK_GETTIME}cthreads,{$ENDIF}
  fafafa.core.sync.base, fafafa.core.sync.event.base;

{$IFDEF LINUX}
const
  CLOCK_MONOTONIC = 1;

// clock_gettime 函数声明
function clock_gettime(clk_id: Integer; tp: Ptimespec): Integer; cdecl; external 'c';
{$ENDIF}

const
  ESysEINTR = 4;  // 信号中断

type
  { TEvent
    Unix 平台基于 pthread_mutex + pthread_cond 的事件实现：
    - 自动/手动重置语义在本层通过 FSignaled + 条件变量实现
    - 为对齐 Windows 语义：
        * 手动重置：IsSignaled 非破坏式返回 FSignaled
        * 自动重置：IsSignaled 固定返回 False（请使用 WaitFor(0) 探测） }
  TEvent = class(TInterfacedObject, IEvent)
  private
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FSignaled: Boolean;
    FManualReset: Boolean;
    FLastError: TWaitError;
    FWaitingCount: Integer;  // 等待线程计数
    FAtomicSignaled: Integer; // 原子状态标志，用于快速路径优化 (0=未信号, 1=已信号)
    FAtomicInterrupted: Integer; // 原子中断标志 (0=未中断, 1=已中断)

    // 性能指标字段
    FMetrics: TEventMetrics;
    FMetricsEnabled: Boolean;
  public
    constructor Create(AManualReset: Boolean = False; AInitialState: Boolean = False);
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // IEvent - 基础操作
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;
    function IsSignaled: Boolean;

    // IEvent - 扩展操作
    function TryWait: Boolean;
    procedure Pulse;
    function IsManualReset: Boolean;
    function GetWaitingThreadCount: Integer;

    // IEvent - 增强的错误处理
    function GetLastErrorMessage: string;
    procedure ClearLastError;

    // IEvent - RAII 守卫方法
    function WaitGuard: IEventGuard;
    function WaitGuard(ATimeoutMs: Cardinal): IEventGuard;
    function TryWaitGuard: IEventGuard;

    // IEvent - 中断支持
    function WaitForInterruptible(ATimeoutMs: Cardinal): TWaitResult;
    procedure Interrupt;
    function IsInterrupted: Boolean;

    // IEvent - 取消令牌支持
    function WaitForCancellable(ATimeoutMs: Cardinal;
                               ACancellationToken: ICancellationToken): TWaitResult;
    function WaitGuardCancellable(ATimeoutMs: Cardinal;
                                 ACancellationToken: ICancellationToken): IEventGuard;

    // IEvent - 性能监控和指标
    function GetMetrics: TEventMetrics;
    procedure ResetMetrics;
    function IsMetricsEnabled: Boolean;
    procedure SetMetricsEnabled(AEnabled: Boolean);



    // 已移除兼容性方法 - 事件不是锁
  end;

implementation

{ 辅助函数：获取单调时间 - 使用 CLOCK_MONOTONIC 避免时间跳变 }
function GetTimeForTimeout(out ts: timespec): Boolean;
{$IFDEF LINUX}
begin
  // Linux: 使用 CLOCK_MONOTONIC 获取单调时间，不受系统时间调整影响
  Result := clock_gettime(CLOCK_MONOTONIC, @ts) = 0;
end;
{$ELSE}
var
  tv: timeval;
begin
  // 其他 Unix 系统：回退到 gettimeofday
  // 注意：这仍然受系统时间跳变影响，但保证兼容性
  if fpgettimeofday(@tv, nil) = 0 then
  begin
    ts.tv_sec := tv.tv_sec;
    ts.tv_nsec := tv.tv_usec * 1000;
    Result := True;
  end
  else
    Result := False;
end;
{$ENDIF}

function AddMillisecondsToTimespec(const base: timespec; ms: Cardinal): timespec;
begin
  Result.tv_sec := base.tv_sec + (ms div 1000);
  Result.tv_nsec := base.tv_nsec + (ms mod 1000) * 1000000;

  // 处理纳秒溢出
  if Result.tv_nsec >= 1000000000 then
  begin
    Inc(Result.tv_sec, Result.tv_nsec div 1000000000);
    Result.tv_nsec := Result.tv_nsec mod 1000000000;
  end;
end;

{ TEvent }

constructor TEvent.Create(AManualReset: Boolean; AInitialState: Boolean);
begin
  inherited Create;
  FLastError := weNone;
  FWaitingCount := 0;

  if pthread_mutex_init(@FMutex, nil) <> 0 then
  begin
    FLastError := weResourceExhausted;
    raise ELockError.Create('event: mutex init failed');
  end;

  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    FLastError := weResourceExhausted;
    raise ELockError.Create('event: cond init failed');
  end;

  FManualReset := AManualReset;
  FSignaled := AInitialState;
  FAtomicSignaled := Ord(AInitialState); // 初始化原子状态用于快速路径
  FAtomicInterrupted := 0; // 初始化原子中断标志

  // 初始化性能指标
  FillChar(FMetrics, SizeOf(FMetrics), 0);
  FMetricsEnabled := False; // 默认禁用指标收集以避免性能开销
end;

destructor TEvent.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TEvent.SetEvent;
var
  NeedSignal: Boolean;
  LockResult: Integer;
begin
  // 手动重置事件的无锁快速路径优化
  if FManualReset then
  begin
    // 如果已经是信号状态，可以快速返回
    if InterlockedCompareExchange(FAtomicSignaled, 0, 0) <> 0 then
    begin
      FLastError := weNone;
      Exit; // 已经是信号状态，无需重复设置
    end;
  end;

  LockResult := pthread_mutex_lock(@FMutex);
  if LockResult <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('event: mutex lock failed with error %d', [LockResult]);
  end;

  try
    // 检查是否需要发送信号（避免不必要的系统调用）
    NeedSignal := not FSignaled;
    if NeedSignal then
    begin
      FSignaled := True;
      // 内存屏障确保状态更新的可见性
      MemoryBarrier;
      // 原子更新必须在锁内进行，确保一致性
      InterlockedExchange(FAtomicSignaled, 1);

      // 发送信号给等待的线程
      if FManualReset then
        pthread_cond_broadcast(@FCond)  // 唤醒所有等待线程
      else
        pthread_cond_signal(@FCond);    // 只唤醒一个等待线程
    end;
  finally
    if pthread_mutex_unlock(@FMutex) <> 0 then
    begin
      FLastError := weSystemError;
      // 这是严重错误，但不能抛出异常（在 finally 块中）
    end;
  end;

  if NeedSignal then
    FLastError := weNone;
end;

procedure TEvent.ResetEvent;
var
  LockResult: Integer;
begin
  // 手动重置事件的无锁快速路径优化
  if FManualReset then
  begin
    // 如果已经是非信号状态，可以快速返回
    if InterlockedCompareExchange(FAtomicSignaled, 0, 0) = 0 then
    begin
      FLastError := weNone;
      Exit; // 已经是非信号状态，无需重复重置
    end;
  end;

  LockResult := pthread_mutex_lock(@FMutex);
  if LockResult <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('event: mutex lock failed with error %d', [LockResult]);
  end;

  try
    // 只有在当前是信号状态时才需要重置
    if FSignaled then
    begin
      FSignaled := False;
      // 内存屏障确保状态更新的可见性
      MemoryBarrier;
      // 原子更新必须在锁内进行，确保一致性
      InterlockedExchange(FAtomicSignaled, 0);
      FLastError := weNone;
    end;
  finally
    if pthread_mutex_unlock(@FMutex) <> 0 then
    begin
      FLastError := weSystemError;
      // 这是严重错误，但不能抛出异常（在 finally 块中）
    end;
  end;
end;

function TEvent.WaitFor: TWaitResult;
begin
  Result := WaitFor(High(Cardinal));
end;

function TEvent.WaitFor(ATimeoutMs: Cardinal): TWaitResult;
var
  ts: timespec;
  rc: Integer;
  current_time: timespec;
  LockResult: Integer;
begin
  LockResult := pthread_mutex_lock(@FMutex);
  if LockResult <> 0 then
  begin
    FLastError := weMutexLockFailed;
    Exit(wrError);
  end;
  try
    if ATimeoutMs = 0 then
    begin
      if FSignaled then
      begin
        if not FManualReset then
        begin
          FSignaled := False;
          InterlockedExchange(FAtomicSignaled, 0); // 原子更新：自动重置消费信号
        end;
        Exit(wrSignaled);
      end
      else
        Exit(wrTimeout);
    end
    else if ATimeoutMs = High(Cardinal) then
    begin
      Inc(FWaitingCount);
      try
        while not FSignaled do
          pthread_cond_wait(@FCond, @FMutex);
        if not FManualReset then
        begin
          FSignaled := False;
          InterlockedExchange(FAtomicSignaled, 0); // 原子更新：自动重置消费信号
        end;
        Exit(wrSignaled);
      finally
        Dec(FWaitingCount);
      end;
    end
    else
    begin
      // 使用改进的时间处理进行超时计算
      if not GetTimeForTimeout(ts) then
      begin
        FLastError := weTimeoutCalculationFailed;
        Exit(wrError);
      end;

      ts := AddMillisecondsToTimespec(ts, ATimeoutMs);

      Inc(FWaitingCount);
      try
        while not FSignaled do
        begin
          rc := pthread_cond_timedwait(@FCond, @FMutex, @ts);
          if rc = ESysETIMEDOUT then
            Exit(wrTimeout)
          else if rc = ESysEINTR then
          begin
            // 信号中断 - 继续等待，但检查是否超时
            if GetTimeForTimeout(current_time) then
            begin
              // 检查是否已经超时
              if (current_time.tv_sec > ts.tv_sec) or
                 ((current_time.tv_sec = ts.tv_sec) and (current_time.tv_nsec >= ts.tv_nsec)) then
                Exit(wrTimeout);
              // 否则继续等待
            end;
          end
          else if rc <> 0 then
          begin
            FLastError := weConditionWaitFailed;
            Exit(wrError);
          end;
        end;
        if not FManualReset then
          FSignaled := False;
        Exit(wrSignaled);
      finally
        Dec(FWaitingCount);
      end;
    end;
  finally
    if pthread_mutex_unlock(@FMutex) <> 0 then
    begin
      FLastError := weMutexUnlockFailed;
      // 在 finally 块中不能抛出异常，只能记录错误
    end;
  end;
end;

function TEvent.IsSignaled: Boolean;
begin
  if FManualReset then
  begin
    // 手动重置事件：使用无锁快速路径读取原子状态
    // 这避免了昂贵的互斥锁操作，显著提升高频调用性能
    Result := InterlockedCompareExchange(FAtomicSignaled, 0, 0) <> 0;
  end
  else
  begin
    // 自动重置事件：提供非破坏性检查
    // 使用 trylock 避免阻塞，如果无法获取锁则保守返回 False
    if pthread_mutex_trylock(@FMutex) = 0 then
    begin
      try
        Result := FSignaled;
      finally
        if pthread_mutex_unlock(@FMutex) <> 0 then
          FLastError := weSystemError;
      end;
    end
    else
    begin
      // 无法获取锁时保守返回 False
      // 这避免了阻塞，但可能产生假阴性结果
      Result := False;
    end;
  end;
end;

{ 已移除的兼容性方法实现 - 事件不是锁
  如需这些功能，请使用：
  - WaitFor() 替代 Acquire()
  - TryWait() 替代 TryAcquire()
  - SetEvent()/ResetEvent() 替代 Release()
}

{ ISynchronizable 实现 }
function TEvent.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

{ IEvent 扩展方法实现 }
function TEvent.TryWait: Boolean;
begin
  if FManualReset then
  begin
    // 手动重置事件：完全无锁快速路径
    // 直接检查原子状态，无需获取互斥锁
    if InterlockedCompareExchange(FAtomicSignaled, 0, 0) <> 0 then
    begin
      FLastError := weNone;
      Result := True;
      Exit;
    end;

    // 快速路径失败，回退到完整检查（但仍然是非阻塞的）
    Result := WaitFor(0) = wrSignaled;
  end
  else
  begin
    // 自动重置事件：尝试无锁快速路径
    if InterlockedCompareExchange(FAtomicSignaled, 0, 0) <> 0 then
    begin
      // 原子状态显示有信号，尝试获取锁来消费信号
      if pthread_mutex_trylock(@FMutex) = 0 then
      begin
        try
          if FSignaled then
          begin
            FSignaled := False;
            InterlockedExchange(FAtomicSignaled, 0);
            FLastError := weNone;
            Result := True;
            Exit;
          end;
        finally
          pthread_mutex_unlock(@FMutex);
        end;
      end;
    end;

    // 快速路径失败，回退到完整的非阻塞等待
    Result := WaitFor(0) = wrSignaled;
  end;
end;

procedure TEvent.Pulse;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;
  try
    FSignaled := True;
    pthread_cond_broadcast(@FCond); // 唤醒所有等待者
    if not FManualReset then
      FSignaled := False; // 立即重置
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TEvent.IsManualReset: Boolean;
begin
  Result := FManualReset;
end;

function TEvent.GetWaitingThreadCount: Integer;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    Exit(0);
  end;
  try
    FLastError := weNone;
    Result := FWaitingCount;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

{ IEvent 增强的错误处理实现 }
function TEvent.GetLastErrorMessage: string;
begin
  // 使用统一的错误消息映射函数
  Result := WaitErrorToString(FLastError);
end;

procedure TEvent.ClearLastError;
begin
  FLastError := weNone;
end;

{ IEvent RAII 守卫方法实现 }
function TEvent.WaitGuard: IEventGuard;
begin
  Result := WaitGuard(High(Cardinal));
end;

function TEvent.WaitGuard(ATimeoutMs: Cardinal): IEventGuard;
var
  WaitResult: TWaitResult;
begin
  WaitResult := WaitFor(ATimeoutMs);
  Result := TEventGuard.Create(Self, WaitResult = wrSignaled);
end;

function TEvent.TryWaitGuard: IEventGuard;
begin
  Result := WaitGuard(0);
end;

{ IEvent 中断支持实现 }
function TEvent.WaitForInterruptible(ATimeoutMs: Cardinal): TWaitResult;
var
  ts: timespec;
  rc: Integer;
  current_time: timespec;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    Exit(wrError);

  try
    Inc(FWaitingCount);
    try
      // 使用原子操作检查中断状态，确保内存可见性
      if InterlockedCompareExchange(FAtomicInterrupted, 0, 0) <> 0 then
        Exit(wrAbandoned); // 使用 wrAbandoned 表示中断

      // 检查初始状态
      if FSignaled then
      begin
        if not FManualReset then
        begin
          FSignaled := False;
          InterlockedExchange(FAtomicSignaled, 0);
        end;
        Exit(wrSignaled);
      end;

      if ATimeoutMs = 0 then
        Exit(wrTimeout);

      if ATimeoutMs = High(Cardinal) then
      begin
        // 无限等待，但可中断
        while not FSignaled do
        begin
          // 在每次循环中检查中断状态
          if InterlockedCompareExchange(FAtomicInterrupted, 0, 0) <> 0 then
            Exit(wrAbandoned);

          pthread_cond_wait(@FCond, @FMutex);
        end;

        if not FManualReset then
        begin
          FSignaled := False;
          InterlockedExchange(FAtomicSignaled, 0);
        end;
        Exit(wrSignaled);
      end
      else
      begin
        // 带超时的可中断等待
        if not GetTimeForTimeout(current_time) then
          Exit(wrError);

        ts.tv_sec := current_time.tv_sec + (ATimeoutMs div 1000);
        ts.tv_nsec := current_time.tv_nsec + ((ATimeoutMs mod 1000) * 1000000);
        if ts.tv_nsec >= 1000000000 then
        begin
          Inc(ts.tv_sec);
          Dec(ts.tv_nsec, 1000000000);
        end;

        while not FSignaled do
        begin
          // 在每次循环中检查中断状态
          if InterlockedCompareExchange(FAtomicInterrupted, 0, 0) <> 0 then
            Exit(wrAbandoned);

          rc := pthread_cond_timedwait(@FCond, @FMutex, @ts);
          if rc = ESysETIMEDOUT then
            Exit(wrTimeout);
          if rc <> 0 then
            Exit(wrError);
        end;

        if not FManualReset then
        begin
          FSignaled := False;
          InterlockedExchange(FAtomicSignaled, 0);
        end;
        Exit(wrSignaled);
      end;
    finally
      Dec(FWaitingCount);
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TEvent.Interrupt;
begin
  // 首先原子性地设置中断标志，确保所有线程立即可见
  InterlockedExchange(FAtomicInterrupted, 1);

  // 然后获取锁并唤醒所有等待的线程
  if pthread_mutex_lock(@FMutex) <> 0 then
    Exit;
  try
    // 唤醒所有等待的线程
    pthread_cond_broadcast(@FCond);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TEvent.IsInterrupted: Boolean;
begin
  // 使用无锁快速路径检查中断状态
  Result := InterlockedCompareExchange(FAtomicInterrupted, 0, 0) <> 0;
end;

{ IEvent 取消令牌支持实现 }
function TEvent.WaitForCancellable(ATimeoutMs: Cardinal;
                                  ACancellationToken: ICancellationToken): TWaitResult;
var
  StartTime, CurrentTime: QWord;
  RemainingTime: Cardinal;
  CheckInterval: Cardinal;
begin
  if not Assigned(ACancellationToken) then
  begin
    // 没有取消令牌，回退到普通等待
    Result := WaitFor(ATimeoutMs);
    Exit;
  end;

  // 检查是否已经被取消
  if ACancellationToken.IsCancelled then
  begin
    Result := wrAbandoned; // 使用 wrAbandoned 表示被取消
    Exit;
  end;

  StartTime := GetTickCount64;
  CheckInterval := 50; // 每50ms检查一次取消状态

  repeat
    // 计算剩余时间
    if ATimeoutMs = High(Cardinal) then
      RemainingTime := CheckInterval
    else
    begin
      CurrentTime := GetTickCount64;
      if CurrentTime - StartTime >= ATimeoutMs then
      begin
        Result := wrTimeout;
        Exit;
      end;
      RemainingTime := Min(CheckInterval, ATimeoutMs - (CurrentTime - StartTime));
    end;

    // 尝试等待事件
    Result := WaitFor(RemainingTime);
    if Result = wrSignaled then
      Exit; // 事件被信号化

    // 检查是否被取消
    if ACancellationToken.IsCancelled then
    begin
      Result := wrAbandoned; // 被取消
      Exit;
    end;

    // 如果是有限超时且已经超时，退出
    if ATimeoutMs <> High(Cardinal) then
    begin
      CurrentTime := GetTickCount64;
      if CurrentTime - StartTime >= ATimeoutMs then
      begin
        Result := wrTimeout;
        Exit;
      end;
    end;
  until False;
end;

function TEvent.WaitGuardCancellable(ATimeoutMs: Cardinal;
                                    ACancellationToken: ICancellationToken): IEventGuard;
var
  WaitResult: TWaitResult;
begin
  WaitResult := WaitForCancellable(ATimeoutMs, ACancellationToken);
  Result := TEventGuard.Create(Self, WaitResult = wrSignaled);
end;

{ IEvent 性能监控和指标实现 }
function TEvent.GetMetrics: TEventMetrics;
begin
  if FMetricsEnabled then
  begin
    // 计算平均等待时间
    if FMetrics.WaitCount > 0 then
      FMetrics.AverageWaitTime := FMetrics.TotalWaitTime / FMetrics.WaitCount
    else
      FMetrics.AverageWaitTime := 0;

    // 更新当前等待线程数
    FMetrics.CurrentWaiters := FWaitingCount;

    Result := FMetrics;
  end
  else
  begin
    // 如果未启用指标收集，返回空指标
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

procedure TEvent.ResetMetrics;
begin
  if FMetricsEnabled then
  begin
    FillChar(FMetrics, SizeOf(FMetrics), 0);
    FMetrics.CurrentWaiters := FWaitingCount;
  end;
end;

function TEvent.IsMetricsEnabled: Boolean;
begin
  Result := FMetricsEnabled;
end;

procedure TEvent.SetMetricsEnabled(AEnabled: Boolean);
begin
  FMetricsEnabled := AEnabled;
  if AEnabled then
  begin
    // 启用时重置指标
    FillChar(FMetrics, SizeOf(FMetrics), 0);
    FMetrics.CurrentWaiters := FWaitingCount;
  end;
end;

end.

