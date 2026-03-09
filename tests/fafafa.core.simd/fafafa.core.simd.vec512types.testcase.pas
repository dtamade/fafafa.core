unit fafafa.core.simd.vec512types.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

// Keep parity with the original testcase compilation behavior.
{$R-}{$Q-}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.utils,
  fafafa.core.simd.ops;

type


  // 512-bit 向量类型测试 (AVX-512)
  TTestCase_Vec512Types = class(TTestCase)
  published
    // TVecF32x16 类型测试
    procedure Test_VecF32x16_Create;
    procedure Test_VecF32x16_LoHi;
    procedure Test_VecF32x16_SizeOf;
    
    // TVecF64x8 类型测试
    procedure Test_VecF64x8_Create;
    procedure Test_VecF64x8_LoHi;
    procedure Test_VecF64x8_SizeOf;
    
    // TVecI32x16 类型测试
    procedure Test_VecI32x16_Create;
    procedure Test_VecI32x16_LoHi;
    procedure Test_VecI32x16_SizeOf;
    
    // TVecI64x8 类型测试
    procedure Test_VecI64x8_Create;
    procedure Test_VecI64x8_SizeOf;
    
    // TVecI8x64 类型测试
    procedure Test_VecI8x64_Create;
    procedure Test_VecI8x64_SizeOf;
    
    // TMask64 掩码类型测试
    procedure Test_Mask64_AllSet;
    procedure Test_Mask64_NoneSet;
    
    // TMaskF32x16 向量掩码测试
    procedure Test_MaskF32x16_AllTrue;
    procedure Test_MaskF32x16_AllFalse;
    procedure Test_MaskF32x16_ToBitmask;
    procedure Test_MaskF32x16_Any_All_None;
    
    // 512-bit 向量算术测试
    procedure Test_VecF32x16_Add;
    procedure Test_VecF32x16_Sub;
    procedure Test_VecF32x16_Mul;
    procedure Test_VecF32x16_Neg;
    procedure Test_VecF64x8_Add;
    procedure Test_VecI32x16_Add;
    procedure Test_VecI64x8_Add;
    procedure Test_VecI64x8_CompareMasks;
    procedure Test_VecF32x16_ExtendedAPI;
    procedure Test_VecF64x8_ExtendedAPI;
    
    // 512-bit 比较和掩码逻辑测试 (Phase 4)
    procedure Test_VecF32x16_CmpEq;
    procedure Test_VecF32x16_CmpLt;
    procedure Test_MaskF32x16_LogicOps;
    procedure Test_MaskF32x16_Select;
  end;

implementation

{ TTestCase_Vec512Types }

procedure TTestCase_Vec512Types.Test_VecF32x16_Create;
var
  v: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.f[i] := i * 1.5;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 1.5, v.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_LoHi;
var
  v: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.f[i] := i;
  
  // Lo 应该是 [0..7]
  for i := 0 to 7 do
    AssertEquals('Lo element ' + IntToStr(i), Single(i), v.lo.f[i], 0.0001);
  
  // Hi 应该是 [8..15]
  for i := 0 to 7 do
    AssertEquals('Hi element ' + IntToStr(i), Single(i + 8), v.hi.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_SizeOf;
begin
  AssertEquals('TVecF32x16 should be 64 bytes', 64, SizeOf(TVecF32x16));
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_Create;
var
  v: TVecF64x8;
  i: Integer;
begin
  for i := 0 to 7 do
    v.d[i] := i * 2.5;
  
  for i := 0 to 7 do
    AssertEquals('Element ' + IntToStr(i), i * 2.5, v.d[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_LoHi;
var
  v: TVecF64x8;
  i: Integer;
begin
  for i := 0 to 7 do
    v.d[i] := i;
  
  // Lo 应该是 [0..3]
  for i := 0 to 3 do
    AssertEquals('Lo element ' + IntToStr(i), Double(i), v.lo.d[i], 0.0001);
  
  // Hi 应该是 [4..7]
  for i := 0 to 3 do
    AssertEquals('Hi element ' + IntToStr(i), Double(i + 4), v.hi.d[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_SizeOf;
begin
  AssertEquals('TVecF64x8 should be 64 bytes', 64, SizeOf(TVecF64x8));
end;

procedure TTestCase_Vec512Types.Test_VecI32x16_Create;
var
  v: TVecI32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.i[i] := i * 100;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 100, v.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI32x16_LoHi;
var
  v: TVecI32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.i[i] := i;
  
  for i := 0 to 7 do
    AssertEquals('Lo element ' + IntToStr(i), i, v.lo.i[i]);
  
  for i := 0 to 7 do
    AssertEquals('Hi element ' + IntToStr(i), i + 8, v.hi.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI32x16_SizeOf;
begin
  AssertEquals('TVecI32x16 should be 64 bytes', 64, SizeOf(TVecI32x16));
end;

procedure TTestCase_Vec512Types.Test_VecI64x8_Create;
var
  v: TVecI64x8;
  i: Integer;
begin
  for i := 0 to 7 do
    v.i[i] := Int64(i) * 1000000000;
  
  for i := 0 to 7 do
    AssertEquals('Element ' + IntToStr(i), Int64(i) * 1000000000, v.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI64x8_SizeOf;
begin
  AssertEquals('TVecI64x8 should be 64 bytes', 64, SizeOf(TVecI64x8));
end;

procedure TTestCase_Vec512Types.Test_VecI8x64_Create;
var
  v: TVecI8x64;
  i: Integer;
begin
  for i := 0 to 63 do
    v.i[i] := Int8(i - 32);
  
  for i := 0 to 63 do
    AssertEquals('Element ' + IntToStr(i), Int8(i - 32), v.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI8x64_SizeOf;
begin
  AssertEquals('TVecI8x64 should be 64 bytes', 64, SizeOf(TVecI8x64));
end;

procedure TTestCase_Vec512Types.Test_Mask64_AllSet;
var
  m: TMask64;
begin
  m := High(QWord);
  AssertEquals('TMask64 all set', High(QWord), m);
end;

procedure TTestCase_Vec512Types.Test_Mask64_NoneSet;
var
  m: TMask64;
begin
  m := 0;
  AssertEquals('TMask64 none set', 0, m);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_AllTrue;
var
  m: TMaskF32x16;
  i: Integer;
begin
  m := MaskF32x16AllTrue;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i) + ' should be $FFFFFFFF', $FFFFFFFF, m.m[i]);
  AssertEquals('Bits should be $FFFF', $FFFF, m.bits);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_AllFalse;
var
  m: TMaskF32x16;
  i: Integer;
begin
  m := MaskF32x16AllFalse;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i) + ' should be 0', 0, m.m[i]);
  AssertEquals('Bits should be 0', 0, m.bits);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_ToBitmask;
var
  m: TMaskF32x16;
  bm: TMask16;
begin
  m := MaskF32x16AllFalse;
  m.m[0] := $FFFFFFFF;  // bit 0
  m.m[3] := $FFFFFFFF;  // bit 3
  m.m[7] := $FFFFFFFF;  // bit 7
  m.m[15] := $FFFFFFFF; // bit 15
  
  bm := MaskF32x16ToBitmask(m);
  AssertEquals('Bitmask should be $8089', $8089, bm);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_Any_All_None;
var
  mAll, mNone, mSome: TMaskF32x16;
begin
  mAll := MaskF32x16AllTrue;
  mNone := MaskF32x16AllFalse;
  mSome := MaskF32x16AllFalse;
  mSome.m[5] := $FFFFFFFF;
  
  // Test Any
  AssertTrue('All mask Any = True', MaskF32x16Any(mAll));
  AssertFalse('None mask Any = False', MaskF32x16Any(mNone));
  AssertTrue('Some mask Any = True', MaskF32x16Any(mSome));
  
  // Test All
  AssertTrue('All mask All = True', MaskF32x16All(mAll));
  AssertFalse('None mask All = False', MaskF32x16All(mNone));
  AssertFalse('Some mask All = False', MaskF32x16All(mSome));
  
  // Test None
  AssertFalse('All mask None = False', MaskF32x16None(mAll));
  AssertTrue('None mask None = True', MaskF32x16None(mNone));
  AssertFalse('Some mask None = False', MaskF32x16None(mSome));
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_Add;
var
  a, b, r: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i;
    b.f[i] := i * 2;
  end;
  
  r := a + b;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 3.0, r.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_Sub;
var
  a, b, r: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i * 3;
    b.f[i] := i;
  end;
  
  r := a - b;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 2.0, r.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_Mul;
var
  a, b, r: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i + 1;
    b.f[i] := 2;
  end;
  
  r := a * b;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), (i + 1) * 2.0, r.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_Neg;
var
  a, r: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    a.f[i] := i - 7.5;
  
  r := -a;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), -(i - 7.5), r.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_Add;
var
  a, b, r: TVecF64x8;
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    a.d[i] := i * 1.5;
    b.d[i] := i * 0.5;
  end;
  
  r := a + b;
  
  for i := 0 to 7 do
    AssertEquals('Element ' + IntToStr(i), i * 2.0, r.d[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecI32x16_Add;
var
  a, b, r: TVecI32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.i[i] := i * 10;
    b.i[i] := i * 5;
  end;
  
  r := a + b;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 15, r.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI64x8_Add;
var
  LVA, LVB, LResult: TVecI64x8;
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
  begin
    LVA.i[LIndex] := Int64(LIndex) * 100;
    LVB.i[LIndex] := Int64(LIndex) * 7;
  end;

  LResult := VecI64x8Add(LVA, LVB);

  for LIndex := 0 to 7 do
    AssertEquals('VecI64x8Add element ' + IntToStr(LIndex),
      Int64(LIndex) * 107,
      LResult.i[LIndex]);
end;

procedure TTestCase_Vec512Types.Test_VecI64x8_CompareMasks;
var
  LVA, LVB: TVecI64x8;
  LMaskEq, LMaskLt, LMaskGt, LMaskLe, LMaskGe, LMaskNe: TMask8;
begin
  LVA.i[0] := -1;  LVB.i[0] := 0;
  LVA.i[1] := 5;   LVB.i[1] := 1;
  LVA.i[2] := 7;   LVB.i[2] := 7;
  LVA.i[3] := -8;  LVB.i[3] := 9;
  LVA.i[4] := 12;  LVB.i[4] := -3;
  LVA.i[5] := 0;   LVB.i[5] := 0;
  LVA.i[6] := 100; LVB.i[6] := 200;
  LVA.i[7] := -50; LVB.i[7] := -60;

  LMaskEq := VecI64x8CmpEq(LVA, LVB);
  LMaskLt := VecI64x8CmpLt(LVA, LVB);
  LMaskGt := VecI64x8CmpGt(LVA, LVB);
  LMaskLe := VecI64x8CmpLe(LVA, LVB);
  LMaskGe := VecI64x8CmpGe(LVA, LVB);
  LMaskNe := VecI64x8CmpNe(LVA, LVB);

  AssertEquals('VecI64x8CmpEq mask', Integer(TMask8($24)), Integer(LMaskEq));
  AssertEquals('VecI64x8CmpLt mask', Integer(TMask8($49)), Integer(LMaskLt));
  AssertEquals('VecI64x8CmpGt mask', Integer(TMask8($92)), Integer(LMaskGt));
  AssertEquals('VecI64x8CmpLe mask', Integer(TMask8($6D)), Integer(LMaskLe));
  AssertEquals('VecI64x8CmpGe mask', Integer(TMask8($B6)), Integer(LMaskGe));
  AssertEquals('VecI64x8CmpNe mask', Integer(TMask8($DB)), Integer(LMaskNe));
end;


procedure TTestCase_Vec512Types.Test_VecF32x16_ExtendedAPI;
var
  LA, LB, LC, LInput, LResult: TVecF32x16;
  LMask: TMask16;
  LSource, LRoundtrip: array[0..15] of Single;
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
  begin
    LA.f[LIndex] := LIndex + 0.25;
    LB.f[LIndex] := 2.0;
    LC.f[LIndex] := 1.0;
    LSource[LIndex] := LIndex + 0.5;
  end;

  LResult := VecF32x16Fma(LA, LB, LC);
  for LIndex := 0 to 15 do
    AssertEquals('VecF32x16Fma lane ' + IntToStr(LIndex),
      (LIndex + 0.25) * 2.0 + 1.0, LResult.f[LIndex], 0.0001);

  LResult := VecF32x16Clamp(LResult, VecF32x16Splat(3.0), VecF32x16Splat(20.0));
  for LIndex := 0 to 15 do
  begin
    AssertTrue('VecF32x16Clamp min lane ' + IntToStr(LIndex), LResult.f[LIndex] >= 3.0);
    AssertTrue('VecF32x16Clamp max lane ' + IntToStr(LIndex), LResult.f[LIndex] <= 20.0);
  end;

  LInput := VecF32x16Zero;
  LInput.f[0] := 1.2;   LInput.f[1] := -1.2;
  LInput.f[2] := 2.8;   LInput.f[3] := -2.8;

  LResult := VecF32x16Floor(LInput);
  AssertEquals('VecF32x16Floor lane0', 1.0, LResult.f[0], 0.0001);
  AssertEquals('VecF32x16Floor lane1', -2.0, LResult.f[1], 0.0001);
  AssertEquals('VecF32x16Floor lane2', 2.0, LResult.f[2], 0.0001);
  AssertEquals('VecF32x16Floor lane3', -3.0, LResult.f[3], 0.0001);

  LResult := VecF32x16Ceil(LInput);
  AssertEquals('VecF32x16Ceil lane0', 2.0, LResult.f[0], 0.0001);
  AssertEquals('VecF32x16Ceil lane1', -1.0, LResult.f[1], 0.0001);
  AssertEquals('VecF32x16Ceil lane2', 3.0, LResult.f[2], 0.0001);
  AssertEquals('VecF32x16Ceil lane3', -2.0, LResult.f[3], 0.0001);

  LResult := VecF32x16Round(LInput);
  AssertEquals('VecF32x16Round lane0', 1.0, LResult.f[0], 0.0001);
  AssertEquals('VecF32x16Round lane1', -1.0, LResult.f[1], 0.0001);
  AssertEquals('VecF32x16Round lane2', 3.0, LResult.f[2], 0.0001);
  AssertEquals('VecF32x16Round lane3', -3.0, LResult.f[3], 0.0001);

  LResult := VecF32x16Trunc(LInput);
  AssertEquals('VecF32x16Trunc lane0', 1.0, LResult.f[0], 0.0001);
  AssertEquals('VecF32x16Trunc lane1', -1.0, LResult.f[1], 0.0001);
  AssertEquals('VecF32x16Trunc lane2', 2.0, LResult.f[2], 0.0001);
  AssertEquals('VecF32x16Trunc lane3', -2.0, LResult.f[3], 0.0001);

  LResult := VecF32x16Load(@LSource[0]);
  VecF32x16Store(@LRoundtrip[0], LResult);
  for LIndex := 0 to 15 do
    AssertEquals('VecF32x16LoadStore lane ' + IntToStr(LIndex),
      LSource[LIndex], LRoundtrip[LIndex], 0.0001);

  LResult := VecF32x16Splat(3.25);
  for LIndex := 0 to 15 do
    AssertEquals('VecF32x16Splat lane ' + IntToStr(LIndex), 3.25, LResult.f[LIndex], 0.0001);

  LResult := VecF32x16Zero;
  for LIndex := 0 to 15 do
    AssertEquals('VecF32x16Zero lane ' + IntToStr(LIndex), 0.0, LResult.f[LIndex], 0.0001);

  for LIndex := 0 to 15 do
  begin
    LA.f[LIndex] := 100 + LIndex;
    LB.f[LIndex] := 200 + LIndex;
  end;
  LMask := TMask16($5555);
  LResult := VecF32x16Select(LMask, LA, LB);
  for LIndex := 0 to 15 do
    if (LIndex and 1) = 0 then
      AssertEquals('VecF32x16Select even lane ' + IntToStr(LIndex), 100.0 + LIndex, LResult.f[LIndex], 0.0001)
    else
      AssertEquals('VecF32x16Select odd lane ' + IntToStr(LIndex), 200.0 + LIndex, LResult.f[LIndex], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_ExtendedAPI;
var
  LA, LB, LC, LInput, LResult: TVecF64x8;
  LMask: TMask8;
  LSource, LRoundtrip: array[0..7] of Double;
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
  begin
    LA.d[LIndex] := LIndex + 0.5;
    LB.d[LIndex] := 3.0;
    LC.d[LIndex] := 2.0;
    LSource[LIndex] := LIndex + 0.125;
  end;

  LResult := VecF64x8Fma(LA, LB, LC);
  for LIndex := 0 to 7 do
    AssertEquals('VecF64x8Fma lane ' + IntToStr(LIndex),
      (LIndex + 0.5) * 3.0 + 2.0, LResult.d[LIndex], 0.000001);

  LResult := VecF64x8Clamp(LResult, VecF64x8Splat(4.0), VecF64x8Splat(20.0));
  for LIndex := 0 to 7 do
  begin
    AssertTrue('VecF64x8Clamp min lane ' + IntToStr(LIndex), LResult.d[LIndex] >= 4.0);
    AssertTrue('VecF64x8Clamp max lane ' + IntToStr(LIndex), LResult.d[LIndex] <= 20.0);
  end;

  LInput := VecF64x8Zero;
  LInput.d[0] := 1.2;   LInput.d[1] := -1.2;
  LInput.d[2] := 2.8;   LInput.d[3] := -2.8;

  LResult := VecF64x8Floor(LInput);
  AssertEquals('VecF64x8Floor lane0', 1.0, LResult.d[0], 0.000001);
  AssertEquals('VecF64x8Floor lane1', -2.0, LResult.d[1], 0.000001);
  AssertEquals('VecF64x8Floor lane2', 2.0, LResult.d[2], 0.000001);
  AssertEquals('VecF64x8Floor lane3', -3.0, LResult.d[3], 0.000001);

  LResult := VecF64x8Ceil(LInput);
  AssertEquals('VecF64x8Ceil lane0', 2.0, LResult.d[0], 0.000001);
  AssertEquals('VecF64x8Ceil lane1', -1.0, LResult.d[1], 0.000001);
  AssertEquals('VecF64x8Ceil lane2', 3.0, LResult.d[2], 0.000001);
  AssertEquals('VecF64x8Ceil lane3', -2.0, LResult.d[3], 0.000001);

  LResult := VecF64x8Round(LInput);
  AssertEquals('VecF64x8Round lane0', 1.0, LResult.d[0], 0.000001);
  AssertEquals('VecF64x8Round lane1', -1.0, LResult.d[1], 0.000001);
  AssertEquals('VecF64x8Round lane2', 3.0, LResult.d[2], 0.000001);
  AssertEquals('VecF64x8Round lane3', -3.0, LResult.d[3], 0.000001);

  LResult := VecF64x8Trunc(LInput);
  AssertEquals('VecF64x8Trunc lane0', 1.0, LResult.d[0], 0.000001);
  AssertEquals('VecF64x8Trunc lane1', -1.0, LResult.d[1], 0.000001);
  AssertEquals('VecF64x8Trunc lane2', 2.0, LResult.d[2], 0.000001);
  AssertEquals('VecF64x8Trunc lane3', -2.0, LResult.d[3], 0.000001);

  LResult := VecF64x8Load(@LSource[0]);
  VecF64x8Store(@LRoundtrip[0], LResult);
  for LIndex := 0 to 7 do
    AssertEquals('VecF64x8LoadStore lane ' + IntToStr(LIndex),
      LSource[LIndex], LRoundtrip[LIndex], 0.000001);

  LResult := VecF64x8Splat(6.5);
  for LIndex := 0 to 7 do
    AssertEquals('VecF64x8Splat lane ' + IntToStr(LIndex), 6.5, LResult.d[LIndex], 0.000001);

  LResult := VecF64x8Zero;
  for LIndex := 0 to 7 do
    AssertEquals('VecF64x8Zero lane ' + IntToStr(LIndex), 0.0, LResult.d[LIndex], 0.000001);

  for LIndex := 0 to 7 do
  begin
    LA.d[LIndex] := 10 + LIndex;
    LB.d[LIndex] := 20 + LIndex;
  end;
  LMask := TMask8($55);
  LResult := VecF64x8Select(LMask, LA, LB);
  for LIndex := 0 to 7 do
    if (LIndex and 1) = 0 then
      AssertEquals('VecF64x8Select even lane ' + IntToStr(LIndex), 10.0 + LIndex, LResult.d[LIndex], 0.000001)
    else
      AssertEquals('VecF64x8Select odd lane ' + IntToStr(LIndex), 20.0 + LIndex, LResult.d[LIndex], 0.000001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_CmpEq;
var
  a, b: TVecF32x16;
  m: TMaskF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i;
    if i mod 2 = 0 then
      b.f[i] := i    // 等于
    else
      b.f[i] := i + 1;  // 不等
  end;
  
  m := VecF32x16CmpEq(a, b);
  
  for i := 0 to 15 do
    if i mod 2 = 0 then
      AssertEquals('Element ' + IntToStr(i) + ' should be true', $FFFFFFFF, m.m[i])
    else
      AssertEquals('Element ' + IntToStr(i) + ' should be false', 0, m.m[i]);
  
  // 检查 bitmask: 偶数位置为 1 = $5555
  AssertEquals('Bitmask', $5555, m.bits);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_CmpLt;
var
  a, b: TVecF32x16;
  m: TMaskF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i;
    b.f[i] := 8;  // 比较与 8
  end;
  
  m := VecF32x16CmpLt(a, b);
  
  // 元素 0-7 应该小于 8，元素 8-15 不小于 8
  for i := 0 to 7 do
    AssertTrue('Element ' + IntToStr(i) + ' < 8', m.m[i] = $FFFFFFFF);
  for i := 8 to 15 do
    AssertTrue('Element ' + IntToStr(i) + ' >= 8', m.m[i] = 0);
  
  // bitmask: 低 8 位为 1 = $00FF
  AssertEquals('Bitmask', $00FF, m.bits);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_LogicOps;
var
  m1, m2, r: TMaskF32x16;
begin
  // m1 = $5555 (偶数位), m2 = $00FF (低 8 位)
  m1 := MaskF32x16FromBitmask($5555);
  m2 := MaskF32x16FromBitmask($00FF);
  
  // AND: $5555 & $00FF = $0055
  r := m1 and m2;
  AssertEquals('AND result', $0055, r.bits);
  
  // OR: $5555 | $00FF = $55FF
  r := m1 or m2;
  AssertEquals('OR result', $55FF, r.bits);
  
  // XOR: $5555 ^ $00FF = $55AA
  r := m1 xor m2;
  AssertEquals('XOR result', $55AA, r.bits);
  
  // NOT: ~$5555 = $AAAA
  r := not m1;
  AssertEquals('NOT result', $AAAA, r.bits);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_Select;
var
  a, b, r: TVecF32x16;
  m: TMaskF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := 100 + i;  // 真分支
    b.f[i] := 200 + i;  // 假分支
  end;
  
  // 偶数位置选 a，奇数位置选 b
  m := MaskF32x16FromBitmask($5555);
  
  r := MaskF32x16Select(m, a, b);
  
  for i := 0 to 15 do
    if i mod 2 = 0 then
      AssertEquals('Element ' + IntToStr(i), 100.0 + i, r.f[i], 0.0001)
    else
      AssertEquals('Element ' + IntToStr(i), 200.0 + i, r.f[i], 0.0001);
end;




initialization
  RegisterTest(TTestCase_Vec512Types);

end.
