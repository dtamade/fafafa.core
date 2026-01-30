{$CODEPAGE UTF8}
unit Test_term_unix_sequences;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_UnixSequences = class(TTestCase)
  published
    procedure Test_SGR_Mouse_Wheel_With_Modifiers;
    procedure Test_Tilde_Style_With_Modifiers;
    procedure Test_Bracketed_Paste_Parse;
  end;
    procedure Test_Focus_In_Out;
    procedure Test_Resize_Signal_Push;

    procedure Test_Bracketed_Paste_Parse;


implementation

{$IFDEF UNIX}

procedure PushCSISeq(const s: AnsiString);
var
  i: Integer;
  ev: term_event_t;
begin
  for i := 1 to Length(s) do
  begin
    ev := term_event_key(KEY_UNKOWN, AnsiChar(s[i]), False, False, False);
    term_evnet_push(ev);
  end;
end;

procedure TTestCase_UnixSequences.Test_SGR_Mouse_Wheel_With_Modifiers;
var
  Ev: term_event_t;
begin
  // ESC [ < 64 ; 12 ; 34 M  -> Wheel Up at (12,34)
  // 再加修饰位：+4=Shift, +16=Ctrl => 64 + 4 + 16 = 84
  term_init;
  try
    PushCSISeq(#27'[<84;12;34M');
    CheckTrue(term_event_poll(Ev, 0));
    AssertEquals(Ord(tek_mouse), Ord(Ev.kind));
    AssertEquals(12, Ev.mouse.x);
    AssertEquals(34, Ev.mouse.y);
    AssertEquals(Ord(tmb_wheel_up), Ev.mouse.button);
    AssertEquals(1, Ev.mouse.shift);
    AssertEquals(1, Ev.mouse.ctrl);
    AssertEquals(0, Ev.mouse.alt);
    AssertEquals(Ord(tms_press), Ev.mouse.state);
  finally

procedure TTestCase_UnixSequences.Test_Focus_In_Out;
var
  Ev: term_event_t;
begin
  {$IFDEF UNIX}
  term_init;
  try
    // ESC [ I -> FocusIn
    PushCSISeq(#27'[I');
    CheckTrue(term_event_poll(Ev, 0));
    AssertEquals(Ord(tek_focus), Ord(Ev.kind));
    AssertEquals(True, Ev.focus.focus);

    // ESC [ O -> FocusOut
    PushCSISeq(#27'[O');
    CheckTrue(term_event_poll(Ev, 0));
    AssertEquals(Ord(tek_focus), Ord(Ev.kind));
    AssertEquals(False, Ev.focus.focus);
  finally
    term_done;
  end;
  {$ELSE}
  CheckTrue(True, 'not unix, skip');
  {$ENDIF}
end;

procedure TTestCase_UnixSequences.Test_Resize_Signal_Push;
var
  w,h: UInt16;
  Ev: term_event_t;
begin
  {$IFDEF UNIX}
  term_init;
  try
    // 直接调用公共 push API 模拟信号触发后的效果
    term_event_push_size_change(120, 40);
    CheckTrue(term_event_poll(Ev, 0));
    AssertEquals(Ord(tek_sizeChange), Ord(Ev.kind));
    AssertEquals(120, Ev.size.width);
    AssertEquals(40, Ev.size.height);
  finally
    term_done;
  end;
  {$ELSE}
  CheckTrue(True, 'not unix, skip');
  {$ENDIF}
end;

    term_done;
  end;
end;

procedure TTestCase_UnixSequences.Test_Tilde_Style_With_Modifiers;
var
  K: TKeyEvent;
  S: string;
  LTerm: ITerminal;
  LInput: ITerminalInput;
begin
  // ESC [ 5 ; 6 ~  -> PageUp + Shift+Ctrl (mod=6)
  term_init;
  try
    PushCSISeq(#27'[5;6~');
    LTerm := CreateTerminal;
    LInput := LTerm.Input;
    CheckTrue(LInput.HasInput);
    CheckTrue(LInput.TryReadKey(K));
    S := KeyEventToString(K);
    AssertTrue('expect PageUp', Pos('PageUp', S) > 0);
    AssertTrue('expect Ctrl+', Pos('Ctrl+', S) > 0);
    AssertTrue('expect Shift+', Pos('Shift+', S) > 0);

procedure TTestCase_UnixSequences.Test_Bracketed_Paste_Parse;
var
  Ev: term_event_t;
  S: string;
begin
  {$IFDEF UNIX}
  term_init;
  try
    // ESC[200~hello worldESC[201~
    PushCSISeq(#27'[200~hello world'#27'[201~');
    CheckTrue(term_event_poll(Ev, 0));
    AssertEquals(Ord(tek_paste), Ord(Ev.kind));
    S := term_paste_get_text(Ev.paste.id);
    AssertEquals('hello world', S);
  finally
    term_done;
  end;
  {$ELSE}
  CheckTrue(True, 'not unix, skip');
  {$ENDIF}
end;

end;

  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTestCase_UnixSequences);

{$ENDIF}

end.

