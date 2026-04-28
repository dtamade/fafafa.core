unit fafafa.core.simd.intrinsics.experimental.fma3facade.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.fma3;

type
  TTestCase_Fma3FacadeExperimental = class(TTestCase)
  published
    procedure Test_PackedF32_128Semantics;
    procedure Test_ScalarF32_LowLaneOnlySemantics;
    procedure Test_PackedF32_256Semantics;
    procedure Test_PackedF64_128Semantics;
    procedure Test_ScalarF64_LowLaneOnlySemantics;
    procedure Test_PackedF64_256Semantics;
    procedure Test_AddSubAlternatingSemantics;
    procedure Test_SubAddAlternatingSemantics;
  end;

implementation

type
  TFloatOpKind = (fokFmadd, fokFmsub, fokFnmadd, fokFnmsub);

procedure InitM128F32(var aValue: TM128; aBase, aStep: Single);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 3 do
    aValue.m128_f32[LIndex] := aBase + aStep * LIndex;
end;

procedure InitM128F64(var aValue: TM128; aBase, aStep: Double);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 1 do
    aValue.m128d_f64[LIndex] := aBase + aStep * LIndex;
end;

procedure InitM256F32(var aValue: TM256; aBase, aStep: Single);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 7 do
    aValue.m256_f32[LIndex] := aBase + aStep * LIndex;
end;

procedure InitM256F64(var aValue: TM256; aBase, aStep: Double);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 3 do
    aValue.m256_f64[LIndex] := aBase + aStep * LIndex;
end;

function ApplyOp(aLeft, aRight, aAddend: Double; aOp: TFloatOpKind): Double;
begin
  case aOp of
    fokFmadd:
      Result := aLeft * aRight + aAddend;
    fokFmsub:
      Result := aLeft * aRight - aAddend;
    fokFnmadd:
      Result := -(aLeft * aRight) + aAddend;
  else
    Result := -(aLeft * aRight) - aAddend;
  end;
end;

procedure AssertM128F32Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m128_f32[LIndex], aActual.m128_f32[LIndex], 0.00001);
end;

procedure AssertM128F64Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m128d_f64[LIndex], aActual.m128d_f64[LIndex], 0.0000000001);
end;

procedure AssertM256F32Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM256);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m256_f32[LIndex], aActual.m256_f32[LIndex], 0.00001);
end;

procedure AssertM256F64Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM256);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m256_f64[LIndex], aActual.m256_f64[LIndex], 0.0000000001);
end;

procedure FillExpectedM128F32(var aExpected: TM128; const aA, aB, aC: TM128; aOp: TFloatOpKind);
var
  LIndex: Integer;
begin
  FillChar(aExpected, SizeOf(aExpected), 0);
  for LIndex := 0 to 3 do
    aExpected.m128_f32[LIndex] := ApplyOp(aA.m128_f32[LIndex], aB.m128_f32[LIndex], aC.m128_f32[LIndex], aOp);
end;

procedure FillExpectedM128F64(var aExpected: TM128; const aA, aB, aC: TM128; aOp: TFloatOpKind);
var
  LIndex: Integer;
begin
  FillChar(aExpected, SizeOf(aExpected), 0);
  for LIndex := 0 to 1 do
    aExpected.m128d_f64[LIndex] := ApplyOp(aA.m128d_f64[LIndex], aB.m128d_f64[LIndex], aC.m128d_f64[LIndex], aOp);
end;

procedure FillExpectedM256F32(var aExpected: TM256; const aA, aB, aC: TM256; aOp: TFloatOpKind);
var
  LIndex: Integer;
begin
  FillChar(aExpected, SizeOf(aExpected), 0);
  for LIndex := 0 to 7 do
    aExpected.m256_f32[LIndex] := ApplyOp(aA.m256_f32[LIndex], aB.m256_f32[LIndex], aC.m256_f32[LIndex], aOp);
end;

procedure FillExpectedM256F64(var aExpected: TM256; const aA, aB, aC: TM256; aOp: TFloatOpKind);
var
  LIndex: Integer;
begin
  FillChar(aExpected, SizeOf(aExpected), 0);
  for LIndex := 0 to 3 do
    aExpected.m256_f64[LIndex] := ApplyOp(aA.m256_f64[LIndex], aB.m256_f64[LIndex], aC.m256_f64[LIndex], aOp);
end;

procedure FillExpectedM128F32Scalar(var aExpected: TM128; const aA, aB, aC: TM128; aOp: TFloatOpKind);
begin
  aExpected := aA;
  aExpected.m128_f32[0] := ApplyOp(aA.m128_f32[0], aB.m128_f32[0], aC.m128_f32[0], aOp);
end;

procedure FillExpectedM128F64Scalar(var aExpected: TM128; const aA, aB, aC: TM128; aOp: TFloatOpKind);
begin
  aExpected := aA;
  aExpected.m128d_f64[0] := ApplyOp(aA.m128d_f64[0], aB.m128d_f64[0], aC.m128d_f64[0], aOp);
end;

procedure TTestCase_Fma3FacadeExperimental.Test_PackedF32_128Semantics;
var
  LA: TM128;
  LB: TM128;
  LC: TM128;
  LExpected: TM128;
begin
  InitM128F32(LA, -2.0, 0.75);
  InitM128F32(LB, 4.0, -0.5);
  InitM128F32(LC, 1.0, 1.25);

  FillExpectedM128F32(LExpected, LA, LB, LC, fokFmadd);
  AssertM128F32Equal(Self, 'fma3_fmadd_ps', LExpected, fma3_fmadd_ps(LA, LB, LC));

  FillExpectedM128F32(LExpected, LA, LB, LC, fokFmsub);
  AssertM128F32Equal(Self, 'fma3_fmsub_ps', LExpected, fma3_fmsub_ps(LA, LB, LC));

  FillExpectedM128F32(LExpected, LA, LB, LC, fokFnmadd);
  AssertM128F32Equal(Self, 'fma3_fnmadd_ps', LExpected, fma3_fnmadd_ps(LA, LB, LC));

  FillExpectedM128F32(LExpected, LA, LB, LC, fokFnmsub);
  AssertM128F32Equal(Self, 'fma3_fnmsub_ps', LExpected, fma3_fnmsub_ps(LA, LB, LC));
end;

procedure TTestCase_Fma3FacadeExperimental.Test_ScalarF32_LowLaneOnlySemantics;
var
  LA: TM128;
  LB: TM128;
  LC: TM128;
  LExpected: TM128;
begin
  InitM128F32(LA, 10.0, 10.0);
  InitM128F32(LB, -3.0, 1.0);
  InitM128F32(LC, 2.0, 2.0);

  FillExpectedM128F32Scalar(LExpected, LA, LB, LC, fokFmadd);
  AssertM128F32Equal(Self, 'fma3_fmadd_ss', LExpected, fma3_fmadd_ss(LA, LB, LC));

  FillExpectedM128F32Scalar(LExpected, LA, LB, LC, fokFmsub);
  AssertM128F32Equal(Self, 'fma3_fmsub_ss', LExpected, fma3_fmsub_ss(LA, LB, LC));

  FillExpectedM128F32Scalar(LExpected, LA, LB, LC, fokFnmadd);
  AssertM128F32Equal(Self, 'fma3_fnmadd_ss', LExpected, fma3_fnmadd_ss(LA, LB, LC));

  FillExpectedM128F32Scalar(LExpected, LA, LB, LC, fokFnmsub);
  AssertM128F32Equal(Self, 'fma3_fnmsub_ss', LExpected, fma3_fnmsub_ss(LA, LB, LC));
end;

procedure TTestCase_Fma3FacadeExperimental.Test_PackedF32_256Semantics;
var
  LA: TM256;
  LB: TM256;
  LC: TM256;
  LExpected: TM256;
begin
  InitM256F32(LA, -4.0, 0.5);
  InitM256F32(LB, 2.0, 0.25);
  InitM256F32(LC, 8.0, -0.75);

  FillExpectedM256F32(LExpected, LA, LB, LC, fokFmadd);
  AssertM256F32Equal(Self, 'fma3_fmadd_ps256', LExpected, fma3_fmadd_ps256(LA, LB, LC));

  FillExpectedM256F32(LExpected, LA, LB, LC, fokFmsub);
  AssertM256F32Equal(Self, 'fma3_fmsub_ps256', LExpected, fma3_fmsub_ps256(LA, LB, LC));

  FillExpectedM256F32(LExpected, LA, LB, LC, fokFnmadd);
  AssertM256F32Equal(Self, 'fma3_fnmadd_ps256', LExpected, fma3_fnmadd_ps256(LA, LB, LC));

  FillExpectedM256F32(LExpected, LA, LB, LC, fokFnmsub);
  AssertM256F32Equal(Self, 'fma3_fnmsub_ps256', LExpected, fma3_fnmsub_ps256(LA, LB, LC));
end;

procedure TTestCase_Fma3FacadeExperimental.Test_PackedF64_128Semantics;
var
  LA: TM128;
  LB: TM128;
  LC: TM128;
  LExpected: TM128;
begin
  InitM128F64(LA, -3.0, 1.25);
  InitM128F64(LB, 4.0, -0.5);
  InitM128F64(LC, 1.5, 2.0);

  FillExpectedM128F64(LExpected, LA, LB, LC, fokFmadd);
  AssertM128F64Equal(Self, 'fma3_fmadd_pd', LExpected, fma3_fmadd_pd(LA, LB, LC));

  FillExpectedM128F64(LExpected, LA, LB, LC, fokFmsub);
  AssertM128F64Equal(Self, 'fma3_fmsub_pd', LExpected, fma3_fmsub_pd(LA, LB, LC));

  FillExpectedM128F64(LExpected, LA, LB, LC, fokFnmadd);
  AssertM128F64Equal(Self, 'fma3_fnmadd_pd', LExpected, fma3_fnmadd_pd(LA, LB, LC));

  FillExpectedM128F64(LExpected, LA, LB, LC, fokFnmsub);
  AssertM128F64Equal(Self, 'fma3_fnmsub_pd', LExpected, fma3_fnmsub_pd(LA, LB, LC));
end;

procedure TTestCase_Fma3FacadeExperimental.Test_ScalarF64_LowLaneOnlySemantics;
var
  LA: TM128;
  LB: TM128;
  LC: TM128;
  LExpected: TM128;
begin
  InitM128F64(LA, 11.0, 10.0);
  InitM128F64(LB, -2.0, 1.0);
  InitM128F64(LC, 5.0, 2.0);

  FillExpectedM128F64Scalar(LExpected, LA, LB, LC, fokFmadd);
  AssertM128F64Equal(Self, 'fma3_fmadd_sd', LExpected, fma3_fmadd_sd(LA, LB, LC));

  FillExpectedM128F64Scalar(LExpected, LA, LB, LC, fokFmsub);
  AssertM128F64Equal(Self, 'fma3_fmsub_sd', LExpected, fma3_fmsub_sd(LA, LB, LC));

  FillExpectedM128F64Scalar(LExpected, LA, LB, LC, fokFnmadd);
  AssertM128F64Equal(Self, 'fma3_fnmadd_sd', LExpected, fma3_fnmadd_sd(LA, LB, LC));

  FillExpectedM128F64Scalar(LExpected, LA, LB, LC, fokFnmsub);
  AssertM128F64Equal(Self, 'fma3_fnmsub_sd', LExpected, fma3_fnmsub_sd(LA, LB, LC));
end;

procedure TTestCase_Fma3FacadeExperimental.Test_PackedF64_256Semantics;
var
  LA: TM256;
  LB: TM256;
  LC: TM256;
  LExpected: TM256;
begin
  InitM256F64(LA, -6.0, 1.25);
  InitM256F64(LB, 3.0, 0.5);
  InitM256F64(LC, 9.0, -1.0);

  FillExpectedM256F64(LExpected, LA, LB, LC, fokFmadd);
  AssertM256F64Equal(Self, 'fma3_fmadd_pd256', LExpected, fma3_fmadd_pd256(LA, LB, LC));

  FillExpectedM256F64(LExpected, LA, LB, LC, fokFmsub);
  AssertM256F64Equal(Self, 'fma3_fmsub_pd256', LExpected, fma3_fmsub_pd256(LA, LB, LC));

  FillExpectedM256F64(LExpected, LA, LB, LC, fokFnmadd);
  AssertM256F64Equal(Self, 'fma3_fnmadd_pd256', LExpected, fma3_fnmadd_pd256(LA, LB, LC));

  FillExpectedM256F64(LExpected, LA, LB, LC, fokFnmsub);
  AssertM256F64Equal(Self, 'fma3_fnmsub_pd256', LExpected, fma3_fnmsub_pd256(LA, LB, LC));
end;

procedure TTestCase_Fma3FacadeExperimental.Test_AddSubAlternatingSemantics;
var
  LA128: TM128;
  LB128: TM128;
  LC128: TM128;
  LE128: TM128;
  LA256: TM256;
  LB256: TM256;
  LC256: TM256;
  LE256: TM256;
  LIndex: Integer;
begin
  InitM128F32(LA128, 1.0, 1.0);
  InitM128F32(LB128, 2.0, 0.5);
  InitM128F32(LC128, 10.0, 1.0);
  FillChar(LE128, SizeOf(LE128), 0);
  for LIndex := 0 to 3 do
    if (LIndex and 1) = 0 then
      LE128.m128_f32[LIndex] := LA128.m128_f32[LIndex] * LB128.m128_f32[LIndex] - LC128.m128_f32[LIndex]
    else
      LE128.m128_f32[LIndex] := LA128.m128_f32[LIndex] * LB128.m128_f32[LIndex] + LC128.m128_f32[LIndex];
  AssertM128F32Equal(Self, 'fma3_fmaddsub_ps', LE128, fma3_fmaddsub_ps(LA128, LB128, LC128));

  InitM128F64(LA128, 1.0, 2.0);
  InitM128F64(LB128, 3.0, 0.25);
  InitM128F64(LC128, 8.0, 1.5);
  FillChar(LE128, SizeOf(LE128), 0);
  for LIndex := 0 to 1 do
    if (LIndex and 1) = 0 then
      LE128.m128d_f64[LIndex] := LA128.m128d_f64[LIndex] * LB128.m128d_f64[LIndex] - LC128.m128d_f64[LIndex]
    else
      LE128.m128d_f64[LIndex] := LA128.m128d_f64[LIndex] * LB128.m128d_f64[LIndex] + LC128.m128d_f64[LIndex];
  AssertM128F64Equal(Self, 'fma3_fmaddsub_pd', LE128, fma3_fmaddsub_pd(LA128, LB128, LC128));

  InitM256F32(LA256, -2.0, 1.0);
  InitM256F32(LB256, 1.5, 0.5);
  InitM256F32(LC256, 7.0, -0.25);
  FillChar(LE256, SizeOf(LE256), 0);
  for LIndex := 0 to 7 do
    if (LIndex and 1) = 0 then
      LE256.m256_f32[LIndex] := LA256.m256_f32[LIndex] * LB256.m256_f32[LIndex] - LC256.m256_f32[LIndex]
    else
      LE256.m256_f32[LIndex] := LA256.m256_f32[LIndex] * LB256.m256_f32[LIndex] + LC256.m256_f32[LIndex];
  AssertM256F32Equal(Self, 'fma3_fmaddsub_ps256', LE256, fma3_fmaddsub_ps256(LA256, LB256, LC256));

  InitM256F64(LA256, 2.0, -0.5);
  InitM256F64(LB256, 4.0, 1.0);
  InitM256F64(LC256, 3.0, 2.0);
  FillChar(LE256, SizeOf(LE256), 0);
  for LIndex := 0 to 3 do
    if (LIndex and 1) = 0 then
      LE256.m256_f64[LIndex] := LA256.m256_f64[LIndex] * LB256.m256_f64[LIndex] - LC256.m256_f64[LIndex]
    else
      LE256.m256_f64[LIndex] := LA256.m256_f64[LIndex] * LB256.m256_f64[LIndex] + LC256.m256_f64[LIndex];
  AssertM256F64Equal(Self, 'fma3_fmaddsub_pd256', LE256, fma3_fmaddsub_pd256(LA256, LB256, LC256));
end;

procedure TTestCase_Fma3FacadeExperimental.Test_SubAddAlternatingSemantics;
var
  LA128: TM128;
  LB128: TM128;
  LC128: TM128;
  LE128: TM128;
  LA256: TM256;
  LB256: TM256;
  LC256: TM256;
  LE256: TM256;
  LIndex: Integer;
begin
  InitM128F32(LA128, 2.0, 1.0);
  InitM128F32(LB128, -1.0, 0.5);
  InitM128F32(LC128, 5.0, 1.0);
  FillChar(LE128, SizeOf(LE128), 0);
  for LIndex := 0 to 3 do
    if (LIndex and 1) = 0 then
      LE128.m128_f32[LIndex] := LA128.m128_f32[LIndex] * LB128.m128_f32[LIndex] + LC128.m128_f32[LIndex]
    else
      LE128.m128_f32[LIndex] := LA128.m128_f32[LIndex] * LB128.m128_f32[LIndex] - LC128.m128_f32[LIndex];
  AssertM128F32Equal(Self, 'fma3_fmsubadd_ps', LE128, fma3_fmsubadd_ps(LA128, LB128, LC128));

  InitM128F64(LA128, -4.0, 1.5);
  InitM128F64(LB128, 2.0, -0.5);
  InitM128F64(LC128, 6.0, 3.0);
  FillChar(LE128, SizeOf(LE128), 0);
  for LIndex := 0 to 1 do
    if (LIndex and 1) = 0 then
      LE128.m128d_f64[LIndex] := LA128.m128d_f64[LIndex] * LB128.m128d_f64[LIndex] + LC128.m128d_f64[LIndex]
    else
      LE128.m128d_f64[LIndex] := LA128.m128d_f64[LIndex] * LB128.m128d_f64[LIndex] - LC128.m128d_f64[LIndex];
  AssertM128F64Equal(Self, 'fma3_fmsubadd_pd', LE128, fma3_fmsubadd_pd(LA128, LB128, LC128));

  InitM256F32(LA256, -3.0, 0.75);
  InitM256F32(LB256, 2.5, -0.25);
  InitM256F32(LC256, 9.0, -0.5);
  FillChar(LE256, SizeOf(LE256), 0);
  for LIndex := 0 to 7 do
    if (LIndex and 1) = 0 then
      LE256.m256_f32[LIndex] := LA256.m256_f32[LIndex] * LB256.m256_f32[LIndex] + LC256.m256_f32[LIndex]
    else
      LE256.m256_f32[LIndex] := LA256.m256_f32[LIndex] * LB256.m256_f32[LIndex] - LC256.m256_f32[LIndex];
  AssertM256F32Equal(Self, 'fma3_fmsubadd_ps256', LE256, fma3_fmsubadd_ps256(LA256, LB256, LC256));

  InitM256F64(LA256, 5.0, -1.0);
  InitM256F64(LB256, -2.0, 0.5);
  InitM256F64(LC256, 4.0, 1.25);
  FillChar(LE256, SizeOf(LE256), 0);
  for LIndex := 0 to 3 do
    if (LIndex and 1) = 0 then
      LE256.m256_f64[LIndex] := LA256.m256_f64[LIndex] * LB256.m256_f64[LIndex] + LC256.m256_f64[LIndex]
    else
      LE256.m256_f64[LIndex] := LA256.m256_f64[LIndex] * LB256.m256_f64[LIndex] - LC256.m256_f64[LIndex];
  AssertM256F64Equal(Self, 'fma3_fmsubadd_pd256', LE256, fma3_fmsubadd_pd256(LA256, LB256, LC256));
end;

initialization
  RegisterTest(TTestCase_Fma3FacadeExperimental);

end.
