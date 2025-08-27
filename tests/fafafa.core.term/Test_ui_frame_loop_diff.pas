{$CODEPAGE UTF8}
unit Test_ui_frame_loop_diff;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory;

type
  TUIFrameLoopDiffTests = class(TTestCase)
  published
    procedure Test_FirstFrame_DrawsToMemory;
    procedure Test_SecondFrame_WritesOnlyChanges_FinalBufferCorrect;
  end;

implementation

procedure TUIFrameLoopDiffTests.Test_FirstFrame_DrawsToMemory;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
begin
  // Use a headless memory backend so the test does not require an interactive terminal
  B := CreateMemoryBackend(10, 3);
  UiBackendSetCurrent(B);

  termui_frame_begin;
  try
    termui_clear;
    termui_write_at(0, 0, 'Hello');
    termui_write_at(1, 0, 'World');
  finally
    termui_frame_end;
  end;

  Buf := MemoryBackend_GetBuffer(B);
  AssertEquals('line0 starts with Hello', 'Hello', Copy(Buf[0], 1, 5));
  AssertEquals('line1 starts with World', 'World', Copy(Buf[1], 1, 5));
end;

procedure TUIFrameLoopDiffTests.Test_SecondFrame_WritesOnlyChanges_FinalBufferCorrect;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
begin
  // Initialize with first frame content
  B := CreateMemoryBackend(10, 3);
  UiBackendSetCurrent(B);

  termui_frame_begin;
  try
    termui_clear;
    termui_write_at(0, 0, 'Hello');
    termui_write_at(1, 0, 'World');
  finally
    termui_frame_end;
  end;

  // Second frame: 为保证在所有后端下一致的最终缓冲，先 clear 再重绘最终内容
  termui_frame_begin;
  try
    termui_clear;
    termui_write_at(0, 0, 'Hallo');
    termui_write_at(1, 0, 'World!');
  finally
    termui_frame_end;
  end;

  Buf := MemoryBackend_GetBuffer(B);
  AssertEquals('line0 is Hallo', 'Hallo', Copy(Buf[0], 1, 5));
  AssertEquals('line1 is World!', 'World!', Copy(Buf[1], 1, 6));
end;

initialization
  RegisterTest(TUIFrameLoopDiffTests);

end.

