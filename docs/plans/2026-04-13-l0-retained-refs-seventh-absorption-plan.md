# L0 Retained Refs Seventh Absorption Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 继续把 strict non-SIMD L0 retained refs 的 `sidecar/tail` 下一跳从“只知道先做 test-hygiene”推进成“知道 test-hygiene 之后哪些 docs current-entry residue 是低风险 absorb candidate，以及它们应该落到哪里”。

**Architecture:** 这轮继续坚持 docs-first、non-destructive、high-ROI，不改 `src/` 行为。先给 retained-refs inventory 的 `docs_current_entry` 再做细粒度拆分，把 root entry、module docs、topics/guides、archive pointers、collections dated docs、legacy docs、report-topic docs 分开，并新增 `docs_absorb_candidate_paths=`。然后把 current landing zones 写进 `docs/collections/legacy/README.md` 和几份 report pointer README，最后刷新第七波审计、根入口、worker handoff 和 docs consistency。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 audit/maintenance scripts

---

### Task 1: 先写 docs-current-entry absorbability contract

**Files:**
- Create: `tests/test_strict_l0_retained_refs_inventory_docs_current_entry_contract.sh`
- Test: `tests/report_strict_l0_retained_refs_inventory.sh`

**Step 1: 写 failing contract**

- 用 PATH stub 的 `git` 模拟 retained refs unique history，覆盖：
  - `docs_root_entry_paths=`
  - `docs_module_paths=`
  - `docs_topic_paths=`
  - `docs_guide_paths=`
  - `docs_archive_pointer_paths=`
  - `docs_collections_dated_paths=`
  - `docs_legacy_paths=`
  - `docs_report_topic_paths=`
  - `docs_absorb_candidate_paths=`
- contract 还要锁定 `sample_docs_absorb_candidate_paths=`，确保 sidecar/tail 的 current-entry residue 不再只靠人工判断。

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_docs_current_entry_contract.sh
```

Expected:

- 因目标脚本还没输出这些 docs bucket / absorb candidate 而 FAIL

### Task 2: 实现 docs-current-entry 细分与 absorb candidate

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_inventory.sh`
- Modify: `docs/TESTING.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`

**Step 1: 细化 docs_current_entry bucket**

- 在 `--details` 输出里补：
  - `docs_root_entry_paths=`
  - `docs_module_paths=`
  - `docs_topic_paths=`
  - `docs_guide_paths=`
  - `docs_archive_pointer_paths=`
  - `docs_collections_dated_paths=`
  - `docs_legacy_paths=`
  - `docs_report_topic_paths=`
  - 以及对应 `sample_*`

**Step 2: 给 inventory 补 docs absorb candidate**

- 新增：
  - `docs_absorb_candidate_paths=`
  - `sample_docs_absorb_candidate_paths=`
- absorb candidate 只统计已经有稳定 landing zone 或本身就是 landing zone 的低风险 docs residue：
  - archive pointers
  - collections dated docs
  - legacy docs

**Step 3: 刷新 TESTING 与 docs consistency**

- 写清楚 `--details` 现在如何继续拆 docs current-entry
- 写清楚 `docs_absorb_candidate_paths=` 的 today contract
- docs consistency 锁定新的 plan / audit / contract / 文档文字

### Task 3: 吸收 sidecar/tail 的低风险 docs current-entry residue

**Files:**
- Modify: `docs/collections/legacy/README.md`
- Modify: `docs/reports/README.md`
- Modify: `docs/collections/reports/README.md`
- Modify: `docs/benchmarks/reports/README.md`

**Step 1: 刷新 landing-zone 文档**

- 明确说明 retained-refs inventory 里出现的这几类 docs residue 已经有 today landing zone：
  - collections dated plans/status -> `docs/collections/legacy/README.md`
  - root/collections/benchmarks reports -> 对应 `docs/*/reports/README.md`
- 文案强调：
  - 这些 landing zones 是 absorb target / pointer，不是继续把 dated docs 堆回 current-entry

**Step 2: 补充 current-entry absorbability 语义**

- 让读者能从这些 README 直接理解：
  - sidecar/tail 再暴露这些路径时应视作低风险 docs residue
  - 它们不该阻塞更后面的 source-review wave

### Task 4: 刷新第七波 audit、根入口和 worker handoff

**Files:**
- Create: `docs/audits/2026-04-13-l0-retained-refs-seventh-absorption-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/audits/2026-04-13-l0-retained-refs-sixth-absorption-audit.md`
- Modify: `workers/worker1.md`
- Modify: `tests/test_strict_l0_legacy_docs_layout_contract.sh`

**Step 1: 更新 latest absorption 入口**

- `docs/README.md` / `docs/INDEX.md` 改为指向第七波 audit

**Step 2: 记录第七波结论**

- sidecar / tail 现在已经能明确拆出：
  - 低风险 docs absorb candidates
  - 稳定 landing zones
  - 仍然属于 live current-entry 的 module/topic/root docs
- 写清楚：
  - `sidecar/tail` 依然先走 `test-hygiene-first`
  - 但 test-hygiene 之后优先看的 docs residue 已经不是未知数

**Step 3: 更新 worker handoff**

- worker1 记录最新 source of truth、fresh verification 和下一跳建议

### Task 5: 跑完整验证并提交

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_docs_current_entry_contract.sh
bash tests/test_strict_l0_examples_build_docs_contract.sh
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
- sidecar / tail 的 docs absorb candidate 可复跑
- latest absorption 入口更新为第七波

**Step 2: 提交**

```bash
git add docs/plans/2026-04-13-l0-retained-refs-seventh-absorption-plan.md \
  docs/audits/2026-04-13-l0-retained-refs-seventh-absorption-audit.md \
  docs/README.md docs/INDEX.md docs/TESTING.md \
  docs/collections/legacy/README.md \
  docs/reports/README.md docs/collections/reports/README.md docs/benchmarks/reports/README.md \
  docs/audits/2026-04-11-l0-current-state-audit.md \
  docs/audits/2026-04-13-l0-retained-refs-sixth-absorption-audit.md \
  workers/worker1.md tests/check_strict_l0_docs_consistency.sh \
  tests/test_strict_l0_legacy_docs_layout_contract.sh \
  tests/report_strict_l0_retained_refs_inventory.sh \
  tests/test_strict_l0_retained_refs_inventory_docs_current_entry_contract.sh
git commit -m "feat(l0): absorb seventh retained refs docs wave"
```

Expected:

- 得到一组继续压低 sidecar/tail docs-current-entry triage 成本的 docs-first retained-refs wave 提交
