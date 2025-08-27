# 线程调度器小根堆优化报告

**日期**: 2025-01-18  
**模块**: fafafa.core.thread.scheduler  
**状态**: 已完成，测试全绿  

## 问题背景

原调度器使用插入排序维护任务队列，存在以下问题：
1. **性能瓶颈**: 插入新任务 O(N)，频繁调度时性能下降
2. **阻塞风险**: RemoveCancelledHeads 仅清理堆顶连续取消项，中间取消项可能阻塞最早到期任务
3. **指标不准**: 取消项未及时计入 FTotalCancelled，导致 metrics 测试失败
4. **忙等问题**: NextSleepMs 计算可能不准确，造成 CPU 空转

## 解决方案

### 1. 小根堆实现
- **数据结构**: 将 TList 改为小根堆，按 DueAt 升序维护
- **核心操作**:
  - `HeapSiftUp(Index)`: 上浮操作，插入后维护堆性质
  - `HeapSiftDown(Index)`: 下沉操作，删除后维护堆性质
  - `HeapPop()`: 弹出堆顶（最早到期），O(log N)
  - `HeapRemoveAt(Index)`: 删除指定位置元素，O(log N)

### 2. 取消项全量清理
```pascal
procedure TTaskScheduler.RemoveCancelledHeads;
begin
  // 扫描整个堆，移除所有已取消的任务
  I := 0;
  while I < HeapCount do
  begin
    P := PScheduledItem(FHeap[I]);
    if Assigned(P^.Future) and P^.Future.IsCancelled then
    begin
      Inc(FTotalCancelled);  // 计入取消指标
      if FActiveTasks > 0 then Dec(FActiveTasks);
      HeapRemoveAt(I);       // 从堆中移除
      Dispose(P);
      Continue; // 留在当前位置检查新元素
    end;
    Inc(I);
  end;
end;
```

### 3. Future.OnComplete 语义修正
- **问题**: 已完成时注册回调可能不被调用，或被调用多次
- **修正**: 只在确有回调时标记 `FCallbackInvoked`，确保"完成后注册"的一次性立即调用

## 性能提升

| 操作 | 原实现 | 新实现 | 提升 |
|------|--------|--------|------|
| 插入任务 | O(N) | O(log N) | 显著 |
| 获取最早 | O(1) | O(1) | 相同 |
| 删除任务 | O(N) | O(log N) | 显著 |
| 清理取消项 | O(k) | O(N) | 全量但准确 |

## 测试结果

### 回归测试
- **执行**: `tests\fafafa.core.thread\BuildOrTest.bat test`
- **结果**: 98/98 通过，0 错误，0 失败
- **耗时**: ~17.2s（包含 CreateCachedThreadPool 10s 用例）
- **内存**: heaptrc 0 未释放块

### 关键用例验证
- `Test_Metrics_Cancelled_And_Active`: ✅ 取消指标正确计入
- `Test_Schedule_Order_ThreeTasks`: ✅ 时序保持准确
- `Test_KeepAlive_Shrink_Metrics_Basic`: ✅ 线程池收缩指标正常

### 快速冒烟测试
新增 `BuildOrTest.bat smoke` 命令：
- 仅运行核心用例：scheduler_basic, scheduler_order, scheduler_metrics, threadpool_keepalive
- 耗时：1-3s，便于日常开发快速反馈

## 代码变更摘要

### 新增方法
- `HeapSiftUp(AIndex)`: 堆上浮
- `HeapSiftDown(AIndex)`: 堆下沉  
- `HeapRemoveAt(AIndex)`: 删除指定位置
- `HeapSwap(I, J)`: 交换堆元素

### 修改方法
- `PushItem()`: 适配堆插入
- `PopDueItem()`: 适配堆弹出
- `RemoveCancelledHeads()`: 全堆扫描清理
- `NextSleepMs()`: 基于堆顶计算

### Future 修正
- `OnComplete()`: 已完成时注册的一次性调用保证
- `NotifyCompletion()`: 仅在确有回调时标记已调用

## 向后兼容性

- **接口不变**: ITaskScheduler 公开接口完全兼容
- **行为一致**: 调度顺序、取消语义保持不变
- **性能提升**: 对用户透明的性能优化

## 后续优化方向

1. **时间轮算法**: 可在宏控制下试验，进一步降低常数因子
2. **批量操作**: 支持批量插入/删除，减少堆调整次数
3. **内存池**: 为 ScheduledItem 使用对象池，减少分配开销

## 结论

本次优化成功解决了调度器的性能瓶颈和指标准确性问题，测试全绿，向后兼容。小根堆实现为高频调度场景提供了更好的性能保证，同时保持了代码的可维护性。
