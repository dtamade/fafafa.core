unit Test_fafafa_core_time_waitfor_until;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread.cancel,
  fafafa.core.time;

type
  TTestCase_WaitForUntil = class(TTestCase)
  published
    procedure Test_WaitFor_PreCancelled;
    procedure Test_WaitUntil_CancelDuring;
    procedure Test_WaitFor_Success;
  end;

implementation

procedure TTestCase_WaitForUntil.Test_WaitFor_PreCancelled;
var cts: ICancellationTokenSource; ok: Boolean;
begin
  cts := CreateCancellationTokenSource;
  cts.Cancel; // 预先取消
  ok := DefaultMonotonicClock.WaitFor(TDuration.FromMs(5), cts.Token);
  CheckFalse(ok);
end;

procedure TTestCase_WaitForUntil.Test_WaitUntil_CancelDuring;
var cts: ICancellationTokenSource; t: TInstant; ok: Boolean;
begin
  cts := CreateCancellationTokenSource;
  // 目标 30ms 后；中途在 5ms 后取消
  t := NowInstant.Add(TDuration.FromMs(30));
  TThread.Sleep(5);
  cts.Cancel;
  ok := DefaultMonotonicClock.WaitUntil(t, cts.Token);
  CheckFalse(ok);
end;

procedure TTestCase_WaitForUntil.Test_WaitFor_Success;
var cts: ICancellationTokenSource; ok: Boolean; start, finish: TInstant;
begin
  cts := CreateCancellationTokenSource;
  start := NowInstant;
  ok := DefaultMonotonicClock.WaitFor(TDuration.FromMs(10), cts.Token);
  finish := NowInstant;
  CheckTrue(ok);
  // 至少等待 ~8ms（容错）
  CheckTrue(finish.Diff(start).AsMs >= 8);
end;

initialization
  RegisterTest(TTestCase_WaitForUntil);
end.

