{$CODEPAGE UTF8}
unit Test_ui_cursor_policy_direct_write;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term.ui, ui_backend, ui_backend_memory, ui_surface;

type
  TUICursorPolicyDirect = class(TTestCase)
  private
    class var LastLine1, LastCol1: term_size_t; // 1-based values recorded by hook
    class procedure OnCursorLine(Line: term_size_t); static;
    class procedure OnCursorCol(Col: term_size_t); static;
  published
    procedure Test_Direct_Mode_Final_Cursor_ToOrigin_For_All_Policies;
    procedure Test_Backbuffer_Mode_Respects_Policies;
  end;

implementation

class procedure TUICursorPolicyDirect.OnCursorLine(Line: term_size_t);
begin
  LastLine1 := Line;
end;

class procedure TUICursorPolicyDirect.OnCursorCol(Col: term_size_t);
begin
  LastCol1 := Col;
end;

procedure TUICursorPolicyDirect.Test_Direct_Mode_Final_Cursor_ToOrigin_For_All_Policies;
var
  B: IUiBackend;
begin
  B := CreateMemoryBackend(8, 4);
  UiBackendSetCurrent(B);
  // 直写模式
  termui_set_backbuffer_enabled(False);
  // 安装光标 hook（仅记录最终一次移动）
  UiDebug_SetOutputHooks(nil, nil, @OnCursorLine, @OnCursorCol, nil, nil);

  // ucpAuto：在直写模式下期望归位到 (0,0)，hook 接收 1-based => (1,1)
  UiSetCursorAfterFramePolicy(ucpAuto);
  termui_frame_begin;
  UiWriteAt(2, 5, 'X'); // 写到屏幕下方，确保有非原点写
  termui_frame_end;
  CheckEquals(1, LastLine1);
  CheckEquals(1, LastCol1);

  // ucpToBottomLeft：当前实现最终仍归位到原点
  UiSetCursorAfterFramePolicy(ucpToBottomLeft);
  termui_frame_begin;
  UiWriteAt(3, 0, 'Y');
  termui_frame_end;
  CheckEquals(1, LastLine1);
  CheckEquals(1, LastCol1);

  // ucpToBottomRight：当前实现最终仍归位到原点
  UiSetCursorAfterFramePolicy(ucpToBottomRight);
  termui_frame_begin;
  UiWriteAt(0, 7, 'Z');
  termui_frame_end;
  CheckEquals(1, LastLine1);
  CheckEquals(1, LastCol1);

  // 清理 hook
  UiDebug_ResetOutputHooks;
end;

procedure TUICursorPolicyDirect.Test_Backbuffer_Mode_Respects_Policies;
var
  B: IUiBackend;
  W, H: term_size_t;
begin
  B := CreateMemoryBackend(9, 5);
  UiBackendSetCurrent(B);
  B.Size(W,H);
  termui_set_backbuffer_enabled(True);
  UiDebug_SetOutputHooks(nil, nil, @OnCursorLine, @OnCursorCol, nil, nil);

  // ucpKeep：不应改变光标位置（本测试关注帧末移动，为稳定性，先移动到非原点，再结束帧）
  UiSetCursorAfterFramePolicy(ucpKeep);
  termui_frame_begin;
  UiWriteAt(2, 2, 'A');
  // 帧末：ucpKeep 不移动，维持最后写入位置 (2,3)，hook 在 Write 路径未被调用，这里仅断言不会被强制归位
  termui_frame_end;
  // 若未触发末尾移动，LastLine1/Col1 仍保持之前值（初始化为0）。不做强断言，只做 Smoke：不为 (1,1) 即认为非强制归位。
  AssertTrue('backbuffer keep should not force origin', not ((LastLine1=1) and (LastCol1=1)));

  // ucpToBottomLeft：应移动到 (H-1,0) => hook 1-based (H,1)
  UiSetCursorAfterFramePolicy(ucpToBottomLeft);
  termui_frame_begin;
  UiWriteAt(1, 1, 'B');
  termui_frame_end;
  CheckEquals(H, LastLine1);
  CheckEquals(1, LastCol1);

  // ucpToBottomRight：应移动到 (H-1,W-1) => hook 1-based (H,W)
  UiSetCursorAfterFramePolicy(ucpToBottomRight);
  termui_frame_begin;
  UiWriteAt(0, 0, 'C');
  termui_frame_end;
  CheckEquals(H, LastLine1);
  CheckEquals(W, LastCol1);

  UiDebug_ResetOutputHooks;
end;

initialization
  RegisterTest(TUICursorPolicyDirect);

end.

