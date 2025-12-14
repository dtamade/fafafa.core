# TList 使用指南

## 概述

`TList<T>` 是双向链表实现，提供 O(1) 双端插入/删除，适合频繁头尾操作和中间插入的场景。

## 核心特性

- **O(1) 双端操作**：PushFront/PushBack/PopFront/PopBack
- **节点内存管理**：使用 TNodeManager 优化内存分配
- **无容量限制**：按需分配节点，无需预留容量
- **可逆遍历**：双向链接支持正反遍历

## 复杂度速查

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| PushFront/PushBack | O(1) | 头尾插入 |
| PopFront/PopBack | O(1) | 头尾删除 |
| Front/Back | O(1) | 头尾访问 |
| 随机访问 | O(n) | 需遍历到目标位置 |
| 中间插入/删除 | O(1) | 已知节点位置时 |
| 查找 | O(n) | 顺序遍历 |

## 快速开始

### 基本使用

```pascal
uses
  fafafa.core.collections.list;

var
  List: specialize TList<Integer>;
begin
  List := specialize TList<Integer>.Create;
  try
    // 尾部添加
    List.PushBack(1);
    List.PushBack(2);
    
    // 头部添加
    List.PushFront(0);
    // 现在: [0, 1, 2]
    
    // 访问头尾
    WriteLn(List.Front);  // 0
    WriteLn(List.Back);   // 2
    
    // 移除头尾
    WriteLn(List.PopFront);  // 0
    WriteLn(List.PopBack);   // 2
    // 现在: [1]
  finally
    List.Free;
  end;
end;
```

### 安全访问（Try* 方法）

```pascal
var
  Value: Integer;
begin
  // 安全获取头部（不抛异常）
  if List.TryFront(Value) then
    WriteLn('Front: ', Value)
  else
    WriteLn('List is empty');
  
  // 安全弹出尾部
  if List.TryPopBack(Value) then
    WriteLn('Popped: ', Value);
end;
```

### 从数组创建

```pascal
// 从数组直接创建
List := specialize TList<Integer>.Create([1, 2, 3, 4, 5]);

// 从指针创建
List := specialize TList<Integer>.Create(@Data[0], DataCount);
```

## 遍历

### for-in 遍历

```pascal
for var Item in List do
  WriteLn(Item);
```

### 使用迭代器

```pascal
var
  Iter: specialize TIter<Integer>;
begin
  Iter := List.Iter;
  while Iter.MoveNext do
    WriteLn(Iter.Current);
end;
```

## 高性能方法（UnChecked）

当确定参数有效时，使用 UnChecked 版本跳过检查：

```pascal
// 批量添加（无检查）
List.PushRangeUnChecked([1, 2, 3, 4, 5]);

// 头尾操作（无检查）
List.PushBackUnChecked(Value);
Value := List.PopFrontUnChecked;

// 清空（无检查）
List.ClearUnChecked;
```

⚠️ **注意**：UnChecked 方法不做参数验证，错误使用会导致未定义行为。

## 链表特有操作

### Reverse - 反转链表

```pascal
List := specialize TList<Integer>.Create([1, 2, 3]);
List.Reverse;
// List = [3, 2, 1]
```

### Clone - 深拷贝

```pascal
var
  ListCopy: specialize TList<Integer>;
begin
  ListCopy := List.CloneList;
  // ListCopy 是独立副本
end;
```

## 与其他容器对比

### TList vs TVec

| 特性 | TList | TVec |
|------|-------|------|
| 头部插入 | O(1) | O(n) |
| 尾部插入 | O(1) | O(1) 摊销 |
| 随机访问 | O(n) | O(1) |
| 内存连续 | 否 | 是 |
| 缓存友好 | 否 | 是 |

### TList vs TVecDeque

| 特性 | TList | TVecDeque |
|------|-------|-----------|
| 头部插入 | O(1) | O(1) 摊销 |
| 尾部插入 | O(1) | O(1) 摊销 |
| 随机访问 | O(n) | O(1) |
| 中间插入 | O(1)* | O(n) |
| 内存效率 | 低（节点开销） | 高 |

\* 需要先定位到节点位置

### 选择建议

- **需要随机访问** → TVec 或 TVecDeque
- **频繁头部操作** → TList 或 TVecDeque
- **频繁中间插入** → TList
- **内存效率优先** → TVec 或 TVecDeque
- **批量操作** → TVecDeque

## 内存管理

TList 使用节点结构，每个元素有额外开销（前后指针）。

### 清空与释放

```pascal
// 清空元素（保留节点管理器）
List.Clear;

// 销毁时自动释放所有节点
List.Free;
```

### 自定义分配器

```pascal
// 使用自定义分配器
List := specialize TList<Integer>.Create(MyAllocator);
```

## 常见问题

### Q: 为什么没有 Get(Index) 方法？

链表随机访问是 O(n)，为避免性能陷阱，不提供索引访问。如需随机访问，请使用 TVec。

### Q: 如何实现队列？

```pascal
// FIFO 队列：尾进头出
List.PushBack(Item);     // 入队
Item := List.PopFront;   // 出队
```

### Q: 如何实现栈？

```pascal
// LIFO 栈：尾进尾出
List.PushBack(Item);    // 入栈
Item := List.PopBack;   // 出栈
```

## 参见

- [TVec](TVec.md) - 动态数组
- [TVecDeque](TVecDeque.md) - 双端队列
- [INDEX](INDEX.md) - 容器模块索引
