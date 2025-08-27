{$CODEPAGE UTF8}
program event_poll_echo;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
uses
  SysUtils, fafafa.core.term;
var
  ev: term_event_t;
  count: integer;
begin
  term_init;
  try
    term_writeln('Press keys (Esc to quit). Polling for 5 seconds of inactivity will exit.');
    count := 0;
    while True do
    begin
      if term_event_poll(ev, 1000) then
      begin
        Inc(count);
        if (ev.kind = tek_key) and (ev.key.key = KEY_ESC) then Break;
        term_writeln(Format('Event %d kind=%d',[count, Ord(ev.kind)]));
      end
      else
      begin
        // timeout
        if count=0 then begin term_writeln('No events.'); end;
        Break;
      end;
    end;
  finally
    term_done;
  end;
end.

