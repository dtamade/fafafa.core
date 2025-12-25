{$mode objfpc}{$H+}{$J-}
{$I ..\..\src\fafafa.core.settings.inc}

unit Test_fafafa_core_time_roundtrip;

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.iso8601;

type
  {
    往返验证测试：Format -> Parse -> 验证结果一致

    验证场景：
    1. TDate: 格式化后解析，值相同
    2. TTimeOfDay: 格式化后解析，值相同
    3. TDuration: ISO8601 格式化后解析，值相同
    4. ISO8601: 各种格式的往返验证
  }
  TTestRoundTrip = class(TTestCase)
  published
    // TDate 往返测试
    procedure Test_Date_RoundTrip_ISO8601;
    procedure Test_Date_RoundTrip_LeapYear;
    procedure Test_Date_RoundTrip_Boundaries;

    // TTimeOfDay 往返测试
    procedure Test_TimeOfDay_RoundTrip_Basic;
    procedure Test_TimeOfDay_RoundTrip_Midnight;
    procedure Test_TimeOfDay_RoundTrip_Noon;
    procedure Test_TimeOfDay_RoundTrip_LongFormat;

    // TDuration 往返测试
    procedure Test_Duration_RoundTrip_ISO8601;
    procedure Test_Duration_RoundTrip_Hours;
    procedure Test_Duration_RoundTrip_Minutes;

    // ISO8601 往返测试
    procedure Test_ISO8601_RoundTrip_DateTime;
    procedure Test_ISO8601_RoundTrip_DateOnly;
    procedure Test_ISO8601_RoundTrip_Duration;
  end;

implementation

{ TTestRoundTrip }

// === TDate 往返测试 ===

procedure TTestRoundTrip.Test_Date_RoundTrip_ISO8601;
var
  original, parsed: TDate;
  formatted: string;
begin
  // 普通日期
  original := TDate.Create(2025, 12, 24);
  formatted := original.ToString;
  AssertTrue('TryParse 应该成功', TDate.TryParse(formatted, parsed));
  AssertEquals('年份应相同', original.GetYear, parsed.GetYear);
  AssertEquals('月份应相同', original.GetMonth, parsed.GetMonth);
  AssertEquals('日期应相同', original.GetDay, parsed.GetDay);
end;

procedure TTestRoundTrip.Test_Date_RoundTrip_LeapYear;
var
  original, parsed: TDate;
  formatted: string;
begin
  // 闰年 2 月 29 日
  original := TDate.Create(2024, 2, 29);
  formatted := original.ToString;
  AssertTrue('闰年日期 TryParse 应该成功', TDate.TryParse(formatted, parsed));
  AssertEquals('闰年年份应相同', 2024, parsed.GetYear);
  AssertEquals('闰年月份应相同', 2, parsed.GetMonth);
  AssertEquals('闰年日期应相同', 29, parsed.GetDay);
end;

procedure TTestRoundTrip.Test_Date_RoundTrip_Boundaries;
var
  original, parsed: TDate;
  formatted: string;
begin
  // 年初
  original := TDate.Create(2025, 1, 1);
  formatted := original.ToString;
  AssertTrue('年初日期 TryParse 应该成功', TDate.TryParse(formatted, parsed));
  AssertEquals('年初日期应相同', 1, parsed.GetDay);

  // 年末
  original := TDate.Create(2025, 12, 31);
  formatted := original.ToString;
  AssertTrue('年末日期 TryParse 应该成功', TDate.TryParse(formatted, parsed));
  AssertEquals('年末月份应相同', 12, parsed.GetMonth);
  AssertEquals('年末日期应相同', 31, parsed.GetDay);
end;

// === TTimeOfDay 往返测试 ===

procedure TTestRoundTrip.Test_TimeOfDay_RoundTrip_Basic;
var
  original, parsed: TTimeOfDay;
  formatted: string;
begin
  // 普通时间
  original := TTimeOfDay.Create(14, 30, 45);
  formatted := original.ToString;
  AssertTrue('时间 TryParse 应该成功', TTimeOfDay.TryParse(formatted, parsed));
  AssertEquals('小时应相同', original.GetHour, parsed.GetHour);
  AssertEquals('分钟应相同', original.GetMinute, parsed.GetMinute);
  AssertEquals('秒应相同', original.GetSecond, parsed.GetSecond);
end;

procedure TTestRoundTrip.Test_TimeOfDay_RoundTrip_Midnight;
var
  original, parsed: TTimeOfDay;
  formatted: string;
begin
  // 午夜
  original := TTimeOfDay.Create(0, 0, 0);
  formatted := original.ToString;
  AssertTrue('午夜 TryParse 应该成功', TTimeOfDay.TryParse(formatted, parsed));
  AssertEquals('午夜小时应为 0', 0, parsed.GetHour);
  AssertEquals('午夜分钟应为 0', 0, parsed.GetMinute);
end;

procedure TTestRoundTrip.Test_TimeOfDay_RoundTrip_Noon;
var
  original, parsed: TTimeOfDay;
  formatted: string;
begin
  // 正午
  original := TTimeOfDay.Create(12, 0, 0);
  formatted := original.ToString;
  AssertTrue('正午 TryParse 应该成功', TTimeOfDay.TryParse(formatted, parsed));
  AssertEquals('正午小时应为 12', 12, parsed.GetHour);
end;

procedure TTestRoundTrip.Test_TimeOfDay_RoundTrip_LongFormat;
var
  original, parsed: TTimeOfDay;
  formatted: string;
begin
  // 带毫秒的时间（使用 ToLongString）
  original := TTimeOfDay.Create(23, 59, 59, 999);
  formatted := original.ToLongString;
  AssertTrue('毫秒时间 TryParse 应该成功', TTimeOfDay.TryParse(formatted, parsed));
  AssertEquals('毫秒时间小时应相同', 23, parsed.GetHour);
  AssertEquals('毫秒时间分钟应相同', 59, parsed.GetMinute);
  AssertEquals('毫秒时间秒应相同', 59, parsed.GetSecond);
end;

// === TDuration 往返测试 ===

procedure TTestRoundTrip.Test_Duration_RoundTrip_ISO8601;
var
  original, parsed: TDuration;
  formatted: string;
  isoDur: TISO8601Duration;
begin
  // 正常持续时间
  original := TDuration.FromHours(2) + TDuration.FromMinutes(30) + TDuration.FromSec(45);
  formatted := TISO8601Formatter.FormatDuration(original);
  isoDur := TISO8601Duration.FromString(formatted);
  parsed := isoDur.ToTDuration;
  // 允许微小误差（毫秒级，因为 ISO8601Duration 精度有限）
  AssertTrue('Duration 值应接近', Abs(original.AsMs - parsed.AsMs) < 1000);
end;

procedure TTestRoundTrip.Test_Duration_RoundTrip_Hours;
var
  original, parsed: TDuration;
  formatted: string;
  isoDur: TISO8601Duration;
begin
  // 小时持续时间
  original := TDuration.FromHours(5);
  formatted := TISO8601Formatter.FormatDuration(original);
  isoDur := TISO8601Duration.FromString(formatted);
  parsed := isoDur.ToTDuration;
  AssertEquals('5小时应相等', original.WholeHours, parsed.WholeHours);
end;

procedure TTestRoundTrip.Test_Duration_RoundTrip_Minutes;
var
  original, parsed: TDuration;
  formatted: string;
  isoDur: TISO8601Duration;
begin
  // 分钟持续时间
  original := TDuration.FromMinutes(90);
  formatted := TISO8601Formatter.FormatDuration(original);
  isoDur := TISO8601Duration.FromString(formatted);
  parsed := isoDur.ToTDuration;
  AssertEquals('90分钟应相等', original.WholeMinutes, parsed.WholeMinutes);
end;

// === ISO8601 往返测试 ===

procedure TTestRoundTrip.Test_ISO8601_RoundTrip_DateTime;
var
  original, parsed: TDateTime;
  formatted: string;
  ok: Boolean;
begin
  original := EncodeDate(2025, 12, 24) + EncodeTime(14, 30, 0, 0);
  formatted := TISO8601Formatter.FormatDateTime(original);
  ok := TISO8601Parser.ParseDateTime(formatted, parsed);
  AssertTrue('ISO8601 DateTime 解析应成功', ok);
  AssertEquals('ISO8601 DateTime 小时应相同', 14, HourOf(parsed));
  AssertEquals('ISO8601 DateTime 分钟应相同', 30, MinuteOf(parsed));
end;

procedure TTestRoundTrip.Test_ISO8601_RoundTrip_DateOnly;
var
  original, parsed: TDateTime;
  formatted: string;
  ok: Boolean;
  opts: TISO8601Options;
begin
  original := EncodeDate(2025, 6, 15);
  opts := TISO8601Options.Default;
  opts.DateFormat := idfExtended;
  formatted := TISO8601Formatter.FormatDateTime(original, opts);
  ok := TISO8601Parser.ParseDateTime(formatted, parsed);
  AssertTrue('ISO8601 日期解析应成功', ok);
  AssertEquals('ISO8601 日期年份应相同', 2025, YearOf(parsed));
  AssertEquals('ISO8601 日期月份应相同', 6, MonthOf(parsed));
  AssertEquals('ISO8601 日期日应相同', 15, DayOf(parsed));
end;

procedure TTestRoundTrip.Test_ISO8601_RoundTrip_Duration;
var
  original: TDuration;
  formatted: string;
  isoDur: TISO8601Duration;
begin
  // PT1H30M 格式
  original := TDuration.FromHours(1) + TDuration.FromMinutes(30);
  formatted := TISO8601Formatter.FormatDuration(original);
  isoDur := TISO8601Duration.FromString(formatted);
  AssertTrue('ISO8601 Duration 应包含 PT', Pos('PT', formatted) > 0);
  AssertEquals('ISO8601 Duration 分钟应相同', 90, isoDur.ToTDuration.WholeMinutes);
end;

initialization
  RegisterTest(TTestRoundTrip);

end.
