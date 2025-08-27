{$CODEPAGE UTF8}
unit Test_term_modeguard_combinations;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  TestHelpers_Env;

type
  TTestCase_TermModeGuard_Combinations = class(TTestCase)
  private
    procedure Raise_Guarded_Exception;
  published
    procedure Test_ModeGuard_Nested_Combinations_With_Exception;
    procedure Test_ModeGuard_Reentrant_Combinations_Idempotent;
  end;

implementation

procedure TTestCase_TermModeGuard_Combinations.Raise_Guarded_Exception;
var
  g1, g2: TTermModeGuard;
begin
  // 组合多种模式，验证异常路径能正确恢复
  g1 := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_button_drag, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004]);
  try
    g2 := term_mode_guard_acquire_current([tm_focus_1004, tm_paste_2004]);
    try
      raise Exception.Create('simulate');
    finally
      term_mode_guard_done(g2);
    end;
  finally
    term_mode_guard_done(g1);
  end;
end;

procedure TTestCase_TermModeGuard_Combinations.Test_ModeGuard_Nested_Combinations_With_Exception;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  if not term_init then
  begin
    CheckTrue(True, 'term_init returned False (skip)');
    Exit;
  end;
  try
    AssertException(Exception, @Self.Raise_Guarded_Exception);
  finally
    term_done;
  end;
end;

procedure TTestCase_TermModeGuard_Combinations.Test_ModeGuard_Reentrant_Combinations_Idempotent;
var
  g1, g2: TTermModeGuard;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  if not term_init then
  begin
    CheckTrue(True, 'term_init returned False (skip)');
    Exit;
  end;
  try
    g1 := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_button_drag, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004]);
    g2 := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_button_drag, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004]);
    // 释放顺序：后进先出
    term_mode_guard_done(g2);
    term_mode_guard_done(g1);

    // 释放后重复调用禁用操作，验证幂等与稳定（不抛异常）
    term_focus_enable(False);
    term_focus_enable(False);
    term_paste_bracket_enable(False);
    term_paste_bracket_enable(False);
    term_mouse_drag_enable(False);
    term_mouse_drag_enable(False);
    term_mouse_sgr_enable(False);
    term_mouse_sgr_enable(False);
    term_mouse_enable(False);
    term_mouse_enable(False);
    CheckTrue(True);
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTestCase_TermModeGuard_Combinations);

end.

