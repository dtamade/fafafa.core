# fafafa.core.platform 示例

这个目录给出 `fafafa.core.platform` 的最小使用方式，只演示静态 target facts，不演示 `fafafa.core.os` 里的 runtime probe。

## 示例列表

- `example_platform.lpr`
  - 输出 target OS / arch
  - 输出 pointer size / pointer bits
  - 展示 `Is32BitPlatform` / `Is64BitPlatform`

## 构建与运行

- Windows：`examples\\fafafa.core.platform\\BuildOrRun.bat`
- Linux/macOS：`./examples/fafafa.core.platform/BuildOrRun.sh run`
