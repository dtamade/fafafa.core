# L0 Retained Refs Third Absorption Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `collections` 域里已经明确 superseded 的 dated docs 下沉到领域内 `legacy` 目录，同时修正当前 collections module docs 里的旧路径和旧导航，继续为 retained refs 的 docs-first 吸收做低风险收口。

**Architecture:** 这轮继续 docs-only、non-destructive。先用 layout contract 锁定 `docs/collections/legacy/` 的 today contract，再把 `2025-11-03` 这批 collections plans/status/reviews 从 `docs/collections/{plans,status,reviews}/` 迁到 `docs/collections/legacy/`。随后刷新 `docs/fafafa.core.collections.md` 作为 current-entry，补一个 `docs/collections/legacy/README.md` 作为历史导航页，并顺手修正 `arr` / `vec` / `vecdeque` / `README_VecDeque` 中已经失效的旧文档路径。最后更新 retained-refs 第三波审计、`worker1` handoff 和 strict L0 docs consistency，再重跑 inventory / audit / maintenance loop。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 audit/maintenance scripts

---

### Task 1: 先写 collections legacy layout contract

**Files:**
- Create: `tests/test_strict_l0_collections_legacy_docs_layout_contract.sh`

**Step 1: 写 failing contract**

- 校验以下 today contract：
  - `docs/collections/legacy/README.md` 存在
  - 一批 dated collections docs 已移动到 `docs/collections/legacy/`
  - 对应旧路径已不存在
  - `docs/fafafa.core.collections.md` 指向 `docs/collections/legacy/README.md`
  - `docs/fafafa.core.collections.arr.md`、`docs/fafafa.core.collections.vec.md`、`docs/fafafa.core.collections.vecdeque.md`、`docs/collections/guides/README_VecDeque.md` 不再引用失效旧路径

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_collections_legacy_docs_layout_contract.sh
```

Expected:

- 因 legacy 目录和修正后的导航尚不存在而 FAIL

### Task 2: 下沉 dated collections docs

**Files:**
- Move: `docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md -> docs/collections/legacy/COLLECTIONS_REFINEMENT_PLAN.md`
- Move: `docs/collections/plans/COLLECTIONS_NEW_CONTAINERS_PLAN_2025-11-03.md -> docs/collections/legacy/COLLECTIONS_NEW_CONTAINERS_PLAN_2025-11-03.md`
- Move: `docs/collections/status/COLLECTIONS_CURRENT_STATUS_2025-11-03.md -> docs/collections/legacy/COLLECTIONS_CURRENT_STATUS_2025-11-03.md`
- Move: `docs/collections/status/COLLECTIONS_OVERVIEW_2025-11-03.md -> docs/collections/legacy/COLLECTIONS_OVERVIEW_2025-11-03.md`
- Move: `docs/collections/reviews/COLLECTIONS_API_CONSISTENCY_REVIEW_2025-11-03.md -> docs/collections/legacy/COLLECTIONS_API_CONSISTENCY_REVIEW_2025-11-03.md`
- Move: `docs/collections/reviews/COLLECTIONS_CODE_QUALITY_REVIEW_2025-11-03.md -> docs/collections/legacy/COLLECTIONS_CODE_QUALITY_REVIEW_2025-11-03.md`
- Create: `docs/collections/legacy/README.md`

**Step 1: 迁移文件**

- 只迁移已经明确带日期或明显阶段性语境的 collections docs
- 不动 `COLLECTIONS_DECISION_TREE.md`、`COLLECTIONS_API_REFERENCE.md`、`COLLECTIONS_BEST_PRACTICES.md` 这类仍可能承载 current guidance 的文档

**Step 2: 给 legacy 文件补历史说明**

- 必要时在 moved docs 顶部加归档说明，明确它们不再是 current-entry

**Step 3: 写 legacy README**

- 列出这批历史计划、状态和审查文档
- 明确当前应优先看哪些 collections 文档

### Task 3: 修当前 collections 文档导航

**Files:**
- Modify: `docs/fafafa.core.collections.md`
- Modify: `docs/fafafa.core.collections.arr.md`
- Modify: `docs/fafafa.core.collections.vec.md`
- Modify: `docs/fafafa.core.collections.vecdeque.md`
- Modify: `docs/collections/guides/README_VecDeque.md`

**Step 1: 刷新 current-entry**

- `docs/fafafa.core.collections.md` 明确：
  - 当前 collections current-entry 是 root module docs + guides/design
  - 历史批次 docs 统一看 `docs/collections/legacy/README.md`

**Step 2: 修正旧路径**

- 把 `docs/UnChecked_Methods_Summary.md` 改成 `docs/collections/guides/UnChecked_Methods_Summary.md`
- 把 `docs/TVecDeque_Guide.md` 改成 `docs/collections/guides/TVecDeque_Guide.md`
- 其他仍然指向旧 `docs/...` 根路径的 collections docs 一并修正

### Task 4: 刷新 retained-refs 第三波审计与 handoff

**Files:**
- Create: `docs/audits/2026-04-12-l0-retained-refs-third-absorption-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/audits/2026-04-12-l0-retained-refs-second-absorption-audit.md`
- Modify: `workers/worker1.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`

**Step 1: 更新 latest absorption 入口**

- `docs/README.md` / `docs/INDEX.md` 改为指向第三波 absorption audit

**Step 2: 记录第三波结论**

- collections docs-only 下沉了哪些文件
- root current-entry review 的结论
- fresh inventory `--details` 暴露的下一跳是否已经从 collections dated docs 继续向 examples/build 漂移推进

**Step 3: 更新 worker handoff**

- 记录第三波新增 contract
- 记录 fresh verification
- 记录下一跳更适合转到 examples/build drift

### Task 5: 跑完整验证并提交

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_collections_legacy_docs_layout_contract.sh
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
- collections legacy layout contract 通过
- latest absorption 入口更新为第三波
- retained refs triage 继续保持 non-destructive

**Step 2: 提交**

```bash
git add docs/plans/2026-04-12-l0-retained-refs-third-absorption-plan.md \
  tests/test_strict_l0_collections_legacy_docs_layout_contract.sh \
  docs/collections/legacy docs/fafafa.core.collections.md \
  docs/fafafa.core.collections.arr.md docs/fafafa.core.collections.vec.md \
  docs/fafafa.core.collections.vecdeque.md docs/collections/guides/README_VecDeque.md \
  docs/README.md docs/INDEX.md docs/audits/2026-04-11-l0-current-state-audit.md \
  docs/audits/2026-04-12-l0-retained-refs-second-absorption-audit.md \
  docs/audits/2026-04-12-l0-retained-refs-third-absorption-audit.md \
  workers/worker1.md tests/check_strict_l0_docs_consistency.sh
git commit -m "feat(l0): absorb third retained refs collections docs wave"
```

Expected:

- 得到一组 collections docs-only wave 的独立提交
