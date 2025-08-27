# fafafa.core.thread 调优与实现说明

## 性能实现要点
- 任务队列与通道缓冲均使用 TVecDeque（环形缓冲）实现：
  - 出队采用 PopFront，入队采用 PushBack，避免 TList.Delete(0) 导致的 O(n) 退化
  - 在锁保护下与事件（IEvent）配合，保持原阻塞/唤醒语义不变
- 协作式取消（Token）：
  - 预取消：Submit(…, Token) 时若 Token 已取消，直接返回 nil，不入队
  - 执行前取消：工作线程在执行任务体前检查 Token.IsCancellationRequested，已取消则 Future.Cancel 并跳过执行
- 通道关闭语义：
  - Close 后禁止发送（Send 返回 False）
  - 允许接收耗尽缓冲（缓冲为空且已关闭时，Recv/TryRecv 返回 False）

## 可调优参数与开关
- WaitSliceMs（fafafa.core.thread.constants）
  - 用于拆分等待片段，防止长时间阻塞导致关闭/取消响应不及时
  - 默认 10ms，可按场景微调（低延迟可减小；低 CPU 占用可适度增大）
- 线程池观测开关
  - 代码开关：TThreadPool.SetObservedMetricsEnabled(True/False)
  - 环境变量：FAFAFA_POOL_METRICS=1 等价启用（轻量观测：队列驻留时间平均值）
- 任务对象池上限
  - 环境变量：FAFAFA_THREAD_TASKITEMPOOL_MAX（>=1 生效）
  - 默认上限 = 4 × Core，至少 64
- 测试快模式（示例）
  - FAF_TEST_KEEPALIVE_MS：覆盖 keep-alive 超时
  - FAF_TEST_FAST=1：缩短测试关键超时以提速

## 设计抉择与迁移
- 为什么使用 TVecDeque 而非无锁 MPMC：
  - 在“有锁 + O(1) 队列 + 事件”下，常见并发（≤8~16）已能提供稳定吞吐与较低延迟
  - 无锁队列需要额外的阻塞/唤醒协调与内存回收策略（hazard/epoch），实现与验证成本高
  - 后续可作为可选策略或在工作窃取架构中引入
- 迁移影响面：
  - 对外接口不变；内部容器替换
  - 依赖 fafafa.core.collections.vecdeque；需在相关单元 uses 中引入

## 最佳实践
- 线程池
  - 有界队列 + rpCallerRuns 配合 Token，形成平滑背压
  - 在任务边界（I/O/循环/批处理）检查 Token 并设置合理超时
- 通道
  - 明确数据所有权（指针仅搬运，不托管内存）；必要时引入包装器或释放回调
  - 关闭后允许耗尽缓冲，发送端需感知返回值并止损
- 指标与监控
  - 仅在需要时开启轻量观测；生产环境建议只暴露必要指标

