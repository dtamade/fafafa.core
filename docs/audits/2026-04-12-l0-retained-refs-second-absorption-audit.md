# 2026-04-12 L0 Retained Refs Second Absorption Audit

> 这份审计记录 strict non-SIMD L0 在 retained refs 清理前，继续吸收 superseded dated L0 docs residue 的第二波结果。
> 当前最新波次请改看 `docs/audits/2026-04-12-l0-retained-refs-fourth-absorption-audit.md`。

## Why this wave exists

- 第一波已经先把纯 archive reports 下沉到 `archive/reports/*`，但 `bash tests/report_strict_l0_retained_refs_inventory.sh` 仍显示 `sidecar` / `tail` 两条 ref 混着一批 `docs_current_entry_paths`。
- 这些 `docs_current_entry_paths` 里，有一批其实已经明确 superseded，只是还停在 `docs/plans/` 或 `docs/audits/` 的 current-entry 区域。
- 如果不先把这批 dated L0 plans / audits 下沉到 `docs/legacy/l0/`，后续 retained refs 吸收就会继续卡在“哪些是 current-entry、哪些只是历史批次”的人工判断上。

## What this wave changes

这轮同时做两件事：

1. 给 `bash tests/report_strict_l0_retained_refs_inventory.sh` 增加 `--details`
   - 让每条 retained ref 都能输出 `sample_unique_commits=`
   - 同时给出 `archive docs` / `current docs` / `code/tests` / `examples/build` 的 representative path samples
2. 把一批已经明确 superseded 的 L0 dated plans / audits 下沉到 `docs/legacy/l0/`
   - `docs/legacy/l0/2026-04-07-l0-rescue-triage-audit.md`
   - `docs/legacy/l0/2026-04-08-l0-tail-docs-audit.md`
   - `docs/legacy/l0/2026-04-09-l0-current-state-audit.md`
   - `docs/legacy/l0/2026-04-10-l0-current-state-audit.md`
   - `docs/legacy/l0/2026-03-26-l0-candidates-platform-span-admission.md`
   - `docs/legacy/l0/2026-03-26-strict-l0-merge-closeout.md`
   - `docs/legacy/l0/2026-03-27-l0-control-plane-closeout.md`
   - `docs/legacy/l0/2026-04-07-l0-rescue-split-closeout.md`
   - `docs/legacy/l0/2026-04-09-l0-kernel-span2-closeout.md`
   - `docs/legacy/l0/2026-04-09-l0-mainline-merge-checklist.md`

## Why this batch is safe

- 这批文件都已经有明确的 superseded / dated / historical 语义，不再承担 strict L0 的 today contract。
- 当前 strict L0 的 current-entry 仍固定为：
  - `docs/ARCHITECTURE_LAYERS.md`
  - `docs/fafafa.core.l0.foundation.md`
  - `docs/fafafa.core.l0.roadmap.md`
  - `docs/audits/2026-04-11-l0-current-state-audit.md`
  - `docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md`
- 因此，这轮下沉不会改变 strict L0 的模块边界、验证口径或 Windows exact evidence 纪律，只会减少 current-entry 区域里的历史噪音。

## Current policy after this wave

- 根索引 `docs/README.md` / `docs/INDEX.md` 只继续指向 current-entry 与 `docs/legacy/l0/README.md`
- 如需 retained refs 的高层分类，继续用：

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh
```

- 如需 retained refs 的代表性 unique commits / path samples，改用：

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh --details
```

- 如需看更早的 L0 dated batch 语境，统一从：

```text
docs/legacy/l0/README.md
```

进入，而不是回到 `docs/plans/` / `docs/audits/` 根层逐个翻旧文件。

## Fresh inventory snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh` 结果：

- `l0-mainline-closeout-20260411`
  - `unique_commit_count=45`
  - `archive_docs_paths=0`
  - `docs_current_entry_paths=44`
  - `code_or_tests_paths=78`
  - `examples_or_build_paths=6`
  - `recommendation=review-code-before-absorb`
- `l0-sidecar-handoff-20260409`
  - `unique_commit_count=26`
  - `archive_docs_paths=56`
  - `docs_current_entry_paths=22`
  - `code_or_tests_paths=106`
  - `examples_or_build_paths=107`
  - `recommendation=absorb-archive-first`
- `l0-main-rescue`
  - `unique_commit_count=3`
  - `archive_docs_paths=0`
  - `docs_current_entry_paths=24`
  - `code_or_tests_paths=24`
  - `examples_or_build_paths=11`
  - `recommendation=review-code-before-absorb`
- `l0-main-tail-cleanup-20260408-final`
  - `unique_commit_count=33`
  - `archive_docs_paths=56`
  - `docs_current_entry_paths=50`
  - `code_or_tests_paths=104`
  - `examples_or_build_paths=41`
  - `recommendation=absorb-archive-first`

## Fresh details snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 现在把下一跳也照清楚了：

- `l0-mainline-closeout-20260411`
  - `sample_unique_commits=` 仍以 `build(l0)` / `examples(l0)` / `span2 control-plane` 这类 strict L0 核心提交为主
  - `sample_docs_current_entry_paths=` 是 `docs/ARCHITECTURE_LAYERS.md`、`docs/INDEX.md`、`docs/README.md`
- `l0-sidecar-handoff-20260409`
  - `sample_archive_docs_paths=` 已清楚落在 `archive/reports/docs-benchmarks/` 和 `archive/reports/docs-collections/`
  - `sample_docs_current_entry_paths=` 现在主要暴露的是 `docs/INDEX.md`、`docs/README.md`、`docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md`
- `l0-main-tail-cleanup-20260408-final`
  - `sample_docs_current_entry_paths=` 同样先暴露 `docs/INDEX.md`、`docs/README.md`、`docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md`

这说明第二波之后，下一跳更值得继续看的 docs residue 已不再是 superseded 的 L0 dated plans/audits，而是：

- root current-entry 的 `docs/README.md` / `docs/INDEX.md`
- collections 域自己的 dated plan / status docs
- sidecar / tail 里仍未拆出来的 code / tests / examples drift

## What changed and what did not

这波的价值主要在 two things：

1. current-entry 已经收紧
   - superseded 的 L0 dated plans / audits 不再继续占据 `docs/plans/` / `docs/audits/` 根层
   - 当前读者进入 `docs/README.md` / `docs/INDEX.md` 时，会被直接导向 current-entry 或 `docs/legacy/l0/README.md`
2. retained refs triage 现在可复跑、可定位
   - 以后不必再先手工翻 `git show`；直接用 `--details` 就能看到每条 ref 的 representative samples

但也要明确：

- 这波没有让 retained refs 的 `unique_patch_count` 直接下降
- fresh `bash tests/audit_strict_l0_retained_refs.sh` 仍然给出：
  - `l0-mainline-closeout-20260411`: `unique_patch_count=45`, `decision=retain-unique-history`
  - `l0-sidecar-handoff-20260409`: `unique_patch_count=26`, `decision=retain-unique-history`
  - `l0-main-rescue`: `unique_patch_count=3`, `decision=retain-unique-history`
  - `l0-main-tail-cleanup-20260408-final`: `unique_patch_count=33`, `decision=retain-unique-history`

所以这轮不是“refs 数字已经收平”的波次，而是“历史 L0 文档先下沉、下一跳边界先照清楚”的波次。
