# TPriorityQueue - 优先队列使用指南

## 概述

`IPriorityQueue<T>` 是基于**二叉堆**实现的优先队列，按优先级出队。

| 特性 | 描述 |
|------|------|
| 结构 | 二叉堆（数组存储） |
| 入队 | O(log n) |
| 出队 | O(log n) |
| 查看堆顶 | O(1) |

> **默认行为**：最小堆（优先级最小的元素先出队）。通过自定义比较器可实现最大堆。

## 快速开始

```pascal
uses
  fafafa.core.collections.priorityqueue;

// 比较函数（最小堆）
function CompareInt(const A, B: Integer; Data: Pointer): SizeInt;
begin
  Result := A - B;  // A < B 返回负数
end;

var
  PQ: specialize IPriorityQueue<Integer>;
begin
  PQ := specialize MakePriorityQueue<Integer>(@CompareInt);
  
  // 入队
  PQ.Enqueue(5);
  PQ.Enqueue(1);
  PQ.Enqueue(3);
  
  // 出队（按优先级）
  var Item: Integer;
  while PQ.Dequeue(Item) do
    WriteLn(Item);  // 输出: 1, 3, 5 (最小优先)
end;
```

## API 参考

### 创建

```pascal
// 需要提供比较函数
PQ := specialize MakePriorityQueue<Integer>(@CompareInt);

// 指定初始容量
PQ := specialize MakePriorityQueue<Integer>(@CompareInt, 1000);

// 自定义分配器
PQ := specialize MakePriorityQueue<Integer>(@CompareInt, 16, MyAllocator);
```

### 核心操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Enqueue(item)` | 入队 | O(log n) |
| `Dequeue(out item): Boolean` | 出队优先级最高的元素 | O(log n) |
| `Peek(out item): Boolean` | 查看堆顶（不移除） | O(1) |

### 容量管理

| 方法 | 描述 |
|------|------|
| `GetCapacity: SizeUInt` | 获取当前容量 |
| `Reserve(n)` | 预留至少 n 个元素的空间 |
| `Capacity: SizeUInt` | 容量属性 |

### 状态查询

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `IsEmpty: Boolean` | 是否为空 | O(1) |
| `Count: SizeUInt` | 元素数量 | O(1) |
| `Clear` | 清空所有元素 | O(n) |

## 比较函数

### 最小堆（默认）

```pascal
function MinHeapCompare(const A, B: Integer; Data: Pointer): SizeInt;
begin
  Result := A - B;  // A < B 时返回负数，A 先出队
end;
```

### 最大堆

```pascal
function MaxHeapCompare(const A, B: Integer; Data: Pointer): SizeInt;
begin
  Result := B - A;  // B < A 时返回负数，即 A > B 时 A 先出队
end;
```

### 自定义优先级

```pascal
type
  TTask = record
    Priority: Integer;
    Name: string;
  end;

function TaskCompare(const A, B: TTask; Data: Pointer): SizeInt;
begin
  Result := A.Priority - B.Priority;  // 优先级数值小的先执行
end;
```

## 典型应用

### 任务调度

```pascal
type
  TTask = record
    Priority: Integer;
    Action: TProc;
  end;

var
  TaskQueue: specialize IPriorityQueue<TTask>;

procedure ScheduleTask(Priority: Integer; Action: TProc);
var
  Task: TTask;
begin
  Task.Priority := Priority;
  Task.Action := Action;
  TaskQueue.Enqueue(Task);
end;

procedure RunTasks;
var
  Task: TTask;
begin
  while TaskQueue.Dequeue(Task) do
    Task.Action();  // 按优先级执行
end;
```

### Dijkstra 最短路径

```pascal
type
  TNode = record
    Vertex: Integer;
    Distance: Integer;
  end;

function NodeCompare(const A, B: TNode; Data: Pointer): SizeInt;
begin
  Result := A.Distance - B.Distance;
end;

procedure Dijkstra(Graph: TGraph; Start: Integer);
var
  PQ: specialize IPriorityQueue<TNode>;
  Current: TNode;
begin
  PQ := specialize MakePriorityQueue<TNode>(@NodeCompare);
  
  Current.Vertex := Start;
  Current.Distance := 0;
  PQ.Enqueue(Current);
  
  while PQ.Dequeue(Current) do
  begin
    if Visited[Current.Vertex] then Continue;
    Visited[Current.Vertex] := True;
    
    for Neighbor in Graph.Neighbors(Current.Vertex) do
    begin
      var NewDist := Current.Distance + Neighbor.Weight;
      if NewDist < Dist[Neighbor.Vertex] then
      begin
        Dist[Neighbor.Vertex] := NewDist;
        var Next: TNode;
        Next.Vertex := Neighbor.Vertex;
        Next.Distance := NewDist;
        PQ.Enqueue(Next);
      end;
    end;
  end;
end;
```

### Top-K 问题

```pascal
// 找出数组中最大的 K 个元素
function TopK(const Arr: array of Integer; K: Integer): TIntArray;
var
  MinHeap: specialize IPriorityQueue<Integer>;
  Item: Integer;
begin
  MinHeap := specialize MakePriorityQueue<Integer>(@MinCompare);
  
  for Item in Arr do
  begin
    MinHeap.Enqueue(Item);
    if MinHeap.Count > K then
      MinHeap.Dequeue(Item);  // 移除最小的，保留最大的 K 个
  end;
  
  SetLength(Result, K);
  for var i := K - 1 downto 0 do
    MinHeap.Dequeue(Result[i]);
end;
```

### 合并 K 个有序数组

```pascal
type
  TArrayElement = record
    Value: Integer;
    ArrayIndex: Integer;
    ElementIndex: Integer;
  end;

function MergeKArrays(const Arrays: array of TIntArray): TIntArray;
var
  PQ: specialize IPriorityQueue<TArrayElement>;
  Elem: TArrayElement;
begin
  PQ := specialize MakePriorityQueue<TArrayElement>(@ElementCompare);
  
  // 初始化：每个数组的第一个元素入队
  for var i := 0 to High(Arrays) do
    if Length(Arrays[i]) > 0 then
    begin
      Elem.Value := Arrays[i][0];
      Elem.ArrayIndex := i;
      Elem.ElementIndex := 0;
      PQ.Enqueue(Elem);
    end;
  
  while PQ.Dequeue(Elem) do
  begin
    Result := Result + [Elem.Value];
    
    // 该数组的下一个元素入队
    if Elem.ElementIndex + 1 < Length(Arrays[Elem.ArrayIndex]) then
    begin
      Inc(Elem.ElementIndex);
      Elem.Value := Arrays[Elem.ArrayIndex][Elem.ElementIndex];
      PQ.Enqueue(Elem);
    end;
  end;
end;
```

## 性能特征

| 操作 | 时间复杂度 | 空间复杂度 |
|------|-----------|-----------|
| Enqueue | O(log n) | O(1) 摊销 |
| Dequeue | O(log n) | O(1) |
| Peek | O(1) | O(1) |
| Reserve | O(n) | O(n) |
| Clear | O(n) | O(1) |

## 堆结构图示

```
最小堆示例 (数组: [1, 3, 2, 7, 6, 4, 5])

         1
       /   \
      3     2
     / \   / \
    7   6 4   5

父节点索引: (i - 1) / 2
左子节点: 2 * i + 1
右子节点: 2 * i + 2
```

## PriorityQueue vs 其他容器

| 场景 | 推荐容器 |
|------|----------|
| 按优先级处理 | `IPriorityQueue<T>` |
| FIFO 顺序 | `IQueue<T>` / `TVecDeque<T>` |
| LIFO 顺序 | `IStack<T>` |
| 有序遍历 | `TTreeMap<K,V>` |

## 注意事项

1. **必须提供比较函数**
   ```pascal
   // ❌ 错误：没有比较函数
   // PQ := specialize MakePriorityQueue<Integer>();
   
   // ✅ 正确
   PQ := specialize MakePriorityQueue<Integer>(@CompareInt);
   ```

2. **堆不保证完全有序**
   ```pascal
   // 迭代不按优先级顺序
   // 要按顺序获取所有元素，必须重复 Dequeue
   ```

3. **修改元素后需要重建堆**
   ```pascal
   // 如果元素是对象/记录，修改其优先级字段后
   // 需要移除并重新入队，或重建整个堆
   ```

## 最佳实践

1. **预估容量**
   ```pascal
   // ✅ 避免频繁扩容
   PQ := specialize MakePriorityQueue<Integer>(@Compare, ExpectedSize);
   ```

2. **使用 Peek 避免不必要的 Dequeue**
   ```pascal
   // ✅ 先查看是否需要处理
   if PQ.Peek(Item) and (Item.Priority < Threshold) then
     PQ.Dequeue(Item);
   ```

3. **记录类型使用值语义**
   ```pascal
   // ✅ 推荐：值类型
   type TTask = record Priority: Integer; Name: string; end;
   
   // ⚠️ 谨慎：引用类型需要额外的生命周期管理
   type TTask = class ... end;
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `IQueue<T>` | FIFO 出队 |
| `IStack<T>` | LIFO 出队 |
| `TTreeMap<K,V>` | 有序键值对 |
| `TTreeSet<T>` | 有序集合 |
