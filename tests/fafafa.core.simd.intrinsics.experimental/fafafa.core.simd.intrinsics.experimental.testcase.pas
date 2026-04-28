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
    procedure Test_Experimental_AES_Semantics;
    procedure Test_Experimental_SHA_Semantics;
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

procedure LoadM128Bytes(var aValue: TM128; const aBytes: array of Byte);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to High(aBytes) do
    aValue.m128i_u8[LIndex] := aBytes[LIndex];
end;

procedure LoadM128Words(var aValue: TM128; const aWords: array of DWord);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to High(aWords) do
    aValue.m128i_u32[LIndex] := aWords[LIndex];
end;

procedure AssertM128BytesEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m128i_u8[LIndex], aActual.m128i_u8[LIndex]);
end;

procedure AssertM128WordsEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m128i_u32[LIndex], aActual.m128i_u32[LIndex]);
end;

function Add32(aLeft, aRight: DWord): DWord; inline;
begin
  Result := DWord(QWord(aLeft) + QWord(aRight));
end;

function Rol32(aValue: DWord; aCount: Byte): DWord; inline;
var
  LCount: Integer;
begin
  LCount := aCount and 31;
  if LCount = 0 then
    Exit(aValue);
  Result := DWord((QWord(aValue) shl LCount) or (QWord(aValue) shr (32 - LCount)));
end;

function Ror32(aValue: DWord; aCount: Byte): DWord; inline;
var
  LCount: Integer;
begin
  LCount := aCount and 31;
  if LCount = 0 then
    Exit(aValue);
  Result := DWord((QWord(aValue) shr LCount) or (QWord(aValue) shl (32 - LCount)));
end;

function SHA1Choose(aB, aC, aD: DWord): DWord; inline;
begin
  Result := (aB and aC) xor ((not aB) and aD);
end;

function SHA1Parity(aB, aC, aD: DWord): DWord; inline;
begin
  Result := aB xor aC xor aD;
end;

function SHA1Majority(aB, aC, aD: DWord): DWord; inline;
begin
  Result := (aB and aC) xor (aB and aD) xor (aC and aD);
end;

function SHA256Choose(aE, aF, aG: DWord): DWord; inline;
begin
  Result := (aE and aF) xor ((not aE) and aG);
end;

function SHA256Majority(aA, aB, aC: DWord): DWord; inline;
begin
  Result := (aA and aB) xor (aA and aC) xor (aB and aC);
end;

function SHA256SmallSigma0(aValue: DWord): DWord; inline;
begin
  Result := Ror32(aValue, 7) xor Ror32(aValue, 18) xor (aValue shr 3);
end;

function SHA256SmallSigma1(aValue: DWord): DWord; inline;
begin
  Result := Ror32(aValue, 17) xor Ror32(aValue, 19) xor (aValue shr 10);
end;

function SHA256BigSigma0(aValue: DWord): DWord; inline;
begin
  Result := Ror32(aValue, 2) xor Ror32(aValue, 13) xor Ror32(aValue, 22);
end;

function SHA256BigSigma1(aValue: DWord): DWord; inline;
begin
  Result := Ror32(aValue, 6) xor Ror32(aValue, 11) xor Ror32(aValue, 25);
end;

function ReferenceSha1Msg1(const aA, aB: TM128): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128i_u32[0] := aA.m128i_u32[0] xor aB.m128i_u32[2];
  Result.m128i_u32[1] := aA.m128i_u32[1] xor aB.m128i_u32[3];
  Result.m128i_u32[2] := aA.m128i_u32[2] xor aA.m128i_u32[0];
  Result.m128i_u32[3] := aA.m128i_u32[3] xor aA.m128i_u32[1];
end;

function ReferenceSha1Msg2(const aA, aB: TM128): TM128;
var
  LT3: DWord;
begin
  FillChar(Result, SizeOf(Result), 0);
  LT3 := Rol32(aA.m128i_u32[3] xor aB.m128i_u32[2], 1);
  Result.m128i_u32[0] := Rol32(LT3 xor aA.m128i_u32[0], 1);
  Result.m128i_u32[1] := Rol32(aA.m128i_u32[1] xor aB.m128i_u32[0], 1);
  Result.m128i_u32[2] := Rol32(aA.m128i_u32[2] xor aB.m128i_u32[1], 1);
  Result.m128i_u32[3] := LT3;
end;

function ReferenceSha1Nexte(const aA, aB: TM128): TM128;
begin
  Result := aB;
  Result.m128i_u32[3] := Add32(aB.m128i_u32[3], Rol32(aA.m128i_u32[3], 30));
end;

function ReferenceSha1RoundLogic(aFunc: Byte; aB, aC, aD: DWord): DWord; inline;
begin
  case (aFunc and 3) of
    0:
      Result := SHA1Choose(aB, aC, aD);
    1, 3:
      Result := SHA1Parity(aB, aC, aD);
  else
    Result := SHA1Majority(aB, aC, aD);
  end;
end;

function ReferenceSha1RoundConstant(aFunc: Byte): DWord; inline;
begin
  case (aFunc and 3) of
    0:
      Result := DWord($5A827999);
    1:
      Result := DWord($6ED9EBA1);
    2:
      Result := DWord($8F1BBCDC);
  else
    Result := DWord($CA62C1D6);
  end;
end;

function ReferenceSha1Rnds4(const aA, aB: TM128; aFunc: Byte): TM128;
var
  LA: DWord;
  LB: DWord;
  LC: DWord;
  LD: DWord;
  LE: DWord;
  LTemp: DWord;
  LRound: Integer;
  LWords: array[0..3] of DWord;
  LRoundLogic: DWord;
  LRoundConstant: DWord;
begin
  FillChar(Result, SizeOf(Result), 0);
  LWords[0] := aB.m128i_u32[3];
  LWords[1] := aB.m128i_u32[2];
  LWords[2] := aB.m128i_u32[1];
  LWords[3] := aB.m128i_u32[0];

  LD := aA.m128i_u32[0];
  LC := aA.m128i_u32[1];
  LB := aA.m128i_u32[2];
  LA := aA.m128i_u32[3];
  LE := 0;
  LRoundConstant := ReferenceSha1RoundConstant(aFunc);

  for LRound := 0 to 3 do
  begin
    LRoundLogic := ReferenceSha1RoundLogic(aFunc, LB, LC, LD);
    LTemp := Add32(Rol32(LA, 5), LRoundLogic);
    if LRound = 0 then
      LTemp := Add32(LTemp, LWords[LRound])
    else
      LTemp := Add32(LTemp, Add32(LE, LWords[LRound]));
    LTemp := Add32(LTemp, LRoundConstant);

    LE := LD;
    LD := LC;
    LC := Rol32(LB, 30);
    LB := LA;
    LA := LTemp;
  end;

  Result.m128i_u32[0] := LD;
  Result.m128i_u32[1] := LC;
  Result.m128i_u32[2] := LB;
  Result.m128i_u32[3] := LA;
end;

function ReferenceSha256Msg1(const aA, aB: TM128): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128i_u32[0] := Add32(SHA256SmallSigma0(aA.m128i_u32[1]), aA.m128i_u32[0]);
  Result.m128i_u32[1] := Add32(SHA256SmallSigma0(aA.m128i_u32[2]), aA.m128i_u32[1]);
  Result.m128i_u32[2] := Add32(SHA256SmallSigma0(aA.m128i_u32[3]), aA.m128i_u32[2]);
  Result.m128i_u32[3] := Add32(SHA256SmallSigma0(aB.m128i_u32[0]), aA.m128i_u32[3]);
end;

function ReferenceSha256Msg2(const aA, aB: TM128): TM128;
var
  LO0: DWord;
  LO1: DWord;
begin
  FillChar(Result, SizeOf(Result), 0);
  LO0 := Add32(SHA256SmallSigma1(aB.m128i_u32[2]), aA.m128i_u32[0]);
  LO1 := Add32(SHA256SmallSigma1(aB.m128i_u32[3]), aA.m128i_u32[1]);
  Result.m128i_u32[0] := LO0;
  Result.m128i_u32[1] := LO1;
  Result.m128i_u32[2] := Add32(SHA256SmallSigma1(LO0), aA.m128i_u32[2]);
  Result.m128i_u32[3] := Add32(SHA256SmallSigma1(LO1), aA.m128i_u32[3]);
end;

function ReferenceSha256Rnds2(const aA, aB, aK: TM128): TM128;
var
  LA: DWord;
  LB: DWord;
  LC: DWord;
  LD: DWord;
  LE: DWord;
  LF: DWord;
  LG: DWord;
  LH: DWord;
  LT1: DWord;
  LT2: DWord;
  LRound: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  LH := aA.m128i_u32[0];
  LG := aA.m128i_u32[1];
  LD := aA.m128i_u32[2];
  LC := aA.m128i_u32[3];
  LF := aB.m128i_u32[0];
  LE := aB.m128i_u32[1];
  LB := aB.m128i_u32[2];
  LA := aB.m128i_u32[3];

  for LRound := 0 to 1 do
  begin
    LT1 := Add32(LH, SHA256BigSigma1(LE));
    LT1 := Add32(LT1, SHA256Choose(LE, LF, LG));
    LT1 := Add32(LT1, aK.m128i_u32[LRound]);
    LT2 := Add32(SHA256BigSigma0(LA), SHA256Majority(LA, LB, LC));

    LH := LG;
    LG := LF;
    LF := LE;
    LE := Add32(LD, LT1);
    LD := LC;
    LC := LB;
    LB := LA;
    LA := Add32(LT1, LT2);
  end;

  Result.m128i_u32[0] := LF;
  Result.m128i_u32[1] := LE;
  Result.m128i_u32[2] := LB;
  Result.m128i_u32[3] := LA;
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

procedure TTestCase_SimdIntrinsicsExperimental.Test_Experimental_AES_Semantics;
var
  LData, LKey, LExpected, LActual: TM128;
begin
  {$IFNDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  Exit;
  {$ENDIF}

  LoadM128Bytes(LData, [
    $00, $11, $22, $33, $44, $55, $66, $77,
    $88, $99, $AA, $BB, $CC, $DD, $EE, $FF
  ]);
  LoadM128Bytes(LKey, [
    $0F, $1E, $2D, $3C, $4B, $5A, $69, $78,
    $87, $96, $A5, $B4, $C3, $D2, $E1, $F0
  ]);

  LoadM128Bytes(LExpected, [
    $6C, $67, $CB, $E5, $BF, $3D, $92, $0E,
    $2A, $90, $99, $40, $11, $39, $6B, $53
  ]);
  LActual := aes_aesenc_si128(LData, LKey);
  AssertM128BytesEqual(Self, 'aes_aesenc_si128', LExpected, LActual);

  LoadM128Bytes(LExpected, [
    $6C, $E2, $81, $2A, $50, $B4, $41, $BB,
    $43, $57, $36, $41, $88, $50, $D2, $1A
  ]);
  LActual := aes_aesenclast_si128(LData, LKey);
  AssertM128BytesEqual(Self, 'aes_aesenclast_si128', LExpected, LActual);

  LoadM128Bytes(LExpected, [
    $D2, $F9, $2D, $FD, $69, $2B, $50, $10,
    $8F, $98, $93, $17, $A0, $2B, $A0, $40
  ]);
  LActual := aes_aesdec_si128(LData, LKey);
  AssertM128BytesEqual(Self, 'aes_aesdec_si128', LExpected, LActual);

  LoadM128Bytes(LExpected, [
    $5D, $D7, $4F, $3E, $CD, $B9, $F0, $86,
    $10, $7B, $31, $C9, $E4, $2B, $32, $96
  ]);
  LActual := aes_aesdeclast_si128(LData, LKey);
  AssertM128BytesEqual(Self, 'aes_aesdeclast_si128', LExpected, LActual);

  LoadM128Bytes(LExpected, [
    $AA, $FF, $88, $DD, $EE, $BB, $CC, $99,
    $22, $77, $00, $55, $66, $33, $44, $11
  ]);
  LActual := aes_aesimc_si128(LData);
  AssertM128BytesEqual(Self, 'aes_aesimc_si128', LExpected, LActual);

  LoadM128Bytes(LExpected, [
    $B3, $BE, $F9, $BC, $A5, $F9, $BC, $B3,
    $2E, $B5, $F8, $8C, $AE, $F8, $8C, $2E
  ]);
  LActual := aes_aeskeygenassist_si128(LKey, $1B);
  AssertM128BytesEqual(Self, 'aes_aeskeygenassist_si128 rcon=1b', LExpected, LActual);

  LoadM128Bytes(LExpected, [
    $B3, $BE, $F9, $BC, $88, $F9, $BC, $B3,
    $2E, $B5, $F8, $8C, $83, $F8, $8C, $2E
  ]);
  LActual := aes_aeskeygenassist_si128(LKey, $36);
  AssertM128BytesEqual(Self, 'aes_aeskeygenassist_si128 rcon=36', LExpected, LActual);
end;

procedure TTestCase_SimdIntrinsicsExperimental.Test_Experimental_SHA_Semantics;
var
  LA: TM128;
  LB: TM128;
  LK: TM128;
  LExpected: TM128;
  LActual: TM128;
begin
  {$IFNDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  Exit;
  {$ENDIF}

  LoadM128Words(LA, [
    DWord($01234567), DWord($89ABCDEF), DWord($0F1E2D3C), DWord($4B5A6978)
  ]);
  LoadM128Words(LB, [
    DWord($11111111), DWord($22222222), DWord($33333333), DWord($44444444)
  ]);
  LoadM128Words(LK, [
    DWord($DEADBEEF), DWord($01020304), DWord($A5A5A5A5), DWord($5A5A5A5A)
  ]);

  LoadM128Words(LExpected, [
    DWord($32107654), DWord($CDEF89AB), DWord($0E3D685B), DWord($C2F1A497)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha1msg1_epu32', LExpected, ReferenceSha1Msg1(LA, LB));
  LActual := sha_sha1msg1_epu32(LA, LB);
  AssertM128WordsEqual(Self, 'sha_sha1msg1_epu32', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($E3E3E3E3), DWord($3175B9FD), DWord($5A781E3C), DWord($F0D2B496)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha1msg2_epu32', LExpected, ReferenceSha1Msg2(LA, LB));
  LActual := sha_sha1msg2_epu32(LA, LB);
  AssertM128WordsEqual(Self, 'sha_sha1msg2_epu32', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($11111111), DWord($22222222), DWord($33333333), DWord($571ADEA2)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha1nexte_epu32', LExpected, ReferenceSha1Nexte(LA, LB));
  LActual := sha_sha1nexte_epu32(LA, LB);
  AssertM128WordsEqual(Self, 'sha_sha1nexte_epu32', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($44CFCE95), DWord($1EA8F2A9), DWord($6DA05997), DWord($643E23C4)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha1rnds4_epu32 func=0', LExpected, ReferenceSha1Rnds4(LA, LB, 0));
  LActual := sha_sha1rnds4_epu32(LA, LB, 0);
  AssertM128WordsEqual(Self, 'sha_sha1rnds4_epu32 func=0', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($A9808128), DWord($C929CA19), DWord($669FFE49), DWord($F7A3843E)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha1rnds4_epu32 func=1', LExpected, ReferenceSha1Rnds4(LA, LB, 1));
  LActual := sha_sha1rnds4_epu32(LA, LB, 1);
  AssertM128WordsEqual(Self, 'sha_sha1rnds4_epu32 func=1', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($11F61F66), DWord($72936C7B), DWord($88768604), DWord($C59BB53B)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha1rnds4_epu32 func=2', LExpected, ReferenceSha1Rnds4(LA, LB, 2));
  LActual := sha_sha1rnds4_epu32(LA, LB, 2);
  AssertM128WordsEqual(Self, 'sha_sha1rnds4_epu32 func=2', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($C062B6B5), DWord($3C52B14A), DWord($B02522CB), DWord($07DEA16F)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha1rnds4_epu32 func=3', LExpected, ReferenceSha1Rnds4(LA, LB, 3));
  LActual := sha_sha1rnds4_epu32(LA, LB, 3);
  AssertM128WordsEqual(Self, 'sha_sha1rnds4_epu32 func=3', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($3E8111B3), DWord($7C5EC829), DWord($72C21867), DWord($AF9EADBC)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha256msg1_epu32', LExpected, ReferenceSha256Msg1(LA, LB));
  LActual := sha_sha256msg1_epu32(LA, LB);
  AssertM128WordsEqual(Self, 'sha_sha256msg1_epu32', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($0116789A), DWord($346789AA), DWord($027C3273), DWord($8147AED5)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha256msg2_epu32', LExpected, ReferenceSha256Msg2(LA, LB));
  LActual := sha_sha256msg2_epu32(LA, LB);
  AssertM128WordsEqual(Self, 'sha_sha256msg2_epu32', LExpected, LActual);

  LoadM128Words(LExpected, [
    DWord($5656DD3C), DWord($56C84A10), DWord($ACAD3392), DWord($B30376E9)
  ]);
  AssertM128WordsEqual(Self, 'reference sha_sha256rnds2_epu32', LExpected, ReferenceSha256Rnds2(LA, LB, LK));
  LActual := sha_sha256rnds2_epu32(LA, LB, LK);
  AssertM128WordsEqual(Self, 'sha_sha256rnds2_epu32', LExpected, LActual);
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
