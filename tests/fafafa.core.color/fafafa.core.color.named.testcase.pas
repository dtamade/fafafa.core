unit fafafa.core.color.named.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_NamedAndSuggest = class(TTestCase)
  published
    procedure Test_Named_Constants_Basics;
    procedure Test_Suggest_FG_For_BG_Basic;
  end;

implementation

procedure TTestCase_NamedAndSuggest.Test_Named_Constants_Basics;
begin
  AssertEquals(0,   COLOR_BLACK.r);
  AssertEquals(255, COLOR_WHITE.r);
  AssertEquals(255, COLOR_RED.r);
  AssertEquals(255, COLOR_GREEN.g);
  AssertEquals(255, COLOR_BLUE.b);
  AssertEquals(255, COLOR_ORANGE.r);
  AssertEquals(165, COLOR_ORANGE.g);
  AssertEquals(0,   COLOR_ORANGE.b);
end;

procedure TTestCase_NamedAndSuggest.Test_Suggest_FG_For_BG_Basic;
var c: color_rgba_t;
begin
  c := color_suggest_fg_for_bg_default(COLOR_BLACK);
  AssertEquals(255, c.r); // white on black
  c := color_suggest_fg_for_bg_default(COLOR_WHITE);
  AssertEquals(0, c.r);   // black on white
  // Mid gray prefers black (higher contrast than white)
  c := color_suggest_fg_for_bg_default(COLOR_LIGHTGRAY);
  AssertEquals(0, c.r);
end;

initialization
  RegisterTest(TTestCase_NamedAndSuggest);

end.

