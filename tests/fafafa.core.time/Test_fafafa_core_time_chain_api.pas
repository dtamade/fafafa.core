unit Test_fafafa_core_time_chain_api;

{$mode objfpc}{$H+}

{
  Test: Phase 2 - 链式构建器 API 测试
  
  目标：
  - 验证 TDate.AndTime 方法
  - 验证 TTimeOfDay.OnDate 方法
  - 验证构建器类（TDateBuilder, TTimeBuilder, TDateTimeBuilder）
  
  遵循 TDD 规范：此测试先于实现编写
}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time,
  fafafa.core.time.helpers,   // 提供 AndTime, OnDate 等链式方法
  fafafa.core.time.builders;  // 提供 TDateBuilder, TTimeBuilder, TDateTimeBuilder

type
  TTestCase_ChainAPI = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // TDate.AndTime 测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Date_AndTime_Basic;
    procedure Test_Date_AndTime_Midnight;
    procedure Test_Date_AndTime_EndOfDay;
    procedure Test_Date_AndTime_WithNanoseconds;
    
    // ═══════════════════════════════════════════════════════════════
    // TTimeOfDay.OnDate 测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Time_OnDate_Basic;
    procedure Test_Time_OnDate_Midnight;
    procedure Test_Time_OnDate_Noon;
    procedure Test_Time_OnDate_LeapYear;
    
    // ═══════════════════════════════════════════════════════════════
    // TDateBuilder 测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_DateBuilder_Basic;
    procedure Test_DateBuilder_ChainCalls;
    procedure Test_DateBuilder_WithDefaults;
    procedure Test_DateBuilder_LeapYear;
    procedure Test_DateBuilder_EndOfMonth;
    procedure Test_DateBuilder_InvalidDate_Raises;
    
    // ═══════════════════════════════════════════════════════════════
    // TTimeBuilder 测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_TimeBuilder_Basic;
    procedure Test_TimeBuilder_ChainCalls;
    procedure Test_TimeBuilder_WithNanoseconds;
    procedure Test_TimeBuilder_WithDefaults;
    procedure Test_TimeBuilder_EndOfDay;
    procedure Test_TimeBuilder_InvalidTime_Raises;
    
    // ═══════════════════════════════════════════════════════════════
    // TDateTimeBuilder 测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_DateTimeBuilder_FromComponents;
    procedure Test_DateTimeBuilder_FromDateAndTime;
    procedure Test_DateTimeBuilder_ChainCalls;
    procedure Test_DateTimeBuilder_WithOffset;
    procedure Test_DateTimeBuilder_BuildNaive;
    procedure Test_DateTimeBuilder_BuildZoned;
  end;

implementation

{ TTestCase_ChainAPI }

// ═══════════════════════════════════════════════════════════════
// TDate.AndTime 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChainAPI.Test_Date_AndTime_Basic;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  D := TDate.Create(2024, 1, 15);
  T := TTimeOfDay.Create(14, 30, 45);
  
  DT := D.AndTime(T);
  
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Month should be 1', 1, DT.Month);
  AssertEquals('Day should be 15', 15, DT.Day);
  AssertEquals('Hour should be 14', 14, DT.Hour);
  AssertEquals('Minute should be 30', 30, DT.Minute);
  AssertEquals('Second should be 45', 45, DT.Second);
end;

procedure TTestCase_ChainAPI.Test_Date_AndTime_Midnight;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  D := TDate.Create(2024, 12, 25);
  T := TTimeOfDay.Midnight;
  
  DT := D.AndTime(T);
  
  AssertEquals('Hour should be 0', 0, DT.Hour);
  AssertEquals('Minute should be 0', 0, DT.Minute);
  AssertEquals('Second should be 0', 0, DT.Second);
end;

procedure TTestCase_ChainAPI.Test_Date_AndTime_EndOfDay;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  D := TDate.Create(2024, 6, 30);
  T := TTimeOfDay.Create(23, 59, 59, 999);
  
  DT := D.AndTime(T);
  
  AssertEquals('Hour should be 23', 23, DT.Hour);
  AssertEquals('Minute should be 59', 59, DT.Minute);
  AssertEquals('Second should be 59', 59, DT.Second);
end;

procedure TTestCase_ChainAPI.Test_Date_AndTime_WithNanoseconds;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  D := TDate.Create(2024, 3, 14);
  T := TTimeOfDay.CreateNs(9, 26, 53, 589793238);  // Pi second!
  
  DT := D.AndTime(T);
  
  AssertEquals('Hour should be 9', 9, DT.Hour);
  AssertEquals('Minute should be 26', 26, DT.Minute);
  AssertEquals('Second should be 53', 53, DT.Second);
  // Nanosecond precision test
  AssertTrue('Nanosecond should be preserved', DT.Nanosecond > 0);
end;

// ═══════════════════════════════════════════════════════════════
// TTimeOfDay.OnDate 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChainAPI.Test_Time_OnDate_Basic;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  T := TTimeOfDay.Create(10, 15, 30);
  D := TDate.Create(2024, 7, 4);
  
  DT := T.OnDate(D);
  
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Month should be 7', 7, DT.Month);
  AssertEquals('Day should be 4', 4, DT.Day);
  AssertEquals('Hour should be 10', 10, DT.Hour);
  AssertEquals('Minute should be 15', 15, DT.Minute);
  AssertEquals('Second should be 30', 30, DT.Second);
end;

procedure TTestCase_ChainAPI.Test_Time_OnDate_Midnight;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  T := TTimeOfDay.Midnight;
  D := TDate.Create(2024, 1, 1);
  
  DT := T.OnDate(D);
  
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Month should be 1', 1, DT.Month);
  AssertEquals('Day should be 1', 1, DT.Day);
  AssertEquals('Hour should be 0', 0, DT.Hour);
end;

procedure TTestCase_ChainAPI.Test_Time_OnDate_Noon;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  T := TTimeOfDay.Noon;
  D := TDate.Create(2024, 6, 21);  // Summer solstice
  
  DT := T.OnDate(D);
  
  AssertEquals('Hour should be 12', 12, DT.Hour);
  AssertEquals('Minute should be 0', 0, DT.Minute);
end;

procedure TTestCase_ChainAPI.Test_Time_OnDate_LeapYear;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  T := TTimeOfDay.Create(12, 0, 0);
  D := TDate.Create(2024, 2, 29);  // Leap day
  
  DT := T.OnDate(D);
  
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Month should be 2', 2, DT.Month);
  AssertEquals('Day should be 29', 29, DT.Day);
  AssertEquals('Hour should be 12', 12, DT.Hour);
end;

// ═══════════════════════════════════════════════════════════════
// TDateBuilder 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChainAPI.Test_DateBuilder_Basic;
var
  D: TDate;
begin
  // DateBuilder.Year(2024).Month(1).Day(15).Build → TDate
  D := DateBuilder.Year(2024).Month(1).Day(15).Build;
  
  AssertEquals('Year should be 2024', 2024, D.GetYear);
  AssertEquals('Month should be 1', 1, D.GetMonth);
  AssertEquals('Day should be 15', 15, D.GetDay);
end;

procedure TTestCase_ChainAPI.Test_DateBuilder_ChainCalls;
var
  D: TDate;
begin
  // 任意顺序的链式调用
  D := DateBuilder.Month(12).Day(25).Year(2024).Build;
  
  AssertEquals('Year should be 2024', 2024, D.GetYear);
  AssertEquals('Month should be 12', 12, D.GetMonth);
  AssertEquals('Day should be 25', 25, D.GetDay);
end;

procedure TTestCase_ChainAPI.Test_DateBuilder_WithDefaults;
var
  D: TDate;
begin
  // 只设置年份，其他默认为 1
  D := DateBuilder.Year(2024).Build;
  
  AssertEquals('Year should be 2024', 2024, D.GetYear);
  AssertEquals('Month should default to 1', 1, D.GetMonth);
  AssertEquals('Day should default to 1', 1, D.GetDay);
end;

procedure TTestCase_ChainAPI.Test_DateBuilder_LeapYear;
var
  D: TDate;
begin
  // 闰年 2 月 29 日
  D := DateBuilder.Year(2024).Month(2).Day(29).Build;
  
  AssertEquals('Year should be 2024', 2024, D.GetYear);
  AssertEquals('Month should be 2', 2, D.GetMonth);
  AssertEquals('Day should be 29', 29, D.GetDay);
  AssertTrue('2024 should be leap year', D.IsLeapYear);
end;

procedure TTestCase_ChainAPI.Test_DateBuilder_EndOfMonth;
var
  D: TDate;
begin
  // 月末
  D := DateBuilder.Year(2024).Month(1).Day(31).Build;
  
  AssertTrue('Should be last day of month', D.IsLastDayOfMonth);
end;

procedure TTestCase_ChainAPI.Test_DateBuilder_InvalidDate_Raises;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    // 非闰年 2 月 29 日，应该抛异常
    DateBuilder.Year(2023).Month(2).Day(29).Build;
  except
    on E: Exception do
      LRaised := True;
  end;
  AssertTrue('Should raise exception for invalid date', LRaised);
end;

// ═══════════════════════════════════════════════════════════════
// TTimeBuilder 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChainAPI.Test_TimeBuilder_Basic;
var
  T: TTimeOfDay;
begin
  // TimeBuilder.Hour(14).Minute(30).Second(45).Build → TTimeOfDay
  T := TimeBuilder.Hour(14).Minute(30).Second(45).Build;
  
  AssertEquals('Hour should be 14', 14, T.GetHour);
  AssertEquals('Minute should be 30', 30, T.GetMinute);
  AssertEquals('Second should be 45', 45, T.GetSecond);
end;

procedure TTestCase_ChainAPI.Test_TimeBuilder_ChainCalls;
var
  T: TTimeOfDay;
begin
  // 任意顺序
  T := TimeBuilder.Second(30).Hour(10).Minute(15).Build;
  
  AssertEquals('Hour should be 10', 10, T.GetHour);
  AssertEquals('Minute should be 15', 15, T.GetMinute);
  AssertEquals('Second should be 30', 30, T.GetSecond);
end;

procedure TTestCase_ChainAPI.Test_TimeBuilder_WithNanoseconds;
var
  T: TTimeOfDay;
begin
  // 纳秒精度
  T := TimeBuilder.Hour(9).Minute(26).Second(53).Nanosecond(589793238).Build;
  
  AssertEquals('Hour should be 9', 9, T.GetHour);
  AssertEquals('Minute should be 26', 26, T.GetMinute);
  AssertEquals('Second should be 53', 53, T.GetSecond);
  AssertTrue('Subsecond nanos should be preserved', T.GetSubsecondNanos > 0);
end;

procedure TTestCase_ChainAPI.Test_TimeBuilder_WithDefaults;
var
  T: TTimeOfDay;
begin
  // 只设置小时，其他默认为 0
  T := TimeBuilder.Hour(12).Build;
  
  AssertEquals('Hour should be 12', 12, T.GetHour);
  AssertEquals('Minute should default to 0', 0, T.GetMinute);
  AssertEquals('Second should default to 0', 0, T.GetSecond);
end;

procedure TTestCase_ChainAPI.Test_TimeBuilder_EndOfDay;
var
  T: TTimeOfDay;
begin
  // 23:59:59.999999999
  T := TimeBuilder.Hour(23).Minute(59).Second(59).Nanosecond(999999999).Build;
  
  AssertEquals('Hour should be 23', 23, T.GetHour);
  AssertEquals('Minute should be 59', 59, T.GetMinute);
  AssertEquals('Second should be 59', 59, T.GetSecond);
end;

procedure TTestCase_ChainAPI.Test_TimeBuilder_InvalidTime_Raises;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    // 无效时间：24:00:00
    TimeBuilder.Hour(24).Build;
  except
    on E: Exception do
      LRaised := True;
  end;
  AssertTrue('Should raise exception for invalid time', LRaised);
end;

// ═══════════════════════════════════════════════════════════════
// TDateTimeBuilder 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChainAPI.Test_DateTimeBuilder_FromComponents;
var
  DT: TNaiveDateTime;
begin
  // 直接从组件构建
  DT := DateTimeBuilder
    .Year(2024).Month(1).Day(15)
    .Hour(14).Minute(30).Second(45)
    .BuildNaive;
  
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Month should be 1', 1, DT.Month);
  AssertEquals('Day should be 15', 15, DT.Day);
  AssertEquals('Hour should be 14', 14, DT.Hour);
  AssertEquals('Minute should be 30', 30, DT.Minute);
  AssertEquals('Second should be 45', 45, DT.Second);
end;

procedure TTestCase_ChainAPI.Test_DateTimeBuilder_FromDateAndTime;
var
  D: TDate;
  T: TTimeOfDay;
  DT: TNaiveDateTime;
begin
  D := TDate.Create(2024, 7, 4);
  T := TTimeOfDay.Create(10, 30, 0);
  
  // 从日期和时间对象构建
  DT := DateTimeBuilder.Date(D).Time(T).BuildNaive;
  
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Month should be 7', 7, DT.Month);
  AssertEquals('Day should be 4', 4, DT.Day);
  AssertEquals('Hour should be 10', 10, DT.Hour);
  AssertEquals('Minute should be 30', 30, DT.Minute);
end;

procedure TTestCase_ChainAPI.Test_DateTimeBuilder_ChainCalls;
var
  DT: TNaiveDateTime;
begin
  // 任意顺序
  DT := DateTimeBuilder
    .Hour(12).Day(25).Month(12).Year(2024).Minute(0).Second(0)
    .BuildNaive;
  
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Month should be 12', 12, DT.Month);
  AssertEquals('Day should be 25', 25, DT.Day);
  AssertEquals('Hour should be 12', 12, DT.Hour);
end;

procedure TTestCase_ChainAPI.Test_DateTimeBuilder_WithOffset;
var
  ZDT: TZonedDateTime;
begin
  // 带时区偏移构建 TZonedDateTime
  ZDT := DateTimeBuilder
    .Year(2024).Month(1).Day(15)
    .Hour(14).Minute(30).Second(0)
    .AtOffset(TUtcOffset.FromHours(8))  // UTC+8 (北京时间)
    .BuildZoned;
  
  AssertEquals('Hour should be 14', 14, ZDT.Hour);
  AssertEquals('Offset hours should be 8', 8, ZDT.Offset.Hours);
end;

procedure TTestCase_ChainAPI.Test_DateTimeBuilder_BuildNaive;
var
  DT: TNaiveDateTime;
begin
  // 构建无时区日期时间
  DT := DateTimeBuilder
    .Year(2024).Month(6).Day(21)
    .Hour(12).Minute(0).Second(0)
    .BuildNaive;
  
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Month should be 6', 6, DT.Month);
  AssertEquals('Day should be 21', 21, DT.Day);
end;

procedure TTestCase_ChainAPI.Test_DateTimeBuilder_BuildZoned;
var
  ZDT: TZonedDateTime;
begin
  // 构建带时区日期时间（默认 UTC）
  ZDT := DateTimeBuilder
    .Year(2024).Month(1).Day(1)
    .Hour(0).Minute(0).Second(0)
    .BuildZoned;  // 默认 UTC
  
  AssertEquals('Year should be 2024', 2024, ZDT.Year);
  AssertTrue('Should be UTC by default', ZDT.Offset.IsUTC);
end;

initialization
  RegisterTest(TTestCase_ChainAPI);

end.
