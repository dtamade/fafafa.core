unit fafafa.core.time.timer;

{$modeswitch advancedrecords}
{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.sync,
  fafafa.core.thread.threadpool;

type
  // Callback procedure type
  TProc = procedure;

  ITimer = interface
    ['{D9A1B6C6-0C1D-4A6E-9F2B-0AF4B7A3ED1B}']
    procedure Cancel;
    function IsCancelled: Boolean;
    // Reset/Reschedule（当前主要支持一次性定时器；周期定时器返回 False）
    function ResetAt(const Deadline: TInstant): Boolean;
    function ResetAfter(const Delay: TDuration): Boolean;
  end;

  ITimerScheduler = interface
    ['{2B7B9D2C-8F9B-4C4D-9C8E-7E83F7C994A4}']
    // 一次性
    function ScheduleOnce(const Delay: TDuration; const Callback: TProc): ITimer;
    function ScheduleAt(const Deadline: TInstant; const Callback: TProc): ITimer;
    // 周期
    function ScheduleAtFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): ITimer;
    function ScheduleWithFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): ITimer;
    // 控制
    procedure Shutdown;
    
    // 异步回调执行支持
    procedure SetCallbackExecutor(const Pool: IThreadPool);
    function GetCallbackExecutor: IThreadPool;
  end;

  ITicker = interface
    ['{7F9E3C3A-0D6E-4C0E-9B7F-2F58E4E8F1C2}']
    procedure Stop;
    function IsStopped: Boolean;
  end;

function CreateTickerFixedRate(const InitialDelay, Period: TDuration; const Callback: TProc; const Clock: IMonotonicClock = nil): ITicker;
function CreateTickerFixedDelay(const InitialDelay, Delay: TDuration; const Callback: TProc; const Clock: IMonotonicClock = nil): ITicker;
function CreateTickerFixedRateOn(const Scheduler: ITimerScheduler; const InitialDelay, Period: TDuration; const Callback: TProc): ITicker;
function CreateTickerFixedDelayOn(const Scheduler: ITimerScheduler; const InitialDelay, Delay: TDuration; const Callback: TProc): ITicker;

function CreateTimerScheduler(const Clock: IMonotonicClock = nil): ITimerScheduler; overload;
function CreateTimerScheduler(const Clock: IMonotonicClock; const CallbackPool: IThreadPool): ITimerScheduler; overload;

  // FixedRate 追赶步数上限（0 表示不限制）
  // ✅ ISSUE-24: 默认值改为 3，避免追赶风暴
var
  GFixedRateMaxCatchupSteps: Integer = 3;

  type
    TTimerExceptionHandler = procedure(const E: Exception);

  // 回调异常处理 Hook（可选）
  procedure SetTimerExceptionHandler(const H: TTimerExceptionHandler);
  function GetTimerExceptionHandler: TTimerExceptionHandler;

  procedure SetTimerFixedRateMaxCatchupSteps(const V: Integer);
var
  GTimerExceptionHandler: TTimerExceptionHandler = nil;

  type
    TTimerMetrics = record
      ScheduledTotal: QWord;
      FiredTotal: QWord;
      CancelledTotal: QWord;
      ExceptionTotal: QWord;
    end;

  procedure TimerResetMetrics;
  function TimerGetMetrics: TTimerMetrics;

  function GetTimerFixedRateMaxCatchupSteps: Integer;


implementation

var
  GMetrics: TTimerMetrics;
  GMetricsLock: ILock;
  // ✅ ISSUE-23: 为 GTimerExceptionHandler 添加锁保护
  GTimerExceptionHandlerLock: ILock;
  
// ✅ ISSUE-28: 默认异常处理器，输出到 stderr
procedure DefaultTimerExceptionHandler(const E: Exception);
begin
  WriteLn(ErrOutput, '[Timer Exception] ', E.ClassName, ': ', E.Message);
end;


type
  PTimerEntry = ^TTimerEntry;
  TTimerKind = (tkOnce, tkFixedRate, tkFixedDelay);

  TTimerEntry = record
    Kind: TTimerKind;
    Deadline: TInstant;
    Period: TDuration; // for FixedRate
    Delay: TDuration;  // for FixedDelay
    Callback: TProc;
    Cancelled: Boolean;
    Fired: Boolean; // for once; for periodic it indicates at least fired once
    // lifecycle safety
    RefCount: LongInt; // references held by TTimerRef or internal temporary holders
    Dead: Boolean;     // removed from scheduling permanently (fired once or cancelled)
    InHeap: Boolean;   // currently present in heap list
    HeapIndex: Integer; // index in heap/list; -1 when not in heap
    Owner: pointer;     // back-reference to scheduler (TTimerSchedulerImpl)
  end;

  TTimerRef = class(TInterfacedObject, ITimer)
  private
    FEntry: PTimerEntry;
    FLock: ILock;
  public
    constructor Create(AEntry: PTimerEntry; const Lock: ILock);
    destructor Destroy; override;
    procedure Cancel;
    function IsCancelled: Boolean;
    function ResetAt(const Deadline: TInstant): Boolean;
    function ResetAfter(const Delay: TDuration): Boolean;
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
    Callback: TProc;
    Entry: PTimerEntry;
    Kind: TTimerKind;
    Delay: TDuration;
    Scheduler: Pointer; // TTimerSchedulerImpl
  end;

  TTimerSchedulerImpl = class(TInterfacedObject, ITimerScheduler)
  private
    FClock: IMonotonicClock;
    FLock: ILock;
    FHeap: array of PTimerEntry; // bespoke binary min-heap
    FCount: Integer; // number of elements in heap
    FThread: TThread;
    FShuttingDown: Boolean;
    FWakeup: IEvent; // wake up timer thread on insert/cancel/shutdown
    
    // 异步回调执行支持
    FCallbackPool: IThreadPool; // 用于异步执行定时器回调
    FUseAsyncCallbacks: Boolean; // 是否启用异步回调
  private


    procedure HeapSwap(a, b: Integer);
    procedure HeapEnsureCap;
    procedure HeapInsert(e: PTimerEntry);
    procedure HeapRemoveAt(Index: Integer);
    procedure HeapUpdateKey(Index: Integer);
    procedure HeapifyUp(Index: Integer);
    procedure HeapifyDown(Index: Integer);
    function  HeapPopMinUnsafe: PTimerEntry; // FLock must be held
    procedure ThreadProc;
    procedure ExecuteCallbackSync(const cb: TProc; const best: PTimerEntry; const kind: TTimerKind; const delay: TDuration);
    procedure ExecuteCallbackAsync(const cb: TProc; const best: PTimerEntry; const kind: TTimerKind; const delay: TDuration);
  public
    constructor Create(const Clock: IMonotonicClock); overload;
    constructor Create(const Clock: IMonotonicClock; const CallbackPool: IThreadPool); overload;
    destructor Destroy; override;
    function ScheduleOnce(const Delay: TDuration; const Callback: TProc): ITimer;
    function ScheduleAt(const Deadline: TInstant; const Callback: TProc): ITimer;
    function ScheduleAtFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): ITimer;
    function ScheduleWithFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): ITimer;
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
  // 这避免了在 HeapInsert 之后、TTimerRef.Create 之前的竞态条件
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
      if GMetricsLock <> nil then GMetricsLock.Acquire;
      try Inc(GMetrics.CancelledTotal); finally if GMetricsLock <> nil then GMetricsLock.Release; end;
    end;
  finally
    FLock.Release;
  end;
end;

destructor TTimerRef.Destroy;
begin
  if FLock <> nil then FLock.Acquire;
  try
    if Assigned(FEntry) then
    begin
      Dec(FEntry^.RefCount);
      // 若已取消/一次性已触发且不在堆中，且计数为0，则释放
      if (FEntry^.RefCount <= 0) and (FEntry^.Dead) and (not FEntry^.InHeap) then
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
begin
  FLock.Acquire;
  try
    if (FEntry = nil) or FEntry^.Cancelled then Exit(False);
    if FEntry^.Kind <> tkOnce then Exit(False);
    if FEntry^.Fired then Exit(False);
    FEntry^.Deadline := Deadline;
    Result := True;
  finally
    FLock.Release;
  end;
end;

function TTimerRef.ResetAfter(const Delay: TDuration): Boolean;
begin
  Result := ResetAt(DefaultMonotonicClock.NowInstant.Add(Delay));
end;

function CreateTickerFixedRateOn(const Scheduler: ITimerScheduler; const InitialDelay, Period: TDuration; const Callback: TProc): ITicker;
var tm: ITimer;
begin
  if Scheduler = nil then Exit(nil);
  tm := Scheduler.ScheduleAtFixedRate(InitialDelay, Period, Callback);
  Result := TTicker.Create(Scheduler, tm);
end;

function CreateTickerFixedDelayOn(const Scheduler: ITimerScheduler; const InitialDelay, Delay: TDuration; const Callback: TProc): ITicker;
var tm: ITimer;
begin
  if Scheduler = nil then Exit(nil);
  tm := Scheduler.ScheduleWithFixedDelay(InitialDelay, Delay, Callback);
  Result := TTicker.Create(Scheduler, tm);
end;

function CreateTickerFixedRate(const InitialDelay, Period: TDuration; const Callback: TProc; const Clock: IMonotonicClock): ITicker;
var sch: ITimerScheduler;
begin
  sch := CreateTimerScheduler(Clock);
  Result := CreateTickerFixedRateOn(sch, InitialDelay, Period, Callback);
end;

function CreateTickerFixedDelay(const InitialDelay, Delay: TDuration; const Callback: TProc; const Clock: IMonotonicClock): ITicker;
var sch: ITimerScheduler;
begin
  sch := CreateTimerScheduler(Clock);
  Result := CreateTickerFixedDelayOn(sch, InitialDelay, Delay, Callback);
end;

procedure SetTimerFixedRateMaxCatchupSteps(const V: Integer);
begin
  if V < 0 then
    GFixedRateMaxCatchupSteps := 0
  else
    GFixedRateMaxCatchupSteps := V;
end;

function GetTimerFixedRateMaxCatchupSteps: Integer;
begin
  Result := GFixedRateMaxCatchupSteps;
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
  SetLength(FHeap, 0); FCount := 0;
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
  SetLength(FHeap, 0); FCount := 0;
  FShuttingDown := False;
  FWakeup := TEvent.Create(True, False);
  FCallbackPool := CallbackPool;
  FUseAsyncCallbacks := (CallbackPool <> nil);
  FThread := TTimerThread.Create(Self);
end;

procedure TTimerSchedulerImpl.HeapSwap(a, b: Integer);
var tmp: PTimerEntry;
begin
  if a = b then Exit;
  tmp := FHeap[a]; FHeap[a] := FHeap[b]; FHeap[b] := tmp;
  if FHeap[a] <> nil then FHeap[a]^.HeapIndex := a;
  if FHeap[b] <> nil then FHeap[b]^.HeapIndex := b;
end;

procedure TTimerSchedulerImpl.HeapEnsureCap;
var newCap: Integer;
begin
  if Length(FHeap) = 0 then SetLength(FHeap, 16)
  else if FCount >= Length(FHeap) then
  begin
    newCap := Length(FHeap) * 2;
    if newCap < 16 then newCap := 16;
    SetLength(FHeap, newCap);
  end;
end;

procedure TTimerSchedulerImpl.HeapInsert(e: PTimerEntry);
begin
  HeapEnsureCap;
  e^.HeapIndex := FCount;
  e^.InHeap := True;
  e^.Owner := Self;
  FHeap[FCount] := e;
  Inc(FCount);
  HeapifyUp(e^.HeapIndex);
end;

procedure TTimerSchedulerImpl.HeapifyUp(Index: Integer);
var i, p: Integer; a, b: PTimerEntry;
begin
  i := Index;
  while i > 0 do
  begin
    p := (i - 1) shr 1;
    a := FHeap[i]; b := FHeap[p];
    if (a = nil) or (b = nil) or (not a^.Deadline.LessThan(b^.Deadline)) then Break;
    HeapSwap(i, p);
    i := p;
  end;
end;



procedure TTimerSchedulerImpl.HeapifyDown(Index: Integer);
var i, l, r, smallest: Integer; a, leftE, rightE, smE: PTimerEntry;
begin
  i := Index;
  while True do
  begin
    l := (i shl 1) + 1; r := l + 1;
    smallest := i;
    if l < FCount then
    begin
      a := FHeap[i]; leftE := FHeap[l];
      if (leftE <> nil) and (a <> nil) and leftE^.Deadline.LessThan(a^.Deadline) then smallest := l;
    end;
    if r < FCount then
    begin
      smE := FHeap[smallest]; rightE := FHeap[r];
      if (rightE <> nil) and (smE <> nil) and rightE^.Deadline.LessThan(smE^.Deadline) then smallest := r;
    end;
    if smallest = i then Break;
    HeapSwap(i, smallest);
    i := smallest;
  end;
end;

function TTimerSchedulerImpl.HeapPopMinUnsafe: PTimerEntry;
begin
  if FCount = 0 then Exit(nil);
  Result := FHeap[0];
  Dec(FCount);
  if FCount > 0 then
  begin
    FHeap[0] := FHeap[FCount];
    if FHeap[0] <> nil then FHeap[0]^.HeapIndex := 0;
    FHeap[FCount] := nil;
    HeapifyDown(0);
  end
  else
    FHeap[0] := nil;
  if Result <> nil then
  begin
    Result^.InHeap := False;
    Result^.HeapIndex := -1;
  end;
end;


procedure TTimerSchedulerImpl.HeapRemoveAt(Index: Integer);
var last: Integer;
begin
  if (Index < 0) or (Index >= FCount) then Exit;
  last := FCount - 1;
  if Index <> last then
  begin
    HeapSwap(Index, last);
  end;
  Dec(FCount);
  FHeap[last] := nil;
  if Index < FCount then
  begin
    HeapifyDown(Index);
    HeapifyUp(Index);
  end;
end;

procedure TTimerSchedulerImpl.HeapUpdateKey(Index: Integer);
begin
  if (Index < 0) or (Index >= FCount) then Exit;
  HeapifyDown(Index);
  HeapifyUp(Index);
end;

destructor TTimerSchedulerImpl.Destroy;
begin
  Shutdown;
  FThread.Free;
  // 清理未释放的条目
  FLock.Acquire;
  try
    while FCount > 0 do
    begin
      Dispose(FHeap[0]);
      FHeap[0] := FHeap[FCount - 1];
      Dec(FCount);
      if FCount > 0 then HeapifyDown(0);
    end;
  finally
    FLock.Release;
  end;
  SetLength(FHeap, 0);
  FCallbackPool := nil; // 释放线程池引用
  inherited Destroy;
end;

procedure TTimerSchedulerImpl.ThreadProc;
var
  nowI: TInstant;
  best: PTimerEntry;
  remain: TDuration;
  waitMs: Cardinal;
  cb: TProc;
  kind: TTimerKind;
  period, delay: TDuration;
  NextDeadline: TInstant;
  OldE: PTimerEntry;
  elapsedNs, missed: Int64;
begin
  // ✅ 显式初始化局部变量，避免未定义行为
  remain := TDuration.Zero;
  waitMs := 0;
  cb := nil;
  best := nil;
  
  while not FShuttingDown do
  begin
    // 取堆顶（最早截止）的有效任务
    FLock.Acquire;
    try
      best := nil;
      while (FCount > 0) do
      begin
        best := FHeap[0];
        if best^.Cancelled or ((best^.Kind = tkOnce) and best^.Fired) then
        begin
          // 丢弃无效元素
          OldE := HeapPopMinUnsafe;
          if OldE <> nil then
          begin
            OldE^.InHeap := False;
            OldE^.Dead := True;
            if (OldE^.RefCount <= 0) then Dispose(OldE);
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
                    if not NextDeadline.GreaterThan(nowI) then
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
          HeapPopMinUnsafe;
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
      // 等待新任务或关闭信号
      if FWakeup.WaitFor(10) = wrTimeout then
        Continue
      else
        Continue;
    end;

    // 如果到期，执行回调
    if (remain.IsNegative or remain.IsZero) and Assigned(cb) then
    begin
      // 异步执行回调以提高定时器精度
      if FUseAsyncCallbacks and Assigned(FCallbackPool) then
        ExecuteCallbackAsync(cb, best, kind, delay)
      else
        ExecuteCallbackSync(cb, best, kind, delay);
      Continue;
    end
    else
    begin
      // 未到期：等待剩余时间或被唤醒
      if FWakeup.WaitFor(waitMs) = wrTimeout then
        Continue
      else
        Continue;
    end;
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
var
  p: PTimerEntry;
begin
  New(p);
  p^.Kind := tkOnce;
  p^.Deadline := Deadline;
  p^.Callback := Callback;
  p^.Cancelled := False;
  p^.Fired := False;
  // ✅ 初始 RefCount 为 1，代表即将创建的 TTimerRef 持有的引用
  // 这避免了在 HeapInsert 之后、TTimerRef.Create 之前的竞态条件
  p^.RefCount := 1; p^.Dead := False; p^.InHeap := False;
  if GMetricsLock <> nil then GMetricsLock.Acquire;
  try Inc(GMetrics.ScheduledTotal); finally if GMetricsLock <> nil then GMetricsLock.Release; end;
  
  FLock.Acquire;
  try
    // ✅ 检查是否已经 shutdown，如果是则拒绝调度
    if FShuttingDown then
    begin
      Dispose(p);
      Exit(nil);
    end;
    HeapInsert(p);
    if Assigned(FWakeup) then FWakeup.SetEvent;
  finally
    FLock.Release;
  end;
  // ✅ 在锁外创建 TTimerRef，因为 TTimerRef.Create 内部会获取锁
  Result := TTimerRef.Create(p, FLock);
end;


function TTimerSchedulerImpl.ScheduleAtFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): ITimer;
var p: PTimerEntry; dl: TInstant; per: TDuration;
begin
  if Period.IsNegative or Period.IsZero then Exit(nil);
  if InitialDelay.IsNegative then dl := FClock.NowInstant else dl := FClock.NowInstant.Add(InitialDelay);
  per := Period;
  New(p);
  p^.Kind := tkFixedRate;
  p^.Deadline := dl;
  p^.Period := per;
  p^.Delay := TDuration.Zero;
  p^.Callback := Callback;
  p^.Cancelled := False;
  p^.Fired := False;
  // ✅ 初始 RefCount 为 1，代表即将创建的 TTimerRef 持有的引用
  p^.RefCount := 1; p^.Dead := False; p^.InHeap := False;
  if GMetricsLock <> nil then GMetricsLock.Acquire;
  try Inc(GMetrics.ScheduledTotal); finally if GMetricsLock <> nil then GMetricsLock.Release; end;
  
  FLock.Acquire;
  try
    // ✅ 检查是否已经 shutdown
    if FShuttingDown then
    begin
      Dispose(p);
      Exit(nil);
    end;
    HeapInsert(p);
    if Assigned(FWakeup) then FWakeup.SetEvent;
  finally
    FLock.Release;
  end;
  // ✅ 在锁外创建 TTimerRef
  Result := TTimerRef.Create(p, FLock);
end;

function TTimerSchedulerImpl.ScheduleWithFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): ITimer;
var p: PTimerEntry; dl: TInstant; del: TDuration;
begin
  if Delay.IsNegative or Delay.IsZero then Exit(nil);
  if InitialDelay.IsNegative then dl := FClock.NowInstant else dl := FClock.NowInstant.Add(InitialDelay);
  del := Delay;
  New(p);
  p^.Kind := tkFixedDelay;
  p^.Deadline := dl;
  p^.Period := TDuration.Zero;
  p^.Delay := del;
  p^.Callback := Callback;
  p^.Cancelled := False;
  p^.Fired := False;
  // ✅ 初始 RefCount 为 1，代表即将创建的 TTimerRef 持有的引用
  p^.RefCount := 1; p^.Dead := False; p^.InHeap := False;
  if GMetricsLock <> nil then GMetricsLock.Acquire;
  try Inc(GMetrics.ScheduledTotal); finally if GMetricsLock <> nil then GMetricsLock.Release; end;
  
  FLock.Acquire;
  try
    // ✅ 检查是否已经 shutdown
    if FShuttingDown then
    begin
      Dispose(p);
      Exit(nil);
    end;
    HeapInsert(p);
    if Assigned(FWakeup) then FWakeup.SetEvent;
  finally
    FLock.Release;
  end;
  // ✅ 在锁外创建 TTimerRef
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
procedure TTimerSchedulerImpl.ExecuteCallbackSync(const cb: TProc; const best: PTimerEntry; const kind: TTimerKind; const delay: TDuration);
var
  handler: TTimerExceptionHandler;
begin
  try
    cb();
    if GMetricsLock <> nil then GMetricsLock.Acquire;
    try Inc(GMetrics.FiredTotal); finally if GMetricsLock <> nil then GMetricsLock.Release; end;
  except
    on E: Exception do
    begin
      if GMetricsLock <> nil then GMetricsLock.Acquire;
      try Inc(GMetrics.ExceptionTotal); finally if GMetricsLock <> nil then GMetricsLock.Release; end;
      
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
      if not best^.Cancelled then
      begin
        best^.Deadline := FClock.NowInstant.Add(delay);
        HeapInsert(best);
        if Assigned(FWakeup) then FWakeup.SetEvent;
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
        if not best^.Cancelled then
        begin
          HeapInsert(best);
          if Assigned(FWakeup) then FWakeup.SetEvent;
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
begin
  Result := False;
  if aData = nil then Exit;
  ctx := PCallbackContext(aData);
  entryToDispose := nil;
  
  try
    sch := TTimerSchedulerImpl(ctx^.Scheduler);
    
    try
      ctx^.Callback();
      if GMetricsLock <> nil then GMetricsLock.Acquire;
      try Inc(GMetrics.FiredTotal); finally if GMetricsLock <> nil then GMetricsLock.Release; end;
      Result := True;
    except
      on E: Exception do
      begin
        if GMetricsLock <> nil then GMetricsLock.Acquire;
        try Inc(GMetrics.ExceptionTotal); finally if GMetricsLock <> nil then GMetricsLock.Release; end;
        
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
        // ✅ 先递减引用计数
        Dec(ctx^.Entry^.RefCount);
        
        if not ctx^.Entry^.Cancelled then
        begin
          ctx^.Entry^.Deadline := sch.FClock.NowInstant.Add(ctx^.Delay);
          sch.HeapInsert(ctx^.Entry);
          if Assigned(sch.FWakeup) then sch.FWakeup.SetEvent;
        end
        else
        begin
          ctx^.Entry^.Dead := True;
          if (ctx^.Entry^.RefCount <= 0) and (not ctx^.Entry^.InHeap) then
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
          // ✅ 先递减引用计数
          Dec(ctx^.Entry^.RefCount);
          
          if not ctx^.Entry^.Cancelled then
          begin
            sch.HeapInsert(ctx^.Entry);
            if Assigned(sch.FWakeup) then sch.FWakeup.SetEvent;
          end
          else
          begin
            ctx^.Entry^.Dead := True;
            if (ctx^.Entry^.RefCount <= 0) and (not ctx^.Entry^.InHeap) then
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
          // ✅ 先递减引用计数
          Dec(ctx^.Entry^.RefCount);
          
          ctx^.Entry^.Dead := True;
          if (ctx^.Entry^.RefCount <= 0) and (not ctx^.Entry^.InHeap) then
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
procedure TTimerSchedulerImpl.ExecuteCallbackAsync(const cb: TProc; const best: PTimerEntry; const kind: TTimerKind; const delay: TDuration);
var
  ctx: PCallbackContext;
begin
  // 增加引用计数，防止回调期间 best 被释放
  FLock.Acquire;
  try
    Inc(best^.RefCount);
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
        Dec(best^.RefCount);
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


initialization
begin
  GMetricsLock := TMutex.Create;
  // ✅ ISSUE-23: 初始化异常处理器锁
  GTimerExceptionHandlerLock := TMutex.Create;
end;

end.

