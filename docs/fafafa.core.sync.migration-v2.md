# fafafa.core.sync API 迁移指南 (v1 → v2)

本指南帮助你将代码从旧 API 迁移到新的推荐 API。

## 概述

v2 版本引入了更现代、更安全的 API，同时保留了向后兼容的旧 API（标记为 deprecated）。

**主要变化**：
- 接口命名简化（如 `IReadWriteLock` → `IRWLock`）
- 统一工厂函数命名（`Make*` 模式）
- RAII Guard 模式替代手动 Acquire/Release
- 新增高级原语（SeqLock、ScopedLock）

## 废弃 API 列表

### 接口重命名

| 旧 API (deprecated) | 新 API | 说明 |
|---------------------|--------|------|
| `IReadWriteLock` | `IRWLock` | 简化命名 |
| `ISemaphore` | `ISem` | 简化命名 |
| `ITryLock` | `ILock` | 方法已合并到 ILock |

**迁移示例**：
```pascal
// 旧代码
var
  RWLock: IReadWriteLock;  // ⚠️ deprecated

// 新代码
var
  RWLock: IRWLock;  // ✅
```

### TRWLockOptions 字段

| 旧字段 (deprecated) | 新字段 | 说明 |
|---------------------|--------|------|
| `FairMode` | `Fairness` | 使用枚举类型 |
| `WriterPriority` | `Fairness` | 使用枚举类型 |
| `ReaderBiasEnabled` | - | 自动优化，无需手动设置 |

**迁移示例**：
```pascal
// 旧代码
Options.FairMode := True;        // ⚠️ deprecated
Options.WriterPriority := True;  // ⚠️ deprecated

// 新代码
Options.Fairness := Fair;           // ✅ 公平模式
Options.Fairness := WriterPreferred; // ✅ 写优先
Options.Fairness := ReaderPreferred; // ✅ 读优先
```

### ISynchronizable 方法

| 旧方法 (deprecated) | 替代方案 | 说明 |
|---------------------|----------|------|
| `GetData()` | 外部映射 | 使用 TDictionary 映射 |
| `SetData()` | 外部映射 | 使用 TDictionary 映射 |
| `LockGuard()` | `Lock()` | 统一命名 |

**迁移示例**：
```pascal
// 旧代码：使用内置数据存储
Lock.SetData(Pointer(MyData));
MyData := Integer(Lock.GetData);

// 新代码：使用外部映射
var LockData: TDictionary<ILock, Pointer>;
LockData[Lock] := Pointer(MyData);
MyData := Integer(LockData[Lock]);
```

## 推荐迁移

### 1. 手动锁 → RAII Guard

**旧模式**（容易忘记释放）：
```pascal
Lock.Acquire;
try
  DoSomething;
finally
  Lock.Release;  // 容易忘记！
end;
```

**新模式**（自动释放）：
```pascal
var
  Guard: ILockGuard;
begin
  Guard := Lock.Lock;
  DoSomething;
  Guard.Release;  // 或让 Guard 超出作用域
end;

// 或使用 WithLock
WithLock(Lock, procedure
begin
  DoSomething;
end);
```

### 2. 多锁获取 → ScopedLock

**旧模式**（死锁风险）：
```pascal
Lock1.Acquire;
try
  Lock2.Acquire;
  try
    DoSomething;
  finally
    Lock2.Release;
  end;
finally
  Lock1.Release;
end;
```

**新模式**（自动防死锁）：
```pascal
var
  Guard: IMultiLockGuard;
begin
  Guard := ScopedLock2(Lock1, Lock2);
  try
    DoSomething;
  finally
    Guard.Release;
  end;
end;
```

### 3. 默认 RWLock → FastRWLock

如果不需要重入支持，使用高性能模式：

**旧代码**：
```pascal
RWLock := MakeRWLock;  // 默认支持重入，较慢
```

**新代码**：
```pascal
// 简单场景，不需要重入
RWLock := MakeRWLock(FastRWLockOptions);  // 11x 更快

// 需要重入支持
RWLock := MakeRWLock(DefaultRWLockOptions);
```

### 4. 高频读小数据 → SeqLock

**旧模式**（读也需要锁）：
```pascal
RWLock.AcquireRead;
try
  Value := SharedData;
finally
  RWLock.ReleaseRead;
end;
```

**新模式**（无锁读）：
```pascal
var
  SeqData: ISeqLockData<Integer>;
begin
  SeqData := specialize MakeSeqLockData<Integer>;

  // 无锁读取（自动重试）
  Value := SeqData.Read;

  // 独占写入
  SeqData.Write(NewValue);
end;
```

## 工厂函数对照表

| 类型 | 工厂函数 | 说明 |
|------|----------|------|
| Mutex | `MakeMutex` | 基本互斥锁 |
| RecMutex | `MakeRecMutex` | 递归互斥锁 |
| RWLock | `MakeRWLock` / `MakeRWLock(Options)` | 读写锁 |
| Spin | `MakeSpin` | 自旋锁 |
| Sem | `MakeSem(Init, Max)` | 信号量 |
| Event | `MakeEvent(Manual, Initial)` | 事件 |
| CondVar | `MakeCondVar` | 条件变量 |
| Barrier | `MakeBarrier(Count)` | 屏障 |
| WaitGroup | `MakeWaitGroup` | 等待组 |
| Latch | `MakeLatch(Count)` | 闭锁 |
| Parker | `MakeParker` | 停车器 |
| Once | `MakeOnce` | 单次执行 |
| **SeqLock** | `MakeSeqLock` | 序列锁 (新) |
| **ScopedLock** | `ScopedLock([...])` | 多锁获取 (新) |

## 编译器警告处理

迁移期间，你可能会看到 deprecated 警告：

```
Warning: Symbol "IReadWriteLock" is deprecated: "Use IRWLock instead"
```

**处理方式**：

1. **立即迁移**（推荐）：按本指南更新代码
2. **暂时抑制**：
```pascal
{$PUSH}{$WARN 5066 OFF}  // Symbol deprecated
var
  OldLock: IReadWriteLock;  // 暂时保留
{$POP}
```

## 版本兼容性

| API | v1.x | v2.x | v3.x (计划) |
|-----|------|------|-------------|
| IReadWriteLock | ✅ | ⚠️ deprecated | ❌ 移除 |
| ISemaphore | ✅ | ⚠️ deprecated | ❌ 移除 |
| IRWLock | ❌ | ✅ | ✅ |
| ISem | ❌ | ✅ | ✅ |
| ScopedLock | ❌ | ✅ | ✅ |
| SeqLock | ❌ | ✅ | ✅ |

## 迁移检查清单

- [ ] 替换 `IReadWriteLock` → `IRWLock`
- [ ] 替换 `ISemaphore` → `ISem`
- [ ] 使用 `Lock()` 替代手动 `Acquire/Release`
- [ ] 使用 `ScopedLock` 替代多锁手动获取
- [ ] 评估是否可用 `FastRWLockOptions`
- [ ] 评估高频读场景是否适合 `SeqLock`
- [ ] 移除 `GetData/SetData` 调用
- [ ] 更新 `TRWLockOptions` 字段

## 获取帮助

- 查看 [sync 选择指南](fafafa.core.sync.selection-guide.md)
- 查看 [死锁避免指南](fafafa.core.sync.deadlock-prevention.md)
- 查看具体模块文档：[rwlock](fafafa.core.sync.rwlock.md)、[mutex](fafafa.core.sync.mutex.md) 等
