program simple_demo;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.time.tick,
  fafafa.core.time.duration;

procedure DoWorkload;
begin
  // 模拟工作载荷：睡眠 10ms
  Sleep(10);
end;

procedure ShowClockInfo(const name: string; t: TTick);
var
  start, ticks: QWord;
  d: TDuration;
begin
  start := t.Now;
  DoWorkload;
  ticks := t.Elapsed(start);
  d := t.TicksToDuration(ticks);
  WriteLn('[', name, '] 用时: ', FormatFloat('0.000', d.AsMs), ' ms',
          '  频率=', t.FrequencyHz, ' Hz',
          '  最小步长≈', t.MinStep.AsNs, ' ns');
end;

var
  best, high, sys: TTick;
begin
  Writeln('演示：对比 Best / HighPrecision / System 三种计时源');
  best := BestTick;
  high := TTick.From(ttHighPrecision);
  sys  := TTick.From(ttSystem);

  ShowClockInfo('Best', best);
  ShowClockInfo('HighPrecision', high);
  ShowClockInfo('System', sys);
end.

