# fafafa.core.sync.event 高级使用场景示例

## 概述

本文档提供了 `fafafa.core.sync.event` 模块的高级使用场景和实际应用示例，帮助开发者在复杂的并发环境中正确使用事件同步原语。

## 1. 生产者-消费者模式

### 单生产者-多消费者

```pascal
unit ProducerConsumerExample;

interface

uses
  Classes, SysUtils, fafafa.core.sync.event;

type
  TWorkItem = record
    Id: Integer;
    Data: string;
    ProcessTime: Cardinal;
  end;

  TProducerConsumerSystem = class
  private
    FWorkQueue: TThreadList;
    FWorkAvailable: IEvent;
    FShutdown: IEvent;
    FConsumers: array of TThread;
    FProducer: TThread;
    
    procedure ProducerProc;
    procedure ConsumerProc(ConsumerId: Integer);
  public
    constructor Create(ConsumerCount: Integer = 4);
    destructor Destroy; override;
    
    procedure Start;
    procedure Stop;
    procedure AddWork(const Item: TWorkItem);
  end;

implementation

constructor TProducerConsumerSystem.Create(ConsumerCount: Integer);
var
  i: Integer;
begin
  inherited Create;
  FWorkQueue := TThreadList.Create;
  FWorkAvailable := MakeEvent(False, False); // 自动重置事件
  FShutdown := MakeEvent(True, False);       // 手动重置事件
  
  // 创建消费者线程
  SetLength(FConsumers, ConsumerCount);
  for i := 0 to ConsumerCount - 1 do
  begin
    FConsumers[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        ConsumerProc(i);
      end);
  end;
  
  // 创建生产者线程
  FProducer := TThread.CreateAnonymousThread(@ProducerProc);
end;

procedure TProducerConsumerSystem.ProducerProc;
var
  Item: TWorkItem;
  i: Integer;
begin
  for i := 1 to 1000 do
  begin
    if FShutdown.TryWait then
      Break;
      
    // 生成工作项
    Item.Id := i;
    Item.Data := Format('Work item %d', [i]);
    Item.ProcessTime := Random(100) + 50;
    
    AddWork(Item);
    Sleep(10); // 模拟生产延迟
  end;
end;

procedure TProducerConsumerSystem.ConsumerProc(ConsumerId: Integer);
var
  List: TList;
  Item: ^TWorkItem;
  WaitResult: TWaitResult;
begin
  while True do
  begin
    // 等待工作或关闭信号
    WaitResult := FWorkAvailable.WaitFor(1000);
    
    if FShutdown.TryWait then
      Break;
      
    if WaitResult = wrSignaled then
    begin
      // 获取工作项
      List := FWorkQueue.LockList;
      try
        if List.Count > 0 then
        begin
          Item := List[0];
          List.Delete(0);
        end
        else
          Item := nil;
      finally
        FWorkQueue.UnlockList;
      end;
      
      // 处理工作项
      if Item <> nil then
      begin
        try
          WriteLn(Format('Consumer %d processing item %d', [ConsumerId, Item^.Id]));
          Sleep(Item^.ProcessTime);
        finally
          Dispose(Item);
        end;
      end;
    end;
  end;
end;

procedure TProducerConsumerSystem.AddWork(const Item: TWorkItem);
var
  List: TList;
  NewItem: ^TWorkItem;
begin
  New(NewItem);
  NewItem^ := Item;
  
  List := FWorkQueue.LockList;
  try
    List.Add(NewItem);
  finally
    FWorkQueue.UnlockList;
  end;
  
  // 通知有新工作可用
  FWorkAvailable.SetEvent;
end;

procedure TProducerConsumerSystem.Start;
var
  i: Integer;
begin
  FProducer.Start;
  for i := 0 to High(FConsumers) do
    FConsumers[i].Start;
end;

procedure TProducerConsumerSystem.Stop;
var
  i: Integer;
begin
  // 发送关闭信号
  FShutdown.SetEvent;
  
  // 等待所有线程完成
  FProducer.WaitFor;
  for i := 0 to High(FConsumers) do
    FConsumers[i].WaitFor;
end;

end.
```

## 2. 线程池实现

```pascal
unit ThreadPoolExample;

interface

uses
  Classes, SysUtils, fafafa.core.sync.event;

type
  TWorkProc = procedure(Data: Pointer);
  
  TThreadPoolTask = record
    WorkProc: TWorkProc;
    Data: Pointer;
    CompletionEvent: IEvent;
  end;

  TAdvancedThreadPool = class
  private
    FThreads: array of TThread;
    FTaskQueue: TThreadList;
    FTaskAvailable: IEvent;
    FShutdown: IEvent;
    FActiveThreads: Integer;
    
    procedure WorkerThreadProc(ThreadId: Integer);
  public
    constructor Create(ThreadCount: Integer = 8);
    destructor Destroy; override;
    
    procedure SubmitTask(WorkProc: TWorkProc; Data: Pointer; CompletionEvent: IEvent = nil);
    procedure WaitForCompletion;
    procedure Shutdown;
  end;

implementation

constructor TAdvancedThreadPool.Create(ThreadCount: Integer);
var
  i: Integer;
begin
  inherited Create;
  FTaskQueue := TThreadList.Create;
  FTaskAvailable := MakeEvent(False, False);
  FShutdown := MakeEvent(True, False);
  FActiveThreads := 0;
  
  SetLength(FThreads, ThreadCount);
  for i := 0 to ThreadCount - 1 do
  begin
    FThreads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        WorkerThreadProc(i);
      end);
    FThreads[i].Start;
  end;
end;

procedure TAdvancedThreadPool.WorkerThreadProc(ThreadId: Integer);
var
  List: TList;
  Task: ^TThreadPoolTask;
  WaitResult: TWaitResult;
begin
  InterlockedIncrement(FActiveThreads);
  try
    while True do
    begin
      // 等待任务或关闭信号
      WaitResult := FTaskAvailable.WaitFor(5000);
      
      if FShutdown.TryWait then
        Break;
        
      if WaitResult = wrSignaled then
      begin
        // 获取任务
        List := FTaskQueue.LockList;
        try
          if List.Count > 0 then
          begin
            Task := List[0];
            List.Delete(0);
          end
          else
            Task := nil;
        finally
          FTaskQueue.UnlockList;
        end;
        
        // 执行任务
        if Task <> nil then
        begin
          try
            Task^.WorkProc(Task^.Data);
            
            // 通知任务完成
            if Task^.CompletionEvent <> nil then
              Task^.CompletionEvent.SetEvent;
          except
            on E: Exception do
              WriteLn(Format('Thread %d task error: %s', [ThreadId, E.Message]));
          end;
          
          Dispose(Task);
        end;
      end;
    end;
  finally
    InterlockedDecrement(FActiveThreads);
  end;
end;

procedure TAdvancedThreadPool.SubmitTask(WorkProc: TWorkProc; Data: Pointer; CompletionEvent: IEvent);
var
  List: TList;
  Task: ^TThreadPoolTask;
begin
  New(Task);
  Task^.WorkProc := WorkProc;
  Task^.Data := Data;
  Task^.CompletionEvent := CompletionEvent;
  
  List := FTaskQueue.LockList;
  try
    List.Add(Task);
  finally
    FTaskQueue.UnlockList;
  end;
  
  FTaskAvailable.SetEvent;
end;

procedure TAdvancedThreadPool.WaitForCompletion;
begin
  // 等待所有任务完成
  while True do
  begin
    if FTaskQueue.LockList.Count = 0 then
    begin
      FTaskQueue.UnlockList;
      Break;
    end;
    FTaskQueue.UnlockList;
    Sleep(10);
  end;
end;

procedure TAdvancedThreadPool.Shutdown;
var
  i: Integer;
begin
  FShutdown.SetEvent;
  
  for i := 0 to High(FThreads) do
  begin
    FThreads[i].WaitFor;
    FThreads[i].Free;
  end;
end;

end.
```

## 3. 可中断的长时间操作

```pascal
unit InterruptibleOperationExample;

interface

uses
  Classes, SysUtils, fafafa.core.sync.event;

type
  TInterruptibleOperation = class
  private
    FCancelEvent: IEvent;
    FProgressEvent: IEvent;
    FProgress: Integer;
    FMaxProgress: Integer;
    
  public
    constructor Create;
    
    function ExecuteLongOperation(MaxSteps: Integer): Boolean;
    procedure Cancel;
    procedure WaitForProgress;
    
    property Progress: Integer read FProgress;
    property MaxProgress: Integer read FMaxProgress;
  end;

implementation

constructor TInterruptibleOperation.Create;
begin
  inherited Create;
  FCancelEvent := MakeEvent(True, False);
  FProgressEvent := MakeEvent(False, False);
  FProgress := 0;
  FMaxProgress := 0;
end;

function TInterruptibleOperation.ExecuteLongOperation(MaxSteps: Integer): Boolean;
var
  i: Integer;
  WaitResult: TWaitResult;
begin
  FMaxProgress := MaxSteps;
  FProgress := 0;
  
  for i := 1 to MaxSteps do
  begin
    // 检查是否被取消（可中断等待）
    WaitResult := FCancelEvent.WaitForInterruptible(0);
    if WaitResult = wrSignaled then
    begin
      WriteLn('Operation cancelled at step ', i);
      Exit(False);
    end;
    
    // 执行工作步骤
    Sleep(100); // 模拟工作
    
    // 更新进度
    FProgress := i;
    FProgressEvent.SetEvent;
    
    WriteLn(Format('Progress: %d/%d', [i, MaxSteps]));
  end;
  
  Result := True;
end;

procedure TInterruptibleOperation.Cancel;
begin
  FCancelEvent.SetEvent;
end;

procedure TInterruptibleOperation.WaitForProgress;
begin
  FProgressEvent.WaitFor(INFINITE);
end;

end.
```

## 4. 事件链和依赖管理

```pascal
unit EventChainExample;

interface

uses
  Classes, SysUtils, Generics.Collections, fafafa.core.sync.event;

type
  TEventChain = class
  private
    FEvents: TList<IEvent>;
    FCompletionEvent: IEvent;
    FFailureEvent: IEvent;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure AddEvent(Event: IEvent);
    function WaitForChain(TimeoutMs: Cardinal = INFINITE): Boolean;
    procedure Reset;
    
    property CompletionEvent: IEvent read FCompletionEvent;
    property FailureEvent: IEvent read FFailureEvent;
  end;

implementation

constructor TEventChain.Create;
begin
  inherited Create;
  FEvents := TList<IEvent>.Create;
  FCompletionEvent := MakeEvent(True, False);
  FFailureEvent := MakeEvent(True, False);
end;

destructor TEventChain.Destroy;
begin
  FEvents.Free;
  inherited Destroy;
end;

procedure TEventChain.AddEvent(Event: IEvent);
begin
  FEvents.Add(Event);
end;

function TEventChain.WaitForChain(TimeoutMs: Cardinal): Boolean;
var
  i: Integer;
  WaitResult: TWaitResult;
  StartTime: QWord;
  ElapsedTime: QWord;
begin
  StartTime := GetTickCount64;
  
  for i := 0 to FEvents.Count - 1 do
  begin
    // 计算剩余超时时间
    ElapsedTime := GetTickCount64 - StartTime;
    if (TimeoutMs <> INFINITE) and (ElapsedTime >= TimeoutMs) then
    begin
      FFailureEvent.SetEvent;
      Exit(False);
    end;
    
    // 等待当前事件
    if TimeoutMs = INFINITE then
      WaitResult := FEvents[i].WaitFor(INFINITE)
    else
      WaitResult := FEvents[i].WaitFor(TimeoutMs - ElapsedTime);
      
    if WaitResult <> wrSignaled then
    begin
      FFailureEvent.SetEvent;
      Exit(False);
    end;
  end;
  
  FCompletionEvent.SetEvent;
  Result := True;
end;

procedure TEventChain.Reset;
var
  i: Integer;
begin
  FCompletionEvent.ResetEvent;
  FFailureEvent.ResetEvent;
  
  for i := 0 to FEvents.Count - 1 do
    FEvents[i].ResetEvent;
end;

end.
```

## 5. 性能监控和调试

```pascal
unit EventMonitoringExample;

interface

uses
  Classes, SysUtils, fafafa.core.sync.event;

type
  TEventStatistics = record
    SetCount: Int64;
    ResetCount: Int64;
    WaitCount: Int64;
    TimeoutCount: Int64;
    AverageWaitTime: Double;
  end;

  TMonitoredEvent = class
  private
    FInnerEvent: IEvent;
    FStatistics: TEventStatistics;
    FStatsLock: TRTLCriticalSection;
    
    procedure UpdateWaitStats(WaitTime: QWord; TimedOut: Boolean);
  public
    constructor Create(ManualReset: Boolean = False; InitialState: Boolean = False);
    destructor Destroy; override;
    
    // IEvent 包装方法
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor(TimeoutMs: Cardinal = INFINITE): TWaitResult;
    function TryWait: Boolean;
    
    // 监控方法
    function GetStatistics: TEventStatistics;
    procedure ResetStatistics;
    procedure PrintStatistics;
  end;

implementation

constructor TMonitoredEvent.Create(ManualReset: Boolean; InitialState: Boolean);
begin
  inherited Create;
  FInnerEvent := MakeEvent(ManualReset, InitialState);
  FillChar(FStatistics, SizeOf(FStatistics), 0);
  InitCriticalSection(FStatsLock);
end;

destructor TMonitoredEvent.Destroy;
begin
  DoneCriticalSection(FStatsLock);
  inherited Destroy;
end;

procedure TMonitoredEvent.SetEvent;
begin
  FInnerEvent.SetEvent;
  
  EnterCriticalSection(FStatsLock);
  try
    Inc(FStatistics.SetCount);
  finally
    LeaveCriticalSection(FStatsLock);
  end;
end;

procedure TMonitoredEvent.ResetEvent;
begin
  FInnerEvent.ResetEvent;
  
  EnterCriticalSection(FStatsLock);
  try
    Inc(FStatistics.ResetCount);
  finally
    LeaveCriticalSection(FStatsLock);
  end;
end;

function TMonitoredEvent.WaitFor(TimeoutMs: Cardinal): TWaitResult;
var
  StartTime: QWord;
  WaitTime: QWord;
begin
  StartTime := GetTickCount64;
  Result := FInnerEvent.WaitFor(TimeoutMs);
  WaitTime := GetTickCount64 - StartTime;
  
  UpdateWaitStats(WaitTime, Result = wrTimeout);
end;

function TMonitoredEvent.TryWait: Boolean;
var
  StartTime: QWord;
  WaitTime: QWord;
begin
  StartTime := GetTickCount64;
  Result := FInnerEvent.TryWait;
  WaitTime := GetTickCount64 - StartTime;
  
  UpdateWaitStats(WaitTime, not Result);
end;

procedure TMonitoredEvent.UpdateWaitStats(WaitTime: QWord; TimedOut: Boolean);
begin
  EnterCriticalSection(FStatsLock);
  try
    Inc(FStatistics.WaitCount);
    if TimedOut then
      Inc(FStatistics.TimeoutCount);
      
    // 更新平均等待时间
    FStatistics.AverageWaitTime := 
      (FStatistics.AverageWaitTime * (FStatistics.WaitCount - 1) + WaitTime) / FStatistics.WaitCount;
  finally
    LeaveCriticalSection(FStatsLock);
  end;
end;

function TMonitoredEvent.GetStatistics: TEventStatistics;
begin
  EnterCriticalSection(FStatsLock);
  try
    Result := FStatistics;
  finally
    LeaveCriticalSection(FStatsLock);
  end;
end;

procedure TMonitoredEvent.ResetStatistics;
begin
  EnterCriticalSection(FStatsLock);
  try
    FillChar(FStatistics, SizeOf(FStatistics), 0);
  finally
    LeaveCriticalSection(FStatsLock);
  end;
end;

procedure TMonitoredEvent.PrintStatistics;
var
  Stats: TEventStatistics;
begin
  Stats := GetStatistics;
  
  WriteLn('Event Statistics:');
  WriteLn(Format('  Set operations: %d', [Stats.SetCount]));
  WriteLn(Format('  Reset operations: %d', [Stats.ResetCount]));
  WriteLn(Format('  Wait operations: %d', [Stats.WaitCount]));
  WriteLn(Format('  Timeouts: %d (%.1f%%)', [Stats.TimeoutCount, 
    (Stats.TimeoutCount * 100.0) / Stats.WaitCount]));
  WriteLn(Format('  Average wait time: %.2f ms', [Stats.AverageWaitTime]));
end;

end.
```

## 最佳实践总结

1. **选择正确的事件类型**
   - 自动重置：一对一通知
   - 手动重置：一对多广播

2. **使用 RAII 守卫**
   - 自动资源管理
   - 异常安全

3. **合理设置超时**
   - 避免无限等待
   - 提供取消机制

4. **监控和调试**
   - 收集性能统计
   - 检测死锁和竞态条件

5. **错误处理**
   - 检查返回值
   - 处理中断和超时

这些示例展示了如何在实际应用中有效使用 `fafafa.core.sync.event` 模块。
