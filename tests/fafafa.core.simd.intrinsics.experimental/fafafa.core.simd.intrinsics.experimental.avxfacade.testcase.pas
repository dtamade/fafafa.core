unit fafafa.core.simd.intrinsics.experimental.avxfacade.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  Math,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.avx;

type
  TTestCase_AvxFacadeExperimental = class(TTestCase)
  published
    procedure Test_CmpPs256_PredicateMasks;
    procedure Test_CmpPd256_PredicateMasks;
    procedure Test_BlendPs256_ImmediateLaneSelection;
    procedure Test_BlendPd256_ImmediateLaneSelection;
    procedure Test_BlendvPs256_SignBitSelection;
    procedure Test_BlendvPd256_SignBitSelection;
    procedure Test_ShufflePs256_ImmediateLaneSelection;
    procedure Test_ShufflePd256_ImmediateLaneSelection;
    procedure Test_PermutePs256_ImmediateLaneSelection;
    procedure Test_PermutePd256_ImmediateLaneSelection;
    procedure Test_Permute2F128Ps256_ImmediateLaneSelection;
    procedure Test_Permute2F128Pd256_ImmediateLaneSelection;
    procedure Test_UnpackPs256_LaneInterleave;
    procedure Test_UnpackPd256_LaneInterleave;
    procedure Test_TestPs256_SignBitPredicates;
    procedure Test_TestPd256_SignBitPredicates;
  end;

implementation

const
  EXTRA_COMPARE_IMMS: array[0..3] of Byte = ($20, $23, $7F, $FF);

function BoolMask32(aValue: Boolean): DWord; inline;
begin
  if aValue then
    Exit(DWord($FFFFFFFF));
  Result := 0;
end;

function BoolMask64(aValue: Boolean): QWord; inline;
begin
  if aValue then
    Exit(QWord($FFFFFFFFFFFFFFFF));
  Result := 0;
end;

procedure AssertM256DWordsEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM256);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m256i_u32[LIndex], aActual.m256i_u32[LIndex]);
end;

procedure AssertM256QWordsEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM256);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m256i_u64[LIndex], aActual.m256i_u64[LIndex]);
end;

function CompareMaskPsLane(aLeft, aRight: Single; aImm8: Byte): DWord; inline;
var
  LUnordered: Boolean;
  LEq: Boolean;
  LLt: Boolean;
  LLe: Boolean;
  LGe: Boolean;
  LGt: Boolean;
  LNeOrdered: Boolean;
begin
  LUnordered := IsNan(aLeft) or IsNan(aRight);
  LEq := (not LUnordered) and (aLeft = aRight);
  LLt := (not LUnordered) and (aLeft < aRight);
  LLe := (not LUnordered) and (aLeft <= aRight);
  LGe := (not LUnordered) and (aLeft >= aRight);
  LGt := (not LUnordered) and (aLeft > aRight);
  LNeOrdered := (not LUnordered) and (aLeft <> aRight);

  case (aImm8 and $1F) of
    $00, $10:
      Result := BoolMask32(LEq);
    $01, $11:
      Result := BoolMask32(LLt);
    $02, $12:
      Result := BoolMask32(LLe);
    $03, $13:
      Result := BoolMask32(LUnordered);
    $04, $14:
      Result := BoolMask32(LUnordered or LNeOrdered);
    $05, $15:
      Result := BoolMask32(not LLt);
    $06, $16:
      Result := BoolMask32(not LLe);
    $07, $17:
      Result := BoolMask32(not LUnordered);
    $08, $18:
      Result := BoolMask32(LUnordered or LEq);
    $09, $19:
      Result := BoolMask32(not LGe);
    $0A, $1A:
      Result := BoolMask32(not LGt);
    $0B, $1B:
      Result := 0;
    $0C, $1C:
      Result := BoolMask32(LNeOrdered);
    $0D, $1D:
      Result := BoolMask32(LGe);
    $0E, $1E:
      Result := BoolMask32(LGt);
  else
    Result := DWord($FFFFFFFF);
  end;
end;

function CompareMaskPdLane(aLeft, aRight: Double; aImm8: Byte): QWord; inline;
var
  LUnordered: Boolean;
  LEq: Boolean;
  LLt: Boolean;
  LLe: Boolean;
  LGe: Boolean;
  LGt: Boolean;
  LNeOrdered: Boolean;
begin
  LUnordered := IsNan(aLeft) or IsNan(aRight);
  LEq := (not LUnordered) and (aLeft = aRight);
  LLt := (not LUnordered) and (aLeft < aRight);
  LLe := (not LUnordered) and (aLeft <= aRight);
  LGe := (not LUnordered) and (aLeft >= aRight);
  LGt := (not LUnordered) and (aLeft > aRight);
  LNeOrdered := (not LUnordered) and (aLeft <> aRight);

  case (aImm8 and $1F) of
    $00, $10:
      Result := BoolMask64(LEq);
    $01, $11:
      Result := BoolMask64(LLt);
    $02, $12:
      Result := BoolMask64(LLe);
    $03, $13:
      Result := BoolMask64(LUnordered);
    $04, $14:
      Result := BoolMask64(LUnordered or LNeOrdered);
    $05, $15:
      Result := BoolMask64(not LLt);
    $06, $16:
      Result := BoolMask64(not LLe);
    $07, $17:
      Result := BoolMask64(not LUnordered);
    $08, $18:
      Result := BoolMask64(LUnordered or LEq);
    $09, $19:
      Result := BoolMask64(not LGe);
    $0A, $1A:
      Result := BoolMask64(not LGt);
    $0B, $1B:
      Result := 0;
    $0C, $1C:
      Result := BoolMask64(LNeOrdered);
    $0D, $1D:
      Result := BoolMask64(LGe);
    $0E, $1E:
      Result := BoolMask64(LGt);
  else
    Result := QWord($FFFFFFFFFFFFFFFF);
  end;
end;

procedure InitCmpPsInputs(var aLeft, aRight: TM256);
begin
  FillChar(aLeft, SizeOf(aLeft), 0);
  FillChar(aRight, SizeOf(aRight), 0);

  aLeft.m256_f32[0] := 1.0;
  aRight.m256_f32[0] := 1.0;

  aLeft.m256_f32[1] := -4.0;
  aRight.m256_f32[1] := 2.0;

  aLeft.m256_f32[2] := 5.0;
  aRight.m256_f32[2] := -1.0;

  aLeft.m256i_u32[3] := $7FC00001;
  aRight.m256_f32[3] := 3.0;

  aLeft.m256_f32[4] := 7.0;
  aRight.m256i_u32[4] := $7FC00002;

  aLeft.m256i_u32[5] := $80000000;
  aRight.m256i_u32[5] := $00000000;

  aLeft.m256i_u32[6] := $FF800000;
  aRight.m256i_u32[6] := $7F800000;

  aLeft.m256i_u32[7] := $7F800000;
  aRight.m256_f32[7] := 123.0;
end;

procedure InitCmpPdInputs(var aLeft, aRight: TM256);
begin
  FillChar(aLeft, SizeOf(aLeft), 0);
  FillChar(aRight, SizeOf(aRight), 0);

  aLeft.m256_f64[0] := 1.0;
  aRight.m256_f64[0] := 1.0;

  aLeft.m256_f64[1] := -4.0;
  aRight.m256_f64[1] := 2.0;

  aLeft.m256_f64[2] := 5.0;
  aRight.m256_f64[2] := -1.0;

  aLeft.m256i_u64[3] := QWord($7FF8000000000001);
  aRight.m256_f64[3] := 3.0;
end;

function ReferenceCmpPs256(const aLeft, aRight: TM256; aImm8: Byte): TM256;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 0 to 7 do
    Result.m256i_u32[LIndex] := CompareMaskPsLane(aLeft.m256_f32[LIndex], aRight.m256_f32[LIndex], aImm8);
end;

function ReferenceCmpPd256(const aLeft, aRight: TM256; aImm8: Byte): TM256;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 0 to 3 do
    Result.m256i_u64[LIndex] := CompareMaskPdLane(aLeft.m256_f64[LIndex], aRight.m256_f64[LIndex], aImm8);
end;

procedure InitU32Lanes(var aValue: TM256; aBase: DWord);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 7 do
    aValue.m256i_u32[LIndex] := aBase + DWord(LIndex);
end;

procedure InitU64Lanes(var aValue: TM256; aBase: QWord);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 3 do
    aValue.m256i_u64[LIndex] := aBase + QWord(LIndex);
end;

function ReferenceShufflePs256(const aLeft, aRight: TM256; aImm8: Byte): TM256;
var
  LLane: Integer;
  LBase: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LLane := 0 to 1 do
  begin
    LBase := LLane * 4;
    Result.m256i_u32[LBase + 0] := aLeft.m256i_u32[LBase + ((aImm8 shr 0) and 3)];
    Result.m256i_u32[LBase + 1] := aLeft.m256i_u32[LBase + ((aImm8 shr 2) and 3)];
    Result.m256i_u32[LBase + 2] := aRight.m256i_u32[LBase + ((aImm8 shr 4) and 3)];
    Result.m256i_u32[LBase + 3] := aRight.m256i_u32[LBase + ((aImm8 shr 6) and 3)];
  end;
end;

function ReferenceShufflePd256(const aLeft, aRight: TM256; aImm8: Byte): TM256;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 0 to 3 do
    if ((aImm8 shr LIndex) and 1) <> 0 then
      Result.m256i_u64[LIndex] := aRight.m256i_u64[LIndex]
    else
      Result.m256i_u64[LIndex] := aLeft.m256i_u64[LIndex];
end;

function ReferencePermutePs256(const aValue: TM256; aImm8: Byte): TM256;
var
  LLane: Integer;
  LBase: Integer;
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LLane := 0 to 1 do
  begin
    LBase := LLane * 4;
    for LIndex := 0 to 3 do
      Result.m256i_u32[LBase + LIndex] := aValue.m256i_u32[LBase + ((aImm8 shr (LIndex * 2)) and 3)];
  end;
end;

function ReferencePermutePd256(const aValue: TM256; aImm8: Byte): TM256;
var
  LLane: Integer;
  LBase: Integer;
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LLane := 0 to 1 do
  begin
    LBase := LLane * 2;
    for LIndex := 0 to 1 do
      Result.m256i_u64[LBase + LIndex] := aValue.m256i_u64[LBase + ((aImm8 shr (LBase + LIndex)) and 1)];
  end;
end;

function ReferencePermute2F128256(const aLeft, aRight: TM256; aImm8: Byte): TM256;

  procedure CopySelectedLane(aDestLane: Integer; aSelector: Byte; aZero: Boolean);
  var
    LDestBase: Integer;
    LSrcBase: Integer;
    LIndex: Integer;
  begin
    LDestBase := aDestLane * 4;
    if aZero then
    begin
      for LIndex := 0 to 3 do
        Result.m256i_u32[LDestBase + LIndex] := 0;
      Exit;
    end;

    LSrcBase := (aSelector and 1) * 4;
    for LIndex := 0 to 3 do
      if (aSelector and 2) = 0 then
        Result.m256i_u32[LDestBase + LIndex] := aLeft.m256i_u32[LSrcBase + LIndex]
      else
        Result.m256i_u32[LDestBase + LIndex] := aRight.m256i_u32[LSrcBase + LIndex];
  end;

begin
  FillChar(Result, SizeOf(Result), 0);
  CopySelectedLane(0, aImm8 and 3, (aImm8 and $08) <> 0);
  CopySelectedLane(1, (aImm8 shr 4) and 3, (aImm8 and $80) <> 0);
end;

function ReferenceUnpackLoPs256(const aLeft, aRight: TM256): TM256;
var
  LLane: Integer;
  LBase: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LLane := 0 to 1 do
  begin
    LBase := LLane * 4;
    Result.m256i_u32[LBase + 0] := aLeft.m256i_u32[LBase + 0];
    Result.m256i_u32[LBase + 1] := aRight.m256i_u32[LBase + 0];
    Result.m256i_u32[LBase + 2] := aLeft.m256i_u32[LBase + 1];
    Result.m256i_u32[LBase + 3] := aRight.m256i_u32[LBase + 1];
  end;
end;

function ReferenceUnpackHiPs256(const aLeft, aRight: TM256): TM256;
var
  LLane: Integer;
  LBase: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LLane := 0 to 1 do
  begin
    LBase := LLane * 4;
    Result.m256i_u32[LBase + 0] := aLeft.m256i_u32[LBase + 2];
    Result.m256i_u32[LBase + 1] := aRight.m256i_u32[LBase + 2];
    Result.m256i_u32[LBase + 2] := aLeft.m256i_u32[LBase + 3];
    Result.m256i_u32[LBase + 3] := aRight.m256i_u32[LBase + 3];
  end;
end;

function ReferenceUnpackLoPd256(const aLeft, aRight: TM256): TM256;
var
  LLane: Integer;
  LBase: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LLane := 0 to 1 do
  begin
    LBase := LLane * 2;
    Result.m256i_u64[LBase + 0] := aLeft.m256i_u64[LBase + 0];
    Result.m256i_u64[LBase + 1] := aRight.m256i_u64[LBase + 0];
  end;
end;

function ReferenceUnpackHiPd256(const aLeft, aRight: TM256): TM256;
var
  LLane: Integer;
  LBase: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LLane := 0 to 1 do
  begin
    LBase := LLane * 2;
    Result.m256i_u64[LBase + 0] := aLeft.m256i_u64[LBase + 1];
    Result.m256i_u64[LBase + 1] := aRight.m256i_u64[LBase + 1];
  end;
end;

function ReferenceTestZPs256(const aLeft, aRight: TM256): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if ((aLeft.m256i_u32[LIndex] and aRight.m256i_u32[LIndex]) and $80000000) <> 0 then
      Exit(False);
  Result := True;
end;

function ReferenceTestCPs256(const aLeft, aRight: TM256): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if (((not aLeft.m256i_u32[LIndex]) and aRight.m256i_u32[LIndex]) and $80000000) <> 0 then
      Exit(False);
  Result := True;
end;

function ReferenceTestZPd256(const aLeft, aRight: TM256): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if ((aLeft.m256i_u64[LIndex] and aRight.m256i_u64[LIndex]) and QWord($8000000000000000)) <> 0 then
      Exit(False);
  Result := True;
end;

function ReferenceTestCPd256(const aLeft, aRight: TM256): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if (((not aLeft.m256i_u64[LIndex]) and aRight.m256i_u64[LIndex]) and QWord($8000000000000000)) <> 0 then
      Exit(False);
  Result := True;
end;

procedure AssertAvxTestPsCase(aTest: TTestCase; const aLabel: string; const aLeft, aRight: TM256);
var
  LExpectedZ: Boolean;
  LExpectedC: Boolean;
begin
  LExpectedZ := ReferenceTestZPs256(aLeft, aRight);
  LExpectedC := ReferenceTestCPs256(aLeft, aRight);

  aTest.AssertEquals(aLabel + '.testz_ps', LExpectedZ, avx_testz_ps256(aLeft, aRight));
  aTest.AssertEquals(aLabel + '.testc_ps', LExpectedC, avx_testc_ps256(aLeft, aRight));
  aTest.AssertEquals(aLabel + '.testnzc_ps', (not LExpectedZ) and (not LExpectedC), avx_testnzc_ps256(aLeft, aRight));
end;

procedure AssertAvxTestPdCase(aTest: TTestCase; const aLabel: string; const aLeft, aRight: TM256);
var
  LExpectedZ: Boolean;
  LExpectedC: Boolean;
begin
  LExpectedZ := ReferenceTestZPd256(aLeft, aRight);
  LExpectedC := ReferenceTestCPd256(aLeft, aRight);

  aTest.AssertEquals(aLabel + '.testz_pd', LExpectedZ, avx_testz_pd256(aLeft, aRight));
  aTest.AssertEquals(aLabel + '.testc_pd', LExpectedC, avx_testc_pd256(aLeft, aRight));
  aTest.AssertEquals(aLabel + '.testnzc_pd', (not LExpectedZ) and (not LExpectedC), avx_testnzc_pd256(aLeft, aRight));
end;

procedure TTestCase_AvxFacadeExperimental.Test_CmpPs256_PredicateMasks;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
  LExtraIndex: Integer;
begin
  InitCmpPsInputs(LA, LB);

  for LImm := 0 to 31 do
  begin
    LExpected := ReferenceCmpPs256(LA, LB, Byte(LImm));
    LActual := avx_cmp_ps256(LA, LB, Byte(LImm));
    AssertM256DWordsEqual(Self, 'avx_cmp_ps256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;

  for LExtraIndex := Low(EXTRA_COMPARE_IMMS) to High(EXTRA_COMPARE_IMMS) do
  begin
    LExpected := ReferenceCmpPs256(LA, LB, EXTRA_COMPARE_IMMS[LExtraIndex]);
    LActual := avx_cmp_ps256(LA, LB, EXTRA_COMPARE_IMMS[LExtraIndex]);
    AssertM256DWordsEqual(Self,
      'avx_cmp_ps256 imm=' + IntToStr(EXTRA_COMPARE_IMMS[LExtraIndex]) +
      ' normalized=' + IntToStr(EXTRA_COMPARE_IMMS[LExtraIndex] and $1F),
      LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_CmpPd256_PredicateMasks;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
  LExtraIndex: Integer;
begin
  InitCmpPdInputs(LA, LB);

  for LImm := 0 to 31 do
  begin
    LExpected := ReferenceCmpPd256(LA, LB, Byte(LImm));
    LActual := avx_cmp_pd256(LA, LB, Byte(LImm));
    AssertM256QWordsEqual(Self, 'avx_cmp_pd256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;

  for LExtraIndex := Low(EXTRA_COMPARE_IMMS) to High(EXTRA_COMPARE_IMMS) do
  begin
    LExpected := ReferenceCmpPd256(LA, LB, EXTRA_COMPARE_IMMS[LExtraIndex]);
    LActual := avx_cmp_pd256(LA, LB, EXTRA_COMPARE_IMMS[LExtraIndex]);
    AssertM256QWordsEqual(Self,
      'avx_cmp_pd256 imm=' + IntToStr(EXTRA_COMPARE_IMMS[LExtraIndex]) +
      ' normalized=' + IntToStr(EXTRA_COMPARE_IMMS[LExtraIndex] and $1F),
      LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_BlendPs256_ImmediateLaneSelection;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  for LIndex := 0 to 7 do
  begin
    LA.m256i_u32[LIndex] := DWord($11111111) * DWord(LIndex + 1);
    LB.m256i_u32[LIndex] := DWord($AAAA0000) + DWord(LIndex * $1111);
  end;

  for LImm := 0 to 255 do
  begin
    FillChar(LExpected, SizeOf(LExpected), 0);
    for LIndex := 0 to 7 do
      if ((LImm shr LIndex) and 1) <> 0 then
        LExpected.m256i_u32[LIndex] := LB.m256i_u32[LIndex]
      else
        LExpected.m256i_u32[LIndex] := LA.m256i_u32[LIndex];

    LActual := avx_blend_ps256(LA, LB, Byte(LImm));
    AssertM256DWordsEqual(Self, 'avx_blend_ps256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_BlendPd256_ImmediateLaneSelection;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  for LIndex := 0 to 3 do
  begin
    LA.m256i_u64[LIndex] := QWord($1111111111111111) * QWord(LIndex + 1);
    LB.m256i_u64[LIndex] := QWord($AAAABBBB00000000) + QWord(LIndex * $11111111);
  end;

  for LImm := 0 to 255 do
  begin
    FillChar(LExpected, SizeOf(LExpected), 0);
    for LIndex := 0 to 3 do
      if ((LImm shr LIndex) and 1) <> 0 then
        LExpected.m256i_u64[LIndex] := LB.m256i_u64[LIndex]
      else
        LExpected.m256i_u64[LIndex] := LA.m256i_u64[LIndex];

    LActual := avx_blend_pd256(LA, LB, Byte(LImm));
    AssertM256QWordsEqual(Self, 'avx_blend_pd256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_BlendvPs256_SignBitSelection;
var
  LA: TM256;
  LB: TM256;
  LMask: TM256;
  LExpected: TM256;
  LActual: TM256;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  FillChar(LMask, SizeOf(LMask), 0);
  for LIndex := 0 to 7 do
  begin
    LA.m256i_u32[LIndex] := DWord($01020304) * DWord(LIndex + 1);
    LB.m256i_u32[LIndex] := DWord($F0E0D0C0) - DWord(LIndex * $01010101);
  end;

  LMask.m256i_u32[0] := $00000000;
  LMask.m256i_u32[1] := $7FFFFFFF;
  LMask.m256i_u32[2] := $80000000;
  LMask.m256i_u32[3] := $FFFFFFFF;
  LMask.m256i_u32[4] := $01234567;
  LMask.m256i_u32[5] := $89ABCDEF;
  LMask.m256i_u32[6] := $40000000;
  LMask.m256i_u32[7] := $C0000000;

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 7 do
    if (LMask.m256i_u32[LIndex] and $80000000) <> 0 then
      LExpected.m256i_u32[LIndex] := LB.m256i_u32[LIndex]
    else
      LExpected.m256i_u32[LIndex] := LA.m256i_u32[LIndex];

  LActual := avx_blendv_ps256(LA, LB, LMask);
  AssertM256DWordsEqual(Self, 'avx_blendv_ps256', LExpected, LActual);
end;

procedure TTestCase_AvxFacadeExperimental.Test_BlendvPd256_SignBitSelection;
var
  LA: TM256;
  LB: TM256;
  LMask: TM256;
  LExpected: TM256;
  LActual: TM256;
  LIndex: Integer;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  FillChar(LMask, SizeOf(LMask), 0);
  for LIndex := 0 to 3 do
  begin
    LA.m256i_u64[LIndex] := QWord($0102030405060708) * QWord(LIndex + 1);
    LB.m256i_u64[LIndex] := QWord($FFEEDDCCBBAA9988) - QWord(LIndex * $0011223344556677);
  end;

  LMask.m256i_u64[0] := $0000000000000000;
  LMask.m256i_u64[1] := $7FFFFFFFFFFFFFFF;
  LMask.m256i_u64[2] := $8000000000000000;
  LMask.m256i_u64[3] := $FFFFFFFFFFFFFFFF;

  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 3 do
    if (LMask.m256i_u64[LIndex] and QWord($8000000000000000)) <> 0 then
      LExpected.m256i_u64[LIndex] := LB.m256i_u64[LIndex]
    else
      LExpected.m256i_u64[LIndex] := LA.m256i_u64[LIndex];

  LActual := avx_blendv_pd256(LA, LB, LMask);
  AssertM256QWordsEqual(Self, 'avx_blendv_pd256', LExpected, LActual);
end;

procedure TTestCase_AvxFacadeExperimental.Test_ShufflePs256_ImmediateLaneSelection;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
begin
  InitU32Lanes(LA, $10000000);
  InitU32Lanes(LB, $B0000000);

  for LImm := 0 to 255 do
  begin
    LExpected := ReferenceShufflePs256(LA, LB, Byte(LImm));
    LActual := avx_shuffle_ps256(LA, LB, Byte(LImm));
    AssertM256DWordsEqual(Self, 'avx_shuffle_ps256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_ShufflePd256_ImmediateLaneSelection;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
begin
  InitU64Lanes(LA, QWord($1000000000000000));
  InitU64Lanes(LB, QWord($B000000000000000));

  for LImm := 0 to 255 do
  begin
    LExpected := ReferenceShufflePd256(LA, LB, Byte(LImm));
    LActual := avx_shuffle_pd256(LA, LB, Byte(LImm));
    AssertM256QWordsEqual(Self, 'avx_shuffle_pd256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_PermutePs256_ImmediateLaneSelection;
var
  LA: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
begin
  InitU32Lanes(LA, $21000000);

  for LImm := 0 to 255 do
  begin
    LExpected := ReferencePermutePs256(LA, Byte(LImm));
    LActual := avx_permute_ps256(LA, Byte(LImm));
    AssertM256DWordsEqual(Self, 'avx_permute_ps256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_PermutePd256_ImmediateLaneSelection;
var
  LA: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
begin
  InitU64Lanes(LA, QWord($2200000000000000));

  for LImm := 0 to 255 do
  begin
    LExpected := ReferencePermutePd256(LA, Byte(LImm));
    LActual := avx_permute_pd256(LA, Byte(LImm));
    AssertM256QWordsEqual(Self, 'avx_permute_pd256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_Permute2F128Ps256_ImmediateLaneSelection;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
begin
  InitU32Lanes(LA, $31000000);
  InitU32Lanes(LB, $B1000000);

  for LImm := 0 to 255 do
  begin
    LExpected := ReferencePermute2F128256(LA, LB, Byte(LImm));
    LActual := avx_permute2f128_ps256(LA, LB, Byte(LImm));
    AssertM256DWordsEqual(Self, 'avx_permute2f128_ps256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_Permute2F128Pd256_ImmediateLaneSelection;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
  LImm: Integer;
begin
  InitU64Lanes(LA, QWord($3200000000000000));
  InitU64Lanes(LB, QWord($B200000000000000));

  for LImm := 0 to 255 do
  begin
    LExpected := ReferencePermute2F128256(LA, LB, Byte(LImm));
    LActual := avx_permute2f128_pd256(LA, LB, Byte(LImm));
    AssertM256QWordsEqual(Self, 'avx_permute2f128_pd256 imm=' + IntToStr(LImm), LExpected, LActual);
  end;
end;

procedure TTestCase_AvxFacadeExperimental.Test_UnpackPs256_LaneInterleave;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
begin
  InitU32Lanes(LA, $41000000);
  InitU32Lanes(LB, $C1000000);

  LExpected := ReferenceUnpackLoPs256(LA, LB);
  LActual := avx_unpacklo_ps256(LA, LB);
  AssertM256DWordsEqual(Self, 'avx_unpacklo_ps256', LExpected, LActual);

  LExpected := ReferenceUnpackHiPs256(LA, LB);
  LActual := avx_unpackhi_ps256(LA, LB);
  AssertM256DWordsEqual(Self, 'avx_unpackhi_ps256', LExpected, LActual);
end;

procedure TTestCase_AvxFacadeExperimental.Test_UnpackPd256_LaneInterleave;
var
  LA: TM256;
  LB: TM256;
  LExpected: TM256;
  LActual: TM256;
begin
  InitU64Lanes(LA, QWord($4200000000000000));
  InitU64Lanes(LB, QWord($C200000000000000));

  LExpected := ReferenceUnpackLoPd256(LA, LB);
  LActual := avx_unpacklo_pd256(LA, LB);
  AssertM256QWordsEqual(Self, 'avx_unpacklo_pd256', LExpected, LActual);

  LExpected := ReferenceUnpackHiPd256(LA, LB);
  LActual := avx_unpackhi_pd256(LA, LB);
  AssertM256QWordsEqual(Self, 'avx_unpackhi_pd256', LExpected, LActual);
end;

procedure TTestCase_AvxFacadeExperimental.Test_TestPs256_SignBitPredicates;
var
  LA: TM256;
  LB: TM256;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  AssertAvxTestPsCase(Self, 'ps empty', LA, LB);

  LA.m256i_u32[0] := $80000000;
  LA.m256i_u32[2] := $80000002;
  LB.m256i_u32[4] := $80000004;
  LB.m256i_u32[6] := $80000006;
  AssertAvxTestPsCase(Self, 'ps disjoint-signs', LA, LB);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m256i_u32[0] := $80000000;
  LA.m256i_u32[2] := $80000002;
  LB.m256i_u32[0] := $80000000;
  LB.m256i_u32[1] := $80000001;
  AssertAvxTestPsCase(Self, 'ps overlap-and-uncovered', LA, LB);

  FillChar(LA, SizeOf(LA), $FF);
  FillChar(LB, SizeOf(LB), 0);
  LB.m256i_u32[1] := $80000001;
  LB.m256i_u32[7] := $80000007;
  AssertAvxTestPsCase(Self, 'ps covered-signs', LA, LB);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m256i_u32[3] := $7FFFFFFF;
  LB.m256i_u32[3] := $7FFFFFFF;
  AssertAvxTestPsCase(Self, 'ps non-sign-payload-ignored', LA, LB);
end;

procedure TTestCase_AvxFacadeExperimental.Test_TestPd256_SignBitPredicates;
var
  LA: TM256;
  LB: TM256;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  AssertAvxTestPdCase(Self, 'pd empty', LA, LB);

  LA.m256i_u64[0] := $8000000000000000;
  LB.m256i_u64[2] := $8000000000000002;
  AssertAvxTestPdCase(Self, 'pd disjoint-signs', LA, LB);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m256i_u64[0] := $8000000000000000;
  LA.m256i_u64[2] := $8000000000000002;
  LB.m256i_u64[0] := $8000000000000000;
  LB.m256i_u64[1] := $8000000000000001;
  AssertAvxTestPdCase(Self, 'pd overlap-and-uncovered', LA, LB);

  FillChar(LA, SizeOf(LA), $FF);
  FillChar(LB, SizeOf(LB), 0);
  LB.m256i_u64[1] := $8000000000000001;
  LB.m256i_u64[3] := $8000000000000003;
  AssertAvxTestPdCase(Self, 'pd covered-signs', LA, LB);

  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  LA.m256i_u64[3] := $7FFFFFFFFFFFFFFF;
  LB.m256i_u64[3] := $7FFFFFFFFFFFFFFF;
  AssertAvxTestPdCase(Self, 'pd non-sign-payload-ignored', LA, LB);
end;

initialization
  RegisterTest(TTestCase_AvxFacadeExperimental);

end.
