# L0 Productivity Wave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在唯一 L0 worktree 上完成一波 strict non-SIMD L0 的高效率收敛，覆盖 closeout 小波、atomic-first rescue 小波、post-merge docs backfill e2e hardening、CI 控制面降噪，以及 span2/segmented-span 后续设计落盘。

**Architecture:** 先保持 strict L0 边界不扩散，不碰 SIMD，不做 retained refs broad absorb。实现上把工作拆成 5 个互不冲突的写集：mem allocator closeout、atomic rescue、docs updater / closeout automation contract、workflow control-plane、roadmap/design docs；最后统一回到 L0 worktree 做集成验证。

**Tech Stack:** Free Pascal, Bash contracts, GitHub Actions YAML, Markdown docs, Git retained-ref triage scripts.

---

### Task 1: Closeout retained-ref mem allocator shortlist wave

**Files:**
- Modify: `src/fafafa.core.mem.allocator.pas`
- Modify: `src/fafafa.core.mem.allocator.callbackAllocator.pas`
- Modify: `tests/fafafa.core.mem.allocator.foundation/test_allocator_foundation_runtime.pas`
- Test: `tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh`
- Reference: `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
- Reference: `tests/fafafa.core.mem.allocator.foundation/README.md`

**Steps:**
1. 用 `l0-mainline-closeout-20260411` 的 shortlist 结果确认只处理 allocator 相关 code/test，不吸收 stale test docs。
2. 先在 `test_allocator_foundation_runtime.pas` 补一个会锁住 current allocator contract 的失败用例。
3. 运行 `bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test`，确认新用例先失败或暴露当前缺口。
4. 对 `fafafa.core.mem.allocator.pas` 和 `fafafa.core.mem.allocator.callbackAllocator.pas` 做最小修复，只吸收 strict L0 today contract 需要的语义。
5. 重新运行 `bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test`。
6. 再运行 `bash tests/fafafa.core.mem/BuildOrTest.sh test-no-contracts`，确认没有把 broader mem facade 烧坏。

### Task 2: Rescue retained-ref atomic-first source-review wave

**Files:**
- Modify: `src/fafafa.core.atomic.core.pas`
- Modify: `src/fafafa.core.atomic.pas`
- Modify: `src/fafafa.core.atomic.base.pas`
- Modify: `tests/fafafa.core.atomic/Test_fafafa.core.atomic.core.contract.pas`
- Modify: `tests/fafafa.core.atomic/Test_fafafa.core.atomic.pas`
- Modify: `tests/fafafa.core.atomic/Test_fafafa.core.atomic.compat.contract.pas`
- Optional: `examples/fafafa.core.atomic/BuildOrRun.sh`
- Reference: `docs/fafafa.core.atomic.md`
- Reference: `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`

**Steps:**
1. 把 `l0-main-rescue` 的 source-review 波次限定在 atomic today contract，不碰 SIMD，也不顺带吸收 platform / mem 以外的面。
2. 先为 atomic core/raw/compat 的 today contract 补一个失败测试或 tightening assertion。
3. 运行 `bash tests/fafafa.core.atomic/BuildOrTest.sh test`，确认失败点稳定。
4. 在 `atomic.core`、`atomic`、`atomic.base` 中做最小修复。
5. 重新运行 `bash tests/fafafa.core.atomic/BuildOrTest.sh test`。
6. 如果改动影响 example entrypoint，再运行 `bash examples/fafafa.core.atomic/BuildOrRun.sh build` 做 smoke。

### Task 3: Harden merged-main docs backfill and closeout automation

**Files:**
- Modify: `tests/update_strict_l0_current_state_docs.sh`
- Modify: `tests/run_strict_l0_mainline_closeout.sh`
- Create or Modify: `tests/test_update_strict_l0_current_state_docs_contract.sh`
- Create: `tests/test_strict_l0_mainline_closeout_postmerge_contract.sh`
- Reference: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Reference: `docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md`
- Reference: `workers/worker1.md`

**Steps:**
1. 先写 merged-main mismatch-posture 的失败 contract：main SHA 前进、Windows exact SHA 仍滞后、docs 不能缩水。
2. 用 temp target root 运行 `tests/update_strict_l0_current_state_docs.sh`，确认 contract 先失败。
3. 如有需要，补强 `run_strict_l0_mainline_closeout.sh` 的参数校验与 post-merge docs apply 语义。
4. 让 updater 在重写文档时保留 `--details` / shortlist-first / docs landing-zone / dangerous-delete 这些 today contract。
5. 运行：
   - `bash tests/test_update_strict_l0_current_state_docs_contract.sh`
   - `bash tests/test_strict_l0_mainline_closeout_postmerge_contract.sh`
   - `bash tests/check_strict_l0_docs_consistency.sh`

### Task 4: Reduce GitHub Actions control-plane noise

**Files:**
- Modify: `.github/workflows/l0-linux-maintenance.yml`
- Modify: `.github/workflows/l0-windows-native-evidence.yml`
- Optional: `docs/CI.md`
- Optional: `tests/lib_github_actions_workflow_runs.sh`

**Steps:**
1. 基于最新 `main` run 的 warning，把 Node 20 deprecation 噪音降掉，但不改变 strict L0 语义。
2. 审视 Linux maintenance workflow 的 checkout / post 阶段 `git exit 128` 注记，确认它是可消除的控制面噪音而不是功能失败。
3. 做最小 workflow patch，优先保持行为等价。
4. 运行本地 contract：
   - `bash tests/test_strict_l0_linux_ci_workflow_contract.sh`
   - `bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
5. 如涉及文档入口变化，再更新 `docs/CI.md`。

### Task 5: Record segmented span / span2 next-step design

**Files:**
- Modify: `docs/fafafa.core.l0.foundation.md`
- Modify: `docs/fafafa.core.l0.roadmap.md`
- Create: `docs/plans/2026-04-14-l0-segmented-span-evaluation-plan.md`
- Reference: `docs/legacy/l0/fafafa.core.l0.merge-closeout.md`
- Reference: `docs/fafafa.core.atomic.md`

**Steps:**
1. 不写实现代码，先把 `segmented span / span2` 的准入条件、排除条件和依赖约束写清。
2. 在 roadmap 里明确这不是“马上并入 strict L0”，而是一个有边界的评估波次。
3. 单独落一个 evaluation plan，写明：
   - 候选 API 面
   - 与 `collections` / deque 双段视图的关系
   - 不得回流为服务层或容器层语义
4. 运行 `bash tests/check_strict_l0_docs_consistency.sh`，确认稳定文档入口不被破坏。

### Final Integration

**Files:**
- Modify: `workers/worker1.md`
- Optional: relevant docs/audits if current-state needs checkpoint

**Steps:**
1. 集成所有不冲突的 worker 结果。
2. 运行：
   - `git diff --check`
   - `bash tests/check_strict_l0_docs_consistency.sh`
   - `bash tests/test_strict_l0_docs_consistency_contract.sh`
   - `bash tests/test_strict_l0_stable_docs_no_sha_contract.sh`
   - `bash tests/run_strict_l0_maintenance_loop.sh`
3. 如果 workflow 文件有变化，再补跑相关 workflow contract。
4. 更新 `workers/worker1.md` 的 current focus / fresh verification / next step。
5. 用一到多笔清晰 commit 收口；保持 `l0-mainline` 作为唯一 L0 worktree 分支，不动 SIMD。
