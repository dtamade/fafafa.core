unit fafafa.core.color.named.css.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_NamedCSS = class(TTestCase)
  published
    procedure Test_Alias_Equivalence;
    procedure Test_Some_CSS_Values;
  end;

implementation

procedure TTestCase_NamedCSS.Test_Alias_Equivalence;
begin
  AssertEquals(COLOR_LIGHTGRAY.r, COLOR_SILVER.r);
  AssertEquals(COLOR_MAGENTA.r,   COLOR_FUCHSIA.r);
  AssertEquals(COLOR_GREEN.g,     COLOR_LIME.g);
  AssertEquals(COLOR_CYAN.g,      COLOR_AQUA.g);
end;

procedure TTestCase_NamedCSS.Test_Some_CSS_Values;
begin
  AssertEquals(128, COLOR_MAROON.r);
  AssertEquals(128, COLOR_NAVY.b);
  AssertEquals(255, COLOR_GOLD.r);
  AssertEquals(255, COLOR_PINK.r);
  AssertEquals(42,  COLOR_BROWN.g);
end;

initialization
  RegisterTest(TTestCase_NamedCSS);

end.

