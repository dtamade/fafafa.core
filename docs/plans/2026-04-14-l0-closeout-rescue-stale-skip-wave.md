# L0 Closeout/Rescue Stale Skip Wave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `closeout/rescue` 中已经 fresh 复核、确认只会回退 today contract 的 retained-ref source-review surface 明确下沉到 `review_skip_paths=`，并把这一结论写回 current-state docs / audit / worker handoff。

**Architecture:** 这轮继续坚持 shortlist-first、review/skip 优先于吸收。`closeout` 里只处理 `mem allocator` 注释差异与 fs perf wrapper/doc cluster；`rescue` 里只处理 `mem/result/span` 与 `base/bits/contracts/result/span` 的 Windows runner / test entry / README cluster。所有动作都以 strict L0 当前边界、current runner contract 和 current docs 为准，不做 broad merge，不碰 SIMD，不扩张 L0 boundary。

**Tech Stack:** Bash shortlist script, retained-ref diff review, Markdown current-state docs, worker handoff, strict L0 verification scripts

---

### Task 1: 收口 `closeout` 的 6-path stale cluster

**Files:**
- Review/skip: `src/fafafa.core.mem.allocator.pas`
- Review/skip: `tests/fafafa.core.fs/ArchivePerfResult.sh`
- Review/skip: `tests/fafafa.core.fs/BuildOrRunPerf.sh`
- Review/skip: `tests/fafafa.core.fs/BuildOrRunPerfAll.sh`
- Review/skip: `tests/fafafa.core.fs/BuildOrRunResolvePerf.sh`
- Review/skip: `tests/fafafa.core.fs/README-perf.md`

**Step 1: 锁定 today contract**

- `mem.allocator.pas` 只接受与 `allocator.base` 为 strict L0 core 相一致的注释口径
- fs perf shell / README 只接受当前统一入口与 wrapper contract

**Step 2: 下沉到 `review_skip_paths=`**

- 不吸收 retained-ref 内容
- 不改变 today code 行为

### Task 2: 收口 `rescue` 的 stale boundary / runner / test-entry cluster

**Files:**
- Review/skip: `src/fafafa.core.mem.allocator.pas`
- Review/skip: `src/fafafa.core.result.pas`
- Review/skip: `src/fafafa.core.span.pas`
- Review/skip: `tests/fafafa.core.base/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.bits/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.contracts/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.result/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.span/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.base/fafafa.core.base.test.lpr`
- Review/skip: `tests/fafafa.core.bits/fafafa.core.bits.test.lpr`
- Review/skip: `tests/fafafa.core.contracts/fafafa.core.contracts.test.lpr`
- Review/skip: `tests/fafafa.core.result/fafafa.core.result.test.lpr`
- Review/skip: `tests/fafafa.core.span/fafafa.core.span.test.lpr`
- Review/skip: `tests/fafafa.core.base/README.md`
- Review/skip: `tests/fafafa.core.bits/README.md`
- Review/skip: `tests/fafafa.core.contracts/README.md`
- Review/skip: `tests/fafafa.core.result/README.md`
- Review/skip: `tests/fafafa.core.span/README.md`

**Step 1: 以 today contract 判 stale**

- `mem.allocator.pas`：rescue 的 boundary 注释口径过时
- `result.pas`：rescue 会收缩当前组合子 surface，不吸收
- `span.pas`：rescue 会回退 `span2`
- `*.test.lpr`：缺 `settings.inc`
- `BuildOrTest.bat` / `README.md`：Windows runner 与叙事口径过时

**Step 2: 下沉到 `review_skip_paths=`**

- 不做源码吸收
- 不回灌旧测试入口 / 旧 README 叙事

### Task 3: 刷新 docs / audit / handoff

**Files:**
- Modify: `tests/update_strict_l0_current_state_docs.sh`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/README.md`
- Modify: `workers/worker1.md`
- Create: `docs/audits/2026-04-14-l0-closeout-rescue-stale-skip-audit.md`

**Step 1: 固定结论**

- `closeout` 的 mem allocator + fs perf cluster 已 fresh review，结论是 stale/no-downgrade skip
- `rescue` 的 mem/result/span + test-entry cluster 已 fresh review，结论是 stale skip
- 这些 skip 不改变 `tail` lane 的 today shell hygiene contract

### Task 4: 跑验证收口

**Step 1: 验证**

Run:

```bash
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/fafafa.core.result/BuildOrTest.sh test
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- closeout source-review candidate 收敛到 0
- rescue candidate surface 明显缩小
- docs / audit / handoff 与 shortlist 保持一致
