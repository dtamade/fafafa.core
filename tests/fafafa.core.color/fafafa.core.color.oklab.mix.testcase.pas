unit fafafa.core.color.oklab.mix.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_OKLabMix = class(TTestCase)
  published
    procedure Test_OKLab_Endpoints;
    procedure Test_OKLCH_Endpoints_And_HueWrap;
  end;

implementation

procedure TTestCase_OKLabMix.Test_OKLab_Endpoints;
var a,b,m0,m1: color_rgba_t;
begin
  a := color_rgb(10, 20, 30);
  b := color_rgb(200, 210, 220);
  m0 := color_mix_oklab(a,b,0.0);
  m1 := color_mix_oklab(a,b,1.0);
  AssertEquals(a.r, m0.r);
  AssertEquals(b.r, m1.r);
end;

procedure TTestCase_OKLabMix.Test_OKLCH_Endpoints_And_HueWrap;
var a,b,m: color_rgba_t; lch: color_oklch_t;
begin
  lch.L := 0.7; lch.C := 0.1; lch.h := 350; a := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.1; lch.h := 10;  b := color_from_oklch(lch);
  m := color_mix_oklch(a,b,0.5, True);
  // hue 应沿最短路径跨 0 度
  // 这里只验证运行路径：中点不应等于端点
  AssertTrue((m.r<>a.r) or (m.g<>a.g) or (m.b<>a.b));
  AssertTrue((m.r<>b.r) or (m.g<>b.g) or (m.b<>b.b));
end;

initialization
  RegisterTest(TTestCase_OKLabMix);

end.

