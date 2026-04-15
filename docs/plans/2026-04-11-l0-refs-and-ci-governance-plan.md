# L0 Refs And CI Governance Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在唯一的 L0 worktree 上，补齐 strict non-SIMD L0 的 Linux CI 运行证据，审计残留 L0 refs，并把“哪些 refs 保留、哪些 refs 可以清理、为什么”固化成可追踪的 closeout 记录。

**Architecture:** 先把当前 `l0-mainline` 推到远端，确保 `.github/workflows/l0-linux-maintenance.yml` 对 GitHub Actions 可见，然后触发并等待这条 Linux maintenance lane。等待期间并行完成残留 L0 refs 的 patch-equivalence 审计，只删除已经证明冗余的 refs；若 refs 仍承载独立历史，则明确记录为保留。最后更新 audit / worker / legacy closeout 文档，并用 fresh verification 固化当前控制面。

**Tech Stack:** Git refs, GitHub CLI (`gh`), GitHub Actions, Bash verification scripts, Markdown docs.

---

### Task 1: 把本轮执行边界和 closeout 目标落盘

**Files:**
- Create: `docs/plans/2026-04-11-l0-refs-and-ci-governance-plan.md`

**Step 1: 写 dated plan**

要求：

- 说明这轮只处理 strict non-SIMD L0 的 refs / CI / closeout，不扩张模块边界
- 明确 GitHub Actions Linux maintenance workflow 是目标证据入口
- 明确 refs 清理采用“只删已证明冗余”的策略

### Task 2: 让 L0 Linux maintenance workflow 在 GitHub 上可运行

**Files:**
- Modify: remote ref `origin/l0-mainline`

**Step 1: 推送当前 `l0-mainline` 到远端**

Run:

```bash
git push origin HEAD:refs/heads/l0-mainline
```

Expected:

- 远端出现 `origin/l0-mainline`
- `.github/workflows/l0-linux-maintenance.yml` 对 GitHub 可见

**Step 2: 触发 workflow**

Run:

```bash
gh workflow run l0-linux-maintenance.yml --ref l0-mainline
```

Expected:

- GitHub 接受 dispatch，返回成功

**Step 3: 记录 run id 并等待结果**

Run:

```bash
gh run list --workflow l0-linux-maintenance.yml --branch l0-mainline --limit 1
gh run watch <run-id> --exit-status
```

Expected:

- 该 run 最终为 `completed/success`

### Task 3: 审计残留 L0 refs，只保留仍承载独立历史的锚点

**Files:**
- Modify: none

**Step 1: 列出残留 refs**

Run:

```bash
git branch --list 'l0*'
```

Expected:

- 当前除了 `l0-mainline`，还存在若干历史 L0 refs

**Step 2: 对每个残留 ref 做 patch-equivalence 审计**

Run:

```bash
for b in l0-main-rescue l0-main-tail-cleanup-20260408-final l0-mainline-closeout-20260411 l0-sidecar-handoff-20260409; do
  echo "== $b =="
  git cherry -v HEAD "$b"
done
```

Expected:

- 若 `git cherry` 仍输出 `+` 提交，则说明该 ref 仍承载独立 patch history，不能盲删
- 只有 patch 已被 `HEAD` 吸收或内容完全冗余时，才进入删除候选

**Step 3: 仅删除已证明冗余的 refs**

Run:

```bash
git branch -d <safe-ref>
```

Expected:

- 只删除确证冗余的 ref
- 若没有这样的 ref，则本步显式记为 no-op

### Task 4: 把 refs / CI 现状写入 current-entry 与历史 closeout

**Files:**
- Create: `docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md`
- Modify: `docs/legacy/l0/README.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/CI.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `workers/worker1.md`

**Step 1: 写 refs / CI closeout**

要求：

- 记录当前 `HEAD`
- 记录 L0 Linux maintenance workflow 的 run id / 结果
- 记录残留 refs 的审计结论
- 明确哪些 refs 保留，为什么保留

**Step 2: 更新导航与 CI 指引**

要求：

- `README` / `INDEX` 增加这份历史 closeout 的入口
- `CI` 增加 `gh workflow run l0-linux-maintenance.yml --ref l0-mainline` 的手动触发方式
- `audit` / `worker1` 与当前 `HEAD`、当前 refs 决策和 CI 结果保持一致

### Task 5: 跑 fresh verification 并形成 checkpoint

**Files:**
- Modify: none

**Step 1: 跑 docs / contract / maintenance 验证**

Run:

```bash
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_linux_ci_workflow_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected: 全部 PASS

**Step 2: 提交 checkpoint**

Run:

```bash
git add docs/README.md docs/INDEX.md docs/CI.md docs/audits/2026-04-11-l0-current-state-audit.md docs/legacy/l0/README.md docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md docs/plans/2026-04-11-l0-refs-and-ci-governance-plan.md workers/worker1.md tests/check_strict_l0_docs_consistency.sh
git commit -m "docs(l0): close refs and ci governance loop"
```

Expected:

- 当前 L0 worktree 留下可追踪的 refs / CI closeout checkpoint
