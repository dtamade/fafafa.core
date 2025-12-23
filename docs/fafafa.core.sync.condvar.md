# fafafa.core.sync.condvar - 条件变量模块

## 概述

`fafafa.core.sync.condvar` 模块提供了高性能、跨平台的条件变量（Condition Variable）实现，用于线程间的等待/通知机制。

## 核心特性

- **跨平台支持**: Windows（CONDITION_VARIABLE）、Unix/Linux（pthread_cond）
- **零分配结果类型**: `TCondVarWaitResult` 栈分配，无堆开销
- **Rust 风格 API**: `WaitFor` 返回结果值
- **单调时钟**: Unix 使用 `CLOCK_MONOTONIC`，避免系统时间跳变影响
- **原子语义**: 与 `IMutex` 配合保证原子释放+等待

## 核心接口

### ICondVar - 条件变量接口

```pascal
ICondVar = interface(ISynchronizable)
  ['{F9CAE7D8-8A7B-4E5F-9C8D-7B6A5E4D3C2B}']

  // 等待操作
  procedure Wait(const ALock: ILock);                              // 无限等待
  function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; // 带超时等待
  function WaitFor(const ALock: ILock; ATimeoutMs: Cardinal): TCondVarWaitResult; // Rust 风格

  // 唤醒操作
  procedure Signal;     // 唤醒一个等待线程
  procedure Broadcast;  // 唤醒所有等待线程
end;
```

### TCondVarWaitResult - 等待结果（零分配）

```pascal
TCondVarWaitResult = record
  function TimedOut: Boolean;  // 检查是否超时

  class function Signaled: TCondVarWaitResult; static;  // 创建"被唤醒"结果
  class function Timeout: TCondVarWaitResult; static;   // 创建"超时"结果
end;
```

## 工厂函数

### MakeCondVar

```pascal
function MakeCondVar: ICondVar;
```

创建一个新的条件变量实例，自动选择平台最优实现。

## 基础使用

### 生产者-消费者模式

```pascal
uses
  fafafa.core.sync.mutex,
  fafafa.core.sync.condvar;

var
  Mutex: IMutex;
  Cond: ICondVar;
  DataReady: Boolean;
  SharedData: Integer;

// 消费者线程
procedure Consumer;
begin
  Mutex.Acquire;
  try
    // 等待数据就绪
    while not DataReady do
      Cond.Wait(Mutex);

    // 处理数据
    WriteLn('Received: ', SharedData);
    DataReady := False;
  finally
    Mutex.Release;
  end;
end;

// 生产者线程
procedure Producer;
begin
  Mutex.Acquire;
  try
    // 生产数据
    SharedData := 42;
    DataReady := True;

    // 通知消费者
    Cond.Signal;
  finally
    Mutex.Release;
  end;
end;

begin
  // Unix: 必须使用 MakePthreadMutex
  {$IFDEF UNIX}
  Mutex := MakePthreadMutex;
  {$ELSE}
  Mutex := MakeMutex;
  {$ENDIF}
  Cond := MakeCondVar;
  DataReady := False;
end;
```

### 带超时等待

```pascal
var
  Mutex: IMutex;
  Cond: ICondVar;
begin
  {$IFDEF UNIX}
  Mutex := MakePthreadMutex;
  {$ELSE}
  Mutex := MakeMutex;
  {$ENDIF}
  Cond := MakeCondVar;

  Mutex.Acquire;
  try
    // 最多等待 1 秒
    if Cond.Wait(Mutex, 1000) then
      WriteLn('被唤醒')
    else
      WriteLn('等待超时');
  finally
    Mutex.Release;
  end;
end;
```

### Rust 风格 API

```pascal
var
  Mutex: IMutex;
  Cond: ICondVar;
  Result: TCondVarWaitResult;
begin
  {$IFDEF UNIX}
  Mutex := MakePthreadMutex;
  {$ELSE}
  Mutex := MakeMutex;
  {$ENDIF}
  Cond := MakeCondVar;

  Mutex.Acquire;
  try
    // 使用 WaitFor 返回结果值（零分配）
    Result := Cond.WaitFor(Mutex, 1000);

    if Result.TimedOut then
      WriteLn('等待超时')
    else
      WriteLn('被信号唤醒');
  finally
    Mutex.Release;
  end;
end;
```

## 高级用法

### 虚假唤醒防护

条件变量可能产生虚假唤醒，必须在循环中检查条件：

```pascal
Mutex.Acquire;
try
  // ✅ 正确：循环检查条件
  while not ConditionMet do
    Cond.Wait(Mutex);

  // 条件满足，处理逻辑
finally
  Mutex.Release;
end;

// ❌ 错误：单次检查
Mutex.Acquire;
try
  if not ConditionMet then
    Cond.Wait(Mutex);  // 虚假唤醒可能导致错误
  // 可能条件仍未满足！
finally
  Mutex.Release;
end;
```

### 广播唤醒（多消费者）

```pascal
// 生产者：唤醒所有等待者
Mutex.Acquire;
try
  // 准备数据
  DataReady := True;

  // 唤醒所有消费者
  Cond.Broadcast;
finally
  Mutex.Release;
end;

// 多个消费者：同时被唤醒
Mutex.Acquire;
try
  while not DataReady do
    Cond.Wait(Mutex);

  // 竞争处理数据
finally
  Mutex.Release;
end;
```

### 条件等待模式

```pascal
type
  TBoundedQueue = class
  private
    FMutex: IMutex;
    FNotEmpty: ICondVar;
    FNotFull: ICondVar;
    FItems: array of Integer;
    FCount, FHead, FTail, FCapacity: Integer;
  public
    constructor Create(ACapacity: Integer);

    procedure Put(Item: Integer);
    function Take: Integer;
  end;

procedure TBoundedQueue.Put(Item: Integer);
begin
  FMutex.Acquire;
  try
    // 等待直到队列不满
    while FCount = FCapacity do
      FNotFull.Wait(FMutex);

    // 添加元素
    FItems[FTail] := Item;
    FTail := (FTail + 1) mod FCapacity;
    Inc(FCount);

    // 通知消费者
    FNotEmpty.Signal;
  finally
    FMutex.Release;
  end;
end;

function TBoundedQueue.Take: Integer;
begin
  FMutex.Acquire;
  try
    // 等待直到队列不空
    while FCount = 0 do
      FNotEmpty.Wait(FMutex);

    // 取出元素
    Result := FItems[FHead];
    FHead := (FHead + 1) mod FCapacity;
    Dec(FCount);

    // 通知生产者
    FNotFull.Signal;
  finally
    FMutex.Release;
  end;
end;
```

## 平台实现细节

### Unix/Linux

```
TCondVar
├── pthread_cond_t
├── pthread_condattr_setclock(CLOCK_MONOTONIC)  // 单调时钟
└── pthread_cond_timedwait / pthread_cond_wait
```

**时钟语义**:
- 使用 `CLOCK_MONOTONIC` 避免系统时间调整影响超时
- 超时计算不受 NTP 或手动时间调整影响

**原子性保证**:
- 当 `ALock` 实现 `IUnixMutexProvider` 接口时，使用底层 `pthread_mutex_t`
- 保证"原子释放+等待"的强语义
- 非 pthread_mutex 的锁只能提供近似行为

### Windows

```
TCondVar
├── CONDITION_VARIABLE (Vista+)
├── SleepConditionVariableCS / SleepConditionVariableSRW
└── WakeConditionVariable / WakeAllConditionVariable
```

## Signal vs Broadcast

| 方法 | 唤醒数量 | 适用场景 |
|------|---------|---------|
| `Signal` | 1 个 | 单消费者、资源独占 |
| `Broadcast` | 所有 | 多消费者、条件改变 |

### 何时使用 Signal

```pascal
// 单个资源就绪，只需唤醒一个等待者
ResourceReady := True;
Cond.Signal;
```

### 何时使用 Broadcast

```pascal
// 1. 状态改变，所有等待者需要重新检查条件
ShutdownFlag := True;
Cond.Broadcast;

// 2. 多个资源就绪
AvailableResources := 5;
Cond.Broadcast;

// 3. 不确定时，Broadcast 更安全
Cond.Broadcast;  // 不会遗漏唤醒
```

## 重要警告

### 锁类型要求

```pascal
// ⚠️ 警告：只有 IMutex 能保证原子语义

// ✅ 正确：使用 pthread 兼容的 mutex
{$IFDEF UNIX}
Mutex := MakePthreadMutex;  // 必须使用此函数
{$ELSE}
Mutex := MakeMutex;
{$ENDIF}
Cond.Wait(Mutex);  // 保证原子释放+等待

// ⚠️ 危险：使用 futex mutex
Mutex := MakeFutexMutex;
Cond.Wait(Mutex);  // futex 不与 pthread_cond 兼容！

// ⚠️ 危险：使用其他 ILock 实现
SpinLock := MakeSpin;
Cond.Wait(SpinLock);  // 可能有竞态窗口
```

### 持有锁调用

```pascal
// ✅ 正确：Wait 前必须持有锁
Mutex.Acquire;
try
  Cond.Wait(Mutex);
finally
  Mutex.Release;
end;

// ❌ 错误：未持有锁调用 Wait
// Cond.Wait(Mutex);  // 未定义行为！

// ✅ Signal/Broadcast 建议在锁内调用
Mutex.Acquire;
try
  Cond.Signal;  // 确保内存可见性
finally
  Mutex.Release;
end;

// ⚠️ 锁外调用可能遗漏唤醒
Mutex.Acquire;
try
  DataReady := True;
finally
  Mutex.Release;
end;
Cond.Signal;  // 在锁释放和 Signal 之间可能有竞态
```

## 最佳实践

### 1. 始终在循环中等待

```pascal
while not Condition do
  Cond.Wait(Mutex);
```

### 2. Unix 使用 MakePthreadMutex

```pascal
{$IFDEF UNIX}
Mutex := MakePthreadMutex;
{$ENDIF}
```

### 3. 不确定时使用 Broadcast

```pascal
// Signal 可能导致等待者永远等待
// Broadcast 更安全，但可能有性能开销
Cond.Broadcast;
```

### 4. 超时等待避免无限阻塞

```pascal
Result := Cond.WaitFor(Mutex, 5000);
if Result.TimedOut then
  // 处理超时情况
```

### 5. 使用 Rust 风格 API

```pascal
// 零分配，类型安全
Result := Cond.WaitFor(Mutex, 1000);
if Result.TimedOut then
  // ...
```

## 常见陷阱

### 陷阱 1：单次 if 检查

```pascal
// ❌ 虚假唤醒导致条件不满足
if not Ready then
  Cond.Wait(Mutex);
// Ready 可能仍为 False！
```

### 陷阱 2：错误的锁类型

```pascal
// ❌ futex mutex 不兼容 pthread_cond
Mutex := MakeFutexMutex;  // 或 MakeMutex (启用 futex 时)
Cond.Wait(Mutex);  // 未定义行为！
```

### 陷阱 3：忘记持有锁

```pascal
// ❌ Wait 前未获取锁
Cond.Wait(Mutex);  // 崩溃或未定义行为
```

### 陷阱 4：Signal 在锁外

```pascal
// ⚠️ 可能遗漏唤醒
Mutex.Release;
Cond.Signal;  // 消费者可能在 Release 和 Signal 之间检查条件
```

## 异常处理

| 异常类型 | 触发条件 |
|---------|---------|
| `ELockError` | 系统调用失败 |
| `EWaitError` | 等待操作失败 |

## 相关文档

- [fafafa.core.sync](fafafa.core.sync.md) - 主同步模块
- [fafafa.core.sync.mutex](fafafa.core.sync.mutex.md) - 互斥锁
- [fafafa.core.sync.barrier](fafafa.core.sync.barrier.md) - 屏障同步
- [fafafa.core.sync.event](fafafa.core.sync.event.md) - 事件

## 版本历史

### v2.0.0 (2025-12)
- 添加 `WaitFor` Rust 风格 API
- `TCondVarWaitResult` 零分配结果类型
- Unix 使用 `CLOCK_MONOTONIC` 单调时钟
- 改进文档和警告说明

### v1.0.0
- 基础条件变量实现
- 跨平台支持
