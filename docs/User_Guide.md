# VecDeque 使用指南

> See also: Collections
> - Collections API 索引：docs/API_collections.md
> - TVec 模块文档：docs/fafafa.core.collections.vec.md
> - 集合系统概览：docs/fafafa.core.collections.md


> Paste 最佳实践速查（终端模块）：docs/partials/term.paste.best_practices.md


## 目录

- [快速入门](#快速入门)
- [基础概念](#基础概念)
- [常见使用场景](#常见使用场景)
- [高级功能](#高级功能)
- [性能优化](#性能优化)
- [错误处理](#错误处理)
- [最佳实践](#最佳实践)
- [测试注册最佳实践](#测试注册最佳实践)


## 快速入门

### 第一个程序

```pascal
program HelloVecDeque;
uses
  fafafa.core.collections.vecdeque.specialized;

var
  LNumbers: TIntegerVecDeque;
  i: Integer;
begin
  // 创建队列
  LNumbers := TIntegerVecDeque.Create;
  try
    // 添加一些数字
    LNumbers.PushBack(1);
    LNumbers.PushBack(2);
    LNumbers.PushBack(3);

    // 打印所有元素
    for i := 0 to LNumbers.GetCount - 1 do
      WriteLn(LNumbers.Get(i));

  finally
    LNumbers.Free;
  end;
end.
```

### 选择合适的类型

```pascal
// 对于整数，使用特化版本
var LIntDeque: TIntegerVecDeque;

// 对于字符串，使用特化版本
var LStringDeque: TStringVecDeque;

// 对于自定义类型，使用泛型版本
type
  TMyRecord = record
    Name: String;
    Age: Integer;
  end;
  TMyVecDeque = specialize TVecDeque<TMyRecord>;

var LMyDeque: TMyVecDeque;
```

## 基础概念

### 双端队列

VecDeque 是一个双端队列，支持在两端高效地添加和删除元素：

```pascal
var LDeque: TIntegerVecDeque;
begin
  LDeque := TIntegerVecDeque.Create;
  try
    // 在尾部添加
    LDeque.PushBack(1);    // [1]
    LDeque.PushBack(2);    // [1, 2]

    // 在头部添加
    LDeque.PushFront(0);   // [0, 1, 2]

    // 从尾部移除
    WriteLn(LDeque.PopBack);   // 输出: 2, 队列变为 [0, 1]

    // 从头部移除
    WriteLn(LDeque.PopFront);  // 输出: 0, 队列变为 [1]

  finally
    LDeque.Free;
  end;
end;
```

### 环形缓冲区

VecDeque 内部使用环形缓冲区实现，这使得头部和尾部操作都是 O(1)：

```
初始状态: [_, _, _, _]  (容量=4, 头=0, 尾=0)
PushBack(1): [1, _, _, _]  (头=0, 尾=1)
PushBack(2): [1, 2, _, _]  (头=0, 尾=2)
PushFront(0): [1, 2, _, 0]  (头=3, 尾=2)
```

## 常见使用场景

### 1. 作为栈使用

```pascal
// 后进先出 (LIFO)
LDeque.PushBack(1);
LDeque.PushBack(2);
LDeque.PushBack(3);

while not LDeque.IsEmpty do
  WriteLn(LDeque.PopBack);  // 输出: 3, 2, 1
```

### 2. 作为队列使用

```pascal
// 先进先出 (FIFO)
LDeque.PushBack(1);
LDeque.PushBack(2);
LDeque.PushBack(3);

while not LDeque.IsEmpty do
  WriteLn(LDeque.PopFront);  // 输出: 1, 2, 3
```

### 3. 滑动窗口

```pascal
procedure ProcessSlidingWindow(const AData: array of Integer; AWindowSize: Integer);
var
  LWindow: TIntegerVecDeque;
  i: Integer;
begin
  LWindow := TIntegerVecDeque.Create;
  try
    for i := 0 to Length(AData) - 1 do
    begin
      // 添加新元素
      LWindow.PushBack(AData[i]);

      // 保持窗口大小
      if LWindow.GetCount > AWindowSize then
        LWindow.PopFront;

      // 处理当前窗口
      if LWindow.GetCount = AWindowSize then
        ProcessWindow(LWindow);
    end;
  finally
    LWindow.Free;
  end;
end;
```

### 4. 撤销/重做功能

```pascal
type
  TUndoRedoManager = class
  private
    FUndoStack: TStringVecDeque;
    FRedoStack: TStringVecDeque;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ExecuteCommand(const ACommand: String);
    procedure Undo;
    procedure Redo;
  end;

procedure TUndoRedoManager.ExecuteCommand(const ACommand: String);
begin
  FUndoStack.PushBack(ACommand);
  FRedoStack.Clear;  // 清空重做栈
end;

procedure TUndoRedoManager.Undo;
begin
  if not FUndoStack.IsEmpty then
  begin
    FRedoStack.PushBack(FUndoStack.PopBack);
    // 执行撤销操作
  end;
end;
```

## 高级功能

### 1. 零拷贝访问

使用 `AsSlices` 获取直接内存访问：

```pascal
var
  LFirst, LSecond: Pointer;
  LFirstLen, LSecondLen: SizeUInt;
  LIntPtr: PInteger;
  i: SizeUInt;
begin
  LDeque.AsSlices(LFirst, LFirstLen, LSecond, LSecondLen);

  // 直接访问第一个片段
  LIntPtr := PInteger(LFirst);
  for i := 0 to LFirstLen - 1 do
  begin
    WriteLn(LIntPtr^);
    Inc(LIntPtr);
  end;

  // 如果有第二个片段
  if LSecondLen > 0 then
  begin
    LIntPtr := PInteger(LSecond);
    for i := 0 to LSecondLen - 1 do
    begin
      WriteLn(LIntPtr^);
      Inc(LIntPtr);
    end;
  end;
end;
```

### 2. 内存连续化

```pascal
var
  LPtr: Pointer;
begin
  // 检查是否连续
  if not LDeque.IsContiguous then
  begin
    WriteLn('数据不连续，正在重排...');

## 测试注册最佳实践

- 使用闭包（reference to procedure）注册测试/子测试，避免使用 `is nested`；
- 原因：`RegisterTests` 返回后，nested proc 的静态链可能失效，延迟调用时会 AV；
- 详情与示例：docs/partials/testing.best_practices.md

    LPtr := LDeque.MakeContiguous;
    WriteLn('数据已连续化');
  end;
end;
```

### 3. 范围操作

```pascal
var
  LDrained: array of Integer;
  i: Integer;
begin
  // 移除中间的元素
  LDeque.Drain(2, 3, LDrained);

  WriteLn('移除的元素:');
  for i := 0 to Length(LDrained) - 1 do
    WriteLn(LDrained[i]);
end;
```

### 4. 分割操作

```pascal
var
  LSecondHalf: TIntegerVecDeque;
begin
  // 在索引 5 处分割
  LSecondHalf := LDeque.SplitOff(5) as TIntegerVecDeque;
  try
    WriteLn('原队列元素数: ', LDeque.GetCount);
    WriteLn('新队列元素数: ', LSecondHalf.GetCount);
  finally
    LSecondHalf.Free;
  end;
end;
```

## 性能优化

### 1. 预留容量

```pascal
var
  LDeque: TIntegerVecDeque;
  i: Integer;
begin
  LDeque := TIntegerVecDeque.Create;
  try
    // 如果知道大概大小，预留容量
    LDeque.Reserve(10000);

    for i := 1 to 10000 do
      LDeque.PushBack(i);

  finally
    LDeque.Free;
  end;
end;
```

### 2. 使用并行操作

```pascal
var
  LLargeDeque: TIntegerVecDeque;
begin
  // 对于大数据集，使用并行排序
  if LLargeDeque.GetCount > 10000 then
    LLargeDeque.ParallelSort
  else
    LLargeDeque.Sort;
end;
```

### 3. 批量操作

```pascal
// 好的做法：批量添加
procedure AddRange(ADeque: TIntegerVecDeque; const AValues: array of Integer);
var
  i: Integer;
begin
  ADeque.Reserve(ADeque.GetCount + Length(AValues));
  for i := 0 to Length(AValues) - 1 do
    ADeque.PushBack(AValues[i]);
end;

// 避免：频繁的单个操作导致多次重新分配
```

## 错误处理

### 1. 安全的元素访问

```pascal
function SafeGet(ADeque: TIntegerVecDeque; AIndex: SizeUInt; ADefault: Integer): Integer;
begin
  try
    Result := ADeque.Get(AIndex);
  except
    on EOutOfRange do
      Result := ADefault;
  end;
end;
```

### 2. 安全的弹出操作

```pascal
function SafePopBack(ADeque: TIntegerVecDeque; out AValue: Integer): Boolean;
begin
  try
    AValue := ADeque.PopBack;
    Result := True;
  except
    on EInvalidOperation do
    begin
      AValue := 0;
      Result := False;
    end;
  end;
end;
```

### 3. 内存分配检查

```pascal
function SafeReserve(ADeque: TIntegerVecDeque; ACapacity: SizeUInt): Boolean;
begin
  Result := ADeque.TryReserve(ACapacity);
  if not Result then
    WriteLn('警告：内存分配失败');
end;
```

## 最佳实践

### 1. 资源管理

```pascal
// 总是使用 try-finally
var
  LDeque: TIntegerVecDeque;
begin
  LDeque := TIntegerVecDeque.Create;
  try
    // 使用 LDeque
  finally
    LDeque.Free;
  end;
end;
```

### 2. 选择合适的操作

```pascal
// 好的做法：根据使用模式选择操作
if NeedFIFO then
begin
  LDeque.PushBack(Value);    // 入队
  Value := LDeque.PopFront;  // 出队
end
else if NeedLIFO then
begin
  LDeque.PushBack(Value);    // 入栈
  Value := LDeque.PopBack;   // 出栈
end;
```

### 3. 性能监控

```pascal
var
  LStartTime, LEndTime: QWord;
begin
  LStartTime := GetTickCount64;

  // 执行操作
  LDeque.Sort;

  LEndTime := GetTickCount64;
  WriteLn('排序耗时: ', LEndTime - LStartTime, ' ms');
end;
```

### 4. 内存使用监控

```pascal
procedure MonitorMemoryUsage(ADeque: TIntegerVecDeque);
begin
  WriteLn('元素数量: ', ADeque.GetCount);
  WriteLn('容量: ', ADeque.GetCapacity);
  WriteLn('内存使用: ', ADeque.GetMemoryUsage, ' bytes');
  WriteLn('利用率: ', (ADeque.GetCount * 100 div ADeque.GetCapacity), '%');
end;
```

## 调试技巧

### 1. 打印队列状态

```pascal
procedure PrintDequeState(ADeque: TIntegerVecDeque; const ALabel: String);
var
  i: Integer;
begin
  WriteLn(ALabel, ':');
  Write('  元素: [');
  for i := 0 to ADeque.GetCount - 1 do
  begin
    if i > 0 then Write(', ');
    Write(ADeque.Get(i));
  end;
  WriteLn(']');
  WriteLn('  数量: ', ADeque.GetCount, ', 容量: ', ADeque.GetCapacity);
end;
```

### 2. 验证不变量

```pascal
procedure ValidateDeque(ADeque: TIntegerVecDeque);
begin
  Assert(ADeque.GetCount <= ADeque.GetCapacity, '元素数量不能超过容量');
  Assert((ADeque.GetCount = 0) = ADeque.IsEmpty, '空状态不一致');

  if ADeque.GetCount > 0 then
  begin
    // 验证头尾元素可访问
    ADeque.Front;
    ADeque.Back;
  end;
end;
```

这个使用指南涵盖了从基础到高级的各种使用场景，帮助开发者充分利用 VecDeque 的功能。
