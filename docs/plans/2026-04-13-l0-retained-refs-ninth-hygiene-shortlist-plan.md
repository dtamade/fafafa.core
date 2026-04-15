# L0 Retained Refs Ninth Hygiene And Shortlist Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `sidecar/tail` 里已经明确属于低风险 test-hygiene 的跟踪产物实际从 `l0-mainline` 清掉，并给 `closeout/rescue` 补一条可执行的 source-review shortlist 入口。

**Architecture:** 这轮继续保持 non-destructive retained-refs 审计口径，不直接 broad merge 历史 refs。第一段只吸收 `archiver/atomic/fs/sync.barrier` 的安全 hygiene 变更：新增局部 `.gitignore`、删除误跟踪 runtime/output/binary 文件、补最小 README 说明。第二段新增一条 `closeout/rescue` 专用 shortlist 报表，按 `src / test code / test script / test doc / CI / examples-build / dangerous deletions` 拆开当前 diff，明确哪些是 review 候选、哪些必须拒绝整包吸收。最后刷新最新 audit、入口文档和 worker handoff。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 retained-refs audit / inventory scripts

---

### Task 1: 写 failing contract，锁定 hygiene absorb 结果

**Files:**
- Create: `tests/test_strict_l0_retained_refs_hygiene_absorption_contract.sh`
- Modify: `tests/fafafa.core.atomic/README.md`
- Create: `tests/fafafa.core.archiver/.gitignore`
- Create: `tests/fafafa.core.atomic/.gitignore`
- Create: `tests/fafafa.core.fs/performance-data/.gitignore`
- Create: `tests/fafafa.core.sync.barrier/.gitignore`

**Step 1: 先写 contract**

- contract 直接锁定：
  - 上面 4 个 `.gitignore` 文件存在
  - `tests/fafafa.core.archiver/last-run.txt` 不再被 git 跟踪
  - `tests/fafafa.core.atomic/tests_atomic` / `atomic_heaptrc_full_output.txt` 不再被 git 跟踪
  - `tests/fafafa.core.sync.barrier/*_output.txt` 不再被 git 跟踪
  - `tests/fafafa.core.fs/performance-data/latest.txt` / `perf_*latest.txt` / dated perf txt 不再被 git 跟踪
  - `tests/fafafa.core.atomic/README.md` 改成把 heaptrc/logs 视为运行期产物，不再把 tracked output 当支持材料

**Step 2: 运行，确认先失败**

Run:

```bash
bash tests/test_strict_l0_retained_refs_hygiene_absorption_contract.sh
```

Expected:

- FAIL，因为当前 tracked runtime/output files 还在版本库里

### Task 2: 落地 sidecar/tail 的实际 hygiene 吸收

**Files:**
- Create: `tests/fafafa.core.archiver/.gitignore`
- Create: `tests/fafafa.core.atomic/.gitignore`
- Create: `tests/fafafa.core.fs/performance-data/.gitignore`
- Create: `tests/fafafa.core.sync.barrier/.gitignore`
- Modify: `tests/fafafa.core.atomic/README.md`
- Delete: `tests/fafafa.core.archiver/last-run.txt`
- Delete: `tests/fafafa.core.atomic/atomic_heaptrc_full_output.txt`
- Delete: `tests/fafafa.core.atomic/tests_atomic`
- Delete: `tests/fafafa.core.sync.barrier/all_test_output.txt`
- Delete: `tests/fafafa.core.sync.barrier/barrier_heaptrc_full_output.txt`
- Delete: `tests/fafafa.core.sync.barrier/barrier_heaptrc_output.txt`
- Delete: `tests/fafafa.core.sync.barrier/global_test_output.txt`
- Delete: `tests/fafafa.core.sync.barrier/ibarrier_test_output.txt`
- Delete: `tests/fafafa.core.sync.barrier/test_output.txt`
- Delete: `tests/fafafa.core.fs/performance-data/latest.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_2025-08-12_周二-21-39.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-0-11.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-5-46.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-5-47.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-5-48.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-5-49.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_2025-08-15_周五-6-23.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_all_latest.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-22_周五_23-48-42-31.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-22_周五_23-53-46-16.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_00-00-25-01.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_00-25-20-68.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_00-28-57-48.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_03-43-38-75.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_resolve_2025-08-23_周六_04-09-47-10.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt`
- Delete: `tests/fafafa.core.fs/performance-data/perf_walk_latest.txt`

**Step 1: 最小实现 hygiene absorb**

- 仅清理明确是 runtime/output/binary residue 的 tracked 文件
- 不改 test source / build script / baseline 文件
- `.gitignore` 只覆盖这批本地运行产物，不扩大到 today contract 文件

**Step 2: 跑 contract 与代表性验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_hygiene_absorption_contract.sh
bash tests/fafafa.core.atomic/BuildOrTest.sh check
bash tests/fafafa.core.archiver/BuildOrTest.sh check
bash tests/fafafa.core.sync.barrier/BuildOrTest.sh build
```

Expected:

- hygiene contract PASS
- 代表性模块验证继续 PASS

### Task 3: 写 failing contract，锁定 source-review shortlist 工具

**Files:**
- Create: `tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
- Create: `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`

**Step 1: 先写 contract**

- 用 PATH stub 的 `git` 模拟 `HEAD..l0-mainline-closeout-20260411` 与 `HEAD..l0-main-rescue` 的 diff
- 锁定 shortlist 输出里必须有：
  - `review_candidate_paths=`
  - `dangerous_delete_paths=`
  - `src_review_paths=`
  - `test_code_review_paths=`
  - `test_script_review_paths=`
  - `test_doc_review_paths=`
  - `ci_review_paths=`
  - `examples_build_review_paths=`
  - `reject_wholesale_absorb=yes`
- contract 还要锁定典型危险删除（如 `tests/run_strict_l0_maintenance_loop.sh` / `.github/workflows/l0-linux-maintenance.yml`）会被单独暴露

**Step 2: 运行，确认先失败**

Run:

```bash
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
```

Expected:

- FAIL，因为 shortlist 脚本还不存在

### Task 4: 实现 shortlist 工具并刷新第九波 audit / current-entry

**Files:**
- Create: `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
- Create: `docs/audits/2026-04-13-l0-retained-refs-ninth-hygiene-shortlist-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `tests/test_strict_l0_legacy_docs_layout_contract.sh`
- Modify: `tests/update_strict_l0_current_state_docs.sh`
- Modify: `tests/test_update_strict_l0_current_state_docs_contract.sh`
- Modify: `workers/worker1.md`

**Step 1: 实现 shortlist 逻辑**

- 默认只处理：
  - `l0-mainline-closeout-20260411`
  - `l0-main-rescue`
- 使用 `git diff --name-status HEAD..ref`
- 分类输出：
  - `review_candidate_paths=`
  - `src_review_paths=`
  - `test_code_review_paths=`
  - `test_script_review_paths=`
  - `test_doc_review_paths=`
  - `ci_review_paths=`
  - `examples_build_review_paths=`
  - `dangerous_delete_paths=`
  - `reject_wholesale_absorb=yes|no`

**Step 2: 刷新 audit / docs / worker**

- 根入口切到第九波 audit
- 写清：
  - hygiene absorb 已真实落地
  - sidecar/tail 的 docs residue 当前主线已经有 landing zone，不再需要重复 broad absorb
  - closeout/rescue 继续禁止整包吸收，改走 shortlist-first

### Task 5: fresh 验证、retained-refs 审计与提交

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_hygiene_absorption_contract.sh
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/report_strict_l0_retained_refs_inventory.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/audit_strict_l0_retained_refs.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 全部 PASS
- shortlist 明确暴露 `closeout/rescue` 的 review surface 与危险删除
- retained refs audit 继续 non-destructive；若仍有 unique history，则明确保持 no-op

**Step 2: 提交**

```bash
git add docs/plans/2026-04-13-l0-retained-refs-ninth-hygiene-shortlist-plan.md \
  docs/audits/2026-04-13-l0-retained-refs-ninth-hygiene-shortlist-audit.md \
  docs/README.md docs/INDEX.md docs/TESTING.md \
  docs/audits/2026-04-11-l0-current-state-audit.md \
  workers/worker1.md tests/check_strict_l0_docs_consistency.sh \
  tests/update_strict_l0_current_state_docs.sh \
  tests/test_update_strict_l0_current_state_docs_contract.sh \
  tests/test_strict_l0_legacy_docs_layout_contract.sh \
  tests/test_strict_l0_retained_refs_hygiene_absorption_contract.sh \
  tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh \
  tests/report_strict_l0_retained_refs_source_review_shortlist.sh \
  tests/fafafa.core.archiver/.gitignore \
  tests/fafafa.core.atomic/.gitignore \
  tests/fafafa.core.fs/performance-data/.gitignore \
  tests/fafafa.core.sync.barrier/.gitignore \
  tests/fafafa.core.atomic/README.md
git commit -m "feat(l0): absorb ninth retained refs hygiene wave"
```

Expected:

- 得到一组把 `sidecar/tail` 的低风险 hygiene 真正落地、同时把 `closeout/rescue` 变成 shortlist-first 的第九波提交
