unit fafafa.core.time.instant.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.instant, fafafa.core.time.duration;

type
  TTestCase_Instant = class(TTestCase)
  published
    procedure Test_Diff_Since;
    procedure Test_CheckedAdd_Sub;
    // === ISO8601 测试 ===
    procedure Test_FromUnixNs_CreatesCorrectInstant;
    procedure Test_ToISO8601_WithNanoseconds;
    procedure Test_TryParseISO8601_ValidFormats;
    procedure Test_TryParseISO8601_InvalidFormats;
  end;

implementation

procedure TTestCase_Instant.Test_Diff_Since;
var a,b: TInstant; d: TDuration;
begin
  a := TInstant.FromNsSinceEpoch(100);
  b := TInstant.FromNsSinceEpoch(40);
  d := a.Diff(b);
  CheckEquals(60, d.AsNs);
  d := a.Since(b);
  CheckEquals(60, d.AsNs);
end;

procedure TTestCase_Instant.Test_CheckedAdd_Sub;
var a,b: TInstant; ok: Boolean; d: TDuration;
begin
  a := TInstant.FromNsSinceEpoch(100);
  ok := a.CheckedAdd(TDuration.FromNs(23), b);
  CheckTrue(ok);
  CheckEquals(123, b.AsNsSinceEpoch);
  ok := b.CheckedSub(TDuration.FromNs(23), a);
  CheckTrue(ok);
  CheckEquals(100, a.AsNsSinceEpoch);
end;

// === ISO8601 测试实现 ===

procedure TTestCase_Instant.Test_FromUnixNs_CreatesCorrectInstant;
var inst: TInstant;
begin
  // 1970-01-01 00:00:00.123456789 UTC
  inst := TInstant.FromUnixNs(123456789);
  CheckEquals(UInt64(123456789), inst.AsNsSinceEpoch);
  
  // 负值饱和到0
  inst := TInstant.FromUnixNs(-100);
  CheckEquals(UInt64(0), inst.AsNsSinceEpoch);
end;

procedure TTestCase_Instant.Test_ToISO8601_WithNanoseconds;
var inst: TInstant;
const
  // 2025-01-15 14:30:45.123456789 UTC
  // Unix timestamp: 1736951445 seconds + 123456789 ns
  NS_PER_SEC = UInt64(1000000000);
  UNIX_SEC = Int64(1736951445);
begin
  // 完整纳秒
  inst := TInstant.FromUnixNs(UNIX_SEC * Int64(NS_PER_SEC) + 123456789);
  CheckEquals('2025-01-15T14:30:45.123456789Z', inst.ToISO8601);
  
  // 微秒级（末尾零省略）
  inst := TInstant.FromUnixNs(UNIX_SEC * Int64(NS_PER_SEC) + 123456000);
  CheckEquals('2025-01-15T14:30:45.123456Z', inst.ToISO8601);
  
  // 毫秒级
  inst := TInstant.FromUnixNs(UNIX_SEC * Int64(NS_PER_SEC) + 123000000);
  CheckEquals('2025-01-15T14:30:45.123Z', inst.ToISO8601);
  
  // 无小数部分
  inst := TInstant.FromUnixNs(UNIX_SEC * Int64(NS_PER_SEC));
  CheckEquals('2025-01-15T14:30:45Z', inst.ToISO8601);
end;

procedure TTestCase_Instant.Test_TryParseISO8601_ValidFormats;
var inst: TInstant; ok: Boolean;
const
  NS_PER_SEC = UInt64(1000000000);
  UNIX_SEC = Int64(1736951445);
begin
  // 完整纳秒
  ok := TInstant.TryParseISO8601('2025-01-15T14:30:45.123456789Z', inst);
  CheckTrue(ok);
  CheckEquals(UInt64(UNIX_SEC * Int64(NS_PER_SEC) + 123456789), inst.AsNsSinceEpoch);
  
  // 无小数部分
  ok := TInstant.TryParseISO8601('2025-01-15T14:30:45Z', inst);
  CheckTrue(ok);
  CheckEquals(UInt64(UNIX_SEC * Int64(NS_PER_SEC)), inst.AsNsSinceEpoch);
  
  // 毫秒
  ok := TInstant.TryParseISO8601('2025-01-15T14:30:45.123Z', inst);
  CheckTrue(ok);
  CheckEquals(UInt64(UNIX_SEC * Int64(NS_PER_SEC) + 123000000), inst.AsNsSinceEpoch);
end;

procedure TTestCase_Instant.Test_TryParseISO8601_InvalidFormats;
var inst: TInstant; ok: Boolean;
begin
  // 缺少Z
  ok := TInstant.TryParseISO8601('2025-01-15T14:30:45', inst);
  CheckFalse(ok);
  
  // 无效日期
  ok := TInstant.TryParseISO8601('2025-13-45T14:30:45Z', inst);
  CheckFalse(ok);
  
  // 空字符串
  ok := TInstant.TryParseISO8601('', inst);
  CheckFalse(ok);
end;

initialization
  RegisterTest(TTestCase_Instant);
end.

