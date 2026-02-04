{$CODEPAGE UTF8}
unit fafafa.core.sync.broadcast.testcase;

{**
 * fafafa.core.sync.broadcast 测试套件
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.broadcast;

type
  TTestCase_Broadcast_Basic = class(TTestCase)
  published
    procedure Test_Init_Done;
    procedure Test_Send_Single;
    procedure Test_MultiReceiver;
    procedure Test_LateSubscriber;
    procedure Test_BufferOverflow;
    procedure Test_Close;
  end;

  TTestCase_Broadcast_Concurrent = class(TTestCase)
  published
    procedure Test_ConcurrentReceivers;
  end;

implementation

{ TTestCase_Broadcast_Basic }

procedure TTestCase_Broadcast_Basic.Test_Init_Done;
var
  BC: TBroadcastInt;
begin
  BC.Init(8);
  AssertEquals('Capacity', 8, BC.Capacity);
  AssertFalse('Not closed', BC.IsClosed);
  AssertEquals('Empty buffer', 0, BC.GetBufferedCount);
  BC.Done;
end;

procedure TTestCase_Broadcast_Basic.Test_Send_Single;
var
  BC: TBroadcastInt;
  Rx: TBroadcastInt.PReceiver;
  Val: Integer;
begin
  BC.Init(8);
  Rx := BC.Subscribe;

  BC.Send(42);
  AssertTrue('Has message', BC.HasPending(Rx));
  AssertTrue('TryRecv succeeds', BC.TryRecvFrom(Rx, Val));
  AssertEquals('Value', 42, Val);
  AssertFalse('No more messages', BC.HasPending(Rx));

  BC.Unsubscribe(Rx);
  BC.Done;
end;

procedure TTestCase_Broadcast_Basic.Test_MultiReceiver;
var
  BC: TBroadcastInt;
  Rx1, Rx2: TBroadcastInt.PReceiver;
  Val1, Val2: Integer;
begin
  BC.Init(8);
  Rx1 := BC.Subscribe;
  Rx2 := BC.Subscribe;

  BC.Send(100);

  AssertTrue('Rx1 has message', BC.TryRecvFrom(Rx1, Val1));
  AssertTrue('Rx2 has message', BC.TryRecvFrom(Rx2, Val2));
  AssertEquals('Rx1 value', 100, Val1);
  AssertEquals('Rx2 value', 100, Val2);

  BC.Unsubscribe(Rx1);
  BC.Unsubscribe(Rx2);
  BC.Done;
end;

procedure TTestCase_Broadcast_Basic.Test_LateSubscriber;
var
  BC: TBroadcastInt;
  Rx1, Rx2: TBroadcastInt.PReceiver;
  Val: Integer;
begin
  BC.Init(8);
  Rx1 := BC.Subscribe;

  BC.Send(1);
  BC.Send(2);

  // 迟到的订阅者（从最新开始）
  Rx2 := BC.Subscribe(True);

  BC.Send(3);

  // Rx1 应该收到 1, 2, 3
  AssertTrue('Rx1 gets 1', BC.TryRecvFrom(Rx1, Val));
  AssertEquals('Rx1 val 1', 1, Val);
  AssertTrue('Rx1 gets 2', BC.TryRecvFrom(Rx1, Val));
  AssertEquals('Rx1 val 2', 2, Val);
  AssertTrue('Rx1 gets 3', BC.TryRecvFrom(Rx1, Val));
  AssertEquals('Rx1 val 3', 3, Val);

  // Rx2 只收到 3
  AssertTrue('Rx2 gets 3', BC.TryRecvFrom(Rx2, Val));
  AssertEquals('Rx2 val', 3, Val);
  AssertFalse('Rx2 no more', BC.TryRecvFrom(Rx2, Val));

  BC.Unsubscribe(Rx1);
  BC.Unsubscribe(Rx2);
  BC.Done;
end;

procedure TTestCase_Broadcast_Basic.Test_BufferOverflow;
var
  BC: TBroadcastInt;
  Rx: TBroadcastInt.PReceiver;
  Val: Integer;
  i: Integer;
begin
  BC.Init(4);  // 小缓冲区
  Rx := BC.Subscribe;

  // 发送超过容量的消息
  for i := 1 to 10 do
    BC.Send(i);

  // 应该只能收到最后 4 条
  for i := 7 to 10 do
  begin
    AssertTrue('Has message ' + IntToStr(i), BC.TryRecvFrom(Rx, Val));
    AssertEquals('Value', i, Val);
  end;

  AssertFalse('No more', BC.TryRecvFrom(Rx, Val));

  BC.Unsubscribe(Rx);
  BC.Done;
end;

procedure TTestCase_Broadcast_Basic.Test_Close;
var
  BC: TBroadcastInt;
  Rx: TBroadcastInt.PReceiver;
  Val: Integer;
begin
  BC.Init(8);
  Rx := BC.Subscribe;

  BC.Send(1);
  BC.Close;

  AssertTrue('Is closed', BC.IsClosed);
  // 已经发送的消息仍然可以接收
  AssertTrue('Can recv', BC.TryRecvFrom(Rx, Val));
  AssertEquals('Value', 1, Val);

  BC.Unsubscribe(Rx);
  BC.Done;
end;

{ TTestCase_Broadcast_Concurrent }

type
  TBroadcastWorker = class(TThread)
  private
    FBC: ^TBroadcastInt;
    FRx: TBroadcastInt.PReceiver;
    FReceived: Integer;
    FExpected: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(var ABC: TBroadcastInt; AExpected: Integer);
    property Received: Integer read FReceived;
  end;

constructor TBroadcastWorker.Create(var ABC: TBroadcastInt; AExpected: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FBC := @ABC;
  FExpected := AExpected;
  FReceived := 0;
  FRx := ABC.Subscribe;
end;

procedure TBroadcastWorker.Execute;
var
  Val: Integer;
begin
  while FReceived < FExpected do
  begin
    if FBC^.TryRecvFrom(FRx, Val) then
      Inc(FReceived)
    else
      Sleep(1);
  end;
  FBC^.Unsubscribe(FRx);
end;

procedure TTestCase_Broadcast_Concurrent.Test_ConcurrentReceivers;
var
  BC: TBroadcastInt;
  Workers: array[0..3] of TBroadcastWorker;
  i, TotalReceived: Integer;
begin
  BC.Init(64);

  // 创建 4 个接收者
  for i := 0 to 3 do
    Workers[i] := TBroadcastWorker.Create(BC, 100);

  // 启动接收者
  for i := 0 to 3 do
    Workers[i].Start;

  // 发送 100 条消息
  for i := 1 to 100 do
    BC.Send(i);

  // 等待完成
  TotalReceived := 0;
  for i := 0 to 3 do
  begin
    Workers[i].WaitFor;
    TotalReceived := TotalReceived + Workers[i].Received;
    Workers[i].Free;
  end;

  // 每个接收者都应该收到 100 条
  AssertEquals('Total received', 400, TotalReceived);

  BC.Done;
end;

initialization
  RegisterTest(TTestCase_Broadcast_Basic);
  RegisterTest(TTestCase_Broadcast_Concurrent);

end.
