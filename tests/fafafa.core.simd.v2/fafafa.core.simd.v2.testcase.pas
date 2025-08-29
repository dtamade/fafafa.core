unit fafafa.core.simd.v2.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.simd.v2;

type
  // === 新架构基础测试 ===
  TTestCase_SimdV2_Basic = class(TTestCase)
  published
    procedure Test_SystemInfo;
    procedure Test_CapabilityDetection;
    procedure Test_ContextManagement;
  end;

  // === F32x4 向量测试 ===
  TTestCase_SimdV2_F32x4 = class(TTestCase)
  published
    procedure Test_F32x4_Creation;
    procedure Test_F32x4_Arithmetic;
    procedure Test_F32x4_Comparison;
    procedure Test_F32x4_Math;
    procedure Test_F32x4_Memory;
    procedure Test_F32x4_Reduce;
  end;

  // === F32x8 向量测试 ===
  TTestCase_SimdV2_F32x8 = class(TTestCase)
  published
    procedure Test_F32x8_Creation;
    procedure Test_F32x8_Arithmetic;
  end;

  // === I32x4 向量测试 ===
  TTestCase_SimdV2_I32x4 = class(TTestCase)
  published
    procedure Test_I32x4_Creation;
    procedure Test_I32x4_Arithmetic;
  end;

  // === 性能对比测试 ===
  TTestCase_SimdV2_Performance = class(TTestCase)
  published
    procedure Test_Performance_F32x4_vs_Scalar;
    procedure Test_Performance_Profiling;
  end;

implementation

// === TTestCase_SimdV2_Basic 实现 ===

procedure TTestCase_SimdV2_Basic.Test_SystemInfo;
var
  CPUInfo, Profile: String;
begin
  CPUInfo := simd_get_cpu_info;
  Profile := simd_get_best_profile;
  
  AssertTrue('CPU info should not be empty', CPUInfo <> '');
  AssertTrue('Profile should not be empty', Profile <> '');
  
  WriteLn('CPU Info: ', CPUInfo);
  WriteLn('Best Profile: ', Profile);
end;

procedure TTestCase_SimdV2_Basic.Test_CapabilityDetection;
var
  Caps: TSimdISASet;
begin
  Caps := simd_detect_capabilities;
  
  // 标量总是可用
  AssertTrue('Scalar should always be available', TSimdISA.isaScalar in Caps);

  WriteLn('Detected capabilities: ', Integer(Caps), ' ISAs');
end;

procedure TTestCase_SimdV2_Basic.Test_ContextManagement;
var
  Context: TSimdContext;
begin
  Context := simd_get_context;
  
  AssertTrue('Context should have capabilities', Context.Capabilities <> []);
  AssertTrue('Scalar should be in capabilities', TSimdISA.isaScalar in Context.Capabilities);
  
  // 测试上下文设置
  simd_set_context(Context);
  
  WriteLn('Context active ISA: ', Ord(Context.ActiveISA));
end;

// === TTestCase_SimdV2_F32x4 实现 ===

procedure TTestCase_SimdV2_F32x4.Test_F32x4_Creation;
var
  V1, V2: TF32x4;
  Data: array[0..3] of Single;
  I: Integer;
begin
  // 测试 Splat
  V1 := simd_splat_f32x4(3.14);
  for I := 0 to 3 do
    AssertEquals('Splat should set all elements', 3.14, V1.Extract(I), 0.001);
  
  // 测试 FromArray
  Data[0] := 1.0; Data[1] := 2.0; Data[2] := 3.0; Data[3] := 4.0;
  V2 := TF32x4.FromArray(Data);
  for I := 0 to 3 do
    AssertEquals('FromArray should set correct elements', Data[I], V2.Extract(I), 0.001);
    
  WriteLn('F32x4 creation tests passed');
end;

procedure TTestCase_SimdV2_F32x4.Test_F32x4_Arithmetic;
var
  A, B, Result: TF32x4;
  I: Integer;
begin
  // 准备测试数据
  A := TF32x4.FromArray([1.0, 2.0, 3.0, 4.0]);
  B := TF32x4.FromArray([5.0, 6.0, 7.0, 8.0]);
  
  // 测试加法
  Result := simd_add_f32x4(A, B);
  AssertEquals('Add [0]', 6.0, Result.Extract(0), 0.001);
  AssertEquals('Add [1]', 8.0, Result.Extract(1), 0.001);
  AssertEquals('Add [2]', 10.0, Result.Extract(2), 0.001);
  AssertEquals('Add [3]', 12.0, Result.Extract(3), 0.001);
  
  // 测试减法
  Result := simd_sub_f32x4(A, B);
  AssertEquals('Sub [0]', -4.0, Result.Extract(0), 0.001);
  AssertEquals('Sub [1]', -4.0, Result.Extract(1), 0.001);
  AssertEquals('Sub [2]', -4.0, Result.Extract(2), 0.001);
  AssertEquals('Sub [3]', -4.0, Result.Extract(3), 0.001);
  
  // 测试乘法
  Result := simd_mul_f32x4(A, B);
  AssertEquals('Mul [0]', 5.0, Result.Extract(0), 0.001);
  AssertEquals('Mul [1]', 12.0, Result.Extract(1), 0.001);
  AssertEquals('Mul [2]', 21.0, Result.Extract(2), 0.001);
  AssertEquals('Mul [3]', 32.0, Result.Extract(3), 0.001);
  
  // 测试除法
  Result := simd_div_f32x4(B, A);
  AssertEquals('Div [0]', 5.0, Result.Extract(0), 0.001);
  AssertEquals('Div [1]', 3.0, Result.Extract(1), 0.001);
  AssertEquals('Div [2]', 7.0/3.0, Result.Extract(2), 0.001);
  AssertEquals('Div [3]', 2.0, Result.Extract(3), 0.001);
  
  WriteLn('F32x4 arithmetic tests passed');
end;

procedure TTestCase_SimdV2_F32x4.Test_F32x4_Comparison;
var
  A, B: TF32x4;
  Mask: TMaskF32x4;
begin
  A := TF32x4.FromArray([1.0, 2.0, 3.0, 4.0]);
  B := TF32x4.FromArray([1.0, 3.0, 2.0, 4.0]);
  
  // 测试相等比较
  Mask := simd_eq_f32x4(A, B);
  AssertTrue('Eq [0] should be true', Mask.Data[0]);
  AssertFalse('Eq [1] should be false', Mask.Data[1]);
  AssertFalse('Eq [2] should be false', Mask.Data[2]);
  AssertTrue('Eq [3] should be true', Mask.Data[3]);
  
  // 测试小于比较
  Mask := simd_lt_f32x4(A, B);
  AssertFalse('Lt [0] should be false', Mask.Data[0]);
  AssertTrue('Lt [1] should be true', Mask.Data[1]);
  AssertFalse('Lt [2] should be false', Mask.Data[2]);
  AssertFalse('Lt [3] should be false', Mask.Data[3]);
  
  WriteLn('F32x4 comparison tests passed');
end;

procedure TTestCase_SimdV2_F32x4.Test_F32x4_Math;
var
  A, B, Result: TF32x4;
begin
  A := TF32x4.FromArray([4.0, 9.0, 16.0, 25.0]);
  B := TF32x4.FromArray([2.0, 5.0, 10.0, 20.0]);
  
  // 测试平方根
  Result := simd_sqrt_f32x4(A);
  AssertEquals('Sqrt [0]', 2.0, Result.Extract(0), 0.001);
  AssertEquals('Sqrt [1]', 3.0, Result.Extract(1), 0.001);
  AssertEquals('Sqrt [2]', 4.0, Result.Extract(2), 0.001);
  AssertEquals('Sqrt [3]', 5.0, Result.Extract(3), 0.001);
  
  // 测试最小值
  Result := simd_min_f32x4(A, B);
  AssertEquals('Min [0]', 2.0, Result.Extract(0), 0.001);
  AssertEquals('Min [1]', 5.0, Result.Extract(1), 0.001);
  AssertEquals('Min [2]', 10.0, Result.Extract(2), 0.001);
  AssertEquals('Min [3]', 20.0, Result.Extract(3), 0.001);
  
  // 测试最大值
  Result := simd_max_f32x4(A, B);
  AssertEquals('Max [0]', 4.0, Result.Extract(0), 0.001);
  AssertEquals('Max [1]', 9.0, Result.Extract(1), 0.001);
  AssertEquals('Max [2]', 16.0, Result.Extract(2), 0.001);
  AssertEquals('Max [3]', 25.0, Result.Extract(3), 0.001);
  
  WriteLn('F32x4 math tests passed');
end;

procedure TTestCase_SimdV2_F32x4.Test_F32x4_Memory;
var
  V1, V2: TF32x4;
  Buffer: array[0..3] of Single;
  I: Integer;
begin
  // 准备测试数据
  V1 := TF32x4.FromArray([1.5, 2.5, 3.5, 4.5]);
  
  // 测试存储
  AssertTrue('Store should succeed', simd_store_f32x4(@Buffer[0], V1));
  
  // 验证存储的数据
  AssertEquals('Stored [0]', 1.5, Buffer[0], 0.001);
  AssertEquals('Stored [1]', 2.5, Buffer[1], 0.001);
  AssertEquals('Stored [2]', 3.5, Buffer[2], 0.001);
  AssertEquals('Stored [3]', 4.5, Buffer[3], 0.001);
  
  // 测试加载
  V2 := simd_load_f32x4(@Buffer[0]);
  for I := 0 to 3 do
    AssertEquals('Loaded element', V1.Extract(I), V2.Extract(I), 0.001);
  
  WriteLn('F32x4 memory tests passed');
end;

procedure TTestCase_SimdV2_F32x4.Test_F32x4_Reduce;
var
  V: TF32x4;
  Sum: Single;
begin
  V := TF32x4.FromArray([1.0, 2.0, 3.0, 4.0]);
  
  Sum := simd_reduce_add_f32x4(V);
  AssertEquals('Reduce add should be 10.0', 10.0, Sum, 0.001);
  
  WriteLn('F32x4 reduce tests passed');
end;

// === TTestCase_SimdV2_F32x8 实现 ===

procedure TTestCase_SimdV2_F32x8.Test_F32x8_Creation;
begin
  WriteLn('F32x8 creation test skipped (not implemented yet)');
end;

procedure TTestCase_SimdV2_F32x8.Test_F32x8_Arithmetic;
begin
  WriteLn('F32x8 arithmetic test skipped (not implemented yet)');
end;

// === TTestCase_SimdV2_I32x4 实现 ===

procedure TTestCase_SimdV2_I32x4.Test_I32x4_Creation;
var
  V: TI32x4;
  Data: array[0..3] of Int32;
  I: Integer;
begin
  Data[0] := 10; Data[1] := 20; Data[2] := 30; Data[3] := 40;
  V := TI32x4.FromArray(Data);
  
  for I := 0 to 3 do
    AssertEquals('I32x4 element', Data[I], V.Extract(I));
    
  WriteLn('I32x4 creation tests passed');
end;

procedure TTestCase_SimdV2_I32x4.Test_I32x4_Arithmetic;
var
  A, B, Result: TI32x4;
  Sum: Int32;
begin
  A := TI32x4.FromArray([1, 2, 3, 4]);
  B := TI32x4.FromArray([5, 6, 7, 8]);
  
  // 测试加法
  Result := simd_add_i32x4(A, B);
  AssertEquals('I32x4 Add [0]', 6, Result.Extract(0));
  AssertEquals('I32x4 Add [1]', 8, Result.Extract(1));
  AssertEquals('I32x4 Add [2]', 10, Result.Extract(2));
  AssertEquals('I32x4 Add [3]', 12, Result.Extract(3));
  
  // 测试聚合
  Sum := simd_reduce_add_i32x4(A);
  AssertEquals('I32x4 reduce add', 10, Sum);
  
  WriteLn('I32x4 arithmetic tests passed');
end;

// === TTestCase_SimdV2_Performance 实现 ===

procedure TTestCase_SimdV2_Performance.Test_Performance_F32x4_vs_Scalar;
var
  A, B, Result: TF32x4;
  ScalarA, ScalarB: array[0..3] of Single;
  ScalarResult: array[0..3] of Single;
  I, J: Integer;
  StartTime, EndTime: QWord;
  SimdTime, ScalarTime: QWord;
  const ITERATIONS = 100000;
begin
  // 准备数据
  A := TF32x4.FromArray([1.0, 2.0, 3.0, 4.0]);
  B := TF32x4.FromArray([5.0, 6.0, 7.0, 8.0]);
  ScalarA[0] := 1.0; ScalarA[1] := 2.0; ScalarA[2] := 3.0; ScalarA[3] := 4.0;
  ScalarB[0] := 5.0; ScalarB[1] := 6.0; ScalarB[2] := 7.0; ScalarB[3] := 8.0;
  
  // 测试 SIMD 性能
  StartTime := GetTickCount64;
  for J := 1 to ITERATIONS do
    Result := simd_add_f32x4(A, B);
  EndTime := GetTickCount64;
  SimdTime := EndTime - StartTime;
  
  // 测试标量性能
  StartTime := GetTickCount64;
  for J := 1 to ITERATIONS do
    for I := 0 to 3 do
      ScalarResult[I] := ScalarA[I] + ScalarB[I];
  EndTime := GetTickCount64;
  ScalarTime := EndTime - StartTime;
  
  WriteLn(Format('SIMD Time: %d ms, Scalar Time: %d ms', [SimdTime, ScalarTime]));
  if ScalarTime > 0 then
    WriteLn(Format('SIMD Speedup: %.2fx', [ScalarTime / SimdTime]));
    
  // 验证结果正确性
  AssertEquals('Performance test result [0]', 6.0, Result.Extract(0), 0.001);
end;

procedure TTestCase_SimdV2_Performance.Test_Performance_Profiling;
var
  Stats: String;
begin
  simd_enable_profiling(True);
  
  // 执行一些操作
  simd_add_f32x4(simd_splat_f32x4(1.0), simd_splat_f32x4(2.0));
  
  Stats := simd_get_performance_stats;
  AssertTrue('Performance stats should not be empty', Stats <> '');
  
  WriteLn('Performance Stats: ', Stats);
  
  simd_enable_profiling(False);
end;

// === 测试注册 ===
initialization
  RegisterTest(TTestCase_SimdV2_Basic);
  RegisterTest(TTestCase_SimdV2_F32x4);
  RegisterTest(TTestCase_SimdV2_F32x8);
  RegisterTest(TTestCase_SimdV2_I32x4);
  RegisterTest(TTestCase_SimdV2_Performance);

end.
