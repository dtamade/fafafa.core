unit Test_fafafa_core_term_ui_with_view;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  fpcunit, testutils, testregistry,
  fafafa.core.term, fafafa.core.term.ui,
  ui_backend, ui_backend_memory;

type
  TTestCase_WithView = class(TTestCase)
  published
    procedure Test_WithView_Clips_To_Viewport_Right;
  end;

implementation

// Global render proc (non-nested) to satisfy TUiRenderProc (non-method)
procedure Render_WithView_Right;
begin
  // Inside view: write at relative (line=0, col=4) so only 'AB' remains visible after clipping
  termui_write_at(0, 4, 'ABCDEFG');
end;

procedure TTestCase_WithView.Test_WithView_Clips_To_Viewport_Right;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  W,H: term_size_t;
begin
  // Arrange: 10x4 memory backend
  W := 10; H := 4;
  B := ui_backend_memory.CreateMemoryBackend(W, H);
  ui_backend.UiBackendSetCurrent(B);

  // Act
  termui_frame_begin;
  try
    // viewport: X=2..7 (W=6), Y=1..2 (H=2)
    termui_with_view(2, 1, 6, 2, 0, 0, @Render_WithView_Right);
  finally
    termui_frame_end;
  end;

  // Assert: only 'AB' visible at global cols 6..7 on line 1
  Buf := ui_backend_memory.MemoryBackend_GetBuffer(B);
  AssertEquals('buffer height', 4, Length(Buf));
  AssertEquals('line 1 visible window', '      AB  ', Buf[1]);
end;

initialization
  RegisterTest(TTestCase_WithView);

end.

