unit fafafa.core.color.advanced.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_Advanced = class(TTestCase)
  published
    procedure Test_HexRGBA_Output;
    procedure Test_BlendOver_Basic;
    procedure Test_BlendOver_Linear_Behavior;
    procedure Test_Mix_sRGB_and_Linear_Endpoints;
    procedure Test_Lighten_Darken_Bounds;
    procedure Test_BestContrast_From_Palette;
  end;

implementation

procedure TTestCase_Advanced.Test_HexRGBA_Output;
var c: color_rgba_t;
begin
  c := color_rgba(1,2,3,4);
  AssertEquals('#01020304', LowerCase(color_to_hex_rgba(c)));
end;

procedure TTestCase_Advanced.Test_BlendOver_Basic;
var fg,bg,outc: color_rgba_t;
begin
  fg := color_rgba(255,0,0,128); // 半透明红
  bg := COLOR_WHITE;
  outc := color_blend_over(fg, bg);
  AssertTrue(outc.r > outc.g);
  AssertTrue(outc.g = outc.b);
  AssertEquals(255, outc.a);

end;

procedure TTestCase_Advanced.Test_BlendOver_Linear_Behavior;
var fg,bg,lin,srgb: color_rgba_t;
begin
  // 半透明红覆盖灰背景：线性光域合成应比 sRGB 合成更暗一些（更物理正确）
  fg := color_rgba(255,0,0,128);
  bg := color_rgb(128,128,128);
  srgb := color_blend_over(fg, bg);
  lin  := color_blend_over_linear(fg, bg);
  // 相对比较：此场景下线性光域合成各通道通常高于 sRGB 合成（压缩伽马导致 sRGB 中值偏低）
  AssertTrue(lin.r >= srgb.r);
  AssertTrue(lin.g >= srgb.g);
  AssertTrue(lin.b >= srgb.b);
  AssertEquals(255, lin.a);
end;

procedure TTestCase_Advanced.Test_Mix_sRGB_and_Linear_Endpoints;
var a,b,m1,m2: color_rgba_t;
begin
  a := color_rgb(0,0,0);
  b := color_rgb(255,255,255);
  m1 := color_mix_srgb(a,b,0.0);  AssertEquals(0, m1.r);
  m1 := color_mix_srgb(a,b,1.0);  AssertEquals(255, m1.r);
  m2 := color_mix_linear(a,b,0.0);AssertEquals(0, m2.r);
  m2 := color_mix_linear(a,b,1.0);AssertEquals(255, m2.r);
end;

procedure TTestCase_Advanced.Test_Lighten_Darken_Bounds;
var c1,c2: color_rgba_t;
begin
  c1 := color_rgb(10,20,30);
  c2 := color_lighten(c1, 100);
  AssertEquals(255*3, c2.r + c2.g + c2.b); // 应为白
  c2 := color_darken(c1, 100);
  AssertEquals(0, c2.r + c2.g + c2.b);     // 应为黑
end;

procedure TTestCase_Advanced.Test_BestContrast_From_Palette;
var bg, res: color_rgba_t; palette: array[0..2] of color_rgba_t;
begin
  bg := color_rgb(200, 200, 200);
  palette[0] := COLOR_RED; palette[1] := COLOR_BLACK; palette[2] := COLOR_BLUE;
  res := color_best_contrast(bg, palette);
  AssertEquals(0, res.r); // 黑对比度应最高
end;

initialization
  RegisterTest(TTestCase_Advanced);

end.

