# SIMD 分层实施基线

这份文档只回答三件事：

1. `simd` 模块最终要做成什么样
2. 为什么这里不是两层，而是三层
3. 后续实施时，哪些东西能下沉，哪些东西必须留在 adapter

如果你这次只是想判断“谁是当前真相源”，先看：

- `docs/SIMD_BACKEND_TRUTH.md`
- `docs/SIMD_INTRINSICS_DISPOSITION.md`
- `docs/SIMD_SSE2_MIGRATION_MAP.md`

如果你这次要决定“下一步到底怎么改代码”，先把这页读完。

## 先锁死目标形态

`fafafa.core.simd` 的目标不是“把所有 SIMD 代码都塞进 intrinsics”。

当前和后续都应该按下面三层理解：

1. `stable façade / control-plane`
2. `thin backend adapter`
3. `raw intrinsics leaf`

对应到仓库里的口径：

- `fafafa.core.simd` / `api` / `runtime` / `dispatch` / `cpuinfo`
  - 属于稳定公开面和控制面
- `fafafa.core.simd.*`
  - 属于默认主线 backend adapter
- `fafafa.core.simd.intrinsics.*`
  - 属于 raw ISA leaf 或 experimental / transitional 单元

一句话说死：

> 公开 contract 在 façade，backend 归属在 `simd.*`，原始指令语义在 `intrinsics.*`。

## 为什么这里不是两层

很多库可以做成两层：

- façade
- intrinsics

但那类两层结构有前提。通常要同时满足：

- façade 暴露的就是 raw 寄存器语义
- 没有 runtime backend 选择
- 没有 dispatch table 注册
- 没有 `TVec*` / `TMask*` 这类独立 contract
- 没有 wide emulation
- 没有 stable / experimental 默认隔离
- 一个 façade 函数基本就是一个 intrinsic 的直通包装

`fafafa.core.simd` 明显不是这种库。

这里实际对外暴露的是：

- `TVec*` 向量语义
- `TMask*` 压缩掩码语义
- runtime backend 选择
- dispatch table
- 多 ISA 主线 backend
- 一部分 256/512 宽度在低阶 backend 上的组合语义

这几件事决定了 `facade -> intrinsics` 不能直接画等号。

### `TVec*` 不是 `TM128`

`intrinsics` 的天然语言是 `TM128/TM256/TM512`。

`facade` 的天然语言是 `TVecF32x4/TVecF64x2/TVecI32x4/...`。

这不只是类型名字不同，而是公开 contract 不同：

- raw leaf 只承诺寄存器级语义
- façade 还承诺对外的向量类型与调用方式

### `TMask*` 不是 raw compare result

raw leaf 经常返回一个 128-bit compare 向量。

但 façade 对外承诺的是：

- `TMask2`
- `TMask4`
- `TMask8`
- `TMask16`

也就是已经压缩过、翻译过的 bitmask contract。

这个职责必须有人承担，而且它不该塞进 raw intrinsics。

### 很多 façade 语义不是一个 intrinsic

这个仓库里有大量“不是单条指令直通”的内容，比如：

- `wide_emulation`
- 多个 128-bit leaf 组合出的 256/512 语义
- façade 级 select / helper / compare 派生逻辑
- mem / text / stat helper

这些都天然属于 backend adapter，而不是 raw leaf。

### runtime / dispatch 是控制面，不该污染 leaf

像下面这些东西：

- `RegisterSSE2Backend`
- dispatch slot 填充
- backend 可用性接线
- runtime 重绑定

如果进了 `intrinsics.*`，那它就不再是 leaf，而是半个 backend adapter。

### 这个仓库需要 stable / experimental 隔离

当前仓库已经明确：

- experimental intrinsics 默认不进入 stable entry chain
- `intrinsics.x86.sse2` 当前仍是 `experimental isolated`

如果把 façade 直接建立在 experimental leaf 上，相当于让 stable 公开面默认吃 experimental 依赖。这会把边界重新搞乱。

## 三层分别负责什么

### 第一层：stable façade / control-plane

典型文件：

- `src/fafafa.core.simd.pas`
- `src/fafafa.core.simd.api.pas`
- `src/fafafa.core.simd.runtime.pas`
- `src/fafafa.core.simd.dispatch.pas`
- `src/fafafa.core.simd.cpuinfo.pas`

负责：

- 对外公开 API
- data-plane façade
- runtime / control-plane
- CPU/OS capability view
- dispatch contract

不负责：

- 具体 ISA raw leaf 细节

### 第二层：thin backend adapter

典型文件：

- `src/fafafa.core.simd.scalar.pas`
- `src/fafafa.core.simd.sse2.pas`
- `src/fafafa.core.simd.sse3.pas`
- `src/fafafa.core.simd.ssse3.pas`
- `src/fafafa.core.simd.sse41.pas`
- `src/fafafa.core.simd.sse42.pas`
- `src/fafafa.core.simd.avx2.pas`
- `src/fafafa.core.simd.avx512.pas`
- `src/fafafa.core.simd.neon.pas`

负责：

- `TVec*` façade 语义
- `TMask*` façade 语义
- backend 注册
- dispatch slot 填充
- compare-mask 压缩/翻译
- `wide_emulation`
- 多寄存器组合语义
- façade helper

不负责：

- 把自己伪装成 raw ISA leaf

要求：

- 这层要尽量薄
- 但它不能消失
- 它的价值就是承接“公开 contract”和“raw 指令语义”之间的接缝

### 第三层：raw intrinsics leaf

典型文件：

- `src/fafafa.core.simd.intrinsics.base.pas`
- `src/fafafa.core.simd.intrinsics.sse.pas`
- `src/fafafa.core.simd.intrinsics.avx2.pas`
- `src/fafafa.core.simd.intrinsics.x86.sse2.pas`

负责：

- raw `TM128/TM256/TM512` 语义
- load / store
- set / zero / broadcast
- add / sub / mul
- bitwise
- compare
- shift
- pack / unpack / shuffle / cast

不负责：

- `TVec*`
- `TMask*`
- dispatch 注册
- runtime control-plane
- backend 选择
- façade helper

## SSE2 是这个边界的样板

当前 SSE2 的职责要按下面三句话理解：

- `src/fafafa.core.simd.sse2.pas` 是当前 SSE2 backend adapter truth source
- `src/fafafa.core.simd.intrinsics.x86.sse2.pas` 是未来 raw leaf 的目标落点
- `src/fafafa.core.simd.intrinsics.sse2.pas` 只是 transitional compatibility wrapper

这不是抽象偏好，而是仓库现状。

原因很具体：

- `simd.sse2` 现在仍承载注册、`TVec*`、`TMask*`、`wide_emulation`、helper、多寄存器组合
- `intrinsics.x86.sse2` 当前虽然已有大量 raw primitive，但仍受 experimental guard 保护
- `intrinsics.sse2` 仍带历史兼容 / transitional 包袱

所以 SSE2 的正确迁移方式不是“把 `simd.sse2` 改名成 intrinsics”，而是：

1. 保持 `simd.sse2` 作为 adapter truth source
2. 逐族把可纯化的 raw primitive 收到 `intrinsics.x86.sse2`
3. adapter 在证据充分后，按需委托给 raw leaf

## 哪些东西可以下沉，哪些必须留下

### 可以下沉到 raw leaf

只有“纯 128-bit raw primitive”可以下沉，例如：

- raw load / store
- raw set / zero / broadcast
- raw add / sub / mul
- raw bitwise
- raw compare building block
- raw shift
- raw unpack / pack / shuffle / cast

判断标准很简单：

- 输入输出都是 `TM128/TM256/TM512` 风格
- 不涉及 dispatch
- 不涉及 runtime
- 不涉及 `TVec*`
- 不涉及 `TMask*`
- 不涉及 helper 语义

### 必须留在 adapter

下面这些默认都属于 adapter，不应下沉：

- backend 注册与 dispatch 接线
- `TVec*` façade 公开函数
- `TMask*` contract
- compare-mask 压缩/翻译
- `wide_emulation`
- 多寄存器组合语义
- mem / text / stat helper
- 任何 façade 级 select / reduce / aggregate 包装

## 后续实施规则

以后新增或迁移任意一个 family，都按这个顺序做。

### Step 1：先判层，不要先写代码

先回答：

- 这是 `stable façade`？
- `backend adapter`？
- 还是 `raw intrinsics leaf`？

没判清之前，不进入默认主链路。

### Step 2：先补 raw 证据，再做 adapter 委托

如果目标是把某个 family 下沉到 raw leaf：

1. 先在 leaf 测试通道补 raw semantic tests
2. 证明 leaf 行为稳定
3. 再让 adapter 委托给 leaf

不要反过来先把 stable adapter 接到一个还没有 raw 证据的 experimental leaf 上。

### Step 3：adapter 名字保留，contract 不迁名

就算 raw leaf 成熟了：

- `SSE2LoadF32x4`
- `SSE2AddF32x4`
- `SSE2CmpEqF64x2`

这类 façade / adapter 名字也继续保留在 `simd.sse2`。

迁的是 leaf 实现归属，不是 façade 对外 contract。

### Step 4：一次只迁一个小 family

推荐批次：

- 先 `load/store`
- 再 `set/zero`
- 再 `bitwise`
- 再 `arithmetic`

不要在同一批里同时混：

- helper
- mask contract
- wide emulation
- dispatch wiring

## 反模式

下面这些做法，后续都应视为错误方向。

### 反模式 1：把 `intrinsics.*` 说成统一主线实现层

这会直接抹掉 stable / experimental / transitional 的边界。

### 反模式 2：为了“只有两层好看”而把 adapter 消掉

结果通常只有两种：

- `intrinsics` 被污染成半个 backend adapter
- façade 内部散落 backend 细节和 mask 翻译

这两种都比现在更乱。

### 反模式 3：还没补 raw tests 就让 stable adapter 直接依赖 experimental leaf

这会让 stable 面背上没有证据的 experimental 风险。

### 反模式 4：一次性搬空 `simd.sse2`

这违反当前保守迁移原则，也会让真相源和发布现实脱节。

## 实施时用什么做裁决

如果后续工程师对边界有分歧，以这四份文档一起裁决：

- `docs/SIMD_LAYERING_IMPLEMENTATION.md`
- `docs/SIMD_BACKEND_TRUTH.md`
- `docs/SIMD_INTRINSICS_DISPOSITION.md`
- `docs/SIMD_SSE2_MIGRATION_MAP.md`

其中：

- 这页负责解释“为什么是三层”和“怎么实施”
- `BACKEND_TRUTH` 负责回答“默认主线 backend 是谁”
- `INTRINSICS_DISPOSITION` 负责回答“每个 intrinsics 单元当前是什么状态”
- `SSE2_MIGRATION_MAP` 负责回答“SSE2 具体哪些东西可以迁、哪些不能迁”

## 一句话结论

`fafafa.core.simd` 的正确目标不是“两层直通”，而是：

> 用稳定 façade 暴露 contract，用 thin backend adapter 承接语义接缝，用 raw intrinsics leaf 承接原始指令实现。

对这个仓库来说，这不是偏好，而是最小混乱方案。
