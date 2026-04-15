# 2026-04-12 L0 Retained Refs Third Absorption Audit

> 这份审计记录 strict non-SIMD L0 在 retained refs 清理前，继续吸收 `collections` 域里已经明确 superseded 的 dated docs residue。
> 当前最新波次请改看 `docs/audits/2026-04-12-l0-retained-refs-fourth-absorption-audit.md`。

## Why this wave exists

- 第二波完成后，fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 已经把下一跳照得更清楚：`sidecar` / `tail` 两条 ref 的 `sample_docs_current_entry_paths=` 继续先暴露 `docs/INDEX.md`、`docs/README.md` 和 `docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md`。
- 其中 `collections` 域这一批 `2025-11-03` 的 plans / status / reviews 已经明确带有 dated / historical 语义，继续留在 current-entry 邻近目录，只会增加 retained-refs triage 的噪音。
- 同一轮检查里还暴露出一个 today-contract 漏洞：当前 docs 已经声称 `UnChecked_Methods_Summary.md` 应位于 `docs/collections/guides/`，但仓库里实际还停在旧的 `docs/reports/` 路径。

## What this wave changes

这轮继续坚持 docs-only、non-destructive，只做 three things：

1. 下沉 `collections` 域的 dated docs
   - `docs/collections/legacy/COLLECTIONS_REFINEMENT_PLAN.md`
   - `docs/collections/legacy/COLLECTIONS_NEW_CONTAINERS_PLAN_2025-11-03.md`
   - `docs/collections/legacy/COLLECTIONS_CURRENT_STATUS_2025-11-03.md`
   - `docs/collections/legacy/COLLECTIONS_OVERVIEW_2025-11-03.md`
   - `docs/collections/legacy/COLLECTIONS_API_CONSISTENCY_REVIEW_2025-11-03.md`
   - `docs/collections/legacy/COLLECTIONS_CODE_QUALITY_REVIEW_2025-11-03.md`
2. 补齐 `docs/collections/legacy/README.md`
   - 明确 collections 的 current-entry
   - 统一 historical batch 的进入方式
3. 刷新当前 docs 导航
   - `docs/fafafa.core.collections.md` 显式指向 `docs/collections/legacy/README.md`
   - `arr` / `vec` / `vecdeque` / `README_VecDeque` 修正失效旧路径
   - `docs/collections/guides/UnChecked_Methods_Summary.md` 真正归位到 guides 目录

## Why this batch is safe

- 这轮没有改任何 `src/`、`tests/` 或 examples 代码，只整理 docs 路径和导航。
- strict non-SIMD L0 的模块边界、Linux maintenance loop、Windows exact evidence 纪律都没有变化。
- 当前 collections 的 today contract 仍固定为：
  - `docs/fafafa.core.collections.md`
  - `docs/fafafa.core.collections.vec.md`
  - `docs/fafafa.core.collections.vecdeque.md`
  - `docs/collections/guides/`
- 因此，这轮只是在减少 current-entry 周围的历史噪音，不会把 SIMD、sidecar 或 code/test drift 混回 L0 当前执行面。

## Fresh inventory snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh` 结果：

- `l0-mainline-closeout-20260411`
  - `unique_commit_count=45`
  - `archive_docs_paths=0`
  - `docs_current_entry_paths=44`
  - `code_or_tests_paths=78`
  - `examples_or_build_paths=6`
  - `other_paths=3`
  - `recommendation=review-code-before-absorb`
- `l0-sidecar-handoff-20260409`
  - `unique_commit_count=26`
  - `archive_docs_paths=56`
  - `docs_current_entry_paths=22`
  - `code_or_tests_paths=106`
  - `examples_or_build_paths=107`
  - `other_paths=7`
  - `recommendation=absorb-archive-first`
- `l0-main-rescue`
  - `unique_commit_count=3`
  - `archive_docs_paths=0`
  - `docs_current_entry_paths=24`
  - `code_or_tests_paths=24`
  - `examples_or_build_paths=11`
  - `other_paths=1`
  - `recommendation=review-code-before-absorb`
- `l0-main-tail-cleanup-20260408-final`
  - `unique_commit_count=33`
  - `archive_docs_paths=56`
  - `docs_current_entry_paths=50`
  - `code_or_tests_paths=104`
  - `examples_or_build_paths=41`
  - `other_paths=7`
  - `recommendation=absorb-archive-first`

## Fresh details snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 结果继续说明：

- `l0-sidecar-handoff-20260409`
  - `sample_docs_current_entry_paths=docs/INDEX.md | docs/README.md | docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md`
  - `sample_examples_or_build_paths=` 已经开始集中暴露 `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`、`examples/fafafa.core.env/BuildOrRun.sh`、`examples/fafafa.core.json/BuildOrRun.sh`
- `l0-main-tail-cleanup-20260408-final`
  - `sample_docs_current_entry_paths=docs/INDEX.md | docs/README.md | docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md`
  - `sample_examples_or_build_paths=` 同样已经开始暴露 examples/build drift，而不再只是 docs residue

这意味着第三波完成之后，docs-first 吸收线已经把 `collections` 这批 dated docs 也从 current-entry 邻域里剥离出来了；下一跳更值得优先看的，将逐步从 docs residue 继续漂移到 examples/build 和 code/tests drift。

## Fresh retained-refs audit

fresh `bash tests/audit_strict_l0_retained_refs.sh` 结果仍然是：

- `l0-mainline-closeout-20260411`
  - `unique_patch_count=45`
  - `decision=retain-unique-history`
- `l0-sidecar-handoff-20260409`
  - `unique_patch_count=26`
  - `decision=retain-unique-history`
- `l0-main-rescue`
  - `unique_patch_count=3`
  - `decision=retain-unique-history`
- `l0-main-tail-cleanup-20260408-final`
  - `unique_patch_count=33`
  - `decision=retain-unique-history`

所以这轮依然不是“可以继续删 ref”的波次，而是“把 docs residue 再吸干一层，让后续 triage 更集中地看到 examples/build 与 code/tests drift”的波次。

## Current policy after this wave

- 根索引 `docs/README.md` / `docs/INDEX.md` 的 latest absorption 入口现在固定为本文件。
- 如需 collections 的 current-entry，统一从 `docs/fafafa.core.collections.md` 与 `docs/collections/guides/` 进入。
- 如需 collections 的历史计划、状态和评审语境，统一从 `docs/collections/legacy/README.md` 进入。
- 如需 retained refs 的高层分类，继续使用：

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh
```

- 如需 retained refs 的代表性 unique commits / paths，继续使用：

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh --details
```

## What this wave still did not do

- 没有删除任何 retained ref
- 没有修改 strict non-SIMD L0 代码或测试 surface
- 没有放松 Windows exact native evidence 只能来自 GitHub Actions / 真实 Windows 的纪律
- 没有处理 `sidecar` / `tail` 上剩余的 examples/build 与 code/tests drift

## Fresh verification

- `bash tests/test_strict_l0_collections_legacy_docs_layout_contract.sh`
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
2. 继续把 `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 当成下一批 triage 的第一入口
3. 把 `sidecar` / `tail` 上剩余的 examples/build drift 当作高 ROI 候选，而不是重新回头翻已经归档的 collections dated docs
4. 把 `l0-mainline-closeout-20260411` / `l0-main-rescue` 继续保留为 code/test/current-entry 专项波次处理
