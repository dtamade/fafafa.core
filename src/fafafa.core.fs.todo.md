
---
## 更新日志（2025-08-11 第四轮）
- 已完成：
  - 去除库单元 {$CODEPAGE UTF8}（highlevel/path/errors）
  - 统一测试脚本 BuildOrTest（bat/sh）
  - 新增路径测试单元并修复 GetCommonPath；补齐跨平台用例
  - 新增错误分类辅助（TFsErrorKind、FsErrorKind/IsNotFound/IsPermission/IsExists）及测试
  - 文档对齐（平台实现、错误模型、路径差异），版本 1.1
  - 编译器提示清理（多轮小步：Windows include 显式初始化、测试缓冲 FillChar、移除未用引用）
- 验证：
  - 全量 37 tests 通过；无内存泄漏；构建提示显著下降
- 待办优先级：
  1) 继续按需压低 Windows include 剩余保守提示（不改变行为）
  2) 评估并实现 Walk/WalkDir 高层 API（可下一轮）
  3) IFsFile 接口草案与迁移策略（中期）
---

# fafafa.core.fs 模块 TODO（规划与进度）

最后更新：2025-08-12（同步：59/59 通过；perf 脚本与文档已就绪；IFsFile/No-Exception 已落地）
负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）

---

## 现状评估（快速体检）
- 核心单元：src/fafafa.core.fs.pas（含平台分发 windows/unix.inc）已实现，API 以 fs_* 函数族为主，负错误码语义统一。
- 平台实现：
  - Windows：src/fafafa.core.fs.windows.inc（覆盖 open/close/read/write/stat/…/realpath/mkdtemp/mkstemp）。
  - Unix：src/fafafa.core.fs.unix.inc（覆盖同等 API）。
- 高层封装：
  - src/fafafa.core.fs.highlevel.pas（TFsFile 及 Read/Write/Flush/Truncate 等便利函数）。
  - src/fafafa.core.fs.path.pas（路径分析/规范化/验证/转换等）。
- 测试：tests/fafafa.core.fs/（fpcunit，含 Test_fafafa_core_fs.pas 与 tests_fs.lpi/lpr）。
- 示例：examples/fafafa.core.fs/（多示例与构建脚本/README）。
- 文档：docs/fafafa.core.fs.md（API 与架构说明）。

发现的问题/不一致：
1) 编码指令：library 单元不应包含 {$CODEPAGE UTF8}，但 highlevel.pas 与 path.pas 目前包含（仅测试/示例/可执行入口允许）。
2) 文档列出 darwin.inc，代码库仅有 windows/unix.inc（需核定：合并到 unix.inc 还是单独补充）。
3) 测试脚本命名规范：规范建议 BuildOrTest.bat/BuildOrTest.sh；当前 tests/fafafa.core.fs 有 buildOrTest.bat（大小写与前缀不统一）。
4) 路径 API 体量较大，需对照竞品模型（Rust std::fs / Go os+filepath / Java NIO Files）进行一次接口一致性与边界行为核对；完善缺失测试。
5) 错误语义：Windows 侧 fs_open 通过全局 LastFsErrorCode 保留 GetLastError，是否需要统一一个对外错误查询/翻译帮助方法（参考 src/fafafa.core.fs.errors.pas）。

---

## 目标与原则（对齐项目规范）
- 面向接口抽象：优先定义接口，再由实现类承载；评估为 TFsFile 引入接口 IFsFile 的必要性（保持兼容，分阶段推进）。
- 跨平台一致性：统一行为与错误语义；必要时通过文档明确差异。
- TDD：先补齐缺失测试，再做改动；覆盖率目标 100%，异常路径使用 AssertException（结合宏）。
- 性能优先：保持零拷贝/批量操作/系统调用直达的特点；不做多余抽象开销。

---

## 本轮计划（最小增量）
1) 竞品调研与差距清单（Rust/Go/Java FS & Path）
   - 输出：短文档（docs/fafafa.core.fs.benchmark-design.md 或追加到现有文档章节）。
   - 结论：列出 API/行为/错误模型差距与取舍建议。

2) 规范化修正（不改变行为）
   - 移除 highlevel.pas 与 path.pas 中的 {$CODEPAGE UTF8} 指令。
   - 统一测试构建脚本命名为 BuildOrTest.bat/BuildOrTest.sh（调用 tools/lazbuild.bat）。

3) 测试补齐与对齐
   - 路径模块边界：Normalize/Resolve/ToRelative/IsSubPath/FindCommonPrefix 等跨平台差异用例。
   - 平台差异：Windows fchmod 返回不支持路径、symlink/readlink 行为校验。
   - realpath/mkdtemp/mkstemp 缓冲区与模板边界用例。

4) 文档对齐
   - 修正 Darwin 实现说明（合并或新增），记录平台差异与错误语义。

5) 中期设计准备（不立刻修改代码）
   - 起草 IFsFile 接口草案（方法、异常/错误策略、与 TFsFile 兼容策略）。

6) 性能基线与按需运行
   - Windows/Linux 一键 perf（BuildOrRunPerf.*）与归档（ArchivePerfResult.*）已完成；默认按需/夜间运行。

---

## 任务清单（跟踪）
- [x] 竞品模型调研与差距报告（Rust/Go/Java）
- [x] 移除 library 单元中的 {$CODEPAGE UTF8}（highlevel/path）
- [x] 统一测试脚本为 BuildOrTest.bat/.sh（调用 tools/lazbuild.bat）
- [x] 路径 API 边界与平台差异测试补齐（ResolvePathEx 已覆盖；Windows 长路径用例按条件执行）
- [ ] fs_* 高级用例补齐（mkdtemp/mkstemp/realpath/flock/fchmod 等）
- [ ] 文档修正（Darwin/差异说明/错误语义）
- [x] 引入 IFsFile 接口与 TFsFile 实现、No-Exception 包装与测试（已完成）
- [x] perf 程序参数化与一键脚本/归档脚本（Windows/Linux）
- [ ] IFsFile 接口迁移计划（文档）


- [x] 文档对齐（核心类型与签名示例）：TfsStat 示例、fs_open 签名风格、fs_stat 签名
- [x] 提示清理（库源码第一轮，保守）：初始化/移除明显未用局部；不改行为；全量回归 82/82 通过

- [x] 测试清理：Windows 长路径用例轻量清理，保持条件化与全绿

- [x] 示例工程：examples/fafafa.core.fs/example_resolve_and_walk（ResolvePathEx / WalkDir，含 buildOrRun.bat）

---

## 决策与约束
- 不引入新依赖；仅使用现有 settings.inc 宏体系。
- 行为不变更的修正优先；破坏性变更需先文档与测试冻结期后执行。

---

## 备注（持久记忆）
- Windows: fs_open 保留 LastFsErrorCode；若要统一对外错误翻译，优先在 fs.errors 增加帮助函数，不改变现有返回值语义。
- 示例项目 README 多版本并存（README/README_BUILD/README_FINAL），后续可收敛为一份权威文件。

