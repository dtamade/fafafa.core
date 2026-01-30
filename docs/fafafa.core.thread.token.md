# 协作式取消（ICancellationToken）最佳实践

本指南介绍在 fafafa.core.thread 模块中使用 ICancellationToken 进行协作式取消的推荐方式、语义细节与常见模式。

## 设计目标
- 低侵入：调用侧可以选择性地传入 Token，不强制依赖
- 可观测：线程池/调度器在排队阶段即可感知取消，避免无谓执行
- 一致性：Spawn/SpawnBlocking/Schedule 的 Token 语义一致

## 语义约定
- 预取消（Pre-cancelled）
  - 当提交前 Token 已请求取消：
    - 线程池 Submit(Token, …) 与调度器 Schedule(Token, …) 直接返回 nil（不入队）
    - 便捷函数（Spawn/SpawnBlocking + Token）也返回 nil
- 队列内取消
  - 提交时保存 Token 到队列项；若随后 Token 被取消：
    - 线程池会在取出前剔除该项并 Fail 对应 Future（避免执行）
    - 调度器会在到期检查/消费前剔除并统计 Cancelled 指标
- 执行中取消
  - Token 为“协作式”信号，不会强制打断正在运行的任务
  - 任务函数可显式查询 Token.IsCancellationRequested 自行提前返回

## 推荐用法
- API 层：支持携带 Token 的重载，便于上层透传
- 调用层：
  - 优先使用带 Token 的 Spawn/SpawnBlocking：
    ```pascal
    var Cts: ICancellationTokenSource; F: IFuture;
    begin
      Cts := CreateCancellationTokenSource;
      F := Spawn(@DoWork, nil, Cts.Token);
      // ... 某些条件触发取消
      Cts.Cancel;
      // 等待或放弃
      F.WaitFor(500);
    end;
    ```
  - 调度器：对可能超时或条件撤销的延迟任务，使用 Schedule(Token,…)

## 模式与反模式
- 模式
  - 超时 -> 取消：上层超时逻辑触发时，调用 Cts.Cancel 通知下游所有任务
  - 合并取消：多个并发工作共享一个 Token，实现“一键撤销”
- 反模式
  - 试图强制终止正在运行的任务：应改为任务内部定期检查 Token 并尽快返回
  - 忽略返回值：带 Token 的便捷函数在预取消时会返回 nil，应先判断再使用 Future

## 与库行为的映射
- Spawn/SpawnBlocking(Token,…)
  - 已实现“全链路透传”：直接调用线程池/阻塞池 Submit(Token,…)
- ThreadPool.Submit(Token,…)
  - 预取消直接返回 nil；否则绑定 Token 到任务项
- TaskScheduler.Schedule(Token,…)
  - 预取消直接返回 nil；否则绑定 Token 到待调度项

## 观测与调试
- 指标：
  - 调度器：TotalCancelled 统计因 Token 取消被剔除的数量
  - 线程池：可结合 TotalSubmitted/TotalCompleted 对比评估取消与执行比
- 日志（调试构建）：
  - FAFAFA_THREAD_DEBUG 打开后，会输出任务剔除/收缩等信息，便于排查

## 兼容性
- 预取消返回 nil 的语义对既有代码是向后兼容的（此前也允许 nil）
- 无 Token 的重载保持原行为不变

## 小贴士
- 在组合助手中使用 Token（如 FutureWaitOrCancel）：
  ```pascal
  if not FutureWaitOrCancel(F, Cts.Token, 1000) then
    WriteLn('cancelled or timeout');
  ```
- 对“必须释放资源”的任务，务必在任务函数内部处理取消与清理逻辑

