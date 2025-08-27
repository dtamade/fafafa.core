program example_winch_portable;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.term,
  {$IFNDEF MSWINDOWS}
  fafafa.core.signal,
  fafafa.core.signal.channel,
  {$ENDIF}
  Classes;

procedure DrawSize;
var W,H: term_size_t;
begin
  if term_size(W,H) then
  begin
    term_clear;
    term_cursor_set(0, 0);
    term_writeln(Format('Size: %dx%d  (q to quit)', [W, H]));
  end
  else
    term_writeln('Failed to get terminal size');
end;

const
  DEBOUNCE_MS = 16; // Frame-level debounce window

var
  Running: Boolean;
  Ev: term_event_t;
{$IFNDEF MSWINDOWS}
  Ch: TSignalChannel;
  Sig: TSignal;
  C: ISignalCenter;
{$ELSE}
  PendingResize: Boolean;
  LastResizeTs: QWord;
  NowTs: QWord;
{$ENDIF}
begin
  if not term_init then
  begin
    WriteLn('term_init failed');
    Halt(1);
  end;

  try
    DrawSize;
    Running := True;

  {$IFNDEF MSWINDOWS}
    // Unix-like: use SignalCenter + Channel(capacity=1) to consume sgWinch
    C := SignalCenter; C.Start;
    C.ConfigureWinchDebounce(DEBOUNCE_MS);
    C.ConfigureQueue(256, qdpDropOldest);
    Ch := TSignalChannel.Create([sgWinch], 1);
    try
      while Running do
      begin
        if Ch.RecvTimeout(Sig, 100) then
        begin
          if Sig = sgWinch then DrawSize;
        end;
        if term_event_poll(Ev, 0) then
        begin
          if Ev.kind = tek_key then
          begin
            case Ev.key.key of
              KEY_Q: Running := False;
            end;
          end;
        end;
      end;
    finally
      Ch.Free;
    end;
  {$ELSE}
    // Windows: use console WINDOW_BUFFER_SIZE_EVENT via term_event_poll + frame-level debounce
    PendingResize := False; LastResizeTs := 0;
    while Running do
    begin
      if term_event_poll(Ev, 100) then
      begin
        case Ev.kind of
          tek_sizeChange:
            begin
              PendingResize := True;
              LastResizeTs := GetTickCount64;
            end;
          tek_key:
            begin
              case Ev.key.key of
                KEY_Q: Running := False;
              end;
            end;
        end;
      end;
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
  {$ENDIF}
  finally
    term_done;
  end;
end.

