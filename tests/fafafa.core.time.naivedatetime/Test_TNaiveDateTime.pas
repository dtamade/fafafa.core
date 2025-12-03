{$CODEPAGE UTF8}
unit Test_TNaiveDateTime;

{$I fafafa.core.settings.inc}
{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpcunit,
  testregistry,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.duration;

type
  TTestTNaiveDateTime = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // 构造函数测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Create_ValidDateTime;
    procedure Test_Create_Midnight;
    procedure Test_Create_EndOfDay;
    procedure Test_FromDateAndTime;
    procedure Test_Now_DoesNotCrash;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_GetDate_ReturnsCorrectDate;
    procedure Test_GetTime_ReturnsCorrectTime;
    procedure Test_GetYear_ReturnsCorrectYear;
    procedure Test_GetMonth_ReturnsCorrectMonth;
    procedure Test_GetDay_ReturnsCorrectDay;
    procedure Test_GetHour_ReturnsCorrectHour;
    procedure Test_GetMinute_ReturnsCorrectMinute;
    procedure Test_GetSecond_ReturnsCorrectSecond;
    procedure Test_GetMillisecond_ReturnsCorrectMillisecond;
    
    // ═══════════════════════════════════════════════════════════════
    // 日期时间算术测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_AddDays_Positive;
    procedure Test_AddDays_Negative;
    procedure Test_AddDays_CrossMonth;
    procedure Test_AddDuration_Hours;
    procedure Test_AddDuration_CrossDay;
    procedure Test_SubtractDuration;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Equal_SameDateTime;
    procedure Test_Equal_DifferentDateTime;
    procedure Test_NotEqual;
    procedure Test_LessThan_SameDay;
    procedure Test_LessThan_DifferentDay;
    procedure Test_GreaterThan;
    
    // ═══════════════════════════════════════════════════════════════
    // 格式化与解析测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ToISO8601_NoTimezone;
    procedure Test_ToISO8601_WithMilliseconds;
    procedure Test_TryParse_Valid;
    procedure Test_TryParse_WithMilliseconds;
    procedure Test_TryParse_Invalid;
    procedure Test_ToString;
    
    // ═══════════════════════════════════════════════════════════════
    // 工具方法测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_DurationBetween_SameDay;
    procedure Test_DurationBetween_CrossDay;
    procedure Test_WithDate;
    procedure Test_WithTime;
    
    // ═══════════════════════════════════════════════════════════════
    // 纳秒精度测试 (P0 升级)
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_GetNanosecond_ReturnsCorrectValue;
    procedure Test_GetMicrosecond_ReturnsCorrectValue;
    procedure Test_CreateWithNanosecond_FullPrecision;
    procedure Test_NanosecondComparison_DifferentByNs;
    procedure Test_ToISO8601_WithNanoseconds;
    procedure Test_TryParse_WithNanoseconds;
    procedure Test_AddDuration_NanosecondPrecision;
    procedure Test_DurationUntil_NanosecondPrecision;
  end;

implementation

{ TTestTNaiveDateTime }

// ═══════════════════════════════════════════════════════════════
// 构造函数测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTNaiveDateTime.Test_Create_ValidDateTime;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  AssertEquals(2024, LDt.Year);
  AssertEquals(6, LDt.Month);
  AssertEquals(15, LDt.Day);
  AssertEquals(10, LDt.Hour);
  AssertEquals(30, LDt.Minute);
  AssertEquals(45, LDt.Second);
  AssertEquals(123, LDt.Millisecond);
end;

procedure TTestTNaiveDateTime.Test_Create_Midnight;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 1, 1, 0, 0, 0, 0);
  AssertEquals(0, LDt.Hour);
  AssertEquals(0, LDt.Minute);
  AssertEquals(0, LDt.Second);
end;

procedure TTestTNaiveDateTime.Test_Create_EndOfDay;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 12, 31, 23, 59, 59, 999);
  AssertEquals(23, LDt.Hour);
  AssertEquals(59, LDt.Minute);
  AssertEquals(59, LDt.Second);
  AssertEquals(999, LDt.Millisecond);
end;

procedure TTestTNaiveDateTime.Test_FromDateAndTime;
var
  LDate: TDate;
  LTime: TTimeOfDay;
  LDt: TNaiveDateTime;
begin
  LDate := TDate.Create(2024, 7, 20);
  LTime := TTimeOfDay.Create(15, 30, 45);
  LDt := TNaiveDateTime.FromDateAndTime(LDate, LTime);
  AssertEquals(2024, LDt.Year);
  AssertEquals(7, LDt.Month);
  AssertEquals(20, LDt.Day);
  AssertEquals(15, LDt.Hour);
  AssertEquals(30, LDt.Minute);
end;

procedure TTestTNaiveDateTime.Test_Now_DoesNotCrash;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Now;
  AssertTrue(LDt.Year >= 2024);
end;

// ═══════════════════════════════════════════════════════════════
// 访问器测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTNaiveDateTime.Test_GetDate_ReturnsCorrectDate;
var
  LDt: TNaiveDateTime;
  LDate: TDate;
begin
  LDt := TNaiveDateTime.Create(2024, 8, 25, 12, 0, 0, 0);
  LDate := LDt.Date;
  AssertEquals(2024, LDate.GetYear);
  AssertEquals(8, LDate.GetMonth);
  AssertEquals(25, LDate.GetDay);
end;

procedure TTestTNaiveDateTime.Test_GetTime_ReturnsCorrectTime;
var
  LDt: TNaiveDateTime;
  LTime: TTimeOfDay;
begin
  LDt := TNaiveDateTime.Create(2024, 8, 25, 14, 35, 50, 0);
  LTime := LDt.Time;
  AssertEquals(14, LTime.GetHour);
  AssertEquals(35, LTime.GetMinute);
  AssertEquals(50, LTime.GetSecond);
end;

procedure TTestTNaiveDateTime.Test_GetYear_ReturnsCorrectYear;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2030, 1, 1, 0, 0, 0, 0);
  AssertEquals(2030, LDt.Year);
end;

procedure TTestTNaiveDateTime.Test_GetMonth_ReturnsCorrectMonth;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 11, 1, 0, 0, 0, 0);
  AssertEquals(11, LDt.Month);
end;

procedure TTestTNaiveDateTime.Test_GetDay_ReturnsCorrectDay;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 1, 28, 0, 0, 0, 0);
  AssertEquals(28, LDt.Day);
end;

procedure TTestTNaiveDateTime.Test_GetHour_ReturnsCorrectHour;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 1, 1, 23, 0, 0, 0);
  AssertEquals(23, LDt.Hour);
end;

procedure TTestTNaiveDateTime.Test_GetMinute_ReturnsCorrectMinute;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 1, 1, 0, 45, 0, 0);
  AssertEquals(45, LDt.Minute);
end;

procedure TTestTNaiveDateTime.Test_GetSecond_ReturnsCorrectSecond;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 1, 1, 0, 0, 59, 0);
  AssertEquals(59, LDt.Second);
end;

procedure TTestTNaiveDateTime.Test_GetMillisecond_ReturnsCorrectMillisecond;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 1, 1, 0, 0, 0, 500);
  AssertEquals(500, LDt.Millisecond);
end;

// ═══════════════════════════════════════════════════════════════
// 日期时间算术测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTNaiveDateTime.Test_AddDays_Positive;
var
  LDt, LResult: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 12, 0, 0, 0);
  LResult := LDt.AddDays(5);
  AssertEquals(20, LResult.Day);
  AssertEquals(12, LResult.Hour); // 时间不变
end;

procedure TTestTNaiveDateTime.Test_AddDays_Negative;
var
  LDt, LResult: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 12, 0, 0, 0);
  LResult := LDt.AddDays(-5);
  AssertEquals(10, LResult.Day);
end;

procedure TTestTNaiveDateTime.Test_AddDays_CrossMonth;
var
  LDt, LResult: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 28, 12, 0, 0, 0);
  LResult := LDt.AddDays(5);
  AssertEquals(7, LResult.Month);
  AssertEquals(3, LResult.Day);
end;

procedure TTestTNaiveDateTime.Test_AddDuration_Hours;
var
  LDt, LResult: TNaiveDateTime;
  LDur: TDuration;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 10, 0, 0, 0);
  LDur := TDuration.FromHours(3);
  LResult := LDt.AddDuration(LDur);
  AssertEquals(13, LResult.Hour);
  AssertEquals(15, LResult.Day); // 日期不变
end;

procedure TTestTNaiveDateTime.Test_AddDuration_CrossDay;
var
  LDt, LResult: TNaiveDateTime;
  LDur: TDuration;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 22, 0, 0, 0);
  LDur := TDuration.FromHours(5);
  LResult := LDt.AddDuration(LDur);
  AssertEquals(3, LResult.Hour);
  AssertEquals(16, LResult.Day); // 跨天
end;

procedure TTestTNaiveDateTime.Test_SubtractDuration;
var
  LDt, LResult: TNaiveDateTime;
  LDur: TDuration;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 10, 0, 0, 0);
  LDur := TDuration.FromHours(3);
  LResult := LDt.SubtractDuration(LDur);
  AssertEquals(7, LResult.Hour);
end;

// ═══════════════════════════════════════════════════════════════
// 比较运算符测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTNaiveDateTime.Test_Equal_SameDateTime;
var
  A, B: TNaiveDateTime;
begin
  A := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 0, 0);
  B := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 0, 0);
  AssertTrue(A = B);
end;

procedure TTestTNaiveDateTime.Test_Equal_DifferentDateTime;
var
  A, B: TNaiveDateTime;
begin
  A := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 0, 0);
  B := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 1, 0);
  AssertFalse(A = B);
end;

procedure TTestTNaiveDateTime.Test_NotEqual;
var
  A, B: TNaiveDateTime;
begin
  A := TNaiveDateTime.Create(2024, 6, 15, 12, 0, 0, 0);
  B := TNaiveDateTime.Create(2024, 6, 15, 13, 0, 0, 0);
  AssertTrue(A <> B);
end;

procedure TTestTNaiveDateTime.Test_LessThan_SameDay;
var
  A, B: TNaiveDateTime;
begin
  A := TNaiveDateTime.Create(2024, 6, 15, 10, 0, 0, 0);
  B := TNaiveDateTime.Create(2024, 6, 15, 12, 0, 0, 0);
  AssertTrue(A < B);
  AssertFalse(B < A);
end;

procedure TTestTNaiveDateTime.Test_LessThan_DifferentDay;
var
  A, B: TNaiveDateTime;
begin
  A := TNaiveDateTime.Create(2024, 6, 14, 23, 0, 0, 0);
  B := TNaiveDateTime.Create(2024, 6, 15, 1, 0, 0, 0);
  AssertTrue(A < B);
end;

procedure TTestTNaiveDateTime.Test_GreaterThan;
var
  A, B: TNaiveDateTime;
begin
  A := TNaiveDateTime.Create(2024, 6, 15, 14, 0, 0, 0);
  B := TNaiveDateTime.Create(2024, 6, 15, 12, 0, 0, 0);
  AssertTrue(A > B);
end;

// ═══════════════════════════════════════════════════════════════
// 格式化与解析测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTNaiveDateTime.Test_ToISO8601_NoTimezone;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 45, 0);
  AssertEquals('2024-06-15T12:30:45', LDt.ToISO8601);
end;

procedure TTestTNaiveDateTime.Test_ToISO8601_WithMilliseconds;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 45, 123);
  AssertEquals('2024-06-15T12:30:45.123', LDt.ToISO8601);
end;

procedure TTestTNaiveDateTime.Test_TryParse_Valid;
var
  LDt: TNaiveDateTime;
begin
  AssertTrue(TNaiveDateTime.TryParse('2024-06-15T12:30:45', LDt));
  AssertEquals(2024, LDt.Year);
  AssertEquals(6, LDt.Month);
  AssertEquals(15, LDt.Day);
  AssertEquals(12, LDt.Hour);
  AssertEquals(30, LDt.Minute);
  AssertEquals(45, LDt.Second);
end;

procedure TTestTNaiveDateTime.Test_TryParse_WithMilliseconds;
var
  LDt: TNaiveDateTime;
begin
  AssertTrue(TNaiveDateTime.TryParse('2024-06-15T12:30:45.123', LDt));
  AssertEquals(123, LDt.Millisecond);
end;

procedure TTestTNaiveDateTime.Test_TryParse_Invalid;
var
  LDt: TNaiveDateTime;
begin
  AssertFalse(TNaiveDateTime.TryParse('invalid', LDt));
  AssertFalse(TNaiveDateTime.TryParse('2024-06-15', LDt));
end;

procedure TTestTNaiveDateTime.Test_ToString;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 0, 0);
  AssertEquals('2024-06-15T12:30:00', LDt.ToString);
end;

// ═══════════════════════════════════════════════════════════════
// 工具方法测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTNaiveDateTime.Test_DurationBetween_SameDay;
var
  A, B: TNaiveDateTime;
  LDur: TDuration;
begin
  A := TNaiveDateTime.Create(2024, 6, 15, 10, 0, 0, 0);
  B := TNaiveDateTime.Create(2024, 6, 15, 13, 0, 0, 0);
  LDur := A.DurationUntil(B);
  AssertEquals(3 * 60 * 60 * 1000, LDur.AsMs); // 3 hours in ms
end;

procedure TTestTNaiveDateTime.Test_DurationBetween_CrossDay;
var
  A, B: TNaiveDateTime;
  LDur: TDuration;
begin
  A := TNaiveDateTime.Create(2024, 6, 15, 22, 0, 0, 0);
  B := TNaiveDateTime.Create(2024, 6, 16, 2, 0, 0, 0);
  LDur := A.DurationUntil(B);
  AssertEquals(4 * 60 * 60 * 1000, LDur.AsMs); // 4 hours in ms
end;

procedure TTestTNaiveDateTime.Test_WithDate;
var
  LDt, LResult: TNaiveDateTime;
  LNewDate: TDate;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 0, 0);
  LNewDate := TDate.Create(2024, 12, 25);
  LResult := LDt.WithDate(LNewDate);
  AssertEquals(2024, LResult.Year);
  AssertEquals(12, LResult.Month);
  AssertEquals(25, LResult.Day);
  AssertEquals(12, LResult.Hour); // 时间保持不变
  AssertEquals(30, LResult.Minute);
end;

procedure TTestTNaiveDateTime.Test_WithTime;
var
  LDt, LResult: TNaiveDateTime;
  LNewTime: TTimeOfDay;
begin
  LDt := TNaiveDateTime.Create(2024, 6, 15, 12, 30, 0, 0);
  LNewTime := TTimeOfDay.Create(18, 45, 30);
  LResult := LDt.WithTime(LNewTime);
  AssertEquals(15, LResult.Day); // 日期保持不变
  AssertEquals(18, LResult.Hour);
  AssertEquals(45, LResult.Minute);
  AssertEquals(30, LResult.Second);
end;

// ═══════════════════════════════════════════════════════════════
// 纳秒精度测试 (P0 升级)
// ═══════════════════════════════════════════════════════════════

procedure TTestTNaiveDateTime.Test_GetNanosecond_ReturnsCorrectValue;
var
  LDt: TNaiveDateTime;
begin
  // 创建带纳秒的日期时间
  LDt := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 30, 45, 123456789);
  AssertEquals(123456789, LDt.Nanosecond);
  // 毫秒应该是 123
  AssertEquals(123, LDt.Millisecond);
end;

procedure TTestTNaiveDateTime.Test_GetMicrosecond_ReturnsCorrectValue;
var
  LDt: TNaiveDateTime;
begin
  LDt := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 30, 45, 123456789);
  // 微秒部分应该是 456
  AssertEquals(456, LDt.Microsecond);
end;

procedure TTestTNaiveDateTime.Test_CreateWithNanosecond_FullPrecision;
var
  LDt: TNaiveDateTime;
begin
  // 测试完整纳秒精度保留
  LDt := TNaiveDateTime.CreateNs(2024, 12, 31, 23, 59, 59, 999999999);
  AssertEquals(2024, LDt.Year);
  AssertEquals(12, LDt.Month);
  AssertEquals(31, LDt.Day);
  AssertEquals(23, LDt.Hour);
  AssertEquals(59, LDt.Minute);
  AssertEquals(59, LDt.Second);
  AssertEquals(999999999, LDt.Nanosecond);
end;

procedure TTestTNaiveDateTime.Test_NanosecondComparison_DifferentByNs;
var
  A, B: TNaiveDateTime;
begin
  // 两个时间只差 1 纳秒
  A := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 0, 0, 100);
  B := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 0, 0, 101);
  AssertTrue(A < B);
  AssertFalse(A = B);
  AssertTrue(A <> B);
end;

procedure TTestTNaiveDateTime.Test_ToISO8601_WithNanoseconds;
var
  LDt: TNaiveDateTime;
begin
  // 完整纳秒输出
  LDt := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 30, 45, 123456789);
  AssertEquals('2024-06-15T12:30:45.123456789', LDt.ToISO8601);
  
  // 只有毫秒时，输出 3 位
  LDt := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 30, 45, 123000000);
  AssertEquals('2024-06-15T12:30:45.123', LDt.ToISO8601);
  
  // 无亚秒时，不输出小数部分
  LDt := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 30, 45, 0);
  AssertEquals('2024-06-15T12:30:45', LDt.ToISO8601);
end;

procedure TTestTNaiveDateTime.Test_TryParse_WithNanoseconds;
var
  LDt: TNaiveDateTime;
begin
  // 解析 9 位纳秒
  AssertTrue(TNaiveDateTime.TryParse('2024-06-15T12:30:45.123456789', LDt));
  AssertEquals(123456789, LDt.Nanosecond);
  
  // 解析 6 位微秒
  AssertTrue(TNaiveDateTime.TryParse('2024-06-15T12:30:45.123456', LDt));
  AssertEquals(123456000, LDt.Nanosecond);
  
  // 解析 3 位毫秒（向后兼容）
  AssertTrue(TNaiveDateTime.TryParse('2024-06-15T12:30:45.123', LDt));
  AssertEquals(123000000, LDt.Nanosecond);
end;

procedure TTestTNaiveDateTime.Test_AddDuration_NanosecondPrecision;
var
  LDt, LResult: TNaiveDateTime;
  LDur: TDuration;
begin
  LDt := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 0, 0, 0);
  LDur := TDuration.FromNs(500); // 500 纳秒
  LResult := LDt.AddDuration(LDur);
  AssertEquals(500, LResult.Nanosecond);
end;

procedure TTestTNaiveDateTime.Test_DurationUntil_NanosecondPrecision;
var
  A, B: TNaiveDateTime;
  LDur: TDuration;
begin
  A := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 0, 0, 100);
  B := TNaiveDateTime.CreateNs(2024, 6, 15, 12, 0, 0, 600);
  LDur := A.DurationUntil(B);
  AssertEquals(500, LDur.AsNs); // 差 500 纳秒
end;

initialization
  RegisterTest(TTestTNaiveDateTime);

end.
