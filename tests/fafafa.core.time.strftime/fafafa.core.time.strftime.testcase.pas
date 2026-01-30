unit fafafa.core.time.strftime.testcase;

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
  TTestCase_Strftime = class(TTestCase)
  published
    // === 日期格式化 ===
    procedure Test_FormatDate_Year4Digit;       // %Y -> 2024
    procedure Test_FormatDate_Year2Digit;       // %y -> 24
    procedure Test_FormatDate_Month2Digit;      // %m -> 06
    procedure Test_FormatDate_Day2Digit;        // %d -> 15
    procedure Test_FormatDate_DayOfYear;        // %j -> 167
    procedure Test_FormatDate_WeekdayName;      // %A -> Saturday
    procedure Test_FormatDate_WeekdayAbbr;      // %a -> Sat
    procedure Test_FormatDate_MonthName;        // %B -> June
    procedure Test_FormatDate_MonthAbbr;        // %b -> Jun
    
    // === 时间格式化 ===
    procedure Test_FormatTime_Hour24;           // %H -> 14
    procedure Test_FormatTime_Hour12;           // %I -> 02
    procedure Test_FormatTime_Minute;           // %M -> 30
    procedure Test_FormatTime_Second;           // %S -> 45
    procedure Test_FormatTime_AmPm;             // %p -> PM
    procedure Test_FormatTime_Millisecond;      // %f -> 123 (扩展)
    
    // === 组合格式 ===
    procedure Test_Format_ISO8601;              // %Y-%m-%dT%H:%M:%S
    procedure Test_Format_Custom;               // 自定义组合
    procedure Test_Format_EscapePercent;        // %% -> %
    
    // === DateTime 格式化 ===
    procedure Test_FormatDateTime_Full;
    
    // === 边界情况 ===
    procedure Test_Format_EmptyFormat;
    procedure Test_Format_NoSpecifiers;
    procedure Test_Format_UnknownSpecifier;
  end;

implementation

// 测试日期: 2024-06-15 (Saturday)
// 测试时间: 14:30:45.123

procedure TTestCase_Strftime.Test_FormatDate_Year4Digit;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('2024', StrftimeDate(D, '%Y'));
end;

procedure TTestCase_Strftime.Test_FormatDate_Year2Digit;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('24', StrftimeDate(D, '%y'));
end;

procedure TTestCase_Strftime.Test_FormatDate_Month2Digit;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('06', StrftimeDate(D, '%m'));
end;

procedure TTestCase_Strftime.Test_FormatDate_Day2Digit;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('15', StrftimeDate(D, '%d'));
end;

procedure TTestCase_Strftime.Test_FormatDate_DayOfYear;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  // 2024是闰年: 31+29+31+30+31+15 = 167
  CheckEquals('167', StrftimeDate(D, '%j'));
end;

procedure TTestCase_Strftime.Test_FormatDate_WeekdayName;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);  // Saturday
  CheckEquals('Saturday', StrftimeDate(D, '%A'));
end;

procedure TTestCase_Strftime.Test_FormatDate_WeekdayAbbr;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);  // Saturday
  CheckEquals('Sat', StrftimeDate(D, '%a'));
end;

procedure TTestCase_Strftime.Test_FormatDate_MonthName;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('June', StrftimeDate(D, '%B'));
end;

procedure TTestCase_Strftime.Test_FormatDate_MonthAbbr;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('Jun', StrftimeDate(D, '%b'));
end;

// === 时间格式化 ===

procedure TTestCase_Strftime.Test_FormatTime_Hour24;
var T: TTimeOfDay;
begin
  T := TTimeOfDay.Create(14, 30, 45);
  CheckEquals('14', StrftimeTime(T, '%H'));
end;

procedure TTestCase_Strftime.Test_FormatTime_Hour12;
var T: TTimeOfDay;
begin
  T := TTimeOfDay.Create(14, 30, 45);
  CheckEquals('02', StrftimeTime(T, '%I'));
end;

procedure TTestCase_Strftime.Test_FormatTime_Minute;
var T: TTimeOfDay;
begin
  T := TTimeOfDay.Create(14, 30, 45);
  CheckEquals('30', StrftimeTime(T, '%M'));
end;

procedure TTestCase_Strftime.Test_FormatTime_Second;
var T: TTimeOfDay;
begin
  T := TTimeOfDay.Create(14, 30, 45);
  CheckEquals('45', StrftimeTime(T, '%S'));
end;

procedure TTestCase_Strftime.Test_FormatTime_AmPm;
var T: TTimeOfDay;
begin
  T := TTimeOfDay.Create(14, 30, 45);
  CheckEquals('PM', StrftimeTime(T, '%p'));
  
  T := TTimeOfDay.Create(9, 30, 45);
  CheckEquals('AM', StrftimeTime(T, '%p'));
end;

procedure TTestCase_Strftime.Test_FormatTime_Millisecond;
var T: TTimeOfDay;
begin
  T := TTimeOfDay.Create(14, 30, 45, 123);
  CheckEquals('123', StrftimeTime(T, '%f'));
end;

// === 组合格式 ===

procedure TTestCase_Strftime.Test_Format_ISO8601;
var Dt: TNaiveDateTime;
begin
  Dt := TNaiveDateTime.Create(2024, 6, 15, 14, 30, 45, 0);
  CheckEquals('2024-06-15T14:30:45', StrftimeDateTime(Dt, '%Y-%m-%dT%H:%M:%S'));
end;

procedure TTestCase_Strftime.Test_Format_Custom;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('Sat, 15 Jun 2024', StrftimeDate(D, '%a, %d %b %Y'));
end;

procedure TTestCase_Strftime.Test_Format_EscapePercent;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('100%', StrftimeDate(D, '100%%'));
end;

// === DateTime 格式化 ===

procedure TTestCase_Strftime.Test_FormatDateTime_Full;
var Dt: TNaiveDateTime;
begin
  Dt := TNaiveDateTime.Create(2024, 6, 15, 14, 30, 45, 0);
  CheckEquals('Saturday, June 15, 2024 02:30:45 PM', 
    StrftimeDateTime(Dt, '%A, %B %d, %Y %I:%M:%S %p'));
end;

// === 边界情况 ===

procedure TTestCase_Strftime.Test_Format_EmptyFormat;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('', StrftimeDate(D, ''));
end;

procedure TTestCase_Strftime.Test_Format_NoSpecifiers;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  CheckEquals('Hello World', StrftimeDate(D, 'Hello World'));
end;

procedure TTestCase_Strftime.Test_Format_UnknownSpecifier;
var D: TDate;
begin
  D := TDate.Create(2024, 6, 15);
  // 未知的说明符保持原样
  CheckEquals('%Q', StrftimeDate(D, '%Q'));
end;

initialization
  RegisterTest(TTestCase_Strftime);
end.
