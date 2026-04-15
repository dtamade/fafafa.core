# L0 Mainline Replay Execution Plan

> 已归档到 `docs/legacy/l0/`。当前 strict non-SIMD L0 的 today contract 与 current-entry 请改看 `docs/fafafa.core.l0.foundation.md`、`docs/fafafa.core.l0.roadmap.md` 和 `docs/audits/2026-04-11-l0-current-state-audit.md`。
> 历史执行计划：这份计划已经完成，对应结果已通过 PR `#9` 合并到 `main@f6585dd9`。
> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在唯一的 L0 worktree 中，把 strict non-SIMD L0 的最新 closeout 状态安全地重建到最新 `origin/main` 之上，并产出与实际分支状态一致的 current-entry 文档。

**Architecture:** 当前 L0 分支历史里包含一条比 `origin/main` 更细粒度的 Windows control-plane 演进线，但 `origin/main` 已通过 `0684af55` 吸收其中一部分内容。执行时先冻结当前 closeout tip，再基于最新 `origin/main` 建新的 integration 分支，最后按最终树差异整合未进主线的 strict L0 变化，避免机械重放重复提交。

**Tech Stack:** Git worktree, Git merge/squash integration, bash test runners, GitHub Actions evidence artifacts, Markdown control-plane docs.

---

### Task 1: 固化执行面与控制面基线

**Files:**

- Create: `task_plan.md`
- Create: `findings.md`
- Create: `progress.md`
- Create: `docs/plans/2026-04-11-l0-mainline-replay-execution-plan.md`（当前归档路径：`docs/legacy/l0/2026-04-11-l0-mainline-replay-execution-plan.md`）

**Step 1: 记录当前分支状态**

Run:

```bash
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
```

Expected: 当前 worktree 干净，`HEAD` 为 `bebd668d`，`origin/main` 为 `0684af55`。

**Step 2: 记录 replay 风险**

写入计划文件时明确指出：

- `origin/main` 已吸收 `70f12256` 代表的 Windows control-plane bundle
- 因此不能再机械整段 cherry-pick 45 个提交

**Step 3: 保存计划文件**

Expected: `task_plan.md`、`findings.md`、`progress.md` 与本计划文件都已存在。

### Task 2: 冻结 closeout tip 并重建 integration 分支

**Files:**

- Modify: `progress.md`

**Step 1: 冻结当前 closeout tip**

Run:

```bash
git branch -f l0-mainline-closeout-20260411 bebd668d
```

Expected: `l0-mainline-closeout-20260411` 指向当前 strict L0 closeout tip。

**Step 2: 基于最新主线重建 integration 分支**

Run:

```bash
git switch -C l0-mainline-integration-20260411 origin/main
```

Expected: 当前分支切到最新 `origin/main` 派生出的新 integration 分支。

**Step 3: 记录分支切换**

在 `progress.md` 中写明新旧分支与冻结点。

### Task 3: 整合 strict L0 的最终树差异

**Files:**

- Modify: strict L0 涉及的源码、测试、示例与文档文件（按实际 merge 结果）
- Modify: `progress.md`

**Step 1: 以最终树差异整合 closeout 分支**

Run:

```bash
git merge --squash l0-mainline-closeout-20260411
```

Expected: 只把 `origin/main` 尚未拥有的 strict L0 最终状态带入当前 integration 分支；若出现冲突，说明存在真实差异需要人工裁决。

**Step 2: 解决冲突并检查 staged 结果**

Run:

```bash
git status --short
git diff --cached --stat
```

Expected: 所有冲突已解决，staged 内容只包含 strict L0 需要保留的最终差异。

**Step 3: 提交 integration 结果**

Run:

```bash
git commit -m "merge(l0): replay strict l0 closeout onto latest mainline"
```

Expected: 当前 integration 分支有一个新的 replay 提交。

### Task 4: 运行最小验证闭环

**Files:**

- Modify: `progress.md`

**Step 1: 运行 Linux gate**

Run:

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
```

Expected: strict L0 聚合 gate 通过。

**Step 2: 运行 hygiene 和 Windows control-plane 复核**

Run:

```bash
git diff --check
bash tests/test_windows_strict_l0_batch_runtime_matrix.sh
bash tests/test_windows_strict_l0_native_closeout_stack.sh
```

Expected: `diff --check` 通过，本地 runtime/control-plane 复核通过。

**Step 3: 仅在触及 strict L0 代码或测试时追加 fresh GH evidence**

Run:

```bash
L0_NATIVE_EVIDENCE_POLL_MAX_TRIES=180 bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-20260411-native-gha
```

Expected: 只有当 replay 触及 strict L0 代码或测试且现有 Windows 证据不再足够时才运行。

### Task 5: 产出新的 current-entry 文档

**Files:**

- Create: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Create: `docs/plans/2026-04-11-l0-mainline-merge-checklist.md`（当前归档路径：`docs/legacy/l0/2026-04-11-l0-mainline-merge-checklist.md`）
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/fafafa.core.l0.foundation.md`
- Modify: `docs/fafafa.core.l0.roadmap.md`
- Modify: `workers/worker1.md`
- Modify: `progress.md`

**Step 1: 写新的 current audit**

包含：

- 新 integration branch
- replay 结果
- fresh verification snapshot
- Windows evidence 口径

**Step 2: 写新的 current merge checklist**

包含：

- 当前 `HEAD`
- 当前 `origin/main`
- 当前 merge readiness
- 若后续继续并回主线时应遵守的 gate

**Step 3: 更新 current-entry 指针**

将 `README`、`INDEX`、`foundation`、`roadmap`、`worker1` 指向最新 `2026-04-11` 审计与清单。
