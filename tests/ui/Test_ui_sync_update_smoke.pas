{$CODEPAGE UTF8}
unit Test_ui_sync_update_smoke;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_terminal;

type
  TUISyncUpdateSmoke = class(TTestCase)
  published
    procedure Test_Enable_Disable_NoCrash_When_NotSupported;
  end;

implementation

procedure TUISyncUpdateSmoke.Test_Enable_Disable_NoCrash_When_NotSupported;
var
  W, H: term_size_t;
begin
  // 确保有 backend
  UiBackendSetCurrent(ui_backend_terminal.CreateTerminalBackend);

  // 关闭（默认）
  termui_set_sync_update_enabled(False);
  termui_frame_begin;
  termui_frame_end;

  // 打开
  termui_set_sync_update_enabled(True);
  termui_frame_begin;
  termui_frame_end;

  // 再次关闭
  termui_set_sync_update_enabled(False);
  termui_frame_begin;
  termui_frame_end;

  // 只要没有异常即通过
  CheckTrue(True);
end;

initialization
  RegisterTest(TUISyncUpdateSmoke);

end.

