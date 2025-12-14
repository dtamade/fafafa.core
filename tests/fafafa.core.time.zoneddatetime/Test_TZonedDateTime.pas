{$CODEPAGE UTF8}
unit Test_TZonedDateTime;

{$I fafafa.core.settings.inc}
{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpcunit,
  testregistry,
  fafafa.core.time.offset,
  fafafa.core.time.tz,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.date,
  fafafa.core.time.timeofday;

type
  TTestTZonedDateTime = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // 构造函数测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Create_ValidDateTime;
    procedure Test_Create_WithOffset;
    procedure Test_FromDateAndTime_UTC;
    procedure Test_FromDateAndTime_WithOffset;
    procedure Test_FromUnixTimestamp_Epoch;
    procedure Test_FromUnixTimestamp_WithOffset;
    procedure Test_NowUtc_DoesNotCrash;
    procedure Test_NowLocal_DoesNotCrash;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_GetDate_ReturnsCorrectDate;
    procedure Test_GetTime_ReturnsCorrectTime;
    procedure Test_GetOffset_ReturnsCorrectOffset;
    procedure Test_GetYear_ReturnsCorrectYear;
    procedure Test_GetMonth_ReturnsCorrectMonth;
    procedure Test_GetDay_ReturnsCorrectDay;
    procedure Test_GetHour_ReturnsCorrectHour;
    procedure Test_GetMinute_ReturnsCorrectMinute;
    procedure Test_GetSecond_ReturnsCorrectSecond;
    
    // ═══════════════════════════════════════════════════════════════
    // 时区转换测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ToUtc_FromPositiveOffset;
    procedure Test_ToUtc_FromNegativeOffset;
    procedure Test_ToUtc_AlreadyUtc;
    procedure Test_WithOffset_ChangeTimezone;
    procedure Test_WithOffset_CrossesMidnight;
    procedure Test_WithOffset_CrossesPreviousDay;
    
    // ═══════════════════════════════════════════════════════════════
    // Unix 时间戳测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ToUnixTimestamp_Epoch;
    procedure Test_ToUnixTimestamp_WithOffset;
    procedure Test_RoundTrip_UnixTimestamp;
    
    // ═══════════════════════════════════════════════════════════════
    // ISO 8601 格式化测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ToISO8601_UTC;
    procedure Test_ToISO8601_PositiveOffset;
    procedure Test_ToISO8601_NegativeOffset;
    procedure Test_TryParse_UTC;
    procedure Test_TryParse_PositiveOffset;
    procedure Test_TryParse_NegativeOffset;
    procedure Test_TryParse_Invalid;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Equal_SameDateTime;
    procedure Test_Equal_DifferentOffset_SameInstant;
    procedure Test_NotEqual_DifferentInstant;
    procedure Test_LessThan_DifferentInstant;
    procedure Test_Compare_CrossTimezone;
    
    // ═════════════════════════════════════════════════════════════════
    // TTimeZone 集成测试
    // ═════════════════════════════════════════════════════════════════
    procedure Test_FromTimeZone_UTC;
    procedure Test_FromTimeZone_Shanghai;
    procedure Test_WithTimeZone_ConvertToShanghai;
  end;

implementation

{ TTestTZonedDateTime }

// ═══════════════════════════════════════════════════════════════
// 构造函数测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTZonedDateTime.Test_Create_ValidDateTime;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 6, 15, 10, 30, 0, TUtcOffset.UTC);
  AssertEquals(2024, LDt.Year);
  AssertEquals(6, LDt.Month);
  AssertEquals(15, LDt.Day);
  AssertEquals(10, LDt.Hour);
  AssertEquals(30, LDt.Minute);
  AssertEquals(0, LDt.Second);
end;

procedure TTestTZonedDateTime.Test_Create_WithOffset;
var
  LDt: TZonedDateTime;
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(8);
  LDt := TZonedDateTime.Create(2024, 6, 15, 18, 30, 0, LOffset);
  AssertEquals(18, LDt.Hour);
  AssertEquals(8 * 3600, LDt.Offset.TotalSeconds);
end;

procedure TTestTZonedDateTime.Test_FromDateAndTime_UTC;
var
  LDate: TDate;
  LTime: TTimeOfDay;
  LDt: TZonedDateTime;
begin
  LDate := TDate.Create(2024, 1, 1);
  LTime := TTimeOfDay.Create(12, 0, 0);
  LDt := TZonedDateTime.FromDateAndTime(LDate, LTime, TUtcOffset.UTC);
  AssertEquals(2024, LDt.Year);
  AssertEquals(1, LDt.Month);
  AssertEquals(1, LDt.Day);
  AssertEquals(12, LDt.Hour);
  AssertTrue(LDt.Offset.IsUTC);
end;

procedure TTestTZonedDateTime.Test_FromDateAndTime_WithOffset;
var
  LDate: TDate;
  LTime: TTimeOfDay;
  LDt: TZonedDateTime;
  LOffset: TUtcOffset;
begin
  LDate := TDate.Create(2024, 12, 31);
  LTime := TTimeOfDay.Create(23, 59, 59);
  LOffset := TUtcOffset.FromHours(-5);
  LDt := TZonedDateTime.FromDateAndTime(LDate, LTime, LOffset);
  AssertEquals(23, LDt.Hour);
  AssertEquals(-5 * 3600, LDt.Offset.TotalSeconds);
end;

procedure TTestTZonedDateTime.Test_FromUnixTimestamp_Epoch;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.FromUnixTimestamp(0, TUtcOffset.UTC);
  AssertEquals(1970, LDt.Year);
  AssertEquals(1, LDt.Month);
  AssertEquals(1, LDt.Day);
  AssertEquals(0, LDt.Hour);
end;

procedure TTestTZonedDateTime.Test_FromUnixTimestamp_WithOffset;
var
  LDt: TZonedDateTime;
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(8);
  LDt := TZonedDateTime.FromUnixTimestamp(0, LOffset);
  // Unix epoch 在 UTC+8 是 1970-01-01 08:00:00
  AssertEquals(1970, LDt.Year);
  AssertEquals(8, LDt.Hour);
end;

procedure TTestTZonedDateTime.Test_NowUtc_DoesNotCrash;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.NowUtc;
  AssertTrue(LDt.Offset.IsUTC);
  AssertTrue(LDt.Year >= 2024);
end;

procedure TTestTZonedDateTime.Test_NowLocal_DoesNotCrash;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.NowLocal;
  AssertTrue(LDt.Year >= 2024);
end;

// ═══════════════════════════════════════════════════════════════
// 访问器测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTZonedDateTime.Test_GetDate_ReturnsCorrectDate;
var
  LDt: TZonedDateTime;
  LDate: TDate;
begin
  LDt := TZonedDateTime.Create(2024, 7, 20, 15, 30, 45, TUtcOffset.UTC);
  LDate := LDt.Date;
  AssertEquals(2024, LDate.GetYear);
  AssertEquals(7, LDate.GetMonth);
  AssertEquals(20, LDate.GetDay);
end;

procedure TTestTZonedDateTime.Test_GetTime_ReturnsCorrectTime;
var
  LDt: TZonedDateTime;
  LTime: TTimeOfDay;
begin
  LDt := TZonedDateTime.Create(2024, 7, 20, 15, 30, 45, TUtcOffset.UTC);
  LTime := LDt.Time;
  AssertEquals(15, LTime.GetHour);
  AssertEquals(30, LTime.GetMinute);
  AssertEquals(45, LTime.GetSecond);
end;

procedure TTestTZonedDateTime.Test_GetOffset_ReturnsCorrectOffset;
var
  LDt: TZonedDateTime;
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHoursMinutes(5, 30);
  LDt := TZonedDateTime.Create(2024, 7, 20, 15, 30, 0, LOffset);
  AssertEquals(5 * 3600 + 30 * 60, LDt.Offset.TotalSeconds);
end;

procedure TTestTZonedDateTime.Test_GetYear_ReturnsCorrectYear;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2030, 1, 1, 0, 0, 0, TUtcOffset.UTC);
  AssertEquals(2030, LDt.Year);
end;

procedure TTestTZonedDateTime.Test_GetMonth_ReturnsCorrectMonth;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 11, 15, 0, 0, 0, TUtcOffset.UTC);
  AssertEquals(11, LDt.Month);
end;

procedure TTestTZonedDateTime.Test_GetDay_ReturnsCorrectDay;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 1, 28, 0, 0, 0, TUtcOffset.UTC);
  AssertEquals(28, LDt.Day);
end;

procedure TTestTZonedDateTime.Test_GetHour_ReturnsCorrectHour;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 1, 1, 23, 0, 0, TUtcOffset.UTC);
  AssertEquals(23, LDt.Hour);
end;

procedure TTestTZonedDateTime.Test_GetMinute_ReturnsCorrectMinute;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 1, 1, 0, 45, 0, TUtcOffset.UTC);
  AssertEquals(45, LDt.Minute);
end;

procedure TTestTZonedDateTime.Test_GetSecond_ReturnsCorrectSecond;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 1, 1, 0, 0, 59, TUtcOffset.UTC);
  AssertEquals(59, LDt.Second);
end;

// ═══════════════════════════════════════════════════════════════
// 时区转换测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTZonedDateTime.Test_ToUtc_FromPositiveOffset;
var
  LDt: TZonedDateTime;
  LUtc: TZonedDateTime;
begin
  // 北京时间 08:00 = UTC 00:00
  LDt := TZonedDateTime.Create(2024, 6, 15, 8, 0, 0, TUtcOffset.FromHours(8));
  LUtc := LDt.ToUtc;
  AssertEquals(0, LUtc.Hour);
  AssertTrue(LUtc.Offset.IsUTC);
end;

procedure TTestTZonedDateTime.Test_ToUtc_FromNegativeOffset;
var
  LDt: TZonedDateTime;
  LUtc: TZonedDateTime;
begin
  // 纽约时间 19:00 (UTC-5) = UTC 00:00 次日
  LDt := TZonedDateTime.Create(2024, 6, 15, 19, 0, 0, TUtcOffset.FromHours(-5));
  LUtc := LDt.ToUtc;
  AssertEquals(0, LUtc.Hour);
  AssertEquals(16, LUtc.Day); // 次日
end;

procedure TTestTZonedDateTime.Test_ToUtc_AlreadyUtc;
var
  LDt: TZonedDateTime;
  LUtc: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 6, 15, 12, 30, 0, TUtcOffset.UTC);
  LUtc := LDt.ToUtc;
  AssertEquals(12, LUtc.Hour);
  AssertEquals(30, LUtc.Minute);
end;

procedure TTestTZonedDateTime.Test_WithOffset_ChangeTimezone;
var
  LDt: TZonedDateTime;
  LConverted: TZonedDateTime;
begin
  // UTC 00:00 转换到 UTC+8 应该是 08:00
  LDt := TZonedDateTime.Create(2024, 6, 15, 0, 0, 0, TUtcOffset.UTC);
  LConverted := LDt.WithOffset(TUtcOffset.FromHours(8));
  AssertEquals(8, LConverted.Hour);
  AssertEquals(15, LConverted.Day);
end;

procedure TTestTZonedDateTime.Test_WithOffset_CrossesMidnight;
var
  LDt: TZonedDateTime;
  LConverted: TZonedDateTime;
begin
  // UTC 20:00 转换到 UTC+8 应该是次日 04:00
  LDt := TZonedDateTime.Create(2024, 6, 15, 20, 0, 0, TUtcOffset.UTC);
  LConverted := LDt.WithOffset(TUtcOffset.FromHours(8));
  AssertEquals(4, LConverted.Hour);
  AssertEquals(16, LConverted.Day); // 次日
end;

procedure TTestTZonedDateTime.Test_WithOffset_CrossesPreviousDay;
var
  LDt: TZonedDateTime;
  LConverted: TZonedDateTime;
begin
  // UTC 03:00 转换到 UTC-5 应该是前一天 22:00
  LDt := TZonedDateTime.Create(2024, 6, 15, 3, 0, 0, TUtcOffset.UTC);
  LConverted := LDt.WithOffset(TUtcOffset.FromHours(-5));
  AssertEquals(22, LConverted.Hour);
  AssertEquals(14, LConverted.Day); // 前一天
end;

// ═══════════════════════════════════════════════════════════════
// Unix 时间戳测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTZonedDateTime.Test_ToUnixTimestamp_Epoch;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(1970, 1, 1, 0, 0, 0, TUtcOffset.UTC);
  AssertEquals(0, LDt.ToUnixTimestamp);
end;

procedure TTestTZonedDateTime.Test_ToUnixTimestamp_WithOffset;
var
  LDt: TZonedDateTime;
begin
  // 北京时间 1970-01-01 08:00 = Unix 0
  LDt := TZonedDateTime.Create(1970, 1, 1, 8, 0, 0, TUtcOffset.FromHours(8));
  AssertEquals(0, LDt.ToUnixTimestamp);
end;

procedure TTestTZonedDateTime.Test_RoundTrip_UnixTimestamp;
var
  LOriginal: TZonedDateTime;
  LTimestamp: Int64;
  LRestored: TZonedDateTime;
begin
  LOriginal := TZonedDateTime.Create(2024, 6, 15, 12, 30, 45, TUtcOffset.UTC);
  LTimestamp := LOriginal.ToUnixTimestamp;
  LRestored := TZonedDateTime.FromUnixTimestamp(LTimestamp, TUtcOffset.UTC);
  AssertEquals(LOriginal.Year, LRestored.Year);
  AssertEquals(LOriginal.Month, LRestored.Month);
  AssertEquals(LOriginal.Day, LRestored.Day);
  AssertEquals(LOriginal.Hour, LRestored.Hour);
  AssertEquals(LOriginal.Minute, LRestored.Minute);
  AssertEquals(LOriginal.Second, LRestored.Second);
end;

// ═══════════════════════════════════════════════════════════════
// ISO 8601 格式化测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTZonedDateTime.Test_ToISO8601_UTC;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 6, 15, 12, 30, 45, TUtcOffset.UTC);
  AssertEquals('2024-06-15T12:30:45Z', LDt.ToISO8601);
end;

procedure TTestTZonedDateTime.Test_ToISO8601_PositiveOffset;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 6, 15, 12, 30, 45, TUtcOffset.FromHours(8));
  AssertEquals('2024-06-15T12:30:45+08:00', LDt.ToISO8601);
end;

procedure TTestTZonedDateTime.Test_ToISO8601_NegativeOffset;
var
  LDt: TZonedDateTime;
begin
  LDt := TZonedDateTime.Create(2024, 6, 15, 12, 30, 45, TUtcOffset.FromHours(-5));
  AssertEquals('2024-06-15T12:30:45-05:00', LDt.ToISO8601);
end;

procedure TTestTZonedDateTime.Test_TryParse_UTC;
var
  LDt: TZonedDateTime;
begin
  AssertTrue(TZonedDateTime.TryParse('2024-06-15T12:30:45Z', LDt));
  AssertEquals(2024, LDt.Year);
  AssertEquals(6, LDt.Month);
  AssertEquals(15, LDt.Day);
  AssertEquals(12, LDt.Hour);
  AssertEquals(30, LDt.Minute);
  AssertEquals(45, LDt.Second);
  AssertTrue(LDt.Offset.IsUTC);
end;

procedure TTestTZonedDateTime.Test_TryParse_PositiveOffset;
var
  LDt: TZonedDateTime;
begin
  AssertTrue(TZonedDateTime.TryParse('2024-06-15T12:30:45+08:00', LDt));
  AssertEquals(12, LDt.Hour);
  AssertEquals(8 * 3600, LDt.Offset.TotalSeconds);
end;

procedure TTestTZonedDateTime.Test_TryParse_NegativeOffset;
var
  LDt: TZonedDateTime;
begin
  AssertTrue(TZonedDateTime.TryParse('2024-06-15T12:30:45-05:00', LDt));
  AssertEquals(12, LDt.Hour);
  AssertEquals(-5 * 3600, LDt.Offset.TotalSeconds);
end;

procedure TTestTZonedDateTime.Test_TryParse_Invalid;
var
  LDt: TZonedDateTime;
begin
  AssertFalse(TZonedDateTime.TryParse('invalid', LDt));
  AssertFalse(TZonedDateTime.TryParse('2024-06-15', LDt));
  AssertFalse(TZonedDateTime.TryParse('12:30:45', LDt));
end;

// ═══════════════════════════════════════════════════════════════
// 比较运算符测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTZonedDateTime.Test_Equal_SameDateTime;
var
  A, B: TZonedDateTime;
begin
  A := TZonedDateTime.Create(2024, 6, 15, 12, 0, 0, TUtcOffset.UTC);
  B := TZonedDateTime.Create(2024, 6, 15, 12, 0, 0, TUtcOffset.UTC);
  AssertTrue(A = B);
end;

procedure TTestTZonedDateTime.Test_Equal_DifferentOffset_SameInstant;
var
  A, B: TZonedDateTime;
begin
  // UTC 04:00 = 北京时间 12:00，代表同一时刻
  A := TZonedDateTime.Create(2024, 6, 15, 4, 0, 0, TUtcOffset.UTC);
  B := TZonedDateTime.Create(2024, 6, 15, 12, 0, 0, TUtcOffset.FromHours(8));
  AssertTrue(A = B);
end;

procedure TTestTZonedDateTime.Test_NotEqual_DifferentInstant;
var
  A, B: TZonedDateTime;
begin
  A := TZonedDateTime.Create(2024, 6, 15, 12, 0, 0, TUtcOffset.UTC);
  B := TZonedDateTime.Create(2024, 6, 15, 13, 0, 0, TUtcOffset.UTC);
  AssertTrue(A <> B);
end;

procedure TTestTZonedDateTime.Test_LessThan_DifferentInstant;
var
  A, B: TZonedDateTime;
begin
  A := TZonedDateTime.Create(2024, 6, 15, 12, 0, 0, TUtcOffset.UTC);
  B := TZonedDateTime.Create(2024, 6, 15, 13, 0, 0, TUtcOffset.UTC);
  AssertTrue(A < B);
  AssertFalse(B < A);
end;

procedure TTestTZonedDateTime.Test_Compare_CrossTimezone;
var
  A, B: TZonedDateTime;
begin
  // UTC 12:00 > 北京时间 12:00 (= UTC 04:00)
  A := TZonedDateTime.Create(2024, 6, 15, 12, 0, 0, TUtcOffset.UTC);
  B := TZonedDateTime.Create(2024, 6, 15, 12, 0, 0, TUtcOffset.FromHours(8));
  AssertTrue(A > B);
end;

// ═════════════════════════════════════════════════════════════════
// TTimeZone 集成测试
// ═════════════════════════════════════════════════════════════════

procedure TTestTZonedDateTime.Test_FromTimeZone_UTC;
var
  Tz: TTimeZone;
  Dt: TZonedDateTime;
begin
  Tz := TTimeZone.UTC;
  Dt := TZonedDateTime.FromTimeZone(2024, 6, 15, 12, 30, 45, Tz);
  AssertEquals(12, Dt.Hour);
  AssertEquals(30, Dt.Minute);
  AssertEquals(45, Dt.Second);
  AssertTrue(Dt.Offset.IsUTC);
end;

procedure TTestTZonedDateTime.Test_FromTimeZone_Shanghai;
var
  Tz: TTimeZone;
  Dt: TZonedDateTime;
begin
  TTimeZone.TryFromId('Asia/Shanghai', Tz);
  Dt := TZonedDateTime.FromTimeZone(2024, 6, 15, 20, 0, 0, Tz);
  AssertEquals(20, Dt.Hour);
  AssertEquals(8 * 3600, Dt.Offset.TotalSeconds);  // UTC+8
end;

procedure TTestTZonedDateTime.Test_WithTimeZone_ConvertToShanghai;
var
  UtcDt: TZonedDateTime;
  Shanghai: TTimeZone;
  Converted: TZonedDateTime;
begin
  // UTC 04:00 -> Shanghai 12:00
  UtcDt := TZonedDateTime.Create(2024, 6, 15, 4, 0, 0, TUtcOffset.UTC);
  TTimeZone.TryFromId('Asia/Shanghai', Shanghai);
  Converted := UtcDt.WithTimeZone(Shanghai);
  AssertEquals(12, Converted.Hour);
  AssertEquals(8 * 3600, Converted.Offset.TotalSeconds);
end;

initialization
  RegisterTest(TTestTZonedDateTime);

end.
