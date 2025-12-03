unit Test_TUtcOffset;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.offset;

type
  TTestTUtcOffset = class(TTestCase)
  published
    // 构造函数测试
    procedure Test_UTC_ReturnsZeroOffset;
    procedure Test_FromHours_PositiveHours;
    procedure Test_FromHours_NegativeHours;
    procedure Test_FromHoursMinutes_PositiveOffset;
    procedure Test_FromHoursMinutes_NegativeOffset;
    procedure Test_FromSeconds_Positive;
    procedure Test_FromSeconds_Negative;
    
    // 边界值测试
    procedure Test_FromHours_UTC_Minus_12;
    procedure Test_FromHours_UTC_Plus_14;
    procedure Test_FromHoursMinutes_HalfHourOffset;
    procedure Test_FromHoursMinutes_QuarterHourOffset;
    
    // 访问器测试
    procedure Test_TotalSeconds_UTC;
    procedure Test_TotalSeconds_PositiveOffset;
    procedure Test_TotalSeconds_NegativeOffset;
    procedure Test_TotalMinutes_PositiveOffset;
    procedure Test_TotalMinutes_NegativeOffset;
    
    // ISO 8601 格式化测试
    procedure Test_ToISO8601_UTC;
    procedure Test_ToISO8601_PositiveWholeHour;
    procedure Test_ToISO8601_NegativeWholeHour;
    procedure Test_ToISO8601_PositiveWithMinutes;
    procedure Test_ToISO8601_NegativeWithMinutes;
    procedure Test_ToISO8601_UTC_Plus_5_30;
    procedure Test_ToISO8601_UTC_Minus_9_30;
    
    // 比较运算符测试
    procedure Test_Equal_SameOffset;
    procedure Test_Equal_DifferentOffset;
    procedure Test_NotEqual;
    
    // TryParse 测试
    procedure Test_TryParse_Z;
    procedure Test_TryParse_PositiveOffset;
    procedure Test_TryParse_NegativeOffset;
    procedure Test_TryParse_WithMinutes;
    procedure Test_TryParse_Invalid;
    
    // Local 测试（平台相关，只验证不崩溃）
    procedure Test_Local_DoesNotCrash;
  end;

implementation

{ TTestTUtcOffset }

procedure TTestTUtcOffset.Test_UTC_ReturnsZeroOffset;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.UTC;
  AssertEquals('UTC should have 0 seconds offset', 0, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromHours_PositiveHours;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(8);
  AssertEquals('UTC+8 should have 28800 seconds', 8 * 3600, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromHours_NegativeHours;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(-5);
  AssertEquals('UTC-5 should have -18000 seconds', -5 * 3600, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromHoursMinutes_PositiveOffset;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHoursMinutes(5, 30);
  AssertEquals('UTC+5:30 should have 19800 seconds', 5 * 3600 + 30 * 60, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromHoursMinutes_NegativeOffset;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHoursMinutes(-3, 30);
  AssertEquals('UTC-3:30 should have -12600 seconds', -(3 * 3600 + 30 * 60), LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromSeconds_Positive;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromSeconds(7200);
  AssertEquals('FromSeconds(7200) should return 7200', 7200, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromSeconds_Negative;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromSeconds(-3600);
  AssertEquals('FromSeconds(-3600) should return -3600', -3600, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromHours_UTC_Minus_12;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(-12);
  AssertEquals('UTC-12 should have -43200 seconds', -12 * 3600, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromHours_UTC_Plus_14;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(14);
  AssertEquals('UTC+14 should have 50400 seconds', 14 * 3600, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_FromHoursMinutes_HalfHourOffset;
var
  LOffset: TUtcOffset;
begin
  // India: UTC+5:30
  LOffset := TUtcOffset.FromHoursMinutes(5, 30);
  AssertEquals('UTC+5:30 total minutes', 5 * 60 + 30, LOffset.TotalMinutes);
end;

procedure TTestTUtcOffset.Test_FromHoursMinutes_QuarterHourOffset;
var
  LOffset: TUtcOffset;
begin
  // Nepal: UTC+5:45
  LOffset := TUtcOffset.FromHoursMinutes(5, 45);
  AssertEquals('UTC+5:45 total seconds', 5 * 3600 + 45 * 60, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_TotalSeconds_UTC;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.UTC;
  AssertEquals(0, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_TotalSeconds_PositiveOffset;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(8);
  AssertEquals(28800, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_TotalSeconds_NegativeOffset;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(-5);
  AssertEquals(-18000, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_TotalMinutes_PositiveOffset;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHoursMinutes(5, 30);
  AssertEquals(330, LOffset.TotalMinutes);
end;

procedure TTestTUtcOffset.Test_TotalMinutes_NegativeOffset;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHoursMinutes(-9, 30);
  AssertEquals(-570, LOffset.TotalMinutes);
end;

procedure TTestTUtcOffset.Test_ToISO8601_UTC;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.UTC;
  AssertEquals('Z', LOffset.ToISO8601);
end;

procedure TTestTUtcOffset.Test_ToISO8601_PositiveWholeHour;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(8);
  AssertEquals('+08:00', LOffset.ToISO8601);
end;

procedure TTestTUtcOffset.Test_ToISO8601_NegativeWholeHour;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHours(-5);
  AssertEquals('-05:00', LOffset.ToISO8601);
end;

procedure TTestTUtcOffset.Test_ToISO8601_PositiveWithMinutes;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHoursMinutes(5, 30);
  AssertEquals('+05:30', LOffset.ToISO8601);
end;

procedure TTestTUtcOffset.Test_ToISO8601_NegativeWithMinutes;
var
  LOffset: TUtcOffset;
begin
  LOffset := TUtcOffset.FromHoursMinutes(-3, 30);
  AssertEquals('-03:30', LOffset.ToISO8601);
end;

procedure TTestTUtcOffset.Test_ToISO8601_UTC_Plus_5_30;
var
  LOffset: TUtcOffset;
begin
  // India Standard Time
  LOffset := TUtcOffset.FromHoursMinutes(5, 30);
  AssertEquals('+05:30', LOffset.ToISO8601);
end;

procedure TTestTUtcOffset.Test_ToISO8601_UTC_Minus_9_30;
var
  LOffset: TUtcOffset;
begin
  // Marquesas Islands
  LOffset := TUtcOffset.FromHoursMinutes(-9, 30);
  AssertEquals('-09:30', LOffset.ToISO8601);
end;

procedure TTestTUtcOffset.Test_Equal_SameOffset;
var
  LA, LB: TUtcOffset;
begin
  LA := TUtcOffset.FromHours(8);
  LB := TUtcOffset.FromHours(8);
  AssertTrue('Same offsets should be equal', LA = LB);
end;

procedure TTestTUtcOffset.Test_Equal_DifferentOffset;
var
  LA, LB: TUtcOffset;
begin
  LA := TUtcOffset.FromHours(8);
  LB := TUtcOffset.FromHours(5);
  AssertFalse('Different offsets should not be equal', LA = LB);
end;

procedure TTestTUtcOffset.Test_NotEqual;
var
  LA, LB: TUtcOffset;
begin
  LA := TUtcOffset.FromHours(8);
  LB := TUtcOffset.FromHours(-5);
  AssertTrue('Different offsets should be not equal', LA <> LB);
end;

procedure TTestTUtcOffset.Test_TryParse_Z;
var
  LOffset: TUtcOffset;
  LOk: Boolean;
begin
  LOk := TUtcOffset.TryParse('Z', LOffset);
  AssertTrue('Should parse Z', LOk);
  AssertEquals(0, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_TryParse_PositiveOffset;
var
  LOffset: TUtcOffset;
  LOk: Boolean;
begin
  LOk := TUtcOffset.TryParse('+08:00', LOffset);
  AssertTrue('Should parse +08:00', LOk);
  AssertEquals(8 * 3600, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_TryParse_NegativeOffset;
var
  LOffset: TUtcOffset;
  LOk: Boolean;
begin
  LOk := TUtcOffset.TryParse('-05:00', LOffset);
  AssertTrue('Should parse -05:00', LOk);
  AssertEquals(-5 * 3600, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_TryParse_WithMinutes;
var
  LOffset: TUtcOffset;
  LOk: Boolean;
begin
  LOk := TUtcOffset.TryParse('+05:30', LOffset);
  AssertTrue('Should parse +05:30', LOk);
  AssertEquals(5 * 3600 + 30 * 60, LOffset.TotalSeconds);
end;

procedure TTestTUtcOffset.Test_TryParse_Invalid;
var
  LOffset: TUtcOffset;
  LOk: Boolean;
begin
  LOk := TUtcOffset.TryParse('invalid', LOffset);
  AssertFalse('Should not parse invalid string', LOk);
end;

procedure TTestTUtcOffset.Test_Local_DoesNotCrash;
var
  LOffset: TUtcOffset;
begin
  // Just verify it doesn't crash; actual value is platform-dependent
  LOffset := TUtcOffset.Local;
  // If we get here without exception, test passes
  AssertTrue(True);
end;

initialization
  RegisterTest(TTestTUtcOffset);
  
end.
