unit fafafa.core.color.oklch.gamut.props.edge.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}
{$I testutils.color.tolerances.inc}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_OKLCHGamutProps_Edge = class(TTestCase)
  published
    procedure Test_Preserve_Extreme_C_High;
    procedure Test_Preserve_Extreme_L_Edges;
  end;

implementation

function HueDelta(a, b: Single): Single; inline;
var d: Single;
begin
  d := Abs(a - b);
  if d > 180 then d := 360 - d;
  Result := d;
end;

procedure TTestCase_OKLCHGamutProps_Edge.Test_Preserve_Extreme_C_High;
var lchIn, lchOut: color_oklch_t; c: color_rgba_t;
begin
  // 极高 C，越界明确
  lchIn.L := 0.6; lchIn.C := 0.95; lchIn.h := 200.0;
  c := color_from_oklch_gamut(lchIn, GMT_PreserveHueDesaturate);
  lchOut := color_to_oklch(c);
  AssertTrue('L preserved within 0.03', Abs(lchOut.L - lchIn.L) <= 0.03);
  AssertTrue('Hue preserved within 2 deg', HueDelta(lchOut.h, lchIn.h) <= 2.0);
  AssertTrue('C does not increase', lchOut.C <= lchIn.C + 1e-4);
  AssertTrue('RGB in byte range', (c.r>=0) and (c.r<=255) and (c.g>=0) and (c.g<=255) and (c.b>=0) and (c.b<=255));
end;

procedure TTestCase_OKLCHGamutProps_Edge.Test_Preserve_Extreme_L_Edges;
var lchIn, lchOut: color_oklch_t; c: color_rgba_t;
begin
  // 非常接近 L 边界的样本
  lchIn.L := 0.02; lchIn.C := 0.4; lchIn.h := 40.0;
  c := color_from_oklch_gamut(lchIn, GMT_PreserveHueDesaturate);
  lchOut := color_to_oklch(c);
  AssertTrue('L preserved within 0.03 (low L)', Abs(lchOut.L - lchIn.L) <= 0.03);
  // Hue 断言策略与 Extra 保持一致：使用共享容差常量
  if lchOut.C >= TOL_C_NEAR_GRAY then
  begin
    if lchIn.L <= TOL_L_VERY_LOW then
      AssertTrue('Hue preserved within 8 deg (very low L)', HueDelta(lchOut.h, lchIn.h) <= TOL_HUE_VERY_LOW)
    else if lchIn.L <= TOL_L_LOW then
      AssertTrue('Hue preserved within 4 deg (low L)', HueDelta(lchOut.h, lchIn.h) <= TOL_HUE_LOW)
    else
      AssertTrue('Hue preserved within 2 deg', HueDelta(lchOut.h, lchIn.h) <= TOL_HUE_NORMAL);
  end;
  AssertTrue('C does not increase (low L)', lchOut.C <= lchIn.C + 1e-4);
  AssertTrue('RGB in byte range (low L)', (c.r>=0) and (c.r<=255) and (c.g>=0) and (c.g<=255) and (c.b>=0) and (c.b<=255));

  lchIn.L := 0.98; lchIn.C := 0.4; lchIn.h := 220.0;
  c := color_from_oklch_gamut(lchIn, GMT_PreserveHueDesaturate);
  lchOut := color_to_oklch(c);
  AssertTrue('L preserved within 0.03 (high L)', Abs(lchOut.L - lchIn.L) <= 0.03);
  AssertTrue('Hue preserved within 2 deg (high L)', HueDelta(lchOut.h, lchIn.h) <= 2.0);
  AssertTrue('C does not increase (high L)', lchOut.C <= lchIn.C + 1e-4);
  AssertTrue('RGB in byte range (high L)', (c.r>=0) and (c.r<=255) and (c.g>=0) and (c.g<=255) and (c.b>=0) and (c.b<=255));
end;

initialization
  RegisterTest(TTestCase_OKLCHGamutProps_Edge);

end.

