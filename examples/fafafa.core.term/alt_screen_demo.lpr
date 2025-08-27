program alt_screen_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

procedure CenterWrite(const S: UnicodeString);
var W,H,X: term_size_t;
begin
  if term_size(W,H) then
  begin
    if Length(S)>0 then
      X := (W - Length(S)) div 2
    else
      X := 0;
    term_cursor_set(X, H div 2);
    term_writeln(S);
  end
  else
    term_writeln(S);
end;

begin
  if not term_init then
  begin
    WriteLn('term_init 失败');
    Halt(1);
  end;

  term_clear;
  term_writeln('进入备用屏幕演示（模拟），按回车进入，回车退出...');
  ReadLn;

  if term_support_alternate_screen then
  begin
    if term_alternate_screen_enable then
    begin
      term_clear;
      CenterWrite('这是备用屏幕');
      term_writeln('按回车返回主屏幕...');
      ReadLn;
      term_alternate_screen_disable;
    end
    else
    begin
      term_clear; CenterWrite('备用屏启用失败，按回车返回'); ReadLn;
    end;
  end
  else
  begin
    term_clear; CenterWrite('终端不支持备用屏，按回车返回'); ReadLn;
  end;

  term_clear;
  term_writeln('已返回主屏幕，按回车退出。');
  ReadLn;
  term_done;
end.

