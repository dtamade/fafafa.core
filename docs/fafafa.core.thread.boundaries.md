# fafafa.core.thread — 边界与异常语义（Boundary & Error Semantics）

目的：集中说明在关闭、拒绝、取消、超时等边界条件下，各 API 的返回值与副作用，确保一致性与可预期性。

## 线程池（ThreadPool）
- CreateCachedThreadPool
  - 策略：Core=0，Max=min(64, 4×CPU)，下界=8；避免无界扩张
  - 如需自定义上限，请使用带参数重载或 CreateThreadPool 显式指定
- 提交 Submit(…)
  - 参数非法：抛出 EInvalidArgument（由工厂/门面负责）
  - 池已 Shutdown/Terminated：按配置的 RejectPolicy 处理
  - 队列与线程均满：按 RejectPolicy 处理
- RejectPolicy 行为
  - rpAbort：抛出 EThreadPoolError；TotalRejected 与 RejectedAbort 递增
  - rpCallerRuns：在调用线程执行；不计入 TotalRejected；RejectedCallerRuns 递增
  - rpDiscard：静默丢弃；TotalRejected 与 RejectedDiscard 递增
  - rpDiscardOldest：丢弃最旧队列项后入队；TotalRejected 与 RejectedDiscardOldest 递增
- 指标
  - ActiveCount/PoolSize/QueueSize/QueuePeak
  - TotalSubmitted/TotalCompleted/TotalRejected
  - KeepAliveShrinkAttempts/Immediate/Timeout（收缩路径观测）

## 取消（Cancellation）
- 工厂：CreateCancellationTokenSource → Token
- 预取消（Pre-Cancel）
  - Spawn/Submit/Schedule 传入已取消 Token：返回 nil，不入队，不计入拒绝
- 执行中取消
  - 任务应轮询 Token.IsCancellationRequested 并尽快退出；库不会强杀线程

## Future
- WaitFor(timeout)
  - 返回 True 表示在超时前完成，False 表示超时
- OnComplete/ContinueWith/Map/AndThen
  - 至多一次触发；若已完成则注册后立即触发一次
- 状态
  - IsDone/IsCancelled 语义稳定；Fail(Exception) 接管异常所有权

## Channel
- CreateChannel(capacity)
  - capacity=0：无缓冲通道；Send 与 Recv 需握手配对
  - capacity>0：有缓冲通道；遵循容量限制
- Close()
  - 关闭后禁止发送（Send/SendTimeout 返回 False）；允许接收耗尽缓冲（无剩余时 Recv/TryRecv 返回 False）

## Scheduler
- CreateTaskScheduler / Schedule(task, delayMs[, token, data])
- Shutdown
  - 停止接受新任务；未到期的已排程任务将取消并计入取消指标
- 精度
  - 当前采用最小可用实现；后续将以时间堆/精确休眠替换轮询以提高精度与功耗表现

## Join / Select
- Join(Fs, timeoutMs)
  - 等待全部完成；超时返回 False
- Select(Fs, timeoutMs)
  - 返回首个完成的索引；超时返回 -1
  - 默认：编译器支持匿名引用时采用非轮询（回调聚合）；否则回退轻量轮询

## 平台与注意事项
- Windows/Unix 跨平台；Unix 控制台程序需首单元 uses cthreads
- 测试/示例含中文输出建议 {$CODEPAGE UTF8}

## 变更记录（与版本对齐）
- 2025-08-20：将 CreateCachedThreadPool 的 Max 从无界（MaxInt）收敛到 min(64, 4×CPU) 且≥8，并在本文档与主文档中标注

