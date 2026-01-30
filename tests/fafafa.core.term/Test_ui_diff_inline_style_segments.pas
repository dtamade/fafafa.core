{$CODEPAGE UTF8}
unit Test_ui_diff_inline_style_segments;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory, ui_surface;

type
  TUIDiffInlineStyleSegments = class(TTestCase)
  private
    class var SegCount: Integer;
    class procedure OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr); static;
  published
    procedure Test_Inline_Style_Segments_Are_Emitted_Separately_With_Reset;
  end;

implementation

class procedure TUIDiffInlineStyleSegments.OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr);
begin
  Inc(SegCount);
end;

procedure TUIDiffInlineStyleSegments.Test_Inline_Style_Segments_Are_Emitted_Separately_With_Reset;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  Attr: TUiAttr;
begin
  // 使用内存后端 12x3
  B := CreateMemoryBackend(12, 3);
  UiBackendSetCurrent(B);

  // 开启 backbuffer 以触发 diff
  termui_set_backbuffer_enabled(True);
  // 注册段发射 hook
  SegCount := 0;
  UiDebug_SetSegmentEmitHook(@OnSeg);

  termui_frame_begin;
  // 写入一行三段：
  // 段1：FG=(255,0,0) 写 'AA'
  FillChar(Attr, SizeOf(Attr), 0);
  Attr.HasFg := True; Attr.Fg.R := 255; Attr.Fg.G := 0; Attr.Fg.B := 0;
  UiSetAttr(Attr);
  UiWriteAt(1, 1, 'AA');
  // 段2：FG=(0,255,0) 写 'BB'
  Attr.Fg.R := 0; Attr.Fg.G := 255; Attr.Fg.B := 0;
  UiSetAttr(Attr);
  UiWriteAt(1, 3, 'BB');
  // 段3：FG=(0,0,255) 写 'CC'
  Attr.Fg.R := 0; Attr.Fg.G := 0; Attr.Fg.B := 255;
  UiSetAttr(Attr);
  UiWriteAt(1, 5, 'CC');
  termui_frame_end;

  // 断言内存缓冲的可见文本正确
  Buf := MemoryBackend_GetBuffer(B);
  CheckEquals('            ', Buf[0]);
  CheckEquals(' AA BB CC  ', Buf[1]);
  CheckEquals('            ', Buf[2]);

  // 断言段数（3 段），每段之间有不同样式，应被分段发射
  CheckEquals(3, SegCount);

  // 清理 hook，避免影响其他用例
  UiDebug_SetSegmentEmitHook(nil);
end;

initialization
  RegisterTest(TUIDiffInlineStyleSegments);

end.

