# fafafa.core.sync.waitgroup

## 概述

WaitGroup 是一个 Go 风格的等待组同步原语，用于等待一组并发操作完成。主线程调用 `Add` 设置要等待的操作数量，每个操作完成时调用 `Done`，主线程调用 `Wait` 阻塞直到所有操作完成。

## 核心概念

### 计数器机制

WaitGroup 维护一个内部计数器：
- `Add(N)` 增加计数器 N
- `Done()` 减少计数器 1（等同于 `Add(-1)`）
- `Wait()` 阻塞直到计数器为 0

### 与 Go sync.WaitGroup 的区别

| 特性 | Go sync.WaitGroup | fafafa WaitGroup |
|------|-------------------|------------------|
| Wait 期间 Add | 会 panic | 允许（但需谨慎） |
| 可重用性 | 不可重用 | 可重用 |
| 负计数器 | panic | 抛出异常 |
| GetCount | 不提供 | 提供（调试用） |

## API 参考

### 类型定义

```pascal
type
  IWaitGroup = interface(ISynchronizable)
    ['{A3F7B2E1-9C4D-4A8F-B5E6-7D1C3E2F4A9B}']
    
    procedure Add(ADelta: Integer);
    procedure Done;
    procedure Wait;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function WaitDuration(const ADuration: TDuration): TWaitResult;
    function GetCount: Integer;
  end;
```

### 创建 WaitGroup

```pascal
function MakeWaitGroup: IWaitGroup;
```

创建一个新的 WaitGroup，初始计数为 0。自动选择当前平台的最优实现。

**返回值**：
- `IWaitGroup` - WaitGroup 接口实例

**线程安全性**：
- 返回的实例是线程安全的

### Add

```pascal
procedure Add(ADelta: Integer);
```

原子地增加或减少计数器。

**参数**：
- `ADelta` - 增量（可为正或负）

**行为**：
- 原子地将 `ADelta` 加到计数器
- 如果结果计数器变为负数，抛出 `EInvalidArgument` 异常

**线程安全性**：
- 线程安全，可从任意线程调用

**异常**：
- `EInvalidArgument` - 如果计数器变为负数

### Done

```pascal
procedure Done;
```

减少计数器 1，等同于 `Add(-1)`。

**行为**：
- 工作线程完成任务后调用
- 当计数器降为 0 时，唤醒所有等待的线程

**线程安全性**：
- 线程安全

**异常**：
- `EInvalidArgument` - 如果计数器变为负数

### Wait

```pascal
procedure Wait;
```

阻塞直到计数器为 0。

**行为**：
- 阻塞当前线程直到计数器降为 0
- 如果计数器已经为 0，立即返回

**线程安全性**：
- 线程安全，可从任意线程调用

### WaitTimeout

```pascal
function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
```

带超时的等待。

**参数**：
- `ATimeoutMs` - 超时时间（毫秒）

**返回值**：
- `True` - 计数器变为 0
- `False` - 超时

**行为**：
- 阻塞当前线程直到计数器降为 0 或超时

**线程安全性**：
- 线程安全

### WaitDuration

```pascal
function WaitDuration(const ADuration: TDuration): TWaitResult;
```

使用 `TDuration` 的超时等待，提供更灵活的时间单位支持。

**参数**：
- `ADuration` - 超时时间（TDuration 类型）

**返回值**：
- `wrSignaled` - 计数器变为 0
- `wrTimeout` - 超时

**线程安全性**：
- 线程安全

### GetCount

```pascal
function GetCount: Integer;
```

获取当前计数器值。

**返回值**：
- 当前计数器值

**注意**：
- 这是一个瞬时值，主要用于调试和监控
- 不应用于同步逻辑（返回值可能立即过时）

**线程安全性**：
- 线程安全（但返回值可能立即过时）

## 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.waitgroup;

var
  LWG: IWaitGroup;
begin
  LWG := MakeWaitGroup;
  LWG.Add(3);  // 3 个工作任务
  
  // 启动工作线程
  TThread.CreateAnonymousThread(procedure begin
    // 工作 1...
    WriteLn('Worker 1 done');
    LWG.Done;
  end).Start;
  
  TThread.CreateAnonymousThread(procedure begin
    // 工作 2...
    WriteLn('Worker 2 done');
    LWG.Done;
  end).Start;
  
  TThread.CreateAnonymousThread(procedure begin
    // 工作 3...
    WriteLn('Worker 3 done');
    LWG.Done;
  end).Start;
  
  LWG.Wait;  // 等待所有工作完成
  WriteLn('All workers done!');
end;
```

### 动态添加任务

```pascal
var
  LWG: IWaitGroup;
  LTaskCount: Integer;
begin
  LWG := MakeWaitGroup;
  
  // 动态添加任务
  for LTaskCount := 1 to 10 do
  begin
    LWG.Add(1);
    TThread.CreateAnonymousThread(procedure
    var
      LTaskID: Integer;
    begin
      LTaskID := LTaskCount;
      // 执行任务
      Sleep(Random(1000));
      WriteLn(Format('Task %d completed', [LTaskID]));
      LWG.Done;
    end).Start;
  end;
  
  LWG.Wait;
  WriteLn('All tasks completed');
end;
```

### 带超时的等待

```pascal
var
  LWG: IWaitGroup;
  LCompleted: Boolean;
begin
  LWG := MakeWaitGroup;
  LWG.Add(5);
  
  // 启动工作线程...
  
  // 等待最多 5 秒
  LCompleted := LWG.WaitTimeout(5000);
  
  if LCompleted then
    WriteLn('所有任务完成')
  else
    WriteLn('超时：部分任务未完成');
end;
```

### 批量操作

```pascal
var
  LWG: IWaitGroup;
const
  BATCH_SIZE = 100;
begin
  LWG := MakeWaitGroup;
  
  // 一次性添加多个任务
  LWG.Add(BATCH_SIZE);
  
  for var i := 1 to BATCH_SIZE do
  begin
    TThread.CreateAnonymousThread(procedure
    begin
      // 批量处理
      ProcessItem(i);
      LWG.Done;
    end).Start;
  end;
  
  LWG.Wait;
end;
```

### 嵌套 WaitGroup

```pascal
procedure ProcessBatch(const ABatchID: Integer);
var
  LInnerWG: IWaitGroup;
begin
  LInnerWG := MakeWaitGroup;
  LInnerWG.Add(10);
  
  for var i := 1 to 10 do
  begin
    TThread.CreateAnonymousThread(procedure
    begin
      // 处理批次内的项目
      ProcessBatchItem(ABatchID, i);
      LInnerWG.Done;
    end).Start;
  end;
  
  LInnerWG.Wait;
  WriteLn(Format('Batch %d completed', [ABatchID]));
end;

var
  LOuterWG: IWaitGroup;
begin
  LOuterWG := MakeWaitGroup;
  LOuterWG.Add(5);
  
  for var i := 1 to 5 do
  begin
    TThread.CreateAnonymousThread(procedure
    var
      LBatchID: Integer;
    begin
      LBatchID := i;
      ProcessBatch(LBatchID);
      LOuterWG.Done;
    end).Start;
  end;
  
  LOuterWG.Wait;
  WriteLn('All batches completed');
end;
```

## 平台实现

### Windows

- 使用 `CriticalSection` + `ManualResetEvent` 实现
- 高效的内核对象同步
- 支持超时等待

### Unix/Linux/macOS

- 使用 `pthread_mutex` + `pthread_cond` 实现
- POSIX 标准兼容
- 支持超时等待

## 性能特性

### 开销分析

| 操作 | 开销 | 说明 |
|------|------|------|
| `MakeWaitGroup` | 低 | 分配同步对象 |
| `Add` | 极低 | 原子操作 + 可能的唤醒 |
| `Done` | 极低 | 原子操作 + 可能的唤醒 |
| `Wait`（计数为0） | 极低 | 仅检查计数器 |
| `Wait`（计数>0） | 中 | 线程上下文切换 |

### 性能建议

1. **批量添加**：优先使用 `Add(N)` 而不是多次 `Add(1)`
2. **避免频繁创建**：重用 WaitGroup 实例
3. **合理超时**：避免过短的超时导致忙等待
4. **减少竞争**：避免过多线程同时调用 `Done`

## 使用场景

### 适合的场景

✅ **并行任务等待**
```pascal
// 等待多个并行任务完成
LWG.Add(TaskCount);
for i := 1 to TaskCount do
  SpawnWorker(LWG);
LWG.Wait;
```

✅ **批量处理**
```pascal
// 批量处理数据
LWG.Add(Length(Items));
for Item in Items do
  ProcessAsync(Item, LWG);
LWG.Wait;
```

✅ **资源清理**
```pascal
// 等待所有资源释放
LWG.Add(ResourceCount);
for Resource in Resources do
  CleanupAsync(Resource, LWG);
LWG.Wait;
```

### 不适合的场景

❌ **需要取消操作**
- 使用 `CancellationToken` 或类似机制

❌ **需要获取结果**
- 使用 `Future/Promise` 模式

❌ **需要顺序执行**
- 直接顺序调用，无需 WaitGroup

## 注意事项

### 计数器管理

⚠️ **避免计数器变为负数**
```pascal
// ❌ 错误：Done 次数超过 Add
LWG.Add(2);
LWG.Done;
LWG.Done;
LWG.Done;  // 抛出异常！

// ✅ 正确：Done 次数等于 Add
LWG.Add(2);
LWG.Done;
LWG.Done;
```

### Wait 期间 Add

⚠️ **谨慎在 Wait 期间调用 Add**
```pascal
// 可能导致死锁或意外行为
TThread.CreateAnonymousThread(procedure
begin
  LWG.Wait;
  LWG.Add(1);  // 危险！
end).Start;
```

### 重用 WaitGroup

✅ **WaitGroup 可以重用**
```pascal
var
  LWG: IWaitGroup;
begin
  LWG := MakeWaitGroup;
  
  // 第一轮
  LWG.Add(5);
  // ... 工作 ...
  LWG.Wait;
  
  // 第二轮（重用）
  LWG.Add(3);
  // ... 工作 ...
  LWG.Wait;
end;
```

### 异常处理

⚠️ **工作线程中的异常不会传播**
```pascal
TThread.CreateAnonymousThread(procedure
begin
  try
    // 工作可能抛出异常
    DoWork;
  finally
    LWG.Done;  // 确保总是调用 Done
  end;
end).Start;
```

## 最佳实践

### 1. 使用 try-finally 确保 Done

```pascal
TThread.CreateAnonymousThread(procedure
begin
  try
    // 执行工作
    DoWork;
  finally
    LWG.Done;  // 确保总是调用
  end;
end).Start;
```

### 2. 批量添加任务

```pascal
// ✅ 好：批量添加
LWG.Add(TaskCount);
for i := 1 to TaskCount do
  SpawnWorker;

// ❌ 差：逐个添加
for i := 1 to TaskCount do
begin
  LWG.Add(1);
  SpawnWorker;
end;
```

### 3. 使用超时避免死锁

```pascal
if not LWG.WaitTimeout(10000) then
begin
  // 超时处理
  WriteLn('警告：部分任务未完成');
  // 执行清理或恢复逻辑
end;
```

### 4. 监控进度（调试用）

```pascal
{$IFDEF DEBUG}
TThread.CreateAnonymousThread(procedure
begin
  while LWG.GetCount > 0 do
  begin
    WriteLn(Format('剩余任务: %d', [LWG.GetCount]));
    Sleep(1000);
  end;
end).Start;
{$ENDIF}
```

### 5. 资源清理

```pascal
// WaitGroup 使用接口引用计数，无需手动释放
var
  LWG: IWaitGroup;
begin
  LWG := MakeWaitGroup;
  // 使用 WaitGroup
  // 离开作用域时自动释放
end;
```

## 与其他同步原语的比较

### WaitGroup vs Barrier

| 特性 | WaitGroup | Barrier |
|------|-----------|---------|
| 用途 | 等待任务完成 | 同步多个线程到达同一点 |
| 计数器 | 可动态调整 | 固定 |
| 重用性 | 可重用 | 可重用（循环） |
| 适用场景 | 主从模式 | 对等模式 |

### WaitGroup vs Latch

| 特性 | WaitGroup | Latch |
|------|-----------|-------|
| 重用性 | 可重用 | 一次性 |
| 计数方向 | 增加/减少 | 仅减少 |
| 灵活性 | 高 | 低 |

## 调试与测试

### 调试检查

```pascal
{$IFDEF DEBUG}
procedure DebugWaitGroup(const AWG: IWaitGroup; const AContext: string);
begin
  WriteLn(Format('[%s] WaitGroup 计数: %d, 上下文: %s',
    [DateTimeToStr(Now), AWG.GetCount, AContext]));
end;
{$ENDIF}
```

### 测试模板

```pascal
procedure TestWaitGroupBasic;
var
  LWG: IWaitGroup;
  LCounter: Integer;
begin
  LWG := MakeWaitGroup;
  LCounter := 0;
  
  LWG.Add(10);
  for var i := 1 to 10 do
  begin
    TThread.CreateAnonymousThread(procedure
    begin
      AtomicIncrement(LCounter);
      LWG.Done;
    end).Start;
  end;
  
  LWG.Wait;
  Assert(LCounter = 10, '所有任务应该完成');
  WriteLn('WaitGroup 基本测试通过');
end;
```

## 相关模块

- `fafafa.core.sync.barrier` - 屏障（同步多个线程到达同一点）
- `fafafa.core.sync.latch` - 门闩（一次性倒计数）
- `fafafa.core.sync.condvar` - 条件变量（复杂的等待机制）
- `fafafa.core.sync.base` - 同步原语基础接口

## 参考资料

- Go `sync.WaitGroup` 文档
- POSIX `pthread_cond` 规范
- Windows Event Objects 文档

## 版本历史

- **v1.0** - 初始版本，支持基本的 Add/Done/Wait 功能
- 支持超时等待（WaitTimeout, WaitDuration）
- 支持计数器查询（GetCount）
- 跨平台实现（Windows/Unix）
- 可重用设计（与 Go 不同）
