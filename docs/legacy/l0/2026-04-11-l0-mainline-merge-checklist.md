# 2026-04-11 L0 Mainline Merge Checklist

> 已归档到 `docs/legacy/l0/`。当前 strict non-SIMD L0 的 today contract 与 current-entry 请改看 `docs/fafafa.core.l0.foundation.md`、`docs/fafafa.core.l0.roadmap.md` 和 `docs/audits/2026-04-11-l0-current-state-audit.md`。
> 历史 closeout 文档：本清单对应 strict non-SIMD L0 在 PR `#9` 合并前的最后一轮 merge-prep。
> 它已经完成，不再是 current-entry；当前状态请改看 `docs/audits/2026-04-11-l0-current-state-audit.md`。

## Status

- 状态：`completed`
- 对应 PR：`#9`
- merged at：`2026-04-11T08:51:07Z`
- merge commit：`f6585dd9`
- 原 integration branch：`l0-mainline-integration-20260411`
- 当前维护 branch：`l0-mainline`

## 先看结论

`2026-04-10` 时还未完成的 replay 和 merge hygiene，今天已经全部收口。

这份文件现在只保留“当时如何判断 merge readiness”的 closeout 语境。

- 当前 strict L0 的 current state 不应再从这份 checklist 倒推
- 当前 merge-prep 分支已经退出历史舞台
- 当前应改看 merged-main 上的 post-merge 审计与稳定化计划

## What Is Already Closed

下面这些已经从“blocker”变成“历史 closeout 事实”：

- latest-mainline replay 本身
- PR `#9` 合并动作本身
- strict L0 的 Linux/macOS 聚合 gate
- strict L0 的 `.bat` runtime-only parity matrix
- strict L0 的 native closeout stack
- strict L0 的 commit-exact Windows native evidence

当前 Windows 真实证据锚点：

- 历史 baseline run：`24224880061`（代码修复锚点 `b8adade0`）
- 当前 commit-exact run：`24278413198`
- 对应 branch：`l0-mainline-integration-20260411`
- 对应 commit：`3ed047847b0bf871b265ded8e4a14c517b84b414`
- local snapshot：`tests/_windows_l0_native_evidence_gh/L0-20260411-native-gha-r10/`
- artifact batch：`L0-GHA-24278413198-1`
- artifact 结论：`12/12 PASS`

## Current Merge Candidate Shape

当前更合理的理解方式不是“继续准备 merge candidate”，而是：

1. 把这份 checklist 当作历史 closeout 记录
2. 把 `docs/audits/2026-04-11-l0-current-state-audit.md` 当作当前状态入口
3. 把 `docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md` 当作当前执行计划
4. 只在 strict L0 再次发生非文档变化时，重新触发 GH native evidence

这条路线满足：

- 不把 merge-prep 与 merged-main 语境混在一起
- 不继续把 dated checklist 当 current-entry
- 不模糊 Windows exact-evidence 的代码锚点

## Recommended Steps

当前如果要继续沿 strict L0 维护，按下面顺序看：

### 1. 先确认当前 branch 仍然跟随 `main`

Run:

```bash
cd /home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407
git status --short --branch
```

Expected:

- 当前分支是 `l0-mainline`
- tracked 工作树干净
- `HEAD` 与 `origin/main` 一致，或至少只包含当前明确要做的 strict L0 变更

### 2. 使用当前 commit-exact Windows evidence 作为 today 代码锚点

当前已经有：

```text
run_id=24278413198
head_branch=l0-mainline-integration-20260411
head_sha=3ed047847b0bf871b265ded8e4a14c517b84b414
snapshot=tests/_windows_l0_native_evidence_gh/L0-20260411-native-gha-r10/
result=12/12 PASS
```

只有当 strict L0 继续新增非文档提交，或者有人明确要求 exact `HEAD` / merge commit 证据时，才需要重新触发 GH native evidence。

### 3. 用 post-merge 维护回路替代旧 merge checklist

要求：

- 使用 `strict L0 gate + diff check + runtime matrix + native closeout stack` 作为日常维护闭环
- 不要为了 docs-only 变化重跑 exact Windows native evidence
- 所有 exact Windows native evidence 仍只通过 GitHub Actions 获取

## Merge Readiness Gates

下面这些条件已经在 closeout 时满足：

- PR `#9` 已 merge 到 `main`
- merge commit 为 `f6585dd9`
- replay commit `78069dfc` 与 exact-evidence commit `3ed04784` 都已进入历史收口链
- strict L0 聚合 gate 通过
- `git diff --check` 通过
- `.bat` runtime-only parity matrix 通过
- `native_closeout_stack` 通过
- 没有把 SIMD owner 的工作或 root `main` 的脏改动混进严格 L0 收口链
- commit-exact Windows native evidence 已通过（run `24278413198`，commit `3ed04784`）

## Current Blockers

这份 checklist 自身已经没有 blocker。当前剩余的是 post-merge 维护纪律：

- 根 `main` 工作树仍然是用户脏状态
- 当前 exact-evidence 绑定的是 `3ed04784`；如果后续 strict L0 再新增非文档提交，需要重新触发 GH native evidence

## What Not To Do

- 不要继续把 `docs/plans/2026-04-10-l0-mainline-merge-checklist.md` 当 current-entry
- 不要把旧的 45 提交 replay 方案再执行一遍
- 不要再把这份 checklist 当 current-state 文档
- 不要把 SIMD owner 的工作、sidecar 污染或其他 unrelated 变更带进 strict L0 维护线

## Related Docs

- `docs/fafafa.core.l0.foundation.md`
- `docs/fafafa.core.l0.roadmap.md`
- `docs/audits/2026-04-11-l0-current-state-audit.md`
- `docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md`
- `docs/legacy/l0/2026-04-11-l0-mainline-replay-execution-plan.md`
- `docs/plans/2026-04-10-l0-windows-ci-enablement.md`
- `docs/plans/2026-04-09-l0-native-windows-matrix-runbook.md`
- `workers/worker1.md`
