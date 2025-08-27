unit Test_fafafa_core_term_ui_with_view_fillrect;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  fpcunit, testregistry,
  fafafa.core.term, fafafa.core.term.ui,
  ui_backend, ui_backend_memory;

type
  TTestCase_WithView_FillRect = class(TTestCase)
  published
    procedure Test_WithView_FillRect_Clips_BottomRight;
    procedure Test_WithView_Nested_Viewport_Clipping;
  end;

implementation

// Global render procs for TUiRenderProc
procedure Render_WithView_FillRect_Clips_BR;
begin
  // Draw a huge rect relative to the view; should be clipped to the visible part only
  termui_fill_rect(0, 0, 10, 10, '#');
end;

procedure Render_WithView_Nested_Inner;
begin
  termui_write_at(0, 0, 'XYZ');
end;

procedure Render_WithView_Nested_Outer;
begin
  // Outer view: (2,1) size (6x3)
  // Inner view uses ABSOLUTE coordinates: (3,2) size (4x2)
  termui_with_view(3, 2, 4, 2, 0, 0, @Render_WithView_Nested_Inner);
end;

procedure TTestCase_WithView_FillRect.Test_WithView_FillRect_Clips_BottomRight;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  W,H: term_size_t;
begin
  // Arrange: memory backend 10x4
  W := 10; H := 4;
  B := ui_backend_memory.CreateMemoryBackend(W, H);
  ui_backend.UiBackendSetCurrent(B);

  // Act: use view starting near bottom-right so most area is clipped
  termui_frame_begin;
  try
    // View: X=7..(11) -> visible cols 7..9; Y=2..(4) -> visible lines 2..3
    termui_with_view(7, 2, 5, 3, 0, 0, @Render_WithView_FillRect_Clips_BR);
  finally
    termui_frame_end;
  end;

  // Assert
  Buf := ui_backend_memory.MemoryBackend_GetBuffer(B);
  AssertEquals('buffer height', 4, Length(Buf));
  AssertEquals('line0', '          ', Buf[0]);
  AssertEquals('line1', '          ', Buf[1]);
  AssertEquals('line2', '       ###', Buf[2]);
  AssertEquals('line3', '       ###', Buf[3]);
end;

procedure TTestCase_WithView_FillRect.Test_WithView_Nested_Viewport_Clipping;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  W,H: term_size_t;
begin
  // Arrange
  W := 10; H := 4;
  B := ui_backend_memory.CreateMemoryBackend(W, H);
  ui_backend.UiBackendSetCurrent(B);

  // Act: outer view (2,1,6,3), inner view (1,1,4,2) writes 'XYZ' at (0,0)
  termui_frame_begin;
  try
    termui_with_view(2, 1, 6, 3, 0, 0, @Render_WithView_Nested_Outer);
  finally
    termui_frame_end;
  end;

  // Assert: global line=2 (0-based), col=3..5 should be 'XYZ'
  Buf := ui_backend_memory.MemoryBackend_GetBuffer(B);
  AssertEquals('buffer height', 4, Length(Buf));
  AssertEquals('line2 content', '   XYZ    ', Buf[2]);
end;

initialization
  RegisterTest(TTestCase_WithView_FillRect);

end.

