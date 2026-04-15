# L0 Mainline Closeout Automation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 strict L0 的 mainline closeout 收敛成可复用的单入口流程，修复 GitHub Actions helper 对 `main` ref 的误判，并把 current-state 文档回填做成可执行脚本。

**Architecture:** 这次不扩 L0 模块面，只加控制面自动化。核心做法是把现有 Linux maintenance lane、Windows exact-evidence helper、docs current-state 文件串成一个主入口，同时补一个独立的 docs backfill 脚本，让 closeout 既能“只跑证据”，也能“跑完后回填文档”。`run_windows_strict_l0_native_evidence_via_github_actions.sh` 的 ref 对齐逻辑会改成以当前 worktree `HEAD` 和远端目标 ref 为准，而不是误依赖本地 stale `refs/heads/main`。

**Tech Stack:** Bash, GitHub CLI (`gh`), git, python3, ripgrep, existing strict L0 contract tests

---

### Task 1: GH helper ref-alignment hardening

**Files:**
- Modify: `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
- Test: `tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
- Create: `tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh`

**Step 1: 写失败契约**

- 新增 `tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh`
- 用 PATH stub 的 `git` / `gh` 模拟下面场景：
  - 当前 worktree `HEAD` 与远端 `main` 一致
  - 本地 `refs/heads/main` 是 stale ref
  - helper 以 `L0_NATIVE_EVIDENCE_REF=main` 运行
- 期望：
  - 不再报 `Refuse dispatch: remote ref does not match local HEAD.`
  - 至少进入 `Dispatch workflow:` 阶段
  - 由于 stub dispatch 故意失败，脚本最终以受控的 dispatch 失败码退出

**Step 2: 改 helper 解析逻辑**

- 在 `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh` 中显式区分：
  - current worktree `HEAD`
  - current branch
  - target dispatch ref
  - remote target ref SHA
- 规则：
  - 如果 dispatch ref 就是当前 branch，local candidate SHA 直接取 current `HEAD`
  - 如果 dispatch ref 不是当前 branch，但 current `HEAD` 已经等于 remote target ref，也允许 dispatch
  - 只有在 worktree clean 的前提下，current `HEAD` 与 remote target ref 明显不一致时，才继续 fail-close
- 保留 dirty worktree guard，不放松 hygiene 语义

**Step 3: 更新现有 GH helper contract**

- 在 `tests/test_windows_strict_l0_native_evidence_gh_contract.sh` 里补一条 literal / contract 检查，确保 helper 继续保留 ref hygiene guard 文案，同时允许 main-ref current-head 路径

**Step 4: 跑验证**

Run:

```bash
bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh
bash tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh
```

Expected:

- 两条 contract 都 PASS

### Task 2: Mainline closeout 单入口

**Files:**
- Create: `tests/run_strict_l0_mainline_closeout.sh`
- Test: `tests/test_strict_l0_mainline_closeout_contract.sh`
- Modify: `docs/CI.md`
- Modify: `docs/TESTING.md`

**Step 1: 写 contract**

- 新增 `tests/test_strict_l0_mainline_closeout_contract.sh`
- 最小要求：
  - `bash tests/run_strict_l0_mainline_closeout.sh --print-commands` 成功
  - 输出必须包含：
    - `gh workflow run l0-linux-maintenance.yml --ref main`
    - `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
    - `bash tests/update_strict_l0_current_state_docs.sh`

**Step 2: 实现脚本**

- 新脚本职责：
  - 支持 `--print-commands`
  - 支持复用或触发 Linux maintenance workflow on `main`
  - 支持复用或触发 Windows native evidence workflow on `main`
  - 支持把 run id / batch id 交给 docs backfill 脚本
- 默认不直接扩张行为面：
  - 允许 `--apply-docs` 显式开启文档回填
  - 不在默认模式下偷偷改 docs
- 优先复用现有 helper：
  - Linux lane 用 `gh workflow run/view`
  - Windows lane 用 `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`

**Step 3: 更新 user-facing docs**

- 在 `docs/CI.md` 和 `docs/TESTING.md` 里补 current-entry：
  - 日常 local maintenance：`bash tests/run_strict_l0_maintenance_loop.sh`
  - post-merge closeout：`bash tests/run_strict_l0_mainline_closeout.sh`

**Step 4: 跑验证**

Run:

```bash
bash tests/test_strict_l0_mainline_closeout_contract.sh
```

Expected:

- PASS

### Task 3: Current-state docs backfill 自动化

**Files:**
- Create: `tests/update_strict_l0_current_state_docs.sh`
- Create: `tests/test_update_strict_l0_current_state_docs_contract.sh`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md`
- Modify: `workers/worker1.md`

**Step 1: 写 contract**

- 新增 `tests/test_update_strict_l0_current_state_docs_contract.sh`
- 在 temp root 下准备最小 docs 目录结构
- 用 sample inputs 跑：
  - `--apply`
  - `--target-root <tmp>`
  - `--main-sha`
  - `--linux-run-id`
  - `--windows-run-id`
  - `--windows-batch-id`
- 校验生成结果里至少包含：
  - Linux maintenance run id
  - Windows native evidence run id
  - batch id
  - worker1 base commit

**Step 2: 实现脚本**

- `tests/update_strict_l0_current_state_docs.sh` 负责：
  - 根据输入参数生成/回填
    - `docs/audits/2026-04-11-l0-current-state-audit.md`
    - `docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md`
    - `workers/worker1.md`
  - 默认只打印 planned targets
  - `--apply` 时执行覆盖更新
  - 支持 `--target-root`，便于 contract test 在 temp root 运行
- 内容要求：
  - 避免把 transient main SHA 写入 stable docs 之外的位置
  - current-state audit / worker handoff 必须反映最新 run id
  - legacy closeout 必须保留历史 `HTTP 404` 语境，但把当前 mainline 已解决状态写清楚

**Step 3: 用脚本回填真实文件**

Run:

```bash
bash tests/update_strict_l0_current_state_docs.sh \
  --apply \
  --main-sha <latest-main-sha> \
  --linux-run-id <latest-linux-run-id> \
  --windows-run-id <latest-windows-run-id> \
  --windows-batch-id <latest-batch-id>
```

Expected:

- 三个 current-state 文件被脚本一致性回填

### Task 4: 最终验证与收口

**Files:**
- Verify only

**Step 1: 跑 docs / contract 验证**

Run:

```bash
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh
bash tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh
bash tests/test_strict_l0_mainline_closeout_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
```

Expected:

- 全部 PASS

**Step 2: 跑完整 strict L0 维护闭环**

Run:

```bash
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 全部 PASS

**Step 3: 提交**

```bash
git add docs/CI.md docs/TESTING.md docs/audits/2026-04-11-l0-current-state-audit.md docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md workers/worker1.md docs/plans/2026-04-11-l0-mainline-closeout-automation-plan.md tests/run_windows_strict_l0_native_evidence_via_github_actions.sh tests/run_strict_l0_mainline_closeout.sh tests/update_strict_l0_current_state_docs.sh tests/test_windows_strict_l0_native_evidence_gh_contract.sh tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh tests/test_strict_l0_mainline_closeout_contract.sh tests/test_update_strict_l0_current_state_docs_contract.sh
git commit -m "feat(l0): automate mainline closeout flow"
```

Expected:

- 形成一组完整的 L0 closeout automation 提交
