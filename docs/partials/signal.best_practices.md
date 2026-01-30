# fafafa.core.signal 最佳实践

更新时间：2025-08-22

## 选择一种工作模式（不要混用）
- 回调模式（Subscribe/SubscribeOnce）
  - 适合快速响应、轻量转发；回调在“派发线程”中执行，必须短小、非阻塞。
  - 回调异常会被捕获并吞没，避免崩溃派发线程；如需记录错误，请在回调中自行转发到日志系统。
- 队列模式（WaitNext）
  - 单消费者语义：不要在多个线程并发调用 WaitNext；否则会竞争事件，产生不可预期行为。
  - 使用有限超时（如 100–500ms）循环等待，便于及时响应 Stop/终止信号。
- Channel 模式（TSignalChannel）
  - 适合需要背压/配对的场景；capacity=0 表示配对，>0 表示有界缓冲。
  - 当前实现 SendTimeout(..., 0)；缓冲满时发送方丢弃事件。需要尽量不丢时，请增大容量或使用回调→自建可靠队列转发。

## 队列与丢弃策略
- ConfigureQueue(capacity, policy)
  - capacity<=0：无限容量（默认）。
  - policy：qdpDropNewest（默认，丢当前入队）/qdpDropOldest（丢最旧）。
- 信号类型建议
  - 状态替换型（如 sgWinch）：可选 DropOldest 或合并；更关注最新状态。
  - 关键控制型（sgInt/sgTerm）：建议无限容量或尽快处理，避免丢弃。

## sgWinch 合并与 UI 建议
- 已实现：
  - 连续 sgWinch 合并（队尾已是 sgWinch 时跳过新入队）。
  - 时间窗口去抖：调用 ConfigureWinchDebounce(windowMs) 可忽略 windowMs 内的重复入队。
- 建议：UI 帧循环内仍可做 16–33ms 去抖/合并以进一步平滑；或使用 Channel(capacity=1) 保留最新状态。

## Windows Ctrl 事件策略
- 当前行为：仅当存在该事件的订阅者时，ConsoleCtrlHandler 返回 True 表示“已处理”（系统默认行为被抑制）；否则返回 False 交由系统默认处理。
- 退出策略：
  - 若希望 Ctrl+C 触发优雅退出，请订阅 sgInt 并在回调中启动清理/退出流程。
  - 若希望保持系统默认退出，不要订阅对应信号（或未来提供“策略枚举”后设为 PassThrough）。

## 生命周期与资源
- Start/Stop 可多次调用（幂等）；Stop 会唤醒等待者并有序终止派发线程；Stop 后内部队列将被清空，Stop 之后不会再调用用户回调。
- 可使用 GetQueueStats() 在运行期观测队列容量/长度与丢弃计数，辅助诊断背压和去抖策略。
- 订阅返回 token：请在不再需要时 Unsubscribe(token)。
- Pause/Resume：暂停期间触发的事件不会为该订阅者回放；恢复后仅接收后续事件。
- SubscribeOnce：只触发一次，内部会在首次回调中自动 Unsubscribe，适合“一次性”场景。

## 回调编写规范
- 禁止：长耗时计算、阻塞 IO、长时间持锁。
- 推荐：
  - 仅设置原子标志、计数器或将事件投递到内部队列/线程池。
  - 必要时与 Channel 结合，实现背压与配对处理。

## WaitNext 模式建议
- 单独使用，不与回调混用。
- 采用有限超时循环：
```
var C: ISignalCenter; S: TSignal;
C := SignalCenter; C.Start;
while running do
begin
  if C.WaitNext(S, 200) then
    Handle(S) // 轻量处理或转发
  else
    Tick();   // 超时后做心跳/检查退出
end;
C.Stop;
```

## Channel 模式建议
- 无缓冲（capacity=0）适合严格配对；有缓冲适合突发；接收可用 Recv/RecvTimeout。
- 用完及时 Close/Free 以释放订阅与通道。

## 测试与调试
- 使用 InjectForTest 注入，不要在测试中发送真实“破坏性”信号。
- 对时间相关用例，使用适度的等待窗口（如 50–200ms）以降低调度抖动带来的偶发失败。

## 常见反例
- 注册了回调，同时在其他线程里 WaitNext 拉取：会竞争同一事件，造成“漏回调/漏消费”。
- 在回调中 Sleep/IO：阻塞派发线程，导致后续信号延迟或堆积。


