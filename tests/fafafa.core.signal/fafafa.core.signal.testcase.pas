unit fafafa.core.signal.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.signal;

// 测试说明：
// - 仅做最小无害用例：订阅/注入/等待
// - 不直接触发真实 SIGKILL 等破坏性信号；Ctrl 事件在 Windows 也仅通过 InjectForTest 验证


Type
  TTestCase_Global = class(TTestCase)
  private
    FCalled: Integer;
    procedure OnAny(const S: TSignal);
  published
    procedure Test_Subscribe_Unsubscribe;
    procedure Test_WaitNext_Inject;
  end;

  TTestCase_Dispatch = class(TTestCase)
  private
    FCountInt, FCountTerm: Integer;
    procedure OnSigInt(const S: TSignal);
    procedure OnSigTerm(const S: TSignal);
  published
    procedure Test_Dispatch_Callbacks;
  end;

implementation

procedure TTestCase_Global.OnAny(const S: TSignal);
begin
  Inc(FCalled);
end;

procedure TTestCase_Global.Test_Subscribe_Unsubscribe;
var C: ISignalCenter; tok: Int64;
begin
  WriteLn('[CASE] Test_Subscribe_Unsubscribe: begin'); System.Flush(Output);
  C := SignalCenter;
  C.Start;
  FCalled := 0;
  tok := C.Subscribe([sgInt, sgTerm], @Self.OnAny);
  C.InjectForTest(sgInt);
  Sleep(50);
  C.Unsubscribe(tok);
  C.InjectForTest(sgTerm);
  Sleep(50);
  C.Stop;
  WriteLn('[CASE] Test_Subscribe_Unsubscribe: end, FCalled=', FCalled);
  CheckTrue(FCalled >= 1, 'at least one callback should fire');
end;

procedure TTestCase_Global.Test_WaitNext_Inject;
var C: ISignalCenter; s: TSignal; ok: Boolean;
begin
  WriteLn('[CASE] Test_WaitNext_Inject: begin'); System.Flush(Output);
  C := SignalCenter;
  C.Start;
  C.InjectForTest(sgUsr1);
  ok := C.WaitNext(s, 500);
  C.Stop;
  WriteLn('[CASE] Test_WaitNext_Inject: ok=', ok, ' s=', Ord(s)); System.Flush(Output);
  CheckTrue(ok, 'WaitNext should return True');
  CheckTrue(s = sgUsr1, 'Expected sgUsr1');
end;

procedure TTestCase_Dispatch.OnSigInt(const S: TSignal);
begin
  if S = sgInt then Inc(FCountInt);
end;

procedure TTestCase_Dispatch.OnSigTerm(const S: TSignal);
begin
  if S = sgTerm then Inc(FCountTerm);
end;

procedure TTestCase_Dispatch.Test_Dispatch_Callbacks;
var C: ISignalCenter; t1, t2: Int64; T0: QWord;
begin
  FCountInt := 0; FCountTerm := 0;
  C := SignalCenter;
  C.Start;
  t1 := C.Subscribe([sgInt], @OnSigInt);
  t2 := C.Subscribe([sgTerm], @OnSigTerm);
  C.InjectForTest(sgInt);
  C.InjectForTest(sgTerm);
  // 等待至多 500ms 以避免调度竞态
  T0 := GetTickCount64;
  while ((FCountInt < 1) or (FCountTerm < 1)) and ((GetTickCount64 - T0) < 500) do Sleep(10);
  C.Unsubscribe(t1);
  C.Unsubscribe(t2);
  C.Stop;
  CheckEquals(1, FCountInt);
  CheckEquals(1, FCountTerm);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_Dispatch);

end.

