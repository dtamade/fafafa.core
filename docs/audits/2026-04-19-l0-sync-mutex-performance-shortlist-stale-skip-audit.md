# 2026-04-19 L0 Sync Mutex Performance Shortlist Stale-Skip Audit

## Scope

- 收口 `tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 里最后残留的 `sync.mutex` examples/build fresh candidate
- 把 `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr` 从 `review_candidate_paths=` 下沉到 `review_skip_paths=`
- 同步修正 `examples/fafafa.core.sync.mutex/README.md`、`docs/README.md`、`docs/INDEX.md` 对这条源码的 current-entry 叙事

## Why this slice

在前一轮 `sync` / `sync.condvar` / `sync.mutex basic` 收窄之后，fresh retained-refs shortlist 只剩一条：

- `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`

这时如果继续把它视为“未吸收的 today current-entry source”，风险在于会误导后续判断。因为 fresh diff 复核显示，两个 retained refs 在这条文件上的唯一区别都是把 include 路径改回旧写法：

```diff
-{$I ../../src/fafafa.core.settings.inc}
+{$I fafafa.core.settings.inc}
```

这不是更先进或更正确的实现，而是与 current HEAD 已修平的 include 约定相反的 stale residue。因此最合理的收口不是给它再补一层 current-entry contract，而是明确把它降级为 non-current-entry standalone source，并从 fresh shortlist 里移除。

## What changed

- `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - 把 `l0-mainline-closeout-20260411` / `l0-main-rescue` 上的
  - `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`
  - 一并下沉到 `is_review_skip_path()`
- `tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
  - 新增 stub diff 覆盖 `example_performance_comparison.lpr`
  - 固定要求它进入 `sample_review_skip_paths=`
- `tests/test_l0_sync_mutex_retained_shortlist_clear.sh`
  - 对真实 retained refs 固定要求两个 ref 的 `review_candidate_paths=0`
  - 固定拒绝 `example_performance_comparison.lpr` 重新出现在 `sample_review_candidate_paths=` / `sample_examples_build_review_paths=`
- `examples/fafafa.core.sync.mutex/README.md`
  - `Current entry` 只保留 `example_basic_usage` / `example_advanced_patterns` 的 `.lpi` / `.lpr`
  - `example_performance_comparison.lpr` 与 `example_comprehensive.lpr` 下沉为 `Standalone sources`
  - 删除“当前最值得关注的 example source”这类 fresh-hotspot 叙事
- `tests/test_l0_sync_mutex_readme_current_entry_contract.sh`
  - 固定要求 README 的 `Current entry` / `Standalone sources` 边界与 today 脚本一致
- `docs/README.md` / `docs/INDEX.md`
  - 把 “shortlist 只剩 performance example” 的旧状态更新为 “examples/build shortlist 已清空”

## Explicit non-goals

- 不把 `example_performance_comparison.lpr` 拉进 `BuildOrRun*` 默认构建链
- 不新增 `example_performance_comparison.lpi`
- 不重开 `sync.mutex` broader runner/source absorb
- 不改 `example_performance_comparison.lpr` 本身的运行逻辑或 benchmark 结构

## Verification

```bash
bash tests/test_l0_sync_mutex_readme_current_entry_contract.sh
bash tests/test_l0_sync_mutex_retained_shortlist_clear.sh
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/check_strict_l0_docs_consistency.sh
git diff --check
```

## Current conclusion

`sync.mutex` retained-refs examples/build 面的最后一个 fresh candidate 已经被证实只是 stale include residue，而不是“漏掉的更正确实现”。因此 today current-entry 现在明确只覆盖 `example_basic_usage` / `example_advanced_patterns`；`example_performance_comparison.lpr` 继续保留为 standalone source，但不再占据 fresh shortlist 或 current-entry 叙事。
