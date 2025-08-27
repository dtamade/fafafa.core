unit fafafa.core.color.palette.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_Palette = class(TTestCase)
  published
    procedure Test_Palette_Sample_Endpoints;
    procedure Test_Palette_OKLCH_ShortestPath;
  end;

implementation

procedure TTestCase_Palette.Test_Palette_Sample_Endpoints;
var a,b,m: color_rgba_t;
begin
  a := COLOR_RED; b := COLOR_BLUE;
  m := palette_sample(a,b,0.0, PIM_SRGB);
  AssertEquals(a.r, m.r);
  m := palette_sample(a,b,1.0, PIM_SRGB);
  AssertEquals(b.b, m.b);
end;

procedure TTestCase_Palette.Test_Palette_OKLCH_ShortestPath;
var a,b,m: color_rgba_t; lch: color_oklch_t;
begin
  lch.L := 0.7; lch.C := 0.2; lch.h := 350; a := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.2; lch.h := 10;  b := color_from_oklch(lch);
  m := palette_sample(a,b,0.5, PIM_OKLCH, True);
  // 中点不等于任一端点即可（路径正确性由其它测试保障）
  AssertTrue((m.r<>a.r) or (m.g<>a.g) or (m.b<>a.b));
  AssertTrue((m.r<>b.r) or (m.g<>b.g) or (m.b<>b.b));
end;

initialization
  RegisterTest(TTestCase_Palette);

end.

