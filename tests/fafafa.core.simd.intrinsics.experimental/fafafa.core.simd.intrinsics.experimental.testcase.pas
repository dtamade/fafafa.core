unit fafafa.core.simd.intrinsics.experimental.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.aes,
  fafafa.core.simd.intrinsics.sha;

type
  TTestCase_SimdIntrinsicsExperimental = class(TTestCase)
  published
    procedure Test_Default_AES_SHA_Rejects;
    procedure Test_Experimental_AES_SHA_PlaceholderSemantics;
  end;

{$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
{$IFDEF CPUX86_64}
  TTestCase_SimdIntrinsicsExperimentalX86 = class(TTestCase)
  published
    procedure Test_SSE3_LoaddupPd_LoadsFirstLaneTwice;
    procedure Test_SSE41_DpPd_UsesSelectedLanes;
    procedure Test_SSE41_RoundPs_Mode1_UpdatesEachLane;
    procedure Test_SSE41_RoundPd_Mode2_UpdatesEachLane;
    procedure Test_SSE41_RoundSsSd_PreserveUnmodifiedLanes;
    procedure Test_SSE41_InsertPs_ReplacesSelectedLane;
    procedure Test_SSE41_ConvertExtends_SignedAndUnsigned;
    procedure Test_SSE41_MinMax_SignedAndUnsigned;
    procedure Test_SSE41_Blend_ImmediateAndVariableMasks;
    procedure Test_SSE42_StringCompareCmpGtAndCrcPlaceholderSemantics;
    procedure Test_AVX_PlaceholderCopyAndMovemaskSemantics;
    procedure Test_AVX512_AddAndMaskPlaceholderSemantics;
    procedure Test_FMA3_FusedAndAlternatingPlaceholderSemantics;
  end;
{$ENDIF}
{$ENDIF}

implementation

{$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
{$IFDEF CPUX86_64}
uses
  fafafa.core.simd.intrinsics.x86.sse2,
  fafafa.core.simd.intrinsics.sse3,
  fafafa.core.simd.intrinsics.sse41,
  fafafa.core.simd.intrinsics.sse42,
  fafafa.core.simd.intrinsics.avx,
  fafafa.core.simd.intrinsics.avx512,
  fafafa.core.simd.intrinsics.fma3;
{$ENDIF}
{$ENDIF}

procedure InitM128ForXorTest(var aValue: TM128; aBase: Byte);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 15 do
    aValue.m128i_u8[LIndex] := Byte(aBase + LIndex);
end;

procedure TTestCase_SimdIntrinsicsExperimental.Test_Default_AES_SHA_Rejects;
var
  LData, LKey, LResult: TM128;
  LRaised: Boolean;
begin
  {$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  Exit;
  {$ENDIF}

  InitM128ForXorTest(LData, 1);
  InitM128ForXorTest(LKey, 17);

  LRaised := False;
  try
    LResult := aes_aesenc_si128(LData, LKey);
    if LResult.m128i_u8[0] = 255 then
      ;
  except
    on E: ENotSupportedException do
      LRaised := True;
  end;
  AssertTrue('aes_aesenc_si128 should reject by default', LRaised);

  LRaised := False;
  try
    LResult := sha_sha1msg1_epu32(LData, LKey);
    if LResult.m128i_u8[0] = 255 then
      ;
  except
    on E: ENotSupportedException do
      LRaised := True;
  end;
  AssertTrue('sha_sha1msg1_epu32 should reject by default', LRaised);
end;

procedure TTestCase_SimdIntrinsicsExperimental.Test_Experimental_AES_SHA_PlaceholderSemantics;
var
  LData, LKey, LA, LB, LC, LResult: TM128;
  LIndex: Integer;
  LExpectedByte: Byte;
  LExpectedWord: DWord;
begin
  {$IFNDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  Exit;
  {$ENDIF}

  InitM128ForXorTest(LData, 3);
  InitM128ForXorTest(LKey, 67);

  LResult := aes_aesenc_si128(LData, LKey);
  for LIndex := 0 to 15 do
  begin
    LExpectedByte := LData.m128i_u8[LIndex] xor LKey.m128i_u8[LIndex];
    AssertEquals('aes_aesenc_si128 xor lane ' + IntToStr(LIndex),
      LExpectedByte, LResult.m128i_u8[LIndex]);
  end;

  LResult := aes_aesenclast_si128(LData, LKey);
  for LIndex := 0 to 15 do
  begin
    LExpectedByte := LData.m128i_u8[LIndex] xor LKey.m128i_u8[LIndex];
    AssertEquals('aes_aesenclast_si128 xor lane ' + IntToStr(LIndex),
      LExpectedByte, LResult.m128i_u8[LIndex]);
  end;

  LResult := aes_aesdec_si128(LData, LKey);
  for LIndex := 0 to 15 do
  begin
    LExpectedByte := LData.m128i_u8[LIndex] xor LKey.m128i_u8[LIndex];
    AssertEquals('aes_aesdec_si128 xor lane ' + IntToStr(LIndex),
      LExpectedByte, LResult.m128i_u8[LIndex]);
  end;

  LResult := aes_aesdeclast_si128(LData, LKey);
  for LIndex := 0 to 15 do
  begin
    LExpectedByte := LData.m128i_u8[LIndex] xor LKey.m128i_u8[LIndex];
    AssertEquals('aes_aesdeclast_si128 xor lane ' + IntToStr(LIndex),
      LExpectedByte, LResult.m128i_u8[LIndex]);
  end;

  LResult := aes_aeskeygenassist_si128(LKey, $5A);
  AssertEquals('aes_aeskeygenassist_si128 first byte xor rcon',
    Byte(LKey.m128i_u8[0] xor $5A), LResult.m128i_u8[0]);
  for LIndex := 1 to 15 do
    AssertEquals('aes_aeskeygenassist_si128 lane keep ' + IntToStr(LIndex),
      LKey.m128i_u8[LIndex], LResult.m128i_u8[LIndex]);

  LResult := aes_aesimc_si128(LData);
  for LIndex := 0 to 15 do
    AssertEquals('aes_aesimc_si128 identity lane ' + IntToStr(LIndex),
      LData.m128i_u8[LIndex], LResult.m128i_u8[LIndex]);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  FillChar(LC, SizeOf(LC), 0);
  LA.m128i_u32[0] := 1;   LA.m128i_u32[1] := 10;  LA.m128i_u32[2] := 100;  LA.m128i_u32[3] := 1000;
  LB.m128i_u32[0] := 2;   LB.m128i_u32[1] := 20;  LB.m128i_u32[2] := 200;  LB.m128i_u32[3] := 2000;
  LC.m128i_u32[0] := 3;   LC.m128i_u32[1] := 30;  LC.m128i_u32[2] := 300;  LC.m128i_u32[3] := 3000;

  LResult := sha_sha1msg1_epu32(LA, LB);
  for LIndex := 0 to 3 do
  begin
    LExpectedWord := LA.m128i_u32[LIndex] xor LB.m128i_u32[LIndex];
    AssertEquals('sha_sha1msg1_epu32 xor lane ' + IntToStr(LIndex),
      LExpectedWord, LResult.m128i_u32[LIndex]);
  end;

  LResult := sha_sha1msg2_epu32(LA, LB);
  for LIndex := 0 to 3 do
  begin
    LExpectedWord := LA.m128i_u32[LIndex] + LB.m128i_u32[LIndex];
    AssertEquals('sha_sha1msg2_epu32 add lane ' + IntToStr(LIndex),
      LExpectedWord, LResult.m128i_u32[LIndex]);
  end;

  LResult := sha_sha1nexte_epu32(LA, LB);
  AssertEquals('sha_sha1nexte_epu32 lane0 add b3',
    LA.m128i_u32[0] + LB.m128i_u32[3], LResult.m128i_u32[0]);
  for LIndex := 1 to 3 do
    AssertEquals('sha_sha1nexte_epu32 keep lane ' + IntToStr(LIndex),
      LA.m128i_u32[LIndex], LResult.m128i_u32[LIndex]);

  LResult := sha_sha1rnds4_epu32(LA, LB, 7);
  for LIndex := 0 to 3 do
  begin
    LExpectedWord := LA.m128i_u32[LIndex] + LB.m128i_u32[LIndex] + 7;
    AssertEquals('sha_sha1rnds4_epu32 add lane ' + IntToStr(LIndex),
      LExpectedWord, LResult.m128i_u32[LIndex]);
  end;

  LResult := sha_sha256msg1_epu32(LA, LB);
  for LIndex := 0 to 3 do
  begin
    LExpectedWord := LA.m128i_u32[LIndex] + LB.m128i_u32[LIndex];
    AssertEquals('sha_sha256msg1_epu32 add lane ' + IntToStr(LIndex),
      LExpectedWord, LResult.m128i_u32[LIndex]);
  end;

  LResult := sha_sha256msg2_epu32(LA, LB);
  for LIndex := 0 to 3 do
  begin
    LExpectedWord := LA.m128i_u32[LIndex] xor LB.m128i_u32[LIndex];
    AssertEquals('sha_sha256msg2_epu32 xor lane ' + IntToStr(LIndex),
      LExpectedWord, LResult.m128i_u32[LIndex]);
  end;

  LResult := sha_sha256rnds2_epu32(LA, LB, LC);
  for LIndex := 0 to 3 do
  begin
    LExpectedWord := LA.m128i_u32[LIndex] + LB.m128i_u32[LIndex] + LC.m128i_u32[LIndex];
    AssertEquals('sha_sha256rnds2_epu32 add lane ' + IntToStr(LIndex),
      LExpectedWord, LResult.m128i_u32[LIndex]);
  end;
end;

{$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
{$IFDEF CPUX86_64}
procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE3_LoaddupPd_LoadsFirstLaneTwice;
var
  LSource: Double;
  LResult: TM128;
begin
  LSource := 7.25;
  LResult := sse3_loaddup_pd(@LSource);
  AssertEquals('sse3_loaddup_pd lane0', 7.25, LResult.m128d_f64[0], 0.0);
  AssertEquals('sse3_loaddup_pd lane1', 7.25, LResult.m128d_f64[1], 0.0);
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE41_DpPd_UsesSelectedLanes;
var
  LA: TM128;
  LB: TM128;
  LResult: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128d_f64[0] := 1.0;
  LA.m128d_f64[1] := 2.0;
  LB.m128d_f64[0] := 3.0;
  LB.m128d_f64[1] := 4.0;

  LResult := sse41_dp_pd(LA, LB, $33);
  AssertEquals('sse41_dp_pd lane0', 11.0, LResult.m128d_f64[0], 0.0);
  AssertEquals('sse41_dp_pd lane1', 11.0, LResult.m128d_f64[1], 0.0);
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE41_RoundPs_Mode1_UpdatesEachLane;
var
  LValue: TM128;
  LResult: TM128;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128_f32[0] := 1.75;
  LValue.m128_f32[1] := 2.25;
  LValue.m128_f32[2] := 3.5;
  LValue.m128_f32[3] := 4.1;

  LResult := sse41_round_ps(LValue, 1);
  AssertEquals('sse41_round_ps lane0', 1.0, LResult.m128_f32[0], 0.0);
  AssertEquals('sse41_round_ps lane1', 1.0, LResult.m128_f32[1], 0.0);
  AssertEquals('sse41_round_ps lane2', 3.0, LResult.m128_f32[2], 0.0);
  AssertEquals('sse41_round_ps lane3', 3.0, LResult.m128_f32[3], 0.0);
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE41_RoundPd_Mode2_UpdatesEachLane;
var
  LValue: TM128;
  LResult: TM128;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128d_f64[0] := 1.1;
  LValue.m128d_f64[1] := 2.6;

  LResult := sse41_round_pd(LValue, 2);
  AssertEquals('sse41_round_pd lane0', 1.0, LResult.m128d_f64[0], 0.0);
  AssertEquals('sse41_round_pd lane1', 3.0, LResult.m128d_f64[1], 0.0);
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE41_RoundSsSd_PreserveUnmodifiedLanes;
var
  LA: TM128;
  LB: TM128;
  LC: TM128;
  LD: TM128;
  LResult: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  FillChar(LC, SizeOf(LC), 0);
  FillChar(LD, SizeOf(LD), 0);

  LA.m128_f32[0] := 10.0;
  LA.m128_f32[1] := 20.0;
  LA.m128_f32[2] := 30.0;
  LA.m128_f32[3] := 40.0;
  LB.m128_f32[0] := 7.9;
  LB.m128_f32[1] := 70.0;
  LB.m128_f32[2] := 80.0;
  LB.m128_f32[3] := 90.0;

  LResult := sse41_round_ss(LA, LB, 3);
  AssertEquals('sse41_round_ss lane0', 7.0, LResult.m128_f32[0], 0.0);
  AssertEquals('sse41_round_ss lane1', 20.0, LResult.m128_f32[1], 0.0);
  AssertEquals('sse41_round_ss lane2', 30.0, LResult.m128_f32[2], 0.0);
  AssertEquals('sse41_round_ss lane3', 40.0, LResult.m128_f32[3], 0.0);

  LC.m128d_f64[0] := 11.0;
  LC.m128d_f64[1] := 22.0;
  LD.m128d_f64[0] := 8.2;
  LD.m128d_f64[1] := 88.0;

  LResult := sse41_round_sd(LC, LD, 3);
  AssertEquals('sse41_round_sd lane0', 8.0, LResult.m128d_f64[0], 0.0);
  AssertEquals('sse41_round_sd lane1', 22.0, LResult.m128d_f64[1], 0.0);
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE41_InsertPs_ReplacesSelectedLane;
var
  LA: TM128;
  LB: TM128;
  LResult: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128_f32[0] := 10.0;
  LA.m128_f32[1] := 20.0;
  LA.m128_f32[2] := 30.0;
  LA.m128_f32[3] := 40.0;
  LB.m128_f32[0] := 100.0;
  LB.m128_f32[1] := 200.0;
  LB.m128_f32[2] := 300.0;
  LB.m128_f32[3] := 400.0;

  LResult := sse41_insert_ps(LA, LB, $C2);
  AssertEquals('sse41_insert_ps lane0', 10.0, LResult.m128_f32[0], 0.0);
  AssertEquals('sse41_insert_ps lane1', 20.0, LResult.m128_f32[1], 0.0);
  AssertEquals('sse41_insert_ps lane2', 400.0, LResult.m128_f32[2], 0.0);
  AssertEquals('sse41_insert_ps lane3', 40.0, LResult.m128_f32[3], 0.0);
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE41_ConvertExtends_SignedAndUnsigned;
var
  LValue: TM128;
  LResult: TM128;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_i8[0] := -1;
  LValue.m128i_i8[1] := 2;
  LValue.m128i_i8[2] := -3;
  LValue.m128i_i8[3] := 4;
  LValue.m128i_i8[4] := -5;
  LValue.m128i_i8[5] := 6;
  LValue.m128i_i8[6] := -7;
  LValue.m128i_i8[7] := 8;

  LResult := sse41_cvtepi8_epi16(LValue);
  AssertEquals('sse41_cvtepi8_epi16 lane0', -1, LResult.m128i_i16[0]);
  AssertEquals('sse41_cvtepi8_epi16 lane1', 2, LResult.m128i_i16[1]);
  AssertEquals('sse41_cvtepi8_epi16 lane6', -7, LResult.m128i_i16[6]);
  AssertEquals('sse41_cvtepi8_epi16 lane7', 8, LResult.m128i_i16[7]);

  LResult := sse41_cvtepi8_epi32(LValue);
  AssertEquals('sse41_cvtepi8_epi32 lane0', -1, LResult.m128i_i32[0]);
  AssertEquals('sse41_cvtepi8_epi32 lane1', 2, LResult.m128i_i32[1]);
  AssertEquals('sse41_cvtepi8_epi32 lane2', -3, LResult.m128i_i32[2]);
  AssertEquals('sse41_cvtepi8_epi32 lane3', 4, LResult.m128i_i32[3]);

  LResult := sse41_cvtepi8_epi64(LValue);
  AssertEquals('sse41_cvtepi8_epi64 lane0', -1, LResult.m128i_i64[0]);
  AssertEquals('sse41_cvtepi8_epi64 lane1', 2, LResult.m128i_i64[1]);

  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_i16[0] := -101;
  LValue.m128i_i16[1] := 202;
  LValue.m128i_i16[2] := -303;
  LValue.m128i_i16[3] := 404;

  LResult := sse41_cvtepi16_epi32(LValue);
  AssertEquals('sse41_cvtepi16_epi32 lane0', -101, LResult.m128i_i32[0]);
  AssertEquals('sse41_cvtepi16_epi32 lane1', 202, LResult.m128i_i32[1]);
  AssertEquals('sse41_cvtepi16_epi32 lane2', -303, LResult.m128i_i32[2]);
  AssertEquals('sse41_cvtepi16_epi32 lane3', 404, LResult.m128i_i32[3]);

  LResult := sse41_cvtepi16_epi64(LValue);
  AssertEquals('sse41_cvtepi16_epi64 lane0', -101, LResult.m128i_i64[0]);
  AssertEquals('sse41_cvtepi16_epi64 lane1', 202, LResult.m128i_i64[1]);

  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_i32[0] := -123456;
  LValue.m128i_i32[1] := 789012;

  LResult := sse41_cvtepi32_epi64(LValue);
  AssertEquals('sse41_cvtepi32_epi64 lane0', -123456, LResult.m128i_i64[0]);
  AssertEquals('sse41_cvtepi32_epi64 lane1', 789012, LResult.m128i_i64[1]);

  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_u8[0] := 200;
  LValue.m128i_u8[1] := 201;
  LValue.m128i_u8[2] := 202;
  LValue.m128i_u8[3] := 203;
  LValue.m128i_u8[4] := 204;
  LValue.m128i_u8[5] := 205;
  LValue.m128i_u8[6] := 206;
  LValue.m128i_u8[7] := 207;

  LResult := sse41_cvtepu8_epi16(LValue);
  AssertEquals('sse41_cvtepu8_epi16 lane0', 200, LResult.m128i_u16[0]);
  AssertEquals('sse41_cvtepu8_epi16 lane7', 207, LResult.m128i_u16[7]);

  LResult := sse41_cvtepu8_epi32(LValue);
  AssertEquals('sse41_cvtepu8_epi32 lane0', 200, LResult.m128i_u32[0]);
  AssertEquals('sse41_cvtepu8_epi32 lane3', 203, LResult.m128i_u32[3]);

  LResult := sse41_cvtepu8_epi64(LValue);
  AssertEquals('sse41_cvtepu8_epi64 lane0', 200, LResult.m128i_u64[0]);
  AssertEquals('sse41_cvtepu8_epi64 lane1', 201, LResult.m128i_u64[1]);

  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_u16[0] := 50000;
  LValue.m128i_u16[1] := 60000;
  LValue.m128i_u16[2] := 12345;
  LValue.m128i_u16[3] := 54321;

  LResult := sse41_cvtepu16_epi32(LValue);
  AssertEquals('sse41_cvtepu16_epi32 lane0', 50000, LResult.m128i_u32[0]);
  AssertEquals('sse41_cvtepu16_epi32 lane3', 54321, LResult.m128i_u32[3]);

  LResult := sse41_cvtepu16_epi64(LValue);
  AssertEquals('sse41_cvtepu16_epi64 lane0', 50000, LResult.m128i_u64[0]);
  AssertEquals('sse41_cvtepu16_epi64 lane1', 60000, LResult.m128i_u64[1]);

  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_u32[0] := $F1234567;
  LValue.m128i_u32[1] := $E2345678;

  LResult := sse41_cvtepu32_epi64(LValue);
  AssertEquals('sse41_cvtepu32_epi64 lane0 low', DWord($F1234567), DWord(LResult.m128i_u64[0] and $FFFFFFFF));
  AssertEquals('sse41_cvtepu32_epi64 lane0 high', QWord(0), QWord(LResult.m128i_u64[0] shr 32));
  AssertEquals('sse41_cvtepu32_epi64 lane1 low', DWord($E2345678), DWord(LResult.m128i_u64[1] and $FFFFFFFF));
  AssertEquals('sse41_cvtepu32_epi64 lane1 high', QWord(0), QWord(LResult.m128i_u64[1] shr 32));
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE41_MinMax_SignedAndUnsigned;
var
  LLeft: TM128;
  LRight: TM128;
  LResult: TM128;
begin
  FillChar(LLeft, SizeOf(LLeft), 0);
  FillChar(LRight, SizeOf(LRight), 0);

  LLeft.m128i_i8[0] := -8;
  LRight.m128i_i8[0] := 7;
  LLeft.m128i_i8[15] := 12;
  LRight.m128i_i8[15] := -11;

  LResult := sse41_min_epi8(LLeft, LRight);
  AssertEquals('sse41_min_epi8 lane0', -8, LResult.m128i_i8[0]);
  AssertEquals('sse41_min_epi8 lane15', -11, LResult.m128i_i8[15]);

  LResult := sse41_max_epi8(LLeft, LRight);
  AssertEquals('sse41_max_epi8 lane0', 7, LResult.m128i_i8[0]);
  AssertEquals('sse41_max_epi8 lane15', 12, LResult.m128i_i8[15]);

  FillChar(LLeft, SizeOf(LLeft), 0);
  FillChar(LRight, SizeOf(LRight), 0);
  LLeft.m128i_i32[0] := -100;
  LRight.m128i_i32[0] := 50;
  LLeft.m128i_i32[3] := 900;
  LRight.m128i_i32[3] := -700;

  LResult := sse41_min_epi32(LLeft, LRight);
  AssertEquals('sse41_min_epi32 lane0', -100, LResult.m128i_i32[0]);
  AssertEquals('sse41_min_epi32 lane3', -700, LResult.m128i_i32[3]);

  LResult := sse41_max_epi32(LLeft, LRight);
  AssertEquals('sse41_max_epi32 lane0', 50, LResult.m128i_i32[0]);
  AssertEquals('sse41_max_epi32 lane3', 900, LResult.m128i_i32[3]);

  FillChar(LLeft, SizeOf(LLeft), 0);
  FillChar(LRight, SizeOf(LRight), 0);
  LLeft.m128i_u16[0] := 1;
  LRight.m128i_u16[0] := 65535;
  LLeft.m128i_u16[7] := 60000;
  LRight.m128i_u16[7] := 5;

  LResult := sse41_min_epu16(LLeft, LRight);
  AssertEquals('sse41_min_epu16 lane0', 1, LResult.m128i_u16[0]);
  AssertEquals('sse41_min_epu16 lane7', 5, LResult.m128i_u16[7]);

  LResult := sse41_max_epu16(LLeft, LRight);
  AssertEquals('sse41_max_epu16 lane0', 65535, LResult.m128i_u16[0]);
  AssertEquals('sse41_max_epu16 lane7', 60000, LResult.m128i_u16[7]);

  FillChar(LLeft, SizeOf(LLeft), 0);
  FillChar(LRight, SizeOf(LRight), 0);
  LLeft.m128i_u32[0] := $10000000;
  LRight.m128i_u32[0] := $F0000000;
  LLeft.m128i_u32[3] := $90000000;
  LRight.m128i_u32[3] := $00000002;

  LResult := sse41_min_epu32(LLeft, LRight);
  AssertEquals('sse41_min_epu32 lane0', Int64($10000000), Int64(LResult.m128i_u32[0]));
  AssertEquals('sse41_min_epu32 lane3', Int64(2), Int64(LResult.m128i_u32[3]));

  LResult := sse41_max_epu32(LLeft, LRight);
  AssertEquals('sse41_max_epu32 lane0', Int64($F0000000), Int64(LResult.m128i_u32[0]));
  AssertEquals('sse41_max_epu32 lane3', Int64($90000000), Int64(LResult.m128i_u32[3]));
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE41_Blend_ImmediateAndVariableMasks;
var
  LA: TM128;
  LB: TM128;
  LMask: TM128;
  LResult: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128_f32[0] := 10.0;
  LA.m128_f32[1] := 20.0;
  LA.m128_f32[2] := 30.0;
  LA.m128_f32[3] := 40.0;
  LB.m128_f32[0] := 100.0;
  LB.m128_f32[1] := 200.0;
  LB.m128_f32[2] := 300.0;
  LB.m128_f32[3] := 400.0;

  LResult := sse41_blend_ps(LA, LB, $05);
  AssertEquals('sse41_blend_ps lane0', 100.0, LResult.m128_f32[0], 0.0);
  AssertEquals('sse41_blend_ps lane1', 20.0, LResult.m128_f32[1], 0.0);
  AssertEquals('sse41_blend_ps lane2', 300.0, LResult.m128_f32[2], 0.0);
  AssertEquals('sse41_blend_ps lane3', 40.0, LResult.m128_f32[3], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128d_f64[0] := 11.0;
  LA.m128d_f64[1] := 22.0;
  LB.m128d_f64[0] := 111.0;
  LB.m128d_f64[1] := 222.0;

  LResult := sse41_blend_pd(LA, LB, $02);
  AssertEquals('sse41_blend_pd lane0', 11.0, LResult.m128d_f64[0], 0.0);
  AssertEquals('sse41_blend_pd lane1', 222.0, LResult.m128d_f64[1], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  FillChar(LMask, SizeOf(LMask), 0);
  LA.m128_f32[0] := 1.0;
  LA.m128_f32[1] := 2.0;
  LA.m128_f32[2] := 3.0;
  LA.m128_f32[3] := 4.0;
  LB.m128_f32[0] := 10.0;
  LB.m128_f32[1] := 20.0;
  LB.m128_f32[2] := 30.0;
  LB.m128_f32[3] := 40.0;
  LMask.m128i_u32[1] := $80000000;
  LMask.m128i_u32[3] := $80000000;

  LResult := sse41_blendv_ps(LA, LB, LMask);
  AssertEquals('sse41_blendv_ps lane0', 1.0, LResult.m128_f32[0], 0.0);
  AssertEquals('sse41_blendv_ps lane1', 20.0, LResult.m128_f32[1], 0.0);
  AssertEquals('sse41_blendv_ps lane2', 3.0, LResult.m128_f32[2], 0.0);
  AssertEquals('sse41_blendv_ps lane3', 40.0, LResult.m128_f32[3], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  FillChar(LMask, SizeOf(LMask), 0);
  LA.m128d_f64[0] := 5.0;
  LA.m128d_f64[1] := 6.0;
  LB.m128d_f64[0] := 50.0;
  LB.m128d_f64[1] := 60.0;
  LMask.m128i_u64[0] := QWord($8000000000000000);

  LResult := sse41_blendv_pd(LA, LB, LMask);
  AssertEquals('sse41_blendv_pd lane0', 50.0, LResult.m128d_f64[0], 0.0);
  AssertEquals('sse41_blendv_pd lane1', 6.0, LResult.m128d_f64[1], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  FillChar(LMask, SizeOf(LMask), 0);
  LA.m128i_u8[0] := 1;
  LA.m128i_u8[1] := 2;
  LA.m128i_u8[15] := 15;
  LB.m128i_u8[0] := 100;
  LB.m128i_u8[1] := 101;
  LB.m128i_u8[15] := 115;
  LMask.m128i_u8[0] := $80;
  LMask.m128i_u8[15] := $80;

  LResult := sse41_blendv_epi8(LA, LB, LMask);
  AssertEquals('sse41_blendv_epi8 lane0', 100, LResult.m128i_u8[0]);
  AssertEquals('sse41_blendv_epi8 lane1', 2, LResult.m128i_u8[1]);
  AssertEquals('sse41_blendv_epi8 lane15', 115, LResult.m128i_u8[15]);
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_SSE42_StringCompareCmpGtAndCrcPlaceholderSemantics;
var
  LA: TM128;
  LB: TM128;
  LResult: TM128;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  InitM128ForXorTest(LA, 1);
  InitM128ForXorTest(LB, 21);

  LResult := sse42_cmpestrm(LA, 5, LB, 7, $12);
  for LIndex := 0 to 15 do
    AssertEquals('sse42_cmpestrm zero lane ' + IntToStr(LIndex), 0, LResult.m128i_u8[LIndex]);
  AssertEquals('sse42_cmpestri not-found sentinel', 16, sse42_cmpestri(LA, 5, LB, 7, $12));
  AssertFalse('sse42_cmpestrc placeholder false', sse42_cmpestrc(LA, 5, LB, 7, $12));
  AssertFalse('sse42_cmpestro placeholder false', sse42_cmpestro(LA, 5, LB, 7, $12));
  AssertFalse('sse42_cmpestrs placeholder false', sse42_cmpestrs(LA, 5, LB, 7, $12));
  AssertTrue('sse42_cmpestrz placeholder true', sse42_cmpestrz(LA, 5, LB, 7, $12));

  LResult := sse42_cmpistrm(LA, LB, $34);
  for LIndex := 0 to 15 do
    AssertEquals('sse42_cmpistrm zero lane ' + IntToStr(LIndex), 0, LResult.m128i_u8[LIndex]);
  AssertEquals('sse42_cmpistri not-found sentinel', 16, sse42_cmpistri(LA, LB, $34));
  AssertFalse('sse42_cmpistrc placeholder false', sse42_cmpistrc(LA, LB, $34));
  AssertFalse('sse42_cmpistro placeholder false', sse42_cmpistro(LA, LB, $34));
  AssertFalse('sse42_cmpistrs placeholder false', sse42_cmpistrs(LA, LB, $34));
  AssertTrue('sse42_cmpistrz placeholder true', sse42_cmpistrz(LA, LB, $34));

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128i_i64[0] := 10;
  LA.m128i_i64[1] := -8;
  LB.m128i_i64[0] := 7;
  LB.m128i_i64[1] := -8;
  LResult := sse42_cmpgt_epi64(LA, LB);
  AssertEquals('sse42_cmpgt_epi64 lane0', QWord($FFFFFFFFFFFFFFFF), LResult.m128i_u64[0]);
  AssertEquals('sse42_cmpgt_epi64 lane1', QWord(0), LResult.m128i_u64[1]);

  AssertEquals('sse42_crc32_u8 placeholder polynomial', DWord($41047A60), sse42_crc32_u8(0, $AB));
  AssertEquals('sse42_crc32_u16 placeholder polynomial', DWord($489382BF), sse42_crc32_u16(0, $1234));
  AssertEquals('sse42_crc32_u32 placeholder polynomial', DWord($CEFC0ADB), sse42_crc32_u32(0, $89ABCDEF));
  AssertEquals('sse42_crc32_u64 placeholder polynomial', QWord($21193D2E), sse42_crc32_u64(0, QWord($0123456789ABCDEF)));
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_AVX_PlaceholderCopyAndMovemaskSemantics;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LInsert: TM128;
  LExtract: TM128;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  for LIndex := 0 to 7 do
  begin
    LA.m256_f32[LIndex] := 10.0 + LIndex;
    LB.m256_f32[LIndex] := 100.0 + LIndex;
  end;

  LActual := avx_cmp_ps256(LA, LB, $1F);
  for LIndex := 0 to 7 do
    AssertEquals('avx_cmp_ps256 placeholder keeps a lane ' + IntToStr(LIndex), LA.m256_f32[LIndex], LActual.m256_f32[LIndex], 0.0);

  LActual := avx_blend_ps256(LA, LB, $AA);
  for LIndex := 0 to 7 do
    AssertEquals('avx_blend_ps256 placeholder keeps a lane ' + IntToStr(LIndex), LA.m256_f32[LIndex], LActual.m256_f32[LIndex], 0.0);

  LActual := avx_permute_ps256(LA, $4E);
  for LIndex := 0 to 7 do
    AssertEquals('avx_permute_ps256 placeholder keeps a lane ' + IntToStr(LIndex), LA.m256_f32[LIndex], LActual.m256_f32[LIndex], 0.0);

  LActual := avx_unpackhi_ps256(LA, LB);
  for LIndex := 0 to 7 do
    AssertEquals('avx_unpackhi_ps256 placeholder keeps a lane ' + IntToStr(LIndex), LA.m256_f32[LIndex], LActual.m256_f32[LIndex], 0.0);

  LExtract := avx_extractf128_ps256(LA, 0);
  for LIndex := 0 to 3 do
    AssertEquals('avx_extractf128_ps256 low lane ' + IntToStr(LIndex), LA.m256_f32[LIndex], LExtract.m128_f32[LIndex], 0.0);

  LExtract := avx_extractf128_ps256(LA, 1);
  for LIndex := 0 to 3 do
    AssertEquals('avx_extractf128_ps256 high lane ' + IntToStr(LIndex), LA.m256_f32[LIndex + 4], LExtract.m128_f32[LIndex], 0.0);

  FillChar(LInsert, SizeOf(LInsert), 0);
  LInsert.m128_f32[0] := 1000.0;
  LInsert.m128_f32[1] := 1001.0;
  LInsert.m128_f32[2] := 1002.0;
  LInsert.m128_f32[3] := 1003.0;

  LActual := avx_insertf128_ps256(LA, LInsert, 1);
  for LIndex := 0 to 3 do
    AssertEquals('avx_insertf128_ps256 keeps low lane ' + IntToStr(LIndex), LA.m256_f32[LIndex], LActual.m256_f32[LIndex], 0.0);
  for LIndex := 0 to 3 do
    AssertEquals('avx_insertf128_ps256 writes high lane ' + IntToStr(LIndex), LInsert.m128_f32[LIndex], LActual.m256_f32[LIndex + 4], 0.0);

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m256i_u32[0] := $80000000;
  LExpected.m256i_u32[1] := $7FFFFFFF;
  LExpected.m256i_u32[2] := $80000001;
  LExpected.m256i_u32[7] := $FFFFFFFF;
  AssertEquals('avx_movemask_ps256 sign bits', 133, avx_movemask_ps256(LExpected));

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m256i_u64[0] := QWord($8000000000000000);
  LExpected.m256i_u64[1] := QWord($7FFFFFFFFFFFFFFF);
  LExpected.m256i_u64[2] := QWord($FFFFFFFFFFFFFFFF);
  AssertEquals('avx_movemask_pd256 sign bits', 5, avx_movemask_pd256(LExpected));

  AssertTrue('avx_testz_ps256 placeholder true', avx_testz_ps256(LA, LB));
  AssertTrue('avx_testc_pd256 placeholder true', avx_testc_pd256(LA, LB));
  AssertFalse('avx_testnzc_ps256 placeholder false', avx_testnzc_ps256(LA, LB));
  AssertFalse('avx_testnzc_pd256 placeholder false', avx_testnzc_pd256(LA, LB));
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_AVX512_AddAndMaskPlaceholderSemantics;
var
  LSrc: TM512;
  LA: TM512;
  LB: TM512;
  LActual: TM512;
  LIndex: Integer;
begin
  FillChar(LSrc, SizeOf(LSrc), 0);
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  for LIndex := 0 to 15 do
  begin
    LSrc.m512_f32[LIndex] := 1.0 + LIndex;
    LA.m512_f32[LIndex] := 10.0 + LIndex;
    LB.m512_f32[LIndex] := 100.0 + LIndex;
  end;

  LActual := avx512_add_ps512(LA, LB);
  for LIndex := 0 to 15 do
    AssertEquals('avx512_add_ps512 lane ' + IntToStr(LIndex), LA.m512_f32[LIndex] + LB.m512_f32[LIndex], LActual.m512_f32[LIndex], 0.0);

  LActual := avx512_mask_add_ps512(LSrc, LA, LB, (1 shl 0) or (1 shl 3) or (1 shl 15));
  for LIndex := 0 to 15 do
    if (LIndex = 0) or (LIndex = 3) or (LIndex = 15) then
      AssertEquals('avx512_mask_add_ps512 masked lane ' + IntToStr(LIndex), LA.m512_f32[LIndex] + LB.m512_f32[LIndex], LActual.m512_f32[LIndex], 0.0)
    else
      AssertEquals('avx512_mask_add_ps512 src lane ' + IntToStr(LIndex), LSrc.m512_f32[LIndex], LActual.m512_f32[LIndex], 0.0);

  LActual := avx512_maskz_add_ps512(LA, LB, (1 shl 1) or (1 shl 2) or (1 shl 14));
  for LIndex := 0 to 15 do
    if (LIndex = 1) or (LIndex = 2) or (LIndex = 14) then
      AssertEquals('avx512_maskz_add_ps512 masked lane ' + IntToStr(LIndex), LA.m512_f32[LIndex] + LB.m512_f32[LIndex], LActual.m512_f32[LIndex], 0.0)
    else
      AssertEquals('avx512_maskz_add_ps512 zero lane ' + IntToStr(LIndex), 0.0, LActual.m512_f32[LIndex], 0.0);
end;

procedure TTestCase_SimdIntrinsicsExperimentalX86.Test_FMA3_FusedAndAlternatingPlaceholderSemantics;
var
  LA128: TM128;
  LB128: TM128;
  LC128: TM128;
  LActual128: TM128;
  LA256: TM256;
  LB256: TM256;
  LC256: TM256;
  LActual256: TM256;
  LIndex: Integer;
begin
  FillChar(LA128, SizeOf(LA128), 0);
  FillChar(LB128, SizeOf(LB128), 0);
  FillChar(LC128, SizeOf(LC128), 0);
  for LIndex := 0 to 3 do
  begin
    LA128.m128_f32[LIndex] := 1.0 + LIndex;
    LB128.m128_f32[LIndex] := 10.0 + LIndex;
    LC128.m128_f32[LIndex] := 100.0 + LIndex;
  end;

  LActual128 := fma3_fmadd_ps(LA128, LB128, LC128);
  for LIndex := 0 to 3 do
    AssertEquals('fma3_fmadd_ps lane ' + IntToStr(LIndex), LA128.m128_f32[LIndex] * LB128.m128_f32[LIndex] + LC128.m128_f32[LIndex], LActual128.m128_f32[LIndex], 0.0);

  LActual128 := fma3_fmadd_ss(LA128, LB128, LC128);
  AssertEquals('fma3_fmadd_ss lane0', LA128.m128_f32[0] * LB128.m128_f32[0] + LC128.m128_f32[0], LActual128.m128_f32[0], 0.0);
  AssertEquals('fma3_fmadd_ss keep lane1', LA128.m128_f32[1], LActual128.m128_f32[1], 0.0);
  AssertEquals('fma3_fmadd_ss keep lane2', LA128.m128_f32[2], LActual128.m128_f32[2], 0.0);
  AssertEquals('fma3_fmadd_ss keep lane3', LA128.m128_f32[3], LActual128.m128_f32[3], 0.0);

  FillChar(LA256, SizeOf(LA256), 0);
  FillChar(LB256, SizeOf(LB256), 0);
  FillChar(LC256, SizeOf(LC256), 0);
  for LIndex := 0 to 7 do
  begin
    LA256.m256_f32[LIndex] := 2.0 + LIndex;
    LB256.m256_f32[LIndex] := 20.0 + LIndex;
    LC256.m256_f32[LIndex] := 200.0 + LIndex;
  end;

  LActual256 := fma3_fmaddsub_ps256(LA256, LB256, LC256);
  for LIndex := 0 to 7 do
    if (LIndex and 1) = 0 then
      AssertEquals('fma3_fmaddsub_ps256 even lane ' + IntToStr(LIndex), LA256.m256_f32[LIndex] * LB256.m256_f32[LIndex] - LC256.m256_f32[LIndex], LActual256.m256_f32[LIndex], 0.0)
    else
      AssertEquals('fma3_fmaddsub_ps256 odd lane ' + IntToStr(LIndex), LA256.m256_f32[LIndex] * LB256.m256_f32[LIndex] + LC256.m256_f32[LIndex], LActual256.m256_f32[LIndex], 0.0);

  for LIndex := 0 to 3 do
  begin
    LA256.m256_f64[LIndex] := 3.0 + LIndex;
    LB256.m256_f64[LIndex] := 30.0 + LIndex;
    LC256.m256_f64[LIndex] := 300.0 + LIndex;
  end;

  LActual256 := fma3_fmsubadd_pd256(LA256, LB256, LC256);
  for LIndex := 0 to 3 do
    if (LIndex and 1) = 0 then
      AssertEquals('fma3_fmsubadd_pd256 even lane ' + IntToStr(LIndex), LA256.m256_f64[LIndex] * LB256.m256_f64[LIndex] + LC256.m256_f64[LIndex], LActual256.m256_f64[LIndex], 0.0)
    else
      AssertEquals('fma3_fmsubadd_pd256 odd lane ' + IntToStr(LIndex), LA256.m256_f64[LIndex] * LB256.m256_f64[LIndex] - LC256.m256_f64[LIndex], LActual256.m256_f64[LIndex], 0.0);
end;

{$ENDIF}
{$ENDIF}

{$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
{$IFDEF CPUX86_64}

procedure InitM128IncrementingBytes(var aValue: TM128; aBase: Byte);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 15 do
    aValue.m128i_u8[LIndex] := Byte(aBase + LIndex);
end;

procedure AssertM128BytesEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m128i_u8[LIndex], aActual.m128i_u8[LIndex]);
end;

function SaturateI32ToI16(const aValue: LongInt): SmallInt; inline;
begin
  if aValue > High(SmallInt) then
    Exit(High(SmallInt));
  if aValue < Low(SmallInt) then
    Exit(Low(SmallInt));
  Result := SmallInt(aValue);
end;

function SaturateI16ToI8(const aValue: SmallInt): ShortInt; inline;
begin
  if aValue > High(ShortInt) then
    Exit(High(ShortInt));
  if aValue < Low(ShortInt) then
    Exit(Low(ShortInt));
  Result := ShortInt(aValue);
end;

function SaturateI16ToU8(const aValue: SmallInt): Byte; inline;
begin
  if aValue < 0 then
    Exit(0);
  if aValue > High(Byte) then
    Exit(High(Byte));
  Result := Byte(aValue);
end;

function ArithmeticShiftRightI16(const aValue: SmallInt; const aShift: Integer): SmallInt;
var
  LBits: Word;
  LStep: Integer;
begin
  if aShift <= 0 then
    Exit(aValue);
  if aShift >= 16 then
  begin
    if aValue < 0 then
      Exit(-1);
    Exit(0);
  end;

  LBits := Word(aValue);
  for LStep := 1 to aShift do
    if (LBits and $8000) <> 0 then
      LBits := (LBits shr 1) or $8000
    else
      LBits := LBits shr 1;
  Result := SmallInt(LBits);
end;

function ArithmeticShiftRightI32(const aValue: LongInt; const aShift: Integer): LongInt;
var
  LBits: DWord;
  LStep: Integer;
begin
  if aShift <= 0 then
    Exit(aValue);
  if aShift >= 32 then
  begin
    if aValue < 0 then
      Exit(-1);
    Exit(0);
  end;

  LBits := DWord(aValue);
  for LStep := 1 to aShift do
    if (LBits and $80000000) <> 0 then
      LBits := (LBits shr 1) or $80000000
    else
      LBits := LBits shr 1;
  Result := LongInt(LBits);
end;

procedure ExpectSlliEpi32(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LShift: Integer;
  LLane: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  if LShift < 32 then
    for LLane := 0 to 3 do
      LExpected.m128i_u32[LLane] := DWord(aValue.m128i_u32[LLane]) shl LShift;

  LActual := simd_slli_epi32(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_slli_epi32 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSlliEpi64(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LShift: Integer;
  LLane: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  if LShift < 64 then
    for LLane := 0 to 1 do
      LExpected.m128i_u64[LLane] := QWord(aValue.m128i_u64[LLane]) shl LShift;

  LActual := simd_slli_epi64(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_slli_epi64 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSrliEpi16(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LShift: Integer;
  LLane: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  if LShift < 16 then
    for LLane := 0 to 7 do
      LExpected.m128i_u16[LLane] := aValue.m128i_u16[LLane] shr LShift;

  LActual := simd_srli_epi16(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_srli_epi16 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSrliEpi32(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LShift: Integer;
  LLane: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  if LShift < 32 then
    for LLane := 0 to 3 do
      LExpected.m128i_u32[LLane] := aValue.m128i_u32[LLane] shr LShift;

  LActual := simd_srli_epi32(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_srli_epi32 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSrliEpi64(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LShift: Integer;
  LLane: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  if LShift < 64 then
    for LLane := 0 to 1 do
      LExpected.m128i_u64[LLane] := aValue.m128i_u64[LLane] shr LShift;

  LActual := simd_srli_epi64(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_srli_epi64 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSraiEpi16(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LShift: Integer;
  LLane: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  for LLane := 0 to 7 do
    LExpected.m128i_i16[LLane] := ArithmeticShiftRightI16(aValue.m128i_i16[LLane], LShift);

  LActual := simd_srai_epi16(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_srai_epi16 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSraiEpi32(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LShift: Integer;
  LLane: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  for LLane := 0 to 3 do
    LExpected.m128i_i32[LLane] := ArithmeticShiftRightI32(aValue.m128i_i32[LLane], LShift);

  LActual := simd_srai_epi32(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_srai_epi32 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSlliSi128(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  if LShift > 0 then
  begin
    if LShift < 16 then
      for LIndex := LShift to 15 do
        LExpected.m128i_u8[LIndex] := aValue.m128i_u8[LIndex - LShift];
  end
  else
    LExpected := aValue;

  LActual := simd_slli_si128(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_slli_si128 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSrliSi128(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LShift := aShift;
  if LShift > 0 then
  begin
    if LShift < 16 then
      for LIndex := 0 to (15 - LShift) do
        LExpected.m128i_u8[LIndex] := aValue.m128i_u8[LIndex + LShift];
  end
  else
    LExpected := aValue;

  LActual := simd_srli_si128(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_srli_si128 shift=' + IntToStr(aShift), LExpected, LActual);
end;

procedure ExpectSraiSi128(aTest: TTestCase; const aValue: TM128; aShift: Byte);
var
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
  LShift: Integer;
  LFill: Byte;
begin
  LFill := 0;
  if (aValue.m128i_u8[15] and $80) <> 0 then
    LFill := $FF;

  FillChar(LExpected, SizeOf(LExpected), LFill);

  LShift := aShift;
  if LShift <= 0 then
    LExpected := aValue
  else if LShift < 16 then
    for LIndex := 0 to (15 - LShift) do
      LExpected.m128i_u8[LIndex] := aValue.m128i_u8[LIndex + LShift];

  LActual := simd_srai_si128(aValue, aShift);
  AssertM128BytesEqual(aTest, 'simd_srai_si128 shift=' + IntToStr(aShift), LExpected, LActual);
end;

type
  TTestCase_X86Sse2ByteShifts = class(TTestCase)
  published
    procedure Test_SlliSrliSi128_AllCounts;
    procedure Test_SraiSi128_SignExtend;
  end;

  TTestCase_X86Sse2AbiBasics = class(TTestCase)
  published
    procedure Test_AddAndCmpeqMovemask;
    procedure Test_BitwiseAndAndnotSemantics;
    procedure Test_SettersAndCastsPreserveLaneOrder;
    procedure Test_FloatArithmeticLaneSemantics;
    procedure Test_LoadStore_Roundtrip;
    procedure Test_PartialLaneLoadStoreMoveSemantics;
    procedure Test_ConversionFamilies_PreserveExpectedLanes;
    procedure Test_SlliEpi16_ShiftCounts;
    procedure Test_IntegerLogicalShiftFamilies_RespectImmediateBounds;
    procedure Test_IntegerArithmeticShiftFamilies_RespectImmediateBounds;
  end;

  TTestCase_X86Sse2PackShuffleBasics = class(TTestCase)
  published
    procedure Test_UnpackLaneInterleaving;
    procedure Test_PackSaturationSemantics;
    procedure Test_ShuffleAndCrossTypeCastSemantics;
    procedure Test_InsertExtractEpi16_UseLow3BitsOfImmediate;
  end;

procedure TTestCase_X86Sse2ByteShifts.Test_SlliSrliSi128_AllCounts;
const
  SHIFTS: array[0..17] of Byte = (
    0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 200
  );
var
  LValue: TM128;
  LIndex: Integer;
begin
  InitM128IncrementingBytes(LValue, 1);
  for LIndex := Low(SHIFTS) to High(SHIFTS) do
  begin
    try
      ExpectSlliSi128(Self, LValue, SHIFTS[LIndex]);
    except
      on E: Exception do
      begin
        Fail('simd_slli_si128 shift=' + IntToStr(SHIFTS[LIndex]) + ' raised ' + E.ClassName + ': ' + E.Message);
        Exit;
      end;
    end;

    try
      ExpectSrliSi128(Self, LValue, SHIFTS[LIndex]);
    except
      on E: Exception do
      begin
        Fail('simd_srli_si128 shift=' + IntToStr(SHIFTS[LIndex]) + ' raised ' + E.ClassName + ': ' + E.Message);
        Exit;
      end;
    end;
  end;
end;

procedure TTestCase_X86Sse2ByteShifts.Test_SraiSi128_SignExtend;
const
  SHIFTS: array[0..7] of Byte = (0, 1, 3, 7, 15, 16, 17, 200);
var
  LPositive: TM128;
  LNegative: TM128;
  LIndex: Integer;
begin
  InitM128IncrementingBytes(LPositive, 5);
  LPositive.m128i_u8[15] := $7F;

  InitM128IncrementingBytes(LNegative, 5);
  LNegative.m128i_u8[15] := $80;

  for LIndex := Low(SHIFTS) to High(SHIFTS) do
  begin
    ExpectSraiSi128(Self, LPositive, SHIFTS[LIndex]);
    ExpectSraiSi128(Self, LNegative, SHIFTS[LIndex]);
  end;
end;

procedure TTestCase_X86Sse2AbiBasics.Test_AddAndCmpeqMovemask;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
  LExpectedMask: Integer;
  LActualMask: Integer;
begin
  InitM128IncrementingBytes(LA, 1);
  InitM128IncrementingBytes(LB, 5);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m128i_u8[LIndex] := Byte((LA.m128i_u8[LIndex] + LB.m128i_u8[LIndex]) and $FF);

  LActual := simd_add_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_add_epi8', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
  begin
    if LA.m128i_u8[LIndex] = LB.m128i_u8[LIndex] then
      LExpected.m128i_u8[LIndex] := $FF
    else
      LExpected.m128i_u8[LIndex] := $00;
  end;

  LActual := simd_cmpeq_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_cmpeq_epi8', LExpected, LActual);

  FillChar(LA, SizeOf(LA), 0);
  for LIndex := 0 to 15 do
    if (LIndex and 1) = 0 then
      LA.m128i_u8[LIndex] := $80
    else
      LA.m128i_u8[LIndex] := $7F;

  LExpectedMask := 0;
  for LIndex := 0 to 15 do
    if (LA.m128i_u8[LIndex] and $80) <> 0 then
      LExpectedMask := LExpectedMask or (1 shl LIndex);

  LActualMask := simd_movemask_epi8(LA);
  AssertEquals('simd_movemask_epi8 mask', LExpectedMask, LActualMask);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_BitwiseAndAndnotSemantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  InitM128IncrementingBytes(LA, $10);
  InitM128IncrementingBytes(LB, $A0);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m128i_u8[LIndex] := LA.m128i_u8[LIndex] and LB.m128i_u8[LIndex];
  LActual := simd_and_si128(LA, LB);
  AssertM128BytesEqual(Self, 'simd_and_si128', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m128i_u8[LIndex] := LA.m128i_u8[LIndex] or LB.m128i_u8[LIndex];
  LActual := simd_or_si128(LA, LB);
  AssertM128BytesEqual(Self, 'simd_or_si128', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m128i_u8[LIndex] := LA.m128i_u8[LIndex] xor LB.m128i_u8[LIndex];
  LActual := simd_xor_si128(LA, LB);
  AssertM128BytesEqual(Self, 'simd_xor_si128', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m128i_u8[LIndex] := (not LA.m128i_u8[LIndex]) and LB.m128i_u8[LIndex];
  LActual := simd_andnot_si128(LA, LB);
  AssertM128BytesEqual(Self, 'simd_andnot_si128', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_SettersAndCastsPreserveLaneOrder;
var
  LValue: TM128;
  LBits: TM128;
begin
  LValue := simd_setr_epi32(11, 22, 33, 44);
  AssertEquals('simd_setr_epi32 lane0', 11, LValue.m128i_i32[0]);
  AssertEquals('simd_setr_epi32 lane1', 22, LValue.m128i_i32[1]);
  AssertEquals('simd_setr_epi32 lane2', 33, LValue.m128i_i32[2]);
  AssertEquals('simd_setr_epi32 lane3', 44, LValue.m128i_i32[3]);

  LValue := simd_set_epi32(11, 22, 33, 44);
  AssertEquals('simd_set_epi32 lane0', 44, LValue.m128i_i32[0]);
  AssertEquals('simd_set_epi32 lane1', 33, LValue.m128i_i32[1]);
  AssertEquals('simd_set_epi32 lane2', 22, LValue.m128i_i32[2]);
  AssertEquals('simd_set_epi32 lane3', 11, LValue.m128i_i32[3]);

  LValue := simd_set1_epi32(-7);
  AssertEquals('simd_set1_epi32 lane0', -7, LValue.m128i_i32[0]);
  AssertEquals('simd_set1_epi32 lane1', -7, LValue.m128i_i32[1]);
  AssertEquals('simd_set1_epi32 lane2', -7, LValue.m128i_i32[2]);
  AssertEquals('simd_set1_epi32 lane3', -7, LValue.m128i_i32[3]);

  LValue := simd_set1_ps(1.5);
  AssertEquals('simd_set1_ps lane0', 1.5, LValue.m128_f32[0], 0.0);
  AssertEquals('simd_set1_ps lane1', 1.5, LValue.m128_f32[1], 0.0);
  AssertEquals('simd_set1_ps lane2', 1.5, LValue.m128_f32[2], 0.0);
  AssertEquals('simd_set1_ps lane3', 1.5, LValue.m128_f32[3], 0.0);
  LBits := simd_castps_si128(LValue);
  AssertM128BytesEqual(Self, 'simd_castps_si128/simd_castsi128_ps roundtrip',
    LValue, simd_castsi128_ps(LBits));

  LValue := simd_set1_pd(2.5);
  AssertEquals('simd_set1_pd lane0', 2.5, LValue.m128d_f64[0], 0.0);
  AssertEquals('simd_set1_pd lane1', 2.5, LValue.m128d_f64[1], 0.0);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_FloatArithmeticLaneSemantics;
var
  LA: TM128;
  LB: TM128;
  LActual: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);

  LA.m128_f32[0] := 1.0;
  LA.m128_f32[1] := -2.0;
  LA.m128_f32[2] := 3.5;
  LA.m128_f32[3] := -4.5;
  LB.m128_f32[0] := 0.5;
  LB.m128_f32[1] := 4.0;
  LB.m128_f32[2] := -1.5;
  LB.m128_f32[3] := 8.0;

  LActual := simd_add_ps(LA, LB);
  AssertEquals('simd_add_ps lane0', 1.5, LActual.m128_f32[0], 0.0);
  AssertEquals('simd_add_ps lane1', 2.0, LActual.m128_f32[1], 0.0);
  AssertEquals('simd_add_ps lane2', 2.0, LActual.m128_f32[2], 0.0);
  AssertEquals('simd_add_ps lane3', 3.5, LActual.m128_f32[3], 0.0);

  LActual := simd_mul_ps(LA, LB);
  AssertEquals('simd_mul_ps lane0', 0.5, LActual.m128_f32[0], 0.0);
  AssertEquals('simd_mul_ps lane1', -8.0, LActual.m128_f32[1], 0.0);
  AssertEquals('simd_mul_ps lane2', -5.25, LActual.m128_f32[2], 0.0);
  AssertEquals('simd_mul_ps lane3', -36.0, LActual.m128_f32[3], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128d_f64[0] := 1.5;
  LA.m128d_f64[1] := -2.0;
  LB.m128d_f64[0] := 4.0;
  LB.m128d_f64[1] := -0.5;

  LActual := simd_add_pd(LA, LB);
  AssertEquals('simd_add_pd lane0', 5.5, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_add_pd lane1', -2.5, LActual.m128d_f64[1], 0.0);

  LActual := simd_mul_pd(LA, LB);
  AssertEquals('simd_mul_pd lane0', 6.0, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_mul_pd lane1', 1.0, LActual.m128d_f64[1], 0.0);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_LoadStore_Roundtrip;
var
  LBytes: array[0..15] of Byte;
  LBytesOut: array[0..15] of Byte;
  LValue: TM128;
  LLoaded: TM128;
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    LBytes[LIndex] := Byte(200 + LIndex);

  LValue := simd_loadu_si128(@LBytes[0]);
  simd_storeu_si128(LBytesOut[0], LValue);

  for LIndex := 0 to 15 do
    AssertEquals('simd_loadu/storeu lane ' + IntToStr(LIndex), LBytes[LIndex], LBytesOut[LIndex]);

  LLoaded := simd_loadu_si128(@LBytesOut[0]);
  AssertM128BytesEqual(Self, 'simd_loadu roundtrip', LValue, LLoaded);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_PartialLaneLoadStoreMoveSemantics;
var
  LPair: array[0..1] of Double;
  LReversed: array[0..1] of Double;
  LScalar: Double;
  LA: TM128;
  LB: TM128;
  LActual: TM128;
begin
  LPair[0] := 1.25;
  LPair[1] := -9.5;
  LActual := simd_loadr_pd(@LPair[0]);
  AssertEquals('simd_loadr_pd lane0', -9.5, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_loadr_pd lane1', 1.25, LActual.m128d_f64[1], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  LA.m128d_f64[0] := 11.0;
  LA.m128d_f64[1] := 22.0;

  LScalar := -33.5;
  LActual := simd_loadh_pd(LA, @LScalar);
  AssertEquals('simd_loadh_pd keep low lane', 11.0, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_loadh_pd replace high lane', -33.5, LActual.m128d_f64[1], 0.0);

  LScalar := 44.75;
  LActual := simd_loadl_pd(LA, @LScalar);
  AssertEquals('simd_loadl_pd replace low lane', 44.75, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_loadl_pd keep high lane', 22.0, LActual.m128d_f64[1], 0.0);

  LScalar := 123.0;
  simd_storeh_pd(LScalar, LA);
  AssertEquals('simd_storeh_pd writes high lane', 22.0, LScalar, 0.0);

  LScalar := 456.0;
  simd_storel_pd(LScalar, LA);
  AssertEquals('simd_storel_pd writes low lane', 11.0, LScalar, 0.0);

  LScalar := -7.0;
  LActual := simd_load_sd(@LScalar);
  AssertEquals('simd_load_sd low lane', -7.0, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_load_sd zero high lane', 0.0, LActual.m128d_f64[1], 0.0);

  LScalar := 999.0;
  simd_store_sd(LScalar, LA);
  AssertEquals('simd_store_sd writes low lane', 11.0, LScalar, 0.0);

  FillChar(LB, SizeOf(LB), 0);
  LB.m128d_f64[0] := 100.5;
  LB.m128d_f64[1] := 200.5;
  LActual := simd_move_sd(LA, LB);
  AssertEquals('simd_move_sd low from b', 100.5, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_move_sd keep high from a', 22.0, LActual.m128d_f64[1], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  LA.m128i_u64[0] := QWord($0123456789ABCDEF);
  LA.m128i_u64[1] := QWord($FEDCBA9876543210);
  LActual := simd_move_epi64(LA);
  AssertEquals('simd_move_epi64 low lane', Int64(LA.m128i_u64[0]), Int64(LActual.m128i_u64[0]));
  AssertEquals('simd_move_epi64 zero high lane', Int64(0), Int64(LActual.m128i_u64[1]));

  LPair[0] := 5.0;
  LPair[1] := 6.0;
  LReversed[0] := 0.0;
  LReversed[1] := 0.0;
  simd_storer_pd(LReversed, simd_loadu_pd(@LPair[0]));
  AssertEquals('simd_storer_pd lane0', 6.0, LReversed[0], 0.0);
  AssertEquals('simd_storer_pd lane1', 5.0, LReversed[1], 0.0);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_ConversionFamilies_PreserveExpectedLanes;
var
  LInts: TM128;
  LFloats: TM128;
  LDoubles: TM128;
  LA: TM128;
  LB: TM128;
  LActual: TM128;
begin
  FillChar(LInts, SizeOf(LInts), 0);
  LInts.m128i_i32[0] := -12;
  LInts.m128i_i32[1] := 345678;
  LInts.m128i_i32[2] := -9;
  LInts.m128i_i32[3] := 77;

  LActual := simd_cvtepi32_pd(LInts);
  AssertEquals('simd_cvtepi32_pd lane0', -12.0, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_cvtepi32_pd lane1', 345678.0, LActual.m128d_f64[1], 0.0);

  LActual := simd_cvtepi32_ps(LInts);
  AssertEquals('simd_cvtepi32_ps lane0', -12.0, LActual.m128_f32[0], 0.0);
  AssertEquals('simd_cvtepi32_ps lane1', 345678.0, LActual.m128_f32[1], 0.0);
  AssertEquals('simd_cvtepi32_ps lane2', -9.0, LActual.m128_f32[2], 0.0);
  AssertEquals('simd_cvtepi32_ps lane3', 77.0, LActual.m128_f32[3], 0.0);

  FillChar(LFloats, SizeOf(LFloats), 0);
  LFloats.m128_f32[0] := 1.25;
  LFloats.m128_f32[1] := -2.5;
  LFloats.m128_f32[2] := 123.0;
  LFloats.m128_f32[3] := 456.0;

  LActual := simd_cvtps_pd(LFloats);
  AssertEquals('simd_cvtps_pd lane0', 1.25, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_cvtps_pd lane1', -2.5, LActual.m128d_f64[1], 0.0);

  FillChar(LDoubles, SizeOf(LDoubles), 0);
  LDoubles.m128d_f64[0] := 7.5;
  LDoubles.m128d_f64[1] := -8.25;

  LActual := simd_cvtpd_ps(LDoubles);
  AssertEquals('simd_cvtpd_ps lane0', 7.5, LActual.m128_f32[0], 0.0);
  AssertEquals('simd_cvtpd_ps lane1', -8.25, LActual.m128_f32[1], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  LA.m128_f32[0] := 10.0;
  LA.m128_f32[1] := 20.0;
  LA.m128_f32[2] := 30.0;
  LA.m128_f32[3] := 40.0;
  FillChar(LB, SizeOf(LB), 0);
  LB.m128d_f64[0] := 3.75;
  LB.m128d_f64[1] := 999.0;
  LActual := simd_cvtsd_ss(LA, LB);
  AssertEquals('simd_cvtsd_ss lane0', 3.75, LActual.m128_f32[0], 0.0);
  AssertEquals('simd_cvtsd_ss keep lane1', 20.0, LActual.m128_f32[1], 0.0);
  AssertEquals('simd_cvtsd_ss keep lane2', 30.0, LActual.m128_f32[2], 0.0);
  AssertEquals('simd_cvtsd_ss keep lane3', 40.0, LActual.m128_f32[3], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  LA.m128d_f64[0] := 10.0;
  LA.m128d_f64[1] := 22.5;
  FillChar(LB, SizeOf(LB), 0);
  LB.m128_f32[0] := -6.25;
  LB.m128_f32[1] := 777.0;
  LActual := simd_cvtss_sd(LA, LB);
  AssertEquals('simd_cvtss_sd lane0', -6.25, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_cvtss_sd keep high lane', 22.5, LActual.m128d_f64[1], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  LA.m128d_f64[0] := 1.5;
  LA.m128d_f64[1] := 88.0;
  LActual := simd_cvtsi32_sd(LA, -77);
  AssertEquals('simd_cvtsi32_sd lane0', -77.0, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_cvtsi32_sd keep high lane', 88.0, LActual.m128d_f64[1], 0.0);

  LActual := simd_cvtsi64_sd(LA, 1234567890123);
  AssertEquals('simd_cvtsi64_sd lane0', 1234567890123.0, LActual.m128d_f64[0], 0.0);
  AssertEquals('simd_cvtsi64_sd keep high lane', 88.0, LActual.m128d_f64[1], 0.0);

  LActual := simd_cvtsi32_si128(-123456);
  AssertEquals('simd_cvtsi32_si128 low lane', -123456, LActual.m128i_i32[0]);
  AssertEquals('simd_cvtsi32_si128 zero lane1', 0, LActual.m128i_i32[1]);
  AssertEquals('simd_cvtsi32_si128 zero lane2', 0, LActual.m128i_i32[2]);
  AssertEquals('simd_cvtsi32_si128 zero lane3', 0, LActual.m128i_i32[3]);

  LActual := simd_cvtsi64_si128(Int64(-1234567890123));
  AssertEquals('simd_cvtsi64_si128 low qword', Int64(-1234567890123), LActual.m128i_i64[0]);
  AssertEquals('simd_cvtsi64_si128 zero high qword', Int64(0), LActual.m128i_i64[1]);

  FillChar(LInts, SizeOf(LInts), 0);
  LInts.m128i_i32[0] := -99;
  LInts.m128i_i32[1] := 777;
  LInts.m128i_i64[0] := Int64(-9876543210);
  AssertEquals('simd_cvtsi128_si32 low dword', LInts.m128i_i32[0], simd_cvtsi128_si32(LInts));
  AssertEquals('simd_cvtsi128_si64 low qword', Int64(-9876543210), simd_cvtsi128_si64(LInts));
end;

procedure TTestCase_X86Sse2AbiBasics.Test_SlliEpi16_ShiftCounts;
const
  SHIFTS: array[0..6] of Byte = (0, 1, 7, 15, 16, 17, 200);
var
  LValue: TM128;
  LExpected: TM128;
  LActual: TM128;
  LShiftIndex: Integer;
  LLane: Integer;
  LShift: Integer;
  LWord: Word;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  for LLane := 0 to 7 do
    LValue.m128i_u16[LLane] := Word(LLane * 100 + 3);

  for LShiftIndex := Low(SHIFTS) to High(SHIFTS) do
  begin
    LShift := SHIFTS[LShiftIndex];
    FillChar(LExpected, SizeOf(LExpected), 0);

    if LShift < 16 then
      for LLane := 0 to 7 do
      begin
        LWord := LValue.m128i_u16[LLane];
        LExpected.m128i_u16[LLane] := Word((DWord(LWord) shl LShift) and $FFFF);
      end;

    LActual := simd_slli_epi16(LValue, SHIFTS[LShiftIndex]);
    AssertM128BytesEqual(Self, 'simd_slli_epi16 shift=' + IntToStr(SHIFTS[LShiftIndex]), LExpected, LActual);
  end;
end;

procedure TTestCase_X86Sse2AbiBasics.Test_IntegerLogicalShiftFamilies_RespectImmediateBounds;
const
  SHIFTS16: array[0..6] of Byte = (0, 1, 7, 15, 16, 17, 200);
  SHIFTS32: array[0..7] of Byte = (0, 1, 15, 16, 31, 32, 33, 200);
  SHIFTS64: array[0..7] of Byte = (0, 1, 31, 32, 63, 64, 65, 200);
var
  LValue16: TM128;
  LValue32: TM128;
  LValue64: TM128;
  LIndex: Integer;
begin
  FillChar(LValue16, SizeOf(LValue16), 0);
  for LIndex := 0 to 7 do
    LValue16.m128i_u16[LIndex] := Word((LIndex * 257) xor $A55A);

  FillChar(LValue32, SizeOf(LValue32), 0);
  LValue32.m128i_u32[0] := DWord($89ABCDEF);
  LValue32.m128i_u32[1] := DWord($01234567);
  LValue32.m128i_u32[2] := DWord($F0F0CC33);
  LValue32.m128i_u32[3] := DWord($13579BDF);

  FillChar(LValue64, SizeOf(LValue64), 0);
  LValue64.m128i_u64[0] := QWord($0123456789ABCDEF);
  LValue64.m128i_u64[1] := QWord($F0E1D2C3B4A59687);

  for LIndex := Low(SHIFTS16) to High(SHIFTS16) do
  begin
    ExpectSrliEpi16(Self, LValue16, SHIFTS16[LIndex]);
  end;

  for LIndex := Low(SHIFTS32) to High(SHIFTS32) do
  begin
    ExpectSlliEpi32(Self, LValue32, SHIFTS32[LIndex]);
    ExpectSrliEpi32(Self, LValue32, SHIFTS32[LIndex]);
  end;

  for LIndex := Low(SHIFTS64) to High(SHIFTS64) do
  begin
    ExpectSlliEpi64(Self, LValue64, SHIFTS64[LIndex]);
    ExpectSrliEpi64(Self, LValue64, SHIFTS64[LIndex]);
  end;
end;

procedure TTestCase_X86Sse2AbiBasics.Test_IntegerArithmeticShiftFamilies_RespectImmediateBounds;
const
  SHIFTS16: array[0..6] of Byte = (0, 1, 7, 15, 16, 17, 200);
  SHIFTS32: array[0..7] of Byte = (0, 1, 15, 16, 31, 32, 33, 200);
var
  LValue16: TM128;
  LValue32: TM128;
  LIndex: Integer;
begin
  FillChar(LValue16, SizeOf(LValue16), 0);
  LValue16.m128i_i16[0] := -32768;
  LValue16.m128i_i16[1] := -12345;
  LValue16.m128i_i16[2] := -1;
  LValue16.m128i_i16[3] := 0;
  LValue16.m128i_i16[4] := 1;
  LValue16.m128i_i16[5] := 12345;
  LValue16.m128i_i16[6] := 16384;
  LValue16.m128i_i16[7] := 32767;

  FillChar(LValue32, SizeOf(LValue32), 0);
  LValue32.m128i_i32[0] := LongInt($80000000);
  LValue32.m128i_i32[1] := -123456789;
  LValue32.m128i_i32[2] := 123456789;
  LValue32.m128i_i32[3] := LongInt($7FFFFFFF);

  for LIndex := Low(SHIFTS16) to High(SHIFTS16) do
    ExpectSraiEpi16(Self, LValue16, SHIFTS16[LIndex]);

  for LIndex := Low(SHIFTS32) to High(SHIFTS32) do
    ExpectSraiEpi32(Self, LValue32, SHIFTS32[LIndex]);
end;

procedure TTestCase_X86Sse2PackShuffleBasics.Test_UnpackLaneInterleaving;
var
  LA: TM128;
  LB: TM128;
  LLo: TM128;
  LHi: TM128;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);

  for LIndex := 0 to 15 do
  begin
    LA.m128i_i8[LIndex] := LIndex;
    LB.m128i_i8[LIndex] := 60 + LIndex;
  end;

  LLo := simd_unpacklo_epi8(LA, LB);
  LHi := simd_unpackhi_epi8(LA, LB);

  for LIndex := 0 to 7 do
  begin
    AssertEquals('unpacklo_epi8.a[' + IntToStr(LIndex) + ']',
      LA.m128i_i8[LIndex], LLo.m128i_i8[LIndex * 2]);
    AssertEquals('unpacklo_epi8.b[' + IntToStr(LIndex) + ']',
      LB.m128i_i8[LIndex], LLo.m128i_i8[(LIndex * 2) + 1]);
    AssertEquals('unpackhi_epi8.a[' + IntToStr(LIndex) + ']',
      LA.m128i_i8[8 + LIndex], LHi.m128i_i8[LIndex * 2]);
    AssertEquals('unpackhi_epi8.b[' + IntToStr(LIndex) + ']',
      LB.m128i_i8[8 + LIndex], LHi.m128i_i8[(LIndex * 2) + 1]);
  end;

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  for LIndex := 0 to 3 do
  begin
    LA.m128i_i32[LIndex] := LIndex;
    LB.m128i_i32[LIndex] := 100 + LIndex;
  end;

  LLo := simd_unpacklo_epi32(LA, LB);
  LHi := simd_unpackhi_epi32(LA, LB);

  AssertEquals('unpacklo_epi32[0]', 0, LLo.m128i_i32[0]);
  AssertEquals('unpacklo_epi32[1]', 100, LLo.m128i_i32[1]);
  AssertEquals('unpacklo_epi32[2]', 1, LLo.m128i_i32[2]);
  AssertEquals('unpacklo_epi32[3]', 101, LLo.m128i_i32[3]);

  AssertEquals('unpackhi_epi32[0]', 2, LHi.m128i_i32[0]);
  AssertEquals('unpackhi_epi32[1]', 102, LHi.m128i_i32[1]);
  AssertEquals('unpackhi_epi32[2]', 3, LHi.m128i_i32[2]);
  AssertEquals('unpackhi_epi32[3]', 103, LHi.m128i_i32[3]);
end;

procedure TTestCase_X86Sse2PackShuffleBasics.Test_PackSaturationSemantics;
var
  LA: TM128;
  LB: TM128;
  LResult: TM128;
  LExpectedI16: array[0..7] of SmallInt;
  LExpectedI8: array[0..15] of ShortInt;
  LExpectedU8: array[0..15] of Byte;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);

  LA.m128i_i32[0] := -40000;
  LA.m128i_i32[1] := -32768;
  LA.m128i_i32[2] := -1;
  LA.m128i_i32[3] := 0;
  LB.m128i_i32[0] := 1;
  LB.m128i_i32[1] := 32767;
  LB.m128i_i32[2] := 32768;
  LB.m128i_i32[3] := 60000;

  for LIndex := 0 to 3 do
    LExpectedI16[LIndex] := SaturateI32ToI16(LA.m128i_i32[LIndex]);
  for LIndex := 0 to 3 do
    LExpectedI16[4 + LIndex] := SaturateI32ToI16(LB.m128i_i32[LIndex]);

  LResult := simd_packs_epi32(LA, LB);
  for LIndex := 0 to 7 do
    AssertEquals('packs_epi32[' + IntToStr(LIndex) + ']',
      LExpectedI16[LIndex], LResult.m128i_i16[LIndex]);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  for LIndex := 0 to 7 do
  begin
    LA.m128i_i16[LIndex] := (LIndex * 40) - 180;
    LB.m128i_i16[LIndex] := 300 - (LIndex * 35);
  end;

  for LIndex := 0 to 7 do
    LExpectedI8[LIndex] := SaturateI16ToI8(LA.m128i_i16[LIndex]);
  for LIndex := 0 to 7 do
    LExpectedI8[8 + LIndex] := SaturateI16ToI8(LB.m128i_i16[LIndex]);

  for LIndex := 0 to 7 do
    LExpectedU8[LIndex] := SaturateI16ToU8(LA.m128i_i16[LIndex]);
  for LIndex := 0 to 7 do
    LExpectedU8[8 + LIndex] := SaturateI16ToU8(LB.m128i_i16[LIndex]);

  LResult := simd_packs_epi16(LA, LB);
  for LIndex := 0 to 15 do
    AssertEquals('packs_epi16[' + IntToStr(LIndex) + ']',
      LExpectedI8[LIndex], LResult.m128i_i8[LIndex]);

  LResult := simd_packus_epi16(LA, LB);
  for LIndex := 0 to 15 do
    AssertEquals('packus_epi16[' + IntToStr(LIndex) + ']',
      LExpectedU8[LIndex], LResult.m128i_u8[LIndex]);
end;

procedure TTestCase_X86Sse2PackShuffleBasics.Test_ShuffleAndCrossTypeCastSemantics;
var
  LA: TM128;
  LB: TM128;
  LValue: TM128;
  LBits: TM128;
  LShuffled: TM128;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  LA.m128i_i32[0] := 10;
  LA.m128i_i32[1] := 20;
  LA.m128i_i32[2] := 30;
  LA.m128i_i32[3] := 40;

  LShuffled := simd_shuffle_epi32(LA, $1B);
  AssertEquals('simd_shuffle_epi32 lane0', 40, LShuffled.m128i_i32[0]);
  AssertEquals('simd_shuffle_epi32 lane1', 30, LShuffled.m128i_i32[1]);
  AssertEquals('simd_shuffle_epi32 lane2', 20, LShuffled.m128i_i32[2]);
  AssertEquals('simd_shuffle_epi32 lane3', 10, LShuffled.m128i_i32[3]);

  FillChar(LA, SizeOf(LA), 0);
  for LIndex := 0 to 7 do
    LA.m128i_u16[LIndex] := 1 + LIndex;

  LShuffled := simd_shufflelo_epi16(LA, $1B);
  AssertEquals('simd_shufflelo_epi16 lane0', 4, LShuffled.m128i_u16[0]);
  AssertEquals('simd_shufflelo_epi16 lane1', 3, LShuffled.m128i_u16[1]);
  AssertEquals('simd_shufflelo_epi16 lane2', 2, LShuffled.m128i_u16[2]);
  AssertEquals('simd_shufflelo_epi16 lane3', 1, LShuffled.m128i_u16[3]);
  AssertEquals('simd_shufflelo_epi16 high keep lane4', 5, LShuffled.m128i_u16[4]);
  AssertEquals('simd_shufflelo_epi16 high keep lane7', 8, LShuffled.m128i_u16[7]);

  LShuffled := simd_shufflehi_epi16(LA, $1B);
  AssertEquals('simd_shufflehi_epi16 low keep lane0', 1, LShuffled.m128i_u16[0]);
  AssertEquals('simd_shufflehi_epi16 low keep lane3', 4, LShuffled.m128i_u16[3]);
  AssertEquals('simd_shufflehi_epi16 lane4', 8, LShuffled.m128i_u16[4]);
  AssertEquals('simd_shufflehi_epi16 lane5', 7, LShuffled.m128i_u16[5]);
  AssertEquals('simd_shufflehi_epi16 lane6', 6, LShuffled.m128i_u16[6]);
  AssertEquals('simd_shufflehi_epi16 lane7', 5, LShuffled.m128i_u16[7]);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128d_f64[0] := 1.5;
  LA.m128d_f64[1] := 2.5;
  LB.m128d_f64[0] := 10.5;
  LB.m128d_f64[1] := 20.5;

  LShuffled := simd_shuffle_pd(LA, LB, 2);
  AssertEquals('simd_shuffle_pd lane0', 1.5, LShuffled.m128d_f64[0], 0.0);
  AssertEquals('simd_shuffle_pd lane1', 20.5, LShuffled.m128d_f64[1], 0.0);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m128_f32[0] := 1.0;
  LA.m128_f32[1] := 2.0;
  LA.m128_f32[2] := 3.0;
  LA.m128_f32[3] := 4.0;
  LB.m128_f32[0] := 5.0;
  LB.m128_f32[1] := 6.0;
  LB.m128_f32[2] := 7.0;
  LB.m128_f32[3] := 8.0;

  LShuffled := simd_shuffle_ps(LA, LB, $E4);
  AssertEquals('simd_shuffle_ps lane0', 1.0, LShuffled.m128_f32[0], 0.0);
  AssertEquals('simd_shuffle_ps lane1', 2.0, LShuffled.m128_f32[1], 0.0);
  AssertEquals('simd_shuffle_ps lane2', 7.0, LShuffled.m128_f32[2], 0.0);
  AssertEquals('simd_shuffle_ps lane3', 8.0, LShuffled.m128_f32[3], 0.0);

  InitM128IncrementingBytes(LValue, $30);
  LBits := simd_castpd_si128(LValue);
  AssertM128BytesEqual(Self, 'simd_castpd_si128/simd_castsi128_pd roundtrip',
    LValue, simd_castsi128_pd(LBits));

  LBits := simd_castpd_ps(LValue);
  AssertM128BytesEqual(Self, 'simd_castpd_ps/simd_castps_pd roundtrip',
    LValue, simd_castps_pd(LBits));
end;

procedure TTestCase_X86Sse2PackShuffleBasics.Test_InsertExtractEpi16_UseLow3BitsOfImmediate;
var
  LValue: TM128;
  LInserted: TM128;
  LLane: Integer;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  for LLane := 0 to 7 do
    LValue.m128i_u16[LLane] := Word((LLane + 1) * 100);

  LInserted := simd_insert_epi16(LValue, $ABCD, 9);
  for LLane := 0 to 7 do
    if LLane = 1 then
      AssertEquals('simd_insert_epi16 wrap lane1', $ABCD, LInserted.m128i_u16[LLane])
    else
      AssertEquals('simd_insert_epi16 keep lane ' + IntToStr(LLane),
        LValue.m128i_u16[LLane], LInserted.m128i_u16[LLane]);

  LInserted := simd_insert_epi16(LValue, $1234, 15);
  for LLane := 0 to 7 do
    if LLane = 7 then
      AssertEquals('simd_insert_epi16 wrap lane7', $1234, LInserted.m128i_u16[LLane])
    else
      AssertEquals('simd_insert_epi16 keep lane after wrap ' + IntToStr(LLane),
        LValue.m128i_u16[LLane], LInserted.m128i_u16[LLane]);

  AssertEquals('simd_extract_epi16 imm9->lane1', LValue.m128i_u16[1],
    simd_extract_epi16(LValue, 9));
  AssertEquals('simd_extract_epi16 imm15->lane7', LValue.m128i_u16[7],
    simd_extract_epi16(LValue, 15));
  AssertEquals('simd_extract_epi16 imm200->lane0', LValue.m128i_u16[0],
    simd_extract_epi16(LValue, 200));
end;

{$ENDIF}
{$ENDIF}

initialization
  RegisterTest(TTestCase_SimdIntrinsicsExperimental);
  {$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  {$IFDEF CPUX86_64}
  RegisterTest(TTestCase_SimdIntrinsicsExperimentalX86);
  RegisterTest(TTestCase_X86Sse2ByteShifts);
  RegisterTest(TTestCase_X86Sse2AbiBasics);
  RegisterTest(TTestCase_X86Sse2PackShuffleBasics);
  {$ENDIF}
  {$ENDIF}

end.
