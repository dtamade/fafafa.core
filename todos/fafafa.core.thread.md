# todos — fafafa.core.thread （2025-08-14）

## 下一轮目标
- Select 一等 API：提供非轮询等待任一完成，基于 Future.OnComplete + Channel 聚合。
- 取消增强：池与调度器提交均支持 Token；Future.WaitOrCancel 统一策略；传播机制说明文档化。
- Scheduler 精度与效率：替换为时间堆/时间轮；保留当前接口不变。
- 指标扩展：平均等待/执行时间的采样计数器，保持低开销与只读视图。
- 示例与文档：补充取消/Select/CallerRuns 背压综合示例与最佳实践。

## 验收标准
- 单测覆盖新增公开接口全部重载；Windows/Linux 均可通过；heaptrc 0 泄漏。
- 性能基线：
  - Select 聚合开销 < 1µs/操作（不含任务执行）；
  - Scheduler 扫描复杂度由 O(N) 降至 O(log N)。

## 任务拆解（建议）
1. 设计 Select API（门面 + Future 内部钩子），最小可用实现与测试
2. 取消 Token 扩展（Submit/Schedule 重载），适配现有路径，补充测试
3. Scheduler 时间堆实现（可选 feature），A/B 开关与基准对比
4. 指标扩展与 docs 更新
5. 示例与 quickstart 更新



### 2025-08-15 备注（已完成的小修复）
- 门面 Sleep/Yield 精度调整：分片睡眠 + 0ms 让权，解决单测偶发超时；已验证通过全部 83 项用例。


### 2025-08-16 备注（验证与计划）
- 验证：全量用例 N=87 E=0 F=0；OnComplete 语义符合预期（已完成后注册立即在锁外触发一次；未完成时注册一次性触发）；CountDownLatch 行为稳定。
- 计划：
  - 提供 Select 非轮询一等 API（OnComplete + Channel 聚合），在匿名引用可用时默认启用，提供 FORCE_POLLING 回退宏
  - 扩展取消 Token：Submit/Schedule 全路径支持；Future.WaitOrCancel 与 Token 联动
  - Scheduler 时间堆/时间轮实验性实现，作为可选开关
