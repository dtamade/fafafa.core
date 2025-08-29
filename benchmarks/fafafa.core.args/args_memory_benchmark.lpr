program args_memory_benchmark;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.args;

const
  MEMORY_TEST_ITERATIONS = 1000;
  LARGE_ARGS_COUNT = 5000;

{$IFDEF MSWINDOWS}
uses Windows;

function GetMemoryUsage: Int64;
var
  MemCounters: TProcessMemoryCounters;
begin
  MemCounters.cb := SizeOf(MemCounters);
  if GetProcessMemoryInfo(GetCurrentProcess, @MemCounters, SizeOf(MemCounters)) then
    Result := MemCounters.WorkingSetSize
  else
    Result := 0;
end;
{$ELSE}
function GetMemoryUsage: Int64;
var
  StatusFile: TextFile;
  Line: string;
  VmRSS: string;
begin
  Result := 0;
  try
    AssignFile(StatusFile, '/proc/self/status');
    Reset(StatusFile);
    while not EOF(StatusFile) do
    begin
      ReadLn(StatusFile, Line);
      if Pos('VmRSS:', Line) = 1 then
      begin
        VmRSS := Copy(Line, 7, Length(Line));
        VmRSS := Trim(VmRSS);
        VmRSS := Copy(VmRSS, 1, Pos(' ', VmRSS) - 1);
        Result := StrToInt64Def(VmRSS, 0) * 1024; // Convert KB to bytes
        Break;
      end;
    end;
    CloseFile(StatusFile);
  except
    Result := 0;
  end;
end;
{$ENDIF}

function GenerateArgsArray(Count: Integer): TStringArray;
var i: Integer;
begin
  SetLength(Result, Count);
  for i := 0 to Count-1 do
  begin
    case i mod 5 of
      0: Result[i] := Format('--long-argument-name-%d=very-long-value-string-%d', [i, i]);
      1: Result[i] := Format('-s%d', [i mod 26 + Ord('a')]);
      2: Result[i] := Format('/windows-style-arg-%d:value-%d', [i, i]);
      3: Result[i] := Format('positional-argument-%d', [i]);
      4: Result[i] := Format('--flag-%d', [i]);
    end;
  end;
end;

procedure BenchmarkMemoryUsage;
var
  i, argCount: Integer;
  args: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  memBefore, memAfter, memDiff: Int64;
  totalMem: Int64;
begin
  WriteLn('=== Memory Usage Analysis ===');
  
  opts := ArgsOptionsDefault;
  totalMem := 0;
  
  for argCount in [10, 50, 100, 500, 1000, 2000] do
  begin
    args := GenerateArgsArray(argCount);
    
    // 强制垃圾回收（如果可用）
    {$IFDEF FPC}
    // FreePascal 没有垃圾回收，但我们可以尝试释放一些内存
    {$ENDIF}
    
    memBefore := GetMemoryUsage;
    A := TArgs.FromArray(args, opts);
    memAfter := GetMemoryUsage;
    
    memDiff := memAfter - memBefore;
    totalMem := totalMem + memDiff;
    
    WriteLn(Format('Args count %d: %d bytes (%.2f bytes/arg)', 
      [argCount, memDiff, memDiff / argCount]));
    
    A.Free;
  end;
  
  WriteLn(Format('Total memory used: %d bytes', [totalMem]));
end;

procedure BenchmarkMemoryLeaks;
var
  i: Integer;
  args: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  memStart, memEnd: Int64;
begin
  WriteLn('=== Memory Leak Detection ===');
  
  opts := ArgsOptionsDefault;
  args := GenerateArgsArray(100);
  
  memStart := GetMemoryUsage;
  
  // 创建和销毁大量对象
  for i := 1 to MEMORY_TEST_ITERATIONS do
  begin
    A := TArgs.FromArray(args, opts);
    A.Free;
  end;
  
  memEnd := GetMemoryUsage;
  
  WriteLn(Format('Memory before: %d bytes', [memStart]));
  WriteLn(Format('Memory after: %d bytes', [memEnd]));
  WriteLn(Format('Memory difference: %d bytes', [memEnd - memStart]));
  
  if memEnd - memStart < 1024 then
    WriteLn('✓ No significant memory leaks detected')
  else
    WriteLn('⚠ Potential memory leak detected');
end;

procedure BenchmarkLargeArgumentSets;
var
  args: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  memBefore, memAfter: Int64;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== Large Argument Sets Performance ===');
  
  opts := ArgsOptionsDefault;
  args := GenerateArgsArray(LARGE_ARGS_COUNT);
  
  memBefore := GetMemoryUsage;
  startTime := Now;
  
  A := TArgs.FromArray(args, opts);
  
  endTime := Now;
  memAfter := GetMemoryUsage;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  
  WriteLn(Format('Parsed %d arguments in %.2fms', [LARGE_ARGS_COUNT, elapsed]));
  WriteLn(Format('Memory used: %d bytes (%.2f bytes/arg)', 
    [memAfter - memBefore, (memAfter - memBefore) / LARGE_ARGS_COUNT]));
  WriteLn(Format('Parse rate: %.0f args/sec', [LARGE_ARGS_COUNT / elapsed * 1000]));
  
  A.Free;
end;

procedure BenchmarkStringAllocation;
var
  i, j: Integer;
  args: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  memBefore, memAfter: Int64;
  v: string;
  allValues: TStringArray;
begin
  WriteLn('=== String Allocation Analysis ===');
  
  opts := ArgsOptionsDefault;
  
  // 创建包含大量重复键的参数
  SetLength(args, 1000);
  for i := 0 to 999 do
    args[i] := Format('--tag=value-%d', [i]);
  
  memBefore := GetMemoryUsage;
  A := TArgs.FromArray(args, opts);
  
  // 获取所有值（这会分配新的字符串数组）
  allValues := A.GetAll('tag');
  
  memAfter := GetMemoryUsage;
  
  WriteLn(Format('Parsed 1000 repeated keys, got %d values', [Length(allValues)]));
  WriteLn(Format('Memory used: %d bytes', [memAfter - memBefore]));
  
  // 测试查询性能
  startTime := Now;
  for i := 1 to 1000 do
    for j := 0 to 9 do
      A.TryGetValue('tag', v);
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn(Format('Query performance: %.0f queries/sec', [10000 / elapsed * 1000]));
  
  A.Free;
end;

var
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('fafafa.core.args Memory Performance Benchmark');
  WriteLn('=============================================');
  WriteLn('Memory test iterations: ', MEMORY_TEST_ITERATIONS);
  WriteLn('Large args count: ', LARGE_ARGS_COUNT);
  WriteLn;
  
  startTime := Now;
  
  BenchmarkMemoryUsage;
  WriteLn;
  
  BenchmarkMemoryLeaks;
  WriteLn;
  
  BenchmarkLargeArgumentSets;
  WriteLn;
  
  BenchmarkStringAllocation;
  WriteLn;
  
  endTime := Now;
  elapsed := MilliSecondsBetween(endTime, startTime);
  
  WriteLn(Format('Total benchmark time: %.2f seconds', [elapsed / 1000]));
  WriteLn('Memory benchmark completed successfully.');
end.
