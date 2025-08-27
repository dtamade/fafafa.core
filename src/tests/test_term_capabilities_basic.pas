unit test_term_capabilities_basic;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTermCapabilitiesBasic = class(TTestCase)
  published
    procedure Test_ANSI_Color_Mouse;
    procedure Test_TrueColor_Overrides;
    procedure Test_Compatibles_AllOf;
    procedure Test_Alternate_Screen;
  end;

procedure RegisterTermCapabilitiesTests;

implementation

function NewFakeTerm(const Caps: term_compatibles_t): pterm_t;
begin
  New(Result);
  FillChar(Result^, SizeOf(term_t), 0);
  Result^.name := 'fake';
  Result^.compatibles := Caps;
end;

procedure FreeFakeTerm(var T: pterm_t);
begin
  if T <> nil then
  begin
    Dispose(T);
    T := nil;
  end;
end;

procedure TTermCapabilitiesBasic.Test_ANSI_Color_Mouse;
var
  T: pterm_t;
begin
  T := NewFakeTerm([tc_ansi, tc_color_16, tc_mouse]);
  try
    fpcunit.TAssert.AssertTrue(term_support_ansi(T));
    fpcunit.TAssert.AssertTrue(term_support_color(T));
    fpcunit.TAssert.AssertTrue(term_support_color_16(T));
    fpcunit.TAssert.AssertFalse(term_support_color_256(T));
    fpcunit.TAssert.AssertFalse(term_support_color_24bit(T));
    fpcunit.TAssert.AssertTrue(term_support_mouse(T));
  finally
    FreeFakeTerm(T);
  end;
end;

procedure TTermCapabilitiesBasic.Test_TrueColor_Overrides;
var
  T: pterm_t;
begin
  T := NewFakeTerm([tc_ansi, tc_color_24bit]);
  try
    fpcunit.TAssert.AssertTrue(term_support_color(T));
    fpcunit.TAssert.AssertFalse(term_support_color_16(T));
    fpcunit.TAssert.AssertFalse(term_support_color_256(T));
    fpcunit.TAssert.AssertTrue(term_support_color_24bit(T));
  finally
    FreeFakeTerm(T);
  end;
end;

procedure TTermCapabilitiesBasic.Test_Compatibles_AllOf;
var
  T: pterm_t;
  Need: term_compatibles_t;
begin
  T := NewFakeTerm([tc_ansi, tc_mouse]);
  try
    Need := [tc_ansi];
    fpcunit.TAssert.AssertTrue(term_support_compatibles(T, Need));
    Need := [tc_ansi, tc_mouse];
    fpcunit.TAssert.AssertTrue(term_support_compatibles(T, Need));
    Need := [tc_ansi, tc_alternate_screen];
    fpcunit.TAssert.AssertFalse(term_support_compatibles(T, Need));
  finally
    FreeFakeTerm(T);
  end;
end;

procedure TTermCapabilitiesBasic.Test_Alternate_Screen;
var
  T: pterm_t;
begin
  T := NewFakeTerm([tc_ansi, tc_alternate_screen]);
  try
    fpcunit.TAssert.AssertTrue(term_support_alternate_screen(T));
  finally
    FreeFakeTerm(T);
  end;
end;

procedure RegisterTermCapabilitiesTests;
begin
  RegisterTest(TTermCapabilitiesBasic);
end;

end.

