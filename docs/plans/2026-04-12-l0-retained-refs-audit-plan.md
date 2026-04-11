# L0 Retained Refs Audit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 给 strict non-SIMD L0 增加一个非破坏性的 retained refs 审计入口，把“当前 4 个历史 L0 refs 仍未被证明完全冗余”从口头判断收敛成可复跑的本地审计工具与 contract。

**Architecture:** 这轮不删除任何 refs，只加一个只读 audit 脚本。脚本固定审计当前保留的历史 L0 refs，读取 `HEAD`、`merge-base`、`git cherry -v HEAD <ref>` 和 ref tip sha，最后给出 `retain-unique-history` / `candidate-delete` / `same-tip` 这类非破坏性判定。配套 contract 用 PATH stub 的 `git` 验证输出和 fail-close 行为，然后把这个入口补进 current-entry 文档与 docs consistency。

**Tech Stack:** Bash, git, python3-free shell contracts, ripgrep, existing strict L0 docs/update scripts

---

### Task 1: 写 retained refs audit contract

**Files:**
- Create: `tests/test_strict_l0_retained_refs_audit_contract.sh`
- Test: `tests/audit_strict_l0_retained_refs.sh`

**Step 1: 写 failing contract**

- 新增 `tests/test_strict_l0_retained_refs_audit_contract.sh`
- 用 stub `git` 模拟：
  - `l0-mainline-closeout-20260411` 与 `HEAD` 同 tip
  - `l0-main-rescue` 只有 patch-equivalent commits
  - `l0-sidecar-handoff-20260409` 仍有 `git cherry` 的 `+` 提交
  - `l0-main-tail-cleanup-20260408-final` 仍有多个 `+` 提交
- 期望输出至少包含：
  - 当前 `HEAD`
  - 每个 ref 的 decision
  - `retain-unique-history`
  - `candidate-delete`
  - `same-tip`
  - 最终 `[PASS] ... audit completed (non-destructive)`

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_retained_refs_audit_contract.sh
```

Expected:

- 因目标脚本尚不存在而 FAIL

### Task 2: 实现 refs audit 脚本

**Files:**
- Create: `tests/audit_strict_l0_retained_refs.sh`

**Step 1: 实现脚本**

- 支持：
  - 默认执行审计
  - `--print-commands`
  - `--help`
- 固定审计 refs：
  - `l0-mainline-closeout-20260411`
  - `l0-sidecar-handoff-20260409`
  - `l0-main-rescue`
  - `l0-main-tail-cleanup-20260408-final`
- 对每个 ref 输出：
  - `ref_sha`
  - `merge_base`
  - `unique_patch_count`
  - `equivalent_patch_count`
  - `decision`
- 判定规则：
  - ref tip 等于 `HEAD`：`same-tip`
  - `git cherry -v HEAD <ref>` 存在 `+`：`retain-unique-history`
  - 否则：`candidate-delete`
- 默认严格 non-destructive：
  - 不执行 `git branch -d/-D`
  - 只输出建议

**Step 2: 跑 contract，确认转绿**

Run:

```bash
bash tests/test_strict_l0_retained_refs_audit_contract.sh
```

Expected:

- PASS

### Task 3: 接入 current-entry 文档与 consistency

**Files:**
- Modify: `docs/CI.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/INDEX.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `tests/update_strict_l0_current_state_docs.sh`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `workers/worker1.md`

**Step 1: 更新文档入口**

- 在 CI / TESTING / INDEX / worker / current-state audit 中补：
  - 如需重新审计残留 L0 refs 是否仍承载独立 patch history，使用 `bash tests/audit_strict_l0_retained_refs.sh`
- 文案保持非破坏性：
  - 审计只给 decision，不直接删除

**Step 2: 更新 docs updater**

- `tests/update_strict_l0_current_state_docs.sh` 生成的 audit / worker handoff 里补 retained refs 审计入口

**Step 3: 更新 docs consistency**

- 校验新脚本存在
- 校验 current-entry 文档里都出现 `bash tests/audit_strict_l0_retained_refs.sh`

### Task 4: 完整验证并提交

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_audit_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 全部 PASS

**Step 2: 提交**

```bash
git add docs/plans/2026-04-12-l0-retained-refs-audit-plan.md tests/audit_strict_l0_retained_refs.sh tests/test_strict_l0_retained_refs_audit_contract.sh docs/CI.md docs/TESTING.md docs/INDEX.md tests/check_strict_l0_docs_consistency.sh tests/update_strict_l0_current_state_docs.sh docs/audits/2026-04-11-l0-current-state-audit.md workers/worker1.md
git commit -m "feat(l0): audit retained refs non-destructively"
```

Expected:

- 得到一组只读 refs audit 能力提交
