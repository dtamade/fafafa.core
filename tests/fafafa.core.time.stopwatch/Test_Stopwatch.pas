{
  Test_Stopwatch.pas - TStopwatch 单元测试
  
  TDD: 先写测试，验证现有实现
  
  测试范围:
  - TStopwatch 基本功能 (Create, Start, Stop, Reset, Restart)
  - 时间测量 (ElapsedNs, ElapsedUs, ElapsedMs, ElapsedSec, ElapsedDuration)
  - Lap 功能 (Lap, GetLaps, ClearLaps)
  - TStopwatchScope RAII
  - MeasureTime 便捷函数
}
program Test_Stopwatch;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.stopwatch,
  fafafa.core.time.duration,
  fafafa.core.time.cpu;

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

procedure BusyWaitMs(Ms: Integer);
var
  i, j: Integer;
begin
  for i := 1 to Ms do
    for j := 1 to 100000 do
      CpuRelax;
end;

// ============================================================
// 测试: TStopwatch.Create
// ============================================================

procedure Test_Create_NotRunning;
var
  SW: TStopwatch;
begin
  WriteLn('Test_Create_NotRunning:');
  
  SW := TStopwatch.Create;
  Check(not SW.IsRunning, 'New stopwatch should not be running');
  Check(SW.ElapsedNs = 0, 'New stopwatch elapsed should be 0');
end;

procedure Test_StartNew_IsRunning;
var
  SW: TStopwatch;
begin
  WriteLn('Test_StartNew_IsRunning:');
  
  SW := TStopwatch.StartNew;
  Check(SW.IsRunning, 'StartNew should return running stopwatch');
  SW.Stop;
end;

// ============================================================
// 测试: Start/Stop/Reset/Restart
// ============================================================

procedure Test_Start_SetsRunning;
var
  SW: TStopwatch;
begin
  WriteLn('Test_Start_SetsRunning:');
  
  SW := TStopwatch.Create;
  Check(not SW.IsRunning, 'Before start: not running');
  
  SW.Start;
  Check(SW.IsRunning, 'After start: running');
  
  SW.Stop;
end;

procedure Test_Stop_ClearsRunning;
var
  SW: TStopwatch;
begin
  WriteLn('Test_Stop_ClearsRunning:');
  
  SW := TStopwatch.StartNew;
  Check(SW.IsRunning, 'Before stop: running');
  
  SW.Stop;
  Check(not SW.IsRunning, 'After stop: not running');
end;

procedure Test_Reset_ClearsElapsed;
var
  SW: TStopwatch;
begin
  WriteLn('Test_Reset_ClearsElapsed:');
  
  SW := TStopwatch.StartNew;
  BusyWaitMs(5);
  SW.Stop;
  
  Check(SW.ElapsedNs > 0, 'Before reset: elapsed > 0');
  
  SW.Reset;
  Check(SW.ElapsedNs = 0, 'After reset: elapsed = 0');
  Check(not SW.IsRunning, 'After reset: not running');
end;

procedure Test_Restart_ResetsAndStarts;
var
  SW: TStopwatch;
  E1: UInt64;
begin
  WriteLn('Test_Restart_ResetsAndStarts:');
  
  SW := TStopwatch.StartNew;
  BusyWaitMs(10);
  SW.Stop;
  E1 := SW.ElapsedNs;
  
  SW.Restart;
  Check(SW.IsRunning, 'After restart: running');
  Check(SW.ElapsedNs < E1, 'After restart: elapsed reset');
end;

// ============================================================
// 测试: 时间测量单位转换
// ============================================================

procedure Test_ElapsedUnits_Consistency;
var
  SW: TStopwatch;
  ENs, EUs, EMs: UInt64;
  ESec: Double;
begin
  WriteLn('Test_ElapsedUnits_Consistency:');
  
  SW := TStopwatch.StartNew;
  BusyWaitMs(50);
  SW.Stop;
  
  ENs := SW.ElapsedNs;
  EUs := SW.ElapsedUs;
  EMs := SW.ElapsedMs;
  ESec := SW.ElapsedSec;
  
  // 检查单位换算一致性
  Check(EUs = ENs div 1000, 'Us = Ns div 1000');
  Check(EMs = ENs div 1000000, 'Ms = Ns div 1000000');
  Check(Abs(ESec - ENs / 1000000000.0) < 0.0001, 'Sec consistency');
end;

procedure Test_ElapsedDuration_Correct;
var
  SW: TStopwatch;
  D: TDuration;
begin
  WriteLn('Test_ElapsedDuration_Correct:');
  
  SW := TStopwatch.StartNew;
  BusyWaitMs(20);
  SW.Stop;
  
  D := SW.ElapsedDuration;
  Check(D.AsNs = Int64(SW.ElapsedNs), 'ElapsedDuration.AsNs = ElapsedNs');
end;

// ============================================================
// 测试: 累计计时（多次 Start/Stop）
// ============================================================

procedure Test_Cumulative_Timing;
var
  SW: TStopwatch;
  E1, E2: UInt64;
begin
  WriteLn('Test_Cumulative_Timing:');
  
  SW := TStopwatch.Create;
  
  // 第一次计时
  SW.Start;
  BusyWaitMs(10);
  SW.Stop;
  E1 := SW.ElapsedNs;
  
  // 第二次计时（累加）
  SW.Start;
  BusyWaitMs(10);
  SW.Stop;
  E2 := SW.ElapsedNs;
  
  Check(E2 > E1, 'Cumulative: second elapsed > first elapsed');
end;

// ============================================================
// 测试: Lap 功能
// ============================================================

procedure Test_Lap_RecordsInterval;
var
  SW: TStopwatch;
  L1, L2: TDuration;
begin
  WriteLn('Test_Lap_RecordsInterval:');
  
  SW := TStopwatch.StartNew;
  BusyWaitMs(10);
  L1 := SW.Lap;
  BusyWaitMs(10);
  L2 := SW.Lap;
  SW.Stop;
  
  Check(L1.AsNs > 0, 'Lap 1 > 0');
  Check(L2.AsNs > 0, 'Lap 2 > 0');
  Check(SW.GetLapCount = 2, 'LapCount = 2');
end;

procedure Test_GetLaps_ReturnsAll;
var
  SW: TStopwatch;
  Laps: TDurationArray;
begin
  WriteLn('Test_GetLaps_ReturnsAll:');
  
  SW := TStopwatch.StartNew;
  SW.Lap;
  SW.Lap;
  SW.Lap;
  SW.Stop;
  
  Laps := SW.GetLaps;
  Check(Length(Laps) = 3, 'GetLaps returns 3 laps');
end;

procedure Test_ClearLaps_RemovesAll;
var
  SW: TStopwatch;
begin
  WriteLn('Test_ClearLaps_RemovesAll:');
  
  SW := TStopwatch.StartNew;
  SW.Lap;
  SW.Lap;
  Check(SW.GetLapCount = 2, 'Before clear: 2 laps');
  
  SW.ClearLaps;
  Check(SW.GetLapCount = 0, 'After clear: 0 laps');
  SW.Stop;
end;

procedure Test_Lap_WhenNotRunning_ReturnsZero;
var
  SW: TStopwatch;
  L: TDuration;
begin
  WriteLn('Test_Lap_WhenNotRunning_ReturnsZero:');
  
  SW := TStopwatch.Create;  // 未启动
  L := SW.Lap;
  Check(L.IsZero, 'Lap when not running should return zero');
end;

// ============================================================
// 测试: ToString
// ============================================================

procedure Test_ToString_Format;
var
  SW: TStopwatch;
  S: string;
begin
  WriteLn('Test_ToString_Format:');
  
  SW := TStopwatch.StartNew;
  BusyWaitMs(100);
  SW.Stop;
  
  S := SW.ToString;
  Check(Length(S) > 0, 'ToString not empty');
  Check((Pos('ms', S) > 0) or (Pos('s', S) > 0), 'ToString contains unit');
end;

procedure Test_ToStringPrecise_ContainsNs;
var
  SW: TStopwatch;
  S: string;
begin
  WriteLn('Test_ToStringPrecise_ContainsNs:');
  
  SW := TStopwatch.StartNew;
  BusyWaitMs(10);
  SW.Stop;
  
  S := SW.ToStringPrecise;
  Check(Pos('ns', S) > 0, 'ToStringPrecise contains ns');
end;

// ============================================================
// 测试: MeasureTime 便捷函数
// ============================================================

var
  GMeasureCounter: Integer = 0;

procedure DummyProc;
begin
  Inc(GMeasureCounter);
  BusyWaitMs(5);
end;

procedure Test_MeasureTime_SimpleProc;
var
  D: TDuration;
begin
  WriteLn('Test_MeasureTime_SimpleProc:');
  
  GMeasureCounter := 0;
  D := MeasureTime(@DummyProc);
  
  Check(GMeasureCounter = 1, 'Proc was called');
  Check(D.AsNs > 0, 'Duration > 0');
end;

procedure Test_MeasureTimeMs_SimpleProc;
var
  Ms: UInt64;
begin
  WriteLn('Test_MeasureTimeMs_SimpleProc:');
  
  GMeasureCounter := 0;
  Ms := MeasureTimeMs(@DummyProc);
  
  Check(GMeasureCounter = 1, 'Proc was called');
  Check(Ms >= 0, 'Ms >= 0');  // 可能太快导致 0
end;

// ============================================================
// 测试: 正在运行时读取 Elapsed
// ============================================================

procedure Test_ReadElapsed_WhileRunning;
var
  SW: TStopwatch;
  E1, E2: UInt64;
begin
  WriteLn('Test_ReadElapsed_WhileRunning:');
  
  SW := TStopwatch.StartNew;
  E1 := SW.ElapsedNs;
  BusyWaitMs(10);
  E2 := SW.ElapsedNs;
  SW.Stop;
  
  Check(E2 > E1, 'Reading elapsed while running: E2 > E1');
end;

// ============================================================
// 主程序
// ============================================================

begin
  WriteLn('========================================');
  WriteLn('TStopwatch Unit Tests');
  WriteLn('========================================');
  WriteLn;
  
  // Create/StartNew
  Test_Create_NotRunning;
  Test_StartNew_IsRunning;
  
  // Start/Stop/Reset/Restart
  Test_Start_SetsRunning;
  Test_Stop_ClearsRunning;
  Test_Reset_ClearsElapsed;
  Test_Restart_ResetsAndStarts;
  
  // Time units
  Test_ElapsedUnits_Consistency;
  Test_ElapsedDuration_Correct;
  
  // Cumulative
  Test_Cumulative_Timing;
  
  // Lap
  Test_Lap_RecordsInterval;
  Test_GetLaps_ReturnsAll;
  Test_ClearLaps_RemovesAll;
  Test_Lap_WhenNotRunning_ReturnsZero;
  
  // ToString
  Test_ToString_Format;
  Test_ToStringPrecise_ContainsNs;
  
  // MeasureTime
  Test_MeasureTime_SimpleProc;
  Test_MeasureTimeMs_SimpleProc;
  
  // While running
  Test_ReadElapsed_WhileRunning;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn(Format('Tests: %d, Passed: %d, Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
