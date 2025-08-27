# CHANGELOG - fafafa.core.thread

## [Unreleased]
### Added
- TVecDeque 应用于线程池任务队列与 Channel 缓冲/配对等待队列，消除 Delete(0) 的 O(n) 退化
- 执行前取消：工作线程在执行任务体前检查 Token.IsCancellationRequested，已取消则 Future.Cancel 并跳过执行
- Channel 关闭语义：Close 后禁止发送，允许接收耗尽缓冲
- 新增独立基准：benchmarks/fafafa.core.thread/queue_bench.lpr（参数化线程数/队列容量/任务量/轮次）
- 新增测试：
  - Test_channel_close_drain（通道关闭后耗尽缓冲）
  - Test_threadpool_token_preexec_cancel（执行前取消）
  - Test_threadpool_queue_perf_baseline（队列性能功能覆盖）
  - Test_cancel_more_paths（更多取消路径）

### Changed
- 若干 Count 判定统一改为 GetCount；索引访问改为 TryGet/Front/PopFront

### Migration Notes
- 仅内部实现替换，对外接口不变；如你在外部代码直接使用了内部容器类型或依赖 TList 行为，请改用接口方法（QueueSize/Submit/Recv 等）
- Channel：关闭后允许耗尽缓冲；若业务依赖“关闭即不可再取”，请在调用层过滤


