program mouse_input_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term,
  fafafa.core.term.helpers;

function MouseStateName(v: Integer): string;
begin
  case v of
    0: Result := 'release';
    1: Result := 'press';
    2: Result := 'move';
  else
    Result := 'unknown(' + IntToStr(v) + ')';
  end;
end;

function MouseButtonName(v: Integer): string;
var btn: term_mouse_button_t;
begin
  if (v >= Ord(Low(term_mouse_button_t))) and (v <= Ord(High(term_mouse_button_t))) then
  begin
    btn := term_mouse_button_t(v);
    Result := TERM_MOUSE_BUTTON_MAP[btn];
  end
  else
    Result := 'unknown(' + IntToStr(v) + ')';
end;

procedure PrintHelp;
begin
  term_writeln('鼠标输入演示：');
  term_writeln('- 显示鼠标按下/释放/移动事件（位置、按钮）');
  term_writeln('- 按 q 退出');
  term_writeln('');
end;

var
  E: term_event_t;
  running: Boolean;
  ok: Boolean;
begin
  if not term_init then
  begin
    WriteLn('term_init 失败');
    Halt(1);
  end;

  if not term_support_mouse then
  begin
    term_writeln('当前终端不支持鼠标（或未检测到），演示退出。');
    term_done;
    Halt(0);
  end;

  // 启用鼠标 + 按钮拖动 + SGR（1006），并尝试 any-motion（1003）
  ok := term_mouse_enable(True);
  term_mouse_drag_enable(True);
  term_mouse_sgr_enable(True);
  term_write(#27'[?1002h'); // 1002: button event tracking
  term_write(#27'[?1003h'); // 1003: any-motion (may not be supported)
  if not ok then
  begin
    term_writeln('无法启用鼠标事件，演示退出。');
    term_done;
    Halt(0);
  end;

  PrintHelp;
  running := True;
  while running do
  begin
    if term_event_poll(E, 500) then
    begin
      case E.kind of
        tek_key:
          begin
            if (E.key.key = KEY_Q) then running := False;
          end;
        tek_mouse:
          begin
            term_writeln(Format('mouse: (%d,%d) %s %s',
              [E.mouse.x, E.mouse.y,
               MouseStateName(E.mouse.state),
               MouseButtonName(E.mouse.button)]));
          end;
        tek_sizeChange:
          begin
            term_writeln('Size: ' + IntToStr(E.size.width) + 'x' + IntToStr(E.size.height));
          end;
      else
        ;
      end;
    end;
  end;

  // 清理所有启用的协议与模式
  term_mouse_sgr_enable(False);
  term_mouse_drag_enable(False);
  term_mouse_disable; // 关闭鼠标
  term_write(#27'[?1003l'); // any-motion off
  term_write(#27'[?1002l'); // button-tracking off
  term_writeln('退出演示');
  term_done;
end.

