# fafafa.core L0 Foundation Kernel

本文档定义 `fafafa.core` 的 L0。目标不是做一个“什么都能塞进去的基础层”，而是做一个小而强、稳定、可长期复用的基础内核。

## L0 的定位

L0 负责四类事情：

- 基础语义
- bit / layout / endian 这类原始数据语义
- 原子与内存模型
- 分配契约

L0 不负责以下事情：

- 容器
- IO
- 线程与同步服务
- runtime capability / dispatch
- 文件系统、网络、进程
- 依赖其他框架服务才能成立的高级抽象

换句话说，L0 要解决的是“框架最底层怎么说话、怎么表达状态、怎么保证内存语义、怎么分配内存”，而不是“框架帮你做什么服务”。

## L0 的 ASCII 结构

```text
                        +------------------+
                        |   Free Pascal    |
                        |       RTL        |
                        +---------+--------+
                                  |
      +-------------+-------------+-------------+-------------+
      |             |             |             |             |
      v             v             v             v             v
+----------------+  +------------------+  +----------------+  +----------------------+
| settings.inc   |  | fafafa.core.base |  | bits/layout/   |  | atomic.base          |
| build contract |  | shared semantics |  | endian         |  | memory model         |
+----------------+  +--------+---------+  +--------+-------+  +----------+-----------+
                             |                     |                     |
                +------------+------------+        |                     v
                |                         |        |            +------------------+
                v                         v        |            | atomic.compat    |
       +------------------+      +------------------+          +--------+---------+
       | option.base      |      | result           |                   |
       | option           |      | result.facade    |                   v
       +------------------+      +------------------+          +------------------+
                                                                  | atomic           |
                                                                  +------------------+

                             +-----------------------------------------------+
                             | mem.allocator.base                            |
                             |     -> rtlAllocator / callbackAllocator       |
                             +-----------------------------------------------+
```

## 当前纳入 L0 的模块

| 类别 | 单元 | 为什么在 L0 |
|------|------|-------------|
| 构建契约 | `fafafa.core.settings.inc` | 统一承载基础宏、契约开关、平台特性开关 |
| 基础语义 | `fafafa.core.base` | 所有上层共享的类型、异常、函数类型、元组与通用约定 |
| 前置条件 helper | `fafafa.core.contracts` | 统一承载 strict L0 的 precondition helper，给 `option` / `result` / allocator contract 复用 |
| 可空语义 | `fafafa.core.option.base`, `fafafa.core.option` | `Option<T>` 是框架级基础语义，而不是某个服务模块的附属品 |
| 结果语义 | `fafafa.core.result`, `fafafa.core.result.facade` | `Result<T, E>` 是错误传播和组合的基础表达方式 |
| 位级基础 | `fafafa.core.bits` | 对齐、幂次判断和基础整数布局辅助属于所有上层都可能复用的 bit-level 语义 |
| 布局契约 | `fafafa.core.layout` | `TMemLayout`、`TAllocCaps` 与默认对齐 / cache line / page size 都是跨 allocator / bytes / collections 共享的底层布局合同 |
| 字节序语义 | `fafafa.core.endian` | endian 枚举、native 解析与 byteswap 属于独立的基础数据语义，不应继续埋在 `bytes` consumer 里 |
| 原子模型 | `fafafa.core.atomic.base`, `fafafa.core.atomic.compat`, `fafafa.core.atomic` | 定义原子操作、内存序和兼容层，是并发系统的底层前提 |
| 分配契约 | `fafafa.core.mem.allocator.foundation`, `fafafa.core.mem.allocator.base`, `fafafa.core.mem.allocator.rtlAllocator`, `fafafa.core.mem.allocator.callbackAllocator` | `foundation` 提供 strict L0 稳定入口，`base + minimal backends` 提供最小契约与最小实现 |

## 本轮已落地的 L0 基础能力

这轮不是只在文档里“宣布候选方向”，而是已经把 `bits/layout/endian` 真正落地到代码里。

- `fafafa.core.bits`
  - 负责 `DivRoundUp`、`IsPowerOfTwo`、`NextPowerOfTwo`、`AlignUp`、`AlignDown`、`IsAligned`
- `fafafa.core.layout`
  - 负责 `TMemLayout`、`TAllocCaps`、`MEM_DEFAULT_ALIGN`、`MEM_CACHE_LINE_SIZE`、`MEM_PAGE_SIZE`、`TryNextPowerOfTwo`
- `fafafa.core.endian`
  - 负责 `TEndianness`、`NativeEndianness`、`ResolveEndianness`、`IsLittleEndian`、`IsBigEndian`、`ByteSwap16`、`ByteSwap32`、`ByteSwap64`

同时，旧入口已经明确降为 compat / consumer：

- `fafafa.core.math.intutil`
  - 现在是 `fafafa.core.bits` 的兼容层，不再是 bit helper 的 source-of-truth
- `fafafa.core.mem.layout`
  - 现在是 `fafafa.core.layout + fafafa.core.bits` 的兼容层，不再是布局契约的 source-of-truth
- `fafafa.core.bytes`
  - 现在显式依赖 `fafafa.core.endian`，并保留 `TEndianness` 与 `enLittleEndian` / `enBigEndian` / `enNative` 兼容别名

## 当前明确不纳入 L0 的模块

| 模块 | 不纳入原因 |
|------|------------|
| `fafafa.core.simd*` | 包含 runtime capability、dispatch、public ABI、多后端实现，职责已经超出基础内核 |
| `fafafa.core.math*` | 属于数值工具与算法层，不是最小语义内核 |
| `fafafa.core.collections*` | 容器会带来容量策略、迭代器、所有权与更宽 API 面 |
| `fafafa.core.bytes*`, `fafafa.core.io*` | 已经进入服务抽象层 |
| `fafafa.core.sync*`, `fafafa.core.thread*`, `fafafa.core.time*` | 是上层系统服务，不是最小底层契约 |
| `fafafa.core.lockfree*` | 尽管底层，但属于高级并发数据结构，不是所有模块都必须依赖的基础语言 |
| `fafafa.core.result.collect` | 依赖 `fafafa.core.collections.vec`，已经跨出 L0 |
| `fafafa.core.mem.allocator.mimalloc` | 依赖可选后端，不应和基础契约绑定 |
| `fafafa.core.mem.allocator.crtAllocator` | 条件编译的外部后端，不应作为纯 L0 必备实现 |
| `fafafa.core.mem.allocator.instrumentation` | 属于调试和观测扩展，不属于严格 L0 |

## L0 的开发范式

L0 继续保持 `fafafa.core` 现有的开发范式，但要求更严格。

### 1. 保持扁平命名与明确职责

- 继续使用 `fafafa.core.<module>` 的扁平命名。
- 如果一个主题需要“契约层”和“门面层”，优先拆成 `*.base` 和主单元，而不是把所有内容堆进一个文件。
- 如果一个单元开始引入服务层语义，就要考虑上移，不要为了“看起来底层”而留在 L0。

### 2. `settings.inc` 只做基础开关，不做服务决策

- `settings.inc` 负责基础宏和特性开关。
- 它不能演化成任意功能模块的总开关中心。
- 需要服务层策略切换时，应放回对应模块，而不是下压到 L0。

### 3. 门面可以保留，但不能掩盖层级事实

- 门面单元适合对外给出稳定入口。
- 但门面如果把可选后端、实验实现、调试扩展一起重导出，文档必须明确哪些是“L0 契约中心”，哪些只是“当前实现聚合点”。
- `fafafa.core.mem.allocator.pas` 当前就是这种过渡门面。

### 4. 平台实现可以低层，但只能实现已有契约

- 平台特化、架构特化可以存在于 L0。
- 前提是它们只是对基础契约的实现，而不是顺带把 capability discovery、service registry 或 runtime policy 拉进来。

### 5. API 要小，语义要硬

- L0 API 面应该小。
- 命名、错误语义、所有权语义、内存语义必须稳定。
- 如果一个能力必须依赖“框架里另外几个模块配合才好用”，那它大概率不该在 L0。

## `mem.allocator` 的现状与目标

当前实现里：

- `fafafa.core.mem.allocator.foundation` 提供 strict L0 的纯门面。
- `fafafa.core.mem.allocator.base` 提供核心接口和抽象基类。
- `rtlAllocator` 和 `callbackAllocator` 是最小可依赖实现。
- `mimalloc`、`crtAllocator`、instrumentation 则是可选后端或扩展能力。

因此，当前最合理的 L0 说法是：

- **L0 持有 allocator contract**
- **L0 不自动持有所有 allocator backend**

当前实现已经收敛为两条入口：

1. `fafafa.core.mem.allocator.foundation`：只重导出 contract + minimal backend，属于 strict L0。
2. `fafafa.core.mem.allocator`：继续保留兼容 / 扩展聚合角色，可牵出 `mimalloc`、`crt` 等可选能力。

因此本轮不仅是文档边界先立住，代码入口也已经对应收紧。

## L0 后续仍可评估的能力

在 `bits/layout/endian/contracts` 已经落地之后，后续只有在满足“RTL-only、跨模块通用、语义非常基础、API 面可控”时，以下能力才适合继续考虑进入 L0：

- `platform`
- `span`

这些名字代表的是下一批候选方向，不代表应该立刻继续扩张 L0。

## L0 准入清单

一个新能力只有在全部满足时才应该进入 L0：

- 只依赖 RTL 和已确认的 L0 单元。
- 不是容器，不是服务，不是 runtime dispatch，不是 registry。
- 解决的是全框架共同的基础表达问题。
- 能被 `collections`、`simd`、`sync`、`io` 等多个上层模块自然复用。
- API 可以长期稳定，不会频繁随业务或服务实现改变。

只要有一项不满足，就应该优先放在 Layer 1 或 Layer 2。

## 当前结论

`fafafa.core` 的理想 L0 不是更大，而是更准。

它应该是一个 balanced kernel：

- 小到不会把上层服务误塞进底层
- 强到可以稳定托住容器、并发、SIMD、IO 与功能层

这就是当前 L0 的目标形态。
