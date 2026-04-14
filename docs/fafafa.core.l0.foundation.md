# fafafa.core L0 Foundation Kernel

本文档定义 `fafafa.core` 的 L0。目标不是做一个“什么都能塞进去的基础层”，而是做一个小而强、稳定、可长期复用的基础内核。

## 当前 L0 文档组

L0 相关文档从现在起按固定分工维护：

1. `docs/ARCHITECTURE_LAYERS.md`
   说明 L0 在全仓架构分层里的位置。
2. `docs/fafafa.core.l0.foundation.md`
   说明 L0 当前到底包含什么、不包含什么。
3. `docs/fafafa.core.l0.roadmap.md`
   说明 L0 接下来该按什么原则继续推进。
4. `docs/audits/2026-04-11-l0-current-state-audit.md`
   说明当前已验证的执行状态。
5. `docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md`
   只保留当前这一轮 post-merge stabilization 的执行语境。
6. `docs/legacy/l0/`
   只保留已经退出 current-entry 的历史候选与 merge-prep closeout。

如果这些文档之间出现冲突，优先级按上面的顺序判断。

## L0 的定位

L0 负责五类事情：

- 基础语义
- 基础视图表达
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
| settings.inc   |  | fafafa.core.base |  | bits/layout/   |  | atomic.core          |
| build contract |  | shared semantics |  | endian         |  | memory-order core    |
+----------------+  +--------+---------+  +--------+-------+  +----------+-----------+
                             |                     |                     |
                +------------+------------+------------+        |            +------------------+
                |                         |            |        |            | atomic.base      |
                v                         v            v        |            +--------+---------+
       +------------------+      +------------------+ +------------------+          |
       | option.base      |      | result           | | span             |          v
       | option           |      | result.facade    | | read-only view   | +------------------+
       +------------------+      +------------------+ +------------------+ | atomic           |
                                                                             +--------+---------+
                                                                                      |
                                                                                      v
                                                                             +------------------+
                                                                             | atomic.compat    |
                                                                             +------------------+

                             +-----------------------------------------------+
                             | mem.allocator.base                            |
                             |     -> rtlAllocator / callbackAllocator       |
                             +-----------------------------------------------+
```

## 当前纳入 L0 的模块

| 类别            | 单元                                                                                                    | 为什么在 L0                                                                                                                                                                       |
| --------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 构建契约        | `fafafa.core.settings.inc`                                                                              | 统一承载基础宏、契约开关、平台特性开关                                                                                                                                            |
| 基础语义        | `fafafa.core.base`                                                                                      | 所有上层共享的类型、异常、函数类型、元组与通用约定                                                                                                                                |
| 前置条件 helper | `fafafa.core.contracts`                                                                                 | 统一承载 strict L0 的 precondition helper，给 `option` / `result` / allocator contract 复用                                                                                       |
| 可空语义        | `fafafa.core.option.base`, `fafafa.core.option`                                                         | `Option<T>` 是框架级基础语义，而不是某个服务模块的附属品                                                                                                                          |
| 结果语义        | `fafafa.core.result`, `fafafa.core.result.facade`                                                       | `Result<T, E>` 是错误传播和组合的基础表达方式                                                                                                                                     |
| 视图表达        | `fafafa.core.span`                                                                                      | 提供最小只读单段 / 双段、不拥有内存的基础视图 contract，给 collections / bytes 等上层复用                                                                                         |
| 位级基础        | `fafafa.core.bits`                                                                                      | 对齐、幂次判断和基础整数布局辅助属于所有上层都可能复用的 bit-level 语义                                                                                                           |
| 平台表达        | `fafafa.core.platform`                                                                                  | OS family、arch、pointer width 与 native endian 这类静态平台表达是 `simd` / `sync` / `io` 的共同底座，但不应混成 system probe                                                     |
| 布局契约        | `fafafa.core.layout`                                                                                    | `TMemLayout`、`TAllocCaps` 与默认对齐 / cache line / page size 都是跨 allocator / bytes / collections 共享的底层布局合同                                                          |
| 字节序语义      | `fafafa.core.endian`                                                                                    | endian 枚举、native 解析与 byteswap 属于独立的基础数据语义，不应继续埋在 `bytes` consumer 里                                                                                      |
| 原子模型        | `fafafa.core.atomic.core`, `fafafa.core.atomic.base`, `fafafa.core.atomic.compat`, `fafafa.core.atomic` | `atomic.core` 承载最小 memory-order / pause / fence / tagged-pointer packing contract；`atomic` 承载 raw primitive；`atomic.base` 承载 typed wrapper；`compat` 承载 legacy bridge |
| 分配契约        | `fafafa.core.mem.allocator.base`                                                                        | strict L0 只保留 allocator contract 与抽象基类；具体 backend 与 convenience facade 留在 mem 域上层                                                                                |

## 当前已落地的 L0 基础能力

当前不是只在文档里“宣布候选方向”，而是已经把 `bits/platform/layout/endian` 和最小 `span` contract 真正落地到代码里。

- `fafafa.core.bits`
  - 负责 `DivRoundUp`、`IsPowerOfTwo`、`NextPowerOfTwo`、`AlignUp`、`AlignDown`、`IsAligned`
- `fafafa.core.platform`
  - 负责 `TPlatformOS`、`TPlatformArch`、`TPlatformTarget`、`PlatformOS`、`PlatformArch`、`PlatformPointerBits`
  - 通过 `PlatformEndianness` / `PlatformTarget` 组合现有 endian 事实，但不引入新的 probe
  - 明确不承载 env/path/system probe/feature detection
- `fafafa.core.layout`
  - 负责 `TMemLayout`、`TAllocCaps`、`MEM_DEFAULT_ALIGN`、`MEM_CACHE_LINE_SIZE`、`MEM_PAGE_SIZE`、`TryNextPowerOfTwo`
- `fafafa.core.endian`
  - 负责 `TEndianness`、`NativeEndianness`、`ResolveEndianness`、`IsLittleEndian`、`IsBigEndian`、`ByteSwap16`、`ByteSwap32`、`ByteSwap64`
- `fafafa.core.atomic.core`
  - 负责 `memory_order_t`、`cpu_pause`、`atomic_thread_fence`、`atomic_signal_fence`
  - 负责 `atomic_tagged_ptr_t` 的 packing helper：`atomic_tagged_ptr`、`atomic_tagged_ptr_get_ptr`、`atomic_tagged_ptr_get_tag`、`atomic_tagged_ptr_next`
- `fafafa.core.span`
  - 负责最小只读 `TReadOnlySpan<T>` 与 `TReadOnlySpan2<T>`
  - 当前稳定 API：
    - `TReadOnlySpan<T>`：`FromPointer`、`Count`、`IsEmpty`、`Get`、`TryGet`、`GetPtr`、`SubSpan`
    - `TReadOnlySpan2<T>`：`FromTwo`、`ASpan`、`BSpan`、`Count`、`IsEmpty`、`Get`、`TryGet`、`GetPtr`、`GetBlock`、`SubSpan`
  - 明确不承载容器 `SliceView` 裁剪语义、`MakeContiguous`、容量策略或更宽的 segmented-container policy

同时，旧入口已经明确降为 compat / consumer：

- `fafafa.core.math.intutil`
  - 现在是 `fafafa.core.bits` 的兼容层，不再是 bit helper 的 source-of-truth
- `fafafa.core.mem.layout`
  - 现在是 `fafafa.core.layout + fafafa.core.bits` 的兼容层，不再是布局契约的 source-of-truth
- `fafafa.core.bytes`
  - 现在显式依赖 `fafafa.core.endian`，并保留 `TEndianness` 与 `enLittleEndian` / `enBigEndian` / `enNative` 兼容别名

## 当前明确不纳入 L0 的模块

| 模块                                                            | 不纳入原因                                                                                      |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `fafafa.core.simd*`                                             | 包含 runtime capability、dispatch、public ABI、多后端实现，职责已经超出基础内核                 |
| `fafafa.core.math*`                                             | 属于数值工具与算法层，不是最小语义内核                                                          |
| `fafafa.core.collections*`                                      | 容器会带来容量策略、迭代器、所有权与更宽 API 面                                                 |
| `fafafa.core.bytes*`, `fafafa.core.io*`                         | 已经进入服务抽象层                                                                              |
| `fafafa.core.sync*`, `fafafa.core.thread*`, `fafafa.core.time*` | 是上层系统服务，不是最小底层契约                                                                |
| `fafafa.core.lockfree*`                                         | 尽管底层，但属于高级并发数据结构，不是所有模块都必须依赖的基础语言                              |
| `fafafa.core.result.collect`                                    | 依赖 `fafafa.core.collections.vec`，已经跨出 L0                                                 |
| `fafafa.core.collections.slice` 中的容器 `SliceView` 行为       | collections 里的 today container semantics 仍属于 Layer 1，不应借 `span` 之名直接并入 strict L0 |
| `fafafa.core.mem.allocator.foundation`                          | 仍然保留为 mem 域低层 convenience facade，但不再定义 strict L0 边界                             |
| `fafafa.core.mem.allocator.rtlAllocator` / `callbackAllocator`  | 小而实用，但它们是具体 backend，不再算 strict L0 contract 本体                                  |
| `fafafa.core.mem.allocator.mimalloc`                            | 依赖可选后端，不应和基础契约绑定                                                                |
| `fafafa.core.mem.allocator.crtAllocator`                        | 条件编译的外部后端，不应作为纯 L0 必备实现                                                      |
| `fafafa.core.mem.allocator.instrumentation`                     | 属于调试和观测扩展，不属于严格 L0                                                               |

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

- `fafafa.core.mem.allocator.base` 提供 strict L0 真正保留的核心接口和抽象基类。
- `fafafa.core.mem.allocator.foundation` 提供 mem 域低层 convenience facade。
- `rtlAllocator` 和 `callbackAllocator` 继续保留为小型具体 backend。
- `mimalloc`、`crtAllocator`、`instrumentation` 则是可选后端或扩展能力。

因此，当前最合理的 L0 说法是：

- **L0 只持有 allocator contract**
- **具体 backend 与 convenience facade 留在 mem 域上层**

当前实现对应两条入口：

1. `fafafa.core.mem.allocator.base`：strict L0 的 contract core。
2. `fafafa.core.mem.allocator.foundation` / `fafafa.core.mem.allocator`：mem 域低层可用入口与兼容 / 扩展聚合入口。

## L0 后续仍可评估的能力

在 `bits/platform/layout/endian/contracts/span/span2` 已经落地之后，当前没有新的明确准入候选。

后续若要继续扩张 strict L0，仍然必须满足“RTL-only、跨模块通用、语义非常基础、API 面可控”的前提。

当前唯一仍值得保留在评估列表里的话题，是 `fafafa.core.span` 之外更宽的 `segmented span` 方向。

这里说的 future `segmented span`，指的是 deque / ring-buffer 双段只读视图方向的后续扩张候选。

它不等于否认 `fafafa.core.span` 里今天已经落地的最小 `TReadOnlySpan2<T>` cut，也不代表 `fafafa.core.span` 还处于候选状态。

今天对它的最严格约束是：

- 它只能作为 evaluation topic 存在，不能被写成已经 admission
- 它如果成立，也只能承载“最小双段只读视图 contract”，不能顺带把容器切片、deque policy、cursor helper 一起拉进 strict L0
- 它必须先证明自己是多个上层域都会自然复用的基础表达，而不是某个 consumer 的局部便利 API
- 只要它仍然主要依赖 `collections.slice`、deque block 布局或特定容器假设，它就还不该进入 strict L0

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
