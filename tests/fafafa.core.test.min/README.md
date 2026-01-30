# fafafa.core.test.min — 最小可执行示例

该目录包含一个最小可执行的测试程序（tests_core_min.lpr），用于演示自研测试内核的顶层/子测试、Skip/Assume、Cleanup、以及报告生成（Console/JUnit/JSON）。

## 目录结构
- tests_core_min.lpr / .lpi：最小程序入口（使用 TestMain 运行器）
- BuildOrRun.bat / BuildOrRun.sh：构建与运行脚本（Windows / Bash）
- bin/：构建产物输出目录
- lib/：编译中间文件

## 先决条件
- 已安装 Lazarus + FPC，且 lazbuild 可用
  - Windows：优先使用仓库 tools\lazbuild.bat 解析 lazbuild 路径（无需额外配置）
  - Linux/macOS：确保 lazbuild 在 PATH 中

## 构建与运行
- Windows（CMD 或 PowerShell）
  - 构建：`cmd /c tests\fafafa.core.test.min\BuildOrRun.bat build`
  - 运行（控制台）：`cmd /c tests\fafafa.core.test.min\BuildOrRun.bat run --filter=control/`
  - 生成 JSON：`cmd /c tests\fafafa.core.test.min\BuildOrRun.bat run-json --filter=control/`
  - 生成 JUnit：`cmd /c tests\fafafa.core.test.min\BuildOrRun.bat run-junit --filter=control/`
  - 清理：`cmd /c tests\fafafa.core.test.min\BuildOrRun.bat clean`
- Linux/macOS（Bash）
  - 赋权：`chmod +x tests/fafafa.core.test.min/BuildOrRun.sh`
  - 构建：`tests/fafafa.core.test.min/BuildOrRun.sh build`
  - 运行（控制台）：`tests/fafafa.core.test.min/BuildOrRun.sh run --filter=control/`
  - 生成 JSON：`tests/fafafa.core.test.min/BuildOrRun.sh run-json --filter=control/`
  - 生成 JUnit：`tests/fafafa.core.test.min/BuildOrRun.sh run-junit --filter=control/`
  - 清理：`tests/fafafa.core.test.min/BuildOrRun.sh clean`

常用参数（传递给可执行文件）：
- 过滤：`--filter=substr`
- 生成 JUnit：`--junit=out/junit.xml`
- 生成 JSON：`--json=out/report.json`
- 禁用某监听器：`--no-console` / `--no-junit` / `--no-json`

## 顶层用例一览（示例）
- math/add（含子测试 edge/zero）
- string/equals
- control/flow（演示 Skip/Assume/Fail 组合）
- control/skip（根据 DEMO_SKIP 环境变量跳过，不计为失败）
- control/cleanup（成功断言，但 Cleanup 抛异常将把用例整体标记为失败，消息附带 [cleanup]）

示例：
- 触发 Skip（PowerShell）
  - `$env:DEMO_SKIP='1'; cmd /c tests\fafafa.core.test.min\BuildOrRun.bat run-json --filter=control/skip`
- 触发 Cleanup 失败（默认即失败，可直接运行）
  - `cmd /c tests\fafafa.core.test.min\BuildOrRun.bat run-json --filter=control/cleanup`

## Sink 适配与环境变量
可通过环境变量切换 Listener 到 Sink 适配器版本（统一报告内核）：
- FAFAFA_TEST_USE_SINK_CONSOLE=1
- FAFAFA_TEST_USE_SINK_JUNIT=1
- FAFAFA_TEST_USE_SINK_JSON=1

输出路径解析顺序：
1) 命令行 `--json=path` / `--junit=path`
2) 环境变量 `FAFAFA_TEST_JSON_FILE` / `FAFAFA_TEST_JUNIT_FILE`（当命令行未显式指定且未禁用对应 Listener）
3) 显式存在裸 `--json` / `--junit` 时，默认文件名为 `report.json` / `junit.xml`

示例：启用 JSON Sink 并生成报告（也可以直接使用 run-json）
- PowerShell：`$env:FAFAFA_TEST_USE_SINK_JSON='1'; cmd /c tests\fafafa.core.test.min\BuildOrRun.bat run --json`
- Bash：`FAFAFA_TEST_USE_SINK_JSON=1 tests/fafafa.core.test.min/BuildOrRun.sh run --json`

## 语义说明（要点）
- Skip/Assume：顶层与子测试均可使用；跳过不计为失败
- Cleanup：无论成功/失败/跳过都会执行（LIFO）。
  - 成功 + Cleanup 异常：整体标记为失败，并在消息中附带 [cleanup] 区块（列出所有异常）
  - 失败 + Cleanup 异常：原始失败保留，Cleanup 异常聚合到消息中
  - 跳过 + Cleanup 异常：记录日志，不改变跳过结果

## 快照（补充）
本最小程序未包含快照示例；如需文本/JSON/TOML 快照、及差异（diff）输出，请参考主文档：
- `docs/fafafa.core.test.md` 中“快照”与“差异输出（Diff）”章节


## 演示脚本（Windows）
- 一键演示顶层 Skip 与 Cleanup，并生成 JSON 报告到 out/
  - 运行：`powershell -NoProfile -ExecutionPolicy Bypass -File scripts\demo-top-level.ps1`
  - 若 lazbuild 未初始化将失败并提示；请先参照“常见问题”中的指引完成初始化

## 常见问题（Troubleshooting）
- 构建报错 `Invalid compiler ""`
  - 可能是 lazbuild 的编译器路径未初始化；可先运行一次 `tests\fafafa.core.test\BuildOrTest.bat test`，确保工具链与配置就绪
  - 或确认 `tools\lazbuild.bat` 指向的 lazbuild 可执行存在
- Linux/macOS 运行 `.sh` 提示权限不足：请先 `chmod +x` 赋权

## 参考
- 设计/Runner/Listener/Context 详解：`docs/fafafa.core.test.md`
- 快速上手（长文版）：`docs/fafafa.core.test.quickstart.md`

