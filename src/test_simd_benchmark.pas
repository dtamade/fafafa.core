program test_simd_benchmark;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, DateUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.ops,
  fafafa.core.simd.ops.scalar;

const
  BENCHMARK_SIZE = 1000000;  // 100万个元素
  ITERATIONS = 100;          // 重复100次取平均

type
  TBenchmarkResult = record
    Name: string;
    TimeMs: Double;
    ElementsPerSecond: Double;
  end;

var
  TestDataA, TestDataB, ResultData: array[0..BENCHMARK_SIZE-1] of Single;

procedure InitializeTestData;
var
  i: Integer;
begin
  WriteLn('初始化测试数据...');
  for i := 0 to BENCHMARK_SIZE - 1 do
  begin
    TestDataA[i] := Random * 100.0;
    TestDataB[i] := Random * 100.0;
  end;
end;

function BenchmarkScalarAdd: TBenchmarkResult;
var
  startTime, endTime: TDateTime;
  i, iter: Integer;
begin
  Result.Name := '标量加法';
  
  startTime := Now;
  for iter := 1 to ITERATIONS do
  begin
    for i := 0 to BENCHMARK_SIZE - 1 do
      ResultData[i] := TestDataA[i] + TestDataB[i];
  end;
  endTime := Now;
  
  Result.TimeMs := MilliSecondsBetween(endTime, startTime);
  Result.ElementsPerSecond := (BENCHMARK_SIZE * ITERATIONS) / (Result.TimeMs / 1000.0);
end;

function BenchmarkSIMDAdd: TBenchmarkResult;
var
  startTime, endTime: TDateTime;
  i, iter: Integer;
  vecA, vecB, vecResult: TVecF32x4;
begin
  Result.Name := 'SIMD 加法 (4x)';
  
  startTime := Now;
  for iter := 1 to ITERATIONS do
  begin
    i := 0;
    while i < BENCHMARK_SIZE - 3 do
    begin
      vecA := VecF32x4_LoadUnaligned(@TestDataA[i]);
      vecB := VecF32x4_LoadUnaligned(@TestDataB[i]);
      vecResult := VecF32x4_Add(vecA, vecB);
      VecF32x4_StoreUnaligned(vecResult, @ResultData[i]);
      Inc(i, 4);
    end;
    
    // 处理剩余元素
    while i < BENCHMARK_SIZE do
    begin
      ResultData[i] := TestDataA[i] + TestDataB[i];
      Inc(i);
    end;
  end;
  endTime := Now;
  
  Result.TimeMs := MilliSecondsBetween(endTime, startTime);
  Result.ElementsPerSecond := (BENCHMARK_SIZE * ITERATIONS) / (Result.TimeMs / 1000.0);
end;

function BenchmarkScalarMul: TBenchmarkResult;
var
  startTime, endTime: TDateTime;
  i, iter: Integer;
begin
  Result.Name := '标量乘法';
  
  startTime := Now;
  for iter := 1 to ITERATIONS do
  begin
    for i := 0 to BENCHMARK_SIZE - 1 do
      ResultData[i] := TestDataA[i] * TestDataB[i];
  end;
  endTime := Now;
  
  Result.TimeMs := MilliSecondsBetween(endTime, startTime);
  Result.ElementsPerSecond := (BENCHMARK_SIZE * ITERATIONS) / (Result.TimeMs / 1000.0);
end;

function BenchmarkSIMDMul: TBenchmarkResult;
var
  startTime, endTime: TDateTime;
  i, iter: Integer;
  vecA, vecB, vecResult: TVecF32x4;
begin
  Result.Name := 'SIMD 乘法 (4x)';
  
  startTime := Now;
  for iter := 1 to ITERATIONS do
  begin
    i := 0;
    while i < BENCHMARK_SIZE - 3 do
    begin
      vecA := VecF32x4_LoadUnaligned(@TestDataA[i]);
      vecB := VecF32x4_LoadUnaligned(@TestDataB[i]);
      vecResult := VecF32x4_Mul(vecA, vecB);
      VecF32x4_StoreUnaligned(vecResult, @ResultData[i]);
      Inc(i, 4);
    end;
    
    // 处理剩余元素
    while i < BENCHMARK_SIZE do
    begin
      ResultData[i] := TestDataA[i] * TestDataB[i];
      Inc(i);
    end;
  end;
  endTime := Now;
  
  Result.TimeMs := MilliSecondsBetween(endTime, startTime);
  Result.ElementsPerSecond := (BENCHMARK_SIZE * ITERATIONS) / (Result.TimeMs / 1000.0);
end;

function BenchmarkDotProduct: TBenchmarkResult;
var
  startTime, endTime: TDateTime;
  i, iter: Integer;
  sum: Single;
begin
  Result.Name := '标量点积';
  
  startTime := Now;
  for iter := 1 to ITERATIONS do
  begin
    sum := 0.0;
    for i := 0 to BENCHMARK_SIZE - 1 do
      sum := sum + TestDataA[i] * TestDataB[i];
  end;
  endTime := Now;
  
  Result.TimeMs := MilliSecondsBetween(endTime, startTime);
  Result.ElementsPerSecond := (BENCHMARK_SIZE * ITERATIONS) / (Result.TimeMs / 1000.0);
end;

function BenchmarkSIMDDotProduct: TBenchmarkResult;
var
  startTime, endTime: TDateTime;
  i, iter: Integer;
  vecA, vecB, vecMul: TVecF32x4;
  sum: Single;
begin
  Result.Name := 'SIMD 点积 (4x)';
  
  startTime := Now;
  for iter := 1 to ITERATIONS do
  begin
    sum := 0.0;
    i := 0;
    while i < BENCHMARK_SIZE - 3 do
    begin
      vecA := VecF32x4_LoadUnaligned(@TestDataA[i]);
      vecB := VecF32x4_LoadUnaligned(@TestDataB[i]);
      vecMul := VecF32x4_Mul(vecA, vecB);
      sum := sum + VecF32x4_HorizontalAdd(vecMul);
      Inc(i, 4);
    end;
    
    // 处理剩余元素
    while i < BENCHMARK_SIZE do
    begin
      sum := sum + TestDataA[i] * TestDataB[i];
      Inc(i);
    end;
  end;
  endTime := Now;
  
  Result.TimeMs := MilliSecondsBetween(endTime, startTime);
  Result.ElementsPerSecond := (BENCHMARK_SIZE * ITERATIONS) / (Result.TimeMs / 1000.0);
end;

procedure PrintBenchmarkResult(const result: TBenchmarkResult);
begin
  WriteLn(Format('%-20s: %8.2f ms, %12.0f 元素/秒', [
    result.Name,
    result.TimeMs,
    result.ElementsPerSecond
  ]));
end;

procedure RunBenchmarks;
var
  scalarAdd, simdAdd: TBenchmarkResult;
  scalarMul, simdMul: TBenchmarkResult;
  scalarDot, simdDot: TBenchmarkResult;
  speedup: Double;
begin
  WriteLn('=== SIMD 性能基准测试 ===');
  WriteLn(Format('测试数据大小: %d 个元素', [BENCHMARK_SIZE]));
  WriteLn(Format('迭代次数: %d', [ITERATIONS]));
  WriteLn('');
  
  // 加法基准测试
  WriteLn('运行加法基准测试...');
  scalarAdd := BenchmarkScalarAdd;
  simdAdd := BenchmarkSIMDAdd;
  
  WriteLn('加法结果:');
  PrintBenchmarkResult(scalarAdd);
  PrintBenchmarkResult(simdAdd);
  if scalarAdd.TimeMs > 0 then
  begin
    speedup := scalarAdd.TimeMs / simdAdd.TimeMs;
    WriteLn(Format('  SIMD 加速比: %.2fx', [speedup]));
  end;
  WriteLn('');
  
  // 乘法基准测试
  WriteLn('运行乘法基准测试...');
  scalarMul := BenchmarkScalarMul;
  simdMul := BenchmarkSIMDMul;
  
  WriteLn('乘法结果:');
  PrintBenchmarkResult(scalarMul);
  PrintBenchmarkResult(simdMul);
  if scalarMul.TimeMs > 0 then
  begin
    speedup := scalarMul.TimeMs / simdMul.TimeMs;
    WriteLn(Format('  SIMD 加速比: %.2fx', [speedup]));
  end;
  WriteLn('');
  
  // 点积基准测试
  WriteLn('运行点积基准测试...');
  scalarDot := BenchmarkDotProduct;
  simdDot := BenchmarkSIMDDotProduct;
  
  WriteLn('点积结果:');
  PrintBenchmarkResult(scalarDot);
  PrintBenchmarkResult(simdDot);
  if scalarDot.TimeMs > 0 then
  begin
    speedup := scalarDot.TimeMs / simdDot.TimeMs;
    WriteLn(Format('  SIMD 加速比: %.2fx', [speedup]));
  end;
  WriteLn('');
  
  WriteLn('=== 基准测试完成 ===');
end;

begin
  try
    Randomize;
    InitializeTestData;
    RunBenchmarks;
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('按任意键退出...');
  ReadLn;
end.
