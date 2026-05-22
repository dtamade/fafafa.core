program test_sse2_batch_ops;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.sse2;

var
  src1, src2, dst, expected: array[0..31] of Single;
  i: Integer;
  sum, dot: Single;
  passed, failed: Integer;
  dt: PSimdDispatchTable;

procedure Check(const testName: string; condition: Boolean);
begin
  if condition then
  begin
    WriteLn('  [PASS] ', testName);
    Inc(passed);
  end
  else
  begin
    WriteLn('  [FAIL] ', testName);
    Inc(failed);
  end;
end;

function ApproxEqual(a, b: Single; tolerance: Single = 1e-5): Boolean;
begin
  Result := Abs(a - b) <= tolerance;
end;

begin
  passed := 0;
  failed := 0;

  dt := GetDispatchTable;

  WriteLn('=== SSE2 Batch Array Operations Test ===');
  WriteLn('Active backend: ', dt^.BackendInfo.Name);
  WriteLn;

  // --- ArrayAddF32 ---
  WriteLn('--- ArrayAddF32 ---');

  // Test: 8 元素 (走 2x 展开路径)
  for i := 0 to 7 do
  begin
    src1[i] := i * 1.0;
    src2[i] := (i + 1) * 2.0;
    expected[i] := src1[i] + src2[i];
  end;
  FillChar(dst, SizeOf(dst), 0);
  dt^.ArrayAddF32(@src1[0], @src2[0], @dst[0], 8);
  for i := 0 to 7 do
    Check(Format('Add8[%d] = %.2f', [i, expected[i]]), ApproxEqual(dst[i], expected[i]));

  // Test: 11 元素 (8 + 4-block 不够, 走 4 + 3 标量)
  for i := 0 to 10 do
  begin
    src1[i] := i * 0.5;
    src2[i] := i * 0.3;
    expected[i] := src1[i] + src2[i];
  end;
  FillChar(dst, SizeOf(dst), 0);
  dt^.ArrayAddF32(@src1[0], @src2[0], @dst[0], 11);
  for i := 0 to 10 do
    Check(Format('Add11[%d] = %.4f', [i, expected[i]]), ApproxEqual(dst[i], expected[i]));

  // Test: 3 元素 (纯标量路径)
  for i := 0 to 2 do
  begin
    src1[i] := 10.0 + i;
    src2[i] := 20.0 + i;
    expected[i] := src1[i] + src2[i];
  end;
  FillChar(dst, SizeOf(dst), 0);
  dt^.ArrayAddF32(@src1[0], @src2[0], @dst[0], 3);
  for i := 0 to 2 do
    Check(Format('Add3[%d] = %.2f', [i, expected[i]]), ApproxEqual(dst[i], expected[i]));

  // Test: 0 元素
  dt^.ArrayAddF32(@src1[0], @src2[0], @dst[0], 0);
  Check('Add0 no crash', True);

  WriteLn;

  // --- ArrayMulF32 ---
  WriteLn('--- ArrayMulF32 ---');

  for i := 0 to 15 do
  begin
    src1[i] := (i + 1) * 1.0;
    src2[i] := (i + 1) * 0.5;
    expected[i] := src1[i] * src2[i];
  end;
  FillChar(dst, SizeOf(dst), 0);
  dt^.ArrayMulF32(@src1[0], @src2[0], @dst[0], 16);
  for i := 0 to 15 do
    Check(Format('Mul16[%d] = %.4f', [i, expected[i]]), ApproxEqual(dst[i], expected[i]));

  // 5 元素 (4 + 1 标量)
  FillChar(dst, SizeOf(dst), 0);
  dt^.ArrayMulF32(@src1[0], @src2[0], @dst[0], 5);
  for i := 0 to 4 do
    Check(Format('Mul5[%d] = %.4f', [i, expected[i]]), ApproxEqual(dst[i], expected[i]));

  WriteLn;

  // --- ArrayMulScalarF32 ---
  WriteLn('--- ArrayMulScalarF32 ---');

  for i := 0 to 9 do
  begin
    src1[i] := (i + 1) * 2.0;
    expected[i] := src1[i] * 3.5;
  end;
  FillChar(dst, SizeOf(dst), 0);
  dt^.ArrayMulScalarF32(@src1[0], @dst[0], 10, 3.5);
  for i := 0 to 9 do
    Check(Format('MulScalar10[%d] = %.4f', [i, expected[i]]), ApproxEqual(dst[i], expected[i]));

  WriteLn;

  // --- ArrayAxpyF32 ---
  WriteLn('--- ArrayAxpyF32 ---');

  for i := 0 to 9 do
  begin
    src1[i] := (i + 1) * 1.0;  // x
    src2[i] := (i + 1) * 0.1;  // y
    expected[i] := 2.5 * src1[i] + src2[i];
  end;
  FillChar(dst, SizeOf(dst), 0);
  dt^.ArrayAxpyF32(2.5, @src1[0], @src2[0], @dst[0], 10);
  for i := 0 to 9 do
    Check(Format('Axpy10[%d] = %.4f', [i, expected[i]]), ApproxEqual(dst[i], expected[i]));

  WriteLn;

  // --- ReduceSumF32 ---
  WriteLn('--- ReduceSumF32 ---');

  // 16 元素
  sum := 0;
  for i := 0 to 15 do
  begin
    src1[i] := (i + 1) * 1.0;
    sum := sum + src1[i];
  end;
  Check(Format('ReduceSum16 = %.2f', [sum]),
    ApproxEqual(dt^.ReduceSumF32(@src1[0], 16), sum, 1e-3));

  // 7 元素
  sum := 0;
  for i := 0 to 6 do
    sum := sum + src1[i];
  Check(Format('ReduceSum7 = %.2f', [sum]),
    ApproxEqual(dt^.ReduceSumF32(@src1[0], 7), sum, 1e-4));

  // 1 元素
  Check('ReduceSum1 = 1.0',
    ApproxEqual(dt^.ReduceSumF32(@src1[0], 1), 1.0));

  // 0 元素
  Check('ReduceSum0 = 0.0',
    ApproxEqual(dt^.ReduceSumF32(@src1[0], 0), 0.0));

  WriteLn;

  // --- ReduceDotF32 ---
  WriteLn('--- ReduceDotF32 ---');

  // 16 元素
  dot := 0;
  for i := 0 to 15 do
  begin
    src1[i] := (i + 1) * 1.0;
    src2[i] := (i + 1) * 0.5;
    dot := dot + src1[i] * src2[i];
  end;
  Check(Format('ReduceDot16 = %.2f', [dot]),
    ApproxEqual(dt^.ReduceDotF32(@src1[0], @src2[0], 16), dot, 1e-2));

  // 5 元素
  dot := 0;
  for i := 0 to 4 do
    dot := dot + src1[i] * src2[i];
  Check(Format('ReduceDot5 = %.4f', [dot]),
    ApproxEqual(dt^.ReduceDotF32(@src1[0], @src2[0], 5), dot, 1e-4));

  // 0 元素
  Check('ReduceDot0 = 0.0',
    ApproxEqual(dt^.ReduceDotF32(@src1[0], @src2[0], 0), 0.0));

  WriteLn;

  // --- 大数组测试 (32 元素, 验证多次循环) ---
  WriteLn('--- Large array (32 elements) ---');
  sum := 0;
  for i := 0 to 31 do
  begin
    src1[i] := i * 0.1;
    sum := sum + src1[i];
  end;
  Check(Format('ReduceSum32 = %.4f', [sum]),
    ApproxEqual(dt^.ReduceSumF32(@src1[0], 32), sum, 1e-3));

  WriteLn;
  WriteLn('=== Results: ', passed, ' passed, ', failed, ' failed ===');

  if failed > 0 then
    Halt(1);
end.
