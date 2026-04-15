# 2026-04-13 L0 Retained Refs Ninth Hygiene And Shortlist Audit

> 这份审计记录 strict non-SIMD L0 在第八波 focus-routing 之后，继续把 `sidecar/tail` 的低风险 hygiene 真正吸收到主线，同时把 `closeout/rescue` 的 source-review 变成 shortlist-first。

## Why this wave exists

- 第八波之后，`sidecar/tail` 已经不再只是“知道先做 hygiene”，而是已经能直接从 inventory 读到 `test_hygiene_candidate_paths=`。
- 但在主线里，这批 runtime/output/binary residue 仍然实际被 git 跟踪着：
  - `tests/fafafa.core.archiver/last-run.txt`
  - `tests/fafafa.core.atomic/tests_atomic`
  - `tests/fafafa.core.atomic/atomic_heaptrc_full_output.txt`
  - `tests/fafafa.core.sync.barrier/*_output.txt`
  - `tests/fafafa.core.fs/performance-data/latest.txt`
  - `tests/fafafa.core.fs/performance-data/perf_*latest.txt`
  - 一批 dated perf snapshots
- 同时，`closeout/rescue` 虽然已经被固定成 `source-review-first`，但实际操作时仍缺一条命令，能把：
  - review candidate
  - dangerous delete
  - SIMD out-of-scope
  拆开，而不是继续肉眼翻大 diff。

## What this wave changes

这轮分成两段，都是 high-ROI、non-destructive：

1. 实际吸收 `sidecar/tail` 的低风险 hygiene
   - 主线新增：
     - `tests/fafafa.core.archiver/.gitignore`
     - `tests/fafafa.core.atomic/.gitignore`
     - `tests/fafafa.core.fs/performance-data/.gitignore`
     - `tests/fafafa.core.sync.barrier/.gitignore`
   - 主线删除了被误跟踪的 runtime/output/binary residue
   - `tests/fafafa.core.atomic/README.md` 现在明确把 heaptrc/logs 归到运行期产物，不再把 tracked output 当支持材料
2. 新增 `closeout/rescue` 的 shortlist-first 入口
   - 新命令：
     - `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
   - 它会显式输出：
     - `review_candidate_paths=`
     - `src_review_paths=`
     - `test_code_review_paths=`
     - `test_script_review_paths=`
     - `test_doc_review_paths=`
     - `ci_review_paths=`
     - `examples_build_review_paths=`
     - `simd_out_of_scope_paths=`
     - `dangerous_delete_paths=`
     - `reject_wholesale_absorb=`

## Why this batch is safe

- hygiene absorb 只删明确的 runtime/output/binary residue，不改 test source、baseline、公共 API 或 L0 模块实现。
- retained refs 审计口径没有变化，这轮仍然不删除任何历史 ref。
- 新 shortlist 命令只读 git diff，不应用补丁，也不改变 refs。
- SIMD owner 的边界进一步被工具化了：`simd_out_of_scope_paths=` 现在会把 rescue 里的 SIMD-only residue 单独拎出来。

## What got cleaned from mainline

实际从主线去掉的 tracked residue 包括：

- `tests/fafafa.core.archiver/last-run.txt`
- `tests/fafafa.core.atomic/tests_atomic`
- `tests/fafafa.core.atomic/atomic_heaptrc_full_output.txt`
- `tests/fafafa.core.sync.barrier/all_test_output.txt`
- `tests/fafafa.core.sync.barrier/barrier_heaptrc_full_output.txt`
- `tests/fafafa.core.sync.barrier/barrier_heaptrc_output.txt`
- `tests/fafafa.core.sync.barrier/global_test_output.txt`
- `tests/fafafa.core.sync.barrier/ibarrier_test_output.txt`
- `tests/fafafa.core.sync.barrier/test_output.txt`
- `tests/fafafa.core.fs/performance-data/latest.txt`
- `tests/fafafa.core.fs/performance-data/perf_all_latest.txt`
- `tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt`
- `tests/fafafa.core.fs/performance-data/perf_walk_latest.txt`
- `tests/fafafa.core.fs/performance-data/` 下的一批 dated perf snapshots

这意味着 `sidecar/tail` 的第一跳已经不再只是 inventory 标签，而是已经真正有一部分 hygiene residue 被主线吃掉了。

## Docs residue status after hygiene absorb

这轮没有再去 broad absorb `sidecar/tail` 的 collections/report docs residue，原因不是忘了做，而是 fresh 复核后结论更清楚了：

- `docs/collections/legacy/README.md`
- `docs/reports/README.md`
- `docs/collections/reports/README.md`
- `docs/benchmarks/reports/README.md`

这些 landing zone 在主线已经存在，并且已经明确承担：

- collections dated docs 的 legacy 语境
- docs-root / collections / benchmarks archive pointer 语义

所以对 `sidecar/tail` 来说，这一块当前更接近“主线已覆盖 landing zone”，而不是还需要继续 broad 搬运。

## Fresh shortlist snapshot

fresh `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 结果：

- `l0-mainline-closeout-20260411`
  - `review_candidate_paths=6`
  - `test_doc_review_paths=6`
  - `simd_out_of_scope_paths=0`
  - `dangerous_delete_paths=41`
  - `reject_wholesale_absorb=yes`
- `l0-main-rescue`
  - `review_candidate_paths=73`
  - `src_review_paths=10`
  - `test_code_review_paths=29`
  - `test_script_review_paths=16`
  - `test_doc_review_paths=12`
  - `examples_build_review_paths=6`
  - `simd_out_of_scope_paths=30`
  - `dangerous_delete_paths=54`
  - `reject_wholesale_absorb=yes`

这组数字说明：

- `closeout` 现在几乎不再像“可直接吸收的 L0 代码波次”，而更像“夹着大量危险删除的 test-doc residue”。
- `rescue` 继续是混合快照，不仅危险删除很多，而且还有显著的 SIMD-only residue。
- 所以这两条 retained refs 的 today policy 仍然应该是 shortlist-first，而不是 merge-first。

## Current policy after this wave

- 根入口 `docs/README.md` / `docs/INDEX.md` 的 latest retained-refs audit 现在固定为本文件。
- retained-refs 的 today 顺序现在进一步固定为：
  1. 先看 `bash tests/report_strict_l0_retained_refs_inventory.sh --details`
  2. 如果 `next_focus=test-hygiene-first`，先吃 `test_hygiene_candidate_paths=`
  3. docs residue 只在主线 landing zone 尚未覆盖时再吸收
  4. 如果 `next_focus=source-review-first`，立刻跑 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  5. 看到 `dangerous_delete_paths>0` 或 `reject_wholesale_absorb=yes` 时，拒绝整包吸收
- Windows exact native evidence 纪律不变：只接受 GitHub Actions / 真实 Windows runner。

## What this wave still did not do

- 没有删除任何 retained ref
- 没有吸收 `closeout/rescue` 的真实 `src` patch
- 没有修改 strict non-SIMD L0 模块行为
- 没有把 SIMD residue 带回 L0 current worktree

## Fresh verification

- `bash tests/test_strict_l0_retained_refs_hygiene_absorption_contract.sh`
  - 结果：PASS
- `bash tests/fafafa.core.atomic/BuildOrTest.sh check`
  - 结果：PASS
- `bash tests/fafafa.core.archiver/BuildOrTest.sh build`
  - 结果：PASS
- `bash tests/fafafa.core.sync.barrier/BuildOrTest.sh build`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - 结果：PASS

## Next move

下一跳更适合这样推进：

1. 继续保留 `bash tests/audit_strict_l0_retained_refs.sh` 的 non-destructive 口径
2. `sidecar/tail` 如果还剩 docs residue，只在 landing zone 未覆盖时再做 docs-first 小波次
3. `closeout/rescue` 继续只看 shortlist，不做 broad merge
4. 如果后续真的要吸收 `rescue`，应优先从：
   - `src_review_paths=`
   - `test_code_review_paths=`
   - `examples_build_review_paths=`
   里挑最小批次，并带 fresh 验证
