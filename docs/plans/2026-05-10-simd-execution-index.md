# SIMD Execution Index

这页不是讲架构原理，也不是讲某个 family 的细节。

它只回答一件事：

> 如果下一次新开会话，要把 whole-module SIMD 计划正常实施，第一步该做什么，第二步该做什么。

如果你只想快速开始，不要先自己在总纲、matrix、family plan 之间来回跳，先看这页。

如果你是从搜索结果或目录列表里，直接点开某份旧 `simd` plan，先看：

- `docs/plans/2026-05-10-simd-plan-status-index.md`

## 一句话结论

当前 `simd` 的文档体系已经够开工。

正确起手顺序不是“先随便读一个熟悉的文件”，而是：

1. 先用 `plan status index` 排除历史/冲突 plan
2. 再用这页确认当前波次和执行顺序
3. 再去对应的 wave plan 或 family plan
4. 如果是 family 波次，再去 `family matrix` 对位当前 family
5. 再跑这条 wave/family 的 baseline 命令
6. 改完以后更新对应的 wave/family plan，再按需回写 matrix 和 scratch

## 当前总计划状态

### 已经完成的阶段

- `Wave 1 / planning`：已完成
  - total plan 已落盘
  - family matrix 已落盘
  - `AVX2 / x86 incremental / NEON / RISCVV` family-level 文档已落盘
- `Wave 2 / seam hardening`：已完成
  - `dispatch / dataplane / public ABI / direct / façade fast-path` 已收口到单一 truth / publication seam
  - `dispatch-read-scope` 已接入 `check`
- `Wave 3 / x86 families execution`：当前代码队列已完成
  - `Wave 3A` AVX2 sample / lane cleanup 已完成
  - `Wave 3B` SSSE3 noise cleanup / redundancy collapse 已完成
  - `Wave 3C` x86 incremental qualification / shared raw parity baseline 已独立落盘；当前不再作为默认代码起点
  - `Wave 3D` SSE2 debt pilot 已完成
- `Wave 4 / non-x86 families execution`：当前代码队列已完成
  - `NEON` exact-contract fallback forwarder 批次已收口，由 helper semantics checker 守住
  - `RISCVV` exact-contract facade fallback 批次已收口，继续保持 opt-in / opcode lane / ABI shape 边界

### 当前还没完成的阶段

- `Wave 5 / retire + redundancy cleanup`：当前默认下一波
  - retire / hold baseline 已落盘
  - 后续只处理有替代项、有证据、有 checker 护栏的 duplicated helper / transitional debt
  - 语义敏感路径继续要求独立 parity，不用“看起来相似”当合并依据

## 下次开会话的固定步骤

## Step 0：先确认今天是不是要做“文档”还是“代码”

如果你今天的目标是：

- 调整总架构
- 判断某个 family 当前该不该 promote
- 改 wave 顺序

先看：

- `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md`
- `docs/plans/2026-05-09-simd-family-matrix.md`
- `docs/plans/2026-05-11-simd-family-decision-baseline.md`

如果你今天的目标是：

- 落一个具体 family 的实现
- 修一个 bounded frontier / wiring / parity / ownership 问题
- 推进某个 wave

先看：

- 这页
- 对应 wave plan 或 family plan

## Step 1：先看当前执行队列，不要自己重新排优先级

当前默认执行队列是：

1. `Wave 5`：按 retire / hold baseline 清理 duplicated helper / transitional debt / future trigger drift
2. fresh-red family 回查：只有当 `check` / `gate` / family audit 明确红到某个 family，才回到对应 family plan
3. release closeout：如果代码队列已经没有可安全收口项，再回到 release evidence freshness / freeze-status 链路

规则：

- 不要重新打开已经收口的 `Wave 3C / Wave 4A / Wave 4B`，除非有 fresh red 或用户明确指定
- 只有当某条波次出现 fresh red 或用户明确指定，才允许跳队

## Step 2：按目标选入口文档

### 如果你今天要做 `Wave 2 / seam hardening`

看：

- `docs/plans/2026-05-10-simd-wave2-seam-hardening-plan.md`

目标：

- 先把 `dispatch / dataplane / public ABI / direct / façade fast-path` 的 seam 收紧
- 不夹带 family migration

说明：

- 这一波已经完成，当前只作为历史完成记录保留

### 如果你今天要做 `Wave 5 / retire + redundancy cleanup`

看：

- `docs/plans/2026-05-09-simd-sse2-retire-target-plan.md`
- `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
- `docs/plans/2026-05-09-simd-family-matrix.md`

目标：

- 只清理已经有 replacement / evidence / checker 的重复实现
- 只冻结明确 retire / hold 的对象，不把 stable adapter 责任误删
- 不把 semantic-sensitive path 伪装成 exact-contract 去重

### 如果你今天要冻结 family-level promote / hold / future-trigger 决策

看：

- `docs/plans/2026-05-11-simd-family-decision-baseline.md`

目标：

- 把 `family matrix` 里剩下的政策判断收成单页基线
- 避免下一次会话重新争论已经冻结的 family 定位

### 如果你今天要做 `AVX2`

看：

- `docs/plans/2026-05-09-simd-avx2-active-leaf-sample.md`

目标：

- 守住样板
- 不把 adapter / active leaf 边界写坏

### 如果你今天要做 `SSE3 / SSSE3 / SSE4.1 / SSE4.2 / AVX-512`

看：

- `docs/plans/2026-05-09-simd-x86-incremental-qualification-plan.md`
- `docs/plans/2026-05-09-simd-x86-raw-parity-plan.md`

当前补一句明确结论：

- `AVX-512` 这条线已经重新核对过，当前没有新的 thin-wrapper / duplicate implementation 可收，继续保持 `hold green`。
- `raw parity baseline` 已单独落盘，不再临场决定要不要另开 family 级 parity 文档。
- `Wave 3C` 当前不再是默认代码队列；只有 fresh red 明确落到这组 family 时，才回到这里。

目标：

- 先 qualification
- 不先做大迁移

### 如果你今天要做 `SSE2`

看：

- `docs/SIMD_SSE2_MIGRATION_MAP.md`
- `docs/plans/2026-05-09-simd-x86-incremental-qualification-plan.md`
- `docs/plans/2026-05-09-simd-family-matrix.md` 里的 `SSE2` 行
- `docs/plans/2026-05-09-simd-sse2-retire-target-plan.md`
- `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`

目标：

- 先补 raw-leaf qualification
- 再做 promote / split / retire 判断

### 如果你今天要做 `NEON`

看：

- `docs/plans/2026-05-09-simd-neon-qualification-plan.md`
- `docs/fafafa.core.simd.implementation-matrix.md`

目标：

- 先 qualification
- 守住 helper semantics / register truth / closeout evidence

### 如果你今天要做 `RISCVV`

看：

- `docs/plans/2026-05-09-simd-riscvv-qualification-plan.md`
- `docs/fafafa.core.simd.implementation-matrix.md`

目标：

- 先 qualification
- 守住 opt-in / opcode lane / ABI shape / register truth

## Step 3：先跑 baseline，再改代码

默认 baseline：

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

如果是 x86 波次，再加：

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

如果是 non-x86 波次，再加：

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86
```

规则：

- baseline 没跑，不开始重构
- baseline 红了，先定位是旧红还是新红

## Step 4：改代码时的红线

### 永远不要做的事

- 不把 `experimental isolated` 直接接进 stable adapter 默认依赖
- 不把 `transitional` 当长期落点
- 不把 `dispatch` / `dataplane` / `public ABI` / `direct` 各自再造一套 truth
- 不保留同合同的多重实现；只要 width / mask / result contract 相同，就收成单一 helper / raw kernel
- 不把 `SSE2` 的局部策略写成全仓库通用规则

### 默认允许做的事

- 补 qualification
- 补 representative parity
- 补 source truth / runtime evidence
- 收紧 adapter / leaf 边界
- 修 bounded frontier 实现缺口

## Step 5：改完后只更新这 3 处

每一波改完，默认更新：

1. 对应的 wave plan 或 family plan
2. `plans/scratch/2026-04-08-simd-review/` 下的 `task_plan.md / progress.md / findings.md`

如果这波直接改变某个 family 的 `Next action`、verification lane 或 disposition，再补：

3. `docs/plans/2026-05-09-simd-family-matrix.md`

不要每次波动都去改整个总纲。

总纲只在下面两种情况更新：

- 波次顺序变化
- 全局规则变化

## Step 6：收口时怎么判断“这一波完成了”

一波完成，不看“感觉差不多”，只看这 4 条：

1. 当前 wave/family plan 里的目标已经落地
2. 对应 verification lane fresh 通过
3. 如果影响 family 编排，family matrix 的 `Next action` 已更新
4. scratch 里写清楚了这轮做了什么、下一轮接着做什么

## 今天如果只想 5 分钟内开始

直接按这个最短流程：

1. 读这页
2. 打开 `docs/plans/2026-05-09-simd-family-matrix.md`
3. 选今天要推进的 wave 或 family
4. 打开对应 plan
5. 跑它的 baseline
6. 开工

## 当前还没做完的 closeout 级文档

这页只负责“怎么开始”，不负责把所有 closeout 问题都解决。

当前还明确未完成的是：

- `SSE2` promote / split / retire 决策文档链（retire target baseline 已落盘）
- `AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 的 family-specific future trigger 决策

`SSSE3` 当前已经明确为 adapter-only / `no dedicated raw leaf target`，不再作为待补 raw leaf 项处理。
`Wave 2 / seam hardening` 也已完成，不再列入未完成 closeout 项。

这些是后面波次的收尾问题，不影响你从当前计划正常开工。
