# 2026-04-13 L0 Retained Refs Eighth Focus Routing Audit

> 这份审计记录 strict non-SIMD L0 在第七波 docs absorbability 之后，继续把 retained refs 的 `test-hygiene-first` 与 `source-review-first` 从“知道方向”推进成“知道当前应该先看哪些 candidate paths”。

## Why this wave exists

- 第七波之后，`sidecar/tail` 已经能用 `docs_absorb_candidate_paths=` 看清 test-hygiene 之后哪些 docs residue 是低风险 landing-zone 候选。
- 但在进入那一步之前，`sidecar/tail` 的第一跳仍然只有：
  - `next_focus=test-hygiene-first`
  - `test_runtime_record_paths=`
  - `test_control_paths=`
  - `test_artifact_paths=`
  也就是说，虽然能分桶，但还不能直接从 inventory 里读出“这条 retained ref 当前最该先处理的 candidate paths”。
- 同样地，`closeout/rescue` 虽然已经被固定成 `next_focus=source-review-first`，但还没有一个显式 bucket 直接把：
  - `src`
  - real test source
  - CI workflow
  - examples/build drift
  合并成当前 source-review 专项波次的 candidate surface。

## What this wave changes

这轮继续坚持 docs-first、non-destructive，主要做三件事：

1. 给 retained-refs inventory 补 focus-routing candidate bucket
   - `tests/report_strict_l0_retained_refs_inventory.sh --details` 现在额外输出：
     - `test_hygiene_candidate_paths=`
     - `sample_test_hygiene_candidate_paths=`
     - `source_review_candidate_paths=`
     - `sample_source_review_candidate_paths=`
2. 固定 today routing 语义
   - `test_hygiene_candidate_paths=` 当前固定只统计：
     - runtime records
     - control files
     - output artifacts
     - binary artifacts
   - `source_review_candidate_paths=` 当前固定只统计：
     - `src`
     - real test source
     - CI workflow
     - examples/build drift
3. 刷新 latest 入口、current-state audit、worker handoff 和 docs consistency
   - 根入口改为指向本文件
   - `docs/TESTING.md` 现在会把 `next_focus=` 与 `*_candidate_paths=` 的 today 顺序一起写清楚

## Why this batch is safe

- 这轮没有修改 strict non-SIMD L0 的 `src/` 行为或测试语义，只补 inventory、contract、audit、导航与 handoff。
- Windows exact native evidence 纪律没有变化，仍然只接受 GitHub Actions / 真实 Windows runner。
- retained refs 仍然保持 non-destructive 审计口径，这轮没有删除任何 ref。
- SIMD owner 的边界没有变化，这轮仍只在 L0 current worktree 内推进。

## Fresh inventory snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 结果里，四条 retained refs 现在除了 `next_focus=` 之外，还能直接看到当前 candidate surface：

- `l0-mainline-closeout-20260411`
  - `next_focus=source-review-first`
  - `source_review_candidate_paths=84`
  - `docs_absorb_candidate_paths=5`
- `l0-sidecar-handoff-20260409`
  - `next_focus=test-hygiene-first`
  - `test_hygiene_candidate_paths=36`
  - `source_review_candidate_paths=177`
  - `docs_absorb_candidate_paths=6`
- `l0-main-rescue`
  - `next_focus=source-review-first`
  - `source_review_candidate_paths=35`
  - `docs_absorb_candidate_paths=5`
- `l0-main-tail-cleanup-20260408-final`
  - `next_focus=test-hygiene-first`
  - `test_hygiene_candidate_paths=36`
  - `source_review_candidate_paths=109`
  - `docs_absorb_candidate_paths=11`

## What these details mean

- `sidecar/tail` 现在不止知道“先做 test-hygiene”，还知道当前这一跳具体暴露出的低风险 hygiene surface 有多少，以及 representative paths 是什么。
- `closeout/rescue` 现在也不止知道“要走 source-review-first”，而是已经能直接从 inventory 输出读到当前 source-review candidate surface。
- `docs_absorb_candidate_paths=` 继续承担 test-hygiene 之后的 docs residue 下一跳，不和当前 first-focus candidate bucket 混在一起。

## Current policy after this wave

- 根索引 `docs/README.md` / `docs/INDEX.md` 的 latest absorption 入口现在固定为本文件。
- retained-refs inventory 的判断顺序继续固定为：
  - 先看 `recommendation=`
  - 再看 `next_focus=`
  - 如果是 `test-hygiene-first`，优先看 `test_hygiene_candidate_paths=`
  - 如果是 `source-review-first`，优先看 `source_review_candidate_paths=`
  - docs residue 则继续看 `docs_absorb_candidate_paths=`
  - 最后看对应 `sample_*`
- `docs_absorb_candidate_paths=` 当前固定只统计：
  - archive pointers
  - collections dated docs
  - legacy docs

## What this wave still did not do

- 没有删除任何 retained ref
- 没有修改 strict non-SIMD L0 代码或测试 surface
- 没有继续吸收 `closeout/rescue` 上的真实 `src` / test source 差异
- 没有对 `sidecar/tail` 做 destructive test hygiene 清理或 ref 删除

## Fresh verification

- `bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_docs_current_entry_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_focus_routing_contract.sh`
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
2. 继续用 `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 的 `next_focus=` 与 `*_candidate_paths=` 判断优先级
3. 对 `l0-sidecar-handoff-20260409` / `l0-main-tail-cleanup-20260408-final` 继续先做 `test_hygiene_candidate_paths=` 暴露出的 hygiene 专项波次
4. test-hygiene 之后，再优先看 `docs_absorb_candidate_paths=` 暴露出的 low-risk docs residue
5. 把 `l0-mainline-closeout-20260411` / `l0-main-rescue` 继续留给 `source_review_candidate_paths=` 驱动的更高风险 source-review wave
