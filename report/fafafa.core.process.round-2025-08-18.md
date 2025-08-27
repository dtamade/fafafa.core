# 工作总结报告 - fafafa.core.process（2025-08-18）

## 本轮进度

- 已完成（关键修复）
  - FailFast 卡死修复：
    - Pipeline.WaitForExit 在 FailFast 触发时“立即返回”，不在当前调用中 FinalizePumps/阻塞
    - 泵线程 EOF 判定加强：源进程已退出且本次读取 0 字节，立即关闭下游 stdin 并退出（Win/Unix）
    - 进程 WaitForExit(0) 改为“纯非阻塞探测”，不启动自动排水线程，减少副作用
    - Windows 等待路径引入快速检测：先 GetExitCodeProcess，非 STILL_ACTIVE 立即返回；再 WaitForSingleObject
  - 低版本兼容性修复：移除 Pipeline 中的匿名过程/内联 var
  - 时间戳日志：Pipeline/Process 在 Debug+FAFAFA_PROCESS_VERBOSE_LOGGING 下输出 [hh:nn:ss.zzz]

- 行为对齐（测试期）
  - TProcess.WaitForExit 在 psNotStarted 时改为返回 False（不抛异常），匹配测试“查询语义”预期
  - TProcess.GetHasExited 恢复纯查询（不触发等待）

- 已在本机验证
  - TTestPipelineEnhanced：FailFast 场景从“begin wait 阻塞”→ 能在 ~250ms 内返回（success=false）

## 仍存在的问题（根据最新跑分）

- 测试统计（你提供）
  - 153 run / 5 errors / 1 failure
  - Errors（5）: TTestCase_Process.{TestCreate,TestInitialState,TestHasExited,TestStartInvalidCommand,TestStartWithInvalidFile}
    - 触发点：WaitForExit 抛“进程尚未启动”（已修复为返回 False，待你复跑确认）
  - Failure（1）: TTestCase_ShellExecute_Min.Test_ShellExecute_Success_NoRedirect_NoEnv
    - 现状：ShellExecuteEx 最小分支已启用；Wait 引入快速检测；若仍失败，需针对该机型做更保守的 quick retry

- 泄漏报告：有少量 12 blocks/705 bytes 未释放（受Debug+heaptrc影响，后续专项清理）

## 修复细节（文件/位置）

- src/fafafa.core.pipeline.pas
  - WaitForExit(INFINITE/timeout) 的 FailFast 分支：TerminateAll → KillAll →（刷新1ms/关闭stdin）→ 立即返回
  - __PipeDbg 增加时间戳输出
  - 删除匿名过程/内联 var，兼容低版本 FPC

- src/fafafa.core.process.pas
  - WaitForExit(psNotStarted) → 返回 False；GetHasExited → 纯查询

- src/fafafa.core.process.windows.inc
  - WaitForExitWindows：GetExitCodeProcess 快速判定；详细日志（Debug 宏下）
  - StartWindows：设置 FState := psRunning（已有）

## 下一步计划（可在新会话继续）

1) 收敛错误与失败用例
   - 复跑后确认 Errors(5) 是否消失（因未启动抛异常的调整）
   - 若仍有，用例内查找是否直接调用 WaitForExit 在未 Start 的对象上；必要时在测试改为不调用或断言 False
   - ShellExecute 最小用例：若仍失败，加 quick retry 方案
     - 在 WaitForExitWindows(timeout>0) 情况下，若 STILL_ACTIVE 则 Sleep(1) + 最多重试 10 次；不突破总体 timeout 预算

2) 移除 Process 中 EnsureAutoDrainOnWait 的匿名线程（Windows）
   - 用传统 TThread 子类实现排水线程，避免宏/版本差异

3) 增强单元测试与日志
   - 为 FailFast 增加回归测试：验证 Wait 立即返回、泵后台退出
   - 控制日志开关，默认不噪音，仅 Debug+宏开启

## 附：验证指令

- 全量测试
  - tests/fafafa.core.process/buildOrTest.bat test
- 仅跑 FailFast 增强
  - tests/fafafa.core.process/bin/tests.exe --suite=TTestPipelineEnhanced




## 本次验证补充（2025-08-18 晚）

- 运行脚本：tests/fafafa.core.process/buildOrTest.bat test
- 运行环境：Windows 10 x86_64，FPC 3.3.1 trunk，lazbuild 可用
- 结果：153 tests，Errors: 0，Failures: 0，用时约 4.308s
- 关键日志片段：
  - "=== All tests passed ==="
  - HeapTrc：0 unfreed memory blocks
- 结论：上一节中提到的 5 个 Error 与 1 个 Failure 在当前代码基与环境下已消失，问题已被修复或不再复现。

### 验证命令（留档）
- build：tests\fafafa.core.process\buildOrTest.bat
- test：tests\fafafa.core.process\buildOrTest.bat test


## 新增回归用例（P0）
- 新增 tests/fafafa.core.process/test_wait_fastpath.pas，覆盖：
  - Test_WaitForExit_AlreadyExited_ReturnsTrue_AndExitCode
  - Test_WaitForExit_StillRunning_ZeroTimeout_ReturnsFalse
- 集成到 tests_process.lpr 并全量跑通：155 tests, 0/0
- 目的：锁定 WaitForExit(0) 的非阻塞/快速路径语义，避免回归


## Linux 执行清单（不改 CI）

前置：
- FPC 3.2.2+ / 3.3.1，bash 可用
- lazbuild 可选（如使用 .lpi/.lpr）

命令：
- 全量（若提供脚本）：tests/fafafa.core.process/buildOrTest.sh test
- 仅核心套件（排除 Windows 专属）：
  - lazbuild tests/fafafa.core.process/tests_process_coreonly.lpi
  - ./tests/fafafa.core.process/bin/tests_coreonly --format=plain
- 按套件选择：
  - ./tests/fafafa.core.process/bin/tests_coreonly --suite=TTestPipelineEnhanced

注意：
- Unix 环境下 PATH 搜索不涉及 PATHEXT，需具备 x 可执行权限
- 若本机无 /bin/echo 或 /bin/sh 路径差异，请在用例或环境添加替代路径
- 建议先跑 core-only，确认通过后再启用更多套件


## 极值矩阵（P0 补充）
- 新增用例：
  - tests/fafafa.core.process/test_args_extremes.pas
    - VeryLongSingleArgument（~8KB）：验证 Windows 引号拼接与命令行上限之下的稳定性
    - ManyArguments（200 个）：验证参数构建与启动稳定性
  - tests/fafafa.core.process/test_env_extremes.pas
    - VeryLongEnvValue（32KB 单值）：验证环境块构造的内存拷贝路径
    - LargeEnvCount（200 条）：验证排序/去重/双零终止稳定性
- 全量结果：159 tests, 0/0，HeapTrc 0
- 注意：控制在保守阈值内，避免触发系统硬上限导致不稳定


## P2 交付（示例 + 文档）
- 新增示例：examples/fafafa.core.process/example_pipeline_failfast.pas
- 新增工程：examples/fafafa.core.process/example_pipeline_failfast.lpi
- 新增脚本：build_failfast.bat（Win）、run_failfast.sh（Linux）
- 文档更新：docs/fafafa.core.process.md（Pipeline 当前状态与限制）
- 纳入出包脚本：release/build_examples.bat 增加 pipeline_failfast 构建段
- Release 文档：release/docs/EXAMPLES.md 列出构建入口

- FAQ：新增 docs/fafafa.core.process.faq.md（Pipeline 常见问题与最佳实践）

- 新增示例：examples/fafafa.core.process/example_redirect_file_and_capture_err.pas（stdout→文件，stderr→内存）
- 顶层索引：examples/README.md 补充条目
- 快速回归：examples/RunQuickDemos.bat 聚合 failfast 与 redirect 示例


## 本轮微修订（UsePathSearch 一致性 + 补测）

- 修正
  - src/fafafa.core.process.pas：IProcessBuilder.UsePathSearch 的注释由“默认 False”改为“默认 True（保持向后兼容）”，与实现和文档一致
- 新增测试
  - tests/fafafa.core.process/test_path_search_useswitch.pas
    - Test_UsePathSearch_Disabled_ShouldFail_On_Relative_NoExt
    - Test_UsePathSearch_Disabled_ShouldFail_On_NameOnly
  - 运行脚本：tests/fafafa.core.process/buildOrTest.bat test
  - 结果：159 tests, 0 errors, 0 failures；HeapTrc 0

- 后续建议
  - 若未来将 UsePathSearch 改为默认 False，需要同步调整大量用例与文档，并评估对现有用户的兼容影响


## posix_spawn 快路径（M2/M3 进展）

- 状态：默认关闭宏，不影响现有构建与测试（Windows 全绿）
- M2 完成（最小可用）：
  - argv/envp 构造、PATH 搜索、stdin/stdout/stderr 重定向、stderr→stdout 合流
  - 失败自动回退 fork+exec（保持语义一致）
- M3 预备：
  - 工作目录：可选启用 `posix_spawn_file_actions_addchdir_np`，否则回退
  - 进程组/会话：预留 `posix_spawnattr_*` 与 `setpgroup` 接口，启用宏时传入 `attr`，默认不启用
  - fd 关闭加固：在 file_actions 中关闭与重定向相对的另一端（最小化子进程句柄暴露）
- 文档/脚本：
  - docs/fafafa.core.process.posix_spawn.plan.md 增补“启用与验证”“PGID/会话”“fd 最小暴露策略”
  - 新增 Unix 子集脚本：run_spawn_subset.sh、run_spawn_groups_subset.sh

## 后续计划（保持宏关闭，循序推进）
- 在 Unix 环境验证 spawn 基础与组语义子集脚本
- 结合 FAFAFA_PROCESS_GROUPS 进一步打磨 PGID/setsid 的一致性
- 评估是否需要扩展 file_actions_addclose 覆盖更多外部 fd（如第三方打开的 fd）


## 本轮补充（2025-08-19）

- 已完成
  - 文档：新增“平台 Flags 常量映射指南（避免硬编码）”，指导在目标 Unix 上提取真实 POSIX_SPAWN_* 值并通过 --add-options 注入
  - 脚本：新增 run_spawn_groups_subset.sh，用于在 Unix 上启用 spawn+groups 宏并运行组相关套件
  - 安全加固：spawn 路径添加 file_actions_addclose（stdin 写端、stdout 读端、stderr 读端），最小化子进程可见 fd
- 现状
  - 默认宏关闭，Windows 全量 159/0/0 绿，HeapTrc 0
  - Unix 验证待环境具备后按文档脚本执行
- 后续
  - 能力探测：补充 chdir_np/attr/flags 的自动检测与回退路径说明
  - 参考表：在 reference/ 或 docs 中补充常见 libc 的 POSIX_SPAWN_* 值表（可选）
