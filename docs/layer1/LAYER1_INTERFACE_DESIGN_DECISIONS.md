# Layer 1 接口设计决策文档

> 本文件位置：`docs/layer1/LAYER1_INTERFACE_DESIGN_DECISIONS.md`

## 文档信息

**日期**: 2026-01-19
**版本**: 1.0.0
**阶段**: Phase 3 - 设计讨论
**范围**: Layer 1（atomic + sync 模块）P1 级问题

---

## 执行摘要

本文档记录了 Layer 1 接口审查中发现的 7 个 P1 级问题的设计讨论和决策。每个问题都经过详细分析，对比参考设计（Rust std::sync, C++11 std::atomic, Java java.util.concurrent），并提出具体的解决方案。

**问题概览**:
- P1-001: atomic - 缺少 Fence 操作
- P1-002: atomic - CompareExchange 缺少单内存序版本
- P1-003: atomic - 缺少内存序语义文档
- P1-004: sync.base - ILock 接口缺少 TryLockFor 方法
- P1-005: sync.core - Mutex 缺少 Poison 机制的完整实现
- P1-006: sync.core - RWLock 缺少公平性配置
- P1-007: sync.named - NamedCondVar 标记为实验性

---

## 1. P1-001: atomic - 缺少 Fence 操作

### 1.1 问题描述

**当前状态**: `fafafa.core.atomic` 模块缺少内存屏障（fence）操作
**影响**: 高 - 影响高级并发编程能力，无法实现某些无锁算法

### 1.2 参考设计对比

#### C++11 std::atomic
```cpp
// C++11 提供两种 fence 操作
void atomic_thread_fence(memory_order order);
void atomic_signal_fence(memory_order order);
```

**语义**:
- `atomic_thread_fence`: 线程间同步屏障，影响所有线程的内存可见性
- `atomic_signal_fence`: 信号处理器屏障，只影响当前线程和信号处理器

#### Rust std::sync::atomic
```rust
// Rust 提供类似的 fence 操作
pub fn fence(order: Ordering);
pub fn compiler_fence(order: Ordering);
```

**语义**:
- `fence`: 硬件内存屏障，等价于 C++ `atomic_thread_fence`
- `compiler_fence`: 编译器屏障，防止编译器重排序，等价于 C++ `atomic_signal_fence`

### 1.3 设计决策

**决策**: 添加两种 fence 操作，遵循 C++11 命名约定

**理由**:
1. **兼容性**: C++11 命名更广为人知，与现有 C 风格 API 一致
2. **完整性**: 提供完整的内存屏障功能，支持高级并发编程
3. **清晰性**: 两种 fence 的语义区别明确

**实现方案**:

```pascal
{**
 * @desc 线程间内存屏障
 * @details 建立线程间的同步关系，确保屏障前的内存操作对其他线程可见
 *
 * @param aOrder 内存序
 *   - mo_acquire: 获取屏障，确保屏障后的读操作不会被重排到屏障前
 *   - mo_release: 释放屏障，确保屏障前的写操作不会被重排到屏障后
 *   - mo_acq_rel: 获取+释放屏障，结合两者的效果
 *   - mo_seq_cst: 顺序一致性屏障，最强的同步保证
 *   - mo_relaxed: 无效，会触发运行时错误
 *
 * @usage
 *   // 生产者-消费者模式
 *   atomic_store(data, 42, mo_relaxed);
 *   atomic_thread_fence(mo_release);  // 确保 data 写入对消费者可见
 *   atomic_store(flag, 1, mo_relaxed);
 *
 * @thread_safety 线程安全
 * @performance 性能开销取决于内存序和硬件平台
 * @rust_equivalent std::sync::atomic::fence
 * @cpp_equivalent std::atomic_thread_fence
 *}
procedure atomic_thread_fence(aOrder: memory_order_t);

{**
 * @desc 编译器内存屏障（信号处理器屏障）
 * @details 防止编译器重排序，但不影响硬件层面的内存可见性
 *          主要用于信号处理器和当前线程之间的同步
 *
 * @param aOrder 内存序（语义同 atomic_thread_fence）
 *
 * @usage
 *   // 信号处理器中使用
 *   atomic_store(flag, 1, mo_relaxed);
 *   atomic_signal_fence(mo_release);  // 防止编译器重排序
 *
 * @thread_safety 线程安全
 * @performance 零开销（仅编译器指令）
 * @rust_equivalent std::sync::atomic::compiler_fence
 * @cpp_equivalent std::atomic_signal_fence
 *}
procedure atomic_signal_fence(aOrder: memory_order_t);
```

**实现位置**: `src/fafafa.core.atomic.pas`

**测试要求**:
1. 验证 fence 操作的正确性（生产者-消费者模式）
2. 验证不同内存序的效果
3. 验证 `mo_relaxed` 参数触发错误

**文档要求**:
1. 在模块文档中添加 fence 操作的使用指南
2. 提供典型使用场景示例
3. 说明与 C++11/Rust 的对应关系

---

## 2. P1-002: atomic - CompareExchange 缺少单内存序版本

### 2.1 问题描述

**当前状态**: CompareExchange 只有无参数版本（默认 `mo_seq_cst`）和双内存序版本
**影响**: 中等 - 缺少便利 API，影响代码简洁性

### 2.2 参考设计对比

#### C++11 std::atomic
```cpp
// C++11 提供三种 compare_exchange_strong 版本
bool compare_exchange_strong(T& expected, T desired);  // 默认 seq_cst
bool compare_exchange_strong(T& expected, T desired,
                             memory_order order);       // 单内存序
bool compare_exchange_strong(T& expected, T desired,
                             memory_order success,
                             memory_order failure);     // 双内存序
```

**语义**:
- 单内存序版本：success 和 failure 使用相同的内存序
- 双内存序版本：success 和 failure 使用不同的内存序

#### Rust std::sync::atomic
```rust
// Rust 只提供双内存序版本
pub fn compare_exchange(&self, current: T, new: T,
                        success: Ordering,
                        failure: Ordering) -> Result<T, T>;
```

**注意**: Rust 不提供单内存序版本，要求显式指定两个内存序

### 2.3 设计决策

**决策**: 添加单内存序版本，遵循 C++11 设计

**理由**:
1. **便利性**: 大多数情况下 success 和 failure 使用相同的内存序
2. **兼容性**: 与 C++11 保持一致
3. **简洁性**: 减少代码冗余

**实现方案**:

```pascal
{**
 * @desc 原子比较交换（单内存序版本）
 * @details 如果 aObj 等于 aExpected，则将 aObj 设置为 aDesired 并返回 True
 *          否则将 aExpected 设置为 aObj 的当前值并返回 False
 *          success 和 failure 使用相同的内存序
 *
 * @param aObj 原子对象
 * @param aExpected 期望值（输入输出参数）
 * @param aDesired 新值
 * @param aOrder 内存序（同时用于 success 和 failure）
 *
 * @returns 如果交换成功返回 True，否则返回 False
 *
 * @usage
 *   var
 *     counter: Int32 = 0;
 *     expected: Int32 = 0;
 *   begin
 *     // 使用 acquire-release 语义
 *     if atomic_compare_exchange_strong(counter, expected, 1, mo_acq_rel) then
 *       WriteLn('CAS succeeded')
 *     else
 *       WriteLn('CAS failed, current value: ', expected);
 *   end;
 *
 * @thread_safety 线程安全
 * @performance 性能开销取决于内存序和硬件平台
 * @cpp_equivalent std::atomic::compare_exchange_strong(expected, desired, order)
 *}
function atomic_compare_exchange_strong(var aObj: Int32; var aExpected: Int32;
                                        aDesired: Int32; aOrder: memory_order_t): Boolean; overload;
function atomic_compare_exchange_strong(var aObj: Int64; var aExpected: Int64;
                                        aDesired: Int64; aOrder: memory_order_t): Boolean; overload;
function atomic_compare_exchange_strong(var aObj: UInt32; var aExpected: UInt32;
                                        aDesired: UInt32; aOrder: memory_order_t): Boolean; overload;
function atomic_compare_exchange_strong(var aObj: UInt64; var aExpected: UInt64;
                                        aDesired: UInt64; aOrder: memory_order_t): Boolean; overload;
function atomic_compare_exchange_strong(var aObj: Pointer; var aExpected: Pointer;
                                        aDesired: Pointer; aOrder: memory_order_t): Boolean; overload;
```

**实现位置**: `src/fafafa.core.atomic.pas`

**测试要求**:
1. 验证单内存序版本的正确性
2. 验证与双内存序版本的等价性
3. 验证不同内存序的效果

**文档要求**:
1. 在模块文档中说明三种 CompareExchange 版本的区别
2. 提供使用场景建议
3. 说明与 C++11 的对应关系

---

## 3. P1-003: atomic - 缺少内存序语义文档

### 3.1 问题描述

**当前状态**: 内存序枚举只有简短注释，缺少详细的语义说明
**影响**: 高 - 影响 API 可用性，用户难以正确使用内存序

### 3.2 参考设计对比

#### C++11 std::memory_order
C++11 标准提供了详细的内存序语义说明：

- **memory_order_relaxed**: 只保证原子性，不提供同步或顺序保证
- **memory_order_consume**: 数据依赖顺序（已废弃，实现为 acquire）
- **memory_order_acquire**: 获取语义，确保后续读写不会被重排到此操作之前
- **memory_order_release**: 释放语义，确保之前的读写不会被重排到此操作之后
- **memory_order_acq_rel**: 获取+释放语义，结合两者的效果
- **memory_order_seq_cst**: 顺序一致性，最强的同步保证

#### Rust std::sync::atomic::Ordering
Rust 提供了类似的内存序，并有详细的文档说明。

### 3.3 设计决策

**决策**: 编写详细的内存序语义文档，包括：
1. 每种内存序的语义说明
2. 使用场景和示例
3. 性能影响
4. 与 C++11/Rust 的对应关系

**实现方案**:

在 `src/fafafa.core.atomic.pas` 中添加详细的文档注释：

```pascal
{**
 * @desc 内存序枚举
 * @details 定义原子操作的内存顺序语义，影响多线程环境下的内存可见性和操作顺序
 *
 * @memory_order_semantics
 *
 * **mo_relaxed（松弛序）**:
 * - 语义：只保证原子性，不提供同步或顺序保证
 * - 用途：计数器、统计信息等不需要同步的场景
 * - 性能：最快，无额外开销
 * - 示例：
 *   ```pascal
 *   atomic_fetch_add(counter, 1, mo_relaxed);  // 简单计数
 *   ```
 *
 * **mo_consume（消费序）**:
 * - 语义：数据依赖顺序（C++17 已废弃，当前实现等价于 mo_acquire）
 * - 用途：不推荐使用，使用 mo_acquire 代替
 * - 性能：等价于 mo_acquire
 *
 * **mo_acquire（获取序）**:
 * - 语义：获取语义，确保此操作之后的读写不会被重排到此操作之前
 * - 用途：读取共享数据，与 mo_release 配对使用
 * - 性能：中等，可能需要内存屏障
 * - 示例：
 *   ```pascal
 *   // 消费者读取数据
 *   if atomic_load(flag, mo_acquire) = 1 then
 *     value := atomic_load(data, mo_relaxed);  // 保证 data 已写入
 *   ```
 *
 * **mo_release（释放序）**:
 * - 语义：释放语义，确保此操作之前的读写不会被重排到此操作之后
 * - 用途：写入共享数据，与 mo_acquire 配对使用
 * - 性能：中等，可能需要内存屏障
 * - 示例：
 *   ```pascal
 *   // 生产者写入数据
 *   atomic_store(data, 42, mo_relaxed);
 *   atomic_store(flag, 1, mo_release);  // 确保 data 写入对消费者可见
 *   ```
 *
 * **mo_acq_rel（获取-释放序）**:
 * - 语义：获取+释放语义，结合两者的效果
 * - 用途：读-修改-写操作（如 fetch_add, compare_exchange）
 * - 性能：中等，可能需要内存屏障
 * - 示例：
 *   ```pascal
 *   // 原子递增
 *   old_value := atomic_fetch_add(counter, 1, mo_acq_rel);
 *   ```
 *
 * **mo_seq_cst（顺序一致性）**:
 * - 语义：最强的同步保证，所有线程看到相同的操作顺序
 * - 用途：默认选择，适用于大多数场景
 * - 性能：最慢，可能需要全局同步
 * - 示例：
 *   ```pascal
 *   // 默认使用 seq_cst
 *   atomic_store(flag, 1);  // 等价于 atomic_store(flag, 1, mo_seq_cst)
 *   ```
 *
 * @performance_guide
 * - 优先使用 mo_seq_cst（默认），除非性能分析表明需要优化
 * - 对于简单计数器，可以使用 mo_relaxed
 * - 对于生产者-消费者模式，使用 mo_release/mo_acquire 配对
 * - 对于读-修改-写操作，使用 mo_acq_rel
 *
 * @cpp_equivalent std::memory_order
 * @rust_equivalent std::sync::atomic::Ordering
 *}
type
  memory_order_t = (
    mo_relaxed,   // 只保证原子性，无同步
    mo_consume,   // 数据依赖顺序（已废弃，等价于 mo_acquire）
    mo_acquire,   // 获取语义
    mo_release,   // 释放语义
    mo_acq_rel,   // 获取+释放语义
    mo_seq_cst    // 顺序一致性（默认）
  );
```

**文档位置**:
1. `src/fafafa.core.atomic.pas` - 源代码文档注释
2. `docs/fafafa.core.atomic.md` - 用户文档
3. `docs/API_Reference.md` - API 参考文档

**测试要求**:
1. 验证文档示例的正确性
2. 提供更多使用场景示例

**文档要求**:
1. 在用户文档中添加内存序使用指南
2. 提供常见使用模式的示例
3. 说明性能影响和优化建议

---

## 4. P1-004: sync.base - ILock 接口缺少 TryLockFor 方法

### 4.1 问题描述

**当前状态**: `ILock` 和 `ITryLock` 接口分离，`ILock` 只有基本的 `Lock()` 方法
**影响**: 中等 - 接口层次不够简洁，使用不便

### 4.2 参考设计对比

#### Rust std::sync::Mutex
```rust
// Rust Mutex 提供统一的接口
impl<T> Mutex<T> {
    pub fn lock(&self) -> LockResult<MutexGuard<T>>;
    pub fn try_lock(&self) -> TryLockResult<MutexGuard<T>>;
    // 注意：Rust 标准库没有 try_lock_for，但 parking_lot 提供了
}
```

#### Java java.util.concurrent.locks.Lock
```java
// Java Lock 接口提供完整的锁操作
public interface Lock {
    void lock();
    boolean tryLock();
    boolean tryLock(long timeout, TimeUnit unit);
    void unlock();
}
```

### 4.3 设计决策

**决策**: 重构接口层次，将 `TryLockFor` 方法合并到 `ILock` 接口

**理由**:
1. **简洁性**: 减少接口层次，使用更方便
2. **一致性**: 与 Java Lock 接口保持一致
3. **完整性**: 提供完整的锁操作功能

**实现方案**:

```pascal
{**
 * @desc 基础锁接口
 * @details 提供完整的锁操作功能，包括阻塞获取、非阻塞尝试和带超时尝试
 *
 * @methods
 *   - Acquire(): 阻塞获取锁（传统 API）
 *   - Release(): 释放锁（传统 API）
 *   - TryAcquire(): 非阻塞尝试获取锁（传统 API）
 *   - TryAcquire(ATimeoutMs): 带超时尝试获取锁（传统 API）
 *   - Lock(): 阻塞获取锁，返回守卫（现代 API）
 *   - TryLock(): 非阻塞尝试获取锁，返回守卫（现代 API）
 *   - TryLockFor(ATimeoutMs): 带超时尝试获取锁，返回守卫（现代 API）
 *
 * @usage
 *   // 现代 API（推荐）
 *   var guard := mutex.Lock();
 *   try
 *     // 临界区代码
 *   finally
 *     guard := nil;  // 自动释放锁
 *   end;
 *
 *   // 带超时的现代 API
 *   var guard := mutex.TryLockFor(1000);  // 1秒超时
 *   if guard <> nil then
 *   try
 *     // 临界区代码
 *   finally
 *     guard := nil;
 *   end;
 *
 * @thread_safety 线程安全
 * @rust_equivalent std::sync::Mutex (部分)
 * @java_equivalent java.util.concurrent.locks.Lock
 *}
type
  ILock = interface(ISynchronizable)
    ['{GUID-FOR-ILOCK}']
    
    // 传统 API
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    
    // 现代 API（RAII 守卫）
    function Lock: ILockGuard;
    function TryLock: ILockGuard;
    function TryLockFor(ATimeoutMs: Cardinal): ILockGuard;
  end;
```

**废弃接口**:
```pascal
{**
 * @desc 可尝试锁接口（已废弃）
 * @deprecated 使用 ILock 接口代替，ILock 现在包含所有锁操作
 *}
type
  ITryLock = interface(ILock)
    ['{GUID-FOR-ITRYLOCK}']
    // 所有方法已移至 ILock
  end deprecated 'Use ILock instead';
```

**迁移指南**:
1. 将所有 `ITryLock` 引用替换为 `ILock`
2. 代码行为保持不变
3. 编译器会发出废弃警告

**实现位置**: `src/fafafa.core.sync.base.pas`

**测试要求**:
1. 验证新接口的正确性
2. 验证向后兼容性
3. 验证迁移指南的有效性

**文档要求**:
1. 更新 API 参考文档
2. 提供迁移指南
3. 标记废弃接口

---

## 5. P1-005: sync.core - Mutex 缺少 Poison 机制的完整实现

### 5.1 问题描述

**当前状态**: `IMutex` 定义了 Poison 相关方法，但缺少详细的语义文档
**影响**: 高 - 影响 API 可用性和正确性

### 5.2 参考设计对比

#### Rust std::sync::Mutex
```rust
// Rust Mutex 的 Poison 机制
impl<T> Mutex<T> {
    pub fn lock(&self) -> LockResult<MutexGuard<T>>;
    pub fn is_poisoned(&self) -> bool;
}

pub type LockResult<Guard> = Result<Guard, PoisonError<Guard>>;

impl<T> PoisonError<T> {
    pub fn into_inner(self) -> T;  // 恢复守卫
    pub fn get_ref(&self) -> &T;   // 获取守卫引用
}
```

**Poison 语义**:
- 当线程在持有锁时 panic，锁会被标记为 "poisoned"
- 后续尝试获取锁会返回 `Err(PoisonError)`
- 可以通过 `into_inner()` 恢复守卫，继续使用

#### C++ std::mutex
C++ 没有 Poison 机制，线程异常时锁不会自动释放（未定义行为）

### 5.3 设计决策

**决策**: 完善 Mutex Poison 机制的文档和实现

**理由**:
1. **安全性**: Poison 机制提供了额外的安全保证
2. **兼容性**: 与 Rust 保持一致
3. **可用性**: 清晰的文档有助于正确使用

**实现方案**:

```pascal
{**
 * @desc 互斥锁接口
 * @details 提供互斥锁功能，支持 Poison 机制
 *
 * @poison_mechanism
 * Poison 机制用于检测线程在持有锁时发生异常的情况：
 *
 * 1. **Poison 触发条件**：
 *    - 线程在持有锁时抛出未捕获的异常
 *    - 守卫析构时检测到异常状态
 *
 * 2. **Poison 状态**：
 *    - 锁被标记为 "poisoned"
 *    - `IsPoisoned()` 返回 True
 *
 * 3. **Poison 影响**：
 *    - 后续 `Lock()` 调用返回 poisoned 守卫
 *    - 守卫的 `IsPoisoned()` 方法返回 True
 *    - 可以选择忽略 poison 状态继续使用
 *
 * 4. **Poison 恢复**：
 *    - 调用 `ClearPoison()` 清除 poison 状态
 *    - 或者通过守卫继续使用（自行承担风险）
 *
 * @usage
 *   // 基本使用
 *   var guard := mutex.Lock();
 *   try
 *     // 临界区代码
 *   finally
 *     guard := nil;
 *   end;
 *
 *   // 检查 Poison 状态
 *   if mutex.IsPoisoned() then
 *   begin
 *     WriteLn('Warning: Mutex is poisoned!');
 *     mutex.ClearPoison();  // 清除 poison 状态
 *   end;
 *
 *   // 使用 poisoned 守卫
 *   var guard := mutex.Lock();
 *   if guard.IsPoisoned() then
 *   begin
 *     WriteLn('Warning: Guard is poisoned, but continuing...');
 *     // 自行承担风险继续使用
 *   end;
 *
 * @thread_safety 线程安全
 * @rust_equivalent std::sync::Mutex
 *}
type
  IMutex = interface(ILock)
    ['{GUID-FOR-IMUTEX}']
    
    {**
     * @desc 检查锁是否处于 poisoned 状态
     * @returns 如果锁被 poison 返回 True，否则返回 False
     *}
    function IsPoisoned: Boolean;
    
    {**
     * @desc 清除锁的 poison 状态
     * @details 清除后，锁恢复正常状态，可以安全使用
     *}
    procedure ClearPoison;
  end;

{**
 * @desc 锁守卫接口
 * @details 提供 RAII 风格的锁管理，支持 Poison 检测
 *}
type
  ILockGuard = interface(IGuard)
    ['{GUID-FOR-ILOCKGUARD}']
    
    {**
     * @desc 检查守卫是否处于 poisoned 状态
     * @returns 如果守卫被 poison 返回 True，否则返回 False
     *}
    function IsPoisoned: Boolean;
  end;
```

**实现位置**: `src/fafafa.core.sync.mutex.base.pas`

**测试要求**:
1. 验证 Poison 机制的正确性
2. 验证异常情况下的 Poison 触发
3. 验证 `ClearPoison()` 的效果
4. 验证 poisoned 守卫的行为

**文档要求**:
1. 在模块文档中添加 Poison 机制的详细说明
2. 提供使用示例
3. 说明与 Rust 的对应关系

---

## 6. P1-006: sync.core - RWLock 缺少公平性配置

### 6.1 问题描述

**当前状态**: `IRWLock` 接口缺少公平性配置选项
**影响**: 中等 - 影响锁的性能和公平性

### 6.2 参考设计对比

#### Rust parking_lot::RwLock
```rust
// parking_lot 提供公平性配置
pub struct RwLock<T> {
    // 默认使用写优先策略
}

// 可以通过 RwLockFair 使用公平策略
pub struct RwLockFair<T> {
    // 使用公平策略，防止写饥饿
}
```

#### Java java.util.concurrent.locks.ReentrantReadWriteLock
```java
// Java 提供公平性配置
public ReentrantReadWriteLock(boolean fair) {
    // fair = true: 公平模式（FIFO）
    // fair = false: 非公平模式（性能优先）
}
```

### 6.3 设计决策

**决策**: 添加公平性配置选项，提供多种策略

**理由**:
1. **灵活性**: 不同场景需要不同的公平性策略
2. **性能**: 非公平模式性能更好
3. **公平性**: 公平模式防止饥饿

**实现方案**:

```pascal
{**
 * @desc 读写锁公平性策略
 * @details 定义读写锁的公平性行为
 *
 * @fairness_strategies
 *
 * **WriterPreferred（写优先）**:
 * - 语义：写者优先获取锁，读者可能饥饿
 * - 用途：写操作频繁的场景
 * - 性能：写操作延迟低，读操作可能延迟高
 * - 示例：日志系统、数据库写入
 *
 * **ReaderPreferred（读优先）**:
 * - 语义：读者优先获取锁，写者可能饥饿
 * - 用途：读操作频繁的场景
 * - 性能：读操作延迟低，写操作可能延迟高
 * - 示例：配置读取、缓存查询
 *
 * **Fair（公平模式）**:
 * - 语义：按照请求顺序获取锁（FIFO）
 * - 用途：需要公平性保证的场景
 * - 性能：中等，无饥饿
 * - 示例：任务调度、资源分配
 *
 * @performance_guide
 * - 默认使用 WriterPreferred（性能最好）
 * - 如果写者饥饿，使用 Fair
 * - 如果读者饥饿，使用 ReaderPreferred
 *
 * @rust_equivalent parking_lot::RwLock (WriterPreferred), parking_lot::RwLockFair (Fair)
 * @java_equivalent ReentrantReadWriteLock(fair)
 *}
type
  TRWLockFairness = (
    WriterPreferred,  // 写优先（默认）
    ReaderPreferred,  // 读优先
    Fair              // 公平模式（FIFO）
  );

{**
 * @desc 创建读写锁
 * @param AFairness 公平性策略（默认 WriterPreferred）
 * @returns 读写锁实例
 *
 * @usage
 *   // 默认写优先
 *   var rwlock := MakeRWLock();
 *
 *   // 公平模式
 *   var rwlock := MakeRWLock(Fair);
 *
 *   // 读优先
 *   var rwlock := MakeRWLock(ReaderPreferred);
 *}
function MakeRWLock(AFairness: TRWLockFairness = WriterPreferred): IRWLock;

{**
 * @desc 读写锁接口
 * @details 提供读写锁功能，支持公平性配置
 *}
type
  IRWLock = interface(ISynchronizable)
    ['{GUID-FOR-IRWLOCK}']
    
    // 读锁操作
    function Read: IRWLockReadGuard;
    function TryRead: IRWLockReadGuard;
    function TryReadFor(ATimeoutMs: Cardinal): IRWLockReadGuard;
    
    // 写锁操作
    function Write: IRWLockWriteGuard;
    function TryWrite: IRWLockWriteGuard;
    function TryWriteFor(ATimeoutMs: Cardinal): IRWLockWriteGuard;
    
    // 查询公平性策略
    function GetFairness: TRWLockFairness;
  end;
```

**实现位置**: `src/fafafa.core.sync.rwlock.pas`

**测试要求**:
1. 验证不同公平性策略的正确性
2. 验证饥饿情况的处理
3. 性能基准测试（对比不同策略）

**文档要求**:
1. 在模块文档中添加公平性策略的详细说明
2. 提供使用场景建议
3. 提供性能对比数据

---

## 7. P1-007: sync.named - NamedCondVar 标记为实验性

### 7.1 问题描述

**当前状态**: `INamedCondVar` 标记为实验性（EXPERIMENTAL）
**影响**: 中等 - 影响 API 稳定性和用户信心

### 7.2 参考设计对比

#### POSIX pthread_cond_t
```c
// POSIX 提供跨进程条件变量
pthread_condattr_t attr;
pthread_condattr_init(&attr);
pthread_condattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);
pthread_cond_init(&cond, &attr);
```

#### Windows Condition Variable
```c
// Windows 不直接支持跨进程条件变量
// 需要使用命名事件（Event）模拟
```

### 7.3 设计决策

**决策**: 保持实验性标记，但添加详细的说明文档

**理由**:
1. **复杂性**: 跨进程条件变量实现复杂，需要更多测试
2. **平台差异**: Windows 和 Unix 实现差异大
3. **稳定性**: 需要更多实际使用验证

**实现方案**:

```pascal
{**
 * @desc 命名条件变量接口（实验性）
 * @details 提供跨进程条件变量功能
 *
 * @experimental
 * 此接口标记为实验性，原因如下：
 *
 * 1. **实现复杂性**：
 *    - 跨进程条件变量需要复杂的同步机制
 *    - Windows 平台需要使用事件模拟
 *    - Unix 平台需要使用 POSIX 共享内存
 *
 * 2. **平台差异**：
 *    - Windows: 使用命名事件 + 命名互斥锁模拟
 *    - Unix: 使用 POSIX pthread_cond_t + PTHREAD_PROCESS_SHARED
 *    - 行为可能存在细微差异
 *
 * 3. **测试覆盖**：
 *    - 需要更多跨进程测试验证
 *    - 需要压力测试验证稳定性
 *    - 需要边界情况测试
 *
 * 4. **使用建议**：
 *    - 仅在必要时使用跨进程条件变量
 *    - 优先考虑其他跨进程同步原语（如 NamedEvent）
 *    - 在生产环境使用前进行充分测试
 *
 * @stability_plan
 * 稳定化计划：
 * 1. 完成跨进程测试套件（预计 1-2 周）
 * 2. 完成压力测试和边界测试（预计 1 周）
 * 3. 收集实际使用反馈（预计 1-2 个月）
 * 4. 根据反馈调整实现
 * 5. 移除实验性标记（预计 3 个月后）
 *
 * @usage
 *   // 创建命名条件变量
 *   var condvar := MakeNamedCondVar('my_condvar');
 *   var mutex := MakeNamedMutex('my_mutex');
 *
 *   // 等待条件
 *   var guard := mutex.Lock();
 *   try
 *     while not condition do
 *       condvar.Wait(guard);
 *     // 条件满足，执行操作
 *   finally
 *     guard := nil;
 *   end;
 *
 *   // 通知等待者
 *   condvar.Signal();  // 通知一个等待者
 *   condvar.SignalAll();  // 通知所有等待者
 *
 * @thread_safety 线程安全
 * @process_safety 进程安全
 * @posix_equivalent pthread_cond_t with PTHREAD_PROCESS_SHARED
 * @windows_equivalent Named Event + Named Mutex (模拟实现)
 *}
type
  INamedCondVar = interface(ISynchronizable)
    ['{GUID-FOR-INAMEDCONDVAR}']
    
    {**
     * @desc 等待条件满足
     * @param AGuard 持有的锁守卫（必须是命名互斥锁的守卫）
     * @details 释放锁并等待条件满足，被唤醒后重新获取锁
     *}
    procedure Wait(AGuard: ILockGuard);
    
    {**
     * @desc 带超时等待条件满足
     * @param AGuard 持有的锁守卫
     * @param ATimeoutMs 超时时间（毫秒）
     * @returns 如果条件满足返回 True，超时返回 False
     *}
    function WaitFor(AGuard: ILockGuard; ATimeoutMs: Cardinal): Boolean;
    
    {**
     * @desc 通知一个等待者
     * @details 唤醒一个等待的线程/进程
     *}
    procedure Signal;
    
    {**
     * @desc 通知所有等待者
     * @details 唤醒所有等待的线程/进程
     *}
    procedure SignalAll;
    
    {**
     * @desc 获取条件变量名称
     * @returns 条件变量名称
     *}
    function GetName: string;
  end;
```

**实现位置**: `src/fafafa.core.sync.namedCondvar.pas`

**测试要求**:
1. 完成跨进程测试套件
2. 完成压力测试和边界测试
3. 验证 Windows 和 Unix 平台的行为一致性

**文档要求**:
1. 在模块文档中添加实验性说明
2. 提供稳定化计划
3. 提供使用建议和注意事项

---

## 8. 设计决策总结

### 8.1 决策汇总

| 问题编号 | 决策 | 优先级 | 预计工作量 |
|---------|------|--------|-----------|
| P1-001 | 添加 `atomic_thread_fence` 和 `atomic_signal_fence` | 高 | 1-2 天 |
| P1-002 | 添加 CompareExchange 单内存序版本 | 中 | 1 天 |
| P1-003 | 编写详细的内存序语义文档 | 高 | 2-3 天 |
| P1-004 | 重构 ILock 和 ITryLock 接口层次 | 中 | 2-3 天 |
| P1-005 | 完善 Mutex Poison 机制文档 | 高 | 1-2 天 |
| P1-006 | 添加 RWLock 公平性配置 | 中 | 2-3 天 |
| P1-007 | 完善 NamedCondVar 实验性说明 | 低 | 1 天 |

**总计**: 10-17 天

### 8.2 实施顺序

**Phase 4: 接口修订**（按优先级排序）:

1. **第一批（高优先级，3-5 天）**:
   - P1-003: 编写内存序语义文档
   - P1-001: 添加 Fence 操作
   - P1-005: 完善 Mutex Poison 机制文档

2. **第二批（中优先级，5-7 天）**:
   - P1-004: 重构 ILock 接口层次
   - P1-006: 添加 RWLock 公平性配置
   - P1-002: 添加 CompareExchange 单内存序版本

3. **第三批（低优先级，1 天）**:
   - P1-007: 完善 NamedCondVar 实验性说明

### 8.3 向后兼容性

**兼容性保证**:
1. P1-001, P1-002, P1-003: 纯新增功能，完全向后兼容
2. P1-004: 废弃 `ITryLock`，但保留向后兼容
3. P1-005: 纯文档更新，完全向后兼容
4. P1-006: 新增可选参数，默认行为不变，完全向后兼容
5. P1-007: 纯文档更新，完全向后兼容

**迁移成本**: 低 - 只有 P1-004 需要代码迁移，且有自动化工具支持

### 8.4 测试要求

**测试覆盖**:
1. 单元测试：每个新增功能都有对应的单元测试
2. 集成测试：验证新功能与现有功能的集成
3. 性能测试：验证性能影响（特别是 P1-006）
4. 跨平台测试：验证 Windows、Linux、macOS 行为一致

**测试工具**:
1. FPCUnit：单元测试框架
2. HeapTrc：内存泄漏检测
3. 性能基准测试框架

### 8.5 文档要求

**文档更新**:
1. API 参考文档：更新所有新增和修改的接口
2. 用户指南：添加使用示例和最佳实践
3. 迁移指南：提供从旧 API 到新 API 的迁移指南
4. 设计文档：记录设计决策和理由

**文档位置**:
1. `docs/fafafa.core.atomic.md` - atomic 模块文档
2. `docs/fafafa.core.sync.md` - sync 模块文档
3. `docs/API_Reference.md` - API 参考文档
4. （待创建）`docs/layer1/LAYER1_MIGRATION_GUIDE.md` - 迁移指南

---

## 9. 下一步行动

### 9.1 Phase 4: 接口修订

**目标**: 根据设计决策修订接口

**任务**:
1. [ ] 实施 P1-003: 编写内存序语义文档
2. [ ] 实施 P1-001: 添加 Fence 操作
3. [ ] 实施 P1-005: 完善 Mutex Poison 机制文档
4. [ ] 实施 P1-004: 重构 ILock 接口层次
5. [ ] 实施 P1-006: 添加 RWLock 公平性配置
6. [ ] 实施 P1-002: 添加 CompareExchange 单内存序版本
7. [ ] 实施 P1-007: 完善 NamedCondVar 实验性说明

**完成标准**:
- ✅ 所有 P1 问题已修复
- ✅ 所有修改都有测试覆盖
- ✅ 所有文档已更新
- ✅ 向后兼容性已验证

### 9.2 Phase 5: 接口冻结

**目标**: 冻结接口，准备进入实现阶段

**任务**:
1. [ ] 最终审查所有接口
2. [ ] 确认所有 P1 问题已解决
3. [ ] 更新 API 冻结文档
4. [ ] 创建接口快照（Git Tag）
5. [ ] 通知所有开发者

**完成标准**:
- ✅ 接口审查完成
- ✅ 所有问题已解决
- ✅ API 冻结文档已更新
- ✅ Git Tag 已创建
- ✅ 所有开发者已通知

---

**文档生成时间**: 2026-01-19
**文档作者**: Claude Sonnet 4.5
**审核状态**: 待审核
