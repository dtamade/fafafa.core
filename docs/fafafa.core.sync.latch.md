# fafafa.core.sync.latch

## 概述

Latch（CountDownLatch）是一个 Java 风格的一次性倒计数同步原语，用于等待一组事件发生。与 WaitGroup 不同，Latch 的计数只能减少不能增加，适合一次性门控场景。

## 核心概念

### 倒计数机制

Latch 维护一个只能递减的计数器：
- 创建时指定初始计数值
- `CountDown()` 减少计数 1
- `Await()` 阻塞直到计数为 0
- 计数到达 0 后不可重置（一次性）

### 两种典型使用模式

#### 1. 门控启动（Start Gate）
所有工作线程等待一个启动信号，然后同时开始工作。

```pascal
var LStartGate := MakeLatch(1);
// 所有线程等待
LStartGate.Await;
// 主线程发出启动信号
LStartGate.CountDown;  // 所有线程同时开始
```

#### 2. 完成等待（Completion Wait）
主线程等待所有工作线程完成。

```pascal
var LDoneLatch := MakeLatch(N);
// 每个工作线程完成时
LDoneLatch.CountDown;
// 主线程等待所有完成
LDoneLatch.Await;
```

## API 参考

### 类型定义

```pascal
type
  ILatch = interface(ISynchronizable)
    ['{B4E8C3D1-7A2F-4B9E-8C1D-5E6F7A8B9C0D}']
    
    procedure CountDown;
    procedure Await;
    function AwaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function AwaitDuration(const ADuration: TDuration): TWaitResult;
    function GetCount: Integer;
  end;
```

### 创建 Latch

```pascal
function MakeLatch(ACount: Integer): ILatch;
```

创建一个新的 CountDownLatch，初始计数为 `ACount`。

**参数**：
- `ACount` - 初始计数值（必须 >= 0）

**返回值**：
- `ILatch` - Latch 接口实例

**线程安全性**：
- 返回的实例是线程安全的

**异常**：
- `EInvalidArgument` - 如果 `ACount < 0`

### CountDown

```pascal
procedure CountDown;
```

减少计数 1。

**行为**：
- 将计数减 1
- 如果计数已经为 0，则什么都不做
- 当计数降为 0 时，唤醒所有等待的线程

**线程安全性**：
- 线程安全，可从任意线程调用

### Await

```pascal
procedure Await;
```

阻塞直到计数为 0。

**行为**：
- 阻塞当前线程直到计数降为 0
- 如果计数已经为 0，立即返回

**线程安全性**：
- 线程安全，可从任意线程调用

### AwaitTimeout

```pascal
function AwaitTimeout(ATimeoutMs: Cardinal): Boolean;
```

带超时的等待。

**参数**：
- `ATimeoutMs` - 超时时间（毫秒）

**返回值**：
- `True` - 计数变为 0
- `False` - 超时

**行为**：
- 阻塞当前线程直到计数降为 0 或超时

**线程安全性**：
- 线程安全

### AwaitDuration

```pascal
function AwaitDuration(const ADuration: TDuration): TWaitResult;
```

使用 `TDuration` 的超时等待，提供更灵活的时间单位支持。

**参数**：
- `ADuration` - 超时时间（TDuration 类型）

**返回值**：
- `wrSignaled` - 计数变为 0
- `wrTimeout` - 超时

**线程安全性**：
- 线程安全

### GetCount

```pascal
function GetCount: Integer;
```

获取当前计数值。

**返回值**：
- 当前计数值

**注意**：
- 这是一个瞬时值，主要用于调试和监控

**线程安全性**：
- 线程安全（但返回值可能立即过时）

## 使用示例

### 门控启动模式

```pascal
uses
  fafafa.core.sync.latch;

var
  LStartGate: ILatch;
begin
  LStartGate := MakeLatch(1);
  
  // 创建等待启动的工作线程
  for var i := 1 to 10 do
  begin
    TThread.CreateAnonymousThread(procedure
    var
      LWorkerID: Integer;
    begin
      LWorkerID := i;
      WriteLn(Format('Worker %d ready', [LWorkerID]));
      
      // 等待启动信号
      LStartGate.Await;
      
      // 开始工作
      WriteLn(Format('Worker %d started', [LWorkerID]));
      // 执行工作...
    end).Start;
  end;
  
  // 准备工作完成
  WriteLn('All workers ready, starting...');
  Sleep(1000);  // 模拟准备时间
  
  // 发出启动信号，所有线程同时开始
  LStartGate.CountDown;
end;
```

### 完成等待模式

```pascal
var
  LDoneLatch: ILatch;
const
  WORKER_COUNT = 5;
begin
  LDoneLatch := MakeLatch(WORKER_COUNT);
  
  // 启动工作线程
  for var i := 1 to WORKER_COUNT do
  begin
    TThread.CreateAnonymousThread(procedure
    var
      LWorkerID: Integer;
    begin
      LWorkerID := i;
      
      // 执行工作
      WriteLn(Format('Worker %d working...', [LWorkerID]));
      Sleep(Random(2000));
      
      // 完成
      WriteLn(Format('Worker %d done', [LWorkerID]));
      LDoneLatch.CountDown;
    end).Start;
  end;
  
  // 等待所有工作完成
  LDoneLatch.Await;
  WriteLn('All workers completed!');
end;
```

### 双门控模式（启动 + 完成）

```pascal
var
  LStartGate: ILatch;
  LDoneLatch: ILatch;
const
  WORKER_COUNT = 3;
begin
  LStartGate := MakeLatch(1);
  LDoneLatch := MakeLatch(WORKER_COUNT);
  
  // 创建工作线程
  for var i := 1 to WORKER_COUNT do
  begin
    TThread.CreateAnonymousThread(procedure
    var
      LWorkerID: Integer;
    begin
      LWorkerID := i;
      WriteLn(Format('Worker %d ready', [LWorkerID]));
      
      // 等待启动信号
      LStartGate.Await;
      
      // 执行工作
      WriteLn(Format('Worker %d working...', [LWorkerID]));
      Sleep(Random(1000));
      
      // 完成
      WriteLn(Format('Worker %d done', [LWorkerID]));
      LDoneLatch.CountDown;
    end).Start;
  end;
  
  // 等待所有线程准备就绪
  Sleep(500);
  
  // 发出启动信号
  WriteLn('Starting all workers...');
  LStartGate.CountDown;
  
  // 等待所有完成
  LDoneLatch.Await;
  WriteLn('All workers completed!');
end;
```

### 带超时的等待

```pascal
var
  LLatch: ILatch;
  LCompleted: Boolean;
begin
  LLatch := MakeLatch(5);
  
  // 启动工作线程...
  
  // 等待最多 10 秒
  LCompleted := LLatch.AwaitTimeout(10000);
  
  if LCompleted then
    WriteLn('所有任务完成')
  else
    WriteLn('超时：部分任务未完成');
end;
```

### 分阶段执行

```pascal
type
  TPhase = (phInit, phProcess, phFinalize);

procedure ExecutePhase(const APhase: TPhase; const ALatch: ILatch);
begin
  case APhase of
    phInit: WriteLn('初始化阶段');
    phProcess: WriteLn('处理阶段');
    phFinalize: WriteLn('完成阶段');
  end;
  
  // 模拟工作
  Sleep(Random(500));
  
  // 完成当前阶段
  ALatch.CountDown;
end;

var
  LPhaseLatch: ILatch;
const
  WORKER_COUNT = 4;
begin
  // 阶段 1：初始化
  LPhaseLatch := MakeLatch(WORKER_COUNT);
  for var i := 1 to WORKER_COUNT do
    TThread.CreateAnonymousThread(procedure
    begin
      ExecutePhase(phInit, LPhaseLatch);
    end).Start;
  LPhaseLatch.Await;
  WriteLn('初始化阶段完成');
  
  // 阶段 2：处理
  LPhaseLatch := MakeLatch(WORKER_COUNT);
  for var i := 1 to WORKER_COUNT do
    TThread.CreateAnonymousThread(procedure
    begin
      ExecutePhase(phProcess, LPhaseLatch);
    end).Start;
  LPhaseLatch.Await;
  WriteLn('处理阶段完成');
  
  // 阶段 3：完成
  LPhaseLatch := MakeLatch(WORKER_COUNT);
  for var i := 1 to WORKER_COUNT do
    TThread.CreateAnonymousThread(procedure
    begin
      ExecutePhase(phFinalize, LPhaseLatch);
    end).Start;
  LPhaseLatch.Await;
  WriteLn('所有阶段完成');
end;
```

## 平台实现

### Windows

- 使用 `ManualResetEvent` 实现
- 高效的内核对象同步
- 支持超时等待

### Unix/Linux/macOS

- 使用 `pthread_cond` 实现
- POSIX 标准兼容
- 支持超时等待

## 性能特性

### 开销分析

| 操作 | 开销 | 说明 |
|------|------|------|
| `MakeLatch` | 低 | 分配同步对象 |
| `CountDown` | 极低 | 原子操作 + 可能的唤醒 |
| `Await`（计数为0） | 极低 | 仅检查计数器 |
| `Await`（计数>0） | 中 | 线程上下文切换 |

### 性能建议

1. **重用策略**：Latch 是一次性的，无法重用，需要重新创建
2. **批量唤醒**：计数到达 0 时会唤醒所有等待线程，适合广播场景
3. **避免过度等待**：使用超时避免死锁

## 使用场景

### 适合的场景

✅ **同步启动多个线程**
```pascal
// 所有线程同时开始工作
LStartGate.CountDown;
```

✅ **等待多个任务完成**
```pascal
// 等待所有工作线程完成
LDoneLatch.Await;
```

✅ **分阶段执行**
```pascal
// 每个阶段使用一个 Latch
Phase1Latch.Await;
Phase2Latch.Await;
```

✅ **一次性事件通知**
```pascal
// 等待某个一次性事件发生
LEventLatch.Await;
```

### 不适合的场景

❌ **需要重复使用**
- 使用 `Barrier` 或 `WaitGroup`

❌ **需要增加计数**
- 使用 `WaitGroup`

❌ **需要条件等待**
- 使用 `CondVar`

## 与其他同步原语的比较

### Latch vs WaitGroup

| 特性 | Latch | WaitGroup |
|------|-------|-----------|
| 计数方向 | 仅减少 | 可增可减 |
| 重用性 | 一次性 | 可重用 |
| 典型用途 | 门控启动 | 任务等待 |
| 灵活性 | 低 | 高 |

### Latch vs Barrier

| 特性 | Latch | Barrier |
|------|-------|---------|
| 用途 | 等待事件完成 | 同步到达同一点 |
| 参与者 | 不对称（等待者 vs 完成者） | 对称（所有线程平等） |
| 重用性 | 一次性 | 可重用（循环） |
| 计数 | 递减到 0 | 固定数量到达 |

### Latch vs Event

| 特性 | Latch | Event |
|------|-------|-------|
| 计数 | 支持倒计数 | 无计数 |
| 唤醒 | 计数为 0 时唤醒 | 手动/自动唤醒 |
| 适用场景 | 多事件完成 | 单一事件通知 |

## 注意事项

### 一次性使用

⚠️ **Latch 不可重置**
```pascal
var LLatch := MakeLatch(1);
LLatch.CountDown;
LLatch.Await;  // 立即返回

// ❌ 错误：无法重置
// LLatch 已经到达 0，无法再次使用

// ✅ 正确：创建新的 Latch
LLatch := MakeLatch(1);
```

### 计数管理

⚠️ **避免过度 CountDown**
```pascal
var LLatch := MakeLatch(2);
LLatch.CountDown;
LLatch.CountDown;
LLatch.CountDown;  // 计数已为 0，无效但不报错
```

### 死锁风险

⚠️ **确保 CountDown 被调用**
```pascal
// ❌ 错误：如果工作线程崩溃，Await 会永久阻塞
var LLatch := MakeLatch(N);
// 启动 N 个线程...
LLatch.Await;  // 可能永久阻塞

// ✅ 正确：使用超时
if not LLatch.AwaitTimeout(10000) then
  WriteLn('超时：部分线程未完成');
```

### 异常处理

⚠️ **工作线程中的异常**
```pascal
TThread.CreateAnonymousThread(procedure
begin
  try
    // 工作可能抛出异常
    DoWork;
  finally
    LLatch.CountDown;  // 确保总是调用
  end;
end).Start;
```

## 最佳实践

### 1. 使用 try-finally 确保 CountDown

```pascal
TThread.CreateAnonymousThread(procedure
begin
  try
    // 执行工作
    DoWork;
  finally
    LLatch.CountDown;  // 确保总是调用
  end;
end).Start;
```

### 2. 使用超时避免死锁

```pascal
const TIMEOUT_MS = 30000;  // 30 秒
if not LLatch.AwaitTimeout(TIMEOUT_MS) then
begin
  // 超时处理
  WriteLn('警告：等待超时');
  // 执行清理或恢复逻辑
end;
```

### 3. 门控启动模式

```pascal
// 创建启动门控
var LStartGate := MakeLatch(1);

// 创建所有工作线程
for var i := 1 to WorkerCount do
  CreateWorker(LStartGate);

// 等待所有线程准备就绪
Sleep(100);

// 同时启动所有线程
LStartGate.CountDown;
```

### 4. 监控进度（调试用）

```pascal
{$IFDEF DEBUG}
TThread.CreateAnonymousThread(procedure
begin
  while LLatch.GetCount > 0 do
  begin
    WriteLn(Format('剩余: %d', [LLatch.GetCount]));
    Sleep(1000);
  end;
  WriteLn('完成！');
end).Start;
{$ENDIF}
```

### 5. 资源清理

```pascal
// Latch 使用接口引用计数，无需手动释放
var
  LLatch: ILatch;
begin
  LLatch := MakeLatch(5);
  // 使用 Latch
  // 离开作用域时自动释放
end;
```

## 调试与测试

### 调试检查

```pascal
{$IFDEF DEBUG}
procedure DebugLatch(const ALatch: ILatch; const AContext: string);
begin
  WriteLn(Format('[%s] Latch 计数: %d, 上下文: %s',
    [DateTimeToStr(Now), ALatch.GetCount, AContext]));
end;
{$ENDIF}
```

### 测试模板

```pascal
procedure TestLatchBasic;
var
  LLatch: ILatch;
  LCounter: Integer;
const
  COUNT = 5;
begin
  LLatch := MakeLatch(COUNT);
  LCounter := 0;
  
  // 启动工作线程
  for var i := 1 to COUNT do
  begin
    TThread.CreateAnonymousThread(procedure
    begin
      AtomicIncrement(LCounter);
      LLatch.CountDown;
    end).Start;
  end;
  
  // 等待完成
  LLatch.Await;
  
  Assert(LCounter = COUNT, '所有任务应该完成');
  Assert(LLatch.GetCount = 0, '计数应该为 0');
  WriteLn('Latch 基本测试通过');
end;
```

## 相关模块

- `fafafa.core.sync.waitgroup` - 等待组（可重用，可增减计数）
- `fafafa.core.sync.barrier` - 屏障（循环同步点）
- `fafafa.core.sync.event` - 事件对象（简单通知）
- `fafafa.core.sync.base` - 同步原语基础接口

## 参考资料

- Java `java.util.concurrent.CountDownLatch` 文档
- POSIX `pthread_cond` 规范
- Windows Event Objects 文档

## 版本历史

- **v1.0** - 初始版本，支持基本的 CountDown/Await 功能
- 支持超时等待（AwaitTimeout, AwaitDuration）
- 支持计数器查询（GetCount）
- 跨平台实现（Windows/Unix）
- 一次性设计（不可重置）
