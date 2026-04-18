# 2026-04-19 L0 Sync Mutex Current-Entry Repair Audit

## Scope

- 修复 `examples/fafafa.core.sync.mutex` current-entry build 里的 Lazarus CodeTools include 解析噪音
- 修复 `example_advanced_patterns.lpr` 默认运行路径里的计时分辨率除零问题
- 吸收两个最小 root-level verification：
  - `bash tests/test_l0_sync_mutex_current_entry_codetools_include_clean.sh`
  - `bash tests/test_l0_sync_mutex_current_entry_default_run.sh`
- 保持范围只在 `examples/fafafa.core.sync.mutex` current-entry include/run quality，不打开 retained `sync.mutex` broader runner/source absorb

## Why this slice

fresh `sync.mutex` current-entry review 说明这里同时有一类 project/source-of-truth 质量问题和一类 runtime 稳定性问题：

- `bash examples/fafafa.core.sync.mutex/BuildOrRun.sh build` 仍然能通过，因为当前 build 参数会把 `src/` 放进 `-Fi`
- 但 Lazarus CodeTools 仍会对 `example_basic_usage.lpr` 与 `example_advanced_patterns.lpr` 报 `include file not found "fafafa.core.settings.inc"`
- retained refs 在 `example_performance_comparison.lpr` 上也保留了同一类裸 include 变体，因此同目录源码入口需要一起归一，避免后续 triage 把这类 stale include residue 误读成 current-entry 差异
- `bash examples/fafafa.core.sync.mutex/BuildOrRun.sh` 的默认运行路径还会执行 `example_advanced_patterns`
- `DemoPerformanceComparison` 用毫秒级 `GetTickCount64` 测短循环时，`ManualTime` 可能落成 `0`，随后 `... / ManualTime` 会偶发触发 `EZeroDivide`

因此这轮不重开 `sync.mutex` 的 broader absorb，只把 current-entry 示例源码切到显式、稳定的 include 路径，并把 default-run 的零除路径也在同一切片里修平，再各自补一条窄 contract 守住。

## What changed

- `examples/fafafa.core.sync.mutex/example_basic_usage.lpr`
  - 把 `{$I fafafa.core.settings.inc}` 改成显式相对路径 `{$I ../../src/fafafa.core.settings.inc}`
- `examples/fafafa.core.sync.mutex/example_advanced_patterns.lpr`
  - 同步切到显式相对 include，消除 CodeTools 对 settings include 的解析噪音
  - 在 `DemoPerformanceComparison` 里对 `ManualTime = 0` 做显式保护
  - 开销计算改成显式 `Double` 差值，避免 `QWord` 算术下溢把负开销错误放大
- `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`
  - 同步切到同一目录的显式 include 约定，避免 retained stale include residue 继续制造误导
- `tests/test_l0_sync_mutex_current_entry_codetools_include_clean.sh`
  - 固定验证 `bash examples/fafafa.core.sync.mutex/BuildOrRun.sh build`
  - 直接拒绝构建日志中出现 `include file not found "fafafa.core.settings.inc"`
  - 缺少 `lazbuild` 时按 current L0 习惯返回 skip，而不是伪失败
- `tests/test_l0_sync_mutex_current_entry_default_run.sh`
  - 先固定验证 `bash examples/fafafa.core.sync.mutex/BuildOrRun.sh build`
  - 在非交互 stdin 下重复运行 `example_advanced_patterns`，把 timer-resolution 触发的偶发 `EZeroDivide` 放大成稳定红灯
  - 再补一次 `example_basic_usage` 的 current-entry 默认运行

## Explicit non-goals

- 不吸收 `examples/fafafa.core.sync.mutex/*.lpi` 的 retained stale project-entry 改动
- 不重开 `bash tests/test_strict_l0_sync_mutex_example_older_fpc_contract.sh` 那条 older-FPC compatibility 主题
- 不把 `DemoPerformanceComparison` 整体改写成另一套高精度 benchmark 框架
- 不把 `sync.mutex` broader runner/source residue 一并纳入 today contract
- 不把 `examples/fafafa.core.sync*` / `examples/fafafa.core.sync.condvar*` 其他 current-entry 修复批次重新打包

## Verification

```bash
bash tests/test_strict_l0_sync_mutex_example_older_fpc_contract.sh
bash tests/test_l0_sync_mutex_current_entry_codetools_include_clean.sh
bash tests/test_l0_sync_mutex_current_entry_default_run.sh
bash examples/fafafa.core.sync.mutex/BuildOrRun.sh </dev/null
bash tests/check_strict_l0_docs_consistency.sh
git diff --check
```

## Current conclusion

`examples/fafafa.core.sync.mutex` 这条 current-entry 现在不仅保持可构建，还补齐了两层 today contract：一层固定守住 Lazarus CodeTools include-resolution cleanliness，另一层固定守住 default-run 不再被毫秒计时分辨率偶发打成 `EZeroDivide`。`sync.mutex` 其余 retained stale/source-review 话题仍然 defer，后续如果要推进，应继续按更小专题切片，而不是回到 broad absorb。
