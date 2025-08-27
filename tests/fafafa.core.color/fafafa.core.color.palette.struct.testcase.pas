unit fafafa.core.color.palette.struct.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PaletteStruct = class(TTestCase)
  published
    procedure Test_Even_Init_Endpoints_And_Mid;
    procedure Test_Positions_Init_Basic;
  end;

implementation

procedure TTestCase_PaletteStruct.Test_Even_Init_Endpoints_And_Mid;
var p: color_palette_t; c0,c1,mid: color_rgba_t; arr: array[0..1] of color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_BLUE;
  palette_init_even(p, PIM_SRGB, arr);
  c0 := palette_sample_struct(p, 0.0);
  c1 := palette_sample_struct(p, 1.0);
  mid := palette_sample_struct(p, 0.5);
  AssertEquals(COLOR_RED.r, c0.r);
  AssertEquals(COLOR_BLUE.b, c1.b);
  AssertTrue((mid.r<>c0.r) or (mid.b<>c1.b));
end;

procedure TTestCase_PaletteStruct.Test_Positions_Init_Basic;
var p: color_palette_t; arr: array[0..2] of color_rgba_t; pos: array[0..2] of Single; c: color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  pos[0] := 10; pos[1] := 20; pos[2] := 70;
  palette_init_with_positions(p, PIM_SRGB, arr, pos, True, True);
  c := palette_sample_struct(p, 15);
  // 只验证可调用与返回在 0..255
  AssertTrue((c.r>=0) and (c.r<=255));
end;

initialization
  RegisterTest(TTestCase_PaletteStruct);

end.

