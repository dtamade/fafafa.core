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

type
  TClockPrinter = record
    class procedure Print(const name: string; const c: TTick); static;
  end;

class procedure TClockPrinter.Print(const name: string; const c: TTick);
var
  start, elapsed: QWord;
  d: TDuration;
begin
  WriteLn('--- ', name, ' ---');
  WriteLn('Frequency (ticks/sec): ', c.FrequencyHz);
  WriteLn('IsMonotonic: ', c.IsMonotonic);
  WriteLn('Min step: ', c.MinStep.AsNs, ' ns');

  start := c.Now;
  Sleep(50);
  elapsed := c.Elapsed(start);
  d := c.TicksToDuration(elapsed);
  WriteLn('Slept ~50ms, measured: ', d.AsMs:0:3, ' ms (', d.AsNs, ' ns)');
  WriteLn;
end;

var
  c: TTick;
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

  // Best clock
  c := BestTick;
  TClockPrinter.Print('BestTick', c);

  // High precision clock
  c := TTick.From(ttHighPrecision);
  TClockPrinter.Print('HighPrecision', c);

  // System clock
  c := TTick.From(ttSystem);
  TClockPrinter.Print('System', c);

  WriteLn('Done.');
end.

