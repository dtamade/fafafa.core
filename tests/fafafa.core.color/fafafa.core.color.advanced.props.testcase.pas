unit fafafa.core.color.advanced.props.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_AdvancedProps = class(TTestCase)
  published
    procedure Test_Mix_Endpoints_Idempotent;
    procedure Test_Mix_Midpoint_Monotonic;
    procedure Test_Blend_Alpha_Identity;
    procedure Test_Lighten_Darken_Clamp;
    procedure Test_BestContrast_EmptyPalette_Defaults;
  end;

implementation

procedure TTestCase_AdvancedProps.Test_Mix_Endpoints_Idempotent;
var a,b,m: color_rgba_t;
begin
  a := color_rgba(10,20,30,40);
  b := color_rgba(200,210,220,230);
  m := color_mix_srgb(a,b,0.0);
  AssertEquals(a.r, m.r); AssertEquals(a.g, m.g); AssertEquals(a.b, m.b); AssertEquals(a.a, m.a);
  m := color_mix_srgb(a,b,1.0);
  AssertEquals(b.r, m.r); AssertEquals(b.g, m.g); AssertEquals(b.b, m.b); AssertEquals(b.a, m.a);

  m := color_mix_linear(a,b,0.0);
  AssertEquals(a.r, m.r); AssertEquals(a.g, m.g); AssertEquals(a.b, m.b);
  m := color_mix_linear(a,b,1.0);
  AssertEquals(b.r, m.r); AssertEquals(b.g, m.g); AssertEquals(b.b, m.b);
end;

procedure TTestCase_AdvancedProps.Test_Mix_Midpoint_Monotonic;
var a,b,m: color_rgba_t;
begin
  a := color_rgb(0,0,0);
  b := color_rgb(100,100,100);
  m := color_mix_srgb(a,b,0.5);
  AssertTrue((m.r >= a.r) and (m.r <= b.r));
  m := color_mix_linear(a,b,0.5);
  AssertTrue((m.r >= a.r) and (m.r <= b.r));
end;

procedure TTestCase_AdvancedProps.Test_Blend_Alpha_Identity;
var fg,bg,outc: color_rgba_t;
begin
  // alpha=0: 结果等于背景
  fg := color_rgba(255,0,0,0);
  bg := color_rgb(1,2,3);
  outc := color_blend_over(fg,bg);
  AssertEquals(bg.r, outc.r); AssertEquals(bg.g, outc.g); AssertEquals(bg.b, outc.b);
  // alpha=255: 结果等于前景
  fg := color_rgba(7,8,9,255);
  outc := color_blend_over(fg,bg);
  AssertEquals(fg.r, outc.r); AssertEquals(fg.g, outc.g); AssertEquals(fg.b, outc.b);
end;

procedure TTestCase_AdvancedProps.Test_Lighten_Darken_Clamp;
var c, l, d: color_rgba_t;
begin
  c := color_rgb(50, 60, 70);
  l := color_lighten(c, 100);
  d := color_darken(c, 100);
  AssertTrue((l.r>=d.r) and (l.g>=d.g) and (l.b>=d.b));
end;

procedure TTestCase_AdvancedProps.Test_BestContrast_EmptyPalette_Defaults;
var bg, res: color_rgba_t; empty: array of color_rgba_t;
begin
  bg := COLOR_WHITE;
  SetLength(empty, 0);
  res := color_best_contrast(bg, empty);
  AssertEquals(COLOR_BLACK.r, res.r);
end;

initialization
  RegisterTest(TTestCase_AdvancedProps);

end.

