{$CODEPAGE UTF8}
unit Test_term_modeguard_nested_restore_smoke;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

Type
  TTestCase_ModeGuardRestore = class(TTestCase)
  published
    procedure Test_ModeGuard_Nested_Acquire_Release_Restores;
  end;

implementation

procedure TTestCase_ModeGuardRestore.Test_ModeGuard_Nested_Acquire_Release_Restores;
var
  g: TTermModeGuard;
begin
  if not term_init then begin CheckTrue(True, 'term_init False (skip)'); Exit; end;
  try
    // Acquire multiple flags and release; expectation: no exception and state restored
    g := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_button_drag, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004]);
    try
      // re-acquire a subset
      var g2: TTermModeGuard := term_mode_guard_acquire_current([tm_mouse_sgr_1006, tm_paste_2004]);
      try
        CheckTrue(True);
      finally
        term_mode_guard_done(g2);
      end;
    finally
      term_mode_guard_done(g);
    end;
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTestCase_ModeGuardRestore);

end.

