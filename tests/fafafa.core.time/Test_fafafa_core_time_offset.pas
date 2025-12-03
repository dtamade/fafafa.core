unit Test_fafafa_core_time_offset;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.offset;

type
  TTestCase_UtcOffset = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // 构造函数测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_UTC_ReturnsZeroOffset;
    procedure Test_Local_ReturnsSystemOffset;
    procedure Test_FromHours_PositiveHours_Success;
    procedure Test_FromHours_NegativeHours_Success;
    procedure Test_FromHoursMinutes_PositiveWithMinutes_Success;
    procedure Test_FromHoursMinutes_NegativeWithMinutes_Success;
    procedure Test_FromSeconds_ReturnsCorrectOffset;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_TotalSeconds_ReturnsCorrectValue;
    procedure Test_TotalMinutes_ReturnsCorrectValue;
    procedure Test_Hours_ReturnsCorrectValue;
    procedure Test_Minutes_ReturnsCorrectValue;
    procedure Test_Hours_NegativeOffset_ReturnsNegative;
    procedure Test_Minutes_NegativeOffset_ReturnsPositive;
    
    // ═══════════════════════════════════════════════════════════════
    // 格式化测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ToISO8601_UTC_ReturnsZ;
    procedure Test_ToISO8601_PositiveOffset_ReturnsPlus;
    procedure Test_ToISO8601_NegativeOffset_ReturnsMinus;
    procedure Test_ToISO8601_WithMinutes_IncludesMinutes;
    procedure Test_ToString_UTC_ReturnsUTC;
    procedure Test_ToString_PositiveOffset_IncludesSign;
    
    // ═══════════════════════════════════════════════════════════════
    // 解析测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_TryParse_Z_ReturnsUTC;
    procedure Test_TryParse_LowercaseZ_ReturnsUTC;
    procedure Test_TryParse_PositiveOffset_Success;
    procedure Test_TryParse_NegativeOffset_Success;
    procedure Test_TryParse_WithMinutes_Success;
    procedure Test_TryParse_InvalidFormat_ReturnsFalse;
    procedure Test_TryParse_OutOfRange_ReturnsFalse;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Equal_SameOffset_ReturnsTrue;
    procedure Test_Equal_DifferentOffset_ReturnsFalse;
    procedure Test_NotEqual_DifferentOffset_ReturnsTrue;
    procedure Test_LessThan_WesternOffset_ReturnsTrue;
    procedure Test_GreaterThan_EasternOffset_ReturnsTrue;
    procedure Test_LessOrEqual_SameOffset_ReturnsTrue;
    procedure Test_GreaterOrEqual_SameOffset_ReturnsTrue;
    
    // ═══════════════════════════════════════════════════════════════
    // 工具函数测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_IsUTC_ZeroOffset_ReturnsTrue;
    procedure Test_IsUTC_NonZeroOffset_ReturnsFalse;
  end;

implementation

{ TTestCase_UtcOffset }

// ═══════════════════════════════════════════════════════════════
// 构造函数测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_UtcOffset.Test_UTC_ReturnsZeroOffset;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.UTC;
  AssertEquals('TotalSeconds', 0, O.TotalSeconds);
  AssertTrue('IsUTC', O.IsUTC);
end;

procedure TTestCase_UtcOffset.Test_Local_ReturnsSystemOffset;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.Local;
  // 只验证返回有效值（具体值取决于系统时区）
  AssertTrue('Should be between -12h and +14h', 
    (O.TotalSeconds >= -43200) and (O.TotalSeconds <= 50400));
end;

procedure TTestCase_UtcOffset.Test_FromHours_PositiveHours_Success;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHours(8);  // UTC+8
  AssertEquals('Hours', 8, O.Hours);
  AssertEquals('TotalSeconds', 8 * 3600, O.TotalSeconds);
end;

procedure TTestCase_UtcOffset.Test_FromHours_NegativeHours_Success;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHours(-5);  // UTC-5
  AssertEquals('Hours', -5, O.Hours);
  AssertEquals('TotalSeconds', -5 * 3600, O.TotalSeconds);
end;

procedure TTestCase_UtcOffset.Test_FromHoursMinutes_PositiveWithMinutes_Success;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHoursMinutes(5, 30);  // UTC+5:30 (India)
  AssertEquals('Hours', 5, O.Hours);
  AssertEquals('Minutes', 30, O.Minutes);
  AssertEquals('TotalSeconds', 5 * 3600 + 30 * 60, O.TotalSeconds);
end;

procedure TTestCase_UtcOffset.Test_FromHoursMinutes_NegativeWithMinutes_Success;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHoursMinutes(-3, 30);  // UTC-3:30 (Newfoundland)
  AssertEquals('Hours', -3, O.Hours);
  AssertEquals('Minutes', 30, O.Minutes);
  AssertEquals('TotalSeconds', -3 * 3600 - 30 * 60, O.TotalSeconds);
end;

procedure TTestCase_UtcOffset.Test_FromSeconds_ReturnsCorrectOffset;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromSeconds(19800);  // 5.5 hours = 5:30
  AssertEquals('TotalSeconds', 19800, O.TotalSeconds);
end;

// ═══════════════════════════════════════════════════════════════
// 访问器测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_UtcOffset.Test_TotalSeconds_ReturnsCorrectValue;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHours(8);
  AssertEquals('TotalSeconds', 28800, O.TotalSeconds);
end;

procedure TTestCase_UtcOffset.Test_TotalMinutes_ReturnsCorrectValue;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHoursMinutes(5, 30);
  AssertEquals('TotalMinutes', 330, O.TotalMinutes);
end;

procedure TTestCase_UtcOffset.Test_Hours_ReturnsCorrectValue;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHoursMinutes(8, 45);
  AssertEquals('Hours', 8, O.Hours);
end;

procedure TTestCase_UtcOffset.Test_Minutes_ReturnsCorrectValue;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHoursMinutes(5, 30);
  AssertEquals('Minutes', 30, O.Minutes);
end;

procedure TTestCase_UtcOffset.Test_Hours_NegativeOffset_ReturnsNegative;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHours(-5);
  AssertEquals('Hours', -5, O.Hours);
end;

procedure TTestCase_UtcOffset.Test_Minutes_NegativeOffset_ReturnsPositive;
var
  O: TUtcOffset;
begin
  // Minutes should always be positive (absolute value)
  O := TUtcOffset.FromHoursMinutes(-5, 30);
  AssertEquals('Minutes', 30, O.Minutes);
end;

// ═══════════════════════════════════════════════════════════════
// 格式化测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_UtcOffset.Test_ToISO8601_UTC_ReturnsZ;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.UTC;
  AssertEquals('ISO8601', 'Z', O.ToISO8601);
end;

procedure TTestCase_UtcOffset.Test_ToISO8601_PositiveOffset_ReturnsPlus;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHours(8);
  AssertEquals('ISO8601', '+08:00', O.ToISO8601);
end;

procedure TTestCase_UtcOffset.Test_ToISO8601_NegativeOffset_ReturnsMinus;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHours(-5);
  AssertEquals('ISO8601', '-05:00', O.ToISO8601);
end;

procedure TTestCase_UtcOffset.Test_ToISO8601_WithMinutes_IncludesMinutes;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHoursMinutes(5, 30);
  AssertEquals('ISO8601', '+05:30', O.ToISO8601);
end;

procedure TTestCase_UtcOffset.Test_ToString_UTC_ReturnsUTC;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.UTC;
  AssertEquals('ToString', 'UTC', O.ToString);
end;

procedure TTestCase_UtcOffset.Test_ToString_PositiveOffset_IncludesSign;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHours(8);
  AssertEquals('ToString', 'UTC+08:00', O.ToString);
end;

// ═══════════════════════════════════════════════════════════════
// 解析测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_UtcOffset.Test_TryParse_Z_ReturnsUTC;
var
  O: TUtcOffset;
  Ok: Boolean;
begin
  Ok := TUtcOffset.TryParse('Z', O);
  AssertTrue('TryParse should succeed', Ok);
  AssertTrue('Should be UTC', O.IsUTC);
end;

procedure TTestCase_UtcOffset.Test_TryParse_LowercaseZ_ReturnsUTC;
var
  O: TUtcOffset;
  Ok: Boolean;
begin
  Ok := TUtcOffset.TryParse('z', O);
  AssertTrue('TryParse should succeed', Ok);
  AssertTrue('Should be UTC', O.IsUTC);
end;

procedure TTestCase_UtcOffset.Test_TryParse_PositiveOffset_Success;
var
  O: TUtcOffset;
  Ok: Boolean;
begin
  Ok := TUtcOffset.TryParse('+08:00', O);
  AssertTrue('TryParse should succeed', Ok);
  AssertEquals('Hours', 8, O.Hours);
  AssertEquals('Minutes', 0, O.Minutes);
end;

procedure TTestCase_UtcOffset.Test_TryParse_NegativeOffset_Success;
var
  O: TUtcOffset;
  Ok: Boolean;
begin
  Ok := TUtcOffset.TryParse('-05:00', O);
  AssertTrue('TryParse should succeed', Ok);
  AssertEquals('Hours', -5, O.Hours);
end;

procedure TTestCase_UtcOffset.Test_TryParse_WithMinutes_Success;
var
  O: TUtcOffset;
  Ok: Boolean;
begin
  Ok := TUtcOffset.TryParse('+05:30', O);
  AssertTrue('TryParse should succeed', Ok);
  AssertEquals('Hours', 5, O.Hours);
  AssertEquals('Minutes', 30, O.Minutes);
end;

procedure TTestCase_UtcOffset.Test_TryParse_InvalidFormat_ReturnsFalse;
var
  O: TUtcOffset;
begin
  AssertFalse('Missing sign', TUtcOffset.TryParse('08:00', O));
  AssertFalse('Too short', TUtcOffset.TryParse('+8:00', O));
  AssertFalse('Missing colon', TUtcOffset.TryParse('+0800', O));
  AssertFalse('Empty string', TUtcOffset.TryParse('', O));
end;

procedure TTestCase_UtcOffset.Test_TryParse_OutOfRange_ReturnsFalse;
var
  O: TUtcOffset;
begin
  AssertFalse('Hours > 14', TUtcOffset.TryParse('+15:00', O));
  AssertFalse('Minutes > 59', TUtcOffset.TryParse('+05:60', O));
end;

// ═══════════════════════════════════════════════════════════════
// 比较运算符测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_UtcOffset.Test_Equal_SameOffset_ReturnsTrue;
var
  O1, O2: TUtcOffset;
begin
  O1 := TUtcOffset.FromHours(8);
  O2 := TUtcOffset.FromHours(8);
  AssertTrue('Same offset', O1 = O2);
end;

procedure TTestCase_UtcOffset.Test_Equal_DifferentOffset_ReturnsFalse;
var
  O1, O2: TUtcOffset;
begin
  O1 := TUtcOffset.FromHours(8);
  O2 := TUtcOffset.FromHours(9);
  AssertFalse('Different offset', O1 = O2);
end;

procedure TTestCase_UtcOffset.Test_NotEqual_DifferentOffset_ReturnsTrue;
var
  O1, O2: TUtcOffset;
begin
  O1 := TUtcOffset.FromHours(8);
  O2 := TUtcOffset.FromHours(-5);
  AssertTrue('Not equal', O1 <> O2);
end;

procedure TTestCase_UtcOffset.Test_LessThan_WesternOffset_ReturnsTrue;
var
  O1, O2: TUtcOffset;
begin
  O1 := TUtcOffset.FromHours(-5);  // UTC-5 (西)
  O2 := TUtcOffset.FromHours(8);   // UTC+8 (东)
  AssertTrue('Western is less than Eastern', O1 < O2);
end;

procedure TTestCase_UtcOffset.Test_GreaterThan_EasternOffset_ReturnsTrue;
var
  O1, O2: TUtcOffset;
begin
  O1 := TUtcOffset.FromHours(8);   // UTC+8 (东)
  O2 := TUtcOffset.FromHours(-5);  // UTC-5 (西)
  AssertTrue('Eastern is greater than Western', O1 > O2);
end;

procedure TTestCase_UtcOffset.Test_LessOrEqual_SameOffset_ReturnsTrue;
var
  O1, O2: TUtcOffset;
begin
  O1 := TUtcOffset.FromHours(8);
  O2 := TUtcOffset.FromHours(8);
  AssertTrue('Same offset', O1 <= O2);
end;

procedure TTestCase_UtcOffset.Test_GreaterOrEqual_SameOffset_ReturnsTrue;
var
  O1, O2: TUtcOffset;
begin
  O1 := TUtcOffset.FromHours(8);
  O2 := TUtcOffset.FromHours(8);
  AssertTrue('Same offset', O1 >= O2);
end;

// ═══════════════════════════════════════════════════════════════
// 工具函数测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_UtcOffset.Test_IsUTC_ZeroOffset_ReturnsTrue;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.UTC;
  AssertTrue('UTC', O.IsUTC);
end;

procedure TTestCase_UtcOffset.Test_IsUTC_NonZeroOffset_ReturnsFalse;
var
  O: TUtcOffset;
begin
  O := TUtcOffset.FromHours(8);
  AssertFalse('Not UTC', O.IsUTC);
end;

initialization
  RegisterTest(TTestCase_UtcOffset);

end.
