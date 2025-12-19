# 文档总索引（Docs Index）

本页汇总本仓库的主要文档、示例与贡献指南入口，方便快速导航。


## 最近更新（手动维护）
- 颜色模块（fafafa.core.color）
  - Palette 统一采样（单点/多点/非均匀 positions + 归一化）与性质测试（端点幂等、单调性、OKLCH hue 最短路径）
  - OKLCH→sRGB 色域策略：新增 GMT_PreserveHueDesaturate，采用“最大在域内 C”的二分搜索；测试改用性质断言并收紧 in-gamut 判定
  - Palette 策略对象化：新增 IPaletteStrategy/TPaletteStrategy（可序列化/可共享），示例与单元测试已覆盖
  - 新增示例：examples/fafafa.core.color/palette_demo.lpi（含 bat/ps1/sh 一键脚本）
  - 文档与示例入口优化：docs/fafafa.core.color.md、docs/CONTRIBUTING.color.md


## 贡献指南（Contribution Guides）
- 专项规范（fafafa.core.color）：[docs/CONTRIBUTING.color.md](CONTRIBUTING.color.md)
- 通用贡献流程与模板：[CONTRIBUTING.md](../CONTRIBUTING.md)

## 颜色模块（fafafa.core.color）
- 模块文档：[docs/fafafa.core.color.md](fafafa.core.color.md)
- 示例工程与脚本：
  - 工程：examples/fafafa.core.color/palette_demo.lpi
  - 主程序：examples/fafafa.core.color/palette_demo.lpr
  - Windows 批处理：examples\fafafa.core.color\RunDemo.bat
  - Windows PowerShell：./examples/fafafa.core.color/RunDemo.ps1
  - Unix/macOS：bash examples/fafafa.core.color/run_demo.sh
  - 对照示例（Clip vs Preserve）：examples/fafafa.core.color/example_clip_vs_preserve.lpr
  - 一键运行（Clip vs Preserve）：examples\\fafafa.core.color\\RunClipVsPreserve.bat
- 单元测试：tests/fafafa.core.color/

## 文件系统模块（fafafa.core.fs）
- 模块文档：docs/fafafa.core.fs.md
- 快速演示与一键脚本：
  - Windows：examples\\fafafa.core.fs\\example_resolve_and_walk\\buildOrRun.bat
  - Unix/macOS：examples/fafafa.core.fs/example_resolve_and_walk/buildOrRun.sh

## 字节模块（fafafa.core.bytes）
- 模块文档：[docs/fafafa.core.bytes.md](fafafa.core.bytes.md)
- BytesBuilder/Buffer 说明：[docs/fafafa.core.bytes.buf.md](fafafa.core.bytes.buf.md)
- 单元测试：tests/fafafa.core.bytes/
  - Linux/macOS：`bash tests/fafafa.core.bytes/BuildOrTest.sh check` / `bash tests/fafafa.core.bytes/BuildOrTest.sh test`
  - 统一发现：`RUN_ACTION=check bash tests/run_all_tests.sh fafafa.core.bytes` / `bash tests/run_all_tests.sh fafafa.core.bytes`
  - 直接运行：`./tests/fafafa.core.bytes/bin/fafafa.core.bytes.test --all --format=plainnotiming`

## 字符串构建器模块（fafafa.core.stringBuilder）
- 模块文档：[docs/fafafa.core.stringBuilder.md](fafafa.core.stringBuilder.md)
- 单元测试：tests/fafafa.core.stringBuilder/
  - Linux/macOS：`bash tests/fafafa.core.stringBuilder/BuildOrTest.sh check` / `bash tests/fafafa.core.stringBuilder/BuildOrTest.sh test`
  - 统一发现：`RUN_ACTION=check bash tests/run_all_tests.sh fafafa.core.stringBuilder` / `bash tests/run_all_tests.sh fafafa.core.stringBuilder`
  - 直接运行：`./tests/fafafa.core.stringBuilder/bin/fafafa.core.stringBuilder.test --all --format=plainnotiming`

## 环境模块（fafafa.core.env）
- 模块文档：docs/fafafa.core.env.md
- 发布说明：docs/RELEASE-NOTES-env.md
- 路线图：docs/fafafa.core.env.roadmap.md
- 单元测试：tests/fafafa.core.env/
  - Windows：`tests\run_all_tests.bat fafafa.core.env`（或 `tests\fafafa.core.env\BuildOrTest.bat`）
  - Linux/macOS：`bash tests/run_all_tests.sh fafafa.core.env`
  - 直接运行：`./tests/fafafa.core.env/bin/fafafa.core.env.test --all --format=plainnotiming`
- 示例：
  - Windows：`examples\fafafa.core.env\BuildOrRun.bat` / `BuildOrRun_Overrides.bat` / `BuildOrRun_Security.bat`
  - Linux/macOS：`bash examples/fafafa.core.env/BuildOrRun.sh run all`
- 文档示例验证：`./benchmarks/fafafa.core.env/bin/doc_examples_test`
- 基准：benchmarks/fafafa.core.env/BASELINE.md

## 终端模块（fafafa.core.term）
- 合约文档：docs/fafafa.core.term.contracts.md
- 事件语义与合并策略：docs/fafafa.core.term.events.md
- UI 帧循环与双缓冲 diff：docs/fafafa.core.term.ui_loop.md
- 更多（变更/指南）：docs/CHANGELOG_fafafa.core.term.md，docs/fafafa.core.term.md（若存在）

  - Paste 后端微基准与推荐：docs/benchmarks.md#term-paste-backends-微基准legacy-vs-ring，docs/fafafa.core.term.md#paste-后端选择与推荐配置
  - 速查分片（最佳实践）：docs/partials/term.paste.best_practices.md


## 线程与并发（fafafa.core.thread / lockfree）
- 指南与最佳实践：docs/fafafa.core.thread.md
- LockFree 门面与 API：docs/README_LOCKFREE.md，docs/LOCKFREE_API.md

## 网络与其他模块
- Socket 模块：docs/fafafa.core.socket.md（含“测试与示例快速开始”）
- 进程模块最佳实践：docs/fafafa.core.process.bestpractices.md

## JSON / YAML 等数据模块
- JSON 模块：docs/fafafa.core.json.md（含 Flags 索引与注意事项）
- JSON Core 运行说明：docs/json-core-usage-notes.md
- YAML 模块说明：docs/yaml-parser-notes.md

## 最佳实践与常用参考
- 最佳实践速查（中文/英文）：docs/BestPractices-Cheatsheet.md，docs/BestPractices-Cheatsheet.en.md
- 终端测试速查：docs/partials/term.testing.md（EN：docs/partials/term.testing.en.md）
- Collections 最佳实践分片：docs/partials/collections.best_practices.md

## 示例与索引
- 示例总索引：docs/EXAMPLES.md
  - Crypto 一键串联入口：Windows scripts\run-crypto-examples.bat / Linux/macOS ./scripts/run-crypto-examples.sh（支持 --clean）

- 示例代码根目录：examples/

## CI 与性能
- CI 指南：docs/CI.md（样例工作流与建议）
- 基准框架 Quickstart：docs/fafafa.core.benchmark.md

## FAQ 与其他
- 常见问题（FAQ）：docs/FAQ.md（英文：FAQ.en.md）
- 项目状态报告：PROJECT_STATUS_REPORT.md

—— 若有新增模块或文档，请同步更新本索引页。

