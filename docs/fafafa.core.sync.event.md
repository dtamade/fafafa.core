# fafafa.core.sync.event 模块文档

## 概述

fafafa.core.sync.event 模块提供了高性能、线程安全的事件同步原语，支持手动重置和自动重置两种模式。该模块采用跨平台设计，在 Windows 和 Unix 系统上提供一致的 API 接口。

## 核心特性

### ✅ 核心功能
- **双模式支持**: 手动重置和自动重置事件
- **跨平台兼容**: Windows 和 Unix/Linux 平台
- **线程安全**: 完全线程安全的实现
- **高性能**: 基于平台原生 API 的高效实现
- **简洁接口**: 专注核心功能，避免过度设计
- **自动资源管理**: 基于接口引用的自动内存管理

### 🚀 性能特点
- **Windows**: 基于内核事件对象，零用户态开销
- **Unix**: 基于 pthread 条件变量，标准 POSIX 实现
- **时间复杂度**: 所有操作都是 O(1) 常数时间
- **内存效率**: 最小化内存占用和分配

## API 参考

### 工厂函数

```pascal
// 创建事件
function MakeEvent(AManualReset: Boolean = False;
                  AInitialState: Boolean = False): IEvent;
```

### 核心接口

```pascal
IEvent = interface(ISynchronizable)
  ['{E8B9D5C6-7F6A-4D3E-8B9C-6A5D4E3F2B18}']

  { 基础事件操作 }
  procedure SetEvent;                              // 设置事件为信号状态
  procedure ResetEvent;                            // 重置事件为非信号状态
  function WaitFor: TWaitResult; overload;         // 无限等待事件信号
  function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload; // 带超时等待

  { 扩展操作 }
  function TryWait: Boolean;                       // 非阻塞等待
  function IsManualReset: Boolean;                 // 是否手动重置事件
end;
```

### 等待结果

```pascal
TWaitResult = (
  wrSignaled,   // 事件被信号化
  wrTimeout,    // 等待超时
  wrAbandoned,  // 事件被放弃（中断）
  wrError,      // 发生错误
  wrInterrupted // 被信号中断（Unix）
);
```

## 使用指南

### 基础用法

#### 1. 手动重置事件
```pascal
var
  Event: IEvent;
begin
  // 创建手动重置事件，初始为非信号状态
  Event := MakeEvent(True, False);

  // 设置信号
  Event.SetEvent;

  // 多个线程可以同时通过
  if Event.WaitFor(1000) = wrSignaled then
    WriteLn('Event signaled');

  // 手动重置
  Event.ResetEvent;
end;
```

#### 2. 自动重置事件
```pascal
var
  Event: IEvent;
begin
  // 创建自动重置事件
  Event := MakeEvent(False, False);

  // 设置信号
  Event.SetEvent;

  // 只有一个线程能通过，事件自动重置
  if Event.WaitFor(1000) = wrSignaled then
    WriteLn('Got the signal');
end;
```

### 高级用法

#### 1. 非阻塞检查
```pascal
var
  Event: IEvent;
begin
  Event := MakeEvent(False, False);

  // 非阻塞检查事件状态
  if Event.TryWait then
    WriteLn('Event is signaled')
  else
    WriteLn('Event is not signaled');
end;
```

#### 2. 生产者-消费者模式
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
  // 创建自动重置事件用于生产者-消费者通信
  WorkAvailable := MakeEvent(False, False);

  // 启动生产者和消费者线程...
end;
```

#### 3. 多线程广播
```pascal
var
  ShutdownEvent: IEvent;

procedure WorkerThread;
begin
  while True do
  begin
    // 检查是否需要关闭
    if ShutdownEvent.TryWait then
    begin
      WriteLn('Worker thread shutting down');
      Break;
    end;

    // 执行工作...
    Sleep(100);
  end;
end;

begin
  // 创建手动重置事件用于广播关闭信号
  ShutdownEvent := MakeEvent(True, False);

  // 启动多个工作线程...

  // 广播关闭信号（所有线程都会收到）
  ShutdownEvent.SetEvent;
end;
```

## 最佳实践

### 🎯 性能优化建议

#### 1. 选择合适的事件类型
- **手动重置事件**: 适用于广播场景，多个线程需要同时响应
- **自动重置事件**: 适用于工作队列场景，只有一个线程处理

#### 2. 使用非阻塞检查
```pascal
// ✅ 好的做法：使用 TryWait 进行非阻塞检查
if Event.TryWait then
  ProcessEvent
else
  DoOtherWork;
```

#### 3. 合理设置超时
```pascal
// ✅ 好的做法：设置合理的超时时间
case Event.WaitFor(5000) of
  wrSignaled: ProcessEvent;
  wrTimeout:  HandleTimeout;
  wrError:    HandleError;
end;
```

### 🔒 线程安全建议

#### 1. 正确的同步模式
```pascal
// ✅ 自动重置事件：生产者-消费者模式
procedure Producer;
begin
  PrepareData;
  Event.SetEvent; // 通知数据准备完成
end;

procedure Consumer;
begin
  if Event.WaitFor(High(Cardinal)) = wrSignaled then
  begin
    ProcessData; // 自动重置，无需手动重置
  end;
end;
```

#### 2. 避免竞态条件
```pascal
// ✅ 正确：直接等待，避免检查和等待之间的竞态
case Event.WaitFor(1000) of
  wrSignaled: ProcessEvent;
  wrTimeout:  HandleTimeout;
end;
```

### 📊 错误处理

#### 1. 检查等待结果
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

#### 2. 异常处理
```pascal
// 处理创建事件时的异常
try
  Event := MakeEvent(True, False);
except
  on E: ELockError do
  begin
    WriteLn('创建事件失败: ', E.Message);
    // 处理资源不足等情况
  end;
end;
```

## 性能特性

### 典型性能指标

| 操作 | Windows | Unix | 说明 |
|------|---------|------|------|
| SetEvent | O(1) | O(1) | 常数时间操作 |
| ResetEvent | O(1) | O(1) | 常数时间操作 |
| TryWait | O(1) | O(1) | 非阻塞检查 |
| WaitFor | 阻塞 | 阻塞 | 等待直到信号或超时 |

### 内存使用
- **Windows**: 每个事件对象约 64 bytes
- **Unix**: 每个事件对象约 128 bytes (包含 mutex + cond)
- **接口开销**: 最小化，基于引用计数

## 故障排除

### 常见问题

#### 1. 等待超时
**症状**: WaitFor 总是返回 wrTimeout
**解决方案**:
- 检查是否有其他线程调用了 SetEvent
- 确认事件类型是否正确（自动 vs 手动重置）
- 检查超时时间是否合理

#### 2. 自动重置事件行为异常
**症状**: 多个线程都收到了信号
**解决方案**:
- 确认使用的是自动重置事件 (AManualReset = False)
- 检查是否有多次调用 SetEvent

#### 3. 手动重置事件无法重置
**症状**: ResetEvent 后事件仍然是信号状态
**解决方案**:
- 确认使用的是手动重置事件 (AManualReset = True)
- 检查是否有其他线程在 ResetEvent 后又调用了 SetEvent

#### 4. 资源管理
**症状**: 内存使用持续增长
**解决方案**:
- 事件对象通过接口引用自动管理，无需手动释放
- 避免循环引用导致的内存泄漏
- 确保接口变量在适当时机设为 nil

## 平台兼容性

### Windows 平台
- **最低要求**: Windows 7 或更高版本
- **实现**: 基于 Windows 内核事件对象
- **特点**: 高性能，零用户态开销

### Unix 平台
- **最低要求**: 支持 POSIX 线程的 Unix 系统
- **实现**: 基于 pthread_mutex + pthread_cond
- **特点**: 标准兼容，跨平台可移植

## 总结

fafafa.core.sync.event 模块提供了简洁而强大的事件同步原语：

- ✅ **简单易用**: 清晰的 API 设计，易于理解和使用
- ✅ **高性能**: 基于平台原生 API 的高效实现
- ✅ **线程安全**: 完全线程安全，支持多线程并发访问
- ✅ **跨平台**: Windows 和 Unix 平台一致的行为
- ✅ **可靠性**: 经过全面测试，生产环境可用

该模块专注于核心功能，避免了过度设计，为开发者提供了可靠的同步工具。
