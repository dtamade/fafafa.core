# fafafa.core.thread — 本轮维护工作总结（2025-08-14）

## 进度与结论
- 模块现状：src 下 thread 子模块（facade/threadpool/future/channel/scheduler/threadlocal/cancel/constants/debuglog/sync）结构完整、接口稳定，已对齐门面导出。
- 本轮验证：完成线程模块全量单元测试构建与运行，全部通过，无内存泄漏。
- 结论：当前实现达到可用与稳定标准，可在后续轮次做增量优化（取消/Select 一等 API、Scheduler 精度等）。

## 已完成项
- 代码审阅：快速核对门面与子模块 API 一致性；参数校验约束（CreateThreadPool/Fixed/Cached/Single）。
- 构建与测试：
  - 构建 tests\fafafa.core.thread 成功，生成 bin/tests_thread.exe。
  - 运行测试（plain 输出）：N=83, Errors=0, Failures=0，总耗时 ~15.6s；heaptrc 报告 0 未释放块。
- 文档审查：docs/fafafa.core.thread.md 与 metrics 文档覆盖指标与用法，示例项目存在且可构建。

### 测试摘要（关键指标）
- 线程池：拒绝策略（Abort/CallerRuns/Discard/DiscardOldest）、队列容量=0、keepAlive 缩容→均通过。
- Future：WaitFor/Timeout/OnComplete/ContinueWith/Map/AndThen/取消辅助→均通过。
- Channel：capacity=0 握手、公平性（MPMC 分布）→通过。
- Scheduler：延迟调度、顺序、指标与取消→通过。

## 发现的问题与处理
- 暂未发现功能性错误；代码中个别 DEBUG 下线程命名封装宏较复杂但已能通过编译与测试。
- 若开启 FAFAFA_THREAD_DEBUG，日志输出将增多；发布建议保持关闭。

## 风险与限制
- Scheduler 延迟精度为毫秒级（10–50ms 时间片），不适用硬实时。
- 取消为“协作式”，尚未贯穿所有路径（池级别取消/任务中断）。

## 后续计划（下一轮建议）
1) API 增强
- Select 一等 API：在门面提供非轮询版（基于 OnComplete + channel 的完成事件聚合）。
- 取消增强：
  - IThreadPool.Submit(…, Token) 与 ITaskScheduler.Schedule(…, Token) 深度支持；
  - Future.Cancel 传播策略与 WaitFor 可取消版本一致化。
- 指标补充：平均队列等待时间、任务执行时间采样（低开销）。

2) 性能与鲁棒性
- Scheduler 改为“最小堆/时间轮”以降低 Wake/扫描成本，提高精度。
- 线程命名：完善 Windows SetThreadDescription 与 POSIX pthread_setname_np 的动态调用分支，保持无硬依赖。

3) 文档与示例
- 增补 docs/fafafa.core.thread.md 的“取消语义与最佳实践”章节。
- 示例：增加 Select/取消/背压（CallerRuns + queue=0）的综合示例。

## 附：测试运行要点
- 构建：tests\fafafa.core.thread\BuildOrTest.bat test
- 运行：bin\tests_thread.exe --format=plain --all
- 结果（摘要）：Time≈15.6s N=83 E=0 F=0 I=0；Heap: 0 未释放块



# 更新记录 — 2025-08-15（小修复）

- 进度与已完成
  - 修复门面 Sleep/Yield 的跨平台精度问题：Sleep(50) 在部分平台上偶发>100ms，导致单测波动。
  - 新实现采用“分片睡眠 + 末端让权”策略：>20ms 切 10ms 片；>5ms 切 1ms 片；最后 0ms 让权，降低过度超时概率。
  - 统一 Yield 语义为 Sleep(0)（让权而非强制 1ms），降低不必要延迟。

- 验证
  - 重新运行 tests\fafafa.core.thread\BuildOrTest.bat test：N=83 E=0 F=0，heaptrc 0 泄漏。

- 影响评估
  - 行为兼容：Sleep(0) 与 Yield 均让权；非 0 Sleep 更贴近目标时长，对上层时间语义更稳健。
  - 风险极低：变更 confined 于 fafafa.core.thread 门面，不影响线程池/通道/调度器逻辑。

- 后续计划（保持不变）
  - 继续推进 Select 一等 API、取消 Token 透传与 Scheduler 精度优化（见 todos）。


# 更新记录 — 2025-08-15（Select 稳定性）

- 进度与已完成
  - 维持 Select 为默认“轻量轮询 + 短 WaitFor”路径，避免回调模型在不同 FPC 开关上的兼容风险
  - 调整文档，明确 Select 语义与实现策略；后续在匿名引用开关稳定后再切换非轮询实现
- 验证
  - 全量测试 N=83 E=0 F=0 I=0；heaptrc 未发现泄漏
- 后续计划
  - 继续收敛 TTaskScheduler 的 NextSleepMs 算法（时间堆/时间轮替换不改变接口）
  - 评估在 CI 上启用匿名引用宏的独立作业，以准备回调式 Select 的切换


- 新增宏（可选）：FAFAFA_THREAD_SELECT_NONPOLLING
  - 在启用匿名引用宏下可切换 Select 到“回调聚合”实现；默认仍用轻量轮询
  - 已更新 docs 说明；建议CI新增开启该宏的作业，进行兼容性与性能观察


- 默认行为更新（Select）
  - 当编译器支持匿名引用时，默认启用“非轮询（回调聚合）”Select，实现更低 CPU 忙等
  - 提供回退宏 FAFAFA_THREAD_SELECT_FORCE_POLLING，可一键回退到“轮询 + 短 WaitFor”
  - 相关工作流：thread-select-nonpolling.yml（并行验证）、thread-select-bench.yml（手动基准）


# 本轮维护工作总结（2025-08-16）

## 进度与结论（2025-08-16）
- 模块现状：src 下 thread 子模块（facade/threadpool/future/channel/scheduler/threadlocal/cancel/constants/debuglog/sync）结构完整、接口稳定，已对齐门面导出。
- 本轮验证：完成线程模块全量单元测试构建与运行（87 项），全部通过，heaptrc 报告 0 泄漏。
- 结论：当前实现达到可用与稳定标准，可在后续轮次做增量优化（Select 非轮询聚合、取消增强、Scheduler 精度等）。

## 已完成项
- 门面统一导出：Spawn/SpawnBlocking/Join/Select/Channel/ThreadLocal/CountDownLatch/Scheduler
- 线程池：拒绝策略（Abort/CallerRuns/Discard/DiscardOldest）、队列容量=0、keepAlive 收缩
- Future：OnComplete/ContinueWith/Map/AndThen 组合语义一致；WaitFor/Timeout/取消辅助
- Channel：无缓冲握手、公平性（MPMC 分布）
- Scheduler：延迟任务、顺序与指标视图
- 文档：面向用户的 API 摘要与注意事项

### 测试与验证摘要
- 线程池：拒绝策略/队列容量=0/keepAlive 缩容 → 通过
- Future：WaitFor/Timeout/OnComplete/ContinueWith/Map/AndThen/取消辅助 → 通过
- Channel：capacity=0 握手、公平性（MPMC 分布） → 通过
- Scheduler：延迟调度、顺序、指标与取消 → 通过
- 日志参考：tests/fafafa.core.thread/logs/last.txt（UTF8 控制台输出，87/0/0）

### 在线调研（MCP 摘要）
- Rust Tokio：spawn/spawn_blocking 对应 Spawn/SpawnBlocking；一次性回调语义与 Promise.then 类似
- Go channels：capacity=0 同步握手语义 → 已实现；容量>0 缓冲通道可扩展
- Java Executors/CompletableFuture：keepAlive/拒绝策略；thenApply/thenCompose 映射 Map/AndThen/ContinueWith
- FreePascal：Windows/Unix 抽象一致；Unix 下部分超时用轮询以保证稳定

## 发现的问题与处理
- 本轮未发现新问题；对 OnComplete 的语义做回归核验：
  - 未完成时注册 → 存档一次性回调；完成后触发一次
  - 已完成后注册 → 在锁外立即调用一次；不依赖内部 FCallbackInvoked 标志

## 后续计划（下一轮建议）
1) API 增强
- Select 非轮询一等 API：在门面提供回调聚合实现（基于 OnComplete + Channel/事件），匿名引用可用时默认采用
- 取消增强：
  - IThreadPool.Submit(…, Token) 与 ITaskScheduler.Schedule(…, Token) 的 Token 传播与一致化
  - Future.WaitOrCancel（与 Token 联动）与文档化策略
- 指标补充：平均队列等待时间、任务执行时间采样（低开销）

2) 性能与鲁棒性
- Scheduler 改为“最小堆/时间轮”以降低 Wake/扫描成本，提高精度
- Channel MPMC 公平性微调（高负载尾部倾斜场景）

3) 文档与示例
- Quickstart：补充取消/Select/CallerRuns 背压综合示例与最佳实践
- Metrics 文档完善与 JSON 示例



# 本轮维护工作总结（2025-08-18）

## 进度与结论
- 修复 ITaskScheduler 在“提交后到期前取消”场景下仍执行任务的问题：现已在到期分发前检查 Token 并取消 Future，任务不再执行。
- 回归构建与测试：tests/fafafa.core.thread/BuildOrTest.bat test → N=98 E=0 F=0，heaptrc 未发现未释放。

## 关键变更
- scheduler：
  - TScheduledItem 增加 Token 字段；
  - TimerLoop 分发前检查 Future.IsCancelled 与 Token.IsCancellationRequested；
  - 带 Token 的 Schedule 创建 Future 时消除 IFuture/TFuture 不安全强转。

## 验证
- 命令：tests/fafafa.core.thread/BuildOrTest.bat test
- 结果：退出码 0；输出显示 Number of failures: 0；Time≈17s

## 风险与影响
- 仅限内部实现，接口未变；对性能影响极小（一次条件判断）。

## 后续计划
- 线程池 Submit 的 Token 支持与调度器语义一致化
- Scheduler 数据结构优化（最小堆/时间轮），提高精度与低开销
- 文档补充取消语义与最佳实践（已更新 docs/fafafa.core.thread.md）


## 本轮补充（2025-08-18 第二次提交）
- 线程池 Submit(…, Token) 支持预取消（Token 已取消直接返回 nil，不入队），避免无意义任务进入队列；队列中取消不做激进剔除，执行时协作式检查
- 修复此前引入的 GetNextTask 锁内错误，回滚为安全流程，消除卡死
- keepAlive 收缩：放宽限频与提高判定频率，空闲后能回落到 Core；对应测试通过
- 调度器顺序用例回归通过，确保按 DueAt 顺序分发
- 全量测试：N=98 E=0 F=0，heaptrc 0 未释放



# 本轮小修复 — 2025-08-18（Sleep/Yield 一致性 + BuildOrTest.bat 健壮性）

- 变更
  - 门面类 TThreads.Sleep/Yield 改为委派到本单元全局 Sleep/Yield，确保与门面全局实现保持一致（分片睡眠 + Sleep(0) 让权），避免双路径语义不一致。
  - 修复 tests/fafafa.core.thread/BuildOrTest.bat 顶部自调用导致的递归问题：改为标准入口参数 MODE 串联到下方主逻辑，支持从任意 cwd 执行。
- 验证
  - 代码编译在本地环境通过；完整测试因外部单元（fafafa.core.sync）编译错误暂未跑通，此修复不涉及 sync 模块，建议待 sync 编译错误修复后复跑线程套件。
- 风险评估
  - 改动仅限门面委派与测试脚本，行为兼容；无接口变更。
