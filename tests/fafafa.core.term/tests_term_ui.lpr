program tests_term_ui;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  test_term_ui_surface_basic,
  test_term_capabilities_basic,
  test_term_ui_view_attr,
  test_term_ui_dirty_hooks,
  test_term_ui_cursor_policy;

begin
  RegisterTermUiSurfaceTests;
  RegisterTermCapabilitiesTests;
  RegisterTermUiViewAttrTests;
  RegisterTermUiDirtyHookTests;
  RegisterTermCapabilitiesTests;
  RegisterTermUiCursorPolicyTests;
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

