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

procedure LoadM128ShortInts(var aValue: TM128; const aValues: array of ShortInt);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to High(aValues) do
    aValue.m128i_i8[LIndex] := aValues[LIndex];
end;

procedure LoadM128SmallInts(var aValue: TM128; const aValues: array of SmallInt);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to High(aValues) do
    aValue.m128i_i16[LIndex] := aValues[LIndex];
end;

procedure LoadM128LongInts(var aValue: TM128; const aValues: array of LongInt);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to High(aValues) do
    aValue.m128i_i32[LIndex] := aValues[LIndex];
end;

procedure LoadM128Singles(var aValue: TM128; const aValues: array of Single);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to High(aValues) do
    aValue.m128_f32[LIndex] := aValues[LIndex];
end;

procedure LoadM128Doubles(var aValue: TM128; const aValues: array of Double);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to High(aValues) do
    aValue.m128d_f64[LIndex] := aValues[LIndex];
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

function SaturateToI8(aValue: Integer): ShortInt; inline;
begin
  if aValue > High(ShortInt) then
    Exit(High(ShortInt));
  if aValue < Low(ShortInt) then
    Exit(Low(ShortInt));
  Result := ShortInt(aValue);
end;

function SaturateToI16(aValue: Integer): SmallInt; inline;
begin
  if aValue > High(SmallInt) then
    Exit(High(SmallInt));
  if aValue < Low(SmallInt) then
    Exit(Low(SmallInt));
  Result := SmallInt(aValue);
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
    procedure Test_FloatingConstructorsAndLoads;
    procedure Test_FloatingBinaryOps;
    procedure Test_FloatingSqrtOps;
    procedure Test_IntegerConstructors;
    procedure Test_IntegerAddSubOps;
    procedure Test_IntegerCompareOps;
    procedure Test_IntegerMinMaxMulOps;
    procedure Test_IntegerSaturatingOps;
    procedure Test_LogicalBinaryOps;
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

procedure TTestCase_X86Sse2AbiBasics.Test_FloatingConstructorsAndLoads;
var
  LDoubles: array[0..1] of Double;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
  LSingles: array[0..3] of Single;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LActual := simd_setzero_pd;
  AssertM128BytesEqual(Self, 'simd_setzero_pd', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  LActual := simd_setzero_ps;
  AssertM128BytesEqual(Self, 'simd_setzero_ps', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128d_f64[LIndex] := 3.5;
  LActual := simd_set1_pd(3.5);
  AssertM128BytesEqual(Self, 'simd_set1_pd', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128_f32[LIndex] := 2.25;
  LActual := simd_set1_ps(2.25);
  AssertM128BytesEqual(Self, 'simd_set1_ps', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128d_f64[0] := 1.25;
  LExpected.m128d_f64[1] := 9.5;
  LActual := simd_setr_pd(1.25, 9.5);
  AssertM128BytesEqual(Self, 'simd_setr_pd', LExpected, LActual);

  LDoubles[0] := -7.0;
  LDoubles[1] := 42.25;
  FillChar(LExpected, SizeOf(LExpected), 0);
  Move(LDoubles[0], LExpected, SizeOf(LDoubles));
  LActual := simd_loadu_pd(@LDoubles[0]);
  AssertM128BytesEqual(Self, 'simd_loadu_pd', LExpected, LActual);

  for LIndex := 0 to 3 do
    LSingles[LIndex] := (LIndex * 1.5) - 2.0;
  FillChar(LExpected, SizeOf(LExpected), 0);
  Move(LSingles[0], LExpected, SizeOf(LSingles));
  LActual := simd_loadu_ps(@LSingles[0]);
  AssertM128BytesEqual(Self, 'simd_loadu_ps', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_FloatingBinaryOps;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  LoadM128Singles(LA, [1.5, -2.0, 8.0, -16.0]);
  LoadM128Singles(LB, [0.5, 4.0, -2.0, 0.25]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128_f32[LIndex] := LA.m128_f32[LIndex] + LB.m128_f32[LIndex];
  LActual := simd_add_ps(LA, LB);
  AssertM128BytesEqual(Self, 'simd_add_ps', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128_f32[LIndex] := LA.m128_f32[LIndex] - LB.m128_f32[LIndex];
  LActual := simd_sub_ps(LA, LB);
  AssertM128BytesEqual(Self, 'simd_sub_ps', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128_f32[LIndex] := LA.m128_f32[LIndex] * LB.m128_f32[LIndex];
  LActual := simd_mul_ps(LA, LB);
  AssertM128BytesEqual(Self, 'simd_mul_ps', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128_f32[LIndex] := LA.m128_f32[LIndex] / LB.m128_f32[LIndex];
  LActual := simd_div_ps(LA, LB);
  AssertM128BytesEqual(Self, 'simd_div_ps', LExpected, LActual);

  LoadM128Doubles(LA, [1.25, -4.0]);
  LoadM128Doubles(LB, [0.5, 0.125]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128d_f64[LIndex] := LA.m128d_f64[LIndex] + LB.m128d_f64[LIndex];
  LActual := simd_add_pd(LA, LB);
  AssertM128BytesEqual(Self, 'simd_add_pd', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128d_f64[LIndex] := LA.m128d_f64[LIndex] - LB.m128d_f64[LIndex];
  LActual := simd_sub_pd(LA, LB);
  AssertM128BytesEqual(Self, 'simd_sub_pd', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128d_f64[LIndex] := LA.m128d_f64[LIndex] * LB.m128d_f64[LIndex];
  LActual := simd_mul_pd(LA, LB);
  AssertM128BytesEqual(Self, 'simd_mul_pd', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128d_f64[LIndex] := LA.m128d_f64[LIndex] / LB.m128d_f64[LIndex];
  LActual := simd_div_pd(LA, LB);
  AssertM128BytesEqual(Self, 'simd_div_pd', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_FloatingSqrtOps;
var
  LValue: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  LoadM128Singles(LValue, [0.0, 1.0, 4.0, 144.0]);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128_f32[LIndex] := Sqrt(LValue.m128_f32[LIndex]);
  LActual := simd_sqrt_ps(LValue);
  AssertM128BytesEqual(Self, 'simd_sqrt_ps', LExpected, LActual);

  LoadM128Doubles(LValue, [0.25, 81.0]);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128d_f64[LIndex] := Sqrt(LValue.m128d_f64[LIndex]);
  LActual := simd_sqrt_pd(LValue);
  AssertM128BytesEqual(Self, 'simd_sqrt_pd', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_IntegerConstructors;
var
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  LActual := simd_setzero_si128;
  AssertM128BytesEqual(Self, 'simd_setzero_si128', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m128i_i8[LIndex] := -5;
  LActual := simd_set1_epi8(-5);
  AssertM128BytesEqual(Self, 'simd_set1_epi8', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    LExpected.m128i_i16[LIndex] := $1234;
  LActual := simd_set1_epi16($1234);
  AssertM128BytesEqual(Self, 'simd_set1_epi16', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128i_i32[LIndex] := $12345678;
  LActual := simd_set1_epi32($12345678);
  AssertM128BytesEqual(Self, 'simd_set1_epi32', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128i_i64[LIndex] := $1122334455667788;
  LActual := simd_set1_epi64x($1122334455667788);
  AssertM128BytesEqual(Self, 'simd_set1_epi64x', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_i32[0] := 11;
  LExpected.m128i_i32[1] := 22;
  LExpected.m128i_i32[2] := 33;
  LExpected.m128i_i32[3] := 44;
  LActual := simd_setr_epi32(11, 22, 33, 44);
  AssertM128BytesEqual(Self, 'simd_setr_epi32', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_i32[0] := 44;
  LExpected.m128i_i32[1] := 33;
  LExpected.m128i_i32[2] := 22;
  LExpected.m128i_i32[3] := 11;
  LActual := simd_set_epi32(11, 22, 33, 44);
  AssertM128BytesEqual(Self, 'simd_set_epi32', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_i64[0] := $1020304050607080;
  LExpected.m128i_i64[1] := $0102030405060708;
  LActual := simd_set_epi64x($0102030405060708, $1020304050607080);
  AssertM128BytesEqual(Self, 'simd_set_epi64x', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_IntegerAddSubOps;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
  LU64A: array[0..1] of QWord;
  LU64B: array[0..1] of QWord;
begin
  LoadM128ShortInts(LA, [120, -120, 15, -15, 100, -100, 64, -64, 1, -1, 50, -50, 30, -30, 90, -90]);
  LoadM128ShortInts(LB, [10, 20, -30, 40, 70, -80, -90, 100, -1, 1, 100, -100, -60, 60, 100, -100]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m128i_u8[LIndex] := Byte((Integer(LA.m128i_u8[LIndex]) - Integer(LB.m128i_u8[LIndex])) and $FF);
  LActual := simd_sub_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_sub_epi8', LExpected, LActual);

  LoadM128SmallInts(LA, [32760, -32760, 100, -100, 1234, -1234, 20000, -20000]);
  LoadM128SmallInts(LB, [100, -100, 32760, -32760, -1234, 1234, 20000, -20000]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    LExpected.m128i_u16[LIndex] := Word((DWord(LA.m128i_u16[LIndex]) + DWord(LB.m128i_u16[LIndex])) and $FFFF);
  LActual := simd_add_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_add_epi16', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    LExpected.m128i_u16[LIndex] := Word((DWord(LA.m128i_u16[LIndex]) - DWord(LB.m128i_u16[LIndex])) and $FFFF);
  LActual := simd_sub_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_sub_epi16', LExpected, LActual);

  LoadM128LongInts(LA, [2147483600, -2147483600, 100, -100]);
  LoadM128LongInts(LB, [100, -100, 2147483600, -2147483600]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128i_u32[LIndex] := DWord(QWord(LA.m128i_u32[LIndex]) + QWord(LB.m128i_u32[LIndex]));
  LActual := simd_add_epi32(LA, LB);
  AssertM128BytesEqual(Self, 'simd_add_epi32', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128i_u32[LIndex] := DWord(QWord(LA.m128i_u32[LIndex]) - QWord(LB.m128i_u32[LIndex]));
  LActual := simd_sub_epi32(LA, LB);
  AssertM128BytesEqual(Self, 'simd_sub_epi32', LExpected, LActual);

  LU64A[0] := QWord($FFFFFFFFFFFFFFF0);
  LU64A[1] := QWord($0123456789ABCDEF);
  LU64B[0] := QWord($0000000000000030);
  LU64B[1] := QWord($FEDCBA9876543211);
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  Move(LU64A[0], LA, SizeOf(LU64A));
  Move(LU64B[0], LB, SizeOf(LU64B));

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128i_u64[LIndex] := LU64A[LIndex] + LU64B[LIndex];
  LActual := simd_add_epi64(LA, LB);
  AssertM128BytesEqual(Self, 'simd_add_epi64', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 1 do
    LExpected.m128i_u64[LIndex] := LU64A[LIndex] - LU64B[LIndex];
  LActual := simd_sub_epi64(LA, LB);
  AssertM128BytesEqual(Self, 'simd_sub_epi64', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_IntegerCompareOps;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  LoadM128ShortInts(LA, [-5, 5, 100, -100, 0, 1, -1, 127, -128, 42, 42, -42, 64, -64, 10, -10]);
  LoadM128ShortInts(LB, [-10, 5, 99, -99, 1, 0, -1, 126, -127, 100, 42, -100, 65, -65, 20, -20]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    if LA.m128i_i8[LIndex] > LB.m128i_i8[LIndex] then
      LExpected.m128i_u8[LIndex] := $FF
    else
      LExpected.m128i_u8[LIndex] := $00;
  LActual := simd_cmpgt_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_cmpgt_epi8', LExpected, LActual);

  LoadM128SmallInts(LA, [-30000, -1, 0, 1234, 32760, -32760, 42, 42]);
  LoadM128SmallInts(LB, [-30000, 1, 0, -1234, 32760, -32759, 100, 0]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    if LA.m128i_i16[LIndex] = LB.m128i_i16[LIndex] then
      LExpected.m128i_u16[LIndex] := $FFFF
    else
      LExpected.m128i_u16[LIndex] := $0000;
  LActual := simd_cmpeq_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_cmpeq_epi16', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    if LA.m128i_i16[LIndex] > LB.m128i_i16[LIndex] then
      LExpected.m128i_u16[LIndex] := $FFFF
    else
      LExpected.m128i_u16[LIndex] := $0000;
  LActual := simd_cmpgt_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_cmpgt_epi16', LExpected, LActual);

  LoadM128LongInts(LA, [-2147483600, -1, 0, 2147483600]);
  LoadM128LongInts(LB, [-2147483600, 1, -1, 2147483500]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    if LA.m128i_i32[LIndex] = LB.m128i_i32[LIndex] then
      LExpected.m128i_u32[LIndex] := DWord($FFFFFFFF)
    else
      LExpected.m128i_u32[LIndex] := DWord($00000000);
  LActual := simd_cmpeq_epi32(LA, LB);
  AssertM128BytesEqual(Self, 'simd_cmpeq_epi32', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    if LA.m128i_i32[LIndex] > LB.m128i_i32[LIndex] then
      LExpected.m128i_u32[LIndex] := DWord($FFFFFFFF)
    else
      LExpected.m128i_u32[LIndex] := DWord($00000000);
  LActual := simd_cmpgt_epi32(LA, LB);
  AssertM128BytesEqual(Self, 'simd_cmpgt_epi32', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_IntegerMinMaxMulOps;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
  LProduct: Int64;
begin
  LoadM128ShortInts(LA, [-5, 5, 100, -100, 0, 1, -1, 127, -128, 42, 42, -42, 64, -64, 10, -10]);
  LoadM128ShortInts(LB, [-10, 7, 99, -99, 1, 0, -2, 126, -127, 100, 41, -100, 65, -65, 20, -20]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    if LA.m128i_i8[LIndex] > LB.m128i_i8[LIndex] then
      LExpected.m128i_i8[LIndex] := LA.m128i_i8[LIndex]
    else
      LExpected.m128i_i8[LIndex] := LB.m128i_i8[LIndex];
  LActual := simd_max_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_max_epi8', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    if LA.m128i_i8[LIndex] < LB.m128i_i8[LIndex] then
      LExpected.m128i_i8[LIndex] := LA.m128i_i8[LIndex]
    else
      LExpected.m128i_i8[LIndex] := LB.m128i_i8[LIndex];
  LActual := simd_min_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_min_epi8', LExpected, LActual);

  LoadM128SmallInts(LA, [-30000, -1, 0, 1234, 32760, -32760, 42, 42]);
  LoadM128SmallInts(LB, [-30001, 1, 0, -1234, 32759, -32759, 100, 0]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    if LA.m128i_i16[LIndex] > LB.m128i_i16[LIndex] then
      LExpected.m128i_i16[LIndex] := LA.m128i_i16[LIndex]
    else
      LExpected.m128i_i16[LIndex] := LB.m128i_i16[LIndex];
  LActual := simd_max_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_max_epi16', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    if LA.m128i_i16[LIndex] < LB.m128i_i16[LIndex] then
      LExpected.m128i_i16[LIndex] := LA.m128i_i16[LIndex]
    else
      LExpected.m128i_i16[LIndex] := LB.m128i_i16[LIndex];
  LActual := simd_min_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_min_epi16', LExpected, LActual);

  LoadM128Words(LA, [DWord($FFFFFFFE), DWord($11111111), DWord($12345678), DWord($22222222)]);
  LoadM128Words(LB, [DWord($00000003), DWord($33333333), DWord($00000010), DWord($44444444)]);
  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_u64[0] := QWord(LA.m128i_u32[0]) * QWord(LB.m128i_u32[0]);
  LExpected.m128i_u64[1] := QWord(LA.m128i_u32[2]) * QWord(LB.m128i_u32[2]);
  LActual := simd_mul_epu32(LA, LB);
  AssertM128BytesEqual(Self, 'simd_mul_epu32', LExpected, LActual);

  LoadM128SmallInts(LA, [300, -300, 2000, -2000, 1234, -1234, 32767, -32768]);
  LoadM128SmallInts(LB, [200, 200, -30, -30, -10, -10, 2, 2]);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
  begin
    LProduct := Int64(LA.m128i_i16[LIndex]) * Int64(LB.m128i_i16[LIndex]);
    LExpected.m128i_u16[LIndex] := Word(LProduct and $FFFF);
  end;
  LActual := simd_mullo_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_mullo_epi16', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_IntegerSaturatingOps;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
  LValue: Integer;
begin
  LoadM128ShortInts(LA, [120, 100, -120, -100, 60, -60, 127, -128, 50, -50, 90, -90, 1, -1, 30, -30]);
  LoadM128ShortInts(LB, [20, 40, -20, -40, 80, -80, 1, -1, -100, 100, 50, -50, 127, -128, -60, 60]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
  begin
    LValue := Integer(LA.m128i_i8[LIndex]) + Integer(LB.m128i_i8[LIndex]);
    LExpected.m128i_i8[LIndex] := SaturateToI8(LValue);
  end;
  LActual := simd_adds_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_adds_epi8', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
  begin
    LValue := Integer(LA.m128i_i8[LIndex]) - Integer(LB.m128i_i8[LIndex]);
    LExpected.m128i_i8[LIndex] := SaturateToI8(LValue);
  end;
  LActual := simd_subs_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_subs_epi8', LExpected, LActual);

  LoadM128SmallInts(LA, [32760, 20000, -32760, -20000, 1234, -1234, 30000, -30000]);
  LoadM128SmallInts(LB, [100, 20000, -100, -20000, 30000, -30000, 10000, -10000]);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
  begin
    LValue := Integer(LA.m128i_i16[LIndex]) + Integer(LB.m128i_i16[LIndex]);
    LExpected.m128i_i16[LIndex] := SaturateToI16(LValue);
  end;
  LActual := simd_adds_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_adds_epi16', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
  begin
    LValue := Integer(LA.m128i_i16[LIndex]) - Integer(LB.m128i_i16[LIndex]);
    LExpected.m128i_i16[LIndex] := SaturateToI16(LValue);
  end;
  LActual := simd_subs_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_subs_epi16', LExpected, LActual);
end;

procedure TTestCase_X86Sse2AbiBasics.Test_LogicalBinaryOps;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  LoadM128Bytes(LA, [$00, $FF, $0F, $F0, $55, $AA, $12, $34, $80, $7F, $33, $CC, $5A, $A5, $11, $EE]);
  LoadM128Bytes(LB, [$FF, $00, $F0, $0F, $AA, $55, $21, $43, $7F, $80, $CC, $33, $A5, $5A, $EE, $11]);

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
    LExpected.m128i_u8[LIndex] := Byte(not LA.m128i_u8[LIndex]) and LB.m128i_u8[LIndex];
  LActual := simd_andnot_si128(LA, LB);
  AssertM128BytesEqual(Self, 'simd_andnot_si128', LExpected, LActual);
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
