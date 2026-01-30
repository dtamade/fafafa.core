unit fafafa.core.color.palette.strategy.fixup.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.color;

type
  TTestCase_PaletteStrategy_Fixup = class(TTestCase)
  published
    procedure Test_Fixup_MakeNonDecreasing;
    procedure Test_Fixup_Normalize_To01;
  end;

implementation

procedure TTestCase_PaletteStrategy_Fixup.Test_Fixup_MakeNonDecreasing;
var S: IPaletteStrategy; arr: array[0..2] of color_rgba_t; pos: array[0..2] of Single;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  pos[0] := 10; pos[1] := 5; pos[2] := 2; // 递减
  S := TPaletteStrategy.CreateWithPositions(PIM_SRGB, arr, pos, True, False);
  AssertTrue(S.FixupPositions(True, False));
  AssertTrue(S.PositionAt(1) >= S.PositionAt(0));
  AssertTrue(S.PositionAt(2) >= S.PositionAt(1));
end;

procedure TTestCase_PaletteStrategy_Fixup.Test_Fixup_Normalize_To01;
var S: IPaletteStrategy; arr: array[0..2] of color_rgba_t; pos: array[0..2] of Single;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  pos[0] := 10; pos[1] := 20; pos[2] := 70;
  S := TPaletteStrategy.CreateWithPositions(PIM_SRGB, arr, pos, True, False);
  AssertTrue(S.FixupPositions(False, True));
  AssertTrue(Abs(S.PositionAt(0) - 0.0) < 1e-5);
  AssertTrue(Abs(S.PositionAt(2) - 1.0) < 1e-5);
end;

initialization
  RegisterTest(TTestCase_PaletteStrategy_Fixup);

end.

