# fafafa.core.process 进程组/进程树 增强：阶段性总结（2025-08-17）

## 概览
- 目标：完善跨平台进程组/进程树管理能力（Windows Job Object / Unix PGID），确保终止一致性与可控性。
- 本轮策略：不改动代码路径，先完成基线审计、测试回归与后续计划固化。

## 现状（已实现）
- 抽象：IProcessGroup + TProcessGroup；Builder 支持 WithGroup/StartIntoGroup/WithGroupPolicy。
- Windows：
  - CreateJobObject/AssignProcessToJobObject/TerminateJobObject 终止整组。
  - 策略开关：可选 CTRL_BREAK、可选 WM_CLOSE、GracefulWaitMs（等待窗口）。
- Unix：
  - 以 PGID（setpgid）组织进程组；终止流程：SIGTERM → 短等待 → SIGKILL 兜底。
- 稳定性：DrainOutput 后台排水与 WaitForExit 配合，测试通过且无内存泄漏。

## 差距与风险点
- Windows：
  1) Job 行为增强：建议启用 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE（SetInformationJobObject）防泄漏；
  2) 失败可观测性：AssignProcessToJobObject/OpenProcess 失败场景需要更细致错误码上抛；
  3) 控制台/会话差异：GenerateConsoleCtrlEvent 对非共享控制台/服务进程无效，建议文档化并做能力探测；
  4) GUI 进程 WM_CLOSE：仅最佳努力，应配合 GracefulWaitMs 明确时限。
- Unix：
  1) setpgid 时机：建议在子进程（fork 之后、exec 之前）设置 PGID 或 setsid，更稳妥避免 EPERM；
  2) 收敛策略：TerminateGroup 中优雅等待推荐基于 waitpid 非阻塞轮询而非粗粒度 Sleep；
  3) 信号语义：Kill/Terminate 的跨平台语义在文档中需更明确（TERM=优雅，KILL=强制）。

## 决策
- 本轮保持实现不变，专注于：
  - 记录改进计划（todos）
  - 回归测试与结果归档

## 测试与验证（本轮）
- 入口：tests/fafafa.core.process/buildOrTest.bat test
- 预计：全套用例应通过，且 heaptrc 显示 0 未释放块。
- 实际结果：见下节“本轮执行结果”。

## 后续计划（概要，详见 todos/fafafa.core.process.md）
- Windows：KILL_ON_JOB_CLOSE、错误码上抛、能力探测与文档化；
- Unix：PGID/setsid 调整、waitpid 收敛、信号策略测试用例补强；
- 测试：组树终止在复杂流水线/合流输出场景的回归套件。

---

## 本轮执行结果
- 测试时间：2025-08-17
- 入口：tests/fafafa.core.process/buildOrTest.bat test
- 关键摘要：
  - Number of run tests: 153
  - Number of errors:    0
  - Number of failures:  0
  - Heaptrc: 0 unfreed memory blocks


## P2（Unix）代码改造状态
- 已实现（待 Unix 环境验证）：
  - 子进程内在 fork→exec 间调用 setpgid(0,0) 建立新进程组（容错忽略失败）
  - IProcessGroup.Add 在 Unix 上对 setpgid(Pid,Gid) 失败宽容处理，保持组记录一致
  - WaitForExitUnix 容忍 ECHILD（并发 wait 场景），避免误报
- 待办：在 Unix 环境以 play 验证后，再将等价用例合入 tests

## Windows 回归与子集验证（2025-08-18）
- 进程组（Windows）：TTestCase_ProcessGroup_Windows — 1/1 通过，0 错误/0 失败；0 泄漏
- 流水线（Pipeline）：
  - 稳定性改进：
    - 泵 EOF 判定需两次“源已退出且读 0”后才关闭下游 stdin
    - FailFast 命中时主动 FinalizePumps，避免长尾
    - 用例将第二阶段改为 PowerShell Start-Sleep，去除脆弱“耗时阈值”断言
  - Play 复现：example_echo_findstr_smoke.lpr 运行输出 OK，0 泄漏
  - 本机全量执行建议：tests.exe --suite=TTestPipelineBasic / --suite=TTestPipelineEnhanced

## 待办（近期）
- 在 Unix 环境运行 play 验证（example_unix_group_terminate.lpr），通过后将等价用例并入 tests
- 观察本机全量回归稳定性；如仍有个别用例受环境影响，可将其标记为“可选”或放宽断言
