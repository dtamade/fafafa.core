# 工作总结报告 - fafafa.core.pool

## 本轮进度
- 新建门面模块 `src/fafafa.core.pool.pas`
  - 定义统一接口：`IMemPool`/`IArena`/`ISlabPool` 与 `IPoolMetrics`
  - 实现固定块池 `TFixedBlockPool`（连续大缓冲 + 侵入式自由链表，O(1) 分配/释放）
  - 提供 `CreateFixedPool` 工厂
  - 以 `TStackPool` 适配 `IArena`（`CreateArena`），将栈池正式化为 Arena 语义
  - 预留 `CreateSlabPool`（暂未实现，抛异常）
- 明确“淘汰 fafafa.core.mem 下旧池实现”的路线：以门面替代对外使用，逐步迁移

## 已完成项
- 统一池门面建立，API 稳定
- Fixed-pool 热路径重写为 O(1) 分配/释放
- Arena 门面落地（用现有 `TStackPool` 驱动）

## 问题与解决
- 旧 `TMemPool` 的 Free O(n) 与 Reset 退化问题：
  - 解决：单大缓冲 + 块内 next 指针的侵入式自由链；Reset O(1) 重建 freelist
- 与现有代码的兼容：
  - 方案：先通过门面导出统一工厂接口；旧代码逐步改为从 `fafafa.core.pool` 获取池

## 后续计划（下一轮）
1) Slab 最小内核落地（4K 页 + size-class + bitmap，Alloc/Free/Reset + 基本指标）
2) 线程安全包装（可选）：`TThreadSafePool` wrapper + 分片策略（Sharded）
3) 对象池（IObjectPool<T>）雏形（可选，若本轮只聚焦内存池可延后）
4) 测试与样例：
   - 新建 tests/fafafa.core.pool/ 基础用例：alloc/free/reset/边界/对齐
   - 压力与简单并发（在线程安全包装上测）
5) 迁移清理：
   - 标记 `fafafa.core.mem.*Pool` 为兼容层（后续移除）
   - 模块内替换到 `fafafa.core.pool` 工厂

## 风险与建议
- 短期并存期需避免同时从“旧 mem 池 + 新 pool 门面”混用同一对象生命周期
- Slab 内核建议分两步：先核心可用，再补诊断/合并策略，降低一次性复杂度

