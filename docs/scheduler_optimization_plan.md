# 调度器优先队列优化方案
## 基于框架内现有组件的最佳复用实践

---

## 📋 目标

将 `TTaskScheduler` 的任务管理从 **O(n) 线性查找** 优化为 **O(log n) 堆操作**，同时**最大化复用**框架内已有组件，保持代码一致性和可维护性。

---

## 🧩 框架现有组件分析

### 1. **`TPriorityQueue<T>`** ✅
**位置**: `fafafa.core.collections.priorityqueue.pas`

**功能**:
- 泛型最小堆实现
- O(log n) 插入/删除
- O(1) 获取最小元素
- 自定义比较函数支持

**适用场景**: 
- 按 `NextRunTime` 和 `Priority` 排序任务
- 快速获取下一个待执行任务

---

### 2. **`THashMap<K,V>`** ✅
**位置**: `fafafa.core.collections.hashmap.pas`

**功能**:
- 泛型哈希表（开放寻址）
- O(1) 平均查找/插入/删除
- 支持字符串、整数等常见类型的默认哈希
- 自动扩容

**适用场景**:
- `TaskId → IScheduledTask` 快速映射
- 支持 `GetTask(TaskId)` O(1) 查找
- 支持 `RemoveTask(TaskId)` O(1) 删除

---

### 3. **`TList`** ⚠️
**当前使用**: `fafafa.core.time.scheduler.pas` (第 448 行)

**问题**:
- `GetNextTask`: O(n) 线性扫描所有任务
- `GetTask(TaskId)`: O(n) 线性查找
- 随着任务数量增长，性能显著下降

**解决方案**: 用 `TPriorityQueue` + `THashMap` 替代

---

## 🏗️ 优化架构设计

### 核心思想：**双数据结构协同**

```pascal
TTaskScheduler = class(TInterfacedObject, ITaskScheduler)
private
  // 优先队列：按执行时间排序（O(log n) 插入/删除，O(1) 获取最小）
  FTaskQueue: TTaskPriorityQueue;
  
  // 哈希表：TaskId → Task 映射（O(1) 查找/删除）
  FTaskMap: TTaskHashMap;
  
  // 时钟、线程等其他字段保持不变
  FClock: IMonotonicClock;
  FLock: TRTLCriticalSection;
  // ...
end;
```

### 类型定义（复用现有泛型）

```pascal
type
  // 任务优先队列：按执行时间排序
  TTaskPriorityQueue = specialize TPriorityQueue<IScheduledTask>;
  
  // 任务哈希映射：TaskId → IScheduledTask
  TTaskHashMap = specialize THashMap<string, IScheduledTask>;
```

---

## 🔧 实现细节

### 1. **任务比较函数**

```pascal
// 比较器：NextRunTime 升序，相同时 Priority 降序
function CompareTasksByTime(const A, B: IScheduledTask): Integer;
var
  timeA, timeB: TInstant;
begin
  timeA := A.GetNextRunTime;
  timeB := B.GetNextRunTime;
  
  // 时间早的优先
  if timeA < timeB then Exit(-1);
  if timeA > timeB then Exit(1);
  
  // 时间相同，优先级高的优先
  if A.GetPriority > B.GetPriority then Exit(-1);
  if A.GetPriority < B.GetPriority then Exit(1);
  
  Result := 0;
end;
```

---

### 2. **初始化与销毁**

```pascal
constructor TTaskScheduler.Create(const AClock: IMonotonicClock; AMaxThreads: Integer);
begin
  inherited Create;
  InitCriticalSection(FLock);
  
  // 初始化优先队列（指定比较函数）
  FTaskQueue.Initialize(@CompareTasksByTime, 32);
  
  // 初始化哈希表（默认容量）
  FTaskMap := TTaskHashMap.Create(32);
  
  FClock := AClock;
  // ... 其他初始化
end;

destructor TTaskScheduler.Destroy;
begin
  if FIsRunning then
    Shutdown(TDuration.FromSec(5));
    
  EnterCriticalSection(FLock);
  try
    // 清理哈希表
    FTaskMap.Clear;
    FTaskMap.Free;
    
    // 清理优先队列
    FTaskQueue.Clear;
  finally
    LeaveCriticalSection(FLock);
  end;
  
  DoneCriticalSection(FLock);
  inherited;
end;
```

---

### 3. **AddTask 优化** ⚡

**优化前**: O(n) 线性检查 + O(1) 追加
**优化后**: O(1) 哈希查找 + O(log n) 堆插入

```pascal
procedure TTaskScheduler.AddTask(const ATask: IScheduledTask);
var
  taskId: string;
begin
  EnterCriticalSection(FLock);
  try
    taskId := ATask.GetId;
    
    // 检查任务是否已存在（O(1) 哈希查找）
    if FTaskMap.ContainsKey(taskId) then
      Exit; // 已存在，不重复添加
    
    // 插入哈希表（O(1)）
    FTaskMap.AddOrAssign(taskId, ATask);
    
    // 插入优先队列（O(log n)）
    FTaskQueue.Enqueue(ATask);
    
    // 增加引用计数
    ATask._AddRef;
  finally
    LeaveCriticalSection(FLock);
  end;
end;
```

---

### 4. **GetNextTask 优化** ⚡⚡⚡

**优化前**: O(n) 全表扫描
**优化后**: O(1) 堆顶访问

```pascal
function TTaskScheduler.GetNextTask: IScheduledTask;
var
  task: IScheduledTask;
begin
  Result := nil;
  
  EnterCriticalSection(FLock);
  try
    // 从队列中取出最早的任务（O(1) Peek）
    while not FTaskQueue.IsEmpty do
    begin
      if not FTaskQueue.TryPeek(task) then
        Break;
      
      // 检查任务是否仍然有效
      if task.IsActive then
      begin
        Result := task;
        Exit;
      end
      else
      begin
        // 无效任务，从队列和映射表中移除
        FTaskQueue.Dequeue; // O(log n)
        FTaskMap.Remove(task.GetId); // O(1)
        task._Release;
      end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;
```

---

### 5. **RemoveTask 优化** ⚡

**优化前**: O(n) 线性查找 + O(n) 删除
**优化后**: O(1) 哈希查找 + O(n) 队列线性查找 + O(log n) 堆删除

```pascal
procedure TTaskScheduler.RemoveTask(const ATask: IScheduledTask);
var
  taskId: string;
begin
  EnterCriticalSection(FLock);
  try
    taskId := ATask.GetId;
    
    // 从哈希表移除（O(1)）
    if not FTaskMap.Remove(taskId) then
      Exit; // 不存在
    
    // 从优先队列移除（O(n) 查找 + O(log n) 删除）
    FTaskQueue.Remove(ATask);
    
    // 释放引用
    ATask._Release;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.RemoveTask(const ATaskId: string);
var
  task: IScheduledTask;
begin
  EnterCriticalSection(FLock);
  try
    // O(1) 哈希查找
    if FTaskMap.TryGetValue(ATaskId, task) then
      RemoveTask(task);
  finally
    LeaveCriticalSection(FLock);
  end;
end;
```

---

### 6. **GetTask 优化** ⚡⚡

**优化前**: O(n) 线性查找
**优化后**: O(1) 哈希查找

```pascal
function TTaskScheduler.GetTask(const ATaskId: string): IScheduledTask;
begin
  Result := nil;
  EnterCriticalSection(FLock);
  try
    // O(1) 哈希表查找
    FTaskMap.TryGetValue(ATaskId, Result);
  finally
    LeaveCriticalSection(FLock);
  end;
end;
```

---

### 7. **GetTasks 方法调整**

```pascal
function TTaskScheduler.GetTasks: specialize TArray<IScheduledTask>;
var
  arr: array of IScheduledTask;
  i: Integer;
begin
  Result := nil;
  EnterCriticalSection(FLock);
  try
    // 从优先队列获取快照
    arr := FTaskQueue.ToArray;
    SetLength(Result, Length(arr));
    for i := 0 to High(arr) do
      Result[i] := arr[i];
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetTasks(AState: TTaskState): specialize TArray<IScheduledTask>;
var
  arr: array of IScheduledTask;
  i, count: Integer;
begin
  Result := nil;
  EnterCriticalSection(FLock);
  try
    arr := FTaskQueue.ToArray;
    SetLength(Result, Length(arr));
    count := 0;
    
    for i := 0 to High(arr) do
    begin
      if arr[i].GetState = AState then
      begin
        Result[count] := arr[i];
        Inc(count);
      end;
    end;
    
    SetLength(Result, count);
  finally
    LeaveCriticalSection(FLock);
  end;
end;
```

---

## 📊 性能对比预估

| 操作 | 优化前 | 优化后 | 提升 |
|------|--------|--------|------|
| **AddTask** | O(n) | O(log n) + O(1) | 显著 |
| **GetNextTask** | O(n) | O(1) | **极大** |
| **RemoveTask** | O(n) | O(1) + O(n) + O(log n) | 中等 |
| **GetTask(id)** | O(n) | O(1) | **极大** |
| **GetTasks** | O(1) | O(n) | 降低（但通常调用频率低）|

### 典型场景分析

- **1000 个任务，频繁调度**
  - 优化前：每次 `GetNextTask` 需要扫描 1000 个任务
  - 优化后：每次 `GetNextTask` 仅需访问堆顶（1 次操作）
  - **性能提升约 1000 倍**

- **10000 个任务，按 ID 查找**
  - 优化前：平均扫描 5000 个任务
  - 优化后：O(1) 哈希查找
  - **性能提升约 5000 倍**

---

## ⚠️ 注意事项

### 1. **任务状态变更**
当任务的 `NextRunTime` 或 `Priority` 变更时，需要：
1. 从优先队列中移除
2. 更新属性
3. 重新插入优先队列

**建议**: 增加 `UpdateTask` 方法处理此场景。

### 2. **线程安全**
- 所有操作已加锁（`FLock`）
- `TPriorityQueue` 和 `THashMap` 本身非线程安全，依赖外部锁保护

### 3. **内存管理**
- `IScheduledTask` 使用引用计数
- 添加时 `_AddRef`，移除时 `_Release`
- 确保双结构同步，避免内存泄漏

### 4. **队列与映射表一致性**
- 始终保持 `FTaskQueue` 和 `FTaskMap` 的同步
- 插入/删除必须同时操作两个结构

---

## 🧪 测试计划

### 1. **功能测试**
- 添加/移除任务
- 按 ID 查找任务
- 获取下一个任务
- 任务执行和调度

### 2. **性能基准测试**
```pascal
// 测试场景 1：大量任务调度
procedure BenchmarkScheduling(ATaskCount: Integer);
var
  scheduler: ITaskScheduler;
  i: Integer;
  startTime, endTime: TInstant;
begin
  scheduler := CreateTaskScheduler;
  scheduler.Start;
  
  // 添加大量任务
  startTime := DefaultMonotonicClock.NowInstant;
  for i := 1 to ATaskCount do
  begin
    scheduler.ScheduleOnce(
      scheduler.CreateTask('Task' + IntToStr(i), @DummyCallback),
      TDuration.FromSec(i)
    );
  end;
  endTime := DefaultMonotonicClock.NowInstant;
  
  WriteLn(Format('添加 %d 个任务耗时: %d ms', 
    [ATaskCount, endTime.Diff(startTime).ToMs]));
  
  // 获取下一个任务（1000 次）
  startTime := DefaultMonotonicClock.NowInstant;
  for i := 1 to 1000 do
    scheduler.GetNextTask;
  endTime := DefaultMonotonicClock.NowInstant;
  
  WriteLn(Format('获取下一个任务 1000 次耗时: %d ms', 
    [endTime.Diff(startTime).ToMs]));
  
  scheduler.Stop;
end;
```

### 3. **边缘情况测试**
- 空队列操作
- 大量并发任务
- 任务时间相同但优先级不同
- 任务动态取消和重新调度

---

## 📅 实施步骤

### **阶段 1：引入依赖** ✅
- 在 `uses` 子句添加 `fafafa.core.collections.priorityqueue` 和 `fafafa.core.collections.hashmap`
- 定义类型别名 `TTaskPriorityQueue` 和 `TTaskHashMap`

### **阶段 2：扩展字段** ✅
- 添加 `FTaskQueue` 和 `FTaskMap` 字段
- 保留 `FTasks` 用于过渡验证

### **阶段 3：实现比较函数** ✅
- 实现 `CompareTasksByTime`

### **阶段 4：修改任务管理方法** ⚡
- `AddTask`, `RemoveTask`, `GetTask`, `GetNextTask`
- 确保双结构同步

### **阶段 5：初步测试** ✅
- 编译并运行现有测试
- 验证功能正确性

### **阶段 6：清理旧代码** 🧹
- 移除 `FTasks: TList`
- 清理相关代码

### **阶段 7：性能验证** 📈
- 运行基准测试
- 对比优化前后性能

### **阶段 8：文档更新** 📝
- 更新 API 文档
- 编写优化报告

---

## 🎯 预期成果

1. **性能提升**
   - `GetNextTask`: O(n) → O(1) (**数千倍提升**)
   - `GetTask(id)`: O(n) → O(1) (**数千倍提升**)
   - `AddTask`: O(n) → O(log n) (**显著提升**)

2. **代码质量**
   - 最大化复用框架现有组件
   - 保持代码一致性和可维护性
   - 类型安全，泛型支持

3. **可扩展性**
   - 支持海量任务调度（10000+ 任务）
   - 适用于高频调度场景
   - 为未来功能扩展奠定基础

---

## 📚 参考资料

- `fafafa.core.collections.priorityqueue.pas` - 优先队列实现
- `fafafa.core.collections.hashmap.pas` - 哈希表实现
- `fafafa.core.time.scheduler.pas` - 当前调度器实现
- 数据结构与算法：堆、哈希表的时间复杂度分析

---

## ✅ 总结

本方案通过**最大化复用**框架内已有的泛型集合组件（`TPriorityQueue` 和 `THashMap`），实现了调度器的高效优化，避免了重复造轮子，保持了代码的一致性和可维护性。这是 **Pascal/Lazarus 框架工程化的最佳实践**。

**关键原则**:
- ✅ 复用优先于重写
- ✅ 类型安全优先于动态类型
- ✅ 性能优化基于数据结构选择
- ✅ 保持接口稳定性

---

**作者**: fafafa Studio  
**日期**: 2025-10-05  
**版本**: 1.0
