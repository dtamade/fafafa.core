unit fafafa.core.color.oklab.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.color;

type
  TTestCase_OKLab = class(TTestCase)
  published
    procedure Test_OKLab_Roundtrip_Basic;
    procedure Test_OKLCH_Roundtrip_Basic;
  end;

implementation

procedure TTestCase_OKLab.Test_OKLab_Roundtrip_Basic;
var c0,c1: color_rgba_t; lab: color_oklab_t;
begin
  c0 := color_rgb(120, 200, 80);
  lab := color_to_oklab(c0);
  c1 := color_from_oklab(lab);
  // 允许 1 个量化误差
  AssertTrue(Abs(c0.r - c1.r) <= 1);
  AssertTrue(Abs(c0.g - c1.g) <= 1);
  AssertTrue(Abs(c0.b - c1.b) <= 1);
end;

procedure TTestCase_OKLab.Test_OKLCH_Roundtrip_Basic;
var c0,c1: color_rgba_t; lch: color_oklch_t;
begin
  c0 := color_rgb(20, 40, 200);
  lch := color_to_oklch(c0);
  c1 := color_from_oklch(lch);
  AssertTrue(Abs(c0.r - c1.r) <= 1);
  AssertTrue(Abs(c0.g - c1.g) <= 1);
  AssertTrue(Abs(c0.b - c1.b) <= 1);
end;

initialization
  RegisterTest(TTestCase_OKLab);

end.

