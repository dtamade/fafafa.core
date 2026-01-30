# TQueue / IDeque - 队列容器使用指南

## 概述

`IQueue<T>` 是一个 **FIFO (先进先出)** 泛型队列接口。`IDeque<T>` 继承 `IQueue<T>`，提供双端操作。

| 接口 | 语义 | 推荐实现 |
|------|------|----------|
| `IQueue<T>` | FIFO 队列 | `TVecDeque<T>` |
| `IDeque<T>` | 双端队列 | `TVecDeque<T>` |

> **推荐**：使用 `TVecDeque<T>` 作为队列实现，它同时实现 `IQueue<T>` 和 `IDeque<T>`。

## 快速开始

### FIFO 队列用法

```pascal
uses
  fafafa.core.collections.vecdeque;

var
  Queue: specialize IVecDeque<Integer>;
begin
  Queue := specialize MakeVecDeque<Integer>();
  
  // 入队（尾部）
  Queue.Push(1);
  Queue.Push(2);
  Queue.Push(3);
  
  // 出队（头部）- FIFO 顺序
  WriteLn(Queue.Pop);  // 输出: 1
  WriteLn(Queue.Pop);  // 输出: 2
  WriteLn(Queue.Pop);  // 输出: 3
end;
```

### 双端队列用法

```pascal
var
  Deque: specialize IVecDeque<Integer>;
begin
  Deque := specialize MakeVecDeque<Integer>();
  
  // 两端操作
  Deque.PushFront(1);   // [1]
  Deque.PushBack(2);    // [1, 2]
  Deque.PushFront(0);   // [0, 1, 2]
  
  WriteLn(Deque.PopFront);  // 0, 剩 [1, 2]
  WriteLn(Deque.PopBack);   // 2, 剩 [1]
end;
```

## IQueue API 参考

### 核心操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Push(item)` | 入队（尾部） | O(1) 摊销 |
| `Pop: T` | 出队（头部，空时抛异常） | O(1) |
| `Pop(out item): Boolean` | 安全出队（空返回 False） | O(1) |
| `Peek: T` | 查看队首（空时抛异常） | O(1) |
| `TryPeek(out item): Boolean` | 安全查看（空返回 False） | O(1) |

### 状态查询

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `IsEmpty: Boolean` | 是否为空 | O(1) |
| `Count: SizeUInt` | 元素数量 | O(1) |
| `Clear` | 清空所有元素 | O(n) |

## IDeque 扩展 API

### 双端访问

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Front: T` | 队首元素 | O(1) |
| `Back: T` | 队尾元素 | O(1) |
| `PushFront(item)` | 头部入队 | O(1) 摊销 |
| `PushBack(item)` | 尾部入队 | O(1) 摊销 |
| `PopFront: T` | 头部出队 | O(1) |
| `PopBack: T` | 尾部出队 | O(1) |

### 随机访问

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Get(index): T` | 获取指定位置元素 | O(1) |
| `TryGet(index, out item): Boolean` | 安全获取 | O(1) |
| `Insert(index, item)` | 插入元素 | O(n) |
| `Remove(index): T` | 删除元素 | O(n) |

### 容量管理

| 方法 | 描述 |
|------|------|
| `Reserve(n)` | 预分配额外 n 个元素空间 |
| `ShrinkToFit` | 收缩到最小容量 |
| `Truncate(len)` | 截断到指定长度 |
| `Resize(size, value)` | 调整大小，新元素用 value 填充 |

## 典型应用

### BFS 遍历

```pascal
procedure BFS(Root: TNode);
var
  Queue: specialize IVecDeque<TNode>;
  Node: TNode;
begin
  if Root = nil then Exit;
  
  Queue := specialize MakeVecDeque<TNode>();
  Queue.Push(Root);
  
  while not Queue.IsEmpty do
  begin
    Node := Queue.Pop;  // FIFO: 先入先出
    Process(Node);
    
    if Node.Left <> nil then Queue.Push(Node.Left);
    if Node.Right <> nil then Queue.Push(Node.Right);
  end;
end;
```

### 生产者-消费者模式

```pascal
type
  TTaskQueue = specialize IVecDeque<TTask>;

procedure Producer(Queue: TTaskQueue);
begin
  while HasWork do
    Queue.Push(CreateTask);
end;

procedure Consumer(Queue: TTaskQueue);
var
  Task: TTask;
begin
  while Queue.Pop(Task) do
    ProcessTask(Task);
end;
```

### 滑动窗口（Deque）

```pascal
function MaxSlidingWindow(const Nums: array of Integer; K: Integer): TIntArray;
var
  Deque: specialize IVecDeque<Integer>;  // 存储索引
  i: Integer;
begin
  Deque := specialize MakeVecDeque<Integer>();
  SetLength(Result, Length(Nums) - K + 1);
  
  for i := 0 to High(Nums) do
  begin
    // 移除窗口外的元素
    while (not Deque.IsEmpty) and (Deque.Front <= i - K) do
      Deque.PopFront;
    
    // 移除比当前元素小的（它们不可能是最大值）
    while (not Deque.IsEmpty) and (Nums[Deque.Back] < Nums[i]) do
      Deque.PopBack;
    
    Deque.PushBack(i);
    
    if i >= K - 1 then
      Result[i - K + 1] := Nums[Deque.Front];
  end;
end;
```

### 回文检查（Deque）

```pascal
function IsPalindrome(const S: string): Boolean;
var
  Deque: specialize IVecDeque<Char>;
  C: Char;
  Front, Back: Char;
begin
  Deque := specialize MakeVecDeque<Char>();
  
  // 只添加字母
  for C in S do
    if C in ['a'..'z', 'A'..'Z'] then
      Deque.PushBack(LowerCase(C));
  
  // 从两端比较
  while Deque.Count > 1 do
  begin
    Front := Deque.PopFront;
    Back := Deque.PopBack;
    if Front <> Back then Exit(False);
  end;
  
  Result := True;
end;
```

## 异常处理

| 异常 | 触发条件 |
|------|----------|
| `EEmptyCollection` | 对空队列调用 `Pop` 或 `Peek` |
| `EOutOfRange` | `Get`/`Insert`/`Remove` 索引越界 |
| `EOutOfMemory` | 内存分配失败 |

## 性能特征

| 操作 | IQueue | IDeque |
|------|--------|--------|
| Push（尾部） | O(1) 摊销 | O(1) 摊销 |
| Pop（头部） | O(1) | O(1) |
| PushFront | - | O(1) 摊销 |
| PopBack | - | O(1) |
| Get(i) | - | O(1) |
| Insert(i) | - | O(n) |
| Remove(i) | - | O(n) |

## 队列 vs 栈 vs 双端队列

| 容器 | 语义 | Push | Pop | 双端 |
|------|------|------|-----|------|
| `IStack<T>` | LIFO | 尾部 | 尾部 | ❌ |
| `IQueue<T>` | FIFO | 尾部 | 头部 | ❌ |
| `IDeque<T>` | 双端 | 两端 | 两端 | ✅ |

## 最佳实践

1. **使用 TVecDeque 作为通用实现**
   ```pascal
   // ✅ 推荐：使用 TVecDeque 实现 FIFO 队列
   var Queue: specialize IVecDeque<Integer>;
   Queue := specialize MakeVecDeque<Integer>();
   ```

2. **优先使用 Try 方法处理空队列**
   ```pascal
   // ✅ 安全方式
   if Queue.Pop(Value) then ProcessValue(Value);
   
   // ⚠️ 需要先检查
   if not Queue.IsEmpty then Value := Queue.Pop;
   ```

3. **BFS 用队列，DFS 用栈**
   ```pascal
   // BFS: 层序遍历
   Queue.Push(Root);
   while not Queue.IsEmpty do Node := Queue.Pop;  // FIFO
   
   // DFS: 深度优先
   Stack.Push(Root);
   while not Stack.IsEmpty do Node := Stack.Pop;  // LIFO
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `IStack<T>` | LIFO 语义 |
| `TVecDeque<T>` | 队列/双端队列实现 |
| `TPriorityQueue<T>` | 优先级出队 |
| `TCircularBuffer<T>` | 固定大小环形缓冲 |
