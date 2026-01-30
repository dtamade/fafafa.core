{$CODEPAGE UTF8}
unit Test_term_windows_mouse;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term, fafafa.core.term.windows;

type
  TTestCase_Windows_Mouse = class(TTestCase)
  published
    procedure Test_DoubleClick_Normalized_To_Press;
    procedure Test_XButtons_Map_To_Backward_Forward;
    procedure Test_Vertical_Wheel_Maps;
    procedure Test_Horizontal_Wheel_Maps;
  end;

implementation

procedure TTestCase_Windows_Mouse.Test_DoubleClick_Normalized_To_Press;
var
  rec: MOUSE_EVENT_RECORD;
  termWin: term_windows_t;
  ev: term_event_t;
begin
  FillChar(termWin, SizeOf(termWin), 0);
  FillChar(rec, SizeOf(rec), 0);
  // 模拟左键双击
  rec.dwMousePosition.X := 10; rec.dwMousePosition.Y := 5;
  rec.dwButtonState := FROM_LEFT_1ST_BUTTON_PRESSED;
  rec.dwEventFlags := DOUBLE_CLICK;
  ev := term_windows_convert_mouse_event(@termWin, rec);
  CheckEquals(LongInt(Ord(tek_mouse)), LongInt(ev.kind), 'event kind');
  CheckEquals(LongInt(Ord(tmb_left)), LongInt(ev.mouse.button), 'double click -> left button');
  CheckEquals(LongInt(Ord(tms_press)), LongInt(ev.mouse.state), 'double click normalized to press');
  // 坐标为 1 基
  CheckEquals(LongInt(11), LongInt(ev.mouse.x), 'x = 10 + 1');
  CheckEquals(LongInt(6), LongInt(ev.mouse.y), 'y = 5 + 1');
end;

procedure TTestCase_Windows_Mouse.Test_XButtons_Map_To_Backward_Forward;
var
  rec: MOUSE_EVENT_RECORD;
  termWin: term_windows_t;
  ev: term_event_t;
begin
  FillChar(termWin, SizeOf(termWin), 0);
  FillChar(rec, SizeOf(rec), 0);
  rec.dwMousePosition.X := 0; rec.dwMousePosition.Y := 0;

  // Press 3rd (XBUTTON1 -> backward)
  rec.dwButtonState := FROM_LEFT_3RD_BUTTON_PRESSED;
  rec.dwEventFlags := 0; // 边沿由 pressed 计算
  ev := term_windows_convert_mouse_event(@termWin, rec);
  CheckEquals(LongInt(Ord(tmb_backward)), LongInt(ev.mouse.button), 'XBUTTON1 -> backward');
  CheckEquals(LongInt(Ord(tms_press)), LongInt(ev.mouse.state), 'press');
  // Release
  termWin.last_button_state := rec.dwButtonState; // 上次为按下
  rec.dwButtonState := 0;
  ev := term_windows_convert_mouse_event(@termWin, rec);
  CheckEquals(LongInt(Ord(tmb_backward)), LongInt(ev.mouse.button), 'XBUTTON1 release keeps button');
  CheckEquals(LongInt(Ord(tms_release)), LongInt(ev.mouse.state), 'release');

  // Press 4th (XBUTTON2 -> forward)
  FillChar(termWin, SizeOf(termWin), 0);
  rec.dwButtonState := FROM_LEFT_4TH_BUTTON_PRESSED;
  ev := term_windows_convert_mouse_event(@termWin, rec);
  CheckEquals(LongInt(Ord(tmb_forward)), LongInt(ev.mouse.button), 'XBUTTON2 -> forward');
  CheckEquals(LongInt(Ord(tms_press)), LongInt(ev.mouse.state), 'press');
end;

procedure TTestCase_Windows_Mouse.Test_Vertical_Wheel_Maps;
var
  rec: MOUSE_EVENT_RECORD;
  termWin: term_windows_t;
  ev: term_event_t;
begin
  FillChar(termWin, SizeOf(termWin), 0);
  FillChar(rec, SizeOf(rec), 0);
  rec.dwEventFlags := MOUSE_WHEELED;
  // 正 delta -> wheel up
  rec.dwButtonState := DWORD(WORD($0078)) shl 16; // +120 -> $0078
  ev := term_windows_convert_mouse_event(@termWin, rec);
  CheckEquals(LongInt(Ord(tmb_wheel_up)), LongInt(ev.mouse.button), 'wheel up');
  CheckEquals(LongInt(Ord(tms_press)), LongInt(ev.mouse.state), 'press');
  // 负 delta -> wheel down
  rec.dwButtonState := DWORD(WORD($FF88)) shl 16; // -120 -> $FF88
  ev := term_windows_convert_mouse_event(@termWin, rec);
  CheckEquals(LongInt(Ord(tmb_wheel_down)), LongInt(ev.mouse.button), 'wheel down');
  CheckEquals(LongInt(Ord(tms_press)), LongInt(ev.mouse.state), 'press');
end;

procedure TTestCase_Windows_Mouse.Test_Horizontal_Wheel_Maps;
var
  rec: MOUSE_EVENT_RECORD;
  termWin: term_windows_t;
  ev: term_event_t;
begin
  FillChar(termWin, SizeOf(termWin), 0);
  FillChar(rec, SizeOf(rec), 0);
  rec.dwEventFlags := MOUSE_HWHEELED;
  // 正 delta -> wheel right
  rec.dwButtonState := DWORD(WORD($0078)) shl 16; // +120
  ev := term_windows_convert_mouse_event(@termWin, rec);
  CheckEquals(LongInt(Ord(tmb_wheel_right)), LongInt(ev.mouse.button), 'hwheel right');
  CheckEquals(LongInt(Ord(tms_press)), LongInt(ev.mouse.state), 'press');
  // 负 delta -> wheel left
  rec.dwButtonState := DWORD(WORD($FF88)) shl 16; // -120
  ev := term_windows_convert_mouse_event(@termWin, rec);
  CheckEquals(Ord(tmb_wheel_left), ev.mouse.button, 'hwheel left');
  CheckEquals(Ord(tms_press), ev.mouse.state, 'press');
end;

initialization
  RegisterTest(TTestCase_Windows_Mouse);
end.

