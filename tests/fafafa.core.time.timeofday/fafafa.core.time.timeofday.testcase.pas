unit fafafa.core.time.timeofday.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.timeofday, fafafa.core.time.duration;

type
  TTestCase_TimeOfDay = class(TTestCase)
  published
    procedure Test_Create_And_Boundaries;
    procedure Test_Add_Modulo_Wrap;
    procedure Test_Diff_Clockwise;
    procedure Test_IsBetween_And_Clamp_CrossMidnight;
    procedure Test_ToString_And_Formats;
    procedure Test_TryParse_And_TryParseISO;
    procedure Test_Round_And_Truncate;
    procedure Test_TimeRange_Basics;
    procedure Test_Parse_Edges;
    procedure Test_Round_Boundaries;
    procedure Test_TimeRange_CrossMidnight_Edges;
  end;

implementation

procedure TTestCase_TimeOfDay.Test_Create_And_Boundaries;
var t0,t1: TTimeOfDay;
begin
  t0 := TTimeOfDay.Create(0,0,0,0);
  t1 := TTimeOfDay.Create(23,59,59,999);
  CheckEquals(0, t0.ToMilliseconds);
  CheckEquals(24*60*60*1000-1, t1.ToMilliseconds);
  CheckTrue(t0.IsMidnight);
  CheckTrue(TTimeOfDay.Noon.IsNoon);
end;

procedure TTestCase_TimeOfDay.Test_Add_Modulo_Wrap;
var t: TTimeOfDay;
begin
  t := TTimeOfDay.Create(23,59,59,900).AddMilliseconds(200);
  CheckEquals(TTimeOfDay.Create(0,0,0,100).ToMilliseconds, t.ToMilliseconds);
end;

procedure TTestCase_TimeOfDay.Test_Diff_Clockwise;
var a,b: TTimeOfDay; d: TDuration;
begin
  a := TTimeOfDay.Create(0,0,0,0);
  b := TTimeOfDay.Create(23,59,0,0);
  d := a - b; // 顺时针 b->a 差值 1 分钟
  CheckEquals(60*1000, d.AsMs);
  d := b.DurationUntil(a);
  CheckEquals(60*1000, d.AsMs);
end;

procedure TTestCase_TimeOfDay.Test_IsBetween_And_Clamp_CrossMidnight;
var s,e,x: TTimeOfDay;
begin
  s := TTimeOfDay.Create(22,0);
  e := TTimeOfDay.Create(6,0);
  CheckTrue(TTimeOfDay.Create(23,0).IsBetween(s,e));
  CheckTrue(TTimeOfDay.Create(1,0).IsBetween(s,e));
  // Clamp：位于区间内应返回自身
  x := TTimeOfDay.Create(23,30).Clamp(s,e);
  CheckEquals(TTimeOfDay.Create(23,30).ToMilliseconds, x.ToMilliseconds);
end;

procedure TTestCase_TimeOfDay.Test_ToString_And_Formats;
var t: TTimeOfDay;
begin
  t := TTimeOfDay.Create(0,5,6,7);
  CheckEquals('00:05:06.007', t.ToLongString);
  CheckEquals('00:05', t.ToShortString);
  CheckEquals('12:05 AM', t.To12HourString);
  CheckEquals('00:05:06', t.To24HourString);
end;

procedure TTestCase_TimeOfDay.Test_TryParse_And_TryParseISO;
var t: TTimeOfDay; ok: Boolean;
begin
  ok := TTimeOfDay.TryParse('09:08', t);
  CheckTrue(ok);
  CheckEquals(9, t.GetHour);
  ok := TTimeOfDay.TryParse('09:08:07.006', t);
  CheckTrue(ok);
  CheckEquals(7, t.GetSecond);
  ok := TTimeOfDay.TryParseISO('09:08:07.006', t);
  CheckTrue(ok);
  ok := TTimeOfDay.TryParseISO('9:8:7.6', t);
  CheckFalse(ok);
end;

procedure TTestCase_TimeOfDay.Test_Round_And_Truncate;
var t: TTimeOfDay;
begin
  t := TTimeOfDay.Create(12,29,30,600);
  CheckEquals(TTimeOfDay.Create(12,30,0,0).ToMilliseconds, t.RoundToMinute.ToMilliseconds);
  CheckEquals(TTimeOfDay.Create(12,29,0,0).ToMilliseconds, t.TruncateToMinute.ToMilliseconds);
end;

procedure TTestCase_TimeOfDay.Test_TimeRange_Basics;
var r: TTimeRange; s,e: TTimeOfDay;
begin
  s := TTimeOfDay.Create(22,0);
  r := TTimeRange.CreateDuration(s, TDuration.FromSec(2*3600));
  e := r.GetEndTime;
  CheckTrue(r.Contains(TTimeOfDay.Create(23,0)));
  CheckTrue(r.Contains(TTimeOfDay.Create(0,0)) = False);
  CheckTrue(r.Overlaps(TTimeRange.Create(TTimeOfDay.Create(23,0), TTimeOfDay.Create(1,0))));
end;

procedure TTestCase_TimeOfDay.Test_Parse_Edges;
var t: TTimeOfDay; ok: Boolean;
begin
  // TryParse（宽松）
  ok := TTimeOfDay.TryParse('24:00:00', t);   CheckFalse(ok);
  ok := TTimeOfDay.TryParse('-1:00', t);      CheckFalse(ok);
  ok := TTimeOfDay.TryParse('00:00:60', t);   CheckFalse(ok);
  ok := TTimeOfDay.TryParse('12:34:.123', t); CheckTrue(ok);
  ok := TTimeOfDay.TryParse('12:34:56.01', t); CheckTrue(ok);

  // TryParseISO（严格）
  ok := TTimeOfDay.TryParseISO('24:00:00', t);     CheckFalse(ok);
  ok := TTimeOfDay.TryParseISO('-1:00', t);        CheckFalse(ok);
  ok := TTimeOfDay.TryParseISO('00:00:60', t);     CheckFalse(ok);
  ok := TTimeOfDay.TryParseISO('12:34:.123', t);   CheckFalse(ok);
  ok := TTimeOfDay.TryParseISO('12:34:56.01', t);  CheckFalse(ok);
end;

procedure TTestCase_TimeOfDay.Test_Round_Boundaries;
var t: TTimeOfDay;
begin
  t := TTimeOfDay.FromMilliseconds(499); // 00:00:00.499
  CheckEquals(0, t.RoundToSecond.ToMilliseconds);
  t := TTimeOfDay.FromMilliseconds(500); // 00:00:00.500
  CheckEquals(1000, t.RoundToSecond.ToMilliseconds);
  t := TTimeOfDay.FromMilliseconds(501); // 00:00:00.501
  CheckEquals(1000, t.RoundToSecond.ToMilliseconds);
end;

procedure TTestCase_TimeOfDay.Test_TimeRange_CrossMidnight_Edges;
var a,b,u,i: TTimeRange;
begin
  // 相接但不重叠
  a := TTimeRange.Create(TTimeOfDay.Create(22,0), TTimeOfDay.Create(23,0));
  b := TTimeRange.Create(TTimeOfDay.Create(23,0), TTimeOfDay.Create(1,0));
  CheckFalse(a.Overlaps(b));
  u := a.Union(b);
  CheckTrue(u.Contains(TTimeOfDay.Create(0,30)));

  // 完全不相交（不跨午夜）
  a := TTimeRange.Create(TTimeOfDay.Create(10,0), TTimeOfDay.Create(12,0));
  b := TTimeRange.Create(TTimeOfDay.Create(13,0), TTimeOfDay.Create(15,0));
  CheckFalse(a.Overlaps(b));
  i := a.Intersection(b);
  CheckEquals(i.GetStartTime.ToMilliseconds, i.GetEndTime.ToMilliseconds);

  // 双跨午夜的包含关系
  a := TTimeRange.Create(TTimeOfDay.Create(22,0), TTimeOfDay.Create(2,0));
  b := TTimeRange.Create(TTimeOfDay.Create(23,0), TTimeOfDay.Create(1,0));
  CheckTrue(a.Overlaps(b));
  i := a.Intersection(b);
  CheckTrue(i.Contains(TTimeOfDay.Create(23,30)));
  CheckFalse(i.Contains(TTimeOfDay.Create(2,0)));
end;

initialization
  RegisterTest(TTestCase_TimeOfDay);
end.

