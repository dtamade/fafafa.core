# 2026-04-19 L0 Sync Condvar Shortlist Stale-Skip Audit

## Scope

- 收口 `tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 对 `examples/fafafa.core.sync.condvar` current-entry 的误报
- 固定 `sync.condvar` 这组已修 current-entry 不再落到 fresh `review_candidate_paths=`
- 保持范围只在 retained-refs triage 降噪，不重开 `sync.condvar` broader runner/source absorb

## Why this slice

在 `sync.condvar` current-entry 已经有独立合同之后，fresh shortlist 仍然把同一组路径继续当成 source-review-first 候选：

- `bash tests/test_l0_sync_condvar_current_example_build.sh` 已经固定守住 current-entry build
- 对应的 current-entry 修复也已经在 `docs/audits/2026-04-19-l0-sync-condvar-current-entry-build-repair-audit.md` 里完成收口
- 但 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 仍把 `BuildOrRun*` 与 7 组 `.lpi` / `.lpr` 当 fresh review candidate，导致 triage 噪音反复回流

因此这轮不再修改 `sync.condvar` 源码，而是把这组已经被 today contract 守住的 current-entry 路径正式降到 `review_skip_paths=`。

## What changed

- `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - 把 `l0-mainline-closeout-20260411` 与 `l0-main-rescue` 上的 `examples/fafafa.core.sync.condvar/BuildOrRun.bat`
  - `examples/fafafa.core.sync.condvar/BuildOrRun.sh`
  - `examples/fafafa.core.sync.condvar/*/*.lpi`
  - `examples/fafafa.core.sync.condvar/*/*.lpr`
  - 一并下沉到 `is_review_skip_path()`
- `tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
  - 新增最小 stub case，要求 `sync.condvar` current-entry 路径必须被统计进 `review_skip_paths=`
  - 用 red/green 方式防止 shortlist 以后把这组路径重新抬回 fresh candidate

## Explicit non-goals

- 不修改 `examples/fafafa.core.sync.condvar` 当前源码或 runner
- 不把 `README.md` 这种未进入 examples-build shortlist 统计面的文件纳入新的分类规则
- 不扩大到 `sync.mutex` / `example_sync` 以外的其他 fresh candidate
- 不做 retained refs 删除或 broad absorb

## Verification

```bash
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/test_l0_sync_condvar_current_example_build.sh
bash tests/check_strict_l0_docs_consistency.sh
git diff --check
```

## Current conclusion

`sync.condvar` 这组已修 current-entry 现在已经从 retained-refs fresh shortlist 里正式降到 stale/no-absorb lane，不会再反复占用 source-review-first 的人工注意力。fresh examples-build focus 因此收窄到 `example_sync.lpr` 与 `sync.mutex` 那两个仍未降噪的源码点，后续如要继续推进，应围绕它们做更小切片。
