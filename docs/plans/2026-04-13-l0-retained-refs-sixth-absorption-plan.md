# L0 Retained Refs Sixth Absorption Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 继续把 strict non-SIMD L0 retained refs 的 `sidecar/tail` 下一跳从“混着测试源码和测试残留”收紧成更可执行的 inventory、follow-up 建议和 latest docs。

**Architecture:** 这轮继续坚持 docs-first、non-destructive、high-ROI，只做 retained-refs inventory、contract、audit 和 current-entry 文档，不改 `src/` 行为。先把 `tests/*` 里的真实测试源码与 `.gitignore`、performance records、output logs、无扩展名测试二进制进一步拆开，再让 inventory 直接输出 `next_focus=` 级别的下一跳建议，最后刷新第六波审计、根入口、worker handoff 和 docs consistency。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 audit/maintenance scripts

---

### Task 1: 先写 retained-refs test-hygiene contract

**Files:**
- Create: `tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh`
- Test: `tests/report_strict_l0_retained_refs_inventory.sh`

**Step 1: 写 failing contract**

- 用 PATH stub 的 `git` 模拟 retained refs unique history，覆盖：
  - `test_code_paths=`
  - `test_script_paths=`
  - `test_doc_paths=`
  - `test_runtime_record_paths=`
  - `test_control_paths=`
  - `test_output_artifact_paths=`
  - `test_binary_artifact_paths=`
  - `next_focus=`
- contract 还要锁定 `sample_*` 输出，确保 sidecar/tail 后续 triage 不再靠肉眼翻全部路径。

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh
```

Expected:

- 因目标脚本还没输出新 bucket / `next_focus` 而 FAIL

### Task 2: 实现 retained-refs test-hygiene 细分与 next-focus

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_inventory.sh`
- Modify: `tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh`
- Modify: `docs/TESTING.md`

**Step 1: 细化 tests bucket**

- 在 `--details` 输出里补：
  - `test_code_paths=`
  - `test_script_paths=`
  - `test_doc_paths=`
  - `test_runtime_record_paths=`
  - `test_control_paths=`
  - `test_output_artifact_paths=`
  - `test_binary_artifact_paths=`
  - 对应 `sample_*`
- 保持现有 top-level bucket：
  - `code_or_tests_paths=`
  - `test_source_paths=`
  - `test_artifact_paths=`
- 但把 `test_source_paths=` 收紧为真实 test source surface，不再混入 runtime records / control files

**Step 2: 给 inventory 补下一跳建议**

- 保持原有 `recommendation=` 不变
- 新增 `next_focus=`，至少支持：
  - `archive-docs-first`
  - `test-hygiene-first`
  - `source-review-first`
  - `current-docs-first`
- 让 `sidecar/tail` 在 fresh inventory 下直接落到 `test-hygiene-first`

**Step 3: 刷新 TESTING 文档**

- 写清楚 `--details` 现在如何继续拆：
  - 真实测试源码
  - runtime records
  - control files
  - output / binary artifacts
- 写清楚 `next_focus=` 是下一跳 triage 的 today contract

### Task 3: 刷新第六波 audit、根入口和 worker handoff

**Files:**
- Create: `docs/audits/2026-04-13-l0-retained-refs-sixth-absorption-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/audits/2026-04-13-l0-retained-refs-fifth-absorption-audit.md`
- Modify: `workers/worker1.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `tests/test_strict_l0_legacy_docs_layout_contract.sh`

**Step 1: 更新 latest absorption 入口**

- `docs/README.md` / `docs/INDEX.md` 改为指向第六波 audit

**Step 2: 记录第六波结论**

- sidecar / tail 现在已经能明确拆出：
  - test code
  - test scripts
  - test docs
  - runtime records
  - control files
  - output artifacts
  - binary artifacts
- 记录 fresh `next_focus=` 结果，把 sidecar / tail 的下一跳锁成 `test-hygiene-first`

**Step 3: 更新 docs consistency 与 worker handoff**

- 把第六波 audit、计划和新的 contract 接进 consistency
- worker1 记录最新 source of truth、fresh verification 和下一跳建议

### Task 4: 跑完整验证并提交

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh
bash tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh
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
- sidecar / tail 的 `test-hygiene-first` 建议可复跑
- latest absorption 入口更新为第六波

**Step 2: 提交**

```bash
git add docs/plans/2026-04-13-l0-retained-refs-sixth-absorption-plan.md \
  docs/audits/2026-04-13-l0-retained-refs-sixth-absorption-audit.md \
  docs/README.md docs/INDEX.md docs/TESTING.md \
  docs/audits/2026-04-11-l0-current-state-audit.md \
  docs/audits/2026-04-13-l0-retained-refs-fifth-absorption-audit.md \
  workers/worker1.md tests/check_strict_l0_docs_consistency.sh \
  tests/test_strict_l0_legacy_docs_layout_contract.sh \
  tests/report_strict_l0_retained_refs_inventory.sh \
  tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh \
  tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh
git commit -m "feat(l0): absorb sixth retained refs hygiene wave"
```

Expected:

- 得到一组继续压低 sidecar/tail retained-refs triage 成本的 docs-first/hygiene wave 提交
