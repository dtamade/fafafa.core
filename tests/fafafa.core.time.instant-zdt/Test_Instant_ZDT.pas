{
  Test_Instant_ZDT.pas - TInstant <-> TZonedDateTime 互转测试
  
  TDD: 先写测试，后写实现
  
  测试覆盖:
  1. TInstant.AtOffset(TUtcOffset) -> TZonedDateTime
  2. TInstant.AtUtc -> TZonedDateTime (UTC)
  3. TZonedDateTime.ToInstant -> TInstant
  4. 往返一致性 (Roundtrip)
}
program Test_Instant_ZDT;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.instant,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset;

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;
  FailCount: Integer = 0;

procedure Check(Condition: Boolean; const TestName: string);
begin
  Inc(TestCount);
  if Condition then
  begin
    Inc(PassCount);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailCount);
    WriteLn('  ✗ ', TestName, ' [FAILED]');
  end;
end;

procedure CheckEquals(Expected, Actual: Int64; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected=%d, actual=%d)', [TestName, Expected, Actual]));
end;

procedure CheckEqualsUInt64(Expected, Actual: UInt64; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected=%d, actual=%d)', [TestName, Expected, Actual]));
end;

// ============================================================
// 测试: TInstant.AtOffset -> TZonedDateTime
// ============================================================

procedure Test_AtOffset_UTC;
var
  Inst: TInstant;
  ZDT: TZonedDateTime;
begin
  WriteLn('Test_AtOffset_UTC:');
  
  // 创建 Unix 时间戳 0 (1970-01-01 00:00:00 UTC) 对应的 Instant
  Inst := TInstant.FromUnixSec(0);
  
  // 转换为 UTC 时区的 ZonedDateTime
  ZDT := Inst.AtUtc;
  
  CheckEquals(1970, ZDT.Year, 'Year = 1970');
  CheckEquals(1, ZDT.Month, 'Month = 1');
  CheckEquals(1, ZDT.Day, 'Day = 1');
  CheckEquals(0, ZDT.Hour, 'Hour = 0');
  CheckEquals(0, ZDT.Minute, 'Minute = 0');
  CheckEquals(0, ZDT.Second, 'Second = 0');
  CheckEquals(0, ZDT.Offset.TotalSeconds, 'Offset = UTC (+00:00)');
end;

procedure Test_AtOffset_PositiveOffset;
var
  Inst: TInstant;
  ZDT: TZonedDateTime;
  OffsetPlus8: TUtcOffset;
begin
  WriteLn('Test_AtOffset_PositiveOffset:');
  
  // 创建 Unix 时间戳 0 (1970-01-01 00:00:00 UTC)
  Inst := TInstant.FromUnixSec(0);
  
  // 转换为 +08:00 (北京时间) 的 ZonedDateTime
  OffsetPlus8 := TUtcOffset.FromHours(8);
  ZDT := Inst.AtOffset(OffsetPlus8);
  
  // UTC 00:00 + 8小时 = 08:00
  CheckEquals(1970, ZDT.Year, 'Year = 1970');
  CheckEquals(1, ZDT.Month, 'Month = 1');
  CheckEquals(1, ZDT.Day, 'Day = 1');
  CheckEquals(8, ZDT.Hour, 'Hour = 8 (UTC+8)');
  CheckEquals(0, ZDT.Minute, 'Minute = 0');
  CheckEquals(0, ZDT.Second, 'Second = 0');
  CheckEquals(8 * 3600, ZDT.Offset.TotalSeconds, 'Offset = +08:00');
end;

procedure Test_AtOffset_NegativeOffset;
var
  Inst: TInstant;
  ZDT: TZonedDateTime;
  OffsetMinus5: TUtcOffset;
begin
  WriteLn('Test_AtOffset_NegativeOffset:');
  
  // 创建 Unix 时间戳 3600 (1970-01-01 01:00:00 UTC)
  Inst := TInstant.FromUnixSec(3600);
  
  // 转换为 -05:00 (纽约时间) 的 ZonedDateTime
  OffsetMinus5 := TUtcOffset.FromHours(-5);
  ZDT := Inst.AtOffset(OffsetMinus5);
  
  // UTC 01:00 - 5小时 = 前一天 20:00
  CheckEquals(1969, ZDT.Year, 'Year = 1969');
  CheckEquals(12, ZDT.Month, 'Month = 12');
  CheckEquals(31, ZDT.Day, 'Day = 31');
  CheckEquals(20, ZDT.Hour, 'Hour = 20 (UTC-5)');
  CheckEquals(0, ZDT.Minute, 'Minute = 0');
  CheckEquals(-5 * 3600, ZDT.Offset.TotalSeconds, 'Offset = -05:00');
end;

procedure Test_AtOffset_SpecificTimestamp;
var
  Inst: TInstant;
  ZDT: TZonedDateTime;
begin
  WriteLn('Test_AtOffset_SpecificTimestamp:');
  
  // 2024-06-15 12:30:45 UTC 的 Unix 时间戳
  // 计算: 从 1970-01-01 到 2024-06-15 的天数 * 86400 + 12*3600 + 30*60 + 45
  // 使用已知值: 1718451045
  Inst := TInstant.FromUnixSec(1718451045);
  
  ZDT := Inst.AtUtc;
  
  CheckEquals(2024, ZDT.Year, 'Year = 2024');
  CheckEquals(6, ZDT.Month, 'Month = 6');
  CheckEquals(15, ZDT.Day, 'Day = 15');
  CheckEquals(11, ZDT.Hour, 'Hour = 11');  // 1718451045 = 2024-06-15 11:30:45 UTC
  CheckEquals(30, ZDT.Minute, 'Minute = 30');
  CheckEquals(45, ZDT.Second, 'Second = 45');
end;

// ============================================================
// 测试: TZonedDateTime.ToInstant -> TInstant
// ============================================================

procedure Test_ToInstant_UTC;
var
  ZDT: TZonedDateTime;
  Inst: TInstant;
begin
  WriteLn('Test_ToInstant_UTC:');
  
  // 创建 1970-01-01 00:00:00 UTC
  ZDT := TZonedDateTime.Create(1970, 1, 1, 0, 0, 0, TUtcOffset.UTC);
  
  Inst := ZDT.ToInstant;
  
  CheckEqualsUInt64(0, Inst.AsNsSinceEpoch, 'Unix epoch = 0 ns');
end;

procedure Test_ToInstant_PositiveOffset;
var
  ZDT: TZonedDateTime;
  Inst: TInstant;
begin
  WriteLn('Test_ToInstant_PositiveOffset:');
  
  // 创建 1970-01-01 08:00:00 +08:00 (相当于 UTC 00:00:00)
  ZDT := TZonedDateTime.Create(1970, 1, 1, 8, 0, 0, TUtcOffset.FromHours(8));
  
  Inst := ZDT.ToInstant;
  
  CheckEqualsUInt64(0, Inst.AsNsSinceEpoch, 'Beijing 08:00 = UTC 00:00 = 0 ns');
end;

procedure Test_ToInstant_NegativeOffset;
var
  ZDT: TZonedDateTime;
  Inst: TInstant;
begin
  WriteLn('Test_ToInstant_NegativeOffset:');
  
  // 创建 1969-12-31 19:00:00 -05:00 (相当于 UTC 1970-01-01 00:00:00)
  ZDT := TZonedDateTime.Create(1969, 12, 31, 19, 0, 0, TUtcOffset.FromHours(-5));
  
  Inst := ZDT.ToInstant;
  
  CheckEqualsUInt64(0, Inst.AsNsSinceEpoch, 'NYC 19:00 Dec 31 1969 = UTC 00:00 Jan 1 1970 = 0 ns');
end;

procedure Test_ToInstant_NonZero;
var
  ZDT: TZonedDateTime;
  Inst: TInstant;
begin
  WriteLn('Test_ToInstant_NonZero:');
  
  // 创建 1970-01-01 01:00:00 UTC = 3600 seconds since epoch
  ZDT := TZonedDateTime.Create(1970, 1, 1, 1, 0, 0, TUtcOffset.UTC);
  
  Inst := ZDT.ToInstant;
  
  CheckEqualsUInt64(3600 * UInt64(1000000000), Inst.AsNsSinceEpoch, '01:00:00 UTC = 3600 seconds = 3600e9 ns');
end;

// ============================================================
// 测试: 往返一致性 (Roundtrip)
// ============================================================

procedure Test_Roundtrip_InstantToZDTToInstant;
var
  Original, Restored: TInstant;
  ZDT: TZonedDateTime;
begin
  WriteLn('Test_Roundtrip_InstantToZDTToInstant:');
  
  // 测试 1: UTC 时区
  Original := TInstant.FromUnixSec(1718451045);
  ZDT := Original.AtUtc;
  Restored := ZDT.ToInstant;
  Check(Original = Restored, 'Roundtrip UTC: Instant -> ZDT -> Instant');
  
  // 测试 2: +08:00 时区
  ZDT := Original.AtOffset(TUtcOffset.FromHours(8));
  Restored := ZDT.ToInstant;
  Check(Original = Restored, 'Roundtrip +08:00: Instant -> ZDT -> Instant');
  
  // 测试 3: -05:00 时区
  ZDT := Original.AtOffset(TUtcOffset.FromHours(-5));
  Restored := ZDT.ToInstant;
  Check(Original = Restored, 'Roundtrip -05:00: Instant -> ZDT -> Instant');
end;

procedure Test_Roundtrip_ZDTToInstantToZDT;
var
  Original, Restored: TZonedDateTime;
  Inst: TInstant;
begin
  WriteLn('Test_Roundtrip_ZDTToInstantToZDT:');
  
  // 创建 2024-06-15 12:30:45 UTC
  Original := TZonedDateTime.Create(2024, 6, 15, 12, 30, 45, TUtcOffset.UTC);
  
  Inst := Original.ToInstant;
  Restored := Inst.AtUtc;
  
  CheckEquals(Original.Year, Restored.Year, 'Year matches');
  CheckEquals(Original.Month, Restored.Month, 'Month matches');
  CheckEquals(Original.Day, Restored.Day, 'Day matches');
  CheckEquals(Original.Hour, Restored.Hour, 'Hour matches');
  CheckEquals(Original.Minute, Restored.Minute, 'Minute matches');
  CheckEquals(Original.Second, Restored.Second, 'Second matches');
end;

procedure Test_DifferentOffsets_SameInstant;
var
  Inst: TInstant;
  ZDT_UTC, ZDT_Beijing, ZDT_NYC: TZonedDateTime;
begin
  WriteLn('Test_DifferentOffsets_SameInstant:');
  
  // 同一个 Instant 在不同时区应该表示同一时刻
  Inst := TInstant.FromUnixSec(1718451045);
  
  ZDT_UTC := Inst.AtUtc;
  ZDT_Beijing := Inst.AtOffset(TUtcOffset.FromHours(8));
  ZDT_NYC := Inst.AtOffset(TUtcOffset.FromHours(-4));
  
  // 转换回 Instant 应该完全相同
  Check(ZDT_UTC.ToInstant = ZDT_Beijing.ToInstant, 'UTC and Beijing same instant');
  Check(ZDT_UTC.ToInstant = ZDT_NYC.ToInstant, 'UTC and NYC same instant');
  Check(ZDT_Beijing.ToInstant = ZDT_NYC.ToInstant, 'Beijing and NYC same instant');
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TInstant <-> TZonedDateTime Tests');
  WriteLn('========================================');
  WriteLn('');
  
  // TInstant.AtOffset 测试
  Test_AtOffset_UTC;
  Test_AtOffset_PositiveOffset;
  Test_AtOffset_NegativeOffset;
  Test_AtOffset_SpecificTimestamp;
  
  // TZonedDateTime.ToInstant 测试
  Test_ToInstant_UTC;
  Test_ToInstant_PositiveOffset;
  Test_ToInstant_NegativeOffset;
  Test_ToInstant_NonZero;
  
  // 往返测试
  Test_Roundtrip_InstantToZDTToInstant;
  Test_Roundtrip_ZDTToInstantToZDT;
  Test_DifferentOffsets_SameInstant;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
