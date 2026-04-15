# L0 Retained Refs Fifth Absorption Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 继续把 strict non-SIMD L0 retained refs 的下一跳从“混杂路径清单”收口成更可执行的 inventory、examples current-entry 和 test-artifact hygiene 约束。

**Architecture:** 这轮继续坚持 docs-first、non-destructive、high-ROI。先把 retained-refs inventory 的 `code_or_tests` 再细分成 `src` / `test source` / `test artifact` / `CI workflow`，避免 test outputs 继续伪装成“代码差异”。再把 strict L0 examples current-entry 从上一波的 `base/option/env/atomic/json/sync.mutex` 扩到 `result/platform`，最后刷新第五波 audit、根入口、worker handoff 和 docs consistency。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 audit/maintenance scripts

---

### Task 1: 细化 retained-refs 的 code/tests inventory

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_inventory.sh`
- Create: `tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh`
- Modify: `docs/TESTING.md`

**Step 1: 给 `code_or_tests` 补细粒度 buckets**

- 在 `--details` 输出里补：
  - `src_paths=`
  - `test_source_paths=`
  - `ci_workflow_paths=`
  - `test_artifact_paths=`（继续保留，但从“附属观察值”升级成稳定细粒度 bucket）
  - 以及对应 `sample_*`
- 保持现有 top-level buckets 不变，避免破坏已有 inventory contract

**Step 2: 写 focused contract 锁定 code/tests 细节输出**

- 用 stub git 驱动 contract
- 验证 `src`、`tests` 源码、`tests` 产物、`.github` workflow 都能独立落入正确 bucket

**Step 3: 刷新 TESTING 文档**

- 写清楚 `--details` 现在不仅细分 examples/build
- 也会继续把 `code_or_tests` 细分成更可执行的下一跳

### Task 2: 把 strict L0 examples current-entry 扩到 result/platform

**Files:**
- Create: `examples/fafafa.core.result/README.md`
- Modify: `examples/fafafa.core.platform/README.md`
- Modify: `docs/EXAMPLES.md`
- Modify: `tests/test_strict_l0_examples_build_docs_contract.sh`

**Step 1: 给 `result` example domain 补 README**

- README 明确：
  - Linux/macOS 当前入口 `BuildOrRun.sh`
  - Windows 当前入口 `BuildOrRun.bat`
  - 推荐先跑的 `.lpr` / `.lpi`
  - `bin/` / `lib/` 只是生成产物，不是 source-of-truth

**Step 2: 刷新 `platform` example README**

- 统一成 current-entry README 风格
- 明确 `BuildOrRun*` / `.lpr` / `.lpi` 才是入口
- 补 `bin/` / `lib/` 不是 source-of-truth 的 hygiene 说明

**Step 3: 更新 `docs/EXAMPLES.md` 的 strict L0 区段**

- 在已有：
  - `base`
  - `option`
  - `env`
  - `atomic`
  - `json`
  - `sync.mutex`
- 基础上补：
  - `result`
  - `platform`

**Step 4: 扩 examples/build docs contract**

- 锁定 `docs/EXAMPLES.md` 与 `result/platform` README 的 today contract
- 保持“example current-entry != generated outputs”的纪律

### Task 3: 刷新第五波 absorption audit 与 strict L0 handoff

**Files:**
- Create: `docs/audits/2026-04-13-l0-retained-refs-fifth-absorption-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/audits/2026-04-12-l0-retained-refs-fourth-absorption-audit.md`
- Modify: `workers/worker1.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `tests/test_strict_l0_legacy_docs_layout_contract.sh`

**Step 1: 更新 latest absorption 入口**

- `docs/README.md` / `docs/INDEX.md` 改为指向第五波 audit

**Step 2: 记录第五波结论**

- retained-refs inventory 现在能把 `code_or_tests` 继续细分成：
  - `src`
  - `test source`
  - `test artifact`
  - `CI workflow`
- strict L0 examples current-entry 现在扩到了：
  - `result`
  - `platform`
- 下一跳如果还要吸收 retained refs，应优先把 sidecar / tail 上的 test artifacts 和 example/build drift 分开吸收

**Step 3: 更新 docs consistency 与 worker handoff**

- 把第五波 audit、`result` README 和新的 inventory contract 接进 consistency
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
- retained-refs code/tests 细粒度 inventory contract 通过
- strict L0 examples current-entry 扩展到 `result/platform`
- latest absorption 入口更新为第五波

**Step 2: 提交**

```bash
git add docs/plans/2026-04-13-l0-retained-refs-fifth-absorption-plan.md \
  docs/audits/2026-04-13-l0-retained-refs-fifth-absorption-audit.md \
  docs/README.md docs/INDEX.md docs/EXAMPLES.md docs/TESTING.md \
  docs/audits/2026-04-11-l0-current-state-audit.md \
  docs/audits/2026-04-12-l0-retained-refs-fourth-absorption-audit.md \
  workers/worker1.md tests/check_strict_l0_docs_consistency.sh \
  tests/test_strict_l0_legacy_docs_layout_contract.sh \
  tests/report_strict_l0_retained_refs_inventory.sh \
  tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh \
  tests/test_strict_l0_examples_build_docs_contract.sh \
  examples/fafafa.core.result/README.md \
  examples/fafafa.core.platform/README.md
git commit -m "feat(l0): absorb fifth retained refs hygiene wave"
```

Expected:

- 得到一组继续压低 retained-refs triage 成本的 docs-first/hygiene wave 提交
