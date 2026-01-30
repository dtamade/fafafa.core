{$CODEPAGE UTF8}
program scroll_region_demo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;
var
  top, bottom: term_size_t;
  i: Integer;
begin
  if not term_init then Halt(1);
  try
    term_clear;
    term_writeln('Scroll region demo (top=2, bottom=10).');

    if term_support_alternate_screen then
      term_alternate_screen_enable(True);

    if term_scroll_region_set(2, 10) then
    begin
      term_cursor_set(0, 0);
      term_writeln('Header line 1');
      term_writeln('Header line 2 (fixed)');

      term_cursor_set(0, 2);
      for i := 1 to 20 do
      begin
        term_writeln(Format('Line %d (scroll inside region)', [i]));
        Sleep(50);
      end;

      term_scroll_region_reset;
    end
    else
      term_writeln('Scroll region not supported');

    if term_support_alternate_screen then
      term_alternate_screen_enable(False);
  finally
    term_done;
  end;
end.

