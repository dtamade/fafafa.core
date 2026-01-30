program example_basic_usage;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{
  fafafa.core.time.tick basic usage example

  Demonstrates:
  - Listing available tick types
  - Creating default/high-precision/system ticks
  - Reading current tick and resolution
  - Converting elapsed ticks to duration
}

uses
  SysUtils,
  fafafa.core.time.tick,
  fafafa.core.time.duration,
  fafafa.core.time.stopwatch;

procedure PrintClock(const name: string; const c: ITick);
var
  sw: TStopwatch;
  d: TDuration;
  res, minStepNs: QWord;
begin
  WriteLn('--- ', name, ' ---');
  res := c.GetResolution;
  if res = 0 then res := 1;
  minStepNs := (NANOSECONDS_PER_SECOND + res - 1) div res;
  WriteLn('Resolution (ticks/sec): ', res);
  WriteLn('IsMonotonic: ', c.GetIsMonotonic);
  WriteLn('Min step (approx): ', minStepNs, ' ns');

  sw := TStopwatch.StartNewWithClock(c);
  Sleep(50);
  sw.Stop;
  d := sw.ElapsedDuration;
  WriteLn('Slept ~50ms, measured: ', d.AsMs:0:3, ' ms (', d.AsNs, ' ns)');
  WriteLn;
end;

var
  c: ITick;
  tt: TTickType;
  types: TTickTypes;
begin
  WriteLn('fafafa.core.time.tick - Basic Usage');
  WriteLn('===================================');
  WriteLn;

  // List available types
  types := GetAvailableTickTypes;
  WriteLn('Available tick types:');
  for tt := Low(TTickType) to High(TTickType) do
    if tt in types then
      WriteLn('  * ', GetTickTypeName(tt), ' (', Ord(tt), ')');
  WriteLn;

  // Best clock
  c := MakeBestTick;
  PrintClock('BestTick', c);

  // High precision clock
  c := MakeHDTick;
  PrintClock('HighPrecision', c);

  // System clock
  c := MakeStdTick;
  PrintClock('System', c);

  WriteLn('Done.');
end.

