# TCircularBuffer - 环形缓冲区使用指南

## 概述

`TCircularBuffer<T>` 是**固定容量**的 FIFO（先进先出）缓冲区，使用环形索引实现。

| 特性 | 描述 |
|------|------|
| 容量 | 创建时固定 |
| Push/Pop | O(1) |
| 内存 | 固定大小 |
| 溢出策略 | 可配置（覆盖或拒绝） |

> **适用场景**：日志缓冲、滑动窗口、音视频流、生产者-消费者队列。

## 快速开始

```pascal
uses
  fafafa.core.collections.circularbuffer;

var
  Buffer: specialize TCircularBuffer<Integer>;
begin
  // 创建容量为 5 的环形缓冲区（满时覆盖最旧元素）
  Buffer := specialize TCircularBuffer<Integer>.Create(5, True);
  try
    // 填满缓冲区
    Buffer.Push(1);
    Buffer.Push(2);
    Buffer.Push(3);
    Buffer.Push(4);
    Buffer.Push(5);
    
    // 再 Push 会覆盖最旧的元素
    Buffer.Push(6);  // 1 被覆盖
    
    // Pop 返回最旧的元素
    WriteLn(Buffer.Pop);  // 2
    WriteLn(Buffer.Pop);  // 3
  finally
    Buffer.Free;
  end;
end;
```

## API 参考

### 创建

```pascal
// 默认：满时覆盖最旧元素
Buffer := specialize TCircularBuffer<T>.Create(Capacity);

// 明确指定溢出策略
Buffer := specialize TCircularBuffer<T>.Create(Capacity, OverwriteOldest);
```

| 参数 | 说明 |
|------|------|
| `Capacity` | 缓冲区容量（必须 > 0） |
| `OverwriteOldest` | `True` = 满时覆盖；`False` = 满时拒绝 |

### Push

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Push(element): Boolean` | 添加元素 | O(1) |

```pascal
// 覆盖模式：总是返回 True
Buffer.Push(Value);

// 拒绝模式：满时返回 False
if not Buffer.Push(Value) then
  WriteLn('Buffer full');
```

### Pop

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Pop: T` | 移除并返回最旧元素 | O(1) |
| `TryPop(out element): Boolean` | 安全版本 | O(1) |
| `PopBatch(count): TArray` | 批量弹出 | O(n) |

```pascal
// 可能抛异常
var Value := Buffer.Pop;

// 安全版本
var Value: Integer;
if Buffer.TryPop(Value) then
  ProcessValue(Value);

// 批量弹出
var Batch := Buffer.PopBatch(3);
```

### Peek

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Peek: T` | 查看最旧元素（不移除） | O(1) |
| `PeekAt(offset): T` | 查看指定偏移位置 | O(1) |
| `TryPeek(out element): Boolean` | 安全版本 | O(1) |

```pascal
// 查看最旧元素
var Oldest := Buffer.Peek;

// 按偏移查看（0 = 最旧，Count-1 = 最新）
var Third := Buffer.PeekAt(2);

// 安全版本
var Value: Integer;
if Buffer.TryPeek(Value) then
  WriteLn('Next to pop: ', Value);
```

### 状态查询

| 方法 | 描述 |
|------|------|
| `GetCount: SizeUInt` | 当前元素数量 |
| `Capacity: SizeUInt` | 缓冲区容量 |
| `RemainingCapacity: SizeUInt` | 剩余空间 |
| `IsEmpty: Boolean` | 是否为空 |
| `IsFull: Boolean` | 是否已满 |

### 其他

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Clear` | 清空缓冲区 | O(n) |
| `ToArray: TArray` | 转换为数组（FIFO 顺序） | O(n) |

### 属性

```pascal
Buffer.OverwriteOldest := True;  // 运行时可修改溢出策略
```

## 环形缓冲区工作原理

```
容量 = 5，已有 [A, B, C, D, E]

内存布局:
┌───┬───┬───┬───┬───┐
│ A │ B │ C │ D │ E │
└───┴───┴───┴───┴───┘
  ↑               ↑
 Head           Tail
(Pop)          (Push)

Push(F) 后（覆盖模式）:
┌───┬───┬───┬───┬───┐
│ F │ B │ C │ D │ E │
└───┴───┴───┴───┴───┘
      ↑           ↑
    Head        Tail

Pop() 返回 B:
┌───┬───┬───┬───┬───┐
│ F │ - │ C │ D │ E │
└───┴───┴───┴───┴───┘
          ↑       ↑
        Head    Tail
```

## 使用模式

### 模式 1：日志缓冲

```pascal
type
  TLogEntry = record
    Timestamp: TDateTime;
    Level: TLogLevel;
    Message: string;
  end;
  TLogBuffer = specialize TCircularBuffer<TLogEntry>;

var
  RecentLogs: TLogBuffer;

procedure InitLogger;
begin
  // 保留最近 1000 条日志
  RecentLogs := TLogBuffer.Create(1000, True);
end;

procedure Log(Level: TLogLevel; const Msg: string);
var
  Entry: TLogEntry;
begin
  Entry.Timestamp := Now;
  Entry.Level := Level;
  Entry.Message := Msg;
  RecentLogs.Push(Entry);
end;

function GetRecentLogs: TLogBuffer.TInternalArray;
begin
  Result := RecentLogs.ToArray;
end;
```

### 模式 2：滑动窗口统计

```pascal
type
  TSlidingWindow = specialize TCircularBuffer<Double>;

var
  Window: TSlidingWindow;

function MovingAverage(NewValue: Double): Double;
var
  Arr: TSlidingWindow.TInternalArray;
  Sum: Double;
begin
  Window.Push(NewValue);
  
  Arr := Window.ToArray;
  Sum := 0;
  for var V in Arr do
    Sum := Sum + V;
    
  Result := Sum / Length(Arr);
end;

// 初始化
Window := TSlidingWindow.Create(10, True);  // 10个数据点的滑动窗口
```

### 模式 3：生产者-消费者缓冲

```pascal
type
  TDataBuffer = specialize TCircularBuffer<TData>;

var
  Buffer: TDataBuffer;

// 生产者
procedure Produce(const Data: TData);
begin
  // 不覆盖模式：满时等待
  while not Buffer.Push(Data) do
    Sleep(1);
end;

// 消费者
procedure Consume;
var
  Data: TData;
begin
  if Buffer.TryPop(Data) then
    Process(Data);
end;
```

### 模式 4：撤销历史

```pascal
type
  TUndoBuffer = specialize TCircularBuffer<TUndoAction>;

var
  UndoHistory: TUndoBuffer;

procedure RecordAction(const Action: TUndoAction);
begin
  UndoHistory.Push(Action);
end;

procedure Undo;
var
  Action: TUndoAction;
begin
  // 注意：标准环形缓冲区是 FIFO，撤销需要 LIFO
  // 这里需要额外逻辑或使用栈
end;
```

## 典型应用

### 音频采样缓冲

```pascal
type
  TAudioSample = Single;
  TAudioBuffer = specialize TCircularBuffer<TAudioSample>;

var
  PlaybackBuffer: TAudioBuffer;

procedure InitAudio(SampleRate, BufferMs: Integer);
var
  BufferSize: Integer;
begin
  // 计算缓冲区大小：采样率 × 缓冲时间(秒)
  BufferSize := SampleRate * BufferMs div 1000;
  PlaybackBuffer := TAudioBuffer.Create(BufferSize, False);
end;

// 音频回调
procedure AudioCallback(OutputBuffer: PSingle; FrameCount: Integer);
var
  Sample: TAudioSample;
begin
  for var i := 0 to FrameCount - 1 do
  begin
    if PlaybackBuffer.TryPop(Sample) then
      OutputBuffer[i] := Sample
    else
      OutputBuffer[i] := 0;  // 静音
  end;
end;
```

### 网络数据包缓冲

```pascal
type
  TPacket = record
    Data: TBytes;
    ReceivedAt: TDateTime;
  end;
  TPacketBuffer = specialize TCircularBuffer<TPacket>;

var
  IncomingPackets: TPacketBuffer;

procedure OnPacketReceived(const Data: TBytes);
var
  Pkt: TPacket;
begin
  Pkt.Data := Data;
  Pkt.ReceivedAt := Now;
  
  if not IncomingPackets.Push(Pkt) then
    Inc(DroppedPacketCount);  // 缓冲区满，丢包
end;
```

## CircularBuffer vs 其他容器

| 特性 | TCircularBuffer | TVecDeque | TQueue |
|------|-----------------|-----------|--------|
| 容量 | **固定** | 动态 | 动态 |
| 溢出处理 | 可配置 | 自动扩容 | 自动扩容 |
| 内存占用 | 可预测 | 可变 | 可变 |
| Push/Pop | O(1) | O(1) | O(1) |

### 选择建议

| 场景 | 推荐 |
|------|------|
| 内存受限 | `TCircularBuffer` |
| 只保留最近 N 条 | `TCircularBuffer`（覆盖模式） |
| 容量不确定 | `TVecDeque` |
| 简单队列 | `TQueue` |

## 性能特征

| 操作 | 时间复杂度 | 说明 |
|------|-----------|------|
| Push | O(1) | 总是 O(1)，无需扩容 |
| Pop | O(1) | |
| Peek/PeekAt | O(1) | |
| IsFull/IsEmpty | O(1) | |
| ToArray | O(n) | 需复制所有元素 |
| PopBatch | O(k) | k = 弹出数量 |
| Clear | O(n) | 托管类型需要 Finalize |

## 内存结构

```
TCircularBuffer
├── FBuffer: array[0..Capacity-1] of T  // 固定大小数组
├── FHead: SizeUInt                      // 队首索引
├── FTail: SizeUInt                      // 队尾索引
├── FCount: SizeUInt                     // 当前元素数量
├── FCapacity: SizeUInt                  // 固定容量
└── FOverwriteOldest: Boolean            // 溢出策略
```

## 注意事项

1. **容量必须 > 0**
   ```pascal
   // ❌ 异常
   Buffer := TCircularBuffer<T>.Create(0);
   
   // ✅ 正确
   Buffer := TCircularBuffer<T>.Create(1);
   ```

2. **溢出策略选择**
   ```pascal
   // 覆盖模式：保留最新数据
   Buffer := TCircularBuffer<T>.Create(100, True);
   
   // 拒绝模式：保留最旧数据，需检查返回值
   Buffer := TCircularBuffer<T>.Create(100, False);
   if not Buffer.Push(Value) then
     HandleBufferFull;
   ```

3. **PeekAt 偏移范围**
   ```pascal
   // 偏移 0 = 最旧（即将 Pop 的）
   // 偏移 Count-1 = 最新（刚 Push 的）
   Buffer.PeekAt(0);              // 最旧
   Buffer.PeekAt(Buffer.Count-1); // 最新
   Buffer.PeekAt(Buffer.Count);   // ❌ EOutOfRange
   ```

4. **不支持指针迭代**
   ```pascal
   // ❌ 环形缓冲区内存不连续，不支持 PtrIter
   for var p in Buffer.PtrIter do  // 异常
   
   // ✅ 使用 ToArray 或 PeekAt
   for var i := 0 to Buffer.Count - 1 do
     Process(Buffer.PeekAt(i));
   ```

## 最佳实践

1. **预估容量**
   ```pascal
   // 根据实际需求设置合理容量
   // 日志：考虑最大需要回溯的条数
   // 音频：采样率 × 最大延迟
   // 网络：考虑最大突发流量
   ```

2. **使用安全方法**
   ```pascal
   // 生产环境推荐使用 Try* 方法
   var Value: T;
   if Buffer.TryPop(Value) then
     Process(Value);
   ```

3. **运行时调整策略**
   ```pascal
   // 可根据负载动态调整
   if HighLoad then
     Buffer.OverwriteOldest := True
   else
     Buffer.OverwriteOldest := False;
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `TVecDeque<T>` | 动态容量双端队列 |
| `TQueue<T>` | 简单队列 |
| `TStack<T>` | LIFO 栈 |
