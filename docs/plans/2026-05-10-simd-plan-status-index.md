# SIMD Plan Status Index

这页只回答一件事：

> 当前 `docs/plans/*simd*` 里，哪些文档还能作为 active 执行入口，哪些只能当历史背景。

如果你是从搜索结果、目录列表，或者旧聊天记录里直接点开某份 `simd` plan，先看这页。

## 一句话结论

当前真正 active 的 SIMD 计划链，只有 `2026-05-09/10` 这一组 whole-module 文档。

更早的 `2026-02` 到 `2026-04` 计划，不管名字里写的是 `final`、`closeout`、`roadmap`、`phase2` 还是 `frontier`，都不再是当前默认执行队列。

它们可以保留，但只能作为：

- 历史证据
- drift 对照基线
- 已实现设计的背景说明
- 外部证据/模板/patch provenance

不能再作为“今天从哪一页开工”的起点。

## Active 执行链

如果今天要继续 whole-module SIMD 重构，只从下面这些文档起手：

- `docs/plans/2026-05-10-simd-execution-index.md`
- `docs/plans/2026-05-10-simd-wave2-seam-hardening-plan.md`
- `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md`
- `docs/plans/2026-05-09-simd-family-matrix.md`
- `docs/plans/2026-05-09-simd-avx2-active-leaf-sample.md`
- `docs/plans/2026-05-09-simd-x86-incremental-qualification-plan.md`
- `docs/plans/2026-05-09-simd-neon-qualification-plan.md`
- `docs/plans/2026-05-09-simd-riscvv-qualification-plan.md`
- `docs/plans/2026-05-09-simd-sse2-retire-target-plan.md`

配套真相源与基线文档继续是：

- `docs/SIMD_LAYERING_IMPLEMENTATION.md`
- `docs/SIMD_BACKEND_TRUTH.md`
- `docs/SIMD_INTRINSICS_DISPOSITION.md`
- `docs/SIMD_SSE2_MIGRATION_MAP.md`
- `docs/fafafa.core.simd.implementation-matrix.md`
- `docs/fafafa.core.simd.map.md`

## Historical Baseline

下面这些文档可以保留，但它们不是当前 active queue。

### 清单、模板与历史快照

- `docs/plans/2026-02-09-simd-interface-target-checklist.md`
- `docs/plans/2026-02-17-simd-interface-target-checklist-v2.md`
- `docs/plans/2026-02-09-simd-nonx86-interface-target-checklist.md`
- `docs/plans/2026-02-09-simd-windows-closeout-checklist.md`
- `docs/plans/2026-02-09-simd-windows-postrun-fill-template.md`
- `docs/plans/2026-02-17-simd-intrinsics-disposition.md`

### 已实现设计或局部专题背景

- `docs/plans/2026-03-11-simd-public-abi-wrapper-signature-design.md`
- `docs/plans/2026-03-11-simd-public-abi-wrapper-implementation-plan.md`
- `docs/plans/2026-03-13-simd-intrinsics-byte-shifts.md`
- `docs/plans/2026-04-14-simd-only-patch-bundle.md`

这些文档仍然有价值，但用途已经从“当前实施入口”变成“历史说明或对照材料”。

## Superseded Historical Plans

下面这些是旧执行波次、旧 closeout 队列或旧 bounded frontier 方案。

它们记录过当时真实有效的局部目标，但现在已经被 whole-module 执行链覆盖，不再作为当前默认实施顺序。

### 2026-02 阶段

- `docs/plans/2026-02-06-zero-warnings-hints-fs-simd-design.md`
- `docs/plans/2026-02-06-zero-warnings-hints-fs-simd.md`
- `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
- `docs/plans/2026-02-12-simd-complete-landing.md`
- `docs/plans/2026-02-13-simd-linux-finalization.md`
- `docs/plans/2026-02-13-simd-linux-e2e-reverify.md`
- `docs/plans/2026-02-17-simd-remediation-plan.md`
- `docs/plans/2026-02-18-simd-completeness-closeout-plan.md`
- `docs/plans/2026-02-19-simd-full-closure-wave.md`
- `docs/plans/2026-02-24-simd-development-roadmap.md`

### 2026-03 阶段

- `docs/plans/2026-03-07-simd-dispatch-adapter-single-source.md`
- `docs/plans/2026-03-07-simd-parallel-closeout.md`
- `docs/plans/2026-03-07-simd-stable-experimental-boundary.md`
- `docs/plans/2026-03-09-simd-full-platform-completeness.md`
- `docs/plans/2026-03-24-simd-audit-closeout-roadmap.md`

### 2026-04 阶段

- `docs/plans/2026-04-08-simd-maturity-closeout-plan.md`
- `docs/plans/2026-04-10-simd-implementation-closeout-plan.md`
- `docs/plans/2026-04-11-simd-implementation-efficiency-closeout-plan.md`
- `docs/plans/2026-04-11-simd-implementation-phase2-plan.md`
- `docs/plans/2026-04-11-simd-native-evidence-riscvv-hardening-plan.md`
- `docs/plans/2026-04-14-simd-implementation-closeout-wave.md`
- `docs/plans/2026-04-14-simd-x86-bounded-frontier-plan.md`
- `docs/plans/2026-04-14-simd-x86-implementation-frontier.md`
- `docs/plans/2026-04-14-simd-x86-smoke-closeout-plan.md`
- `docs/plans/2026-04-15-simd-runtime-cpuinfo-closeout-plan.md`
- `docs/plans/2026-04-26-simd-final-closeout-plan.md`

## 当前清理规则

如果某份 SIMD plan 已经做完，或者已经被新主链覆盖，默认按下面的顺序处理：

1. 给旧文档加 `Status` 头，明确它不再是 active queue。
2. 从 `map`、`execution index`、`global plan` 这种主动入口里移除它。
3. 如果它仍承载证据、模板、对照基线或 patch provenance，就保留。
4. 只有在内容已经被完整吸收、且没有脚本/文档再引用时，才考虑进一步归档或删除。

## Delete 还是 Keep

默认先 `demote visibility`，不是先删文件。

原因很简单：

- 很多旧 plan 仍承载当时的验证背景
- 部分旧 plan 仍是 drift comparison baseline
- 有些文件虽然不再 active，但仍对 future trigger、patch provenance、Windows 回填流程有参考价值

所以当前更正确的动作是：

- 让 active chain 单一
- 让历史计划显式退役
- 再按重复度决定后续是否进一步归档

## 下次维护时怎么做

以后如果 SIMD 计划继续扩张，先问这两个问题：

1. 这份新文档会不会进入 active 执行链？
2. 它是否让某一份旧文档失去 active 资格？

如果答案是会，就同步做两件事：

- 更新这页
- 给旧文档补 `Status: historical` 或 `Status: superseded`
