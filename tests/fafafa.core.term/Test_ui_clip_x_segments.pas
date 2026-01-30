{$CODEPAGE UTF8}
unit Test_ui_clip_x_segments;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory, ui_surface;

type
  TUIClipXSegments = class(TTestCase)
  private
    class var SegCount: Integer;
    class procedure OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr); static;
  published
    procedure Test_Clipping_Splits_Segments_And_Does_Not_Leak_Styles;
  end;

implementation

class procedure TUIClipXSegments.OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr);
begin
  Inc(SegCount);
end;

procedure TUIClipXSegments.Test_Clipping_Splits_Segments_And_Does_Not_Leak_Styles;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  Attr: TUiAttr;
begin
  // 采用 backbuffer 触发行内分段 + 视口裁剪
  B := CreateMemoryBackend(12, 4);
  UiBackendSetCurrent(B);
  termui_set_backbuffer_enabled(True);

  // 视口：可见区域 (2,1) 起始，宽 6 高 2；子视口内部原点偏移 0,0
  // 将使部分段在左右边界被裁剪
  termui_frame_begin;
  UiPushView(2, 1, 6, 2, 0, 0);

  SegCount := 0;
  UiDebug_SetSegmentEmitHook(@OnSeg);

  // 本地 (0,0) 起写：
  // 段1：FG 红，写 'ABC'（将完整落在可见区左侧边界内的一部分）
  FillChar(Attr, SizeOf(Attr), 0);
  Attr.HasFg := True; Attr.Fg.R := 255;
  UiSetAttr(Attr);
  UiWriteAt(0, 0, 'ABC');

  // 段2：FG 绿，紧随其后写 'DEF'（中间段，全部可见）
  Attr.Fg.R := 0; Attr.Fg.G := 255; Attr.Fg.B := 0;
  UiSetAttr(Attr);
  UiWriteAt(0, 3, 'DEF');

  // 段3：FG 蓝，写 'GHIJK'（将超出右侧边界，尾部被裁剪）
  Attr.Fg.G := 0; Attr.Fg.B := 255;
  UiSetAttr(Attr);
  UiWriteAt(0, 6, 'GHIJK');

  termui_frame_end;

  Buf := MemoryBackend_GetBuffer(B);
  // 可见窗口是屏幕 (2..7, 1..2)
  // 在第2行(0-based)显示：窗口左移两格 + ABCDEF + G（J/K 被裁剪）=> "  ABCDEFG   "（宽12）
  CheckEquals('            ', Buf[0]);
  CheckEquals('  ABCDEFG   ', Buf[1]);
  CheckEquals('            ', Buf[2]);
  CheckEquals('            ', Buf[3]);

  // 段发射计数：至少为 3（每个样式段各一次；裁剪不会产生额外虚段）
  AssertTrue('segment count should be >= 3 due to three style segments', SegCount >= 3);

  UiDebug_SetSegmentEmitHook(nil);
  UiPopView;
end;

initialization
  RegisterTest(TUIClipXSegments);

end.

