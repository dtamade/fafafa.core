{
  Test_TimeZone.pas - ITimeZone 和 TTimeZoneDatabase 单元测试
  
  TDD: 先写测试，后写实现
  
  测试覆盖:
  1. ITimeZone 接口基本功能
  2. TFixedTimeZone - 固定偏移时区
  3. TSystemTimeZone - 系统本地时区
  4. TTimeZoneDatabase - 时区注册表
}
program Test_TimeZone;

{$mode objfpc}{$H+}

uses
  SysUtils,
  DateUtils,
  fafafa.core.time.instant,
  fafafa.core.time.offset,
  fafafa.core.time.timezone;

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

procedure CheckEquals(Expected, Actual: Integer; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected=%d, actual=%d)', [TestName, Expected, Actual]));
end;

procedure CheckEqualsStr(const Expected, Actual: string; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected="%s", actual="%s")', [TestName, Expected, Actual]));
end;

// ============================================================
// 测试: TFixedTimeZone
// ============================================================

procedure Test_FixedTimeZone_UTC;
var
  TZ: ITimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  WriteLn('Test_FixedTimeZone_UTC:');
  
  TZ := TFixedTimeZone.Create(TUtcOffset.UTC);
  
  CheckEqualsStr('UTC', TZ.GetId, 'Id = UTC');
  
  Inst := TInstant.FromUnixSec(0);
  Offset := TZ.GetOffsetAt(Inst);
  CheckEquals(0, Offset.TotalSeconds, 'Offset at epoch = 0');
  
  Check(not TZ.IsDST(Inst), 'UTC has no DST');
end;

procedure Test_FixedTimeZone_Positive;
var
  TZ: ITimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  WriteLn('Test_FixedTimeZone_Positive:');
  
  // UTC+8 (北京时间)
  TZ := TFixedTimeZone.Create(TUtcOffset.FromHours(8));
  
  CheckEqualsStr('+08:00', TZ.GetId, 'Id = +08:00');
  
  Inst := TInstant.FromUnixSec(0);
  Offset := TZ.GetOffsetAt(Inst);
  CheckEquals(8 * 3600, Offset.TotalSeconds, 'Offset = +8h');
  
  // 固定时区无 DST
  Check(not TZ.IsDST(Inst), 'Fixed timezone has no DST');
end;

procedure Test_FixedTimeZone_Negative;
var
  TZ: ITimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  WriteLn('Test_FixedTimeZone_Negative:');
  
  // UTC-5 (纽约标准时间)
  TZ := TFixedTimeZone.Create(TUtcOffset.FromHours(-5));
  
  CheckEqualsStr('-05:00', TZ.GetId, 'Id = -05:00');
  
  Inst := TInstant.FromUnixSec(1718451045);  // 2024-06-15
  Offset := TZ.GetOffsetAt(Inst);
  CheckEquals(-5 * 3600, Offset.TotalSeconds, 'Offset = -5h');
end;

procedure Test_FixedTimeZone_HalfHour;
var
  TZ: ITimeZone;
  Offset: TUtcOffset;
begin
  WriteLn('Test_FixedTimeZone_HalfHour:');
  
  // UTC+5:30 (印度时间)
  TZ := TFixedTimeZone.Create(TUtcOffset.FromHoursMinutes(5, 30));
  
  CheckEqualsStr('+05:30', TZ.GetId, 'Id = +05:30');
  
  Offset := TZ.GetOffsetAt(TInstant.Zero);
  CheckEquals(5 * 3600 + 30 * 60, Offset.TotalSeconds, 'Offset = +5:30');
end;

// ============================================================
// 测试: TSystemTimeZone
// ============================================================

procedure Test_SystemTimeZone_Basic;
var
  TZ: ITimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  WriteLn('Test_SystemTimeZone_Basic:');
  
  TZ := TSystemTimeZone.Create;
  
  // 应该有一个非空的 ID
  Check(Length(TZ.GetId) > 0, 'System timezone has non-empty Id');
  
  // 应该能获取当前时刻的偏移
  Inst := TInstant.FromUnixSec(DateTimeToUnix(Now));
  Offset := TZ.GetOffsetAt(Inst);
  
  // 偏移应该在合理范围内 (-12h to +14h)
  Check((Offset.TotalSeconds >= -12 * 3600) and (Offset.TotalSeconds <= 14 * 3600), 
        'Offset in valid range');
end;

// ============================================================
// 测试: TTimeZoneDatabase
// ============================================================

procedure Test_TimeZoneDatabase_UTC;
var
  TZ: ITimeZone;
begin
  WriteLn('Test_TimeZoneDatabase_UTC:');
  
  TZ := TTimeZoneDatabase.GetZone('UTC');
  Check(TZ <> nil, 'UTC zone exists');
  
  if TZ <> nil then
  begin
    CheckEqualsStr('UTC', TZ.GetId, 'UTC zone Id');
    CheckEquals(0, TZ.GetOffsetAt(TInstant.Zero).TotalSeconds, 'UTC offset = 0');
  end;
end;

procedure Test_TimeZoneDatabase_FixedOffset;
var
  TZ: ITimeZone;
begin
  WriteLn('Test_TimeZoneDatabase_FixedOffset:');
  
  // 应该能解析固定偏移格式
  TZ := TTimeZoneDatabase.GetZone('+08:00');
  Check(TZ <> nil, '+08:00 zone exists');
  
  if TZ <> nil then
  begin
    CheckEquals(8 * 3600, TZ.GetOffsetAt(TInstant.Zero).TotalSeconds, '+08:00 offset');
  end;
  
  TZ := TTimeZoneDatabase.GetZone('-05:00');
  Check(TZ <> nil, '-05:00 zone exists');
  
  if TZ <> nil then
  begin
    CheckEquals(-5 * 3600, TZ.GetOffsetAt(TInstant.Zero).TotalSeconds, '-05:00 offset');
  end;
end;

procedure Test_TimeZoneDatabase_Local;
var
  TZ: ITimeZone;
begin
  WriteLn('Test_TimeZoneDatabase_Local:');
  
  TZ := TTimeZoneDatabase.GetZone('Local');
  Check(TZ <> nil, 'Local zone exists');
  
  if TZ <> nil then
  begin
    Check(Length(TZ.GetId) > 0, 'Local zone has Id');
  end;
end;

procedure Test_TimeZoneDatabase_Unknown;
var
  TZ: ITimeZone;
begin
  WriteLn('Test_TimeZoneDatabase_Unknown:');
  
  TZ := TTimeZoneDatabase.GetZone('Invalid/NonExistent');
  Check(TZ = nil, 'Unknown zone returns nil');
end;

procedure Test_TimeZoneDatabase_GetAvailableIds;
var
  Ids: TStringArray;
begin
  WriteLn('Test_TimeZoneDatabase_GetAvailableIds:');
  
  Ids := TTimeZoneDatabase.GetAvailableIds;
  
  // 至少应该有 UTC 和 Local
  Check(Length(Ids) >= 2, 'At least 2 available ids');
  
  // 检查是否包含 UTC
  Check(Pos('UTC', string.Join(',', Ids)) > 0, 'Available ids contains UTC');
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  ITimeZone / TTimeZoneDatabase Tests');
  WriteLn('========================================');
  WriteLn('');
  
  // TFixedTimeZone 测试
  Test_FixedTimeZone_UTC;
  Test_FixedTimeZone_Positive;
  Test_FixedTimeZone_Negative;
  Test_FixedTimeZone_HalfHour;
  
  // TSystemTimeZone 测试
  Test_SystemTimeZone_Basic;
  
  // TTimeZoneDatabase 测试
  Test_TimeZoneDatabase_UTC;
  Test_TimeZoneDatabase_FixedOffset;
  Test_TimeZoneDatabase_Local;
  Test_TimeZoneDatabase_Unknown;
  Test_TimeZoneDatabase_GetAvailableIds;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
