program keyboard_input_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term,
  fafafa.core.term.iterminal;

procedure PrintHelp(const T: ITerminal);
begin
  T.WriteLn('键盘输入演示：');
  T.WriteLn('- 按任意键显示按键名称（方向键、功能键等）');
  T.WriteLn('- 按 q 退出');
  T.WriteLn('');
end;

function KeyName(aKey: term_key_t): string;
begin
  if (aKey <= High(TERM_KEY_NAME_MAP)) then
    Result := TERM_KEY_NAME_MAP[aKey]
  else
    Result := 'unknown(' + IntToStr(aKey) + ')';
end;

var
  E: term_event_t;
  running: Boolean;
  Term: ITerminal;
begin
  Term := CreateTerminal; // 内部调用 term_init；析构时 term_done

  PrintHelp(Term);
  running := True;
  while running do
  begin
    if Term.Poll(E, 500) then
    begin
      case E.kind of
        tek_key:
          begin
            Term.WriteLn('Key: ' + KeyName(E.key.key));
            if (E.key.key = KEY_Q) then
              running := False;
          end;
        tek_sizeChange:
          begin
            Term.WriteLn('Size: ' + IntToStr(E.size.width) + 'x' + IntToStr(E.size.height));
          end;
      end;
    end;
  end;

  Term.WriteLn('退出演示');
  // ITerminal 引用释放时自动调用 term_done（在薄门面内部）
end.
