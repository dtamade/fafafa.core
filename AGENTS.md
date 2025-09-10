# 仓库指南

## 项目结构与模块组�?- `src/` Free Pascal 单元（ObjFPC），命名�?`fafafa.core.<module>[.<submodule>]`（例�?`fafafa.core.bytes.pas`）�?- `tests/` 与模块镜像的测试，包�?Lazarus 项目（`.lpr/.lpi`）及辅助脚本；例�?`tests\\fafafa.core.yaml\\...`�?- `examples/` 用法示例；`benchmarks/` 性能基准；`docs/` 文档�?- 构建产物：`bin/`、`lib/`（git 忽略）。其他文件夹：`3rd/`、`design/`、`reference/`、`report/`、`out/`、`plays/`、`experiments/`、`todos/`�?
## 构建、测试与开发命�?- 先决条件：FPC + Lazarus。确�?`lazbuild` 位于 `PATH` 中（或设�?`LAZARUS_PATH`）�?- 构建并运行测试（Windows）：`tests\\fafafa.core.yaml\\buildOrTest.bat`（会生成并运�?`bin\\fafafa.core.yaml.test.exe --all --format=plain`）�?- 定向构建示例：`build_test.bat` 会构建并运行 `tests\\fafafa.core.atomic`�?- 直接使用 FPC 编译（示例）：`fpc -Mobjfpc -Sh -O2 -g -gl -Fu src -FE bin quick_test.lpr`�?- 清理产物：`clean.bat`（Windows）或 `./clean.sh`（Linux/macOS）�?
## 代码风格与命名规�?- 编译模式：`{$MODE OBJFPC}{$H+}`；源码为 UTF-8�?- 缩进�? 空格，不使用 Tab。保�?`uses` 列表整洁且最小化�?- 单元：小写点分命名；文件名与 `unit` 名一致�?- 类型/接口/异常：采�?PascalCase，分别以 `T*`、`I*`、`E*` 前缀（例�?`EInvalidArgument`）�?- 公共 API 优先撰写清晰的文档注释；以英文为主（必要时可附中文注释）�?
## 测试规范
- 将新测试放在 `tests/<module path>/` 下，结构�?`src/` 镜像对应�?- 测试单元命名：`Test_<unit>_*.pas`；测试项目以 `.test.lpr/.lpi` 结尾（如适用）�?- 推荐通过 `buildOrTest.bat` 运行，或�?FPC 直接编译测试 `.lpr`；保持测试可重复、快速�?
## 提交与拉取请求（PR）规�?- 尽量使用 Conventional Commits：`feat(core.bytes): add slice helpers`�?- 标题不超�?72 个字符，使用祈使句；正文简要说明做了什么与原因�?- PR 必须包含：摘要、受影响的单元（`fafafa.core.*`）、构�?测试方法（命令），以及如涉及 `benchmarks/` 则补充性能影响�?- 不要提交产物（`.o`、`.ppu`、`.exe`、`bin/`、`lib/`）。提交前请先清理�?- 关联相关 issue；为修复或特性新�?调整相应测试�?
## 面向 Agent 的说�?- 按上述目录布局创建文件；不要重命名公共单元�?- 为任意新模块镜像添加测试；新增对�?API 时同步更�?`examples/`�?- 变更应聚焦；避免仅格式化的提交和大而散、无关的重构�?

## 沟通语言
- 请使用中文（简体中文）与维护者交流。

