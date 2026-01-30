program example_win_winch_poll;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.term;

procedure DrawSize;
var W,H: term_size_t;
begin
  if term_size(W,H) then
  begin
    term_clear;
    term_cursor_set(0, 0);
    term_writeln(Format('Console size: %dx%d  (press q to quit)', [W, H]));
  end
  else
    term_writeln('Failed to get console size');
end;

const
  DEBOUNCE_MS = 16; // 16–33ms are typical frame windows

var
  Running: Boolean;
  Ev: term_event_t;
  PendingResize: Boolean;
  LastResizeTs: QWord;
  NowTs: QWord;
begin
  if not term_init then
  begin
    WriteLn('term_init failed');
    Halt(1);
  end;

  try
    PendingResize := False;
    LastResizeTs := 0;
    DrawSize;
    Running := True;

    while Running do
    begin
      // Poll input/events with a modest timeout
      if term_event_poll(Ev, 100) then
      begin
        case Ev.kind of
          tek_sizeChange:
            begin
              // Mark resize and record timestamp; actual redraw in frame debounce below
              PendingResize := True;
              LastResizeTs := GetTickCount64;
            end;
          tek_key:
            begin
              case Ev.key.key of
                KEY_Q: Running := False;
              end;
            end;
        else
          ;
        end;
      end;

      // Frame-level debounce: coalesce frequent resizes
      if PendingResize then
      begin
        NowTs := GetTickCount64;
        if NowTs - LastResizeTs >= DEBOUNCE_MS then
        begin
          PendingResize := False;
          DrawSize;
        end;
      end;
    end;
  finally
    term_done;
  end;
end.

