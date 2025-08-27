{$CODEPAGE UTF8}
program size_clear;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
uses
  SysUtils, fafafa.core.term;
var
  w,h: term_size_t;
begin
  term_init;
  try
    if term_size(w,h) then
      term_writeln(Format('Size = %dx%d',[w,h]))
    else
      term_writeln('Size: unknown');
    term_writeln('Clearing screen in 1s...');
    Sleep(1000);
    term_clear;
    term_writeln('Done.');
  finally
    term_done;
  end;
end.

