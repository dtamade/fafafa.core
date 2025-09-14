program simple_demo;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.time.tick,
  fafafa.core.time.duration,
  fafafa.core.time.stopwatch;

procedure DoWorkload;
begin
  // 模拟工作载荷：睡眠 10ms
  Sleep(10);
end;

procedure ShowClockInfo(const name: string; c: ITick);
var
  sw: TStopwatch;
  d: TDuration;
begin
  sw := TStopwatch.StartNewWithClock(c);
  DoWorkload;
  sw.Stop;
  d := sw.ElapsedDuration;
  WriteLn('[', name, '] 用时: ', FormatFloat('0.000', d.AsMs), ' ms',
          '  单调=', c.GetIsMonotonic,
          '  分辨率=', c.GetResolution, ' ticks/sec');
end;

var
  best, high, sys: ITick;
begin
  Writeln('演示：对比 Best / HighPrecision / System 三种计时源');
  best := MakeBestTick;
  high := MakeHDTick;
  sys  := MakeStdTick;

  ShowClockInfo('Best', best);
  ShowClockInfo('HighPrecision', high);
  ShowClockInfo('System', sys);
end.

