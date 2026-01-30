unit fafafa.core.color.oklab.props.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_OKLabProps = class(TTestCase)
  private
    function NearlyEqual(a, b: Integer; tol: Integer = 1): Boolean;
    function NearlyEqualF(a, b: Single; tol: Single): Boolean;
  published
    procedure Test_OKLab_Roundtrip_Grid;
    procedure Test_OKLab_Mix_L_Monotonic;
    procedure Test_OKLCH_Endpoints_Close;
    procedure Test_OKLCH_HueWrap_Tolerance;
    procedure Test_sRGB_vs_OKLab_Midpoint_Difference;
  end;

implementation

function TTestCase_OKLabProps.NearlyEqual(a, b: Integer; tol: Integer): Boolean;
begin
  Result := Abs(a - b) <= tol;
end;

function TTestCase_OKLabProps.NearlyEqualF(a, b: Single; tol: Single): Boolean;
begin
  Result := Abs(a - b) <= tol;
end;

procedure TTestCase_OKLabProps.Test_OKLab_Roundtrip_Grid;
var r,g,b: Integer; c0,c1: color_rgba_t; lab: color_oklab_t;
begin
  for r in [0,64,128,192,255] do
    for g in [0,64,128,192,255] do
      for b in [0,64,128,192,255] do
      begin
        c0 := color_rgb(r,g,b);
        lab := color_to_oklab(c0);
        c1 := color_from_oklab(lab);
        AssertTrue(NearlyEqual(c0.r, c1.r, 1));
        AssertTrue(NearlyEqual(c0.g, c1.g, 1));
        AssertTrue(NearlyEqual(c0.b, c1.b, 1));
      end;
end;

procedure TTestCase_OKLabProps.Test_OKLab_Mix_L_Monotonic;
var a,b,m: color_rgba_t; la, lb, lm: color_oklab_t;
begin
  a := color_rgb(30, 30, 30);
  b := color_rgb(230, 230, 230);
  la := color_to_oklab(a);
  lb := color_to_oklab(b);
  m := color_mix_oklab(a,b,0.5);
  lm := color_to_oklab(m);
  // L 单调：中点应在端点 L 之间
  AssertTrue((lm.L >= Min(la.L, lb.L)) and (lm.L <= Max(la.L, lb.L)));
end;

procedure TTestCase_OKLabProps.Test_OKLCH_Endpoints_Close;
var a,b,m0,m1: color_rgba_t; lch: color_oklch_t;
begin
  lch.L := 0.7; lch.C := 0.1; lch.h := 40; a := color_from_oklch(lch);
  lch.L := 0.5; lch.C := 0.2; lch.h := 80; b := color_from_oklch(lch);
  m0 := color_mix_oklch(a,b,0.0, True);
  m1 := color_mix_oklch(a,b,1.0, True);
  AssertTrue(NearlyEqual(m0.r, a.r, 1) and NearlyEqual(m0.g, a.g, 1) and NearlyEqual(m0.b, a.b, 1));
  AssertTrue(NearlyEqual(m1.r, b.r, 1) and NearlyEqual(m1.g, b.g, 1) and NearlyEqual(m1.b, b.b, 1));
end;

procedure TTestCase_OKLabProps.Test_OKLCH_HueWrap_Tolerance;
var a,b,m: color_rgba_t; lm: color_oklch_t; lch: color_oklch_t;
begin
  // 350 -> 10 使用最短路径，t=0.5 时角度应靠近 0 度附近（容差 40°）
  lch.L := 0.7; lch.C := 0.15; lch.h := 350; a := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.15; lch.h := 10;  b := color_from_oklch(lch);
  m := color_mix_oklch(a,b,0.5, True);
  lm := color_to_oklch(m);
  AssertTrue((lm.h <= 40) or (lm.h >= 320));
  // 非最短路径则中点应远离 0 度附近（简易断言）
  m := color_mix_oklch(a,b,0.5, False);
  lm := color_to_oklch(m);
  AssertTrue((lm.h > 40) and (lm.h < 320));
end;

procedure TTestCase_OKLabProps.Test_sRGB_vs_OKLab_Midpoint_Difference;
var a,b,ms,ml: color_rgba_t;
begin
  a := color_rgb(255, 0, 0);
  b := color_rgb(0, 255, 0);
  ms := color_mix_srgb(a,b,0.5);
  ml := color_mix_oklab(a,b,0.5);
  // 断言两种中点不完全相同（表现差异存在）
  AssertTrue((ms.r <> ml.r) or (ms.g <> ml.g) or (ms.b <> ml.b));
end;

initialization
  RegisterTest(TTestCase_OKLabProps);

end.

