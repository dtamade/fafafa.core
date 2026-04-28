unit fafafa.core.simd.intrinsics.experimental.sse41facade.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.sse41;

type
  TTestCase_Sse41FacadeExperimental = class(TTestCase)
  published
    procedure Test_MinMaxIntegerSemantics;
    procedure Test_DotProductMasks;
    procedure Test_BlendSemantics;
    procedure Test_RoundSemantics;
    procedure Test_InsertExtractAndLoadSemantics;
    procedure Test_ConversionSemantics;
    procedure Test_PtestSemantics;
    procedure Test_MulAndPackSemantics;
  end;

implementation

procedure AssertM128U8Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), QWord(aExpected.m128i_u8[LIndex]), QWord(aActual.m128i_u8[LIndex]));
end;

procedure AssertM128U16Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), QWord(aExpected.m128i_u16[LIndex]), QWord(aActual.m128i_u16[LIndex]));
end;

procedure AssertM128U32Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), QWord(aExpected.m128i_u32[LIndex]), QWord(aActual.m128i_u32[LIndex]));
end;

procedure AssertM128U64Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), QWord(aExpected.m128i_u64[LIndex]), QWord(aActual.m128i_u64[LIndex]));
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

procedure TTestCase_Sse41FacadeExperimental.Test_MinMaxIntegerSemantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  for LIndex := 0 to 15 do
  begin
    LA.m128i_i8[LIndex] := ShortInt(LIndex - 8);
    LB.m128i_i8[LIndex] := ShortInt(7 - LIndex);
  end;

  for LIndex := 0 to 15 do
    if LA.m128i_i8[LIndex] > LB.m128i_i8[LIndex] then
      LExpected.m128i_i8[LIndex] := LA.m128i_i8[LIndex]
    else
      LExpected.m128i_i8[LIndex] := LB.m128i_i8[LIndex];
  AssertM128U8Equal(Self, 'sse41_max_epi8', LExpected, sse41_max_epi8(LA, LB));

  for LIndex := 0 to 15 do
    if LA.m128i_i8[LIndex] < LB.m128i_i8[LIndex] then
      LExpected.m128i_i8[LIndex] := LA.m128i_i8[LIndex]
    else
      LExpected.m128i_i8[LIndex] := LB.m128i_i8[LIndex];
  AssertM128U8Equal(Self, 'sse41_min_epi8', LExpected, sse41_min_epi8(LA, LB));

  LA.m128i_i32[0] := -9;
  LA.m128i_i32[1] := 20;
  LA.m128i_i32[2] := -30;
  LA.m128i_i32[3] := 40;
  LB.m128i_i32[0] := -10;
  LB.m128i_i32[1] := 30;
  LB.m128i_i32[2] := -20;
  LB.m128i_i32[3] := 1;
  LExpected.m128i_i32[0] := -9;
  LExpected.m128i_i32[1] := 30;
  LExpected.m128i_i32[2] := -20;
  LExpected.m128i_i32[3] := 40;
  AssertM128U32Equal(Self, 'sse41_max_epi32', LExpected, sse41_max_epi32(LA, LB));
  LExpected.m128i_i32[0] := -10;
  LExpected.m128i_i32[1] := 20;
  LExpected.m128i_i32[2] := -30;
  LExpected.m128i_i32[3] := 1;
  AssertM128U32Equal(Self, 'sse41_min_epi32', LExpected, sse41_min_epi32(LA, LB));

  LA.m128i_u16[0] := 1;
  LA.m128i_u16[1] := 500;
  LB.m128i_u16[0] := 2;
  LB.m128i_u16[1] := 400;
  LExpected := LA;
  LExpected.m128i_u16[0] := 2;
  LExpected.m128i_u16[1] := 500;
  AssertEquals('sse41_max_epu16 lane0', QWord(2), QWord(sse41_max_epu16(LA, LB).m128i_u16[0]));
  AssertEquals('sse41_max_epu16 lane1', QWord(500), QWord(sse41_max_epu16(LA, LB).m128i_u16[1]));
  AssertEquals('sse41_min_epu16 lane0', QWord(1), QWord(sse41_min_epu16(LA, LB).m128i_u16[0]));
  AssertEquals('sse41_min_epu16 lane1', QWord(400), QWord(sse41_min_epu16(LA, LB).m128i_u16[1]));

  LA.m128i_u32[0] := 1;
  LA.m128i_u32[1] := $FFFFFFFF;
  LB.m128i_u32[0] := 2;
  LB.m128i_u32[1] := 7;
  AssertEquals('sse41_max_epu32 lane0', QWord(2), QWord(sse41_max_epu32(LA, LB).m128i_u32[0]));
  AssertEquals('sse41_max_epu32 lane1', QWord($FFFFFFFF), QWord(sse41_max_epu32(LA, LB).m128i_u32[1]));
  AssertEquals('sse41_min_epu32 lane0', QWord(1), QWord(sse41_min_epu32(LA, LB).m128i_u32[0]));
  AssertEquals('sse41_min_epu32 lane1', QWord(7), QWord(sse41_min_epu32(LA, LB).m128i_u32[1]));
end;

procedure TTestCase_Sse41FacadeExperimental.Test_DotProductMasks;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
begin
  LA.m128_f32[0] := 1.0;
  LA.m128_f32[1] := 2.0;
  LA.m128_f32[2] := 4.0;
  LA.m128_f32[3] := 8.0;
  LB.m128_f32[0] := 10.0;
  LB.m128_f32[1] := 20.0;
  LB.m128_f32[2] := 30.0;
  LB.m128_f32[3] := 40.0;

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128_f32[0] := 10.0 + 120.0;
  LExpected.m128_f32[2] := 10.0 + 120.0;
  AssertM128F32Equal(Self, 'sse41_dp_ps', LExpected, sse41_dp_ps(LA, LB, $55));

  LA.m128d_f64[0] := 3.0;
  LA.m128d_f64[1] := 5.0;
  LB.m128d_f64[0] := 7.0;
  LB.m128d_f64[1] := 11.0;
  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128d_f64[0] := 21.0 + 55.0;
  AssertM128F64Equal(Self, 'sse41_dp_pd', LExpected, sse41_dp_pd(LA, LB, $31));
end;

procedure TTestCase_Sse41FacadeExperimental.Test_BlendSemantics;
var
  LA: TM128;
  LB: TM128;
  LMask: TM128;
  LExpected: TM128;
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
  begin
    LA.m128_f32[LIndex] := 10.0 + LIndex;
    LB.m128_f32[LIndex] := 20.0 + LIndex;
    LExpected.m128_f32[LIndex] := LA.m128_f32[LIndex];
  end;
  LExpected.m128_f32[1] := LB.m128_f32[1];
  LExpected.m128_f32[3] := LB.m128_f32[3];
  AssertM128F32Equal(Self, 'sse41_blend_ps', LExpected, sse41_blend_ps(LA, LB, $0A));

  LA.m128d_f64[0] := 1.0;
  LA.m128d_f64[1] := 2.0;
  LB.m128d_f64[0] := 3.0;
  LB.m128d_f64[1] := 4.0;
  LExpected := LA;
  LExpected.m128d_f64[0] := LB.m128d_f64[0];
  AssertM128F64Equal(Self, 'sse41_blend_pd', LExpected, sse41_blend_pd(LA, LB, $01));

  LMask.m128i_u32[0] := $00000000;
  LMask.m128i_u32[1] := $80000000;
  LMask.m128i_u32[2] := $7FFFFFFF;
  LMask.m128i_u32[3] := $FFFFFFFF;
  LA.m128_f32[0] := 1.0;
  LA.m128_f32[1] := 2.0;
  LA.m128_f32[2] := 3.0;
  LA.m128_f32[3] := 4.0;
  LB.m128_f32[0] := 11.0;
  LB.m128_f32[1] := 12.0;
  LB.m128_f32[2] := 13.0;
  LB.m128_f32[3] := 14.0;
  LExpected.m128_f32[0] := 1.0;
  LExpected.m128_f32[1] := 12.0;
  LExpected.m128_f32[2] := 3.0;
  LExpected.m128_f32[3] := 14.0;
  AssertM128F32Equal(Self, 'sse41_blendv_ps', LExpected, sse41_blendv_ps(LA, LB, LMask));

  LMask.m128i_u64[0] := $8000000000000000;
  LMask.m128i_u64[1] := 0;
  LExpected.m128d_f64[0] := LB.m128d_f64[0];
  LExpected.m128d_f64[1] := LA.m128d_f64[1];
  AssertM128F64Equal(Self, 'sse41_blendv_pd', LExpected, sse41_blendv_pd(LA, LB, LMask));

  for LIndex := 0 to 15 do
  begin
    LA.m128i_u8[LIndex] := LIndex;
    LB.m128i_u8[LIndex] := 100 + LIndex;
    if (LIndex and 1) = 0 then
      LMask.m128i_u8[LIndex] := $80
    else
      LMask.m128i_u8[LIndex] := 0;
    if (LIndex and 1) = 0 then
      LExpected.m128i_u8[LIndex] := LB.m128i_u8[LIndex]
    else
      LExpected.m128i_u8[LIndex] := LA.m128i_u8[LIndex];
  end;
  AssertM128U8Equal(Self, 'sse41_blendv_epi8', LExpected, sse41_blendv_epi8(LA, LB, LMask));
end;

procedure TTestCase_Sse41FacadeExperimental.Test_RoundSemantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
begin
  LA.m128_f32[0] := -1.25;
  LA.m128_f32[1] := 1.25;
  LA.m128_f32[2] := -1.75;
  LA.m128_f32[3] := 1.75;
  LExpected.m128_f32[0] := -2.0;
  LExpected.m128_f32[1] := 1.0;
  LExpected.m128_f32[2] := -2.0;
  LExpected.m128_f32[3] := 1.0;
  AssertM128F32Equal(Self, 'sse41_round_ps floor', LExpected, sse41_round_ps(LA, 1));

  LExpected.m128_f32[0] := -1.0;
  LExpected.m128_f32[1] := 2.0;
  LExpected.m128_f32[2] := -1.0;
  LExpected.m128_f32[3] := 2.0;
  AssertM128F32Equal(Self, 'sse41_round_ps ceil', LExpected, sse41_round_ps(LA, 2));

  LExpected.m128_f32[0] := -1.0;
  LExpected.m128_f32[1] := 1.0;
  LExpected.m128_f32[2] := -1.0;
  LExpected.m128_f32[3] := 1.0;
  AssertM128F32Equal(Self, 'sse41_round_ps trunc', LExpected, sse41_round_ps(LA, 3));

  LA.m128d_f64[0] := -2.25;
  LA.m128d_f64[1] := 2.25;
  LExpected.m128d_f64[0] := -3.0;
  LExpected.m128d_f64[1] := 2.0;
  AssertM128F64Equal(Self, 'sse41_round_pd floor', LExpected, sse41_round_pd(LA, 1));

  LA.m128_f32[0] := 99.0;
  LA.m128_f32[1] := 88.0;
  LB.m128_f32[0] := -3.25;
  LExpected := LA;
  LExpected.m128_f32[0] := -4.0;
  AssertM128F32Equal(Self, 'sse41_round_ss floor preserves high lanes', LExpected, sse41_round_ss(LA, LB, 1));

  LA.m128d_f64[0] := 77.0;
  LA.m128d_f64[1] := 66.0;
  LB.m128d_f64[0] := 3.25;
  LExpected := LA;
  LExpected.m128d_f64[0] := 4.0;
  AssertM128F64Equal(Self, 'sse41_round_sd ceil preserves high lane', LExpected, sse41_round_sd(LA, LB, 2));
end;

procedure TTestCase_Sse41FacadeExperimental.Test_InsertExtractAndLoadSemantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LValue64: Int64;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128i_u32[0] := $11111111;
  LA.m128i_u32[1] := $22222222;
  LA.m128i_u32[2] := $33333333;
  LA.m128i_u32[3] := $44444444;
  LB.m128i_u32[0] := $AAAAAAAA;
  LB.m128i_u32[1] := $BBBBBBBB;
  LB.m128i_u32[2] := $CCCCCCCC;
  LB.m128i_u32[3] := $DDDDDDDD;
  LExpected := LA;
  LExpected.m128i_u32[0] := 0;
  LExpected.m128i_u32[1] := LB.m128i_u32[2];
  LExpected.m128i_u32[3] := 0;
  AssertM128U32Equal(Self, 'sse41_insert_ps', LExpected, sse41_insert_ps(LA, LB, $99));

  AssertEquals('sse41_extract_ps', QWord($33333333), QWord(sse41_extract_ps(LA, 2)));

  LExpected := LA;
  LExpected.m128i_u8[7] := $7F;
  AssertM128U8Equal(Self, 'sse41_insert_epi8', LExpected, sse41_insert_epi8(LA, $7F, 7));
  AssertEquals('sse41_extract_epi8', QWord($7F), QWord(sse41_extract_epi8(LExpected, 7)));

  LExpected := LA;
  LExpected.m128i_i32[2] := -123456;
  AssertM128U32Equal(Self, 'sse41_insert_epi32', LExpected, sse41_insert_epi32(LA, -123456, 2));
  AssertEquals('sse41_extract_epi32', -123456, sse41_extract_epi32(LExpected, 2));

  LExpected := LA;
  LExpected.m128i_i64[1] := Int64($1122334455667788);
  AssertM128U64Equal(Self, 'sse41_insert_epi64', LExpected, sse41_insert_epi64(LA, Int64($1122334455667788), 1));
  AssertEquals('sse41_extract_epi64', Int64($1122334455667788), sse41_extract_epi64(LExpected, 1));

  LValue64 := -123456789012345;
  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_i64[0] := LValue64;
  AssertM128U64Equal(Self, 'sse41_loadl_epi64', LExpected, sse41_loadl_epi64(@LValue64));
end;

procedure TTestCase_Sse41FacadeExperimental.Test_ConversionSemantics;
var
  LA: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  LA.m128i_i8[0] := -1;
  LA.m128i_i8[1] := -128;
  LA.m128i_i8[2] := 127;
  AssertEquals('sse41_cvtepi8_epi16 sign', -1, sse41_cvtepi8_epi16(LA).m128i_i16[0]);
  AssertEquals('sse41_cvtepi8_epi32 sign', -128, sse41_cvtepi8_epi32(LA).m128i_i32[1]);
  AssertEquals('sse41_cvtepi8_epi64 sign', Int64(-1), sse41_cvtepi8_epi64(LA).m128i_i64[0]);

  LA.m128i_i16[0] := -32768;
  LA.m128i_i16[1] := 1234;
  AssertEquals('sse41_cvtepi16_epi32 sign', -32768, sse41_cvtepi16_epi32(LA).m128i_i32[0]);
  AssertEquals('sse41_cvtepi16_epi64 sign', Int64(1234), sse41_cvtepi16_epi64(LA).m128i_i64[1]);

  LA.m128i_i32[0] := -2000000000;
  LA.m128i_i32[1] := 2000000000;
  AssertEquals('sse41_cvtepi32_epi64 sign', Int64(-2000000000), sse41_cvtepi32_epi64(LA).m128i_i64[0]);

  FillChar(LA, SizeOf(LA), 0);
  LA.m128i_u8[0] := $FF;
  LA.m128i_u8[1] := $80;
  AssertEquals('sse41_cvtepu8_epi16 zero', QWord($00FF), QWord(sse41_cvtepu8_epi16(LA).m128i_u16[0]));
  AssertEquals('sse41_cvtepu8_epi32 zero', QWord($0080), QWord(sse41_cvtepu8_epi32(LA).m128i_u32[1]));
  AssertEquals('sse41_cvtepu8_epi64 zero', QWord($00FF), QWord(sse41_cvtepu8_epi64(LA).m128i_u64[0]));

  LA.m128i_u16[0] := $FFFF;
  LA.m128i_u16[1] := $8000;
  AssertEquals('sse41_cvtepu16_epi32 zero', QWord($FFFF), QWord(sse41_cvtepu16_epi32(LA).m128i_u32[0]));
  AssertEquals('sse41_cvtepu16_epi64 zero', QWord($8000), QWord(sse41_cvtepu16_epi64(LA).m128i_u64[1]));

  LA.m128i_u32[0] := $FFFFFFFF;
  AssertEquals('sse41_cvtepu32_epi64 zero', QWord($FFFFFFFF), QWord(sse41_cvtepu32_epi64(LA).m128i_u64[0]));
end;

procedure TTestCase_Sse41FacadeExperimental.Test_PtestSemantics;
var
  LA: TM128;
  LMask: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LMask, SizeOf(LMask), 0);
  LA.m128i_u32[0] := $00000000;
  LMask.m128i_u32[0] := $FFFFFFFF;
  AssertTrue('sse41_test_all_zeros true', sse41_test_all_zeros(LA, LMask));
  LA.m128i_u32[0] := $00000001;
  AssertFalse('sse41_test_all_zeros false', sse41_test_all_zeros(LA, LMask));

  FillChar(LA, SizeOf(LA), $FF);
  AssertTrue('sse41_test_all_ones true', sse41_test_all_ones(LA));
  LA.m128i_u8[3] := $7F;
  AssertFalse('sse41_test_all_ones false', sse41_test_all_ones(LA));

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LMask, SizeOf(LMask), $FF);
  LA.m128i_u32[0] := $0000FFFF;
  AssertTrue('sse41_test_mix_ones_zeros same-word mix', sse41_test_mix_ones_zeros(LA, LMask));

  FillChar(LA, SizeOf(LA), $FF);
  AssertFalse('sse41_test_mix_ones_zeros all ones', sse41_test_mix_ones_zeros(LA, LMask));
end;

procedure TTestCase_Sse41FacadeExperimental.Test_MulAndPackSemantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
begin
  LA.m128i_i32[0] := 100000;
  LA.m128i_i32[1] := -3;
  LA.m128i_i32[2] := -200000;
  LA.m128i_i32[3] := 7;
  LB.m128i_i32[0] := 30000;
  LB.m128i_i32[1] := -4;
  LB.m128i_i32[2] := 10000;
  LB.m128i_i32[3] := -8;
  LExpected.m128i_i32[0] := LA.m128i_i32[0] * LB.m128i_i32[0];
  LExpected.m128i_i32[1] := LA.m128i_i32[1] * LB.m128i_i32[1];
  LExpected.m128i_i32[2] := LA.m128i_i32[2] * LB.m128i_i32[2];
  LExpected.m128i_i32[3] := LA.m128i_i32[3] * LB.m128i_i32[3];
  AssertM128U32Equal(Self, 'sse41_mullo_epi32', LExpected, sse41_mullo_epi32(LA, LB));

  LExpected.m128i_i64[0] := Int64(LA.m128i_i32[0]) * Int64(LB.m128i_i32[0]);
  LExpected.m128i_i64[1] := Int64(LA.m128i_i32[2]) * Int64(LB.m128i_i32[2]);
  AssertM128U64Equal(Self, 'sse41_mul_epi32', LExpected, sse41_mul_epi32(LA, LB));

  LA.m128i_i32[0] := -1;
  LA.m128i_i32[1] := 0;
  LA.m128i_i32[2] := 42;
  LA.m128i_i32[3] := 70000;
  LB.m128i_i32[0] := 65535;
  LB.m128i_i32[1] := 65536;
  LB.m128i_i32[2] := 1234;
  LB.m128i_i32[3] := -100;
  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_u16[0] := 0;
  LExpected.m128i_u16[1] := 0;
  LExpected.m128i_u16[2] := 42;
  LExpected.m128i_u16[3] := 65535;
  LExpected.m128i_u16[4] := 65535;
  LExpected.m128i_u16[5] := 65535;
  LExpected.m128i_u16[6] := 1234;
  LExpected.m128i_u16[7] := 0;
  AssertM128U16Equal(Self, 'sse41_packus_epi32', LExpected, sse41_packus_epi32(LA, LB));
end;

initialization
  RegisterTest(TTestCase_Sse41FacadeExperimental);

end.
