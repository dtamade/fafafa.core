# fafafa.core.sync.event 故障排除指南

## 概述

本指南帮助开发者诊断和解决使用 `fafafa.core.sync.event` 模块时遇到的常见问题。

## 常见问题诊断

### 1. 死锁问题

#### 症状
- 程序挂起，无响应
- 线程永久等待
- CPU 使用率低

#### 诊断方法
```pascal
// 使用超时等待检测死锁
function DetectDeadlock(Event: IEvent): Boolean;
var
  StartTime: QWord;
  WaitResult: TWaitResult;
begin
  StartTime := GetTickCount64;
  WaitResult := Event.WaitFor(5000); // 5秒超时
  
  if WaitResult = wrTimeout then
  begin
    WriteLn('Potential deadlock detected after 5 seconds');
    Result := True;
  end
  else
    Result := False;
end;
```

#### 解决方案
1. **使用超时等待**
```pascal
// 错误：无限等待可能导致死锁
Event.WaitFor(INFINITE);

// 正确：使用合理的超时
if Event.WaitFor(5000) = wrTimeout then
  HandleTimeout;
```

2. **避免循环依赖**
```pascal
// 错误：可能的循环依赖
Thread1: Event1.WaitFor -> Event2.SetEvent
Thread2: Event2.WaitFor -> Event1.SetEvent

// 正确：使用统一的锁顺序
Thread1: Event1.WaitFor -> Event2.WaitFor
Thread2: Event1.WaitFor -> Event2.WaitFor
```

### 2. 竞态条件

#### 症状
- 间歇性错误
- 数据不一致
- 非确定性行为

#### 诊断方法
```pascal
// 竞态条件检测器
type
  TRaceDetector = class
  private
    FEvent: IEvent;
    FSharedData: Integer;
    FExpectedValue: Integer;
    FInconsistencyCount: Integer;
  public
    procedure TestRaceCondition;
    property InconsistencyCount: Integer read FInconsistencyCount;
  end;

procedure TRaceDetector.TestRaceCondition;
var
  Threads: array[0..7] of TThread;
  i: Integer;
begin
  FEvent := CreateEvent(True, False);
  FSharedData := 0;
  FExpectedValue := 0;
  FInconsistencyCount := 0;
  
  // 创建竞争线程
  for i := 0 to 7 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
      begin
        for j := 1 to 1000 do
        begin
          FEvent.WaitFor(INFINITE);
          
          // 检查数据一致性
          if FSharedData <> FExpectedValue then
            InterlockedIncrement(FInconsistencyCount);
            
          Inc(FSharedData);
          Inc(FExpectedValue);
          
          FEvent.SetEvent;
        end;
      end);
    Threads[i].Start;
  end;
  
  // 启动竞争
  FEvent.SetEvent;
  
  // 等待完成
  for i := 0 to 7 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
end;
```

#### 解决方案
1. **使用原子操作**
```pascal
// 错误：非原子操作
Inc(SharedCounter);

// 正确：原子操作
InterlockedIncrement(SharedCounter);
```

2. **正确的同步模式**
```pascal
// 错误：检查后使用模式
if Event.IsSignaled then
  Event.ResetEvent; // 竞态条件窗口

// 正确：原子操作
if Event.TryWait then
  // 已经原子性地消费了信号
```

### 3. 内存泄漏

#### 症状
- 内存使用持续增长
- 程序运行时间越长越慢
- 最终内存耗尽

#### 诊断方法
```pascal
// 内存泄漏检测器
type
  TMemoryLeakDetector = class
  private
    FInitialMemory: Int64;
    FPeakMemory: Int64;
    FCurrentMemory: Int64;
    
    function GetMemoryUsage: Int64;
  public
    constructor Create;
    procedure CheckMemoryLeak;
    procedure PrintMemoryReport;
  end;

function TMemoryLeakDetector.GetMemoryUsage: Int64;
{$IFDEF UNIX}
var
  StatusFile: TextFile;
  Line: string;
  VmRSS: string;
begin
  Result := 0;
  try
    AssignFile(StatusFile, '/proc/self/status');
    Reset(StatusFile);
    while not EOF(StatusFile) do
    begin
      ReadLn(StatusFile, Line);
      if Pos('VmRSS:', Line) = 1 then
      begin
        VmRSS := Copy(Line, 7, Length(Line));
        VmRSS := Trim(Copy(VmRSS, 1, Pos(' ', VmRSS) - 1));
        Result := StrToInt64Def(VmRSS, 0) * 1024;
        Break;
      end;
    end;
    CloseFile(StatusFile);
  except
    Result := 0;
  end;
end;
{$ELSE}
begin
  Result := 0; // Windows 简化实现
end;
{$ENDIF}

procedure TMemoryLeakDetector.CheckMemoryLeak;
begin
  FCurrentMemory := GetMemoryUsage;
  if FCurrentMemory > FPeakMemory then
    FPeakMemory := FCurrentMemory;
    
  // 检查是否有显著的内存增长
  if FCurrentMemory > FInitialMemory * 1.5 then
    WriteLn('Warning: Potential memory leak detected');
end;
```

#### 解决方案
1. **正确的资源管理**
```pascal
// 错误：忘记释放引用
var
  Event: IEvent;
begin
  Event := CreateEvent(True, False);
  // 使用 Event...
  // 忘记设置 Event := nil
end;

// 正确：显式释放
var
  Event: IEvent;
begin
  Event := CreateEvent(True, False);
  try
    // 使用 Event...
  finally
    Event := nil; // 释放引用
  end;
end;
```

2. **使用 RAII 守卫**
```pascal
// 自动资源管理
var
  Event: IEvent;
  Guard: IEventGuard;
begin
  Event := CreateEvent(True, True);
  Guard := Event.WaitGuard; // 自动管理生命周期
  // Guard 会在作用域结束时自动释放
end;
```

### 4. 性能问题

#### 症状
- 响应时间慢
- 吞吐量低
- CPU 使用率异常

#### 诊断方法
```pascal
// 性能分析器
type
  TPerformanceProfiler = class
  private
    FOperationCount: Int64;
    FTotalTime: Int64;
    FMinTime: Int64;
    FMaxTime: Int64;
    
  public
    procedure StartOperation;
    procedure EndOperation;
    procedure PrintProfile;
  end;

var
  GProfiler: TPerformanceProfiler;

procedure ProfiledEventOperation;
var
  Event: IEvent;
  StartTime: QWord;
begin
  GProfiler.StartOperation;
  StartTime := GetTickCount64;
  
  Event := CreateEvent(True, False);
  try
    Event.SetEvent;
    Event.WaitFor(1000);
    Event.ResetEvent;
  finally
    Event := nil;
  end;
  
  GProfiler.EndOperation;
end;
```

#### 解决方案
1. **选择合适的事件类型**
```pascal
// 对于一对一通知，使用自动重置事件
Event := CreateEvent(False, False); // 更高效

// 对于一对多广播，使用手动重置事件
Event := CreateEvent(True, False);
```

2. **避免不必要的系统调用**
```pascal
// 错误：频繁的状态检查
while not Event.IsSignaled do
  Sleep(1); // 忙等待

// 正确：使用适当的等待
Event.WaitFor(INFINITE);
```

### 5. 平台兼容性问题

#### 症状
- 在某个平台上工作正常，在另一个平台上失败
- 行为不一致
- 平台特定错误

#### 诊断方法
```pascal
// 平台兼容性测试
procedure TestPlatformCompatibility;
var
  Event: IEvent;
  WaitingCount: Integer;
  LastError: TWaitError;
begin
  Event := CreateEvent(True, False);
  
  // 测试平台特定功能
  WaitingCount := Event.GetWaitingThreadCount;
  LastError := Event.GetLastError;
  
  {$IFDEF WINDOWS}
  if LastError <> weNotSupported then
    WriteLn('Windows: GetWaitingThreadCount should return weNotSupported');
  {$ELSE}
  if LastError <> weNone then
    WriteLn('Unix: GetWaitingThreadCount should not set error');
  {$ENDIF}
end;
```

#### 解决方案
1. **检查错误状态**
```pascal
// 跨平台兼容的代码
var
  Event: IEvent;
  Count: Integer;
begin
  Event := CreateEvent(True, False);
  Count := Event.GetWaitingThreadCount;
  
  if Event.GetLastError = weNotSupported then
    WriteLn('Waiting thread count not supported on this platform')
  else
    WriteLn(Format('Waiting threads: %d', [Count]));
end;
```

2. **使用条件编译**
```pascal
{$IFDEF WINDOWS}
// Windows 特定代码
{$ELSE}
// Unix 特定代码
{$ENDIF}
```

## 调试技巧

### 1. 启用调试输出
```pascal
{$DEFINE DEBUG_EVENTS}

{$IFDEF DEBUG_EVENTS}
procedure DebugLog(const Msg: string);
begin
  WriteLn(Format('[%s] %s', [FormatDateTime('hh:nn:ss.zzz', Now), Msg]));
end;
{$ELSE}
procedure DebugLog(const Msg: string);
begin
  // 空实现
end;
{$ENDIF}
```

### 2. 使用断言
```pascal
procedure SafeEventOperation(Event: IEvent);
begin
  Assert(Event <> nil, 'Event cannot be nil');
  
  Event.SetEvent;
  Assert(Event.IsSignaled, 'Event should be signaled after SetEvent');
  
  Event.ResetEvent;
  Assert(not Event.IsSignaled, 'Event should not be signaled after ResetEvent');
end;
```

### 3. 线程安全检查
```pascal
// 线程安全验证器
type
  TThreadSafetyChecker = class
  private
    FCurrentThread: TThreadID;
    FOperationCount: Integer;
  public
    procedure EnterOperation;
    procedure LeaveOperation;
  end;

procedure TThreadSafetyChecker.EnterOperation;
var
  CurrentThread: TThreadID;
begin
  CurrentThread := GetCurrentThreadId;
  
  if (FCurrentThread <> 0) and (FCurrentThread <> CurrentThread) then
    raise Exception.Create('Thread safety violation detected');
    
  FCurrentThread := CurrentThread;
  Inc(FOperationCount);
end;
```

## 性能调优建议

### 1. 减少上下文切换
```pascal
// 使用自旋等待进行短时间等待
function SpinWait(Event: IEvent; MaxSpinMs: Cardinal): Boolean;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  
  // 短时间自旋
  while GetTickCount64 - StartTime < MaxSpinMs do
  begin
    if Event.TryWait then
      Exit(True);
    // 让出 CPU 时间片
    {$IFDEF WINDOWS}
    SwitchToThread;
    {$ELSE}
    sched_yield;
    {$ENDIF}
  end;
  
  // 回退到阻塞等待
  Result := Event.WaitFor(INFINITE) = wrSignaled;
end;
```

### 2. 批量操作
```pascal
// 批量事件处理
procedure ProcessEventsBatch(const Events: array of IEvent);
var
  i: Integer;
  ReadyEvents: TList<IEvent>;
begin
  ReadyEvents := TList<IEvent>.Create;
  try
    // 收集就绪的事件
    for i := 0 to High(Events) do
    begin
      if Events[i].TryWait then
        ReadyEvents.Add(Events[i]);
    end;
    
    // 批量处理
    for i := 0 to ReadyEvents.Count - 1 do
      ProcessEvent(ReadyEvents[i]);
      
  finally
    ReadyEvents.Free;
  end;
end;
```

### 3. 内存池
```pascal
// 事件对象池
type
  TEventPool = class
  private
    FPool: TThreadList;
  public
    constructor Create(InitialSize: Integer = 10);
    destructor Destroy; override;
    
    function GetEvent: IEvent;
    procedure ReturnEvent(Event: IEvent);
  end;
```

## 总结

正确使用 `fafafa.core.sync.event` 需要：

1. **理解事件语义** - 选择正确的事件类型
2. **避免常见陷阱** - 死锁、竞态条件、内存泄漏
3. **使用调试工具** - 日志、断言、性能分析
4. **遵循最佳实践** - RAII、错误检查、超时设置
5. **性能优化** - 减少系统调用、批量处理、对象池

通过遵循这些指导原则，可以构建健壮、高性能的多线程应用程序。
