{$CODEPAGE UTF8}
unit fafafa.core.sync.ticketlock.testcase;

{**
 * fafafa.core.sync.ticketlock 测试套件
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.ticketlock;

type
  TTestCase_TicketLock_Basic = class(TTestCase)
  published
    procedure Test_Init_Done;
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire;
    procedure Test_IsLocked;
  end;

  TTestCase_TicketLock_Concurrent = class(TTestCase)
  published
    procedure Test_ConcurrentCounter;
    procedure Test_FIFO_Order;
  end;

implementation

{ TTestCase_TicketLock_Basic }

procedure TTestCase_TicketLock_Basic.Test_Init_Done;
var
  L: TTicketLock;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;
  AssertFalse('Not locked', L.IsLocked);
  AssertEquals('No waiters', 0, L.WaiterCount);
  L.Done;
end;

procedure TTestCase_TicketLock_Basic.Test_Acquire_Release;
var
  L: TTicketLock;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;

  L.Acquire;
  AssertTrue('Locked', L.IsLocked);

  L.Release;
  AssertFalse('Unlocked', L.IsLocked);

  L.Done;
end;

procedure TTestCase_TicketLock_Basic.Test_TryAcquire;
var
  L: TTicketLock;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;

  AssertTrue('TryAcquire succeeds', L.TryAcquire);
  AssertFalse('TryAcquire fails when locked', L.TryAcquire);

  L.Release;
  AssertTrue('TryAcquire succeeds again', L.TryAcquire);
  L.Release;

  L.Done;
end;

procedure TTestCase_TicketLock_Basic.Test_IsLocked;
var
  L: TTicketLock;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;

  AssertFalse('Initially unlocked', L.IsLocked);

  L.Acquire;
  AssertTrue('Locked after acquire', L.IsLocked);

  L.Release;
  AssertFalse('Unlocked after release', L.IsLocked);

  L.Done;
end;

{ TTestCase_TicketLock_Concurrent }

type
  TTicketWorker = class(TThread)
  private
    FLock: ^TTicketLock;
    FCounter: ^Integer;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(var ALock: TTicketLock; var ACounter: Integer; AIterations: Integer);
  end;

constructor TTicketWorker.Create(var ALock: TTicketLock; var ACounter: Integer; AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FLock := @ALock;
  FCounter := @ACounter;
  FIterations := AIterations;
end;

procedure TTicketWorker.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FLock^.Acquire;
    Inc(FCounter^);
    FLock^.Release;
  end;
end;

procedure TTestCase_TicketLock_Concurrent.Test_ConcurrentCounter;
var
  L: TTicketLock;
  Counter: Integer;
  Workers: array[0..3] of TTicketWorker;
  i: Integer;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;
  Counter := 0;

  for i := 0 to 3 do
    Workers[i] := TTicketWorker.Create(L, Counter, 1000);

  for i := 0 to 3 do
    Workers[i].Start;

  for i := 0 to 3 do
  begin
    Workers[i].WaitFor;
    Workers[i].Free;
  end;

  AssertEquals('Counter correct', 4000, Counter);

  L.Done;
end;

type
  TOrderWorker = class(TThread)
  private
    FLock: ^TTicketLock;
    FOrder: ^Integer;
    FMyOrder: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(var ALock: TTicketLock; var AOrder: Integer);
    property MyOrder: Integer read FMyOrder;
  end;

constructor TOrderWorker.Create(var ALock: TTicketLock; var AOrder: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FLock := @ALock;
  FOrder := @AOrder;
  FMyOrder := -1;
end;

procedure TOrderWorker.Execute;
begin
  FLock^.Acquire;
  Inc(FOrder^);
  FMyOrder := FOrder^;
  FLock^.Release;
end;

procedure TTestCase_TicketLock_Concurrent.Test_FIFO_Order;
var
  L: TTicketLock;
  Order: Integer;
  Workers: array[0..2] of TOrderWorker;
  i: Integer;
  AllCompleted: Boolean;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;
  Order := 0;

  // 先获取锁
  L.Acquire;

  // 创建并启动工作线程
  for i := 0 to 2 do
  begin
    Workers[i] := TOrderWorker.Create(L, Order);
    Workers[i].Start;
    Sleep(5);  // 确保按顺序排队
  end;

  // 释放锁
  L.Release;

  // 等待完成
  AllCompleted := True;
  for i := 0 to 2 do
  begin
    Workers[i].WaitFor;
    if Workers[i].MyOrder < 0 then
      AllCompleted := False;
    Workers[i].Free;
  end;

  AssertTrue('All completed', AllCompleted);

  L.Done;
end;

initialization
  RegisterTest(TTestCase_TicketLock_Basic);
  RegisterTest(TTestCase_TicketLock_Concurrent);

end.
