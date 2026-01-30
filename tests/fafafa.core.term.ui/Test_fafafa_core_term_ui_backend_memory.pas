unit Test_fafafa_core_term_ui_backend_memory;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.term,
  fafafa.core.term.ui.surface,
  ui_backend, ui_backend_memory;

type
  TTestCase_MemoryBackend = class(TTestCase)
  published
    procedure Test_WriteAt_FillRect_Smoke;
  end;

implementation

procedure TTestCase_MemoryBackend.Test_WriteAt_FillRect_Smoke;
var
  b: IUiBackend;
  buf: TUnicodeStringArray;
begin
  // Arrange: switch to memory backend 8x4
  b := CreateMemoryBackend(8, 4);
  UiBackendSetCurrent(b);

  // Act: draw two frames with surface helpers
  fafafa.core.term.ui.surface.UiFrameBegin;
  fafafa.core.term.ui.surface.UiClear;
  fafafa.core.term.ui.surface.UiWriteAt(0, 0, 'Hello');
  fafafa.core.term.ui.surface.UiFrameEnd;

  fafafa.core.term.ui.surface.UiFrameBegin;
  fafafa.core.term.ui.surface.UiFillRect(2, 1, 3, 2, '*');
  fafafa.core.term.ui.surface.UiFrameEnd;

  // Assert: read back buffer and check a few positions (minimal checks)
  buf := MemoryBackend_GetBuffer(b);
  AssertEquals(4, Length(buf));
  AssertEquals(UnicodeString('Hello   '), buf[0]);
  // row 1 col 2..4 replaced by '*' (0-based col=2..4)
  AssertEquals(UnicodeString('  ***   '), buf[1]);
end;

initialization
  RegisterTest(TTestCase_MemoryBackend);

end.

