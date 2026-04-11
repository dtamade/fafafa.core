# L0 Main Merge And GitHub Evidence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不使用根目录脏 `main` 工作树的前提下，把当前 `l0-mainline` 合并进 `main`，拿到 merge 后 GitHub-side 的 strict L0 Linux maintenance run 证据，并把这次 merge / workflow 事实固化进 L0 文档。

**Architecture:** 分两段完成。第一段把当前 `l0-mainline` 通过 GitHub PR merge 送进 `main`，让 `.github/workflows/l0-linux-maintenance.yml` 真正进入 default branch。第二段在同一个 `L0` worktree 中 fast-forward 到 merge 后的 `origin/main`，触发 GitHub-side Linux maintenance workflow，等待 run 完成，再补一轮 docs-only closeout 并通过第二个 PR merge 回 `main`。

**Tech Stack:** Git branches, GitHub CLI (`gh`), GitHub Pull Requests, GitHub Actions, Bash verification scripts, Markdown docs.

---

### Task 1: 固化本轮实施计划

**Files:**
- Create: `docs/plans/2026-04-11-l0-main-merge-and-gh-evidence-plan.md`

**Step 1: 写 dated plan**

要求：

- 明确这轮不扩张 strict L0 模块边界
- 明确根目录 `main` 因为用户脏状态不作为 merge 执行面
- 明确采用“两段式 PR merge + GitHub workflow evidence + docs closeout”

### Task 2: 创建并合并第一轮 PR

**Files:**
- Modify: remote refs / PR state only

**Step 1: 推送当前 `l0-mainline`**

Run:

```bash
git push origin HEAD:refs/heads/l0-mainline
```

Expected:

- `origin/l0-mainline` 更新到当前 `HEAD`

**Step 2: 创建 PR**

Run:

```bash
gh pr create --base main --head l0-mainline --title "docs(l0): land maintenance workflow and closeout governance" --body-file <temp-body-file>
```

Expected:

- 返回 PR URL / 编号

**Step 3: 合并 PR**

Run:

```bash
gh pr merge <pr-number> --merge --delete-branch=false
```

Expected:

- `main` 获得 merge commit
- `l0-mainline` 远端分支保留，供第二段 docs-only closeout 继续使用

### Task 3: 让本地 `l0-mainline` 跟上 merge 后的 `main`

**Files:**
- Modify: local branch ref only

**Step 1: fetch 最新远端**

Run:

```bash
git fetch origin
```

Expected:

- 本地拿到 merge 后的 `origin/main`

**Step 2: 在当前 worktree fast-forward 到 `origin/main`**

Run:

```bash
git merge --ff-only origin/main
```

Expected:

- 当前 `l0-mainline` 指到 merge 后的 mainline commit

### Task 4: 触发并记录 GitHub-side Linux maintenance evidence

**Files:**
- Modify: none

**Step 1: 确认 workflow 已被 GitHub 注册**

Run:

```bash
gh workflow list
gh api repos/dtamade/fafafa.core/actions/workflows/l0-linux-maintenance.yml
```

Expected:

- `L0 Linux Maintenance` 出现在 workflow 列表
- workflow endpoint 不再返回 `HTTP 404`

**Step 2: 触发 workflow**

Run:

```bash
gh workflow run l0-linux-maintenance.yml --ref main
```

Expected:

- GitHub 接受 dispatch

**Step 3: 等待 run 结束并记录结果**

Run:

```bash
gh run list --workflow l0-linux-maintenance.yml --branch main --limit 1
gh run watch <run-id> --exit-status
```

Expected:

- run 最终 `completed/success`
- 记录 run id、head sha、结论

### Task 5: 基于 merge 后事实更新 docs

**Files:**
- Modify: `docs/CI.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md`
- Modify: `workers/worker1.md`

**Step 1: 更新 CI 文档**

要求：

- 去掉“未进入 default branch 所以 `HTTP 404`”的 current limitation
- 写入 merge 后 workflow 已可 dispatch 的事实
- 写入这次 GitHub-side L0 Linux run 的 run id / 结果

**Step 2: 更新 audit / closeout / worker**

要求：

- `audit` 写明当前 `main` 已含 L0 Linux maintenance workflow
- `closeout` 从 pre-merge 404 结论切到 post-merge GitHub-side evidence 结论
- `worker1` 写入最新 verification state

### Task 6: 验证并合并第二轮 docs-only closeout

**Files:**
- Modify: remote refs / PR state only

**Step 1: 跑 fresh verification**

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

**Step 2: 提交 docs-only closeout**

Run:

```bash
git add docs/CI.md docs/audits/2026-04-11-l0-current-state-audit.md docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md workers/worker1.md
git commit -m "docs(l0): record main-merge linux workflow evidence"
```

Expected:

- 形成 merge 后 docs-only closeout commit

**Step 3: 创建并合并第二轮 PR**

Run:

```bash
git push origin HEAD:refs/heads/l0-mainline
gh pr create --base main --head l0-mainline --title "docs(l0): record main-merge linux workflow evidence" --body-file <temp-body-file>
gh pr merge <pr-number> --merge --delete-branch=false
```

Expected:

- docs-only closeout 最终进入 `main`

### Task 7: 最终同步并记录结果

**Files:**
- Modify: none

**Step 1: 最终同步本地分支**

Run:

```bash
git fetch origin
git merge --ff-only origin/main
git status --short --branch
```

Expected:

- 当前 `l0-mainline` 与最新 `origin/main` 对齐
- 工作区干净
