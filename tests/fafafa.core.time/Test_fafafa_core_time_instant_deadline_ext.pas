unit Test_fafafa_core_time_instant_deadline_ext;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_InstantDeadlineExt = class(TTestCase)
  published
    procedure Test_Instant_Clamp_Between;
    procedure Test_Deadline_Remaining_ClampZero;
  end;

implementation

procedure TTestCase_InstantDeadlineExt.Test_Instant_Clamp_Between;
var a, mn, mx, r: TInstant;
begin
  a := TInstant.FromNsSinceEpoch(120);
  mn := TInstant.FromNsSinceEpoch(100);
  mx := TInstant.FromNsSinceEpoch(110);
  r := a.Clamp(mn, mx);
  CheckEquals(QWord(110), r.AsNsSinceEpoch);
  // Between 已被删除，再次测试 Clamp 确保功能一致
  r := a.Clamp(mn, mx);
  CheckEquals(QWord(110), r.AsNsSinceEpoch);
end;

procedure TTestCase_InstantDeadlineExt.Test_Deadline_Remaining_ClampZero;
var dl: TDeadline; nowI: TInstant; r: TDuration;
begin
  dl := TDeadline.FromInstant(TInstant.FromNsSinceEpoch(100));
  nowI := TInstant.FromNsSinceEpoch(120);
  r := dl.RemainingClampedZero(nowI);
  CheckEquals(0, r.AsNs);
  nowI := TInstant.FromNsSinceEpoch(90);
  r := dl.Remaining(nowI);
  CheckEquals(10, r.AsNs);
end;

initialization
  RegisterTest(TTestCase_InstantDeadlineExt);
end.

