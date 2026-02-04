# fafafa.core.sync 死锁避免指南

本指南帮助你识别、预防和调试死锁问题。

## 什么是死锁？

死锁是两个或多个线程互相等待对方持有的资源，导致所有线程永久阻塞。

```
Thread A                    Thread B
─────────                   ─────────
Lock1.Acquire;              Lock2.Acquire;
Lock2.Acquire; ← 等待       Lock1.Acquire; ← 等待
     ↑                           ↑
     └───────── 互相等待 ─────────┘
                 死锁！
```

## 死锁的四个必要条件

死锁发生需要同时满足以下四个条件：

| 条件 | 描述 | 预防策略 |
|------|------|----------|
| **互斥** | 资源不能共享 | 使用 RWLock 允许读共享 |
| **持有并等待** | 持有资源的同时等待其他资源 | 一次性获取所有资源 |
| **不可剥夺** | 资源只能由持有者释放 | 使用超时机制 |
| **循环等待** | 线程形成循环等待链 | 按顺序获取锁 |

## 预防策略

### 策略 1：使用 ScopedLock（推荐）

`ScopedLock` 自动按地址排序锁，从根本上防止循环等待。

```pascal
uses fafafa.core.sync;

var
  Lock1, Lock2, Lock3: IMutex;
  Guard: IMultiLockGuard;
begin
  Lock1 := MakeMutex;
  Lock2 := MakeMutex;
  Lock3 := MakeMutex;

  // ✅ 安全：无论传入顺序如何，都按地址排序获取
  Guard := ScopedLock([Lock1, Lock2, Lock3]);
  try
    // 临界区
  finally
    Guard.Release;
  end;
end;
```

**为什么安全**：
```
Thread A: ScopedLock([Lock1, Lock2])  → 排序后: Lock1, Lock2
Thread B: ScopedLock([Lock2, Lock1])  → 排序后: Lock1, Lock2
                                        ↑ 相同顺序，无死锁
```

### 策略 2：固定获取顺序

如果不使用 ScopedLock，必须在所有代码中保持一致的锁顺序。

```pascal
// 定义锁层级
const
  LOCK_LEVEL_DATABASE = 1;
  LOCK_LEVEL_CACHE = 2;
  LOCK_LEVEL_LOG = 3;

// ✅ 始终按层级顺序获取
procedure SafeOperation;
begin
  DatabaseLock.Acquire;   // Level 1
  try
    CacheLock.Acquire;    // Level 2
    try
      LogLock.Acquire;    // Level 3
      try
        // 操作
      finally
        LogLock.Release;
      end;
    finally
      CacheLock.Release;
    end;
  finally
    DatabaseLock.Release;
  end;
end;

// ❌ 危险：不同顺序
procedure UnsafeOperation;
begin
  CacheLock.Acquire;      // Level 2 先！
  DatabaseLock.Acquire;   // Level 1 后 - 可能死锁！
  ...
end;
```

### 策略 3：使用超时避免永久阻塞

```pascal
var
  Guard: IMultiLockGuard;
begin
  // 尝试获取锁，最多等待 1 秒
  if TryScopedLockFor([Lock1, Lock2], 1000, Guard) then
  begin
    try
      // 成功获取
    finally
      Guard.Release;
    end;
  end
  else
  begin
    // 超时，可能有死锁风险
    LogWarning('Failed to acquire locks - possible deadlock');
    // 采取替代策略
  end;
end;
```

### 策略 4：减少锁粒度

```pascal
// ❌ 粗粒度锁 - 更容易死锁
procedure ProcessAllItems;
begin
  GlobalLock.Acquire;
  try
    for Item in Items do
      ProcessItem(Item);  // 如果 ProcessItem 需要其他锁...
  finally
    GlobalLock.Release;
  end;
end;

// ✅ 细粒度锁 - 更安全
procedure ProcessAllItems;
begin
  for Item in Items do
  begin
    Item.Lock.Acquire;
    try
      ProcessItem(Item);
    finally
      Item.Lock.Release;
    end;
  end;
end;
```

### 策略 5：使用读写锁减少竞争

```pascal
var
  RWLock: IRWLock;

// 多个线程可以同时读
procedure ReadData;
begin
  RWLock.AcquireRead;
  try
    // 读取操作
  finally
    RWLock.ReleaseRead;
  end;
end;

// 只有写入时需要独占
procedure WriteData;
begin
  RWLock.AcquireWrite;
  try
    // 写入操作
  finally
    RWLock.ReleaseWrite;
  end;
end;
```

## 常见死锁模式

### 模式 1：AB-BA 死锁

```pascal
// Thread A              // Thread B
LockA.Acquire;          LockB.Acquire;
LockB.Acquire; // 等待   LockA.Acquire; // 等待
// 死锁！
```

**解决**：使用 `ScopedLock2(LockA, LockB)`

### 模式 2：嵌套锁回调

```pascal
procedure ProcessWithCallback(Callback: TProc);
begin
  Lock.Acquire;
  try
    Callback();  // ❌ 如果 Callback 也需要 Lock...
  finally
    Lock.Release;
  end;
end;
```

**解决**：
```pascal
procedure ProcessWithCallback(Callback: TProc);
var
  DataCopy: TData;
begin
  Lock.Acquire;
  try
    DataCopy := Data;  // 复制数据
  finally
    Lock.Release;
  end;

  Callback(DataCopy);  // ✅ 锁外调用
end;
```

### 模式 3：信号处理死锁

```pascal
// ❌ 危险：信号处理中获取锁
procedure SignalHandler;
begin
  Lock.Acquire;  // 如果主线程已持有锁...
  ...
end;
```

**解决**：信号处理中不要获取锁，使用无锁数据结构或延迟处理

### 模式 4：递归锁误用

```pascal
var
  Mutex: IMutex;  // 普通 Mutex 不支持递归

procedure Outer;
begin
  Mutex.Acquire;
  try
    Inner;  // ❌ 死锁！
  finally
    Mutex.Release;
  end;
end;

procedure Inner;
begin
  Mutex.Acquire;  // 同一线程再次获取
  ...
end;
```

**解决**：使用 `IRecMutex` 或重构代码避免递归获取

```pascal
var
  RecMutex: IRecMutex;

begin
  RecMutex := MakeRecMutex;
  RecMutex.Acquire;
  RecMutex.Acquire;  // ✅ 递归互斥锁允许
  RecMutex.Release;
  RecMutex.Release;
end;
```

## 死锁检测

### 运行时检测

启用毒化检测可以帮助发现一些问题：

```pascal
var
  RWLock: IRWLock;
begin
  // 默认启用毒化检测
  RWLock := MakeRWLock(DefaultRWLockOptions);

  // 如果线程在持有锁时异常退出，锁会被标记为 "poisoned"
  if RWLock.IsPoisoned then
    WriteLn('Warning: Lock was poisoned by previous holder');
end;
```

### 超时检测

```pascal
const
  DEADLOCK_TIMEOUT = 30000;  // 30 秒

function SafeAcquire(Lock: ILock): Boolean;
begin
  Result := Lock.TryAcquire(DEADLOCK_TIMEOUT);
  if not Result then
  begin
    // 可能是死锁
    LogError('Potential deadlock detected!');
    DumpThreadStacks;  // 打印线程栈
  end;
end;
```

### 静态分析

检查代码中的锁顺序：
1. 列出所有锁
2. 绘制锁依赖图
3. 检查是否有循环

```
Lock1 → Lock2 → Lock3
  ↑               │
  └───────────────┘  ← 循环！死锁风险
```

## 调试技巧

### 1. 打印锁获取顺序

```pascal
procedure DebugAcquire(Lock: ILock; const Name: string);
begin
  WriteLn(Format('[%d] Acquiring %s...', [GetCurrentThreadId, Name]));
  Lock.Acquire;
  WriteLn(Format('[%d] Acquired %s', [GetCurrentThreadId, Name]));
end;
```

### 2. 使用超时暴露问题

```pascal
// 测试时使用短超时
{$IFDEF DEBUG}
const LOCK_TIMEOUT = 100;  // 100ms
{$ELSE}
const LOCK_TIMEOUT = 30000;  // 30s
{$ENDIF}
```

### 3. 线程转储

当检测到可能的死锁时，打印所有线程的调用栈：

```pascal
procedure DumpDeadlockInfo;
begin
  WriteLn('=== Potential Deadlock ===');
  WriteLn('Thread ', GetCurrentThreadId, ' waiting for lock');
  WriteLn('Current stack:');
  DumpExceptionBackTrace(Output);
end;
```

## 检查清单

在代码审查时检查：

- [ ] 是否使用 `ScopedLock` 同时获取多个锁？
- [ ] 如果手动获取，顺序是否一致？
- [ ] 是否有递归锁需求（使用 RecMutex）？
- [ ] 持有锁时是否调用回调/事件？
- [ ] 是否有适当的超时机制？
- [ ] 是否可以使用 RWLock 减少竞争？
- [ ] 锁的粒度是否合适？

## 相关文档

- [fafafa.core.sync.scopedlock](fafafa.core.sync.scopedlock.md) - 多锁安全获取
- [fafafa.core.sync.selection-guide](fafafa.core.sync.selection-guide.md) - 选择合适的同步原语
- [fafafa.core.sync.rwlock](fafafa.core.sync.rwlock.md) - 读写锁
- [fafafa.core.sync.recMutex](fafafa.core.sync.recMutex.md) - 递归互斥锁
