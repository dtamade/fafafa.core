# fafafa.core.sync.event API 文档

## 概述

`fafafa.core.sync.event` 模块提供了跨平台的事件同步原语，支持 Windows 和 Unix 系统。事件是一种同步机制，允许线程等待特定条件的发生。

**版本**: 2.0
**最后更新**: 2025-01-XX
**兼容性**: Windows 7+, Linux 2.6+, macOS 10.9+

### 版本 2.0 重要改进

- ✅ **并发安全增强**: 修复了内存屏障和原子操作问题，消除竞态条件
- ✅ **平台一致性**: 统一了 Windows 和 Unix 平台的 API 行为和错误处理
- ✅ **中断机制优化**: 完全基于原子操作的可靠中断实现
- ✅ **错误处理完善**: 新增 `weNotSupported` 错误码，统一错误消息
- ✅ **性能优化**: 改进了热路径性能，减少不必要的系统调用
- ✅ **测试覆盖**: 新增边界条件、稳定性和并发安全测试

## 核心接口

### IEvent 接口

事件的主要接口，提供完整的事件操作功能。

```pascal
IEvent = interface(ISynchronizable)
  // 基础操作
  procedure SetEvent;                    // 设置事件为信号状态
  procedure ResetEvent;                  // 重置事件为非信号状态
  function WaitFor(ATimeoutMs: Cardinal): TWaitResult; // 等待事件信号
  function IsSignaled: Boolean;          // 检查事件是否处于信号状态
  
  // 扩展操作
  function TryWait: Boolean;             // 非阻塞等待
  procedure Pulse;                       // 脉冲信号
  
  // RAII 守卫方法
  function WaitGuard: IEventGuard;       // 阻塞等待并返回守卫
  function WaitGuard(ATimeoutMs: Cardinal): IEventGuard; // 带超时的等待守卫
  function TryWaitGuard: IEventGuard;    // 非阻塞等待守卫
  
  // 中断支持
  function WaitForInterruptible(ATimeoutMs: Cardinal): TWaitResult; // 可中断的等待
  procedure Interrupt;                   // 中断所有等待的线程
  function IsInterrupted: Boolean;       // 检查是否已被中断
  
  // 状态查询
  function IsManualReset: Boolean;       // 是否手动重置
  function GetWaitingThreadCount: Integer; // 等待线程数
  
  // 错误处理
  function GetLastError: TWaitError;     // 获取最后的错误
  function GetLastErrorMessage: string;  // 获取错误描述
  procedure ClearLastError;              // 清除错误状态
  
  // 调试和监控
  function GetDebugInfo: string;         // 获取调试信息
  function GetPerformanceCounters: string; // 获取性能计数器
  procedure ResetPerformanceCounters;    // 重置性能计数器
  procedure EnableDebugLogging(AEnabled: Boolean); // 启用调试日志
end;
```

### IEventGuard 接口

RAII 守卫接口，提供自动资源管理。

```pascal
IEventGuard = interface
  function IsValid: Boolean;    // 守卫是否有效
  function GetEvent: IEvent;    // 获取关联的事件对象
  procedure Release;            // 手动释放守卫
end;
```

## 工厂函数

### CreateEvent

创建事件对象的主要工厂函数。

```pascal
function CreateEvent(AManualReset: Boolean; AInitialState: Boolean): IEvent;
```

**参数：**
- `AManualReset`: 是否为手动重置事件
  - `True`: 手动重置事件，需要显式调用 `ResetEvent` 来重置
  - `False`: 自动重置事件，等待成功后自动重置
- `AInitialState`: 初始状态
  - `True`: 创建时处于信号状态
  - `False`: 创建时处于非信号状态

**返回值：**
- 返回 `IEvent` 接口实例

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

### TWaitError

错误类型枚举（版本 2.0 增强）。

```pascal
TWaitError = (
  weNone,              // 无错误
  weTimeout,           // 超时
  weInvalidHandle,     // 无效句柄
  weResourceExhausted, // 资源耗尽
  weAccessDenied,      // 访问被拒绝
  weDeadlock,          // 死锁
  weNotSupported,      // 功能不支持（新增）
  weSystemError        // 系统错误
);
```

#### 平台兼容性说明

- `weNotSupported`: 当调用平台不支持的功能时返回
  - Windows: `GetWaitingThreadCount` 返回此错误
  - Unix: 所有功能都支持，不会返回此错误

## 使用示例

### 基础用法

```pascal
var
  Event: IEvent;
  Result: TWaitResult;
begin
  // 创建自动重置事件，初始状态为非信号
  Event := CreateEvent(False, False);
  
  // 在另一个线程中设置事件
  Event.SetEvent;
  
  // 等待事件信号，最多等待1000毫秒
  Result := Event.WaitFor(1000);
  
  case Result of
    wrSignaled: WriteLn('事件被信号化');
    wrTimeout:  WriteLn('等待超时');
    wrError:    WriteLn('发生错误: ' + Event.GetLastErrorMessage);
  end;
end;
```

### RAII 守卫用法

```pascal
var
  Event: IEvent;
  Guard: IEventGuard;
begin
  Event := CreateEvent(True, False); // 手动重置事件
  
  // 使用守卫模式，自动管理资源
  Guard := Event.WaitGuard(5000);
  
  if Guard.IsValid then
  begin
    WriteLn('成功获取事件');
    // 守卫会在超出作用域时自动释放
  end
  else
    WriteLn('获取事件失败');
end;
```

### 中断支持用法

```pascal
var
  Event: IEvent;
  Result: TWaitResult;
begin
  Event := CreateEvent(False, False);
  
  // 在另一个线程中可能会调用 Event.Interrupt
  Result := Event.WaitForInterruptible(INFINITE);
  
  case Result of
    wrSignaled:  WriteLn('事件被信号化');
    wrAbandoned: WriteLn('等待被中断');
    wrError:     WriteLn('发生错误');
  end;
end;
```

### 调试和监控用法

```pascal
var
  Event: IEvent;
begin
  Event := CreateEvent(True, False);
  
  // 启用调试日志
  Event.EnableDebugLogging(True);
  
  // 执行一些操作
  Event.SetEvent;
  Event.WaitFor(100);
  Event.ResetEvent;
  
  // 查看性能统计
  WriteLn(Event.GetPerformanceCounters);
  WriteLn(Event.GetDebugInfo);
  
  // 重置计数器
  Event.ResetPerformanceCounters;
end;
```

## 平台差异

### Windows 平台
- 基于 Windows Event Objects 实现
- `GetWaitingThreadCount` 返回 -1（不支持）
- 支持所有功能

### Unix 平台
- 基于 pthread 条件变量实现
- `GetWaitingThreadCount` 返回实际等待线程数
- 支持所有功能
- 使用 `CLOCK_MONOTONIC`（Linux）避免时间跳变

## 性能优化

### 无锁快速路径
- `IsSignaled` 方法对手动重置事件使用原子操作
- `TryWait` 方法对手动重置事件优先使用快速检查
- 减少不必要的系统调用开销

### 性能建议
1. 对于高频状态查询，优先使用手动重置事件
2. 使用 `TryWait` 而不是 `WaitFor(0)` 进行非阻塞检查
3. 启用性能计数器监控热点操作
4. 在生产环境中禁用调试日志

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
  Event := CreateEvent(False, False);
  
  Result := Event.WaitFor(1000);
  
  if Result = wrError then
  begin
    WriteLn('错误: ' + Event.GetLastErrorMessage);
    // 处理错误情况
  end;
end;
```

### 资源管理
- 使用接口引用自动管理内存
- 考虑使用 RAII 守卫模式
- 避免长时间持有事件引用

### 并发安全
- 所有操作都是线程安全的
- 避免在信号处理程序中调用事件方法
- 注意中断机制的使用场景

## 注意事项

1. **PulseEvent 已修复**: Windows 实现不再使用不可靠的 `PulseEvent`
2. **时间跳变处理**: Unix 实现使用单调时钟避免系统时间调整影响
3. **中断语义**: 中断会导致 `WaitForInterruptible` 返回 `wrAbandoned`
4. **调试开销**: 启用调试日志会影响性能，仅在开发时使用
5. **跨平台兼容**: 某些功能在不同平台上行为略有差异，已在文档中说明
