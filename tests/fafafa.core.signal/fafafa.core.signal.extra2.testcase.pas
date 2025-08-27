unit fafafa.core.signal.extra2.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.signal;

type
  TTestCase_Extra2 = class(TTestCase)
  private
    FOnceCount: Integer;
    procedure OnOnce(const S: TSignal);
  published
    procedure Test_SubscribeOnce_OnlyOnce;
    procedure Test_TryWaitNext_WhenEmpty;
  end;

implementation

procedure TTestCase_Extra2.OnOnce(const S: TSignal);
begin
  Inc(FOnceCount);
end;

procedure TTestCase_Extra2.Test_SubscribeOnce_OnlyOnce;
var C: ISignalCenter; tok: Int64;
begin
  C := SignalCenter; C.Start;
  try
    FOnceCount := 0;
    tok := C.SubscribeOnce([sgInt], @OnOnce);
    C.InjectForTest(sgInt);
    Sleep(20);
    CheckEquals(1, FOnceCount, 'SubscribeOnce should fire exactly once');

    // 再次注入不应触发
    C.InjectForTest(sgInt);
    Sleep(20);
    CheckEquals(1, FOnceCount, 'SubscribeOnce should not fire twice');

    // token 已自动注销，再调用 Unsubscribe 不应异常
    C.Unsubscribe(tok);
  finally
    C.Stop;
  end;
end;

procedure TTestCase_Extra2.Test_TryWaitNext_WhenEmpty;
var C: ISignalCenter; s: TSignal; ok: Boolean;
begin
  C := SignalCenter; C.Start;
  try
    ok := C.TryWaitNext(s);
    CheckFalse(ok, 'TryWaitNext should return False when queue is empty');

    // 注入后应返回 True
    C.InjectForTest(sgInt);
    ok := C.TryWaitNext(s);
    CheckTrue(ok and (s = sgInt), 'TryWaitNext should fetch injected signal');
  finally
    C.Stop;
  end;
end;

initialization
  RegisterTest(TTestCase_Extra2);

end.

