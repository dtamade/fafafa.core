{$CODEPAGE UTF8}
unit Test_term_input_semantics;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  TestHelpers_Env;

type
  TTestCase_InputSemantics = class(TTestCase)
  published
    procedure Test_KeyEvent_Modifiers_ToString;
    procedure Test_UnknownKey_ToString_NoCrash;
    procedure Test_ArrowKeys_ToString;
    procedure Test_ArrowKeys_WithModifiers_ToString;
    procedure Test_FunctionKeys_WithModifiers_ToString;
    procedure Test_NavigationKeys_ToString;
    procedure Test_Modifiers_Mapped_ToString;
    procedure Test_MouseEvent_Basics;
    procedure Test_MouseEvent_DragMove;
    procedure Test_MouseWheel_Basics;
  end;

implementation

procedure PushCSISeq(const s: AnsiString);
var
  i: Integer;
  ev: term_event_t;
begin
  // 直接推送字节到队列（简化：每字节一个普通键事件，再由 TTerminalInput 统一映射）
  for i := 1 to Length(s) do
  begin
    ev := term_event_key(KEY_UNKOWN, AnsiChar(s[i]), False, False, False);
    term_evnet_push(ev);
  end;
end;

procedure TTestCase_InputSemantics.Test_KeyEvent_Modifiers_ToString;
var
  E: TKeyEvent;
  S: string;
begin
  E := MakeKeyEvent(ktChar, 'a', [kmCtrl, kmAlt, kmShift]);
  S := KeyEventToString(E);
  AssertTrue('Should contain Ctrl+', Pos('Ctrl+', S) > 0);
  AssertTrue('Should contain Alt+', Pos('Alt+', S) > 0);
  AssertTrue('Should contain Shift+', Pos('Shift+', S) > 0);
  AssertTrue('Should contain a', Pos('a', S) > 0);
end;

procedure TTestCase_InputSemantics.Test_UnknownKey_ToString_NoCrash;
var
  E: TKeyEvent;
  S: string;
begin
  // 构造未知键，断言不崩溃且非空
  E := MakeKeyEvent(ktUnknown, #0, []);
  S := KeyEventToString(E);
  AssertTrue('Unknown key to string should not be empty', Length(S) > 0);
end;

procedure TTestCase_InputSemantics.Test_ArrowKeys_ToString;
var
  E: TKeyEvent;
  S: string;
begin
  E := MakeKeyEvent(ktArrowLeft);  S := KeyEventToString(E); AssertTrue(Pos('Left',  S) > 0);
  E := MakeKeyEvent(ktArrowRight); S := KeyEventToString(E); AssertTrue(Pos('Right', S) > 0);
  E := MakeKeyEvent(ktArrowUp);    S := KeyEventToString(E); AssertTrue(Pos('Up',    S) > 0);
  E := MakeKeyEvent(ktArrowDown);  S := KeyEventToString(E); AssertTrue(Pos('Down',  S) > 0);
end;

procedure TTestCase_InputSemantics.Test_ArrowKeys_WithModifiers_ToString;
var
  E: TKeyEvent;
  S: string;
begin
  E := MakeKeyEvent(ktArrowLeft,  #0, [kmCtrl]);   S := KeyEventToString(E); AssertTrue(Pos('Ctrl+Left',  S) > 0);
  E := MakeKeyEvent(ktArrowRight, #0, [kmAlt]);    S := KeyEventToString(E); AssertTrue(Pos('Alt+Right',  S) > 0);
  E := MakeKeyEvent(ktArrowUp,    #0, [kmShift]);  S := KeyEventToString(E); AssertTrue(Pos('Shift+Up',   S) > 0);
  E := MakeKeyEvent(ktArrowDown,  #0, [kmCtrl,kmAlt,kmShift]);
  S := KeyEventToString(E); AssertTrue(Pos('Ctrl+Shift+Alt+Down', S) > 0);
end;

procedure TTestCase_InputSemantics.Test_FunctionKeys_WithModifiers_ToString;
var
  E: TKeyEvent;
  S: string;
  i: Integer;
begin
  for i := 1 to 12 do
  begin
    case i of
      1: E := MakeKeyEvent(ktF1);
      2: E := MakeKeyEvent(ktF2);
      3: E := MakeKeyEvent(ktF3);
      4: E := MakeKeyEvent(ktF4);
      5: E := MakeKeyEvent(ktF5);
      6: E := MakeKeyEvent(ktF6);
      7: E := MakeKeyEvent(ktF7);
      8: E := MakeKeyEvent(ktF8);
      9: E := MakeKeyEvent(ktF9);
     10: E := MakeKeyEvent(ktF10);
     11: E := MakeKeyEvent(ktF11);
     12: E := MakeKeyEvent(ktF12);
    end;
    S := KeyEventToString(E);
    AssertTrue('F-key should render text', Pos('F', S) = 1);

    // 带修饰键
    E.Modifiers := [kmCtrl, kmAlt];
    S := KeyEventToString(E);
    AssertTrue('With modifiers', (Pos('Ctrl+', S) > 0) and (Pos('Alt+', S) > 0));
  end;

  end;




procedure TTestCase_InputSemantics.Test_NavigationKeys_ToString;
var
  E: TKeyEvent;
  S: string;
begin
  E := MakeKeyEvent(ktHome);    S := KeyEventToString(E); AssertTrue(Pos('Home',    S) > 0);
  E := MakeKeyEvent(ktEnd);     S := KeyEventToString(E); AssertTrue(Pos('End',     S) > 0);
  E := MakeKeyEvent(ktPageUp);  S := KeyEventToString(E); AssertTrue(Pos('PageUp',  S) > 0);
  E := MakeKeyEvent(ktPageDown);S := KeyEventToString(E); AssertTrue(Pos('PageDown',S) > 0);
  E := MakeKeyEvent(ktInsert);  S := KeyEventToString(E); AssertTrue(Pos('Insert',  S) > 0);
  E := MakeKeyEvent(ktDelete);  S := KeyEventToString(E); AssertTrue(Pos('Delete',  S) > 0);
end;

procedure TTestCase_InputSemantics.Test_MouseEvent_Basics;
var
  M: term_event_mouse_t;
  Ev: term_event_t;
begin
  FillByte(M, SizeOf(M), 0);
  M.x := 10; M.y := 5; M.button := 1; M.state := 1;
  Ev := term_event_mouse(M);
  AssertEquals('mouse kind', Ord(tek_mouse), Ord(Ev.kind));
  AssertEquals('mouse x', 10, Ev.mouse.x);
  AssertEquals('mouse y', 5, Ev.mouse.y);
end;

procedure TTestCase_InputSemantics.Test_MouseEvent_DragMove;
var
  M: term_event_mouse_t;
  Ev: term_event_t;
begin
  FillByte(M, SizeOf(M), 0);
  // 假定 state=2 表示移动中（与 tms_moved=2 匹配），button=1 表示左键
  M.x := 20; M.y := 8; M.button := 1; M.state := 2;
  M.shift := 1; M.ctrl := 0; M.alt := 1;
  Ev := term_event_mouse(M);
  AssertEquals(Ord(tek_mouse), Ord(Ev.kind));
  AssertEquals(20, Ev.mouse.x);
  AssertEquals(8, Ev.mouse.y);
  AssertEquals(2, Ev.mouse.state);
  AssertEquals(1, Ev.mouse.button);
  AssertEquals(1, Ev.mouse.shift);
  AssertEquals(0, Ev.mouse.ctrl);
  AssertEquals(1, Ev.mouse.alt);
end;

procedure TTestCase_InputSemantics.Test_MouseWheel_Basics;
var
  Ev: term_event_t;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    term_evnet_push(term_event_mouse(10,10, tms_press, tmb_wheel_up, False, False, False));
    CheckTrue(term_event_poll(Ev, 0));
    AssertEquals(Ord(tek_mouse), Ord(Ev.kind));
    AssertEquals(Ord(tmb_wheel_up), Ev.mouse.button);

    term_evnet_push(term_event_mouse(10,10, tms_press, tmb_wheel_down, False, False, False));
    CheckTrue(term_event_poll(Ev, 0));
    AssertEquals(Ord(tmb_wheel_down), Ev.mouse.button);
  finally
    term_done;
  end;
end;

procedure TTestCase_InputSemantics.Test_Modifiers_Mapped_ToString;
var
  E: TKeyEvent;
  S: string;
begin
  // 直接构造带修饰的方向键，验证 ToString 映射
  E := MakeKeyEvent(ktArrowUp, #0, [kmCtrl, kmShift]);
  S := KeyEventToString(E);
  AssertTrue('expect Up', Pos('Up', S) > 0);
  AssertTrue('expect Ctrl+', Pos('Ctrl+', S) > 0);
  AssertTrue('expect Shift+', Pos('Shift+', S) > 0);
end;

initialization
  RegisterTest(TTestCase_InputSemantics);
end.

