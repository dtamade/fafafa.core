unit fafafa.core.thread.scheduler;

{**
 * fafafa.core.thread.scheduler - 任务调度器模块
 *
 * @desc 提供高级任务调度功能，包括：
 *       - ITaskScheduler 接口：任务调度的标准接口
 *       - TTaskScheduler 类：任务调度器实现
 *       - 支持延迟执行任务
 *       - 线程安全的调度管理
 *
 * @author fafafa.core 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.sync,
  {$IFDEF FAFAFA_THREAD_DEBUG}
  fafafa.core.thread.debuglog,
  {$ENDIF}
  fafafa.core.thread.future,
  fafafa.core.thread.threadpool,
  fafafa.core.thread.cancel,
  fafafa.core.time;

type

  {**
   * 任务调度器相关异常类型
   *}

  {**
   * EThreadError
   *
   * @desc 线程操作的基础异常类
   *}
  EThreadError = class(ECore);

  {**
   * ETaskSchedulerError
   *
   * @desc 任务调度器异常类
   *}
  ETaskSchedulerError = class(EThreadError);

  {**
   * 任务回调函数类型定义
   *}
  TTaskFunc = function(aData: Pointer): Boolean;
  TTaskMethod = function(aData: Pointer): Boolean of Object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TTaskRefFunc = reference to function(): Boolean;
  TTaskRefFunc1 = reference to function(Data: Pointer): Boolean;
  {$ENDIF}

  {**
   * 前向声明（避免循环依赖）
   *}


  {**
   * ITaskSchedulerMetrics
   * @desc 任务调度器指标视图（只读）
   *}
  ITaskSchedulerMetrics = interface
    ['{9D2E3C4B-5A6F-7081-92A3-B4C5D6E7F809}']
    function GetTotalScheduled: QWord;
    function GetTotalExecuted: QWord;
    function GetTotalCancelled: QWord;
    function GetActiveTasks: Integer;
    function GetAverageDelayMs: Double;
    function GetObservedAverageDelayMs: Double;
  end;

  {**
   * ITaskScheduler
   *
   * @desc 任务调度器接口
   *       支持延迟执行、定时执行、周期性执行等高级调度功能
   *}
  ITaskScheduler = interface
    ['{C6D7E8F9-A0B1-2C3D-4E5F-A6B7C8D9E0F1}']
    function GetMetrics: ITaskSchedulerMetrics;

    {** Schedule（返回 Future，可由调用者 Cancel 协作取消） **}
    function Schedule(ATask: TTaskFunc; ADelayMs: Cardinal; AData: Pointer = nil): IFuture; overload;
    function Schedule(ATask: TTaskMethod; ADelayMs: Cardinal; AData: Pointer = nil): IFuture; overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Schedule(const ATask: TTaskRefFunc; ADelayMs: Cardinal): IFuture; overload;
    function Schedule(const ATask: TTaskRefFunc1; ADelayMs: Cardinal; AData: Pointer = nil): IFuture; overload;
    {$ENDIF}

    // 协作式取消：支持 Token（若预取消则不入队）
    function Schedule(ATask: TTaskFunc; ADelayMs: Cardinal; const AToken: ICancellationToken; AData: Pointer = nil): IFuture; overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Schedule(const ATask: TTaskRefFunc; ADelayMs: Cardinal; const AToken: ICancellationToken): IFuture; overload;
    function Schedule(const ATask: TTaskRefFunc1; ADelayMs: Cardinal; const AToken: ICancellationToken; AData: Pointer = nil): IFuture; overload;
    {$ENDIF}

    // 注意：周期性任务功能暂时简化，专注于基础延迟执行功能

    procedure Shutdown;
    function IsShutdown: Boolean;
  end;

  {**
   * TTaskScheduler
   *
   * @desc 任务调度器实现类
   *       支持延迟执行、定时执行、周期性执行等高级调度功能
   *}
  TTaskScheduler = class(TInterfacedObject, ITaskScheduler)
  private
    type
      PScheduledItem = ^TScheduledItem;
      TScheduledItem = record
        DueAt: TInstant; // 单调时钟时点
        Kind: Integer; // 0=Func,1=Method,2=Ref
        Func: TTaskFunc;
        Method: TTaskMethod;
        {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
        Ref: TTaskRefFunc;
        Ref1: TTaskRefFunc1;
        {$ENDIF}
        Data: Pointer;
        Future: IFutureInternal;
        Token: ICancellationToken; // 协作式取消令牌（可选）
        Cancelled: Boolean;
      end;
  private
    FThreadPool: IThreadPool;
    FHeap: TList; // 简化小根堆：按 DueAt 升序维护
    FTimerThread: TThread;
    FShutdown: Boolean;
    FLock: ILock;

    // metrics
    FTotalScheduled: QWord;
    FTotalExecuted: QWord;
    FTotalCancelled: QWord;
    FActiveTasks: Integer;
    FTotalDelayMs: QWord; // 累计延迟，用于平均值
    // light observed delay metrics (disabled by default)
    FObsDelayTotalMs: QWord;
    FObsDelayCount: QWord;
    class var GObsMetricsEnabled: Boolean;



    procedure TimerLoop;
    // 小根堆操作封装
    procedure HeapSwap(I, J: Integer); inline;
    procedure HeapSiftUp(AIndex: Integer); inline;
    procedure HeapSiftDown(AIndex: Integer); inline;
    function HeapCount: Integer; inline;
    function HeapPeek: PScheduledItem; inline;
    function HeapPop(out AItem: PScheduledItem): Boolean; inline;
    procedure HeapRemoveAt(AIndex: Integer); inline;

    // 适配原有接口
    procedure PushItem(AItem: PScheduledItem);
    function PopDueItem(ANow: TInstant; out AItem: PScheduledItem): Boolean;
    function NextSleepMs(ANow: TInstant): Integer;

    procedure RemoveCancelledHeads;

    function GetMetrics: ITaskSchedulerMetrics;

  private type
    TTaskSchedulerMetrics = class(TInterfacedObject, ITaskSchedulerMetrics)
    private
      FOwner: TTaskScheduler;
    public
      constructor Create(AOwner: TTaskScheduler);
      function GetTotalScheduled: QWord;
      function GetTotalExecuted: QWord;
      function GetTotalCancelled: QWord;
      function GetActiveTasks: Integer;
      function GetAverageDelayMs: Double;
      function GetObservedAverageDelayMs: Double;
    end;
  public
    constructor Create;
    destructor Destroy; override;
    class procedure SetObservedMetricsEnabled(AEnabled: Boolean); static;

    function Schedule(ATask: TTaskFunc; ADelayMs: Cardinal; AData: Pointer = nil): IFuture; overload;
    function Schedule(ATask: TTaskMethod; ADelayMs: Cardinal; AData: Pointer = nil): IFuture; overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Schedule(const ATask: TTaskRefFunc; ADelayMs: Cardinal): IFuture; overload;
    function Schedule(const ATask: TTaskRefFunc1; ADelayMs: Cardinal; AData: Pointer = nil): IFuture; overload;
    {$ENDIF}

    // 带取消令牌的重载（与 ITaskScheduler 接口一致）
    function Schedule(ATask: TTaskFunc; ADelayMs: Cardinal; const AToken: ICancellationToken; AData: Pointer = nil): IFuture; overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Schedule(const ATask: TTaskRefFunc; ADelayMs: Cardinal; const AToken: ICancellationToken): IFuture; overload;
    function Schedule(const ATask: TTaskRefFunc1; ADelayMs: Cardinal; const AToken: ICancellationToken; AData: Pointer = nil): IFuture; overload;
    {$ENDIF}

    procedure Shutdown;
    function IsShutdown: Boolean;

  end;

implementation

{$IFDEF FAFAFA_SCHEDULER_DEBUG_LOG}
var
  __sched_log_f: Text;
  __sched_log_inited: Boolean = False;

procedure __sched_log(const S: string);
begin
  try
    if not __sched_log_inited then
    begin
      AssignFile(__sched_log_f, 'scheduler_debug.log');
      {$I-}Rewrite(__sched_log_f);{$I+}
      if IOResult <> 0 then Exit;
      __sched_log_inited := True;
    end;
    WriteLn(__sched_log_f, FormatDateTime('hh:nn:ss.zzz" "', Now) + S);
    Flush(__sched_log_f);
  except
    // ignore logging errors
  end;
end;
{$ENDIF}

{ TTaskScheduler }

procedure TTaskScheduler.TimerLoop;
var
  LItem: PScheduledItem;
  LNow: TInstant;
  LSleep: Integer;
  // 为提交阶段暂存的字段（避免在块内声明变量的语法问题）
  LKind: Integer;
  LFunc: TTaskFunc;
  LMethod: TTaskMethod;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  LRef: TTaskRefFunc;
  LRef1: TTaskRefFunc1;
  {$ENDIF}
  LData: Pointer;
  LUserFuture: IFutureInternal;
begin
  // 定时线程：10ms 粒度轮询 + 小根堆到期弹出
  // 初始化一次运行时开关（从环境变量，默认 false）
  if not GObsMetricsEnabled then
  begin
    try
      GObsMetricsEnabled := GetEnvironmentVariable('FAFAFA_SCHED_METRICS') = '1';
    except
      GObsMetricsEnabled := False;
    end;
  end;

  while True do
  begin
    // 每轮初始化，避免沿用上轮残值
    LItem := nil;
    LSleep := 0;
    // 退出条件
    FLock.Acquire;
    try
      if FShutdown then Exit;
      // 清理已取消的队首，避免其阻塞最近到期任务
      RemoveCancelledHeads;
      LNow := NowInstant;
      if PopDueItem(LNow, LItem) then
      begin
        // 准备执行
      end
      else
      begin
        // 计算下一次睡眠：根据最近到期任务动态调整
        LSleep := NextSleepMs(LNow);
      end;
    finally
      FLock.Release;
    end;

    if Assigned(LItem) then
    begin
      // 提交到线程池执行（若 Future 未取消），并在任务完成时再完成返回给用户的 Future
      // 为避免悬挂引用，先拷贝必要字段到局部变量（已在过程顶部定义变量）
      LKind := LItem^.Kind;
      LFunc := LItem^.Func;
      LMethod := LItem^.Method;
      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      LRef := LItem^.Ref;
      LRef1 := LItem^.Ref1;
      {$ENDIF}
      LData := LItem^.Data;
      LUserFuture := LItem^.Future;

      // 处理取消：如果此时已被取消，则计入取消指标并丢弃
      if Assigned(LUserFuture) and LUserFuture.IsCancelled then
      begin
        {$IFDEF DEBUG}__sched_log('item already cancelled');{$ENDIF}
        // 指标：取消 + 活跃数调整
        FLock.Acquire;
        try
          Inc(FTotalCancelled);
          if FActiveTasks > 0 then Dec(FActiveTasks);
        finally
          FLock.Release;
        end;
        LUserFuture.Fail(Exception.Create('Scheduled task cancelled'));
        Dispose(LItem);
        LItem := nil;
        LSleep := 0;
        Continue;
      end;
      // 若绑定了 Token，且此刻已请求取消，则计入取消指标并丢弃
      if (Assigned(LItem^.Token)) and LItem^.Token.IsCancellationRequested then
      begin
        FLock.Acquire;
        try
          Inc(FTotalCancelled);
          if FActiveTasks > 0 then Dec(FActiveTasks);
        finally
          FLock.Release;
        end;
        if Assigned(LUserFuture) then LUserFuture.Cancel;
        Dispose(LItem);
        LItem := nil;
        LSleep := 0;
        Continue;
      end;

      // 统计：将要调度的任务执行计入执行次数；活跃任务减一
      FLock.Acquire;
      try
        Inc(FTotalExecuted);
        if FActiveTasks > 0 then Dec(FActiveTasks);
        // 轻量观测：记录实际延迟（仅在开关启用时）
        if GObsMetricsEnabled then
        begin
          if LNow >= LItem^.DueAt then
          begin
            Inc(FObsDelayTotalMs, LNow.Diff(LItem^.DueAt).AsMs);
            Inc(FObsDelayCount);
          end;
        end;
      finally
        FLock.Release;
      end;

      Dispose(LItem);
      LItem := nil;

      if FThreadPool = nil then
        FThreadPool := TThreadPool.Create(1, 1, 60000);

      case LKind of
        0: // 全局函数
          FThreadPool.Submit(function: Boolean
          var Ok: Boolean;
          begin
            try
              if Assigned(LFunc) then
                Ok := LFunc(LData)
              else
                Ok := True;
              if Assigned(LUserFuture) then
              begin
                if Ok then LUserFuture.Complete
                else LUserFuture.Fail(Exception.Create('Task returned False'));
              end;
              Result := Ok;
            except
              on E: Exception do
              begin
                if Assigned(LUserFuture) then LUserFuture.Fail(E);
                Result := False;
              end;
            end;
          end);
        1: // 对象方法
          FThreadPool.Submit(function: Boolean
          var Ok: Boolean;
          begin
            try
              if Assigned(LMethod) then
                Ok := LMethod(LData)
              else
                Ok := True;
              if Assigned(LUserFuture) then
              begin
                if Ok then LUserFuture.Complete
                else LUserFuture.Fail(Exception.Create('Task returned False'));
              end;
              Result := Ok;
            except
              on E: Exception do
              begin
                if Assigned(LUserFuture) then LUserFuture.Fail(E);
                Result := False;
              end;
            end;
          end);
        {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
        2: // 匿名函数
          FThreadPool.Submit(function: Boolean
          var Ok: Boolean;
          begin
            try
              if Assigned(LRef) then
                Ok := LRef()
              else
                Ok := True;
              if Assigned(LUserFuture) then
              begin
                if Ok then LUserFuture.Complete
                else LUserFuture.Fail(Exception.Create('Task returned False'));
              end;
              Result := Ok;
            except
              on E: Exception do
              begin
                if Assigned(LUserFuture) then LUserFuture.Fail(E);
                Result := False;
              end;
            end;
          end);
        {$ENDIF}
        3: // 带参数的匿名函数
          FThreadPool.Submit(function: Boolean
          var Ok: Boolean;
          begin
            try
              if Assigned(LRef1) then
                Ok := LRef1(LData)
              else
                Ok := True;
              if Assigned(LUserFuture) then
              begin
                if Ok then LUserFuture.Complete
                else LUserFuture.Fail(Exception.Create('Task returned False'));
              end;
              Result := Ok;
            except
              on E: Exception do
              begin
                if Assigned(LUserFuture) then LUserFuture.Fail(E);
                Result := False;
              end;
            end;
          end);
      end;

      {$IFDEF DEBUG}__sched_log('dispatched');{$ENDIF}
      LSleep := 0;
    end;

    if LSleep > 0 then
      SysUtils.Sleep(LSleep)
    else
    begin
      // watchdog：NextSleepMs=0 且无任务，避免无尽空转
      {$IFDEF FAFAFA_SCHEDULER_DEBUG_LOG}__sched_log('watchdog: zero sleep -> sleep(10)');{$ENDIF}
      SysUtils.Sleep(10);
    end;
  end;
end;

procedure TTaskScheduler.PushItem(AItem: PScheduledItem);
begin
  // 小根堆：插入末尾并上滤
  FHeap.Add(AItem);
  HeapSiftUp(FHeap.Count - 1);
end;

procedure TTaskScheduler.HeapSwap(I, J: Integer);
var
  T: Pointer;
begin
  T := FHeap[I];
  FHeap[I] := FHeap[J];
  FHeap[J] := T;
end;

function TTaskScheduler.HeapCount: Integer;
begin
  Result := FHeap.Count;
end;

function TTaskScheduler.HeapPeek: PScheduledItem;
begin
  if FHeap.Count = 0 then Exit(nil);
  Result := PScheduledItem(FHeap[0]);
end;

procedure TTaskScheduler.HeapSiftUp(AIndex: Integer);
var
  P: Integer;
  Cur, Par: PScheduledItem;
begin
  while AIndex > 0 do
  begin
    P := (AIndex - 1) div 2;
    Cur := PScheduledItem(FHeap[AIndex]);
    Par := PScheduledItem(FHeap[P]);
    if Cur^.DueAt < Par^.DueAt then
    begin
      HeapSwap(AIndex, P);
      AIndex := P;
    end
    else
      Break;
  end;
end;

procedure TTaskScheduler.HeapSiftDown(AIndex: Integer);
var
  N, L, R, S: Integer;
  Cur, Left, Right, Smallest: PScheduledItem;
begin
  N := FHeap.Count;
  while True do
  begin
    L := 2 * AIndex + 1;
    R := L + 1;
    S := AIndex;
    if L < N then
    begin
      if PScheduledItem(FHeap[L])^.DueAt < PScheduledItem(FHeap[S])^.DueAt then S := L;
    end;
    if R < N then
    begin
      if PScheduledItem(FHeap[R])^.DueAt < PScheduledItem(FHeap[S])^.DueAt then S := R;
    end;
    if S = AIndex then Break;
    HeapSwap(AIndex, S);
    AIndex := S;
  end;
end;

function TTaskScheduler.HeapPop(out AItem: PScheduledItem): Boolean;
begin
  AItem := nil;
  Result := False;
  if FHeap.Count = 0 then Exit;
  AItem := PScheduledItem(FHeap[0]);
  // 尾元素放顶并下滤
  FHeap[0] := FHeap[FHeap.Count - 1];
  FHeap.Delete(FHeap.Count - 1);
  if FHeap.Count > 0 then HeapSiftDown(0);
  Result := True;

end;
procedure TTaskScheduler.HeapRemoveAt(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FHeap.Count) then Exit;
  // 用堆尾覆盖并下滤/上滤
  FHeap[AIndex] := FHeap[FHeap.Count - 1];
  FHeap.Delete(FHeap.Count - 1);
  if AIndex < FHeap.Count then
  begin
    HeapSiftDown(AIndex);
    HeapSiftUp(AIndex);
  end;
end;



function TTaskScheduler.PopDueItem(ANow: TInstant; out AItem: PScheduledItem): Boolean;
var
  Top: PScheduledItem;
begin
  AItem := nil;
  Result := False;
  Top := HeapPeek;
  if Top = nil then Exit;
  if Top^.DueAt <= ANow then
  begin
    Result := HeapPop(AItem);
  end;
end;

function TTaskScheduler.NextSleepMs(ANow: TInstant): Integer;
var
  LItem: PScheduledItem;
  remain: TDuration;
begin
  // 清理队首已取消的任务，避免无效等待
  RemoveCancelledHeads;

  if HeapCount = 0 then
    Exit(10); // 默认 10ms 粒度
  LItem := HeapPeek;
  if (LItem <> nil) and (LItem^.DueAt <= ANow) then
    Exit(0);
  if LItem = nil then Exit(10);
  remain := LItem^.DueAt.Diff(ANow);
  if remain.IsNegative or remain.IsZero then Exit(0);
  if remain.AsMs > 100 then
    Result := 100
  else
    Result := Integer(remain.AsMs);
end;

procedure TTaskScheduler.RemoveCancelledHeads;
var
  I: Integer;
  P: PScheduledItem;
begin
  // 扫描整个堆，移除所有已取消的任务，避免它们长期占位影响指标与最早到期计算
  I := 0;
  while I < HeapCount do
  begin
    P := PScheduledItem(FHeap[I]);
    if Assigned(P^.Future) and P^.Future.IsCancelled then
    begin
      Inc(FTotalCancelled);
      if FActiveTasks > 0 then Dec(FActiveTasks);
      HeapRemoveAt(I);
      Dispose(P);
      Continue; // 留在当前位置，因为已放入新元素
    end;
    Inc(I);
  end;
end;

constructor TTaskScheduler.Create;
begin
  inherited Create;
  FThreadPool := nil;
  FHeap := TList.Create;
  FShutdown := False;
  FLock := TMutex.Create;
  // metrics 初始化
  FTotalScheduled := 0;
  FTotalExecuted := 0;
  FTotalCancelled := 0;
  FActiveTasks := 0;
  FTotalDelayMs := 0;
  FObsDelayTotalMs := 0;
  FObsDelayCount := 0;
  {$IFDEF FAFAFA_SCHEDULER_DEBUG_LOG}__sched_log('scheduler create');{$ENDIF}
  // 后台定时线程
  FTimerThread := TThread.CreateAnonymousThread(@TimerLoop);
  {$IFDEF FAFAFA_SCHEDULER_DEBUG_LOG}__sched_log('timer thread created');{$ENDIF}
  FTimerThread.Start;
  {$IFDEF FAFAFA_SCHEDULER_DEBUG_LOG}__sched_log('timer thread started');{$ENDIF}
end;

destructor TTaskScheduler.Destroy;
begin
  // Shutdown 内已等待定时线程退出
  Shutdown;
  FreeAndNil(FHeap);
  FLock := nil;
  inherited Destroy;
end;

function TTaskScheduler.Schedule(ATask: TTaskFunc; ADelayMs: Cardinal; AData: Pointer): IFuture;
var
  LItem: PScheduledItem;
  LFuture: TFuture;
  LDue: TInstant;
  LNow: TInstant;
begin
  FLock.Acquire;
  try
    if FShutdown then
      raise ETaskSchedulerError.Create('任务调度器已关闭');

    New(LItem);
    LNow := NowInstant;
    LDue := LNow.Add(TDuration.FromMs(ADelayMs));
    LItem^.DueAt := LDue;
    LItem^.Kind := 0;
    LItem^.Func := ATask;
    LItem^.Method := nil;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    LItem^.Ref := nil;
    {$ENDIF}
    LItem^.Data := AData;
    LFuture := TFuture.Create;
    LItem^.Future := LFuture;
    LItem^.Token := nil;
    // metrics：提交 + 活跃 + 延迟累计
    Inc(FTotalScheduled);
    Inc(FActiveTasks);
    if ADelayMs > 0 then Inc(FTotalDelayMs, ADelayMs);

    LItem^.Cancelled := False;

    PushItem(LItem);
    Result := LFuture;
  finally
    FLock.Release;
  end;
end;

function TTaskScheduler.Schedule(ATask: TTaskMethod; ADelayMs: Cardinal; AData: Pointer): IFuture;
var
  LItem: PScheduledItem;
  LFuture: TFuture;
begin
  FLock.Acquire;
  try
    if FShutdown then
      raise ETaskSchedulerError.Create('任务调度器已关闭');

    New(LItem);
    LItem^.DueAt := NowInstant.Add(TDuration.FromMs(ADelayMs));
    LItem^.Kind := 1;
    LItem^.Func := nil;
    LItem^.Method := ATask;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    LItem^.Ref := nil;
    {$ENDIF}
    LItem^.Data := AData;
    LFuture := TFuture.Create;
    LItem^.Future := LFuture;
    LItem^.Token := nil;
    LItem^.Cancelled := False;
    PushItem(LItem);
    // metrics：提交 + 活跃 + 延迟累计
    Inc(FTotalScheduled);
    Inc(FActiveTasks);
    if ADelayMs > 0 then Inc(FTotalDelayMs, ADelayMs);

    Result := LFuture;
  finally
    FLock.Release;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TTaskScheduler.Schedule(const ATask: TTaskRefFunc; ADelayMs: Cardinal): IFuture;
var
  LItem: PScheduledItem;
  LFuture: TFuture;
begin
  FLock.Acquire;
  try
    if FShutdown then
      raise ETaskSchedulerError.Create('任务调度器已关闭');

    New(LItem);
    LItem^.DueAt := NowInstant.Add(TDuration.FromMs(ADelayMs));
    LItem^.Kind := 2;
    LItem^.Func := nil;
    LItem^.Method := nil;
    LItem^.Ref1 := nil;
    // metrics：提交 + 活跃 + 延迟累计
    Inc(FTotalScheduled);
    Inc(FActiveTasks);
    if ADelayMs > 0 then Inc(FTotalDelayMs, ADelayMs);

    LItem^.Ref := ATask;
    LItem^.Data := nil;
    LFuture := TFuture.Create;
    LItem^.Future := LFuture;
    LItem^.Token := nil;
    LItem^.Cancelled := False;
    PushItem(LItem);
    Result := LFuture;
  finally
    FLock.Release;
  end;
end;

function TTaskScheduler.Schedule(const ATask: TTaskRefFunc1; ADelayMs: Cardinal; AData: Pointer): IFuture;
var
  LItem: PScheduledItem;
  LFuture: TFuture;
begin
  FLock.Acquire;
  try
    if FShutdown then
      raise ETaskSchedulerError.Create('任务调度器已关闭');

    New(LItem);
    LItem^.DueAt := NowInstant.Add(TDuration.FromMs(ADelayMs));
    LItem^.Kind := 3;
    LItem^.Func := nil;
    LItem^.Method := nil;
    LItem^.Ref := nil;
    LItem^.Ref1 := ATask;
    LItem^.Data := AData;
    LFuture := TFuture.Create;
    LItem^.Future := LFuture;
    LItem^.Token := nil;
    LItem^.Cancelled := False;
    // metrics：提交 + 活跃 + 延迟累计
    Inc(FTotalScheduled);
    Inc(FActiveTasks);
    if ADelayMs > 0 then Inc(FTotalDelayMs, ADelayMs);
    PushItem(LItem);
    Result := LFuture;
  finally
    FLock.Release;
  end;
end;

{$ENDIF}



procedure TTaskScheduler.Shutdown;
var
  I: Integer;
  P: PScheduledItem;
  LItems: TList;
begin
  // 第一步：在锁内置关闭标志，避免新提交；然后在锁外等待后台线程退出
  FLock.Acquire;
  try
    if FShutdown then Exit;
    FShutdown := True;
  finally
    FLock.Release;
  end;

  // 等待定时线程自然退出，确保不再并发访问堆
  if Assigned(FTimerThread) then
    FTimerThread.WaitFor;

  // 第二步：现在无并发，安全清理未到期任务并失败其 Future
  if Assigned(FHeap) then
  begin
    for I := 0 to FHeap.Count - 1 do
    begin
      P := PScheduledItem(FHeap[I]);
      if Assigned(P) then
      begin
        if Assigned(P^.Future) then
        begin
          P^.Future.Fail(Exception.Create('Scheduler shutdown'));
          Inc(FTotalCancelled);
          if FActiveTasks > 0 then Dec(FActiveTasks);
        end;
        Dispose(P);
      end;
    end;
    FHeap.Clear;
  end;
end;

function TTaskScheduler.GetMetrics: ITaskSchedulerMetrics;
var
  L: TTaskSchedulerMetrics;
begin
  // 返回当前计数的只读快照（避免调用端持有内部引用）
  L := TTaskSchedulerMetrics.Create(Self);
  Result := L;
end;


function TTaskScheduler.Schedule(ATask: TTaskFunc; ADelayMs: Cardinal; const AToken: ICancellationToken; AData: Pointer): IFuture;
var
  LFutureObj: TFuture;
  LItem: PScheduledItem;
  LNow: TInstant;
begin
  if Assigned(AToken) and AToken.IsCancellationRequested then Exit(nil);
  // 创建任务并绑定 Token，后续若 Token 被取消，CancelWatcher 将取消 Future
  Result := nil;
  FLock.Acquire;
  try
    if FShutdown then
      raise ETaskSchedulerError.Create('任务调度器已关闭');
    New(LItem);
    LNow := NowInstant;
    LItem^.DueAt := LNow.Add(TDuration.FromMs(ADelayMs));
    LItem^.Kind := 0;
    LItem^.Func := ATask;
    LItem^.Method := nil;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    LItem^.Ref := nil;
    {$ENDIF}
    LItem^.Data := AData;
    LItem^.Token := AToken;
    // 创建 Future 对象并以内部接口保存，避免不安全的类/接口强转
    LFutureObj := TFuture.Create;
    LItem^.Future := LFutureObj; // implicit cast to IFutureInternal
    Inc(FTotalScheduled);
    Inc(FActiveTasks);
    if ADelayMs > 0 then Inc(FTotalDelayMs, ADelayMs);
    LItem^.Cancelled := False;
    PushItem(LItem);
    // 返回给调用方的 IFuture 引用
    Result := LFutureObj;
  finally
    FLock.Release;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TTaskScheduler.Schedule(const ATask: TTaskRefFunc; ADelayMs: Cardinal; const AToken: ICancellationToken): IFuture;
var
  LFutureObj: TFuture;
  LItem: PScheduledItem;
  LNow: TInstant;
begin
  if Assigned(AToken) and AToken.IsCancellationRequested then Exit(nil);
  Result := nil;
  FLock.Acquire;
  try
    if FShutdown then
      raise ETaskSchedulerError.Create('任务调度器已关闭');
    New(LItem);
    LNow := NowInstant;
    LItem^.DueAt := LNow.Add(TDuration.FromMs(ADelayMs));
    LItem^.Kind := 2;
    LItem^.Func := nil;
    LItem^.Method := nil;
    LItem^.Ref1 := nil;
    LItem^.Ref := ATask;
    LItem^.Data := nil;
    LItem^.Token := AToken;
    LFutureObj := TFuture.Create;
    LItem^.Future := LFutureObj;
    Inc(FTotalScheduled);
    Inc(FActiveTasks);
    if ADelayMs > 0 then Inc(FTotalDelayMs, ADelayMs);
    LItem^.Cancelled := False;
    PushItem(LItem);
    Result := LFutureObj;
  finally
    FLock.Release;
  end;
end;

function TTaskScheduler.Schedule(const ATask: TTaskRefFunc1; ADelayMs: Cardinal; const AToken: ICancellationToken; AData: Pointer): IFuture;
var
  LFutureObj: TFuture;
  LItem: PScheduledItem;
  LNow: TInstant;
begin
  if Assigned(AToken) and AToken.IsCancellationRequested then Exit(nil);
  Result := nil;
  FLock.Acquire;
  try
    if FShutdown then
      raise ETaskSchedulerError.Create('任务调度器已关闭');
    New(LItem);
    LNow := NowInstant;
    LItem^.DueAt := LNow.Add(TDuration.FromMs(ADelayMs));
    LItem^.Kind := 3;
    LItem^.Func := nil;
    LItem^.Method := nil;
    LItem^.Ref := nil;
    LItem^.Ref1 := ATask;
    LItem^.Data := AData;
    LItem^.Token := AToken;
    LFutureObj := TFuture.Create;
    LItem^.Future := LFutureObj;
    Inc(FTotalScheduled);
    Inc(FActiveTasks);
    if ADelayMs > 0 then Inc(FTotalDelayMs, ADelayMs);
    LItem^.Cancelled := False;
    PushItem(LItem);
    Result := LFutureObj;
  finally
    FLock.Release;
  end;
end;
{$ENDIF}


{ TTaskSchedulerMetrics }

constructor TTaskScheduler.TTaskSchedulerMetrics.Create(AOwner: TTaskScheduler);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TTaskScheduler.TTaskSchedulerMetrics.GetActiveTasks: Integer;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FActiveTasks;
  finally
    FOwner.FLock.Release;
  end;
end;

function TTaskScheduler.TTaskSchedulerMetrics.GetAverageDelayMs: Double;
var
  LTotal: QWord;
  LCount: QWord;
begin
  FOwner.FLock.Acquire;
  try
    LTotal := FOwner.FTotalDelayMs;
    LCount := FOwner.FTotalScheduled;
  finally
    FOwner.FLock.Release;
  end;
  if LCount = 0 then Exit(0.0);
  Result := LTotal / LCount;
end;

function TTaskScheduler.TTaskSchedulerMetrics.GetTotalCancelled: QWord;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTotalCancelled;
  finally
    FOwner.FLock.Release;
  end;
end;

function TTaskScheduler.TTaskSchedulerMetrics.GetTotalExecuted: QWord;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTotalExecuted;
  finally
    FOwner.FLock.Release;
  end;
end;

function TTaskScheduler.TTaskSchedulerMetrics.GetObservedAverageDelayMs: Double;
var
  LTotal: QWord;
  LCount: QWord;
begin
  FOwner.FLock.Acquire;
  try
    LTotal := FOwner.FObsDelayTotalMs;
    LCount := FOwner.FObsDelayCount;
  finally
    FOwner.FLock.Release;
  end;
  if LCount = 0 then Exit(0.0);
  Result := LTotal / LCount;
end;

class procedure TTaskScheduler.SetObservedMetricsEnabled(AEnabled: Boolean);
begin
  GObsMetricsEnabled := AEnabled;
end;

function TTaskScheduler.TTaskSchedulerMetrics.GetTotalScheduled: QWord;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTotalScheduled;
  finally
    FOwner.FLock.Release;
  end;
end;


function TTaskScheduler.IsShutdown: Boolean;
begin
  FLock.Acquire;
  try
    Result := FShutdown;
  finally
    FLock.Release;
  end;
end;

end.
