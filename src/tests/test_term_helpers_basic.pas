unit test_term_helpers_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.term.helpers;

type
  TTermHelpersBasic = class(TTestCase)
  published
    procedure Test_ChooseBorderMode_WindowsTerminal_PrefersASCII;
    procedure Test_ChooseBorderMode_AnyMotionNotSupported_PrefersASCII;
    procedure Test_ChooseBorderMode_Ok_PrefersBox;
    procedure Test_UseAsciiBorder_ForcedModes;
  end;

procedure RegisterTermHelpersTests;

implementation

procedure TTermHelpersBasic.Test_ChooseBorderMode_WindowsTerminal_PrefersASCII;
var m: Integer;
begin
  m := term_choose_border_mode(1, True);
  fpcunit.TAssert.AssertEquals(1, m);
end;

procedure TTermHelpersBasic.Test_ChooseBorderMode_AnyMotionNotSupported_PrefersASCII;
var m: Integer;
begin
  m := term_choose_border_mode(-1, False);
  fpcunit.TAssert.AssertEquals(1, m);
end;

procedure TTermHelpersBasic.Test_ChooseBorderMode_Ok_PrefersBox;
var m: Integer;
begin
  m := term_choose_border_mode(1, False);
  fpcunit.TAssert.AssertEquals(2, m);
end;

procedure TTermHelpersBasic.Test_UseAsciiBorder_ForcedModes;
begin
  fpcunit.TAssert.AssertTrue(term_use_ascii_border(1, 1, False));
  fpcunit.TAssert.AssertFalse(term_use_ascii_border(2, -1, True));
  // auto
  fpcunit.TAssert.AssertTrue(term_use_ascii_border(0, -1, False));
  fpcunit.TAssert.AssertTrue(term_use_ascii_border(0, 1, True));
  fpcunit.TAssert.AssertFalse(term_use_ascii_border(0, 1, False));
end;

procedure RegisterTermHelpersTests;
begin
  RegisterTest(TTermHelpersBasic);
end;

end.

