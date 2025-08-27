# IThreadPoolMetrics — 对象池指标扩展

本页补充线程池指标接口 IThreadPoolMetrics 的新字段定义与使用建议，聚焦任务对象池（TaskItem pool）命中情况的可观测性。

## 新增指标字段

- TaskItemPoolHit: 从对象池借用成功的次数（命中）
- TaskItemPoolMiss: 借用时池为空而新建的次数（未命中→New）
- TaskItemPoolReturn: 归还到对象池的次数
- TaskItemPoolDrop: 因池已达上限而直接释放（Drop）的次数

说明：
- 以上计数为运行时近似值，在对象池锁/线程池锁的不同临界区内维护，避免交叉锁顺序带来的死锁风险
- 这些计数用于“趋势观测”，非严格事务一致性；读取时通过线程池内部锁保护

## 何时关注这些指标

- PoolHit 高：
  - 提示任务对象复用充分，减少了 New/Dispose 带来的小对象分配/释放开销
  - 若同时 PoolDrop 也偏高，可能池上限偏小，可适当调大上限
- PoolMiss 高：
  - 初期或突发峰值常见；若持续高，说明池容量不足或存在长尾未归还（需排查异常路径）
- PoolReturn 高：
  - 表示借/还路径正常闭环；与 PoolHit 一起观察复用效率
- PoolDrop 高：
  - 说明归还时池已满，存在释放；不一定是坏事，但若长期高可考虑调大上限或减小突发

## 如何读取

```pascal
var P: IThreadPool; M: IThreadPoolMetrics;
begin
  P := CreateThreadPool(2, 4, 60000, -1, TRejectPolicy.rpAbort);
  try
    M := P.GetMetrics;
    WriteLn('hit=', M.TaskItemPoolHit,
            ' miss=', M.TaskItemPoolMiss,
            ' ret=', M.TaskItemPoolReturn,
            ' drop=', M.TaskItemPoolDrop);
  finally
    P.Shutdown; P.AwaitTermination(3000);
  end;
end;
```

## 调优建议（默认上限：max(64, 4×Core)）

- 业务主要是“短小任务/高 QPS”：
  - 对象池作用更明显；建议观察 PoolHit/Miss 比例，必要时将上限从默认值适度调大
- 业务存在“长尾/异常路径”导致归还不及时：
  - 优先修正逻辑；对象池只是缓冲，无法替代正确的生命周期管理
- 关注 Drop：
  - 大量 Drop 可能说明上限过小或峰值极端；如内存允许，可适当提高

## 测试用例

- 参见 tests/fafafa.core.thread/Test_threadpool_metrics_pool.pas
  - 确认基本借/还路径被覆盖，指标计数非零

## 附：与其它指标的关系

- TotalSubmitted/TotalCompleted/TotalRejected：任务层面吞吐与拒绝
- ActiveCount/PoolSize/QueueSize：容量/负载即时观测
- TaskItemPool*：对象池内部复用效果的“微观指标”，用于定位小对象吞吐优化

