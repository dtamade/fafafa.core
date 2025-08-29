# fafafa.core.sync.event 性能调优指南

## 概述

本指南提供了优化 `fafafa.core.sync.event` 模块性能的详细建议和最佳实践，帮助开发者构建高性能的并发应用程序。

## 性能基准和目标

### 典型性能指标

| 操作类型 | 目标性能 | 说明 |
|---------|---------|------|
| SetEvent/ResetEvent | > 1M ops/sec | 基础状态切换操作 |
| TryWait (signaled) | > 5M ops/sec | 无锁快速路径 |
| TryWait (not signaled) | > 2M ops/sec | 快速失败路径 |
| WaitFor (immediate) | > 1M ops/sec | 立即返回的等待 |
| IsSignaled | > 10M ops/sec | 状态查询操作 |

### 性能测试代码
```pascal
program PerformanceTest;

uses
  SysUtils, DateUtils, fafafa.core.sync.event;

procedure BenchmarkOperation(const Name: string; Iterations: Integer; Operation: TProcedure);
var
  StartTime, EndTime: TDateTime;
  OpsPerSecond: Double;
begin
  StartTime := Now;
  Operation();
  EndTime := Now;
  
  OpsPerSecond := Iterations / ((EndTime - StartTime) * 24 * 3600);
  WriteLn(Format('%-20s: %10.0f ops/sec', [Name, OpsPerSecond]));
end;

var
  Event: IEvent;
  i: Integer;
const
  ITERATIONS = 1000000;

begin
  Event := CreateEvent(True, True);
  
  // 基准测试
  BenchmarkOperation('IsSignaled', ITERATIONS, 
    procedure
    var j: Integer;
    begin
      for j := 1 to ITERATIONS do
        Event.IsSignaled;
    end);
    
  BenchmarkOperation('TryWait', ITERATIONS,
    procedure
    var j: Integer;
    begin
      for j := 1 to ITERATIONS do
        Event.TryWait;
    end);
end.
```

## 核心优化策略

### 1. 选择最优的事件类型

#### 自动重置事件优化
```pascal
// 适用场景：生产者-消费者模式
// 优势：自动状态管理，减少 ResetEvent 调用

type
  TOptimizedProducerConsumer = class
  private
    FWorkEvent: IEvent;
    FWorkQueue: TThreadList;
  public
    constructor Create;
    
    procedure ProduceWork(const WorkItem: Pointer);
    function ConsumeWork: Pointer;
  end;

constructor TOptimizedProducerConsumer.Create;
begin
  // 使用自动重置事件，避免手动重置开销
  FWorkEvent := CreateEvent(False, False);
  FWorkQueue := TThreadList.Create;
end;

procedure TOptimizedProducerConsumer.ProduceWork(const WorkItem: Pointer);
var
  List: TList;
begin
  List := FWorkQueue.LockList;
  try
    List.Add(WorkItem);
  finally
    FWorkQueue.UnlockList;
  end;
  
  // 只需要 SetEvent，自动重置处理状态
  FWorkEvent.SetEvent;
end;
```

#### 手动重置事件优化
```pascal
// 适用场景：广播通知
// 优势：一次设置，多个线程受益

type
  TOptimizedBroadcaster = class
  private
    FShutdownEvent: IEvent;
    FWorkerThreads: array of TThread;
  public
    constructor Create(ThreadCount: Integer);
    
    procedure Shutdown;
  end;

constructor TOptimizedBroadcaster.Create(ThreadCount: Integer);
var
  i: Integer;
begin
  // 手动重置事件用于广播
  FShutdownEvent := CreateEvent(True, False);
  
  SetLength(FWorkerThreads, ThreadCount);
  for i := 0 to ThreadCount - 1 do
  begin
    FWorkerThreads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        // 所有线程共享同一个事件，高效广播
        while FShutdownEvent.WaitFor(1000) <> wrSignaled do
        begin
          // 执行工作...
        end;
      end);
  end;
end;

procedure TOptimizedBroadcaster.Shutdown;
begin
  // 一次设置，通知所有线程
  FShutdownEvent.SetEvent;
end;
```

### 2. 无锁快速路径优化

#### 利用原子操作
```pascal
// 高性能状态检查
function FastIsSignaled(Event: IEvent): Boolean; inline;
begin
  // 利用内部原子状态进行快速检查
  Result := Event.IsSignaled;
end;

// 高性能非阻塞获取
function FastTryAcquire(Event: IEvent): Boolean; inline;
begin
  // TryWait 使用无锁快速路径
  Result := Event.TryWait;
end;
```

#### 批量操作优化
```pascal
// 批量事件处理器
type
  TBatchEventProcessor = class
  private
    FEvents: array of IEvent;
    FReadyMask: Cardinal;
    
    procedure UpdateReadyMask;
  public
    constructor Create(const Events: array of IEvent);
    
    function ProcessReadyEvents: Integer;
  end;

procedure TBatchEventProcessor.UpdateReadyMask;
var
  i: Integer;
begin
  FReadyMask := 0;
  
  // 批量检查状态，减少系统调用
  for i := 0 to High(FEvents) do
  begin
    if FEvents[i].TryWait then
      FReadyMask := FReadyMask or (1 shl i);
  end;
end;

function TBatchEventProcessor.ProcessReadyEvents: Integer;
var
  i: Integer;
begin
  UpdateReadyMask;
  Result := 0;
  
  // 处理就绪的事件
  for i := 0 to High(FEvents) do
  begin
    if (FReadyMask and (1 shl i)) <> 0 then
    begin
      ProcessEvent(FEvents[i]);
      Inc(Result);
    end;
  end;
end;
```

### 3. 内存和缓存优化

#### 对象池模式
```pascal
// 高性能事件对象池
type
  TEventPool = class
  private
    FPool: array of IEvent;
    FPoolSize: Integer;
    FNextIndex: Integer;
    FLock: TRTLCriticalSection;
    
  public
    constructor Create(PoolSize: Integer = 100);
    destructor Destroy; override;
    
    function AcquireEvent: IEvent;
    procedure ReleaseEvent(Event: IEvent);
  end;

constructor TEventPool.Create(PoolSize: Integer);
var
  i: Integer;
begin
  FPoolSize := PoolSize;
  SetLength(FPool, PoolSize);
  
  // 预分配事件对象
  for i := 0 to PoolSize - 1 do
    FPool[i] := CreateEvent(False, False);
    
  FNextIndex := 0;
  InitCriticalSection(FLock);
end;

function TEventPool.AcquireEvent: IEvent;
begin
  EnterCriticalSection(FLock);
  try
    if FNextIndex < FPoolSize then
    begin
      Result := FPool[FNextIndex];
      FPool[FNextIndex] := nil;
      Inc(FNextIndex);
    end
    else
    begin
      // 池已空，创建新对象
      Result := CreateEvent(False, False);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;
```

#### 缓存友好的数据结构
```pascal
// 缓存对齐的事件数组
type
  TCacheAlignedEventArray = class
  private
    FEvents: array of IEvent;
    FCount: Integer;
    
  public
    constructor Create(Count: Integer);
    
    function GetEvent(Index: Integer): IEvent; inline;
    procedure SetAllEvents;
    procedure ResetAllEvents;
  end;

constructor TCacheAlignedEventArray.Create(Count: Integer);
var
  i: Integer;
begin
  FCount := Count;
  SetLength(FEvents, Count);
  
  // 批量创建，提高缓存局部性
  for i := 0 to Count - 1 do
    FEvents[i] := CreateEvent(True, False);
end;

procedure TCacheAlignedEventArray.SetAllEvents;
var
  i: Integer;
begin
  // 顺序访问，缓存友好
  for i := 0 to FCount - 1 do
    FEvents[i].SetEvent;
end;
```

### 4. 线程调度优化

#### 自适应等待策略
```pascal
// 自适应等待：短时间自旋，长时间阻塞
function AdaptiveWait(Event: IEvent; TimeoutMs: Cardinal): TWaitResult;
const
  SPIN_THRESHOLD = 10; // 10ms 以下使用自旋
  SPIN_ITERATIONS = 1000;
var
  i: Integer;
  StartTime: QWord;
begin
  if TimeoutMs <= SPIN_THRESHOLD then
  begin
    // 短时间等待：使用自旋
    for i := 1 to SPIN_ITERATIONS do
    begin
      if Event.TryWait then
        Exit(wrSignaled);
        
      // CPU 让出时间片
      {$IFDEF WINDOWS}
      SwitchToThread;
      {$ELSE}
      sched_yield;
      {$ENDIF}
    end;
    
    Result := wrTimeout;
  end
  else
  begin
    // 长时间等待：使用阻塞
    Result := Event.WaitFor(TimeoutMs);
  end;
end;
```

#### 线程亲和性优化
```pascal
// 绑定线程到特定 CPU 核心
{$IFDEF WINDOWS}
procedure SetThreadAffinity(ThreadHandle: THandle; CPUMask: DWORD_PTR);
begin
  SetThreadAffinityMask(ThreadHandle, CPUMask);
end;
{$ENDIF}

// 高性能工作线程
type
  THighPerformanceWorker = class(TThread)
  private
    FEvent: IEvent;
    FCPUCore: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(Event: IEvent; CPUCore: Integer);
  end;

constructor THighPerformanceWorker.Create(Event: IEvent; CPUCore: Integer);
begin
  inherited Create(False);
  FEvent := Event;
  FCPUCore := CPUCore;
  
  {$IFDEF WINDOWS}
  // 绑定到特定 CPU 核心
  SetThreadAffinity(Handle, 1 shl FCPUCore);
  {$ENDIF}
end;
```

### 5. 系统调用优化

#### 减少系统调用频率
```pascal
// 事件状态缓存
type
  TCachedEventState = class
  private
    FEvent: IEvent;
    FLastCheckTime: QWord;
    FCachedState: Boolean;
    FCacheValidMs: Cardinal;
    
  public
    constructor Create(Event: IEvent; CacheValidMs: Cardinal = 10);
    
    function IsSignaled: Boolean;
  end;

function TCachedEventState.IsSignaled: Boolean;
var
  CurrentTime: QWord;
begin
  CurrentTime := GetTickCount64;
  
  // 检查缓存是否有效
  if CurrentTime - FLastCheckTime < FCacheValidMs then
  begin
    Result := FCachedState;
  end
  else
  begin
    // 更新缓存
    FCachedState := FEvent.IsSignaled;
    FLastCheckTime := CurrentTime;
    Result := FCachedState;
  end;
end;
```

#### 批量系统调用
```pascal
// 批量等待多个事件
function WaitForMultipleEvents(const Events: array of IEvent; 
  WaitAll: Boolean; TimeoutMs: Cardinal): Integer;
var
  i: Integer;
  StartTime: QWord;
  ElapsedTime: QWord;
begin
  StartTime := GetTickCount64;
  Result := -1;
  
  repeat
    for i := 0 to High(Events) do
    begin
      if Events[i].TryWait then
      begin
        if not WaitAll then
          Exit(i); // 返回第一个就绪的事件索引
          
        Result := i;
      end;
    end;
    
    if WaitAll and (Result >= 0) then
      Exit(Result);
      
    // 检查超时
    ElapsedTime := GetTickCount64 - StartTime;
    if ElapsedTime >= TimeoutMs then
      Exit(-1);
      
    // 短暂休息，避免忙等待
    Sleep(1);
  until False;
end;
```

## 性能监控和分析

### 1. 性能计数器
```pascal
// 高精度性能计数器
type
  TPerformanceCounter = class
  private
    FFrequency: Int64;
    FStartTime: Int64;
    
  public
    constructor Create;
    
    procedure Start;
    function ElapsedMicroseconds: Int64;
    function ElapsedNanoseconds: Int64;
  end;

constructor TPerformanceCounter.Create;
begin
  {$IFDEF WINDOWS}
  QueryPerformanceFrequency(FFrequency);
  {$ELSE}
  FFrequency := 1000000; // 微秒精度
  {$ENDIF}
end;

procedure TPerformanceCounter.Start;
begin
  {$IFDEF WINDOWS}
  QueryPerformanceCounter(FStartTime);
  {$ELSE}
  FStartTime := GetTickCount64 * 1000; // 转换为微秒
  {$ENDIF}
end;

function TPerformanceCounter.ElapsedMicroseconds: Int64;
var
  CurrentTime: Int64;
begin
  {$IFDEF WINDOWS}
  QueryPerformanceCounter(CurrentTime);
  Result := ((CurrentTime - FStartTime) * 1000000) div FFrequency;
  {$ELSE}
  CurrentTime := GetTickCount64 * 1000;
  Result := CurrentTime - FStartTime;
  {$ENDIF}
end;
```

### 2. 热点分析
```pascal
// 操作热点分析器
type
  TOperationProfiler = class
  private
    FOperationCounts: array[0..10] of Int64;
    FOperationTimes: array[0..10] of Int64;
    
  public
    procedure RecordOperation(OpType: Integer; ElapsedTime: Int64);
    procedure PrintHotspots;
  end;

procedure TOperationProfiler.RecordOperation(OpType: Integer; ElapsedTime: Int64);
begin
  if (OpType >= 0) and (OpType <= 10) then
  begin
    InterlockedIncrement(FOperationCounts[OpType]);
    InterlockedExchangeAdd(FOperationTimes[OpType], ElapsedTime);
  end;
end;

procedure TOperationProfiler.PrintHotspots;
var
  i: Integer;
  AvgTime: Double;
const
  OpNames: array[0..10] of string = (
    'SetEvent', 'ResetEvent', 'WaitFor', 'TryWait', 'IsSignaled',
    'Interrupt', 'WaitGuard', 'TryWaitGuard', 'GetLastError',
    'ClearLastError', 'GetWaitingThreadCount'
  );
begin
  WriteLn('Operation Hotspots:');
  for i := 0 to 10 do
  begin
    if FOperationCounts[i] > 0 then
    begin
      AvgTime := FOperationTimes[i] / FOperationCounts[i];
      WriteLn(Format('  %-20s: %8d calls, %6.2f μs avg', 
        [OpNames[i], FOperationCounts[i], AvgTime]));
    end;
  end;
end;
```

## 平台特定优化

### Windows 优化
```pascal
{$IFDEF WINDOWS}
// 使用 Windows 特定的高性能 API
function CreateHighPerformanceEvent(ManualReset: Boolean): IEvent;
begin
  // 可以考虑使用 CreateEventEx 等高级 API
  Result := CreateEvent(ManualReset, False);
end;

// 设置线程优先级
procedure SetHighPriorityThread;
begin
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);
end;
{$ENDIF}
```

### Linux 优化
```pascal
{$IFDEF LINUX}
// 使用 Linux 特定优化
procedure OptimizeForLinux;
begin
  // 设置实时调度策略
  // sched_setscheduler(0, SCHED_FIFO, ...);
end;

// 使用 futex 进行更高效的同步
// (这需要更底层的实现)
{$ENDIF}
```

## 性能调优检查清单

### ✅ 基础优化
- [ ] 选择正确的事件类型（自动 vs 手动重置）
- [ ] 使用 TryWait 进行非阻塞检查
- [ ] 避免不必要的 ResetEvent 调用
- [ ] 使用 RAII 守卫管理资源

### ✅ 高级优化
- [ ] 实现对象池减少分配开销
- [ ] 使用批量操作减少系统调用
- [ ] 实现自适应等待策略
- [ ] 优化线程亲和性和调度

### ✅ 监控和分析
- [ ] 添加性能计数器
- [ ] 实现热点分析
- [ ] 监控内存使用
- [ ] 测试不同负载下的性能

### ✅ 平台优化
- [ ] 使用平台特定的高性能 API
- [ ] 优化编译器设置
- [ ] 考虑硬件特性（NUMA、缓存等）

通过遵循这些优化策略，可以显著提升 `fafafa.core.sync.event` 的性能表现。
