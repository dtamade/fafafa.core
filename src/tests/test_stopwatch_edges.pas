unit test_stopwatch_edges;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.tick,
  fafafa.core.time.stopwatch;

type
  TStopwatchEdgeCase = class(TTestCase)
  published
    procedure Test_Measure_Basic;
    procedure Test_MeasureWithClock_Basic;
    procedure Test_Restart_MultiCycles;
    procedure Test_ZeroWorkload;
  end;

procedure RegisterStopwatchEdgeTests;

implementation

procedure RegisterStopwatchEdgeTests;
begin
  RegisterTest(TStopwatchEdgeCase);
end;

procedure TStopwatchEdgeCase.Test_Measure_Basic;
var d: TDuration;
begin
  d := TStopwatch.Measure(procedure begin Sleep(1); end);
  AssertTrue('Measure >= 0.5ms', d.AsMs >= 0.5);
end;

procedure TStopwatchEdgeCase.Test_MeasureWithClock_Basic;
var clk: TTick; d: TDuration;
begin
  clk := BestTick;
  d := TStopwatch.MeasureWithClock(procedure begin Sleep(1); end, clk);
  AssertTrue('MeasureWithClock >= 0.5ms', d.AsMs >= 0.5);
end;

procedure TStopwatchEdgeCase.Test_Restart_MultiCycles;
var sw: TStopwatch; d1, d2: TDuration;
begin
  sw := TStopwatch.StartNew;
  Sleep(1); sw.Stop; d1 := sw.ElapsedDuration;
  sw.Restart; Sleep(1); sw.Stop; d2 := sw.ElapsedDuration;
  AssertTrue('restart accumulates', d2.AsNs > d1.AsNs);
end;

procedure TStopwatchEdgeCase.Test_ZeroWorkload;
var sw: TStopwatch; d: TDuration;
begin
  sw := TStopwatch.StartNew; sw.Stop; d := sw.ElapsedDuration;
  AssertTrue('zero workload ok', d.AsNs >= 0);
end;

end.

