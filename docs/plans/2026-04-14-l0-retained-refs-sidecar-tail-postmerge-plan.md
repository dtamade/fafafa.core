# L0 Retained Refs Sidecar Tail Postmerge Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 merged-main 之后继续收紧 strict non-SIMD L0 的 retained refs 管理：先吸收 `sidecar` 里一批仍未覆盖的低风险 runtime hygiene，再补一个专门面向 `sidecar/tail` 的 post-merge overlap 报表，把“当前还能不能删 ref、各自还剩什么独占批次”收敛成可复跑结论。

**Architecture:** 这轮继续保持 non-destructive、shortlist-first，不做 broad merge。第一段只处理 `tests/fafafa.core.env/` 与 `tests/fafafa.core.mem.manager.rtl/` 里的 sidecar runtime residue：新增局部 `.gitignore`，删除误跟踪日志/heaptrc 产物，并用 contract 锁住 today hygiene 语义。第二段新增 `sidecar/tail` pairwise overlap 报表与 contract，固定输出 shared merge-base、各自 exclusive commit 计数、exclusive path buckets 与 `safe_delete_*_now=` 结论；随后刷新最新 audit、README/INDEX、TESTING、current-state audit 和 worker handoff。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, existing strict L0 retained-refs audit / docs consistency scripts

---

### Task 1: 吸收 sidecar 的低风险 runtime hygiene 小批次

**Files:**
- Create: `tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh`
- Create: `tests/fafafa.core.env/.gitignore`
- Create: `tests/fafafa.core.mem.manager.rtl/.gitignore`
- Delete: `tests/fafafa.core.env/build_log.txt`
- Delete: `tests/fafafa.core.env/fpcdebug.txt`
- Delete: `tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt`

**Step 1: 先写 contract**

- 锁定：
  - `tests/fafafa.core.env/.gitignore` 必须存在，且包含 `build_log.txt` 与 `fpcdebug.txt`
  - `tests/fafafa.core.mem.manager.rtl/.gitignore` 必须存在，且包含 `mem_manager_heaptrc_output.txt`
  - 上面 3 个 runtime/output 文件不再被 git 跟踪

**Step 2: 落地最小 absorb**

- 不改任何 test source / public API / current-entry docs
- 只处理 sidecar 明确还没被主线覆盖的 runtime residue

**Step 3: 跑代表性验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh
bash tests/fafafa.core.env/BuildOrTest.sh build
bash tests/fafafa.core.mem.manager.rtl/BuildOrTest.sh check
```

Expected:

- hygiene contract PASS
- 代表性模块构建 / 检查继续 PASS

### Task 2: 新增 sidecar/tail post-merge overlap 报表与 contract

**Files:**
- Create: `tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
- Create: `tests/test_strict_l0_retained_refs_sidecar_tail_overlap_contract.sh`

**Step 1: 先写 failing contract**

- 用 PATH stub 的 `git` 锁定：
  - `current_head=`
  - `sidecar_tail_merge_base=`
  - `sidecar_only_commit_count=`
  - `tail_only_commit_count=`
  - `sidecar_safe_delete_now=`
  - `tail_safe_delete_now=`
  - `pairwise_decision=`
  - `pairwise_cleanup_readiness=`
  - `sample_sidecar_only_commits=`
  - `sample_tail_only_commits=`
  - 至少一组 `*_docs_paths=`、`*_test_runner_paths=`、`*_example_runner_paths=`、`*_src_paths=`、`*_worker_paths=` 分类输出

**Step 2: 实现报表**

- 固定只比较：
  - `l0-sidecar-handoff-20260409`
  - `l0-main-tail-cleanup-20260408-final`
- 使用：
  - `git merge-base`
  - `git cherry -v <left> <right>`
  - `git show --name-only --format= <sha>`
- 输出 today policy：
  - 哪一边还有 exclusive commits
  - 哪一边当前还不能删
  - exclusive batch 更接近 runner/test hygiene 还是 src/docs/control-plane

**Step 3: 跑 contract 与实仓 fresh 报表**

Run:

```bash
bash tests/test_strict_l0_retained_refs_sidecar_tail_overlap_contract.sh
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
```

Expected:

- overlap contract PASS
- real report 明确 `sidecar` / `tail` 目前都还不能安全删除

### Task 3: 刷新 post-merge retained-refs audit 与入口文档

**Files:**
- Create: `docs/audits/2026-04-14-l0-retained-refs-sidecar-tail-postmerge-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `workers/worker1.md`

**Step 1: 写最新 audit**

- 写清：
  - merged-main 之后，inventory 的 `test-hygiene-first` 仍然只是 absorb-class 指示，不等于 today ref-delete readiness
  - `sidecar` 新吸收了 env/mem.manager.rtl hygiene residue
  - `sidecar/tail` 的 pairwise overlap 现在有单独入口
  - fresh 结果下两条 ref 仍然不能删

**Step 2: 刷新 README / INDEX / TESTING / current-state / worker**

- README / INDEX：
  - latest retained-refs audit 切到这份 post-merge audit
  - 新增 overlap 报表入口
- TESTING：
  - 明确 inventory 与 overlap 的职责边界
- current-state / worker：
  - 记录 latest overlap 结论与新的 low-risk hygiene absorb

### Task 4: 对齐 docs consistency / current-state docs updater

**Files:**
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `tests/update_strict_l0_current_state_docs.sh`
- Modify: `tests/test_update_strict_l0_current_state_docs_contract.sh`

**Step 1: 更新 docs consistency**

- required files 增加：
  - 新 plan
  - 新 audit
  - 新 overlap 报表
  - 新 overlap contract
  - 新 sidecar hygiene contract
- README / INDEX / TESTING / current-state / worker 的 required literal 与 latest retained-refs audit 入口同步到第 2026-04-14 波

**Step 2: 更新 current-state docs updater**

- 自动生成的 current-state audit / worker handoff 也要带上：
  - `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
  - `bash tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh`
  - post-merge overlap 的 today policy

### Task 5: 跑完整验证并收口

**Files:**
- Verify and commit

**Step 1: 跑验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh
bash tests/fafafa.core.env/BuildOrTest.sh build
bash tests/fafafa.core.mem.manager.rtl/BuildOrTest.sh check
bash tests/test_strict_l0_retained_refs_sidecar_tail_overlap_contract.sh
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
bash tests/audit_strict_l0_retained_refs.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 全部 PASS
- current-entry docs 与 worker handoff 对 post-merge retained-refs cleanup 的说明一致
- `sidecar` / `tail` 仍明确保持 no broad merge / no blind delete

**Step 2: 提交**

```bash
git add docs/plans/2026-04-14-l0-retained-refs-sidecar-tail-postmerge-plan.md \
  docs/audits/2026-04-14-l0-retained-refs-sidecar-tail-postmerge-audit.md \
  docs/README.md docs/INDEX.md docs/TESTING.md \
  docs/audits/2026-04-11-l0-current-state-audit.md \
  workers/worker1.md \
  tests/check_strict_l0_docs_consistency.sh \
  tests/update_strict_l0_current_state_docs.sh \
  tests/test_update_strict_l0_current_state_docs_contract.sh \
  tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh \
  tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh \
  tests/test_strict_l0_retained_refs_sidecar_tail_overlap_contract.sh \
  tests/fafafa.core.env/.gitignore \
  tests/fafafa.core.mem.manager.rtl/.gitignore
git commit -m "feat(l0): tighten sidecar tail postmerge cleanup"
```
