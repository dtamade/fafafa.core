unit fafafa.core.color.lightdark.single.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_LightDarkSingle = class(TTestCase)
  published
    procedure Test_HSL_Single_Equivalence_With_Percent;
    procedure Test_OKLCH_Single_Equivalence_With_Percent;
  end;

implementation

procedure TTestCase_LightDarkSingle.Test_HSL_Single_Equivalence_With_Percent;
var c: color_rgba_t; p: Integer; s: Single; a,b: color_rgba_t;
begin
  c := color_rgb(120, 200, 80);
  for p := 0 to 100 do begin
    s := p/100.0;
    a := color_lighten(c, p);
    b := color_lighten(c, s);
    AssertTrue(color_equals(a,b));
    a := color_darken(c, p);
    b := color_darken(c, s);
    AssertTrue(color_equals(a,b));
  end;
end;

procedure TTestCase_LightDarkSingle.Test_OKLCH_Single_Equivalence_With_Percent;
var c: color_rgba_t; p: Integer; s: Single; a,b: color_rgba_t;
begin
  c := color_rgb(120, 200, 80);
  for p := 0 to 100 do begin
    s := p/100.0;
    a := color_lighten_oklch(c, p);
    b := color_lighten_oklch(c, s);
    AssertTrue(color_equals(a,b));
    a := color_darken_oklch(c, p);
    b := color_darken_oklch(c, s);
    AssertTrue(color_equals(a,b));
  end;
end;

initialization
  RegisterTest(TTestCase_LightDarkSingle);

end.

