# fafafa.core.sync.builder - Builder 模式

## 概述

`fafafa.core.sync.builder` 模块提供流式 API 来配置和创建同步原语实例。遵循 Rust/Java Builder 模式设计，使代码更清晰、配置更灵活。

## 设计优势

| 特性 | 工厂函数 | Builder 模式 |
|------|----------|--------------|
| 简洁性 | ✅ 单行调用 | ⚠️ 多行链式 |
| 可配置性 | ⚠️ 参数多时复杂 | ✅ 可选配置 |
| 可读性 | ⚠️ 参数含义不明 | ✅ 方法名自解释 |
| 扩展性 | ❌ 需新增重载 | ✅ 新增方法即可 |

## 支持的 Builder

| Builder | 创建类型 | 可配置项 |
|---------|----------|----------|
| `MutexBuilder` | `IMutex` | 无（默认配置） |
| `SemBuilder` | `ISem` | MaxCount, InitialCount |
| `RWLockBuilder` | `IRWLock` | WriterPriority, FairMode, MaxReaders, SpinCount |
| `CondVarBuilder` | `ICondVar` | 无 |
| `BarrierBuilder` | `IBarrier` | ParticipantCount |
| `OnceBuilder` | `IOnce` | Callback |
| `EventBuilder` | `IEvent` | ManualReset, InitialState |
| `WaitGroupBuilder` | `IWaitGroup` | InitialCount |
| `LatchBuilder` | `ILatch` | Count |
| `SpinBuilder` | `ISpin` | 无 |
| `ParkerBuilder` | `IParker` | 无 |
| `RecMutexBuilder` | `IRecMutex` | SpinCount (Windows) |

---

## MutexBuilder

创建互斥锁实例。

```pascal
uses fafafa.core.sync.builder;

// 简单用法
var Mutex := MutexBuilder.Build;

// 等同于
var Mutex := MakeMutex;
```

---

## SemBuilder

创建信号量实例。

### 可配置项

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `WithMaxCount(N)` | 最大许可数 | 1 |
| `WithInitialCount(N)` | 初始许可数 | MaxCount |

### 使用示例

```pascal
// 二元信号量（默认）
var Sem := SemBuilder.Build;

// 计数信号量
var Sem := SemBuilder
  .WithMaxCount(10)
  .WithInitialCount(5)
  .Build;

// 空信号量（初始无许可）
var Sem := SemBuilder
  .WithMaxCount(10)
  .WithInitialCount(0)
  .Build;
```

---

## RWLockBuilder

创建读写锁实例。

### 可配置项

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `WithWriterPriority` | 写者优先模式 | False |
| `WithFairMode` | 公平模式 (FIFO) | False |
| `WithMaxReaders(N)` | 最大读者数 | 1024 |
| `WithSpinCount(N)` | 自旋次数 | 4000 |

### 使用示例

```pascal
// 默认配置
var RWLock := RWLockBuilder.Build;

// 写者优先
var RWLock := RWLockBuilder
  .WithWriterPriority
  .Build;

// 高并发读场景
var RWLock := RWLockBuilder
  .WithMaxReaders(10000)
  .WithSpinCount(8000)
  .Build;

// 完整配置
var RWLock := RWLockBuilder
  .WithWriterPriority
  .WithFairMode
  .WithMaxReaders(500)
  .WithSpinCount(2000)
  .Build;
```

---

## CondVarBuilder

创建条件变量实例。

```pascal
var CondVar := CondVarBuilder.Build;
```

---

## BarrierBuilder

创建屏障实例。

### 可配置项

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `WithParticipantCount(N)` | 参与者数量 | 2 |

### 使用示例

```pascal
// 4 个线程同步
var Barrier := BarrierBuilder
  .WithParticipantCount(4)
  .Build;

// 使用场景
TThread.CreateAnonymousThread(procedure begin
  // Phase 1
  Barrier.Wait;  // 等待所有线程到达
  // Phase 2
end).Start;
```

---

## OnceBuilder

创建一次性执行实例。

### 可配置项

| 方法 | 说明 |
|------|------|
| `WithCallback(Proc)` | 设置过程回调 |
| `WithCallback(Method)` | 设置方法回调 |
| `WithCallback(AnonymousProc)` | 设置匿名回调 |

### 使用示例

```pascal
// 无回调
var Once := OnceBuilder.Build;
Once.Do(@MyProc);

// 预设回调
procedure InitGlobal;
begin
  GlobalConfig := LoadConfig;
end;

var Once := OnceBuilder
  .WithCallback(@InitGlobal)
  .Build;

// 多次调用只执行一次
Once.Do;
Once.Do;  // 不再执行
```

---

## EventBuilder

创建事件实例。

### 可配置项

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `WithManualReset` | 手动重置模式 | False |
| `WithAutoReset` | 自动重置模式 | True |
| `WithInitialState(Bool)` | 初始信号状态 | False |

### 使用示例

```pascal
// 自动重置事件（默认）
var Event := EventBuilder.Build;

// 手动重置事件
var Event := EventBuilder
  .WithManualReset
  .Build;

// 初始已信号
var Event := EventBuilder
  .WithInitialState(True)
  .Build;

// 完整配置
var Event := EventBuilder
  .WithManualReset
  .WithInitialState(True)
  .Build;
```

### 手动 vs 自动重置

```
自动重置（默认）:
  Set → Wait 返回 → 自动 Reset → 下次 Wait 阻塞

手动重置:
  Set → Wait 返回 → 保持信号 → 需手动 Reset
```

---

## WaitGroupBuilder

创建等待组实例。

### 可配置项

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `WithInitialCount(N)` | 初始计数 | 0 |

### 使用示例

```pascal
// 默认（计数 = 0）
var WG := WaitGroupBuilder.Build;
WG.Add(5);

// 预设初始计数
var WG := WaitGroupBuilder
  .WithInitialCount(5)
  .Build;

// 等同于
var WG := MakeWaitGroup;
WG.Add(5);
```

---

## LatchBuilder

创建倒计数锁存器实例。

### 可配置项

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `WithCount(N)` | 初始计数 | 1 |

### 使用示例

```pascal
// 门控启动（1 个信号）
var StartGate := LatchBuilder
  .WithCount(1)
  .Build;

// 等待 5 个任务
var DoneLatch := LatchBuilder
  .WithCount(5)
  .Build;
```

---

## SpinBuilder

创建自旋锁实例。

```pascal
var Spin := SpinBuilder.Build;
```

---

## ParkerBuilder

创建 Parker 实例。

```pascal
var Parker := ParkerBuilder.Build;
```

---

## RecMutexBuilder

创建可重入互斥锁实例。

### 可配置项 (Windows 专用)

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `WithSpinCount(N)` | 自旋计数 | 系统默认 |

### 使用示例

```pascal
// 默认配置
var RecMutex := RecMutexBuilder.Build;

// Windows: 自定义自旋计数
{$IFDEF WINDOWS}
var RecMutex := RecMutexBuilder
  .WithSpinCount(4000)
  .Build;
{$ENDIF}
```

---

## 最佳实践

### 1. 简单场景用工厂函数

```pascal
// ✅ 简单场景
var Mutex := MakeMutex;
var WG := MakeWaitGroup;

// ⚠️ 过度使用 Builder
var Mutex := MutexBuilder.Build;  // 无必要
```

### 2. 复杂配置用 Builder

```pascal
// ✅ 多参数配置用 Builder
var RWLock := RWLockBuilder
  .WithWriterPriority
  .WithMaxReaders(500)
  .WithSpinCount(2000)
  .Build;

// ⚠️ 工厂函数参数过多
var RWLock := MakeRWLock(True, False, 500, 2000);  // 参数含义不清
```

### 3. 链式调用风格

```pascal
// ✅ 每个方法单独一行
var Sem := SemBuilder
  .WithMaxCount(10)
  .WithInitialCount(5)
  .Build;

// ⚠️ 单行过长
var Sem := SemBuilder.WithMaxCount(10).WithInitialCount(5).Build;
```

### 4. 配置复用

```pascal
// 创建多个相同配置的实例
function CreateHighConcurrencyRWLock: IRWLock;
begin
  Result := RWLockBuilder
    .WithMaxReaders(10000)
    .WithSpinCount(8000)
    .Build;
end;

var Lock1 := CreateHighConcurrencyRWLock;
var Lock2 := CreateHighConcurrencyRWLock;
```

---

## 与工厂函数对比

### 信号量

```pascal
// 工厂函数
var Sem := MakeSem(5, 10);  // 哪个是初始？哪个是最大？

// Builder（更清晰）
var Sem := SemBuilder
  .WithMaxCount(10)
  .WithInitialCount(5)
  .Build;
```

### 事件

```pascal
// 工厂函数
var Event := MakeEvent(True, False);  // 参数含义？

// Builder
var Event := EventBuilder
  .WithManualReset
  .WithInitialState(False)
  .Build;
```

### 屏障

```pascal
// 工厂函数
var Barrier := MakeBarrier(4);

// Builder（等效但更显式）
var Barrier := BarrierBuilder
  .WithParticipantCount(4)
  .Build;
```

---

## 相关文档

- [fafafa.core.sync](fafafa.core.sync.md) - 主同步模块
- [fafafa.core.sync.mutex](fafafa.core.sync.mutex.md) - 互斥锁
- [fafafa.core.sync.rwlock](fafafa.core.sync.rwlock.md) - 读写锁
- [fafafa.core.sync.modern](fafafa.core.sync.modern.md) - 现代同步原语

---

## 版本历史

### v1.0.0 (2025-12)
- 12 种 Builder 类型
- 完整流式 API 支持
- 类型安全的配置
