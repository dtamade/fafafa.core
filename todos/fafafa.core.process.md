# todos: fafafa.core.process（进程组/进程树 A 计划）

## Windows（Job Object）
1. 启用并验证 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE：
   - SetInformationJobObject(JobObjectExtendedLimitInformation)
   - 单元测试：释放组对象后子树自动清理（仅在 CI 非交互会话下运行）
2. 错误可观测性：
   - OpenProcess/AssignProcessToJobObject 失败时携带 GetLastError 码与上下文
   - 测试：权限不足/进程已退出等边界
3. 能力探测与策略文档：
   - CTRL_BREAK 有效性（控制台共享要求）与回退
   - WM_CLOSE 仅最佳努力
   - GracefulWaitMs 建议默认值与上限

## Unix（PGID）
1. PGID 设置位置前移：
   - 在子进程（fork 后）调用 setpgid(0,0) 或 setsid，然后再 exec
   - 测试：EPERM 场景规避，kill(-pgid, sig) 覆盖
2. 优雅等待：
   - TerminateGroup 内采用非阻塞 waitpid 轮询（短间隔），代替 Sleep
3. 信号策略一致性：
   - Terminate=SIGTERM；KillTree/Kill=SIGKILL；文档与测试一致

## 通用
1. 文档：补充“组终止语义与局限”章节（Windows/Unix 差异与限制）
2. 测试：
   - 复杂流水线/合流输出下的组终止一致性
   - 大量并发子进程（10~50）下的 Job/PGID 收敛
3. Builder 便捷：
   - ProcessGroup.WithPolicy 的默认策略预设（e.g., GracefulWaitMs=300ms）

## 执行顺序建议
- P1：Windows KILL_ON_JOB_CLOSE + 错误码上抛
- P2：Unix setsid/setpgid 到子进程内 + waitpid 收敛
- P3：测试矩阵扩展 + 文档完善



---

# 当前轮待办（2025-08-18）

- P0 修复当前测试集红点
  1) 复跑确认：WaitForExit(psNotStarted) → False 的改动是否消除 5 个 Error
  2) ShellExecute 最小用例失败：
     - 若仍失败，在 WaitForExitWindows(timeout>0) 中对 GetExitCodeProcess=STILL_ACTIVE 增加最多 10 次 Sleep(1) 快速重试（不超过总 timeout）
     - 记录关键日志（仅 Debug+宏）：Wait 参数/返回、ExitCode 变化

- P1 兼容性清理
  - 移除 EnsureAutoDrainOnWait 中 Windows 匿名线程，改传统 TThread 子类（统一到 Unix 策略）

- P2 回归测试与日志
  - 为 FailFast 增加回归用例：验证立即返回、后台泵退出
  - 日志：保留时间戳开关，默认关闭，仅 Debug+宏启用

- P3 文档/报告
  - 更新 docs/fafafa.core.process.md：FailFast/Wait 语义、ShellExecute 能力边界
  - 更新 report：记录本轮变更、问题分析、后续计划


## 本轮微任务补充（2025-08-18 晚）
- [x] 统一 UsePathSearch 默认值注释（Builder 注释修正为默认 True）
- [x] 新增 UsePathSearch(False) 负路径用例（test_path_search_useswitch.pas）并全量通过
- [x] 完成 posix_spawn 快路径 M2（最小可用）接入，默认关闭不扰动
- [x] M3 预备：工作目录（chdir_np 可选）、PGID/会话（attr 占位与接线）、fd addclose 加固
- [x] 文档与脚本：plan.md 增补启用指南/PGID/fd 策略；新增 run_spawn_subset.sh / run_spawn_groups_subset.sh
- [ ] 后续（Unix 环境具备时）：运行子集脚本验证 spawn 与组语义
- [ ] 后续：根据平台 flags 值补充 POSIX_SPAWN_* 常量映射，并完善能力探测


## 下一步（待 Unix 环境）
- [ ] 运行 tests/fafafa.core.process/run_spawn_subset.sh（启用 FAFAFA_PROCESS_USE_POSIX_SPAWN）
- [ ] 运行 tests/fafafa.core.process/run_spawn_groups_subset.sh（启用 ATTR/SETPGROUP/FLAGS 宏）
- [ ] 若平台支持 chdir_np：加 -dFAFAFA_POSIX_SPAWN_CHDIR_NP 验证工作目录
- [ ] 通过“平台 Flags 常量映射指南”提取 POSIX_SPAWN_* 实值，并用 --add-options 注入
- [ ] 记录验证日志与平台版本，补充到 report
