# TVecDeque 使用指南

## 概述

`TVecDeque<T>` 是基于环形缓冲区的高性能双端队列，同时支持 O(1) 双端操作和 O(1) 随机访问。

## 核心特性

- **O(1) 双端操作**：PushFront/PushBack/PopFront/PopBack
- **O(1) 随机访问**：Get/Put，支持索引器语法
- **环形缓冲区**：高效利用内存，避免数据移动
- **2 的幂容量**：位掩码优化索引计算
- **多种排序算法**：QuickSort/MergeSort/HeapSort/IntroSort

## 复杂度速查

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| PushFront/PushBack | O(1) 摊销 | 双端插入 |
| PopFront/PopBack | O(1) | 双端删除 |
| Front/Back | O(1) | 双端访问 |
| Get/Put | O(1) | 随机访问 |
| Insert/Remove | O(n) | 中间操作 |
| Rotate | O(n) | 旋转元素 |
| Reserve | O(n) | 扩容 |

## 快速开始

### 基本使用

```pascal
uses
  fafafa.core.collections.vecdeque;

var
  Deque: specialize TVecDeque<Integer>;
begin
  Deque := specialize TVecDeque<Integer>.Create;
  try
    // 双端插入
    Deque.PushBack(1);
    Deque.PushBack(2);
    Deque.PushFront(0);
    // 现在: [0, 1, 2]
    
    // 随机访问
    WriteLn(Deque[0]);  // 0
    WriteLn(Deque[1]);  // 1
    Deque[1] := 10;
    
    // 双端删除
    WriteLn(Deque.PopFront);  // 0
    WriteLn(Deque.PopBack);   // 2
  finally
    Deque.Free;
  end;
end;
```

### 队列模式（FIFO）

```pascal
// 尾进头出
Deque.Enqueue(Item);      // = PushBack
Item := Deque.Dequeue;    // = PopFront
Item := Deque.Peek;       // = Front
```

### 栈模式（LIFO）

```pascal
// 尾进尾出
Deque.Push(Item);         // = PushBack
Item := Deque.Pop;        // = PopBack
```

## 环形缓冲区原理

TVecDeque 使用环形缓冲区存储元素，Head 和 Tail 指针可以"绕回"到数组开头：

```
逻辑视图: [0, 1, 2, 3, 4]

物理布局 (可能):
  [3, 4, _, _, 0, 1, 2]
       ^Tail     ^Head
```

优势：
- 头部操作无需移动元素
- 内存连续，缓存友好
- 位掩码快速计算物理索引

## 批量操作

### 批量插入

```pascal
// 尾部批量插入
Deque.PushBack([10, 20, 30]);

// 头部批量插入
Deque.PushFront([1, 2, 3]);

// 从指针插入
Deque.PushBack(@Data[0], DataCount);
```

### 从其他容器加载

```pascal
// 替换当前内容
Deque.LoadFromArray([1, 2, 3, 4, 5]);

// 追加到末尾
Deque.AppendFrom(OtherDeque, StartIndex, Count);

// 在指定位置插入
Deque.InsertFrom(Index, [10, 20, 30]);
```

## 高级操作

### Rotate - 旋转元素

```pascal
Deque := [1, 2, 3, 4, 5];

// 左旋 2 位
Deque.RotateLeft(2);
// [3, 4, 5, 1, 2]

// 右旋 1 位
Deque.RotateRight(1);
// [2, 3, 4, 5, 1]
```

### Split - 分割

```pascal
Deque := [1, 2, 3, 4, 5];
var Second := Deque.Split(3);
// Deque = [1, 2, 3]
// Second = [4, 5]
```

### Merge - 合并

```pascal
Deque.Merge(OtherDeque, mpBack);   // 追加到末尾
Deque.Merge(OtherDeque, mpFront);  // 插入到头部
Deque.Merge(OtherDeque, mpReplace); // 替换当前内容
```

### SwapEnds - 交换首尾

```pascal
Deque := [1, 2, 3, 4, 5];
Deque.SwapEnds;
// [5, 2, 3, 4, 1]
```

## 排序

### 支持的算法

```pascal
// 快速排序（默认）
Deque.Sort(@MyComparer, nil);

// 指定算法
Deque.SortWith(saQuickSort, @MyComparer, nil);
Deque.SortWith(saMergeSort, @MyComparer, nil);  // 稳定排序
Deque.SortWith(saHeapSort, @MyComparer, nil);
Deque.SortWith(saIntroSort, @MyComparer, nil);  // 混合算法
Deque.SortWith(saInsertionSort, @MyComparer, nil);  // 小数据集
```

### 检查排序状态

```pascal
if Deque.IsSorted(0) then
  WriteLn('Already sorted');
```

## 容量管理

```pascal
// 预分配
Deque.Reserve(1000);      // 预留额外容量

// 收缩
Deque.ShrinkToFit;        // 智能收缩
Deque.ShrinkToFitExact;   // 精确收缩到 Count

// 截断
Deque.Truncate(10);       // 保留前 10 个元素

// 释放缓冲
Deque.FreeBuffer;         // 完全释放内存
```

## 查找与遍历

### 查找元素

```pascal
var Index: SizeInt;

// 从头查找
Index := Deque.Find(Value);
if Index >= 0 then
  WriteLn('Found at ', Index);

// 从指定位置查找
Index := Deque.Find(Value, StartIndex);

// 从尾查找
Index := Deque.FindLast(Value);

// 条件查找
Index := Deque.FindIF(@IsEven, nil);
```

### 遍历

```pascal
// for-in
for var Item in Deque do
  WriteLn(Item);

// ForEach（带索引范围）
Deque.ForEach(0, Deque.Count, @ProcessItem, nil);
```

### 统计

```pascal
// 计数
var EvenCount := Deque.CountIf(0, Deque.Count, @IsEven, nil);
var ValueCount := Deque.CountOf(TargetValue, 0, Deque.Count);
```

## 与其他容器对比

| 特性 | TVecDeque | TVec | TList |
|------|-----------|------|-------|
| 头部插入 | O(1) | O(n) | O(1) |
| 尾部插入 | O(1) | O(1) | O(1) |
| 随机访问 | O(1) | O(1) | O(n) |
| 内存连续 | 部分* | 是 | 否 |
| 缓存友好 | 较好 | 最好 | 差 |

\* 环形缓冲区在物理上可能分两段

### 选择建议

- **需要双端高效操作 + 随机访问** → TVecDeque
- **只需尾部操作** → TVec（更简单）
- **频繁中间插入** → TList
- **内存紧凑优先** → TVec

## 性能提示

1. **预分配**：已知元素数量时使用 `Create(capacity)` 或 `Reserve`
2. **批量操作**：使用 `PushBack(array)` 而非循环 `PushBack(element)`
3. **避免中间操作**：Insert/Remove 是 O(n)，尽量使用双端操作
4. **选择合适的排序**：小数据用 InsertionSort，大数据用 IntroSort

## 参见

- [TVec](TVec.md) - 动态数组
- [TList](TList.md) - 双向链表
- [INDEX](INDEX.md) - 容器模块索引
