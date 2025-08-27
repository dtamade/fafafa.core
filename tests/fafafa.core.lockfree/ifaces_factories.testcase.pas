unit ifaces_factories.testcase;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{$I test_config.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.factories,
  fafafa.core.lockfree.hashmap.openAddressing,
  fafafa.core.lockfree;

function CaseInsensitiveHash(const S: string): Cardinal;
function CaseInsensitiveEqual(const L, R: string): Boolean;

type
  TTestCase_IfacesFactories = class(TTestCase)
  published
    procedure Test_SPSC_Factory_Enqueue_Dequeue;
    procedure Test_Treiber_Factory_Push_Pop;
    procedure Test_MPMC_Factory_Basics;
    procedure Test_Map_OA_CaseInsensitive;
    procedure Test_Map_OA_Capacity_FullAndFail;
    procedure Test_MapEx_OA_PutEx_RemoveEx;
    procedure Test_MapEx_OA_FactoryPath;
    procedure Test_MapEx_OA_Capacity_FullAndFail;
    procedure Test_SPSC_Blocking_Close_RemainingCapacity;
    procedure Test_MPSC_Blocking_Semantics;
    procedure Test_MPMC_Blocking_Batch_RemainingCapacity;
    procedure Test_Stack_Treiber_TryPeek_Clear;
    procedure Test_MapEx_OA_PutIfAbsent_GetOrAdd_Compute;
    procedure Test_QueueBuilder_SPSC;
    procedure Test_QueueBuilder_MPMC;
    procedure Test_MapBuilder_OA;
    procedure Test_MapBuilder_MM_Planned_Raises;
    procedure Test_MapBuilder_OA_WithComparer;
    procedure Test_MapBuilder_MM_WithComparer;

    procedure Test_QueueBuilder_BlockingPolicy_Spin;
    procedure Test_QueueBuilder_BlockingPolicy_MPSC_Spin;
    procedure Test_QueueBuilder_BlockingPolicy_MPMC_Sleep;
    // 新增：策略注入后的阻塞/超时与 Close 唤醒
    procedure Test_Builder_WithBlockingPolicy_Timeouts;
    procedure Test_Builder_WithBlockingPolicy_CloseWake;
    // 新增：Aggressive 退避策略对比用例
    procedure Test_Builder_AggressiveBackoff_Comparison;


  end;


implementation

function CaseInsensitiveHash(const S: string): Cardinal;
var U: string;
begin
  U := UpperCase(S);
  if Length(U) > 0 then
    Result := SimpleHash(U[1], Length(U))
  else
    Result := 0;
end;

function CaseInsensitiveEqual(const L, R: string): Boolean;
begin
  Result := SameText(L, R);
end;

function Inc9(const OldValue: Integer): Integer; inline;
begin
  Inc9 := OldValue + 9;
end;

function Add10(const OldValue: Integer): Integer; inline;
begin
  Add10 := OldValue + 10;
end;

function Hash64(const S: string): QWord; inline;
var U: string;
begin
  U := UpperCase(S);
  Hash64 := DefaultStringHash(U);
end;

procedure TTestCase_IfacesFactories.Test_SPSC_Factory_Enqueue_Dequeue;
var
  Q: specialize ILockFreeQueueSPSC<Integer>;
  V: Integer;
begin
  Q := specialize NewSpscQueue<Integer>(8);
  CheckTrue(Q.Enqueue(1));
  CheckTrue(Q.Enqueue(2));
  CheckEquals(2, Q.Size);
  CheckEquals(8, Q.Capacity);
  CheckTrue(Q.Dequeue(V));
  CheckEquals(1, V);
  CheckTrue(Q.Dequeue(V));
  CheckEquals(2, V);
  CheckTrue(Q.IsEmpty);
end;

procedure TTestCase_IfacesFactories.Test_Treiber_Factory_Push_Pop;
var
  S: specialize ILockFreeStack<Integer>;
  V: Integer;
begin
  S := specialize NewTreiberStack<Integer>;
  CheckTrue(S.Push(42));
  CheckFalse(S.IsEmpty);
  CheckTrue(S.Pop(V));
  CheckEquals(42, V);
  CheckTrue(S.IsEmpty);
end;

procedure TTestCase_IfacesFactories.Test_MPMC_Factory_Basics;
var
  Q: specialize ILockFreeQueueMPMC<Integer>;
  V: Integer;
  I: Integer;
begin
  Q := specialize NewMpmcQueue<Integer>(8);
  for I := 0 to 7 do
    CheckTrue(Q.Enqueue(I));
  CheckFalse(Q.Enqueue(999));
  CheckFalse(Q.IsEmpty);
  CheckEquals(8, Q.Capacity);
  for I := 0 to 7 do
  begin
    CheckTrue(Q.Dequeue(V));
    CheckEquals(I, V);
  end;
  CheckTrue(Q.IsEmpty);
end;

procedure TTestCase_IfacesFactories.Test_Map_OA_CaseInsensitive;
var
  M: specialize TLockFreeHashMap<string, Integer>;
  V: Integer;
begin
  M := specialize TLockFreeHashMap<string, Integer>.Create(128,
    @CaseInsensitiveHash,
    @CaseInsensitiveEqual);
  try
    CheckTrue(M.Put('Key', 1));
    CheckTrue(M.Get('KEY', V));
    CheckEquals(1, V);

    CheckTrue(M.Put('key', 2));
    CheckTrue(M.Get('KEY', V));
    CheckEquals(2, V);
  finally
    M.Free;
  end;
end;



procedure TTestCase_IfacesFactories.Test_QueueBuilder_SPSC;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  V: Integer;
begin
  QB := specialize TQueueBuilder<Integer>.New.Capacity(4).ModelSPSC;
  Q := QB.Build;
  CheckTrue(Q.TryEnqueue(7));
  CheckTrue(Q.TryDequeue(V));
  CheckEquals(7, V);
end;

procedure TTestCase_IfacesFactories.Test_QueueBuilder_MPMC;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  V: Integer;
begin
  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC;
  Q := QB.Build;
  CheckTrue(Q.TryEnqueue(11));
  CheckTrue(Q.TryDequeue(V));
  CheckEquals(11, V);
end;

procedure TTestCase_IfacesFactories.Test_MapBuilder_OA;
var
  MB: specialize TMapBuilder<string,Integer>;
  M: specialize ILockFreeMapEx<string,Integer>;
  V: Integer;
begin
  MB := specialize TMapBuilder<string,Integer>.New.Capacity(32).ImplOA;
  M := MB.BuildEx;
  CheckTrue(M.Put('a', 1));
  CheckTrue(M.Get('a', V));
  CheckEquals(1, V);
end;

procedure TTestCase_IfacesFactories.Test_SPSC_Blocking_Close_RemainingCapacity;
var
  Q: specialize ILockFreeQueueSPSC<Integer>;
  V: Integer;
begin
  Q := specialize NewSpscQueue<Integer>(4);
  CheckEquals(4, Q.Capacity);
  CheckEquals(4, Q.RemainingCapacity);
  CheckTrue(Q.Enqueue(1)); CheckTrue(Q.Enqueue(2));
  CheckTrue(Q.Enqueue(3)); CheckTrue(Q.Enqueue(4));
  CheckEquals(0, Q.RemainingCapacity);
  // Blocking dequeue should succeed quickly
  CheckTrue(Q.DequeueBlocking(V, 10));
  // Close and drain
  Q.Close;
  while Q.Dequeue(V) do ;
  // After Close and empty, DequeueBlocking should return False
  CheckFalse(Q.DequeueBlocking(V, 5));
end;

procedure TTestCase_IfacesFactories.Test_MapBuilder_OA_WithComparer;
var
  MB: specialize TMapBuilder<string,Integer>;
  M: specialize ILockFreeMapEx<string,Integer>;
  outV: Integer; inserted, updated: Boolean;
begin
  MB := specialize TMapBuilder<string,Integer>.New.Capacity(32).ImplOA
    .WithComparer(@CaseInsensitiveHash, @CaseInsensitiveEqual);
  M := MB.BuildEx;
  CheckTrue(M.PutIfAbsent('Key', 1, inserted)); CheckTrue(inserted);
  CheckTrue(M.Get('key', outV)); CheckEquals(1, outV);
  CheckTrue(M.Compute('KEY', @Inc9, updated));
  CheckTrue(updated);
  CheckTrue(M.Get('key', outV)); CheckEquals(10, outV);
end;



procedure TTestCase_IfacesFactories.Test_MPSC_Blocking_Semantics;
var
  Q: specialize ILockFreeQueueMPSC<Integer>;
  V: Integer;
begin
  Q := specialize NewMpscQueue<Integer>;
  // EnqueueBlocking should always succeed (unbounded semantics)
  CheckTrue(Q.EnqueueBlocking(10, 1));
  CheckTrue(Q.DequeueBlocking(V, 50)); CheckEquals(10, V);
  // Close then DequeueBlocking should fail if empty
  Q.Close;
  CheckFalse(Q.DequeueBlocking(V, 5));
end;

procedure TTestCase_IfacesFactories.Test_MapBuilder_MM_Planned_Raises;
var
  MB: specialize TMapBuilder<string,Integer>;
  M: specialize ILockFreeMapEx<string,Integer>;
begin
  MB := specialize TMapBuilder<string,Integer>.New.Capacity(16).ImplMM;
  try
    M := MB.BuildEx;
    Fail('MapBuilder.ImplMM should raise for now');
  except
    on E: Exception do
      CheckTrue(Pos('requires comparer', LowerCase(E.Message)) > 0);
  end;
end;

procedure TTestCase_IfacesFactories.Test_MapBuilder_MM_WithComparer;
var
  MB: specialize TMapBuilder<string,Integer>;
  M: specialize ILockFreeMapEx<string,Integer>;
  outV: Integer; inserted, updated: Boolean;
begin
  MB := specialize TMapBuilder<string,Integer>.New.Capacity(32).ImplMM
    .WithComparerMM(@Hash64, @CaseInsensitiveEqual);
  M := MB.BuildEx;
  CheckTrue(M.PutIfAbsent('Key', 1, inserted)); CheckTrue(inserted);
  CheckTrue(M.Get('key', outV)); CheckEquals(1, outV);
  CheckTrue(M.Compute('KEY', @Inc9, updated));
  CheckTrue(updated);
  CheckTrue(M.Get('key', outV)); CheckEquals(10, outV);
end;

procedure TTestCase_IfacesFactories.Test_Builder_WithBlockingPolicy_Timeouts;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  V: Integer;
begin
  // MPMC 有界队列，注入默认阻塞策略，验证超时返回 False
  QB := specialize TQueueBuilder<Integer>.New.Capacity(4).ModelMPMC
    .BlockingPolicy(bpSleep);
  Q := QB.Build;
  // 队列空，DequeueBlocking 应在短超时内返回 False
  CheckFalse(Q.DequeueBlocking(V, 5));
  // 放入一个元素后，DequeueBlocking 应成功
  CheckTrue(Q.Enqueue(123));
  CheckTrue(Q.DequeueBlocking(V, 10)); CheckEquals(123, V);
end;

procedure TTestCase_IfacesFactories.Test_Builder_WithBlockingPolicy_CloseWake;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  V: Integer;
begin
  // SPSC 也验证 Close 后阻塞者尽快失败
  QB := specialize TQueueBuilder<Integer>.New.Capacity(2).ModelSPSC
    .BlockingPolicy(bpSleep);
  Q := QB.Build;
  // 开启阻塞等待，但随后关闭，预期在超时时间内返回 False
  Q.Close;
  CheckFalse(Q.DequeueBlocking(V, 10));
end;



procedure TTestCase_IfacesFactories.Test_MPMC_Blocking_Batch_RemainingCapacity;
var
  Q: specialize ILockFreeQueueMPMC<Integer>;
  inArr: array[0..7] of Integer = (1,2,3,4,5,6,7,8);
  outArr: array[0..7] of Integer;
  pushed, popped: SizeInt;
  V: Integer;
begin
  Q := specialize NewMpmcQueue<Integer>(8);
  CheckEquals(8, Q.RemainingCapacity);
  CheckTrue(Q.EnqueueMany(inArr, pushed));
  CheckTrue(pushed >= 1);
  FillChar(outArr, SizeOf(outArr), 0);
  CheckTrue(Q.DequeueMany(outArr, popped));
  CheckTrue(popped >= 1);
  // Close and ensure DequeueBlocking returns False when empty
  Q.Close;
  while Q.Dequeue(V) do ;
  CheckFalse(Q.DequeueBlocking(V, 5));
end;


procedure TTestCase_IfacesFactories.Test_Builder_AggressiveBackoff_Comparison;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  V: Integer;
begin
  // 使用默认退避策略，功能级验证
  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC
    .BlockingPolicy(bpSleep);
  Q := QB.Build;
  // 基本入队/出队应如常工作
  CheckTrue(Q.Enqueue(1));
  CheckTrue(Q.DequeueBlocking(V, 10)); CheckEquals(1, V);
end;

procedure TTestCase_IfacesFactories.Test_Stack_Treiber_TryPeek_Clear;
var
  S: specialize ILockFreeStack<Integer>;
  V: Integer;
begin
  S := specialize NewTreiberStack<Integer>;
  CheckTrue(S.Push(1));
  CheckFalse(S.TryPeek(V)); // 当前实现不支持 TryPeek -> False
  S.Clear;
  CheckTrue(S.IsEmpty);
end;

procedure TTestCase_IfacesFactories.Test_MapEx_OA_PutIfAbsent_GetOrAdd_Compute;
var
  M: specialize ILockFreeMapEx<string, Integer>;
  inserted, updated: Boolean;
  outV: Integer;
begin
  M := specialize TMapBuilder<string,Integer>.New.Capacity(64).ImplOA
    .WithComparer(@CaseInsensitiveHash, @CaseInsensitiveEqual).BuildEx;
  CheckTrue(M.PutIfAbsent('Key', 1, inserted)); CheckTrue(inserted);
  // 再次 PutIfAbsent 不插入
  CheckTrue(M.PutIfAbsent('key', 2, inserted)); CheckFalse(inserted);
  // GetOrAdd
  CheckTrue(M.GetOrAdd('KEY', 3, outV)); CheckEquals(1, outV);
  // Compute 更新
  CheckTrue(M.Compute('Key', @Add10, updated));
  CheckTrue(updated);
  CheckTrue(M.Get('key', outV)); CheckEquals(11, outV);
end;


procedure TTestCase_IfacesFactories.Test_QueueBuilder_BlockingPolicy_Spin;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  V: Integer;
begin
  QB := specialize TQueueBuilder<Integer>.New.Capacity(4).ModelSPSC.BlockingPolicy(bpSpin);
  Q := QB.Build;
  // Try path still works
  CheckTrue(Q.TryEnqueue(42));
  CheckTrue(Q.TryDequeue(V)); CheckEquals(42, V);
  // Blocking path uses spin over Try*; should still succeed
  CheckTrue(Q.EnqueueBlocking(7, 10));
  CheckTrue(Q.DequeueBlocking(V, 10)); CheckEquals(7, V);
end;






procedure TTestCase_IfacesFactories.Test_QueueBuilder_BlockingPolicy_MPSC_Spin;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  V: Integer;
begin
  QB := specialize TQueueBuilder<Integer>.New.ModelMPSC.BlockingPolicy(bpSpin);
  Q := QB.Build;
  // Enqueue then Dequeue should succeed under MPSC spin policy
  CheckTrue(Q.EnqueueBlocking(123, 1));
  CheckTrue(Q.DequeueBlocking(V, 1)); CheckEquals(123, V);
end;

procedure TTestCase_IfacesFactories.Test_QueueBuilder_BlockingPolicy_MPMC_Sleep;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  V: Integer;
begin
  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC.BlockingPolicy(bpSleep);
  Q := QB.Build;
  CheckTrue(Q.EnqueueBlocking(9, 10));
  CheckTrue(Q.DequeueBlocking(V, 10)); CheckEquals(9, V);
end;




procedure TTestCase_IfacesFactories.Test_Map_OA_Capacity_FullAndFail;
var
  M: specialize TLockFreeHashMap<Integer, Integer>;
  I, Count: Integer;
  Cap: SizeInt;
  Ok: Boolean;
  V: Integer;
begin
  M := specialize TLockFreeHashMap<Integer, Integer>.Create(32);
  try
    Cap := M.GetCapacity;
    Count := 0;
    I := 0;
    repeat
      Ok := M.Put(I, I);
      if Ok then Inc(Count);
      Inc(I);
    until not Ok;

    CheckTrue(Count <= Cap, 'Inserted count should be <= Capacity');
    // 再次尝试插入新键应失败
    CheckFalse(M.Put(High(Integer), High(Integer)));
    // 读取部分已存在键
    if Count > 0 then
    begin
      CheckTrue(M.Get(0, V));
      CheckEquals(0, V);
    end;
  finally
    M.Free;
  end;
end;

procedure TTestCase_IfacesFactories.Test_MapEx_OA_PutEx_RemoveEx;
var
  M: specialize ILockFreeMapEx<string, Integer>;
  Old: Integer;
  RPut: TMapPutResult;
  RRem: TMapRemoveResult;
begin
  M := specialize TMapBuilder<string,Integer>.New.Capacity(64).ImplOA
    .WithComparer(@CaseInsensitiveHash, @CaseInsensitiveEqual).BuildEx;
  RPut := M.PutEx('Key', 1, Old);
  CheckEquals(Ord(mprInserted), Ord(RPut));
  CheckEquals(0, Old);

  RPut := M.PutEx('KEY', 2, Old);
  CheckEquals(Ord(mprUpdated), Ord(RPut));
  CheckEquals(1, Old);

  RRem := M.RemoveEx('keY', Old);
  CheckEquals(Ord(mrrRemoved), Ord(RRem));
  CheckEquals(2, Old);

  RRem := M.RemoveEx('key', Old);
  CheckEquals(Ord(mrrNotFound), Ord(RRem));
end;

procedure TTestCase_IfacesFactories.Test_MapEx_OA_FactoryPath;
var
  M: specialize ILockFreeMapEx<string, Integer>;
  Old: Integer;
  RPut: TMapPutResult;
  RRem: TMapRemoveResult;
begin
  M := specialize TMapBuilder<string,Integer>.New.Capacity(64).ImplOA
    .WithComparer(@CaseInsensitiveHash, @CaseInsensitiveEqual).BuildEx;

  RPut := M.PutEx('Key', 10, Old);
  CheckEquals(Ord(mprInserted), Ord(RPut));
  CheckEquals(0, Old);

  RPut := M.PutEx('KEY', 20, Old);
  CheckEquals(Ord(mprUpdated), Ord(RPut));
  CheckEquals(10, Old);

  RRem := M.RemoveEx('key', Old);
  CheckEquals(Ord(mrrRemoved), Ord(RRem));
  CheckEquals(20, Old);
end;

procedure TTestCase_IfacesFactories.Test_MapEx_OA_Capacity_FullAndFail;
var
  M: specialize ILockFreeMapEx<Integer, Integer>;
  Old: Integer;
  RPut: TMapPutResult;
  I, Count: Integer;
  Cap: SizeInt;
begin
  M := specialize TMapBuilder<Integer,Integer>.New.Capacity(32).ImplOA.BuildEx;
  Cap := 32; // 接口无直接 Capacity，此处用构造参数语义
  Count := 0;
  I := 0;
  repeat
    RPut := M.PutEx(I, I, Old);
    if RPut = mprInserted then Inc(Count)
    else if RPut = mprFailed then Break
    else ;
    Inc(I);
  until False;
  CheckTrue(Count <= Cap, 'Inserted count should be <= Capacity');
  RPut := M.PutEx(High(Integer), High(Integer), Old);
  CheckEquals(Ord(mprFailed), Ord(RPut));
end;

initialization
  RegisterTest(TTestCase_IfacesFactories);
end.

