# L0 Retained Refs Eighth Focus Routing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 strict non-SIMD L0 retained refs 的 `test-hygiene-first` 与 `source-review-first` 从“只有方向标签”推进成“有显式 candidate path bucket、sample 和文档语义”的可执行路由。

**Architecture:** 这轮继续坚持 docs-first、non-destructive、high-ROI，不改 strict L0 的 `src/` 行为。核心做法是在 `tests/report_strict_l0_retained_refs_inventory.sh --details` 里新增 `test_hygiene_candidate_paths=` 与 `source_review_candidate_paths=`，并补对应 sample；然后刷新 `docs/TESTING.md`、根入口、current-state audit 和 worker handoff，让 `sidecar/tail` 与 `closeout/rescue` 的下一跳都能直接从 inventory 输出读出来。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 retained-refs contracts and maintenance scripts

---

### Task 1: 写 focus-routing contract

**Files:**
- Create: `tests/test_strict_l0_retained_refs_inventory_focus_routing_contract.sh`
- Test: `tests/report_strict_l0_retained_refs_inventory.sh`

**Step 1: 写 failing contract**

- 用 PATH stub 的 `git` 模拟 retained refs unique history，覆盖：
  - `test_hygiene_candidate_paths=`
  - `sample_test_hygiene_candidate_paths=`
  - `source_review_candidate_paths=`
  - `sample_source_review_candidate_paths=`
- contract 还要锁定：
  - `sidecar/tail` 继续是 `next_focus=test-hygiene-first`
  - `closeout/rescue` 继续是 `next_focus=source-review-first`
  - 但现在四条 retained refs 的下一跳 candidate paths 已能直接读出

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_focus_routing_contract.sh
```

Expected:

- 因目标脚本还没输出新的 routing candidate bucket 而 FAIL

### Task 2: 实现 test-hygiene / source-review candidate bucket

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_inventory.sh`
- Modify: `docs/TESTING.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`

**Step 1: 补 inventory 细分**

- 在 `--details` 输出里新增：
  - `test_hygiene_candidate_paths=`
  - `sample_test_hygiene_candidate_paths=`
  - `source_review_candidate_paths=`
  - `sample_source_review_candidate_paths=`

**Step 2: 固定 today contract**

- `test_hygiene_candidate_paths=` 只统计：
  - runtime records
  - control files
  - output artifacts
  - binary artifacts
- `source_review_candidate_paths=` 只统计：
  - `src`
  - real test source
  - CI workflows
  - examples/build drift

**Step 3: 刷新 TESTING 与 docs consistency**

- 写清楚 retained-refs triage 的 today 顺序：
  - 先看 `recommendation=`
  - 再看 `next_focus=`
  - 如果是 `test-hygiene-first`，优先看 `test_hygiene_candidate_paths=`
  - 如果是 `source-review-first`，优先看 `source_review_candidate_paths=`
  - docs residue 则继续看 `docs_absorb_candidate_paths=`

### Task 3: 刷新 latest 入口、current-state audit 和 worker handoff

**Files:**
- Create: `docs/audits/2026-04-13-l0-retained-refs-eighth-focus-routing-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `workers/worker1.md`

**Step 1: 刷新 latest absorption 入口**

- `docs/README.md` / `docs/INDEX.md` 改为指向第八波 audit

**Step 2: 记录第八波结论**

- `sidecar/tail`：
  - 继续 `test-hygiene-first`
  - 现在有显式 `test_hygiene_candidate_paths=`
  - docs 侧仍继续使用 `docs_absorb_candidate_paths=`
- `closeout/rescue`：
  - 继续 `source-review-first`
  - 现在有显式 `source_review_candidate_paths=`

**Step 3: 更新 worker handoff**

- worker1 记录新的 source of truth、fresh verification 和下一跳建议

### Task 4: 跑完整验证并提交

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_docs_current_entry_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_focus_routing_contract.sh
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
- `sidecar/tail` 的 test-hygiene candidate 路径可复跑
- `closeout/rescue` 的 source-review candidate 路径可复跑

**Step 2: 提交**

```bash
git add docs/plans/2026-04-13-l0-retained-refs-eighth-focus-routing-plan.md \
  docs/audits/2026-04-13-l0-retained-refs-eighth-focus-routing-audit.md \
  docs/README.md docs/INDEX.md docs/TESTING.md \
  docs/audits/2026-04-11-l0-current-state-audit.md \
  workers/worker1.md tests/check_strict_l0_docs_consistency.sh \
  tests/report_strict_l0_retained_refs_inventory.sh \
  tests/test_strict_l0_retained_refs_inventory_focus_routing_contract.sh
git commit -m "feat(l0): absorb eighth retained refs routing wave"
```

Expected:

- 得到一组把 `test-hygiene-first` / `source-review-first` 变成可执行 retained-refs triage contract 的 docs-first 提交
