# fafafa.core.atomic 示例代码

本目录包含 `fafafa.core.atomic` 模块的完整使用示例，展示各种原子操作的实际应用场景。

## 示例列表

### 1. example_basic_operations.lpr
**基础原子操作示例**

演示内容：
- 原子加载与存储
- 原子交换
- 原子增减操作
- 比较交换（CAS）
- 位运算操作
- 指针运算
- 不同内存序的使用

适合初学者了解原子操作的基本用法。

### 2. example_producer_consumer.lpr
**生产者-消费者模式**

演示内容：
- 使用原子操作实现无锁环形缓冲区
- acquire/release 内存序的正确使用
- 多线程同步模式
- 忙等待与退避策略

展示了如何用原子操作替代传统的锁机制。

### 3. example_tagged_ptr_aba.lpr
**Tagged Pointer 与 ABA 问题解决**

演示内容：
- 无锁栈的实现
- ABA 问题的产生与危害
- 使用 tagged pointer 解决 ABA 问题
- 版本标签的自动递增机制

这是高级无锁编程的重要技术。

### 4. example_thread_counter.lpr
**多线程计数器与性能对比**

演示内容：
- 原子操作 vs 非原子操作的正确性对比
- 不同内存序的性能差异
- 位掩码的并发操作
- 竞态条件的演示

帮助理解原子操作的必要性和性能特征。

## 编译与运行

### 单独编译示例
```bash
# 编译基础操作示例
fpc -Fu../../src example_basic_operations.lpr

# 编译生产者-消费者示例
fpc -Fu../../src example_producer_consumer.lpr

# 编译 tagged pointer 示例
fpc -Fu../../src example_tagged_ptr_aba.lpr

# 编译多线程计数器示例
fpc -Fu../../src example_thread_counter.lpr
```

### 使用 Lazarus 编译
1. 在 Lazarus 中打开 .lpr 文件
2. 确保项目搜索路径包含 `../../src`
3. 编译并运行

## 学习路径建议

1. **入门**：先运行 `example_basic_operations`，了解基本 API
2. **进阶**：学习 `example_thread_counter`，理解线程安全的重要性
3. **实践**：研究 `example_producer_consumer`，掌握内存序的使用
4. **高级**：挑战 `example_tagged_ptr_aba`，学习高级无锁技术

## 注意事项

1. **编译器优化**：建议在 Release 模式下测试性能
2. **平台差异**：某些示例在不同平台上的表现可能有差异
3. **内存序**：理解不同内存序的语义对于正确使用原子操作至关重要
4. **调试**：在 Debug 模式下可能有额外的检查，影响性能测试结果

## 扩展练习

基于这些示例，你可以尝试：

1. **实现无锁队列**：基于 tagged pointer 技术
2. **读写锁**：使用原子操作实现读者-写者锁
3. **内存池**：无锁的内存分配器
4. **工作窃取队列**：多线程任务调度的基础
5. **无锁哈希表**：高性能并发数据结构

## 参考资料

- [fafafa.core.atomic API 文档](../../docs/fafafa.core.atomic.md)
- [内存模型与原子操作理论](https://en.cppreference.com/w/cpp/atomic/memory_order)
- [无锁编程最佳实践](https://www.1024cores.net/home/lock-free-algorithms)
