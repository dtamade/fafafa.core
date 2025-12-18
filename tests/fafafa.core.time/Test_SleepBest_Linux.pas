unit Test_SleepBest_Linux;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

{$IFDEF LINUX}
uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.time;

type
  TTestCase_SleepBest_Linux = class(TTestCase)
  published
    procedure Test_AbsoluteSleep_DriftVsRelative;
  end;

implementation

procedure TTestCase_SleepBest_Linux.Test_AbsoluteSleep_DriftVsRelative;
var
  i, N: Integer;
  stepMs: Int64;
  idealNs, relNs, absNs: Int64;
  tStart, tNow, tTarget: TInstant;
  driftRel, driftAbs: Int64;
begin
  // 对比相对睡眠 vs 绝对睡眠的累计误差
  N := 10;
  stepMs := 5;
  idealNs := N * stepMs * NANOSECONDS_PER_MILLI;

  // 相对睡眠：重复 SleepFor(step)
  tStart := NowInstant;
  for i := 1 to N do
    SleepFor(TDuration.FromMs(stepMs));
  tNow := NowInstant;
  relNs := tNow.Diff(tStart).AsNs;

  // 绝对睡眠：每次按目标点 SleepUntil
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

  // 断言绝对睡眠漂移不大于相对睡眠，且总体误差在 50ms 内（宽松阈值，容忍调度抖动）
  CheckTrue(driftAbs <= driftRel);
  CheckTrue(Abs(absNs - idealNs) <= 50 * NANOSECONDS_PER_MILLI);
end;

initialization
  RegisterTest(TTestCase_SleepBest_Linux);
{$ENDIF}

end.

