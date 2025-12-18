unit fafafa.core.color.oklch.props.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_OKLCHProps = class(TTestCase)
  published
    procedure Test_OKLCH_Roundtrip_Grid;
    procedure Test_OKLCH_Roundtrip_Random_Seeded;
    procedure Test_OKLCH_HueWrap_BothDirections;
  end;

implementation

procedure TTestCase_OKLCHProps.Test_OKLCH_Roundtrip_Grid;
var r,g,b: Integer; c0,c1: color_rgba_t; lch: color_oklch_t;
begin
  for r in [0,64,128,192,255] do
    for g in [0,64,128,192,255] do
      for b in [0,64,128,192,255] do
      begin
        c0 := color_rgb(r,g,b);
        lch := color_to_oklch(c0);
        c1 := color_from_oklch(lch);
        AssertTrue(Abs(c0.r - c1.r) <= 1);
        AssertTrue(Abs(c0.g - c1.g) <= 1);
        AssertTrue(Abs(c0.b - c1.b) <= 1);
      end;
end;

procedure TTestCase_OKLCHProps.Test_OKLCH_Roundtrip_Random_Seeded;
var i: Integer; c0,c1: color_rgba_t; lch: color_oklch_t;
begin
  RandSeed := 1234567; // 固定种子，保证可复现
  for i := 1 to 200 do
  begin
    c0 := color_rgb(Random(256), Random(256), Random(256));
    lch := color_to_oklch(c0);
    c1 := color_from_oklch(lch);
    AssertTrue(Abs(c0.r - c1.r) <= 1);
    AssertTrue(Abs(c0.g - c1.g) <= 1);
    AssertTrue(Abs(c0.b - c1.b) <= 1);
  end;
end;

procedure TTestCase_OKLCHProps.Test_OKLCH_HueWrap_BothDirections;
var a,b,m: color_rgba_t; lch: color_oklch_t; mid: color_oklch_t;
begin
  // 350 -> 10 : 最短路径中点接近 0°
  lch.L := 0.7; lch.C := 0.15; lch.h := 350; a := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.15; lch.h := 10;  b := color_from_oklch(lch);
  m := color_mix_oklch(a,b,0.5, True);
  mid := color_to_oklch(m);
  AssertTrue((mid.h <= 40) or (mid.h >= 320));

  // 10 -> 350 : 最短路径中点同样接近 0°
  lch.L := 0.7; lch.C := 0.15; lch.h := 10;  a := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.15; lch.h := 350; b := color_from_oklch(lch);
  m := color_mix_oklch(a,b,0.5, True);
  mid := color_to_oklch(m);
  AssertTrue((mid.h <= 40) or (mid.h >= 320));
end;

initialization
  RegisterTest(TTestCase_OKLCHProps);

end.

