unit fafafa.core.time.rfc2822.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.rfc2822,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset;

type
  TTestCase_RFC2822 = class(TTestCase)
  published
    // === 格式化测试 ===
    procedure Test_Format_UTC;
    procedure Test_Format_PositiveOffset;
    procedure Test_Format_NegativeOffset;
    
    // === 解析测试 ===
    procedure Test_Parse_WithTimezone;
    procedure Test_Parse_UTC;
    procedure Test_Parse_NegativeOffset;
    procedure Test_Parse_TwoDigitYear;
    
    // === 边界情况 ===
    procedure Test_Parse_Invalid;
    procedure Test_Parse_MissingTimezone;
    
    // === 往返测试 ===
    procedure Test_Roundtrip;
  end;

implementation

// RFC 2822 格式: "Tue, 03 Dec 2024 12:30:45 +0800"

procedure TTestCase_RFC2822.Test_Format_UTC;
var Dt: TZonedDateTime;
begin
  Dt := TZonedDateTime.Create(2024, 12, 3, 12, 30, 45, TUtcOffset.UTC);
  CheckEquals('Tue, 03 Dec 2024 12:30:45 +0000', FormatRFC2822(Dt));
end;

procedure TTestCase_RFC2822.Test_Format_PositiveOffset;
var Dt: TZonedDateTime;
begin
  Dt := TZonedDateTime.Create(2024, 12, 3, 20, 30, 45, TUtcOffset.FromHours(8));
  CheckEquals('Tue, 03 Dec 2024 20:30:45 +0800', FormatRFC2822(Dt));
end;

procedure TTestCase_RFC2822.Test_Format_NegativeOffset;
var Dt: TZonedDateTime;
begin
  Dt := TZonedDateTime.Create(2024, 12, 3, 7, 30, 45, TUtcOffset.FromHours(-5));
  CheckEquals('Tue, 03 Dec 2024 07:30:45 -0500', FormatRFC2822(Dt));
end;

// === 解析测试 ===

procedure TTestCase_RFC2822.Test_Parse_WithTimezone;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 20:30:45 +0800', Dt);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(2024, Dt.Year);
  CheckEquals(12, Dt.Month);
  CheckEquals(3, Dt.Day);
  CheckEquals(20, Dt.Hour);
  CheckEquals(30, Dt.Minute);
  CheckEquals(45, Dt.Second);
  CheckEquals(8 * 3600, Dt.Offset.TotalSeconds);
end;

procedure TTestCase_RFC2822.Test_Parse_UTC;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 12:30:45 +0000', Dt);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(12, Dt.Hour);
  CheckTrue(Dt.Offset.IsUTC);
end;

procedure TTestCase_RFC2822.Test_Parse_NegativeOffset;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 07:30:45 -0500', Dt);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(7, Dt.Hour);
  CheckEquals(-5 * 3600, Dt.Offset.TotalSeconds);
end;

procedure TTestCase_RFC2822.Test_Parse_TwoDigitYear;
var Dt: TZonedDateTime; ok: Boolean;
begin
  // RFC 2822 允许 2 位年份
  ok := TryParseRFC2822('Tue, 03 Dec 24 12:30:45 +0000', Dt);
  CheckTrue(ok, 'Parse 2-digit year should succeed');
  CheckEquals(2024, Dt.Year);
end;

// === 边界情况 ===

procedure TTestCase_RFC2822.Test_Parse_Invalid;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('not a date', Dt);
  CheckFalse(ok, 'Parse should fail for invalid input');
end;

procedure TTestCase_RFC2822.Test_Parse_MissingTimezone;
var Dt: TZonedDateTime; ok: Boolean;
begin
  // 没有时区信息应该失败
  ok := TryParseRFC2822('Tue, 03 Dec 2024 12:30:45', Dt);
  CheckFalse(ok, 'Parse should fail without timezone');
end;

// === 往返测试 ===

procedure TTestCase_RFC2822.Test_Roundtrip;
var Dt1, Dt2: TZonedDateTime; s: string; ok: Boolean;
begin
  Dt1 := TZonedDateTime.Create(2024, 12, 3, 20, 30, 45, TUtcOffset.FromHours(8));
  s := FormatRFC2822(Dt1);
  ok := TryParseRFC2822(s, Dt2);
  CheckTrue(ok, 'Roundtrip parse should succeed');
  CheckEquals(Dt1.Year, Dt2.Year);
  CheckEquals(Dt1.Month, Dt2.Month);
  CheckEquals(Dt1.Day, Dt2.Day);
  CheckEquals(Dt1.Hour, Dt2.Hour);
  CheckEquals(Dt1.Minute, Dt2.Minute);
  CheckEquals(Dt1.Second, Dt2.Second);
  CheckEquals(Dt1.Offset.TotalSeconds, Dt2.Offset.TotalSeconds);
end;

initialization
  RegisterTest(TTestCase_RFC2822);
end.
