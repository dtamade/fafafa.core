unit fafafa.core.time.tz.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.tz, fafafa.core.time.offset;

type
  TTestCase_TimeZone = class(TTestCase)
  published
    // === 基础框架测试 ===
    procedure Test_UTC_ReturnsUtcTimeZone;
    procedure Test_FromId_UTC_ReturnsUtcTimeZone;
    procedure Test_GetId_ReturnsCorrectId;
    procedure Test_GetOffset_AtInstant_ReturnsCorrectOffset;
    procedure Test_Local_ReturnsSystemTimeZone;
    procedure Test_FromId_InvalidId_ReturnsFalse;
    procedure Test_Equality_SameZone;
    
    // === 系统时区检测测试 ===
    procedure Test_Local_IdIsValidFormat;
    procedure Test_Local_OffsetInReasonableRange;
    procedure Test_Local_CalledTwice_ReturnsSameId;
    
    // === IANA 时区测试 ===
    procedure Test_FromId_AsiaShanghai_ReturnsPlus8;
    procedure Test_FromId_AmericaNewYork_ReturnsMinus5;
  end;

implementation

uses
  fafafa.core.time.instant;

procedure TTestCase_TimeZone.Test_UTC_ReturnsUtcTimeZone;
var tz: TTimeZone;
begin
  tz := TTimeZone.UTC;
  CheckEquals('UTC', tz.GetId);
  CheckTrue(tz.IsFixedOffset);
end;

procedure TTestCase_TimeZone.Test_FromId_UTC_ReturnsUtcTimeZone;
var tz: TTimeZone; ok: Boolean;
begin
  ok := TTimeZone.TryFromId('UTC', tz);
  CheckTrue(ok);
  CheckEquals('UTC', tz.GetId);
end;

procedure TTestCase_TimeZone.Test_GetId_ReturnsCorrectId;
var tz: TTimeZone;
begin
  tz := TTimeZone.UTC;
  CheckEquals('UTC', tz.GetId);
end;

procedure TTestCase_TimeZone.Test_GetOffset_AtInstant_ReturnsCorrectOffset;
var tz: TTimeZone; inst: TInstant; offset: TUtcOffset;
begin
  tz := TTimeZone.UTC;
  inst := TInstant.FromUnixSec(0);  // Unix epoch
  offset := tz.GetOffsetAt(inst);
  CheckEquals(0, offset.TotalSeconds);
end;

procedure TTestCase_TimeZone.Test_Local_ReturnsSystemTimeZone;
var tz: TTimeZone;
begin
  tz := TTimeZone.Local;
  // 本地时区应该有一个非空的 ID
  CheckTrue(Length(tz.GetId) > 0);
end;

procedure TTestCase_TimeZone.Test_FromId_InvalidId_ReturnsFalse;
var tz: TTimeZone; ok: Boolean;
begin
  ok := TTimeZone.TryFromId('Invalid/Zone/Name', tz);
  CheckFalse(ok);
end;

procedure TTestCase_TimeZone.Test_Equality_SameZone;
var tz1, tz2: TTimeZone;
begin
  tz1 := TTimeZone.UTC;
  tz2 := TTimeZone.UTC;
  CheckTrue(tz1 = tz2);
end;

// === 系统时区检测测试 ===

procedure TTestCase_TimeZone.Test_Local_IdIsValidFormat;
var tz: TTimeZone; id: string;
begin
  tz := TTimeZone.Local;
  id := tz.GetId;
  // ID 应为 "Local" 或 IANA 格式（包含 /）
  CheckTrue((id = 'Local') or (Pos('/', id) > 0), 'ID should be Local or IANA format: ' + id);
end;

procedure TTestCase_TimeZone.Test_Local_OffsetInReasonableRange;
var tz: TTimeZone; inst: TInstant; offset: TUtcOffset; secs: Integer;
begin
  tz := TTimeZone.Local;
  inst := TInstant.FromUnixSec(0);  // Unix epoch
  offset := tz.GetOffsetAt(inst);
  secs := offset.TotalSeconds;
  // 全球时区范围: UTC-12 到 UTC+14
  CheckTrue((secs >= -12 * 3600) and (secs <= 14 * 3600),
    'Offset should be in valid timezone range: ' + IntToStr(secs));
end;

procedure TTestCase_TimeZone.Test_Local_CalledTwice_ReturnsSameId;
var tz1, tz2: TTimeZone;
begin
  tz1 := TTimeZone.Local;
  tz2 := TTimeZone.Local;
  CheckEquals(tz1.GetId, tz2.GetId);
end;

// === IANA 时区测试 ===

procedure TTestCase_TimeZone.Test_FromId_AsiaShanghai_ReturnsPlus8;
var tz: TTimeZone; ok: Boolean; offset: TUtcOffset; inst: TInstant;
begin
  ok := TTimeZone.TryFromId('Asia/Shanghai', tz);
  CheckTrue(ok);
  CheckEquals('Asia/Shanghai', tz.GetId);
  CheckFalse(tz.IsFixedOffset);  // IANA 时区不是固定偏移
  
  inst := TInstant.FromUnixSec(0);
  offset := tz.GetOffsetAt(inst);
  CheckEquals(8 * 3600, offset.TotalSeconds);  // UTC+8
end;

procedure TTestCase_TimeZone.Test_FromId_AmericaNewYork_ReturnsMinus5;
var tz: TTimeZone; ok: Boolean; offset: TUtcOffset; inst: TInstant;
begin
  ok := TTimeZone.TryFromId('America/New_York', tz);
  CheckTrue(ok);
  CheckEquals('America/New_York', tz.GetId);
  
  inst := TInstant.FromUnixSec(0);
  offset := tz.GetOffsetAt(inst);
  // 注意: 当前版本不处理 DST，返回标准时间 UTC-5
  CheckEquals(-5 * 3600, offset.TotalSeconds);
end;

initialization
  RegisterTest(TTestCase_TimeZone);
end.
