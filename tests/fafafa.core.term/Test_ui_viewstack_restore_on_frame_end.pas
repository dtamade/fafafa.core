{$CODEPAGE UTF8}
unit Test_ui_viewstack_restore_on_frame_end;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory;

type
  TUIViewStackRestore = class(TTestCase)
  published
    procedure Test_ViewStack_Is_Reset_On_FrameEnd_When_Not_Popped;
  end;

implementation

procedure TUIViewStackRestore.Test_ViewStack_Is_Reset_On_FrameEnd_When_Not_Popped;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
begin
  B := CreateMemoryBackend(8, 4);
  UiBackendSetCurrent(B);
  termui_set_backbuffer_enabled(True);

  // 帧1：Push 视口但不 Pop，写入本地 (0,0) 'A'，应映射到屏幕 (2,1)
  termui_frame_begin;
  UiPushView(2, 1, 4, 2, 0, 0);
  UiWriteAt(0, 0, 'A');
  termui_frame_end;

  Buf := MemoryBackend_GetBuffer(B);
  CheckEquals('        ', Buf[0]);
  CheckEquals('  A     ', Buf[1]);

  // 帧2：未 Pop 的情况下，帧末应已清空视口栈；再次写入 (0,0) 'B' 应落在屏幕 (0,0)
  termui_frame_begin;
  UiWriteAt(0, 0, 'B');
  termui_frame_end;

  Buf := MemoryBackend_GetBuffer(B);
  CheckEquals('B       ', Buf[0]);
  CheckEquals('  A     ', Buf[1]);
  CheckEquals('        ', Buf[2]);
  CheckEquals('        ', Buf[3]);
end;

initialization
  RegisterTest(TUIViewStackRestore);

end.

