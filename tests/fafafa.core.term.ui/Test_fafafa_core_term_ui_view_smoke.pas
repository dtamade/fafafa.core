unit Test_fafafa_core_term_ui_view_smoke;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.term,
  fafafa.core.term.ui.surface,
  ui_backend, ui_backend_memory;

type
  TTestCase_ViewSmoke = class(TTestCase)
  published
    procedure Test_PushView_Write_Clip_Smoke;
  end;

implementation

procedure TTestCase_ViewSmoke.Test_PushView_Write_Clip_Smoke;
var
  b: IUiBackend;
  buf: TUnicodeStringArray;
begin
  // Arrange: 6x3 buffer, push a viewport at (2,1) size (3x1)
  b := CreateMemoryBackend(6, 3);
  UiBackendSetCurrent(b);

  fafafa.core.term.ui.surface.UiFrameBegin;
  try
    fafafa.core.term.ui.surface.UiClear;
    fafafa.core.term.ui.surface.UiPushView(2, 1, 3, 1, 0, 0);
    // This should be clipped to width 3 inside the viewport, placed at row=1, col=2
    fafafa.core.term.ui.surface.UiWriteAt(0, 0, 'ABCD');
    fafafa.core.term.ui.surface.UiPopView;
  finally
    fafafa.core.term.ui.surface.UiFrameEnd;
  end;

  // Assert
  buf := MemoryBackend_GetBuffer(b);
  AssertEquals(3, Length(buf));
  AssertEquals(UnicodeString('      '), buf[0]);
  AssertEquals(UnicodeString('  ABC '), buf[1]);
  AssertEquals(UnicodeString('      '), buf[2]);
end;

initialization
  RegisterTest(TTestCase_ViewSmoke);

end.

