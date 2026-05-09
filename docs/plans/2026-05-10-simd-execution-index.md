# SIMD Execution Index

这页不是讲架构原理，也不是讲某个 family 的细节。

它只回答一件事：

> 如果下一次新开会话，要把 whole-module SIMD 计划正常实施，第一步该做什么，第二步该做什么。

如果你只想快速开始，不要先自己在总纲、matrix、family plan 之间来回跳，先看这页。

## 一句话结论

当前 `simd` 的文档体系已经够开工。

正确起手顺序不是“先随便读一个熟悉的文件”，而是：

1. 先用这页确认当前波次和执行顺序
2. 再去 `family matrix` 找当前 family
3. 再去对应 family plan
4. 再跑这条 family 的 baseline 命令
5. 改完以后只更新 3 处：family plan / family matrix / scratch

## 当前总计划状态

### 已经完成的阶段

- `Wave 1 / planning`：已完成
  - total plan 已落盘
  - family matrix 已落盘
  - `AVX2 / x86 incremental / NEON / RISCVV` family-level 文档已落盘

### 还没完成的阶段

- `Wave 2 / seam hardening`：待进入代码实施
- `Wave 3 / x86 families execution`：待进入代码实施
- `Wave 4 / non-x86 families execution`：待进入代码实施
- `Wave 5 / retire + redundancy cleanup`：待进入代码实施

## 下次开会话的固定步骤

## Step 0：先确认今天是不是要做“文档”还是“代码”

如果你今天的目标是：

- 调整总架构
- 判断某个 family 当前该不该 promote
- 改 wave 顺序

先看：

- `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md`
- `docs/plans/2026-05-09-simd-family-matrix.md`

如果你今天的目标是：

- 落一个具体 family 的实现
- 修一个 bounded frontier / wiring / parity / ownership 问题
- 推进某个 wave

先看：

- 这页
- 对应 family plan

## Step 1：先看当前执行队列，不要自己重新排优先级

当前默认执行队列是：

1. `Wave 2`：收紧 `dispatch / dataplane / public ABI / direct` 的边界
2. `Wave 3A`：守住 `AVX2` 正样板，不做大拆
3. `Wave 3B`：补 `SSSE3` raw-leaf target 真相
4. `Wave 3C`：按 shared x86 incremental plan 收 `SSE3 / SSSE3 / SSE4.1 / SSE4.2 / AVX-512`
5. `Wave 3D`：推进 `SSE2` 高债务试点
6. `Wave 4A`：按 `NEON` qualification plan 推进
7. `Wave 4B`：按 `RISCVV` qualification plan 推进
8. `Wave 5`：清理 retire target / duplicated helper / future trigger

规则：

- 不要跳过前面的波次，直接去做后面更“有趣”的重构
- 只有当某条波次出现 fresh red 或用户明确指定，才允许跳队

## Step 2：按目标选入口文档

### 如果你今天要做 `AVX2`

看：

- `docs/plans/2026-05-09-simd-avx2-active-leaf-sample.md`

目标：

- 守住样板
- 不把 adapter / active leaf 边界写坏

### 如果你今天要做 `SSE3 / SSSE3 / SSE4.1 / SSE4.2 / AVX-512`

看：

- `docs/plans/2026-05-09-simd-x86-incremental-qualification-plan.md`

目标：

- 先 qualification
- 不先做大迁移

### 如果你今天要做 `SSE2`

看：

- `docs/SIMD_SSE2_MIGRATION_MAP.md`
- `docs/plans/2026-05-09-simd-x86-incremental-qualification-plan.md`
- `docs/plans/2026-05-09-simd-family-matrix.md` 里的 `SSE2` 行

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
- 不把 `SSE2` 的局部策略写成全仓库通用规则

### 默认允许做的事

- 补 qualification
- 补 representative parity
- 补 source truth / runtime evidence
- 收紧 adapter / leaf 边界
- 修 bounded frontier 实现缺口

## Step 5：改完后只更新这 3 处

每一波改完，默认只更新：

1. 对应 family plan
2. `docs/plans/2026-05-09-simd-family-matrix.md`
3. `plans/scratch/2026-04-08-simd-review/` 下的 `task_plan.md / progress.md / findings.md`

不要每次波动都去改整个总纲。

总纲只在下面两种情况更新：

- 波次顺序变化
- 全局规则变化

## Step 6：收口时怎么判断“这一波完成了”

一波完成，不看“感觉差不多”，只看这 4 条：

1. family plan 里的当前目标已经落地
2. 对应 verification lane fresh 通过
3. family matrix 的 `Next action` 已更新
4. scratch 里写清楚了这轮做了什么、下一轮接着做什么

## 今天如果只想 5 分钟内开始

直接按这个最短流程：

1. 读这页
2. 打开 `docs/plans/2026-05-09-simd-family-matrix.md`
3. 选今天要推进的 family
4. 打开对应 family plan
5. 跑它的 baseline
6. 开工

## 当前还没做完的 closeout 级文档

这页只负责“怎么开始”，不负责把所有 closeout 问题都解决。

当前还明确未完成的是：

- `SSE2` promote / split / retire 决策文档
- `SSSE3` raw-leaf target 明确化
- `AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 的 future trigger 文档

这些是后面波次的收尾问题，不影响你从当前计划正常开工。
