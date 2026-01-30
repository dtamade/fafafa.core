program input_monitor;
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

function HasFlag(const Name: string): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 1 to ParamCount do
    if (ParamStr(i) = Name) then Exit(True);
end;

function GetArgValue(const Name: string; Default: Integer): Integer;
var i, p: Integer; s: string;
begin
  Result := Default;
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if Pos(Name + '=', s) = 1 then
    begin
      Val(Copy(s, Length(Name)+2, MaxInt), Result, p);
      if p <> 0 then Result := Default;
      Exit;
    end;
  end;
end;

procedure PrintHelp;
begin
  Writeln('Usage: input_monitor [--duration=ms] [--esc-timeout=ms]');
  Writeln('       [--no-mouse] [--no-sgr] [--no-focus] [--no-paste]');
  Writeln;
  Writeln('Defaults: duration=10000, SGR/mouse/focus/paste enabled when supported.');
end;

procedure MonitorInput(DurationMs: QWord; Flags: term_mode_flags_t);
var
  Ev: term_event_t;
  t0: QWord;
  sMods: string;
  Guard: TTermModeGuard;
begin
  // 启用一组常用模式：根据 Flags 决定
  Guard := term_mode_guard_acquire_current(Flags);
  // 额外尝试开启 any-motion (?1003)，便于观察移动事件（部分终端可能不支持）
  term_write(#27'[?1003h');
  try
    Writeln('--- Input Monitor ---');
    Writeln('• Mouse: wheel/drag + modifiers');
    Writeln('• Focus: gained/lost');
    Writeln('• Resize: terminal size change');
    if tm_paste_2004 in Flags then
      Writeln('• Paste: bracketed paste is enabled (2004).');

    t0 := GetTickCount64;
    while GetTickCount64 - t0 < DurationMs do
    begin
      if term_event_poll(Ev, 50) then
      begin
        case Ev.kind of
          tek_mouse:
            begin
              sMods := '';
              if Ev.mouse.shift <> 0 then sMods += 'Shift+';
              if Ev.mouse.ctrl  <> 0 then sMods += 'Ctrl+';
              if Ev.mouse.alt   <> 0 then sMods += 'Alt+';
              if (Ev.mouse.button >= Ord(tmb_wheel_up)) and (Ev.mouse.button <= Ord(tmb_wheel_right)) then
                Writeln('MouseWheel: ', sMods, 'btn=', Ev.mouse.button, ' state=', Ev.mouse.state,
                        ' x=', Ev.mouse.x, ' y=', Ev.mouse.y)
              else
                Writeln('Mouse: ', sMods, 'btn=', Ev.mouse.button, ' state=', Ev.mouse.state,
                        ' x=', Ev.mouse.x, ' y=', Ev.mouse.y);
            end;
          tek_focus:
            begin
              if Ev.focus.focus then Writeln('Focus: gained') else Writeln('Focus: lost');
            end;
          tek_sizeChange:
            begin
              Writeln('Resize: ', Ev.size.width, 'x', Ev.size.height);
            end;
        end;
      end
      else
      begin
        // 空闲期小睡，避免 100% CPU 忙等
        Sleep(5);
      end;
    end;
  finally
    // 对称关闭 any-motion
    term_write(#27'[?1003l');
    term_mode_guard_done(Guard);
  end;
end;

var
  Duration: Integer;
  Flags: term_mode_flags_t;
begin
  if HasFlag('--help') or HasFlag('-h') then
  begin
    PrintHelp;
    Halt(0);
  end;

  // 可选：通过命令行传入 ESC 解析超时（Unix）--esc-timeout=XX
  {$IFDEF UNIX}
  term_unix_set_escape_timeout_ms(GetArgValue('--esc-timeout', term_unix_get_escape_timeout_ms));
  {$ENDIF}

  // 解析 duration 与开关
  Duration := GetArgValue('--duration', 10000);
  Flags := [tm_mouse_enable_base, tm_mouse_button_drag, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004];
  if HasFlag('--no-mouse') then begin Exclude(Flags, tm_mouse_enable_base); Exclude(Flags, tm_mouse_button_drag); end;
  if HasFlag('--no-sgr') then Exclude(Flags, tm_mouse_sgr_1006);
  if HasFlag('--no-focus') then Exclude(Flags, tm_focus_1004);
  if HasFlag('--no-paste') then Exclude(Flags, tm_paste_2004);

  if not term_init then
  begin
    Writeln('Failed to init terminal');
    Halt(1);
  end;
  try
    MonitorInput(Duration, Flags);
  finally
    term_done;
  end;
end.

