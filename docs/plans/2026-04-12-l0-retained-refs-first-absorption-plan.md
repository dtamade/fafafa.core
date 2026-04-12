# L0 Retained Refs First Absorption Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 给 strict non-SIMD L0 落一波 retained refs 吸收基础设施，并先把 sidecar/tail 上低风险的 historical docs/archive history 吸收到 mainline，减少后续 refs 清理的人工判断成本。

**Architecture:** 先新增一个 retained-refs inventory 脚本和 contract，把 4 条保留 refs 的 unique history 按 path bucket 分类，输出可执行的吸收建议。然后再用一个 archive layout contract 锁定“历史报告应下沉到 archive、docs 原目录只保留指路页”的 today contract，接着把 sidecar/tail 上已经明确属于 archive 的历史报告迁到 `archive/reports/*` 并补齐 `docs/benchmarks/reports/README.md`、`docs/collections/reports/README.md`、`docs/reports/README.md`。最后更新 L0 current-entry 文档，重跑 retained-refs 审计和 strict L0 maintenance loop，确认这波仍然保持 non-SIMD L0 稳定。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 audit/maintenance scripts

---

### Task 1: 先写 retained refs inventory contract

**Files:**
- Create: `tests/test_strict_l0_retained_refs_inventory_contract.sh`
- Test: `tests/report_strict_l0_retained_refs_inventory.sh`

**Step 1: 写 failing contract**

- 用 PATH stub 的 `git` 模拟 4 条 retained refs 的 `git cherry -v` 与 `git show --name-only` 输出。
- contract 至少校验：
  - 输出 `current_head=`
  - 每条 ref 的 `unique_commit_count=`
  - bucket 统计，如 `archive_docs_paths=`、`code_or_tests_paths=`、`examples_or_build_paths=`
  - recommendation 字段
  - 最终 `[PASS] ... inventory completed`

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_contract.sh
```

Expected:

- 因目标脚本不存在而 FAIL

### Task 2: 实现 retained refs inventory 脚本

**Files:**
- Create: `tests/report_strict_l0_retained_refs_inventory.sh`
- Modify: `docs/TESTING.md`
- Modify: `docs/INDEX.md`
- Modify: `workers/worker1.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`

**Step 1: 实现脚本**

- 支持默认执行和 `--help`
- 固定分析：
  - `l0-mainline-closeout-20260411`
  - `l0-sidecar-handoff-20260409`
  - `l0-main-rescue`
  - `l0-main-tail-cleanup-20260408-final`
- 逐条 ref 输出：
  - `unique_commit_count`
  - `archive_docs_paths`
  - `docs_current_entry_paths`
  - `code_or_tests_paths`
  - `examples_or_build_paths`
  - `recommendation`
- recommendation 最少覆盖：
  - `absorb-archive-first`
  - `review-code-before-absorb`
  - `no-unique-commits`

**Step 2: 跑 contract，确认转绿**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_contract.sh
```

Expected:

- PASS

**Step 3: 接 current-entry 入口**

- 在 `docs/TESTING.md` / `docs/INDEX.md` / `workers/worker1.md` 中补充 inventory 命令入口
- 在 `tests/check_strict_l0_docs_consistency.sh` 中校验新脚本与新入口 literal

### Task 3: 先写 archive layout failing contract

**Files:**
- Create: `tests/test_strict_l0_archive_reports_layout_contract.sh`

**Step 1: 写 contract**

- 校验以下 today contract：
  - `docs/benchmarks/reports/README.md`
  - `docs/collections/reports/README.md`
  - `docs/reports/README.md`
  - 代表性历史文件已在 `archive/reports/docs-benchmarks/`、`archive/reports/docs-collections/`、`archive/reports/docs-root/`
  - 对应原始 `docs/...` 历史报告文件已不存在

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_archive_reports_layout_contract.sh
```

Expected:

- FAIL，提示 README 或 archive 文件缺失

### Task 4: 吸收 sidecar/tail 的低风险 archive history

**Files:**
- Create: `docs/benchmarks/reports/README.md`
- Create: `docs/collections/reports/README.md`
- Create: `docs/reports/README.md`
- Create: `docs/audits/2026-04-12-l0-retained-refs-absorption-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `workers/worker1.md`
- Move: representative historical reports from `docs/benchmarks/reports/`, `docs/collections/reports/`, `docs/reports/`, `docs/` to `archive/reports/docs-benchmarks/`, `archive/reports/docs-collections/`, `archive/reports/docs-root/`

**Step 1: 实际迁移文件**

- 先迁移纯历史 benchmark / collections reports
- 再迁移 root-level historical reports 与 module completion reports
- 不改 SIMD current-entry，不扩 L0 module surface

**Step 2: 补 README 指路页**

- 原目录只保留归档说明和 archive 入口

**Step 3: 写 absorption audit**

- 记录 inventory 结果
- 记录这次实际吸收了哪一批 archive docs
- 记录 absorb 后 retained refs 是否仍然保留 unique history

**Step 4: 跑 archive layout contract，确认转绿**

Run:

```bash
bash tests/test_strict_l0_archive_reports_layout_contract.sh
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
bash tests/test_strict_l0_archive_reports_layout_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/report_strict_l0_retained_refs_inventory.sh
bash tests/audit_strict_l0_retained_refs.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 全部 PASS
- retained refs inventory 给出更明确的 absorb 建议
- retained refs audit 保持 non-destructive 输出

**Step 2: 提交**

```bash
git add docs/plans/2026-04-12-l0-retained-refs-first-absorption-plan.md \
  tests/test_strict_l0_retained_refs_inventory_contract.sh \
  tests/report_strict_l0_retained_refs_inventory.sh \
  tests/test_strict_l0_archive_reports_layout_contract.sh \
  docs/benchmarks/reports/README.md \
  docs/collections/reports/README.md \
  docs/reports/README.md \
  docs/audits/2026-04-12-l0-retained-refs-absorption-audit.md \
  docs/README.md docs/INDEX.md docs/TESTING.md docs/audits/2026-04-11-l0-current-state-audit.md workers/worker1.md \
  tests/check_strict_l0_docs_consistency.sh \
  archive/reports/docs-benchmarks archive/reports/docs-collections archive/reports/docs-root
git commit -m "feat(l0): absorb first retained refs archive wave"
```

Expected:

- 得到一组 retained refs inventory + first archive absorption 提交
