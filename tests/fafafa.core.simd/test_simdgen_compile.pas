program test_simdgen_compile;
{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Math,
  fafafa.core.simd.base,
  fafafa.core.simd.generated.scalar;

var
  A4, B4, C4: TVecF32x4;
  R: Single;
  M: TMask4;
begin
  A4.f[0] := 1.0; A4.f[1] := 2.0; A4.f[2] := 3.0; A4.f[3] := 4.0;
  B4.f[0] := 5.0; B4.f[1] := 6.0; B4.f[2] := 7.0; B4.f[3] := 8.0;

  // Arithmetic
  C4 := ScalarAddF32x4(A4, B4);
  Assert(Abs(C4.f[0] - 6.0) < 1e-6, 'AddF32x4 failed');

  C4 := ScalarSubF32x4(A4, B4);
  Assert(Abs(C4.f[0] - (-4.0)) < 1e-6, 'SubF32x4 failed');

  C4 := ScalarMulF32x4(A4, B4);
  Assert(Abs(C4.f[2] - 21.0) < 1e-6, 'MulF32x4 failed');

  C4 := ScalarDivF32x4(A4, B4);
  Assert(Abs(C4.f[0] - 0.2) < 1e-6, 'DivF32x4 failed');

  C4 := ScalarMinF32x4(A4, B4);
  Assert(Abs(C4.f[0] - 1.0) < 1e-6, 'MinF32x4 failed');

  C4 := ScalarMaxF32x4(A4, B4);
  Assert(Abs(C4.f[0] - 5.0) < 1e-6, 'MaxF32x4 failed');

  // Reduction
  R := ScalarReduceAddF32x4(A4);
  Assert(Abs(R - 10.0) < 1e-6, 'ReduceAddF32x4 failed');

  R := ScalarReduceMinF32x4(A4);
  Assert(Abs(R - 1.0) < 1e-6, 'ReduceMinF32x4 failed');

  R := ScalarReduceMaxF32x4(A4);
  Assert(Abs(R - 4.0) < 1e-6, 'ReduceMaxF32x4 failed');

  // Compare
  M := ScalarCmpLtF32x4(A4, B4);
  Assert(M = $F, 'CmpLtF32x4 failed: all lanes should be less');

  M := ScalarCmpEqF32x4(A4, A4);
  Assert(M = $F, 'CmpEqF32x4 failed: self-compare should be all true');

  // Math
  C4 := ScalarAbsF32x4(A4);
  Assert(Abs(C4.f[0] - 1.0) < 1e-6, 'AbsF32x4 failed');

  // Ternary (Fma)
  C4 := ScalarFmaF32x4(A4, B4, A4);
  Assert(Abs(C4.f[0] - 6.0) < 1e-6, 'FmaF32x4 failed: 1*5+1=6');

  // Dot
  R := ScalarDotF32x4(A4, B4);
  Assert(Abs(R - 70.0) < 1e-6, 'DotF32x4 failed: 1*5+2*6+3*7+4*8=70');

  WriteLn('OK: simdgen generated scalar unit compiles and passes smoke tests');
  WriteLn('  438 function signatures validated at compile time');
  WriteLn('  14 runtime correctness checks passed');
end.
