{$CODEPAGE UTF8}
unit Test_ui_diff_no_empty_segments;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory, ui_surface;

type
  TUIDiffNoEmptySegments = class(TTestCase)
  private
    class var SegCount: Integer;
    class procedure OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr); static;
  published
    procedure Test_Empty_Writes_Do_Not_Create_Segments;
  end;

implementation

class procedure TUIDiffNoEmptySegments.OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr);
begin
  Inc(SegCount);
end;

procedure TUIDiffNoEmptySegments.Test_Empty_Writes_Do_Not_Create_Segments;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  Attr: TUiAttr;
begin
  B := CreateMemoryBackend(10, 2);
  UiBackendSetCurrent(B);
  termui_set_backbuffer_enabled(True);

  SegCount := 0;
  UiDebug_SetSegmentEmitHook(@OnSeg);

  termui_frame_begin;
  // 多次切换样式并写入空字符串，不应产生任何 segment
  FillChar(Attr, SizeOf(Attr), 0);
  Attr.HasFg := True; Attr.Fg.R := 255; // 红
  UiSetAttr(Attr);
  UiWriteAt(0, 0, '');

  Attr.Fg.R := 0; Attr.Fg.G := 255; Attr.Fg.B := 0; // 绿
  UiSetAttr(Attr);
  UiWriteAt(0, 1, '');

  // 实际文本段1：蓝色 'A' 在列2
  Attr.Fg.G := 0; Attr.Fg.B := 255; // 蓝
  UiSetAttr(Attr);
  UiWriteAt(0, 2, 'A');

  // 再次切换样式但仍空写
  Attr.Fg.R := 128; Attr.Fg.G := 128; Attr.Fg.B := 0; // 黄褐
  UiSetAttr(Attr);
  UiWriteAt(0, 3, '');

  // 文本段2：Reset 后默认样式 'B' 在列4
  UiAttrReset;
  UiWriteAt(0, 4, 'B');

  termui_frame_end;

  Buf := MemoryBackend_GetBuffer(B);
  // 期望第0行内容：__A_B_____（下划线为空格，宽10）
  CheckEquals('  A B     ', Buf[0]);
  CheckEquals('          ', Buf[1]);

  // 仅两个实际文本段，应只发射 2 个 segment
  CheckEquals(2, SegCount);

  UiDebug_SetSegmentEmitHook(nil);
end;

initialization
  RegisterTest(TUIDiffNoEmptySegments);

end.

