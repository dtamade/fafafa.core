unit fafafa.core.simd.intrinsics.experimental.sse2facade.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.sse2;

type
  TTestCase_Sse2FacadeExperimental = class(TTestCase)
  published
    procedure Test_LoadStore_Roundtrip;
    procedure Test_AddCmpEqMovemask;
    procedure Test_ByteShiftSemantics;
    procedure Test_SlliEpi16_ShiftCounts;
    procedure Test_SraiEpi16_ShiftCounts;
    procedure Test_ShuffleEpi32_Immediate;
    procedure Test_ShuffleHiLoEpi16_Immediate;
    procedure Test_InsertExtractEpi16_Immediate;
    procedure Test_MoveEpi64_LowHalfOnly;
    procedure Test_PacksAndPackusEpi16_Saturation;
    procedure Test_UnpackHiLoEpi8_Interleave;
    procedure Test_UnpackHiLoEpi16_Interleave;
    procedure Test_PacksEpi32_Saturation;
    procedure Test_UnpackHiLoEpi32_Interleave;
    procedure Test_UnpackHiLoEpi64_Interleave;
  end;

implementation

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

procedure AssertM128WordsEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m128i_u32[LIndex], aActual.m128i_u32[LIndex]);
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

function ArithmeticShiftRight16(aValue: SmallInt; aShift: Integer): SmallInt; inline;
var
  LBits: Word;
  LMask: Word;
begin
  if aShift <= 0 then
    Exit(aValue);

  if aShift >= 16 then
    aShift := 15;

  LBits := Word(aValue);
  if aValue >= 0 then
    Exit(SmallInt(LBits shr aShift));

  LMask := Word($FFFF shl (16 - aShift));
  Result := SmallInt((LBits shr aShift) or LMask);
end;

function ReferenceShuffleEpi32(const aValue: TM128; aImm8: Byte): TM128;
var
  LDest: Integer;
  LSrc: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LDest := 0 to 3 do
  begin
    LSrc := (aImm8 shr (LDest * 2)) and $3;
    Result.m128i_u32[LDest] := aValue.m128i_u32[LSrc];
  end;
end;

function ReferenceShuffleHiEpi16(const aValue: TM128; aImm8: Byte): TM128;
var
  LDest: Integer;
  LSrc: Integer;
begin
  Result := aValue;
  for LDest := 0 to 3 do
  begin
    LSrc := 4 + ((aImm8 shr (LDest * 2)) and $3);
    Result.m128i_u16[4 + LDest] := aValue.m128i_u16[LSrc];
  end;
end;

function ReferenceShuffleLoEpi16(const aValue: TM128; aImm8: Byte): TM128;
var
  LDest: Integer;
  LSrc: Integer;
begin
  Result := aValue;
  for LDest := 0 to 3 do
  begin
    LSrc := (aImm8 shr (LDest * 2)) and $3;
    Result.m128i_u16[LDest] := aValue.m128i_u16[LSrc];
  end;
end;

function SaturateI16ToI8Reference(aValue: SmallInt): ShortInt; inline;
begin
  if aValue > 127 then
    Exit(127);
  if aValue < -128 then
    Exit(-128);
  Result := ShortInt(aValue);
end;

function SaturateI16ToU8Reference(aValue: SmallInt): Byte; inline;
begin
  if aValue <= 0 then
    Exit(0);
  if aValue >= 255 then
    Exit(255);
  Result := Byte(aValue);
end;

function SaturateI32ToI16Reference(aValue: LongInt): SmallInt; inline;
begin
  if aValue > 32767 then
    Exit(32767);
  if aValue < -32768 then
    Exit(-32768);
  Result := SmallInt(aValue);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_LoadStore_Roundtrip;
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

procedure TTestCase_Sse2FacadeExperimental.Test_AddCmpEqMovemask;
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

procedure TTestCase_Sse2FacadeExperimental.Test_ByteShiftSemantics;
const
  SHIFTS: array[0..17] of Byte = (
    0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 200
  );
var
  LValue: TM128;
  LIndex: Integer;
begin
  InitM128IncrementingBytes(LValue, 5);
  for LIndex := Low(SHIFTS) to High(SHIFTS) do
  begin
    ExpectSlliSi128(Self, LValue, SHIFTS[LIndex]);
    ExpectSrliSi128(Self, LValue, SHIFTS[LIndex]);
  end;
end;

procedure TTestCase_Sse2FacadeExperimental.Test_SlliEpi16_ShiftCounts;
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

procedure TTestCase_Sse2FacadeExperimental.Test_SraiEpi16_ShiftCounts;
const
  SHIFTS: array[0..6] of Byte = (0, 1, 4, 8, 15, 16, 200);
var
  LValue: TM128;
  LExpected: TM128;
  LActual: TM128;
  LShiftIndex: Integer;
  LLane: Integer;
  LShift: Integer;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_i16[0] := -32768;
  LValue.m128i_i16[1] := -1025;
  LValue.m128i_i16[2] := -1;
  LValue.m128i_i16[3] := 0;
  LValue.m128i_i16[4] := 1;
  LValue.m128i_i16[5] := 255;
  LValue.m128i_i16[6] := 1024;
  LValue.m128i_i16[7] := 32767;

  for LShiftIndex := Low(SHIFTS) to High(SHIFTS) do
  begin
    LShift := SHIFTS[LShiftIndex];
    for LLane := 0 to 7 do
      LExpected.m128i_i16[LLane] := ArithmeticShiftRight16(LValue.m128i_i16[LLane], LShift);

    LActual := simd_srai_epi16(LValue, SHIFTS[LShiftIndex]);
    AssertM128BytesEqual(Self, 'simd_srai_epi16 shift=' + IntToStr(SHIFTS[LShiftIndex]), LExpected, LActual);
  end;
end;

procedure TTestCase_Sse2FacadeExperimental.Test_ShuffleEpi32_Immediate;
var
  LValue: TM128;
  LExpected: TM128;
  LActual: TM128;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_u32[0] := $11223344;
  LValue.m128i_u32[1] := $55667788;
  LValue.m128i_u32[2] := $99AABBCC;
  LValue.m128i_u32[3] := $DDEEFF00;

  LExpected := ReferenceShuffleEpi32(LValue, $1B);
  LActual := simd_shuffle_epi32(LValue, $1B);
  AssertM128WordsEqual(Self, 'simd_shuffle_epi32 imm=1b', LExpected, LActual);

  LExpected := ReferenceShuffleEpi32(LValue, $E4);
  LActual := simd_shuffle_epi32(LValue, $E4);
  AssertM128WordsEqual(Self, 'simd_shuffle_epi32 imm=e4', LExpected, LActual);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_ShuffleHiLoEpi16_Immediate;
var
  LValue: TM128;
  LExpected: TM128;
  LActual: TM128;
  LLane: Integer;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  for LLane := 0 to 7 do
    LValue.m128i_u16[LLane] := Word($1000 + (LLane * $111));

  LExpected := ReferenceShuffleHiEpi16(LValue, $1B);
  LActual := simd_shufflehi_epi16(LValue, $1B);
  AssertM128BytesEqual(Self, 'simd_shufflehi_epi16 imm=1b', LExpected, LActual);

  LExpected := ReferenceShuffleHiEpi16(LValue, $E4);
  LActual := simd_shufflehi_epi16(LValue, $E4);
  AssertM128BytesEqual(Self, 'simd_shufflehi_epi16 imm=e4', LExpected, LActual);

  LExpected := ReferenceShuffleLoEpi16(LValue, $1B);
  LActual := simd_shufflelo_epi16(LValue, $1B);
  AssertM128BytesEqual(Self, 'simd_shufflelo_epi16 imm=1b', LExpected, LActual);

  LExpected := ReferenceShuffleLoEpi16(LValue, $4E);
  LActual := simd_shufflelo_epi16(LValue, $4E);
  AssertM128BytesEqual(Self, 'simd_shufflelo_epi16 imm=4e', LExpected, LActual);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_InsertExtractEpi16_Immediate;
var
  LValue: TM128;
  LExpected: TM128;
  LActual: TM128;
  LLane: Integer;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_u16[0] := $0001;
  LValue.m128i_u16[1] := $8002;
  LValue.m128i_u16[2] := $1234;
  LValue.m128i_u16[3] := $ABCD;
  LValue.m128i_u16[4] := $00FF;
  LValue.m128i_u16[5] := $7F00;
  LValue.m128i_u16[6] := $BEEF;
  LValue.m128i_u16[7] := $FEDC;

  LExpected := LValue;
  LExpected.m128i_u16[1] := $5678;
  LActual := simd_insert_epi16(LValue, $12345678, 9);
  AssertM128BytesEqual(Self, 'simd_insert_epi16 imm masks to lane 1', LExpected, LActual);

  LExpected := LValue;
  LExpected.m128i_u16[7] := $4321;
  LActual := simd_insert_epi16(LValue, $87654321, $FF);
  AssertM128BytesEqual(Self, 'simd_insert_epi16 imm masks to lane 7', LExpected, LActual);

  for LLane := 0 to 7 do
    AssertEquals(
      'simd_extract_epi16 lane ' + IntToStr(LLane),
      Integer(LValue.m128i_u16[LLane]),
      simd_extract_epi16(LValue, Byte(LLane))
    );

  AssertEquals('simd_extract_epi16 imm masks to lane 1', Integer($8002), simd_extract_epi16(LValue, 9));
  AssertEquals('simd_extract_epi16 imm masks to lane 7', Integer($FEDC), simd_extract_epi16(LValue, $FF));
end;

procedure TTestCase_Sse2FacadeExperimental.Test_MoveEpi64_LowHalfOnly;
var
  LValue: TM128;
  LExpected: TM128;
  LActual: TM128;
begin
  FillChar(LValue, SizeOf(LValue), 0);
  LValue.m128i_u64[0] := $0123456789ABCDEF;
  LValue.m128i_u64[1] := $FEDCBA9876543210;

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_u64[0] := LValue.m128i_u64[0];

  LActual := simd_move_epi64(LValue);
  AssertM128BytesEqual(Self, 'simd_move_epi64', LExpected, LActual);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_PacksAndPackusEpi16_Saturation;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);

  LA.m128i_i16[0] := -300;
  LA.m128i_i16[1] := -129;
  LA.m128i_i16[2] := -128;
  LA.m128i_i16[3] := -1;
  LA.m128i_i16[4] := 0;
  LA.m128i_i16[5] := 100;
  LA.m128i_i16[6] := 127;
  LA.m128i_i16[7] := 300;

  LB.m128i_i16[0] := -1024;
  LB.m128i_i16[1] := -50;
  LB.m128i_i16[2] := 1;
  LB.m128i_i16[3] := 42;
  LB.m128i_i16[4] := 128;
  LB.m128i_i16[5] := 255;
  LB.m128i_i16[6] := 256;
  LB.m128i_i16[7] := 1024;

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    LExpected.m128i_i8[LIndex] := SaturateI16ToI8Reference(LA.m128i_i16[LIndex]);
  for LIndex := 0 to 7 do
    LExpected.m128i_i8[8 + LIndex] := SaturateI16ToI8Reference(LB.m128i_i16[LIndex]);

  LActual := simd_packs_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_packs_epi16 saturation', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    LExpected.m128i_u8[LIndex] := SaturateI16ToU8Reference(LA.m128i_i16[LIndex]);
  for LIndex := 0 to 7 do
    LExpected.m128i_u8[8 + LIndex] := SaturateI16ToU8Reference(LB.m128i_i16[LIndex]);

  LActual := simd_packus_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_packus_epi16 saturation', LExpected, LActual);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_UnpackHiLoEpi8_Interleave;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  InitM128IncrementingBytes(LA, 1);
  InitM128IncrementingBytes(LB, 101);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
  begin
    LExpected.m128i_u8[LIndex * 2] := LA.m128i_u8[LIndex];
    LExpected.m128i_u8[(LIndex * 2) + 1] := LB.m128i_u8[LIndex];
  end;

  LActual := simd_unpacklo_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_unpacklo_epi8', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
  begin
    LExpected.m128i_u8[LIndex * 2] := LA.m128i_u8[8 + LIndex];
    LExpected.m128i_u8[(LIndex * 2) + 1] := LB.m128i_u8[8 + LIndex];
  end;

  LActual := simd_unpackhi_epi8(LA, LB);
  AssertM128BytesEqual(Self, 'simd_unpackhi_epi8', LExpected, LActual);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_UnpackHiLoEpi16_Interleave;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  for LIndex := 0 to 7 do
  begin
    LA.m128i_u16[LIndex] := Word($1000 + LIndex);
    LB.m128i_u16[LIndex] := Word($2000 + (LIndex * 3));
  end;

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
  begin
    LExpected.m128i_u16[LIndex * 2] := LA.m128i_u16[LIndex];
    LExpected.m128i_u16[(LIndex * 2) + 1] := LB.m128i_u16[LIndex];
  end;

  LActual := simd_unpacklo_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_unpacklo_epi16', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
  begin
    LExpected.m128i_u16[LIndex * 2] := LA.m128i_u16[4 + LIndex];
    LExpected.m128i_u16[(LIndex * 2) + 1] := LB.m128i_u16[4 + LIndex];
  end;

  LActual := simd_unpackhi_epi16(LA, LB);
  AssertM128BytesEqual(Self, 'simd_unpackhi_epi16', LExpected, LActual);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_PacksEpi32_Saturation;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);

  LA.m128i_i32[0] := -50000;
  LA.m128i_i32[1] := -32769;
  LA.m128i_i32[2] := -32768;
  LA.m128i_i32[3] := -1;
  LB.m128i_i32[0] := 0;
  LB.m128i_i32[1] := 32767;
  LB.m128i_i32[2] := 32768;
  LB.m128i_i32[3] := 50000;

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    LExpected.m128i_i16[LIndex] := SaturateI32ToI16Reference(LA.m128i_i32[LIndex]);
  for LIndex := 0 to 3 do
    LExpected.m128i_i16[4 + LIndex] := SaturateI32ToI16Reference(LB.m128i_i32[LIndex]);

  LActual := simd_packs_epi32(LA, LB);
  AssertM128BytesEqual(Self, 'simd_packs_epi32 saturation', LExpected, LActual);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_UnpackHiLoEpi32_Interleave;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);

  LA.m128i_u32[0] := $11111111;
  LA.m128i_u32[1] := $22222222;
  LA.m128i_u32[2] := $33333333;
  LA.m128i_u32[3] := $44444444;
  LB.m128i_u32[0] := $AAAA0001;
  LB.m128i_u32[1] := $BBBB0002;
  LB.m128i_u32[2] := $CCCC0003;
  LB.m128i_u32[3] := $DDDD0004;

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_u32[0] := LA.m128i_u32[0];
  LExpected.m128i_u32[1] := LB.m128i_u32[0];
  LExpected.m128i_u32[2] := LA.m128i_u32[1];
  LExpected.m128i_u32[3] := LB.m128i_u32[1];

  LActual := simd_unpacklo_epi32(LA, LB);
  AssertM128WordsEqual(Self, 'simd_unpacklo_epi32', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_u32[0] := LA.m128i_u32[2];
  LExpected.m128i_u32[1] := LB.m128i_u32[2];
  LExpected.m128i_u32[2] := LA.m128i_u32[3];
  LExpected.m128i_u32[3] := LB.m128i_u32[3];

  LActual := simd_unpackhi_epi32(LA, LB);
  AssertM128WordsEqual(Self, 'simd_unpackhi_epi32', LExpected, LActual);
end;

procedure TTestCase_Sse2FacadeExperimental.Test_UnpackHiLoEpi64_Interleave;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
  LActual: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);

  LA.m128i_u64[0] := $0123456789ABCDEF;
  LA.m128i_u64[1] := $1111222233334444;
  LB.m128i_u64[0] := $5555666677778888;
  LB.m128i_u64[1] := $FEDCBA9876543210;

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_u64[0] := LA.m128i_u64[0];
  LExpected.m128i_u64[1] := LB.m128i_u64[0];

  LActual := simd_unpacklo_epi64(LA, LB);
  AssertM128BytesEqual(Self, 'simd_unpacklo_epi64', LExpected, LActual);

  FillChar(LExpected, SizeOf(LExpected), 0);
  LExpected.m128i_u64[0] := LA.m128i_u64[1];
  LExpected.m128i_u64[1] := LB.m128i_u64[1];

  LActual := simd_unpackhi_epi64(LA, LB);
  AssertM128BytesEqual(Self, 'simd_unpackhi_epi64', LExpected, LActual);
end;

initialization
  RegisterTest(TTestCase_Sse2FacadeExperimental);

end.
