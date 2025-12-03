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
    // === 纳秒精度测试 ===
    procedure Test_GetNanosecond_ReturnsCorrectValue;
    procedure Test_GetMicrosecond_ReturnsCorrectValue;
    procedure Test_CreateWithNanosecond_FullPrecision;
    procedure Test_NanosecondComparison_DifferentByNs;
    procedure Test_ToISO8601_WithNanoseconds;
    procedure Test_TryParse_WithNanoseconds;
    procedure Test_AddDuration_NanosecondPrecision;
    procedure Test_FromNanoseconds_And_ToNanoseconds;
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

// === 纳秒精度测试实现 ===

procedure TTestCase_TimeOfDay.Test_GetNanosecond_ReturnsCorrectValue;
var t: TTimeOfDay;
begin
  // 创建带纳秒的时间：12:34:56.123456789
  t := TTimeOfDay.CreateNs(12, 34, 56, 123456789);
  CheckEquals(12, t.GetHour);
  CheckEquals(34, t.GetMinute);
  CheckEquals(56, t.GetSecond);
  CheckEquals(123, t.GetMillisecond);
  CheckEquals(456, t.GetMicrosecond);
  CheckEquals(789, t.GetNanosecond);
end;

procedure TTestCase_TimeOfDay.Test_GetMicrosecond_ReturnsCorrectValue;
var t: TTimeOfDay;
begin
  t := TTimeOfDay.CreateNs(0, 0, 0, 123456000);
  CheckEquals(123, t.GetMillisecond);
  CheckEquals(456, t.GetMicrosecond);
  CheckEquals(0, t.GetNanosecond);
end;

procedure TTestCase_TimeOfDay.Test_CreateWithNanosecond_FullPrecision;
var t: TTimeOfDay;
begin
  // 测试纳秒存储不丢失精度
  t := TTimeOfDay.CreateNs(23, 59, 59, 999999999);
  CheckEquals(23, t.GetHour);
  CheckEquals(59, t.GetMinute);
  CheckEquals(59, t.GetSecond);
  CheckEquals(999999999, t.GetSubsecondNanos);
end;

procedure TTestCase_TimeOfDay.Test_NanosecondComparison_DifferentByNs;
var t1, t2: TTimeOfDay;
begin
  // 两个时间只差 1 纳秒
  t1 := TTimeOfDay.CreateNs(12, 0, 0, 123456788);
  t2 := TTimeOfDay.CreateNs(12, 0, 0, 123456789);
  CheckTrue(t1 < t2);
  CheckTrue(t2 > t1);
  CheckFalse(t1 = t2);
end;

procedure TTestCase_TimeOfDay.Test_ToISO8601_WithNanoseconds;
var t: TTimeOfDay;
begin
  // 完整纳秒输出
  t := TTimeOfDay.CreateNs(12, 34, 56, 123456789);
  CheckEquals('12:34:56.123456789', t.ToISO8601);
  
  // 微秒级（末尾零省略到微秒）
  t := TTimeOfDay.CreateNs(12, 34, 56, 123456000);
  CheckEquals('12:34:56.123456', t.ToISO8601);
  
  // 毫秒级
  t := TTimeOfDay.CreateNs(12, 34, 56, 123000000);
  CheckEquals('12:34:56.123', t.ToISO8601);
  
  // 无小数部分
  t := TTimeOfDay.CreateNs(12, 34, 56, 0);
  CheckEquals('12:34:56', t.ToISO8601);
end;

procedure TTestCase_TimeOfDay.Test_TryParse_WithNanoseconds;
var t: TTimeOfDay; ok: Boolean;
begin
  // 纳秒解析
  ok := TTimeOfDay.TryParse('12:34:56.123456789', t);
  CheckTrue(ok);
  CheckEquals(123456789, t.GetSubsecondNanos);
  
  // 微秒解析
  ok := TTimeOfDay.TryParse('12:34:56.123456', t);
  CheckTrue(ok);
  CheckEquals(123456000, t.GetSubsecondNanos);
  
  // 毫秒解析（向后兼容）
  ok := TTimeOfDay.TryParse('12:34:56.123', t);
  CheckTrue(ok);
  CheckEquals(123000000, t.GetSubsecondNanos);
end;

procedure TTestCase_TimeOfDay.Test_AddDuration_NanosecondPrecision;
var t1, t2: TTimeOfDay; d: TDuration;
begin
  t1 := TTimeOfDay.CreateNs(12, 0, 0, 0);
  d := TDuration.FromNs(123456789);
  t2 := t1 + d;
  CheckEquals(123456789, t2.GetSubsecondNanos);
  CheckEquals(12, t2.GetHour);
end;

procedure TTestCase_TimeOfDay.Test_FromNanoseconds_And_ToNanoseconds;
var t: TTimeOfDay;
const
  NS_PER_HOUR: Int64 = 3600000000000;
begin
  // FromNanoseconds 并验证 ToNanoseconds
  t := TTimeOfDay.FromNanoseconds(NS_PER_HOUR * 12 + 123456789);
  CheckEquals(Int64(NS_PER_HOUR * 12 + 123456789), t.ToNanoseconds);
  CheckEquals(12, t.GetHour);
  CheckEquals(0, t.GetMinute);
  CheckEquals(0, t.GetSecond);
  CheckEquals(123456789, t.GetSubsecondNanos);
end;

initialization
  RegisterTest(TTestCase_TimeOfDay);
end.

