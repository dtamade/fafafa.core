# fafafa.core.sync.seqlock

序列锁（SeqLock）是一种针对读多写少场景优化的同步原语，源自 Linux 内核。

## 概述

SeqLock 使用**乐观读**策略：读者不会阻塞写者，而是在读取后检测是否发生了并发写入。如果检测到冲突，读者重试读取。

### 适用场景

| 场景 | 推荐度 | 原因 |
|------|--------|------|
| 读多写少（>100:1） | ⭐⭐⭐ | 读操作无锁、零开销 |
| 小数据（≤16字节） | ⭐⭐⭐ | 复制开销可忽略 |
| 时间戳/计数器更新 | ⭐⭐⭐ | 经典用例 |
| 写频繁（<10:1） | ⭐ | 读者重试过多 |
| 大对象复制 | ⭐ | 复制开销大 |

## API 参考

### 工厂函数

```pascal
function MakeSeqLock: ISeqLock;
```

### ISeqLock 接口

```pascal
ISeqLock = interface(ISynchronizable)
  // 乐观读：返回当前序列号
  function ReadBegin: UInt32;

  // 检查是否需要重试（序列号变化 = 有写入发生）
  function ReadRetry(ASeq: UInt32): Boolean;

  // 写操作
  procedure WriteBegin;
  procedure WriteEnd;
  function TryWriteBegin: Boolean;

  // RAII Guard
  function WriteGuard: ILockGuard;

  // 获取当前序列号
  function GetSequence: UInt32;
end;
```

### 泛型容器 ISeqLockData<T>

```pascal
// 自动处理乐观读重试的泛型容器
function MakeSeqLockData<T>: ISeqLockData<T>;

ISeqLockData<T> = interface(ISeqLock)
  // 自动重试的安全读取
  function Read: T;

  // 原子写入
  procedure Write(const AValue: T);

  // RAII 写入 Guard
  function WriteGuard: ISeqLockDataWriteGuard<T>;
end;
```

## 使用示例

### 基础用法：手动乐观读

```pascal
var
  SeqLock: ISeqLock;
  Data: Integer;
  Seq: UInt32;
begin
  SeqLock := MakeSeqLock;

  // 读操作（乐观读）
  repeat
    Seq := SeqLock.ReadBegin;
    // 读取数据（无锁）
    LocalCopy := Data;
  until not SeqLock.ReadRetry(Seq);  // 检测是否有写入

  // 写操作
  SeqLock.WriteBegin;
  try
    Data := NewValue;
  finally
    SeqLock.WriteEnd;
  end;
end;
```

### 推荐用法：泛型容器

```pascal
type
  TTimestamp = record
    Seconds: Int64;
    Nanoseconds: Int32;
  end;

var
  Timestamp: ISeqLockData<TTimestamp>;
begin
  Timestamp := specialize MakeSeqLockData<TTimestamp>;

  // 读取（自动重试）
  Current := Timestamp.Read;

  // 写入
  Timestamp.Write(NewTimestamp);

  // 或使用 RAII Guard
  Guard := Timestamp.WriteGuard;
  Guard.Value.Seconds := GetCurrentSeconds;
  Guard.Value.Nanoseconds := GetCurrentNanos;
  // Guard 离开作用域自动提交
end;
```

### RAII WriteGuard

```pascal
var
  Guard: ILockGuard;
begin
  Guard := SeqLock.WriteGuard;
  // 写入操作...
  // Guard 离开作用域自动调用 WriteEnd
end;
```

## 性能基准

测试环境：Linux x86_64, FPC 3.2.2

| 操作 | 无竞争 | 有竞争（4线程） |
|------|--------|-----------------|
| Read（乐观） | 27 ns | ~41% 重试率 |
| Write | 45 ns | 独占写入 |

### 与其他锁对比

| 原语 | 读性能 | 写性能 | 读者阻塞 |
|------|--------|--------|----------|
| SeqLock | 27 ns | 45 ns | 否（重试） |
| RWLock（Fast） | 158 ns | 113 ns | 是 |
| RWLock（Default） | 1782 ns | 398 ns | 是 |
| Mutex | 24 ns | 24 ns | 是 |

## 实现细节

### 序列号机制

```
序列号：奇数 = 写入进行中，偶数 = 稳定状态

WriteBegin: seq++ (偶数 → 奇数)
WriteEnd:   seq++ (奇数 → 偶数)

ReadRetry:  return (saved_seq != current_seq) or (seq & 1)
```

### 内存屏障

- `ReadBegin`: `atomic_load(acquire)` + 读屏障
- `ReadRetry`: 读屏障 + `atomic_load(acquire)`
- `WriteBegin/End`: `atomic_store(release)` + 完整屏障

## 注意事项

1. **读者可能看到部分更新**：乐观读不加锁，读者可能读到不一致状态，但 `ReadRetry` 会检测到
2. **写者必须独占**：多个写者需要外部同步
3. **不适合大对象**：每次重试都需要完整复制
4. **不适合指针数据**：读取过程中指针可能失效

## 相关文档

- [fafafa.core.sync.rwlock](fafafa.core.sync.rwlock.md) - 读写锁
- [fafafa.core.sync.mutex](fafafa.core.sync.mutex.md) - 互斥锁
- [sync 选择指南](fafafa.core.sync.selection-guide.md) - 如何选择同步原语
