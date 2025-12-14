unit fafafa.core.time.strptime.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.strftime,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.naivedatetime;

type
  TTestCase_Strptime = class(TTestCase)
  published
    // === 日期解析 ===
    procedure Test_ParseDate_ISO8601;          // %Y-%m-%d
    procedure Test_ParseDate_YearMonth;        // %Y-%m
    procedure Test_ParseDate_USFormat;         // %m/%d/%Y
    
    // === 时间解析 ===
    procedure Test_ParseTime_HMS;              // %H:%M:%S
    procedure Test_ParseTime_HM;               // %H:%M
    procedure Test_ParseTime_12Hour;           // %I:%M %p
    
    // === 日期时间解析 ===
    procedure Test_ParseDateTime_ISO8601;      // %Y-%m-%dT%H:%M:%S
    procedure Test_ParseDateTime_Custom;       // 自定义格式
    
    // === 边界情况 ===
    procedure Test_Parse_InvalidFormat;
    procedure Test_Parse_PartialMatch;
    
    // === 往返测试 ===
    procedure Test_Roundtrip_Date;
    procedure Test_Roundtrip_Time;
    procedure Test_Roundtrip_DateTime;
  end;

implementation

// === 日期解析 ===

procedure TTestCase_Strptime.Test_ParseDate_ISO8601;
var D: TDate; ok: Boolean;
begin
  ok := StrptimeDate('2024-06-15', '%Y-%m-%d', D);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(2024, D.GetYear);
  CheckEquals(6, D.GetMonth);
  CheckEquals(15, D.GetDay);
end;

procedure TTestCase_Strptime.Test_ParseDate_YearMonth;
var D: TDate; ok: Boolean;
begin
  ok := StrptimeDate('2024-06', '%Y-%m', D);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(2024, D.GetYear);
  CheckEquals(6, D.GetMonth);
  CheckEquals(1, D.GetDay);  // 默认第1天
end;

procedure TTestCase_Strptime.Test_ParseDate_USFormat;
var D: TDate; ok: Boolean;
begin
  ok := StrptimeDate('06/15/2024', '%m/%d/%Y', D);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(2024, D.GetYear);
  CheckEquals(6, D.GetMonth);
  CheckEquals(15, D.GetDay);
end;

// === 时间解析 ===

procedure TTestCase_Strptime.Test_ParseTime_HMS;
var T: TTimeOfDay; ok: Boolean;
begin
  ok := StrptimeTime('14:30:45', '%H:%M:%S', T);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(14, T.GetHour);
  CheckEquals(30, T.GetMinute);
  CheckEquals(45, T.GetSecond);
end;

procedure TTestCase_Strptime.Test_ParseTime_HM;
var T: TTimeOfDay; ok: Boolean;
begin
  ok := StrptimeTime('14:30', '%H:%M', T);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(14, T.GetHour);
  CheckEquals(30, T.GetMinute);
  CheckEquals(0, T.GetSecond);  // 默认0秒
end;

procedure TTestCase_Strptime.Test_ParseTime_12Hour;
var T: TTimeOfDay; ok: Boolean;
begin
  ok := StrptimeTime('02:30 PM', '%I:%M %p', T);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(14, T.GetHour);  // 2 PM = 14
  CheckEquals(30, T.GetMinute);
  
  ok := StrptimeTime('09:15 AM', '%I:%M %p', T);
  CheckTrue(ok, 'Parse AM should succeed');
  CheckEquals(9, T.GetHour);
  CheckEquals(15, T.GetMinute);
end;

// === 日期时间解析 ===

procedure TTestCase_Strptime.Test_ParseDateTime_ISO8601;
var Dt: TNaiveDateTime; ok: Boolean;
begin
  ok := StrptimeDateTime('2024-06-15T14:30:45', '%Y-%m-%dT%H:%M:%S', Dt);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(2024, Dt.GetYear);
  CheckEquals(6, Dt.GetMonth);
  CheckEquals(15, Dt.GetDay);
  CheckEquals(14, Dt.GetHour);
  CheckEquals(30, Dt.GetMinute);
  CheckEquals(45, Dt.GetSecond);
end;

procedure TTestCase_Strptime.Test_ParseDateTime_Custom;
var Dt: TNaiveDateTime; ok: Boolean;
begin
  ok := StrptimeDateTime('15/06/2024 02:30 PM', '%d/%m/%Y %I:%M %p', Dt);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(2024, Dt.GetYear);
  CheckEquals(6, Dt.GetMonth);
  CheckEquals(15, Dt.GetDay);
  CheckEquals(14, Dt.GetHour);
  CheckEquals(30, Dt.GetMinute);
end;

// === 边界情况 ===

procedure TTestCase_Strptime.Test_Parse_InvalidFormat;
var D: TDate; ok: Boolean;
begin
  ok := StrptimeDate('not-a-date', '%Y-%m-%d', D);
  CheckFalse(ok, 'Parse should fail for invalid input');
end;

procedure TTestCase_Strptime.Test_Parse_PartialMatch;
var D: TDate; ok: Boolean;
begin
  // 输入比格式短
  ok := StrptimeDate('2024-06', '%Y-%m-%d', D);
  CheckFalse(ok, 'Parse should fail for partial input');
end;

// === 往返测试 ===

procedure TTestCase_Strptime.Test_Roundtrip_Date;
var D1, D2: TDate; s: string; ok: Boolean;
begin
  D1 := TDate.Create(2024, 6, 15);
  s := StrftimeDate(D1, '%Y-%m-%d');
  ok := StrptimeDate(s, '%Y-%m-%d', D2);
  CheckTrue(ok, 'Roundtrip parse should succeed');
  CheckEquals(D1.GetYear, D2.GetYear);
  CheckEquals(D1.GetMonth, D2.GetMonth);
  CheckEquals(D1.GetDay, D2.GetDay);
end;

procedure TTestCase_Strptime.Test_Roundtrip_Time;
var T1, T2: TTimeOfDay; s: string; ok: Boolean;
begin
  T1 := TTimeOfDay.Create(14, 30, 45);
  s := StrftimeTime(T1, '%H:%M:%S');
  ok := StrptimeTime(s, '%H:%M:%S', T2);
  CheckTrue(ok, 'Roundtrip parse should succeed');
  CheckEquals(T1.GetHour, T2.GetHour);
  CheckEquals(T1.GetMinute, T2.GetMinute);
  CheckEquals(T1.GetSecond, T2.GetSecond);
end;

procedure TTestCase_Strptime.Test_Roundtrip_DateTime;
var Dt1, Dt2: TNaiveDateTime; s: string; ok: Boolean;
begin
  Dt1 := TNaiveDateTime.Create(2024, 6, 15, 14, 30, 45, 0);
  s := StrftimeDateTime(Dt1, '%Y-%m-%dT%H:%M:%S');
  ok := StrptimeDateTime(s, '%Y-%m-%dT%H:%M:%S', Dt2);
  CheckTrue(ok, 'Roundtrip parse should succeed');
  CheckEquals(Dt1.GetYear, Dt2.GetYear);
  CheckEquals(Dt1.GetMonth, Dt2.GetMonth);
  CheckEquals(Dt1.GetDay, Dt2.GetDay);
  CheckEquals(Dt1.GetHour, Dt2.GetHour);
  CheckEquals(Dt1.GetMinute, Dt2.GetMinute);
  CheckEquals(Dt1.GetSecond, Dt2.GetSecond);
end;

initialization
  RegisterTest(TTestCase_Strptime);
end.
