unit fafafa.core.color.palette.struct.props.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PaletteStructProps = class(TTestCase)
  published
    procedure Test_Struct_Even_Endpoints_Idempotent;
    procedure Test_Struct_Positions_Equivalence_With_Functional;
    procedure Test_Struct_OKLCH_Shortest_Hue_Wrap;
  end;

implementation

procedure TTestCase_PaletteStructProps.Test_Struct_Even_Endpoints_Idempotent;
var p: color_palette_t; arr: array[0..2] of color_rgba_t; c0,c1: color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  palette_init_even(p, PIM_SRGB, arr, True);
  c0 := palette_sample_struct(p, 0.0);
  c1 := palette_sample_struct(p, 1.0);
  AssertEquals(arr[0].r, c0.r);
  AssertEquals(arr[2].b, c1.b);
end;

procedure TTestCase_PaletteStructProps.Test_Struct_Positions_Equivalence_With_Functional;
var p: color_palette_t; arr: array[0..2] of color_rgba_t; pos: array[0..2] of Single; tf: Single; cs, cf: color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  pos[0] := 10; pos[1] := 20; pos[2] := 70;
  palette_init_with_positions(p, PIM_OKLAB, arr, pos, True, True);
  tf := 15.0;
  cs := palette_sample_struct(p, tf);
  cf := palette_sample_multi_with_positions(arr, pos, tf, PIM_OKLAB, True, True);
  AssertTrue(Abs(Integer(cs.r)-Integer(cf.r))<=1);
  AssertTrue(Abs(Integer(cs.g)-Integer(cf.g))<=1);
  AssertTrue(Abs(Integer(cs.b)-Integer(cf.b))<=1);
end;

procedure TTestCase_PaletteStructProps.Test_Struct_OKLCH_Shortest_Hue_Wrap;
var p: color_palette_t; arr: array[0..1] of color_rgba_t; lch: color_oklch_t; mid: color_oklch_t; m: color_rgba_t;
begin
  lch.L := 0.7; lch.C := 0.2; lch.h := 350; arr[0] := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.2; lch.h := 10;  arr[1] := color_from_oklch(lch);
  palette_init_even(p, PIM_OKLCH, arr, True);
  m := palette_sample_struct(p, 0.5);
  mid := color_to_oklch(m);
  AssertTrue((mid.h <= 40) or (mid.h >= 320));
end;

initialization
  RegisterTest(TTestCase_PaletteStructProps);

end.

