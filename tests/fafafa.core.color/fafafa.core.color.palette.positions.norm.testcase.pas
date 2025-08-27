unit fafafa.core.color.palette.positions.norm.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PalettePositionsNorm = class(TTestCase)
  published
    procedure Test_Positions_Normalize_To_01;
  end;

implementation

procedure TTestCase_PalettePositionsNorm.Test_Positions_Normalize_To_01;
var colors: array[0..2] of color_rgba_t; pos: array[0..2] of Single; m: color_rgba_t;
begin
  colors[0] := COLOR_RED; colors[1] := COLOR_GREEN; colors[2] := COLOR_BLUE;
  pos[0] := 10.0; pos[1] := 20.0; pos[2] := 70.0;
  // t=15 应归一化为 0.125，位于第一段中部
  m := palette_sample_multi_with_positions(colors, pos, 15.0, PIM_SRGB, False, True);
  AssertTrue((m.r<>colors[0].r) or (m.g<>colors[0].g) or (m.b<>colors[0].b));
  AssertTrue((m.r<>colors[1].r) or (m.g<>colors[1].g) or (m.b<>colors[1].b));
  // t 超出范围，按边界裁剪
  m := palette_sample_multi_with_positions(colors, pos, 5.0, PIM_SRGB, False, True);
  AssertEquals(colors[0].r, m.r);
  m := palette_sample_multi_with_positions(colors, pos, 80.0, PIM_SRGB, False, True);
  AssertEquals(colors[2].b, m.b);
end;

initialization
  RegisterTest(TTestCase_PalettePositionsNorm);

end.

