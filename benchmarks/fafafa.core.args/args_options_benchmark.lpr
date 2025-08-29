program args_options_benchmark;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.args;

const
  ITERATIONS = 5000;

function GenerateTestArgs: TStringArray;
begin
  SetLength(Result, 15);
  Result[0] := '--Verbose';
  Result[1] := '--CONFIG=/path/config.toml';
  Result[2] := '-ABC';
  Result[3] := '--Count=42';
  Result[4] := '/Output:result.txt';
  Result[5] := '--no-Color';
  Result[6] := '-x';
  Result[7] := '--THREADS=8';
  Result[8] := 'input.txt';
  Result[9] := '--Format=JSON';
  Result[10] := '-123.45';
  Result[11] := '--timeout=30s';
  Result[12] := '--';
  Result[13] := '--not-a-flag';
  Result[14] := 'literal-arg';
end;

procedure BenchmarkOption(const Name: string; const Opts: TArgsOptions);
var
  i: Integer;
  args: TStringArray;
  A: TArgs;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  args := GenerateTestArgs;
  
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    A := TArgs.FromArray(args, Opts);
    A.Free;
  end;
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn(Format('%s: %.0f parses/sec (%.2fms total)', 
    [Name, ITERATIONS / elapsed * 1000, elapsed]));
end;

procedure BenchmarkCaseSensitivity;
var
  optsDefault, optsCaseInsensitive: TArgsOptions;
begin
  WriteLn('=== Case Sensitivity Impact ===');
  
  optsDefault := ArgsOptionsDefault;
  optsCaseInsensitive := ArgsOptionsDefault;
  optsCaseInsensitive.CaseInsensitiveKeys := True;
  
  BenchmarkOption('Case Sensitive (default)', optsDefault);
  BenchmarkOption('Case Insensitive', optsCaseInsensitive);
end;

procedure BenchmarkShortFlagsCombo;
var
  optsDefault, optsNoCombo: TArgsOptions;
begin
  WriteLn('=== Short Flags Combo Impact ===');
  
  optsDefault := ArgsOptionsDefault;
  optsNoCombo := ArgsOptionsDefault;
  optsNoCombo.AllowShortFlagsCombo := False;
  
  BenchmarkOption('Short Flags Combo (default)', optsDefault);
  BenchmarkOption('No Short Flags Combo', optsNoCombo);
end;

procedure BenchmarkShortKeyValue;
var
  optsDefault, optsNoShortKV: TArgsOptions;
begin
  WriteLn('=== Short Key-Value Impact ===');
  
  optsDefault := ArgsOptionsDefault;
  optsNoShortKV := ArgsOptionsDefault;
  optsNoShortKV.AllowShortKeyValue := False;
  
  BenchmarkOption('Short Key-Value (default)', optsDefault);
  BenchmarkOption('No Short Key-Value', optsNoShortKV);
end;

procedure BenchmarkDoubleDashStop;
var
  optsDefault, optsNoStop: TArgsOptions;
begin
  WriteLn('=== Double Dash Stop Impact ===');
  
  optsDefault := ArgsOptionsDefault;
  optsNoStop := ArgsOptionsDefault;
  optsNoStop.StopAtDoubleDash := False;
  
  BenchmarkOption('Stop at Double Dash (default)', optsDefault);
  BenchmarkOption('No Stop at Double Dash', optsNoStop);
end;

procedure BenchmarkNegativeNumbers;
var
  optsDefault, optsNegAsPos: TArgsOptions;
begin
  WriteLn('=== Negative Numbers Treatment Impact ===');
  
  optsDefault := ArgsOptionsDefault;
  optsNegAsPos := ArgsOptionsDefault;
  optsNegAsPos.TreatNegativeNumbersAsPositionals := True;
  
  BenchmarkOption('Negative as Flags (default)', optsDefault);
  BenchmarkOption('Negative as Positionals', optsNegAsPos);
end;

procedure BenchmarkNoPrefixNegation;
var
  optsDefault, optsWithNegation: TArgsOptions;
begin
  WriteLn('=== No-Prefix Negation Impact ===');
  
  optsDefault := ArgsOptionsDefault;
  optsWithNegation := ArgsOptionsDefault;
  optsWithNegation.EnableNoPrefixNegation := True;
  
  BenchmarkOption('No Prefix Negation (default)', optsDefault);
  BenchmarkOption('With Prefix Negation', optsWithNegation);
end;

procedure BenchmarkWorstCase;
var
  optsWorst: TArgsOptions;
begin
  WriteLn('=== Worst Case Configuration ===');
  
  // 启用所有可能影响性能的选项
  optsWorst := ArgsOptionsDefault;
  optsWorst.CaseInsensitiveKeys := True;
  optsWorst.AllowShortFlagsCombo := True;
  optsWorst.AllowShortKeyValue := True;
  optsWorst.StopAtDoubleDash := False;
  optsWorst.TreatNegativeNumbersAsPositionals := True;
  optsWorst.EnableNoPrefixNegation := True;
  
  BenchmarkOption('All Options Enabled', optsWorst);
end;

procedure BenchmarkQueryPerformanceWithOptions;
var
  i: Integer;
  args: TStringArray;
  A1, A2: TArgs;
  opts1, opts2: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed1, elapsed2: Double;
  v: string;
  found: Boolean;
begin
  WriteLn('=== Query Performance with Different Options ===');
  
  args := GenerateTestArgs;
  
  opts1 := ArgsOptionsDefault;
  opts2 := ArgsOptionsDefault;
  opts2.CaseInsensitiveKeys := True;
  
  A1 := TArgs.FromArray(args, opts1);
  A2 := TArgs.FromArray(args, opts2);
  
  try
    // Case sensitive queries
    startTime := Now;
    for i := 1 to ITERATIONS * 10 do
      found := A1.TryGetValue('config', v);
    endTime := Now;
    elapsed1 := MilliSecondsBetween(endTime, startTime);
    
    // Case insensitive queries
    startTime := Now;
    for i := 1 to ITERATIONS * 10 do
      found := A2.TryGetValue('CONFIG', v);
    endTime := Now;
    elapsed2 := MilliSecondsBetween(endTime, startTime);
    
    WriteLn(Format('Case sensitive queries: %.0f ops/sec', 
      [ITERATIONS * 10 / elapsed1 * 1000]));
    WriteLn(Format('Case insensitive queries: %.0f ops/sec', 
      [ITERATIONS * 10 / elapsed2 * 1000]));
    WriteLn(Format('Performance ratio: %.2fx', [elapsed2 / elapsed1]));
    
  finally
    A1.Free;
    A2.Free;
  end;
end;

begin
  WriteLn('fafafa.core.args Options Performance Benchmark');
  WriteLn('==============================================');
  WriteLn('Iterations per test: ', ITERATIONS);
  WriteLn;
  
  BenchmarkCaseSensitivity;
  WriteLn;
  
  BenchmarkShortFlagsCombo;
  WriteLn;
  
  BenchmarkShortKeyValue;
  WriteLn;
  
  BenchmarkDoubleDashStop;
  WriteLn;
  
  BenchmarkNegativeNumbers;
  WriteLn;
  
  BenchmarkNoPrefixNegation;
  WriteLn;
  
  BenchmarkWorstCase;
  WriteLn;
  
  BenchmarkQueryPerformanceWithOptions;
  WriteLn;
  
  WriteLn('Options benchmark completed successfully.');
end.
