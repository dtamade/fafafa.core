{$CODEPAGE UTF8}
unit Test_fafafa_core_term_ui_attr_style_only_v2;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ui_backend, ui_backend_memory, ui_surface, ui_style;

type
  TTestCase_AttrStyleOnly = class(TTestCase)
  published
    procedure Test_StyleOnlyChange_ZeroTextWrites_WithV2;
  end;

implementation

var
  GWriteCount: SizeInt = 0;

procedure Hook_Write(const S: UnicodeString);
begin
  Inc(GWriteCount);
end;

procedure TTestCase_AttrStyleOnly.Test_StyleOnlyChange_ZeroTextWrites_WithV2;
var
  B: IUiBackend;
  prevCount: SizeInt;
begin
  // Arrange backend (V2 supported by memory backend)
  B := CreateMemoryBackend(10, 2);
  UiBackendSetCurrent(B);
  UiDebug_SetOutputHooks(@Hook_Write, nil, nil, nil, nil, nil);

  // Frame 1: draw text with default style
  UiFrameBegin;
  UiAttrReset;
  UiWriteAt(0, 0, 'abc');
  UiFrameEnd;

  // Frame 2: same text, style only change (FG) — expect 0 text writes
  prevCount := GWriteCount;
  UiFrameBegin;
  UiSetFg24(200, 50, 50);
  // 不重复写文本，直接结束帧；若仅样式变化生效，将不会触发文本 write
  UiFrameEnd;

  CheckEquals(prevCount, GWriteCount, 'Style-only change should cause zero text writes with V2');
  UiDebug_ResetOutputHooks;
end;

initialization
  RegisterTest(TTestCase_AttrStyleOnly);
end.

