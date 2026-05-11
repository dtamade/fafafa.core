# SIMD 分层设计与实施基线

这份文档是下一轮实施的主设计文档。

如果你下一次开新会话，要直接开始改 `simd`，先读这页，再读下面三张表：

- `docs/SIMD_BACKEND_TRUTH.md`
- `docs/SIMD_INTRINSICS_DISPOSITION.md`
- `docs/SIMD_SSE2_MIGRATION_MAP.md`

这 4 份文档的分工是固定的：

- 这页负责回答“整体结构应该长成什么样”“为什么不是两层”“下一步应该怎么实施”
- `BACKEND_TRUTH` 负责回答“默认主线 backend 是谁”
- `INTRINSICS_DISPOSITION` 负责回答“每个 intrinsics 单元现在处于什么状态”
- `SSE2_MIGRATION_MAP` 负责回答“SSE2 哪些东西以后可以迁，哪些必须留下”

## 先记住一句总纲

`fafafa.core.simd` 的正确目标不是“两层直通：façade -> intrinsics”。

对这个仓库，正确目标是：

> 用稳定公开面暴露 contract，用 thin backend adapter 承接 façade 语义和控制面接缝，用 raw leaf 承接原始 ISA 语义。

再压缩一点：

> 三个核心层，一个 control/publication seam，两个 companion surfaces，四种 intrinsics 状态。

下面把这三件事写死。

## 先看全局图

从全局看，当前 `simd` 不是只有一条“公开 façade -> backend -> intrinsics”的主线。

它同时还带着三个必须显式安置的中间结构：

- `control/publication seam`
- `public ABI wrapper`
- `direct dispatch companion`

这里真正容易被漏掉的不是 `direct`，而是 `dataplane`。

如果 `dataplane` 继续只被当成实现细节，不被写进主设计，下一轮实施时还是会反复把它误判成：

- `dispatch` 的附属 helper
- `direct/public ABI` 的私有缓存
- 或 façade hot-path 的偶然优化

这三种理解都不对。

`dataplane` 在当前仓库里已经是 **published binding seam**。

它和 `dispatch` 一起，构成了“控制真相发布到热点调用面”的中间缝。

## 最优雅终态

从整个模块看，最优雅的目标形态不是只背“有三层”。

更准确的全局图应该是：

1. `public surface`
2. `control/publication seam`
3. `companion surfaces`
4. `backend adapters`
5. `raw leaves`

压成更贴近代码的结构就是：

```text
public surface
  -> simd / api / runtime / cpuinfo

control/publication seam
  -> dispatch / dataplane

companion surfaces
  -> public ABI wrapper / direct

backend adapters
  -> scalar / sse2 / avx2 / neon / ...

raw leaves
  -> intrinsics.*
```

这张图里有两个关键点：

- `dispatch` 负责 control-plane truth
- `dataplane` 负责 published binding snapshot

而 `simd.pas` façade fast-path、`public ABI wrapper`、`direct` 都只是消费这条发布缝。

如果这三个面不写出来，读者很容易误以为整个模块只有 Pascal façade 一条入口链，这就不算“全局反映架构”。

## 第一层：public / control surface

这一层负责对外 contract 和运行时控制面。

典型单元：

- `src/fafafa.core.simd.pas`
- `src/fafafa.core.simd.api.pas`
- `src/fafafa.core.simd.runtime.pas`
- `src/fafafa.core.simd.cpuinfo.pas`

职责：

- 对外公开 `TVec*` façade
- 对外公开 mem / text / stat data-plane façade
- 对外公开 runtime / control-plane
- 对外公开 CPU/OS capability 视图

不负责：

- 原始 ISA leaf 语义
- backend 内部拼装细节

## 一条中间缝：control / publication seam

这一段不适合硬塞进“public surface”或“backend adapter”。

它的职责就是把“控制面真相”稳定地发布成“热点调用面可消费的绑定结果”。

### `dispatch`

对应位置：

- `src/fafafa.core.simd.dispatch.pas`

职责：

- backend 注册
- backend 选择
- in-repo dispatch contract
- dispatch hook publication
- runtime 切换后的 target truth

它是 control-plane truth source。

### `dataplane`

对应位置：

- `src/fafafa.core.simd.dataplane.pas`

职责：

- 按当前 published dispatch 生成 data-plane binding snapshot
- 保存 façade hot-path / public ABI / direct 会消费的已绑定函数指针
- 以“发布后的 snapshot”而不是“每次现算 getter”形式服务热点路径
- `simd.pas` 可以保留本地 dispatch pointer mirror，但这份 mirror 只能从 `dataplane` snapshot 发布结果填充，不能回到 control-plane 现算

它不是：

- 新的 public API
- backend selector
- backend adapter
- raw leaf

为什么这里要单独写出来：

- `simd.pas` façade fast-path 会从这里取 bound pointers
- `simd.pas` 普通 wrapper 会从这里派生本地 dispatch mirror，避免热点路径每次再穿过 dataplane getter
- `public ABI wrapper` 会从这里取 bound API table 成员
- `direct` 会从这里取当前 dispatch snapshot

如果不把这条 seam 单独写出来，下一轮实施时就很容易把 façade fast-path、public ABI 和 direct 的共享语义拆散。

## 第二层：backend adapter

这一层负责把公开 contract 绑定到具体 backend。

典型单元：

- `src/fafafa.core.simd.scalar.pas`
- `src/fafafa.core.simd.sse2.pas`
- `src/fafafa.core.simd.sse3.pas`
- `src/fafafa.core.simd.ssse3.pas`
- `src/fafafa.core.simd.sse41.pas`
- `src/fafafa.core.simd.sse42.pas`
- `src/fafafa.core.simd.avx2.pas`
- `src/fafafa.core.simd.avx512.pas`
- `src/fafafa.core.simd.neon.pas`
- `src/fafafa.core.simd.riscvv.pas`

职责：

- `TVec*` façade 语义
- `TMask*` façade 语义
- backend 注册
- dispatch slot 填充
- compare-mask 压缩/翻译
- `wide_emulation`
- 多寄存器组合语义
- façade 级 helper

要求：

- 这层应尽量薄
- 但它不能被删除
- 它存在的意义就是承接“公开 contract”和“raw leaf”之间的语义接缝

## 第三层：raw leaf

这一层只负责原始寄存器级语义。

典型单元：

- `src/fafafa.core.simd.intrinsics.base.pas`
- `src/fafafa.core.simd.intrinsics.sse.pas`
- `src/fafafa.core.simd.intrinsics.avx2.pas`
- `src/fafafa.core.simd.intrinsics.x86.sse2.pas`

职责：

- `TM128/TM256/TM512` 风格 raw 语义
- raw load / store
- raw set / zero / broadcast
- raw add / sub / mul
- raw bitwise
- raw compare building block
- raw shift
- raw unpack / pack / shuffle / cast

不负责：

- `TVec*`
- `TMask*`
- backend 注册
- dispatch 注册
- runtime / control-plane
- façade helper

## 两个伴生出口

这两个面都是真实代码面，但都不应该被误判成“又多了一层实现”。

### `public ABI wrapper`

对应位置：

- `src/fafafa.core.simd.public_abi.intf.inc`
- `src/fafafa.core.simd.public_abi.impl.inc`
- 物理上由 `src/fafafa.core.simd.pas` include 进主入口

逻辑位置：

- 第一层的 external stable wrapper

职责：

- 给 Pascal 之外的调用方暴露 POD-only 稳定边界
- 暴露 `cdecl` 风格 public API table
- 消费当前 `dataplane` published binding，而不是重新发明一套 backend 语义

不负责：

- 公开 `TSimdDispatchTable` 作为外部 ABI
- backend adapter 注册
- raw leaf 语义

要记死一句：

> `public ABI wrapper` 是外部稳定包装面，不是内部 dispatch contract 的直接翻版。

### `direct dispatch companion`

对应位置：

- `src/fafafa.core.simd.direct.pas`

逻辑位置：

- 第一层旁路 fast-path companion

职责：

- 读取当前已发布的 data-plane dispatch snapshot
- 给仓库内热点路径、测试和 wiring 提供 direct pointer 访问
- 在 control-plane 切换后通过 `dataplane` 执行 rebind

不负责：

- 自己决定 active backend
- 自己维护 dispatch 真相
- 替代 `runtime` / `dispatch` 成为 control-plane 裁决面

要记死一句：

> `direct` 只是读取已发布 dataplane 的伴生入口，不是新的 backend，也不是新的控制面真相源。

## 七类单元

这一步最容易被写乱。

`namespace` 不等于 `layer`。尤其是 `fafafa.core.simd.*` 这个前缀，不要直接等同于 backend adapter。

同样要记住：

- include-backed surface 也可以承载独立 contract
- 物理文件位置不等于逻辑职责层次

下一轮实施时，请按下面七类单元判断，而不是只按文件名前缀判断。

| 单元类别 | 典型文件 | 所属逻辑层 | 说明 |
| --- | --- | --- | --- |
| public / canonical surface | `simd` / `api` / `runtime` / `cpuinfo` | 第一核心层 | 对外 contract 与 canonical public/control surface |
| control seam | `dispatch` | 中间缝 | control-plane truth、dispatch contract、hook publication |
| publication seam | `dataplane` | 中间缝 | published binding snapshot；给 façade/public ABI/direct 消费 |
| public ABI wrapper | `public_abi.intf/impl.inc` | companion surface | POD-only external stable wrapper；物理上挂在 `simd.pas` 内 |
| direct dispatch companion | `direct` | companion surface | 读取已发布 dataplane snapshot；不是控制面真相源 |
| backend adapter | `scalar` / `sse2` / `avx2` / `neon` 等 | 第二核心层 | 默认主线 backend 真相源 |
| raw leaf family | `intrinsics.*` | 第三核心层 | 具体状态看 disposition 表，不要默认都能进入 stable 主链 |

这张表要记死五条：

1. `dispatch` 在 `simd.*` 命名空间里，但它不是 backend adapter
2. `dataplane` 是 publication seam，不是 public façade，也不是 backend adapter
3. `public ABI wrapper` 物理上在 `simd.pas` 里，但逻辑上是独立外部 contract 面
4. `direct` 是伴生 fast-path，不拥有 backend 选择真相
5. `intrinsics.*` 在实现上属于 raw leaf 平面，但能不能被默认 stable adapter 依赖，要看它的状态，不是看它叫不叫 intrinsics

## 四种 intrinsics 状态

`intrinsics` 的状态，不是修辞词，是实施准入条件。

当前只允许这四种：

- `active leaf`
- `experimental isolated`
- `transitional`
- `retire target`

这四种状态的实施含义如下：

| 状态 | 能否作为默认 stable adapter 的新依赖 | 能否承接新的 raw family | 典型用途 |
| --- | --- | --- | --- |
| `active leaf` | 可以，但必须先有 raw tests | 可以 | 已纳入主线实施秩序的 raw leaf |
| `experimental isolated` | 不可以 | 可以做隔离实验 | 默认 stable 入口链不得直接依赖 |
| `transitional` | 不可以 | 原则上不再新增职责 | 历史兼容 / wrapper / 迁移包袱 |
| `retire target` | 不可以 | 不可以 | 只等迁移证据齐全后删除 |

下一轮实施最重要的一条准入规则是：

> stable backend adapter 只允许新增依赖 `active leaf`，不允许新增依赖 `experimental isolated` 或 `transitional`。

这条规则要和下面这条一起理解：

> `intrinsics.*` 是 raw leaf 平面，不等于它已经具备 stable 依赖资格。

## 为什么这里不是两层

很多库确实可以做成两层：

- façade
- intrinsics

但那种两层结构有前提。通常要同时满足：

- façade 暴露的就是 raw 寄存器语义
- 没有 runtime backend 选择
- 没有 dispatch 注册
- 没有独立的 `TVec*` contract
- 没有独立的 `TMask*` contract
- 没有 wide emulation
- 没有 stable / experimental 默认隔离
- 一个 façade 函数基本就是一个 intrinsic 的直通包装

`fafafa.core.simd` 不满足这些前提。

### `TVec*` contract 不是 `TM128`

公开面天然语言是：

- `TVecF32x4`
- `TVecF64x2`
- `TVecI32x4`
- 以及更宽的 façade 类型

raw leaf 的天然语言是：

- `TM128`
- `TM256`
- `TM512`

这不是简单 typedef 差异，而是 contract 差异：

- raw leaf 承诺寄存器级语义
- façade 承诺对外向量 API 语义

### `TMask*` contract 不是 raw compare result

raw compare 往往给你一整块向量寄存器结果。

公开 contract 需要的是：

- `TMask2`
- `TMask4`
- `TMask8`
- `TMask16`

也就是已经压缩、翻译过的 façade mask 语义。

这个职责必须留在 adapter。

### 很多 façade 行为不是单条 intrinsic

典型例子：

- `wide_emulation`
- 多个 128-bit leaf 组合出的更宽语义
- façade 级 select / reduce / aggregate
- mem / text / stat helper

这些都不是 raw leaf 应该承接的职责。

### runtime / dispatch 是控制面

像这些东西：

- `RegisterSSE2Backend`
- dispatch slot 填充
- backend 能力接线
- runtime 重绑定

都属于控制面或 adapter 接线逻辑，不应进入 raw leaf。

### 这里还有显式 publication seam

这个仓库不只是“有 dispatch”。

它还明确有：

- runtime published snapshot
- dataplane published snapshot

也就是说，当前实现不是“门面每次自己重新找 dispatch”，而是：

- `dispatch` 先发布 control-plane truth
- `dataplane` 再发布热点调用面要消费的 binding snapshot
- façade fast-path / public ABI / direct 只读取这份已发布结果

这也是为什么 `dataplane` 必须被写进主架构，而不是继续埋在实现细节里。

### 这个仓库还有 companion surfaces

这里不仅有普通 Pascal façade，还有两个额外边界：

- `public ABI wrapper`：对外稳定包装
- `direct dispatch companion`：对内热点直达入口

这两个面都依赖“先有稳定 public/control surface，再经过 control/publication seam，最后发布 dataplane snapshot”。

更重要的是：

- `simd.pas` 自己的 façade fast-path 也在消费这条 seam
- 所以这不是 `public ABI/direct` 两个特例，而是整个热点调用面的共用结构

如果做成“façade 直接引用 intrinsics”的两层直通，最终只会把：

- façade hot-path 绑定
- 外部 ABI 包装
- direct dataplane 绑定
- dispatch publication

重新塞回一个含混的 façade 层里，结构上反而更脏。

### 这个仓库明确需要 stable / experimental 隔离

只要一个 raw leaf 仍是 `experimental isolated`，默认 stable 入口链就不能把它当成普通实现依赖。

这不是编码偏好，是仓库当前的发布边界。

## 全局规则和 SSE2 局部规则不能混写

上一版最容易误导的地方，就是把 SSE2 当前的局部迁移纪律，写成了整个仓库的全局设计规则。

这里统一纠正：

### 全局规则

对整个仓库，raw leaf 的抽象形态可以是：

- `TM128`
- `TM256`
- `TM512`

也就是说：

- `intrinsics.avx2` 这类 `active leaf` 例外是允许存在的
- 未来如果某个 256/512 family 被正式纳入 `active leaf`，也完全符合整体设计

### SSE2 当前局部规则

对当前 `SSE2` 迁移线，raw leaf frontier 只限定在：

- 纯 `TM128`
- 纯 128-bit family

原因不是“整个仓库只允许 128-bit leaf”，而是：

- 当前目标单元是 `intrinsics.x86.sse2`
- 当前最小、最稳、最容易证明 parity 的 frontier 就是 128-bit raw family

所以：

> “只迁 128-bit”是 SSE2 当前实施纪律，不是整个仓库的全局设计定律。

## SSE2 的正确设计位置

SSE2 是下一轮最重要的实施样板，但它不是全仓库的唯一范式。

当前必须锁死三句话：

- `src/fafafa.core.simd.sse2.pas` 是当前 SSE2 backend adapter truth source
- `src/fafafa.core.simd.intrinsics.x86.sse2.pas` 是未来 raw leaf 的目标落点
- `src/fafafa.core.simd.intrinsics.sse2.pas` 是 transitional compatibility wrapper

再加一条最关键的实施准入：

- 只要 `intrinsics.x86.sse2` 仍然是 `experimental isolated`，`simd.sse2` 就不应新增对它的默认 stable 依赖

这意味着：

- `SSE2_MIGRATION_MAP` 里的 A 桶现在是“目标归属图”
- 不是“今天就可以直接把 stable adapter 接进去”的授权书

要把 A 桶真正变成可实施迁移，必须先满足准入条件。

## SSE2 可以迁什么，必须留什么

### 永久留在 adapter

下面这些职责，默认都属于 adapter：

- backend 注册与 dispatch 接线
- `TVec*` façade 公开函数
- `TMask*` contract
- compare-mask 压缩/翻译
- `wide_emulation`
- 多寄存器组合语义
- mem / text / stat helper
- façade 级 select / reduce / aggregate 包装

### 可以下沉到 raw leaf

对当前 SSE2 frontier，只允许纯 `TM128` raw family 讨论下沉，例如：

- raw load / store
- raw set / zero / broadcast
- raw arithmetic
- raw bitwise
- raw compare building block
- raw shift
- raw unpack / pack / shuffle / cast

判断标准很简单：

- 输入输出是 raw `TM128`
- 不涉及 `TVec*`
- 不涉及 `TMask*`
- 不涉及 dispatch
- 不涉及 runtime
- 不涉及 façade helper

## 下一轮实施必须遵守的准入顺序

这是下一次新会话最重要的执行顺序。

### Step 1：先判“层”和“状态”

先回答两个问题：

1. 这次改的是 public surface、control seam、publication seam、companion surface、backend adapter，还是 raw leaf
2. 如果涉及 raw leaf，这个单元现在是 `active leaf`、`experimental isolated`、还是 `transitional`

没判清之前，不开始迁移。

### Step 2：先补 raw semantic tests

如果目标是把某个 family 下沉到 raw leaf：

1. 先补 raw semantic tests
2. 先证明 leaf 行为稳定
3. 先证明它符合 raw leaf 边界

这一步没完成，不进入 stable adapter 委托。

### Step 3：先拿到 stable 依赖资格，再允许 adapter 委托

只有两种路径允许进入这一步：

1. 目标单元本身已经是 `active leaf`
2. 目标单元虽然当前不是 `active leaf`，但你先把它提升为 `active leaf`，或者把其中稳定子集拆成新的 `active leaf` 单元

如果既没有 promotion，也没有 split，就不允许让 stable adapter 直接依赖它。

### Step 4：adapter 名字保留，contract 不迁名

就算 raw leaf 成熟了：

- `SSE2LoadF32x4`
- `SSE2AddF32x4`
- `SSE2CmpEqF64x2`

这些 façade / adapter 名字也继续保留在 `simd.sse2`。

迁移的是实现归属，不是对外 contract 改名。

### Step 5：一次只迁一个小 family

推荐的 SSE2 实施顺序：

1. `load/store`
2. `set/zero/broadcast`
3. `bitwise`
4. `arithmetic`
5. `compare/shift/shuffle`

不要在同一批里混入：

- helper
- mask contract
- `wide_emulation`
- dispatch wiring

## 下一轮建议的第一批实施内容

如果下一次新会话要直接开始干，建议按下面顺序。

### Phase A：把 `intrinsics.x86.sse2` 做到“可准入判断”

目标不是立刻接线，而是先回答：

- 它能不能从 `experimental isolated` 进入 `active leaf`
- 或者是否应该先拆出一个更小的 `active leaf` 子集

这一阶段的工作应集中在：

- `TM128` raw load/store
- `TM128` set/zero/broadcast
- `TM128` bitwise

并补齐对应 raw semantic tests。

### Phase B：做准入决策

这一步只有两个合法结果：

1. promote：`intrinsics.x86.sse2` 或其稳定子集进入 `active leaf`
2. hold：继续保持 `experimental isolated`，此时 stable `simd.sse2` 不做默认接线

不允许的结果：

- 还保持 `experimental isolated`
- 但 stable adapter 已经直接依赖它

### Phase C：做第一批 adapter 委托

只有在 Phase B 通过后，才建议开始第一批委托。

推荐第一批只动这 8 个 façade helper：

- `SSE2LoadF32x4`
- `SSE2StoreF32x4`
- `SSE2SplatF32x4`
- `SSE2ZeroF32x4`
- `SSE2LoadF64x2`
- `SSE2StoreF64x2`
- `SSE2SplatF64x2`
- `SSE2ZeroF64x2`

这批之所以合适，是因为它们最接近纯 raw family，不牵涉 mask、wide、helper、dispatch。

### Phase D：再决定是否继续推进 bitwise

如果前一批干净通过，再单独讨论：

- `SSE2AndI32x4`
- `SSE2OrI32x4`
- `SSE2XorI32x4`
- `SSE2AndNotI32x4`

不要把这批和第一批混做。

## Stop Conditions

下一轮实施过程中，只要遇到下面任意一条，就应该停在当前批次，不要越线。

- raw tests 还没补齐
- target leaf 仍是 `experimental isolated`
- leaf 边界被 `TVec*` / `TMask*` / dispatch / runtime 污染
- 需要同时改 helper、mask、wide、dispatch 才能让一个小 family 工作
- 需要删除现有 `simd.sse2` 正式导出符号

## 反模式

下面这些做法，一律按错误方向处理。

### 反模式 1：把 `intrinsics.*` 说成统一主线实现层

这会直接抹掉 stable / active / experimental / transitional 的边界。

### 反模式 2：把 `simd.*` 前缀直接等同于 adapter

这样会把 `dispatch` 这种 control / infra 单元误判成 backend adapter。

### 反模式 3：把 SSE2 局部规则外推成整个仓库的全局规则

最常见的错误就是：

- “SSE2 现在先只迁 128-bit”
- 被误说成
- “整个仓库的 raw leaf 只能是 128-bit”

这不成立。

### 反模式 4：还没 promotion 就让 stable adapter 直接依赖 experimental leaf

这会把 stable 面和 experimental 面重新混起来。

### 反模式 5：一次性搬空 `simd.sse2`

这违反当前保守迁移原则，也会让真相源和发布现实脱节。

## 下一轮实施前的最短读取顺序

如果你下一次开新会话，只想用 3 分钟恢复上下文，按这个顺序读：

1. `docs/SIMD_LAYERING_IMPLEMENTATION.md`
2. `docs/SIMD_BACKEND_TRUTH.md`
3. `docs/SIMD_INTRINSICS_DISPOSITION.md`
4. `docs/SIMD_SSE2_MIGRATION_MAP.md`
5. `docs/fafafa.core.simd.maintenance.md`
6. `docs/fafafa.core.simd.handoff.md`

然后再看代码和测试。

## 最终结论

这个仓库的设计基线不是：

> façade 直接引用 intrinsics，尽量只保留两层

而是：

> public / control surface 公开 contract，backend adapter 承接 façade 语义和运行时接缝，raw leaf 承接原始 ISA 语义；stable adapter 只允许新增依赖 active leaf。

这就是下一轮实施的最高优先级裁决规则。
