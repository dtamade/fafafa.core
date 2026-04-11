# 2026-04-11 L0 Mainline Merge Checklist

> 这是 strict non-SIMD L0 在完成 latest-mainline replay 之后的当前 dated checklist。
> 长期边界和推进顺序仍以 `docs/ARCHITECTURE_LAYERS.md`、`docs/fafafa.core.l0.foundation.md` 和 `docs/fafafa.core.l0.roadmap.md` 为准；本页只回答“按 2026-04-11 的状态，接下来进入真正主线合并窗口前还需要看什么”。

## Status

- 状态：`active`
- 当前 L0 worktree：`/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- 当前 L0 branch：`l0-mainline-integration-20260411`
- 当前 L0 `HEAD`：`78069dfc`
- 当前 `origin/main`：`0684af55`
- 当前 merge-base：`0684af55`
- 当前分支状态：`ahead 1, behind 0`

## 先看结论

`2026-04-10` 时还未完成的 replay，今天已经完成了。

当前 strict L0 的真实状态不是“还要再想一遍怎么把旧分支重放到主线”，而是：

- 当前分支已经是最新 `origin/main` 之上的 L0 integration branch
- replay 后的 Linux gate 和 Windows control-plane 复核都已经 fresh 通过
- 当前剩余问题主要是“最后在哪个干净执行面完成真正合并”，而不是“L0 代码还没整理到最新主线”

## What Is Already Closed

下面这些今天已经不是 blocker：

- latest-mainline replay 本身
- strict L0 的 Linux/macOS 聚合 gate
- strict L0 的 `.bat` runtime-only parity matrix
- strict L0 的 native closeout stack
- strict L0 的真实 Windows native evidence baseline

当前 Windows 真实证据锚点：

- GitHub Actions run：`24224880061`
- 对应 strict L0 代码修复提交：`b8adade0`
- artifact 结论：`12/12 PASS`
- `2026-04-11` replay 没有再改 strict L0 的证明边界；唯一手工冲突只发生在 native evidence collector，并保留了 closeout 侧逻辑

## Current Merge Candidate Shape

当前更合理的主线准备形态是：

1. 把 `l0-mainline-integration-20260411` 作为唯一的 strict L0 review / merge-prep surface
2. 不回到旧的 `l0-mainline-integration-20260409` 或 `2026-04-10` replay 方案
3. 不在用户脏的根 `main` 工作树上直接做最终合并动作
4. 只有在需要 commit-exact Windows artifact 时，才在推送当前分支后补 fresh GH native evidence

这条路线满足：

- 不新增第三个 worktree
- 不碰用户脏的根 `main`
- 不重复 replay 已被 `origin/main` 吸收的那段 Windows control-plane 历史

## Recommended Steps

真正准备进入主线合并窗口时，按下面顺序看：

### 1. 先确认当前分支仍然是 clean integration surface

Run:

```bash
cd /home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407
git status --short --branch
```

Expected:

- 当前分支仍是 `l0-mainline-integration-20260411`
- tracked 工作树干净
- 不把本地 scratch / unrelated 变更混进去

### 2. 如果需要 commit-exact Windows native evidence，再补一轮 GH run

Run:

```bash
L0_NATIVE_EVIDENCE_POLL_MAX_TRIES=180 bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-20260411-native-gha
```

解释：

- 当前 worktree-only closeout 并不强制要求这一步
- 只有当最终主线窗口要求“artifact 必须精确绑定 `78069dfc`”时，才值得补

### 3. 最终合并时，只从干净执行面推进

要求：

- 不要在根 `main` 工作树上直接 merge 当前 L0 branch
- 可以在干净的 review / PR / temporary merge surface 上继续推进
- 如果 `origin/main` 在这之前又前进了，再做一次轻量 replay，而不是回退到旧 checklist

## Merge Readiness Gates

下面这些条件同时满足，就说明当前 strict L0 已经具备进入真正主线集成窗口的条件：

- 当前 integration branch 基于最新 `origin/main`
- 当前 `HEAD` 相对 `origin/main` 是 `ahead 1, behind 0`
- strict L0 聚合 gate 通过
- `git diff --check` 通过
- `.bat` runtime-only parity matrix 通过
- `native_closeout_stack` 通过
- 没有把 SIMD owner 的工作或 root `main` 的脏改动混进当前分支
- 如果主线窗口要求 commit-exact Windows artifact，则 fresh GH native evidence 也通过

## Current Blockers

今天的 blocker 只剩执行面选择和最终窗口纪律：

- 根 `main` 工作树是用户脏状态
- 当前分支尚未因为“commit-exact Windows artifact”而重跑 GH native evidence；这不是今天的 blocker，只是可选 final hardening

## What Not To Do

- 不要继续把 `docs/plans/2026-04-10-l0-mainline-merge-checklist.md` 当 current-entry
- 不要把旧的 45 提交 replay 方案再执行一遍
- 不要在根 `main` 工作树上直接 merge 当前 L0 branch
- 不要把 SIMD owner 的工作、sidecar 污染或其他 unrelated 变更带进 strict L0 集成线

## Related Docs

- `docs/fafafa.core.l0.foundation.md`
- `docs/fafafa.core.l0.roadmap.md`
- `docs/audits/2026-04-11-l0-current-state-audit.md`
- `docs/plans/2026-04-11-l0-mainline-replay-execution-plan.md`
- `docs/plans/2026-04-10-l0-windows-ci-enablement.md`
- `docs/plans/2026-04-09-l0-native-windows-matrix-runbook.md`
- `workers/worker1.md`
