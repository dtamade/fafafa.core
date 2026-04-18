# Examples for fafafa.core.sync.mutex

本目录收纳 `fafafa.core.sync.mutex` 的示例入口。today current-entry 只覆盖基础使用和进阶模式；性能对比与综合示例保留为独立源码参考。

## Current entry

- Linux/macOS：`examples/fafafa.core.sync.mutex/BuildOrRun.sh`
- Windows：`examples\fafafa.core.sync.mutex\BuildOrRun.bat`
- 历史兼容脚本：`examples\fafafa.core.sync.mutex\buildOrRun.bat`
- current-entry 构建项目：
  - `examples/fafafa.core.sync.mutex/example_basic_usage.lpi`
  - `examples/fafafa.core.sync.mutex/example_advanced_patterns.lpi`
- current-entry 示例源码：
  - `examples/fafafa.core.sync.mutex/example_basic_usage.lpr`
  - `examples/fafafa.core.sync.mutex/example_advanced_patterns.lpr`

## Standalone sources

- `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`
- `examples/fafafa.core.sync.mutex/example_comprehensive.lpr`
- 这些源码当前不在 `BuildOrRun*` 默认链路里，不构成 today current-entry contract。

## What to run first

- 基础路径：`example_basic_usage.lpi` / `example_basic_usage.lpr`
- 模式与组合：`example_advanced_patterns.lpi` / `example_advanced_patterns.lpr`

## Generated outputs

- `bin/` 和 `lib/` 只代表本地构建结果，不是 source-of-truth。
- current-entry 应回到 README、`BuildOrRun*` 脚本、`.lpr` / `.lpi` 源文件，而不是把生成产物当成稳定入口。
