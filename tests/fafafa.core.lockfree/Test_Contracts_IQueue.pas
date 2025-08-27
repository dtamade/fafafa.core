unit Test_Contracts_IQueue;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{ 契约测试：IQueue（TE 版工厂；批量与能力断言） }

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

{$I test_config.inc}

implementation



uses
  Contracts_Factories_TE_Clean;

function _QueueFactory: IQueueFactory_Integer;
begin
  Result := GetDefaultQueueFactory_Integer_TE; // 来自 Impl
end;

type
  TTestCase_IQueue_Contracts_Integer = class(TTestCase)
  private
    FQ: IQueueInt;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Queue_Empty_ToStart;
    procedure Test_Queue_Enqueue_Dequeue_Order;
    procedure Test_Queue_TryPeek_OnEmpty_ReturnsFalse;
    procedure Test_Queue_SPSC_Bounded_Capacity_Behavior;
    procedure Test_Queue_MPMC_Bounded_Capacity_Behavior;
    procedure Test_Queue_MPSC_Unbounded_Basic;
    procedure Test_Queue_Batch_APIs;
    procedure Test_Queue_Clear_Behavior;
    procedure Test_Queue_Capabilities;
    {$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
    procedure Test_Queue_SPSC_Smoke;
    procedure Test_Queue_MPSC_Smoke;
    procedure Test_Queue_MPMC_Smoke;
    {$ENDIF}
  end;

procedure TTestCase_IQueue_Contracts_Integer.SetUp;
begin
  FQ := _QueueFactory.MakeSPSC(8);
end;

procedure TTestCase_IQueue_Contracts_Integer.TearDown;
begin
  FQ := nil;
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_Empty_ToStart;
begin
  AssertTrue(FQ.IsEmpty);
  AssertEquals(0, FQ.Size);
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_Enqueue_Dequeue_Order;
var v: Integer;
begin
  AssertTrue(FQ.Enqueue(1));
  AssertTrue(FQ.Enqueue(2));
  AssertTrue(FQ.TryDequeue(v)); AssertEquals(1, v);
  AssertTrue(FQ.TryDequeue(v)); AssertEquals(2, v);
  AssertTrue(FQ.IsEmpty);
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_TryPeek_OnEmpty_ReturnsFalse;
var v: Integer;
begin
  AssertTrue(FQ.IsEmpty);
  AssertFalse(FQ.TryPeek(v));
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_SPSC_Bounded_Capacity_Behavior;
var i, cap: Integer; q: IQueueInt;
begin
  q := _QueueFactory.MakeSPSC(4);
  cap := q.Capacity;
  AssertTrue(q.Bounded);
  AssertEquals(4, cap);
  for i := 1 to cap do AssertTrue(q.Enqueue(i));
  AssertEquals(cap, q.Size);
  AssertFalse(q.Enqueue(999));
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_MPMC_Bounded_Capacity_Behavior;
var i, cap, v: Integer; q: IQueueInt;
begin
  q := _QueueFactory.MakeMPMC(4);
  AssertTrue(q.Bounded);
  cap := q.Capacity; AssertEquals(4, cap);
  for i := 1 to cap do AssertTrue(q.Enqueue(i));
  AssertFalse(q.Enqueue(999));
  for i := 1 to cap do begin AssertTrue(q.TryDequeue(v)); AssertEquals(i, v); end;
  AssertTrue(q.IsEmpty);
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_MPSC_Unbounded_Basic;
var q: IQueueInt; v: Integer;
begin
  q := _QueueFactory.MakeMPSC;
  AssertFalse(q.Bounded);
  AssertEquals(-1, q.Capacity);
  AssertTrue(q.Enqueue(10));
  AssertTrue(q.Enqueue(20));
  AssertTrue(q.TryDequeue(v)); AssertEquals(10, v);
  AssertTrue(q.TryDequeue(v)); AssertEquals(20, v);
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_Batch_APIs;
var inArr: array[0..3] of Integer = (1,2,3,4); outArr: array[0..3] of Integer; n: Integer;
begin
  n := FQ.EnqueueMany(inArr);
  AssertTrue(n >= 1);
  FillChar(outArr, SizeOf(outArr), 0);
  n := FQ.DequeueMany(outArr);
  AssertTrue(n >= 1);
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_Clear_Behavior;
var i: Integer; v: Integer;
begin
  for i := 1 to 5 do FQ.Enqueue(i);
  FQ.Clear;
  AssertTrue(FQ.IsEmpty);
  AssertFalse(FQ.TryDequeue(v));
end;

procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_Capabilities;
begin
  // HasStats 在 MPMC 返回 True，SPSC/MPSC 返回 False（依据 TE 包装）
  AssertFalse(FQ.HasStats);
end;

{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
// ...（并发烟囱同前，略）
{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_SMOKE}
procedure TTestCase_IQueue_Contracts_Integer.Test_Queue_SPSC_Smoke;
var i, v: Integer; q: IQueueInt;
begin
  q := _QueueFactory.MakeSPSC(16);
  for i := 1 to 100 do AssertTrue(q.Enqueue(i));
  for i := 1 to 100 do begin AssertTrue(q.TryDequeue(v)); AssertEquals(i, v); end;
  AssertTrue(q.IsEmpty);
end;
{$ENDIF}

{$ENDIF}

initialization
  RegisterTest(TTestCase_IQueue_Contracts_Integer);

end.

