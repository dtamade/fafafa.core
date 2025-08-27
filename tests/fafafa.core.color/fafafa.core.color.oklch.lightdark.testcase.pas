unit fafafa.core.color.oklch.lightdark.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_OKLCHLightDark = class(TTestCase)
  published
    procedure Test_OKLCH_Lighten_Darken_Clamp_And_Alpha;
  end;

implementation

procedure TTestCase_OKLCHLightDark.Test_OKLCH_Lighten_Darken_Clamp_And_Alpha;
var c, l1, d1: color_rgba_t;
begin
  c := color_rgba(10, 20, 30, 123);
  l1 := color_lighten_oklch(c, 10);
  d1 := color_darken_oklch(c, 10);
  AssertEquals(123, l1.a);
  AssertEquals(123, d1.a);
  // 过量调整也应夹到 [0,1]
  l1 := color_lighten_oklch(c, 100);
  d1 := color_darken_oklch(c, 100);
  AssertEquals(123, l1.a);
  AssertEquals(123, d1.a);
end;

initialization
  RegisterTest(TTestCase_OKLCHLightDark);

end.

