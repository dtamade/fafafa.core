program input_best_practices;
{$APPTYPE CONSOLE}
{$mode objfpc}{$H+}




uses
  SysUtils,
  fafafa.core.term;

// 可选：在 Unix 下调整 ESC/CSI 解析超时，单位毫秒（默认 10ms）
// term_unix_set_escape_timeout_ms(20);
// 或使用命令行参数 --esc-timeout=XX（仅 Unix 生效）：
// 例如：./05_input_best_practices --esc-timeout=20


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


procedure DemoPeekAndFlush;
var
  Term: ITerminal;
  Inp: ITerminalInput;
  K: TKeyEvent;
  S: string;
begin
  Writeln('--- PeekKey & FlushInput Demo ---');
  Term := CreateTerminal;
  Inp := Term.Input;

  // 开启基本鼠标按钮事件与 SGR 模式（如果终端支持 ANSI）
  term_mouse_enable(True);
  term_mouse_drag_enable(True);
  term_mouse_sgr_enable(True);
  // 启用焦点与括号粘贴（Bracketed Paste）
  term_focus_enable(True);
  term_paste_bracket_enable(True);

  Writeln('Press some keys (Shift/Ctrl modifiers) or move mouse; we will peek without consuming...');
  Sleep(500);
  if Inp.PeekKey(K) then
  begin
    S := KeyEventToString(K);
    Writeln('Peeked: ', S);
  end
  else
    Writeln('No input to peek');

  Writeln('Flushing input buffer...');
  Inp.FlushInput;
  if not Inp.PeekKey(K) then
    Writeln('Buffer now empty.');

  // 在示例结束前关闭开关并恢复
  try
  finally
    term_paste_bracket_enable(False);
    term_focus_enable(False);
    term_mouse_sgr_enable(False);
    term_mouse_drag_enable(False);
    term_mouse_enable(False);
    term_write(#27'[?1003l'); // any-motion off
    term_write(#27'[?1002l'); // button-tracking off
  end;
end;

procedure DemoMouseWheelWithModifiers;
var
  Term: ITerminal;
  Ev: term_event_t;
  t0: QWord;
  sMods: string;
begin
  Writeln('--- Mouse Wheel + Modifiers & Focus Demo ---');
  Writeln('Try wheel up/down/left/right with Shift/Ctrl/Alt (Unix SGR terminals).');
  Writeln('Also switch terminal focus to see focus events (tek_focus).');
  Term := CreateTerminal;
  t0 := GetTickCount64;
  while GetTickCount64 - t0 < 3000 do
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
              Writeln('Wheel event: ', sMods, 'btn=', Ev.mouse.button, ' state=', Ev.mouse.state,
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
    end;
  end;
end;

begin
  // 可选：通过命令行传入 ESC 解析超时（Unix）--esc-timeout=XX
  // 仅在 Unix 生效；Windows 下调用不会产生影响
  {$IFDEF UNIX}
  term_unix_set_escape_timeout_ms(GetArgValue('--esc-timeout', term_unix_get_escape_timeout_ms));
  {$ENDIF}

  term_init;
  try
    DemoPeekAndFlush;
    DemoMouseWheelWithModifiers;
  finally
    term_done;
  end;
end.

