# 2026-04-14 L0 Retained Refs Sidecar Tail Postmerge Audit

> 这份审计记录 strict non-SIMD L0 在 merged-main closeout 之后，继续把 `sidecar/tail` 的 retained-refs cleanup 从“还知道有 unique history”推进成“已经吸掉一批低风险 sidecar hygiene，并能 pairwise 看清各自还剩什么独占批次、为什么暂时还不能删”。

## Why this wave exists

- mainline closeout 完成后，fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 仍然会把：
  - `l0-sidecar-handoff-20260409`
  - `l0-main-tail-cleanup-20260408-final`
  固定显示成 `next_focus=test-hygiene-first`。
- 但 merged-main 之后，这个字段更像 retained history 的 absorb-class，而不是 today 的 ref-delete readiness：
  - 第九波已经吸掉一批 `archiver/atomic/fs/sync.barrier` hygiene residue
  - current-entry docs / worker 仍缺一条 pairwise 入口，回答：
    - `sidecar` / `tail` 现在各自还剩什么 exclusive batch
    - 它们是不是已经可以安全删除
    - 哪一边更像 runner cleanup batch，哪一边更像 span2 / control-plane batch
- 同时，fresh 只读 diff 继续说明：`sidecar` 里还有一小段主线尚未覆盖的低风险 hygiene：
  - `tests/fafafa.core.env/build_log.txt`
  - `tests/fafafa.core.env/fpcdebug.txt`
  - `tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt`

## What this wave changes

这轮分成两段，都是 small-cut、non-destructive：

1. 实际吸收 sidecar 剩余的低风险 runtime hygiene
   - 主线新增：
     - `tests/fafafa.core.env/.gitignore`
     - `tests/fafafa.core.mem.manager.rtl/.gitignore`
   - 主线删除了被误跟踪的 runtime/output residue：
     - `tests/fafafa.core.env/build_log.txt`
     - `tests/fafafa.core.env/fpcdebug.txt`
     - `tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt`
2. 新增 `sidecar/tail` 的 pairwise overlap 入口
   - 新命令：
     - `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
   - 它会显式输出：
     - `sidecar_tail_merge_base=`
     - `sidecar_only_commit_count=`
     - `tail_only_commit_count=`
     - `sidecar_safe_delete_now=`
     - `tail_safe_delete_now=`
     - `pairwise_decision=`
     - `pairwise_cleanup_readiness=`
     - 以及各自 exclusive path buckets / samples

## Why this batch is safe

- hygiene absorb 只处理运行期日志 / heaptrc 输出，不改 Pascal 源码、公共 API、contract 语义或 current-entry docs。
- overlap 报表只读 `merge-base`、`git cherry -v` 和 `git show --name-only`，不应用任何 patch，也不删除 refs。
- 这轮继续不碰 `closeout/rescue` broad absorb，也不碰 SIMD。
- 这轮不需要伪造 Windows 结论；Windows exact evidence 纪律仍保持 CI / 真实 Windows runner only。

## Fresh overlap snapshot

fresh `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh` 结果：

- `sidecar_tail_merge_base=06d4dfd1e97b466bc314b9b6d937c4466fbc34ca`
- `sidecar`
  - `sidecar_only_commit_count=1`
  - `sidecar_safe_delete_now=no`
  - `sidecar_only_test_runner_paths=23`
  - `sidecar_only_example_runner_paths=38`
  - `sidecar_only_test_code_paths=7`
  - `sidecar_only_docs_paths=1`
  - sample exclusive commit：
    - `44974e49f2b3480c0c9a3f96c80bfe3a396ed619 chore(sync): preserve sidecar runner cleanup batch`
- `tail`
  - `tail_only_commit_count=8`
  - `tail_safe_delete_now=no`
  - `tail_only_docs_paths=61`
  - `tail_only_src_paths=2`
  - `tail_only_test_code_paths=21`
  - `tail_only_test_doc_paths=15`
  - `tail_only_worker_paths=6`
  - sample exclusive commits：
    - `fde7c4ffe678b2fd656205622db2d900fee9a508 l0: admit span2 and refresh control plane`
    - `4e8774bfdee1187b7625b24f8dc7cffaceb3d0ee docs(l0): harden current-state control plane`
    - `9216f320ee6241f582dffa5e586a2381f75e4c3e test(l0): normalize settings include in test entrypoints`
- pairwise summary：
  - `pairwise_decision=keep-both`
  - `pairwise_cleanup_readiness=review-exclusive-batches-first`

这组结果把 post-merge 语义讲清楚了：

- `sidecar` 当前更像“一整个 sync/example/test runner cleanup batch”，不是还能直接 blind delete 的空壳 ref。
- `tail` 当前更像“span2 + docs/control-plane + test normalization 批次”，也不是已经被主线完全覆盖的空壳 ref。
- 所以 inventory 里的 `test-hygiene-first` 仍然是历史 absorb 分类，但当前 ref cleanup 判断必须再看 overlap。

## What actually shrank from sidecar

这一波真实从主线吸掉的 low-risk residue 是：

- `tests/fafafa.core.env/build_log.txt`
- `tests/fafafa.core.env/fpcdebug.txt`
- `tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt`

以及对应的 `.gitignore`：

- `tests/fafafa.core.env/.gitignore`
- `tests/fafafa.core.mem.manager.rtl/.gitignore`

这意味着 `sidecar` 的 retained surface 又进一步少了一段“纯 runtime residue”，不用再把这类日志 / heaptrc 继续留在主线 tracked surface。

## Current policy after this wave

- retained-refs triage 继续保持：
  1. 先看 `bash tests/report_strict_l0_retained_refs_inventory.sh --details`
  2. 如果当前问题是 absorb class / candidate surface，继续读 `next_focus=`、`test_hygiene_candidate_paths=`、`source_review_candidate_paths=`、`docs_absorb_candidate_paths=`
  3. 如果当前问题变成“`sidecar/tail` 到底还能不能删、各自还剩什么 exclusive batch”，立刻改跑 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
  4. 只要 `sidecar_safe_delete_now=no` 或 `tail_safe_delete_now=no`，就拒绝 blind delete
- `closeout/rescue` 继续保持 shortlist-first，不受这轮 overlap 报表替代：
  - `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
- Windows exact native evidence 纪律不变：
  - 只接受 GitHub Actions / 真实 Windows runner

## What this wave still did not do

- 没有删除任何 retained ref
- 没有吸收 `sidecar` 的 sync/example runner 大批次
- 没有吸收 `tail` 的 span2 / docs control-plane / test normalization 批次
- 没有 broad merge `closeout/rescue`
- 没有触碰 SIMD

## Fresh verification

- `bash tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh`
  - 结果：PASS
- `bash tests/fafafa.core.env/BuildOrTest.sh build`
  - 结果：PASS
- `bash tests/fafafa.core.mem.manager.rtl/BuildOrTest.sh check`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_sidecar_tail_overlap_contract.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
  - 结果：PASS

## Next move

下一跳更适合这样推进：

1. 继续保留 `bash tests/audit_strict_l0_retained_refs.sh` 的 non-destructive ref 审计
2. `sidecar` 如需继续吸收，优先挑 runner/test hygiene 的最小批次，不碰 current-entry docs 回退
3. `tail` 如需继续吸收，优先做 source-review-first 的小批次，不做 broad merge
4. `sidecar/tail` 的 blind delete 结论继续保持 `no`
