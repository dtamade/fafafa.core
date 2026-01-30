{$CODEPAGE UTF8}
program cursor_shape_blink_demo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;

begin
  if not term_init then Halt(1);
  try
    term_writeln('Cursor shape/blink demo');
    term_cursor_hide;

    term_cursor_shape_set(tcs_bar);
    term_cursor_blink_set(True);
    term_writeln('bar + blink');
    Sleep(500);

    term_cursor_shape_set(tcs_block);
    term_cursor_blink_set(False);
    term_writeln('block + no blink');
    Sleep(500);

    term_cursor_shape_reset;
    term_cursor_show;
  finally
    term_done;
  end;
end.

