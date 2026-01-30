# Layer 1 接口审查和设计评审方案

> 本文件位置：`docs/layer1/LAYER1_INTERFACE_REVIEW_PLAN.md`

## 执行摘要

**日期**: 2026-01-19
**目标**: 在进入实现阶段前，完成 Layer 1（atomic + sync 模块）的接口审查和设计评审
**核心原则**: **接口设计的稳定性是后续实现与维护的前提**

---

## 1. 为什么接口设计必须先行

### 1.1 Layer 1 的特殊性

**基础设施层的关键地位**:
- atomic 和 sync 是整个项目的**基础设施层**
- 被 Layer 2+（collections, thread, lockfree 等）广泛依赖
- 接口设计错误会影响整个项目架构
- 一旦发布，接口变更代价极高

**实际依赖关系**:
```
Layer 6: 应用层
  ↓
Layer 5: 高级抽象层
  ↓
Layer 4: 工具层
  ↓
Layer 3: 容器层（collections）
  ↓
Layer 2: 并发层（thread, lockfree）
  ↓
Layer 1: 同步原语层（atomic, sync）← 我们在这里
  ↓
Layer 0: 基础层（base, mem, option, result）
```

### 1.2 实现阶段的前提条件

**为什么必须先固定接口**:

1. **避免返工**
   - 接口变更会影响所有依赖模块
   - 改接口需要同步所有实现/测试/文档与下游依赖
   - 代价：N 个文件 × M 次修改

2. **保证一致性**
   - 统一的接口设计风格需要整体审查
   - 不能各自为政，导致风格不一致
   - 需要参考成熟设计（Rust std::sync）

3. **减少冲突**
   - 接口稳定后，各模块实现可以独立进行
   - 冲突最小化，合并更容易
   - 测试和文档可以同步推进

4. **提高质量**
   - 接口设计需要深思熟虑
   - 需要考虑未来扩展性
   - 需要考虑跨平台兼容性

### 1.3 接口设计的影响范围

**直接影响**:
- Layer 2: thread, lockfree 模块直接依赖 sync 接口
- Layer 3: collections 模块使用 sync 保证线程安全
- 所有并发代码都依赖 atomic 操作

**间接影响**:
- API 文档和使用示例
- 性能基准测试
- 跨平台兼容性
- 第三方库集成

---

## 2. 接口审查的范围和目标

### 2.1 审查范围

#### atomic 模块（3 个文件）

**核心接口**:
```pascal
// src/fafafa.core.atomic.pas
- TAtomicInt32, TAtomicInt64, TAtomicUInt32, TAtomicUInt64
- TAtomicPtr<T>
- 内存序：TMemoryOrder (Relaxed, Acquire, Release, AcqRel, SeqCst)
- 原子操作：Load, Store, Exchange, CompareExchange, FetchAdd, FetchSub
```

**审查重点**:
- [ ] 内存序语义是否正确
- [ ] 是否支持所有必要的原子操作
- [ ] 是否与 C++11 std::atomic 兼容
- [ ] 是否与 Rust std::sync::atomic 兼容
- [ ] 跨平台实现是否一致

#### sync 模块（103 个文件）

**核心同步原语**（12 种）:
```pascal
1. ILock / TLock - 基础锁接口
2. IMutex / TMutex - 互斥锁
3. IRWLock / TRWLock - 读写锁
4. ISpinLock / TSpinLock - 自旋锁
5. ISemaphore / TSemaphore - 信号量
6. ICondVar / TCondVar - 条件变量
7. IBarrier / TBarrier - 屏障
8. IEvent / TEvent - 事件
9. ILatch / TLatch - 闩锁
10. IOnce / TOnce - 一次性初始化
11. IWaitGroup / TWaitGroup - 等待组
12. IParker / TParker - 线程停靠
```

**命名同步原语**（10 种，跨进程）:
```pascal
13. INamedMutex / TNamedMutex
14. INamedRWLock / TNamedRWLock
15. INamedSemaphore / TNamedSemaphore
... (其他 7 种)
```

**高级功能**:
```pascal
- IGuard / ILockGuard / IRWLockReadGuard / IRWLockWriteGuard - RAII 守卫
- ISyncBuilder - 构建器模式
- ILazyLock / TLazyLock - 延迟锁
- IOnceLock / TOnceLock - 一次性锁
```

**审查重点**:
- [ ] 接口层次结构是否合理
- [ ] RAII 守卫设计是否完善
- [ ] 是否支持超时操作
- [ ] 是否支持 try_lock 操作
- [ ] 错误处理是否一致
- [ ] 是否与 Rust std::sync 兼容
- [ ] 跨平台实现是否一致

### 2.2 审查目标

**功能完整性**:
- ✅ 所有必要的同步原语都已实现
- ✅ 所有必要的原子操作都已实现
- ✅ 支持超时和非阻塞操作

**接口一致性**:
- ✅ 命名规范统一
- ✅ 参数顺序一致
- ✅ 返回值类型一致
- ✅ 错误处理一致

**设计质量**:
- ✅ 接口简洁易用
- ✅ 支持 RAII 模式
- ✅ 支持现代化 API（Rust 风格）
- ✅ 支持传统 API（兼容性）

**跨平台兼容性**:
- ✅ Windows、Linux、macOS 行为一致
- ✅ 32 位和 64 位平台兼容
- ✅ 不同编译器兼容

**未来扩展性**:
- ✅ 接口设计考虑未来扩展
- ✅ 不会破坏向后兼容性
- ✅ 支持新的同步原语

---

## 3. 接口设计评审标准

### 3.1 参考设计

**Rust std::sync**（主要参考）:
```rust
// Rust 的同步原语设计
pub struct Mutex<T> { ... }
impl<T> Mutex<T> {
    pub fn new(t: T) -> Mutex<T>;
    pub fn lock(&self) -> LockResult<MutexGuard<T>>;
    pub fn try_lock(&self) -> TryLockResult<MutexGuard<T>>;
}

pub struct RwLock<T> { ... }
impl<T> RwLock<T> {
    pub fn new(t: T) -> RwLock<T>;
    pub fn read(&self) -> LockResult<RwLockReadGuard<T>>;
    pub fn write(&self) -> LockResult<RwLockWriteGuard<T>>;
}
```

**C++11 std::atomic**（次要参考）:
```cpp
// C++ 的原子操作设计
template<typename T>
class atomic {
public:
    T load(memory_order order = memory_order_seq_cst);
    void store(T desired, memory_order order = memory_order_seq_cst);
    T exchange(T desired, memory_order order = memory_order_seq_cst);
    bool compare_exchange_strong(T& expected, T desired,
                                  memory_order order = memory_order_seq_cst);
};
```

**Java java.util.concurrent**（辅助参考）:
```java
// Java 的同步原语设计
public class ReentrantLock implements Lock {
    public void lock();
    public boolean tryLock();
    public boolean tryLock(long timeout, TimeUnit unit);
    public void unlock();
}
```

### 3.2 评审清单

#### 3.2.1 命名规范

**接口命名**:
- [ ] 接口以 `I` 开头（如 `ILock`、`IMutex`）
- [ ] 类以 `T` 开头（如 `TLock`、`TMutex`）
- [ ] 守卫以 `Guard` 结尾（如 `ILockGuard`、`TLockGuard`）
- [ ] 命名同步原语以 `Named` 开头（如 `INamedMutex`）

**方法命名**:
- [ ] 现代化 API：`Lock()`, `TryLock()`, `TryLockFor()`
- [ ] 传统 API：`Acquire()`, `Release()`, `TryAcquire()`
- [ ] 一致性：所有锁都使用相同的方法名

**参数命名**:
- [ ] 超时参数：`ATimeoutMs: Cardinal`
- [ ] 内存序参数：`AOrder: TMemoryOrder`
- [ ] 一致性：所有方法使用相同的参数名

#### 3.2.2 接口设计

**RAII 守卫**:
- [ ] 所有锁都支持 RAII 守卫
- [ ] 守卫实现 `IGuard` 基接口
- [ ] 守卫支持 `IsLocked()` 和 `Release()` 方法
- [ ] 守卫在析构时自动释放锁

**超时支持**:
- [ ] 所有阻塞操作都支持超时版本
- [ ] 超时参数统一使用毫秒（`Cardinal`）
- [ ] 超时返回 `nil`（守卫）或 `False`（布尔）

**错误处理**:
- [ ] 使用 `TResult<T, E>` 或 `TOptional<T>` 返回错误
- [ ] 不使用异常（除非必要）
- [ ] 错误类型统一（`ESyncError` 及其子类）

**内存序**:
- [ ] 支持所有必要的内存序（Relaxed, Acquire, Release, AcqRel, SeqCst）
- [ ] 默认使用 `SeqCst`（最安全）
- [ ] 文档清楚说明每种内存序的语义

#### 3.2.3 跨平台兼容性

**平台抽象**:
- [ ] 使用 `.base.pas` 定义接口
- [ ] 使用 `.windows.pas` 实现 Windows 版本
- [ ] 使用 `.unix.pas` 实现 Unix 版本
- [ ] 主文件（`.pas`）根据平台选择实现

**行为一致性**:
- [ ] 所有平台行为一致
- [ ] 超时精度一致（毫秒级）
- [ ] 错误处理一致

**编译器兼容性**:
- [ ] 支持 FPC 3.2.0+
- [ ] 支持 Delphi 10.4+（如果需要）
- [ ] 使用标准 Pascal 语法

#### 3.2.4 性能考虑

**零成本抽象**:
- [ ] 接口调用开销最小
- [ ] 使用内联优化（`{$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}`）
- [ ] 避免不必要的内存分配

**缓存友好**:
- [ ] 数据结构紧凑
- [ ] 避免伪共享（false sharing）
- [ ] 对齐到缓存行（64 字节）

**可扩展性**:
- [ ] 支持多核扩展
- [ ] 避免全局锁
- [ ] 使用无锁算法（如果可能）

---

## 4. 接口审查流程

### 4.1 审查阶段

#### Phase 0: 准备阶段（1 天）

**目标**: 准备审查所需的材料和工具

**任务**:
1. [ ] 阅读 Rust std::sync 文档
2. [ ] 阅读 C++11 std::atomic 文档
3. [ ] 阅读 Java java.util.concurrent 文档
4. [ ] 准备审查清单
5. [ ] 准备审查模板

**输出**:
- 审查清单（Checklist）
- 审查模板（Template）
- 参考设计文档（Reference）

#### Phase 1: 接口清单（2-3 天）

**目标**: 列出所有公共接口，建立接口清单

**任务**:
1. [ ] 列出 atomic 模块的所有公共接口
2. [ ] 列出 sync 模块的所有公共接口
3. [ ] 分类接口（核心、高级、辅助）
4. [ ] 标记接口状态（稳定、实验、废弃）

**输出**:
- `docs/layer1/LAYER1_INTERFACE_INVENTORY.md` - 接口清单文档

#### Phase 2: 接口审查（3-5 天）

**目标**: 逐个审查接口，发现设计问题

**任务**:
1. [ ] 审查 atomic 模块接口
2. [ ] 审查 sync.core 模块接口（mutex, rwlock, spin, sem, condvar）
3. [ ] 审查 sync.basic 模块接口（barrier, event, latch, once, waitgroup, parker, recMutex）
4. [ ] 审查 sync.named 模块接口（10 种命名同步原语）
5. [ ] 审查 sync.advanced 模块接口（guards, builder, lazylock, oncelock）

**审查方法**:
- 对照评审清单逐项检查
- 与参考设计对比
- 记录发现的问题
- 提出改进建议

**输出**:
- `docs/layer1/LAYER1_INTERFACE_REVIEW_REPORT.md` - 接口审查报告

#### Phase 3: 设计讨论（2-3 天）

**目标**: 讨论发现的问题，达成设计共识

**任务**:
1. [ ] 整理审查发现的问题
2. [ ] 按优先级排序（P0/P1/P2/P3）
3. [ ] 讨论每个问题的解决方案
4. [ ] 达成设计共识
5. [ ] 更新接口设计

**讨论方式**:
- 创建 GitHub Issue 讨论每个问题
- 使用 RFC（Request for Comments）流程
- 记录讨论结果和决策

**输出**:
- `docs/layer1/LAYER1_INTERFACE_DESIGN_DECISIONS.md` - 设计决策文档

#### Phase 4: 接口修订（3-5 天）

**目标**: 根据审查结果修订接口

**任务**:
1. [ ] 修订 atomic 模块接口
2. [ ] 修订 sync 模块接口
3. [ ] 更新文档注释
4. [ ] 更新使用示例
5. [ ] 更新测试用例

**修订原则**:
- 保持向后兼容（如果可能）
- 标记废弃接口（`deprecated`）
- 提供迁移指南

**输出**:
- 修订后的接口代码
- 迁移指南文档

#### Phase 5: 接口冻结（1-2 天）

**目标**: 冻结接口，准备进入实现阶段

**任务**:
1. [ ] 最终审查所有接口
2. [ ] 确认所有问题已解决
3. [ ] 更新 API 冻结文档
4. [ ] 创建接口快照（Git Tag）
5. [ ] 通知所有开发者

**冻结标准**:
- ✅ 所有 P0/P1 问题已解决
- ✅ 所有接口都有文档注释
- ✅ 所有接口都有使用示例
- ✅ 所有接口都有测试用例
- ✅ 接口设计达成共识

**输出**:
- （待创建）`docs/layer1/LAYER1_API_FREEZE.md` - API 冻结文档
- Git Tag: `layer1-api-freeze-v1.0`

### 4.2 审查工具

**自动化工具**:
```bash
# 1. 提取所有公共接口
grep -r "^  \(function\|procedure\)" src/fafafa.core.atomic*.pas src/fafafa.core.sync*.pas

# 2. 检查文档注释覆盖率
grep -r "{**" src/fafafa.core.atomic*.pas src/fafafa.core.sync*.pas | wc -l

# 3. 检查废弃接口
grep -r "deprecated" src/fafafa.core.atomic*.pas src/fafafa.core.sync*.pas

# 4. 检查内联优化
grep -r "inline" src/fafafa.core.atomic*.pas src/fafafa.core.sync*.pas
```

**手动审查**:
- 阅读代码
- 对照清单检查
- 与参考设计对比
- 记录问题和建议

---

## 5. 接口设计问题分类

### 5.1 问题优先级

**P0 - 阻塞性问题**（必须修复）:
- 接口设计根本性错误
- 跨平台不兼容
- 内存安全问题
- 性能严重问题

**P1 - 重要问题**（应该修复）:
- 接口不一致
- 命名不规范
- 缺少必要功能
- 文档不完整

**P2 - 次要问题**（可以修复）:
- 接口不够简洁
- 缺少便利功能
- 文档不够详细
- 示例不够丰富

**P3 - 优化建议**（未来考虑）:
- 性能优化建议
- 新功能建议
- API 改进建议
- 文档改进建议

### 5.2 常见问题类型

**接口设计问题**:
- 接口过于复杂
- 接口不够灵活
- 接口不一致
- 缺少必要功能

**命名问题**:
- 命名不规范
- 命名不一致
- 命名不清晰
- 命名冲突

**文档问题**:
- 缺少文档注释
- 文档不完整
- 文档不准确
- 缺少使用示例

**兼容性问题**:
- 跨平台不兼容
- 编译器不兼容
- 版本不兼容
- 与参考设计不兼容

**性能问题**:
- 性能开销过大
- 缓存不友好
- 可扩展性差
- 内存占用过大

---

## 6. 接口冻结后的工作

### 6.1 冻结后的实现规划

**建议顺序**:
1. 先让回归链可信（脚本无交互、返回码可信、`src/` 清洁）
2. 按原语推进（mutex → rwlock → condvar → sem → barrier → event → spin → once/oncelock/lazylock → 其他）
3. 每个原语做到：实现/测试/文档一致，并能被 `run_all_tests.*` 发现

### 6.2 接口变更管理

**变更流程**:
1. 发现接口问题
2. 创建 GitHub Issue
3. 讨论解决方案
4. 达成共识
5. 更新接口
6. 通知所有开发者
7. 更新文档和测试

**变更原则**:
- 尽量避免破坏性变更
- 提供迁移指南
- 标记废弃接口
- 保持向后兼容

---

## 7. 成功标准

### 7.1 接口审查完成标准

- ✅ 所有公共接口都已审查
- ✅ 所有 P0/P1 问题已解决
- ✅ 接口设计达成共识
- ✅ 接口文档完整
- ✅ 接口测试完整

### 7.2 接口冻结标准

- ✅ 接口审查完成
- ✅ 所有问题已解决
- ✅ API 冻结文档已更新
- ✅ Git Tag 已创建
- ✅ 所有开发者已通知

### 7.3 质量指标

| 指标 | 目标值 | 达成标准 |
|------|--------|----------|
| **接口文档覆盖率** | 100% | 所有公共接口都有文档注释 |
| **接口一致性** | 100% | 所有接口遵循统一规范 |
| **跨平台兼容性** | 100% | 所有平台行为一致 |
| **P0 问题** | 0 | 所有 P0 问题已解决 |
| **P1 问题** | 0 | 所有 P1 问题已解决 |

---

## 8. 时间表

| 阶段 | 任务 | 时间 |
|------|------|------|
| **Phase 0** | 准备阶段 | 1 天 |
| **Phase 1** | 接口清单 | 2-3 天 |
| **Phase 2** | 接口审查 | 3-5 天 |
| **Phase 3** | 设计讨论 | 2-3 天 |
| **Phase 4** | 接口修订 | 3-5 天 |
| **Phase 5** | 接口冻结 | 1-2 天 |
| **总计** | | **12-19 天** |

**注**: 接口冻结后进入实现阶段，优先保证回归链可信。

---

## 9. 下一步行动

### 9.1 立即行动

1. **阅读参考设计**:
   - Rust std::sync 文档
   - C++11 std::atomic 文档
   - Java java.util.concurrent 文档

2. **准备审查清单**:
   - 命名规范清单
   - 接口设计清单
   - 跨平台兼容性清单
   - 性能考虑清单

3. **开始 Phase 1**:
   - 列出 atomic 模块的所有公共接口
   - 列出 sync 模块的所有公共接口
   - 创建接口清单文档

### 9.2 准备工作

1. **环境准备**:
   - 确保可以编译所有模块
   - 确保可以运行所有测试
   - 确保可以查看所有文档

2. **工具准备**:
   - 准备代码审查工具
   - 准备文档生成工具
   - 准备测试工具

3. **文档准备**:
   - 阅读现有文档
   - 阅读参考设计
   - 准备审查模板

---

## 10. 参考文档

- `docs/PHASE0_REFINEMENT_PLAN.md` - Phase 0 精炼计划（参考模板）
- `docs/PHASE0_API_FREEZE.md` - API 冻结文档（参考标准）
- `docs/standards/ENGINEERING_STANDARDS.md` - 工程标准
- `docs/design/MODULE_DEVELOPMENT_ORDER.md` - 模块开发顺序

**外部参考**:
- [Rust std::sync](https://doc.rust-lang.org/std/sync/)
- [C++11 std::atomic](https://en.cppreference.com/w/cpp/atomic)
- [Java java.util.concurrent](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/package-summary.html)

---

**报告生成时间**: 2026-01-19
**报告作者**: Claude Sonnet 4.5
**审核状态**: 待审核
