# SIMD Global Architecture Refactor Plan

**Goal:** 把整个 `fafafa.core.simd` 模块重构到“低冗余、职责单一、分层稳定、可持续演进”的状态，而不是只把某一个 ISA family 局部修漂亮。

**Architecture:** 不再把 `SSE2` 当成整个重构本身，而是把它降级为“第一条高债务试点 family”。全模块统一采用 `public/control surface -> control/publication seam -> companion surfaces -> backend adapters -> raw leaves` 的架构，并用统一的 unit disposition / verification lane / admission rule 管理所有 ISA family。

**Tech Stack:** FreePascal/Lazarus、`fafafa.core.simd` 主模块、`dispatch/runtime/cpuinfo/dataplane` 控制面、各 ISA backend adapter、`intrinsics.*` raw leaf 单元、release gate/check 脚本与 Python 结构检查器。

---

## 为什么现有 SSE2 计划不够

当前 `SSE2` 方案是必要的，但它只是局部重构计划，不是全模块重构计划。

原因有三个：

1. `SSE2` 当前同时带着 `stable adapter truth source + transitional wrapper + future raw leaf target` 三重身份，债务最集中，所以它适合作为试点。
2. 其他 ISA family 并不是“没考虑”，而是它们的现状不同：
   - 有的已经是 `active leaf` 样板，例如 `intrinsics.avx2`
   - 有的已有 stable adapter，但 raw leaf 还停留在 `experimental isolated`
   - 有的只适合继续保留在 opt-in / experimental lane
3. 如果继续只写 `SSE2`，后续很容易把“某个 family 的迁移策略”误当成“整个模块的全局架构”。

所以本计划的核心是：**先定义全模块统一治理模型，再决定每个 family 怎么迁。**

## 真正的终态

整个模块的目标不是“没有层”，也不是“全部直连 intrinsics”。

目标是：

```text
public / control surface
  -> simd / api / runtime / cpuinfo

control / publication seam
  -> dispatch / dataplane

companion surfaces
  -> public ABI wrapper / direct

backend adapters
  -> scalar / sse2 / sse3 / ssse3 / sse41 / sse42 / avx2 / avx512 / neon / riscvv / ...

raw leaves
  -> intrinsics.*
```

### 每层只做一件事

- `public / control surface`
  - 公开 `TVec*` / `TMask*` contract
  - 公开 runtime / cpuinfo / backend 选择语义
- `control / publication seam`
  - `dispatch` 负责 control-plane truth
  - `dataplane` 负责 published binding snapshot
- `companion surfaces`
  - `public ABI wrapper` 给外部 ABI 调用方
  - `direct` 给仓库内热点 companion path
- `backend adapters`
  - 承接 façade 语义、mask 语义、dispatch slot 填充、多寄存器组合与必要 helper
- `raw leaves`
  - 只承接 `TM128/TM256/TM512` 风格 raw ISA 语义

## 什么叫“不要冗余”

这里的“不要冗余”不是把所有层都删掉，而是消灭错误类型的冗余。

### 1. 真相源冗余

同一个 family 不能同时存在两个“今天都算默认发布真相”的实现入口。

目标：

- 每个 family 在任一时刻只允许一个 `current truth source`
- transitional wrapper 不能再被误读成 current truth source
- experimental leaf 不能再被误读成 current truth source

### 2. 语义冗余

同一类 raw primitive 不应同时在 adapter 和多个 intrinsics wrapper 中长期复制。

目标：

- raw leaf 负责 raw ISA primitive
- adapter 只保留 façade 级语义、组合语义、registration、mask 翻译
- transitional 单元只临时存在，不再承接新增长期职责
- 只要两个实现的 width / mask / result contract 完全一致，就合并成单一 helper 或 raw kernel，不再保留第二份同义实现
- typed wrapper 只保留签名、分发入口和必要的命名兼容，不再养独立 truth source

### 3. 入口冗余

相同的运行时/发布语义不能由多套控制路径各自维护。

目标：

- backend 选择只认 `dispatch`
- 热点调用绑定只认 `dataplane`
- `public ABI wrapper` / `direct` / façade fast-path 统一消费 publication seam

### 4. 状态冗余

“能不能被 stable adapter 默认依赖”不能在每个 family 单独发明规则。

目标：

- 全模块只认一套 disposition 规则：
  - `active leaf`
  - `experimental isolated`
  - `transitional`
  - `retire target`

## 全 ISA 视角下的当前分组

### A 组：可以作为正样板的 family

- `Scalar`
- `MMX`
- `SSE`
- `AVX2`

特点：

- 已有明确 adapter truth source
- 至少部分 raw leaf 已经进入 `active leaf`
- 已有实际测试/检查 lane

这组不是当前最大债务，而是后续重构时的“正样板”。

### B 组：高债务 family

- `SSE2`

特点：

- 当前 stable truth source 仍在 adapter
- 同时存在 transitional wrapper
- 同时存在 future raw leaf target
- 最容易把局部迁移策略误写成全局架构

这组要作为试点，但不能替代总规划。

### C 组：已有 adapter，但 raw leaf 还未准入的 family

- `SSE3`
- `SSSE3`
- `SSE4.1`
- `SSE4.2`
- `AVX-512`
- `NEON`
- `RISCVV`

特点：

- stable adapter 已存在
- raw leaf 多数仍处于 `experimental isolated`
- 默认 stable 链路不应直接新增对这些 experimental leaf 的依赖

这组的首要任务不是立刻搬代码，而是先做 raw-leaf qualification。

### D 组：继续隔离的实验 leaf

- `AES`
- `SHA`
- `AVX`
- `FMA3`
- `SVE`
- `SVE2`
- `LASX`

特点：

- 当前更适合作为 opt-in / experimental lane
- 不应在这轮全模块重构里强行并入 stable adapter 默认路径

## 全模块统一实施原则

### 原则 1：先判层，再判状态，再谈迁移

任何一个单元要改造，先回答 2 个问题：

1. 它属于 `public/control surface`、`seam`、`companion`、`adapter`、还是 `raw leaf`
2. 它当前状态是 `active leaf`、`experimental isolated`、`transitional`、还是 `retire target`

没有回答这两个问题，就不允许直接搬代码。

### 原则 2：stable adapter 只允许新增依赖 `active leaf`

这是全模块统一准入规则，不再只对 `SSE2` 生效。

因此：

- `experimental isolated` 不能直接进入 stable adapter 默认依赖
- `transitional` 不能作为新的长期落点
- 想被 stable adapter 默认使用，先 promote 为 `active leaf`，或先拆出新的 `active leaf` 子集

### 原则 3：每个 family 都要有自己的 verification lane

不能只看“能编译”，要看它在仓库里有没有独立可持续的验证入口。

每个 family 最少要声明：

- truth source
- disposition
- raw test lane
- adapter smoke lane
- 是否进入 default gate

### 原则 4：先建立矩阵，再开始删代码

删除 transitional / wrapper / duplicated helper 的前提是：

- replacement 已存在
- replacement 已有 parity 证据
- replacement 已进入正确 disposition
- gate 能持续守住边界

## 这套文档各自负责什么

这轮 whole-module refactor 不再允许“每份文档都讲一点，但没有唯一真相源”。

从现在开始按下面的分工看：

| 文档 | 责任 |
| --- | --- |
| `docs/plans/2026-05-10-simd-plan-status-index.md` | 计划生命周期入口：哪些 `simd` plan 仍是 active queue，哪些只是 historical baseline |
| `docs/plans/2026-05-10-simd-execution-index.md` | 下次开会话时的单页实施入口：先做什么、再做什么、改完后更新哪里 |
| `docs/plans/2026-05-10-simd-wave2-seam-hardening-plan.md` | 当前第一波 active 实施计划：收紧 `dispatch / dataplane / public ABI / direct` seam，不夹带 family migration |
| `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md` | whole-module 总纲、波次、完成标准 |
| `docs/plans/2026-05-09-simd-family-matrix.md` | 各 ISA family 的执行矩阵：truth source / disposition / verification lane / next action |
| `docs/SIMD_LAYERING_IMPLEMENTATION.md` | 架构裁决基线：层次、seam、companion、准入规则 |
| `docs/SIMD_BACKEND_TRUTH.md` | 当前 stable backend truth source 表 |
| `docs/SIMD_INTRINSICS_DISPOSITION.md` | 各 intrinsics 单元状态表 |
| `docs/SIMD_SSE2_MIGRATION_MAP.md` | `SSE2` family 的局部迁移图 |
| `docs/fafafa.core.simd.implementation-matrix.md` | non-x86 implementation working ledger |
| `docs/fafafa.core.simd.map.md` | 阅读入口，不承载新的设计真相 |

规则：

1. 总纲只定义全局规则，不重复抄 family 级细节。
2. family 细节进入 `family matrix` 或该 family 的局部迁移图。
3. 阅读地图只做导航，不再承载裁决性判断。

## 我对当前计划的判断

这份计划现在已经从“方向正确”进入“可以执行”，但还不能算完全完善。

### 现在已经具备的部分

- 有统一终态，不再是 `SSE2-first` 局部视角。
- 有统一准入规则，不再让每个 family 自己发明稳定性边界。
- 有波次，不再是散点翻文件。
- 有显式的 `family matrix`。
- 有文档分工，不再让总纲、状态表、阅读地图互相抢 source-of-truth。

### 还不够的部分

- `SSE2` 还没有进入 promote / split / retire 的决策文档阶段。
- `SSSE3` 的 raw-leaf 目标还没有在真相文档里被显式写死。
- `AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 目前仍只有 hold 判断，没有 future trigger 文档。

因此，这份计划现在已经是 `execution-ready`，但还不是 `closeout-complete`。

## 工作流分波次

## Wave 1：冻结总纲与 family matrix

目标：

- 把全模块重构目标从 `SSE2-first` 提升到 `whole-module`
- 为每个 ISA family 建立统一的 matrix

产出：

- global refactor plan
- family matrix
- 每个 family 的 truth/disposition/verification lane 表

退出条件：

- `docs/plans/2026-05-09-simd-family-matrix.md` 存在并覆盖当前 active families
- 总纲、matrix、layering doc 三者分工不冲突
- 后续执行可以不再从 `SSE2` 子问题重新起盘

## Wave 2：收紧 control/publication seam

目标：

- 明确 `dispatch` / `dataplane` / `public ABI wrapper` / `direct` 的唯一职责
- 停止 companion surface 继续各自复制控制语义

完成标志：

- backend 选择只认 `dispatch`
- published binding 只认 `dataplane`
- companion surface 不再私自拥有第二套 truth
- 文档层面不再有人把 `public ABI` / `direct` / façade fast-path 当成独立控制面

## Wave 3：建立 x86 family 样板

目标：

- 不是“一次性清空 x86”，而是把 x86 family 按状态分层治理

优先顺序：

1. `AVX2` 作为 `active leaf` 正样板
2. `SSE2` 作为高债务试点 family
3. `SSE3/SSSE3/SSE4.1/SSE4.2/AVX-512` 做 qualification，不急于默认接线

完成标志：

- `SSE2` 不再被当成全模块例外语义黑洞
- `AVX2` 被正式提炼成可复制样板
- 其他 x86 family 都被归入统一 matrix，而不是分散在历史脚本和注释里
- 至少一条 `experimental isolated -> active leaf` 或 `hold isolated` 的判定流程被文档化证明

## Wave 4：建立 non-x86 family 样板

目标：

- 统一 `NEON` / `RISCVV` / `SVE*` / `LASX` 的层次与状态判定

优先顺序：

1. `NEON`
2. `RISCVV`
3. `SVE/SVE2`
4. `LASX`

完成标志：

- non-x86 不再只有 adapter 入口，没有 raw-leaf qualification 计划
- opt-in / stable / experimental 边界对所有非 x86 family 都清晰可验证
- `NEON` / `RISCVV` 至少各有一条 family-specific qualification 路线

## Wave 5：消减冗余并冻结删除策略

目标：

- 清理 transitional wrapper
- 清理错误的 duplicated helper
- 冻结 retire target 列表

前提：

- 替代项已通过 release 证据
- family matrix 已更新
- gate / structure checker 能守住新边界

## 这轮重构不做什么

- 不把所有 adapter 一次性改写成“直接调 intrinsics”
- 不预设所有 intrinsics family 都要进入 stable default path
- 不把 `experimental isolated` 当成“只差一点点就能默认接线”
- 不因为追求“文件少一点”就删掉 `dispatch` / `dataplane` / `public ABI wrapper` / `direct` 这些真实架构位

## 完成标准

整个 `simd` 模块收口到“低冗余、正确架构”的标准，不是看某个 family 是否更优雅，而是同时满足：

1. 全模块每个 unit 都能被归到唯一层次和唯一 disposition
2. 每个 ISA family 都有明确 truth source 与 verification lane
3. stable adapter 不再默认依赖 `experimental isolated` / `transitional`
4. `dispatch` / `dataplane` / `public ABI wrapper` / `direct` 的边界稳定
5. redundant truth source / transitional debt 有明确 retire path
6. release 策略下的 `check` / `gate` / 结构检查继续通过

## 下一步

下一步应该是：

1. 继续维护 `AVX2 / NEON / RISCVV / x86 incremental` 这 4 份 family-level 文档，避免它们重新漂回聊天上下文
2. 把现有 `SSE2` 计划继续保留在 `Wave 3`，作为高债务试点子计划
3. 先补 `SSSE3` raw-leaf target 真相
4. 再按 matrix 执行 qualification / promote / split / retire
5. 最后再补 `SSE2 retire target` 与 `experimental hold future trigger` 这两类 closeout 级文档
