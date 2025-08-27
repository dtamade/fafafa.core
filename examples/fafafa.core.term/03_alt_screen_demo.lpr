{$CODEPAGE UTF8}
program alt_screen_demo;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
uses
  SysUtils, fafafa.core.term;
var
  ok: boolean;
  i: integer;
begin
  term_init;
  try
    if term_support_alternate_screen then
    begin
      ok := term_alternate_screen_enable(true);
      if ok then
      begin
        term_clear;
        term_writeln('Alternate screen enabled. Showing a simple counter...');
        for i:=1 to 5 do begin
          term_writeln(Format('Tick %d',[i]));
          Sleep(400);
        end;
        term_writeln('Leaving alt screen...');
        term_alternate_screen_disable;
      end
      else
        term_writeln('Failed to enable alt screen.');
    end
    else
      term_writeln('Alternate screen not supported on this terminal.');
  finally
    // 确保退出正常屏幕
    if term_support_alternate_screen then term_alternate_screen_disable;
    term_done;
  end;
end.

