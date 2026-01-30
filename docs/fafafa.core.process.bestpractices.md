# fafafa.core.process: 最佳实践指南

本指南汇总模块在生产与开发中的推荐使用方式，覆盖默认配置、宏开关策略、进程组/会话、标准流与编码、资源安全、观测与测试、发布前检查等。

## 推荐默认配置
- 生产环境
  - 不启用任何 spawn/组相关宏（默认行为），保证跨平台稳定性
  - UsePathSearch 默认 True，除非需要强约束执行路径才显式关闭
  - 仅在必要时重定向标准流，避免无意义的后台排水
  - 关闭冗余日志；仅 Debug+宏时开启详细日志
- 开发环境
  - Windows：保持默认宏关闭，跑全量测试
  - Unix：先用子集脚本验证 spawn 快路径，再逐步扩大范围

## posix_spawn 快路径（Unix）
- 适用场景：多线程/高并发创建子进程，对 fork+exec 的写时复制/锁复制敏感
- 启用顺序（子集优先）：
  1) 基础能力：tests/fafafa.core.process/run_spawn_subset.sh
  2) PGID/会话：tests/fafafa.core.process/run_spawn_groups_subset.sh
- 宏控制（默认均关闭，按需启用）：
  - FAFAFA_PROCESS_USE_POSIX_SPAWN：启用 spawn 快路径
  - FAFAFA_POSIX_SPAWN_FILE_ACTIONS：启用重定向/合流/关闭无用 fd
  - FAFAFA_POSIX_SPAWN_CHDIR_NP：启用工作目录（平台支持时）
  - FAFAFA_POSIX_SPAWN_ATTR + FAFAFA_POSIX_SPAWN_SETPGROUP：启用 PGID/会话设置
  - FAFAFA_POSIX_SPAWN_FLAGS：提供平台真实的 POSIX_SPAWN_* 常量（通过构建注入）
- 平台 Flags 取值：参见 docs/fafafa.core.process.posix_spawn.plan.md“平台 Flags 常量映射指南”

## 进程组/会话（PGID/setsid）
- Windows：Job Object（KILL_ON_JOB_CLOSE）优先；失败回退策略清晰
- Unix：fork+exec 路径 setpgid/setsid 为主；spawn 路径在宏与平台支持时用 attr 设置，否则回退
- 终止策略：先优雅（SIGTERM/WM_CLOSE + GracefulWaitMs），后强杀（SIGKILL/TerminateJobObject）

## 标准流与编码
- 文本约定 UTF‑8；Windows 边界做 UTF‑16 转换
- 合流：需要 stdout+stderr 统一收集时启用 StdErrToStdOut；否则分别重定向
- 排水线程：仅在 Redirect 且输出量可能较大时启用 DrainOutput；退出时关闭读端促使收敛

## 路径搜索与参数
- UsePathSearch=True（默认）：开启 PATH(+PATHEXT) 搜索（Windows）；需要绝对路径安全时显式关闭
- 参数传递：
  - Windows：使用模块提供的引号/反斜杠规则构造命令行，避免 shell 注入
  - Unix：argv 直传，不走 Shell；如需 Shell 语义请在上层封装“受控 shell”接口

## 超时与终止
- WithTimeout/RunWithTimeout：两段式（先 Terminate 再 Kill）
- OutputWithTimeout：严格时间窗口场景使用；超时后立即清理资源

## 资源安全（强制）
- 父进程：pipe2(O_CLOEXEC)/fcntl(FD_CLOEXEC) 确保默认不继承
- 子进程（spawn 路径）：
  - file_actions adddup2 映射 0/1/2
  - file_actions addclose 关闭与重定向相对的另一端（stdin 写端、stdout 读端、stderr 读端）
- 任一路径失败或不支持：清理并回退 fork+exec，保持语义一致

## 观测与故障定位
- Debug + 宏启用详细日志（时间戳、Wait/ExitCode/errno）
- 异常应包含平台错误码与上下文（路径、参数摘要）

## 测试策略（TDD，轻量高效）
- 遵循测试命名/结构规范（TTestCase_类名/Global；Test_函数名_参数）
- 覆盖面最低要求：基本启动/退出码、重定向/合流、PATH 搜索、envp、工作目录、超时/终止、资源清理
- 子集脚本（Unix 优先）：run_spawn_subset.sh / run_spawn_groups_subset.sh
- Windows 全量回归：tests\fafafa.core.process\buildOrTest.bat test

## 版本与宏管理
- 全局配置：仅使用 src/fafafa.core.settings.inc
- 宏默认关闭；在本地/脚本中通过 --add-options 启用，不改默认工程设置
- 平台常量（如 POSIX_SPAWN_*）通过构建注入，避免硬编码

## 发布前检查（快速清单）
- Windows 全量测试绿；HeapTrc 0
- 文档链接可用；启用/验证章节可执行
- 默认构建未启用任何 spawn/组宏
- 本轮变更已记录于 report 与 todos

## 快速入口
- 启用与验证（Unix）：docs/fafafa.core.process.posix_spawn.plan.md
- 脚本：
  - tests/fafafa.core.process/run_spawn_subset.sh
  - tests/fafafa.core.process/run_spawn_groups_subset.sh

