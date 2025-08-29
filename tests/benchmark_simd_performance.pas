program benchmark_simd_performance;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, DateUtils,
  fafafa.core.simd.v2,
  fafafa.core.simd.v2.types,
  fafafa.core.simd.v2.detect,
  fafafa.core.simd.v2.dispatch,
  fafafa.core.simd.v2.sse2,
  fafafa.core.simd.v2.avx2;

const
  BENCHMARK_ITERATIONS = 1000000;
  ARRAY_SIZE = 1024;

type
  TBenchmarkResult = record
    Name: String;
    TimeMs: Double;
    Throughput: Double; // 操作数/秒
    Speedup: Double;    // 相对于标量的加速比
  end;

var
  TestDataA, TestDataB, TestResult: array[0..ARRAY_SIZE-1] of Single;
  ScalarTime: Double;

// === 基准测试辅助函数 ===

function GetTimeMs: Double;
begin
  Result := Now * 24 * 60 * 60 * 1000; // 转换为毫秒
end;

procedure InitializeTestData;
var
  I: Integer;
begin
  WriteLn('初始化测试数据...');
  for I := 0 to ARRAY_SIZE - 1 do
  begin
    TestDataA[I] := Random * 100.0;
    TestDataB[I] := Random * 100.0;
    TestResult[I] := 0.0;
  end;
end;

function BenchmarkScalarAdd: TBenchmarkResult;
var
  StartTime, EndTime: Double;
  I, J: Integer;
begin
  Result.Name := 'Scalar Add';
  
  StartTime := GetTimeMs;
  for J := 0 to BENCHMARK_ITERATIONS - 1 do
  begin
    for I := 0 to ARRAY_SIZE - 1 do
      TestResult[I] := TestDataA[I] + TestDataB[I];
  end;
  EndTime := GetTimeMs;
  
  Result.TimeMs := EndTime - StartTime;
  Result.Throughput := (BENCHMARK_ITERATIONS * ARRAY_SIZE) / (Result.TimeMs / 1000.0);
  Result.Speedup := 1.0; // 基准
  
  ScalarTime := Result.TimeMs; // 保存用于计算加速比
end;

function BenchmarkSIMDAdd: TBenchmarkResult;
var
  StartTime, EndTime: Double;
  I, J: Integer;
  VecA, VecB, VecC: TF32x4;
begin
  Result.Name := 'SIMD F32x4 Add';
  
  StartTime := GetTimeMs;
  for J := 0 to BENCHMARK_ITERATIONS - 1 do
  begin
    I := 0;
    while I < ARRAY_SIZE - 3 do
    begin
      VecA := TF32x4.Load(@TestDataA[I]);
      VecB := TF32x4.Load(@TestDataB[I]);
      VecC := simd_add_f32x4(VecA, VecB);
      VecC.Store(@TestResult[I]);
      Inc(I, 4);
    end;
    
    // 处理剩余元素
    while I < ARRAY_SIZE do
    begin
      TestResult[I] := TestDataA[I] + TestDataB[I];
      Inc(I);
    end;
  end;
  EndTime := GetTimeMs;
  
  Result.TimeMs := EndTime - StartTime;
  Result.Throughput := (BENCHMARK_ITERATIONS * ARRAY_SIZE) / (Result.TimeMs / 1000.0);
  Result.Speedup := ScalarTime / Result.TimeMs;
end;

function BenchmarkSSE2Add: TBenchmarkResult;
var
  StartTime, EndTime: Double;
  I, J: Integer;
  VecA, VecB, VecC: TF32x4;
begin
  Result.Name := 'SSE2 F32x4 Add';
  
  StartTime := GetTimeMs;
  for J := 0 to BENCHMARK_ITERATIONS - 1 do
  begin
    I := 0;
    while I < ARRAY_SIZE - 3 do
    begin
      VecA := sse2_f32x4_load(@TestDataA[I]);
      VecB := sse2_f32x4_load(@TestDataB[I]);
      VecC := sse2_f32x4_add(VecA, VecB);
      sse2_f32x4_store(@TestResult[I], VecC);
      Inc(I, 4);
    end;
    
    // 处理剩余元素
    while I < ARRAY_SIZE do
    begin
      TestResult[I] := TestDataA[I] + TestDataB[I];
      Inc(I);
    end;
  end;
  EndTime := GetTimeMs;
  
  Result.TimeMs := EndTime - StartTime;
  Result.Throughput := (BENCHMARK_ITERATIONS * ARRAY_SIZE) / (Result.TimeMs / 1000.0);
  Result.Speedup := ScalarTime / Result.TimeMs;
end;

function BenchmarkAVX2Add: TBenchmarkResult;
var
  StartTime, EndTime: Double;
  I, J: Integer;
  VecA, VecB, VecC: TF32x8;
begin
  Result.Name := 'AVX2 F32x8 Add';
  
  StartTime := GetTimeMs;
  for J := 0 to BENCHMARK_ITERATIONS - 1 do
  begin
    I := 0;
    while I < ARRAY_SIZE - 7 do
    begin
      VecA := avx2_f32x8_load(@TestDataA[I]);
      VecB := avx2_f32x8_load(@TestDataB[I]);
      VecC := avx2_f32x8_add(VecA, VecB);
      avx2_f32x8_store(@TestResult[I], VecC);
      Inc(I, 8);
    end;
    
    // 处理剩余元素
    while I < ARRAY_SIZE do
    begin
      TestResult[I] := TestDataA[I] + TestDataB[I];
      Inc(I);
    end;
  end;
  EndTime := GetTimeMs;
  
  Result.TimeMs := EndTime - StartTime;
  Result.Throughput := (BENCHMARK_ITERATIONS * ARRAY_SIZE) / (Result.TimeMs / 1000.0);
  Result.Speedup := ScalarTime / Result.TimeMs;
end;

procedure PrintResult(const Result: TBenchmarkResult);
begin
  WriteLn(Format('%-20s: %8.2f ms, %12.0f ops/sec, %6.2fx speedup', 
    [Result.Name, Result.TimeMs, Result.Throughput, Result.Speedup]));
end;

procedure RunBenchmarks;
var
  ScalarResult, SIMDResult, SSE2Result, AVX2Result: TBenchmarkResult;
  Caps: TSimdISASet;
  Context: TSimdContext;
begin
  WriteLn('=== SIMD 性能基准测试 ===');
  WriteLn;
  
  // 显示系统信息
  WriteLn('系统信息:');
  WriteLn('  CPU: ', simd_get_cpu_info);
  WriteLn('  最佳配置: ', simd_get_best_profile);
  
  Caps := simd_detect_capabilities;
  WriteLn('  支持的指令集:');
  if isaScalar in Caps then WriteLn('    - Scalar');
  if isaSSE2 in Caps then WriteLn('    - SSE2');
  if isaAVX2 in Caps then WriteLn('    - AVX2');
  
  Context := simd_get_context;
  WriteLn('  当前活动 ISA: ', Ord(Context.ActiveISA));
  WriteLn;
  
  WriteLn('基准测试参数:');
  WriteLn('  迭代次数: ', BENCHMARK_ITERATIONS);
  WriteLn('  数组大小: ', ARRAY_SIZE);
  WriteLn('  总操作数: ', BENCHMARK_ITERATIONS * ARRAY_SIZE);
  WriteLn;
  
  WriteLn('运行基准测试...');
  WriteLn;
  
  // 运行基准测试
  ScalarResult := BenchmarkScalarAdd;
  PrintResult(ScalarResult);
  
  SIMDResult := BenchmarkSIMDAdd;
  PrintResult(SIMDResult);
  
  if isaSSE2 in Caps then
  begin
    SSE2Result := BenchmarkSSE2Add;
    PrintResult(SSE2Result);
  end;
  
  if isaAVX2 in Caps then
  begin
    AVX2Result := BenchmarkAVX2Add;
    PrintResult(AVX2Result);
  end;
  
  WriteLn;
  WriteLn('基准测试完成！');
end;

begin
  Randomize;
  InitializeTestData;
  RunBenchmarks;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
