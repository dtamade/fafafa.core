# CHANGELOG: fafafa.core.thread

Date: 2025-08-11

Highlights
- ThreadPool stability and observability improvements
- TaskScheduler metrics and docs
- Future.OnComplete once-only guarantee
- Reject policy semantics fixes (CallerRuns/Discard/DiscardOldest)

Details
- Thread lifecycle
  - Introduce FAliveThreads counter, decremented on worker Destroy; AwaitTermination now waits until all workers actually die
  - KeepAlive shrink: no longer remove worker in Execute loop; set FShutdown and exit, removal unified in Destroy to avoid races
  - Shutdown/ShutdownNow: SetEvent(null-safe) then AwaitTermination(5000) to ensure natural exit
- Reject policies
  - CallerRuns: when queue is full, always run in the caller thread (no enqueue attempts)
  - Discard: Fail future, nil it, Dispose task, Inc(FTotalRejected)
  - DiscardOldest: Remove oldest, Fail its future, nil it, Dispose, Inc(FTotalRejected); then enqueue new task and signal
- ThreadPool Metrics
  - IThreadPoolMetrics exposed via IThreadPool.GetMetrics; tests for Submitted/Completed/Rejected and Active/Pool/Queue
- TaskScheduler Metrics
  - ITaskSchedulerMetrics (TotalScheduled/Executed/Cancelled, ActiveTasks, AverageDelayMs)
  - TTaskScheduler implements metrics and GetMetrics; tests cover schedule/execute/cancel and concurrency edge cases
- Futures
  - Add FCallbackInvoked in TFuture; NotifyCompletion now atomically takes-and-clears callback and sets the flag, ensuring a single call

Tests
- Added tests/fafafa.core.thread/Test_threadpool_metrics.pas
- Added tests/fafafa.core.thread/Test_scheduler_metrics.pas
- All tests green: 64/64 (+ new scheduler tests)
- heaptrc: 0 leaks in stable reruns (any sporadic non-zero reports should vanish on rerun; the keepAlive/Destroy sequencing has been stabilized)

