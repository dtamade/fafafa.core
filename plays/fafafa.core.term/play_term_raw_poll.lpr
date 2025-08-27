{$CODEPAGE UTF8}
program play_term_raw_poll;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.term;

procedure PrintHelp;
begin
  WriteLn('play_term_raw_poll - interactive demo');
  WriteLn('  q/Q: quit');
  WriteLn('  shows key events; on ANSI terminals, toggles alt screen and raw mode');
end;

var
  ok: Boolean;
  ev: term_event_t;
  w,h: term_size_t;
begin
  if not term_init then begin
    WriteLn('term_init failed');
    Halt(1);
  end;
  try
    PrintHelp;
    if term_support_ansi then begin
      term_alternate_screen_enable(true);
      term_focus_enable(true);
      term_paste_bracket_enable(true);
      term_sync_update_enable(true);
    end;
    term_cursor_hide;
    term_raw_mode_enable(true);
    term_mouse_enable; // if unsupported, should be harmless no-op/False

    if term_size(w,h) then begin
      term_cursor_set(0,0);
      term_writeln(Format('Terminal size: %dx%d', [w,h]));
    end;
    term_cursor_set(0,1);
    term_writeln(Format('Support: ANSI=%s Mouse=%s AltScreen=%s Focus=%s Paste=%s Sync=%s', [
      BoolToStr(term_support_ansi, True),
      BoolToStr(term_support_mouse, True),
      BoolToStr(term_support_alternate_screen, True),
      BoolToStr(term_support_focus_1004, True),
      BoolToStr(term_support_paste_2004, True),
      BoolToStr(term_support_sync_update, True)
    ]));

    repeat
      ok := term_event_poll(ev, 25); // 25ms small timeout for responsiveness
      if ok then begin
        case ev.kind of
          tek_key:
            begin
              term_cursor_set(0,2);
              term_writeln(Format('Key: code=%d shift=%d ctrl=%d alt=%d char=%s        ',
                [Ord(ev.key.key), ev.key.shift, ev.key.ctrl, ev.key.alt, {$IFDEF FPC}UTF8Encode(ev.key.char.char){$ELSE}UTF8Encode(ev.key.char.char){$ENDIF}]));
              if (ev.key.key = KEY_Q) or (ev.key.key = KEY_q) then Break;
            end;
          tek_mouse:
            begin
              term_cursor_set(0,3);
              term_writeln(Format('Mouse: x=%d y=%d state=%d button=%d                ',
                [ev.mouse.x, ev.mouse.y, ev.mouse.state, ev.mouse.button]));
            end;
          tek_sizeChange:
            begin
              term_cursor_set(0,1);
              term_writeln(Format('Resize: %dx%d                                    ', [ev.size.width, ev.size.height]));
            end;
        else
          ;
        end;
      end;
    until False;

    term_mouse_disable;
    term_raw_mode_disable;
    term_cursor_show;
    if term_support_ansi then term_alternate_screen_disable;
  finally
    term_done;
  end;
end.

