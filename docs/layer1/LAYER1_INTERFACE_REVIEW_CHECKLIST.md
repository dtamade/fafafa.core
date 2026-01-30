# Layer 1 接口审查清单

> 本文件位置：`docs/layer1/LAYER1_INTERFACE_REVIEW_CHECKLIST.md`

## 文档信息

**日期**: 2026-01-19
**版本**: 1.0.0
**用途**: Layer 1（atomic + sync 模块）接口审查的详细检查清单

---

## 使用说明

本清单用于系统化地审查 Layer 1 的所有公共接口。每个检查项都应该：
- ✅ 通过：符合标准
- ⚠️ 警告：需要改进但不阻塞
- ❌ 失败：必须修复
- N/A：不适用

---

## 1. 命名规范检查

### 1.1 接口命名

- [ ] 接口以 `I` 开头（如 `ILock`、`IMutex`、`IRWLock`）
- [ ] 类以 `T` 开头（如 `TLock`、`TMutex`、`TRWLock`）
- [ ] 守卫以 `Guard` 结尾（如 `ILockGuard`、`TLockGuard`）
- [ ] 命名同步原语以 `Named` 开头（如 `INamedMutex`、`TNamedMutex`）
- [ ] 枚举类型以 `T` 开头（如 `TMemoryOrder`、`TWaitResult`）

### 1.2 方法命名

**现代化 API（Rust 风格）**：
- [ ] 阻塞获取锁：`Lock()` 返回 `ILockGuard`
- [ ] 非阻塞尝试：`TryLock()` 返回 `ILockGuard` 或 `nil`
- [ ] 带超时尝试：`TryLockFor(ATimeoutMs: Cardinal)` 返回 `ILockGuard` 或 `nil`

**传统 API（兼容性）**：
- [ ] 阻塞获取锁：`Acquire()`
- [ ] 释放锁：`Release()`
- [ ] 非阻塞尝试：`TryAcquire()` 返回 `Boolean`
- [ ] 带超时尝试：`TryAcquire(ATimeoutMs: Cardinal)` 返回 `Boolean`

**原子操作命名**：
- [ ] 加载：`Load(AOrder: TMemoryOrder)`
- [ ] 存储：`Store(AValue: T; AOrder: TMemoryOrder)`
- [ ] 交换：`Exchange(AValue: T; AOrder: TMemoryOrder)`
- [ ] 比较交换：`CompareExchange(var AExpected: T; ADesired: T; AOrder: TMemoryOrder)`
- [ ] 算术操作：`FetchAdd`, `FetchSub`, `FetchAnd`, `FetchOr`, `FetchXor`

### 1.3 参数命名

- [ ] 超时参数：`ATimeoutMs: Cardinal`（统一使用毫秒）
- [ ] 内存序参数：`AOrder: TMemoryOrder`
- [ ] 值参数：`AValue: T`
- [ ] 期望值参数：`AExpected: T`（用于 CAS）
- [ ] 期望值参数：`ADesired: T`（用于 CAS）

### 1.4 常量命名

- [ ] 常量以 `c` 开头（如 `cDefaultTimeout`）
- [ ] 或使用全大写（如 `DEFAULT_TIMEOUT`）

---

## 2. 接口设计检查

### 2.1 RAII 守卫设计

**基础守卫接口**：
- [ ] 所有锁都支持 RAII 守卫
- [ ] 守卫实现 `IGuard` 基接口
- [ ] `IGuard` 定义：
  ```pascal
  IGuard = interface
    function IsLocked: Boolean;
    procedure Release;
  end;
  ```

**具体守卫类型**：
- [ ] `ILockGuard` 继承自 `IGuard`（互斥锁守卫）
- [ ] `IRWLockReadGuard` 继承自 `IGuard`（读锁守卫）
- [ ] `IRWLockWriteGuard` 继承自 `IGuard`（写锁守卫）

**守卫实现**：
- [ ] 守卫在析构时自动释放锁
- [ ] 守卫支持手动 `Release()` 方法
- [ ] `Release()` 方法是幂等的（多次调用安全）
- [ ] 守卫支持 `IsLocked()` 查询状态

### 2.2 超时支持

**超时参数**：
- [ ] 所有阻塞操作都有超时版本
- [ ] 超时参数统一使用 `Cardinal`（毫秒）
- [ ] 超时为 0 表示立即返回（非阻塞）
- [ ] 超时为 `INFINITE` 表示永久等待

**超时返回值**：
- [ ] 守卫版本：超时返回 `nil`
- [ ] 布尔版本：超时返回 `False`
- [ ] 错误版本：超时返回 `TResult<T, ESyncTimeoutError>`

### 2.3 错误处理

**异常类型**：
- [ ] 基础异常：`ESyncError = class(ECore)`
- [ ] 锁错误：`ELockError = class(ESyncError)`
- [ ] 超时错误：`ESyncTimeoutError = class(ESyncError)`
- [ ] 死锁错误：`EDeadlockError = class(ESyncError)`
- [ ] 参数错误：`EInvalidArgument = class(ESyncError)`

**错误处理策略**：
- [ ] 优先使用 `TResult<T, E>` 或 `TOptional<T>` 返回错误
- [ ] 避免使用异常（除非必要）
- [ ] 错误类型统一且有层次结构
- [ ] 错误信息清晰且有上下文

### 2.4 内存序设计

**内存序枚举**：
- [ ] 定义 `TMemoryOrder` 枚举
- [ ] 支持 `Relaxed`（无同步）
- [ ] 支持 `Acquire`（获取语义）
- [ ] 支持 `Release`（释放语义）
- [ ] 支持 `AcqRel`（获取+释放）
- [ ] 支持 `SeqCst`（顺序一致性，默认）

**内存序语义**：
- [ ] 文档清楚说明每种内存序的语义
- [ ] 默认使用 `SeqCst`（最安全）
- [ ] 提供性能优化指南（何时使用 Relaxed/Acquire/Release）

---

## 3. 跨平台兼容性检查

### 3.1 平台抽象

**文件组织**：
- [ ] 使用 `.base.pas` 定义接口和公共类型
- [ ] 使用 `.windows.pas` 实现 Windows 版本
- [ ] 使用 `.unix.pas` 实现 Unix 版本
- [ ] 主文件（`.pas`）根据平台选择实现

**条件编译**：
- [ ] 使用 `{$IFDEF WINDOWS}` 和 `{$IFDEF UNIX}` 条件编译
- [ ] 避免使用平台特定的类型（如 `HANDLE`、`pthread_t`）在公共接口中
- [ ] 平台特定代码封装在实现单元中

### 3.2 行为一致性

**功能一致性**：
- [ ] 所有平台提供相同的功能
- [ ] 所有平台的接口签名一致
- [ ] 所有平台的错误处理一致

**性能一致性**：
- [ ] 超时精度一致（毫秒级）
- [ ] 锁的公平性一致（或文档说明差异）
- [ ] 性能特性一致（或文档说明差异）

### 3.3 编译器兼容性

- [ ] 支持 FPC 3.2.0+
- [ ] 支持 Delphi 10.4+（如果需要）
- [ ] 使用标准 Pascal 语法
- [ ] 避免使用编译器特定的扩展

---

## 4. 性能考虑检查

### 4.1 零成本抽象

**内联优化**：
- [ ] 关键路径方法使用 `inline` 指令
- [ ] 内联条件：`{$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}`
- [ ] 避免在内联方法中使用复杂逻辑

**接口调用开销**：
- [ ] 接口调用开销最小
- [ ] 避免不必要的虚方法调用
- [ ] 使用静态方法或内联方法优化热路径

### 4.2 缓存友好

**数据结构设计**：
- [ ] 数据结构紧凑
- [ ] 避免伪共享（false sharing）
- [ ] 对齐到缓存行（64 字节）

**内存布局**：
- [ ] 热数据放在一起
- [ ] 冷数据分离
- [ ] 使用 `packed` 记录减少内存占用

### 4.3 可扩展性

**多核扩展**：
- [ ] 支持多核扩展
- [ ] 避免全局锁
- [ ] 使用无锁算法（如果可能）

**性能基准**：
- [ ] 有性能基准测试
- [ ] 有性能优化指南
- [ ] 有性能回归测试

---

## 5. 文档完整性检查

### 5.1 模块级文档

**必需内容**：
- [ ] 模块概述（`@desc`）
- [ ] 设计哲学（`@design_philosophy`）
- [ ] 核心概念（`@core_concepts`）
- [ ] 使用模式（`@usage_patterns`）
- [ ] 最佳实践（`@best_practices`）

**可选内容**：
- [ ] 性能特性（`@performance`）
- [ ] 跨平台说明（`@cross_platform`）
- [ ] 参考设计（`@rust_equivalent`、`@cpp_equivalent`）

### 5.2 接口级文档

**必需内容**：
- [ ] 接口描述（`@desc`）
- [ ] 方法列表（`@methods`）
- [ ] 使用示例（`@usage`）

**可选内容**：
- [ ] 线程安全性（`@thread_safety`）
- [ ] 性能特性（`@performance`）
- [ ] 参考设计（`@rust_equivalent`）

### 5.3 方法级文档

**必需内容**：
- [ ] 方法描述（`@desc`）
- [ ] 参数说明（`@params`）
- [ ] 返回值说明（`@returns`）
- [ ] 使用示例（`@example`）

**可选内容**：
- [ ] 异常说明（`@exception`）
- [ ] 线程安全性（`@thread_safety`）
- [ ] 性能说明（`@performance`）
- [ ] 安全性说明（`@safety`）

### 5.4 类型级文档

**必需内容**：
- [ ] 类型描述（`@desc`）
- [ ] 字段说明（`@fields`）
- [ ] 使用示例（`@usage`）

**可选内容**：
- [ ] 不变量说明（`@invariants`）
- [ ] 内存布局（`@memory_layout`）

---

## 6. 与参考设计对比

### 6.1 与 Rust std::sync 对比

**Mutex 接口**：
- [ ] 支持 `Lock()` 返回守卫（对应 Rust `lock()`）
- [ ] 支持 `TryLock()` 返回守卫（对应 Rust `try_lock()`）
- [ ] 守卫自动释放锁（对应 Rust `MutexGuard` 的 `Drop`）

**RwLock 接口**：
- [ ] 支持 `Read()` 返回读守卫（对应 Rust `read()`）
- [ ] 支持 `Write()` 返回写守卫（对应 Rust `write()`）
- [ ] 支持 `TryRead()` 和 `TryWrite()`

**Poison 机制**：
- [ ] 是否需要 Poison 机制？（Rust 有，C++ 没有）
- [ ] 如果需要，如何实现？
- [ ] 如果不需要，如何处理 panic 情况？

### 6.2 与 C++11 std::atomic 对比

**原子操作接口**：
- [ ] 支持 `Load(AOrder)`（对应 C++ `load(order)`）
- [ ] 支持 `Store(AValue, AOrder)`（对应 C++ `store(desired, order)`）
- [ ] 支持 `Exchange(AValue, AOrder)`（对应 C++ `exchange(desired, order)`）
- [ ] 支持 `CompareExchange`（对应 C++ `compare_exchange_strong/weak`）

**内存序**：
- [ ] 支持所有 C++11 内存序
- [ ] 默认使用 `SeqCst`
- [ ] 文档说明内存序语义

**类型系统**：
- [ ] 支持泛型原子类型（`TAtomicInt32`, `TAtomicInt64`, `TAtomicPtr<T>`）
- [ ] 支持特化优化（整数、指针）

### 6.3 与 Java java.util.concurrent 对比

**Lock 接口**：
- [ ] 支持 `Lock()` 和 `Unlock()`（对应 Java `lock()` 和 `unlock()`）
- [ ] 支持 `TryLock()`（对应 Java `tryLock()`）
- [ ] 支持 `TryLock(ATimeoutMs)`（对应 Java `tryLock(timeout, unit)`）

**Condition 接口**：
- [ ] 支持 `Wait()`（对应 Java `await()`）
- [ ] 支持 `Signal()` 和 `SignalAll()`（对应 Java `signal()` 和 `signalAll()`）

---

## 7. 特定模块检查

### 7.1 atomic 模块

**核心类型**：
- [ ] `TAtomicBool`
- [ ] `TAtomicInt32`, `TAtomicInt64`
- [ ] `TAtomicUInt32`, `TAtomicUInt64`
- [ ] `TAtomicPtr<T>`

**核心操作**：
- [ ] `Load`, `Store`, `Exchange`
- [ ] `CompareExchange` (Strong/Weak)
- [ ] `FetchAdd`, `FetchSub`（整数类型）
- [ ] `FetchAnd`, `FetchOr`, `FetchXor`（整数类型）

**内存序**：
- [ ] `TMemoryOrder` 枚举定义
- [ ] 所有操作支持内存序参数
- [ ] 默认使用 `SeqCst`

### 7.2 sync.core 模块

**Mutex**：
- [ ] `IMutex` / `TMutex`
- [ ] `Lock()`, `TryLock()`, `TryLockFor()`
- [ ] `Acquire()`, `Release()`, `TryAcquire()`
- [ ] `ILockGuard` / `TLockGuard`

**RWLock**：
- [ ] `IRWLock` / `TRWLock`
- [ ] `Read()`, `Write()`, `TryRead()`, `TryWrite()`
- [ ] `IRWLockReadGuard`, `IRWLockWriteGuard`

**SpinLock**：
- [ ] `ISpinLock` / `TSpinLock`
- [ ] 与 Mutex 相同的接口
- [ ] 文档说明使用场景（短期持有）

**Semaphore**：
- [ ] `ISemaphore` / `TSemaphore`
- [ ] `Acquire()`, `Release()`, `TryAcquire()`
- [ ] 支持计数

**CondVar**：
- [ ] `ICondVar` / `TCondVar`
- [ ] `Wait(Guard)`, `WaitFor(Guard, TimeoutMs)`
- [ ] `Signal()`, `SignalAll()`

### 7.3 sync.basic 模块

**Barrier**：
- [ ] `IBarrier` / `TBarrier`
- [ ] `Wait()` 返回是否是最后一个线程

**Event**：
- [ ] `IEvent` / `TEvent`
- [ ] `Set()`, `Reset()`, `Wait()`, `WaitFor()`

**Latch**：
- [ ] `ILatch` / `TLatch`
- [ ] `CountDown()`, `Wait()`, `WaitFor()`

**Once**：
- [ ] `IOnce` / `TOnce`
- [ ] `CallOnce(Proc)`

**WaitGroup**：
- [ ] `IWaitGroup` / `TWaitGroup`
- [ ] `Add(Delta)`, `Done()`, `Wait()`

**Parker**：
- [ ] `IParker` / `TParker`
- [ ] `Park()`, `ParkFor()`, `Unpark()`

**RecMutex**：
- [ ] `IRecMutex` / `TRecMutex`
- [ ] 支持重入（同一线程可多次获取）

### 7.4 sync.named 模块

**命名同步原语**：
- [ ] `INamedMutex` / `TNamedMutex`
- [ ] `INamedRWLock` / `TNamedRWLock`
- [ ] `INamedSemaphore` / `TNamedSemaphore`
- [ ] `INamedBarrier` / `TNamedBarrier`
- [ ] `INamedCondVar` / `TNamedCondVar`
- [ ] `INamedEvent` / `TNamedEvent`
- [ ] `INamedLatch` / `TNamedLatch`
- [ ] `INamedOnce` / `TNamedOnce`
- [ ] `INamedWaitGroup` / `TNamedWaitGroup`
- [ ] `INamedSharedCounter` / `TNamedSharedCounter`

**跨进程支持**：
- [ ] 支持命名（字符串名称）
- [ ] 支持跨进程同步
- [ ] 支持权限控制（Unix）
- [ ] 支持全局命名空间（Windows）

### 7.5 sync.advanced 模块

**Guards**：
- [ ] `IGuard` 基接口
- [ ] `ILockGuard`, `IRWLockReadGuard`, `IRWLockWriteGuard`
- [ ] 守卫支持 `IsLocked()` 和 `Release()`

**Builder**：
- [ ] `ISyncBuilder` 构建器接口
- [ ] 支持链式调用
- [ ] 支持配置超时、公平性等

**LazyLock**：
- [ ] `ILazyLock<T>` / `TLazyLock<T>`
- [ ] 延迟初始化
- [ ] 线程安全

**OnceLock**：
- [ ] `IOnceLock<T>` / `TOnceLock<T>`
- [ ] 一次性初始化
- [ ] 线程安全

---

## 8. 测试覆盖检查

### 8.1 单元测试

**基础功能测试**：
- [ ] 每个公共方法都有测试
- [ ] 测试覆盖率 > 90%
- [ ] 测试边界情况

**并发测试**：
- [ ] 多线程压力测试
- [ ] 竞态条件测试
- [ ] 死锁检测测试

**错误处理测试**：
- [ ] 异常测试
- [ ] 超时测试
- [ ] 无效参数测试

### 8.2 集成测试

**跨模块测试**：
- [ ] atomic + sync 集成测试
- [ ] 不同同步原语组合测试

**跨平台测试**：
- [ ] Windows 测试
- [ ] Linux 测试
- [ ] macOS 测试

### 8.3 性能测试

**性能基准**：
- [ ] 每个同步原语都有性能基准
- [ ] 与参考实现对比
- [ ] 性能回归测试

**内存测试**：
- [ ] 内存泄漏检测（HeapTrc）
- [ ] 内存占用测试
- [ ] 内存对齐测试

---

## 9. 问题分类和优先级

### 9.1 P0 - 阻塞性问题（必须修复）

- [ ] 接口设计根本性错误
- [ ] 跨平台不兼容
- [ ] 内存安全问题
- [ ] 性能严重问题
- [ ] 死锁或竞态条件

### 9.2 P1 - 重要问题（应该修复）

- [ ] 接口不一致
- [ ] 命名不规范
- [ ] 缺少必要功能
- [ ] 文档不完整
- [ ] 测试覆盖不足

### 9.3 P2 - 次要问题（可以修复）

- [ ] 接口不够简洁
- [ ] 缺少便利功能
- [ ] 文档不够详细
- [ ] 示例不够丰富
- [ ] 性能可以优化

### 9.4 P3 - 优化建议（未来考虑）

- [ ] 性能优化建议
- [ ] 新功能建议
- [ ] API 改进建议
- [ ] 文档改进建议

---

## 10. 审查流程

### 10.1 审查步骤

1. **准备阶段**：
   - [ ] 阅读参考设计文档
   - [ ] 准备审查清单
   - [ ] 准备审查工具

2. **接口清单**：
   - [ ] 列出所有公共接口
   - [ ] 分类接口（核心、高级、辅助）
   - [ ] 标记接口状态（稳定、实验、废弃）

3. **逐项审查**：
   - [ ] 对照清单逐项检查
   - [ ] 记录发现的问题
   - [ ] 标记问题优先级

4. **设计讨论**：
   - [ ] 整理审查发现的问题
   - [ ] 讨论解决方案
   - [ ] 达成设计共识

5. **接口修订**：
   - [ ] 根据审查结果修订接口
   - [ ] 更新文档和测试
   - [ ] 验证修订结果

6. **接口冻结**：
   - [ ] 最终审查所有接口
   - [ ] 确认所有问题已解决
   - [ ] 创建接口快照（Git Tag）

### 10.2 审查输出

**审查报告**：
- [ ] 接口清单文档
- [ ] 接口审查报告
- [ ] 设计决策文档
- [ ] API 冻结文档

**修订代码**：
- [ ] 修订后的接口代码
- [ ] 更新的文档注释
- [ ] 更新的测试用例

---

## 11. 成功标准

### 11.1 完成标准

- [ ] 所有检查项都已审查
- [ ] 所有 P0/P1 问题已解决
- [ ] 接口设计达成共识
- [ ] 接口文档完整
- [ ] 接口测试完整

### 11.2 质量指标

| 指标 | 目标值 | 达成标准 |
|------|--------|----------|
| **接口文档覆盖率** | 100% | 所有公共接口都有文档注释 |
| **接口一致性** | 100% | 所有接口遵循统一规范 |
| **跨平台兼容性** | 100% | 所有平台行为一致 |
| **P0 问题** | 0 | 所有 P0 问题已解决 |
| **P1 问题** | 0 | 所有 P1 问题已解决 |
| **测试覆盖率** | 90%+ | 所有关键路径有测试 |

---

## 12. 参考资源

### 12.1 参考设计

- **Rust std::sync**: https://doc.rust-lang.org/std/sync/
- **C++11 std::atomic**: https://en.cppreference.com/w/cpp/atomic
- **Java java.util.concurrent**: https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/package-summary.html

### 12.2 项目文档

- `docs/layer1/LAYER1_INTERFACE_REVIEW_PLAN.md` - 接口审查计划
- `docs/PHASE0_REFINEMENT_PLAN.md` - Phase 0 精炼计划（参考模板）
- `docs/PHASE0_API_FREEZE.md` - API 冻结文档（参考标准）
- `docs/standards/ENGINEERING_STANDARDS.md` - 工程标准

---

**文档生成时间**: 2026-01-19
**文档作者**: Claude Sonnet 4.5
**版本**: 1.0.0
