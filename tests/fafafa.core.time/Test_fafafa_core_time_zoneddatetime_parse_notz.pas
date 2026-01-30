{$mode objfpc}{$H+}{$J-}

unit Test_fafafa_core_time_zoneddatetime_parse_notz;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset;

type
  { TTestZonedDateTimeParseNoTZ }
  TTestZonedDateTimeParseNoTZ = class(TTestCase)
  published
    // 测试无时区字符串默认使用 UTC
    procedure Test_TryParse_NoTimeZone_DefaultsToUTC;
    procedure Test_TryParse_WithZ_ParsesUTC;
    procedure Test_TryParse_WithPositiveOffset_ParsesCorrectly;
    procedure Test_TryParse_WithNegativeOffset_ParsesCorrectly;
    procedure Test_TryParse_Invalid_ReturnsFalse;
    
    // TUtcOffset.TryParse 空字符串测试
    procedure Test_UtcOffset_TryParse_Empty_ReturnsUTC;
  end;

implementation

{ TTestZonedDateTimeParseNoTZ }

procedure TTestZonedDateTimeParseNoTZ.Test_TryParse_NoTimeZone_DefaultsToUTC;
var
  zdt: TZonedDateTime;
  ok: Boolean;
begin
  // 无时区信息的 ISO 8601 字符串应默认解析为 UTC
  ok := TZonedDateTime.TryParse('2025-06-15T14:30:45', zdt);
  
  AssertTrue('Should parse successfully', ok);
  AssertEquals('Year', 2025, zdt.Year);
  AssertEquals('Month', 6, zdt.Month);
  AssertEquals('Day', 15, zdt.Day);
  AssertEquals('Hour', 14, zdt.Hour);
  AssertEquals('Minute', 30, zdt.Minute);
  AssertEquals('Second', 45, zdt.Second);
  AssertTrue('Offset should be UTC', zdt.Offset.IsUTC);
end;

procedure TTestZonedDateTimeParseNoTZ.Test_TryParse_WithZ_ParsesUTC;
var
  zdt: TZonedDateTime;
  ok: Boolean;
begin
  ok := TZonedDateTime.TryParse('2025-06-15T14:30:45Z', zdt);
  
  AssertTrue('Should parse successfully', ok);
  AssertEquals('Hour', 14, zdt.Hour);
  AssertTrue('Offset should be UTC', zdt.Offset.IsUTC);
end;

procedure TTestZonedDateTimeParseNoTZ.Test_TryParse_WithPositiveOffset_ParsesCorrectly;
var
  zdt: TZonedDateTime;
  ok: Boolean;
begin
  ok := TZonedDateTime.TryParse('2025-06-15T14:30:45+08:00', zdt);
  
  AssertTrue('Should parse successfully', ok);
  AssertEquals('Hour', 14, zdt.Hour);
  AssertEquals('Offset hours', 8, zdt.Offset.Hours);
  AssertEquals('Offset minutes', 0, zdt.Offset.Minutes);
end;

procedure TTestZonedDateTimeParseNoTZ.Test_TryParse_WithNegativeOffset_ParsesCorrectly;
var
  zdt: TZonedDateTime;
  ok: Boolean;
begin
  ok := TZonedDateTime.TryParse('2025-06-15T14:30:45-05:30', zdt);
  
  AssertTrue('Should parse successfully', ok);
  AssertEquals('Hour', 14, zdt.Hour);
  AssertEquals('Offset hours', -5, zdt.Offset.Hours);
  AssertEquals('Offset minutes', 30, zdt.Offset.Minutes);
end;

procedure TTestZonedDateTimeParseNoTZ.Test_TryParse_Invalid_ReturnsFalse;
var
  zdt: TZonedDateTime;
begin
  // 缺少 T 分隔符
  AssertFalse('Missing T', TZonedDateTime.TryParse('2025-06-15 14:30:45', zdt));
  
  // 空字符串
  AssertFalse('Empty string', TZonedDateTime.TryParse('', zdt));
  
  // 无效日期
  AssertFalse('Invalid date', TZonedDateTime.TryParse('invalid', zdt));
end;

procedure TTestZonedDateTimeParseNoTZ.Test_UtcOffset_TryParse_Empty_ReturnsUTC;
var
  offset: TUtcOffset;
  ok: Boolean;
begin
  ok := TUtcOffset.TryParse('', offset);
  
  AssertTrue('Empty string should parse as UTC', ok);
  AssertTrue('Should be UTC', offset.IsUTC);
  AssertEquals('TotalSeconds should be 0', 0, offset.TotalSeconds);
end;

initialization
  RegisterTest(TTestZonedDateTimeParseNoTZ);

end.
