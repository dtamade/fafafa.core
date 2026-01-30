# Collections 线程安全指南

**模块**: fafafa.core.collections  
**更新日期**: 2025-12-03

## 概述

`fafafa.core.collections` 模块中的容器**默认不是线程安全的**。这是有意的设计决策：

- **单线程场景**：无同步开销，性能最优
- **多线程场景**：用户可根据需求选择适当的同步策略

如需线程安全的容器，请使用 `fafafa.core.lockfree` 模块。

---

## 容器线程安全分类

### ❌ 非线程安全容器 (fafafa.core.collections)

| 容器 | 说明 | 多线程建议 |
|------|------|-----------|
| `TVec<T>` | 动态数组 | 使用外部锁或复制 |
| `THashMap<K,V>` | 哈希表 | 使用 `TMichaelHashMap` |
| `THashSet<K>` | 哈希集合 | 使用外部锁 |
| `TVecDeque<T>` | 双端队列 | 使用外部锁 |
| `TBitSet` | 位集合 | 使用原子操作或外部锁 |
| `TTreeMap<K,V>` | 红黑树 | 使用外部锁 |
| `TLinkedHashMap<K,V>` | 有序哈希表 | 使用外部锁 |
| `TCircularBuffer<T>` | 环形缓冲区 | 使用外部锁 |
| `TArrayStack<T>` | 栈 | 使用外部锁 |
| `TArrayDeque<T>` | 双端队列 | 使用外部锁 |

### ✅ 线程安全容器 (fafafa.core.lockfree)

| 容器 | 说明 | 算法 |
|------|------|------|
| `TMichaelHashMap<K,V>` | 无锁哈希表 | Michael & Michael 2002 |
| `TLockFreeQueue<T>` | 无锁队列 | Michael-Scott |
| `TLockFreeStack<T>` | 无锁栈 | Treiber Stack |

---

## 安全使用模式

### 模式 1: 读写锁 (多读单写)

```pascal
uses
  fafafa.core.sync.rwlock;

var
  FMap: specialize THashMap<string, Integer>;
  FLock: IRWLock;

// 读操作
FLock.ReadLock;
try
  Value := FMap.TryGetValue(Key, Result);
finally
  FLock.ReadUnlock;
end;

// 写操作
FLock.WriteLock;
try
  FMap.AddOrAssign(Key, Value);
finally
  FLock.WriteUnlock;
end;
```

### 模式 2: 互斥锁 (简单场景)

```pascal
uses
  fafafa.core.sync.mutex;

var
  FVec: specialize TVec<Integer>;
  FMutex: IMutex;

FMutex.Lock;
try
  FVec.Push(42);
finally
  FMutex.Unlock;
end;
```

### 模式 3: 无锁容器 (高并发)

```pascal
uses
  fafafa.core.lockfree.hashmap;

var
  FMap: specialize TMichaelHashMap<string, Integer>;

// 无需锁，直接并发访问
FMap.insert('key', 100);
if FMap.find('key', Value) then
  // ...
```

### 模式 4: 线程局部存储 (避免共享)

```pascal
threadvar
  TLVec: specialize TVec<Integer>;

// 每个线程有独立实例，无需同步
TLVec.Push(42);
```

### 模式 5: 不可变快照 (读多写少)

```pascal
// 写线程
FLock.WriteLock;
try
  FSnapshot := FVec.Clone;  // 创建快照
finally
  FLock.WriteUnlock;
end;

// 读线程直接使用快照（不可变）
for Item in FSnapshot do
  Process(Item);
```

---

## 常见错误

### ❌ 错误: 无保护的并发写入

```pascal
// 线程 A
FVec.Push(1);

// 线程 B (同时)
FVec.Push(2);  // 数据竞争！可能崩溃或数据损坏
```

### ❌ 错误: 迭代时修改

```pascal
// 即使单线程也不安全
for Item in FVec do
  if SomeCondition(Item) then
    FVec.Remove(Item);  // 迭代器失效！
```

### ❌ 错误: 跨作用域持有迭代器

```pascal
FLock.ReadLock;
Iter := FVec.GetEnumerator;
FLock.ReadUnlock;

// Iter 在锁外使用 - 另一线程可能修改容器
while Iter.MoveNext do  // 危险！
  Process(Iter.Current);
```

---

## 性能考虑

| 同步方式 | 开销 | 适用场景 |
|---------|------|---------|
| 无同步 | 0 | 单线程 |
| 互斥锁 | 中 | 低争用 |
| 读写锁 | 中 | 读多写少 |
| 无锁容器 | 低-中 | 高并发 |
| 线程局部 | 0 | 无共享需求 |

---

## 推荐做法

1. **默认单线程**：除非明确需要，假设单线程使用
2. **最小共享**：尽量减少跨线程共享的数据
3. **不可变优先**：传递数据的不可变副本
4. **文档化假设**：明确标注代码的线程安全假设
5. **优先 lockfree**：高并发场景使用无锁容器

---

## 相关模块

- `fafafa.core.lockfree` - 无锁数据结构
- `fafafa.core.sync` - 同步原语 (Mutex, RWLock, etc.)
- `fafafa.core.atomic` - 原子操作
