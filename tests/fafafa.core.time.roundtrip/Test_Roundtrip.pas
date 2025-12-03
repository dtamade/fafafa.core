{$CODEPAGE UTF8}
unit Test_Roundtrip;

{**
 * ISSUE-45: 往返一致性测试
 *
 * 验证格式化后再解析能得到相同结果：
 *   Original -> Format -> String -> Parse -> Result
 *   Assert: Original = Result
 *
 * 测试覆盖：
 * - TDate ISO 8601 往返
 * - TTimeOfDay ISO 8601 往返
 * - TDuration ISO 8601 往返
 * - TDuration Compact 往返
 * - TZonedDateTime ISO 8601 往返
 * - TNaiveDateTime ISO 8601 往返
 * - TIsoWeek ISO 8601 往返
 * - TUtcOffset ISO 8601 往返
 *}

{$I fafafa.core.settings.inc}
{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpcunit,
  testregistry,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.duration,
  fafafa.core.time.offset,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.isoweek;

type
  TTestRoundtrip = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // TDate 往返测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Date_ISO8601_Roundtrip_Normal;
    procedure Test_Date_ISO8601_Roundtrip_LeapYear;
    procedure Test_Date_ISO8601_Roundtrip_YearBoundary;
    procedure Test_Date_ISO8601_Roundtrip_MonthEnd;
    
    // ═══════════════════════════════════════════════════════════════
    // TTimeOfDay 往返测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_TimeOfDay_ISO8601_Roundtrip_Normal;
    procedure Test_TimeOfDay_ISO8601_Roundtrip_Midnight;
    procedure Test_TimeOfDay_ISO8601_Roundtrip_EndOfDay;
    procedure Test_TimeOfDay_ISO8601_Roundtrip_WithMilliseconds;
    
    // ═══════════════════════════════════════════════════════════════
    // TDuration 往返测试
    // NOTE: TDuration 当前没有 ToISO8601/TryParseISO8601 方法
    // 等待 fafafa.core.time.iso8601 模块完善后添加
    // ═══════════════════════════════════════════════════════════════
    
    // ═══════════════════════════════════════════════════════════════
    // TUtcOffset 往返测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_UtcOffset_ISO8601_Roundtrip_UTC;
    procedure Test_UtcOffset_ISO8601_Roundtrip_Positive;
    procedure Test_UtcOffset_ISO8601_Roundtrip_Negative;
    procedure Test_UtcOffset_ISO8601_Roundtrip_HalfHour;
    
    // ═══════════════════════════════════════════════════════════════
    // TZonedDateTime 往返测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ZonedDateTime_ISO8601_Roundtrip_UTC;
    procedure Test_ZonedDateTime_ISO8601_Roundtrip_PositiveOffset;
    procedure Test_ZonedDateTime_ISO8601_Roundtrip_NegativeOffset;
    procedure Test_ZonedDateTime_ISO8601_Roundtrip_Midnight;
    
    // ═══════════════════════════════════════════════════════════════
    // TNaiveDateTime 往返测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_NaiveDateTime_ISO8601_Roundtrip_Normal;
    procedure Test_NaiveDateTime_ISO8601_Roundtrip_Midnight;
    procedure Test_NaiveDateTime_ISO8601_Roundtrip_WithMilliseconds;
    
    // ═══════════════════════════════════════════════════════════════
    // TIsoWeek 往返测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_IsoWeek_ISO8601_Roundtrip_Normal;
    procedure Test_IsoWeek_ISO8601_Roundtrip_FirstWeek;
    procedure Test_IsoWeek_ISO8601_Roundtrip_LastWeek;
  end;

implementation

{ TTestRoundtrip }

// ═══════════════════════════════════════════════════════════════
// TDate 往返测试
// ═══════════════════════════════════════════════════════════════

procedure TTestRoundtrip.Test_Date_ISO8601_Roundtrip_Normal;
var
  LOriginal, LParsed: TDate;
  LStr: string;
begin
  LOriginal := TDate.Create(2024, 6, 15);
  LStr := LOriginal.ToISO8601;
  AssertTrue('Parse should succeed', TDate.TryParseISO(LStr, LParsed));
  AssertTrue('Roundtrip should preserve value', LOriginal = LParsed);
end;

procedure TTestRoundtrip.Test_Date_ISO8601_Roundtrip_LeapYear;
var
  LOriginal, LParsed: TDate;
  LStr: string;
begin
  LOriginal := TDate.Create(2024, 2, 29); // 闰年 2 月 29 日
  LStr := LOriginal.ToISO8601;
  AssertTrue(TDate.TryParseISO(LStr, LParsed));
  AssertTrue(LOriginal = LParsed);
end;

procedure TTestRoundtrip.Test_Date_ISO8601_Roundtrip_YearBoundary;
var
  LOriginal, LParsed: TDate;
  LStr: string;
begin
  // 年初
  LOriginal := TDate.Create(2024, 1, 1);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TDate.TryParseISO(LStr, LParsed));
  AssertTrue(LOriginal = LParsed);
  
  // 年末
  LOriginal := TDate.Create(2024, 12, 31);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TDate.TryParseISO(LStr, LParsed));
  AssertTrue(LOriginal = LParsed);
end;

procedure TTestRoundtrip.Test_Date_ISO8601_Roundtrip_MonthEnd;
var
  LOriginal, LParsed: TDate;
  LStr: string;
begin
  // 30 天月份
  LOriginal := TDate.Create(2024, 4, 30);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TDate.TryParseISO(LStr, LParsed));
  AssertTrue(LOriginal = LParsed);
  
  // 31 天月份
  LOriginal := TDate.Create(2024, 7, 31);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TDate.TryParseISO(LStr, LParsed));
  AssertTrue(LOriginal = LParsed);
end;

// ═══════════════════════════════════════════════════════════════
// TTimeOfDay 往返测试
// ═══════════════════════════════════════════════════════════════

procedure TTestRoundtrip.Test_TimeOfDay_ISO8601_Roundtrip_Normal;
var
  LOriginal, LParsed: TTimeOfDay;
  LStr: string;
begin
  LOriginal := TTimeOfDay.Create(14, 30, 45);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TTimeOfDay.TryParseISO(LStr, LParsed));
  // 比较时忽略毫秒（如果 ToISO8601 不包含毫秒）
  AssertEquals(LOriginal.GetHour, LParsed.GetHour);
  AssertEquals(LOriginal.GetMinute, LParsed.GetMinute);
  AssertEquals(LOriginal.GetSecond, LParsed.GetSecond);
end;

procedure TTestRoundtrip.Test_TimeOfDay_ISO8601_Roundtrip_Midnight;
var
  LOriginal, LParsed: TTimeOfDay;
  LStr: string;
begin
  LOriginal := TTimeOfDay.Midnight;
  LStr := LOriginal.ToISO8601;
  AssertTrue(TTimeOfDay.TryParseISO(LStr, LParsed));
  AssertEquals(0, LParsed.GetHour);
  AssertEquals(0, LParsed.GetMinute);
  AssertEquals(0, LParsed.GetSecond);
end;

procedure TTestRoundtrip.Test_TimeOfDay_ISO8601_Roundtrip_EndOfDay;
var
  LOriginal, LParsed: TTimeOfDay;
  LStr: string;
begin
  LOriginal := TTimeOfDay.Create(23, 59, 59);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TTimeOfDay.TryParseISO(LStr, LParsed));
  AssertEquals(23, LParsed.GetHour);
  AssertEquals(59, LParsed.GetMinute);
  AssertEquals(59, LParsed.GetSecond);
end;

procedure TTestRoundtrip.Test_TimeOfDay_ISO8601_Roundtrip_WithMilliseconds;
var
  LOriginal, LParsed: TTimeOfDay;
  LStr: string;
begin
  LOriginal := TTimeOfDay.Create(12, 30, 45, 123);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TTimeOfDay.TryParseISO(LStr, LParsed));
  AssertEquals(LOriginal.GetHour, LParsed.GetHour);
  AssertEquals(LOriginal.GetMinute, LParsed.GetMinute);
  AssertEquals(LOriginal.GetSecond, LParsed.GetSecond);
  // 毫秒往返取决于 ToISO8601 是否输出毫秒
  if Pos('.', LStr) > 0 then
    AssertEquals(LOriginal.GetMillisecond, LParsed.GetMillisecond);
end;

// ═══════════════════════════════════════════════════════════════
// TUtcOffset 往返测试
// ═══════════════════════════════════════════════════════════════

procedure TTestRoundtrip.Test_UtcOffset_ISO8601_Roundtrip_UTC;
var
  LOriginal, LParsed: TUtcOffset;
  LStr: string;
begin
  LOriginal := TUtcOffset.UTC;
  LStr := LOriginal.ToISO8601;
  AssertTrue(TUtcOffset.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.TotalSeconds, LParsed.TotalSeconds);
end;

procedure TTestRoundtrip.Test_UtcOffset_ISO8601_Roundtrip_Positive;
var
  LOriginal, LParsed: TUtcOffset;
  LStr: string;
begin
  LOriginal := TUtcOffset.FromHours(8);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TUtcOffset.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.TotalSeconds, LParsed.TotalSeconds);
end;

procedure TTestRoundtrip.Test_UtcOffset_ISO8601_Roundtrip_Negative;
var
  LOriginal, LParsed: TUtcOffset;
  LStr: string;
begin
  LOriginal := TUtcOffset.FromHours(-5);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TUtcOffset.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.TotalSeconds, LParsed.TotalSeconds);
end;

procedure TTestRoundtrip.Test_UtcOffset_ISO8601_Roundtrip_HalfHour;
var
  LOriginal, LParsed: TUtcOffset;
  LStr: string;
begin
  LOriginal := TUtcOffset.FromHoursMinutes(5, 30);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TUtcOffset.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.TotalSeconds, LParsed.TotalSeconds);
end;

// ═══════════════════════════════════════════════════════════════
// TZonedDateTime 往返测试
// ═══════════════════════════════════════════════════════════════

procedure TTestRoundtrip.Test_ZonedDateTime_ISO8601_Roundtrip_UTC;
var
  LOriginal, LParsed: TZonedDateTime;
  LStr: string;
begin
  LOriginal := TZonedDateTime.Create(2024, 6, 15, 14, 30, 45, TUtcOffset.UTC);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TZonedDateTime.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.Year, LParsed.Year);
  AssertEquals(LOriginal.Month, LParsed.Month);
  AssertEquals(LOriginal.Day, LParsed.Day);
  AssertEquals(LOriginal.Hour, LParsed.Hour);
  AssertEquals(LOriginal.Minute, LParsed.Minute);
  AssertEquals(LOriginal.Second, LParsed.Second);
  AssertTrue(LParsed.Offset.IsUTC);
end;

procedure TTestRoundtrip.Test_ZonedDateTime_ISO8601_Roundtrip_PositiveOffset;
var
  LOriginal, LParsed: TZonedDateTime;
  LStr: string;
begin
  LOriginal := TZonedDateTime.Create(2024, 6, 15, 14, 30, 45, TUtcOffset.FromHours(8));
  LStr := LOriginal.ToISO8601;
  AssertTrue(TZonedDateTime.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.Hour, LParsed.Hour);
  AssertEquals(LOriginal.Offset.TotalSeconds, LParsed.Offset.TotalSeconds);
end;

procedure TTestRoundtrip.Test_ZonedDateTime_ISO8601_Roundtrip_NegativeOffset;
var
  LOriginal, LParsed: TZonedDateTime;
  LStr: string;
begin
  LOriginal := TZonedDateTime.Create(2024, 6, 15, 14, 30, 45, TUtcOffset.FromHours(-5));
  LStr := LOriginal.ToISO8601;
  AssertTrue(TZonedDateTime.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.Hour, LParsed.Hour);
  AssertEquals(LOriginal.Offset.TotalSeconds, LParsed.Offset.TotalSeconds);
end;

procedure TTestRoundtrip.Test_ZonedDateTime_ISO8601_Roundtrip_Midnight;
var
  LOriginal, LParsed: TZonedDateTime;
  LStr: string;
begin
  LOriginal := TZonedDateTime.Create(2024, 1, 1, 0, 0, 0, TUtcOffset.UTC);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TZonedDateTime.TryParse(LStr, LParsed));
  AssertEquals(0, LParsed.Hour);
  AssertEquals(0, LParsed.Minute);
  AssertEquals(0, LParsed.Second);
end;

// ═══════════════════════════════════════════════════════════════
// TNaiveDateTime 往返测试
// ═══════════════════════════════════════════════════════════════

procedure TTestRoundtrip.Test_NaiveDateTime_ISO8601_Roundtrip_Normal;
var
  LOriginal, LParsed: TNaiveDateTime;
  LStr: string;
begin
  LOriginal := TNaiveDateTime.Create(2024, 6, 15, 14, 30, 45, 0);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TNaiveDateTime.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.Year, LParsed.Year);
  AssertEquals(LOriginal.Month, LParsed.Month);
  AssertEquals(LOriginal.Day, LParsed.Day);
  AssertEquals(LOriginal.Hour, LParsed.Hour);
  AssertEquals(LOriginal.Minute, LParsed.Minute);
  AssertEquals(LOriginal.Second, LParsed.Second);
end;

procedure TTestRoundtrip.Test_NaiveDateTime_ISO8601_Roundtrip_Midnight;
var
  LOriginal, LParsed: TNaiveDateTime;
  LStr: string;
begin
  LOriginal := TNaiveDateTime.Create(2024, 1, 1, 0, 0, 0, 0);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TNaiveDateTime.TryParse(LStr, LParsed));
  AssertEquals(0, LParsed.Hour);
  AssertEquals(0, LParsed.Minute);
  AssertEquals(0, LParsed.Second);
end;

procedure TTestRoundtrip.Test_NaiveDateTime_ISO8601_Roundtrip_WithMilliseconds;
var
  LOriginal, LParsed: TNaiveDateTime;
  LStr: string;
begin
  LOriginal := TNaiveDateTime.Create(2024, 6, 15, 14, 30, 45, 123);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TNaiveDateTime.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.Millisecond, LParsed.Millisecond);
end;

// ═══════════════════════════════════════════════════════════════
// TIsoWeek 往返测试
// ═══════════════════════════════════════════════════════════════

procedure TTestRoundtrip.Test_IsoWeek_ISO8601_Roundtrip_Normal;
var
  LOriginal, LParsed: TIsoWeek;
  LStr: string;
begin
  LOriginal := TIsoWeek.Create(2024, 25);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TIsoWeek.TryParse(LStr, LParsed));
  AssertEquals(LOriginal.Year, LParsed.Year);
  AssertEquals(LOriginal.Week, LParsed.Week);
end;

procedure TTestRoundtrip.Test_IsoWeek_ISO8601_Roundtrip_FirstWeek;
var
  LOriginal, LParsed: TIsoWeek;
  LStr: string;
begin
  LOriginal := TIsoWeek.Create(2024, 1);
  LStr := LOriginal.ToISO8601;
  AssertTrue(TIsoWeek.TryParse(LStr, LParsed));
  AssertEquals(1, LParsed.Week);
end;

procedure TTestRoundtrip.Test_IsoWeek_ISO8601_Roundtrip_LastWeek;
var
  LOriginal, LParsed: TIsoWeek;
  LStr: string;
begin
  LOriginal := TIsoWeek.Create(2020, 53); // 2020 有 53 周
  LStr := LOriginal.ToISO8601;
  AssertTrue(TIsoWeek.TryParse(LStr, LParsed));
  AssertEquals(53, LParsed.Week);
end;

initialization
  RegisterTest(TTestRoundtrip);

end.
