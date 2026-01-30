{
  Test_TimeJson.pas - 时间类型 JSON 序列化测试
  
  TDD: 先写测试，后写实现
  
  测试覆盖:
  1. TDate JSON 序列化/反序列化
  2. TTimeOfDay JSON 序列化/反序列化
  3. TZonedDateTime JSON 序列化/反序列化
  4. 往返一致性
}
program Test_TimeJson;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fpjson,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset,
  fafafa.core.time.json;

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

procedure CheckEqualsStr(const Expected, Actual: string; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected="%s", actual="%s")', [TestName, Expected, Actual]));
end;

// ============================================================
// 测试: TDate JSON 序列化
// ============================================================

procedure Test_Date_ToJSON;
var
  D: TDate;
  Json: string;
begin
  WriteLn('Test_Date_ToJSON:');
  
  D := TDate.Create(2024, 6, 15);
  Json := DateToJSON(D);
  CheckEqualsStr('"2024-06-15"', Json, 'Date to JSON');
  
  D := TDate.Create(2000, 1, 1);
  Json := DateToJSON(D);
  CheckEqualsStr('"2000-01-01"', Json, 'Date 2000-01-01 to JSON');
end;

procedure Test_Date_FromJSON;
var
  D: TDate;
  Ok: Boolean;
begin
  WriteLn('Test_Date_FromJSON:');
  
  Ok := JSONToDate('"2024-06-15"', D);
  Check(Ok, 'Parse success');
  Check((D.GetYear = 2024) and (D.GetMonth = 6) and (D.GetDay = 15), 'Date parsed correctly');
  
  Ok := JSONToDate('"2000-01-01"', D);
  Check(Ok, 'Parse 2000-01-01 success');
  Check((D.GetYear = 2000) and (D.GetMonth = 1) and (D.GetDay = 1), 'Date 2000-01-01 parsed correctly');
end;

procedure Test_Date_Roundtrip;
var
  Original, Restored: TDate;
  Json: string;
  Ok: Boolean;
begin
  WriteLn('Test_Date_Roundtrip:');
  
  Original := TDate.Create(2024, 12, 31);
  Json := DateToJSON(Original);
  Ok := JSONToDate(Json, Restored);
  
  Check(Ok, 'Roundtrip parse success');
  Check(Original = Restored, 'Roundtrip equality');
end;

// ============================================================
// 测试: TTimeOfDay JSON 序列化
// ============================================================

procedure Test_TimeOfDay_ToJSON;
var
  T: TTimeOfDay;
  Json: string;
begin
  WriteLn('Test_TimeOfDay_ToJSON:');
  
  T := TTimeOfDay.Create(12, 30, 45);
  Json := TimeOfDayToJSON(T);
  CheckEqualsStr('"12:30:45"', Json, 'TimeOfDay to JSON');
  
  T := TTimeOfDay.Create(0, 0, 0);
  Json := TimeOfDayToJSON(T);
  CheckEqualsStr('"00:00:00"', Json, 'Midnight to JSON');
  
  T := TTimeOfDay.Create(23, 59, 59);
  Json := TimeOfDayToJSON(T);
  CheckEqualsStr('"23:59:59"', Json, 'End of day to JSON');
end;

procedure Test_TimeOfDay_FromJSON;
var
  T: TTimeOfDay;
  Ok: Boolean;
begin
  WriteLn('Test_TimeOfDay_FromJSON:');
  
  Ok := JSONToTimeOfDay('"12:30:45"', T);
  Check(Ok, 'Parse success');
  Check((T.GetHour = 12) and (T.GetMinute = 30) and (T.GetSecond = 45), 'Time parsed correctly');
  
  Ok := JSONToTimeOfDay('"00:00:00"', T);
  Check(Ok, 'Parse midnight success');
  Check((T.GetHour = 0) and (T.GetMinute = 0) and (T.GetSecond = 0), 'Midnight parsed correctly');
end;

procedure Test_TimeOfDay_Roundtrip;
var
  Original, Restored: TTimeOfDay;
  Json: string;
  Ok: Boolean;
begin
  WriteLn('Test_TimeOfDay_Roundtrip:');
  
  Original := TTimeOfDay.Create(15, 45, 30);
  Json := TimeOfDayToJSON(Original);
  Ok := JSONToTimeOfDay(Json, Restored);
  
  Check(Ok, 'Roundtrip parse success');
  Check((Original.GetHour = Restored.GetHour) and 
        (Original.GetMinute = Restored.GetMinute) and
        (Original.GetSecond = Restored.GetSecond), 'Roundtrip equality');
end;

// ============================================================
// 测试: TZonedDateTime JSON 序列化
// ============================================================

procedure Test_ZonedDateTime_ToJSON;
var
  ZDT: TZonedDateTime;
  Json: string;
begin
  WriteLn('Test_ZonedDateTime_ToJSON:');
  
  ZDT := TZonedDateTime.Create(2024, 6, 15, 12, 30, 45, TUtcOffset.UTC);
  Json := ZonedDateTimeToJSON(ZDT);
  CheckEqualsStr('"2024-06-15T12:30:45Z"', Json, 'ZDT UTC to JSON');
  
  ZDT := TZonedDateTime.Create(2024, 6, 15, 20, 30, 45, TUtcOffset.FromHours(8));
  Json := ZonedDateTimeToJSON(ZDT);
  CheckEqualsStr('"2024-06-15T20:30:45+08:00"', Json, 'ZDT +08:00 to JSON');
end;

procedure Test_ZonedDateTime_FromJSON;
var
  ZDT: TZonedDateTime;
  Ok: Boolean;
begin
  WriteLn('Test_ZonedDateTime_FromJSON:');
  
  Ok := JSONToZonedDateTime('"2024-06-15T12:30:45Z"', ZDT);
  Check(Ok, 'Parse UTC success');
  Check((ZDT.Year = 2024) and (ZDT.Month = 6) and (ZDT.Day = 15), 'Date part correct');
  Check((ZDT.Hour = 12) and (ZDT.Minute = 30) and (ZDT.Second = 45), 'Time part correct');
  Check(ZDT.Offset.IsUTC, 'Offset is UTC');
  
  Ok := JSONToZonedDateTime('"2024-06-15T20:30:45+08:00"', ZDT);
  Check(Ok, 'Parse +08:00 success');
  Check(ZDT.Offset.TotalSeconds = 8 * 3600, 'Offset is +08:00');
end;

procedure Test_ZonedDateTime_Roundtrip;
var
  Original, Restored: TZonedDateTime;
  Json: string;
  Ok: Boolean;
begin
  WriteLn('Test_ZonedDateTime_Roundtrip:');
  
  Original := TZonedDateTime.Create(2024, 12, 31, 23, 59, 59, TUtcOffset.FromHours(-5));
  Json := ZonedDateTimeToJSON(Original);
  Ok := JSONToZonedDateTime(Json, Restored);
  
  Check(Ok, 'Roundtrip parse success');
  Check(Original = Restored, 'Roundtrip equality');
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Time Types JSON Serialization Tests');
  WriteLn('========================================');
  WriteLn('');
  
  Test_Date_ToJSON;
  Test_Date_FromJSON;
  Test_Date_Roundtrip;
  
  Test_TimeOfDay_ToJSON;
  Test_TimeOfDay_FromJSON;
  Test_TimeOfDay_Roundtrip;
  
  Test_ZonedDateTime_ToJSON;
  Test_ZonedDateTime_FromJSON;
  Test_ZonedDateTime_Roundtrip;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
