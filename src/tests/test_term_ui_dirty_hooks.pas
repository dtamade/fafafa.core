unit test_term_ui_dirty_hooks;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  ui_backend, ui_backend_memory,
  fafafa.core.term, fafafa.core.term.ui;

procedure RegisterTermUiDirtyHookTests;

implementation

type
  TOp = record Line, Col: Integer; Text: UnicodeString; end;

var
  GOps: array of TOp;
  GCurLine, GCurCol: Integer;

procedure Hook_Write(const S: UnicodeString);
begin
  SetLength(GOps, Length(GOps)+1);
  GOps[High(GOps)].Line := GCurLine;
  GOps[High(GOps)].Col := GCurCol;
  GOps[High(GOps)].Text := S;
end;

procedure Hook_Writeln(const S: UnicodeString);
begin
  Hook_Write(S + LineEnding);
end;

procedure Hook_CursorLine(Line: term_size_t);
begin
  // hooks receive 1-based line; convert to 0-based
  GCurLine := Line - 1;
end;

procedure Hook_CursorCol(Col: term_size_t);
begin
  // hooks receive 1-based col; convert to 0-based
  GCurCol := Col - 1;
end;

function Hook_CursorVisibleSet(Visible: Boolean): Boolean;
begin
  Result := True;
end;

function Hook_Size(var W, H: term_size_t): Boolean;
begin
  // Delegate to backend size, and enable backbuffer mode by returning True
  Result := UiBackendGetCurrent.Size(W, H);
end;

procedure Hooks_On;
begin
  SetLength(GOps, 0);
  GCurLine := 0; GCurCol := 0;
  termui_debug_set_hooks(@Hook_Write, @Hook_Writeln, @Hook_CursorLine, @Hook_CursorCol, @Hook_CursorVisibleSet, @Hook_Size);
end;

procedure Hooks_Off;
begin
  termui_debug_reset_hooks;
end;

procedure AssertOpsCount(Expected: Integer);
begin
  fpcunit.TAssert.AssertEquals(Expected, Length(GOps));
end;

procedure AssertOp(i, Line, Col: Integer; const Text: UnicodeString);
begin
  fpcunit.TAssert.AssertTrue((i >= 0) and (i < Length(GOps)));
  fpcunit.TAssert.AssertEquals(Line, GOps[i].Line);
  fpcunit.TAssert.AssertEquals(Col, GOps[i].Col);
  fpcunit.TAssert.AssertEquals(UTF8Encode(Text), UTF8Encode(GOps[i].Text));
end;

type
  TTermUiDirtyHook = class(TTestCase)
  published
    procedure Test_Minimal_Diff_Single_Char;
    procedure Test_Minimal_Diff_Two_Segments;
    procedure Test_Negative_Origin_Left_Clip;
  end;

procedure TTermUiDirtyHook.Test_Minimal_Diff_Single_Char;
var
  B: IUiBackend;
begin
  B := ui_backend_memory.CreateMemoryBackend(20, 2);
  UiBackendSetCurrent(B);

  // First frame: draw baseline
  termui_frame_begin; try
    termui_write_at(0, 0, 'Hello World');
  finally termui_frame_end; end;

  // Second frame: small change
  Hooks_On; try
    termui_frame_begin; try
      termui_write_at(0, 0, 'Hello Xorld');
    finally termui_frame_end; end;
  finally Hooks_Off; end;

  // Expect one diff segment at line 0, col 6 with text 'X'
  AssertOpsCount(1);
  AssertOp(0, 0, 6, 'X');
end;

procedure TTermUiDirtyHook.Test_Minimal_Diff_Two_Segments;
var
  B: IUiBackend;
begin
  B := ui_backend_memory.CreateMemoryBackend(20, 2);
  UiBackendSetCurrent(B);

  termui_frame_begin; try
    termui_write_at(0, 0, 'abcdef');
  finally termui_frame_end; end;

  Hooks_On; try
    termui_frame_begin; try
      termui_write_at(0, 0, 'XbcdYf');
    finally termui_frame_end; end;
  finally Hooks_Off; end;

  // Expect two segments: 'X' at col 0 and 'Y' at col 4
  AssertOpsCount(2);
  AssertOp(0, 0, 0, 'X');
  AssertOp(1, 0, 4, 'Y');
end;

procedure TTermUiDirtyHook.Test_Negative_Origin_Left_Clip;
var
  B: IUiBackend;
  Buf: ui_backend_memory.TUnicodeStringArray;
begin
  B := ui_backend_memory.CreateMemoryBackend(20, 4);
  UiBackendSetCurrent(B);

  termui_frame_begin; try
    // Right-edge clipping: viewport width=2, write 'abc' -> only 'ab' fits
    termui_push_view(5, 1, 2, 1, 0, 0);
    try
      termui_write_at(0, 0, 'abc');
    finally
      termui_pop_view;
    end;
  finally termui_frame_end; end;

  Buf := ui_backend_memory.MemoryBackend_GetBuffer(UiBackendGetCurrent);
  // Expect 'ab' starting at absolute col=5 on line=1
  fpcunit.TAssert.AssertEquals(UTF8Encode(StringOfChar(' ',5)+'ab'+StringOfChar(' ',20-5-2)), UTF8Encode(Buf[1]));
end;



procedure RegisterTermUiDirtyHookTests;
begin
  RegisterTest(TTermUiDirtyHook);
end;

end.

