{$CODEPAGE UTF8}
unit Test_ui_line_redraw_policy;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.env, fafafa.core.term.ui, ui_backend, ui_backend_memory, ui_surface;

type
  TUILineRedrawPolicy = class(TTestCase)
  private
    class var SegCount: Integer;
    class procedure OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr); static;
  published
    procedure Test_V2_Defaults_To_WholeLine_Redraw_Then_Force_Segments_With_Env;
  end;

implementation

class procedure TUILineRedrawPolicy.OnSeg(Line, Col, Len: term_size_t; const Attr: TUiAttr);
begin
  Inc(SegCount);
end;

procedure TUILineRedrawPolicy.Test_V2_Defaults_To_WholeLine_Redraw_Then_Force_Segments_With_Env;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  GuardForce: TEnvOverrideGuard;
  Attr: TUiAttr;
begin
  // 内存后端 12x2，默认 V2 支持，倾向整行重绘
  B := CreateMemoryBackend(12, 2);
  UiBackendSetCurrent(B);
  termui_set_backbuffer_enabled(True);

  // 首帧写入基线
  termui_frame_begin;
  FillChar(Attr, SizeOf(Attr), 0);
  Attr.HasFg := True; Attr.Fg.R := 255; // 给基线一段样式
  UiSetAttr(Attr);
  UiWriteAt(0, 0, 'HelloWorld  ');
  termui_frame_end;

  // 第二帧：做小改动（行内仅两处差异），默认应倾向整行重绘（SegmentEmitHook 可能为 0）
  TUILineRedrawPolicy.SegCount := 0;
  UiDebug_SetSegmentEmitHook(@OnSeg);
  termui_frame_begin;
  // 仅修改部分字符
  UiWriteAt(0, 5, 'X'); // HelloXorld
  UiWriteAt(0, 10, '!');
  termui_frame_end;
  Buf := MemoryBackend_GetBuffer(B);
  CheckEquals('HelloXorld!', TrimRight(Buf[0]));
  // 在默认策略下，V2 可能选择整行，分段计数应为 0 或很小（允许为 0）
  AssertTrue('default policy should not emit many segments', SegCount <= 1);

  // 第三帧：强制分段策略
  GuardForce := env_override('FAFAFA_TERM_UI_FORCE_LINE_REDRAW', '0');
  try
    // 做相似的小改动，但期望走分段
    TUILineRedrawPolicy.SegCount := 0;
    termui_frame_begin;
    UiWriteAt(0, 0, 'HalloXorld?');
    termui_frame_end;
    Buf := MemoryBackend_GetBuffer(B);
    CheckEquals('HalloXorld?', TrimRight(Buf[0]));
    // 现在应发生分段发射（至少 1 段）
    AssertTrue('forced segmented policy should emit segments', SegCount >= 1);
  finally
    GuardForce.Done;
    UiDebug_SetSegmentEmitHook(nil);
  end;
end;

initialization
  RegisterTest(TUILineRedrawPolicy);

end.

