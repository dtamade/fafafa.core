unit fafafa.core.color.palette.props.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PaletteProps = class(TTestCase)
  published
    procedure Test_Multi_Endpoints_Idempotent;
    procedure Test_Multi_Segment_Midpoint_Monotonic_SRGB;
    procedure Test_Multi_OKLCH_HueWrap_Shortest;
  end;

implementation

procedure TTestCase_PaletteProps.Test_Multi_Endpoints_Idempotent;
var colors: array[0..3] of color_rgba_t; m: color_rgba_t;
begin
  colors[0] := COLOR_RED; colors[1] := COLOR_GREEN; colors[2] := COLOR_BLUE; colors[3] := COLOR_WHITE;
  m := palette_sample_multi(colors, 0.0, PIM_SRGB);
  AssertEquals(colors[0].r, m.r);
  m := palette_sample_multi(colors, 1.0, PIM_SRGB);
  AssertEquals(colors[3].r, m.r);
end;

procedure TTestCase_PaletteProps.Test_Multi_Segment_Midpoint_Monotonic_SRGB;
var colors: array[0..2] of color_rgba_t; m: color_rgba_t;
begin
  colors[0] := color_rgb(0,0,0);
  colors[1] := color_rgb(128,128,128);
  colors[2] := color_rgb(255,255,255);
  // t=0.5 -> 第二段中点
  m := palette_sample_multi(colors, 0.5, PIM_SRGB);
  AssertTrue((m.r >= colors[1].r) and (m.r <= colors[2].r));
end;

procedure TTestCase_PaletteProps.Test_Multi_OKLCH_HueWrap_Shortest;
var colors: array[0..2] of color_rgba_t; lch: color_oklch_t; mid: color_oklch_t; m: color_rgba_t;
begin
  // 第一段 350 -> 10，使用最短路径应跨 0°
  lch.L := 0.7; lch.C := 0.2; lch.h := 350; colors[0] := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.2; lch.h := 10;  colors[1] := color_from_oklch(lch);
  colors[2] := COLOR_WHITE;
  m := palette_sample_multi(colors, 0.25, PIM_OKLCH, True);
  mid := color_to_oklch(m);
  AssertTrue((mid.h <= 40) or (mid.h >= 320));
end;

initialization
  RegisterTest(TTestCase_PaletteProps);

end.

