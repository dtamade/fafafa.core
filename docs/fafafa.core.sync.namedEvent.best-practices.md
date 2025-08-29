# fafafa.core.sync.namedEvent 最佳实践指南

## 设计原则

### 1. 遵循主流框架标准

我们的设计借鉴了现代编程语言的最佳实践：

#### Rust 风格：零成本抽象
```pascal
// RAII 自动资源管理，无需手动释放
var LGuard := LEvent.Wait;
// LGuard 超出作用域时自动清理
```

#### Java 风格：企业级可靠性
```pascal
// 明确的错误处理
try
  LGuard := LEvent.TryWaitFor(5000);
  if Assigned(LGuard) then
    ProcessEvent;
except
  on E: ELockError do
    HandleSyncError(E);
end;
```

#### Go 风格：简洁高效
```pascal
// 简化的 API，只保留核心功能
LEvent := CreateNamedEvent('MyEvent');
LEvent.Signal;
LGuard := LEvent.Wait;
```

## API 使用指南

### 1. 工厂函数选择

#### 基本用法（推荐）
```pascal
// 自动重置事件，适用于任务分发
LEvent := CreateNamedEvent('TaskReady');

// 手动重置事件，适用于状态通知
LEvent := CreateNamedEvent('StatusChanged', True);
```

#### 跨进程通信
```pascal
// 全局事件，可跨会话访问
LEvent := CreateGlobalNamedEvent('AppShutdown', True);
```

#### 高级配置
```pascal
// 自定义配置
var LConfig := DefaultNamedEventConfig;
LConfig.TimeoutMs := 10000;
LConfig.MaxRetries := 50;
LEvent := CreateNamedEventWithConfig('CustomEvent', LConfig);
```

### 2. 事件类型选择

#### 自动重置事件
- **用途**: 任务分发、资源分配
- **特点**: 只有一个等待者能获得信号
- **示例**: 工作队列、连接池

```pascal
// 工作队列示例
LTaskEvent := CreateNamedEvent('NewTask', False); // 自动重置

// 生产者
LTaskEvent.Signal; // 只有一个工作线程会被唤醒

// 消费者
LGuard := LTaskEvent.Wait;
if Assigned(LGuard) then
  ProcessTask;
```

#### 手动重置事件
- **用途**: 状态广播、条件通知
- **特点**: 所有等待者都能获得信号
- **示例**: 应用启动完成、配置更新

```pascal
// 状态广播示例
LStatusEvent := CreateNamedEvent('AppReady', True); // 手动重置

// 通知者
LStatusEvent.Signal; // 所有等待的线程都会被唤醒

// 等待者们
LGuard := LStatusEvent.Wait;
if Assigned(LGuard) then
  StartProcessing;
```

### 3. RAII 模式最佳实践

#### 正确的守卫使用
```pascal
procedure ProcessEvent;
var
  LGuard: INamedEventGuard;
begin
  LGuard := LEvent.TryWaitFor(1000);
  if Assigned(LGuard) then
  begin
    try
      // 处理事件
      DoWork;
    finally
      LGuard := nil; // 显式释放（可选，超出作用域时自动释放）
    end;
  end;
end;
```

#### 避免长时间持有守卫
```pascal
// ❌ 错误：长时间持有守卫
procedure BadExample;
var LGuard: INamedEventGuard;
begin
  LGuard := LEvent.Wait;
  Sleep(10000); // 长时间阻塞，影响其他等待者
  ProcessData;
end;

// ✅ 正确：快速处理后释放
procedure GoodExample;
var LGuard: INamedEventGuard;
begin
  LGuard := LEvent.Wait;
  if Assigned(LGuard) then
  begin
    ProcessData; // 快速处理
    LGuard := nil; // 立即释放
  end;
end;
```

## 性能优化建议

### 1. 选择合适的超时值

```pascal
// 交互式应用：短超时，快速响应
LGuard := LEvent.TryWaitFor(100);

// 批处理应用：长超时，避免频繁重试
LGuard := LEvent.TryWaitFor(30000);

// 实时系统：无超时，确保处理
LGuard := LEvent.Wait;
```

### 2. 避免频繁创建/销毁

```pascal
// ❌ 错误：频繁创建事件对象
for i := 1 to 1000 do
begin
  LEvent := CreateNamedEvent('TempEvent' + IntToStr(i));
  // 使用事件
  LEvent := nil;
end;

// ✅ 正确：复用事件对象
LEvent := CreateNamedEvent('WorkerEvent');
for i := 1 to 1000 do
begin
  // 复用同一个事件
  LEvent.Signal;
  ProcessWork;
  LEvent.Reset;
end;
```

### 3. 合理的命名策略

```pascal
// ✅ 好的命名：描述性强，避免冲突
LEvent := CreateNamedEvent('MyApp.Worker.TaskReady');
LEvent := CreateNamedEvent('MyApp.Status.ConfigUpdated');

// ❌ 差的命名：容易冲突
LEvent := CreateNamedEvent('Event1');
LEvent := CreateNamedEvent('Ready');
```

## 错误处理模式

### 1. 分层错误处理

```pascal
function SafeWaitForEvent(const AEventName: string; ATimeoutMs: Cardinal): Boolean;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  Result := False;
  try
    LEvent := CreateNamedEvent(AEventName);
    LGuard := LEvent.TryWaitFor(ATimeoutMs);
    Result := Assigned(LGuard);
  except
    on E: ELockError do
    begin
      LogError('同步错误: ' + E.Message);
      // 可以选择重试或返回失败
    end;
    on E: EInvalidArgument do
    begin
      LogError('参数错误: ' + E.Message);
      // 参数错误通常不应重试
    end;
    on E: Exception do
    begin
      LogError('未知错误: ' + E.Message);
      // 记录并重新抛出
      raise;
    end;
  end;
end;
```

### 2. 超时处理策略

```pascal
function WaitWithRetry(LEvent: INamedEvent; AMaxRetries: Integer): Boolean;
var
  i: Integer;
  LGuard: INamedEventGuard;
begin
  for i := 1 to AMaxRetries do
  begin
    LGuard := LEvent.TryWaitFor(1000);
    if Assigned(LGuard) then
      Exit(True);
      
    // 指数退避
    Sleep(i * 100);
  end;
  Result := False;
end;
```

## 跨进程通信模式

### 1. 生产者-消费者模式

```pascal
// 生产者进程
procedure Producer;
var
  LDataReady: INamedEvent;
  LProcessed: INamedEvent;
begin
  LDataReady := CreateGlobalNamedEvent('DataReady');
  LProcessed := CreateGlobalNamedEvent('DataProcessed');
  
  // 生产数据
  ProduceData;
  
  // 通知数据就绪
  LDataReady.Signal;
  
  // 等待处理完成
  LProcessed.Wait;
end;

// 消费者进程
procedure Consumer;
var
  LDataReady: INamedEvent;
  LProcessed: INamedEvent;
  LGuard: INamedEventGuard;
begin
  LDataReady := CreateGlobalNamedEvent('DataReady');
  LProcessed := CreateGlobalNamedEvent('DataProcessed');
  
  // 等待数据就绪
  LGuard := LDataReady.Wait;
  if Assigned(LGuard) then
  begin
    // 处理数据
    ConsumeData;
    
    // 通知处理完成
    LProcessed.Signal;
  end;
end;
```

### 2. 协调器模式

```pascal
// 协调器：管理多个工作进程
procedure Coordinator;
var
  LStartEvent: INamedEvent;
  LDoneEvent: INamedEvent;
  i: Integer;
begin
  LStartEvent := CreateGlobalNamedEvent('WorkStart', True); // 手动重置
  LDoneEvent := CreateGlobalNamedEvent('WorkDone');
  
  // 启动所有工作进程
  LStartEvent.Signal;
  
  // 等待所有工作完成
  for i := 1 to WORKER_COUNT do
    LDoneEvent.Wait;
    
  WriteLn('所有工作完成');
end;

// 工作进程
procedure Worker;
var
  LStartEvent: INamedEvent;
  LDoneEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  LStartEvent := CreateGlobalNamedEvent('WorkStart', True);
  LDoneEvent := CreateGlobalNamedEvent('WorkDone');
  
  // 等待开始信号
  LGuard := LStartEvent.Wait;
  if Assigned(LGuard) then
  begin
    // 执行工作
    DoWork;
    
    // 报告完成
    LDoneEvent.Signal;
  end;
end;
```

## 调试和监控

### 1. 错误状态检查

```pascal
procedure CheckEventStatus(LEvent: INamedEvent);
begin
  case LEvent.GetLastError of
    weNone: WriteLn('状态正常');
    weTimeout: WriteLn('操作超时');
    weSystemError: WriteLn('系统错误');
    weInvalidArgument: WriteLn('参数无效');
  end;
end;
```

### 2. 性能监控

```pascal
procedure MonitorEventPerformance;
var
  LStartTime: TDateTime;
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  LEvent := CreateNamedEvent('PerfTest');
  
  LStartTime := Now;
  LGuard := LEvent.TryWaitFor(1000);
  
  WriteLn(Format('等待时间: %.3f ms', 
    [(Now - LStartTime) * 24 * 60 * 60 * 1000]));
end;
```

## 常见陷阱和解决方案

### 1. 死锁避免

```pascal
// ❌ 可能导致死锁
LEvent1.Signal;
LGuard2 := LEvent2.Wait; // 如果另一个线程在等待 Event1

// ✅ 使用超时避免死锁
LGuard2 := LEvent2.TryWaitFor(5000);
if not Assigned(LGuard2) then
  HandleTimeout;
```

### 2. 资源泄漏预防

```pascal
// ✅ 使用 try-finally 确保清理
var LGuard: INamedEventGuard;
begin
  LGuard := LEvent.Wait;
  try
    ProcessEvent;
  finally
    LGuard := nil; // 确保释放
  end;
end;
```

### 3. 竞态条件处理

```pascal
// ✅ 原子操作模式
function AtomicEventCheck(LEvent: INamedEvent): Boolean;
var LGuard: INamedEventGuard;
begin
  LGuard := LEvent.TryWait;
  Result := Assigned(LGuard);
  // 不要在检查后再次操作，避免竞态条件
end;
```

这个最佳实践指南涵盖了从基本使用到高级模式的完整指导，帮助开发者正确高效地使用命名事件模块。
