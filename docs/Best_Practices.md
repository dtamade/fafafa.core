# VecDeque 最佳实践指南

> 相关链接（Collections）
> - Collections API 索引：docs/API_collections.md
> - TVec 模块文档：docs/fafafa.core.collections.vec.md
> - 集合系统概览：docs/fafafa.core.collections.md


## 目录

- [设计原则](#设计原则)
- [类型选择](#类型选择)
- [内存管理](#内存管理)
- [错误处理](#错误处理)
- [性能优化](#性能优化)
- [线程安全](#线程安全)
- [测试策略](#测试策略)
- [测试注册最佳实践](#测试注册最佳实践)

- [代码风格](#代码风格)

## 设计原则

### 1. 选择合适的数据结构

```pascal
// ✅ 好的选择：需要双端操作
procedure GoodUseCase;
var
  LTaskQueue: TStringVecDeque;
begin
  LTaskQueue := TStringVecDeque.Create;
  try
    // 高优先级任务插入队首
    LTaskQueue.PushFront('HighPriorityTask');

    // 普通任务插入队尾
    LTaskQueue.PushBack('NormalTask');

    // 从队首处理任务
    while not LTaskQueue.IsEmpty do
      ProcessTask(LTaskQueue.PopFront);

  finally
    LTaskQueue.Free;
  end;
end;

// ❌ 不好的选择：只需要单端操作
procedure PoorUseCase;
var
  LStack: TIntegerVecDeque;  // 应该使用 TList 或 TStack
begin
  // 只使用一端操作，VecDeque 是过度设计
  LStack.PushBack(1);
  LStack.PushBack(2);
  WriteLn(LStack.PopBack);
end;
```

### 2. 明确所有权和生命周期

```pascal
type
  TDataProcessor = class
  private
    FDataQueue: TIntegerVecDeque;  // 拥有队列
    FSharedQueue: TIntegerVecDeque; // 不拥有，只是引用
  public
    constructor Create(ASharedQueue: TIntegerVecDeque);
    destructor Destroy; override;

    procedure ProcessData;
  end;

constructor TDataProcessor.Create(ASharedQueue: TIntegerVecDeque);
begin
  inherited Create;
  FDataQueue := TIntegerVecDeque.Create;  // 创建自己的队列
  FSharedQueue := ASharedQueue;           // 保存引用，不拥有
end;

destructor TDataProcessor.Destroy;
begin
  FDataQueue.Free;  // 释放自己拥有的队列
  // 不释放 FSharedQueue，因为不拥有它
  inherited Destroy;
end;
```

## 类型选择

### 1. 优先使用特化类型

```pascal
// ✅ 推荐：使用特化类型
var
  LNumbers: TIntegerVecDeque;
  LNames: TStringVecDeque;
begin
  LNumbers := TIntegerVecDeque.Create;
  LNames := TStringVecDeque.Create;
  try
    // 可以使用默认排序和特化方法
    LNumbers.Sort;
    WriteLn('Sum: ', LNumbers.Sum);

    LNames.Sort;
    WriteLn('Joined: ', LNames.Join(', '));

  finally
    LNumbers.Free;
    LNames.Free;
  end;
end;

// ⚠️ 谨慎：泛型类型需要更多工作
type
  TMyRecord = record
    ID: Integer;
    Name: String;
  end;
  TMyVecDeque = specialize TVecDeque<TMyRecord>;

function CompareMyRecord(const A, B: TMyRecord; Data: Pointer): Integer;
begin
  Result := A.ID - B.ID;
end;

var
  LRecords: TMyVecDeque;
begin
  LRecords := TMyVecDeque.Create;
  try
    // 必须提供比较函数
    LRecords.Sort(@CompareMyRecord, nil);
  finally
    LRecords.Free;
  end;
end;
```

### 2. 自定义类型的最佳实践

```pascal
type
  // 为复杂类型定义比较函数
  TEmployee = record
    ID: Integer;
    Name: String;
    Salary: Currency;
  end;

  TEmployeeVecDeque = specialize TVecDeque<TEmployee>;

  TEmployeeComparator = class
  public
    class function ByID(const A, B: TEmployee; Data: Pointer): Integer; static;
    class function ByName(const A, B: TEmployee; Data: Pointer): Integer; static;
    class function BySalary(const A, B: TEmployee; Data: Pointer): Integer; static;
  end;

class function TEmployeeComparator.ByID(const A, B: TEmployee; Data: Pointer): Integer;
begin
  Result := A.ID - B.ID;
end;

class function TEmployeeComparator.ByName(const A, B: TEmployee; Data: Pointer): Integer;
begin
  Result := CompareStr(A.Name, B.Name);
end;

class function TEmployeeComparator.BySalary(const A, B: TEmployee; Data: Pointer): Integer;
begin
  if A.Salary < B.Salary then Result := -1
  else if A.Salary > B.Salary then Result := 1
  else Result := 0;
end;

// 使用示例
procedure SortEmployees(AEmployees: TEmployeeVecDeque);
begin
  // 根据需要选择排序方式
  AEmployees.Sort(@TEmployeeComparator.ByName, nil);
end;
```

## 内存管理

### 1. 容量预估和预留

```pascal
// ✅ 好的实践：预估容量
procedure ProcessLargeDataset(const AFilename: String);
var
  LData: TIntegerVecDeque;
  LEstimatedSize: SizeUInt;
begin
  LData := TIntegerVecDeque.Create;
  try
    // 根据文件大小或历史数据预估
    LEstimatedSize := EstimateDataSize(AFilename);
    LData.Reserve(LEstimatedSize);

    LoadDataFromFile(AFilename, LData);
    ProcessData(LData);

  finally
    LData.Free;
  end;
end;

function EstimateDataSize(const AFilename: String): SizeUInt;
var
  LFileSize: Int64;
begin
  LFileSize := GetFileSize(AFilename);
  // 假设每行大约 20 字节，估算行数
  Result := LFileSize div 20;
end;

## 测试注册最佳实践

- 使用闭包（reference to procedure）注册测试/子测试，避免使用 `is nested` 的过程类型；
- 原因：`RegisterTests` 返回后，nested proc 的静态链可能失效，延迟调用会 AV；
- 参考：docs/partials/testing.best_practices.md；

```

### 2. 内存使用监控

```pascal
type
  TMemoryAwareVecDeque = class
  private
    FDeque: TIntegerVecDeque;
    FMaxMemoryUsage: SizeUInt;

    procedure CheckMemoryUsage;
  public
    constructor Create(AMaxMemoryMB: Integer);
    destructor Destroy; override;

    procedure PushBack(const AValue: Integer);
    procedure PushFront(const AValue: Integer);
  end;

constructor TMemoryAwareVecDeque.Create(AMaxMemoryMB: Integer);
begin
  inherited Create;
  FDeque := TIntegerVecDeque.Create;
  FMaxMemoryUsage := AMaxMemoryMB * 1024 * 1024;  // 转换为字节
end;

procedure TMemoryAwareVecDeque.CheckMemoryUsage;
begin
  if FDeque.GetMemoryUsage > FMaxMemoryUsage then
  begin
    WriteLn('警告：内存使用超过限制');
    // 可以选择收缩或抛出异常
    FDeque.ShrinkTo(FDeque.GetCount);
  end;
end;

procedure TMemoryAwareVecDeque.PushBack(const AValue: Integer);
begin
  FDeque.PushBack(AValue);
  CheckMemoryUsage;
end;
```

### 3. 资源清理模式

```pascal
// ✅ RAII 模式
type
  TVecDequeGuard = class
  private
    FDeque: TIntegerVecDeque;
  public
    constructor Create;
    destructor Destroy; override;

    property Deque: TIntegerVecDeque read FDeque;
  end;

constructor TVecDequeGuard.Create;
begin
  inherited Create;
  FDeque := TIntegerVecDeque.Create;
end;

destructor TVecDequeGuard.Destroy;
begin
  FDeque.Free;
  inherited Destroy;
end;

// 使用示例
procedure SafeVecDequeUsage;
var
  LGuard: TVecDequeGuard;
begin
  LGuard := TVecDequeGuard.Create;
  try
    // 使用 LGuard.Deque
    LGuard.Deque.PushBack(42);

    // 即使发生异常，也会自动清理
    if SomeCondition then
      raise Exception.Create('Something went wrong');

  finally
    LGuard.Free;  // 自动清理 VecDeque
  end;
end;
```

## 错误处理

### 1. 防御性编程

```pascal
// ✅ 安全的访问模式
function SafeGetElement(ADeque: TIntegerVecDeque; AIndex: SizeUInt;
                       ADefault: Integer = 0): Integer;
begin
  if (ADeque <> nil) and (AIndex < ADeque.GetCount) then
    Result := ADeque.Get(AIndex)
  else
    Result := ADefault;
end;

function SafePopBack(ADeque: TIntegerVecDeque; out AValue: Integer): Boolean;
begin
  if (ADeque <> nil) and not ADeque.IsEmpty then
  begin
    AValue := ADeque.PopBack;
    Result := True;
  end
  else
  begin
    AValue := 0;
    Result := False;
  end;
end;
```

### 2. 异常处理策略

```pascal
// ✅ 分层异常处理
procedure ProcessDataWithErrorHandling(ADeque: TIntegerVecDeque);
begin
  try
    // 业务逻辑
    ProcessBusinessLogic(ADeque);

  except
    on E: EOutOfRange do
    begin
      WriteLn('数据访问错误: ', E.Message);
      // 记录日志，但不重新抛出
    end;

    on E: EInvalidOperation do
    begin
      WriteLn('操作错误: ', E.Message);
      // 可能需要重新抛出
      raise;
    end;

    on E: EOutOfMemory do
    begin
      WriteLn('内存不足: ', E.Message);
      // 尝试清理内存
      ADeque.ShrinkTo(ADeque.GetCount div 2);
      raise;  // 重新抛出，让上层处理
    end;
  end;
end;
```

### 3. 输入验证

```pascal
procedure ValidatedBatchInsert(ADeque: TIntegerVecDeque;
                              const AValues: array of Integer);
var
  i: Integer;
begin
  // 输入验证
  if ADeque = nil then
    raise EArgumentNilException.Create('ADeque cannot be nil');

  if Length(AValues) = 0 then
    Exit;  // 空数组，直接返回

  // 检查内存限制
  if not ADeque.TryReserve(Length(AValues)) then
    raise EOutOfMemory.Create('Cannot reserve memory for batch insert');

  // 执行插入
  for i := 0 to Length(AValues) - 1 do
    ADeque.PushBack(AValues[i]);
end;
```

## 性能优化

### 1. 操作模式优化

```pascal
// ✅ 针对使用模式优化
type
  TOptimizedQueue = class
  private
    FQueue: TIntegerVecDeque;
    FBatchSize: Integer;
    FBatchBuffer: array of Integer;
    FBatchCount: Integer;

  public
    constructor Create(ABatchSize: Integer = 100);
    destructor Destroy; override;

    procedure EnqueueBatch(const AValues: array of Integer);
    procedure FlushBatch;
    function Dequeue: Integer;
  end;

procedure TOptimizedQueue.EnqueueBatch(const AValues: array of Integer);
var
  i, LAvailable: Integer;
begin
  i := 0;
  while i < Length(AValues) do
  begin
    LAvailable := FBatchSize - FBatchCount;
    LAvailable := Min(LAvailable, Length(AValues) - i);

    // 填充批次缓冲区
    Move(AValues[i], FBatchBuffer[FBatchCount], LAvailable * SizeOf(Integer));
    Inc(FBatchCount, LAvailable);
    Inc(i, LAvailable);

    // 如果批次满了，刷新到队列
    if FBatchCount = FBatchSize then
      FlushBatch;
  end;
end;

procedure TOptimizedQueue.FlushBatch;
var
  i: Integer;
begin
  if FBatchCount > 0 then
  begin
    FQueue.Reserve(FQueue.GetCount + FBatchCount);
    for i := 0 to FBatchCount - 1 do
      FQueue.PushBack(FBatchBuffer[i]);
    FBatchCount := 0;
  end;
end;
```

### 2. 缓存友好的访问

```pascal
// ✅ 缓存友好的遍历
procedure CacheFriendlyProcessing(ADeque: TIntegerVecDeque);
var
  LFirst, LSecond: Pointer;
  LFirstLen, LSecondLen: SizeUInt;
  LPtr: PInteger;
  i: SizeUInt;
begin
  // 使用 AsSlices 获得连续内存访问
  ADeque.AsSlices(LFirst, LFirstLen, LSecond, LSecondLen);

  // 处理第一个片段
  LPtr := PInteger(LFirst);
  for i := 0 to LFirstLen - 1 do
  begin
    ProcessElement(LPtr^);  // 顺序访问，缓存友好
    Inc(LPtr);
  end;

  // 处理第二个片段
  if LSecondLen > 0 then
  begin
    LPtr := PInteger(LSecond);
    for i := 0 to LSecondLen - 1 do
    begin
      ProcessElement(LPtr^);
      Inc(LPtr);
    end;
  end;
end;
```

## 线程安全

### 1. 外部同步

```pascal
// ✅ 线程安全的包装器
type
  TThreadSafeVecDeque = class
  private
    FDeque: TIntegerVecDeque;
    FLock: TCriticalSection;

  public
    constructor Create;
    destructor Destroy; override;

    procedure PushBack(const AValue: Integer);
    function PopFront: Integer;
    function GetCount: SizeUInt;
    function IsEmpty: Boolean;
  end;

constructor TThreadSafeVecDeque.Create;
begin
  inherited Create;
  FDeque := TIntegerVecDeque.Create;
  FLock := TCriticalSection.Create;
end;

destructor TThreadSafeVecDeque.Destroy;
begin
  FLock.Free;
  FDeque.Free;
  inherited Destroy;
end;

procedure TThreadSafeVecDeque.PushBack(const AValue: Integer);
begin
  FLock.Enter;
  try
    FDeque.PushBack(AValue);
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeVecDeque.PopFront: Integer;
begin
  FLock.Enter;
  try
    if FDeque.IsEmpty then
      raise EInvalidOperation.Create('Queue is empty');
    Result := FDeque.PopFront;
  finally
    FLock.Leave;
  end;
end;
```

### 2. 读写锁优化

```pascal
// ✅ 读写锁优化（伪代码，需要实际的读写锁实现）
type
  TReadWriteVecDeque = class
  private
    FDeque: TIntegerVecDeque;
    FReadWriteLock: TReadWriteLock;  // 假设的读写锁

  public
    function Get(AIndex: SizeUInt): Integer;  // 读操作
    procedure PushBack(const AValue: Integer);  // 写操作
    function GetCount: SizeUInt;  // 读操作
  end;

function TReadWriteVecDeque.Get(AIndex: SizeUInt): Integer;
begin
  FReadWriteLock.BeginRead;
  try
    Result := FDeque.Get(AIndex);
  finally
    FReadWriteLock.EndRead;
  end;
end;

procedure TReadWriteVecDeque.PushBack(const AValue: Integer);
begin
  FReadWriteLock.BeginWrite;
  try
    FDeque.PushBack(AValue);
  finally
    FReadWriteLock.EndWrite;
  end;
end;
```

## 测试策略

### 1. 单元测试模式

```pascal
// ✅ 全面的单元测试
procedure TestVecDequeBasicOperations;
var
  LDeque: TIntegerVecDeque;
begin
  LDeque := TIntegerVecDeque.Create;
  try
    // 测试空队列
    Assert(LDeque.IsEmpty, 'New deque should be empty');
    Assert(LDeque.GetCount = 0, 'New deque should have count 0');

    // 测试添加元素
    LDeque.PushBack(1);
    Assert(not LDeque.IsEmpty, 'Deque should not be empty after push');
    Assert(LDeque.GetCount = 1, 'Count should be 1 after one push');
    Assert(LDeque.Front = 1, 'Front should be 1');
    Assert(LDeque.Back = 1, 'Back should be 1');

    // 测试双端操作
    LDeque.PushFront(0);
    LDeque.PushBack(2);
    Assert(LDeque.GetCount = 3, 'Count should be 3');
    Assert(LDeque.Front = 0, 'Front should be 0');
    Assert(LDeque.Back = 2, 'Back should be 2');

    // 测试弹出操作
    Assert(LDeque.PopFront = 0, 'PopFront should return 0');
    Assert(LDeque.PopBack = 2, 'PopBack should return 2');
    Assert(LDeque.GetCount = 1, 'Count should be 1 after pops');

  finally
    LDeque.Free;
  end;
end;
```

### 2. 边界条件测试

```pascal
procedure TestVecDequeBoundaryConditions;
var
  LDeque: TIntegerVecDeque;
  LExceptionRaised: Boolean;
begin
  LDeque := TIntegerVecDeque.Create;
  try
    // 测试空队列操作
    LExceptionRaised := False;
    try
      LDeque.PopFront;
    except
      on EInvalidOperation do
        LExceptionRaised := True;
    end;
    Assert(LExceptionRaised, 'PopFront on empty deque should raise exception');

    // 测试越界访问
    LDeque.PushBack(1);
    LExceptionRaised := False;
    try
      LDeque.Get(10);
    except
      on EOutOfRange do
        LExceptionRaised := True;
    end;
    Assert(LExceptionRaised, 'Out of range access should raise exception');

  finally
    LDeque.Free;
  end;
end;
```

## 代码风格

### 1. 命名约定

```pascal
// ✅ 清晰的命名
type
  TTaskQueue = TStringVecDeque;
  TNumberBuffer = TIntegerVecDeque;

var
  LPendingTasks: TTaskQueue;
  LProcessingBuffer: TNumberBuffer;
  LTemporaryStorage: TIntegerVecDeque;
```

### 2. 文档注释

```pascal
/// <summary>
/// 处理批量数据，使用 VecDeque 作为缓冲区
/// </summary>
/// <param name="AInputData">输入数据数组</param>
/// <param name="ABatchSize">批处理大小</param>
/// <returns>处理的元素总数</returns>
function ProcessBatchData(const AInputData: array of Integer;
                         ABatchSize: Integer): Integer;
var
  LBuffer: TIntegerVecDeque;
  i, LProcessedCount: Integer;
begin
  LBuffer := TIntegerVecDeque.Create;
  try
    // 预留足够的空间避免重新分配
    LBuffer.Reserve(ABatchSize);

    LProcessedCount := 0;
    for i := 0 to Length(AInputData) - 1 do
    begin
      LBuffer.PushBack(AInputData[i]);

      // 当缓冲区满时处理一批
      if LBuffer.GetCount >= ABatchSize then
      begin
        ProcessBatch(LBuffer);
        Inc(LProcessedCount, LBuffer.GetCount);
        LBuffer.Clear;
      end;
    end;

    // 处理剩余的元素
    if not LBuffer.IsEmpty then
    begin
      ProcessBatch(LBuffer);
      Inc(LProcessedCount, LBuffer.GetCount);
    end;

    Result := LProcessedCount;

  finally
    LBuffer.Free;
  end;
end;
```

### 3. 错误消息

```pascal
// ✅ 清晰的错误消息
procedure ValidateIndex(ADeque: TIntegerVecDeque; AIndex: SizeUInt);
begin
  if ADeque = nil then
    raise EArgumentNilException.Create('VecDeque cannot be nil');

  if AIndex >= ADeque.GetCount then
    raise EOutOfRange.CreateFmt(
      'Index %d is out of range. Valid range is 0..%d',
      [AIndex, ADeque.GetCount - 1]);
end;
```

通过遵循这些最佳实践，您可以编写出高质量、可维护、高性能的 VecDeque 应用程序。
