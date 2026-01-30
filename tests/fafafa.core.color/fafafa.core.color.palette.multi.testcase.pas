unit fafafa.core.color.palette.multi.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PaletteMulti = class(TTestCase)
  published
    procedure Test_Palette_Multi_Endpoints_And_Mid;
    procedure Test_Palette_Multi_OKLCH_Shortest;
  end;

implementation

procedure TTestCase_PaletteMulti.Test_Palette_Multi_Endpoints_And_Mid;
var colors: array[0..2] of color_rgba_t; m: color_rgba_t;
begin
  colors[0] := COLOR_RED; colors[1] := COLOR_GREEN; colors[2] := COLOR_BLUE;
  m := palette_sample_multi(colors, 0.0, PIM_SRGB);
  AssertEquals(colors[0].r, m.r);
  m := palette_sample_multi(colors, 1.0, PIM_SRGB);
  AssertEquals(colors[2].b, m.b);
  m := palette_sample_multi(colors, 0.6, PIM_SRGB);
  // 0.6 落在中段（GREEN->BLUE），结果不等于端点
  AssertTrue((m.r<>colors[1].r) or (m.g<>colors[1].g) or (m.b<>colors[1].b));
  AssertTrue((m.r<>colors[2].r) or (m.g<>colors[2].g) or (m.b<>colors[2].b));
end;

procedure TTestCase_PaletteMulti.Test_Palette_Multi_OKLCH_Shortest;
var colors: array[0..2] of color_rgba_t; lch: color_oklch_t; m: color_rgba_t;
begin
  lch.L := 0.7; lch.C := 0.2; lch.h := 350; colors[0] := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.2; lch.h := 10;  colors[1] := color_from_oklch(lch);
  colors[2] := COLOR_WHITE;
  m := palette_sample_multi(colors, 0.25, PIM_OKLCH, True);
  // 0.25 落在 [0]->[1] 段，验证不等于段端点
  AssertTrue((m.r<>colors[0].r) or (m.g<>colors[0].g) or (m.b<>colors[0].b));
  AssertTrue((m.r<>colors[1].r) or (m.g<>colors[1].g) or (m.b<>colors[1].b));
end;

initialization
  RegisterTest(TTestCase_PaletteMulti);

end.

