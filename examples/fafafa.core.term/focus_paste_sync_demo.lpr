{$CODEPAGE UTF8}
program focus_paste_sync_demo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;
var
  ev: term_event_t;
begin
  if not term_init then Halt(1);
  try
    if term_support_ansi then
    begin
      term_writeln('Enabling focus, bracketed paste, and synchronized updates (if supported)');
      term_focus_enable(True);
      term_paste_bracket_enable(True);
      term_sync_update_enable(True);
      term_writeln('Press any key to disable and exit...');
      term_event_read(ev);
      term_sync_update_enable(False);
      term_paste_bracket_enable(False);
      term_focus_enable(False);
    end
    else
      term_writeln('ANSI not supported; demo skipped');
  finally
    term_done;
  end;
end.
