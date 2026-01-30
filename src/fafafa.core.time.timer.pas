unit fafafa.core.time.timer;

{$modeswitch advancedrecords}
{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.timer.base,            // ✅ Phase 2: 共享类型
  fafafa.core.time.timer.backend,         // ✅ Phase 3.1: 后端接口
  fafafa.core.time.timer.backend.heap,    // ✅ Phase 3.1: 二叉堆后端实现
  fafafa.core.sync,
  fafafa.core.thread.threadpool,
  fafafa.core.thread.cancel;

// ✅ Phase 2: 类型已移至 fafafa.core.time.timer.base
// 重新导出以保持向后兼容

type
  // 重新导出 timer.base 中的类型（向后兼容别名）
  TTimerKindAlias = fafafa.core.time.timer.base.TTimerKind;
  TTimerCallbackAlias = fafafa.core.time.timer.base.TTimerCallback;
  ITimerScheduler = fafafa.core.time.timer.base.ITimerScheduler;
  ITimer = fafafa.core.time.timer.base.ITimer;
  ITicker = fafafa.core.time.timer.base.ITicker;
  TTimerSchedulerOptions = fafafa.core.time.timer.base.TTimerSchedulerOptions;
  TTimerKind = fafafa.core.time.timer.base.TTimerKind;
  TTimerCallback = fafafa.core.time.timer.base.TTimerCallback;
  TTimerCallbackKind = fafafa.core.time.timer.base.TTimerCallbackKind;
  TTimerProc = fafafa.core.time.timer.base.TTimerProc;
  TTimerProcData = fafafa.core.time.timer.base.TTimerProcData;
  TTimerMethod = fafafa.core.time.timer.base.TTimerMethod;
  TTimerProcNested = fafafa.core.time.timer.base.TTimerProcNested;
  TProc = fafafa.core.time.timer.base.TProc;
  TTimerExceptionHandler = fafafa.core.time.timer.base.TTimerExceptionHandler;
  TTimerMetrics = fafafa.core.time.timer.base.TTimerMetrics;
  TTimerResult = fafafa.core.time.timer.base.TTimerResult;
  ITimerSchedulerTry = fafafa.core.time.timer.base.ITimerSchedulerTry;

// 重新导出回调便捷构造函数
function TimerCallback(const P: TTimerProc): TTimerCallback; overload;
function TimerCallback(const P: TTimerProcData; Data: Pointer): TTimerCallback; overload;
function TimerCallbackMethod(const M: TTimerMethod): TTimerCallback;
function TimerCallbackNested(const N: TTimerProcNested): TTimerCallback;
procedure ExecuteTimerCallback(const cb: TTimerCallback);

function CreateTickerFixedRate(const InitialDelay, Period: TDuration; const Callback: TProc; const Clock: IMonotonicClock = nil): ITicker;
function CreateTickerFixedDelay(const InitialDelay, Delay: TDuration; const Callback: TProc; const Clock: IMonotonicClock = nil): ITicker;
function CreateTickerFixedRateOn(const Scheduler: ITimerScheduler; const InitialDelay, Period: TDuration; const Callback: TProc): ITicker;
function CreateTickerFixedDelayOn(const Scheduler: ITimerScheduler; const InitialDelay, Delay: TDuration; const Callback: TProc): ITicker;

function CreateTimerScheduler(const Clock: IMonotonicClock = nil): ITimerScheduler; overload;
function CreateTimerScheduler(const Clock: IMonotonicClock; const CallbackPool: IThreadPool): ITimerScheduler; overload;
function CreateTimerScheduler(const Options: TTimerSchedulerOptions): ITimerScheduler; overload;
function DefaultTimerScheduler: ITimerScheduler; inline;

  // FixedRate 追赶步数上限（0 表示不限制）
  // ✅ ISSUE-24: 默认值改为 3，避免追赶风暴
var
  GFixedRateMaxCatchupSteps: Integer = 3;

  // 回调异常处理 Hook（可选）
  procedure SetTimerExceptionHandler(const H: TTimerExceptionHandler);
  function GetTimerExceptionHandler: TTimerExceptionHandler;

  procedure SetTimerFixedRateMaxCatchupSteps(const V: Integer);
var
  GTimerExceptionHandler: TTimerExceptionHandler = nil;

  procedure TimerResetMetrics;
  function TimerGetMetrics: TTimerMetrics;

  function GetTimerFixedRateMaxCatchupSteps: Integer;


implementation

var
  GMetrics: TTimerMetrics;
  GMetricsLock: ILock;  // ✅ 保留用于 Reset/Get 操作
  // ✅ ISSUE-23: 为 GTimerExceptionHandler 添加锁保护
  GTimerExceptionHandlerLock: ILock;
  // ✅ v2.0 优化: 全局默认调度器（懒加载）
  // ✅ ISSUE-REVIEW-P1-1: 使用原子状态标志避免双重检查锁定的内存屏障问题
  GDefaultScheduler: ITimerScheduler = nil;
  GDefaultSchedulerLock: ILock;
  GDefaultSchedulerOnce: Int32 = 0;  // 0=未初始化, 1=正在初始化, 2=已完成

// ✅ v2.0 优化: 原子指标计数（替代锁）
procedure AtomicIncScheduled;
begin
  {$IFDEF FPC}
  InterlockedIncrement64(GMetrics.ScheduledTotal);
  {$ELSE}
  AtomicIncrement(GMetrics.ScheduledTotal);
  {$ENDIF}
end;

procedure AtomicIncFired;
begin
  {$IFDEF FPC}
  InterlockedIncrement64(GMetrics.FiredTotal);
  {$ELSE}
  AtomicIncrement(GMetrics.FiredTotal);
  {$ENDIF}
end;

procedure AtomicIncCancelled;
begin
  {$IFDEF FPC}
  InterlockedIncrement64(GMetrics.CancelledTotal);
  {$ELSE}
  AtomicIncrement(GMetrics.CancelledTotal);
  {$ENDIF}
end;

procedure AtomicIncException;
begin
  {$IFDEF FPC}
  InterlockedIncrement64(GMetrics.ExceptionTotal);
  {$ELSE}
  AtomicIncrement(GMetrics.ExceptionTotal);
  {$ENDIF}
end;
  
// ✅ ISSUE-28: 默认异常处理器，输出到 stderr
procedure DefaultTimerExceptionHandler(const E: Exception);
begin
  WriteLn(ErrOutput, '[Timer Exception] ', E.ClassName, ': ', E.Message);
end;

// ✅ v2.0: TTimerCallback 便捷构造函数实现
function TimerCallback(const P: TTimerProc): TTimerCallback;
begin
  Result.Kind := tckProc;
  Result.Proc := P;
end;

function TimerCallback(const P: TTimerProcData; Data: Pointer): TTimerCallback;
begin
  Result.Kind := tckProcData;
  Result.ProcData := P;
  Result.Data := Data;
end;

function TimerCallbackMethod(const M: TTimerMethod): TTimerCallback;
begin
  Result.Kind := tckMethod;
  Result.Method := M;
end;

function TimerCallbackNested(const N: TTimerProcNested): TTimerCallback;
begin
  Result.Kind := tckNested;
  Result.Nested := N;
end;

// ✅ v2.0: 回调执行
procedure ExecuteTimerCallback(const cb: TTimerCallback);
begin
  case cb.Kind of
    tckProc:
      if Assigned(cb.Proc) then cb.Proc();
    tckProcData:
      if Assigned(cb.ProcData) then cb.ProcData(cb.Data);
    tckMethod:
      if Assigned(cb.Method) then cb.Method();
    tckNested:
      if Assigned(cb.Nested) then cb.Nested();
  end;
end;


type
  // ✅ Phase 2: TTimerEntry 和 PTimerEntry 已移至 fafafa.core.time.timer.base
  // TTimerKind 已在接口部分定义

  TTimerRef = class(TInterfacedObject, ITimer)
  private
    FEntry: PTimerEntry;
    FLock: ILock;
  public
    constructor Create(AEntry: PTimerEntry; const Lock: ILock);
    destructor Destroy; override;
    // 基础方法
    procedure Cancel;
    function IsCancelled: Boolean;
    function ResetAt(const Deadline: TInstant): Boolean;
    function ResetAfter(const Delay: TDuration): Boolean;
    // ✅ v2.0: 状态查询
    function GetNextDeadline: TInstant;
    function GetExecutionCount: QWord;
    function GetKind: TTimerKind;
    function IsFired: Boolean;
    // ✅ v2.0: 周期定时器控制
    function Pause: Boolean;
    function Resume: Boolean;
    function IsPaused: Boolean;
    // ✅ v2.0: 执行次数限制
    function SetMaxExecutions(Max: QWord): Boolean;
    function GetMaxExecutions: QWord;
  end;

  // Simple ticker wrapper
  TTicker = class(TInterfacedObject, ITicker)
  private
    FSch: ITimerScheduler;
    FTimer: ITimer;
    FStopped: Boolean;
    FLock: ILock;
  public
    constructor Create(const Sch: ITimerScheduler; const Tm: ITimer);
    procedure Stop;
    function IsStopped: Boolean;
  end;

  // 回调上下文：用于异步执行
  PCallbackContext = ^TCallbackContext;
  TCallbackContext = record
    Callback: TTimerCallback;  // ✅ v2.0: 使用统一回调类型
    Entry: PTimerEntry;
    Kind: TTimerKind;
    Delay: TDuration;
    Scheduler: Pointer; // TTimerSchedulerImpl
    SchedulerRef: IInterface; // keep scheduler alive until task completes
  end;

  TTimerSchedulerImpl = class(TInterfacedObject, ITimerScheduler, ITimerSchedulerTry)
  private
    FClock: IMonotonicClock;
    FLock: ILock;
    // ✅ Phase 3.1: 使用可插拔后端接口替代内部堆数组
    FBackend: ITimerQueueBackend;
    FThread: TThread;
    FShuttingDown: Boolean;
    FWakeup: IEvent; // wake up timer thread on insert/cancel/shutdown

    // 异步回调执行支持
    FCallbackPool: IThreadPool; // 用于异步执行定时器回调
    FUseAsyncCallbacks: Boolean; // 是否启用异步回调
  private
    // ✅ Phase 3.1: 后端封装方法（替代旧的堆方法）
    function BackendInsert(e: PTimerEntry): Boolean;
    procedure BackendRemove(e: PTimerEntry);
    procedure BackendUpdateDeadline(e: PTimerEntry);
    function BackendPopMin: PTimerEntry;
    function BackendCount: Integer; inline;
    function BackendPeek: PTimerEntry; inline;
    function BackendIsEmpty: Boolean; inline;

    procedure ThreadProc;
    procedure ExecuteCallbackSync(const cb: TTimerCallback; const best: PTimerEntry; const kind: TTimerKind; const delay: TDuration);
    procedure ExecuteCallbackAsync(const cb: TTimerCallback; const best: PTimerEntry; const kind: TTimerKind; const delay: TDuration);
    // ✅ v2.0: 内部核心调度方法
    function DoScheduleAt(const Deadline: TInstant; const Callback: TTimerCallback; const AKind: TTimerKind; const Period, Delay: TDuration; const Token: ICancellationToken = nil): ITimer;
  public
    constructor Create(const Clock: IMonotonicClock); overload;
    constructor Create(const Clock: IMonotonicClock; const CallbackPool: IThreadPool); overload;
    destructor Destroy; override;
    // TProc 版本（向后兼容）
    function ScheduleOnce(const Delay: TDuration; const Callback: TProc): ITimer;
    function ScheduleAt(const Deadline: TInstant; const Callback: TProc): ITimer;
    function ScheduleAtFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): ITimer;
    function ScheduleWithFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): ITimer;
    // ✅ v2.0: TTimerCallback 版本
    function Schedule(const Delay: TDuration; const Callback: TTimerCallback): ITimer;
    function ScheduleAtCb(const Deadline: TInstant; const Callback: TTimerCallback): ITimer;
    function ScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback): ITimer;
    function ScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback): ITimer;
    // ✅ v2.0: 带取消令牌的版本
    function ScheduleWithToken(const Delay: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;
    function ScheduleFixedRateWithToken(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;
    function ScheduleFixedDelayWithToken(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;

    // Phase 1: Result-style APIs
    function TrySchedule(const Delay: TDuration; const Callback: TTimerCallback): TTimerResult; overload;
    function TrySchedule(const Delay: TDuration; const Callback: TProc): TTimerResult; overload;

    function TryScheduleAt(const Deadline: TInstant; const Callback: TProc): TTimerResult;
    function TryScheduleAtCb(const Deadline: TInstant; const Callback: TTimerCallback): TTimerResult;

    function TryScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback): TTimerResult; overload;
    function TryScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): TTimerResult; overload;

    function TryScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback): TTimerResult; overload;
    function TryScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): TTimerResult; overload;

    procedure Shutdown;
    procedure SetCallbackExecutor(const Pool: IThreadPool);
    function GetCallbackExecutor: IThreadPool;
  end;

  TTimerThread = class(TThread)
  private
    FOwner: TTimerSchedulerImpl;
  protected
    procedure Execute; override;
  public
    constructor Create(Owner: TTimerSchedulerImpl);
  end;

{ TTimerRef }
constructor TTimerRef.Create(AEntry: PTimerEntry; const Lock: ILock);
begin
  inherited Create;
  FEntry := AEntry;
  FLock := Lock;
  // ✅ 不再增加 RefCount，因为 Schedule 方法中已经将初始值设置为 1
  // 这避免了在 BackendInsert 之后、TTimerRef.Create 之前的竞态条件
  // 当前 TTimerRef 持有这个引用，数值已经包含在初始值中
end;

procedure SetTimerExceptionHandler(const H: TTimerExceptionHandler);
begin
  // ✅ ISSUE-23: 使用锁保护，避免读写竞争
  if GTimerExceptionHandlerLock <> nil then
    GTimerExceptionHandlerLock.Acquire;
  try
    GTimerExceptionHandler := H;
  finally
    if GTimerExceptionHandlerLock <> nil then
      GTimerExceptionHandlerLock.Release;
  end;
end;

function GetTimerExceptionHandler: TTimerExceptionHandler;
begin
  // ✅ ISSUE-23: 使用锁保护，避免读写竞争
  if GTimerExceptionHandlerLock <> nil then
    GTimerExceptionHandlerLock.Acquire;
  try
    Result := GTimerExceptionHandler;
  finally
    if GTimerExceptionHandlerLock <> nil then
      GTimerExceptionHandlerLock.Release;
  end;
end;
procedure TimerResetMetrics;
begin
  if GMetricsLock <> nil then GMetricsLock.Acquire;
  try
    FillChar(GMetrics, SizeOf(GMetrics), 0);
  finally
    if GMetricsLock <> nil then GMetricsLock.Release;
  end;
end;

function TimerGetMetrics: TTimerMetrics;
begin
  if GMetricsLock <> nil then GMetricsLock.Acquire;
  try
    Result := GMetrics;
  finally
    if GMetricsLock <> nil then GMetricsLock.Release;
  end;
end;


procedure TTimerRef.Cancel;
begin
  FLock.Acquire;
  try
    if Assigned(FEntry) and (not FEntry^.Cancelled) then
    begin
      FEntry^.Cancelled := True;
      FEntry^.Dead := True;
      AtomicIncCancelled;  // ✅ v2.0 优化: 原子计数替代锁
    end;
  finally
    FLock.Release;
  end;
end;

destructor TTimerRef.Destroy;
var
  LNewRefCount: LongInt;
begin
  if FLock <> nil then FLock.Acquire;
  try
    if Assigned(FEntry) then
    begin
      // ✅ ISSUE-REVIEW-P1-3: 使用原子操作避免竞态条件
      LNewRefCount := InterlockedDecrement(FEntry^.RefCount);
      // 若已取消/一次性已触发且不在堆中，且计数为0，则释放
      if (LNewRefCount <= 0) and (FEntry^.Dead) and (not FEntry^.InHeap) then
        Dispose(FEntry);
      FEntry := nil;
    end;
  finally
    if FLock <> nil then FLock.Release;
  end;
  inherited Destroy;
end;

function TTimerRef.IsCancelled: Boolean;
begin
  FLock.Acquire;
  try
    Result := Assigned(FEntry) and FEntry^.Cancelled;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.ResetAt(const Deadline: TInstant): Boolean;
var
  sch: TTimerSchedulerImpl;
begin
  FLock.Acquire;
  try
    if (FEntry = nil) or FEntry^.Cancelled then Exit(False);
    if FEntry^.Kind <> tkOnce then Exit(False);
    if FEntry^.Fired then Exit(False);
    if not FEntry^.InHeap then Exit(False);  // ✅ 必须在堆中才能重置

    // 保存调度器引用
    sch := TTimerSchedulerImpl(FEntry^.Owner);

    // 修改截止时间
    FEntry^.Deadline := Deadline;

    // ✅ Phase 3.1: 使用后端接口更新堆排序
    if (sch <> nil) and FEntry^.InHeap then
    begin
      sch.BackendUpdateDeadline(FEntry);
      // ✅ 唤醒调度线程重新计算等待时间
      if Assigned(sch.FWakeup) then
        sch.FWakeup.SetEvent;
    end;

    Result := True;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.ResetAfter(const Delay: TDuration): Boolean;
var
  sch: TTimerSchedulerImpl;
  dl: TInstant;
begin
  // 必须使用所属调度器的时钟（支持注入 IFixedClock 等测试时钟）
  if FEntry = nil then Exit(False);

  sch := TTimerSchedulerImpl(FEntry^.Owner);
  if sch <> nil then
    dl := sch.FClock.NowInstant.Add(Delay)
  else
    dl := DefaultMonotonicClock.NowInstant.Add(Delay); // 防御性回退

  Result := ResetAt(dl);
end;

// ✅ v2.0: 状态查询方法实现

function TTimerRef.GetNextDeadline: TInstant;
begin
  FLock.Acquire;
  try
    if (FEntry = nil) or FEntry^.Cancelled or FEntry^.Dead then
      Result := TInstant.Zero
    else
      Result := FEntry^.Deadline;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.GetExecutionCount: QWord;
begin
  FLock.Acquire;
  try
    if FEntry = nil then
      Result := 0
    else
      Result := FEntry^.ExecutionCount;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.GetKind: TTimerKind;
begin
  FLock.Acquire;
  try
    if FEntry = nil then
      Result := tkOnce  // 默认值
    else
      Result := FEntry^.Kind;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.IsFired: Boolean;
begin
  FLock.Acquire;
  try
    Result := (FEntry <> nil) and FEntry^.Fired;
  finally
    FLock.Release;
  end;
end;

// ✅ v2.0: 周期定时器控制方法实现

function TTimerRef.Pause: Boolean;
var
  sch: TTimerSchedulerImpl;
begin
  FLock.Acquire;
  try
    // 仅支持周期定时器
    if (FEntry = nil) or (FEntry^.Kind = tkOnce) then Exit(False);
    if FEntry^.Cancelled or FEntry^.Dead then Exit(False);
    if FEntry^.Paused then Exit(False);  // 已经暂停

    FEntry^.Paused := True;

    // ✅ Phase 3.1: 如果在堆中，需要移除（暂停时不参与调度）
    if FEntry^.InHeap then
    begin
      sch := TTimerSchedulerImpl(FEntry^.Owner);
      if sch <> nil then
        sch.BackendRemove(FEntry);
      // 后端会自动设置 InHeap=False 和 HeapIndex=-1
    end;

    Result := True;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.Resume: Boolean;
var
  sch: TTimerSchedulerImpl;
begin
  FLock.Acquire;
  try
    // 仅支持周期定时器
    if (FEntry = nil) or (FEntry^.Kind = tkOnce) then Exit(False);
    if FEntry^.Cancelled or FEntry^.Dead then Exit(False);
    if not FEntry^.Paused then Exit(False);  // 没有暂停

    FEntry^.Paused := False;

    // 重新加入堆，设置新的 Deadline
    sch := TTimerSchedulerImpl(FEntry^.Owner);
    if sch <> nil then
    begin
      // 根据类型设置下次触发时间
      case FEntry^.Kind of
        tkFixedRate:
          FEntry^.Deadline := sch.FClock.NowInstant.Add(FEntry^.Period);
        tkFixedDelay:
          FEntry^.Deadline := sch.FClock.NowInstant.Add(FEntry^.Delay);
        tkOnce:
          ;  // 不应该发生（已在上面检查过），忽略
      end;

      // 重新加入堆
      if not FEntry^.InHeap then
      begin
        // ✅ Phase 3.1: 使用后端接口
        if not sch.BackendInsert(FEntry) then
          Exit(False);  // 容量已满，恢复失败
        if Assigned(sch.FWakeup) then
          sch.FWakeup.SetEvent;
      end;
    end;

    Result := True;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.IsPaused: Boolean;
begin
  FLock.Acquire;
  try
    Result := (FEntry <> nil) and FEntry^.Paused;
  finally
    FLock.Release;
  end;
end;

// ✅ v2.0: 执行次数限制
function TTimerRef.SetMaxExecutions(Max: QWord): Boolean;
begin
  FLock.Acquire;
  try
    if FEntry = nil then Exit(False);
    if FEntry^.Kind = tkOnce then Exit(False);  // 一次性定时器不适用
    if FEntry^.Cancelled then Exit(False);
    FEntry^.MaxExecutions := Max;
    Result := True;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.GetMaxExecutions: QWord;
begin
  FLock.Acquire;
  try
    if FEntry = nil then
      Result := 0
    else
      Result := FEntry^.MaxExecutions;
  finally
    FLock.Release;
  end;
end;

function CreateTickerFixedRateOn(const Scheduler: ITimerScheduler; const InitialDelay, Period: TDuration; const Callback: TProc): ITicker;
var tm: ITimer;
begin
  if Scheduler = nil then Exit(nil);
  tm := Scheduler.ScheduleFixedRate(InitialDelay, Period, TimerCallback(TTimerProc(Callback)));
  Result := TTicker.Create(Scheduler, tm);
end;

function CreateTickerFixedDelayOn(const Scheduler: ITimerScheduler; const InitialDelay, Delay: TDuration; const Callback: TProc): ITicker;
var tm: ITimer;
begin
  if Scheduler = nil then Exit(nil);
  tm := Scheduler.ScheduleFixedDelay(InitialDelay, Delay, TimerCallback(TTimerProc(Callback)));
  Result := TTicker.Create(Scheduler, tm);
end;

// ✅ v2.0 优化: 获取全局默认调度器（懒加载）
// ✅ ISSUE-REVIEW-P1-1: 使用原子 CAS 模式避免双重检查锁定的内存屏障问题
function GetDefaultTimerScheduler: ITimerScheduler;
var
  LState: Int32;
begin
  // 快速路径：检查是否已初始化完成
  LState := InterlockedCompareExchange(GDefaultSchedulerOnce, 0, 0);
  if LState = 2 then
    Exit(GDefaultScheduler);

  // 尝试获取初始化权
  if InterlockedCompareExchange(GDefaultSchedulerOnce, 1, 0) = 0 then
  begin
    // 我们赢得了初始化权，执行初始化
    try
      GDefaultScheduler := CreateTimerScheduler(nil);
      // 使用内存屏障确保写入可见后再设置状态
      InterlockedExchange(GDefaultSchedulerOnce, 2);
    except
      // 初始化失败，重置状态允许重试
      InterlockedExchange(GDefaultSchedulerOnce, 0);
      raise;
    end;
  end
  else
  begin
    // 其他线程正在初始化，等待完成
    while InterlockedCompareExchange(GDefaultSchedulerOnce, 0, 0) <> 2 do
    begin
      {$IFDEF WINDOWS}
      Sleep(0);  // 让出时间片
      {$ELSE}
      ThreadSwitch;
      {$ENDIF}
    end;
  end;
  Result := GDefaultScheduler;
end;

function DefaultTimerScheduler: ITimerScheduler;
begin
  Result := GetDefaultTimerScheduler;
end;

// ✅ v2.0 优化: 使用全局默认调度器（当 Clock 为 nil 时）
function CreateTickerFixedRate(const InitialDelay, Period: TDuration; const Callback: TProc; const Clock: IMonotonicClock): ITicker;
var sch: ITimerScheduler;
begin
  if Clock = nil then
    sch := GetDefaultTimerScheduler
  else
    sch := CreateTimerScheduler(Clock);
  Result := CreateTickerFixedRateOn(sch, InitialDelay, Period, Callback);
end;

// ✅ v2.0 优化: 使用全局默认调度器（当 Clock 为 nil 时）
function CreateTickerFixedDelay(const InitialDelay, Delay: TDuration; const Callback: TProc; const Clock: IMonotonicClock): ITicker;
var sch: ITimerScheduler;
begin
  if Clock = nil then
    sch := GetDefaultTimerScheduler
  else
    sch := CreateTimerScheduler(Clock);
  Result := CreateTickerFixedDelayOn(sch, InitialDelay, Delay, Callback);
end;

// ✅ ISSUE-REVIEW-P2-5: 使用原子操作确保线程安全
procedure SetTimerFixedRateMaxCatchupSteps(const V: Integer);
var
  LValue: Int32;
begin
  if V < 0 then
    LValue := 0
  else
    LValue := V;
  // 使用原子写入确保线程可见性
  InterlockedExchange(GFixedRateMaxCatchupSteps, LValue);
end;

function GetTimerFixedRateMaxCatchupSteps: Integer;
begin
  // ✅ ISSUE-REVIEW-P2-5: 使用原子读取确保获取最新值
  Result := InterlockedCompareExchange(GFixedRateMaxCatchupSteps, 0, 0);
end;


{ TTicker }
constructor TTicker.Create(const Sch: ITimerScheduler; const Tm: ITimer);
begin
  inherited Create;
  FSch := Sch; FTimer := Tm; FStopped := False; FLock := TMutex.Create;
end;

procedure TTicker.Stop;
begin
  FLock.Acquire;
  try
    if not FStopped then
    begin
      FStopped := True;
      if Assigned(FTimer) then FTimer.Cancel;
      FTimer := nil;
    end;
  finally
    FLock.Release;
  end;
end;

function TTicker.IsStopped: Boolean;
begin
  FLock.Acquire;
  try
    Result := FStopped;
  finally
    FLock.Release;
  end;
end;


{ TTimerThread }
constructor TTimerThread.Create(Owner: TTimerSchedulerImpl);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwner := Owner;
  Start;
end;

procedure TTimerThread.Execute;
begin
  FOwner.ThreadProc;
end;

{ TTimerSchedulerImpl }
constructor TTimerSchedulerImpl.Create(const Clock: IMonotonicClock);
begin
  inherited Create;
  if Clock <> nil then FClock := Clock else FClock := DefaultMonotonicClock;
  FLock := TMutex.Create;
  FBackend := CreateDefaultBackend;  // ✅ Phase 3.1: 使用后端接口
  FShuttingDown := False;
  FWakeup := TEvent.Create(True, False); // manual reset, non-signaled
  FCallbackPool := nil;
  FUseAsyncCallbacks := False;
  FThread := TTimerThread.Create(Self);
end;

constructor TTimerSchedulerImpl.Create(const Clock: IMonotonicClock; const CallbackPool: IThreadPool);
begin
  inherited Create;
  if Clock <> nil then FClock := Clock else FClock := DefaultMonotonicClock;
  FLock := TMutex.Create;
  FBackend := CreateDefaultBackend;  // ✅ Phase 3.1: 使用后端接口
  FShuttingDown := False;
  FWakeup := TEvent.Create(True, False);
  FCallbackPool := CallbackPool;
  FUseAsyncCallbacks := (CallbackPool <> nil);
  FThread := TTimerThread.Create(Self);
end;

// ✅ Phase 3.1: 后端封装方法实现
function TTimerSchedulerImpl.BackendInsert(e: PTimerEntry): Boolean;
begin
  // 容量限制检查
  if FBackend.Count >= TIMER_HEAP_MAX_CAPACITY then
    Exit(False);
  e^.Owner := Self;
  FBackend.Enqueue(PTimerEntryOpaque(e));
  Result := True;
end;

procedure TTimerSchedulerImpl.BackendRemove(e: PTimerEntry);
begin
  FBackend.Remove(PTimerEntryOpaque(e));
end;

procedure TTimerSchedulerImpl.BackendUpdateDeadline(e: PTimerEntry);
begin
  FBackend.UpdateDeadline(PTimerEntryOpaque(e));
end;

function TTimerSchedulerImpl.BackendPopMin: PTimerEntry;
begin
  Result := PTimerEntry(FBackend.Dequeue);
end;

function TTimerSchedulerImpl.BackendCount: Integer;
begin
  Result := FBackend.Count;
end;

function TTimerSchedulerImpl.BackendPeek: PTimerEntry;
begin
  Result := PTimerEntry(FBackend.Peek);
end;

function TTimerSchedulerImpl.BackendIsEmpty: Boolean;
begin
  Result := FBackend.IsEmpty;
end;

destructor TTimerSchedulerImpl.Destroy;
var
  entry: PTimerEntry;
begin
  Shutdown;
  FThread.Free;
  // ✅ Phase 3.1: 使用后端接口清理未释放的条目
  FLock.Acquire;
  try
    while not FBackend.IsEmpty do
    begin
      entry := PTimerEntry(FBackend.Dequeue);
      if entry <> nil then
        Dispose(entry);
    end;
    FBackend.Clear;
  finally
    FLock.Release;
  end;
  FBackend := nil;  // ✅ 释放后端接口引用
  FCallbackPool := nil; // 释放线程池引用
  inherited Destroy;
end;

procedure TTimerSchedulerImpl.ThreadProc;
var
  nowI: TInstant;
  best: PTimerEntry;
  remain: TDuration;
  waitMs: Cardinal;
  cb: TTimerCallback;  // ✅ v2.0: 使用统一回调类型
  kind: TTimerKind;
  period, delay: TDuration;
  NextDeadline: TInstant;
  OldE: PTimerEntry;
  elapsedNs, missed: Int64;
begin
  // ✅ 显式初始化局部变量，避免未定义行为
  remain := TDuration.Zero;
  waitMs := 0;
  FillChar(cb, SizeOf(cb), 0);  // ✅ v2.0: 初始化回调记录
  best := nil;
  
  while not FShuttingDown do
  begin
    // 取堆顶（最早截止）的有效任务
    FLock.Acquire;
    try
      best := nil;
      while not BackendIsEmpty do  // ✅ Phase 3.1: 使用后端接口
      begin
        best := BackendPeek;  // ✅ Phase 3.1: 使用后端接口
        // ✅ v2.0: 添加 Paused 检查（暂停的定时器不应该被调度）
        if best^.Cancelled or best^.Paused or ((best^.Kind = tkOnce) and best^.Fired) then
        begin
          // 丢弃无效元素
          OldE := BackendPopMin;  // ✅ Phase 3.1: 使用后端接口
          if OldE <> nil then
          begin
            OldE^.InHeap := False;
            // 仅对 Cancelled/Fired 标记 Dead，Paused 不标记
            if not OldE^.Paused then
              OldE^.Dead := True;
            if (OldE^.RefCount <= 0) and OldE^.Dead then Dispose(OldE);
          end;
          best := nil;
          Continue;
        end;
        Break;
      end;

      if (best = nil) then
      begin
        // 无任务，等待唤醒或关闭
        FWakeup.ResetEvent;
      end
      else
      begin
        // 计算等待时间（若未到期）
        nowI := FClock.NowInstant;
        remain := best^.Deadline.Diff(nowI);
        if remain.IsNegative or remain.IsZero then
        begin
          // 到期：先取出任务参数并更新下一次触发/标记
          cb := best^.Callback;
          kind := best^.Kind;
          period := best^.Period;
          delay := best^.Delay;
          case kind of
            tkOnce:
              best^.Fired := True;
            tkFixedRate:
              begin
                // 追赶：推进至当前之后，统一用整除对齐，避免 O(k) 循环
                NextDeadline := best^.Deadline;
                elapsedNs := nowI.Diff(NextDeadline).AsNs;
                if elapsedNs >= 0 then
                begin
                  // 计算至少推进 1 个周期
                  if period.AsNs > 0 then
                  begin
                    missed := (elapsedNs div period.AsNs) + 1;
                    // 若设置了最大追赶步数，则仅推进至 limit，再一次性对齐最近倍数
                    if (GFixedRateMaxCatchupSteps > 0) and (missed > GFixedRateMaxCatchupSteps) then
                      missed := GFixedRateMaxCatchupSteps;
                    NextDeadline := NextDeadline.Add(period.Mul(missed));
                    // 若仍未超过 nowI（可能 limit 过小），则直接跳到 nowI 之后的最近整数倍
                    if not (NextDeadline > nowI) then
                    begin
                      elapsedNs := nowI.Diff(best^.Deadline).AsNs;
                      missed := (elapsedNs div period.AsNs) + 1;
                      NextDeadline := best^.Deadline.Add(period.Mul(missed));
                    end;
                  end
                  else
                    NextDeadline := nowI; // 防御
                end;
                best^.Deadline := NextDeadline;
              end;
            tkFixedDelay:
              ;
          end;
          // 弹出堆顶，让出锁后执行回调
          BackendPopMin;  // ✅ Phase 3.1: 使用后端接口
          // 固定延迟的下一次触发在回调后安排
        end
        else
        begin
          // 未到期：等待 remain 或被唤醒（有更早任务插入/取消/关闭）
          waitMs := remain.AsMs;
          if waitMs = 0 then waitMs := 1;
          FWakeup.ResetEvent;
        end;
      end;
    finally
      FLock.Release;
    end;

    if best = nil then
    begin
      // 无任务：阻塞等待唤醒或关闭（避免 10ms 轮询）
      FWakeup.Wait;
      Continue;
    end;

    // 如果到期，执行回调
    if (remain.IsNegative or remain.IsZero) then
    begin
      // 异步执行回调以提高定时器精度
      if FUseAsyncCallbacks and Assigned(FCallbackPool) then
        ExecuteCallbackAsync(cb, best, kind, delay)
      else
        ExecuteCallbackSync(cb, best, kind, delay);
      Continue;
    end;

    // 未到期：等待剩余时间或被唤醒
    FWakeup.WaitFor(waitMs);
    Continue;
  end;
end;

function TTimerSchedulerImpl.ScheduleOnce(const Delay: TDuration; const Callback: TProc): ITimer;
var
  dl: TInstant;
begin
  if Delay.IsNegative then
    dl := FClock.NowInstant
  else
    dl := FClock.NowInstant.Add(Delay);
  Result := ScheduleAt(dl, Callback);
end;

function TTimerSchedulerImpl.ScheduleAt(const Deadline: TInstant; const Callback: TProc): ITimer;
begin
  // ✅ v2.0: 向后兼容 - 转换为 TTimerCallback
  Result := DoScheduleAt(Deadline, TimerCallback(Callback), tkOnce, TDuration.Zero, TDuration.Zero);
end;

function TTimerSchedulerImpl.ScheduleAtFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): ITimer;
var dl: TInstant;
begin
  if Period.IsNegative or Period.IsZero then Exit(nil);
  if InitialDelay.IsNegative then dl := FClock.NowInstant else dl := FClock.NowInstant.Add(InitialDelay);
  // ✅ v2.0: 向后兼容 - 转换为 TTimerCallback
  Result := DoScheduleAt(dl, TimerCallback(Callback), tkFixedRate, Period, TDuration.Zero);
end;

function TTimerSchedulerImpl.ScheduleWithFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): ITimer;
var dl: TInstant;
begin
  if Delay.IsNegative or Delay.IsZero then Exit(nil);
  if InitialDelay.IsNegative then dl := FClock.NowInstant else dl := FClock.NowInstant.Add(InitialDelay);
  // ✅ v2.0: 向后兼容 - 转换为 TTimerCallback
  Result := DoScheduleAt(dl, TimerCallback(Callback), tkFixedDelay, TDuration.Zero, Delay);
end;

// ✅ v2.0: TTimerCallback 版本的 Schedule 方法
function TTimerSchedulerImpl.Schedule(const Delay: TDuration; const Callback: TTimerCallback): ITimer;
var dl: TInstant;
begin
  if Delay.IsNegative then
    dl := FClock.NowInstant
  else
    dl := FClock.NowInstant.Add(Delay);
  Result := ScheduleAtCb(dl, Callback);
end;

function TTimerSchedulerImpl.ScheduleAtCb(const Deadline: TInstant; const Callback: TTimerCallback): ITimer;
begin
  Result := DoScheduleAt(Deadline, Callback, tkOnce, TDuration.Zero, TDuration.Zero);
end;

function TTimerSchedulerImpl.ScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback): ITimer;
var dl: TInstant;
begin
  if Period.IsNegative or Period.IsZero then Exit(nil);
  if InitialDelay.IsNegative then dl := FClock.NowInstant else dl := FClock.NowInstant.Add(InitialDelay);
  Result := DoScheduleAt(dl, Callback, tkFixedRate, Period, TDuration.Zero);
end;

function TTimerSchedulerImpl.ScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback): ITimer;
var dl: TInstant;
begin
  if Delay.IsNegative or Delay.IsZero then Exit(nil);
  if InitialDelay.IsNegative then dl := FClock.NowInstant else dl := FClock.NowInstant.Add(InitialDelay);
  Result := DoScheduleAt(dl, Callback, tkFixedDelay, TDuration.Zero, Delay);
end;

// ✅ v2.0: 带取消令牌的调度方法
function TTimerSchedulerImpl.ScheduleWithToken(const Delay: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;
var dl: TInstant;
begin
  if Delay.IsNegative then
    dl := FClock.NowInstant
  else
    dl := FClock.NowInstant.Add(Delay);
  Result := DoScheduleAt(dl, Callback, tkOnce, TDuration.Zero, TDuration.Zero, Token);
end;

function TTimerSchedulerImpl.ScheduleFixedRateWithToken(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;
var dl: TInstant;
begin
  if Period.IsNegative or Period.IsZero then Exit(nil);
  if InitialDelay.IsNegative then dl := FClock.NowInstant else dl := FClock.NowInstant.Add(InitialDelay);
  Result := DoScheduleAt(dl, Callback, tkFixedRate, Period, TDuration.Zero, Token);
end;

function TTimerSchedulerImpl.ScheduleFixedDelayWithToken(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;
var dl: TInstant;
begin
  if Delay.IsNegative or Delay.IsZero then Exit(nil);
  if InitialDelay.IsNegative then dl := FClock.NowInstant else dl := FClock.NowInstant.Add(InitialDelay);
  Result := DoScheduleAt(dl, Callback, tkFixedDelay, TDuration.Zero, Delay, Token);
end;

function TTimerSchedulerImpl.TrySchedule(const Delay: TDuration; const Callback: TTimerCallback): TTimerResult;
var
  tm: ITimer;
begin
  tm := Schedule(Delay, Callback);
  if tm = nil then
    Result := TTimerResult.Err(tekShutdown)
  else
    Result := TTimerResult.Ok(tm);
end;

function TTimerSchedulerImpl.TrySchedule(const Delay: TDuration; const Callback: TProc): TTimerResult;
begin
  Result := TrySchedule(Delay, TimerCallback(TTimerProc(Callback)));
end;

function TTimerSchedulerImpl.TryScheduleAt(const Deadline: TInstant; const Callback: TProc): TTimerResult;
var
  tm: ITimer;
begin
  tm := ScheduleAt(Deadline, Callback);
  if tm = nil then
    Result := TTimerResult.Err(tekShutdown)
  else
    Result := TTimerResult.Ok(tm);
end;

function TTimerSchedulerImpl.TryScheduleAtCb(const Deadline: TInstant; const Callback: TTimerCallback): TTimerResult;
var
  tm: ITimer;
begin
  tm := ScheduleAtCb(Deadline, Callback);
  if tm = nil then
    Result := TTimerResult.Err(tekShutdown)
  else
    Result := TTimerResult.Ok(tm);
end;

function TTimerSchedulerImpl.TryScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback): TTimerResult;
var
  tm: ITimer;
begin
  if Period.IsNegative or Period.IsZero then
    Exit(TTimerResult.Err(tekInvalidArgument));

  tm := ScheduleFixedRate(InitialDelay, Period, Callback);
  if tm = nil then
    Result := TTimerResult.Err(tekShutdown)
  else
    Result := TTimerResult.Ok(tm);
end;

function TTimerSchedulerImpl.TryScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): TTimerResult;
begin
  Result := TryScheduleFixedRate(InitialDelay, Period, TimerCallback(TTimerProc(Callback)));
end;

function TTimerSchedulerImpl.TryScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback): TTimerResult;
var
  tm: ITimer;
begin
  if Delay.IsNegative or Delay.IsZero then
    Exit(TTimerResult.Err(tekInvalidArgument));

  tm := ScheduleFixedDelay(InitialDelay, Delay, Callback);
  if tm = nil then
    Result := TTimerResult.Err(tekShutdown)
  else
    Result := TTimerResult.Ok(tm);
end;

function TTimerSchedulerImpl.TryScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): TTimerResult;
begin
  Result := TryScheduleFixedDelay(InitialDelay, Delay, TimerCallback(TTimerProc(Callback)));
end;

// ✅ v2.0: 核心调度方法
function TTimerSchedulerImpl.DoScheduleAt(const Deadline: TInstant; const Callback: TTimerCallback; const AKind: TTimerKind; const Period, Delay: TDuration; const Token: ICancellationToken): ITimer;
var p: PTimerEntry;
begin
  // ✅ v2.0: 如果令牌已取消，直接返回 nil
  if (Token <> nil) and Token.IsCancellationRequested then
    Exit(nil);

  New(p);
  p^.Kind := AKind;
  p^.Deadline := Deadline;
  p^.Period := Period;
  p^.Delay := Delay;
  p^.Callback := Callback;
  p^.Cancelled := False;
  p^.Fired := False;
  p^.ExecutionCount := 0;  // ✅ v2.0: 初始化执行计数
  p^.MaxExecutions := 0;   // ✅ v2.0: 初始化最大执行次数（0=无限制）
  p^.Paused := False;      // ✅ v2.0: 初始化暂停状态
  p^.CancellationToken := Token;  // ✅ v2.0: 存储取消令牌
  p^.RefCount := 1;
  p^.Dead := False;
  p^.InHeap := False;

  AtomicIncScheduled;  // ✅ v2.0 优化: 原子计数替代锁

  FLock.Acquire;
  try
    if FShuttingDown then
    begin
      p^.CancellationToken := nil;  // ✅ 清除接口引用
      Dispose(p);
      Exit(nil);
    end;
    // ✅ ISSUE-REVIEW-P2-3: 检查 BackendInsert 返回值（容量满时返回 False）
    if not BackendInsert(p) then
    begin
      p^.CancellationToken := nil;
      Dispose(p);
      Exit(nil);
    end;
    if Assigned(FWakeup) then FWakeup.SetEvent;
  finally
    FLock.Release;
  end;
  Result := TTimerRef.Create(p, FLock);
end;

procedure TTimerSchedulerImpl.Shutdown;
var
  alreadyShutdown: Boolean;
begin
  // ✅ 使用锁保护 FShuttingDown 标志，避免竞态条件
  FLock.Acquire;
  try
    alreadyShutdown := FShuttingDown;
    if not alreadyShutdown then
      FShuttingDown := True;
  finally
    FLock.Release;
  end;
  
  // ✅ 幂等性：如果已经 shutdown，直接返回
  if alreadyShutdown then Exit;
  
  // 唤醒调度线程，使其尽快退出
  if Assigned(FWakeup) then 
    FWakeup.SetEvent;
  
  // ✅ 等待线程退出（不再需要超时，因为线程一定会检查 FShuttingDown 并退出）
  if Assigned(FThread) then
    FThread.WaitFor;
end;

procedure TTimerSchedulerImpl.SetCallbackExecutor(const Pool: IThreadPool);
begin
  FLock.Acquire;
  try
    FCallbackPool := Pool;
    FUseAsyncCallbacks := (Pool <> nil);
  finally
    FLock.Release;
  end;
end;

function TTimerSchedulerImpl.GetCallbackExecutor: IThreadPool;
begin
  FLock.Acquire;
  try
    Result := FCallbackPool;
  finally
    FLock.Release;
  end;
end;

// 同步执行回调（默认模式，向后兼容）
procedure TTimerSchedulerImpl.ExecuteCallbackSync(const cb: TTimerCallback; const best: PTimerEntry; const kind: TTimerKind; const delay: TDuration);
var
  handler: TTimerExceptionHandler;
begin
  // ✅ v2.0: 检查取消令牌
  if (best^.CancellationToken <> nil) and best^.CancellationToken.IsCancellationRequested then
  begin
    // 令牌已取消，跳过回调执行
    FLock.Acquire;
    try
      best^.Cancelled := True;
      best^.Dead := True;
      AtomicIncCancelled;
    finally
      FLock.Release;
    end;
    // 清理并退出
    if (best^.RefCount <= 0) and (not best^.InHeap) then
      Dispose(best);
    Exit;
  end;

  try
    ExecuteTimerCallback(cb);  // ✅ v2.0: 使用统一回调执行
    // ✅ v2.0: 增加执行计数并检查限制
    FLock.Acquire;
    try
      Inc(best^.ExecutionCount);
      // ✅ v2.0: 检查执行次数限制（仅周期定时器）
      if (kind <> tkOnce) and (best^.MaxExecutions > 0) and
         (best^.ExecutionCount >= best^.MaxExecutions) then
      begin
        best^.Cancelled := True;  // 达到限制，标记为取消
        best^.Dead := True;
        AtomicIncCancelled;
      end;
    finally
      FLock.Release;
    end;
    AtomicIncFired;  // ✅ v2.0 优化: 原子计数替代锁
  except
    on E: Exception do
    begin
      AtomicIncException;  // ✅ v2.0 优化: 原子计数替代锁

      // ✅ ISSUE-23: 使用局部变量复制 handler，避免在调用时持有锁
      handler := nil;
      if GTimerExceptionHandlerLock <> nil then
        GTimerExceptionHandlerLock.Acquire;
      try
        handler := GTimerExceptionHandler;
      finally
        if GTimerExceptionHandlerLock <> nil then
          GTimerExceptionHandlerLock.Release;
      end;

      // ✅ ISSUE-28: 如果没有设置 handler，使用默认 handler
      if Assigned(handler) then
        handler(E)
      else
        DefaultTimerExceptionHandler(E);
    end;
  end;
  
  // 固定延迟：回调完成后设定下一次触发
  if (kind = tkFixedDelay) then
  begin
    FLock.Acquire;
    try
      if (not best^.Cancelled) and (not FShuttingDown) then
      begin
        best^.Deadline := FClock.NowInstant.Add(delay);
        // ✅ ISSUE-REVIEW-P2-3: 检查 BackendInsert 返回值
        if BackendInsert(best) then
        begin
          if Assigned(FWakeup) then FWakeup.SetEvent;
        end
        else
        begin
          // 容量满，标记任务为 Dead
          best^.Dead := True;
          if (best^.RefCount <= 0) and (not best^.InHeap) then Dispose(best);
        end;
      end
      else
      begin
        best^.Dead := True;
        if (best^.RefCount <= 0) and (not best^.InHeap) then Dispose(best);
      end;
    finally
      FLock.Release;
    end;
  end
  else
  begin
    // fixedRate 回收到堆；once 不再回收
    if kind = tkFixedRate then
    begin
      FLock.Acquire;
      try
        if (not best^.Cancelled) and (not FShuttingDown) then
        begin
          // ✅ ISSUE-REVIEW-P2-3: 检查 BackendInsert 返回值
          if BackendInsert(best) then
          begin
            if Assigned(FWakeup) then FWakeup.SetEvent;
          end
          else
          begin
            // 容量满，标记任务为 Dead
            best^.Dead := True;
            if (best^.RefCount <= 0) and (not best^.InHeap) then Dispose(best);
          end;
        end
        else
        begin
          best^.Dead := True;
          if (best^.RefCount <= 0) and (not best^.InHeap) then Dispose(best);
        end;
      finally
        FLock.Release;
      end;
    end
    else
    begin
      // tkOnce：生命周期结束
      best^.Dead := True;
      if (best^.RefCount <= 0) and (not best^.InHeap) then Dispose(best);
    end;
  end;
end;

// 异步回调任务包装器
function AsyncCallbackTask(aData: Pointer): Boolean;
var
  ctx: PCallbackContext;
  sch: TTimerSchedulerImpl;
  entryToDispose: PTimerEntry;
  handler: TTimerExceptionHandler; // ✅ ISSUE-23: 局部变量复制 handler
  LNewRefCount: LongInt;  // ✅ ISSUE-REVIEW-P1-3: 原子操作结果
begin
  Result := False;
  if aData = nil then Exit;
  ctx := PCallbackContext(aData);
  entryToDispose := nil;

  try
    sch := TTimerSchedulerImpl(ctx^.Scheduler);

    // ✅ v2.0: 检查取消令牌
    if (ctx^.Entry^.CancellationToken <> nil) and ctx^.Entry^.CancellationToken.IsCancellationRequested then
    begin
      // 令牌已取消，跳过回调执行
      sch.FLock.Acquire;
      try
        ctx^.Entry^.Cancelled := True;
        ctx^.Entry^.Dead := True;
        // ✅ ISSUE-REVIEW-P1-3: 使用原子操作
        LNewRefCount := InterlockedDecrement(ctx^.Entry^.RefCount);
        AtomicIncCancelled;
        if (LNewRefCount <= 0) and (not ctx^.Entry^.InHeap) then
          entryToDispose := ctx^.Entry;
      finally
        sch.FLock.Release;
      end;
      if entryToDispose <> nil then
        Dispose(entryToDispose);
      Exit;
    end;

    try
      ExecuteTimerCallback(ctx^.Callback);  // ✅ v2.0: 使用统一回调执行
      // ✅ v2.0: 增加执行计数并检查限制
      sch.FLock.Acquire;
      try
        Inc(ctx^.Entry^.ExecutionCount);
        // ✅ v2.0: 检查执行次数限制（仅周期定时器）
        if (ctx^.Kind <> tkOnce) and (ctx^.Entry^.MaxExecutions > 0) and
           (ctx^.Entry^.ExecutionCount >= ctx^.Entry^.MaxExecutions) then
        begin
          ctx^.Entry^.Cancelled := True;  // 达到限制，标记为取消
          ctx^.Entry^.Dead := True;
          AtomicIncCancelled;
        end;
      finally
        sch.FLock.Release;
      end;
      AtomicIncFired;  // ✅ v2.0 优化: 原子计数替代锁
      Result := True;
    except
      on E: Exception do
      begin
        AtomicIncException;  // ✅ v2.0 优化: 原子计数替代锁

        // ✅ ISSUE-23: 使用局部变量复制 handler，避免在调用时持有锁
        handler := nil;
        if GTimerExceptionHandlerLock <> nil then
          GTimerExceptionHandlerLock.Acquire;
        try
          handler := GTimerExceptionHandler;
        finally
          if GTimerExceptionHandlerLock <> nil then
            GTimerExceptionHandlerLock.Release;
        end;

        // ✅ ISSUE-28: 如果没有设置 handler，使用默认 handler
        if Assigned(handler) then
          handler(E)
        else
          DefaultTimerExceptionHandler(E);
      end;
    end;
    
    // 固定延迟：回调完成后设定下一次触发
    if (ctx^.Kind = tkFixedDelay) then
    begin
      sch.FLock.Acquire;
      try
        // ✅ ISSUE-REVIEW-P1-3: 使用原子操作
        LNewRefCount := InterlockedDecrement(ctx^.Entry^.RefCount);

        if (not ctx^.Entry^.Cancelled) and (not sch.FShuttingDown) then
        begin
          ctx^.Entry^.Deadline := sch.FClock.NowInstant.Add(ctx^.Delay);
          // ✅ ISSUE-REVIEW-P2-3: 检查 BackendInsert 返回值
          if sch.BackendInsert(ctx^.Entry) then
          begin
            if Assigned(sch.FWakeup) then sch.FWakeup.SetEvent;
          end
          else
          begin
            // 容量满，标记任务为 Dead
            ctx^.Entry^.Dead := True;
            if (LNewRefCount <= 0) and (not ctx^.Entry^.InHeap) then
              entryToDispose := ctx^.Entry;
          end;
        end
        else
        begin
          ctx^.Entry^.Dead := True;
          if (LNewRefCount <= 0) and (not ctx^.Entry^.InHeap) then
            entryToDispose := ctx^.Entry; // 标记待释放，但在锁外释放
        end;
      finally
        sch.FLock.Release;
      end;
    end
    else
    begin
      // fixedRate 回收到堆；once 不再回收
      if ctx^.Kind = tkFixedRate then
      begin
        sch.FLock.Acquire;
        try
          // ✅ ISSUE-REVIEW-P1-3: 使用原子操作
          LNewRefCount := InterlockedDecrement(ctx^.Entry^.RefCount);

          if (not ctx^.Entry^.Cancelled) and (not sch.FShuttingDown) then
          begin
            // ✅ ISSUE-REVIEW-P2-3: 检查 BackendInsert 返回值
            if sch.BackendInsert(ctx^.Entry) then
            begin
              if Assigned(sch.FWakeup) then sch.FWakeup.SetEvent;
            end
            else
            begin
              // 容量满，标记任务为 Dead
              ctx^.Entry^.Dead := True;
              if (LNewRefCount <= 0) and (not ctx^.Entry^.InHeap) then
                entryToDispose := ctx^.Entry;
            end;
          end
          else
          begin
            ctx^.Entry^.Dead := True;
            if (LNewRefCount <= 0) and (not ctx^.Entry^.InHeap) then
              entryToDispose := ctx^.Entry; // 标记待释放，但在锁外释放
          end;
        finally
          sch.FLock.Release;
        end;
      end
      else
      begin
        // tkOnce：生命周期结束
        sch.FLock.Acquire;
        try
          // ✅ ISSUE-REVIEW-P1-3: 使用原子操作
          LNewRefCount := InterlockedDecrement(ctx^.Entry^.RefCount);

          ctx^.Entry^.Dead := True;
          if (LNewRefCount <= 0) and (not ctx^.Entry^.InHeap) then
            entryToDispose := ctx^.Entry; // 标记待释放，但在锁外释放
        finally
          sch.FLock.Release;
        end;
      end;
    end;
    
    // ✅ 在锁外释放内存，避免在持有锁时调用 Dispose
    if entryToDispose <> nil then
      Dispose(entryToDispose);
      
  finally
    // ✅ 保证无论如何都会释放上下文
    Dispose(ctx);
  end;
end;

// 异步执行回调（通过线程池）
procedure TTimerSchedulerImpl.ExecuteCallbackAsync(const cb: TTimerCallback; const best: PTimerEntry; const kind: TTimerKind; const delay: TDuration);
var
  ctx: PCallbackContext;
begin
  // 增加引用计数，防止回调期间 best 被释放
  FLock.Acquire;
  try
    // ✅ ISSUE-REVIEW-P1-3: 使用原子操作
    InterlockedIncrement(best^.RefCount);
  finally
    FLock.Release;
  end;

  // 创建上下文
  New(ctx);
  ctx^.Callback := cb;
  ctx^.Entry := best;
  ctx^.Kind := kind;
  ctx^.Delay := delay;
  ctx^.Scheduler := Self;
  ctx^.SchedulerRef := Self; // retain scheduler lifetime across async task

  // 提交到线程池
  try
    FCallbackPool.Submit(@AsyncCallbackTask, ctx);
  except
    // 如果提交失败（例如队列满且拒绝策略为 Abort），降级到同步执行
    on E: Exception do
    begin
      // 减少引用计数
      FLock.Acquire;
      try
        // ✅ ISSUE-REVIEW-P1-3: 使用原子操作
        InterlockedDecrement(best^.RefCount);
      finally
        FLock.Release;
      end;
      Dispose(ctx);
      // 降级到同步执行
      ExecuteCallbackSync(cb, best, kind, delay);
    end;
  end;
end;

function CreateTimerScheduler(const Clock: IMonotonicClock): ITimerScheduler;
begin
  Result := TTimerSchedulerImpl.Create(Clock);
end;

function CreateTimerScheduler(const Clock: IMonotonicClock; const CallbackPool: IThreadPool): ITimerScheduler;
begin
  Result := TTimerSchedulerImpl.Create(Clock, CallbackPool);
end;

function CreateTimerScheduler(const Options: TTimerSchedulerOptions): ITimerScheduler;
begin
  if Options.CallbackExecutor <> nil then
    Result := TTimerSchedulerImpl.Create(Options.Clock, Options.CallbackExecutor)
  else
    Result := TTimerSchedulerImpl.Create(Options.Clock);
end;


initialization
begin
  GMetricsLock := TMutex.Create;
  // ✅ ISSUE-23: 初始化异常处理器锁
  GTimerExceptionHandlerLock := TMutex.Create;
  // ✅ v2.0 优化: 初始化全局默认调度器锁
  GDefaultSchedulerLock := TMutex.Create;
end;

end.

