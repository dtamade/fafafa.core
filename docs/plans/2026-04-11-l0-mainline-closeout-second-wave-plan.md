# L0 Mainline Closeout Second Wave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 strict L0 mainline closeout 的第二波控制面收紧完成，补上真正的 stubbed E2E contract，抽取共享的 GitHub Actions workflow helper，并把当前两波 closeout automation 作为一组干净提交落地。

**Architecture:** 这轮不扩 L0 模块边界，也不改业务语义。核心做法是先用一个会失败的 stubbed mainline closeout E2E contract 锁定 `--skip-linux` / `--skip-windows` / `--apply-docs` / run-id / run-sha 传递缺口，再把 GH workflow run 查找与等待逻辑抽成一个共享 shell helper，最后让 `run_strict_l0_mainline_closeout.sh` 在 skip+reuse 路径上也从 run 本身解析 `headSha`，而不是错误回落到 `main` SHA。

**Tech Stack:** Bash, git, gh CLI, python3, ripgrep, existing strict L0 contract tests

---

### Task 1: 写第二波 closeout E2E contract

**Files:**
- Create: `tests/test_strict_l0_mainline_closeout_e2e_contract.sh`
- Test: `tests/run_strict_l0_mainline_closeout.sh`

**Step 1: 写 failing contract**

- 新增 `tests/test_strict_l0_mainline_closeout_e2e_contract.sh`
- 在 temp dir 下 stub：
  - `gh`
  - `git`
  - `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
  - `tests/update_strict_l0_current_state_docs.sh`
- 至少覆盖两条路径：
  1. `--skip-linux --skip-windows --apply-docs --linux-run-id ... --windows-run-id ...`
     - 期望 docs updater 收到的 `--linux-run-sha` 与 `--windows-run-sha` 来自 `gh run view` 的 `headSha`
     - 不能错误回退成 `--main-sha`
  2. 非 skip 路径
     - 期望 closeout 能从 Windows helper 输出里抓到 `Watching run: <id>`
     - 期望 docs updater 收到捕获到的 windows run id

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_mainline_closeout_e2e_contract.sh
```

Expected:

- 因当前 skip+reuse 路径会错传 run sha 而 FAIL

### Task 2: 抽取共享 GH workflow helper

**Files:**
- Create: `tests/lib_github_actions_workflow_runs.sh`
- Modify: `tests/run_strict_l0_mainline_closeout.sh`
- Modify: `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`

**Step 1: 抽共用函数**

- 新增 `tests/lib_github_actions_workflow_runs.sh`
- 最小共享函数：
  - `gh_runlib_find_latest_dispatch_run_id`
  - `gh_runlib_wait_for_run_completion`
  - `gh_runlib_get_run_head_sha`
- `find_latest` 支持 `strict` 与 `relaxed` 两种匹配模式：
  - `strict` 给 `run_strict_l0_mainline_closeout.sh`
  - `relaxed` 给 `run_windows_strict_l0_native_evidence_via_github_actions.sh`

**Step 2: 改 closeout skip/reuse 逻辑**

- `run_strict_l0_mainline_closeout.sh` 改成：
  - 只要存在 `--linux-run-id`，无论是否 skip，都可从 shared helper 取 Linux run `headSha`
  - 只要存在 `--windows-run-id`，无论是否 skip，都可从 shared helper 取 Windows run `headSha`
  - `--apply-docs` 时优先把真实 run sha 传给 docs updater，而不是盲目 fallback 到 `main`

**Step 3: 改 Windows helper 用 shared helper**

- `run_windows_strict_l0_native_evidence_via_github_actions.sh` 改成 source 共享 helper
- 保留现有 fail-close 文案与 billing/workflow-missing 语义

**Step 4: 跑 test，确认转绿**

Run:

```bash
bash tests/test_strict_l0_mainline_closeout_e2e_contract.sh
bash tests/test_strict_l0_mainline_closeout_contract.sh
bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh
bash tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh
```

Expected:

- 全部 PASS

### Task 3: 全量验证并收口提交

**Files:**
- Modify: `docs/CI.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md`
- Modify: `workers/worker1.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `tests/test_update_strict_l0_current_state_docs_contract.sh`
- Modify: `tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
- Add/Modify all new helper / contract / plan files in this wave

**Step 1: 跑完整验证**

Run:

```bash
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
bash tests/test_strict_l0_linux_ci_workflow_contract.sh
bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh
bash tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh
bash tests/test_strict_l0_mainline_closeout_contract.sh
bash tests/test_strict_l0_mainline_closeout_e2e_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 全部 PASS

**Step 2: 提交**

先提交第一波已经验证完成的 closeout automation，再把第二波 helper/E2E 强化一起纳入同一个 clean commit。

Run:

```bash
git add docs/CI.md docs/INDEX.md docs/TESTING.md docs/audits/2026-04-11-l0-current-state-audit.md docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md workers/worker1.md tests/check_strict_l0_docs_consistency.sh tests/run_windows_strict_l0_native_evidence_via_github_actions.sh tests/test_windows_strict_l0_native_evidence_gh_contract.sh tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh tests/run_strict_l0_mainline_closeout.sh tests/test_strict_l0_mainline_closeout_contract.sh tests/test_strict_l0_mainline_closeout_e2e_contract.sh tests/update_strict_l0_current_state_docs.sh tests/test_update_strict_l0_current_state_docs_contract.sh tests/lib_github_actions_workflow_runs.sh docs/plans/2026-04-11-l0-mainline-closeout-automation-plan.md docs/plans/2026-04-11-l0-mainline-closeout-second-wave-plan.md
git commit -m "feat(l0): automate mainline closeout flow"
```

Expected:

- 得到一组包含两波 closeout automation 的干净提交

**Step 3: 记录明确边界**

- 当前不执行真实 `main` 分支 CI closeout
- 原因：
  - 用户要求先在 L0 worktree 内做完再合并
  - `mainline closeout` 的真实 GH evidence 只能在后续把这组改动合到 `main` 后再收
- 当前交付的是：
  - closeout 自动化脚本
  - contracts
  - docs backfill
  - 本地完整验证
