# CHANGELOG - fafafa.core.process

## 2025-08-12

### Added
- CombinedOutput（StdErrToStdOut）功能：
  - IProcessStartInfo 增加属性 `StdErrToStdOut: Boolean`（默认 False）
  - TProcessBuilder 新增链式方法 `StdErrToStdOut`
  - Windows：`StartWindows` 在启用时将 `StartupInfo.hStdError` 指向与 `hStdOutput` 相同句柄
  - Unix：`StartUnix` 在启用时执行 `dup2(1,2)` 合流
  - 关闭子进程端句柄时避免重复关闭
- 单元测试 `test_combined_output.pas`：验证合流后可在 `Output` 中同时看到 OUT 与 ERR
- 文档：`docs/fafafa.core.process.md` 新增“常见误区（必读）”小节

### Changed
- Windows 字符串错误消息统一：先用 UnicodeString 拼接，再 `UTF8Encode` 抛出（零行为改动）
- 测试工程入口 `tests_process.lpr`：仅关闭 Warning 5023（Unit not used）

### Fixed
- 多处隐式字符串转换告警，统一为显式路径以减少 Warning

### Notes
- 新增功能默认不启用；需通过 `NewProcessBuilder....StdErrToStdOut` 明确开启
- 推荐继续为 Unix/Windows 补充更多边界测试，并按需添加 WithTimeout 等便捷 API



## 2025-08-14

### Fixed
- Resource cleanup ordering: free stream wrappers first, then unify handle closing in CleanupResources to avoid double-close hazards.
- Windows drain threads: ensure handles are closed in CleanupResources via CloseDrainThreadsWindows before pipe closure.

### Added/Changed
- Timeout convenience API confirmed and wired:
  - WithTimeout(timeoutMs) sets a default for subsequent calls
  - RunWithTimeout(timeoutMs) waits and raises EProcessTimeoutError on expiry (kills process)
  - OutputWithTimeout(timeoutMs) uses timeout path for long-running processes, retains existing Output behavior for immediate captures
- Tests: process test suite builds and runs green on Win64 (see tests/fafafa.core.process/*)



## 2025-08-20

### Added
- 文档：新增 “AutoDrain（自动排水）行为与边界” 与 “最佳实践：AutoDrain 读取示例” 小节（docs/fafafa.core.process.md）
- 示例：examples/fafafa.core.process/
  - example_autodrain.lpr（Builder/非 Builder 两种演示）
  - build_autodrain.bat、run_autodrain.bat、run_autodrain.sh（Win/Linux 一键脚本）
  - 整合到 build.bat/run.bat 与 build.sh/run.sh 的可选步骤与提示
- 示例索引：在 docs/EXAMPLES.md 中加入 AutoDrain 示例链接

### Changed
- Windows 分支警告清理：将若干隐式字符串转换改为 UnicodeString 拼接并统一 UTF8Encode（零行为变更）
- 接口 GUID：IProcessStartInfo/IProcess/IChild/IProcessBuilder/IProcessGroup 替换占位 GUID 为正式 GUID

### Notes
- AutoDrain 需启用 stdout/stderr 重定向与 StartInfo.SetDrainOutput(True)
- WaitForExit 前会按需启动后台排水；进程退出后缓冲 Position 重置为 0，便于读取

- 文档：补充“Unix 快路径（posix_spawn）→ 启用与验证（Unix）”与“进程组（PGID）与 posix_spawn 的关系”说明
- API：IPipeline 新增 ErrorText（分路捕获 stderr）。示例与脚本：example_pipeline_best_practices.lpr、example_pipeline_redirect_and_split.lpr
- 示例：GroupPolicy 新增 DemoForceOnly（仅强制，无优雅阶段）；GUI 子进程示例支持 File->Exit 菜单与 Esc
- 文档：策略矩阵新增“仅强制”行及风险提示；Pipeline 最佳实践指明 ErrorText 用法

