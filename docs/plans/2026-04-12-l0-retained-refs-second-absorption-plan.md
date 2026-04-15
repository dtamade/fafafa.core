# L0 Retained Refs Second Absorption Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 给 strict non-SIMD L0 的 retained refs 吸收流程补上更细的 inventory triage 能力，并把一批已经明确 superseded 的 L0 dated plan/audit 从 current-entry 区域下沉到 `docs/legacy/l0/`。

**Architecture:** 这轮继续坚持 docs-first、non-destructive、high-ROI。先给 `tests/report_strict_l0_retained_refs_inventory.sh` 加 `--details` 模式，用 contract 锁定“每条 retained ref 都能输出代表性 unique commits 和路径样本”。再写一个 legacy layout contract，把已确认过期的 L0 dated plans/audits 从 `docs/plans/`、`docs/audits/` 迁到 `docs/legacy/l0/`，同时刷新 `docs/README.md`、`docs/INDEX.md`、`docs/TESTING.md`、`docs/legacy/l0/README.md`、`workers/worker1.md` 和 retained-refs 吸收审计。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 audit/maintenance scripts

---

### Task 1: 先写 retained refs inventory details contract

**Files:**
- Create: `tests/test_strict_l0_retained_refs_inventory_details_contract.sh`
- Test: `tests/report_strict_l0_retained_refs_inventory.sh`

**Step 1: 写 failing contract**

- 用 PATH stub 的 `git` 模拟 retained refs 的 `git cherry -v` 与 `git show --name-only` 输出。
- contract 至少校验：
  - `bash tests/report_strict_l0_retained_refs_inventory.sh --details`
  - 每条 ref 都出现 `sample_unique_commits=`
  - 至少一个 bucket 样本行，例如 `sample_docs_current_entry_paths=`、`sample_archive_docs_paths=`
  - 最终仍输出 `[PASS] strict L0 retained refs inventory completed`

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh
```

Expected:

- 因 `--details` 尚未实现或缺少细节 literal 而 FAIL

### Task 2: 实现 inventory `--details` 并接 current-entry

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_inventory.sh`
- Modify: `docs/TESTING.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `workers/worker1.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`

**Step 1: 实现最小功能**

- 支持 `--details`
- 在不改变默认输出合同的前提下，额外输出：
  - `sample_unique_commits=`
  - 各 bucket 的 representative path samples
- 默认 sample 数固定小值，避免输出失控

**Step 2: 跑 contract，确认转绿**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh
```

Expected:

- 全部 PASS

**Step 3: 接 current-entry**

- 在 `docs/TESTING.md`、`docs/INDEX.md`、`docs/audits/2026-04-11-l0-current-state-audit.md`、`workers/worker1.md` 中补 `--details` 用法
- 在 `tests/check_strict_l0_docs_consistency.sh` 中校验 `bash tests/report_strict_l0_retained_refs_inventory.sh --details`

### Task 3: 先写 legacy L0 docs layout contract

**Files:**
- Create: `tests/test_strict_l0_legacy_docs_layout_contract.sh`

**Step 1: 写 failing contract**

- 校验第二波 today contract：
  - 一批 superseded L0 dated docs 存在于 `docs/legacy/l0/`
  - 对应旧路径已不存在
  - `docs/legacy/l0/README.md`、`docs/README.md`、`docs/INDEX.md` 指向新的 legacy 入口

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_legacy_docs_layout_contract.sh
```

Expected:

- 因文件仍在旧路径而 FAIL

### Task 4: 下沉 superseded L0 dated docs 并刷新索引/审计

**Files:**
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/legacy/l0/README.md`
- Modify: `docs/audits/2026-04-12-l0-retained-refs-absorption-audit.md`
- Create: `docs/audits/2026-04-12-l0-retained-refs-second-absorption-audit.md`
- Move: `docs/audits/2026-04-07-l0-rescue-triage-audit.md -> docs/legacy/l0/2026-04-07-l0-rescue-triage-audit.md`
- Move: `docs/audits/2026-04-08-l0-tail-docs-audit.md -> docs/legacy/l0/2026-04-08-l0-tail-docs-audit.md`
- Move: `docs/audits/2026-04-09-l0-current-state-audit.md -> docs/legacy/l0/2026-04-09-l0-current-state-audit.md`
- Move: `docs/audits/2026-04-10-l0-current-state-audit.md -> docs/legacy/l0/2026-04-10-l0-current-state-audit.md`
- Move: `docs/plans/2026-03-26-l0-candidates-platform-span-admission.md -> docs/legacy/l0/2026-03-26-l0-candidates-platform-span-admission.md`
- Move: `docs/plans/2026-03-26-strict-l0-merge-closeout.md -> docs/legacy/l0/2026-03-26-strict-l0-merge-closeout.md`
- Move: `docs/plans/2026-03-27-l0-control-plane-closeout.md -> docs/legacy/l0/2026-03-27-l0-control-plane-closeout.md`
- Move: `docs/plans/2026-04-07-l0-rescue-split-closeout.md -> docs/legacy/l0/2026-04-07-l0-rescue-split-closeout.md`
- Move: `docs/plans/2026-04-09-l0-kernel-span2-closeout.md -> docs/legacy/l0/2026-04-09-l0-kernel-span2-closeout.md`
- Move: `docs/plans/2026-04-09-l0-mainline-merge-checklist.md -> docs/legacy/l0/2026-04-09-l0-mainline-merge-checklist.md`
- Modify: `workers/worker1.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`

**Step 1: 迁移历史 L0 dated docs**

- 只迁移已经明确 superseded 的 L0 dated plans / audits
- 不迁移 `docs/fafafa.core.l0.*`、`docs/ARCHITECTURE_LAYERS.md`、`docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md` 这类 current-entry

**Step 2: 刷新 current-entry**

- `docs/README.md` / `docs/INDEX.md` 改成指向 `docs/legacy/l0/README.md` 或新的 legacy 路径
- `docs/legacy/l0/README.md` 列出第二波下沉的历史文档
- retained-refs 第二波审计记录：
  - 为什么这批可以先下沉
  - 这批实际迁移了哪些路径
  - fresh audit / inventory 的结果

**Step 3: 跑 legacy layout contract，确认转绿**

Run:

```bash
bash tests/test_strict_l0_legacy_docs_layout_contract.sh
```

Expected:

- PASS

### Task 5: 完整验证并提交

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh
bash tests/test_strict_l0_legacy_docs_layout_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/report_strict_l0_retained_refs_inventory.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
bash tests/audit_strict_l0_retained_refs.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 全部 PASS
- inventory `--details` 输出代表性 commit / path 样本
- second-wave legacy docs layout contract 通过
- retained refs audit 继续保持 non-destructive

**Step 2: 提交**

```bash
git add docs/plans/2026-04-12-l0-retained-refs-second-absorption-plan.md \
  tests/test_strict_l0_retained_refs_inventory_details_contract.sh \
  tests/test_strict_l0_legacy_docs_layout_contract.sh \
  tests/report_strict_l0_retained_refs_inventory.sh \
  docs/README.md docs/INDEX.md docs/TESTING.md docs/legacy/l0/README.md \
  docs/audits/2026-04-11-l0-current-state-audit.md \
  docs/audits/2026-04-12-l0-retained-refs-absorption-audit.md \
  docs/audits/2026-04-12-l0-retained-refs-second-absorption-audit.md \
  workers/worker1.md tests/check_strict_l0_docs_consistency.sh \
  docs/legacy/l0
git commit -m "feat(l0): absorb second retained refs docs wave"
```

Expected:

- 得到一组 inventory 细化 + legacy docs 下沉的独立提交
