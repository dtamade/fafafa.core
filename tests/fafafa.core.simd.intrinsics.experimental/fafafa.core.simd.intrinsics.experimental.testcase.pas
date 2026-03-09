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

implementation

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

initialization
  RegisterTest(TTestCase_SimdIntrinsicsExperimental);

end.
