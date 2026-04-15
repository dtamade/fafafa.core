# L0 Source Review Skip Wave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 strict non-SIMD L0 retained-refs `source-review-first` 的当前高噪音热点收口成“已复核跳过”而不是反复人工重审，并把这一判断固定进 shortlist script、contract 与 current-state docs。

**Architecture:** 这轮不做 broad absorb，也不为了制造进展感去改 `atomic` / `mem allocator callback` / Windows native CI 的 today code。先基于 fresh diff 逐个确认这些 retained-ref hotspot 在当前 `HEAD` 上要么已经吸收、要么属于 stale/no-downgrade 候选；然后给 `tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 增加 `review_skip_paths=` bucket，把这批已复核路径从下一轮手工 review 池中显式剥离。最后刷新 contract、current-state docs 与本波 audit，跑完整 verification 收口。

**Tech Stack:** Bash, git diff/name-status, retained-refs shortlist contracts, Markdown docs, current-state docs updater, strict L0 maintenance loop

---

### Task 1: 逐簇复核 source-review hotspot

**Files:**
- Review: `src/fafafa.core.atomic.pas`
- Review: `src/fafafa.core.atomic.base.pas`
- Review: `tests/fafafa.core.atomic/Test_fafafa.core.atomic.pas`
- Review: `tests/fafafa.core.atomic/Test_fafafa.core.atomic.base.pas`
- Review: `tests/fafafa.core.atomic/Test_fafafa.core.atomic.compat.contract.pas`
- Review: `tests/fafafa.core.atomic/README.md`
- Review: `src/fafafa.core.mem.allocator.callbackAllocator.pas`
- Review: `tests/fafafa.core.mem.allocator.foundation/test_allocator_foundation_runtime.pas`
- Review: `tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh`
- Review: `tests/fafafa.core.mem.allocator.foundation/buildOrTest.bat`
- Review: `tests/fafafa.core.mem.allocator.foundation/fafafa.core.mem.allocator.foundation.test.lpi`
- Review: `tests/fafafa.core.mem.allocator.foundation/fafafa.core.mem.allocator.foundation.test.lpr`
- Review: `.github/workflows/l0-windows-native-evidence.yml`
- Review: `tests/lib_github_actions_workflow_runs.sh`

**Step 1: 只看 closeout/rescue 相对 HEAD 的真实 diff**

Run:

```bash
git diff HEAD..l0-mainline-closeout-20260411 -- <hotspot-files>
git diff HEAD..l0-main-rescue -- <hotspot-files>
```

Expected:

- 明确哪些路径是 `HEAD` 已领先 / already absorbed / stale current-entry downgrade
- 不把未复核路径误标成 skip

### Task 2: 让 shortlist 显式跳过已复核 hotspot

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
- Modify: `tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`

**Step 1: 加 skip bucket**

- 新增 `review_skip_paths=` / `sample_review_skip_paths=`
- 只对白名单的、已经完成 fresh 复核的 retained-ref path 生效
- 这些 path 不再计入 `review_candidate_paths=`

**Step 2: 保持 retained-refs policy 不变**

- 仍然 `shortlist-first`
- 仍然 `reject_wholesale_absorb=yes`
- 仍然 non-destructive

### Task 3: 刷新 current-state docs / worker handoff 口径

**Files:**
- Modify: `tests/update_strict_l0_current_state_docs.sh`
- Modify: `tests/test_update_strict_l0_current_state_docs_contract.sh`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `docs/TESTING.md`
- Modify: `docs/INDEX.md`

**Step 1: 把新 bucket 写进 current-entry 说明**

- 文档和 updater 都要承认 `review_skip_paths=`
- 不再在 current-state 里硬编码过时的 shortlist 数字
- 明确 `atomic / mem / windows-native-evidence / stale test docs` 这类已复核热点应跳过

### Task 4: 记录这轮收口审计

**Files:**
- Create: `docs/audits/2026-04-14-l0-source-review-skip-audit.md`

**Step 1: 固化这轮结论**

- 哪些 hotspot 被 fresh 复核
- 哪些结论是 `HEAD` 已领先
- 哪些结论是 stale/no-downgrade
- 为什么这轮没有做 broad absorb

### Task 5: 完整验证并提交

**Files:**
- Verify and commit

**Step 1: 运行验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- shortlist 继续 non-destructive
- current-state docs / worker handoff 与新 bucket 对齐
- strict L0 maintenance loop 继续 PASS
