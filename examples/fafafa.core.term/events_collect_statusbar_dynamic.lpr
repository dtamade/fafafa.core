{$CODEPAGE UTF8}
program events_collect_statusbar_dynamic;

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

function IsEscKey(const E: term_event_t): Boolean; inline;
begin
  Result := (E.kind = tek_key) and (E.key.key = KEY_ESC);
end;

function IsCharKey(const E: term_event_t; const C: WideChar): Boolean; inline;
begin
  // 兼容宽/窄字符
  Result := (E.kind = tek_key)
    and (E.key.key = KEY_UNKOWN)
    and ((E.key.char.wchar = C) or (E.key.char.char = AnsiChar(C)));
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
  budgetMs: UInt32 = 8; // 默认 8ms

function BuildStatusString: UnicodeString;
begin
  Result := Format('budget:%dms  events:%d  last:%s  mouse:(%d,%d)  fps:%.1f  (b:toggle  h:help  ESC:exit)',
    [budgetMs, n, KindToString(lastKind), lastMouseX, lastMouseY, fps]);
end;

procedure RenderStatusBar;
begin
  if not term_size(w, h) then Exit;
  term_attr_reset;
  term_cursor_set(1, h); // 1-based 行列
  ClearLine;
  term_write(BuildStatusString);
end;

procedure RenderStatusPlain;
begin
  WriteLn(BuildStatusString);
end;

procedure PrintHelp;
begin
  term_writeln('events_collect_statusbar_dynamic');
  term_writeln('---------------------------------------------');
  term_writeln('ESC: 退出');
  term_writeln('b:   切换 budget (0ms <-> 8ms)');
  term_writeln('h:   显示本帮助');
  term_writeln('状态栏显示: 收集数量、最后事件、鼠标位置、FPS、当前预算');
  term_writeln('');
end;

procedure PrintCliHelp;
begin
  WriteLn('Usage: events_collect_statusbar_dynamic [--budget=N] [--format=status] [--help]');
  WriteLn('  --budget=N      设置收集合并预算毫秒数(0 表示仅消费队列)。默认 8');
  WriteLn('  --format=status 以纯文本单行打印状态（每秒一行），便于自动采集');
  WriteLn('  --help          显示本帮助并退出');
end;

var
  gPlainFormat: Boolean = False;

procedure ParseCli;
var i: Integer; s: String; v: Integer; lc: String;
begin
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    lc := LowerCase(s);
    if (lc = '--help') or (lc = '-h') then
    begin
      PrintCliHelp;
      Halt(0);
    end
    else if Pos('--budget=', lc) = 1 then
    begin
      v := StrToIntDef(Copy(s, Length('--budget=') + 1, MaxInt), Integer(budgetMs));
      if v < 0 then v := 0; if v > 1000 then v := 1000;
      budgetMs := UInt32(v);
      WriteLn(Format('Using budget: %d ms', [budgetMs]));
    end
    else if (lc = '--format=status') then
    begin
      gPlainFormat := True;
    end;
  end;
end;

begin
  ParseCli;
  if gPlainFormat then
  begin
    // 纯文本模式：避免移动光标、避免控制台复位，仅每秒输出状态行
    if not term_init then Halt(1);
    try
      term_raw_mode_enable(False);
      term_focus_enable(False);
      term_paste_bracket_enable(False);
      term_mouse_enable(False);
      term_mouse_sgr_enable(False);

      tick0 := MilliNow;
      frames := 0;
      lastMouseX := 0; lastMouseY := 0; lastKind := tek_unknown;

      while True do
      begin
        n := term_events_collect(buf, Length(buf), budgetMs);
        for i := 0 to n-1 do
        begin
          lastKind := buf[i].kind;
          if buf[i].kind = tek_mouse then
          begin
            lastMouseX := buf[i].mouse.x;
            lastMouseY := buf[i].mouse.y;
          end;
        end;

        Inc(frames);
        if (MilliNow - tick0) >= 1000 then
        begin
          fps := frames * 1000.0 / (MilliNow - tick0);
          frames := 0; tick0 := MilliNow;
          RenderStatusPlain;
        end;
      end;
    finally
      term_done;
    end;
  end
  else
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

      term_writeln('Dynamic status bar at bottom. ESC to exit. Press h for help.');

      while True do
      begin
        n := term_events_collect(buf, Length(buf), budgetMs);
        for i := 0 to n-1 do
        begin
          lastKind := buf[i].kind;
          case buf[i].kind of
            tek_key:
              begin
                if buf[i].key.key = KEY_ESC then Exit;
                if IsCharKey(buf[i], 'b') then
                begin
                  if budgetMs = 0 then budgetMs := 8 else budgetMs := 0;
                end
                else if IsCharKey(buf[i], 'h') then
                  PrintHelp;
              end;
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

        RenderStatusBar;
      end;

    finally
      term_mouse_sgr_enable(False);
      term_mouse_enable(False);
      term_paste_bracket_enable(False);
      term_focus_enable(False);
      term_raw_mode_enable(False);
      term_done;
    end;
  end;
end.

