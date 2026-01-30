# fafafa.core 模块开发顺序清单

> 本文档定义了 fafafa.core 框架的自底向上开发顺序，确保模块依赖关系正确、接口稳定、开发效率最大化。

## 目录

1. [模块依赖图](#模块依赖图)
2. [开发阶段划分](#开发阶段划分)
3. [各阶段详细清单](#各阶段详细清单)
4. [完成度标准](#完成度标准)
5. [接口稳定性要求](#接口稳定性要求)
6. [交叉开发指南](#交叉开发指南)

---

## 模块依赖图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           第 6 层：应用层                                    │
│  fafafa.core (门面单元)                                                      │
│  fafafa.core.benchmark, fafafa.core.test                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                           第 5 层：数据格式层                                │
│  fafafa.core.json, fafafa.core.xml, fafafa.core.yaml                        │
│  fafafa.core.toml, fafafa.core.csv, fafafa.core.ini                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                           第 4 层：系统服务层                                │
│  fafafa.core.fs, fafafa.core.process, fafafa.core.socket                    │
│  fafafa.core.logging, fafafa.core.signal, fafafa.core.env                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                           第 3 层：并发层                                    │
│  fafafa.core.thread, fafafa.core.async, fafafa.core.lockfree                │
│  fafafa.core.parallel, fafafa.core.pool                                     │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                           第 2 层：容器层                                    │
│  fafafa.core.collections (vec, vecdeque, hashmap, list, ...)                │
│  fafafa.core.bytes, fafafa.core.stringBuilder                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                           第 1 层：同步原语层                                │
│  fafafa.core.sync (mutex, rwlock, condvar, barrier, sem, event, ...)        │
│  fafafa.core.atomic                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                           第 0 层：基础层                                    │
│  fafafa.core.base, fafafa.core.mem, fafafa.core.math                        │
│  fafafa.core.option, fafafa.core.result                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 开发阶段划分

| 阶段 | 层级 | 模块数 | 实际状态 | 整体完成度 | 前置条件 |
|------|------|--------|----------|------------|----------|
| Phase 0 | 基础层 | 5 | ✅ 完成 | 83% | 无 |
| Phase 1 | 同步原语层 | 2 | ✅ 完成 | 85% | Phase 0 完成 |
| Phase 2 | 容器层 | 4 | ✅ 完成 | 83% | Phase 1 完成 |
| Phase 3 | 并发层 | 5 | 🔳 基本完成 | 72% | Phase 2 完成 |
| Phase 4 | 系统服务层 | 6 | 🔳 基本完成 | 73% | Phase 3 完成 |
| Phase 5 | 数据格式层 | 6 | ✅ 完成 | 78% | Phase 4 完成 |
| Phase 6 | 应用层 | 3 | ✅ 完成 | 83% | Phase 5 完成 |

**项目整体完成度**: ~80%

---

## 各阶段详细清单

### Phase 0：基础层（Foundation Layer）

**目标**：建立类型系统、内存管理、数学工具等基础设施

| 序号 | 模块 | 依赖 | 状态 | 完成度 | 接口稳定性 | 代码行数 |
|------|------|------|------|--------|------------|----------|
| 0.1 | `fafafa.core.base` | SysUtils, Classes | ✅ COMPLETE | 80% | ✅ STABLE | 276 |
| 0.2 | `fafafa.core.math` | fafafa.core.base | ✅ COMPLETE | 85% | ✅ STABLE | 43K+ (7个子模块) |
| 0.3 | `fafafa.core.mem` | fafafa.core.base | ✅ COMPLETE | 85% | ✅ STABLE | 30+ 子模块 |
| 0.4 | `fafafa.core.option` | fafafa.core.base | ✅ COMPLETE | 80% | ✅ STABLE | 275+6K |
| 0.5 | `fafafa.core.result` | fafafa.core.base | ✅ COMPLETE | 85% | ✅ STABLE | 1021+31K |

**关键接口**：
- `IAllocator` - 内存分配器接口
- `TProc`, `TObjProc`, `TRefProc` - 过程类型
- `ECore` 异常层次结构

**验收标准**：
- [ ] 所有模块编译通过
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] HeapTrc 内存泄漏检测通过
- [ ] 接口文档完整

---

### Phase 1：同步原语层（Synchronization Layer）

**目标**：提供线程安全的同步原语

| 序号 | 模块 | 依赖 | 状态 | 完成度 | 接口稳定性 | 代码行数 |
|------|------|------|------|--------|------------|----------|
| 1.1 | `fafafa.core.atomic` | fafafa.core.base | ✅ COMPLETE | 85% | ✅ STABLE | 111K+ (3个子模块) |
| 1.2 | `fafafa.core.sync` | fafafa.core.base | ✅ COMPLETE | 85% | ✅ STABLE | 30K+ (40+子模块) |

**子模块开发顺序**（fafafa.core.sync）：
1. `sync.base` - 基础定义
2. `sync.mutex` - 互斥锁
3. `sync.spin` - 自旋锁
4. `sync.rwlock` - 读写锁
5. `sync.condvar` - 条件变量
6. `sync.sem` - 信号量
7. `sync.event` - 事件
8. `sync.barrier` - 屏障
9. `sync.once` - 单次执行
10. `sync.waitgroup` - 等待组
11. `sync.latch` - 倒计时锁存器
12. `sync.parker` - Rust 风格 Parker
13. `sync.oncelock` - Rust 风格 OnceLock

**关键接口**：
- `TMutex`, `TRWLock`, `TCondVar`
- `TSpinLock`, `TSemaphore`, `TEvent`
- `TBarrier`, `TWaitGroup`, `TLatch`

**验收标准**：
- [ ] 多线程压力测试通过
- [ ] 死锁检测测试通过
- [ ] 性能基准测试完成

---

### Phase 2：容器层（Container Layer）

**目标**：提供高性能泛型容器

| 序号 | 模块 | 依赖 | 状态 | 完成度 | 接口稳定性 | 代码行数 |
|------|------|------|------|--------|------------|----------|
| 2.1 | `fafafa.core.collections.base` | mem.allocator, math | ✅ COMPLETE | 85% | ✅ STABLE | 119K |
| 2.2 | `fafafa.core.collections` | collections.base | ✅ COMPLETE | 85% | ✅ STABLE | 47K+ (34个子模块) |
| 2.3 | `fafafa.core.bytes` | collections.base | ✅ COMPLETE | 80% | ✅ STABLE | 2个子模块 |
| 2.4 | `fafafa.core.stringBuilder` | collections.base | ✅ COMPLETE | 80% | ✅ STABLE | 1个模块 |

**容器开发顺序**（fafafa.core.collections）：
1. `collections.elementManager` - 元素管理器
2. `collections.arr` - 静态数组包装
3. `collections.vec` - 动态数组（核心）
4. `collections.vecdeque` - 双端队列
5. `collections.list` - 双向链表
6. `collections.forwardList` - 单向链表
7. `collections.stack` - 栈
8. `collections.queue` - 队列
9. `collections.hashmap` - 哈希映射（核心）
10. `collections.linkedhashmap` - 有序哈希映射
11. `collections.treemap` - 红黑树映射
12. `collections.priorityqueue` - 优先队列
13. `collections.bitset` - 位集合
14. `collections.lrucache` - LRU 缓存
15. `collections.trie` - 字典树
16. `collections.skiplist` - 跳表

**关键接口**：
- `ICollection`, `IIterable`, `IIndexable`
- `TVec<T>`, `TVecDeque<T>`, `THashMap<K,V>`
- `TList<T>`, `TPriorityQueue<T>`

**验收标准**：
- [ ] 所有容器 API 一致性审查通过
- [ ] 边界测试（Low/High/0/-1）通过
- [ ] 内存泄漏检测通过
- [ ] 性能基准对比完成

---

### Phase 3：并发层（Concurrency Layer）

**目标**：提供高性能并发工具

| 序号 | 模块 | 依赖 | 状态 | 完成度 | 接口稳定性 | 代码行数 |
|------|------|------|------|--------|------------|----------|
| 3.1 | `fafafa.core.thread` | sync, collections | ✅ COMPLETE | 85% | ✅ STABLE | 46K+ (15个子模块) |
| 3.2 | `fafafa.core.lockfree` | atomic, mem | ✅ COMPLETE | 85% | ✅ STABLE | 20+ 子模块 |
| 3.3 | `fafafa.core.async` | thread, collections | 🔳 BASIC | 60% | ⚠️ UNSTABLE | 12K+ (2个子模块) |
| 3.4 | `fafafa.core.parallel` | thread, collections | 🔳 BASIC | 50% | ⚠️ UNSTABLE | 6.8K |
| 3.5 | `fafafa.core.pool` | thread, collections | ✅ COMPLETE | 80% | ✅ STABLE | 含于 thread |

**无锁结构开发顺序**（fafafa.core.lockfree）：
1. `lockfree.stack` - Treiber 栈
2. `lockfree.spsc` - 单生产者单消费者队列
3. `lockfree.mpsc` - 多生产者单消费者队列
4. `lockfree.mpmc` - 多生产者多消费者队列

**关键接口**：
- `TThreadPool`, `TFuture<T>`, `TChannel<T>`
- `TLockFreeStack<T>`, `TLockFreeMPSCQueue<T>`
- `TAsyncRuntime`, `TParallelFor`

**验收标准**：
- [ ] 并发正确性测试通过
- [ ] ABA 问题测试通过
- [ ] 性能基准：SPSC ≥ 100M ops/sec

---

### Phase 4：系统服务层（System Services Layer）

**目标**：提供系统级服务封装

| 序号 | 模块 | 依赖 | 状态 | 完成度 | 接口稳定性 | 代码行数 |
|------|------|------|------|--------|------------|----------|
| 4.1 | `fafafa.core.fs` | base, collections | ✅ COMPLETE | 85% | ✅ STABLE | 34个子模块 |
| 4.2 | `fafafa.core.process` | base, collections | ✅ COMPLETE | 80% | ✅ STABLE | 多个子模块 |
| 4.3 | `fafafa.core.socket` | base, collections | 🔳 BASIC | 60% | ⚠️ UNSTABLE | 多个子模块 |
| 4.4 | `fafafa.core.env` | base, collections | ✅ COMPLETE | 85% | ✅ STABLE | 1个模块 |
| 4.5 | `fafafa.core.signal` | base, sync | ✅ COMPLETE | 80% | ✅ STABLE | 多个子模块 |
| 4.6 | `fafafa.core.logging` | sync, collections, io | 🔳 BASIC | 50% | ⚠️ UNSTABLE | 多个子模块 |

**关键接口**：
- `IFile`, `IDirectory`, `IPath`
- `IProcess`, `IProcessBuilder`
- `ISocket`, `ITcpListener`, `IUdpSocket`
- `ILogger`, `ILogSink`

**验收标准**：
- [ ] 跨平台测试通过（Windows/Linux/macOS）
- [ ] 错误处理完整
- [ ] 资源清理测试通过

---

### Phase 5：数据格式层（Data Format Layer）

**目标**：提供数据序列化/反序列化

| 序号 | 模块 | 依赖 | 状态 | 完成度 | 接口稳定性 | 代码行数 |
|------|------|------|------|--------|------------|----------|
| 5.1 | `fafafa.core.json` | mem.allocator, collections | ✅ COMPLETE | 85% | ✅ STABLE | 9.5K+ (多个子模块) |
| 5.2 | `fafafa.core.xml` | mem.allocator, collections | ✅ COMPLETE | 80% | ✅ STABLE | 多个子模块 |
| 5.3 | `fafafa.core.yaml` | mem.allocator, collections | 🔳 BASIC | 60% | ⚠️ UNSTABLE | 多个子模块 |
| 5.4 | `fafafa.core.toml` | mem.allocator, collections | ✅ COMPLETE | 80% | ✅ STABLE | 多个子模块 |
| 5.5 | `fafafa.core.csv` | collections | ✅ COMPLETE | 85% | ✅ STABLE | 1个模块 |
| 5.6 | `fafafa.core.ini` | collections | ✅ COMPLETE | 80% | ✅ STABLE | 1个模块 |

**关键接口**：
- `IJsonReader`, `IJsonWriter`, `IJsonValue`
- `IXmlReader`, `IXmlWriter`, `IXmlNode`
- `IYamlReader`, `IYamlWriter`

**验收标准**：
- [ ] 标准合规性测试通过
- [ ] 大文件性能测试通过
- [ ] UTF-8 编码测试通过

---

### Phase 6：应用层（Application Layer）

**目标**：提供门面单元和测试框架

| 序号 | 模块 | 依赖 | 状态 | 完成度 | 接口稳定性 | 代码行数 |
|------|------|------|------|--------|------------|----------|
| 6.1 | `fafafa.core` | 所有模块 | ✅ COMPLETE | 80% | ✅ STABLE | 门面单元 |
| 6.2 | `fafafa.core.test` | 所有模块 | ✅ COMPLETE | 85% | ✅ STABLE | 多个子模块 |
| 6.3 | `fafafa.core.benchmark` | 所有模块 | ✅ COMPLETE | 85% | ✅ STABLE | 多个子模块 |

**验收标准**：
- [ ] 门面单元导出完整
- [ ] 示例程序运行通过
- [ ] 文档完整

---

## 完成度标准

### 完成度级别定义

| 级别 | 百分比 | 标准 | 标记 |
|------|--------|------|------|
| 未开始 | 0% | 尚未开始开发 | ⬜ TODO |
| 骨架 | 20% | 代码结构完成，编译通过 | 🔲 SKELETON |
| 基本 | 50% | 核心功能实现，基础测试通过 | 🔳 BASIC |
| 完整 | 80% | 所有功能实现，全量测试通过 | ✅ COMPLETE |
| 生产就绪 | 100% | 代码审查、性能验证、内存安全验证全部通过 | 🏆 PRODUCTION |

### 各级别详细要求

#### 20% - 骨架（SKELETON）
- [ ] 文件结构创建完成
- [ ] 接口定义完成
- [ ] 编译通过（无实现）
- [ ] 基本文档框架

#### 50% - 基本（BASIC）
- [ ] 核心功能实现
- [ ] 基础测试用例通过
- [ ] 主要 API 可用
- [ ] 基本错误处理

#### 80% - 完整（COMPLETE）
- [ ] 所有功能实现
- [ ] 全量测试通过
- [ ] 边界测试通过
- [ ] 文档完整
- [ ] 示例代码完成

#### 100% - 生产就绪（PRODUCTION）
- [ ] 代码审查通过
- [ ] 性能基准验证
- [ ] HeapTrc 内存泄漏检测通过
- [ ] 多线程压力测试通过
- [ ] API 稳定性确认
- [ ] 版本号标记

---

## 接口稳定性要求

### 稳定性级别

| 级别 | 标记 | 含义 | 变更策略 |
|------|------|------|----------|
| 实验性 | 🧪 EXPERIMENTAL | 接口可能随时变更 | 无需通知 |
| 不稳定 | ⚠️ UNSTABLE | 接口可能在下个版本变更 | 需要弃用警告 |
| 稳定 | ✅ STABLE | 接口在主版本内保持兼容 | 需要迁移指南 |
| 冻结 | 🔒 FROZEN | 接口永不变更 | 禁止修改 |

### 接口变更规则

1. **Phase 0-1 模块**：必须达到 `STABLE` 才能进入 Phase 2
2. **Phase 2 模块**：必须达到 `STABLE` 才能进入 Phase 3
3. **依赖模块变更**：需要评估所有上层模块影响
4. **破坏性变更**：需要提供迁移指南和弃用周期

### 接口审查清单

- [ ] 命名规范一致性
- [ ] 参数顺序合理性
- [ ] 返回值类型一致性
- [ ] 异常/错误处理一致性
- [ ] 文档注释完整性

---

## 交叉开发指南

### 允许的交叉开发

在满足以下条件时，可以进行交叉开发：

1. **同层模块**：同一层级的模块可以独立推进（默认顺序开发，避免并行协作流程）
2. **接口已冻结**：依赖模块的接口已达到 STABLE
3. **Mock 可用**：可以使用 Mock 对象进行测试

### 交叉开发矩阵

```
          Phase 0  Phase 1  Phase 2  Phase 3  Phase 4  Phase 5
Phase 0     ✅       ❌       ❌       ❌       ❌       ❌
Phase 1     ✅       ✅       ❌       ❌       ❌       ❌
Phase 2     ✅       ✅       ✅       ❌       ❌       ❌
Phase 3     ✅       ✅       ✅       ✅       ❌       ❌
Phase 4     ✅       ✅       ✅       ✅       ✅       ❌
Phase 5     ✅       ✅       ✅       ✅       ✅       ✅

✅ = 可以依赖  ❌ = 不可依赖
```

### 开发流程

```
1. 选择模块
   ↓
2. 检查依赖模块完成度
   ↓ (依赖模块 ≥ 80%)
3. 创建骨架代码 (20%)
   ↓
4. 实现核心功能 (50%)
   ↓
5. 完善功能和测试 (80%)
   ↓
6. 代码审查和性能验证 (100%)
   ↓
7. 标记接口稳定性
   ↓
8. 更新本文档状态
```

---

## 附录

### A. 模块完整列表

共计 **594** 个源文件，**136** 个测试目录，**47** 个顶级模块：

```
fafafa.core.archiver    fafafa.core.args        fafafa.core.async
fafafa.core.atomic      fafafa.core.base        fafafa.core.benchmark
fafafa.core.bytes       fafafa.core.collections fafafa.core.color
fafafa.core.compress    fafafa.core.crypto      fafafa.core.csv
fafafa.core.env         fafafa.core.fs          fafafa.core.graphics
fafafa.core.id          fafafa.core.ini         fafafa.core.io
fafafa.core.json        fafafa.core.lockfree    fafafa.core.logging
fafafa.core.math        fafafa.core.mem         fafafa.core.option
fafafa.core.os          fafafa.core.parallel    fafafa.core.pipeline
fafafa.core.poller      fafafa.core.pool        fafafa.core.process
fafafa.core.report      fafafa.core.result      fafafa.core.settings
fafafa.core.signal      fafafa.core.simd        fafafa.core.socket
fafafa.core.stringBuilder fafafa.core.sync      fafafa.core.term
fafafa.core.test        fafafa.core.thread      fafafa.core.tick
fafafa.core.time        fafafa.core.toml        fafafa.core.widgets
fafafa.core.xml         fafafa.core.yaml
```

### B. 代码统计摘要

| 模块类别 | 代码行数 | 子模块数 |
|----------|----------|----------|
| collections | 47,298 | 34 |
| sync | 30,908 | 40+ |
| atomic | 111,150+ | 3 |
| json | 9,516 | 多个 |
| thread | 46,000+ | 15 |
| lockfree | 20,000+ | 20+ |
| fs | - | 34 |
| mem | - | 30+ |

### C. 快速参考命令

```bash
# 编译单个模块
/home/dtamade/freePascal/fpc -O3 -Fi./src -Fu./src src/fafafa.core.<module>.pas

# 运行模块测试
bash tests/fafafa.core.<module>/BuildOrTest.sh

# 内存泄漏检测
/home/dtamade/freePascal/fpc -gh -gl -B -Fu./src -Fi./src -oTestLeak test_<module>.pas
./TestLeak

# 快速回归测试
STOP_ON_FAIL=1 bash tests/run_all_tests.sh
```

### D. 文档更新日志

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-01-13 | v1.0 | 初始版本 |
| 2026-01-13 | v1.1 | 更新实际完成度评估数据 |

---

*本文档由 AI 助手生成，最后更新于 2026-01-13。请根据实际开发进度持续更新。*
