# fafafa.core.sync.mutex 使用指南

## 概述

`fafafa.core.sync.mutex` 模块提供了高性能、跨平台的互斥锁实现，用于保护共享资源免受并发访问的影响。本模块实现了非重入互斥锁，适用于大多数同步场景。

## 核心特性

- **跨平台支持**：Windows、Linux、macOS、FreeBSD 等
- **高性能实现**：使用平台原生 API 优化
- **非重入设计**：防止死锁和逻辑错误
- **异常安全**：RAII 风格的锁保护
- **调试友好**：详细的错误信息和诊断

## 基本用法

### 1. 创建互斥锁

```pascal
uses
  fafafa.core.sync.mutex;

var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;
end;
```

### 2. 手动锁管理

```pascal
procedure CriticalOperation;
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;
  
  Mutex.Acquire;
  try
    // 临界区代码
    WriteLn('在临界区中执行操作');
  finally
    Mutex.Release;
  end;
end;
```

### 3. RAII 风格锁管理（推荐）

```pascal
procedure SafeOperation;
var
  Guard: ILockGuard;
begin
  Guard := MutexGuard;  // 自动获取锁
  
  // 临界区代码
  WriteLn('在临界区中执行操作');
  
  // Guard 超出作用域时自动释放锁
end;
```

### 4. 非阻塞锁获取

```pascal
procedure TryLockExample;
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;
  
  if Mutex.TryAcquire then
  begin
    try
      // 成功获取锁，执行临界区代码
      WriteLn('获取锁成功');
    finally
      Mutex.Release;
    end;
  end
  else
  begin
    // 无法获取锁，执行替代逻辑
    WriteLn('无法获取锁，跳过操作');
  end;
end;
```

### 5. 带超时的锁获取

```pascal
procedure TimeoutLockExample;
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;
  
  if Mutex.TryAcquire(1000) then  // 等待最多 1 秒
  begin
    try
      WriteLn('在超时前获取到锁');
    finally
      Mutex.Release;
    end;
  end
  else
  begin
    WriteLn('获取锁超时');
  end;
end;
```

## 多线程示例

### 共享计数器保护

```pascal
program SharedCounterExample;

uses
  fafafa.core.sync.mutex, fafafa.core.thread;

var
  SharedCounter: Integer = 0;
  CounterMutex: IMutex;

procedure IncrementCounter;
var
  Guard: ILockGuard;
  i: Integer;
begin
  for i := 1 to 1000 do
  begin
    Guard := MakeLockGuard(CounterMutex);
    Inc(SharedCounter);
    // Guard 自动释放
  end;
end;

begin
  CounterMutex := MakeMutex;
  
  // 启动多个线程
  var Thread1 := TThread.CreateAnonymousThread(IncrementCounter);
  var Thread2 := TThread.CreateAnonymousThread(IncrementCounter);
  
  Thread1.Start;
  Thread2.Start;
  
  Thread1.WaitFor;
  Thread2.WaitFor;
  
  WriteLn('最终计数器值: ', SharedCounter);  // 应该是 2000
end.
```

### 生产者-消费者模式

```pascal
type
  TSharedQueue = class
  private
    FQueue: TQueue<Integer>;
    FMutex: IMutex;
  public
    constructor Create;
    procedure Enqueue(Value: Integer);
    function TryDequeue(out Value: Integer): Boolean;
  end;

constructor TSharedQueue.Create;
begin
  FQueue := TQueue<Integer>.Create;
  FMutex := MakeMutex;
end;

procedure TSharedQueue.Enqueue(Value: Integer);
var
  Guard: ILockGuard;
begin
  Guard := MakeLockGuard(FMutex);
  FQueue.Enqueue(Value);
end;

function TSharedQueue.TryDequeue(out Value: Integer): Boolean;
var
  Guard: ILockGuard;
begin
  Guard := MakeLockGuard(FMutex);
  Result := FQueue.Count > 0;
  if Result then
    Value := FQueue.Dequeue;
end;
```

## 性能注意事项

### 1. 锁粒度

- **细粒度锁**：保护较小的数据结构，减少锁竞争
- **粗粒度锁**：保护较大的操作，简化代码逻辑

```pascal
// 细粒度锁 - 每个账户有自己的锁
type
  TAccount = class
  private
    FBalance: Currency;
    FMutex: IMutex;
  public
    constructor Create;
    procedure Transfer(Amount: Currency);
  end;

// 粗粒度锁 - 所有账户共享一个锁
var
  GlobalAccountMutex: IMutex;
```

### 2. 锁顺序

避免死锁的关键是保持一致的锁获取顺序：

```pascal
// 正确：总是按照相同顺序获取锁
procedure TransferMoney(FromAccount, ToAccount: TAccount; Amount: Currency);
var
  FirstLock, SecondLock: IMutex;
begin
  // 按照对象地址排序，确保一致的锁顺序
  if PtrUInt(FromAccount) < PtrUInt(ToAccount) then
  begin
    FirstLock := FromAccount.Mutex;
    SecondLock := ToAccount.Mutex;
  end
  else
  begin
    FirstLock := ToAccount.Mutex;
    SecondLock := FromAccount.Mutex;
  end;
  
  FirstLock.Acquire;
  try
    SecondLock.Acquire;
    try
      // 执行转账操作
    finally
      SecondLock.Release;
    end;
  finally
    FirstLock.Release;
  end;
end;
```

### 3. 避免长时间持有锁

```pascal
// 错误：在锁内执行耗时操作
procedure BadExample;
var
  Guard: ILockGuard;
begin
  Guard := MutexGuard;
  
  // 错误：在锁内执行 I/O 操作
  WriteLn('这会阻塞其他线程很长时间');
  Sleep(1000);  // 非常糟糕！
end;

// 正确：最小化锁持有时间
procedure GoodExample;
var
  Guard: ILockGuard;
  LocalData: string;
begin
  // 在锁外准备数据
  LocalData := PrepareData;
  
  Guard := MutexGuard;
  // 在锁内只执行必要的操作
  UpdateSharedData(LocalData);
  // Guard 立即释放
end;
```

## 错误处理

### 常见异常

- `ELockError`：锁操作失败
- `ETimeoutError`：获取锁超时
- `EDeadlockError`：检测到死锁

### 异常安全编程

```pascal
procedure ExceptionSafeExample;
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;
  
  Mutex.Acquire;
  try
    // 可能抛出异常的代码
    RiskyOperation;
  finally
    // 确保锁总是被释放
    Mutex.Release;
  end;
end;

// 更好的方式：使用 RAII
procedure BetterExceptionSafeExample;
var
  Guard: ILockGuard;
begin
  Guard := MutexGuard;
  
  // 即使抛出异常，Guard 也会自动释放锁
  RiskyOperation;
end;
```

## 调试技巧

### 1. 启用调试模式

在 `fafafa.core.settings.inc` 中启用调试选项：

```pascal
{$DEFINE DEBUG}
{$DEFINE FAFAFA_SYNC_DEBUG}
```

### 2. 检测死锁

```pascal
// 使用超时检测潜在的死锁
if not Mutex.TryAcquire(5000) then  // 5 秒超时
begin
  WriteLn('警告：可能发生死锁');
  // 记录调试信息或采取恢复措施
end;
```

### 3. 性能分析

```pascal
var
  StartTime: QWord;
  Guard: ILockGuard;
begin
  StartTime := GetTickCount64;
  
  Guard := MutexGuard;
  // 临界区操作
  
  WriteLn('锁持有时间: ', GetTickCount64 - StartTime, ' ms');
end;
```

## 最佳实践

1. **优先使用 RAII 风格**：使用 `MutexGuard` 或 `MakeLockGuard`
2. **最小化锁粒度**：只保护必要的代码段
3. **保持一致的锁顺序**：避免死锁
4. **避免嵌套锁**：尽可能使用单一锁
5. **使用非阻塞操作**：在适当时使用 `TryAcquire`
6. **及时释放锁**：不要在锁内执行耗时操作
7. **异常安全**：确保锁总是被释放

## 平台特定说明

### Windows

- 默认使用 `CRITICAL_SECTION`（兼容 Windows XP+）
- 可选使用 `SRWLOCK`（Windows Vista+，性能更好）
- 通过 `FAFAFA_CORE_USE_SRWLOCK` 宏控制

### Unix/Linux

- 默认使用 `pthread_mutex`（兼容所有 Unix 系统）
- 可选使用 `futex`（Linux，性能更好）
- 通过 `FAFAFA_CORE_USE_FUTEX` 宏控制

## 相关模块

- `fafafa.core.sync.recMutex`：可重入互斥锁
- `fafafa.core.sync.rwlock`：读写锁
- `fafafa.core.sync.semaphore`：信号量
- `fafafa.core.sync.barrier`：屏障同步
