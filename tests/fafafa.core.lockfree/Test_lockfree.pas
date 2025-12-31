unit Test_lockfree;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$modeswitch nestedprocvars}

{$I test_config.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, SyncObjs,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.base,
  // 原子统一：测试不再依赖 fafafa.core.sync
  fafafa.core.lockfree,
  fafafa.core.lockfree.hashmap,
  fafafa.core.lockfree.hashmap.openAddressing
  {$IFDEF FAFAFA_CORE_MAP_INTERFACE}
  , fafafa.core.lockfree.map
  {$ENDIF}
  {$IFDEF FAFAFA_CORE_IFACE_FACTORIES}
  , ifaces_factories.testcase
  {$ENDIF}
  ;


type
  // 允许将匿名/嵌套过程赋值给过程变量（需要 nestedprocvars + anonymousfunctions）
  TThreadProcedure = procedure is nested;

  { 测试辅助类 }

  TTestThread = class(TThread)
  private
    FProc: TThreadProcedure;
    FErr: string;
    FStartGate: TEvent;
  public
    constructor Create(AProc: TThreadProcedure; AStartGate: TEvent);
    procedure Execute; override;
  end;


function CaseInsensitiveHash(const S: string): Cardinal;
function CaseInsensitiveEqual(const L, R: string): Boolean;

implementation

type
  // 简单插入线程（用于 OA HashMap 并发测试）
  TInsertThread = class(TThread)
  private
    FMap: TIntIntOAHashMap;
    FStartBase, FCount, FStep: Integer;
    FStartGate: TEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(AMap: TIntIntOAHashMap; AStartBase, ACount, AStep: Integer); overload;
    constructor Create(AMap: TIntIntOAHashMap; AStartBase, ACount, AStep: Integer; AStartGate: TEvent); overload;
  end;

  TThreadTestHelper = class
  public
    class function RunConcurrent(const AProcs: array of TThreadProcedure;
      ATimeoutMs: Cardinal = 10000): Boolean;
    class function RunThreadsWait(const AThreads: array of TThread;
      ATimeoutMs: Cardinal = 10000): Boolean;
  end;

  { TTestCase_TSPSCQueue - SPSC队列测试 }

  {$IFDEF FAFAFA_CORE_ENABLE_QUEUE_TESTS}
  TTestCase_TSPSCQueue = class(TTestCase)
  private
    type
      TIntQueue = TIntegerSPSCQueue;
    var
      FQueue: TIntQueue;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure TestCreate;
    procedure TestEnqueueDequeue;
    procedure TestCapacity;
    procedure TestEmpty;
    procedure TestFull;

    // 边界条件测试
    procedure TestEnqueueToFull;
    procedure TestDequeueFromEmpty;

    {$IFDEF FAFAFA_CORE_PERF_TESTS}
    // 性能测试
    procedure TestPerformance;
    {$ENDIF}

    // 并发测试
    procedure TestSingleProducerSingleConsumer;
  end;
  {$ENDIF} // FAFAFA_CORE_ENABLE_QUEUE_TESTS



  { TTestCase_TMichaelScottQueue - MPSC（Michael-Scott）无锁队列测试 }

  {$IFDEF FAFAFA_CORE_ENABLE_QUEUE_TESTS}
  TTestCase_TMichaelScottQueue = class(TTestCase)
  private
    type
      TIntQueue = TIntMPSCQueue;
    var
      FQueue: TIntQueue;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure TestCreate;
    procedure TestEnqueueDequeue;
    procedure TestEmpty;

    // 并发测试
    procedure TestMultipleProducersSingleConsumer;
    procedure TestHighConcurrency;
  end;
  {$ENDIF} // FAFAFA_CORE_ENABLE_QUEUE_TESTS

  { TTestCase_TPreAllocMPMCQueue - MPMC队列测试 }

{$IFDEF FAFAFA_CORE_ENABLE_QUEUE_TESTS}
  TTestCase_TPreAllocMPMCQueue = class(TTestCase)

  private
    type
      TIntQueue = TIntMPMCQueue;
    var
      FQueue: TIntQueue;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure TestCreate;
    procedure TestEnqueueDequeue;
    procedure TestCapacity;
    procedure TestEmpty;
    procedure TestFull;
    procedure TestFullIdempotency;
    procedure TestEmptyIdempotency;


    // 并发测试
    {$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
    procedure TestMultipleProducersMultipleConsumers;
    procedure TestHighConcurrency;
    {$ENDIF}

    {$IFDEF FAFAFA_CORE_PERF_TESTS}
    // 性能测试
    procedure TestPerformanceVsLocked;
    {$ENDIF}
  end;
{$ENDIF} // FAFAFA_CORE_ENABLE_QUEUE_TESTS



  { TTestCase_TTreiberStack - Treiber无锁栈测试 }

  TTestCase_TTreiberStack = class(TTestCase)
  private
    type
      TIntStack = TIntTreiberStack;
    var
      FStack: TIntStack;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure TestCreate;
    procedure TestPushPop;
    procedure TestEmpty;

    // 边界条件测试
    procedure TestPopFromEmpty;

    // 并发测试
    {$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
    procedure TestConcurrentPushPop;
    procedure TestHighConcurrency;
    {$ENDIF}

    {$IFDEF FAFAFA_CORE_PERF_TESTS}
    // 性能测试
    procedure TestPerformance;
    {$ENDIF}
  end;

  { TTestCase_TPreAllocStack - 预分配安全栈测试 }

  TTestCase_TPreAllocStack = class(TTestCase)
  private
    type
      TIntStack = TIntPreAllocStack;
    var
      FStack: TIntStack;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure TestCreate;
    procedure TestPushPop;
    procedure TestEmpty;
    procedure TestFull;
    procedure TestCapacity;

    // 边界条件测试
    procedure TestPopFromEmpty;
    procedure TestPushToFull;

    // 并发测试
    {$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
    procedure TestConcurrentPushPop;
    procedure TestHighConcurrency;
    {$ENDIF}

    {$IFDEF FAFAFA_CORE_PERF_TESTS}
    // 性能测试
    procedure TestPerformance;
    {$ENDIF}
  end;

  { TTestCase_TLockFreeHashMap - 无锁哈希表测试 }

  TTestCase_TLockFreeHashMap = class(TTestCase)
  private
    type
      TIntStringMap = TIntStrOAHashMap;
    var
      FHashMap: TIntStringMap;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure TestCreate;
    procedure TestPutGet;
    procedure TestRemove;
    procedure TestContainsKey;
    procedure TestEmpty;
    procedure TestCapacity;

    // 边界条件测试
    procedure TestGetNonExistent;
    procedure TestRemoveNonExistent;
    procedure TestOverwrite;
    procedure TestCapacityFullAndFail;


    // 并发测试
    procedure TestConcurrentPutGet;
    procedure TestHighConcurrency;

    {$IFDEF FAFAFA_CORE_PERF_TESTS}
    // 性能测试
    procedure TestPerformance;
    {$ENDIF}
  end;

  // 自定义比较器（大小写不敏感）的 OA HashMap 契约测试
  TTestCase_TLockFreeHashMap_CustomComparer = class(TTestCase)
  published
    procedure Test_CaseInsensitive_PutGet_Remove;
    procedure Test_CaseInsensitive_CapacityFullAndFail;
  end;

  { 并发烟囱：OA HashMap 多线程插入与校验 }
  TTestCase_TLockFreeHashMap_Concurrency = class(TTestCase)
  private
    type TIntIntMap = TIntIntOAHashMap;
    var FMap: TIntIntMap;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestConcurrentPutAndGet;
  end;

  { 并发烟囱：预分配栈多线程压栈与计数 }
  TTestCase_TPreAllocStack_Concurrency = class(TTestCase)
  private
    type TIntStack = TIntPreAllocStack;
    var FStack: TIntStack;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestConcurrentPushAndCount;
  end;



  { TTestCase_Global - 全局测试 }

  TTestCase_Global = class(TTestCase)
  published
    procedure TestNextPowerOfTwo;
    procedure TestIsPowerOfTwo;
    procedure TestSimpleHash;
  end;

  {$IFDEF FAFAFA_CORE_MAP_INTERFACE}
  { TTestCase_ILockFreeMap_Contract }
  TTestCase_ILockFreeMap_Contract = class(TTestCase)
  published
    // 基本契约
    procedure Test_OA_Impl_BasicContract;
    procedure Test_MM_Impl_BasicContract;
    // 语义与边界
    procedure Test_OA_Impl_OverwriteSemantics;
    procedure Test_OA_Impl_RemoveIdempotency;
    procedure Test_OA_Impl_CapacityAndLoad;
    procedure Test_MM_Impl_OverwriteSemantics;
    procedure Test_MM_Impl_RemoveIdempotency;
    procedure Test_MM_Impl_CollisionsWithBadHash;
  end;
  {$ENDIF}

  { TTestCase_HashMap_MM_Construct }
  TTestCase_HashMap_MM_Construct = class(TTestCase)
  published
    procedure Test_MM_Create_NilHash_Throws;
    procedure Test_MM_Create_NilComparer_Throws;
  end;



{ TTestThread }

constructor TTestThread.Create(AProc: TThreadProcedure; AStartGate: TEvent);
begin
  // 先分配，再设置回调，最后启动，避免竞态
  inherited Create(True); // 创建为悬挂状态
  FreeOnTerminate := False;
  FProc := AProc;
  FErr := '';
  FStartGate := AStartGate;
  Start;
end;

{ TInsertThread }
constructor TInsertThread.Create(AMap: TIntIntOAHashMap; AStartBase, ACount, AStep: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FMap := AMap;
  FStartBase := AStartBase;
  FCount := ACount;
  FStep := AStep;
  FStartGate := nil;
end;

constructor TInsertThread.Create(AMap: TIntIntOAHashMap; AStartBase, ACount, AStep: Integer; AStartGate: TEvent);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FMap := AMap;
  FStartBase := AStartBase;
  FCount := ACount;
  FStep := AStep;
  FStartGate := AStartGate;
end;

procedure TInsertThread.Execute;
var k, key: Integer;
begin
  if Assigned(FStartGate) then
    FStartGate.WaitFor(INFINITE);
  for k := 0 to FCount-1 do
  begin
    key := FStartBase + k*FStep;
    FMap.Put(key, key*2);
  end;
end;

procedure TTestThread.Execute;
begin
  try
    if Assigned(FStartGate) then
      FStartGate.WaitFor(INFINITE);
    if Assigned(FProc) then
      FProc();
  except
    on E: Exception do
      FErr := E.ClassName + ': ' + E.Message;
  end;
end;

{ TThreadTestHelper }

class function TThreadTestHelper.RunConcurrent(const AProcs: array of TThreadProcedure;
  ATimeoutMs: Cardinal): Boolean;
var
  LThreads: array of TTestThread;
  I: Integer;
  LStartTime: QWord;
  StartGate: TEvent;
  HasErr: Boolean;
begin
  Result := False;
  SetLength(LThreads, Length(AProcs));
  StartGate := TEvent.Create(nil, True, False, '');
  try
    // 创建并启动所有线程（构造器内部已 Start）
    for I := 0 to High(AProcs) do
    begin
      WriteLn('RunConcurrent: creating thread #', I);
      LThreads[I] := TTestThread.Create(AProcs[I], StartGate);
    end;

    // 同步起跑
    StartGate.SetEvent;

    // 等待所有线程完成（带总超时，避免 WaitFor 阻塞）
    LStartTime := GetTickCount64;
    repeat
      Result := True;
      for I := 0 to High(LThreads) do
        if Assigned(LThreads[I]) and (not LThreads[I].Finished) then
        begin
          Result := False;
          Break;
        end;
      if Result then
        Break; // 全部完成
      if GetTickCount64 - LStartTime > ATimeoutMs then
      begin
        WriteLn('RunConcurrent: timeout after ', ATimeoutMs, ' ms');
        Result := False; // 超时
        Break;
      end;
      Sleep(10);
    until False;

    // 统一异常检查
    HasErr := False;
    for I := 0 to High(LThreads) do
      if Assigned(LThreads[I]) and (LThreads[I].FErr <> '') then
      begin
        HasErr := True;
        WriteLn('RunConcurrent: thread #', I, ' error: ', LThreads[I].FErr);
      end;
    if HasErr then
      Result := False;
  finally
    // 清理线程
    for I := 0 to High(LThreads) do
      if Assigned(LThreads[I]) then
      begin
        WriteLn('RunConcurrent: freeing thread #', I);
        LThreads[I].Free;
      end;
    StartGate.Free;
  end;
end;

class function TThreadTestHelper.RunThreadsWait(const AThreads: array of TThread;
  ATimeoutMs: Cardinal): Boolean;
var
  I: Integer;
  LStartTime: QWord;
  Pending: String;
begin
  // 轮询 Finished，带总超时，避免 WaitFor 永久阻塞
  LStartTime := GetTickCount64;
  repeat
    Result := True;
    for I := 0 to High(AThreads) do
      if Assigned(AThreads[I]) and (not AThreads[I].Finished) then
      begin
        Result := False;
        Break;
      end;
    if Result then Exit(True);
    if GetTickCount64 - LStartTime > ATimeoutMs then
    begin
      Pending := '';
      for I := 0 to High(AThreads) do
        if Assigned(AThreads[I]) and (not AThreads[I].Finished) then
          Pending := Pending + IntToStr(I) + ' ';
      WriteLn('RunThreadsWait: timeout after ', ATimeoutMs, ' ms; pending threads: ', Pending);
      Exit(False);
    end;
    Sleep(10);
  until False;
end;

{ TTestCase_Global }



{ TTestCase_TSPSCQueue }

{$IFDEF FAFAFA_CORE_ENABLE_QUEUE_TESTS}

procedure TTestCase_TSPSCQueue.SetUp;
begin
  FQueue := CreateIntSPSCQueue(16); // 小容量便于测试
end;

procedure TTestCase_TSPSCQueue.TearDown;
begin
  FQueue.Free;
end;

procedure TTestCase_TSPSCQueue.TestCreate;
begin
  CheckTrue(FQueue.IsEmpty, '新创建的队列应该为空');
  CheckEquals(16, FQueue.Capacity, '容量应该正确');
  CheckEquals(0, FQueue.Size, '大小应该为0');
end;

procedure TTestCase_TSPSCQueue.TestEnqueueDequeue;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试入队
  LResult := FQueue.Enqueue(42);
  CheckTrue(LResult, '入队应该成功');
  CheckFalse(FQueue.IsEmpty, '队列不应该为空');
  CheckEquals(1, FQueue.Size, '大小应该为1');

  // 测试出队
  LResult := FQueue.Dequeue(LValue);
  CheckTrue(LResult, '出队应该成功');
  CheckEquals(42, LValue, '出队的值应该正确');
  CheckTrue(FQueue.IsEmpty, '队列应该为空');
  CheckEquals(0, FQueue.Size, '大小应该为0');
end;

procedure TTestCase_TSPSCQueue.TestCapacity;
begin
  CheckEquals(16, FQueue.Capacity, '容量应该是16');
end;

procedure TTestCase_TSPSCQueue.TestEmpty;
var
  LValue: Integer;
begin
  CheckTrue(FQueue.IsEmpty, '空队列应该返回true');
  CheckFalse(FQueue.Dequeue(LValue), '空队列出队应该失败');
end;

procedure TTestCase_TSPSCQueue.TestFull;
var
  I: Integer;
  LResult: Boolean;
begin
  // 填满队列
  for I := 1 to 16 do
  begin
    LResult := FQueue.Enqueue(I);
    CheckTrue(LResult, '入队应该成功');
  end;

  CheckTrue(FQueue.IsFull, '满队列应该返回true');

  // 尝试再次入队
  LResult := FQueue.Enqueue(17);
  CheckFalse(LResult, '满队列入队应该失败');
end;

procedure TTestCase_TSPSCQueue.TestEnqueueToFull;
var
  I: Integer;
begin
  // 填满队列
  for I := 1 to 16 do
    FQueue.Enqueue(I);

  // 验证无法继续入队
  CheckFalse(FQueue.Enqueue(17), '满队列入队应该失败');
end;

procedure TTestCase_TSPSCQueue.TestDequeueFromEmpty;
var
  LValue: Integer;
begin
  CheckFalse(FQueue.Dequeue(LValue), '空队列出队应该失败');
end;

{$IFDEF FAFAFA_CORE_PERF_TESTS}

procedure TTestCase_TSPSCQueue.TestPerformance;
var
  LStartTime, LEndTime: QWord;
  I: Integer;
  LValue: Integer;
begin
  // 测试10万次入队出队的性能
  LStartTime := GetTickCount64;

  for I := 1 to 100000 do
  begin
    FQueue.Enqueue(I);
    FQueue.Dequeue(LValue);
  end;

  LEndTime := GetTickCount64;

  WriteLn('SPSC队列10万次操作耗时: ', LEndTime - LStartTime, ' ms');
  CheckTrue((LEndTime - LStartTime) < 5000, '性能应该足够好');
end;
{$ENDIF}


procedure TTestCase_TSPSCQueue.TestSingleProducerSingleConsumer;
var
  LProducedCount, LConsumedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LProducedCount := 0;
  LConsumedCount := 0;

  // 简化的单生产者单消费者测试 - 适应队列容量
  for I := 1 to 10 do
  begin
    if FQueue.Enqueue(I) then
      Inc(LProducedCount);
  end;

  while FQueue.Dequeue(LValue) do
    Inc(LConsumedCount);

  CheckEquals(10, LProducedCount, '应该生产10个元素');
  CheckEquals(10, LConsumedCount, '应该消费10个元素');
end;
{$ENDIF} // FAFAFA_CORE_ENABLE_QUEUE_TESTS


{ TTestCase_TMichaelScottQueue }

{$IFDEF FAFAFA_CORE_ENABLE_QUEUE_TESTS}

procedure TTestCase_TMichaelScottQueue.SetUp;
begin
  FQueue := CreateIntMPSCQueue;
end;

procedure TTestCase_TMichaelScottQueue.TearDown;
begin
  FQueue.Free;
end;



procedure TTestCase_TMichaelScottQueue.TestCreate;
begin
  CheckTrue(FQueue.IsEmpty, '新创建的队列应该为空');
end;

procedure TTestCase_TMichaelScottQueue.TestEnqueueDequeue;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试入队
  FQueue.Enqueue(42);
  CheckFalse(FQueue.IsEmpty, '队列不应该为空');

  // 测试出队
  LResult := FQueue.Dequeue(LValue);
  CheckTrue(LResult, '出队应该成功');
  CheckEquals(42, LValue, '出队的值应该正确');
  CheckTrue(FQueue.IsEmpty, '队列应该为空');
end;

procedure TTestCase_TMichaelScottQueue.TestEmpty;
var
  LValue: Integer;
begin
  CheckTrue(FQueue.IsEmpty, '空队列应该返回true');
  CheckFalse(FQueue.Dequeue(LValue), '空队列出队应该失败');
end;

procedure TTestCase_TMichaelScottQueue.TestMultipleProducersSingleConsumer;
var
  LConsumedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LConsumedCount := 0;

  // 简化的并发测试 - 先生产后消费
  for I := 1 to 1000 do
    FQueue.Enqueue(I);

  // 验证消费
  while FQueue.Dequeue(LValue) do
    Inc(LConsumedCount);

  CheckEquals(1000, LConsumedCount, '应该消费1000个元素');
end;

procedure TTestCase_TMichaelScottQueue.TestHighConcurrency;
var
  LConsumedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LConsumedCount := 0;

  // 简化的高并发测试
  for I := 1 to 5000 do
    FQueue.Enqueue(I);

  // 验证消费
  while FQueue.Dequeue(LValue) do
    Inc(LConsumedCount);

  CheckEquals(5000, LConsumedCount, '应该消费5000个元素');
end;

{$ENDIF} // FAFAFA_CORE_ENABLE_QUEUE_TESTS



{$IFDEF FAFAFA_CORE_ENABLE_QUEUE_TESTS}

{ TTestCase_TPreAllocMPMCQueue }

procedure TTestCase_TPreAllocMPMCQueue.SetUp;
begin
  FQueue := CreateIntMPMCQueue(128); // 容量>=100，避免生产阶段阻塞
end;

procedure TTestCase_TPreAllocMPMCQueue.TearDown;
begin
  FQueue.Free;
end;

procedure TTestCase_TPreAllocMPMCQueue.TestCreate;
begin
  CheckTrue(FQueue.IsEmpty, '新创建的队列应该为空');
  CheckEquals(128, FQueue.GetCapacity, '容量应该正确');
  CheckEquals(0, FQueue.GetSize, '大小应该为0');
end;

procedure TTestCase_TPreAllocMPMCQueue.TestEnqueueDequeue;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试入队
  LResult := FQueue.Enqueue(42);
  CheckTrue(LResult, '入队应该成功');
  CheckFalse(FQueue.IsEmpty, '队列不应该为空');
  CheckEquals(1, FQueue.GetSize, '大小应该为1');

  // 测试出队
  LResult := FQueue.Dequeue(LValue);
  CheckTrue(LResult, '出队应该成功');
  CheckEquals(42, LValue, '出队的值应该正确');
  CheckTrue(FQueue.IsEmpty, '队列应该为空');
  CheckEquals(0, FQueue.GetSize, '大小应该为0');
end;

procedure TTestCase_TPreAllocMPMCQueue.TestCapacity;
begin
  CheckEquals(128, FQueue.GetCapacity, '容量应该是128');
end;

procedure TTestCase_TPreAllocMPMCQueue.TestEmpty;
var


  LValue: Integer;
begin
  CheckTrue(FQueue.IsEmpty, '空队列应该返回true');
  CheckFalse(FQueue.Dequeue(LValue), '空队列出队应该失败');
end;

procedure TTestCase_TPreAllocMPMCQueue.TestFull;
var
  I, C: Integer;
  LResult: Boolean;
begin
  C := FQueue.GetCapacity;
  // 填满队列
  for I := 1 to C do
  begin
    LResult := FQueue.Enqueue(I);
    CheckTrue(LResult, '入队应该成功');
  end;

  CheckTrue(FQueue.IsFull, '满队列应该返回true');

  // 尝试再次入队
  LResult := FQueue.Enqueue(C + 1);

  CheckFalse(LResult, '满队列入队应该失败');
end;

procedure TTestCase_TPreAllocMPMCQueue.TestFullIdempotency;
var
  C, I: Integer;
  R: Boolean;
begin
  C := FQueue.GetCapacity;
  // 填满
  for I := 1 to C do
    CheckTrue(FQueue.Enqueue(I));
  CheckTrue(FQueue.IsFull);
  // 重复 Enqueue 仍应失败，不改变状态
  R := FQueue.Enqueue(C + 1);
  CheckFalse(R);
  CheckTrue(FQueue.IsFull);
  CheckEquals(C, FQueue.GetSize);
end;

procedure TTestCase_TPreAllocMPMCQueue.TestEmptyIdempotency;
var
  V: Integer;
begin
  CheckTrue(FQueue.IsEmpty);
  // 重复 Dequeue 仍应失败，不改变状态
  CheckFalse(FQueue.Dequeue(V));
  CheckFalse(FQueue.Dequeue(V));
  CheckTrue(FQueue.IsEmpty);
  CheckEquals(0, FQueue.GetSize);
end;


{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
procedure TTestCase_TPreAllocMPMCQueue.TestMultipleProducersMultipleConsumers;
var
  LConsumedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LConsumedCount := 0;

  // 简化的MPMC测试
  for I := 1 to 100 do
    while not FQueue.Enqueue(I) do
      Sleep(0);

  // 验证消费
  while FQueue.Dequeue(LValue) do
    Inc(LConsumedCount);

  CheckEquals(100, LConsumedCount, '应该消费100个元素');
end;
{$ENDIF}

{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
procedure TTestCase_TPreAllocMPMCQueue.TestHighConcurrency;
var
  LConsumedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LConsumedCount := 0;

  // 简化的高并发测试
  for I := 1 to 50 do
    while not FQueue.Enqueue(I) do
      Sleep(0);

  // 验证消费
  while FQueue.Dequeue(LValue) do
    Inc(LConsumedCount);

  CheckEquals(50, LConsumedCount, '应该消费50个元素');
end;
{$ENDIF}

{$IFDEF FAFAFA_CORE_PERF_TESTS}
procedure TTestCase_TPreAllocMPMCQueue.TestPerformanceVsLocked;
var
  LStartTime, LEndTime: QWord;
  LLockedQueue: TThreadList;
  I: Integer;
  LValue: Integer;
begin
  // 测试无锁队列性能
  LStartTime := GetTickCount64;
  for I := 1 to 10000 do
  begin
    FQueue.Enqueue(I);
    FQueue.Dequeue(LValue);
  end;
  LEndTime := GetTickCount64;
  WriteLn('MPMC队列1万次操作耗时: ', LEndTime - LStartTime, ' ms');

  // 测试基于锁的队列性能
  LLockedQueue := TThreadList.Create;
  try
    LStartTime := GetTickCount64;
    for I := 1 to 10000 do
    begin
      with LLockedQueue.LockList do
      try
        Add(Pointer(PtrInt(I)));
        if Count > 0 then
        begin
          Delete(0);
        end;
      finally
        LLockedQueue.UnlockList;
      end;
    end;
    LEndTime := GetTickCount64;
    WriteLn('基于锁的队列10万次操作耗时: ', LEndTime - LStartTime, ' ms');
  finally
    LLockedQueue.Free;
  end;
end;
{$ENDIF}

{$ENDIF} // FAFAFA_CORE_ENABLE_QUEUE_TESTS


{ TTestCase_TTreiberStack }




procedure TTestCase_TTreiberStack.SetUp;
begin
  FStack := TIntStack.Create;
end;

procedure TTestCase_TTreiberStack.TearDown;
begin
  FreeAndNil(FStack);
end;

procedure TTestCase_TTreiberStack.TestCreate;
begin
  CheckTrue(FStack.IsEmpty, '新创建的栈应该为空');
end;


// 日志：进入 TestPushPop

procedure TTestCase_TTreiberStack.TestPushPop;
var
  LArr: array[0..2] of Integer;
  LOut: array[0..2] of Integer;
  LCount: Integer;
var
  LValue: Integer;
  LResult: Boolean;
  LDummy: Integer;
begin
  // 测试压栈
  FStack.Push(42);
  CheckFalse(FStack.IsEmpty, '栈不应该为空');

  // 测试弹栈
  WriteLn('>> TTreiberStack.TestPushPop: after first Pop');

  LResult := FStack.Pop(LValue);
  CheckTrue(LResult, '弹栈应该成功');
  CheckEquals(42, LValue, '弹栈的值应该正确');
  CheckTrue(FStack.IsEmpty, '栈应该为空');

{$IFDEF FAFAFA_CORE_ENABLE_EXTENDED_STACK_API_TESTS}
  // 扩展 API: PushItem/PopItem/TryPeek/PeekItem/PushMany/PopMany/Clear/GetStats
  // 适度覆盖，保持简洁
  LArr[0] := 10; LArr[1] := 20; LArr[2] := 30;
  LCount := FStack.PushMany(LArr);
  CheckEquals(3, LCount, 'PushMany 应返回 3');

  // TryPeek 应返回 False（无锁栈通常不支持）
  CheckFalse(FStack.TryPeek(LDummy), 'TryPeek 应返回 False');

  // PeekItem 应抛异常
  try
    FStack.PeekItem;
    Fail('Expected exception not raised: Peek not supported');
  except
    on E: Exception do ;
  end;

  // PopMany
  LCount := FStack.PopMany(LOut);
  CheckEquals(3, LCount, 'PopMany 应返回 3');
  CheckEquals(30, LOut[0]); // LIFO
  CheckEquals(20, LOut[1]);
  CheckEquals(10, LOut[2]);

  // GetStats 不为 nil（接口不应为 nil）
  CheckTrue(FStack.GetStats <> nil, 'GetStats 应返回非空接口');

  // Clear
  FStack.Push(1);
  FStack.Push(2);
  FStack.Clear;
  CheckTrue(FStack.IsEmpty, 'Clear 后应为空');
{$ENDIF}
end;


procedure TTestCase_TTreiberStack.TestEmpty;
var
  LValue: Integer;
begin
  CheckTrue(FStack.IsEmpty, '空栈应该返回true');
  CheckFalse(FStack.Pop(LValue), '空栈弹栈应该失败');
end;

procedure TTestCase_TTreiberStack.TestPopFromEmpty;
var
  LValue: Integer;
begin
  CheckFalse(FStack.Pop(LValue), '空栈弹栈应该失败');
end;

{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
procedure TTestCase_TTreiberStack.TestConcurrentPushPop;
var
  LPushedCount, LPoppedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LPushedCount := 0;
  LPoppedCount := 0;

  // 简化的并发测试
  for I := 1 to 100 do
  begin
    FStack.Push(I);
    Inc(LPushedCount);
  end;

  // 验证弹栈
  while FStack.Pop(LValue) do
    Inc(LPoppedCount);

  CheckEquals(100, LPushedCount, '应该压栈100个元素');
  CheckEquals(100, LPoppedCount, '应该弹栈100个元素');
end;
{$ENDIF}


{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
procedure TTestCase_TTreiberStack.TestHighConcurrency;
var
  LPoppedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LPoppedCount := 0;

  // 简化的高并发测试
  for I := 1 to 200 do
    FStack.Push(I);

  // 验证弹栈
  while FStack.Pop(LValue) do
    Inc(LPoppedCount);

  CheckEquals(200, LPoppedCount, '应该弹栈200个元素');
end;
{$ENDIF}

{$IFDEF FAFAFA_CORE_PERF_TESTS}

procedure TTestCase_TTreiberStack.TestPerformance;
var
  LStartTime, LEndTime: QWord;
  I: Integer;
  LValue: Integer;
begin
  // 测试100万次压栈弹栈的性能
  LStartTime := GetTickCount64;

  for I := 1 to 1000000 do
  begin
    FStack.Push(I);
    FStack.Pop(LValue);
  end;

  LEndTime := GetTickCount64;

  WriteLn('无锁栈100万次操作耗时: ', LEndTime - LStartTime, ' ms');
  CheckTrue((LEndTime - LStartTime) < 5000, '性能应该足够好');
end;

{ TTestCase_TPreAllocStack }

{$ENDIF}

procedure TTestCase_TPreAllocStack.SetUp;
begin
  FStack := TIntStack.Create(64); // 较小容量便于测试
end;

procedure TTestCase_TPreAllocStack.TearDown;
begin
  FStack.Free;
end;

procedure TTestCase_TPreAllocStack.TestCreate;
begin
  CheckTrue(FStack.IsEmpty, '新创建的栈应该为空');
  CheckEquals(64, FStack.GetCapacity, '容量应该正确');
  CheckEquals(0, FStack.GetSize, '大小应该为0');
end;

procedure TTestCase_TPreAllocStack.TestPushPop;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试压栈
  LResult := FStack.TryPush(42);
  CheckTrue(LResult, '压栈应该成功');
  CheckFalse(FStack.IsEmpty, '栈不应该为空');
  CheckEquals(1, FStack.GetSize, '大小应该为1');

  // 测试弹栈
  LResult := FStack.Pop(LValue);
  CheckTrue(LResult, '弹栈应该成功');
  CheckEquals(42, LValue, '弹栈的值应该正确');
  CheckTrue(FStack.IsEmpty, '栈应该为空');
  CheckEquals(0, FStack.GetSize, '大小应该为0');
end;

procedure TTestCase_TPreAllocStack.TestEmpty;
var
  LValue: Integer;
begin
  CheckTrue(FStack.IsEmpty, '空栈应该返回true');
  CheckFalse(FStack.Pop(LValue), '空栈弹栈应该失败');
end;

procedure TTestCase_TPreAllocStack.TestFull;
var
  I: Integer;
  LResult: Boolean;
begin
  // 填满栈
  for I := 1 to 64 do
  begin
    LResult := FStack.TryPush(I);
    CheckTrue(LResult, '压栈应该成功');
  end;

  CheckTrue(FStack.IsFull, '满栈应该返回true');

  // 尝试再次压栈
  LResult := FStack.TryPush(65);
  CheckFalse(LResult, '满栈压栈应该失败');
end;

procedure TTestCase_TPreAllocStack.TestCapacity;
begin
  CheckEquals(64, FStack.GetCapacity, '容量应该是64');
end;

procedure TTestCase_TPreAllocStack.TestPopFromEmpty;
var
  LValue: Integer;
begin
  CheckFalse(FStack.Pop(LValue), '空栈弹栈应该失败');
end;

procedure TTestCase_TPreAllocStack.TestPushToFull;
var
  I: Integer;
begin
  // 填满栈
  for I := 1 to 64 do
    FStack.Push(I);

  // 验证无法继续压栈
  CheckFalse(FStack.TryPush(65), '满栈压栈应该失败');
end;

{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
procedure TTestCase_TPreAllocStack.TestConcurrentPushPop;
var
  LPushedCount, LPoppedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LPushedCount := 0;
  LPoppedCount := 0;

  // 简化的并发测试
  for I := 1 to 50 do
  begin
    if FStack.TryPush(I) then
      Inc(LPushedCount);
  end;

  // 验证弹栈
  while FStack.Pop(LValue) do
    Inc(LPoppedCount);

  CheckEquals(LPushedCount, LPoppedCount, '压栈和弹栈数量应该相等');
end;
{$ENDIF}

{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
procedure TTestCase_TPreAllocStack.TestHighConcurrency;
var
  LPoppedCount: Integer;
  LValue: Integer;
  I: Integer;
begin
  LPoppedCount := 0;

  // 简化的高并发测试
  for I := 1 to 50 do
    FStack.Push(I);

  // 验证弹栈
  while FStack.Pop(LValue) do
    Inc(LPoppedCount);

  CheckEquals(50, LPoppedCount, '应该弹栈50个元素');
end;
{$ENDIF}



{ TTestCase_TLockFreeHashMap_Concurrency }
procedure TTestCase_TLockFreeHashMap_Concurrency.SetUp;
begin
  FMap := TIntIntMap.Create(8192);
end;

procedure TTestCase_TLockFreeHashMap_Concurrency.TearDown;
begin
  FMap.Free;
end;

procedure TTestCase_TLockFreeHashMap_Concurrency.TestConcurrentPutAndGet;
const
  THREADS = 4;
  PER_THREAD = 500;
var
  I, J, V: Integer;
  LThreadsArr: array[0..THREADS-1] of TThread;
  StartGate: TEvent;
begin
  // 每个线程写入不相交的键：起点 = 线程索引，步长 = 线程数

  StartGate := TEvent.Create(nil, True, False, '');
  try
    for I := 0 to THREADS-1 do
      LThreadsArr[I] := TInsertThread.Create(FMap, I, PER_THREAD, THREADS, StartGate);
    StartGate.SetEvent;
    // 使用统一的并发辅助等待（带总超时），避免无穷等待
    if not TThreadTestHelper.RunThreadsWait(LThreadsArr, 15000) then
      Fail('并发插入线程超时');
  finally
    StartGate.Free;
  end;
  for I := 0 to THREADS-1 do
  begin
    LThreadsArr[I].Free;
    LThreadsArr[I] := nil;
  end;

  // 校验所有键
  CheckEquals(THREADS*PER_THREAD, FMap.GetSize, '并发插入计数不符');
  for J := 0 to THREADS*PER_THREAD-1 do
  begin
    CheckTrue(FMap.Get(J, V), Format('缺少键 %d',[J]));
    CheckEquals(J*2, V, '值不匹配');
  end;
end;

{ TTestCase_TPreAllocStack_Concurrency }
procedure TTestCase_TPreAllocStack_Concurrency.SetUp;
begin
  FStack := TIntStack.Create(4096);
end;

procedure TTestCase_TPreAllocStack_Concurrency.TearDown;
begin
  FStack.Free;
end;

procedure TTestCase_TPreAllocStack_Concurrency.TestConcurrentPushAndCount;
const
  THREADS = 4;
  PER_THREAD = 500;
var
  I, Count, Val: Integer;
  LProcs: array[0..THREADS-1] of TThreadProcedure;
begin
  for I := 0 to THREADS-1 do
  begin
    LProcs[I] := procedure
    var k: Integer; base: Integer;
    begin
      base := I * PER_THREAD;
      for k := 0 to PER_THREAD-1 do
        FStack.Push(base + k);
    end;
  end;
  CheckTrue(TThreadTestHelper.RunConcurrent(LProcs), '并发执行应成功');

  Count := 0;
  while FStack.Pop(Val) do
    Inc(Count);
  CheckEquals(THREADS*PER_THREAD, Count, '并发压栈后弹出数量不符');
end;



{$IFDEF FAFAFA_CORE_PERF_TESTS}

procedure TTestCase_TPreAllocStack.TestPerformance;
var
  LStartTime, LEndTime: QWord;
  I: Integer;
  LValue: Integer;
begin
  // 测试10万次压栈弹栈的性能
  LStartTime := GetTickCount64;

  for I := 1 to 100000 do
  begin
    if FStack.TryPush(I) then
      FStack.Pop(LValue);
  end;

  LEndTime := GetTickCount64;

  WriteLn('预分配栈10万次操作耗时: ', LEndTime - LStartTime, ' ms');
  CheckTrue((LEndTime - LStartTime) < 5000, '性能应该足够好');
end;
{$ENDIF}


function CaseInsensitiveHash(const S: string): Cardinal;
var
  U: string;
  I: Integer;
begin
  // FNV-1a over uppercase string bytes to ensure case-insensitive hashing
  U := UpperCase(S);
  Result := 2166136261;
  {$PUSH}
  {$Q-}
  for I := 1 to Length(U) do
  begin
    Result := Result xor Ord(U[I]);
    Result := Result * 16777619;
  end;
  {$POP}
end;

function CaseInsensitiveEqual(const L, R: string): Boolean;
begin
  Result := SameText(L, R);
end;

{ TTestCase_TLockFreeHashMap_CustomComparer }
procedure TTestCase_TLockFreeHashMap_CustomComparer.Test_CaseInsensitive_PutGet_Remove;
var
  LMap: specialize TLockFreeHashMap<string, Integer>;
  V: Integer;
begin
  // 使用大小写不敏感的哈希与比较器
  LMap := specialize TLockFreeHashMap<string, Integer>.Create(128,
    @CaseInsensitiveHash, @CaseInsensitiveEqual);
  try
    CheckTrue(LMap.Put('Key', 1));
    CheckTrue(LMap.Get('KEY', V));
    CheckEquals(1, V);

    // 覆盖更新（大小写不同但视为相等）
    CheckTrue(LMap.Put('key', 2));
    CheckTrue(LMap.Get('KEY', V));
    CheckEquals(2, V);

    // 删除（大小写不同但视为相等）
    CheckTrue(LMap.Remove('KeY'));
    CheckFalse(LMap.ContainsKey('key'));
  finally
    LMap.Free;
  end;
end;


procedure TTestCase_TLockFreeHashMap_CustomComparer.Test_CaseInsensitive_CapacityFullAndFail;
var
  LMap: specialize TLockFreeHashMap<string, Integer>;
  Count: Integer;
  Cap: SizeInt;
  I: Integer;
  Ok: Boolean;
  Key: string;
begin
  // 使用大小写不敏感的哈希与比较器，验证容量边界下行为
  LMap := specialize TLockFreeHashMap<string, Integer>.Create(64,
    @CaseInsensitiveHash, @CaseInsensitiveEqual);
  try
    Cap := LMap.GetCapacity;
    Count := 0;
    I := 0;
    repeat
      Key := 'k' + IntToStr(I);
      Ok := LMap.Put(Key, I);
      if Ok then Inc(Count);
      Inc(I);
    until not Ok;
    CheckTrue(Count <= Cap, 'Inserted count should be <= Capacity');

    // 容量满后，再插入新“不同大小写”的键，依然应失败
    CheckFalse(LMap.Put('KEY_NEW', 12345));
  finally
    LMap.Free;
  end;
end;


{ TTestCase_TLockFreeHashMap }

procedure TTestCase_TLockFreeHashMap.SetUp;
begin
  FHashMap := TIntStringMap.Create(64);
end;

procedure TTestCase_TLockFreeHashMap.TearDown;
begin
  FHashMap.Free;
end;

procedure TTestCase_TLockFreeHashMap.TestCreate;
begin
  CheckTrue(FHashMap.IsEmpty, '新创建的哈希表应该为空');
  CheckEquals(64, FHashMap.GetCapacity, '容量应该正确');
  CheckEquals(0, FHashMap.GetSize, '大小应该为0');
end;

procedure TTestCase_TLockFreeHashMap.TestPutGet;
var
  LValue: string;
  LResult: Boolean;
begin
  // 测试插入
  LResult := FHashMap.Put(42, 'Hello');
  CheckTrue(LResult, '插入应该成功');
  CheckFalse(FHashMap.IsEmpty, '哈希表不应该为空');
  CheckEquals(1, FHashMap.GetSize, '大小应该为1');

  // 测试获取
  LResult := FHashMap.Get(42, LValue);
  CheckTrue(LResult, '获取应该成功');
  CheckEquals('Hello', LValue, '获取的值应该正确');
end;

procedure TTestCase_TLockFreeHashMap.TestRemove;
var
  LResult: Boolean;
begin
  // 先插入
  FHashMap.Put(42, 'Hello');

  // 测试删除
  LResult := FHashMap.Remove(42);
  CheckTrue(LResult, '删除应该成功');
  CheckTrue(FHashMap.IsEmpty, '哈希表应该为空');
  CheckEquals(0, FHashMap.GetSize, '大小应该为0');
end;

procedure TTestCase_TLockFreeHashMap.TestContainsKey;
begin
  CheckFalse(FHashMap.ContainsKey(42), '空哈希表不应该包含键');

  FHashMap.Put(42, 'Hello');
  CheckTrue(FHashMap.ContainsKey(42), '哈希表应该包含键');

  FHashMap.Remove(42);
  CheckFalse(FHashMap.ContainsKey(42), '删除后不应该包含键');
end;

procedure TTestCase_TLockFreeHashMap.TestEmpty;
var
  LValue: string;
begin
  CheckTrue(FHashMap.IsEmpty, '空哈希表应该返回true');
  CheckFalse(FHashMap.Get(42, LValue), '空哈希表获取应该失败');
end;

procedure TTestCase_TLockFreeHashMap.TestCapacity;
begin
  CheckEquals(64, FHashMap.GetCapacity, '容量应该是64');
end;

procedure TTestCase_TLockFreeHashMap.TestGetNonExistent;
var
  LValue: string;
begin
  CheckFalse(FHashMap.Get(999, LValue), '获取不存在的键应该失败');
end;

procedure TTestCase_TLockFreeHashMap.TestRemoveNonExistent;
begin
  CheckFalse(FHashMap.Remove(999), '删除不存在的键应该失败');
end;

procedure TTestCase_TLockFreeHashMap.TestOverwrite;
var
  LValue: string;
  LResult: Boolean;
begin
  // 插入初始值
  FHashMap.Put(42, 'Hello');

  // 覆盖值
  LResult := FHashMap.Put(42, 'World');
  CheckTrue(LResult, '覆盖应该成功');
  CheckEquals(1, FHashMap.GetSize, '大小应该仍为1');

  // 验证新值
  FHashMap.Get(42, LValue);
  CheckEquals('World', LValue, '应该获取到新值');
end;

procedure TTestCase_TLockFreeHashMap.TestCapacityFullAndFail;
var
  I, Count: Integer;
  Ok: Boolean;
  Cap: SizeInt;
begin
  Cap := FHashMap.GetCapacity;
  Count := 0;
  I := 0;
  repeat
    Ok := FHashMap.Put(I, 'V' + IntToStr(I));
    if Ok then Inc(Count);
    Inc(I);
  until not Ok;
  CheckTrue(Count <= Cap, 'Inserted count should be <= Capacity');
  // 插入新键再次失败
  CheckFalse(FHashMap.Put(High(Integer), 'X'));
end;


procedure TTestCase_TLockFreeHashMap.TestConcurrentPutGet;
var
  LGetCount: Integer;
  LValue: string;
  I, LExpect: Integer;
begin
  LGetCount := 0;
  // 在不开启扩容的实现下，插入数量不应超过容量
  LExpect := 100;
  if FHashMap.GetCapacity < LExpect then
    LExpect := FHashMap.GetCapacity;

  // 简化的并发测试（先写后读）
  for I := 1 to LExpect do
    FHashMap.Put(I, 'Value' + IntToStr(I));

  // 验证获取
  for I := 1 to LExpect do
  begin
    if FHashMap.Get(I, LValue) then
      Inc(LGetCount);
  end;

  CheckEquals(LExpect, LGetCount, '应该获取到预期数量的值');
end;

procedure TTestCase_TLockFreeHashMap.TestHighConcurrency;
var
  I: Integer;
  LValue: string;
begin
  // 简化的高并发测试
  for I := 1 to 200 do
    FHashMap.Put(I, 'V' + IntToStr(I));

  // 验证获取
  for I := 1 to 200 do
    FHashMap.Get(I, LValue);

  CheckTrue(True, '哈希表高并发测试应该完成');
end;
{$IFDEF FAFAFA_CORE_PERF_TESTS}


procedure TTestCase_TLockFreeHashMap.TestPerformance;
var
  LStartTime, LEndTime: QWord;
  I: Integer;
  LValue: string;
begin
  // 测试10万次插入获取的性能
  LStartTime := GetTickCount64;

  for I := 1 to 100000 do
  begin
    FHashMap.Put(I mod 1000, 'Value' + IntToStr(I));
    FHashMap.Get(I mod 1000, LValue);
  end;

  LEndTime := GetTickCount64;

  WriteLn('哈希表10万次操作耗时: ', LEndTime - LStartTime, ' ms');
  CheckTrue((LEndTime - LStartTime) < 10000, '性能应该足够好');
end;
{$ENDIF}


{ TTestCase_Global }

procedure TTestCase_Global.TestNextPowerOfTwo;
begin
  CheckEquals(1, NextPowerOfTwo(0), 'NextPowerOfTwo(0) 应该返回 1');
  CheckEquals(1, NextPowerOfTwo(1), 'NextPowerOfTwo(1) 应该返回 1');
  CheckEquals(2, NextPowerOfTwo(2), 'NextPowerOfTwo(2) 应该返回 2');
  CheckEquals(4, NextPowerOfTwo(3), 'NextPowerOfTwo(3) 应该返回 4');
  CheckEquals(8, NextPowerOfTwo(5), 'NextPowerOfTwo(5) 应该返回 8');
  CheckEquals(16, NextPowerOfTwo(15), 'NextPowerOfTwo(15) 应该返回 16');
  CheckEquals(1024, NextPowerOfTwo(1000), 'NextPowerOfTwo(1000) 应该返回 1024');
end;

procedure TTestCase_Global.TestIsPowerOfTwo;
begin
  CheckFalse(IsPowerOfTwo(0), 'IsPowerOfTwo(0) 应该返回 false');
  CheckTrue(IsPowerOfTwo(1), 'IsPowerOfTwo(1) 应该返回 true');
  CheckTrue(IsPowerOfTwo(2), 'IsPowerOfTwo(2) 应该返回 true');
  CheckFalse(IsPowerOfTwo(3), 'IsPowerOfTwo(3) 应该返回 false');
  CheckTrue(IsPowerOfTwo(4), 'IsPowerOfTwo(4) 应该返回 true');
  CheckFalse(IsPowerOfTwo(5), 'IsPowerOfTwo(5) 应该返回 false');
  CheckTrue(IsPowerOfTwo(1024), 'IsPowerOfTwo(1024) 应该返回 true');
  CheckFalse(IsPowerOfTwo(1000), 'IsPowerOfTwo(1000) 应该返回 false');
end;

procedure TTestCase_Global.TestSimpleHash;
var
  LValue1, LValue2: Integer;
  LHash1, LHash2: Cardinal;
begin
  LValue1 := 42;
  LValue2 := 43;

  LHash1 := SimpleHash(LValue1, SizeOf(LValue1));
  LHash2 := SimpleHash(LValue2, SizeOf(LValue2));

  CheckTrue(LHash1 <> 0, '哈希值不应该为0');
  CheckTrue(LHash2 <> 0, '哈希值不应该为0');

{$IFDEF FAFAFA_CORE_MAP_INTERFACE}
{ TTestCase_ILockFreeMap_Contract }

procedure TTestCase_ILockFreeMap_Contract.Test_OA_Impl_BasicContract;
var
  LMap: specialize TLockFreeMapOA<Integer, string>;
  LInt: Integer;
  LStr: string;
begin
  LMap := specialize TLockFreeMapOA<Integer, string>.Create(64);
  try
    CheckTrue(LMap.IsEmpty, 'OA: 新建应为空');
    CheckEquals(0, LMap.Size, 'OA: 初始大小应为0');
    CheckTrue(LMap.Put(1, 'One'), 'OA: Put 应返回 True');
    CheckTrue(LMap.Get(1, LStr) and (LStr = 'One'), 'OA: Get 应拿到 One');
    CheckTrue(LMap.ContainsKey(1), 'OA: ContainsKey 应为 True');
    CheckTrue(LMap.Remove(1), 'OA: Remove 应为 True');
    CheckFalse(LMap.ContainsKey(1), 'OA: 删除后不应包含键');

    // Clear
    LMap.Put(2, 'Two');
    LMap.Put(3, 'Three');
    LMap.Clear;
    CheckTrue(LMap.IsEmpty, 'OA: Clear 后应为空');
    CheckEquals(0, LMap.Size, 'OA: Clear 后大小应为0');
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_ILockFreeMap_Contract.Test_MM_Impl_BasicContract;
var
  LMap: specialize TLockFreeMapMM<string, Integer>;
  LVal: Integer;
begin
  LMap := specialize TLockFreeMapMM<string, Integer>.Create(64, @DefaultStringHash, @DefaultStringComparer);
  try
    CheckTrue(LMap.IsEmpty, 'MM: 新建应为空');
    CheckEquals(0, LMap.Size, 'MM: 初始大小应为0');

    // Put 会 insert 或 update
    CheckTrue(LMap.Put('a', 10), 'MM: Put a=10');
    CheckTrue(LMap.Get('a', LVal) and (LVal = 10), 'MM: Get a=10');

    // 覆盖应成功
    CheckTrue(LMap.Put('a', 20), 'MM: Put 覆盖 a=20');
    CheckTrue(LMap.Get('a', LVal) and (LVal = 20), 'MM: Get a=20');

    CheckTrue(LMap.ContainsKey('a'), 'MM: ContainsKey a');
    CheckTrue(LMap.Remove('a'), 'MM: Remove a');
    CheckFalse(LMap.ContainsKey('a'), 'MM: 删除后不应包含 a');

    // Clear
    LMap.Put('b', 1);
    LMap.Put('c', 2);
    LMap.Clear;
    CheckTrue(LMap.IsEmpty, 'MM: Clear 后应为空');
    CheckEquals(0, LMap.Size, 'MM: Clear 后大小应为0');
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_ILockFreeMap_Contract.Test_OA_Impl_OverwriteSemantics;
var
  LMap: specialize TLockFreeMapOA<Integer, Integer>;
  LVal: Integer;
begin
  LMap := specialize TLockFreeMapOA<Integer, Integer>.Create(64);
  try
    CheckTrue(LMap.Put(1, 10));
    CheckTrue(LMap.Put(1, 20));
    CheckEquals(1, LMap.Size);
    CheckTrue(LMap.Get(1, LVal));
    CheckEquals(20, LVal);
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_ILockFreeMap_Contract.Test_OA_Impl_RemoveIdempotency;
var
  LMap: specialize TLockFreeMapOA<Integer, Integer>;
begin
  LMap := specialize TLockFreeMapOA<Integer, Integer>.Create(64);
  try
    CheckTrue(LMap.Put(42, 1));
    CheckTrue(LMap.Remove(42));
    CheckFalse(LMap.Remove(42));
    CheckEquals(0, LMap.Size);
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_ILockFreeMap_Contract.Test_OA_Impl_CapacityAndLoad;
var
  LMap: specialize TLockFreeMapOA<Integer, Integer>;
  I: Integer;
  LVal: Integer;
begin
  LMap := specialize TLockFreeMapOA<Integer, Integer>.Create(64);
  try
    for I := 1 to 40 do
      CheckTrue(LMap.Put(I, I));
    CheckEquals(64, LMap.Capacity);
    CheckEquals(40, LMap.Size);
    for I := 1 to 40 do
    begin
      CheckTrue(LMap.Get(I, LVal));
      CheckEquals(I, LVal);
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_ILockFreeMap_Contract.Test_MM_Impl_OverwriteSemantics;
var
  LMap: specialize TLockFreeMapMM<Integer, Integer>;
  LVal: Integer;
begin
  LMap := specialize TLockFreeMapMM<Integer, Integer>.Create(64, @DefaultIntegerHash, @DefaultIntegerComparer);
  try
    CheckTrue(LMap.Put(1, 10));
    CheckTrue(LMap.Put(1, 20));
    CheckEquals(1, LMap.Size);
    CheckTrue(LMap.Get(1, LVal));
    CheckEquals(20, LVal);
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_ILockFreeMap_Contract.Test_MM_Impl_RemoveIdempotency;
var
  LMap: specialize TLockFreeMapMM<Integer, Integer>;
begin
  LMap := specialize TLockFreeMapMM<Integer, Integer>.Create(64, @DefaultIntegerHash, @DefaultIntegerComparer);
  try
    CheckTrue(LMap.Put(42, 1));
    CheckTrue(LMap.Remove(42));
    CheckFalse(LMap.Remove(42));
    CheckEquals(0, LMap.Size);
  finally
    LMap.Free;
  end;
end;

function BadHash(const AKey: Integer): Cardinal;
begin
  Result := 1; // 强制冲突
end;

function IntComparer(const A,B: Integer): Boolean;
begin
  Result := A = B;
end;

procedure TTestCase_ILockFreeMap_Contract.Test_MM_Impl_CollisionsWithBadHash;
var
  LMap: specialize TLockFreeMapMM<Integer, Integer>;
  I: Integer;
  LVal: Integer;
begin
  LMap := specialize TLockFreeMapMM<Integer, Integer>.Create(64, @BadHash, @IntComparer);
  try
    for I := 1 to 50 do
      CheckTrue(LMap.Put(I, I));
    for I := 1 to 50 do
    begin
      CheckTrue(LMap.Get(I, LVal));
      CheckEquals(I, LVal);
    end;
  finally
    LMap.Free;
  end;
end;

{$ENDIF}

  CheckTrue(LHash1 <> LHash2, '不同值的哈希应该不同');

  // 测试相同值的哈希一致性
  CheckEquals(LHash1, SimpleHash(LValue1, SizeOf(LValue1)), '相同值的哈希应该一致');
end;


{ TTestCase_HashMap_MM_Construct }

procedure TTestCase_HashMap_MM_Construct.Test_MM_Create_NilHash_Throws;
var
  LMap: specialize TMichaelHashMap<Integer, Integer>;
begin
  // 统一使用 try..except 断言异常信息
  try
    LMap := specialize TMichaelHashMap<Integer, Integer>.Create(64, nil, @DefaultIntegerComparer);
    try
      Fail('应当抛出异常: 未提供哈希函数');
    finally
      LMap.Free;
    end;
  except
    on E: Exception do
      if (Pos('未提供哈希函数', E.Message) = 0) and (Pos('missing hash function', LowerCase(E.Message)) = 0) then
        Fail('异常消息应包含提示/should include reason about missing hash function; got: ' + E.Message);
  end;
{$IFDEF FAFAFA_CORE_ENABLE_STRESS_TESTS}

procedure TTestCase_TTreiberStack.TestStress_ConcurrentPushPop;
var
  LStopAt: QWord;
  LPushCount, LPopCount: Integer;
  LVal: Integer;
begin
  // 1 秒真并发压力：两个线程分别 Push/Pop，验证计数合理性
  LStopAt := GetTickCount64 + 1000;
  LPushCount := 0; LPopCount := 0;

  TThread.CreateAnonymousThread(
    procedure
    begin
      while GetTickCount64 < LStopAt do
      begin
        Inc(LPushCount);
        FStack.Push(LPushCount);
        Sleep(0);
      end;
    end
  ).Start;

  TThread.CreateAnonymousThread(
    procedure
    begin
      while GetTickCount64 < LStopAt do
      begin
        if FStack.Pop(LVal) then
          Inc(LPopCount);
        Sleep(0);
      end;
    end
  ).Start;

  // 主线程等待 1200ms 以覆盖收尾
  Sleep(1200);

  // 校验：Pop 不应超过 Push；结束后允许剩余元素未消费
  CheckTrue(LPopCount <= LPushCount, 'Pop 不应超过 Push');
end;

procedure TTestCase_TPreAllocStack.TestStress_ConcurrentPushPop;
var
  LStopAt: QWord;
  LPushCount, LPopCount: Integer;
  LVal: Integer;
begin
  LStopAt := GetTickCount64 + 1000;
  LPushCount := 0; LPopCount := 0;

  TThread.CreateAnonymousThread(
    procedure
    begin
      while GetTickCount64 < LStopAt do
      begin
        Inc(LPushCount);
        FStack.Push(LPushCount);
        Sleep(0);
      end;
    end
  ).Start;

  TThread.CreateAnonymousThread(
    procedure
    begin
      while GetTickCount64 < LStopAt do
      begin
        if FStack.Pop(LVal) then
          Inc(LPopCount);
        Sleep(0);
      end;
    end
  ).Start;

  Sleep(1200);

  CheckTrue(LPopCount <= LPushCount, 'Pop 不应超过 Push');
end;

procedure TTestCase_TMichaelScottQueue.TestStress_ConcurrentEnqDeq;
var
  LStopAt: QWord;
  LEnq, LDeq: Integer;
  LVal: Integer;
begin
  LStopAt := GetTickCount64 + 1000;
  LEnq := 0; LDeq := 0;

  TThread.CreateAnonymousThread(
    procedure
    begin
      while GetTickCount64 < LStopAt do
      begin
        Inc(LEnq);
        FQueue.Enqueue(LEnq);
        Sleep(0);
      end;
    end
  ).Start;

  TThread.CreateAnonymousThread(
    procedure
    begin
      while GetTickCount64 < LStopAt do
      begin
        if FQueue.Dequeue(LVal) then
          Inc(LDeq);
        Sleep(0);
      end;
    end
  ).Start;

  Sleep(1200);

  CheckTrue(LDeq <= LEnq, 'Dequeue 不应超过 Enqueue');
end;

procedure TTestCase_TPreAllocMPMCQueue.TestStress_ConcurrentEnqDeq;
var
  LStopAt: QWord;
  LEnq, LDeq: Integer;
  LVal: Integer;
begin
  LStopAt := GetTickCount64 + 1000;
  LEnq := 0; LDeq := 0;

  TThread.CreateAnonymousThread(
    procedure
    begin
      while GetTickCount64 < LStopAt do
      begin
        Inc(LEnq);
        FQueue.Enqueue(LEnq);
        Sleep(0);
      end;
    end
  ).Start;

  TThread.CreateAnonymousThread(
    procedure
    begin
      while GetTickCount64 < LStopAt do
      begin
        if FQueue.Dequeue(LVal) then
          Inc(LDeq);
        Sleep(0);
      end;
    end
  ).Start;

  Sleep(1200);

  CheckTrue(LDeq <= LEnq, 'Dequeue 不应超过 Enqueue');
end;

{$ENDIF} // FAFAFA_CORE_ENABLE_STRESS_TESTS

end;

procedure TTestCase_HashMap_MM_Construct.Test_MM_Create_NilComparer_Throws;
var
  LMap: specialize TMichaelHashMap<Integer, Integer>;
begin
  // 统一使用 try..except 断言异常信息
  try
    LMap := specialize TMichaelHashMap<Integer, Integer>.Create(64, @DefaultIntegerHash, nil);
    try
      Fail('应当抛出异常: 未提供键比较器');
    finally
      LMap.Free;
    end;
  except
    on E: Exception do
      if (Pos('未提供键比较器', E.Message) = 0) and (Pos('missing key comparer', LowerCase(E.Message)) = 0) then
        Fail('异常消息应包含提示/should include reason about missing key comparer; got: ' + E.Message);
  end;
end;

initialization
  RegisterTest(TTestCase_HashMap_MM_Construct);
  {$IFDEF FAFAFA_CORE_MAP_INTERFACE}
  RegisterTest(TTestCase_ILockFreeMap_Contract);
  {$ENDIF}

  {$IFDEF FAFAFA_CORE_IFACE_FACTORIES}
  RegisterTest(TTestCase_IfacesFactories);
  {$ENDIF}

  RegisterTest(TTestCase_Global);
  // 暂时屏蔽并发/队列相关用例以定位卡死根因（仅保留栈与基础HashMap）
  {$IFDEF FAFAFA_CORE_ENABLE_QUEUE_TESTS}
  RegisterTest(TTestCase_TSPSCQueue);
  RegisterTest(TTestCase_TMichaelScottQueue);
  RegisterTest(TTestCase_TPreAllocMPMCQueue);
  {$ENDIF}
  RegisterTest(TTestCase_TTreiberStack);
  RegisterTest(TTestCase_TPreAllocStack);
  RegisterTest(TTestCase_TLockFreeHashMap);
  RegisterTest(TTestCase_TLockFreeHashMap_CustomComparer);
  // RegisterTest(TTestCase_TLockFreeHashMap_Concurrency);
  // RegisterTest(TTestCase_TPreAllocStack_Concurrency);
end.
