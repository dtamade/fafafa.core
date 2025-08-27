unit fafafa.core.color.palette.positions.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PalettePositions = class(TTestCase)
  published
    procedure Test_Positions_Basic;
    procedure Test_Positions_NonIncreasing_Fallback;
  end;

implementation

procedure TTestCase_PalettePositions.Test_Positions_Basic;
var colors: array[0..2] of color_rgba_t; pos: array[0..2] of Single; m: color_rgba_t;
begin
  colors[0] := COLOR_RED; colors[1] := COLOR_GREEN; colors[2] := COLOR_BLUE;
  pos[0] := 0.0; pos[1] := 0.2; pos[2] := 1.0;
  m := palette_sample_multi_with_positions(colors, pos, 0.1, PIM_SRGB);
  // 0.1 落在 [0,0.2] 段中，结果不等于端点
  AssertTrue((m.r<>colors[0].r) or (m.g<>colors[0].g) or (m.b<>colors[0].b));
  AssertTrue((m.r<>colors[1].r) or (m.g<>colors[1].g) or (m.b<>colors[1].b));
  // 边界
  m := palette_sample_multi_with_positions(colors, pos, 0.0, PIM_SRGB);
  AssertEquals(colors[0].r, m.r);
  m := palette_sample_multi_with_positions(colors, pos, 1.0, PIM_SRGB);
  AssertEquals(colors[2].b, m.b);
end;

procedure TTestCase_PalettePositions.Test_Positions_NonIncreasing_Fallback;
var colors: array[0..2] of color_rgba_t; pos: array[0..2] of Single; m: color_rgba_t;
begin
  colors[0] := COLOR_RED; colors[1] := COLOR_GREEN; colors[2] := COLOR_BLUE;
  pos[0] := 0.0; pos[1] := 0.0; pos[2] := 1.0; // 非严格递增
  m := palette_sample_multi_with_positions(colors, pos, 0.0, PIM_SRGB);
  AssertEquals(colors[0].r, m.r);
  m := palette_sample_multi_with_positions(colors, pos, 0.01, PIM_SRGB);
  // pos[1]-pos[0]=0 导致第一个段长度为0；t=0.01 落在第二段 [0.0,1.0]，应在 [colors[1],colors[2]] 内插
  AssertTrue((m.r<>colors[1].r) or (m.g<>colors[1].g) or (m.b<>colors[1].b));
  AssertTrue((m.r<>colors[2].r) or (m.g<>colors[2].g) or (m.b<>colors[2].b));
end;

initialization
  RegisterTest(TTestCase_PalettePositions);

end.

