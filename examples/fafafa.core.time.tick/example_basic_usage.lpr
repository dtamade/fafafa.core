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
  fafafa.core.time.duration;

procedure PrintTickInfo(const name: string; const tick: ITick);
var
  start, elapsed: QWord;
  d: TDuration;
begin
  WriteLn('--- ', name, ' ---');
  WriteLn('Resolution (ticks/sec): ', tick.GetResolution);
  WriteLn('IsMonotonic: ', tick.IsMonotonic);
  WriteLn('IsHighResolution: ', tick.IsHighResolution);
  WriteLn('Min interval: ', tick.GetMinimumInterval.AsNs, ' ns');

  start := tick.GetCurrentTick;
  Sleep(50);
  elapsed := tick.GetElapsedTicks(start);
  d := tick.TicksToDuration(elapsed);
  WriteLn('Slept ~50ms, measured: ', d.AsMs, ' ms (', d.AsNs, ' ns)');
  WriteLn;
end;

var
  t: ITick;
  tt: TTickType;
  types: TTickTypeArray;
  i: Integer;
begin
  WriteLn('fafafa.core.time.tick - Basic Usage');
  WriteLn('===================================');
  WriteLn;

  // List available types
  types := GetAvailableTickTypes;
  WriteLn('Available tick types:');
  for i := 0 to High(types) do
  begin
    tt := types[i];
    WriteLn('  * ', GetTickTypeName(tt), ' (', Ord(tt), ')');
  end;
  WriteLn;

  // Default tick
  t := DefaultTick;
  PrintTickInfo('DefaultTick', t);

  // High precision tick
  t := HighPrecisionTick;
  PrintTickInfo('HighPrecisionTick', t);

  // System tick
  t := SystemTick;
  PrintTickInfo('SystemTick', t);

  WriteLn('Done.');
end.

