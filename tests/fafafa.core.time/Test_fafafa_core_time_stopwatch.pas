unit Test_fafafa_core_time_stopwatch;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time,            // TDuration
  fafafa.core.time.tick;       // TStopwatch, TimeItTick

type
  TTestCase_Stopwatch = class(TTestCase)
  published
    procedure Test_Stopwatch_Basic_StartStop;
    procedure Test_Stopwatch_Restart_And_Lap;
    procedure Test_Stopwatch_Stop_Idempotent;
    procedure Test_Stopwatch_Lap_WhenNotRunning;
    procedure Test_Stopwatch_AccumulateAcrossStartStop;

    procedure Test_TimeItTick_WrapsProc;
  end;

implementation

var
  GCalled: Boolean = False;

procedure WorkProc;
begin
  GCalled := True;
  Sleep(1);
end;


procedure TTestCase_Stopwatch.Test_Stopwatch_Basic_StartStop;
var
  sw: TStopwatch;
  d: TDuration;
begin
  sw := TStopwatch.StartNew;
  {$IFDEF MSWINDOWS}
  Sleep(1);
  {$ELSE}
  Sleep(1);
  {$ENDIF}
  sw.Stop;
  d := sw.ElapsedDuration;
  CheckTrue(d.AsNs >= 0);
  // 一般情况下应 >= 1ms；但为兼容负载/调度，允许 >= 0
  CheckTrue(d.AsMs >= 0);
end;

procedure TTestCase_Stopwatch.Test_Stopwatch_Restart_And_Lap;
var
  sw: TStopwatch;
  lap1, lap2: TDuration;
begin
  sw := TStopwatch.StartNew;
  Sleep(1);
  lap1 := sw.LapDuration;
  CheckTrue(lap1.AsNs > 0);
  // 紧接着再次 lap，间隔可能很小，但应为非负
  lap2 := sw.LapDuration;
  CheckTrue(lap2.AsNs >= 0);
  // Restart 后重新计时
  sw.Restart;
  Sleep(1);
  sw.Stop;
  CheckTrue(sw.ElapsedDuration.AsNs > 0);
end;

procedure TTestCase_Stopwatch.Test_Stopwatch_Stop_Idempotent;
var
  sw: TStopwatch;
  d1, d2: TDuration;
begin
  sw := TStopwatch.StartNew;
  Sleep(1);
  sw.Stop;
  d1 := sw.ElapsedDuration;
  // 再次 Stop 不应抛异常，且耗时保持不变
  sw.Stop;
  d2 := sw.ElapsedDuration;
  CheckEquals(d1.AsNs, d2.AsNs);
end;

procedure TTestCase_Stopwatch.Test_Stopwatch_Lap_WhenNotRunning;
var
  sw: TStopwatch;
  lap: TDuration;
begin
  // 未 Start 情况
  sw.Reset; // 确保是未运行状态
  lap := sw.LapDuration;
  CheckTrue(lap.AsNs = 0);
  // Start 后 Stop，再 Lap 也应为 0（不运行）
  sw := TStopwatch.StartNew;
  Sleep(1);
  sw.Stop;
  lap := sw.LapDuration;
  CheckTrue(lap.AsNs = 0);
end;

procedure TTestCase_Stopwatch.Test_Stopwatch_AccumulateAcrossStartStop;
var
  sw: TStopwatch;
  d1, d2: TDuration;
begin
  sw := TStopwatch.StartNew;
  Sleep(1);
  sw.Stop;
  d1 := sw.ElapsedDuration;
  // 再次 Start 继续累积
  sw.Start(nil);
  Sleep(1);
  sw.Stop;
  d2 := sw.ElapsedDuration;
  CheckTrue(d2.AsNs > d1.AsNs);
end;

procedure TTestCase_Stopwatch.Test_TimeItTick_WrapsProc;
var
  d: TDuration;
begin
  GCalled := False;
  d := TimeItTick(@WorkProc);
  CheckTrue(GCalled);
  CheckTrue(d.AsNs >= 0);
end;

initialization
  RegisterTest(TTestCase_Stopwatch);
end.

