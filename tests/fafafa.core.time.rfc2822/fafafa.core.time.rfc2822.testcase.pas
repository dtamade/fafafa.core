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
    procedure Test_Parse_Standard;
    procedure Test_Parse_WithSeconds;
    procedure Test_Parse_NegativeOffset;
    procedure Test_Parse_UTC_Z;
    procedure Test_Parse_UTC_UT;
    procedure Test_Parse_UTC_GMT;
    
    // === 时区名称解析 ===
    procedure Test_Parse_EST;
    procedure Test_Parse_PST;
    
    // === 边界情况 ===
    procedure Test_Parse_InvalidFormat;
    procedure Test_Parse_InvalidMonth;
    
    // === 往返测试 ===
    procedure Test_Roundtrip;
  end;

implementation

// === 格式化测试 ===

procedure TTestCase_RFC2822.Test_Format_UTC;
var Dt: TZonedDateTime; s: string;
begin
  Dt := TZonedDateTime.Create(2024, 12, 3, 12, 30, 45, TUtcOffset.UTC);
  s := FormatRFC2822(Dt);
  // 格式: Tue, 03 Dec 2024 12:30:45 +0000
  CheckEquals('Tue, 03 Dec 2024 12:30:45 +0000', s);
end;

procedure TTestCase_RFC2822.Test_Format_PositiveOffset;
var Dt: TZonedDateTime; s: string;
begin
  Dt := TZonedDateTime.Create(2024, 12, 3, 20, 30, 45, TUtcOffset.FromHours(8));
  s := FormatRFC2822(Dt);
  CheckEquals('Tue, 03 Dec 2024 20:30:45 +0800', s);
end;

procedure TTestCase_RFC2822.Test_Format_NegativeOffset;
var Dt: TZonedDateTime; s: string;
begin
  Dt := TZonedDateTime.Create(2024, 12, 3, 7, 30, 45, TUtcOffset.FromHours(-5));
  s := FormatRFC2822(Dt);
  CheckEquals('Tue, 03 Dec 2024 07:30:45 -0500', s);
end;

// === 解析测试 ===

procedure TTestCase_RFC2822.Test_Parse_Standard;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 12:30:45 +0800', Dt);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(2024, Dt.Year);
  CheckEquals(12, Dt.Month);
  CheckEquals(3, Dt.Day);
  CheckEquals(12, Dt.Hour);
  CheckEquals(30, Dt.Minute);
  CheckEquals(45, Dt.Second);
  CheckEquals(8 * 3600, Dt.Offset.TotalSeconds);
end;

procedure TTestCase_RFC2822.Test_Parse_WithSeconds;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Wed, 04 Dec 2024 09:15:30 +0000', Dt);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(9, Dt.Hour);
  CheckEquals(15, Dt.Minute);
  CheckEquals(30, Dt.Second);
end;

procedure TTestCase_RFC2822.Test_Parse_NegativeOffset;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 07:30:00 -0500', Dt);
  CheckTrue(ok, 'Parse should succeed');
  CheckEquals(-5 * 3600, Dt.Offset.TotalSeconds);
end;

procedure TTestCase_RFC2822.Test_Parse_UTC_Z;
var Dt: TZonedDateTime; ok: Boolean;
begin
  // 虽然 Z 不是标准 RFC 2822，但很多实现支持
  ok := TryParseRFC2822('Tue, 03 Dec 2024 12:30:45 Z', Dt);
  if ok then
    CheckTrue(Dt.Offset.IsUTC);
end;

procedure TTestCase_RFC2822.Test_Parse_UTC_UT;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 12:30:45 UT', Dt);
  CheckTrue(ok, 'Parse UT should succeed');
  CheckTrue(Dt.Offset.IsUTC);
end;

procedure TTestCase_RFC2822.Test_Parse_UTC_GMT;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 12:30:45 GMT', Dt);
  CheckTrue(ok, 'Parse GMT should succeed');
  CheckTrue(Dt.Offset.IsUTC);
end;

// === 时区名称解析 ===

procedure TTestCase_RFC2822.Test_Parse_EST;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 07:30:45 EST', Dt);
  CheckTrue(ok, 'Parse EST should succeed');
  CheckEquals(-5 * 3600, Dt.Offset.TotalSeconds);  // EST = UTC-5
end;

procedure TTestCase_RFC2822.Test_Parse_PST;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Dec 2024 04:30:45 PST', Dt);
  CheckTrue(ok, 'Parse PST should succeed');
  CheckEquals(-8 * 3600, Dt.Offset.TotalSeconds);  // PST = UTC-8
end;

// === 边界情况 ===

procedure TTestCase_RFC2822.Test_Parse_InvalidFormat;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('not a valid date', Dt);
  CheckFalse(ok, 'Parse should fail for invalid input');
end;

procedure TTestCase_RFC2822.Test_Parse_InvalidMonth;
var Dt: TZonedDateTime; ok: Boolean;
begin
  ok := TryParseRFC2822('Tue, 03 Xyz 2024 12:30:45 +0000', Dt);
  CheckFalse(ok, 'Parse should fail for invalid month');
end;

// === 往返测试 ===

procedure TTestCase_RFC2822.Test_Roundtrip;
var Dt1, Dt2: TZonedDateTime; s: string; ok: Boolean;
begin
  Dt1 := TZonedDateTime.Create(2024, 12, 3, 14, 30, 45, TUtcOffset.FromHours(8));
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
