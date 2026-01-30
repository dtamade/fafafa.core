unit Test_fafafa_core_time_wait_matrix;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread.cancel,
  fafafa.core.time;

type
  TTestCase_WaitMatrix = class(TTestCase)
  published
    procedure Test_WaitFor_Matrix_Short;
  end;

implementation

procedure TTestCase_WaitMatrix.Test_WaitFor_Matrix_Short;
const DurMs = 4;
var s: TSleepStrategy; ok: Boolean; start, finish: TInstant; cts: ICancellationTokenSource;
begin
  // 预设推荐参数（确保逻辑一致）
  SetFinalSpinThresholdNs(2 * 1000 * 1000); // 2ms
  SetSliceSleepMsFor(PlatLinux, 1);
  SetSpinYieldEvery(2048);

  for s in [EnergySaving, Balanced, LowLatency, UltraLowLatency] do
  begin
    SetSleepStrategy(s);
    start := NowInstant;
    cts := CreateCancellationTokenSource;
    ok := DefaultMonotonicClock.WaitFor(TDuration.FromMs(DurMs), cts.Token);
    finish := NowInstant;
    CheckTrue(ok);
    // 基于可移植的宽松校验：至少应等待 2ms 以上
    CheckTrue(finish.Diff(start).AsMs >= 2);
  end;
end;

initialization
  RegisterTest(TTestCase_WaitMatrix);
end.

