# fafafa.core.sync.event 最佳实践指南

## 概述

本指南提供了使用 `fafafa.core.sync.event` 模块的最佳实践，帮助开发者编写高效、可靠、可维护的并发代码。

## 事件类型选择

### 自动重置事件 (Auto-Reset Event)

**适用场景：**
- 生产者-消费者模式
- 工作队列处理
- 一对一通知

**特点：**
- 一次信号只唤醒一个等待线程
- 信号被消费后自动重置
- 适合串行处理场景

```pascal
// 生产者-消费者示例
var
  WorkAvailable: IEvent;
  
procedure Producer;
begin
  // 生产工作项
  ProduceWorkItem;
  
  // 通知有工作可用（只唤醒一个消费者）
  WorkAvailable.SetEvent;
end;

procedure Consumer;
begin
  while True do
  begin
    // 等待工作可用
    if WorkAvailable.WaitFor(1000) = wrSignaled then
    begin
      ProcessWorkItem;
    end;
  end;
end;

initialization
  WorkAvailable := MakeEvent(False, False); // 自动重置
```

### 手动重置事件 (Manual-Reset Event)

**适用场景：**
- 广播通知
- 状态变更通知
- 多线程同步点

**特点：**
- 一次信号可以唤醒所有等待线程
- 需要显式调用 ResetEvent 重置
- 适合广播场景

```pascal
// 广播通知示例
var
  ShutdownEvent: IEvent;
  
procedure InitiateShutdown;
begin
  // 通知所有线程开始关闭
  ShutdownEvent.SetEvent;
end;

procedure WorkerThread;
begin
  while ShutdownEvent.WaitFor(100) <> wrSignaled do
  begin
    // 执行工作
    DoWork;
  end;
  
  // 收到关闭信号，清理并退出
  Cleanup;
end;

initialization
  ShutdownEvent := MakeEvent(True, False); // 手动重置
```

## 资源管理最佳实践

### 使用 RAII 守卫模式

**推荐：** 使用 RAII 守卫自动管理资源

```pascal
// ✅ 推荐：使用 RAII 守卫
procedure ProcessWithGuard;
var
  Guard: IEventGuard;
begin
  Guard := Event.WaitGuard(5000);
  if Guard.IsValid then
  begin
    // 处理逻辑
    ProcessData;
    // 守卫自动释放，无需手动管理
  end
  else
    HandleTimeout;
end;

// ❌ 不推荐：手动管理
procedure ProcessManually;
var
  Result: TWaitResult;
begin
  Result := Event.WaitFor(5000);
  if Result = wrSignaled then
  begin
    try
      ProcessData;
    finally
      // 需要手动管理状态，容易出错
      if Event.IsManualReset then
        Event.ResetEvent;
    end;
  end;
end;
```

### 接口引用管理

```pascal
// ✅ 推荐：使用接口引用
var
  Event: IEvent;
begin
  Event := MakeEvent(False, False);
  // 接口引用自动管理内存
  // 无需手动释放
end;

// ❌ 避免：不要尝试手动管理事件对象
```

## 错误处理最佳实践

### 全面的错误检查

```pascal
// ✅ 推荐：全面的错误处理
function WaitForEventSafely(Event: IEvent; TimeoutMs: Cardinal): Boolean;
var
  Result: TWaitResult;
begin
  Result := Event.WaitFor(TimeoutMs);
  
  case Result of
    wrSignaled:
    begin
      Result := True;
    end;
    
    wrTimeout:
    begin
      LogWarning('Event wait timed out after %d ms', [TimeoutMs]);
      Result := False;
    end;
    
    wrAbandoned:
    begin
      LogInfo('Event wait was interrupted');
      Result := False;
    end;
    
    wrError:
    begin
      LogError('Event wait failed: %s (Error: %s)', 
        [Event.GetLastErrorMessage, GetEnumName(TypeInfo(TWaitError), Ord(Event.GetLastError))]);
      Result := False;
    end;
  end;
end;
```

### 错误恢复策略

```pascal
// 带重试的错误恢复
function WaitForEventWithRetry(Event: IEvent; TimeoutMs: Cardinal; MaxRetries: Integer): Boolean;
var
  Attempt: Integer;
  Result: TWaitResult;
begin
  for Attempt := 1 to MaxRetries do
  begin
    Result := Event.WaitFor(TimeoutMs);
    
    case Result of
      wrSignaled:
        Exit(True);
        
      wrTimeout:
      begin
        if Attempt < MaxRetries then
        begin
          LogWarning('Event wait timeout, attempt %d/%d', [Attempt, MaxRetries]);
          Sleep(100); // 短暂延迟后重试
          Continue;
        end;
      end;
      
      wrError:
      begin
        case Event.GetLastError of
          weResourceExhausted:
          begin
            // 资源不足，等待后重试
            Sleep(1000);
            Continue;
          end;
          
          weSystemError:
          begin
            // 系统错误，记录并退出
            LogError('System error in event wait: %s', [Event.GetLastErrorMessage]);
            Break;
          end;
        end;
      end;
    end;
  end;
  
  Result := False;
end;
```

## 性能优化最佳实践

### 选择合适的等待方法

```pascal
// ✅ 高频非阻塞检查：使用 TryWait
if Event.TryWait then
  ProcessImmediately
else
  ContinueOtherWork;

// ✅ 低频阻塞等待：使用 WaitFor
Result := Event.WaitFor(TimeoutMs);

// ✅ 状态查询：使用 IsSignaled（仅手动重置事件有效）
if Event.IsManualReset and Event.IsSignaled then
  ProcessData;
```

### 避免性能陷阱

```pascal
// ❌ 避免：忙等待
while not Event.TryWait do
  Sleep(1); // 浪费 CPU

// ✅ 推荐：适当的超时等待
while Event.WaitFor(100) <> wrSignaled do
begin
  // 执行其他工作或检查退出条件
  if ShouldExit then Break;
end;

// ❌ 避免：过度频繁的状态查询
for i := 1 to 1000000 do
  if Event.IsSignaled then Break; // 可能导致缓存抖动

// ✅ 推荐：合理的检查频率
while not Event.IsSignaled do
begin
  DoSomeWork;
  if WorkCompleted then Break;
end;
```

## 并发安全最佳实践

### 正确的同步模式

```pascal
// ✅ 生产者-消费者模式
var
  DataReady: IEvent;
  DataMutex: IMutex; // 假设有互斥锁
  SharedData: TData;

procedure Producer;
begin
  // 准备数据
  NewData := PrepareData;
  
  // 保护共享数据
  DataMutex.Lock;
  try
    SharedData := NewData;
  finally
    DataMutex.Unlock;
  end;
  
  // 通知数据就绪
  DataReady.SetEvent;
end;

procedure Consumer;
var
  LocalData: TData;
begin
  // 等待数据就绪
  if DataReady.WaitFor(5000) = wrSignaled then
  begin
    // 复制共享数据
    DataMutex.Lock;
    try
      LocalData := SharedData;
    finally
      DataMutex.Unlock;
    end;
    
    // 处理本地数据
    ProcessData(LocalData);
  end;
end;
```

### 避免竞态条件

```pascal
// ❌ 危险：检查和操作之间的竞态条件
if Event.IsSignaled then
begin
  // 在这里，事件可能被其他线程重置
  ProcessData; // 可能基于过时的状态
end;

// ✅ 安全：原子操作
if Event.TryWait then
begin
  // TryWait 原子地检查并消费信号
  ProcessData;
end;

// ✅ 更安全：使用守卫
Guard := Event.TryWaitGuard;
if Guard.IsValid then
begin
  ProcessData;
end;
```

## 调试和监控最佳实践

### 开发时调试

```pascal
// 开发环境：启用详细调试
{$IFDEF DEBUG}
procedure EnableEventDebugging(Event: IEvent);
begin
  Event.EnableDebugLogging(True);
  
  // 定期输出性能统计
  SetTimer(procedure
  begin
    WriteLn(Event.GetPerformanceCounters);
  end, 10000); // 每10秒输出一次
end;
{$ENDIF}
```

### 生产环境监控

```pascal
// 生产环境：轻量级监控
procedure MonitorEventPerformance(Event: IEvent);
var
  Counters: string;
begin
  // 定期收集性能数据
  Counters := Event.GetPerformanceCounters;
  
  // 发送到监控系统
  SendToMonitoringSystem(Counters);
  
  // 重置计数器
  Event.ResetPerformanceCounters;
end;
```

### 问题诊断

```pascal
// 诊断事件问题
procedure DiagnoseEventIssues(Event: IEvent);
begin
  WriteLn('=== Event Diagnostic Information ===');
  WriteLn(Event.GetDebugInfo);
  WriteLn;
  WriteLn('=== Performance Counters ===');
  WriteLn(Event.GetPerformanceCounters);
  
  // 检查常见问题
  if Event.GetWaitingThreadCount > 10 then
    WriteLn('WARNING: High number of waiting threads');
    
  if Event.IsInterrupted then
    WriteLn('INFO: Event has been interrupted');
end;
```

## 常见反模式和解决方案

### 反模式 1: 忙等待

```pascal
// ❌ 反模式：忙等待
while not Event.TryWait do
  ; // 空循环，浪费 CPU

// ✅ 解决方案：适当的等待
while Event.WaitFor(100) <> wrSignaled do
begin
  // 执行其他有用的工作
  DoBackgroundWork;
end;
```

### 反模式 2: 过度同步

```pascal
// ❌ 反模式：为每个操作创建事件
for i := 1 to 1000 do
begin
  Event := MakeEvent(False, False);
  // 使用事件...
end;

// ✅ 解决方案：重用事件对象
Event := MakeEvent(False, False);
for i := 1 to 1000 do
begin
  // 重用同一个事件
  Event.ResetEvent;
  // 使用事件...
end;
```

### 反模式 3: 忽略错误

```pascal
// ❌ 反模式：忽略错误
Event.WaitFor(1000); // 不检查返回值

// ✅ 解决方案：处理所有可能的结果
case Event.WaitFor(1000) of
  wrSignaled:  ProcessData;
  wrTimeout:   HandleTimeout;
  wrAbandoned: HandleInterruption;
  wrError:     HandleError(Event.GetLastErrorMessage);
end;
```

## 总结

遵循这些最佳实践可以帮助您：

1. **提高可靠性** - 正确的错误处理和资源管理
2. **提升性能** - 选择合适的方法和避免性能陷阱
3. **增强可维护性** - 清晰的代码结构和充分的调试信息
4. **确保并发安全** - 正确的同步模式和避免竞态条件

记住：事件是强大的同步原语，但需要正确使用才能发挥其优势。始终考虑您的具体使用场景，选择最适合的事件类型和操作方法。
