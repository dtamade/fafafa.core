unit fafafa.core.async.runtime;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, SyncObjs, DateUtils,
  fafafa.core.base,
  fafafa.core.thread.types,
  fafafa.core.thread.future,
  fafafa.core.thread.pool;

type
  // 事件循环状态
  TEventLoopState = (elsIdle, elsRunning, elsShutdown);
  
  // 异步任务项
  TAsyncTaskItem = class
  private
    FTask: TThreadMethod;
    FScheduledTime: TDateTime;
    FPriority: Integer;
  public
    constructor Create(const Task: TThreadMethod; ScheduledTime: TDateTime = 0; Priority: Integer = 0);
    
    property Task: TThreadMethod read FTask;
    property ScheduledTime: TDateTime read FScheduledTime;
    property Priority: Integer read FPriority;
  end;

  // 异步调度器
  TAsyncScheduler = class
  private
    FTaskQueue: TThreadSafeQueue<TAsyncTaskItem>;
    FTimerQueue: TThreadSafeQueue<TAsyncTaskItem>;
    FLock: TCriticalSection;
    FEvent: TEvent;
    
    procedure ProcessTimerQueue;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Schedule(const Task: TThreadMethod; Priority: Integer = 0);
    procedure ScheduleDelayed(const Task: TThreadMethod; DelayMs: Cardinal; Priority: Integer = 0);
    procedure ScheduleAt(const Task: TThreadMethod; ScheduledTime: TDateTime; Priority: Integer = 0);
    
    function HasPendingTasks: Boolean;
    function GetNextTask: TAsyncTaskItem;
    procedure ProcessPendingTasks;
    
    procedure WakeUp;
    procedure WaitForTasks(TimeoutMs: Cardinal = 100);
  end;

  // 异步运行时
  TAsyncRuntime = class
  private
    class var FInstance: TAsyncRuntime;
    class var FLock: TCriticalSection;
    
    FScheduler: TAsyncScheduler;
    FThreadPool: IThreadPool;
    FState: TEventLoopState;
    FMainThread: TThread;
    FShutdownEvent: TEvent;
    FRunning: Boolean;
    
    constructor Create;
    destructor Destroy; override;
    
    procedure EventLoopProc;
    procedure ProcessEvents;
  public
    class function Instance: TAsyncRuntime;
    class procedure Initialize;
    class procedure Finalize;
    
    procedure Run;
    procedure RunOnce;
    procedure Shutdown;
    procedure Stop;
    
    function IsRunning: Boolean;
    function IsMainThread: Boolean;
    
    // 任务调度
    procedure Schedule(const Task: TThreadMethod; Priority: Integer = 0);
    procedure ScheduleDelayed(const Task: TThreadMethod; DelayMs: Cardinal);
    function ScheduleTask<T>(const Task: specialize TFunc<T>): specialize IFuture<T>;
    
    // 属性
    property Scheduler: TAsyncScheduler read FScheduler;
    property ThreadPool: IThreadPool read FThreadPool;
    property State: TEventLoopState read FState;
  end;

  // 异步任务包装器
  generic TAsyncTaskWrapper<T> = class
  private
    FTask: specialize TFunc<T>;
    FPromise: specialize IPromise<T>;
    FRuntime: TAsyncRuntime;
  public
    constructor Create(const Task: specialize TFunc<T>; Promise: specialize IPromise<T>; Runtime: TAsyncRuntime);
    procedure Execute;
  end;

implementation

uses
  fafafa.core.thread.promise;

{ TAsyncTaskItem }

constructor TAsyncTaskItem.Create(const Task: TThreadMethod; ScheduledTime: TDateTime; Priority: Integer);
begin
  inherited Create;
  FTask := Task;
  FScheduledTime := ScheduledTime;
  FPriority := Priority;
end;

{ TAsyncScheduler }

constructor TAsyncScheduler.Create;
begin
  inherited Create;
  FTaskQueue := TThreadSafeQueue<TAsyncTaskItem>.Create;
  FTimerQueue := TThreadSafeQueue<TAsyncTaskItem>.Create;
  FLock := TCriticalSection.Create;
  FEvent := TEvent.Create(nil, False, False, '');
end;

destructor TAsyncScheduler.Destroy;
var
  Item: TAsyncTaskItem;
begin
  // 清理待处理任务
  while FTaskQueue.TryDequeue(Item) do
    Item.Free;
  while FTimerQueue.TryDequeue(Item) do
    Item.Free;
    
  FreeAndNil(FTaskQueue);
  FreeAndNil(FTimerQueue);
  FreeAndNil(FLock);
  FreeAndNil(FEvent);
  inherited Destroy;
end;

procedure TAsyncScheduler.Schedule(const Task: TThreadMethod; Priority: Integer);
var
  Item: TAsyncTaskItem;
begin
  Item := TAsyncTaskItem.Create(Task, 0, Priority);
  FTaskQueue.Enqueue(Item);
  FEvent.SetEvent;
end;

procedure TAsyncScheduler.ScheduleDelayed(const Task: TThreadMethod; DelayMs: Cardinal; Priority: Integer);
var
  ScheduledTime: TDateTime;
begin
  ScheduledTime := Now + (DelayMs / (24 * 60 * 60 * 1000));
  ScheduleAt(Task, ScheduledTime, Priority);
end;

procedure TAsyncScheduler.ScheduleAt(const Task: TThreadMethod; ScheduledTime: TDateTime; Priority: Integer);
var
  Item: TAsyncTaskItem;
begin
  Item := TAsyncTaskItem.Create(Task, ScheduledTime, Priority);
  
  FLock.Enter;
  try
    FTimerQueue.Enqueue(Item);
  finally
    FLock.Leave;
  end;
  
  FEvent.SetEvent;
end;

function TAsyncScheduler.HasPendingTasks: Boolean;
begin
  Result := (FTaskQueue.Count > 0) or (FTimerQueue.Count > 0);
end;

function TAsyncScheduler.GetNextTask: TAsyncTaskItem;
begin
  Result := nil;
  
  // 首先处理定时任务
  ProcessTimerQueue;
  
  // 然后获取普通任务
  if not FTaskQueue.TryDequeue(Result) then
    Result := nil;
end;

procedure TAsyncScheduler.ProcessTimerQueue;
var
  Item: TAsyncTaskItem;
  CurrentTime: TDateTime;
  TempQueue: TThreadSafeQueue<TAsyncTaskItem>;
begin
  CurrentTime := Now;
  TempQueue := TThreadSafeQueue<TAsyncTaskItem>.Create;
  
  FLock.Enter;
  try
    // 检查所有定时任务
    while FTimerQueue.TryDequeue(Item) do
    begin
      if Item.ScheduledTime <= CurrentTime then
      begin
        // 时间到了，移到普通任务队列
        FTaskQueue.Enqueue(TAsyncTaskItem.Create(Item.Task, 0, Item.Priority));
        Item.Free;
      end
      else
      begin
        // 时间未到，放回定时队列
        TempQueue.Enqueue(Item);
      end;
    end;
    
    // 将未到时间的任务放回定时队列
    while TempQueue.TryDequeue(Item) do
      FTimerQueue.Enqueue(Item);
  finally
    FLock.Leave;
    TempQueue.Free;
  end;
end;

procedure TAsyncScheduler.ProcessPendingTasks;
var
  Item: TAsyncTaskItem;
  ProcessedCount: Integer;
const
  MAX_TASKS_PER_CYCLE = 100; // 防止饥饿
begin
  ProcessedCount := 0;
  
  while (ProcessedCount < MAX_TASKS_PER_CYCLE) do
  begin
    Item := GetNextTask;
    if Item = nil then
      Break;
      
    try
      // 执行任务
      if Assigned(Item.Task) then
        Item.Task();
    except
      on E: Exception do
      begin
        // 记录异常，但不中断事件循环
        // TODO: 添加全局异常处理器
      end;
    end;
    
    Item.Free;
    Inc(ProcessedCount);
  end;
end;

procedure TAsyncScheduler.WakeUp;
begin
  FEvent.SetEvent;
end;

procedure TAsyncScheduler.WaitForTasks(TimeoutMs: Cardinal);
begin
  if HasPendingTasks then
    Exit; // 有任务待处理，不等待
    
  FEvent.WaitFor(TimeoutMs);
end;

{ TAsyncRuntime }

constructor TAsyncRuntime.Create;
begin
  inherited Create;
  FScheduler := TAsyncScheduler.Create;
  FThreadPool := TThreadPool.Create(4, 16); // 默认4-16个工作线程
  FState := elsIdle;
  FShutdownEvent := TEvent.Create(nil, True, False, '');
  FRunning := False;
end;

destructor TAsyncRuntime.Destroy;
begin
  if FRunning then
    Stop;
    
  FreeAndNil(FScheduler);
  FThreadPool := nil;
  FreeAndNil(FShutdownEvent);
  inherited Destroy;
end;

class function TAsyncRuntime.Instance: TAsyncRuntime;
begin
  if FInstance = nil then
  begin
    FLock.Enter;
    try
      if FInstance = nil then
        FInstance := TAsyncRuntime.Create;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class procedure TAsyncRuntime.Initialize;
begin
  if FLock = nil then
    FLock := TCriticalSection.Create;
  Instance; // 确保实例被创建
end;

class procedure TAsyncRuntime.Finalize;
begin
  if FInstance <> nil then
  begin
    FInstance.Stop;
    FreeAndNil(FInstance);
  end;
  FreeAndNil(FLock);
end;

procedure TAsyncRuntime.Run;
begin
  if FRunning then
    Exit;
    
  FRunning := True;
  FState := elsRunning;
  
  if IsMainThread then
  begin
    // 在主线程中运行事件循环
    EventLoopProc;
  end
  else
  begin
    // 在后台线程中运行事件循环
    FMainThread := TThread.CreateAnonymousThread(@EventLoopProc);
    FMainThread.Start;
  end;
end;

procedure TAsyncRuntime.RunOnce;
begin
  if FState = elsShutdown then
    Exit;
    
  ProcessEvents;
end;

procedure TAsyncRuntime.Shutdown;
begin
  if not FRunning then
    Exit;
    
  FState := elsShutdown;
  FScheduler.WakeUp;
  FShutdownEvent.SetEvent;
  
  // 等待事件循环结束
  if Assigned(FMainThread) and not IsMainThread then
  begin
    FMainThread.WaitFor;
    FreeAndNil(FMainThread);
  end;
  
  FRunning := False;
end;

procedure TAsyncRuntime.Stop;
begin
  Shutdown;
end;

function TAsyncRuntime.IsRunning: Boolean;
begin
  Result := FRunning and (FState = elsRunning);
end;

function TAsyncRuntime.IsMainThread: Boolean;
begin
  Result := GetCurrentThreadId = MainThreadID;
end;

procedure TAsyncRuntime.Schedule(const Task: TThreadMethod; Priority: Integer);
begin
  FScheduler.Schedule(Task, Priority);
end;

procedure TAsyncRuntime.ScheduleDelayed(const Task: TThreadMethod; DelayMs: Cardinal);
begin
  FScheduler.ScheduleDelayed(Task, DelayMs);
end;

function TAsyncRuntime.ScheduleTask<T>(const Task: specialize TFunc<T>): specialize IFuture<T>;
var
  Promise: specialize IPromise<T>;
  Wrapper: specialize TAsyncTaskWrapper<T>;
begin
  Promise := specialize TPromise<T>.Create;
  Wrapper := specialize TAsyncTaskWrapper<T>.Create(Task, Promise, Self);
  
  FThreadPool.Submit(TWorkItem.Create(@Wrapper.Execute));
  
  Result := Promise.GetFuture;
end;

procedure TAsyncRuntime.EventLoopProc;
begin
  while FState = elsRunning do
  begin
    ProcessEvents;
    
    // 检查是否需要关闭
    if FShutdownEvent.WaitFor(0) = wrSignaled then
      Break;
      
    // 等待新任务或超时
    FScheduler.WaitForTasks(10); // 10ms 超时
  end;
  
  FState := elsIdle;
end;

procedure TAsyncRuntime.ProcessEvents;
begin
  // 处理调度器中的待处理任务
  FScheduler.ProcessPendingTasks;
  
  // 处理线程池完成的任务
  if Assigned(FThreadPool) then
    FThreadPool.ProcessCompletedTasks;
end;

{ TAsyncTaskWrapper<T> }

constructor TAsyncTaskWrapper<T>.Create(const Task: specialize TFunc<T>; Promise: specialize IPromise<T>; Runtime: TAsyncRuntime);
begin
  inherited Create;
  FTask := Task;
  FPromise := Promise;
  FRuntime := Runtime;
end;

procedure TAsyncTaskWrapper<T>.Execute;
var
  Result: T;
begin
  try
    Result := FTask();
    FPromise.SetValue(Result);
  except
    on E: Exception do
      FPromise.SetException(E);
  end;
end;

end.
