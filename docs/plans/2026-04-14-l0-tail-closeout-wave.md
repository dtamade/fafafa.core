# L0 Tail Closeout Wave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 strict non-SIMD L0 worktree 中继续 non-destructive 地吸收 `l0-main-tail-cleanup-20260408-final` 的高 ROI 独占历史，按 `checkpoint -> docs/control-plane -> test normalization -> src review -> closeout verification` 的顺序把 tail 收到最小。

**Architecture:** 这一波继续坚持 shortlist-first，不做 broad merge，也不碰 `simd`。先把已经完成并通过验证的 shell/runner hygiene 独立提交成 checkpoint，降低后续审查噪音；然后按风险从低到高吸收 `tail` 独占批次：先 docs/control-plane，再 test entry/test normalization，最后只处理 overlap 里仍独占的 `src/fafafa.core.span.pas` 与 `src/fafafa.core.atomic.base.pas`。每一段都跑对应的 targeted verification，最后再跑完整 strict L0 maintenance loop 收口。

**Tech Stack:** Bash, git, ripgrep, Markdown docs, Pascal/Lazarus test modules, existing strict L0 retained-refs audit / overlap / maintenance scripts

---

### Task 1: 提交当前 shell/runner hygiene checkpoint

**Files:**
- Modify: current uncommitted shell hygiene/docs consistency files
- Verify: `tests/test_active_shell_runners.sh`
- Verify: `tests/test_fs_perf_shell_scripts.sh`
- Verify: `tests/run_strict_l0_maintenance_loop.sh`

**Step 1: 复核当前 checkpoint 范围**

Run:

```bash
git status --short
bash tests/test_active_shell_runners.sh
bash tests/test_fs_perf_shell_scripts.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
```

Expected:

- 只包含本波 shell/runner hygiene 与 docs/worker/updater 同步
- contract / docs consistency 继续 PASS

**Step 2: 提交 checkpoint**

Run:

```bash
git add docs/CI.md docs/INDEX.md docs/TESTING.md docs/audits/2026-04-11-l0-current-state-audit.md docs/fafafa.core.fs.md docs/plans/2026-04-14-l0-tail-closeout-wave.md tests/check_strict_l0_docs_consistency.sh tests/cleanup_orphan_dirs.sh tests/fafafa.core.fs/ArchivePerfResult.sh tests/fafafa.core.fs/BuildOrRunPerf.sh tests/fafafa.core.fs/BuildOrRunPerfAll.sh tests/fafafa.core.fs/BuildOrRunResolvePerf.sh tests/fafafa.core.fs/README-perf.md tests/run_strict_l0_maintenance_loop.sh tests/test_active_shell_runners.sh tests/test_fs_perf_shell_scripts.sh tests/test_strict_l0_maintenance_loop_contract.sh tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh tests/test_update_strict_l0_current_state_docs_contract.sh tests/update_strict_l0_current_state_docs.sh workers/worker1.md
git commit -m "test(l0): harden active shell runners and fs perf wrappers"
```

Expected:

- 当前 shell hygiene 独立成一个可审查 checkpoint

### Task 2: 吸收 tail 的 docs/control-plane 独占批次

**Files:**
- Review/Modify: `docs/ARCHITECTURE_LAYERS.md`
- Review/Modify: `docs/README.md`
- Review/Modify: `docs/INDEX.md`
- Review/Modify: current-state / control-plane docs if touched by target commits
- Review/Modify: `workers/worker1.md`

**Step 1: 枚举 tail 独占 docs/control-plane commits**

Run:

```bash
git cherry -v HEAD l0-main-tail-cleanup-20260408-final
git show --stat <tail-docs-commit>
```

Expected:

- 明确 docs/control-plane-only 的 commit family
- 不把 test/src 批次混进去

**Step 2: 精确吸收 docs/control-plane**

- 优先 cherry-pick docs/control-plane-only commit
- 如存在轻微冲突，按当前 `mainline` today contract 手工解冲
- 继续保持 `Windows exact evidence only via CI/real Windows runner`

**Step 3: 跑验证**

Run:

```bash
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
git diff --check
```

Expected:

- docs/control-plane 吸收后 contract 继续 PASS

### Task 3: 吸收 tail 的 test normalization / test runner 独占批次

**Files:**
- Review/Modify: `tests/fafafa.core.span/fafafa.core.span.testcase.pas`
- Review/Modify: `tests/fafafa.core.atomic/Test_fafafa.core.atomic.base.pas`
- Review/Modify: `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas`
- Review/Modify: `tests/fafafa.core.option/BuildOrTest.bat`
- Review/Modify: `tests/fafafa.core.result/BuildOrTest.bat`
- Review/Modify: related README files if the same commit family includes them

**Step 1: 锁定 tail 的 test-only commit family**

Run:

```bash
git show --stat <tail-test-commit>
```

Expected:

- 只选择 test normalization / runner / README 小修相关 commit

**Step 2: 精确吸收并对齐 today contract**

- 保持单源 include、L0 current-entry 与 current maintenance wording 不倒退
- README 不能把 today contract 降级成历史/stale 说明

**Step 3: 跑 targeted verification**

Run:

```bash
bash tests/fafafa.core.span/BuildOrTest.sh test
bash tests/fafafa.core.atomic/BuildOrTest.sh test
bash tests/fafafa.core.option/BuildOrTest.sh build
bash tests/fafafa.core.result/BuildOrTest.sh build
bash tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh
git diff --check
```

Expected:

- 对应模块继续 PASS
- no-downgrade contract 继续 PASS

### Task 4: 吸收 tail 的 src 独占批次

**Files:**
- Review/Modify: `src/fafafa.core.span.pas`
- Review/Modify: `src/fafafa.core.atomic.base.pas`
- Review/Modify: directly coupled tests if commit demands it

**Step 1: 逐文件 review tail 独占 diff**

Run:

```bash
git diff HEAD...l0-main-tail-cleanup-20260408-final -- src/fafafa.core.span.pas
git diff HEAD...l0-main-tail-cleanup-20260408-final -- src/fafafa.core.atomic.base.pas
```

Expected:

- 明确哪些改动真的是 today contract 需要，哪些只是历史噪音

**Step 2: 最小吸收**

- 只拿对 strict L0 current surface 有价值的部分
- 不做 unrelated refactor

**Step 3: 跑 targeted verification**

Run:

```bash
bash tests/fafafa.core.span/BuildOrTest.sh test
bash tests/fafafa.core.atomic/BuildOrTest.sh test
git diff --check
```

Expected:

- span / atomic 相关验证继续 PASS

### Task 5: 跑完整验证并收口

**Files:**
- Verify and commit

**Step 1: 跑最终验证**

Run:

```bash
bash tests/test_active_shell_runners.sh
bash tests/test_fs_perf_shell_scripts.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 新 shell/runner contract 继续 PASS
- maintenance loop PASS
- overlap / shortlist / inventory 输出继续保持 today contract

**Step 2: 提交 closeout wave**

Run:

```bash
git add <final-changed-files>
git commit -m "feat(l0): absorb tail closeout docs tests and span atomic deltas"
```

Expected:

- `tail` 独占面积进一步缩小
- 当前 worktree 完成这一波收口，准备进入下一轮 retained-refs triage

---

## Execution Closeout Notes

- `Task 2` 结论：`docs/control-plane` tail commits 经过逐个复核后判定为 stale，不能按 tail 版本回灌；当前 `HEAD` 已经以 `2026-04-11` current-state audit、`2026-04-14` retained-refs postmerge audit、`post-merge stabilization plan` 和 `docs/legacy/l0/README.md` 为 today control plane，故本任务按“reviewed and intentionally skipped”收口。
- `Task 3` 结论：`9216f320` 的 test entrypoint `settings.inc` normalization 已经完整存在于当前 `HEAD`；对 atomic/base/bits/contracts/endian/layout/option/result/span 入口的 diff 为 `no-op`，因此本任务按“already absorbed”收口，不再重复 cherry-pick。
- `Task 4` 结论：`src/fafafa.core.span.pas` 及其直接耦合测试相对 `l0-main-tail-cleanup-20260408-final` 已经是空 diff；唯一仍值得对齐的 source delta 是 `src/fafafa.core.atomic.base.pas` 中 `TAtomicPtr.CompareExchangeStrong/Weak` 的 generic-template 注释，这一波只吸收该最小 comment-only 对齐，不做行为修改。
- 本 wave 的最终策略保持不变：`shortlist-first`、`no broad absorb`、`simd out of scope`、`Windows exact native evidence only via CI / real Windows runner`。
