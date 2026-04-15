# Examples for fafafa.core.result

本目录收纳 `fafafa.core.result` 的示例入口，当前重点覆盖基础语义、链式组合和 filter/try 风格。

## Current entry

- Linux/macOS：`examples/fafafa.core.result/BuildOrRun.sh`
- Windows：`examples\fafafa.core.result\BuildOrRun.bat`
- Windows filter 入口：`examples\fafafa.core.result\BuildOrRun.bat filters`
- 示例源码：
  - `examples/fafafa.core.result/example_result_basics.lpr`
  - `examples/fafafa.core.result/example_chain.lpr`
  - `examples/fafafa.core.result/example_result_chain.lpr`
  - `examples/fafafa.core.result/example_result_filters_and_try.lpr`

## What to run first

- 最小 smoke example：`example_result_basics.lpr`
- 链式组合：`example_result_chain.lpr`
- retained-refs triage 里当前最值得关注的 example source：`example_result_filters_and_try.lpr`

## Generated outputs

- `bin/` 和 `lib/` 只代表本地构建结果，不是 source-of-truth。
- current-entry 应回到 README、`BuildOrRun*` 脚本、`.lpr` / `.lpi` 源文件，而不是把生成产物当成稳定入口。
