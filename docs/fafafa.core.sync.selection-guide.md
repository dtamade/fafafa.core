# fafafa.core.sync 选择指南

本指南帮助你选择合适的同步原语。

## 快速决策树

```
需要保护共享资源？
├── 是，单个资源
│   ├── 需要递归获取？ → RecMutex
│   ├── 读多写少？
│   │   ├── 读:写 > 100:1，小数据 → SeqLock ⭐最快读
│   │   └── 读:写 < 100:1 → RWLock
│   │       ├── 简单场景，无重入 → FastRWLockOptions ⭐推荐
│   │       └── 需要重入/毒化检测 → DefaultRWLockOptions
│   └── 简单互斥 → Mutex ⭐最常用
│
├── 是，多个资源
│   └── 需要同时锁定多个 → ScopedLock
│
└── 协调线程间通信？
    ├── 等待某个条件成立 → CondVar
    ├── 等待 N 个线程到达 → Barrier
    ├── 等待计数器归零 → Latch / WaitGroup
    ├── 信号量（资源池） → Sem
    ├── 事件通知 → Event
    ├── 线程休眠/唤醒 → Parker
    └── 确保只执行一次 → Once
```

## 性能基准对照表

测试环境：Linux x86_64, FPC 3.2.2, 无竞争场景

| 原语 | 获取 | 释放 | 适用场景 |
|------|------|------|----------|
| **Mutex** | 24 ns | 24 ns | 通用互斥 |
| **RWLock (Fast)** | 158 ns (读) | - | 读多写少，简单场景 |
| **RWLock (Default)** | 1782 ns (读) | - | 需要重入支持 |
| **SeqLock** | 27 ns (读) | 45 ns (写) | 读极多写极少 |
| **Spin** | 15 ns | 15 ns | 极短临界区 |

## 详细场景分析

### 场景 1：保护简单数据结构

**推荐：Mutex**

```pascal
var
  Mutex: IMutex;
  Counter: Integer;
begin
  Mutex := MakeMutex;

  Guard := Mutex.Lock;
  Inc(Counter);
  // Guard 自动释放
end;
```

### 场景 2：读多写少的配置数据

**推荐：RWLock (FastRWLockOptions)**

```pascal
var
  RWLock: IRWLock;
  Config: TConfig;
begin
  RWLock := MakeRWLock(FastRWLockOptions);

  // 读取（多线程并发）
  RWLock.AcquireRead;
  try
    Result := Config.Value;
  finally
    RWLock.ReleaseRead;
  end;

  // 写入（独占）
  RWLock.AcquireWrite;
  try
    Config.Value := NewValue;
  finally
    RWLock.ReleaseWrite;
  end;
end;
```

### 场景 3：高频读取的小数据（时间戳、计数器）

**推荐：SeqLock**

```pascal
var
  Timestamp: ISeqLockData<Int64>;
begin
  Timestamp := specialize MakeSeqLockData<Int64>;

  // 读取（无锁，可能重试）
  Current := Timestamp.Read;

  // 写入
  Timestamp.Write(GetTickCount64);
end;
```

### 场景 4：同时操作多个账户（转账）

**推荐：ScopedLock**

```pascal
procedure Transfer(FromAccount, ToAccount: IAccount; Amount: Integer);
var
  Guard: IMultiLockGuard;
begin
  // 自动按地址排序，防止死锁
  Guard := ScopedLock2(FromAccount.Lock, ToAccount.Lock);

  FromAccount.Balance := FromAccount.Balance - Amount;
  ToAccount.Balance := ToAccount.Balance + Amount;
end;
```

### 场景 5：生产者-消费者队列

**推荐：Mutex + CondVar**

```pascal
var
  Mutex: IMutex;
  NotEmpty: ICondVar;
  Queue: TQueue;
begin
  Mutex := MakeMutex;
  NotEmpty := MakeCondVar;

  // 消费者
  Mutex.Acquire;
  while Queue.IsEmpty do
    NotEmpty.Wait(Mutex);
  Item := Queue.Pop;
  Mutex.Release;

  // 生产者
  Mutex.Acquire;
  Queue.Push(Item);
  NotEmpty.Signal;
  Mutex.Release;
end;
```

### 场景 6：等待所有 Worker 完成

**推荐：WaitGroup**

```pascal
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;

  for i := 1 to 10 do
  begin
    WG.Add(1);
    StartWorker(procedure
    begin
      DoWork;
      WG.Done;
    end);
  end;

  WG.Wait;  // 等待所有 Worker 完成
end;
```

### 场景 7：多阶段并行计算

**推荐：Barrier**

```pascal
var
  Barrier: IBarrier;
begin
  Barrier := MakeBarrier(4);  // 4 个线程

  // 每个线程
  Phase1Work;
  Barrier.Wait;  // 等待所有线程完成 Phase1

  Phase2Work;
  Barrier.Wait;  // 等待所有线程完成 Phase2
end;
```

### 场景 8：单例初始化

**推荐：Once**

```pascal
var
  InitOnce: IOnce;
  Instance: TInstance;
begin
  InitOnce := MakeOnce;

  // 多线程安全的单例初始化
  InitOnce.Do_(procedure
  begin
    Instance := TInstance.Create;
  end);
end;
```

## RWLock 选项对比

| 选项 | AllowReentrancy | EnablePoisoning | 性能 | 场景 |
|------|-----------------|-----------------|------|------|
| **FastRWLockOptions** | False | False | ⭐⭐⭐ 最快 | 简单场景，无递归 |
| **DefaultRWLockOptions** | True | True | ⭐ | 需要递归、毒化检测 |
| **FairRWLockOptions** | True | True | ⭐ | 防止写者饥饿 |
| **WriterPriorityRWLockOptions** | True | True | ⭐ | 写优先 |

**性能差异原因**：
- `AllowReentrancy=True` 需要管理 ReentryManager 锁，每次操作额外开销约 1600ns
- `EnablePoisoning=True` 需要检查毒化状态

## 常见陷阱

### 1. 死锁

```pascal
// ❌ 错误：不同顺序获取锁
Thread1: Lock1.Acquire; Lock2.Acquire;
Thread2: Lock2.Acquire; Lock1.Acquire;

// ✅ 正确：使用 ScopedLock
Thread1: Guard := ScopedLock2(Lock1, Lock2);
Thread2: Guard := ScopedLock2(Lock2, Lock1);  // 自动按地址排序
```

### 2. 递归获取非递归锁

```pascal
// ❌ 错误：Mutex 不支持递归
Mutex.Acquire;
Mutex.Acquire;  // 死锁！

// ✅ 正确：使用 RecMutex
RecMutex := MakeRecMutex;
RecMutex.Acquire;
RecMutex.Acquire;  // OK
RecMutex.Release;
RecMutex.Release;
```

### 3. 忘记释放锁

```pascal
// ❌ 错误：异常时锁未释放
Mutex.Acquire;
DoSomething;  // 如果抛出异常，锁永远不会释放
Mutex.Release;

// ✅ 正确：使用 Guard 或 try-finally
Guard := Mutex.Lock;
DoSomething;
// Guard 自动释放

// 或
Mutex.Acquire;
try
  DoSomething;
finally
  Mutex.Release;
end;
```

### 4. SeqLock 用于大对象

```pascal
// ❌ 不推荐：大对象复制开销大
type
  TLargeData = record
    Data: array[0..1023] of Byte;
  end;
SeqLock: ISeqLockData<TLargeData>;
Value := SeqLock.Read;  // 每次重试复制 1KB

// ✅ 推荐：大对象用 RWLock
RWLock := MakeRWLock(FastRWLockOptions);
```

## 选择清单

| 需求 | 推荐原语 |
|------|----------|
| 简单互斥 | Mutex |
| 需要递归锁 | RecMutex |
| 读多写少 | RWLock (Fast) 或 SeqLock |
| 极高频读取小数据 | SeqLock |
| 同时锁多个资源 | ScopedLock |
| 条件等待 | CondVar |
| 计数等待 | Latch / WaitGroup |
| 多阶段同步 | Barrier |
| 资源池 | Sem |
| 事件通知 | Event |
| 线程暂停/恢复 | Parker |
| 单次初始化 | Once |

## 相关文档

- [fafafa.core.sync.mutex](fafafa.core.sync.mutex.md)
- [fafafa.core.sync.rwlock](fafafa.core.sync.rwlock.md)
- [fafafa.core.sync.seqlock](fafafa.core.sync.seqlock.md)
- [fafafa.core.sync.scopedlock](fafafa.core.sync.scopedlock.md)
- [fafafa.core.sync.condvar](fafafa.core.sync.condvar.md)
- [fafafa.core.sync.barrier](fafafa.core.sync.barrier.md)
- [fafafa.core.sync.waitgroup](fafafa.core.sync.waitgroup.md)
