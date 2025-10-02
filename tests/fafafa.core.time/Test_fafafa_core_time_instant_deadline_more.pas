unit Test_fafafa_core_time_instant_deadline_more;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_InstantDeadlineMore = class(TTestCase)
  published
    procedure Test_Instant_IsBefore_IsAfter;
    procedure Test_Deadline_Until_Overdue_IsExpired;
  end;

implementation

procedure TTestCase_InstantDeadlineMore.Test_Instant_IsBefore_IsAfter;
var a,b: TInstant;
begin
  a := TInstant.FromNsSinceEpoch(100);
  b := TInstant.FromNsSinceEpoch(120);
  CheckTrue(a.IsBefore(b));
  CheckTrue(b.IsAfter(a));
end;

procedure TTestCase_InstantDeadlineMore.Test_Deadline_Until_Overdue_IsExpired;
var dl: TDeadline; nowI: TInstant; d: TDuration;
begin
  dl := TDeadline.FromInstant(TInstant.FromNsSinceEpoch(100));
  nowI := TInstant.FromNsSinceEpoch(90);
  d := dl.Remaining(nowI);  // 使用 Remaining 代替 TimeUntil
  CheckEquals(10, d.AsNs);
  nowI := TInstant.FromNsSinceEpoch(120);
  d := dl.Overdue(nowI);
  CheckEquals(20, d.AsNs);
  CheckTrue(dl.HasExpired(nowI));  // 使用 HasExpired 代替 IsExpired
end;

initialization
  RegisterTest(TTestCase_InstantDeadlineMore);
end.

