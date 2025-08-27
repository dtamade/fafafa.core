{$CODEPAGE UTF8}
unit Test_ui_clip_y_segments;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.env,
  fafafa.core.term.ui, ui_backend, ui_backend_memory, ui_surface;

type
  TUIClipYSegments = class(TTestCase)
  private
    class var SegCount: Integer;
    class procedure OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr); static;
  published
    procedure Test_Vertical_Clipping_With_Inline_Segments_No_Leak;
  end;

implementation

class procedure TUIClipYSegments.OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr);
begin
  Inc(SegCount);
end;

procedure TUIClipYSegments.Test_Vertical_Clipping_With_Inline_Segments_No_Leak;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  Attr: TUiAttr;
  GuardForce: TEnvOverrideGuard;
begin
  // 内存后端 10x5，开启 backbuffer
  B := CreateMemoryBackend(10, 5);
  UiBackendSetCurrent(B);
  termui_set_backbuffer_enabled(True);
  // 强制走分段策略，避免整行覆盖导致段计数为 0
  GuardForce := env_override('FAFAFA_TERM_UI_FORCE_LINE_REDRAW', '0');
  try
    SegCount := 0; UiDebug_SetSegmentEmitHook(@OnSeg);

    termui_frame_begin;
    // 视口：屏幕 (1,2) 起，宽8，高2 => 可见行是索引2与3
    UiPushView(1, 2, 8, 2, 0, 0);

    // 行0：红 'AAAA'
    FillChar(Attr, SizeOf(Attr), 0);
    Attr.HasFg := True; Attr.Fg.R := 255;
    UiSetAttr(Attr);
    UiWriteAt(0, 0, 'AAAA');

    // 行1：绿 'BBBB'
    Attr.Fg.R := 0; Attr.Fg.G := 255; Attr.Fg.B := 0;
    UiSetAttr(Attr);
    UiWriteAt(1, 0, 'BBBB');

    // 行2：蓝 'CCCC'（超出 viewport 高度，应被完全裁剪）
    Attr.Fg.G := 0; Attr.Fg.B := 255;
    UiSetAttr(Attr);
    UiWriteAt(2, 0, 'CCCC');

    termui_frame_end;

    // 文本断言：仅第2/3行有内容，并带有左移 1 列的视口偏移
    Buf := MemoryBackend_GetBuffer(B);
    CheckEquals('          ', Buf[0]);
    CheckEquals('          ', Buf[1]);
    CheckEquals(' AAAA     ', Buf[2]);
    CheckEquals(' BBBB     ', Buf[3]);
    CheckEquals('          ', Buf[4]);

    // 段计数至少 2（各行一段），且不会因被裁剪的行产生额外段
    AssertTrue('segment count >= 2 for two visible style segments', SegCount >= 2);
  finally
    GuardForce.Done;
    UiDebug_SetSegmentEmitHook(nil);
    UiPopView;
  end;
end;

initialization
  RegisterTest(TUIClipYSegments);

end.

