# TForwardList - 单向链表使用指南

## 概述

`IForwardList<T>` 是一个 **单向链表** 接口，专为**头部操作**优化。

| 特性 | 描述 |
|------|------|
| 结构 | 单向链表，每个节点只有 next 指针 |
| 优势 | O(1) 头部插入/删除，内存高效 |
| 限制 | 无 Back 操作，无随机访问 |

> **适用场景**：频繁的头部插入/删除，顺序遍历。不需要双端操作或随机访问时选择此容器。

## 快速开始

```pascal
uses
  fafafa.core.collections.forwardList;

var
  List: specialize IForwardList<Integer>;
begin
  List := specialize MakeForwardList<Integer>();
  
  // 头部插入（LIFO 顺序）
  List.PushFront(1);  // [1]
  List.PushFront(2);  // [2, 1]
  List.PushFront(3);  // [3, 2, 1]
  
  // 头部访问/移除
  WriteLn(List.Front);     // 输出: 3
  WriteLn(List.PopFront);  // 输出: 3, 剩 [2, 1]
end;
```

## API 参考

### 创建

```pascal
// 空链表
List := specialize MakeForwardList<Integer>();

// 从数组初始化
List := specialize MakeForwardList<Integer>([1, 2, 3]);

// 自定义分配器
List := specialize MakeForwardList<Integer>(MyAllocator);
```

### 头部操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `PushFront(item)` | 头部插入 | O(1) |
| `PopFront: T` | 头部移除（空时抛异常） | O(1) |
| `TryPopFront(out item): Boolean` | 安全移除（空返回 False） | O(1) |
| `Front: T` | 获取头部元素（空时抛异常） | O(1) |
| `TryFront(out item): Boolean` | 安全获取（空返回 False） | O(1) |

### 迭代器操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `InsertAfter(pos, item): TIter` | 在指定位置后插入 | O(1) |
| `EraseAfter(pos): TIter` | 移除指定位置后的元素 | O(1) |

### 批量操作

| 方法 | 描述 |
|------|------|
| `Remove(value): SizeUInt` | 移除所有等于 value 的元素 |
| `RemoveIf(predicate): SizeUInt` | 移除满足条件的元素 |
| `Unique` | 移除相邻重复元素 |
| `Sort` | 排序（归并排序） |
| `Merge(other)` | 合并已排序链表 |
| `Splice(pos, other)` | 将 other 链接到 pos 之后 |

### 状态查询

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `IsEmpty: Boolean` | 是否为空 | O(1) |
| `Count: SizeUInt` | 元素数量 | O(n) 或 O(1)* |
| `Clear` | 清空所有元素 | O(n) |

> *某些实现维护计数器实现 O(1)

## 使用模式

### 模式 1：LIFO 栈行为

单向链表天然支持 LIFO（后进先出）：

```pascal
List.PushFront(1);
List.PushFront(2);
List.PushFront(3);

// 弹出顺序: 3, 2, 1
while not List.IsEmpty do
  WriteLn(List.PopFront);
```

### 模式 2：顺序遍历

```pascal
var
  Iter: specialize TIter<Integer>;
begin
  Iter := List.GetIterator;
  while Iter.MoveNext do
    ProcessItem(Iter.Current);
end;
```

### 模式 3：条件删除

```pascal
// 移除所有偶数
function IsEven(const V: Integer; Data: Pointer): Boolean;
begin
  Result := V mod 2 = 0;
end;

List.RemoveIf(@IsEven);
```

## 典型应用

### 内存池空闲链表

```pascal
type
  TFreeList = specialize IForwardList<Pointer>;

var
  FreeList: TFreeList;

function Allocate: Pointer;
begin
  if FreeList.TryPopFront(Result) then
    Exit;
  Result := GetMem(BlockSize);
end;

procedure Deallocate(P: Pointer);
begin
  FreeList.PushFront(P);  // O(1) 归还
end;
```

### 哈希表冲突链

```pascal
type
  TBucket = specialize IForwardList<TKeyValue>;

procedure HashTable.Insert(const Key: K; const Value: V);
var
  Bucket: TBucket;
begin
  Bucket := FBuckets[Hash(Key)];
  Bucket.PushFront(MakeKV(Key, Value));  // O(1) 插入
end;
```

### 逆序链表

```pascal
function Reverse<T>(List: specialize IForwardList<T>): specialize IForwardList<T>;
var
  Item: T;
begin
  Result := specialize MakeForwardList<T>();
  while List.TryPopFront(Item) do
    Result.PushFront(Item);  // 头插实现逆序
end;
```

### 合并排序链表

```pascal
procedure MergeSortedLists;
var
  A, B: specialize IForwardList<Integer>;
begin
  // 假设 A, B 已排序
  A.Sort;
  B.Sort;
  A.Merge(B);  // B 的元素移动到 A，保持排序
  // B 现在为空
end;
```

## ForwardList vs List vs Vec

| 操作 | ForwardList | List | Vec |
|------|-------------|------|-----|
| 头部插入 | **O(1)** | O(1) | O(n) |
| 尾部插入 | O(n) | O(1) | **O(1)** 摊销 |
| 中间插入 | O(1)* | O(1)* | O(n) |
| 随机访问 | O(n) | O(n) | **O(1)** |
| 内存开销 | 低 | 中 | 高** |

*需要迭代器定位，定位本身 O(n)
**连续内存，可能有未使用容量

### 选择建议

| 场景 | 推荐容器 |
|------|----------|
| 频繁头部操作 | `IForwardList<T>` |
| 双端频繁操作 | `IList<T>` 或 `TVecDeque<T>` |
| 随机访问为主 | `TVec<T>` |
| 内存紧张环境 | `IForwardList<T>` |

## 异常处理

| 异常 | 触发条件 |
|------|----------|
| `EInvalidOperation` | 对空链表调用 `PopFront` 或 `Front` |
| `EInvalidArgument` | 无效的迭代器 |
| `EOutOfMemory` | 内存分配失败 |

**安全访问模式**：

```pascal
// ✅ 安全方式
if List.TryPopFront(Value) then
  ProcessValue(Value);

// ✅ 先检查
if not List.IsEmpty then
  Value := List.PopFront;

// ❌ 危险方式（可能抛异常）
Value := List.PopFront;
```

## 性能特征

| 操作 | 时间复杂度 | 空间复杂度 |
|------|-----------|-----------|
| PushFront | O(1) | O(1) |
| PopFront | O(1) | O(1) |
| Front | O(1) | O(1) |
| InsertAfter | O(1) | O(1) |
| EraseAfter | O(1) | O(1) |
| Remove(value) | O(n) | O(1) |
| Sort | O(n log n) | O(log n) |
| Merge | O(n + m) | O(1) |

## 内存布局

```
ForwardList:
  Head -> [Node1] -> [Node2] -> [Node3] -> nil
              |          |          |
            Data       Data       Data

每个节点:
  +--------+--------+
  |  Next  |  Data  |
  +--------+--------+
```

## 最佳实践

1. **只在需要头部操作时使用**
   ```pascal
   // ✅ 适合 ForwardList
   FreeList.PushFront(ptr);
   ptr := FreeList.PopFront;
   
   // ❌ 不适合（需要尾部操作）
   // 改用 TVecDeque 或 TList
   ```

2. **批量操作使用 Splice**
   ```pascal
   // ✅ O(1) 链表合并
   List1.Splice(Position, List2);
   
   // ❌ O(n) 逐个复制
   while not List2.IsEmpty do
     List1.PushFront(List2.PopFront);
   ```

3. **排序后使用 Unique**
   ```pascal
   List.Sort;
   List.Unique;  // 移除相邻重复，需先排序
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `IList<T>` | 需要双端操作 |
| `TVec<T>` | 需要随机访问 |
| `TVecDeque<T>` | 需要双端 + 随机访问 |
| `IStack<T>` | 标准栈抽象 |
