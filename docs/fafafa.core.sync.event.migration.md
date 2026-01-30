# fafafa.core.sync.event 迁移指南

## 概述

本指南帮助开发者了解 fafafa.core.sync.event 模块的当前实现和最佳使用方式。该模块提供了简洁、高效的事件同步原语，专注于核心功能。

## 当前 API 概览

### 核心接口

当前版本提供以下核心方法：

```pascal
IEvent = interface(ISynchronizable)
  // 基础事件操作
  procedure SetEvent;                              // 设置事件为信号状态
  procedure ResetEvent;                            // 重置事件为非信号状态
  function WaitFor: TWaitResult; overload;         // 无限等待
  function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload; // 带超时等待

  // 扩展操作
  function TryWait: Boolean;                       // 非阻塞等待
  function IsManualReset: Boolean;                 // 是否手动重置事件
end;
```

### 工厂函数

```pascal
// 创建事件
function MakeEvent(AManualReset: Boolean = False;
                  AInitialState: Boolean = False): IEvent;
```

## 基本使用模式

### 1. 创建事件

```pascal
// 创建自动重置事件（默认）
Event := MakeEvent;

// 创建手动重置事件
Event := MakeEvent(True, False);

// 创建初始为信号状态的事件
Event := MakeEvent(False, True);
```

### 2. 基础操作

```pascal
// 设置事件为信号状态
Event.SetEvent;

// 重置事件为非信号状态（主要用于手动重置事件）
Event.ResetEvent;

// 等待事件信号
Result := Event.WaitFor(1000); // 等待最多1秒
case Result of
  wrSignaled: WriteLn('事件被信号化');
  wrTimeout:  WriteLn('等待超时');
  wrError:    WriteLn('发生错误');
end;

// 非阻塞检查
if Event.TryWait then
  WriteLn('事件已信号化')
else
  WriteLn('事件未信号化');
```

### 3. 错误处理

```pascal
// 基础错误处理
Result := Event.WaitFor(1000);
case Result of
  wrSignaled: ProcessEvent;
  wrTimeout:  HandleTimeout;
  wrError:    HandleError;
  wrAbandoned: HandleAbandoned;
end;
end;
```

## 常见使用模式

### 1. 生产者-消费者模式

```pascal
var
  WorkAvailable: IEvent;

procedure Producer;
begin
  // 生产工作项
  ProduceWorkItem;

  // 通知消费者
  WorkAvailable.SetEvent;
end;

procedure Consumer;
begin
  while True do
  begin
    // 等待工作可用
    if WorkAvailable.WaitFor(5000) = wrSignaled then
    begin
      ProcessWorkItem;
    end
    else
    begin
      WriteLn('等待工作超时');
    end;
  end;
end;

begin
  // 创建自动重置事件
  WorkAvailable := MakeEvent(False, False);
end;
```

### 2. 多线程广播

```pascal
var
  ShutdownEvent: IEvent;

procedure WorkerThread;
begin
  while True do
  begin
    // 检查关闭信号
    if ShutdownEvent.TryWait then
    begin
      WriteLn('工作线程关闭');
      Break;
    end;

    // 执行工作
    DoWork;
  end;
end;

begin
  // 创建手动重置事件用于广播
  ShutdownEvent := MakeEvent(True, False);

  // 启动工作线程...

  // 广播关闭信号
  ShutdownEvent.SetEvent;
end;
```

## 最佳实践

### 1. 选择正确的事件类型

```pascal
// 自动重置事件：适用于工作队列
WorkQueue := MakeEvent(False, False);

// 手动重置事件：适用于状态广播
ShutdownSignal := MakeEvent(True, False);
```

### 2. 合理设置超时

```pascal
// 设置合理的超时时间
case Event.WaitFor(5000) of
  wrSignaled: ProcessEvent;
  wrTimeout:  HandleTimeout;
  wrError:    HandleError;
end;
```

### 3. 错误处理

```pascal
// 完整的错误处理
Result := Event.WaitFor(1000);
case Result of
  wrSignaled:
    begin
      WriteLn('事件信号化成功');
      ProcessEvent;
    end;
  wrTimeout:
    begin
      WriteLn('等待超时');
      HandleTimeout;
    end;
  wrError:
    begin
      WriteLn('发生错误');
      HandleError;
    end;
  wrAbandoned:
    begin
      WriteLn('事件被放弃');
      HandleAbandoned;
    end;
end;
```

## 性能考虑

### 1. 选择合适的等待方式

```pascal
// 对于需要立即响应的场景，使用非阻塞检查
if Event.TryWait then
  ProcessEvent
else
  DoOtherWork;

// 对于可以等待的场景，使用阻塞等待
if Event.WaitFor(1000) = wrSignaled then
  ProcessEvent;
```

### 2. 避免不必要的操作

```pascal
// 避免重复设置已经是信号状态的事件
// 虽然不会出错，但有轻微性能开销

// 对于手动重置事件，可以先检查状态
if Event.IsManualReset and not Event.TryWait then
  Event.SetEvent;
```

## 常见问题

### 1. 自动重置 vs 手动重置

```pascal
// 自动重置事件：一次信号只唤醒一个等待者
AutoEvent := MakeEvent(False, False);
AutoEvent.SetEvent;
// 第一个 WaitFor 会成功，后续的会等待

// 手动重置事件：一次信号唤醒所有等待者
ManualEvent := MakeEvent(True, False);
ManualEvent.SetEvent;
// 所有 WaitFor 都会成功，直到调用 ResetEvent
```

### 2. 超时处理

```pascal
// 合理的超时处理
case Event.WaitFor(5000) of
  wrSignaled:
    begin
      WriteLn('事件信号化');
      ProcessEvent;
    end;
  wrTimeout:
    begin
      WriteLn('等待超时，可能需要重试或放弃');
      HandleTimeout;
    end;
  wrError:
    begin
      WriteLn('系统错误');
      HandleError;
    end;
end;
```

### 3. 资源管理

```pascal
// 事件对象通过接口引用自动管理
var
  Event: IEvent;
begin
  Event := MakeEvent(False, False);

  // 使用事件...

  // 无需手动释放，接口引用超出作用域时自动释放
end;
```

## 总结

fafafa.core.sync.event 模块提供了简洁而强大的事件同步功能：

### 核心优势

1. **简单易用**: 清晰的 API 设计，易于理解和使用
2. **高性能**: 基于平台原生 API 的高效实现
3. **线程安全**: 完全线程安全，支持多线程并发访问
4. **跨平台**: Windows 和 Unix 平台一致的行为
5. **自动管理**: 基于接口引用的自动资源管理

### 推荐使用模式

```pascal
// 创建事件
Event := MakeEvent(False, False); // 自动重置事件

// 基础使用
Event.SetEvent;
if Event.WaitFor(1000) = wrSignaled then
  ProcessEvent;

// 非阻塞检查
if Event.TryWait then
  ProcessEvent;

// 完整错误处理
case Event.WaitFor(5000) of
  wrSignaled: ProcessEvent;
  wrTimeout:  HandleTimeout;
  wrError:    HandleError;
end;
```

该模块专注于提供可靠、高效的事件同步功能，避免了复杂的高级特性，确保了代码的简洁性和可维护性。
