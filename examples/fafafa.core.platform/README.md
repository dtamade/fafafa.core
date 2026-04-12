# Examples for fafafa.core.platform

本目录收纳 `fafafa.core.platform` 的最小示例入口，只演示静态 target facts，不演示 `fafafa.core.os` 里的 runtime probe。

## Current entry

- Linux/macOS：`examples/fafafa.core.platform/BuildOrRun.sh`
- Windows：`examples\fafafa.core.platform\BuildOrRun.bat`
- 示例源码：`examples/fafafa.core.platform/example_platform.lpr`
- Lazarus 工程：`examples/fafafa.core.platform/example_platform.lpi`

## What to run first

- `example_platform.lpr`
  - 输出 target OS / arch
  - 输出 pointer size / pointer bits
  - 展示 `Is32BitPlatform` / `Is64BitPlatform`

## Generated outputs

- `bin/` 和 `lib/` 只代表本地构建结果，不是 source-of-truth。
- current-entry 应回到 README、`BuildOrRun*` 脚本、`.lpr` / `.lpi` 源文件，而不是把生成产物当成稳定入口。
