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

initialization
  RegisterTest(TTestCase_AvxFacadeExperimental);

end.
