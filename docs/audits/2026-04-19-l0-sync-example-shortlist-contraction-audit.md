# 2026-04-19 L0 Sync Example Shortlist Contraction Audit

## Scope

- 收口 `tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 对两个已合同化 current-entry example source 的误报
- 把 `examples/fafafa.core.sync/example_sync.lpr` 与 `examples/fafafa.core.sync.mutex/example_basic_usage.lpr` 下沉到 `review_skip_paths=`
- 保持范围只在 retained-refs shortlist 降噪，不扩展到 `example_performance_comparison.lpr` 或 broader absorb

## Why this slice

在上一轮 condvar triage 降噪之后，fresh shortlist 已经只剩 3 个 examples/build candidate：

- `examples/fafafa.core.sync/example_sync.lpr`
- `examples/fafafa.core.sync.mutex/example_basic_usage.lpr`
- `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`

其中前两者其实都已经有 today contract：

- `example_sync.lpr` 已由 `bash tests/test_l0_sync_current_example_build.sh` 固定守住
- `example_basic_usage.lpr` 已落在 `bash tests/test_l0_sync_mutex_current_entry_default_run.sh` 的 build/run 路径里

因此这轮不再把它们继续留在 fresh shortlist，而是把注意力收窄到仍未独立守住的 `example_performance_comparison.lpr`。

## What changed

- `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - 把 `l0-mainline-closeout-20260411` 与 `l0-main-rescue` 上的
  - `examples/fafafa.core.sync/example_sync.lpr`
  - `examples/fafafa.core.sync.mutex/example_basic_usage.lpr`
  - 一并下沉到 `is_review_skip_path()`
- `tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
  - 新增最小 stub case，要求这两个 current-entry source 不得继续落到 fresh candidate
  - 把 green 结果固定成“shortlist 只剩未单独合同化的 example path”

## Explicit non-goals

- 不把 `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr` 一并降成 skip
- 不新增 `example_performance_comparison.lpr` 的 build contract
- 不改 `examples/fafafa.core.sync` / `examples/fafafa.core.sync.mutex` 当前源码
- 不做 retained refs 删除或 broad absorb

## Verification

```bash
bash tests/test_l0_sync_current_example_build.sh
bash tests/test_l0_sync_mutex_current_entry_default_run.sh
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/check_strict_l0_docs_consistency.sh
git diff --check
```

## Current conclusion

fresh retained-refs shortlist 现在已经从 3 个 examples/build candidate 收窄到 1 个：`examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`。这意味着 `sync` / `sync.mutex` 当前真正还值得继续开的下一刀已经被压缩成单点，而不是继续在已合同化的 current-entry source 上反复兜圈。
