# fafafa.core.sync.parker

## 概述

Parker 提供了一种轻量级的线程暂停/唤醒机制，类似于 Rust 的 `std::thread::park/unpark`。它比条件变量更简单，适合简单的线程同步场景。

## 核心概念

### Permit 机制

Parker 使用二进制许可（permit）机制：
- 每个 Parker 实例维护一个二进制许可状态（有/无）
- `Unpark()` 设置许可为可用状态
- `Park()` 消费许可，如果没有许可则阻塞
- 多次调用 `Unpark()` 只存储一个许可（不累积）

### 与条件变量的区别

| 特性 | Parker | CondVar |
|------|--------|---------|
| 复杂度 | 简单，无需显式锁 | 需要配合 Mutex 使用 |
| 许可机制 | 支持（可先 Unpark 后 Park） | 不支持（必须先等待） |
| 适用场景 | 简单的线程通知 | 复杂的条件等待 |
| 性能开销 | 较低 | 较高 |

## API 参考

### 类型定义

```pascal
type
  IParker = interface(ISynchronizable)
    ['{C5D7E8F9-1A2B-3C4D-5E6F-7A8B9C0D1E2F}']
    
    procedure Park;
    function ParkTimeout(ATimeoutMs: Cardinal): Boolean;
    function ParkDuration(const ADuration: TDuration): TWaitResult;
    procedure Unpark;
  end;
```

### 创建 Parker

```pascal
function MakeParker: IParker;
```

创建一个新的 Parker 实例，初始状态无许可。自动选择当前平台的最优实现。

**返回值**：
- `IParker` - Parker 接口实例

**线程安全性**：
- 返回的实例是线程安全的

### Park

```pascal
procedure Park;
```

暂停当前线程，等待唤醒。

**行为**：
- 如果有许可可用，消费许可并立即返回
- 否则阻塞当前线程直到另一个线程调用 `Unpark`

**线程安全性**：
- 线程安全，通常由"拥有"此 Parker 的线程调用

### ParkTimeout

```pascal
function ParkTimeout(ATimeoutMs: Cardinal): Boolean;
```

带超时的暂停。

**参数**：
- `ATimeoutMs` - 超时时间（毫秒）

**返回值**：
- `True` - 被 Unpark 唤醒
- `False` - 超时

**行为**：
- 如果有许可可用，消费许可并立即返回 `True`
- 否则阻塞直到 Unpark 或超时

### ParkDuration

```pascal
function ParkDuration(const ADuration: TDuration): TWaitResult;
```

使用 `TDuration` 的超时暂停，提供更灵活的时间单位支持。

**参数**：
- `ADuration` - 超时时间（TDuration 类型）

**返回值**：
- `wrSignaled` - 被 Unpark 唤醒
- `wrTimeout` - 超时

**行为**：
- 如果有许可可用，消费许可并立即返回 `wrSignaled`
- 否则阻塞直到 Unpark 或超时

### Unpark

```pascal
procedure Unpark;
```

唤醒或发放许可。

**行为**：
- 如果线程正在 Park 中等待，唤醒它
- 否则设置许可为可用，下次 Park 将立即返回
- 多次调用只存储一个许可

**线程安全性**：
- 线程安全，可从任意线程调用

## 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.parker;

var
  LParker: IParker;
begin
  LParker := MakeParker;
  
  // 线程 A（等待者）
  LParker.Park;  // 等待唤醒
  
  // 线程 B（唤醒者）
  LParker.Unpark;  // 唤醒线程 A
end;
```

### Permit 机制示例

```pascal
var
  LParker: IParker;
begin
  LParker := MakeParker;
  
  // 先发放许可
  LParker.Unpark;
  
  // 立即返回（消费许可）
  LParker.Park;
  
  WriteLn('立即返回，无需等待');
end;
```

### 带超时的等待

```pascal
var
  LParker: IParker;
  LAwakened: Boolean;
begin
  LParker := MakeParker;
  
  // 等待最多 1000 毫秒
  LAwakened := LParker.ParkTimeout(1000);
  
  if LAwakened then
    WriteLn('被唤醒')
  else
    WriteLn('超时');
end;
```

### 生产者-消费者模式

```pascal
type
  TProducerConsumer = class
  private
    FParker: IParker;
    FData: Integer;
    FHasData: Boolean;
  public
    constructor Create;
    procedure Produce(AValue: Integer);
    function Consume: Integer;
  end;

constructor TProducerConsumer.Create;
begin
  FParker := MakeParker;
  FHasData := False;
end;

procedure TProducerConsumer.Produce(AValue: Integer);
begin
  FData := AValue;
  FHasData := True;
  FParker.Unpark;  // 唤醒消费者
end;

function TProducerConsumer.Consume: Integer;
begin
  while not FHasData do
    FParker.Park;  // 等待数据
  
  Result := FData;
  FHasData := False;
end;
```

## 平台实现

### Windows

- 使用 `CriticalSection` + `Event` 实现
- 高效的内核对象同步
- 支持超时等待

### Unix/Linux/macOS

- 使用 `pthread_mutex` + `pthread_cond` 实现
- POSIX 标准兼容
- 支持超时等待

## 性能特性

### 开销分析

| 操作 | 开销 | 说明 |
|------|------|------|
| `MakeParker` | 低 | 分配同步对象 |
| `Park`（有许可） | 极低 | 仅原子操作 |
| `Park`（无许可） | 中 | 线程上下文切换 |
| `Unpark` | 低 | 原子操作 + 可能的唤醒 |

### 性能建议

1. **避免频繁创建**：重用 Parker 实例
2. **减少阻塞**：优先使用 Permit 机制
3. **合理超时**：避免过短的超时导致忙等待
4. **批量唤醒**：如需唤醒多个线程，考虑使用其他原语（如 Event）

## 使用场景

### 适合的场景

✅ **简单的线程通知**
```pascal
// 主线程通知工作线程
LWorkerParker.Unpark;
```

✅ **生产者-消费者模式**（单生产者单消费者）
```pascal
// 生产者发送数据后唤醒消费者
LParker.Unpark;
```

✅ **自定义同步原语的基础组件**
```pascal
// 构建更复杂的同步机制
type
  TCustomSync = class
  private
    FParker: IParker;
  end;
```

### 不适合的场景

❌ **多生产者多消费者**
- 使用 `CondVar` + `Mutex` 更合适

❌ **需要广播唤醒**
- 使用 `Event` 或 `CondVar.NotifyAll`

❌ **复杂的条件等待**
- 使用 `CondVar` 配合谓词检查

## 注意事项

### 线程绑定

⚠️ **Parker 实例不绑定特定线程**
- 可以从任意线程调用 `Unpark`
- 通常配合线程本地存储使用

### 虚假唤醒

⚠️ **Parker 不会产生虚假唤醒**
- 与 `CondVar` 不同，Parker 的唤醒总是有明确原因
- 无需在循环中检查条件

### 许可不累积

⚠️ **多次 Unpark 只存储一个许可**
```pascal
LParker.Unpark;
LParker.Unpark;  // 第二次调用无效
LParker.Park;    // 消费唯一的许可
LParker.Park;    // 阻塞（没有许可）
```

### 死锁风险

⚠️ **避免在持有锁时 Park**
```pascal
// ❌ 错误：可能死锁
LMutex.Lock;
try
  LParker.Park;  // 危险！
finally
  LMutex.Unlock;
end;

// ✅ 正确：先释放锁
LMutex.Unlock;
LParker.Park;
```

## 最佳实践

### 1. 配合线程本地存储

```pascal
threadvar
  GThreadParker: IParker;

procedure InitThreadParker;
begin
  if GThreadParker = nil then
    GThreadParker := MakeParker;
end;
```

### 2. 使用 Permit 机制避免竞态

```pascal
// 先设置许可，再启动线程
LParker.Unpark;
LThread := TThread.CreateAnonymousThread(
  procedure
  begin
    LParker.Park;  // 立即返回或等待
    // 执行工作
  end);
LThread.Start;
```

### 3. 超时处理

```pascal
const
  TIMEOUT_MS = 5000;
var
  LAwakened: Boolean;
begin
  LAwakened := LParker.ParkTimeout(TIMEOUT_MS);
  if not LAwakened then
  begin
    // 超时处理逻辑
    WriteLn('等待超时，执行清理');
  end;
end;
```

### 4. 资源清理

```pascal
// Parker 使用接口引用计数，无需手动释放
var
  LParker: IParker;
begin
  LParker := MakeParker;
  // 使用 Parker
  // 离开作用域时自动释放
end;
```

## 调试与测试

### 调试检查

```pascal
{$IFDEF DEBUG}
procedure DebugPark(const AParker: IParker; const AContext: string);
begin
  WriteLn(Format('[%s] Park 开始: %s', [DateTimeToStr(Now), AContext]));
  AParker.Park;
  WriteLn(Format('[%s] Park 结束: %s', [DateTimeToStr(Now), AContext]));
end;
{$ENDIF}
```

### 测试模板

```pascal
procedure TestParkerBasic;
var
  LParker: IParker;
begin
  LParker := MakeParker;
  
  // 测试 Permit 机制
  LParker.Unpark;
  LParker.Park;  // 应立即返回
  
  // 测试超时
  Assert(not LParker.ParkTimeout(100), '应该超时');
  
  WriteLn('Parker 基本测试通过');
end;
```

## 相关模块

- `fafafa.core.sync.condvar` - 条件变量（更复杂的等待机制）
- `fafafa.core.sync.event` - 事件对象（支持广播）
- `fafafa.core.sync.mutex` - 互斥锁（保护共享数据）
- `fafafa.core.sync.base` - 同步原语基础接口

## 参考资料

- Rust `std::thread::park/unpark` 文档
- POSIX `pthread_cond` 规范
- Windows Event Objects 文档

## 版本历史

- **v1.0** - 初始版本，支持基本的 Park/Unpark 功能
- 支持超时等待（ParkTimeout, ParkDuration）
- 跨平台实现（Windows/Unix）
