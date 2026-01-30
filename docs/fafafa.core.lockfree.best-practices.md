# fafafa.core.lockfree 最佳实践指南

## 🎯 性能基准参考

基于实际测试，各数据结构的性能表现：

| 数据结构 | 吞吐量 (ops/sec) | 适用场景 | 内存特点 |
|----------|------------------|----------|----------|
| TSPSCQueue | 64,500,000+ | 单生产者单消费者 | 预分配环形缓冲区 |
| TPreAllocStack | 18,000,000+ | 多线程栈操作 | 预分配节点池 |
| TTreiberStack | 16,000,000+ | 多线程栈操作 | 动态内存分配 |
| TPreAllocMPMCQueue | 10,600,000+ | 多生产者多消费者 | 预分配环形缓冲区 |
| TLockFreeHashMap | 9,000,000+ | 键值存储 | 开放寻址哈希表 |

## 🚀 选择指南

### 1. 队列选择

#### 单生产者单消费者（SPSC）
```pascal
// 最佳选择：TSPSCQueue
var LQueue: specialize TSPSCQueue<Integer>;
begin
  LQueue := specialize TSPSCQueue<Integer>.Create(1024);
  // 极致性能：6000万+ ops/sec
end;
```

**优势**：
- 极致性能，无CAS操作开销
- 内存友好，避免false sharing
- 适合高频数据传输

**注意事项**：
- 只能单线程生产，单线程消费
- 容量固定，需要合理设置

#### 多生产者多消费者（MPMC）
```pascal
// 最佳选择：TPreAllocMPMCQueue
var LQueue: specialize TPreAllocMPMCQueue<Integer>;
begin
  LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(1024);
  // 高性能：1000万+ ops/sec
end;
```

**优势**：
- 支持多线程并发
- 预分配内存，避免动态分配
- 内置性能统计

**注意事项**：
- 容量必须是2的幂次方
- 内存使用相对较大

### 2. 栈选择

#### 有容量限制的场景
```pascal
// 推荐：TPreAllocStack
var LStack: specialize TPreAllocStack<Integer>;
begin
  LStack := specialize TPreAllocStack<Integer>.Create(1024);
  // 高性能：1800万+ ops/sec，ABA安全
end;
```

**优势**：
- 解决ABA问题
- 预分配内存，性能稳定
- 内存使用可控

#### 无容量限制的场景
```pascal
// 推荐：TTreiberStack
var LStack: specialize TTreiberStack<Integer>;
begin
  LStack := specialize TTreiberStack<Integer>.Create;
  // 高性能：1600万+ ops/sec
end;
```

**优势**：
- 无容量限制
- 经典算法，广泛验证
- 内存使用灵活

**注意事项**：
- 存在ABA问题（在实际使用中很少遇到）
- 动态内存分配

### 3. 哈希表使用

```pascal
// 键值存储：TLockFreeHashMap
var LHashMap: specialize TLockFreeHashMap<Integer, string>;
begin
  LHashMap := specialize TLockFreeHashMap<Integer, string>.Create(1024);
  // 性能：900万+ ops/sec
end;
```

**优势**：
- 支持并发读写
- 开放寻址，缓存友好
- 适合高频查找

**注意事项**：
- 不支持动态扩容
- 删除操作使用标记删除

## ⚡ 性能优化技巧

### 1. 容量设置
```pascal
// 好的做法：设置为2的幂次方
LQueue := specialize TSPSCQueue<Integer>.Create(1024);  // ✅
LQueue := specialize TSPSCQueue<Integer>.Create(2048);  // ✅

// 避免：非2的幂次方（会自动调整，但浪费内存）
LQueue := specialize TSPSCQueue<Integer>.Create(1000);  // ❌
```

### 2. 批量操作
```pascal
// 高效：使用批量操作
var LElements: array[0..99] of Integer;
LCount := LQueue.EnqueueMany(LElements);

// 低效：逐个操作
for I := 0 to 99 do
  LQueue.Enqueue(LElements[I]);
```

### 3. 内存对齐
```pascal
// 对于高频使用的数据结构，考虑内存对齐
type
  {$PACKRECORDS C}
  TAlignedData = record
    Value: Integer;
    Padding: array[0..59] of Byte; // 避免false sharing
  end;
```

## 🛡️ 线程安全使用

### 1. SPSC队列
```pascal
// 正确：严格单生产者单消费者
// 生产者线程
procedure ProducerThread;
begin
  while not Terminated do
    LQueue.Enqueue(GetNextItem);
end;

// 消费者线程
procedure ConsumerThread;
var LItem: Integer;
begin
  while not Terminated do
    if LQueue.Dequeue(LItem) then
      ProcessItem(LItem);
end;
```

### 2. MPMC队列
```pascal
// 正确：多线程安全
procedure WorkerThread;
var LItem: Integer;
begin
  while not Terminated do
  begin
    // 生产
    LQueue.Enqueue(GenerateItem);

    // 消费
    if LQueue.Dequeue(LItem) then
      ProcessItem(LItem);
  end;
end;
```

## 📊 性能监控

### 1. 使用内置统计
```pascal
var
  LQueue: specialize TPreAllocMPMCQueue<Integer>;
  LStats: ILockFreeStats;
begin
  LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(1024);

  // 执行操作...

  // 获取统计信息
  LStats := LQueue.GetStats;
  WriteLn('吞吐量: ', LStats.GetThroughput:0:0, ' ops/sec');
  WriteLn('成功率: ', (LStats.GetSuccessfulOperations * 100.0 / LStats.GetTotalOperations):0:1, '%');
end;
```

### 2. 自定义性能监控
```pascal
var
  LMonitor: TPerformanceMonitor;
begin
  LMonitor := TPerformanceMonitor.Create;
  try
    LMonitor.Enable;

    // 执行操作
    LMonitor.RecordOperation(LQueue.Enqueue(Item));

    // 查看报告
    WriteLn(LMonitor.GenerateReport);
  finally
    LMonitor.Free;
  end;
end;
```

## ⚠️ 常见陷阱

### 1. ABA问题
```pascal
// TPreAllocStack 已解决ABA问题
// TTreiberStack 在实际使用中ABA问题很少发生，但要注意

// 如果担心ABA问题，使用预分配版本
LStack := specialize TPreAllocStack<Integer>.Create(1024);  // ✅ ABA安全
```

### 2. 内存泄漏
```pascal
// 正确：及时释放
var LQueue: specialize TSPSCQueue<Integer>;
begin
  LQueue := specialize TSPSCQueue<Integer>.Create(1024);
  try
    // 使用队列...
  finally
    LQueue.Free;  // ✅ 必须释放
  end;
end;
```

### 3. 容量溢出
```pascal
// 正确：检查返回值
if not LQueue.Enqueue(Item) then
begin
  // 队列已满，处理溢出
  HandleQueueFull;
end;

// 错误：忽略返回值
LQueue.Enqueue(Item);  // ❌ 可能失败
```

## 🎯 总结

fafafa.core.lockfree 提供了世界级性能的无锁数据结构：

1. **选择合适的数据结构** - 根据并发模式选择
2. **正确设置容量** - 使用2的幂次方
3. **监控性能** - 使用内置统计功能
4. **注意线程安全** - 遵循各数据结构的使用约定
5. **处理边界情况** - 检查返回值，处理满/空状态

通过遵循这些最佳实践，您可以充分发挥无锁数据结构的性能优势。


## 🧩 宏与性能开关（最佳实践）

- 默认策略：库构建保持“关闭”以保证通用性与可移植性；仅在基准/压力工程中开启对比
  - Cacheline Padding：-dFAFAFA_LOCKFREE_CACHELINE_PAD（降低伪共享，MPMC/SPSC 争用更友好）
  - Backoff：-dFAFAFA_LOCKFREE_BACKOFF（高冲突 CAS 自适应轻量退避）
- 在 tests/fafafa.core.lockfree 下，已提供快捷脚本：
  - Run_Micro_SPSC_MPMC_PadCompare.bat（单次对比）
  - Run_Micro_BatchMatrix_Quick.bat（小矩阵批跑）
- 结果产出：logs/micro_matrix_*.csv，便于汇总与回归对比

示例（使用统一 lazbuild 工具直接编译开启不同宏的微基准）：
```bat
call tools\lazbuild.bat --build-mode=PadOff tests\fafafa.core.lockfree\benchmark_micro_spsc_mpmc.lpi
call tools\lazbuild.bat --build-mode=PadOn  tests\fafafa.core.lockfree\benchmark_micro_spsc_mpmc.lpi
call tools\lazbuild.bat --build-mode=BackoffOn tests\fafafa.core.lockfree\benchmark_micro_spsc_mpmc.lpi
```

## 🗺️ 哈希表构造（最佳实践）

- 开放寻址（OA）：优先选用泛型构造，无需传函数，缓存友好
  - 直接使用：specialize TLockFreeHashMap<K,V>.Create(ACapacity)
- 分离链表（MM）：优先使用门面便捷构造器，自动携带默认 Hash/Comparer
  - 建议使用门面：CreateIntStrMMHashMap / CreateStrIntMMHashMap / ...
  - 如需直接构造（不推荐）：必须显式传入 Hash/Comparer，例如 DefaultStringHash / DefaultIntegerComparer

示例（门面构造，推荐）：
```pascal
var M: TStringIntHashMap; // type alias to TMichaelHashMap<string,Integer>
begin
  M := CreateStrIntMMHashMap(1024);
  // ... 使用 M.insert/find/erase/update ...
end;
```

示例（OA 构造）：
```pascal
var MOA: specialize TLockFreeHashMap<Integer, string>;
begin
  MOA := specialize TLockFreeHashMap<Integer, string>.Create(1024);
  // ... MOA.Put/Get/Remove ...
end;
```

注意：不要依赖“隐式默认”行为。MM 直接构造时未提供函数将抛出异常；通过门面使用最稳妥。
