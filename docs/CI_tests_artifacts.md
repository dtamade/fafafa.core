# Tests Artifacts 指南（fafafa.core.test）

- 本地运行
  - 进入仓库根目录：
    - `tests\fafafa.core.test\BuildOrTest.bat test`
  - 产物位置：
    - Console 日志：`tests\fafafa.core.test\bin\last-run.txt`
    - JUnit XML：`tests\fafafa.core.test\bin\results.xml`
  - 说明：脚本已修正失败提示逻辑，编译失败不会误报 Build successful；若找不到 exe，将提示路径

- 生成 JSON 报告（可选）
  - 方式一：在自定义 runner 中添加 `--json=path`（若后续开放）
  - 方式二：使用 Listener（示例：`examples\fafafa.core.test\example_json_v2_cleanup.lpr`）

- CI 建议
  - 在 CI 任务中执行同样的 bat 脚本
  - 将 `bin\results.xml` 作为 JUnit 工件归档，`last-run.txt` 作为调试日志归档
  - 若开启 JSON V2 报告，归档生成的 `report.json`，并由后续流程解析 `tests[].cleanup`


- Runner 最佳实践（统一产物与退出码）
  - 设置环境变量：
    - FAFAFA_TEST_JUNIT_FILE=out/junit.xml
    - FAFAFA_TEST_JSON_FILE=out/report.json
  - 调用示例：
    - `tests\fafafa.core.test\bin\tests.exe --ci --fail-on-skip --top-slowest=5`
  - 退出码：0=通过；1=失败或跳过(启用 fail-on-skip)；2=Runner 自身错误

- 用例清单（供矩阵编排或选择性运行）
  - Windows: `powershell -File scripts\list-tests.ps1 -Filter core -CI`
  - Linux/macOS: `./scripts/list-tests.sh core`
  - 可选：`--list-json-pretty`、`--list-sort=alpha|none`、`--list-sort-case`

更多细节见 docs/fafafa.core.test.md → 章节「Runner 环境变量与退出码策略」。
- 冒烟检查（Bash，本地）
  - DEBUG_RAW=1 PRETTY_JSON=1 ./scripts/list-tests.sh core
  - 预期：stderr 打印 primary/fallback 状态，stdout 为 JSON 数组


