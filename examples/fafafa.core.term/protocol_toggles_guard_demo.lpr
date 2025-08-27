{$CODEPAGE UTF8}
program protocol_toggles_guard_demo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;
var
  g: TTermModeGuard;
  ev: term_event_t;
begin
  if not term_init then Halt(1);
  g := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_sgr_1006, tm_mouse_button_drag, tm_focus_1004, tm_paste_2004]);
  try
    term_writeln('Protocols enabled via guard. They will be restored on exit.');
    term_writeln('Press any key to exit...');
    term_event_read(ev); // wait one event
  finally
    term_mode_guard_done(g);
    term_done;
  end;
end.
