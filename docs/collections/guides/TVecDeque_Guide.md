# TVecDeque 完整使用指南

> See also: 示例总表（TVec/TVecDeque）：docs/EXAMPLES.md#集合模块示例总表（TVec-/-TVecDeque）


## 概述

TVecDeque 是 fafafa.collections5 框架中的高性能双端队列实现，基于环形缓冲区设计，提供了真正的 O(1) 双端操作性能。

## 核心特性

### 🚀 性能特征
- **O(1) 双端操作**: PushFront, PushBack, PopFront, PopBack
- **O(1) 随机访问**: Get, Put, GetPtr 等索引操作
- **智能容量管理**: 自动增长和收缩，负载因子监控
- **批量操作优化**: 高效的数组和指针批量插入

### 🔧 接口支持
- **IVec**: 完整的向量功能
- **IDeque**: 双端队列操作
- **IQueue**: 队列操作
- **IArray**: 数组访问功能

注意：
- PeekRange 仅在“后端 aCount 元素物理连续”时返回非 nil 指针；跨环情况下将返回 nil。零拷贝访问请优先使用 GetTwoSlices；若需要强制连续，可在后续版本使用 MakeContiguous（计划中）。
- ShrinkTo/ShrinkToFit/ShrinkToFitExact 的容量将对齐到 2 的幂（并遵循最小容量阈值），与位掩码优化契合。

## 基本使用

### 创建和初始化

```pascal
uses fafafa.core.collections.vecdeque;

type
  TIntDeque = specialize TVecDeque<Integer>;
  TStringDeque = specialize TVecDeque<String>;

var
  IntDeque: TIntDeque;
  StrDeque: TStringDeque;
begin
  // 默认创建
  IntDeque := TIntDeque.Create;

  // 指定初始容量
  StrDeque := TStringDeque.Create(100);

  // 从数组创建
  IntDeque := TIntDeque.Create([1, 2, 3, 4, 5]);

  // 从其他集合创建
  StrDeque := TStringDeque.Create(SomeOtherCollection);
end;
```

### 双端操作

```pascal
var
  Deque: TIntDeque;
begin
  Deque := TIntDeque.Create;

  // 前端操作
  Deque.PushFront(10);    // [10]
  Deque.PushFront(20);    // [20, 10]

  // 后端操作
  Deque.PushBack(30);     // [20, 10, 30]
  Deque.PushBack(40);     // [20, 10, 30, 40]

  // 弹出操作
  WriteLn(Deque.PopFront);  // 输出: 20, 队列变为 [10, 30, 40]
  WriteLn(Deque.PopBack);   // 输出: 40, 队列变为 [10, 30]

  // 查看操作（不移除）
  WriteLn(Deque.PeekFront); // 输出: 10
  WriteLn(Deque.PeekBack);  // 输出: 30
end;
```

### 随机访问

```pascal
var
  Deque: TIntDeque;
  i: Integer;
begin
  Deque := TIntDeque.Create([1, 2, 3, 4, 5]);

  // 索引访问
  WriteLn(Deque[0]);      // 输出: 1
  WriteLn(Deque[4]);      // 输出: 5

  // 修改元素
  Deque[2] := 99;         // [1, 2, 99, 4, 5]

  // 遍历
  for i := 0 to Deque.GetCount - 1 do
    WriteLn(Deque[i]);
end;
```

## 高级功能

### 批量操作

```pascal
var
  Deque: TIntDeque;
  Arr: array[0..2] of Integer = (10, 20, 30);
begin
  Deque := TIntDeque.Create;

  // 批量前端插入
  Deque.PushFront(Arr);           // [30, 20, 10]

  // 批量后端插入
  Deque.PushBack([40, 50, 60]);   // [30, 20, 10, 40, 50, 60]

  // 批量移除
  Deque.PopFrontN(2);             // [10, 40, 50, 60]
  Deque.PopBackN(1);              // [10, 40, 50]
end;
```

### 容量管理

```pascal
var
  Deque: TIntDeque;
begin
  Deque := TIntDeque.Create;

  // 预留容量
  Deque.Reserve(1000);
  WriteLn('Capacity: ', Deque.GetCapacity);

  // 收缩到实际大小
  Deque.ShrinkToFit;

  // 检查负载因子
  WriteLn('Load Factor: ', Deque.GetLoadFactor:0:2);
  WriteLn('Wasted Space: ', Deque.GetWastedSpace);
end;

### 清空与收缩的最佳实践

- Clear：清空逻辑长度但不释放容量；清空后保持环形不变式 FCount=0, FHead=0, FTail=0
- ShrinkToFit / ShrinkToFitExact：需要释放内存时使用；前者可保留增长策略对齐，后者严格匹配
- 建议：频繁复用容器的场景首选 Clear；内存敏感阶段再进行 ShrinkToFit

```

### 双端队列特有算法

```pascal
var
  Deque: TIntDeque;
  Split: TIntDeque;
begin
  Deque := TIntDeque.Create([1, 2, 3, 4, 5, 6]);

  // 旋转操作
  Deque.RotateLeft(2);    // [3, 4, 5, 6, 1, 2]
  Deque.RotateRight(1);   // [2, 3, 4, 5, 6, 1]

  // 分割队列
  Split := Deque.Split(3); // Deque: [2, 3, 4], Split: [5, 6, 1]

  // 合并队列
  Deque.Merge(Split, mpBack); // [2, 3, 4, 5, 6, 1]

  // 交换两端
  Deque.SwapEnds;         // [1, 3, 4, 5, 6, 2]

  // 移动元素
  Deque.MoveToFront(4);   // [6, 1, 3, 4, 5, 2]
  Deque.MoveToBack(0);    // [1, 3, 4, 5, 2, 6]
end;
```

## 排错清单（Troubleshooting）

- Clear 后顺序异常
  - 症状：Clear 之后 PushFront/PushBack 序列错位
  - 排查：空状态下应满足 FCount=0, FHead=0, FTail=0；若不满足，修复 Clear 等重置路径
- 环绕读写取数不一致
  - 症状：跨环场景下顺序或拷贝错误
  - 建议：使用 GetTwoSlices 或 SerializeToArrayBuffer 验证逻辑顺序是否正确；避免保留旧指针
- 指针失效
  - 症状：Resize/Append/Insert 之后通过旧指针访问崩溃/脏数据
  - 原因：任何改变布局的操作都会使先前获取的指针失效
  - 建议：仅在短期使用 GetPtr/切片指针，不要长期持有
- 不必要的连续化/收缩
  - 症状：性能退化而非功能错误
  - 建议：仅在批量顺序访问或内存敏感时调用连续化/收缩；常规访问直接用 Get/TwoSlices
- 增长策略不当
  - 症状：频繁扩容或空间浪费
  - 建议：默认使用 2 的幂策略；已知数据规模时使用 Reserve/ReserveExact 预分配


## 性能优化建议

### 1. 容量预分配
```pascal
// 好的做法：预知大小时预分配
Deque := TIntDeque.Create(ExpectedSize);

// 避免：频繁的小幅增长
for i := 1 to 10000 do
  Deque.PushBack(i);  // 会触发多次重新分配
```

### 2. 批量操作
```pascal
// 好的做法：使用批量操作
Deque.PushBack(LargeArray);

// 避免：逐个元素操作
for Element in LargeArray do
  Deque.PushBack(Element);
```

### 3. 选择合适的操作
```pascal
// 双端操作：O(1)
Deque.PushFront(Value);
Deque.PushBack(Value);

// 中间插入：O(n)，尽量避免
Deque.Insert(MiddleIndex, Value);
```

## 常见使用模式

### 1. 滑动窗口
```pascal
procedure ProcessSlidingWindow(const Data: array of Integer; WindowSize: Integer);
var
  Window: TIntDeque;
  i: Integer;
begin
  Window := TIntDeque.Create(WindowSize);

  for i := 0 to High(Data) do
  begin
    Window.PushBack(Data[i]);

    if Window.GetCount > WindowSize then
      Window.PopFront;

    if Window.GetCount = WindowSize then
      ProcessWindow(Window);
  end;

  Window.Free;
end;
```

### 2. 双端BFS
```pascal
procedure BidirectionalBFS(Start, Target: TNode);
var
  ForwardQueue, BackwardQueue: TNodeDeque;
begin
  ForwardQueue := TNodeDeque.Create;
  BackwardQueue := TNodeDeque.Create;

  ForwardQueue.PushBack(Start);
  BackwardQueue.PushBack(Target);

  while (not ForwardQueue.IsEmpty) and (not BackwardQueue.IsEmpty) do
  begin
    // 从较小的队列开始搜索
    if ForwardQueue.GetCount <= BackwardQueue.GetCount then
      ExpandForward(ForwardQueue)
    else
      ExpandBackward(BackwardQueue);
  end;
end;
```

### 3. 撤销/重做系统
```pascal
type
  TUndoRedoManager = class
  private
    FUndoStack: TCommandDeque;
    FRedoStack: TCommandDeque;
  public
    procedure ExecuteCommand(Command: TCommand);
    procedure Undo;
    procedure Redo;
  end;

procedure TUndoRedoManager.ExecuteCommand(Command: TCommand);
begin
  Command.Execute;
  FUndoStack.PushBack(Command);
  FRedoStack.Clear;  // 清空重做栈
end;

procedure TUndoRedoManager.Undo;
var
  Command: TCommand;
begin
  if not FUndoStack.IsEmpty then
  begin
    Command := FUndoStack.PopBack;
    Command.Undo;
    FRedoStack.PushBack(Command);
  end;
end;
```

## 错误处理

TVecDeque 提供了完整的边界检查和错误处理：

```pascal
try
  Value := Deque[100];  // 如果索引超出范围会抛出 EOutOfRange
except
  on E: EOutOfRange do
    WriteLn('Index out of range: ', E.Message);
end;

try
  Value := Deque.PopFront;  // 如果队列为空会抛出 EOutOfRange
except
  on E: EOutOfRange do
    WriteLn('Deque is empty');
end;

// 安全的操作方式
var
  Value: Integer;
begin
  if Deque.PopFront(Value) then
    WriteLn('Got value: ', Value)
  else
    WriteLn('Deque is empty');
end;
```

## 内存管理

TVecDeque 自动管理内存，但了解其行为有助于优化：

```pascal
var
  Deque: TIntDeque;
begin
  Deque := TIntDeque.Create;

  // 添加大量元素
  for i := 1 to 10000 do
    Deque.PushBack(i);

  // 移除大部分元素
  Deque.TrimToSize(100);

  // 手动触发容量优化
  Deque.OptimizeCapacity;  // 如果负载因子过低会自动收缩

  Deque.Free;  // 释放所有资源
end;
```

## 线程安全

TVecDeque **不是线程安全的**。在多线程环境中使用时需要外部同步：

```pascal
var
  Deque: TIntDeque;
  Lock: TCriticalSection;

procedure ThreadSafeAdd(Value: Integer);
begin
  Lock.Enter;
  try
    Deque.PushBack(Value);
  finally
    Lock.Leave;
  end;
end;
```

## 与其他容器的比较

| 操作 | TVecDeque | TArray | TList |
|------|-----------|---------|-------|
| 前端插入 | O(1) | O(n) | O(n) |
| 后端插入 | O(1) | O(1)* | O(1)* |
| 随机访问 | O(1) | O(1) | O(1) |
| 中间插入 | O(n) | O(n) | O(n) |
| 内存效率 | 高 | 高 | 中等 |

*摊销时间复杂度

## 最佳实践

1. **预分配容量**: 如果知道大概的元素数量，预先分配容量
2. **使用批量操作**: 优先使用数组版本的 PushFront/PushBack
3. **避免中间操作**: 尽量使用双端操作而不是中间插入/删除
4. **及时释放**: 使用完毕后及时调用 Free 释放资源
5. **监控容量**: 在调试时可以监控负载因子和浪费空间

更多策略组合与建议，参见：docs/partials/collections.best_practices.md。

TVecDeque 是一个功能强大、性能优异的双端队列实现，适合各种需要高效双端操作的场景。
