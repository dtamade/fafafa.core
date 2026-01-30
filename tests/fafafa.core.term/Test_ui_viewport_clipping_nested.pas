{$CODEPAGE UTF8}
unit Test_ui_viewport_clipping_nested;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory;

type
  TUIViewClipNested = class(TTestCase)
  published
    procedure Test_Nested_Viewports_Clip_To_Visible_Area;
  end;

implementation

procedure TUIViewClipNested.Test_Nested_Viewports_Clip_To_Visible_Area;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
begin
  // 内存后端 10x5
  B := CreateMemoryBackend(10, 5);
  UiBackendSetCurrent(B);

  termui_frame_begin;
  // 顶层视口：从 (2,1) 大小 6x3，可见范围横向 2..7、纵向 1..3
  UiPushView(2, 1, 6, 3, 0, 0);
  // 子视口：相对原点偏移 (1,1)，把本地 (0,0) 映射到屏幕 (3,2)
  UiPushView(0, 0, 4, 2, 1, 1);
  // 在子视口本地 (0,0) 写入 6 个字符，超出子视口宽度（4），应被裁剪为 4
  UiWriteAt(0, 0, 'ABCDEF');
  // 在子视口本地 (1,3) 写入，超过子视口高度（2），应全部被裁剪（不产生写入）
  UiWriteAt(1, 3, 'XXXX');
  UiPopView; // 退出子视口

  // 在父视口本地 (5,2) 写入，映射到屏幕 (7,3) 起始，宽度 6 应被裁剪到父视口剩余 1 列
  UiWriteAt(2, 5, 'YYYYYY');
  UiPopView; // 退出父视口
  termui_frame_end;

  Buf := MemoryBackend_GetBuffer(B);
  // 期望：
  // 行0: "          "
  // 行1: "          "
  // 行2: "   ABCD   "  // 'ABCD' 写到屏幕 (3,2)..(6,2)
  // 行3: "       Y  "  // 'Y' 写到 (7,3)
  // 行4: "          "
  CheckEquals('          ', Buf[0]);
  CheckEquals('          ', Buf[1]);
  CheckEquals('   ABCD   ', Buf[2]);
  CheckEquals('       Y  ', Buf[3]);
  CheckEquals('          ', Buf[4]);
end;

initialization
  RegisterTest(TUIViewClipNested);

end.

