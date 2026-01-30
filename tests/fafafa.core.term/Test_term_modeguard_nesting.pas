{$CODEPAGE UTF8}
unit Test_term_modeguard_nesting;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermModeGuardNesting = class(TTestCase)
  private
    procedure Raise_ModeGuard_Nested;
  published
    procedure Test_ModeGuard_Nested_With_Exception;
    procedure Test_ModeGuard_Reentrant_Enable_Disable;
  end;

implementation

procedure TTestCase_TermModeGuardNesting.Raise_ModeGuard_Nested;
begin
  // 预期抛出异常，外层用 AssertException 捕获；此处务必保证恢复
  term_raw_mode_enable(True);
  try
    term_mouse_enable(True);
    try
      // 再次启用，随后模拟异常路径
      term_mouse_enable(True);
      raise Exception.Create('simulate');
    finally
      term_mouse_enable(False);
    end;
  finally
    term_raw_mode_enable(False);
  end;
end;

procedure TTestCase_TermModeGuardNesting.Test_ModeGuard_Nested_With_Exception;
begin
  // 按最佳实践：使用 AssertException 断言预期异常，且保证 term_done 清理
  if not term_init then
  begin
    CheckTrue(True, 'term_init returned False (skip)');
    Exit;
  end;
  try
    AssertException(Exception, @Self.Raise_ModeGuard_Nested);
  finally
    term_done;
  end;
end;

procedure TTestCase_TermModeGuardNesting.Test_ModeGuard_Reentrant_Enable_Disable;
begin
  if not term_init then
  begin
    CheckTrue(True, 'term_init returned False (skip)');
    Exit;
  end;
  try
    term_mouse_enable(True);
    term_mouse_enable(True);
    term_mouse_enable(False);
    term_mouse_enable(False);
    CheckTrue(True);
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTestCase_TermModeGuardNesting);

end.

