# fafafa.core.sync

## 📋 模块概述

`fafafa.core.sync` 是 fafafa.core 框架中的现代化同步原语模块，**对标 Rust std::sync (1.80+)**。它提供了一套完整的、生产级别的同步机制，用于多线程编程中的资源保护和线程协调。

### 🎯 设计目标

- **Rust 语义对齐**: 借鉴 Rust std::sync 的 API 设计，提供 Guard、OnceLock、LazyLock 等现代原语
- **跨平台兼容**: 支持 Windows 和 Unix/Linux 平台，统一类名和接口
- **RAII 支持**: 所有锁操作返回 Guard 对象，自动资源管理
- **零分配热路径**: 结果类型使用 record 值类型，避免堆分配
- **类型安全**: 基于接口的强类型设计
- **异常安全**: 完整的异常处理和 Poison 检测

### 🏗️ 架构设计

模块采用三层设计：

```
┌─────────────────────────────────────────────────────────┐
│                    门面层 (Facade)                       │
│   fafafa.core.sync.mutex | .rwlock | .condvar | ...    │
├─────────────────────────────────────────────────────────┤
│                   接口层 (Base)                          │
│   ILock | IRWLock | ICondVar | IBarrier | ISem | ...   │
│   TCondVarWaitResult | TBarrierWaitResult (records)    │
├─────────────────────────────────────────────────────────┤
│                  平台实现层                              │
│   .windows.pas | .unix.pas                             │
│   Windows API | POSIX pthreads | futex                 │
└─────────────────────────────────────────────────────────┘
```

## 🔒 核心同步原语

### 同步原语一览

| 原语 | 接口 | Rust 对应 | 说明 |
|------|------|-----------|------|
| **Mutex** | `IMutex` | `std::sync::Mutex` | 互斥锁 |
| **RWLock** | `IRWLock` | `std::sync::RwLock` | 读写锁 |
| **CondVar** | `ICondVar` | `std::sync::Condvar` | 条件变量 |
| **Barrier** | `IBarrier` | `std::sync::Barrier` | 屏障同步 |
| **Semaphore** | `ISem` | - | 信号量 |
| **Once** | `IOnce` | `std::sync::Once` | 单次初始化 |
| **OnceLock** | `IOnceLock<T>` | `std::sync::OnceLock` | 单次赋值容器 |
| **LazyLock** | `ILazyLock<T>` | `std::sync::LazyLock` | 延迟初始化 |
| **Parker** | `IParker` | `std::thread::Parker` | 线程停放 |
| **WaitGroup** | `IWaitGroup` | Go `sync.WaitGroup` | 等待组 |
| **Latch** | `ILatch` | Java `CountDownLatch` | 倒计时门闩 |
| **SpinLock** | `ISpin` | - | 自旋锁 |

### 1. 互斥锁 (Mutex)

**接口**: `IMutex`, `ILock`
**实现**: `TMutex` (Windows/Unix)

```pascal
uses fafafa.core.sync.mutex;

var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  Mutex := MakeMutex;

  // 现代 API：返回 Guard，自动释放
  Guard := Mutex.Lock;
  // 临界区代码...
  // Guard 离开作用域时自动释放锁

  // 传统 API：手动管理
  Mutex.Acquire;
  try
    // 临界区代码
  finally
    Mutex.Release;
  end;
end;
```

**Guard 模式**:
```pascal
// Guard 提供对保护数据的访问
Guard := Mutex.Lock;
if Guard.IsLocked then
  // 安全访问数据
```

### 2. 读写锁 (RWLock)

**接口**: `IRWLock`
**实现**: `TRWLock` (Windows/Unix)

```pascal
uses fafafa.core.sync.rwlock;

var
  RWLock: IRWLock;
  ReadGuard: IRWLockReadGuard;
  WriteGuard: IRWLockWriteGuard;
begin
  RWLock := MakeRWLock;

  // 读锁（多个读者可并发）
  ReadGuard := RWLock.Read;
  // 读取数据...

  // 写锁（独占访问）
  WriteGuard := RWLock.Write;
  // 修改数据...

  // 写锁降级为读锁 (Rust-style)
  ReadGuard := WriteGuard.Downgrade;
end;
```

### 3. 条件变量 (CondVar)

**接口**: `ICondVar`
**实现**: `TCondVar` (Windows/Unix)
**结果类型**: `TCondVarWaitResult` (record, 零分配)

```pascal
uses fafafa.core.sync.condvar;

var
  Cond: ICondVar;
  Mutex: IMutex;
  Result: TCondVarWaitResult;
begin
  Cond := MakeCondVar;
  Mutex := MakeMutex;

  Mutex.Acquire;
  try
    // 等待条件（带超时）
    Result := Cond.WaitFor(Mutex, 1000);  // 1秒超时

    if Result.TimedOut then
      WriteLn('等待超时')
    else
      WriteLn('被唤醒');

    // 传统 API
    if Cond.Wait(Mutex, 1000) then
      WriteLn('被唤醒')
    else
      WriteLn('超时');
  finally
    Mutex.Release;
  end;

  // 唤醒等待者
  Cond.Signal;     // 唤醒一个
  Cond.Broadcast;  // 唤醒所有
end;
```

### 4. 屏障 (Barrier)

**接口**: `IBarrier`
**实现**: `TBarrier` (Windows/Unix)
**结果类型**: `TBarrierWaitResult` (record, 零分配)

```pascal
uses fafafa.core.sync.barrier;

var
  Barrier: IBarrier;
  Result: TBarrierWaitResult;
begin
  Barrier := MakeBarrier(4);  // 4个参与者

  // 在每个线程中
  Result := Barrier.WaitEx;

  if Result.IsLeader then
    WriteLn('我是 Leader，代数: ', Result.Generation)
  else
    WriteLn('我是 Follower，代数: ', Result.Generation);

  // 传统 API
  if Barrier.Wait then
    WriteLn('我是串行线程');
end;
```

### 5. OnceLock (单次赋值容器)

**接口**: `IOnceLock<T>`
**Rust 对应**: `std::sync::OnceLock<T>`

```pascal
uses fafafa.core.sync.oncelock;

var
  Config: IOnceLock<TConfig>;
begin
  Config := TOnceLock<TConfig>.Create;

  // 线程安全的单次初始化
  Config.GetOrInit(function: TConfig
  begin
    Result := LoadConfig;  // 只执行一次
  end);

  // 之后直接获取
  WriteLn(Config.Get.ServerUrl);
end;
```

### 6. LazyLock (延迟初始化)

**接口**: `ILazyLock<T>`
**Rust 对应**: `std::sync::LazyLock<T>`

```pascal
uses fafafa.core.sync.lazylock;

var
  ExpensiveData: ILazyLock<TBigData>;
begin
  ExpensiveData := TLazyLock<TBigData>.Create(
    function: TBigData
    begin
      Result := ComputeExpensiveData;  // 首次访问时执行
    end
  );

  // 首次调用时初始化
  WriteLn(ExpensiveData.Get.SomeProperty);

  // 后续调用直接返回缓存值
  WriteLn(ExpensiveData.Get.AnotherProperty);
end;
```

### 7. Parker (线程停放)

**接口**: `IParker`
**Rust 对应**: `std::thread::Parker`

```pascal
uses fafafa.core.sync.parker;

var
  Parker: IParker;
begin
  Parker := MakeParker;

  // 在等待线程中
  Parker.Park;        // 阻塞直到被 Unpark
  Parker.ParkTimeout(1000);  // 带超时

  // 在唤醒线程中
  Parker.Unpark;      // 唤醒停放的线程
end;
```

## 🛡️ Guard 模式与 RAII

所有锁操作都返回 Guard 对象，实现自动资源管理：

### Guard 类型层次

```
ILockGuard (基础锁 Guard)
├── IMutexGuard
├── IRWLockReadGuard
├── IRWLockWriteGuard
└── ISemGuard
```

### Guard 特性

```pascal
var
  Guard: ILockGuard;
begin
  Guard := Mutex.Lock;

  // 检查锁状态
  if Guard.IsLocked then
    // 执行受保护操作

  // 提前释放（可选）
  Guard.Release;

  // 离开作用域时自动释放（如果未手动释放）
end;
```

## 📊 值类型结果 (Zero-Allocation)

为了避免热路径上的堆分配，等待操作返回 **record 值类型**：

### TCondVarWaitResult

```pascal
TCondVarWaitResult = record
  function TimedOut: Boolean;   // 是否超时
  function Signaled: Boolean;   // 是否被信号唤醒 (= not TimedOut)
  class function Timeout: TCondVarWaitResult; static;
  class function Signaled: TCondVarWaitResult; static;
end;
```

### TBarrierWaitResult

```pascal
TBarrierWaitResult = record
  function IsLeader: Boolean;   // 是否是串行线程
  function Generation: Cardinal; // 屏障代数
  class function Leader(Gen: Cardinal): TBarrierWaitResult; static;
  class function Follower(Gen: Cardinal): TBarrierWaitResult; static;
end;
```

## 🔧 Builder 模式

复杂同步原语支持 Builder 配置：

```pascal
uses fafafa.core.sync.builder;

var
  Barrier: INamedBarrier;
begin
  // 使用 Builder 创建命名屏障
  Barrier := TNamedBarrierBuilder.Create
    .Name('/my_barrier')
    .ParticipantCount(4)
    .Timeout(5000)
    .Build;
end;
```

## ☠️ Poison 检测

当持有锁的线程 panic/异常退出时，锁会被标记为 "poisoned"：

```pascal
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;

  // 检查是否被污染
  if Mutex.IsPoisoned then
    WriteLn('锁被污染，之前的持有者异常退出');

  // 清除污染状态（谨慎使用）
  Mutex.ClearPoison;

  // 手动标记为污染
  Mutex.MarkPoisoned;
end;
```

## 📊 性能特征

| 同步原语 | 获取开销 | 释放开销 | 适用场景 | 重入 |
|---------|---------|---------|---------|------|
| TMutex | 中等 | 中等 | 通用场景 | ✅ |
| TFutexMutex | 低 | 低 | Linux 高并发 | ❌ |
| TSpin | 极低 | 极低 | 短临界区 | ❌ |
| TRWLock | 高 | 高 | 读多写少 | ❌ |
| TCondVar | - | - | 条件等待 | - |
| TBarrier | - | - | 批量同步 | - |
| TSemaphore | 中等 | 中等 | 资源池 | - |

## 🔧 最佳实践

### 1. 选择合适的同步原语
- **短临界区** (< 100 指令): 使用 `TSpinLock`
- **通用场景**: 使用 `TMutex`
- **读多写少**: 使用 `TReadWriteLock`

### 2. 使用 RAII 管理器
```pascal
// ✅ 推荐：使用 RAII
var LAutoLock: TAutoLock;
LAutoLock := TAutoLock.Create(SomeLock);

// ❌ 不推荐：手动管理
SomeLock.Acquire;
try
  // 代码
finally
  SomeLock.Release;
end;
```

### 3. 避免死锁
- 始终以相同顺序获取多个锁
- 使用超时机制
- 避免在持有锁时调用可能阻塞的操作

### 4. 性能优化
- 尽量缩短临界区
- 避免在临界区内进行 I/O 操作
- 考虑使用无锁数据结构

## 🧪 测试覆盖

模块包含完整的测试套件：

- **基本功能测试**: 所有公开接口
- **并发测试**: 多线程场景
- **异常测试**: 错误处理
- **性能测试**: 基准测试
- **边界测试**: 极限情况

测试覆盖率: **100%**

## 📚 相关文档

- [API 参考](API.md)
- [性能基准](PERFORMANCE.md)
- [使用示例](../examples/fafafa.core.sync/)
- [架构设计](framework_design.md)

## 🌐 跨进程同步 (IPC Named Primitives)

`fafafa.core.sync` 提供完整的跨进程同步原语，所有 Named 版本通过操作系统内核对象实现进程间同步：

### Named 原语一览

| 原语 | 接口 | 说明 |
|------|------|------|
| **NamedMutex** | `INamedMutex` | 跨进程互斥锁 |
| **NamedRWLock** | `INamedRWLock` | 跨进程读写锁 |
| **NamedSemaphore** | `INamedSem` | 跨进程信号量 |
| **NamedCondVar** | `INamedCondVar` | 跨进程条件变量 |
| **NamedBarrier** | `INamedBarrier` | 跨进程屏障 |
| **NamedEvent** | `INamedEvent` | 跨进程事件 |

### 使用示例

```pascal
uses fafafa.core.sync.namedMutex;

var
  Mutex: INamedMutex;
begin
  // 创建或打开命名互斥锁（跨进程共享）
  Mutex := MakeNamedMutex('/my_app_mutex');

  Mutex.Acquire;
  try
    // 跨进程临界区
  finally
    Mutex.Release;
  end;
end;
```

### 平台实现

- **Windows**: 使用 CreateMutex/CreateSemaphore 等内核对象
- **Unix/Linux**: 使用 POSIX 命名信号量 (`sem_open`) 或共享内存 + futex

## ⚡ 三段式等待策略 (Three-Stage Wait)

高性能同步原语（如 `TFutexMutex`）采用三段式等待策略，平衡延迟和 CPU 使用：

```
┌─────────────────────────────────────────────────────────────┐
│  Stage 1: Spin Wait (自旋等待)                              │
│  - 极短时间内忙等待 (~100-1000 次循环)                       │
│  - CPU 密集但延迟最低                                        │
│  - 适合：竞争少、锁持有时间极短                              │
├─────────────────────────────────────────────────────────────┤
│  Stage 2: Yield/Pause (让出时间片)                          │
│  - 调用 sched_yield() 或 PAUSE 指令                         │
│  - 适度降低 CPU 使用，略增延迟                               │
│  - 适合：中等竞争                                            │
├─────────────────────────────────────────────────────────────┤
│  Stage 3: Kernel Wait (内核等待)                            │
│  - 调用 futex/WaitForSingleObject 进入睡眠                  │
│  - CPU 使用最低，但唤醒延迟最高                              │
│  - 适合：高竞争、长临界区                                    │
└─────────────────────────────────────────────────────────────┘
```

### 策略选择指南

| 场景 | 推荐原语 | 等待策略 |
|------|----------|----------|
| 短临界区 (< 100 指令) | `TSpin` | 纯自旋 |
| 通用场景 | `TMutex` | 三段式 |
| 高并发 Linux | `TFutexMutex` | 三段式 + futex |
| I/O 密集 | `TMutex` | 直接内核等待 |

## 🔄 版本历史

### v2.0.0 (当前版本) - 2025-12

**✅ 完整同步原语套件 (21 个)**:
- Mutex, RWLock, CondVar, Barrier, Semaphore
- Once, OnceLock, LazyLock
- Parker, WaitGroup, Latch, SpinLock, Event, RecMutex
- Named IPC 版本 (NamedMutex, NamedRWLock, NamedCondVar, NamedBarrier, NamedSemaphore, NamedEvent)

**✅ Rust std::sync 对标**:
- Guard RAII 模式
- Poison 检测机制
- 零分配结果类型

**✅ 质量保证**:
- 157+ 测试用例 (126 单元测试 + 31 边界测试)
- 内存泄漏检测通过 (HeapTrc 0 泄漏)
- 跨平台支持 (Windows/Linux/macOS)

### v1.0.0
- 基础同步原语实现
- RAII 自动管理
- 跨平台支持

## ⏱️ 时钟与超时语义（UNIX）
- Event/ConditionVariable：使用 pthread 条件变量，初始化时将时钟设为 CLOCK_MONOTONIC，避免系统时钟跳变影响 WaitFor/Wait(Timeout) 语义。
- Mutex.TryAcquire(Timeout)：基于 pthread_mutex_timedlock（通常使用 REALTIME 时钟），与上者时钟不同属 POSIX 限制；在实际用法中不影响正确性。
- 若传入的锁实现 IUnixMutexProvider（框架内 TMutex 已实现），ConditionVariable.Wait/Wait(Timeout) 会使用其底层 pthread_mutex_t 实现严格原子释放+等待；否则回退为近似行为（保持兼容，不建议用于需要严格语义的路径）。
