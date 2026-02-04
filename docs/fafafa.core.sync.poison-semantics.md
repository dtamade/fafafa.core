# fafafa.core.sync Poison 语义指南

本指南解释 fafafa.core.sync 中的"毒化"（Poisoning）机制，这是一个受 Rust 启发的安全特性。

## 什么是 Poison？

当一个线程在持有锁的情况下发生 panic（异常崩溃）时，锁会被标记为"poisoned"（毒化）。这表明被锁保护的数据可能处于不一致状态。

```
Thread A                         共享数据状态
─────────                        ────────────
Lock.Acquire                     [一致]
BeginUpdate                      [部分更新]
  ↓ 异常发生！                    [不一致!]
Lock 自动释放（finally）
Lock 标记为 poisoned              [可能损坏]
```

## 为什么需要 Poison？

### 问题场景

```pascal
procedure UnsafeUpdate;
begin
  Lock.Acquire;
  try
    Data.Field1 := NewValue1;
    // ❌ 这里抛出异常！
    Data.Field2 := NewValue2;  // 未执行
  finally
    Lock.Release;  // 锁被释放
  end;
end;

// 其他线程获取锁后...
Lock.Acquire;
// Data.Field1 已更新，Data.Field2 未更新
// 数据处于不一致状态！
```

### Poison 解决方案

```pascal
// 使用支持 Poison 的 RWLock
RWLock := MakeRWLock(DefaultRWLockOptions);  // EnablePoisoning = True

// Thread A 崩溃后...

// Thread B 尝试获取锁
RWLock.AcquireRead;
// 抛出 ERWLockPoisonError: "Lock was poisoned by previous holder"
```

## 支持 Poison 的原语

| 原语 | 支持 Poison | 默认启用 |
|------|-------------|----------|
| RWLock | ✅ | 是 (DefaultRWLockOptions) |
| Mutex | ❌ | - |
| RecMutex | ❌ | - |
| Spin | ❌ | - |

## 使用方法

### 启用/禁用 Poison

```pascal
var
  Options: TRWLockOptions;
begin
  // 启用 Poison（默认）
  Options := DefaultRWLockOptions;
  Options.EnablePoisoning := True;
  RWLock := MakeRWLock(Options);

  // 禁用 Poison（高性能模式）
  RWLock := MakeRWLock(FastRWLockOptions);  // EnablePoisoning = False
end;
```

### 检查 Poison 状态

```pascal
if RWLock.IsPoisoned then
begin
  WriteLn('Warning: Lock was poisoned!');
  // 决定如何处理...
end;
```

### 处理 Poison 异常

```pascal
try
  RWLock.AcquireRead;
  try
    // 使用数据
  finally
    RWLock.ReleaseRead;
  end;
except
  on E: ERWLockPoisonError do
  begin
    // 选项 1: 传播异常
    raise;

    // 选项 2: 尝试恢复
    if CanRecover then
    begin
      RWLock.ClearPoison;  // 清除毒化状态
      ResetData;           // 重置数据到已知状态
    end;

    // 选项 3: 使用降级功能
    UseFallbackData;
  end;
end;
```

### 清除 Poison 状态

```pascal
// 只有在确定数据已恢复一致时才清除
procedure RecoverFromPoison;
begin
  if RWLock.IsPoisoned then
  begin
    // 重新初始化数据到已知良好状态
    Data := CreateFreshData;

    // 清除毒化标记
    RWLock.ClearPoison;

    WriteLn('Recovered from poisoned state');
  end;
end;
```

## Poison 与 Guard

使用 Guard 模式时，Poison 检查发生在获取锁时：

```pascal
var
  Guard: IRWLockReadGuard;
begin
  // 如果锁被毒化，这里会抛出异常
  Guard := RWLock.Read;

  // 如果到达这里，说明锁未被毒化
  ProcessData;
end;
```

### TryRead/TryWrite 的行为

```pascal
Guard := RWLock.TryRead(1000);
if Guard = nil then
begin
  // 可能是超时，也可能是 poisoned
  if RWLock.IsPoisoned then
    HandlePoisoned
  else
    HandleTimeout;
end;
```

## 性能考虑

Poison 检查有少量开销：

| 配置 | 读性能 | 说明 |
|------|--------|------|
| EnablePoisoning = True | ~1800 ns | 默认，包含检查 |
| EnablePoisoning = False | ~160 ns | FastRWLockOptions |

**建议**：
- 关键业务数据：启用 Poison（安全优先）
- 缓存/统计数据：可禁用 Poison（性能优先）

## 最佳实践

### 1. 保持操作原子性

```pascal
// ✅ 好：要么全部成功，要么全部失败
procedure AtomicUpdate;
var
  NewData: TData;
begin
  // 先准备好所有数据
  NewData.Field1 := CalcField1;
  NewData.Field2 := CalcField2;

  // 然后一次性替换
  RWLock.AcquireWrite;
  try
    Data := NewData;  // 单个赋值，原子替换
  finally
    RWLock.ReleaseWrite;
  end;
end;
```

### 2. 使用事务模式

```pascal
procedure TransactionalUpdate;
var
  Backup: TData;
begin
  RWLock.AcquireWrite;
  try
    Backup := Data;  // 备份
    try
      Data.Field1 := NewValue1;
      Data.Field2 := NewValue2;
      ValidateData(Data);  // 可能抛出异常
    except
      Data := Backup;  // 回滚
      raise;
    end;
  finally
    RWLock.ReleaseWrite;
  end;
end;
```

### 3. 日志记录

```pascal
except
  on E: ERWLockPoisonError do
  begin
    // 记录详细信息以便调试
    LogError('Lock poisoned: %s', [E.Message]);
    LogError('Original thread: %d', [E.ThreadId]);
    LogError('Current stack: %s', [GetStackTrace]);
    raise;
  end;
end;
```

## 与 Rust 的对比

| 特性 | Rust | fafafa.core |
|------|------|-------------|
| 默认行为 | Mutex 返回 PoisonError | RWLock 抛出异常 |
| 访问方式 | `lock.lock().unwrap()` | `RWLock.AcquireRead` |
| 忽略 Poison | `lock.lock().unwrap_or_else(\|e\| e.into_inner())` | `RWLock.ClearPoison` |
| 检查状态 | `lock.is_poisoned()` | `RWLock.IsPoisoned` |

## 常见问题

### Q: Mutex 为什么不支持 Poison？

A: 为了与标准 Pascal 互斥锁行为兼容。如果需要 Poison 语义，使用 RWLock 的写锁作为独占锁。

### Q: 如何在不启用 Poison 的情况下检测崩溃？

A: 使用外部健康检查机制，如心跳或看门狗定时器。

### Q: ClearPoison 是线程安全的吗？

A: 是的，但调用前应确保没有其他线程正在使用该锁。

## 相关文档

- [fafafa.core.sync.rwlock](fafafa.core.sync.rwlock.md) - RWLock 详细文档
- [fafafa.core.sync.selection-guide](fafafa.core.sync.selection-guide.md) - 选择合适的同步原语
- [fafafa.core.sync.migration-v2](fafafa.core.sync.migration-v2.md) - API 迁移指南
