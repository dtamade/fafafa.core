# L0 Rescue Examples/Docs Stale Skip Wave

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 继续收窄 `l0-main-rescue` 的 source-review surface，把已经 fresh 复核、确认只会回退 today example entry / runner contract / docs narrative 的 stale cluster 统一下沉到 `review_skip_paths=`，并把结论写回 strict L0 current-state docs。

**Architecture:** 这轮继续坚持 shortlist-first、review/skip 优先于吸收。只处理 `rescue` 中的 examples/build/runner/doc 小簇，以及 `sidecar` 暴露出来的 landing-zone docs no-absorb 判定；不做 broad absorb，不删 retained refs，不碰 SIMD，不把旧 pointer 文本回灌成 current-entry。

**Tech Stack:** Bash shortlist script, retained-ref diff review, Markdown docs/index/testing/audit, strict L0 contract scripts

---

### Task 1: 收口 `rescue` 的 examples/build stale cluster

**Files:**
- Review/skip: `examples/fafafa.core.atomic/BuildOrRun.sh`
- Review/skip: `examples/fafafa.core.base/BuildOrRun.sh`
- Review/skip: `examples/fafafa.core.base/example_base.lpr`
- Review/skip: `examples/fafafa.core.option/BuildOrRun.sh`
- Review/skip: `examples/fafafa.core.result/BuildOrRun.sh`
- Review/skip: `examples/fafafa.core.result/example_result_filters_and_try.lpr`

**Step 1: 锁定 today example entry**

- 当前 example source-of-truth 继续是 README、`BuildOrRun*` 与 `.lpr` / `.lpi`
- `rescue` 这批 diff 只会回退 today entry 叙事、脚本协议或整理过的头部，不吸收

### Task 2: 收口 `rescue` 的 stale runner / doc cluster

**Files:**
- Review/skip: `tests/fafafa.core.endian/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.fs/ArchivePerfResult.sh`
- Review/skip: `tests/fafafa.core.fs/BuildOrRunPerf.sh`
- Review/skip: `tests/fafafa.core.fs/BuildOrRunPerfAll.sh`
- Review/skip: `tests/fafafa.core.fs/BuildOrRunResolvePerf.sh`
- Review/skip: `tests/fafafa.core.fs/README-perf.md`
- Review/skip: `tests/fafafa.core.layout/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.mem/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.mem/BuildOrTest.sh`
- Review/skip: `tests/fafafa.core.mem/README.md`
- Review/skip: `tests/fafafa.core.option/BuildOrTest.bat`
- Review/skip: `tests/fafafa.core.option/README.md`
- Review/skip: `tests/fafafa.core.platform/BuildOrTest.bat`

**Step 1: 以 today runner contract 判 stale**

- `FAFAFA_SKIP_BUILD=1` runtime-only 路径、统一 wrapper contract、README current-entry 叙事都以主线 today 版本为准
- `rescue` 这批 runner/doc 变化会把 today contract 回退成旧 runner 或旧 narrative，因此统一下沉 skip

### Task 3: 固化 sidecar landing-zone docs no-absorb 结论

**Files:**
- Review/no-absorb: `docs/collections/legacy/README.md`
- Review/no-absorb: `docs/reports/README.md`
- Review/no-absorb: `docs/collections/reports/README.md`
- Review/no-absorb: `docs/benchmarks/reports/README.md`
- Review/no-absorb: `docs/legacy/l0/README.md`

**Step 1: 锁定 current landing zone**

- 当前主线 landing-zone README 已是 today contract
- `sidecar` 暴露的旧 archive-pointer / legacy-pointer 文本不应吸收

### Task 4: 刷新 shortlist contract 与 current-state docs

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
- Modify: `tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
- Modify: `tests/update_strict_l0_current_state_docs.sh`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/TESTING.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Create: `docs/audits/2026-04-14-l0-rescue-examples-docs-stale-skip-audit.md`

### Task 5: 完整验证并收口

Run:

```bash
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

**Expected:**

- `rescue` 的 examples/build/runner/doc review surface 继续缩小
- current-state docs / worker handoff 与 shortlist 保持一致
- sidecar landing-zone docs 继续保持 today contract，不被旧 pointer 文本回灌
