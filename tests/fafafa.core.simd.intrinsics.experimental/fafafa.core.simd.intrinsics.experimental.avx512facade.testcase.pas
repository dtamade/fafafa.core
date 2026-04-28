unit fafafa.core.simd.intrinsics.experimental.avx512facade.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.avx512;

type
  TTestCase_Avx512FacadeExperimental = class(TTestCase)
  published
    procedure Test_avx512_load_ps512;
    procedure Test_avx512_loadu_ps512;
    procedure Test_avx512_store_ps512;
    procedure Test_avx512_storeu_ps512;
    procedure Test_avx512_setzero_ps512;
    procedure Test_avx512_set1_ps512;
    procedure Test_avx512_add_ps512;
    procedure Test_avx512_sub_ps512;
    procedure Test_avx512_mul_ps512;
    procedure Test_avx512_div_ps512;
    procedure Test_avx512_mask_add_ps512;
    procedure Test_avx512_maskz_add_ps512;
  end;

implementation

procedure InitM512Pattern(var aValue: TM512; aBase: DWord);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 15 do
    aValue.m512i_u32[LIndex] := aBase + DWord(LIndex * $01010101);
end;

procedure InitM512Singles(var aValue: TM512; aBase, aStep: Single);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 0 to 15 do
    aValue.m512_f32[LIndex] := aBase + aStep * LIndex;
end;

procedure AssertM512DWordsEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM512);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), QWord(aExpected.m512i_u32[LIndex]), QWord(aActual.m512i_u32[LIndex]));
end;

procedure AssertM512SinglesEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM512);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m512_f32[LIndex], aActual.m512_f32[LIndex], 0.00001);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_load_ps512;
var
  LInput: TM512;
  LActual: TM512;
begin
  InitM512Pattern(LInput, $10203040);

  LActual := avx512_load_ps512(@LInput);

  AssertM512DWordsEqual(Self, 'load_ps512', LInput, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_loadu_ps512;
var
  LInput: TM512;
  LActual: TM512;
begin
  InitM512Pattern(LInput, $A0B0C000);

  LActual := avx512_loadu_ps512(@LInput);

  AssertM512DWordsEqual(Self, 'loadu_ps512', LInput, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_store_ps512;
var
  LInput: TM512;
  LActual: TM512;
begin
  InitM512Pattern(LInput, $01020304);
  FillChar(LActual, SizeOf(LActual), $A5);

  avx512_store_ps512(LActual, LInput);

  AssertM512DWordsEqual(Self, 'store_ps512', LInput, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_storeu_ps512;
var
  LInput: TM512;
  LActual: TM512;
begin
  InitM512Pattern(LInput, $55667788);
  FillChar(LActual, SizeOf(LActual), $5A);

  avx512_storeu_ps512(LActual, LInput);

  AssertM512DWordsEqual(Self, 'storeu_ps512', LInput, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_setzero_ps512;
var
  LExpected: TM512;
  LActual: TM512;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);

  LActual := avx512_setzero_ps512;

  AssertM512DWordsEqual(Self, 'setzero_ps512', LExpected, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_set1_ps512;
var
  LExpected: TM512;
  LActual: TM512;
  LIndex: Integer;
begin
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m512_f32[LIndex] := -3.5;

  LActual := avx512_set1_ps512(-3.5);

  AssertM512SinglesEqual(Self, 'set1_ps512', LExpected, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_add_ps512;
var
  LLeft: TM512;
  LRight: TM512;
  LExpected: TM512;
  LActual: TM512;
  LIndex: Integer;
begin
  InitM512Singles(LLeft, -8.0, 0.5);
  InitM512Singles(LRight, 2.0, 1.25);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m512_f32[LIndex] := LLeft.m512_f32[LIndex] + LRight.m512_f32[LIndex];

  LActual := avx512_add_ps512(LLeft, LRight);

  AssertM512SinglesEqual(Self, 'add_ps512', LExpected, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_sub_ps512;
var
  LLeft: TM512;
  LRight: TM512;
  LExpected: TM512;
  LActual: TM512;
  LIndex: Integer;
begin
  InitM512Singles(LLeft, 10.0, 0.75);
  InitM512Singles(LRight, 3.0, -0.25);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m512_f32[LIndex] := LLeft.m512_f32[LIndex] - LRight.m512_f32[LIndex];

  LActual := avx512_sub_ps512(LLeft, LRight);

  AssertM512SinglesEqual(Self, 'sub_ps512', LExpected, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_mul_ps512;
var
  LLeft: TM512;
  LRight: TM512;
  LExpected: TM512;
  LActual: TM512;
  LIndex: Integer;
begin
  InitM512Singles(LLeft, -4.0, 0.5);
  InitM512Singles(LRight, 0.25, 0.25);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m512_f32[LIndex] := LLeft.m512_f32[LIndex] * LRight.m512_f32[LIndex];

  LActual := avx512_mul_ps512(LLeft, LRight);

  AssertM512SinglesEqual(Self, 'mul_ps512', LExpected, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_div_ps512;
var
  LLeft: TM512;
  LRight: TM512;
  LExpected: TM512;
  LActual: TM512;
  LIndex: Integer;
begin
  InitM512Singles(LLeft, 16.0, 2.0);
  InitM512Singles(LRight, 2.0, 0.5);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    LExpected.m512_f32[LIndex] := LLeft.m512_f32[LIndex] / LRight.m512_f32[LIndex];

  LActual := avx512_div_ps512(LLeft, LRight);

  AssertM512SinglesEqual(Self, 'div_ps512', LExpected, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_mask_add_ps512;
var
  LSource: TM512;
  LLeft: TM512;
  LRight: TM512;
  LExpected: TM512;
  LActual: TM512;
  LIndex: Integer;
const
  MASK = UInt16($A55A);
begin
  InitM512Singles(LSource, 100.0, 1.0);
  InitM512Singles(LLeft, -5.0, 0.5);
  InitM512Singles(LRight, 10.0, 2.0);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    if (MASK and (UInt16(1) shl LIndex)) <> 0 then
      LExpected.m512_f32[LIndex] := LLeft.m512_f32[LIndex] + LRight.m512_f32[LIndex]
    else
      LExpected.m512_f32[LIndex] := LSource.m512_f32[LIndex];

  LActual := avx512_mask_add_ps512(LSource, LLeft, LRight, MASK);

  AssertM512SinglesEqual(Self, 'mask_add_ps512', LExpected, LActual);
end;

procedure TTestCase_Avx512FacadeExperimental.Test_avx512_maskz_add_ps512;
var
  LLeft: TM512;
  LRight: TM512;
  LExpected: TM512;
  LActual: TM512;
  LIndex: Integer;
const
  MASK = UInt16($0F0F);
begin
  InitM512Singles(LLeft, 1.0, 1.0);
  InitM512Singles(LRight, 20.0, -0.5);
  FillChar(LExpected, SizeOf(LExpected), 0);
  for LIndex := 0 to 15 do
    if (MASK and (UInt16(1) shl LIndex)) <> 0 then
      LExpected.m512_f32[LIndex] := LLeft.m512_f32[LIndex] + LRight.m512_f32[LIndex]
    else
      LExpected.m512_f32[LIndex] := 0.0;

  LActual := avx512_maskz_add_ps512(LLeft, LRight, MASK);

  AssertM512SinglesEqual(Self, 'maskz_add_ps512', LExpected, LActual);
end;

initialization
  RegisterTest(TTestCase_Avx512FacadeExperimental);

end.
