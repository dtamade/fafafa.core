# 异步日志 Sink 与信号量最佳实践 / 常见陷阱

本节记录在实现与使用异步日志（TAsyncLogSink）以及线程池入队路径时的一些经验与踩坑。

## TAsyncLogSink 的信号量配对
- 设计：
  - 生产者（Enqueue）在成功入队前 Acquire(NotFull)，入队后 Release(NotEmpty)
  - 消费者（Dequeue/Worker）在出队前 Acquire(NotEmpty)，出队后 Release(NotFull)
- 析构（Destroy）：
  - 仅需唤醒可能在等待非空的消费者：Release(NotEmpty)
  - 不要额外 Release(NotFull)。NotFull 在创建时最大计数 = 容量，额外增加会触发 ELockError（Semaphore count would exceed maximum）

## 线程池有效队列长度计算
- 背景：判定“队列是否已满”时，存在并发窗口：采样 ActiveCount/Worker 数与队列长度时，工作线程可能瞬间领取任务
- 做法：
  - 使用 Integer 快照 LQueueLen 参与计算，避免与其它 QWord 路径混算引发整数溢出
  - 有效长度 = max(0, LQueueLen - max(0, WorkersSnap - ActiveSnap))

## 常见陷阱
- 信号量额外 Release：破坏生产者/消费者配对关系，可能导致最大计数越界
- 混用整型宽度：QWord 与 Integer 在存在范围检查时容易诱发溢出或负值截断

## 建议
- 只在必要处 Release 对应一方信号量，保持配对对称
- 对并发采样值做下限截断，所有参与计算的整型统一宽度
- 增加回归测试覆盖高并发/压力场景

