# 2026-04-10 L0 Mainline Merge Checklist

> 这是 strict non-SIMD L0 并回主线前的当前 dated checklist。
> 长期边界和推进顺序仍以 `docs/ARCHITECTURE_LAYERS.md`、`docs/fafafa.core.l0.foundation.md` 和 `docs/fafafa.core.l0.roadmap.md` 为准；本页只回答“按今天的状态，真正合并到主线前还需要做什么”。

## Status

- 状态：`active`
- 当前 L0 worktree：`/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- 当前 L0 branch：`l0-mainline-integration-20260409`
- 当前 L0 `HEAD`：`d1574512`
- 当前 `origin/main`：`0684af55`
- 当前 merge-base：`d5187ea4`

## 先看结论

当前 strict L0 已经不是“还差 Windows 证据才能讨论并回主线”的状态。

今天真正还没收口的是 merge hygiene：

- 根 `main` 工作树仍然是用户脏状态，不适合作为最终合并执行面
- 根 `main` 当前相对 `origin/main` 仍有明显分叉和本地未整理改动
- 当前 L0 分支已经吸收了 Windows native evidence closeout、compat wording 和 current-entry 同步这几轮提交；如果要并回主线，更合理的做法是保住当前 tip，再在同一个 L0 worktree 里对最新 `origin/main` 重放

## What Is Already Closed

下面这些今天已经不是 blocker：

- strict L0 的 Linux/macOS 聚合 gate
- strict L0 的 Windows `wine` smoke
- strict L0 的 `.bat` runtime-only parity matrix
- strict L0 的 native lane script wiring / collector / verifier / GH helper / shell verifier contract
- strict L0 的真实 Windows native evidence

当前 Windows 真实证据锚点：

- GitHub Actions run：`24224880061`
- 对应代码提交：`b8adade0`
- artifact 结论：`12/12 PASS`
- 后续 `a436ce98`、`9378d374`、`d1574512` 都是 docs/control-plane 提交，不改变 strict L0 代码验证面

## Current Merge Candidate Shape

当前更合理的合并形态不是“直接 merge 当前 branch 到根 `main`”，而是：

1. 在当前唯一的 L0 worktree 里保住今天的 closeout tip
2. 基于最新 `origin/main` 在同一个 L0 worktree 里重建 integration branch
3. 重放完整 strict L0 closeout 线
4. 在 replay 后重新跑 Linux gate 和最小 Windows control-plane 复核
5. 再决定是否进入主线集成窗口

这条路线满足：

- 不新增第三个 worktree
- 不碰用户脏的根 `main`
- 不把旧 dated checklist 和今天的 current state 混在一起

## Current Replay Slice

当前建议保留的 closeout tip：

- `l0-mainline-closeout-20260410`

当前建议的 replay 范围：

- 起点：`b4a33c46`
- 终点：`d1574512`

为什么默认保留整段：

- `b8adade0` 已经收掉 allocator 相关的最后一个 Windows FPC blocker
- `a436ce98` 把 Windows native evidence closeout 写回 current audit / worker / merge navigation
- `9378d374` 把 `atomic.compat`、`AndResult` / `OrResult`、`mem.allocator.foundation` 的 compat/facade 边界写硬
- `d1574512` 把 `CI` / `TESTING` / native runbook 的 today guidance 同步到真实 GH 证据状态

如果把后面三条 docs/control-plane 提交漏掉，主线会重新退回过时 guidance。

## Recommended Steps

真正准备往主线推进时，按下面顺序做：

### 1. 保住当前 closeout tip

Run:

```bash
git -C .claude/worktrees/l0-main-promotion-20260407 branch -f l0-mainline-closeout-20260410 d1574512
```

### 2. 在同一个 L0 worktree 上重建 integration branch

Run:

```bash
git fetch origin
git -C .claude/worktrees/l0-main-promotion-20260407 switch -C l0-mainline-integration-20260410 origin/main
git -C .claude/worktrees/l0-main-promotion-20260407 cherry-pick b4a33c46^..l0-mainline-closeout-20260410
```

### 3. replay 后先做 Linux gate 和 hygiene

Run:

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
git diff --check
```

### 4. 再做 Windows control-plane 复核

Run:

```bash
bash tests/test_windows_strict_l0_batch_runtime_matrix.sh
bash tests/test_windows_strict_l0_native_closeout_stack.sh
```

### 5. 如果 replay 过程中碰到了 strict L0 代码或测试冲突，再补 fresh GH evidence

Run:

```bash
L0_NATIVE_EVIDENCE_POLL_MAX_TRIES=180 bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-YYYYMMDD-native-gha
```

解释：

- 如果 replay 只吸收了 docs/control-plane 变化，现有 run `24224880061` 仍然是有效代码锚点
- 如果 replay 冲突实际改到了 strict L0 的代码或测试，就不要复用旧 Windows 证据，直接重新收 fresh artifact

## Merge Readiness Gates

下面这些条件同时满足，才适合进入真正的主线集成窗口：

- replay 后的 integration branch 基于最新 `origin/main`
- strict L0 聚合 gate 通过
- `git diff --check` 通过
- `.bat` runtime-only parity matrix 通过
- `native_closeout_stack` 通过
- 若 replay 冲突触到了 strict L0 代码/测试，fresh GH native evidence 也通过
- 没有把 SIMD owner 的工作或 root `main` 的脏改动混进来

## Current Blockers

今天的 blocker 只有 merge hygiene / integration window 这类流程问题：

- 根 `main` 工作树是用户脏状态
- 根 `main` 相对 `origin/main` 仍有本地 ahead/behind 分叉
- 当前 L0 branch 与 `origin/main` 已有额外差距，正式并回前需要在最新 `origin/main` 上 replay 一次

Windows 证据已经不在这组 blocker 里。

## What Not To Do

- 不要直接在根 `main` 工作树上 merge 当前 L0 branch
- 不要因为“Windows 已经绿了”就跳过 replay 后的 Linux gate
- 不要把 dated `2026-04-09` checklist 当成今天的 current-entry
- 不要把 SIMD owner 的工作、sidecar 污染或 root `main` 的脏改动带进 strict L0 集成线

## Related Docs

- `docs/fafafa.core.l0.foundation.md`
- `docs/fafafa.core.l0.roadmap.md`
- `docs/audits/2026-04-10-l0-current-state-audit.md`
- `docs/plans/2026-04-10-l0-windows-ci-enablement.md`
- `docs/plans/2026-04-09-l0-native-windows-matrix-runbook.md`
- `workers/worker1.md`
