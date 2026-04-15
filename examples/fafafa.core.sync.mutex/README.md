# Examples for fafafa.core.sync.mutex

本目录收纳 `fafafa.core.sync.mutex` 的示例入口，当前重点覆盖基础使用、进阶模式和性能对比。

## Current entry

- Linux/macOS：`examples/fafafa.core.sync.mutex/BuildOrRun.sh`
- Windows：`examples\fafafa.core.sync.mutex\BuildOrRun.bat`
- 历史兼容脚本：`examples\fafafa.core.sync.mutex\buildOrRun.bat`
- 示例源码：
  - `examples/fafafa.core.sync.mutex/example_basic_usage.lpr`
  - `examples/fafafa.core.sync.mutex/example_advanced_patterns.lpr`
  - `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`
  - `examples/fafafa.core.sync.mutex/example_comprehensive.lpr`

## What to run first

- 基础路径：`example_basic_usage.lpr`
- 模式与组合：`example_advanced_patterns.lpr`
- retained-refs triage 里当前最值得关注的 example source：`example_performance_comparison.lpr`

## Generated outputs

- `bin/` 和 `lib/` 只代表本地构建结果，不是 source-of-truth。
- current-entry 应回到 README、`BuildOrRun*` 脚本、`.lpr` / `.lpi` 源文件，而不是把生成产物当成稳定入口。
