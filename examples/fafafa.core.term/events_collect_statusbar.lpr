{$CODEPAGE UTF8}
program events_collect_statusbar;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;

function KindToString(k: term_event_kind_t): string;
begin
  case k of
    tek_unknown:    Result := 'unknown';
    tek_key:        Result := 'key';
    tek_mouse:      Result := 'mouse';
    tek_sizeChange: Result := 'resize';
    tek_focus:      Result := 'focus';
    tek_paste:      Result := 'paste';
  else
    Result := 'unknown';
  end;
end;

function MilliNow: QWord; inline;
begin
  Result := GetTickCount64;
end;

procedure ClearLine; inline;
begin
  // ANSI CSI 2K: 擦除整行
  term_write(#27'[2K');
end;

var
  buf: array[0..127] of term_event_t;
  n: SizeUInt;
  i: SizeUInt;
  tick0, frames: QWord;
  w, h: term_size_t;
  lastMouseX, lastMouseY: term_size_t;
  lastKind: term_event_kind_t;
  fps: Double;

procedure render_status;
var s: UnicodeString;
begin
  if not term_size(w, h) then Exit;
  s := Format('events:%d  last:%s  mouse:(%d,%d)  fps:%.1f', [n, KindToString(lastKind), lastMouseX, lastMouseY, fps]);
  // 以一行状态栏写在底部
  term_attr_reset;
  term_cursor_set(1, h); // 1-based 行列
  ClearLine;
  term_write(s);
end;

begin
  if not term_init then Halt(1);
  try
    term_raw_mode_enable(True);
    term_focus_enable(True);
    term_paste_bracket_enable(True);
    term_mouse_enable(True);
    term_mouse_sgr_enable(True);

    tick0 := MilliNow;
    frames := 0;
    lastMouseX := 0; lastMouseY := 0; lastKind := tek_unknown;

    term_writeln('Status bar at bottom. ESC to exit.');

    while True do
    begin
      n := term_events_collect(buf, Length(buf), 33); // ~30fps 预算
      for i := 0 to n-1 do
      begin
        lastKind := buf[i].kind;
        case buf[i].kind of
          tek_key:
            if buf[i].key.key = KEY_ESC then Exit;
          tek_mouse:
            begin
              lastMouseX := buf[i].mouse.x;
              lastMouseY := buf[i].mouse.y;
            end;
        end;
      end;

      Inc(frames);
      if (MilliNow - tick0) >= 1000 then
      begin
        fps := frames * 1000.0 / (MilliNow - tick0);
        frames := 0; tick0 := MilliNow;
      end;

      render_status;
    end;

  finally
    term_mouse_sgr_enable(False);
    term_mouse_enable(False);
    term_paste_bracket_enable(False);
    term_focus_enable(False);
    term_raw_mode_enable(False);
    term_done;
  end;
end.

