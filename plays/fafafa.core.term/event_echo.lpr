{$CODEPAGE UTF8}
program event_echo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;

function KindToString(k: term_event_kind_t): string; inline;
begin
  Result := TERM_EVENT_KIND_NAME[k];
end;

function IsEscKey(const E: term_event_t): Boolean; inline;
begin
  Result := (E.kind = tek_key) and (E.key.key = KEY_ESC);
end;

procedure PrintEvent(const E: term_event_t);
var
  s: UnicodeString;
begin
  case E.kind of
    tek_key:
      begin
        s := Format('[key] code=%d mods=%d char="%s"',
          [Ord(E.key.key), Integer(E.key.mods), UnicodeString(E.key.char.wchar)]);
        term_writeln(s);
      end;
    tek_mouse:
      begin
        s := Format('[mouse] x=%d y=%d btn=%d state=%d',
          [E.mouse.x, E.mouse.y, Integer(E.mouse.button), Integer(E.mouse.state)]);
        term_writeln(s);
      end;
    tek_sizeChange:
      begin
        s := Format('[resize] %dx%d', [E.size.width, E.size.height]);
        term_writeln(s);
      end;
    tek_focus:
      begin
        if E.focus.focus then term_writeln('[focus] in') else term_writeln('[focus] out');
      end;
    tek_paste:
      begin
        s := Format('[paste] id=%d (use paste_store API to fetch text)', [E.paste.id]);
        term_writeln(s);
      end;
  else
    term_writeln('[unknown]');
  end;
end;

var
  ev: term_event_t;
  ok: Boolean;
begin
  term_init;
  try
    // 启用建议的协议（不支持时内部降级为 no-op）
    term_alternate_screen_enable(True);
    term_focus_enable(True);
    term_paste_bracket_enable(True);
    term_mouse_enable(True);
    term_mouse_drag_enable(True);
    term_mouse_sgr_enable(True);

    term_writeln('Event Echo (ESC to quit)');
    term_writeln('Enabled: AltScreen, Focus(1004), Paste(2004), Mouse(1000/1002/1006)');

    while True do
    begin
      FillByte(ev, SizeOf(ev), 0);
      ok := term_event_poll(ev, 50); // 50ms 轮询
      if ok then
      begin
        if IsEscKey(ev) then Break;
        PrintEvent(ev);
      end;
      // 无事件帧为常态：保持 O(1) 空转，不做睡眠（由内部实现决定）
    end;

  finally
    // 退出期按相反顺序关闭协议，并确保 term_done 执行
    term_mouse_sgr_enable(False);
    term_mouse_drag_enable(False);
    term_mouse_enable(False);
    term_paste_bracket_enable(False);
    term_focus_enable(False);
    term_alternate_screen_enable(False);
    term_done;
  end;
end.

