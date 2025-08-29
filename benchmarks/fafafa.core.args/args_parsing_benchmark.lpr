program args_parsing_benchmark;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.args;

const
  ITERATIONS = 10000;
  LARGE_ARGS_COUNT = 1000;

// 生成测试参数数组
function GenerateSimpleArgs(Count: Integer): TStringArray;
var i: Integer;
begin
  SetLength(Result, Count);
  for i := 0 to Count-1 do
    Result[i] := Format('--arg%d=value%d', [i, i]);
end;

function GenerateMixedArgs(Count: Integer): TStringArray;
var i: Integer;
begin
  SetLength(Result, Count);
  for i := 0 to Count-1 do
  begin
    case i mod 4 of
      0: Result[i] := Format('--long-arg-%d=value%d', [i, i]);
      1: Result[i] := Format('-s%d', [i mod 26 + Ord('a')]);
      2: Result[i] := Format('/win-style%d:value%d', [i, i]);
      3: Result[i] := Format('positional%d', [i]);
    end;
  end;
end;

function GenerateComplexArgs: TStringArray;
begin
  SetLength(Result, 20);
  Result[0] := '--verbose';
  Result[1] := '--config=/path/to/config.toml';
  Result[2] := '-abc';
  Result[3] := '--count=42';
  Result[4] := '/output:result.txt';
  Result[5] := '--no-color';
  Result[6] := '-x';
  Result[7] := '--threads=8';
  Result[8] := 'input.txt';
  Result[9] := '--format=json';
  Result[10] := '-q';
  Result[11] := '--timeout=30s';
  Result[12] := '/debug';
  Result[13] := '--exclude=*.tmp';
  Result[14] := '--include=*.pas';
  Result[15] := 'output.txt';
  Result[16] := '--';
  Result[17] := '--not-a-flag';
  Result[18] := 'literal-arg';
  Result[19] := '-xyz';
end;

procedure BenchmarkBasicParsing;
var
  i: Integer;
  args: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== Basic Parsing Performance ===');
  
  opts := ArgsOptionsDefault;
  args := GenerateSimpleArgs(10);
  
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    A := TArgs.FromArray(args, opts);
    A.Free;
  end;
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Simple args (10 items): ', ITERATIONS, ' iterations in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', (ITERATIONS / elapsed * 1000):0:0, ' parses/sec');
  WriteLn('  Per-arg rate: ', (ITERATIONS * 10 / elapsed * 1000):0:0, ' args/sec');
end;

procedure BenchmarkScalability;
var
  i, argCount: Integer;
  args: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
  iterations: Integer;
begin
  WriteLn('=== Scalability Test ===');
  
  opts := ArgsOptionsDefault;
  
  // 测试不同参数数量的性能
  for argCount in [10, 50, 100, 500, 1000] do
  begin
    args := GenerateSimpleArgs(argCount);
    iterations := Max(100, ITERATIONS div (argCount div 10));
    
    startTime := Now;
    for i := 1 to iterations do
    begin
      A := TArgs.FromArray(args, opts);
      A.Free;
    end;
    endTime := Now;
    
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn(Format('Args count %d: %d iterations in %.2fms', [argCount, iterations, elapsed]));
    WriteLn(Format('  Rate: %.0f parses/sec, %.0f args/sec', 
      [iterations / elapsed * 1000, iterations * argCount / elapsed * 1000]));
  end;
end;

procedure BenchmarkArgumentTypes;
var
  i: Integer;
  simpleArgs, mixedArgs, complexArgs: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== Argument Types Performance ===');
  
  opts := ArgsOptionsDefault;
  simpleArgs := GenerateSimpleArgs(20);
  mixedArgs := GenerateMixedArgs(20);
  complexArgs := GenerateComplexArgs;
  
  // 简单参数
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    A := TArgs.FromArray(simpleArgs, opts);
    A.Free;
  end;
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Simple args: ', (ITERATIONS / elapsed * 1000):0:0, ' parses/sec');
  
  // 混合参数
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    A := TArgs.FromArray(mixedArgs, opts);
    A.Free;
  end;
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Mixed args: ', (ITERATIONS / elapsed * 1000):0:0, ' parses/sec');
  
  // 复杂参数
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    A := TArgs.FromArray(complexArgs, opts);
    A.Free;
  end;
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Complex args: ', (ITERATIONS / elapsed * 1000):0:0, ' parses/sec');
end;

procedure BenchmarkQueryOperations;
var
  i: Integer;
  args: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
  v: string;
  n: Int64;
  found: Boolean;
begin
  WriteLn('=== Query Operations Performance ===');
  
  opts := ArgsOptionsDefault;
  args := GenerateComplexArgs;
  A := TArgs.FromArray(args, opts);
  
  try
    // HasFlag 查询
    startTime := Now;
    for i := 1 to ITERATIONS * 10 do
      found := A.HasFlag('verbose');
    endTime := Now;
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn('HasFlag: ', (ITERATIONS * 10 / elapsed * 1000):0:0, ' ops/sec');
    
    // TryGetValue 查询
    startTime := Now;
    for i := 1 to ITERATIONS * 10 do
      found := A.TryGetValue('config', v);
    endTime := Now;
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn('TryGetValue: ', (ITERATIONS * 10 / elapsed * 1000):0:0, ' ops/sec');
    
    // TryGetInt64 查询
    startTime := Now;
    for i := 1 to ITERATIONS * 10 do
      found := A.TryGetInt64('count', n);
    endTime := Now;
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn('TryGetInt64: ', (ITERATIONS * 10 / elapsed * 1000):0:0, ' ops/sec');
    
  finally
    A.Free;
  end;
end;

begin
  WriteLn('fafafa.core.args Parsing Performance Benchmark');
  WriteLn('==============================================');
  WriteLn('Iterations per test: ', ITERATIONS);
  WriteLn;
  
  BenchmarkBasicParsing;
  WriteLn;
  
  BenchmarkScalability;
  WriteLn;
  
  BenchmarkArgumentTypes;
  WriteLn;
  
  BenchmarkQueryOperations;
  WriteLn;
  
  WriteLn('Benchmark completed successfully.');
end.
