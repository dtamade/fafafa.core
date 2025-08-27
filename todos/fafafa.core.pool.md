# 开发计划日志 - fafafa.core.pool

## 目标
- 构建“统一池体系”门面（淘汰 `fafafa.core.mem` 下旧池实现）
- 固定块池 O(1) 分配/释放；Arena（bump）标准化；Slab 最小内核
- 指标可选、线程安全包装可选；默认热路径零开销

## 当轮计划
- [x] 建立门面 `fafafa.core.pool.pas`，导出 `IMemPool/IArena/ISlabPool/IPoolMetrics`
- [x] `TFixedBlockPool`（连续缓冲 + 侵入式自由链表）
- [x] `CreateFixedPool/CreateArena` 工厂；`CreateSlabPool` 暂抛异常
- [ ] Slab Pool 最小内核
- [ ] 线程安全包装（Wrapper + Sharded 策略）
- [ ] 测试：`tests/fafafa.core.pool/`
- [ ] 迁移：模块内部引用改为从 `fafafa.core.pool` 获取池

## 细项拆分（下一步）
1. Slab 内核
   - [ ] 页=4K，对齐；size-classes：8..2048（2^k）
   - [ ] partial/full/free 列表 + bitmap 分配
   - [ ] Alloc/Free/Reset + 基本 Metrics
2. 线程安全包装
   - [ ] `TThreadSafePool(IMemPool)`：内部组合 `ILock`
   - [ ] Sharded(N)：按 CPU/GUID 分片路由
3. 测试与样例
   - [ ] Fixed/Arena 基础功能 + 边界/对齐
   - [ ] 压力与并发（在线程安全包装上测）
4. 迁移与清理
   - [ ] docs 更新（阶段末统一补）
   - [ ] 将 `fafafa.core.mem.*Pool` 标记为兼容层，逐步移除

