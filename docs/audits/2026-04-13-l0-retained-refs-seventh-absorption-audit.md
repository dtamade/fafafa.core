# 2026-04-13 L0 Retained Refs Seventh Absorption Audit

> 这份审计记录 strict non-SIMD L0 在 retained refs 清理前，继续把 `sidecar/tail` 的 docs current-entry residue 从“知道有一堆 docs”推进成“知道哪些是 low-risk absorb candidate，以及它们应该落到哪里”。

## Why this wave exists

- 第六波结束后，fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 已经能说明：
  - `sidecar/tail` 继续是 `next_focus=test-hygiene-first`
  - 但 docs residue 仍然混着：
    - root entry
    - module docs
    - topics / guides
    - archive pointer README
    - collections dated docs
    - legacy docs
    - report topic docs
- 当时还不能直接回答：
  - test-hygiene 之后，哪些 docs residue 是低风险 absorb candidate
  - 这些 low-risk residue 应该落到哪些 landing zone
  - 哪些 docs 即使出现在 retained refs 里，也仍然属于 live current-entry，而不是可以“吸掉”的历史残留

## What this wave changes

这轮继续坚持 docs-first、non-destructive，主要做三件事：

1. 继续细化 retained-refs inventory 的 docs 视角
   - `tests/report_strict_l0_retained_refs_inventory.sh --details` 现在额外输出：
     - `docs_root_entry_paths=`
     - `docs_module_paths=`
     - `docs_topic_paths=`
     - `docs_guide_paths=`
     - `docs_archive_pointer_paths=`
     - `docs_collections_dated_paths=`
     - `docs_legacy_paths=`
     - `docs_report_topic_paths=`
     - `docs_absorb_candidate_paths=`
   - 同时保留原有 top-level buckets，不打乱前 6 波的统计口径
2. 固定 low-risk docs residue 的 landing zones
   - `docs/collections/legacy/README.md`
   - `docs/reports/README.md`
   - `docs/collections/reports/README.md`
   - `docs/benchmarks/reports/README.md`
   现在都明确写明：当 retained-refs inventory 暴露出对应路径时，应该优先把它们当作 landing zone / archive pointer / legacy 语境，而不是新的 current-entry blocker
3. 刷新第七波审计、latest 入口、worker handoff 和 docs consistency
   - 根入口改为指向本文件
   - docs consistency 现在会锁定新的 docs-current-entry contract 和 `docs_absorb_candidate_paths=` today contract

## Why this batch is safe

- 这轮没有修改 strict non-SIMD L0 的 `src/` 行为或测试语义，只补 inventory、contract、README pointer、audit 和 docs navigation。
- Windows exact native evidence 纪律没有变化，仍然只接受 GitHub Actions / 真实 Windows runner。
- 当前 retained refs 仍保持 non-destructive 审计口径，这轮没有删除任何 ref。
- SIMD owner 的边界没有变化，这轮仍只在 L0 current worktree 内推进。

## Fresh inventory snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 结果里，docs residue 现在已经能更细地看：

- `l0-mainline-closeout-20260411`
  - `docs_current_entry_paths=44`
  - `docs_root_entry_paths=2`
  - `docs_module_paths=19`
  - `docs_legacy_paths=5`
  - `docs_absorb_candidate_paths=5`
  - `next_focus=source-review-first`
- `l0-sidecar-handoff-20260409`
  - `docs_current_entry_paths=22`
  - `docs_root_entry_paths=3`
  - `docs_module_paths=9`
  - `docs_topic_paths=2`
  - `docs_guide_paths=2`
  - `docs_archive_pointer_paths=3`
  - `docs_collections_dated_paths=3`
  - `docs_report_topic_paths=1`
  - `docs_absorb_candidate_paths=6`
  - `next_focus=test-hygiene-first`
- `l0-main-rescue`
  - `docs_current_entry_paths=24`
  - `docs_module_paths=16`
  - `docs_legacy_paths=5`
  - `docs_absorb_candidate_paths=5`
  - `next_focus=source-review-first`
- `l0-main-tail-cleanup-20260408-final`
  - `docs_current_entry_paths=50`
  - `docs_root_entry_paths=3`
  - `docs_module_paths=24`
  - `docs_topic_paths=2`
  - `docs_guide_paths=2`
  - `docs_archive_pointer_paths=3`
  - `docs_collections_dated_paths=3`
  - `docs_legacy_paths=5`
  - `docs_report_topic_paths=1`
  - `docs_absorb_candidate_paths=11`
  - `next_focus=test-hygiene-first`

## What these details mean

- `sidecar/tail` 的 docs residue 已经不是一团黑箱：
  - 其中一部分是 live current-entry：
    - root entry
    - module docs
    - topic / guide docs
    - report topic docs
  - 另一部分已经是低风险 absorb candidate：
    - archive pointers
    - collections dated docs
    - legacy docs
- `closeout/rescue` 虽然也带着部分 `docs_absorb_candidate_paths=`，但它们同时混着更高风险的真实 `src` / test source / examples/build 差异，所以当前仍不适合把 docs residue 单独拉出来盲吸。
- 也就是说，第七波之后：
  - `sidecar/tail` 仍先做 `test-hygiene-first`
  - 但 test-hygiene 之后，docs 的下一跳现在已经有明确 landing zones

## Current policy after this wave

- 根索引 `docs/README.md` / `docs/INDEX.md` 的 latest absorption 入口现在固定为本文件。
- retained-refs inventory 的判断顺序继续固定为：
  - 先看 `recommendation=`
  - 再看 `next_focus=`
  - 再看 `docs_absorb_candidate_paths=`
  - 最后看 `sample_*` 里的 representative paths
- `docs_absorb_candidate_paths=` 当前固定只统计：
  - archive pointers
  - collections dated docs
  - legacy docs
- `docs/reports/time/*` 这种 report topic 继续属于 live topic surface，不算 absorb candidate。

## What this wave still did not do

- 没有删除任何 retained ref
- 没有修改 strict non-SIMD L0 代码或测试 surface
- 没有继续吸收 `closeout/rescue` 上的真实 `src` 或测试源码差异
- 没有对 `sidecar/tail` 做 destructive docs 清理或 ref 删除

## Fresh verification

- `bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_docs_current_entry_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_examples_build_docs_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_legacy_docs_layout_contract.sh`
  - 结果：PASS
- `bash tests/check_strict_l0_docs_consistency.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_docs_consistency_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_stable_docs_no_sha_contract.sh`
  - 结果：PASS
- `bash tests/test_update_strict_l0_current_state_docs_contract.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_inventory.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_inventory.sh --details`
  - 结果：PASS
- `bash tests/audit_strict_l0_retained_refs.sh`
  - 结果：PASS
- `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS
- `git diff --check`
  - 结果：PASS

## Next move

下一跳更适合这样推进：

1. 继续保留 `bash tests/audit_strict_l0_retained_refs.sh` 的 non-destructive 口径
2. 继续用 `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 的 `next_focus=` 与 `docs_absorb_candidate_paths=` 判断优先级
3. 对 `l0-sidecar-handoff-20260409` / `l0-main-tail-cleanup-20260408-final` 继续先做 test-hygiene 专项波次
4. test-hygiene 之后，再优先看已经明确落到 landing zone 的 low-risk docs residue
5. 把 `l0-mainline-closeout-20260411` / `l0-main-rescue` 继续留给更高风险的 source-review wave
