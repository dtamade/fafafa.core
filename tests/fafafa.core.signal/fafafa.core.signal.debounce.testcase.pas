unit fafafa.core.signal.debounce.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.signal;

type
  TTestCase_Debounce = class(TTestCase)
  private
    FCount: Integer;
    procedure OnSig(const S: TSignal);
  published
    procedure Test_Winch_Debounce_Window;
  end;

implementation

procedure TTestCase_Debounce.OnSig(const S: TSignal);
begin
  if S = sgWinch then Inc(FCount);
end;

procedure TTestCase_Debounce.Test_Winch_Debounce_Window;
var C: ISignalCenter; t: Int64; s: TSignal; ok: Boolean;
begin
  C := SignalCenter; C.Start;
  try
    FCount := 0;
    C.ConfigureWinchDebounce(50);
    t := C.Subscribe([sgWinch], @OnSig);
    // 在窗口内快速注入多次 sgWinch
    C.InjectForTest(sgWinch);
    Sleep(10);
    C.InjectForTest(sgWinch);
    Sleep(10);
    C.InjectForTest(sgWinch);
    // 给派发线程一点时间
    Sleep(80);
    CheckEquals(1, FCount, 'Debounce should allow only one callback in window');

    // 窗口外再次注入，应再触发一次
    C.InjectForTest(sgWinch);
    Sleep(60);
    CheckEquals(2, FCount, 'Debounce window expired; should fire again');

    // 队列消费路径也应受影响：窗口内多次注入只需等一次
    C.InjectForTest(sgWinch); Sleep(10);
    C.InjectForTest(sgWinch); Sleep(10);
    ok := C.WaitNext(s, 200);
    CheckTrue(ok and (s = sgWinch));
    ok := C.TryWaitNext(s);
    CheckFalse(ok, 'Debounced sgWinch should not enqueue duplicates within window');

    C.Unsubscribe(t);
  finally
    C.Stop;
  end;
end;

initialization
  RegisterTest(TTestCase_Debounce);

end.

