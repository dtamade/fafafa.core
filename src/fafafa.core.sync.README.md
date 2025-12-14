# fafafa.core.sync - 企业级同步原语模块

## 概述

`fafafa.core.sync` 是一个跨平台、高性能的同步原语库，对标 Rust `std::sync`、Go `sync` 和 Java `java.util.concurrent`。

## 架构

```
fafafa.core.sync (facade)
├── 基础原语
│   ├── IMutex       - 互斥锁 (Rust: Mutex)
│   ├── IRWLock      - 读写锁 (Rust: RwLock)
│   ├── IRecMutex    - 可重入互斥锁
│   └── ISpin        - 自旋锁
│
├── 高级同步
│   ├── ICondVar     - 条件变量 (Rust: Condvar)
│   ├── ISem         - 计数信号量 (Java: Semaphore)
│   ├── IBarrier     - 屏障 (Rust: Barrier)
│   ├── IEvent       - 事件 (Windows-style)
│   ├── IWaitGroup   - 等待组 (Go: sync.WaitGroup)
│   └── ILatch       - 倒计时门闩 (Java: CountDownLatch)
│
├── 一次性初始化
│   ├── IOnce        - 一次性执行 (Go: sync.Once)
│   ├── OnceLock<T>  - 一次性设置容器 (Rust: OnceLock)
│   └── LazyLock<T>  - 延迟初始化 (Rust: LazyLock)
│
├── 泛型数据保护
│   ├── TMutexGuard<T>   - 互斥锁保护的数据 (Rust: Mutex<T>)
│   └── TRwLockGuard<T>  - 读写锁保护的数据 (Rust: RwLock<T>)
│
├── 命名同步原语 (跨进程)
│   ├── INamedMutex, INamedEvent, INamedSemaphore
│   ├── INamedBarrier, INamedCondVar, INamedRWLock
│   └── (用于进程间同步)
│
├── Builder 模式
│   ├── MutexBuilder, SemBuilder, RWLockBuilder
│   ├── CondVarBuilder, BarrierBuilder, OnceBuilder
│   ├── EventBuilder, WaitGroupBuilder, LatchBuilder
│   └── (流式配置 API)
│
└── 便捷方法
    ├── WithLock(lock, proc)    - 自动加锁执行
    └── TryWithLock(lock, proc) - 尝试加锁执行
```

## 类型对照表

| fafafa.core.sync | Rust std::sync | Go sync | Java j.u.c |
|------------------|----------------|---------|------------|
| IMutex | Mutex | Mutex | ReentrantLock |
| IRWLock | RwLock | RWMutex | ReentrantReadWriteLock |
| ICondVar | Condvar | Cond | Condition |
| ISem | - | - | Semaphore |
| IBarrier | Barrier | - | CyclicBarrier |
| IWaitGroup | - | WaitGroup | CountDownLatch |
| ILatch | - | - | CountDownLatch |
| IOnce | Once | Once | - |
| OnceLock<T> | OnceLock<T> | - | - |
| LazyLock<T> | LazyLock<T> | - | - |
| TMutexGuard<T> | Mutex<T> | - | - |
| TRwLockGuard<T> | RwLock<T> | - | - |
| IGuard | MutexGuard | - | - |

## 快速开始

### 基本用法

```pascal
uses
  fafafa.core.sync;

// 创建互斥锁
var Mutex := MakeMutex;
Mutex.Acquire;
try
  // 临界区
finally
  Mutex.Release;
end;

// RAII 风格（推荐）
begin
  var Guard := Mutex.LockGuard;
  // Guard 离开作用域自动释放
end;
```

### Builder 模式

```pascal
// 配置读写锁
var RWLock := RWLockBuilder
  .WithWriterPriority
  .WithMaxReaders(100)
  .Build;

// 配置信号量
var Sem := SemBuilder
  .WithMaxCount(10)
  .WithInitialCount(5)
  .Build;

// 配置屏障
var Barrier := BarrierBuilder
  .WithParticipantCount(4)
  .Build;

// 配置事件
var Event := EventBuilder
  .WithManualReset(True)
  .WithInitialState(False)
  .Build;

// 配置等待组
var WG := WaitGroupBuilder
  .WithInitialCount(3)
  .Build;

// 配置门闩
var Latch := LatchBuilder
  .WithCount(5)
  .Build;
```

### 便捷方法 WithLock / TryWithLock

```pascal
var Mutex := MakeMutex;

// WithLock - 自动加锁执行
WithLock(Mutex, procedure
begin
  // 临界区代码，自动加锁和解锁
  DoSomething;
end);

// TryWithLock - 尝试加锁，返回是否成功
if TryWithLock(Mutex, procedure
begin
  DoSomething;
end) then
  WriteLn('执行成功')
else
  WriteLn('获取锁失败');
```

### 泛型数据保护 (Rust 风格)

```pascal
type
  TConfig = record
    Value: Integer;
    Name: string;
  end;

var SharedConfig: specialize TMutexGuard<TConfig>;

// 初始化
SharedConfig := specialize TMutexGuard<TConfig>.Create;
SharedConfig.SetValue(Config);

// 线程安全访问
procedure ThreadProc;
begin
  var Guard := SharedConfig.Lock;
  try
    WriteLn(Guard.Value^.Name);
    Guard.Value^.Value := 42;
  finally
    Guard.Free;
  end;
end;

// 使用 Update 进行原子更新
SharedConfig.Update(procedure(var V: TConfig)
begin
  Inc(V.Value);
  V.Name := 'Updated';
end);

// 带超时的 TryLock
var Guard := SharedConfig.TryLockTimeout(1000); // 1秒超时
if Guard <> nil then
try
  // 操作数据
finally
  Guard.Free;
end;

// IntoInner - 消费 Guard 获取内部数据（无锁竞争时）
var Data := SharedConfig.IntoInner;
```

### 延迟初始化

```pascal
var
  ExpensiveResource: specialize TOnceLock<TResource>;

// 首次访问时初始化
var Resource := ExpensiveResource.GetOrInit(
  function: TResource
  begin
    Result := TResource.Create;
    Result.LoadFromFile('config.dat');
  end
);
```

## 平台实现

### Unix/Linux
- **IMutex**: `pthread_mutex_t` 或 `futex` (可配置)
- **IRWLock**: `pthread_rwlock_t`
- **IBarrier**: `pthread_barrier_t`
- **ICondVar**: `pthread_cond_t`

### Windows
- **IMutex**: `SRWLock` (Vista+) 或 `CriticalSection`
- **IRWLock**: `SRWLock`
- **IBarrier**: `SynchronizationBarrier`
- **ICondVar**: `ConditionVariable`

## 性能特性

### 基准测试结果 (Linux x86_64, 单线程)

**基础原语**
- Baseline (Inc, 无锁): 0.36 ns/op, 2.78B ops/s
- Mutex Acquire/Release: 18 ns/op, 55M ops/s
- RWLock Write: 245 ns/op, 4M ops/s

**RWLock 读模式对比** (重要!)
- NoReentry 模式: 117 ns/op, 8.5M ops/s ⬅ **推荐**
- Reentrant 模式: 1,451 ns/op, 689K ops/s (慢 12x)
- Guard 模式: 1,624 ns/op, 616K ops/s

**命名原语 (cross-process)**
- NamedMutex Acquire/Release: 132 ns/op, 7.6M ops/s
- NamedEvent Signal/Reset: 292 ns/op, 3.4M ops/s
- NamedMutex Create/Destroy: 37,503 ns/op

### 配置选择建议

**RWLock 模式选择**:
- 默认/高性能场景: 使用 `RWLockBuilder.WithReentrant(False)` (NoReentry)
- 需要可重入: 使用 `RWLockBuilder.WithReentrant(True)`，注意性能代价

**其他特性**:
- 自适应自旋: 在高竞争场景下自动调整策略
- MaxReaders 限制: RWLock 支持配置最大读者数
- 毒化检测: Rust 风格的 panic safety

## 线程安全性

所有同步原语都是线程安全的。接口设计遵循：
- **RAII**: Guard 对象自动管理锁的生命周期
- **异常安全**: 即使在异常情况下也能正确释放锁
- **毒化支持**: 检测持锁线程 panic 的情况

## 配置选项

通过 `fafafa.core.settings.inc` 配置：

```pascal
{$DEFINE FAFAFA_CORE_USE_FUTEX}    // 启用 Linux futex 优化
{$DEFINE FAFAFA_CORE_USE_SRWLOCK}  // 启用 Windows SRWLock
```

## 版本历史

- **v2.2** (2025-12): API 命名统一
  - 统一 Named 原语工厂函数命名为 `MakeNamed*` 风格
  - 移除 `CreateNamedMutex()`, `CreateNamedSemaphore()` (使用 `MakeNamed*` 代替)
  - IEvent 新增 `Signal()` 和 `Clear()` 别名 (跨平台命名)
  - NamedCondVar 添加实验性警告 (Windows Broadcast 风险)

- **v2.1** (2025-12): API 增强
  - 新增 WithLock/TryWithLock 便捷方法
  - 新增 EventBuilder, WaitGroupBuilder, LatchBuilder
  - TMutexGuard<T> 新增 TryLockTimeout, Update, IntoInner
  - TRwLockGuard<T> 新增 TryReadTimeout, TryWriteTimeout, Update
  - 标记过期别名: IReadWriteLock, ISemaphore, TLock.LockGuard
  - 标记 IRWLockReadGuard.IsValid, IRWLockWriteGuard.IsValid 为 deprecated

- **v2.0** (2024-12): 企业级重构
  - 新增 TMutexGuard<T>, TRwLockGuard<T>
  - 新增 Builder 模式 (CondVar, Barrier, Once)
  - 修复 TFutexMutex 多线程死锁
  - 实现 RWLock MaxReaders 限制
  - 统一 IGuard 接口

- **v1.0**: 初始版本

## 作者

fafafaStudio - dtamade@gmail.com
