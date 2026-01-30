{
  Test_Duration_ISO8601.pas - TDuration ISO 8601 往返测试
  
  TDD: 先写测试，后写实现
  
  ISO 8601 Duration 格式:
  - P[n]Y[n]M[n]DT[n]H[n]M[n]S
  - 例如: PT1H30M (1小时30分钟)
  - 例如: PT2.5S (2.5秒)
  - 例如: P1DT12H (1天12小时)
  
  注意: TDuration 不支持年/月（因为它们是可变长度的）
  只支持: 周(W)、天(D)、小时(H)、分钟(M)、秒(S) 及其小数部分
}
program Test_Duration_ISO8601;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.duration;

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

procedure CheckEquals(const Expected, Actual: string; const TestName: string);
begin
  Check(Expected = Actual, TestName + Format(' (expected="%s", actual="%s")', [Expected, Actual]));
end;

procedure CheckEqualsNs(Expected, Actual: Int64; const TestName: string);
begin
  Check(Expected = Actual, TestName + Format(' (expected=%d ns, actual=%d ns)', [Expected, Actual]));
end;

// ============================================================
// 测试: ToISO8601
// ============================================================

procedure Test_ToISO8601_Zero;
var
  D: TDuration;
  S: string;
begin
  WriteLn('Test_ToISO8601_Zero:');
  
  D := TDuration.Zero;
  S := D.ToISO8601;
  CheckEquals('PT0S', S, 'Zero duration should be PT0S');
end;

procedure Test_ToISO8601_Seconds;
var
  D: TDuration;
  S: string;
begin
  WriteLn('Test_ToISO8601_Seconds:');
  
  // 整数秒
  D := TDuration.FromSec(30);
  S := D.ToISO8601;
  CheckEquals('PT30S', S, '30 seconds');
  
  // 1秒
  D := TDuration.FromSec(1);
  S := D.ToISO8601;
  CheckEquals('PT1S', S, '1 second');
end;

procedure Test_ToISO8601_Minutes;
var
  D: TDuration;
  S: string;
begin
  WriteLn('Test_ToISO8601_Minutes:');
  
  D := TDuration.FromMinutes(45);
  S := D.ToISO8601;
  CheckEquals('PT45M', S, '45 minutes');
  
  // 分钟 + 秒
  D := TDuration.FromMinutes(5) + TDuration.FromSec(30);
  S := D.ToISO8601;
  CheckEquals('PT5M30S', S, '5 minutes 30 seconds');
end;

procedure Test_ToISO8601_Hours;
var
  D: TDuration;
  S: string;
begin
  WriteLn('Test_ToISO8601_Hours:');
  
  D := TDuration.FromHours(2);
  S := D.ToISO8601;
  CheckEquals('PT2H', S, '2 hours');
  
  // 小时 + 分钟
  D := TDuration.FromHours(1) + TDuration.FromMinutes(30);
  S := D.ToISO8601;
  CheckEquals('PT1H30M', S, '1 hour 30 minutes');
  
  // 小时 + 分钟 + 秒
  D := TDuration.FromHours(1) + TDuration.FromMinutes(30) + TDuration.FromSec(45);
  S := D.ToISO8601;
  CheckEquals('PT1H30M45S', S, '1 hour 30 minutes 45 seconds');
end;

procedure Test_ToISO8601_Days;
var
  D: TDuration;
  S: string;
begin
  WriteLn('Test_ToISO8601_Days:');
  
  D := TDuration.FromDays(3);
  S := D.ToISO8601;
  CheckEquals('P3D', S, '3 days');
  
  // 天 + 时间部分
  D := TDuration.FromDays(1) + TDuration.FromHours(12);
  S := D.ToISO8601;
  CheckEquals('P1DT12H', S, '1 day 12 hours');
end;

procedure Test_ToISO8601_Weeks;
var
  D: TDuration;
  S: string;
begin
  WriteLn('Test_ToISO8601_Weeks:');
  
  // 整周（ISO 8601 允许 PnW 格式）
  D := TDuration.FromWeeks(2);
  S := D.ToISO8601;
  // 可能输出 P2W 或 P14D，两者都是有效的
  Check((S = 'P2W') or (S = 'P14D'), '2 weeks: ' + S);
end;

procedure Test_ToISO8601_FractionalSeconds;
var
  D: TDuration;
  S: string;
begin
  WriteLn('Test_ToISO8601_FractionalSeconds:');
  
  // 带毫秒
  D := TDuration.FromMs(1500);  // 1.5 秒
  S := D.ToISO8601;
  Check(Pos('1.5', S) > 0, '1.5 seconds should contain "1.5": ' + S);
  
  // 带微秒
  D := TDuration.FromUs(2500000);  // 2.5 秒
  S := D.ToISO8601;
  Check(Pos('2.5', S) > 0, '2.5 seconds should contain "2.5": ' + S);
end;

procedure Test_ToISO8601_Negative;
var
  D: TDuration;
  S: string;
begin
  WriteLn('Test_ToISO8601_Negative:');
  
  D := -TDuration.FromSec(30);
  S := D.ToISO8601;
  // ISO 8601 负时长用 - 前缀
  Check(S[1] = '-', 'Negative duration should start with "-": ' + S);
end;

// ============================================================
// 测试: TryParseISO8601
// ============================================================

procedure Test_ParseISO8601_Seconds;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_Seconds:');
  
  Check(TDuration.TryParseISO8601('PT30S', D), 'Parse PT30S');
  CheckEqualsNs(30 * 1000000000, D.AsNs, 'PT30S = 30 seconds');
  
  Check(TDuration.TryParseISO8601('PT1S', D), 'Parse PT1S');
  CheckEqualsNs(1000000000, D.AsNs, 'PT1S = 1 second');
end;

procedure Test_ParseISO8601_Minutes;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_Minutes:');
  
  Check(TDuration.TryParseISO8601('PT45M', D), 'Parse PT45M');
  CheckEqualsNs(45 * 60 * 1000000000, D.AsNs, 'PT45M = 45 minutes');
  
  Check(TDuration.TryParseISO8601('PT5M30S', D), 'Parse PT5M30S');
  CheckEqualsNs((5*60 + 30) * 1000000000, D.AsNs, 'PT5M30S = 5m30s');
end;

procedure Test_ParseISO8601_Hours;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_Hours:');
  
  Check(TDuration.TryParseISO8601('PT2H', D), 'Parse PT2H');
  CheckEqualsNs(2 * 3600 * 1000000000, D.AsNs, 'PT2H = 2 hours');
  
  Check(TDuration.TryParseISO8601('PT1H30M', D), 'Parse PT1H30M');
  CheckEqualsNs((1*3600 + 30*60) * 1000000000, D.AsNs, 'PT1H30M = 1h30m');
  
  Check(TDuration.TryParseISO8601('PT1H30M45S', D), 'Parse PT1H30M45S');
  CheckEqualsNs((1*3600 + 30*60 + 45) * 1000000000, D.AsNs, 'PT1H30M45S');
end;

procedure Test_ParseISO8601_Days;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_Days:');
  
  Check(TDuration.TryParseISO8601('P3D', D), 'Parse P3D');
  CheckEqualsNs(3 * 86400 * 1000000000, D.AsNs, 'P3D = 3 days');
  
  Check(TDuration.TryParseISO8601('P1DT12H', D), 'Parse P1DT12H');
  CheckEqualsNs((86400 + 12*3600) * 1000000000, D.AsNs, 'P1DT12H = 1d12h');
end;

procedure Test_ParseISO8601_Weeks;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_Weeks:');
  
  Check(TDuration.TryParseISO8601('P2W', D), 'Parse P2W');
  CheckEqualsNs(2 * 7 * 86400 * 1000000000, D.AsNs, 'P2W = 2 weeks');
end;

procedure Test_ParseISO8601_FractionalSeconds;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_FractionalSeconds:');
  
  Check(TDuration.TryParseISO8601('PT1.5S', D), 'Parse PT1.5S');
  CheckEqualsNs(1500000000, D.AsNs, 'PT1.5S = 1.5 seconds');
  
  Check(TDuration.TryParseISO8601('PT2.5S', D), 'Parse PT2.5S');
  CheckEqualsNs(2500000000, D.AsNs, 'PT2.5S = 2.5 seconds');
  
  // 高精度
  Check(TDuration.TryParseISO8601('PT0.001S', D), 'Parse PT0.001S');
  CheckEqualsNs(1000000, D.AsNs, 'PT0.001S = 1 millisecond');
end;

procedure Test_ParseISO8601_Negative;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_Negative:');
  
  Check(TDuration.TryParseISO8601('-PT30S', D), 'Parse -PT30S');
  CheckEqualsNs(-30 * 1000000000, D.AsNs, '-PT30S = -30 seconds');
  
  Check(TDuration.TryParseISO8601('-P1D', D), 'Parse -P1D');
  CheckEqualsNs(-86400 * 1000000000, D.AsNs, '-P1D = -1 day');
end;

procedure Test_ParseISO8601_Zero;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_Zero:');
  
  Check(TDuration.TryParseISO8601('PT0S', D), 'Parse PT0S');
  Check(D.IsZero, 'PT0S should be zero');
  
  Check(TDuration.TryParseISO8601('P0D', D), 'Parse P0D');
  Check(D.IsZero, 'P0D should be zero');
end;

procedure Test_ParseISO8601_Invalid;
var
  D: TDuration;
begin
  WriteLn('Test_ParseISO8601_Invalid:');
  
  Check(not TDuration.TryParseISO8601('', D), 'Empty string should fail');
  Check(not TDuration.TryParseISO8601('T30S', D), 'Missing P should fail');
  Check(not TDuration.TryParseISO8601('P', D), 'P alone should fail');
  Check(not TDuration.TryParseISO8601('PT', D), 'PT alone should fail');
  Check(not TDuration.TryParseISO8601('P1Y', D), 'Years not supported');
  Check(not TDuration.TryParseISO8601('P1M', D), 'Months not supported');
  Check(not TDuration.TryParseISO8601('garbage', D), 'Garbage should fail');
end;

// ============================================================
// 测试: 往返一致性 (Roundtrip)
// ============================================================

procedure Test_Roundtrip_Consistency;
var
  Original, Parsed: TDuration;
  S: string;
begin
  WriteLn('Test_Roundtrip_Consistency:');
  
  // 秒
  Original := TDuration.FromSec(45);
  S := Original.ToISO8601;
  Check(TDuration.TryParseISO8601(S, Parsed), 'Roundtrip parse 45s');
  Check(Original = Parsed, 'Roundtrip 45 seconds: ' + S);
  
  // 分钟+秒
  Original := TDuration.FromMinutes(5) + TDuration.FromSec(30);
  S := Original.ToISO8601;
  Check(TDuration.TryParseISO8601(S, Parsed), 'Roundtrip parse 5m30s');
  Check(Original = Parsed, 'Roundtrip 5m30s: ' + S);
  
  // 小时+分钟+秒
  Original := TDuration.FromHours(2) + TDuration.FromMinutes(15) + TDuration.FromSec(30);
  S := Original.ToISO8601;
  Check(TDuration.TryParseISO8601(S, Parsed), 'Roundtrip parse 2h15m30s');
  Check(Original = Parsed, 'Roundtrip 2h15m30s: ' + S);
  
  // 天+小时
  Original := TDuration.FromDays(1) + TDuration.FromHours(12);
  S := Original.ToISO8601;
  Check(TDuration.TryParseISO8601(S, Parsed), 'Roundtrip parse 1d12h');
  Check(Original = Parsed, 'Roundtrip 1d12h: ' + S);
  
  // 毫秒精度
  Original := TDuration.FromMs(1234);
  S := Original.ToISO8601;
  Check(TDuration.TryParseISO8601(S, Parsed), 'Roundtrip parse 1234ms');
  Check(Original = Parsed, 'Roundtrip 1234ms: ' + S);
  
  // 负值
  Original := -TDuration.FromMinutes(30);
  S := Original.ToISO8601;
  Check(TDuration.TryParseISO8601(S, Parsed), 'Roundtrip parse -30m');
  Check(Original = Parsed, 'Roundtrip -30m: ' + S);
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TDuration ISO 8601 Unit Tests');
  WriteLn('========================================');
  WriteLn('');
  
  // ToISO8601 测试
  Test_ToISO8601_Zero;
  Test_ToISO8601_Seconds;
  Test_ToISO8601_Minutes;
  Test_ToISO8601_Hours;
  Test_ToISO8601_Days;
  Test_ToISO8601_Weeks;
  Test_ToISO8601_FractionalSeconds;
  Test_ToISO8601_Negative;
  
  // TryParseISO8601 测试
  Test_ParseISO8601_Seconds;
  Test_ParseISO8601_Minutes;
  Test_ParseISO8601_Hours;
  Test_ParseISO8601_Days;
  Test_ParseISO8601_Weeks;
  Test_ParseISO8601_FractionalSeconds;
  Test_ParseISO8601_Negative;
  Test_ParseISO8601_Zero;
  Test_ParseISO8601_Invalid;
  
  // 往返测试
  Test_Roundtrip_Consistency;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
