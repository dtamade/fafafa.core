{$CODEPAGE UTF8}
unit Test_ui_backbuffer_disabled_direct_write;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory;

type
  TUIBackbufferDirectWrite = class(TTestCase)
  published
    procedure Test_Direct_Write_When_Backbuffer_Disabled;
  end;

implementation

procedure TUIBackbufferDirectWrite.Test_Direct_Write_When_Backbuffer_Disabled;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
begin
  // 内存后端 8x3
  B := CreateMemoryBackend(8, 3);
  UiBackendSetCurrent(B);

  // 关闭 backbuffer：应直写到后端（内存后端作为 V2，UiWriteAt 会直接调用 WriteAt）
  termui_set_backbuffer_enabled(False);

  termui_frame_begin;
  UiWriteAt(1, 2, 'Hi');
  termui_frame_end;

  Buf := MemoryBackend_GetBuffer(B);
  // 预期行1（0-based 第二行）：前两个空格 + 'Hi' + 后续空格
  CheckEquals('        ', Buf[0]);
  CheckEquals('  Hi    ', Buf[1]);
  CheckEquals('        ', Buf[2]);

  // 恢复 backbuffer 设置，避免影响后续用例
  termui_set_backbuffer_enabled(True);
end;

initialization
  RegisterTest(TUIBackbufferDirectWrite);

end.

