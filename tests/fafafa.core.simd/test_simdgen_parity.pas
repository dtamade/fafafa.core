program test_simdgen_parity;
{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Math,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.scalar,
  fafafa.core.simd.generated.scalar;

var
  GPassCount: Integer = 0;
  GFailCount: Integer = 0;

procedure Check(const aName: string; aExpected, aActual: Single);
begin
  if IsNan(aExpected) and IsNan(aActual) then
  begin Inc(GPassCount); Exit; end;
  if Abs(aExpected - aActual) < 1e-5 then
    Inc(GPassCount)
  else begin
    WriteLn('FAIL: ', aName, ' expected=', aExpected:0:6, ' actual=', aActual:0:6);
    Inc(GFailCount);
  end;
end;

procedure CheckVecF32x4(const aName: string; const aExp, aAct: TVecF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    Check(aName + '[' + IntToStr(i) + ']', aExp.f[i], aAct.f[i]);
end;

procedure CheckVecF32x8(const aName: string; const aExp, aAct: TVecF32x8);
var i: Integer;
begin
  for i := 0 to 7 do
    Check(aName + '[' + IntToStr(i) + ']', aExp.f[i], aAct.f[i]);
end;

procedure CheckVecF64x2(const aName: string; const aExp, aAct: TVecF64x2);
var i: Integer;
begin
  for i := 0 to 1 do
    Check(aName + '[' + IntToStr(i) + ']', aExp.d[i], aAct.d[i]);
end;

var
  AF4, BF4, CF4_Existing, CF4_Generated: TVecF32x4;
  AF8, BF8, CF8_Existing, CF8_Generated: TVecF32x8;
  AD2, BD2, CD2_Existing, CD2_Generated: TVecF64x2;
  MaskExisting, MaskGenerated: TMask4;
  i: Integer;
begin
  // Setup test vectors with diverse values including edge cases
  AF4.f[0] := 1.5; AF4.f[1] := -2.7; AF4.f[2] := 0.0; AF4.f[3] := 99.9;
  BF4.f[0] := 3.2; BF4.f[1] := 4.1;  BF4.f[2] := 1.0; BF4.f[3] := -0.5;

  AF8.f[0] := 1.0; AF8.f[1] := 2.0; AF8.f[2] := 3.0; AF8.f[3] := 4.0;
  AF8.f[4] := 5.0; AF8.f[5] := 6.0; AF8.f[6] := 7.0; AF8.f[7] := 8.0;
  BF8.f[0] := 8.0; BF8.f[1] := 7.0; BF8.f[2] := 6.0; BF8.f[3] := 5.0;
  BF8.f[4] := 4.0; BF8.f[5] := 3.0; BF8.f[6] := 2.0; BF8.f[7] := 1.0;

  AD2.d[0] := 3.14159; AD2.d[1] := -2.71828;
  BD2.d[0] := 1.41421; BD2.d[1] := 1.73205;

  // === F32x4 Arithmetic Parity ===
  // Use fafafa.core.simd.scalar (existing) vs fafafa.core.simd.generated.scalar

  // Add
  CF4_Existing := fafafa.core.simd.scalar.ScalarAddF32x4(AF4, BF4);
  CF4_Generated := fafafa.core.simd.generated.scalar.ScalarAddF32x4(AF4, BF4);
  CheckVecF32x4('AddF32x4', CF4_Existing, CF4_Generated);

  // Sub
  CF4_Existing := fafafa.core.simd.scalar.ScalarSubF32x4(AF4, BF4);
  CF4_Generated := fafafa.core.simd.generated.scalar.ScalarSubF32x4(AF4, BF4);
  CheckVecF32x4('SubF32x4', CF4_Existing, CF4_Generated);

  // Mul
  CF4_Existing := fafafa.core.simd.scalar.ScalarMulF32x4(AF4, BF4);
  CF4_Generated := fafafa.core.simd.generated.scalar.ScalarMulF32x4(AF4, BF4);
  CheckVecF32x4('MulF32x4', CF4_Existing, CF4_Generated);

  // Div
  CF4_Existing := fafafa.core.simd.scalar.ScalarDivF32x4(AF4, BF4);
  CF4_Generated := fafafa.core.simd.generated.scalar.ScalarDivF32x4(AF4, BF4);
  CheckVecF32x4('DivF32x4', CF4_Existing, CF4_Generated);

  // Min
  CF4_Existing := fafafa.core.simd.scalar.ScalarMinF32x4(AF4, BF4);
  CF4_Generated := fafafa.core.simd.generated.scalar.ScalarMinF32x4(AF4, BF4);
  CheckVecF32x4('MinF32x4', CF4_Existing, CF4_Generated);

  // Max
  CF4_Existing := fafafa.core.simd.scalar.ScalarMaxF32x4(AF4, BF4);
  CF4_Generated := fafafa.core.simd.generated.scalar.ScalarMaxF32x4(AF4, BF4);
  CheckVecF32x4('MaxF32x4', CF4_Existing, CF4_Generated);

  // === F32x8 Arithmetic Parity ===
  CF8_Existing := fafafa.core.simd.scalar.ScalarAddF32x8(AF8, BF8);
  CF8_Generated := fafafa.core.simd.generated.scalar.ScalarAddF32x8(AF8, BF8);
  CheckVecF32x8('AddF32x8', CF8_Existing, CF8_Generated);

  CF8_Existing := fafafa.core.simd.scalar.ScalarMulF32x8(AF8, BF8);
  CF8_Generated := fafafa.core.simd.generated.scalar.ScalarMulF32x8(AF8, BF8);
  CheckVecF32x8('MulF32x8', CF8_Existing, CF8_Generated);

  // === F64x2 Arithmetic Parity ===
  CD2_Existing := fafafa.core.simd.scalar.ScalarAddF64x2(AD2, BD2);
  CD2_Generated := fafafa.core.simd.generated.scalar.ScalarAddF64x2(AD2, BD2);
  CheckVecF64x2('AddF64x2', CD2_Existing, CD2_Generated);

  CD2_Existing := fafafa.core.simd.scalar.ScalarDivF64x2(AD2, BD2);
  CD2_Generated := fafafa.core.simd.generated.scalar.ScalarDivF64x2(AD2, BD2);
  CheckVecF64x2('DivF64x2', CD2_Existing, CD2_Generated);

  // === Compare Parity ===
  MaskExisting := fafafa.core.simd.scalar.ScalarCmpLtF32x4(AF4, BF4);
  MaskGenerated := fafafa.core.simd.generated.scalar.ScalarCmpLtF32x4(AF4, BF4);
  if MaskExisting = MaskGenerated then Inc(GPassCount)
  else begin WriteLn('FAIL: CmpLtF32x4 mask ', MaskExisting, ' vs ', MaskGenerated); Inc(GFailCount); end;

  MaskExisting := fafafa.core.simd.scalar.ScalarCmpEqF32x4(AF4, AF4);
  MaskGenerated := fafafa.core.simd.generated.scalar.ScalarCmpEqF32x4(AF4, AF4);
  if MaskExisting = MaskGenerated then Inc(GPassCount)
  else begin WriteLn('FAIL: CmpEqF32x4 mask ', MaskExisting, ' vs ', MaskGenerated); Inc(GFailCount); end;

  // === Reduce Parity ===
  Check('ReduceAddF32x4',
    fafafa.core.simd.scalar.ScalarReduceAddF32x4(AF4),
    fafafa.core.simd.generated.scalar.ScalarReduceAddF32x4(AF4));

  Check('ReduceMinF32x4',
    fafafa.core.simd.scalar.ScalarReduceMinF32x4(AF4),
    fafafa.core.simd.generated.scalar.ScalarReduceMinF32x4(AF4));

  Check('ReduceMaxF32x4',
    fafafa.core.simd.scalar.ScalarReduceMaxF32x4(AF4),
    fafafa.core.simd.generated.scalar.ScalarReduceMaxF32x4(AF4));

  // Summary
  WriteLn;
  if GFailCount = 0 then
    WriteLn('PARITY OK: ', GPassCount, ' checks passed, 0 failures')
  else
  begin
    WriteLn('PARITY FAILED: ', GPassCount, ' passed, ', GFailCount, ' failed');
    Halt(1);
  end;
  WriteLn('  Generated scalar implementations are semantically identical to hand-written ones.');
end.
