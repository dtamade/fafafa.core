program ThreadPool;

{$mode objfpc}{$H+}

{
  工作线程池示例
  
  本示例演示：
  1. 使用事件实现线程池
  2. 任务分发和执行
  3. 线程池的启动和关闭
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 工作任务 }
  TWorkTask = record
    TaskId: Integer;
    Data: Integer;
    ProcessingTime: Integer; // 模拟处理时间（毫秒）
  end;
  PWorkTask = ^TWorkTask;

  { 任务队列 }
  TTaskQueue = class
  private
    FTasks: array[0..99] of TWorkTask;
    FHead, FTail, FCount: Integer;
    FLock: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function Enqueue(const ATask: TWorkTask): Boolean;
    function Dequeue(out ATask: TWorkTask): Boolean;
    function Count: Integer;
    function IsEmpty: Boolean;
  end;

  { 工作线程 }
  TWorkerThread = class(TThread)
  private
    FThreadId: Integer;
    FTaskQueue: TTaskQueue;
    FTaskAvailableEvent: IEvent;
    FShutdownEvent: IEvent;
    FTasksProcessed: Integer;
  protected
    procedure Execute; override;
    procedure ProcessTask(const ATask: TWorkTask);
  public
    constructor Create(AThreadId: Integer; ATaskQueue: TTaskQueue; 
                      ATaskAvailableEvent, AShutdownEvent: IEvent);
    property TasksProcessed: Integer read FTasksProcessed;
  end;

  { 线程池 }
  TThreadPool = class
  private
    FWorkers: array of TWorkerThread;
    FTaskQueue: TTaskQueue;
    FTaskAvailableEvent: IEvent;
    FShutdownEvent: IEvent;
    FWorkerCount: Integer;
    FIsRunning: Boolean;
  public
    constructor Create(AWorkerCount: Integer);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function SubmitTask(const ATask: TWorkTask): Boolean;
    function GetQueueSize: Integer;
    function GetTotalTasksProcessed: Integer;
    property IsRunning: Boolean read FIsRunning;
  end;

{ TTaskQueue }
constructor TTaskQueue.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
  FHead := 0;
  FTail := 0;
  FCount := 0;
end;

destructor TTaskQueue.Destroy;
begin
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

function TTaskQueue.Enqueue(const ATask: TWorkTask): Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCount < Length(FTasks);
    if Result then
    begin
      FTasks[FTail] := ATask;
      FTail := (FTail + 1) mod Length(FTasks);
      Inc(FCount);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskQueue.Dequeue(out ATask: TWorkTask): Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCount > 0;
    if Result then
    begin
      ATask := FTasks[FHead];
      FHead := (FHead + 1) mod Length(FTasks);
      Dec(FCount);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskQueue.Count: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskQueue.IsEmpty: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCount = 0;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

{ TWorkerThread }
constructor TWorkerThread.Create(AThreadId: Integer; ATaskQueue: TTaskQueue; 
                                ATaskAvailableEvent, AShutdownEvent: IEvent);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FThreadId := AThreadId;
  FTaskQueue := ATaskQueue;
  FTaskAvailableEvent := ATaskAvailableEvent;
  FShutdownEvent := AShutdownEvent;
  FTasksProcessed := 0;
end;

procedure TWorkerThread.Execute;
var
  Task: TWorkTask;
  Events: array[0..1] of IEvent;
  WaitResult: Integer;
begin
  WriteLn('工作线程 ', FThreadId, ' 启动');
  
  // 设置要等待的事件
  Events[0] := FTaskAvailableEvent;  // 任务可用事件
  Events[1] := FShutdownEvent;       // 关闭事件
  
  while not Terminated do
  begin
    // 等待任务或关闭信号
    // 注意：这里简化处理，实际应该使用 WaitForMultipleObjects
    if FShutdownEvent.TryWait then
    begin
      WriteLn('工作线程 ', FThreadId, ' 收到关闭信号');
      Break;
    end;
    
    if FTaskAvailableEvent.WaitFor(100) = wrSignaled then
    begin
      // 尝试获取任务
      while FTaskQueue.Dequeue(Task) do
      begin
        ProcessTask(Task);
        Inc(FTasksProcessed);
        
        // 检查是否需要关闭
        if FShutdownEvent.TryWait then
        begin
          WriteLn('工作线程 ', FThreadId, ' 在处理任务时收到关闭信号');
          Exit;
        end;
      end;
    end;
  end;
  
  WriteLn('工作线程 ', FThreadId, ' 结束，共处理 ', FTasksProcessed, ' 个任务');
end;

procedure TWorkerThread.ProcessTask(const ATask: TWorkTask);
begin
  WriteLn('线程 ', FThreadId, ' 开始处理任务 ', ATask.TaskId, ' (数据: ', ATask.Data, ')');
  
  // 模拟任务处理
  Sleep(ATask.ProcessingTime);
  
  WriteLn('线程 ', FThreadId, ' 完成任务 ', ATask.TaskId);
end;

{ TThreadPool }
constructor TThreadPool.Create(AWorkerCount: Integer);
begin
  inherited Create;
  FWorkerCount := AWorkerCount;
  FTaskQueue := TTaskQueue.Create;
  FTaskAvailableEvent := MakeEvent(True, False);  // 手动重置
  FShutdownEvent := MakeEvent(True, False);       // 手动重置
  FIsRunning := False;
  SetLength(FWorkers, FWorkerCount);
end;

destructor TThreadPool.Destroy;
begin
  if FIsRunning then
    Stop;
  FTaskQueue.Free;
  inherited Destroy;
end;

procedure TThreadPool.Start;
var
  i: Integer;
begin
  if FIsRunning then Exit;
  
  WriteLn('启动线程池，工作线程数：', FWorkerCount);
  
  // 创建并启动工作线程
  for i := 0 to FWorkerCount - 1 do
  begin
    FWorkers[i] := TWorkerThread.Create(i + 1, FTaskQueue, FTaskAvailableEvent, FShutdownEvent);
    FWorkers[i].Start;
  end;
  
  FIsRunning := True;
  WriteLn('线程池启动完成');
end;

procedure TThreadPool.Stop;
var
  i: Integer;
begin
  if not FIsRunning then Exit;
  
  WriteLn('正在关闭线程池...');
  
  // 发送关闭信号
  FShutdownEvent.SetEvent;
  
  // 等待所有工作线程结束
  for i := 0 to FWorkerCount - 1 do
  begin
    if Assigned(FWorkers[i]) then
    begin
      FWorkers[i].WaitFor;
      FWorkers[i].Free;
      FWorkers[i] := nil;
    end;
  end;
  
  // 重置事件
  FShutdownEvent.ResetEvent;
  FTaskAvailableEvent.ResetEvent;
  
  FIsRunning := False;
  WriteLn('线程池已关闭');
end;

function TThreadPool.SubmitTask(const ATask: TWorkTask): Boolean;
begin
  if not FIsRunning then
  begin
    Result := False;
    Exit;
  end;
  
  Result := FTaskQueue.Enqueue(ATask);
  if Result then
  begin
    // 通知工作线程有新任务
    FTaskAvailableEvent.SetEvent;
    WriteLn('提交任务 ', ATask.TaskId, ' 到线程池');
  end
  else
    WriteLn('任务队列已满，无法提交任务 ', ATask.TaskId);
end;

function TThreadPool.GetQueueSize: Integer;
begin
  Result := FTaskQueue.Count;
end;

function TThreadPool.GetTotalTasksProcessed: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FWorkerCount - 1 do
  begin
    if Assigned(FWorkers[i]) then
      Result := Result + FWorkers[i].TasksProcessed;
  end;
end;

procedure RunThreadPoolDemo;
var
  ThreadPool: TThreadPool;
  Task: TWorkTask;
  i: Integer;
  StartTime: QWord;
begin
  WriteLn('=== 线程池演示 ===');
  
  ThreadPool := TThreadPool.Create(3); // 创建3个工作线程的线程池
  try
    // 启动线程池
    ThreadPool.Start;
    
    StartTime := GetTickCount64;
    
    // 提交任务
    WriteLn('提交任务到线程池...');
    for i := 1 to 10 do
    begin
      Task.TaskId := i;
      Task.Data := i * 100;
      Task.ProcessingTime := 200 + Random(300); // 200-500ms 处理时间
      
      if not ThreadPool.SubmitTask(Task) then
        WriteLn('无法提交任务 ', i);
        
      Sleep(50); // 模拟任务提交间隔
    end;
    
    WriteLn('所有任务已提交');
    
    // 等待所有任务完成
    WriteLn('等待任务完成...');
    while ThreadPool.GetQueueSize > 0 do
    begin
      WriteLn('队列中剩余任务：', ThreadPool.GetQueueSize);
      Sleep(500);
    end;
    
    // 等待一段时间确保所有任务都被处理
    Sleep(1000);
    
    WriteLn('总处理任务数：', ThreadPool.GetTotalTasksProcessed);
    WriteLn('总耗时：', GetTickCount64 - StartTime, ' ms');
    
    // 关闭线程池
    ThreadPool.Stop;
    
  finally
    ThreadPool.Free;
  end;
end;

begin
  WriteLn('fafafa.core 事件同步原语 - 线程池示例');
  WriteLn('==========================================');
  WriteLn;
  
  Randomize;
  
  try
    RunThreadPoolDemo;
    WriteLn;
    WriteLn('演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生错误：', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
