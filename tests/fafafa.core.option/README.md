# fafafa.core.option Tests

这个目录是 `option` 模块当前测试入口。它负责说明主测试工程、当前 runner，以及 Windows root wrapper 和历史实现脚本之间的关系。

## 当前 source-of-truth

1. `docs/fafafa.core.option.md`
2. `tests/fafafa.core.option/BuildOrTest.sh`
3. `tests/fafafa.core.option/BuildOrTest.bat`
4. `tests/fafafa.core.option/buildOrTest.bat`
5. `tests/fafafa.core.option/fafafa.core.option.test.lpi`

补充说明：

- 仓库根 `tests/run_all_tests.bat` 当前只会递归发现 `BuildOrTest.bat` / `BuildAndTest.bat`
- 这里的大写 `BuildOrTest.bat` 是 Windows root wrapper，小写 `buildOrTest.bat` 继续承载具体实现

## 当前测试集合

当前目录主要分成两组：

- 主测试工程
  - `fafafa.core.option.test.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.option.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.option\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.option/BuildOrTest.sh test`

如果你只想做构建检查：

- Linux/macOS：`bash tests/fafafa.core.option/BuildOrTest.sh check`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.option.test.lpi`
- 产物：`bin/fafafa.core.option.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 当前是 Windows root wrapper
- 会委托给 `buildOrTest.bat`
- 目的是让 `tests/run_all_tests.bat` 可以发现 `option` 模块当前入口

### buildOrTest.bat

- 构建目标：`fafafa.core.option.test.lpi`
- 产物：`bin\\fafafa.core.option.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`

## 当前边界

- 根测试目录代表今天的主验证入口，不再让 `logs/`、`bin/`、`lib/` 一类产物目录冒充当前合同。
- 当前 shell / Windows root runner 都围绕 `fafafa.core.option.test.lpi -> bin/fafafa.core.option.test[.exe]` 这一条 today contract。
- 如果 README、脚本和工程文件冲突，以脚本与工程文件现状为准。
