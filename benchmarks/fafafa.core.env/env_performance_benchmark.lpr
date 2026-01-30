program env_performance_benchmark;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.env,
  fafafa.core.benchmark;

const
  ITERATIONS = 10000;
  LARGE_STRING_SIZE = 10000;

procedure BenchmarkStringExpansion;
var
  i: Integer;
  testString, result: string;
  startTime, endTime: TDateTime;
  elapsed: Double;
  guard: TEnvOverrideGuard;
begin
  WriteLn('=== String Expansion Benchmark ===');
  
  // Setup test environment
  guard := env_override('BENCH_VAR', 'test_value_123');
  try
    // Test 1: Simple expansion
    testString := 'prefix_$BENCH_VAR_suffix';
    startTime := Now;
    for i := 1 to ITERATIONS do
      result := env_expand(testString);
    endTime := Now;
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn('Simple expansion: ', ITERATIONS, ' iterations in ', elapsed:0:2, 'ms');
    WriteLn('  Rate: ', (ITERATIONS / elapsed * 1000):0:0, ' ops/sec');
    
    // Test 2: Complex expansion with multiple variables
    env_set('BENCH_VAR2', 'another_value');
    env_set('BENCH_VAR3', 'third_value');
    testString := 'start_$BENCH_VAR_middle_${BENCH_VAR2}_end_$BENCH_VAR3_finish';
    startTime := Now;
    for i := 1 to ITERATIONS do
      result := env_expand(testString);
    endTime := Now;
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn('Complex expansion: ', ITERATIONS, ' iterations in ', elapsed:0:2, 'ms');
    WriteLn('  Rate: ', (ITERATIONS / elapsed * 1000):0:0, ' ops/sec');
    
    // Test 3: Large string expansion
    testString := StringOfChar('x', LARGE_STRING_SIZE div 2) + '$BENCH_VAR' + StringOfChar('y', LARGE_STRING_SIZE div 2);
    startTime := Now;
    for i := 1 to ITERATIONS div 10 do  // Fewer iterations for large strings
      result := env_expand(testString);
    endTime := Now;
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn('Large string expansion: ', ITERATIONS div 10, ' iterations in ', elapsed:0:2, 'ms');
    WriteLn('  Rate: ', ((ITERATIONS div 10) / elapsed * 1000):0:0, ' ops/sec');
    
    env_unset('BENCH_VAR2');
    env_unset('BENCH_VAR3');
  finally
    guard.Done;
  end;
end;

procedure BenchmarkPathOperations;
var
  i: Integer;
  pathString: string;
  pathArray: TStringArray;
  joinedPath: string;
  startTime, endTime: TDateTime;
  elapsed: Double;
  sep: Char;
begin
  WriteLn('=== PATH Operations Benchmark ===');
  
  sep := env_path_list_separator;
  
  // Create test path string
  pathString := 'path1' + sep + 'path2' + sep + 'path3' + sep + 'path4' + sep + 'path5';
  
  // Test 1: Path splitting
  startTime := Now;
  for i := 1 to ITERATIONS do
    pathArray := env_split_paths(pathString);
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Path splitting: ', ITERATIONS, ' iterations in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', (ITERATIONS / elapsed * 1000):0:0, ' ops/sec');
  
  // Test 2: Path joining
  SetLength(pathArray, 5);
  pathArray[0] := 'path1';
  pathArray[1] := 'path2';
  pathArray[2] := 'path3';
  pathArray[3] := 'path4';
  pathArray[4] := 'path5';
  
  startTime := Now;
  for i := 1 to ITERATIONS do
    joinedPath := env_join_paths(pathArray);
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Path joining: ', ITERATIONS, ' iterations in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', (ITERATIONS / elapsed * 1000):0:0, ' ops/sec');
  
  // Test 3: Large path operations
  SetLength(pathArray, 100);
  for i := 0 to 99 do
    pathArray[i] := 'very_long_path_segment_' + IntToStr(i) + '_with_more_text';
  
  startTime := Now;
  for i := 1 to ITERATIONS div 10 do
    joinedPath := env_join_paths(pathArray);
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Large path joining: ', ITERATIONS div 10, ' iterations in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', ((ITERATIONS div 10) / elapsed * 1000):0:0, ' ops/sec');
end;

procedure BenchmarkBasicOperations;
var
  i: Integer;
  value: string;
  result: Boolean;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== Basic Operations Benchmark ===');
  
  // Test 1: Environment variable get/set
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    env_set('BENCH_BASIC', 'test_value');
    value := env_get('BENCH_BASIC');
    env_unset('BENCH_BASIC');
  end;
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Get/Set/Unset cycle: ', ITERATIONS, ' iterations in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', (ITERATIONS / elapsed * 1000):0:0, ' ops/sec');
  
  // Test 2: Environment variable lookup
  env_set('BENCH_LOOKUP', 'lookup_value');
  startTime := Now;
  for i := 1 to ITERATIONS do
    result := env_lookup('BENCH_LOOKUP', value);
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Lookup operations: ', ITERATIONS, ' iterations in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', (ITERATIONS / elapsed * 1000):0:0, ' ops/sec');
  env_unset('BENCH_LOOKUP');
end;

procedure BenchmarkSecurityFunctions;
var
  i: Integer;
  result: Boolean;
  masked: string;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== Security Functions Benchmark ===');
  
  // Test 1: Sensitive name detection
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    result := env_is_sensitive_name('API_KEY');
    result := env_is_sensitive_name('PASSWORD');
    result := env_is_sensitive_name('PATH');
  end;
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Sensitive name detection: ', ITERATIONS * 3, ' checks in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', (ITERATIONS * 3 / elapsed * 1000):0:0, ' ops/sec');
  
  // Test 2: Value masking
  startTime := Now;
  for i := 1 to ITERATIONS do
    masked := env_mask_value('secret_key_12345678');
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Value masking: ', ITERATIONS, ' operations in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', (ITERATIONS / elapsed * 1000):0:0, ' ops/sec');
  
  // Test 3: Name validation
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    result := env_validate_name('VALID_NAME');
    result := env_validate_name('123INVALID');
    result := env_validate_name('ALSO_VALID_123');
  end;
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn('Name validation: ', ITERATIONS * 3, ' validations in ', elapsed:0:2, 'ms');
  WriteLn('  Rate: ', (ITERATIONS * 3 / elapsed * 1000):0:0, ' ops/sec');
end;

begin
  WriteLn('fafafa.core.env Performance Benchmark');
  WriteLn('=====================================');
  WriteLn('Iterations per test: ', ITERATIONS);
  WriteLn('Large string size: ', LARGE_STRING_SIZE);
  WriteLn;
  
  BenchmarkBasicOperations;
  WriteLn;
  
  BenchmarkStringExpansion;
  WriteLn;
  
  BenchmarkPathOperations;
  WriteLn;
  
  BenchmarkSecurityFunctions;
  WriteLn;
  
  WriteLn('Benchmark completed successfully.');
end.
