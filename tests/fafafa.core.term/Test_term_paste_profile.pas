{$CODEPAGE UTF8}
unit Test_term_paste_profile;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_PasteProfile = class(TTestCase)
  published
    procedure Test_Profile_TUI_Applies_When_Unset;
    procedure Test_Profile_Does_Not_Override_Explicit;
  end;

implementation

procedure TTestCase_PasteProfile.Test_Profile_TUI_Applies_When_Unset;
begin
  term_paste_clear_all;
  term_paste_set_auto_keep_last(0);
  term_paste_set_max_bytes(0);
  term_paste_set_trim_fastpath_div(8); // default
  term_paste_apply_profile('tui');
  AssertEquals(SizeUInt(128), term_paste_get_auto_keep_last());
  AssertEquals(SizeUInt(1 shl 20), term_paste_get_max_bytes());
  AssertEquals(SizeUInt(8), term_paste_get_trim_fastpath_div());
end;

procedure TTestCase_PasteProfile.Test_Profile_Does_Not_Override_Explicit;
begin
  term_paste_clear_all;
  term_paste_set_auto_keep_last(7);   // explicit
  term_paste_set_max_bytes(9);        // explicit
  term_paste_set_trim_fastpath_div(6);// non-default explicit
  term_paste_apply_profile('daemon');
  // should keep explicit values
  AssertEquals(SizeUInt(7), term_paste_get_auto_keep_last());
  AssertEquals(SizeUInt(9), term_paste_get_max_bytes());
  AssertEquals(SizeUInt(6), term_paste_get_trim_fastpath_div());
end;

initialization
  RegisterTest(TTestCase_PasteProfile);

end.

