# Examples for fafafa.core.env

本目录收纳 `fafafa.core.env` 的示例入口，覆盖 quickstart、overrides 和 security 三条常见路径。

## Current entry

- Linux/macOS：`examples/fafafa.core.env/BuildOrRun.sh`
- Windows：
  - `examples\fafafa.core.env\BuildOrRun.bat`
  - `examples\fafafa.core.env\BuildOrRun_Overrides.bat`
  - `examples\fafafa.core.env\BuildOrRun_Security.bat`
- 示例源码：
  - `examples/fafafa.core.env/example_quickstart.lpr`
  - `examples/fafafa.core.env/example_overrides_showcase.lpr`
  - `examples/fafafa.core.env/example_security_showcase.lpr`

## What to run first

- quickstart：`examples/fafafa.core.env/example_quickstart.lpr`
- overrides：`examples/fafafa.core.env/example_overrides_showcase.lpr`
- security：`examples/fafafa.core.env/example_security_showcase.lpr`

如果你只是想确认 examples current-entry 是否仍然正确，优先用 `BuildOrRun.sh` 或 `BuildOrRun.bat`，再按目标场景切到 overrides / security 专用脚本。

## Generated outputs

- `bin/` 和 `lib/` 只代表本地构建结果，不是 source-of-truth。
- current-entry 应回到 README、`BuildOrRun*` 脚本、`.lpr` / `.lpi` 源文件，而不是把生成产物当成稳定入口。
