# 开发计划日志 · fafafa.core.fs · 2025-08-18（Symlink 语义巩固）

## 今日目标
- 巩固 CopyTree/MoveTree 对符号链接的语义，与 Walk 的 FollowSymlinks 选项保持一致。

## 已完成
- TCopyTreeWalker.OnEach：当收到 S_IFLNK 时直接跳过（Follow=false 情况）；避免复制链接或其目标。
- 新增用例：Test_CopyTree_Symlink_FollowFalse_SkipsLink。
- 全量回归通过（101/101），heaptrc 无泄漏。

## 明日/后续计划
- 文档同步：
  - 更新 docs/partials/fs.best_practices.md，强调 Follow=false 跳过链接。
  - docs/fafafa.core.fs.md 的“目录树 Copy/Move”小节增加该语义说明与示例代码。
- 评估可选特性（待确认需求）：
  - CopySymlinksAsLinks 选项（复制链接本体），需跨平台能力探测与条件测试（Windows 受限）。
- 性能回归：
  - 使用 tests/fafafa.core.fs/BuildOrRunWalkPerf.bat 定期跑 Walk 基准，记录 summary。

