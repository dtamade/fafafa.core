# L0 Retained Refs Fourth Absorption Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 strict non-SIMD L0 retained refs 下一跳里已经浮出来的 `examples/build drift` 收敛成可执行的 inventory、文档入口和 hygiene contract，让后续吸收不再混着“示例源码 / 构建脚本 / 生成产物 / 测试产物”一起人工判断。

**Architecture:** 这轮继续坚持 docs-first、non-destructive、high-ROI。先给 retained-refs inventory 的 `--details` 模式补上 examples/build 细粒度 buckets，再补 examples current-entry README 与 `docs/EXAMPLES.md`，明确哪些文件是入口、哪些只是生成产物。最后更新第四波 absorption audit、根入口、worker handoff 和 docs consistency，并重跑 strict L0 maintenance loop。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 audit/maintenance scripts

---

### Task 1: 细化 retained-refs examples/build inventory

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_inventory.sh`
- Create: `tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh`
- Modify: `docs/TESTING.md`

**Step 1: 给 inventory 脚本补细粒度 buckets**

- 在 `--details` 输出里补：
  - `sample_example_source_paths=`
  - `sample_build_script_paths=`
  - `sample_generated_output_paths=`
  - `sample_test_artifact_paths=`
- 保持现有 top-level buckets 不变，避免破坏前 3 波 contract

**Step 2: 写 contract 锁定 examples/build 细节输出**

- 用 stub git 驱动 contract
- 验证 examples source / build scripts / generated outputs / test artifacts 都能独立出样本

**Step 3: 刷新 TESTING 文档**

- 写清楚 `--details` 现在不仅能看 representative path samples
- 还能把 examples/build drift 细分成更可执行的下一跳

### Task 2: 补 examples current-entry README 与 hygiene 文档

**Files:**
- Create: `examples/fafafa.core.base/README.md`
- Create: `examples/fafafa.core.option/README.md`
- Create: `examples/fafafa.core.env/README.md`
- Create: `examples/fafafa.core.sync.mutex/README.md`
- Modify: `examples/fafafa.core.json/README.md`
- Modify: `examples/fafafa.core.atomic/README.md`
- Modify: `docs/EXAMPLES.md`
- Create: `tests/test_strict_l0_examples_build_docs_contract.sh`

**Step 1: 给缺失的 example domains 补 README**

- 每份 README 明确：
  - 当前推荐运行入口
  - 主要示例源码
  - `bin/` / `lib/` 是生成产物，不是 source-of-truth

**Step 2: 给已有 README 补 hygiene 说明**

- `json` / `atomic` README 也统一说明：
  - `bin/` / `lib/` 只代表本地构建结果
  - current-entry 应回到 `.lpr` / `.lpi` / `BuildOrRun*` / 相关 docs

**Step 3: 重写 `docs/EXAMPLES.md` 的高 ROI 区段**

- 把这轮 inventory 暴露出来的 domain 先收紧成稳定入口：
  - `base`
  - `option`
  - `env`
  - `atomic`
  - `json`
  - `sync.mutex`
- 避免继续把临时日志、产物路径混进 current-entry

**Step 4: 写 contract**

- 验证 `docs/EXAMPLES.md` 和这些 README 的 today contract
- 锁定 “示例入口 != 生成产物”

### Task 3: 刷新第四波 absorption audit 与 strict L0 handoff

**Files:**
- Create: `docs/audits/2026-04-12-l0-retained-refs-fourth-absorption-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/audits/2026-04-12-l0-retained-refs-third-absorption-audit.md`
- Modify: `workers/worker1.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `tests/test_strict_l0_legacy_docs_layout_contract.sh`

**Step 1: 更新 latest absorption 入口**

- `docs/README.md` / `docs/INDEX.md` 改为指向第四波 audit

**Step 2: 记录第四波结论**

- examples/build drift 已被细分为：
  - example sources
  - build scripts
  - generated outputs
  - test artifacts
- 当前 examples current-entry 已经固定到具体 README / script / source 路径
- 下一跳如果还要吸收 retained refs，应优先看 examples source / build script 级差异，而不是生成产物

**Step 3: 更新 docs consistency 与 worker handoff**

- 把第四波 audit 和新 contract 接进 consistency
- worker1 记录最新 source of truth、fresh verification 和下一跳建议

### Task 4: 跑完整验证并提交

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh
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
- examples/build 细粒度 inventory contract 通过
- examples current-entry / hygiene contract 通过
- latest absorption 入口更新为第四波

**Step 2: 提交**

```bash
git add docs/plans/2026-04-12-l0-retained-refs-fourth-absorption-plan.md \
  tests/report_strict_l0_retained_refs_inventory.sh \
  tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh \
  tests/test_strict_l0_examples_build_docs_contract.sh \
  docs/EXAMPLES.md docs/TESTING.md docs/README.md docs/INDEX.md \
  docs/audits/2026-04-11-l0-current-state-audit.md \
  docs/audits/2026-04-12-l0-retained-refs-third-absorption-audit.md \
  docs/audits/2026-04-12-l0-retained-refs-fourth-absorption-audit.md \
  workers/worker1.md tests/check_strict_l0_docs_consistency.sh \
  tests/test_strict_l0_legacy_docs_layout_contract.sh \
  examples/fafafa.core.base/README.md examples/fafafa.core.option/README.md \
  examples/fafafa.core.env/README.md examples/fafafa.core.sync.mutex/README.md \
  examples/fafafa.core.json/README.md examples/fafafa.core.atomic/README.md
git commit -m "feat(l0): absorb fourth retained refs examples wave"
```

Expected:

- 得到一组 examples/build docs-first wave 的独立提交
