unit Test_SleepBest_Darwin;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

{$IFDEF DARWIN}
uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.time;

type
  TTestCase_SleepBest_Darwin = class(TTestCase)
  published
    procedure Test_AbsoluteSleep_DriftVsRelative;
  end;

implementation

procedure TTestCase_SleepBest_Darwin.Test_AbsoluteSleep_DriftVsRelative;
var
  i, N: Integer;
  stepMs: Int64;
  idealNs, relNs, absNs: Int64;
  tStart, tNow, tTarget: TInstant;
  driftRel, driftAbs: Int64;
begin
  // 与 Linux 类似，断言使用 mach_wait_until 的绝对睡眠漂移更小或相等
  N := 10;
  stepMs := 5;
  idealNs := N * stepMs * NANOSECONDS_PER_MILLI;

  // 相对睡眠
  tStart := NowInstant;
  for i := 1 to N do
    SleepFor(TDuration.FromMs(stepMs));
  tNow := NowInstant;
  relNs := tNow.Diff(tStart).AsNs;

  // 绝对睡眠
  tStart := NowInstant;
  for i := 1 to N do
  begin
    tTarget := tStart.Add(TDuration.FromMs(i * stepMs));
    SleepUntil(tTarget);
  end;
  tNow := NowInstant;
  absNs := tNow.Diff(tStart).AsNs;

  driftRel := Abs(relNs - idealNs);
  driftAbs := Abs(absNs - idealNs);

  CheckTrue(driftAbs <= driftRel);
  CheckTrue(Abs(absNs - idealNs) <= 50 * NANOSECONDS_PER_MILLI);
end;

initialization
  RegisterTest(TTestCase_SleepBest_Darwin);
{$ENDIF}

end.

