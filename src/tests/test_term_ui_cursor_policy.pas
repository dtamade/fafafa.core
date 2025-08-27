unit test_term_ui_cursor_policy;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  ui_backend, ui_backend_memory,
  fafafa.core.term.ui;

procedure RegisterTermUiCursorPolicyTests;

implementation

// Hooks to capture last cursor position seen by UiGotoLineCol
var
  GLastHookLine, GLastHookCol: Integer;

procedure Hook_CursorLine(Line: Word);
begin
  // 1-based from surface; store as 0-based
  GLastHookLine := Line - 1;
end;

procedure Hook_CursorCol(Col: Word);
begin
  GLastHookCol := Col - 1;
end;

function Hook_Size(var W, H: Word): Boolean;
begin
  // Enable backbuffer by delegating to backend size
  Result := UiBackendGetCurrent.Size(W, H);
end;

procedure Hooks_On;
begin
  GLastHookLine := -1;
  GLastHookCol := -1;
  termui_debug_set_hooks(nil, nil, @Hook_CursorLine, @Hook_CursorCol, nil, @Hook_Size);
end;

procedure Hooks_Off;
begin
  termui_debug_reset_hooks;
end;


type
  TTermUiCursorPolicy = class(TTestCase)
  published
    procedure Test_Backbuffer_KeepCursorPosition;
    procedure Test_DirectWrite_ReturnToOrigin;
  end;

// Backbuffer mode: at frame end we should NOT force goto(0,0)
procedure TTermUiCursorPolicy.Test_Backbuffer_KeepCursorPosition;
var
  B: IUiBackend;
begin
  B := ui_backend_memory.CreateMemoryBackend(10, 3);
  UiBackendSetCurrent(B);
  Hooks_On;
  try
    termui_frame_begin;
    termui_write_at(1, 5, 'X');
    termui_frame_end;
    // If UiFrameEnd forced goto(0,0) we'd see hooks update to (0,0)
    // Expect to keep last write position (1,5) or at least not (0,0)
    fpcunit.TAssert.AssertTrue((GLastHookLine <> 0) or (GLastHookCol <> 0));
  finally
    Hooks_Off;
  end;
end;

// Direct write mode (backbuffer disabled): at frame end we DO force goto(0,0)
procedure TTermUiCursorPolicy.Test_DirectWrite_ReturnToOrigin;
var
  B: IUiBackend;
begin
  B := ui_backend_memory.CreateMemoryBackend(10, 3);
  UiBackendSetCurrent(B);
  termui_set_backbuffer_enabled(False);
  Hooks_On;
  try
    termui_frame_begin;
    termui_write_at(2, 7, 'Z');
    termui_frame_end;
    // In direct mode, we expect frame end to goto(0,0)
    fpcunit.TAssert.AssertEquals(0, GLastHookLine);
    fpcunit.TAssert.AssertEquals(0, GLastHookCol);
  finally
    termui_set_backbuffer_enabled(True);
    Hooks_Off;
  end;
end;


procedure RegisterTermUiCursorPolicyTests;
begin
  RegisterTest(TTermUiCursorPolicy);
end;

end.

