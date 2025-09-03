program test_time_duration;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.time.duration;

var
  d1, d2, d3: TDuration;
  i1, i2: TInstant;
  sw: TStopwatch;
begin
  WriteLn('=== Testing Time Duration Module ===');
  
  // Test Duration creation and conversion
  d1 := TDuration.FromSec(5);
  WriteLn('5 seconds = ', d1.AsMs, ' ms');
  WriteLn('5 seconds = ', d1.ToString);
  
  d2 := TDuration.FromMs(2500);
  WriteLn('2500 ms = ', d2.ToString);
  
  // Test Duration arithmetic
  d3 := d1.Add(d2);
  WriteLn('5s + 2.5s = ', d3.ToString);
  
  // Test Instant
  i1 := TInstant.Now;
  Sleep(100);
  i2 := TInstant.Now;
  
  WriteLn('Time elapsed: ', i2.DurationSince(i1).ToString);
  
  // Test Stopwatch
  sw := TStopwatch.StartNew;
  Sleep(50);
  sw.Stop;
  WriteLn('Stopwatch measured: ', sw.Elapsed.ToString);
  
  WriteLn('=== Test Complete ===');
end.
