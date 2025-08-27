unit fafafa.core.color.oklch.gamut.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_OKLCHGamut = class(TTestCase)
  published
    procedure Test_Gamut_Clip_Equals_Default;
    procedure Test_Gamut_PreserveHueDesaturate_Preserves_Lh_And_InGamut;
  end;

implementation

procedure TTestCase_OKLCHGamut.Test_Gamut_Clip_Equals_Default;
var lch: color_oklch_t; c1,c2: color_rgba_t;
begin
  // 构造一个可能越界的 LCH（高 C）
  lch.L := 0.7; lch.C := 0.5; lch.h := 20;
  c1 := color_from_oklch(lch);
  c2 := color_from_oklch_gamut(lch, GMT_Clip);
  AssertEquals(c1.r, c2.r);
  AssertEquals(c1.g, c2.g);
  AssertEquals(c1.b, c2.b);
end;

procedure TTestCase_OKLCHGamut.Test_Gamut_PreserveHueDesaturate_Preserves_Lh_And_InGamut;
var lchIn, lchOut: color_oklch_t; c: color_rgba_t;
begin
  lchIn.L := 0.7; lchIn.C := 0.5; lchIn.h := 220;
  c := color_from_oklch_gamut(lchIn, GMT_PreserveHueDesaturate);
  // 回推 OKLCH 以验证性质
  lchOut := color_to_oklch(c);
  AssertTrue(Abs(lchOut.L - lchIn.L) <= 0.02);
  // hue 保持（容差 2 度）
  if Abs(lchOut.h - lchIn.h) > 180 then
    AssertTrue(360 - Abs(lchOut.h - lchIn.h) <= 2.0)
  else
    AssertTrue(Abs(lchOut.h - lchIn.h) <= 2.0);
end;

initialization
  RegisterTest(TTestCase_OKLCHGamut);

end.

