unit test_term_ui_view_attr;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  ui_backend, ui_backend_memory,
  fafafa.core.term.ui;

type
  TTermUiViewAttr = class(TTestCase)
  published
    procedure Test_WithView_Origin_Clipping;
    procedure Test_WriteAt_Clipped_Helper;
    procedure Test_StatusLine_Content;
    procedure Test_WithView_Nested_Clipping;
    procedure Test_Write_Center;
  end;

procedure RegisterTermUiViewAttrTests;

implementation

procedure AssertBufLineEq(const Buf: ui_backend_memory.TUnicodeStringArray; Line: Integer; const Exp: UnicodeString);
begin
  fpcunit.TAssert.AssertTrue(Line >= 0);
  fpcunit.TAssert.AssertTrue(Line <= High(Buf));
  fpcunit.TAssert.AssertEquals(UTF8Encode(Exp), UTF8Encode(Buf[Line]));
end;

procedure TTermUiViewAttr.Test_WithView_Origin_Clipping;
var
  B: IUiBackend;
  Buf: ui_backend_memory.TUnicodeStringArray;
begin
  // 20x5 buffer
  B := ui_backend_memory.CreateMemoryBackend(20, 5);
  UiBackendSetCurrent(B);

  termui_frame_begin;
  try
    // View at (5,1) size (6x2), local origin (1,1)
    termui_push_view(5, 1, 6, 2, 1, 1);
    try
      // local (0,0) -> screen (X=5+1+0=6, Y=1+1+0=2), clip width to 5 (since start inside view by 1)
      termui_write_at(0, 0, 'ABCDEFG');
    finally
      termui_pop_view;
    end;
  finally
    termui_frame_end;
  end;

  Buf := ui_backend_memory.MemoryBackend_GetBuffer(UiBackendGetCurrent);
  // Expect on line 2 (0-based): 6 spaces then 'ABCDE' then rest spaces
  AssertBufLineEq(Buf, 2, StringOfChar(' ', 6) + 'ABCDE' + StringOfChar(' ', 20-6-5));
end;

procedure TTermUiViewAttr.Test_WriteAt_Clipped_Helper;
var
  B: IUiBackend;
  Buf: ui_backend_memory.TUnicodeStringArray;
begin
  B := ui_backend_memory.CreateMemoryBackend(20, 3);
  UiBackendSetCurrent(B);

  termui_frame_begin;
  try
    termui_clear;
    termui_write_at_clipped(0, 2, 5, 'hello world');
  finally
    termui_frame_end;
  end;

  Buf := ui_backend_memory.MemoryBackend_GetBuffer(UiBackendGetCurrent);
  AssertBufLineEq(Buf, 0, StringOfChar(' ', 2) + 'hello' + StringOfChar(' ', 20-2-5));
end;

procedure TTermUiViewAttr.Test_StatusLine_Content;
var
  B: IUiBackend;
  Buf: ui_backend_memory.TUnicodeStringArray;
  Attr: TUiAttr;
begin
  B := ui_backend_memory.CreateMemoryBackend(20, 2);
  UiBackendSetCurrent(B);


  termui_frame_begin;
  try
    Attr := termui_attr_preset_info;
    termui_status_line(1, 'STATUS', Attr);
  finally
    termui_frame_end;
  end;

  Buf := ui_backend_memory.MemoryBackend_GetBuffer(UiBackendGetCurrent);
  AssertBufLineEq(Buf, 1, 'STATUS' + StringOfChar(' ', 20-6));
end;


procedure TTermUiViewAttr.Test_WithView_Nested_Clipping;
var
  B: IUiBackend;
  Buf: ui_backend_memory.TUnicodeStringArray;
begin
  B := ui_backend_memory.CreateMemoryBackend(20, 5);
  UiBackendSetCurrent(B);

  termui_frame_begin; try
    // Outer view at (2,1) size (10x3)
    termui_push_view(2, 1, 10, 3, 0, 0);
    try
      // Inner view at (6,2) absolute (i.e., relative to screen), size (5x2)
      // Since our PushView uses absolute coordinates, set inner X,Y = 2+4,1+1
      termui_push_view(6, 2, 5, 2, 0, 0);
      try
        termui_write_at(0, 0, '1234567'); // expect only first 5 visible at col=6 on line=2
      finally
        termui_pop_view;
      end;
    finally
      termui_pop_view;
    end;
  finally termui_frame_end; end;

  Buf := ui_backend_memory.MemoryBackend_GetBuffer(UiBackendGetCurrent);
  AssertBufLineEq(Buf, 2, StringOfChar(' ',6) + '12345' + StringOfChar(' ',20-6-5));
end;

procedure TTermUiViewAttr.Test_Write_Center;
var
  B: IUiBackend;
  Buf: ui_backend_memory.TUnicodeStringArray;
begin
  B := ui_backend_memory.CreateMemoryBackend(20, 1);
  UiBackendSetCurrent(B);

  termui_frame_begin; try
    termui_write_center(0, 'ABCD', 20); // centered: starts at col=(20-4)/2=8
  finally termui_frame_end; end;

  Buf := ui_backend_memory.MemoryBackend_GetBuffer(UiBackendGetCurrent);
  AssertBufLineEq(Buf, 0, StringOfChar(' ',8) + 'ABCD' + StringOfChar(' ',8));
end;


procedure RegisterTermUiViewAttrTests;
begin
  RegisterTest(TTermUiViewAttr);
end;

end.

