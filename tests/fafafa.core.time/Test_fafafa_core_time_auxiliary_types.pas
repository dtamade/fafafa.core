unit Test_fafafa_core_time_auxiliary_types;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time,
  fafafa.core.time.monthday,
  fafafa.core.time.yearmonth;

type

  { TTestCase_MonthDay }

  TTestCase_MonthDay = class(TTestCase)
  published
    // 创建和基本属性
    procedure Test_MonthDay_Create_Valid;
    procedure Test_MonthDay_Create_InvalidMonth_Raises;
    procedure Test_MonthDay_Create_InvalidDay_Raises;
    procedure Test_MonthDay_Month_Day_Properties;
    
    // 预定义常量
    procedure Test_MonthDay_NewYear;
    procedure Test_MonthDay_Christmas;
    procedure Test_MonthDay_LeapDay;
    
    // 年份映射
    procedure Test_MonthDay_AtYear_Normal;
    procedure Test_MonthDay_AtYear_Feb29_LeapYear;
    procedure Test_MonthDay_AtYear_Feb29_NonLeapYear_Raises;
    
    // 验证方法
    procedure Test_MonthDay_IsValidInYear_Feb29;
    procedure Test_MonthDay_IsValidInYear_Feb28;
    procedure Test_MonthDay_IsValidInYear_Jan31;
    
    // 比较运算
    procedure Test_MonthDay_Equal;
    procedure Test_MonthDay_LessThan;
    procedure Test_MonthDay_GreaterThan;
    
    // 格式化
    procedure Test_MonthDay_ToString;
    procedure Test_MonthDay_Parse_Valid;
    procedure Test_MonthDay_Parse_Invalid;
  end;

  { TTestCase_YearMonth }

  TTestCase_YearMonth = class(TTestCase)
  published
    // 创建和基本属性
    procedure Test_YearMonth_Create_Valid;
    procedure Test_YearMonth_Create_InvalidMonth_Raises;
    procedure Test_YearMonth_Year_Month_Properties;
    
    // 当前时间
    procedure Test_YearMonth_Now;
    
    // 日期映射
    procedure Test_YearMonth_AtDay_Valid;
    procedure Test_YearMonth_AtDay_Invalid_Raises;
    procedure Test_YearMonth_AtEndOfMonth_Normal;
    procedure Test_YearMonth_AtEndOfMonth_February;
    procedure Test_YearMonth_AtEndOfMonth_LeapYear;
    procedure Test_YearMonth_FirstDay;
    
    // 月份信息
    procedure Test_YearMonth_DaysInMonth_January;
    procedure Test_YearMonth_DaysInMonth_February_Normal;
    procedure Test_YearMonth_DaysInMonth_February_LeapYear;
    procedure Test_YearMonth_DaysInMonth_April;
    
    // 算术运算
    procedure Test_YearMonth_AddMonths_Positive;
    procedure Test_YearMonth_AddMonths_Negative;
    procedure Test_YearMonth_AddMonths_YearRollover;
    procedure Test_YearMonth_SubMonths;
    procedure Test_YearMonth_AddYears;
    procedure Test_YearMonth_SubYears;
    
    // 比较运算
    procedure Test_YearMonth_Equal;
    procedure Test_YearMonth_LessThan;
    procedure Test_YearMonth_GreaterThan;
    
    // 格式化
    procedure Test_YearMonth_ToString;
    procedure Test_YearMonth_Parse_Valid;
    procedure Test_YearMonth_Parse_Invalid;
    
    // 迭代
    procedure Test_YearMonth_Next;
    procedure Test_YearMonth_Prev;
  end;

implementation

{ TTestCase_MonthDay }

procedure TTestCase_MonthDay.Test_MonthDay_Create_Valid;
var
  md: TMonthDay;
begin
  md := TMonthDay.Create(3, 15);  // March 15
  AssertEquals(3, md.Month);
  AssertEquals(15, md.Day);
end;

procedure TTestCase_MonthDay.Test_MonthDay_Create_InvalidMonth_Raises;
var
  md: TMonthDay;
  Raised: Boolean;
begin
  Raised := False;
  try
    md := TMonthDay.Create(13, 1);  // Invalid month
  except
    on E: EArgumentException do
      Raised := True;
  end;
  AssertTrue('Should raise for invalid month', Raised);
end;

procedure TTestCase_MonthDay.Test_MonthDay_Create_InvalidDay_Raises;
var
  md: TMonthDay;
  Raised: Boolean;
begin
  Raised := False;
  try
    md := TMonthDay.Create(1, 32);  // Invalid day for January
  except
    on E: EArgumentException do
      Raised := True;
  end;
  AssertTrue('Should raise for invalid day', Raised);
end;

procedure TTestCase_MonthDay.Test_MonthDay_Month_Day_Properties;
var
  md: TMonthDay;
begin
  md := TMonthDay.Create(12, 25);
  AssertEquals(12, md.Month);
  AssertEquals(25, md.Day);
end;

procedure TTestCase_MonthDay.Test_MonthDay_NewYear;
var
  md: TMonthDay;
begin
  md := TMonthDay.NewYear;
  AssertEquals(1, md.Month);
  AssertEquals(1, md.Day);
end;

procedure TTestCase_MonthDay.Test_MonthDay_Christmas;
var
  md: TMonthDay;
begin
  md := TMonthDay.Christmas;
  AssertEquals(12, md.Month);
  AssertEquals(25, md.Day);
end;

procedure TTestCase_MonthDay.Test_MonthDay_LeapDay;
var
  md: TMonthDay;
begin
  md := TMonthDay.LeapDay;
  AssertEquals(2, md.Month);
  AssertEquals(29, md.Day);
end;

procedure TTestCase_MonthDay.Test_MonthDay_AtYear_Normal;
var
  md: TMonthDay;
  d: TDate;
begin
  md := TMonthDay.Create(7, 4);  // July 4
  d := md.AtYear(2024);
  AssertEquals(2024, d.GetYear);
  AssertEquals(7, d.GetMonth);
  AssertEquals(4, d.GetDay);
end;

procedure TTestCase_MonthDay.Test_MonthDay_AtYear_Feb29_LeapYear;
var
  md: TMonthDay;
  d: TDate;
begin
  md := TMonthDay.LeapDay;  // Feb 29
  d := md.AtYear(2024);     // 2024 is a leap year
  AssertEquals(2024, d.GetYear);
  AssertEquals(2, d.GetMonth);
  AssertEquals(29, d.GetDay);
end;

procedure TTestCase_MonthDay.Test_MonthDay_AtYear_Feb29_NonLeapYear_Raises;
var
  md: TMonthDay;
  d: TDate;
  Raised: Boolean;
begin
  Raised := False;
  md := TMonthDay.LeapDay;  // Feb 29
  try
    d := md.AtYear(2023);   // 2023 is not a leap year
  except
    on E: EArgumentException do
      Raised := True;
  end;
  AssertTrue('Should raise for Feb 29 in non-leap year', Raised);
end;

procedure TTestCase_MonthDay.Test_MonthDay_IsValidInYear_Feb29;
var
  md: TMonthDay;
begin
  md := TMonthDay.LeapDay;
  AssertTrue('Feb 29 valid in 2024', md.IsValidInYear(2024));
  AssertFalse('Feb 29 invalid in 2023', md.IsValidInYear(2023));
  AssertTrue('Feb 29 valid in 2000', md.IsValidInYear(2000));
  AssertFalse('Feb 29 invalid in 1900', md.IsValidInYear(1900));
end;

procedure TTestCase_MonthDay.Test_MonthDay_IsValidInYear_Feb28;
var
  md: TMonthDay;
begin
  md := TMonthDay.Create(2, 28);
  AssertTrue('Feb 28 always valid', md.IsValidInYear(2023));
  AssertTrue('Feb 28 always valid', md.IsValidInYear(2024));
end;

procedure TTestCase_MonthDay.Test_MonthDay_IsValidInYear_Jan31;
var
  md: TMonthDay;
begin
  md := TMonthDay.Create(1, 31);
  AssertTrue('Jan 31 always valid', md.IsValidInYear(2023));
  AssertTrue('Jan 31 always valid', md.IsValidInYear(2024));
end;

procedure TTestCase_MonthDay.Test_MonthDay_Equal;
var
  md1, md2, md3: TMonthDay;
begin
  md1 := TMonthDay.Create(3, 15);
  md2 := TMonthDay.Create(3, 15);
  md3 := TMonthDay.Create(3, 16);
  AssertTrue('Same should be equal', md1 = md2);
  AssertFalse('Different should not be equal', md1 = md3);
end;

procedure TTestCase_MonthDay.Test_MonthDay_LessThan;
var
  jan1, feb1, jan15: TMonthDay;
begin
  jan1 := TMonthDay.Create(1, 1);
  feb1 := TMonthDay.Create(2, 1);
  jan15 := TMonthDay.Create(1, 15);
  
  AssertTrue('Jan < Feb', jan1 < feb1);
  AssertTrue('Jan 1 < Jan 15', jan1 < jan15);
  AssertFalse('Feb not < Jan', feb1 < jan1);
end;

procedure TTestCase_MonthDay.Test_MonthDay_GreaterThan;
var
  jan1, dec25: TMonthDay;
begin
  jan1 := TMonthDay.Create(1, 1);
  dec25 := TMonthDay.Christmas;
  
  AssertTrue('Dec > Jan', dec25 > jan1);
  AssertFalse('Jan not > Dec', jan1 > dec25);
end;

procedure TTestCase_MonthDay.Test_MonthDay_ToString;
var
  md: TMonthDay;
begin
  md := TMonthDay.Create(3, 15);
  AssertEquals('--03-15', md.ToString);
  
  md := TMonthDay.Christmas;
  AssertEquals('--12-25', md.ToString);
end;

procedure TTestCase_MonthDay.Test_MonthDay_Parse_Valid;
var
  md: TMonthDay;
begin
  md := TMonthDay.Parse('--03-15');
  AssertEquals(3, md.Month);
  AssertEquals(15, md.Day);
  
  md := TMonthDay.Parse('--12-25');
  AssertEquals(12, md.Month);
  AssertEquals(25, md.Day);
end;

procedure TTestCase_MonthDay.Test_MonthDay_Parse_Invalid;
var
  md: TMonthDay;
  Raised: Boolean;
begin
  Raised := False;
  try
    md := TMonthDay.Parse('03-15');  // Missing --
  except
    on E: EConvertError do
      Raised := True;
  end;
  AssertTrue('Should raise for invalid format', Raised);
end;

{ TTestCase_YearMonth }

procedure TTestCase_YearMonth.Test_YearMonth_Create_Valid;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 3);
  AssertEquals(2024, ym.Year);
  AssertEquals(3, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_Create_InvalidMonth_Raises;
var
  ym: TYearMonth;
  Raised: Boolean;
begin
  Raised := False;
  try
    ym := TYearMonth.Create(2024, 0);
  except
    on E: EArgumentException do
      Raised := True;
  end;
  AssertTrue('Should raise for invalid month', Raised);
end;

procedure TTestCase_YearMonth.Test_YearMonth_Year_Month_Properties;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 12);
  AssertEquals(2024, ym.Year);
  AssertEquals(12, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_Now;
var
  ym: TYearMonth;
  today: TDate;
begin
  ym := TYearMonth.Now;
  today := NowDate;
  AssertEquals(today.GetYear, ym.Year);
  AssertEquals(today.GetMonth, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AtDay_Valid;
var
  ym: TYearMonth;
  d: TDate;
begin
  ym := TYearMonth.Create(2024, 3);
  d := ym.AtDay(15);
  AssertEquals(2024, d.GetYear);
  AssertEquals(3, d.GetMonth);
  AssertEquals(15, d.GetDay);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AtDay_Invalid_Raises;
var
  ym: TYearMonth;
  d: TDate;
  Raised: Boolean;
begin
  Raised := False;
  ym := TYearMonth.Create(2024, 2);  // February
  try
    d := ym.AtDay(30);  // Invalid day
  except
    on E: EArgumentException do
      Raised := True;
  end;
  AssertTrue('Should raise for invalid day in month', Raised);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AtEndOfMonth_Normal;
var
  ym: TYearMonth;
  d: TDate;
begin
  ym := TYearMonth.Create(2024, 1);  // January
  d := ym.AtEndOfMonth;
  AssertEquals(31, d.GetDay);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AtEndOfMonth_February;
var
  ym: TYearMonth;
  d: TDate;
begin
  ym := TYearMonth.Create(2023, 2);  // February non-leap
  d := ym.AtEndOfMonth;
  AssertEquals(28, d.GetDay);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AtEndOfMonth_LeapYear;
var
  ym: TYearMonth;
  d: TDate;
begin
  ym := TYearMonth.Create(2024, 2);  // February leap year
  d := ym.AtEndOfMonth;
  AssertEquals(29, d.GetDay);
end;

procedure TTestCase_YearMonth.Test_YearMonth_FirstDay;
var
  ym: TYearMonth;
  d: TDate;
begin
  ym := TYearMonth.Create(2024, 7);
  d := ym.FirstDay;
  AssertEquals(2024, d.GetYear);
  AssertEquals(7, d.GetMonth);
  AssertEquals(1, d.GetDay);
end;

procedure TTestCase_YearMonth.Test_YearMonth_DaysInMonth_January;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 1);
  AssertEquals(31, ym.DaysInMonth);
end;

procedure TTestCase_YearMonth.Test_YearMonth_DaysInMonth_February_Normal;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2023, 2);
  AssertEquals(28, ym.DaysInMonth);
end;

procedure TTestCase_YearMonth.Test_YearMonth_DaysInMonth_February_LeapYear;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 2);
  AssertEquals(29, ym.DaysInMonth);
end;

procedure TTestCase_YearMonth.Test_YearMonth_DaysInMonth_April;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 4);
  AssertEquals(30, ym.DaysInMonth);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AddMonths_Positive;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 3);
  ym := ym.AddMonths(2);
  AssertEquals(2024, ym.Year);
  AssertEquals(5, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AddMonths_Negative;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 3);
  ym := ym.AddMonths(-2);
  AssertEquals(2024, ym.Year);
  AssertEquals(1, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AddMonths_YearRollover;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 11);
  ym := ym.AddMonths(3);  // Nov + 3 = Feb next year
  AssertEquals(2025, ym.Year);
  AssertEquals(2, ym.Month);
  
  // Test negative rollover
  ym := TYearMonth.Create(2024, 2);
  ym := ym.AddMonths(-3);  // Feb - 3 = Nov prev year
  AssertEquals(2023, ym.Year);
  AssertEquals(11, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_SubMonths;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 5);
  ym := ym.SubMonths(2);
  AssertEquals(2024, ym.Year);
  AssertEquals(3, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_AddYears;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 3);
  ym := ym.AddYears(2);
  AssertEquals(2026, ym.Year);
  AssertEquals(3, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_SubYears;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 3);
  ym := ym.SubYears(2);
  AssertEquals(2022, ym.Year);
  AssertEquals(3, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_Equal;
var
  ym1, ym2, ym3: TYearMonth;
begin
  ym1 := TYearMonth.Create(2024, 3);
  ym2 := TYearMonth.Create(2024, 3);
  ym3 := TYearMonth.Create(2024, 4);
  AssertTrue('Same should be equal', ym1 = ym2);
  AssertFalse('Different should not be equal', ym1 = ym3);
end;

procedure TTestCase_YearMonth.Test_YearMonth_LessThan;
var
  ym1, ym2, ym3: TYearMonth;
begin
  ym1 := TYearMonth.Create(2024, 3);
  ym2 := TYearMonth.Create(2024, 5);
  ym3 := TYearMonth.Create(2025, 1);
  
  AssertTrue('Same year, earlier month', ym1 < ym2);
  AssertTrue('Earlier year', ym1 < ym3);
  AssertFalse('Not less than self', ym1 < ym1);
end;

procedure TTestCase_YearMonth.Test_YearMonth_GreaterThan;
var
  ym1, ym2: TYearMonth;
begin
  ym1 := TYearMonth.Create(2024, 12);
  ym2 := TYearMonth.Create(2024, 1);
  
  AssertTrue('Dec > Jan same year', ym1 > ym2);
  AssertFalse('Jan not > Dec', ym2 > ym1);
end;

procedure TTestCase_YearMonth.Test_YearMonth_ToString;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 3);
  AssertEquals('2024-03', ym.ToString);
  
  ym := TYearMonth.Create(2024, 12);
  AssertEquals('2024-12', ym.ToString);
end;

procedure TTestCase_YearMonth.Test_YearMonth_Parse_Valid;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Parse('2024-03');
  AssertEquals(2024, ym.Year);
  AssertEquals(3, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_Parse_Invalid;
var
  ym: TYearMonth;
  Raised: Boolean;
begin
  Raised := False;
  try
    ym := TYearMonth.Parse('2024/03');  // Wrong separator
  except
    on E: EConvertError do
      Raised := True;
  end;
  AssertTrue('Should raise for invalid format', Raised);
end;

procedure TTestCase_YearMonth.Test_YearMonth_Next;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 12);
  ym := ym.Next;
  AssertEquals(2025, ym.Year);
  AssertEquals(1, ym.Month);
end;

procedure TTestCase_YearMonth.Test_YearMonth_Prev;
var
  ym: TYearMonth;
begin
  ym := TYearMonth.Create(2024, 1);
  ym := ym.Prev;
  AssertEquals(2023, ym.Year);
  AssertEquals(12, ym.Month);
end;

initialization
  RegisterTest(TTestCase_MonthDay);
  RegisterTest(TTestCase_YearMonth);

end.
