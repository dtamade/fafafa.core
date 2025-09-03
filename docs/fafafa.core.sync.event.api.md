# fafafa.core.sync.event API 参考

## 概述

`fafafa.core.sync.event` 模块提供了高性能、跨平台的事件同步原语实现。事件是一种同步机制，允许线程等待特定条件的发生，支持自动重置和手动重置两种模式。

**兼容性**: Windows 7+, Linux 2.6+, macOS 10.9+
**线程安全**: 完全线程安全
**平台实现**:
- Windows: 基于内核事件对象 (CreateEvent/SetEvent/WaitForSingleObject)
- Unix: 基于 pthread_mutex + pthread_cond

## 核心接口

### IEvent 接口

事件同步原语的主要接口，继承自 `ISynchronizable`。

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

## 工厂函数

### MakeEvent

创建事件对象的工厂函数。

```pascal
function MakeEvent(AManualReset: Boolean = False;
                  AInitialState: Boolean = False): IEvent;
```

**参数：**
- `AManualReset`: 是否为手动重置事件（默认：False）
  - `True`: 手动重置事件，需要显式调用 `ResetEvent` 来重置
  - `False`: 自动重置事件，等待成功后自动重置为非信号状态
- `AInitialState`: 初始信号状态（默认：False）
  - `True`: 创建时处于信号状态
  - `False`: 创建时处于非信号状态

**返回值：**
- 返回 `IEvent` 接口实例

**异常：**
- `ELockError`: 当系统资源不足或创建失败时抛出

**示例：**
```pascal
var
  AutoEvent, ManualEvent: IEvent;
begin
  // 创建自动重置事件，初始非信号状态
  AutoEvent := MakeEvent(False, False);

  // 创建手动重置事件，初始信号状态
  ManualEvent := MakeEvent(True, True);

  // 使用默认参数（自动重置，非信号状态）
  DefaultEvent := MakeEvent;
end;
```

## 枚举类型

### TWaitResult

等待操作的结果。

```pascal
TWaitResult = (
  wrSignaled,   // 事件被信号化
  wrTimeout,    // 等待超时
  wrAbandoned,  // 事件被放弃（中断）
  wrError       // 发生错误
);
```

**说明：**
- `wrSignaled`: 事件被成功信号化，等待操作成功
- `wrTimeout`: 在指定的超时时间内未收到信号
- `wrAbandoned`: 事件被放弃（主要在 Windows 平台）
- `wrError`: 发生系统级错误
- `wrInterrupted`: 等待被信号中断（主要在 Unix 平台）

## 使用示例

### 基础用法

```pascal
var
  Event: IEvent;
  Result: TWaitResult;
begin
  // 创建自动重置事件，初始状态为非信号
  Event := MakeEvent(False, False);

  // 在另一个线程中设置事件
  Event.SetEvent;

  // 等待事件信号，最多等待1000毫秒
  Result := Event.WaitFor(1000);

  case Result of
    wrSignaled: WriteLn('事件被信号化');
    wrTimeout:  WriteLn('等待超时');
    wrError:    WriteLn('发生错误');
    wrAbandoned: WriteLn('事件被放弃');
  end;
end;
```

### 非阻塞等待

```pascal
var
  Event: IEvent;
begin
  Event := MakeEvent(False, False);

  // 非阻塞检查事件状态
  if Event.TryWait then
    WriteLn('事件已信号化')
  else
    WriteLn('事件未信号化');
end;
```

### 手动重置事件

```pascal
var
  Event: IEvent;
  i: Integer;
begin
  // 创建手动重置事件
  Event := MakeEvent(True, False);

  // 设置事件信号
  Event.SetEvent;

  // 多次等待都会成功（手动重置特性）
  for i := 1 to 3 do
  begin
    if Event.WaitFor(100) = wrSignaled then
      WriteLn('第 ', i, ' 次等待成功');
  end;

  // 手动重置为非信号状态
  Event.ResetEvent;

  // 现在等待会超时
  if Event.WaitFor(100) = wrTimeout then
    WriteLn('重置后等待超时');
end;
```

### 生产者-消费者模式

```pascal
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
    if WorkAvailable.WaitFor(5000) = wrSignaled then
    begin
      // 处理工作项
      ProcessWorkItem;
    end
    else
    begin
      // 超时处理
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

## 平台实现

### Windows 平台
- **实现方式**: 基于 Windows 内核事件对象 (CreateEvent/SetEvent/ResetEvent/WaitForSingleObject)
- **性能特点**: 高效的内核级同步，无额外用户态开销
- **线程安全**: 由操作系统内核保证

### Unix 平台
- **实现方式**: 基于 pthread_mutex + pthread_cond
- **性能特点**: 标准 POSIX 实现，跨平台兼容性好
- **线程安全**: 通过互斥锁保护共享状态

## 性能特性

### 时间复杂度
- `SetEvent`: O(1) - 常数时间
- `ResetEvent`: O(1) - 常数时间
- `TryWait`: O(1) - 常数时间
- `WaitFor`: O(1) - 阻塞等待，不消耗 CPU

### 性能建议
1. **自动重置事件**: 适用于生产者-消费者模式，避免惊群效应
2. **手动重置事件**: 适用于广播通知，一次信号唤醒所有等待者
3. **使用 TryWait**: 进行非阻塞状态检查，避免不必要的阻塞
4. **合理设置超时**: 避免无限等待导致的资源占用

## 最佳实践

### 事件类型选择
- **自动重置事件**: 适用于生产者-消费者模式，一次信号只唤醒一个等待者
- **手动重置事件**: 适用于广播通知，一次信号可以唤醒所有等待者

### 错误处理
```pascal
var
  Event: IEvent;
  Result: TWaitResult;
begin
  Event := MakeEvent(False, False);

  Result := Event.WaitFor(1000);

  case Result of
    wrSignaled:
      begin
        // 处理成功情况
        WriteLn('事件信号化成功');
      end;
    wrTimeout:
      begin
        // 处理超时情况
        WriteLn('等待超时');
      end;
    wrError:
      begin
        // 处理错误情况
        WriteLn('发生错误');
      end;
  end;
end;
```

### 资源管理
- 使用接口引用自动管理内存
- 事件对象在接口引用超出作用域时自动释放
- 避免循环引用导致的内存泄漏

### 并发安全
- 所有操作都是线程安全的
- 可以从多个线程同时调用同一事件对象的方法
- 避免在信号处理程序中调用事件方法（Unix 平台）

## 注意事项

1. **线程安全**: 所有方法都是线程安全的，可以并发调用
2. **资源清理**: 事件对象通过接口引用自动管理，无需手动释放
3. **平台差异**: Windows 和 Unix 平台在内部实现上有差异，但 API 行为一致
4. **超时精度**: 超时时间的精度取决于操作系统的调度器精度
5. **性能考虑**: 频繁的事件操作可能影响性能，建议进行性能测试
