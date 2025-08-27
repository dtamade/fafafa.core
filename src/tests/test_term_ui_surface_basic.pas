unit test_term_ui_surface_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  ui_backend, ui_backend_memory,
  fafafa.core.term.ui;

type
  TTermUiSurfaceBasic = class(TTestCase)
  published
    procedure Test_WriteAt_And_FillLine;
    procedure Test_Frame_Begin_End_InvalidateRect;
  end;

procedure RegisterTermUiSurfaceTests;

implementation

procedure AssertBufLineEq(const Buf: ui_backend_memory.TUnicodeStringArray; Line: Integer; const Exp: UnicodeString);
begin
  fpcunit.TAssert.AssertTrue(Line >= 0);
  fpcunit.TAssert.AssertTrue(Line <= High(Buf));
  fpcunit.TAssert.AssertEquals(Length(Exp), Length(Buf[Line]));
  fpcunit.TAssert.AssertEquals(UTF8Encode(Exp), UTF8Encode(Buf[Line]));
end;

procedure TTermUiSurfaceBasic.Test_WriteAt_And_FillLine;
var
  B: IUiBackend;
  Buf: ui_backend_memory.TUnicodeStringArray;
begin
  // 20x4 buffer for easy assertions
  B := ui_backend_memory.CreateMemoryBackend(20, 4);
  UiBackendSetCurrent(B);

  termui_clear; // initializes buffer with spaces
  termui_write_at(0, 0, 'hello');
  termui_fill_line(1, 'x', 5);

  Buf := ui_backend_memory.MemoryBackend_GetBuffer(UiBackendGetCurrent);
  AssertBufLineEq(Buf, 0, 'hello' + StringOfChar(' ', 15));
  AssertBufLineEq(Buf, 1, StringOfChar('x', 5) + StringOfChar(' ', 15));
end;

procedure TTermUiSurfaceBasic.Test_Frame_Begin_End_InvalidateRect;
var
  B: IUiBackend;
  Buf: ui_backend_memory.TUnicodeStringArray;
begin
  B := ui_backend_memory.CreateMemoryBackend(10, 3);
  UiBackendSetCurrent(B);

  termui_frame_begin;
  try
    termui_fill_rect(2, 1, 5, 1, '#');
    termui_invalidate_rect(2, 1, 5, 1);
  finally
    termui_frame_end;
  end;

  Buf := ui_backend_memory.MemoryBackend_GetBuffer(UiBackendGetCurrent);
  AssertBufLineEq(Buf, 1, StringOfChar(' ', 2) + StringOfChar('#', 5) + StringOfChar(' ', 3));
end;

procedure RegisterTermUiSurfaceTests;
begin
  RegisterTest(TTermUiSurfaceBasic); // suite auto-discovers published test methods
end;

end.

