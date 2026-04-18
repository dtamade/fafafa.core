# fafafa.core.base Tests

这个目录是 `fafafa.core.base` 当前测试入口。它负责说明 root runner、当前测试工程，以及根测试目录与其他基础模块之间的边界。

## 当前 source-of-truth

1. `docs/fafafa.core.base.md`
2. `tests/fafafa.core.base/BuildOrTest.sh`
3. `tests/fafafa.core.base/BuildOrTest.bat`
4. `tests/fafafa.core.base/fafafa.core.base.test.lpi`

## 当前测试集合

当前目录主要分成两组：

- 主测试工程
  - `fafafa.core.base.test.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.base.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.base\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.base/BuildOrTest.sh test`

如果你只想做构建检查：

- Linux/macOS：`bash tests/fafafa.core.base/BuildOrTest.sh check`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.base.test.lpi`
- 产物：`bin/fafafa.core.base.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.base.test.lpi`
- 产物：`bin\\fafafa.core.base.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`

## 当前边界

- 这个目录只覆盖 `base` 模块根测试入口，不负责 `option` / `result` 等上层基础原语的测试入口。
- `bin/`、`lib/`、`logs/` 是产物目录，不应被当成当前合同。
- 如果 README、脚本和工程文件冲突，以脚本与工程文件现状为准。
