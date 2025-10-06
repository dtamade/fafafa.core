# 调度器优化总结

## 日期
2025-01-05

## 目标
优化 `fafafa.core.time.scheduler` 模块的性能，特别是 `GetNextTask` 方法，从 O(n) 线性扫描优化为更高效的实现。

## 实现的优化

### 1. 优先队列集成
- **数据结构**: 使用 `TPriorityQueue<IScheduledTask>` 最小堆
- **比较函数**: `CompareTasksByTime` - 按 NextRunTime 升序排序，时间相同时按 Priority 降序
- **性能提升**: GetNextTask 从 O(n) 优化为 O(1) peek 操作

### 2. 数据结构设计
```pascal
TTaskScheduler = class(TInterfacedObject, ITaskScheduler)
private:
  FTasks: TList;                    // 保留用于 GetTasks 等操作
  FTaskQueue: TTaskPriorityQueue;   // 按执行时间排序的优先队列
```

### 3. 关键方法优化

#### AddTask
- 检查任务是否已存在（O(n) 线性查找）
- 添加到 FTasks 列表
- 添加到优先队列 FTaskQueue（O(log n)）
- 增加任务引用计数

#### RemoveTask
- 从 FTasks 列表移除（O(n) 查找 + O(1) 删除）
- 从优先队列移除（O(n) 查找 + O(log n) 删除）
- 释放任务引用

#### GetNextTask（核心优化）
- 从优先队列 Peek 获取最早任务（O(1)）
- 懒惰移除无效任务
- 性能从 O(n) 提升到 O(1)

## 尝试但未实现的优化

### HashMap 集成尝试
**目标**: 实现 O(1) 的 GetTask(taskId) 查找

**尝试方案**:
1. 使用 `THashMap<string, IScheduledTask>`
2. 使用 `TRBTreeMap<string, IScheduledTask>` (红黑树)

**遇到的问题**:
1. **THashMap**:
   - 实现不完整，缺少多个抽象方法实现
   - 缺少 `Contains` 方法的多个重载版本
   - 接口声明和实现不匹配

2. **TRBTreeMap**:
   - 编译器在处理泛型特化时崩溃（Access Violation）
   - 可能是循环依赖或泛型嵌套过深导致

**结论**: 
- 暂时保留 GetTask 的 O(n) 线性查找实现
- 将 HashMap/Map 优化标记为未来改进项
- 当前优先队列优化已足够满足大多数使用场景

## 性能分析

### 优化前
- GetNextTask: O(n) - 遍历所有任务找到最早的
- AddTask: O(1) - 直接添加到列表末尾
- RemoveTask: O(n) - 线性查找
- GetTask(id): O(n) - 线性查找

### 优化后
- GetNextTask: O(1) - Peek 优先队列
- AddTask: O(log n) - 插入优先队列
- RemoveTask: O(n) - 从优先队列移除需要查找
- GetTask(id): O(n) - 未优化，仍然线性查找

### 性能影响
- **最频繁操作**: GetNextTask - 调度器每次循环都调用，优化效果最显著
- **次频繁操作**: AddTask - 通常在启动时批量添加，O(log n) 可接受
- **较少操作**: RemoveTask, GetTask - 相对不频繁，O(n) 可接受

## 测试结果
- 基本功能测试通过
- 两个一次性任务正确调度和执行
- 无内存泄漏
- 线程安全运行正常

## 未来改进建议

### 短期（低优先级）
1. 完善 THashMap 实现
   - 实现缺失的抽象方法
   - 添加所有必需的 Contains 重载
   - 确保接口完整性

2. 优化 GetTask(id)
   - 可以使用独立的字符串映射表
   - 或等待 HashMap 完善后集成

### 长期
1. 考虑使用第三方成熟的 HashMap 实现
2. 评估是否需要更复杂的索引结构
3. 添加性能基准测试套件

## 总结
本次优化成功将调度器最关键的 GetNextTask 方法从 O(n) 优化到 O(1)，大幅提升了调度器在大量任务场景下的性能。虽然 HashMap 集成未能完成，但当前的实现已经满足了大多数实际使用需求，且代码稳定可靠。

## 相关文件
- `src/fafafa.core.time.scheduler.pas` - 调度器实现
- `src/fafafa.core.collections.priorityqueue.pas` - 优先队列实现
- `tests/fafafa.core.time/test_scheduler_basic.pas` - 基本功能测试
