# 开发计划日志：fafafa.core.os

更新时间：2025-08-22
负责人：Augment Agent

## 当前目标（本轮）
- 建立模块骨架与最小 API（环境变量 + 基础平台信息）——已完成
- 对齐仓库规范（docs/report/todos/tests）——已完成

## 现状与基线
- 测试工程存在，Windows 本地直运行 tests_os.exe 退出码 0；后续在 Linux/macOS 上回归
- 文档与示例齐备：example_basic / example_capabilities 可构建与运行

## 下一步（短期）
- [ ] 单测补充：Windows 环境变量大小写不敏感行为验证（已有基础用例，细化断言与负例）
- [ ] 单测补充：临时目录与 HOME/USERPROFILE 回退链路（Windows/Unix 各自验证）
- [ ] 单测补充：locale/timezone 规范化的软约束（长度/字符集/连接符）
- [ ] 扩展 API：用户/组 ID（Unix）、会话/TTY 信息（接口草案+软实现）
- [ ] 融合到 plays/：快速演示与调试脚本

## 远期计划
- [ ] 能力探测：WSL/容器/K8s/CI 环境标识的更多信号与回退
- [ ] 环境变量快照/差异与合并工具
- [ ] 与 process 模块的更紧密集成（继承/覆盖 env 策略）



## 本轮审阅补充（2025-08-27）
- 规范化任务：去除所有内联变量/for var 写法，统一至函数 var 段（不改 API/行为）。
- 构建限制：当前环境无 lazbuild/fpc；建议在具备工具链的环境进行一次 Linux/macOS 回归。
- 测试补充计划：
  - [ ] os_lookupenv 边界：未定义 vs 定义为空（Windows/Unix 各 1 条）
  - [ ] os_exe_path macOS 分支最小用例（_NSGetExecutablePath 回退路径）
- 里程碑：完成规范化后，标记 report/fafafa.core.os.md 并附构建/运行日志。
