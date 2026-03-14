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

{$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
{$IFDEF CPUX86_64}
uses
  fafafa.core.simd.intrinsics.x86.sse2;
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
    procedure Test_LoadStore_Roundtrip;
    procedure Test_SlliEpi16_ShiftCounts;
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

{$ENDIF}
{$ENDIF}

initialization
  RegisterTest(TTestCase_SimdIntrinsicsExperimental);
  {$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  {$IFDEF CPUX86_64}
  RegisterTest(TTestCase_X86Sse2ByteShifts);
  RegisterTest(TTestCase_X86Sse2AbiBasics);
  {$ENDIF}
  {$ENDIF}

end.
