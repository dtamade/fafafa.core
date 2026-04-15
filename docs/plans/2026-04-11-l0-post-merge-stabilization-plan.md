# L0 Post-Merge Stabilization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在唯一的 L0 worktree 上，把 strict non-SIMD L0 从“刚完成主线合并”切换到“mainline 稳定维护态”，同步 current-entry 文档、验证口径和本地历史 refs。

**Architecture:** 先把 current-entry 文档修正到 `main@f6585dd9` 和 `l0-mainline` 的真实状态，避免继续从 merge-prep 语境倒推当前事实。然后把 Windows exact-evidence 与 Phase 3 verification loop 固化进稳定文档，最后只删除已经被 `origin/main` 吸收或完全重复的本地 L0 refs，保留仍然承载独立历史的锚点。

**Tech Stack:** Git refs/worktrees, Markdown docs, bash test runners, GitHub Actions evidence helpers.

---

### Task 1: 修正 post-merge 的 current-entry 真相

**Files:**

- Create: `docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `workers/worker1.md`
- Modify: `docs/fafafa.core.l0.foundation.md`
- Modify: `docs/legacy/l0/2026-04-11-l0-mainline-merge-checklist.md`
- Modify: `docs/legacy/l0/2026-04-11-l0-mainline-replay-execution-plan.md`

**Step 1: 把 current audit 改成 merged-main 事实**

写明：

- PR `#9` 已合并到 `main`
- 当前 merge commit 为 `f6585dd9`
- 当前唯一 L0 branch 为 `l0-mainline`
- 当前 Windows exact evidence 仍锚定 `3ed04784`，但后续 docs-only merge 不改变 strict L0 代码结论

**Step 2: 把 worker 与 foundation 指针改到 post-merge 维护态**

写明：

- `worker1` 当前职责已经从 merge-prep 转成 post-merge stabilization
- `foundation` 的 dated 计划入口改指向新的 post-merge stabilization plan

**Step 3: 把 merge checklist / replay plan 降级成历史 closeout**

写明：

- merge checklist 已完成，不再是 current-entry
- replay execution plan 已执行完成，只保留历史执行语境

### Task 2: 修正顶层导航，避免继续把 merge 文档当 current-entry

**Files:**

- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/fafafa.core.l0.roadmap.md`

**Step 1: 调整 README 的快速入口**

保留：

- `roadmap`
- `foundation`
- 最新 `audit`
- 新的 post-merge stabilization plan

降级：

- `merge checklist`
- `replay execution plan`

**Step 2: 调整 INDEX 的当前特别说明**

明确：

- strict L0 已经合并到 `main`
- merge checklist / replay plan 现在是历史 closeout 文档
- 当前状态优先看 `audit` + `roadmap` + `foundation`

**Step 3: 在 roadmap 写明 post-merge 姿态**

增加：

- 当前 `l0-mainline -> origin/main`
- 当前 focus 是 source-of-truth 与 verification hardening
- 当前没有新的 L0 admission 候选

### Task 3: 固化 verification / Windows evidence 规则

**Files:**

- Modify: `docs/fafafa.core.l0.roadmap.md`
- Modify: `docs/CI.md`

**Step 1: 在 roadmap 的 Phase 3 里补硬规则**

明确：

- `git diff --check`
- strict L0 聚合 gate
- `.bat` runtime matrix
- `native_closeout_stack`
- Windows exact evidence 只能来自 GitHub Actions

**Step 2: 在 CI 文档里增加 post-merge 维护回路**

写明：

- Linux x64 常规 4 步验证闭环
- 何时需要 rerun GH native evidence
- 何时不需要为了 docs-only 变化重跑 exact evidence

### Task 4: 清理安全可删的本地 L0 refs

**Files:**

- Modify: local git refs only

**Step 1: 识别已经被 `origin/main` 吸收的 stale refs**

Run:

```bash
for b in l0-main-followup-20260407 l0-main-promotion-20260407 l0-main-rescue l0-main-tail-cleanup-20260408 l0-main-tail-cleanup-20260408-final l0-mainline-closeout-20260411 l0-sidecar-handoff-20260409 l0-windows-ci-enablement; do
  if git merge-base --is-ancestor "$b" origin/main; then
    echo "$b merged"
  else
    echo "$b NOT_MERGED"
  fi
done
```

Expected:

- 只删除已经 merged 的 refs
- 若两个分支指向同一 SHA，只保留更明确的命名

**Step 2: 删除 merged 或重复分支**

Run:

```bash
git branch -d l0-main-followup-20260407
git branch -d l0-main-promotion-20260407
git branch -d l0-windows-ci-enablement
git branch -d l0-main-tail-cleanup-20260408
```

Expected:

- `l0-mainline` 保留
- `l0-mainline-closeout-20260411`、`l0-sidecar-handoff-20260409` 保留
- `l0-main-rescue`、`l0-main-tail-cleanup-20260408-final` 若仍承载独立历史则保留

### Task 5: 跑 fresh 验证闭环

**Files:**

- Modify: none

**Step 1: 跑 strict L0 聚合 gate**

Run:

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
```

Expected: `11/11 PASS`

**Step 2: 跑 hygiene 与 Windows control-plane contract**

Run:

```bash
git diff --check
bash tests/test_windows_strict_l0_batch_runtime_matrix.sh
bash tests/test_windows_strict_l0_native_closeout_stack.sh
```

Expected:

- `git diff --check` 通过
- runtime matrix 通过
- native closeout stack 通过

**Step 3: 记录结果**

写明：

- 当前 `HEAD`
- 当前 `origin/main`
- 当前保留的本地 L0 refs
- 当前 exact Windows evidence 口径
