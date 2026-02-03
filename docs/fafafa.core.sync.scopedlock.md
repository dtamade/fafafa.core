# fafafa.core.sync.scopedlock

ScopedLock 提供安全获取多个锁的机制，自动处理死锁预防。

## 概述

当需要同时持有多个锁时，如果不同线程以不同顺序获取锁，会导致死锁。ScopedLock 通过**按地址排序**确保所有线程以相同顺序获取锁，从而避免死锁。

### 死锁示例

```
线程 A: Lock1.Acquire → Lock2.Acquire
线程 B: Lock2.Acquire → Lock1.Acquire
→ 死锁！
```

使用 ScopedLock：
```
线程 A: ScopedLock([Lock1, Lock2]) → 按地址排序后获取
线程 B: ScopedLock([Lock2, Lock1]) → 按地址排序后获取（相同顺序）
→ 无死锁
```

## API 参考

### 工厂函数

```pascal
// 获取多个锁（阻塞）
function ScopedLock(const ALocks: array of ILock): IMultiLockGuard;

// 便捷版本
function ScopedLock2(ALock1, ALock2: ILock): IMultiLockGuard;
function ScopedLock3(ALock1, ALock2, ALock3: ILock): IMultiLockGuard;
function ScopedLock4(ALock1, ALock2, ALock3, ALock4: ILock): IMultiLockGuard;

// 非阻塞尝试
function TryScopedLock(const ALocks: array of ILock; out AGuard: IMultiLockGuard): Boolean;

// 带超时尝试
function TryScopedLockFor(const ALocks: array of ILock; ATimeoutMs: Cardinal;
                          out AGuard: IMultiLockGuard): Boolean;
```

### IMultiLockGuard 接口

```pascal
IMultiLockGuard = interface(IGuard)
  // 获取锁数量
  function GetLockCount: Integer;
  property LockCount: Integer read GetLockCount;

  // 按索引获取锁
  function GetLock(AIndex: Integer): ILock;
  property Locks[AIndex: Integer]: ILock read GetLock;

  // 从 IGuard 继承
  procedure Release;  // 显式释放所有锁
  procedure Unlock;   // Release 的别名
end;
```

## 使用示例

### 基础用法

```pascal
var
  Lock1, Lock2: IMutex;
  Guard: IMultiLockGuard;
begin
  Lock1 := MakeMutex;
  Lock2 := MakeMutex;

  // 安全获取两个锁
  Guard := ScopedLock2(Lock1, Lock2);
  try
    // 临界区：同时持有两个锁
    DoSomething;
  finally
    Guard.Release;  // 显式释放锁
    Guard := nil;   // 清理引用
  end;
end;
```

> **重要**：由于 FPC 的接口引用计数机制，`Guard := nil` 不会立即触发锁释放。
> 必须显式调用 `Guard.Release` 来确保锁被释放。

### 动态锁数组

```pascal
var
  Locks: array of ILock;
  Guard: IMultiLockGuard;
begin
  SetLength(Locks, 4);
  Locks[0] := MakeMutex;
  Locks[1] := MakeMutex;
  Locks[2] := MakeMutex;
  Locks[3] := MakeMutex;

  Guard := ScopedLock(Locks);
  // 持有所有 4 个锁
end;
```

### 非阻塞尝试

```pascal
var
  Guard: IMultiLockGuard;
begin
  if TryScopedLock([Lock1, Lock2], Guard) then
  begin
    // 成功获取所有锁
    DoSomething;
    Guard := nil;  // 释放
  end
  else
  begin
    // 至少一个锁获取失败
    HandleLockFailure;
  end;
end;
```

### 带超时尝试

```pascal
var
  Guard: IMultiLockGuard;
begin
  if TryScopedLockFor([Lock1, Lock2], 1000, Guard) then
  begin
    // 在 1 秒内成功获取所有锁
    DoSomething;
  end
  else
  begin
    // 超时
    WriteLn('获取锁超时');
  end;
end;
```

## 实现细节

### 死锁预防算法

1. **排序**：按锁的指针地址排序
2. **顺序获取**：从最小地址到最大地址依次获取
3. **逆序释放**：从最大地址到最小地址依次释放

```pascal
// 伪代码
procedure AcquireAll;
begin
  // 按地址排序
  Sort(Locks, @CompareByAddress);

  // 顺序获取
  for i := 0 to High(Locks) do
    Locks[i].Acquire;
end;

procedure ReleaseAll;
begin
  // 逆序释放
  for i := High(Locks) downto 0 do
    Locks[i].Release;
end;
```

### TryScopedLock 的回滚机制

```pascal
function TryScopedLock(const ALocks: array of ILock; out AGuard): Boolean;
var
  i: Integer;
begin
  // 按地址排序
  Sort(SortedLocks, @CompareByAddress);

  // 尝试获取，失败则回滚
  for i := 0 to High(SortedLocks) do
  begin
    if not SortedLocks[i].TryAcquire then
    begin
      // 回滚已获取的锁
      for j := i - 1 downto 0 do
        SortedLocks[j].Release;
      Exit(False);
    end;
  end;

  Result := True;
end;
```

## 性能考虑

| 操作 | 开销 | 说明 |
|------|------|------|
| 排序 | O(n log n) | n = 锁数量，通常很小 |
| 获取 | O(n) | 顺序获取 |
| 释放 | O(n) | 顺序释放 |
| Guard 创建 | 1 次分配 | 接口引用计数 |

### 适用场景

| 场景 | 推荐度 |
|------|--------|
| 需要同时操作多个资源 | ⭐⭐⭐ |
| 银行转账（源账户 + 目标账户） | ⭐⭐⭐ |
| 图算法（多节点锁） | ⭐⭐ |
| 单个资源保护 | ⭐（直接用 Mutex） |

## 注意事项

1. **不要混用**：使用 ScopedLock 后，不要单独获取其中的锁
2. **相同锁集合**：对相同资源集合应始终使用相同的锁集合
3. **空数组**：传入空数组会返回一个空 Guard（不获取任何锁）
4. **重复锁**：不要传入重复的锁引用（会导致死锁）

## 与其他语言对比

| 语言/库 | API |
|---------|-----|
| C++ | `std::scoped_lock(mutex1, mutex2, ...)` |
| Rust | `parking_lot::MutexGroup` |
| Java | 无标准 API，需手动排序 |
| Go | 无标准 API，需手动排序 |
| **fafafa.core** | `ScopedLock([Lock1, Lock2, ...])` |

## 相关文档

- [fafafa.core.sync.mutex](fafafa.core.sync.mutex.md) - 互斥锁
- [fafafa.core.sync.guards](fafafa.core.sync.guards.md) - Guard 机制
- [sync 选择指南](fafafa.core.sync.selection-guide.md) - 如何选择同步原语
