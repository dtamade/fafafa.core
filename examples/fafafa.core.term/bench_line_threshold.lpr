program bench_line_threshold;
{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.term,
  ui_backend, ui_backend_terminal, ui_backend_memory, ui_surface;

// A tiny benchmark to compare per-frame cost when a line has high diff ratio.
// It renders two frames repeatedly: Frame A (baseline), Frame B (modify N columns per line)
// You can toggle the threshold via env: FAFAFA_TERM_DIFF_LINE_THRESHOLD (0..1)
// And backend between terminal (default) and memory via env FAFAFA_TERM_BENCH_USE_MEMORY

const
  W = 200;  // width
  H = 50;   // height
  Iter = 50; // iterations

procedure RenderFrameA;
var y: Integer;
begin
  UiFrameBegin;
  for y := 0 to H-1 do begin
    UiWriteAt(y, 0, StringOfChar(UnicodeChar('A'), W));
  end;
  UiFrameEnd;
end;

procedure RenderFrameB(ChangedPerLine: Integer);
var y, i: Integer; s: UnicodeString;
begin
  UiFrameBegin;
  SetLength(s, ChangedPerLine);
  for i := 1 to ChangedPerLine do s[i] := UnicodeChar('B');
  for y := 0 to H-1 do begin
    UiWriteAt(y, 0, s);
  end;
  UiFrameEnd;
end;

var
  t0, t1: TDateTime;
  i: Integer;
  changed: Integer;
  backend: IUiBackend;
  useMem: Boolean;
begin
  // Ensure terminal is initialized for terminal backend
  term_init;
  try
    useMem := GetEnvironmentVariable('FAFAFA_TERM_BENCH_USE_MEMORY') <> '';
    if useMem then
      backend := ui_backend_memory.CreateMemoryBackend(W,H)
    else
      backend := ui_backend_terminal.CreateTerminalBackend;
    UiBackendSetCurrent(backend);

    // Warm-up
    RenderFrameA;

    // Scenario 1: low diff (10% of line)
    changed := (W * 10) div 100;
    t0 := Now;
    for i := 1 to Iter do begin
      RenderFrameB(changed);
    end;
    t1 := Now;
    WriteLn('low-diff 10%: ', MilliSecondsBetween(t1, t0), ' ms total for ', Iter, ' frames');

    // Scenario 2: high diff (50% of line)
    changed := (W * 50) div 100;
    t0 := Now;
    for i := 1 to Iter do begin
      RenderFrameB(changed);
    end;
    t1 := Now;
    WriteLn('high-diff 50%: ', MilliSecondsBetween(t1, t0), ' ms total for ', Iter, ' frames');
  finally
    term_done;
  end;

  // Note: Adjust FAFAFA_TERM_DIFF_LINE_THRESHOLD to 0.35/0.9 to observe changes.
end.

