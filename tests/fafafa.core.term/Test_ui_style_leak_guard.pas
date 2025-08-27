{$CODEPAGE UTF8}
unit Test_ui_style_leak_guard;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory, ui_surface;

type
  TUIStyleLeakGuard = class(TTestCase)
  private
    class var SegCount: Integer;
    class procedure OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr); static;
  published
    procedure Test_Style_Leak_Guard_With_Reset_Between_Segments;
  end;

implementation

class procedure TUIStyleLeakGuard.OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr);
begin
  Inc(SegCount);
end;

procedure TUIStyleLeakGuard.Test_Style_Leak_Guard_With_Reset_Between_Segments;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  Attr: TUiAttr;
begin
  // 使用内存后端 16x3
  B := CreateMemoryBackend(16, 3);
  UiBackendSetCurrent(B);

  termui_set_backbuffer_enabled(True);
  SegCount := 0;
  UiDebug_SetSegmentEmitHook(@OnSeg);

  termui_frame_begin;
  // 段1：FG 红，写 'RR'
  FillChar(Attr, SizeOf(Attr), 0);
  Attr.HasFg := True; Attr.Fg.R := 255; Attr.Fg.G := 0; Attr.Fg.B := 0;
  UiSetAttr(Attr);
  UiWriteAt(1, 1, 'RR');

  // 段2：BG 绿，写 'GG'
  FillChar(Attr, SizeOf(Attr), 0);
  Attr.HasBg := True; Attr.Bg.R := 0; Attr.Bg.G := 255; Attr.Bg.B := 0;
  UiSetAttr(Attr);
  UiWriteAt(1, 4, 'GG');

  // 段3：FG 蓝 + BG 黄，写 'BY'
  FillChar(Attr, SizeOf(Attr), 0);
  Attr.HasFg := True; Attr.Fg.R := 0; Attr.Fg.G := 0; Attr.Fg.B := 255;
  Attr.HasBg := True; Attr.Bg.R := 255; Attr.Bg.G := 255; Attr.Bg.B := 0;
  UiSetAttr(Attr);
  UiWriteAt(1, 7, 'BY');

  // 段4：Reset 后无样式，写 'PL'
  UiAttrReset;
  UiWriteAt(1, 10, 'PL');
  termui_frame_end;

  Buf := MemoryBackend_GetBuffer(B);
  // 断言文本正确（空格+RR+空格+GG+空格+BY+空格+PL+空格）
  CheckEquals('                ', Buf[0]);
  CheckEquals(' RR GG BY PL   ', Buf[1]);
  CheckEquals('                ', Buf[2]);

  // 分段应为 4 段
  CheckEquals(4, SegCount);

  // 清理 hook
  UiDebug_SetSegmentEmitHook(nil);
end;

initialization
  RegisterTest(TUIStyleLeakGuard);

end.

