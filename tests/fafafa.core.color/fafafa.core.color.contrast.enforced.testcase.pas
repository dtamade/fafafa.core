unit fafafa.core.color.contrast.enforced.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_ContrastEnforced = class(TTestCase)
  published
    procedure Test_Enforced_At_Least_Threshold;
    procedure Test_Enforced_BlackWhite_Shortcut;
  end;

implementation

procedure TTestCase_ContrastEnforced.Test_Enforced_At_Least_Threshold;
var bg, fg: color_rgba_t; cr: Single; lch: color_oklch_t;
begin
  lch.L := 0.7; lch.C := 0.2; lch.h := 40;
  bg := color_from_oklch(lch);
  fg := color_suggest_fg_for_bg_enforced(bg, 4.5);
  cr := color_contrast_ratio(fg, bg);
  AssertTrue(cr >= 4.5 - 1e-3);
end;

procedure TTestCase_ContrastEnforced.Test_Enforced_BlackWhite_Shortcut;
var bg, fg: color_rgba_t; cr: Single;
begin
  bg := COLOR_WHITE;
  fg := color_suggest_fg_for_bg_enforced(bg, 3.0);
  cr := color_contrast_ratio(fg, bg);
  AssertTrue(cr >= 3.0 - 1e-3);
end;

initialization
  RegisterTest(TTestCase_ContrastEnforced);

end.

