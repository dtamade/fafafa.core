{$CODEPAGE UTF8}
unit fafafa.core.sync.watch.testcase;

{**
 * fafafa.core.sync.watch 测试套件
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.watch;

type
  TTestCase_Watch_Basic = class(TTestCase)
  published
    procedure Test_Init_Done;
    procedure Test_InitialValue;
    procedure Test_Send_Borrow;
    procedure Test_HasChanged;
    procedure Test_MultiReceiver;
    procedure Test_Close;
  end;

implementation

{ TTestCase_Watch_Basic }

procedure TTestCase_Watch_Basic.Test_Init_Done;
var
  W: TWatchInt;
begin
  FillChar(W, SizeOf(W), 0);  // 初始化为 0
  W.Init(0);
  AssertFalse('Not closed', W.IsClosed);
  AssertTrue('Version > 0', W.GetVersion > 0);
  W.Done;
end;

procedure TTestCase_Watch_Basic.Test_InitialValue;
var
  W: TWatchInt;
begin
  FillChar(W, SizeOf(W), 0);
  W.Init(42);
  AssertEquals('Initial value', 42, W.Get);
  W.Done;
end;

procedure TTestCase_Watch_Basic.Test_Send_Borrow;
var
  W: TWatchInt;
  Rx: TWatchInt.PReceiver;
begin
  FillChar(W, SizeOf(W), 0);
  W.Init(0);
  Rx := W.Subscribe;

  W.Send(100);
  AssertEquals('Updated value', 100, W.Borrow(Rx));

  W.Send(200);
  AssertEquals('Updated value 2', 200, W.Borrow(Rx));

  W.Unsubscribe(Rx);
  W.Done;
end;

procedure TTestCase_Watch_Basic.Test_HasChanged;
var
  W: TWatchInt;
  Rx: TWatchInt.PReceiver;
  Val: Integer;
begin
  FillChar(W, SizeOf(W), 0);
  W.Init(0);
  Rx := W.Subscribe;

  // 刚订阅时没有变化（因为初始版本已设置）
  AssertFalse('No change initially', W.HasChanged(Rx));

  W.Send(1);
  AssertTrue('Has change after send', W.HasChanged(Rx));

  Val := W.Borrow(Rx);
  AssertEquals('Value', 1, Val);
  AssertFalse('No change after borrow', W.HasChanged(Rx));

  W.Unsubscribe(Rx);
  W.Done;
end;

procedure TTestCase_Watch_Basic.Test_MultiReceiver;
var
  W: TWatchInt;
  Rx1, Rx2: TWatchInt.PReceiver;
begin
  FillChar(W, SizeOf(W), 0);
  W.Init(10);
  Rx1 := W.Subscribe;
  Rx2 := W.Subscribe;

  W.Send(20);

  AssertEquals('Rx1 sees value', 20, W.Borrow(Rx1));
  AssertEquals('Rx2 sees value', 20, W.Borrow(Rx2));

  W.Send(30);

  AssertTrue('Rx1 has change', W.HasChanged(Rx1));
  AssertTrue('Rx2 has change', W.HasChanged(Rx2));

  W.Unsubscribe(Rx1);
  W.Unsubscribe(Rx2);
  W.Done;
end;

procedure TTestCase_Watch_Basic.Test_Close;
var
  W: TWatchInt;
begin
  FillChar(W, SizeOf(W), 0);
  W.Init(0);
  AssertFalse('Not closed', W.IsClosed);
  W.Close;
  AssertTrue('Is closed', W.IsClosed);
  W.Done;
end;

initialization
  RegisterTest(TTestCase_Watch_Basic);

end.
