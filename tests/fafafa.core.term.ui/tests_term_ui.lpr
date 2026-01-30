program tests_term_ui;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  Test_fafafa_core_term_ui,
  Test_fafafa_core_term_ui_hooks,
  Test_fafafa_core_term_ui_backend_memory,
  Test_fafafa_core_term_ui_view_smoke,
  Test_fafafa_core_term_ui_attr_smoke,
  Test_fafafa_core_term_ui_attr_min_write,
  Test_fafafa_core_term_ui_attr_style_only_v2,
  Test_fafafa_core_term_ui_surface_clip,
  Test_fafafa_core_term_ui_with_view,
  Test_fafafa_core_term_ui_with_view_fillrect;

type
  TUITestApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TUITestApp.DoRun;
var
  Runner: TTestRunner;
begin
  Runner := TTestRunner.Create(nil);
  try
    Runner.Initialize;
    Runner.Run;
  finally
    Runner.Free;
  end;
  Terminate;
end;

var
  App: TUITestApp;
begin
  App := TUITestApp.Create(nil);
  try
    App.Title := 'fafafa.core.term.ui Tests';
    App.Run;
  finally
    App.Free;
  end;
end.

