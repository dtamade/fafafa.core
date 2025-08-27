program bench_line_threshold_plus;
{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils, StrUtils,
  fafafa.core.term,
  ui_backend, ui_backend_terminal, ui_backend_memory, ui_surface;

// Extended benchmark: compare metrics under different line-diff thresholds.
// Metrics include total write calls, total UTF-8 bytes, and ESC (ANSI) sequence count.
// Config via env:
//   FAFAFA_TERM_BENCH_USE_MEMORY=1  -> use memory backend
//   FAFAFA_TERM_DIFF_LINE_THRESHOLD -> 0..1 (overrides per run below)

const
  DefaultW = 160;
  DefaultH = 40;
  DefaultIter = 60;
  kFlushThreshold = 64 * 1024; // approximate OS write flush chunk

var
  W: Integer = DefaultW;
  H: Integer = DefaultH;
  Iter: Integer = DefaultIter;

type
  TChangeMode = (cmContiguous, cmBlocky);
  TMetrics = record
    Writes: QWord;
    Bytes: QWord;
    Escs: QWord;
    Flushes: QWord;   // simulated flushes using 64KB threshold per frame
    Frames: QWord;    // frames rendered
  end;

  TStringArray = array of string;

var
  GMetrics: TMetrics;
  flushCount: QWord;

  // CLI-configurable knobs
  GBlockSize: Integer = 16;
  GStride: Integer = 0; // 0 -> 2*BlockSize
  GModes: TStringArray; // empty -> both
  GThresholds: TStringArray; // default list if empty
  GPercentages: TStringArray; // default [10,30,50]
  GOutCSV: string = '';
  GOutJSON: string = '';
  GOutCSVHeader: Boolean = False;

function SplitCSV(const S: string): TStringArray;
var tmp: string; p, n: Integer;
begin
  tmp := S; SetLength(Result, 0);
  while tmp <> '' do
  begin
    p := Pos(',', tmp); n := Length(Result); SetLength(Result, n+1);
    if p=0 then begin Result[n] := Trim(tmp); Break; end;
    Result[n] := Trim(Copy(tmp, 1, p-1));
    Delete(tmp, 1, p);
  end;
end;

procedure WriteHook(const S: UnicodeString);
var
  i: SizeInt;
  bytes: RawByteString;
begin
  Inc(GMetrics.Writes);
  bytes := UTF8Encode(S);
  Inc(GMetrics.Bytes, Length(bytes));
  for i := 1 to Length(S) do if Ord(S[i]) = 27 then Inc(GMetrics.Escs);
  // simulate flushes based on 64KB threshold per frame
  if (GMetrics.Bytes > 0) and (GMetrics.Bytes mod kFlushThreshold < Length(bytes)) then Inc(GMetrics.Flushes);
  // forward to backend
  UiBackendGetCurrent.Write(S);
end;

procedure WritelnHook(const S: UnicodeString);
begin
  WriteHook(S + LineEnding);
end;

procedure InstallHooks;
begin
  UiDebug_SetOutputHooks(@WriteHook, @WritelnHook, nil, nil, nil, nil);
end;

procedure UninstallHooks;
begin
  UiDebug_ResetOutputHooks;
end;

procedure ResetMetrics;
begin
  FillChar(GMetrics, SizeOf(GMetrics), 0);
end;

procedure RenderBaseline;
var y: Integer;
begin
  UiFrameBegin;
  for y := 0 to H-1 do UiWriteAt(y, 0, StringOfChar(UnicodeChar('A'), W));
  UiFrameEnd;
end;

procedure RenderChange(ChangedPerLine: Integer; Mode: TChangeMode; BlockSize, Stride: Integer);
var
  y, i, used, pos0, blen: Integer;
  s, blk: UnicodeString;
begin
  UiFrameBegin;
  case Mode of
    cmContiguous:
      begin
        SetLength(s, ChangedPerLine);
        for i := 1 to ChangedPerLine do s[i] := UnicodeChar('B');
        for y := 0 to H-1 do UiWriteAt(y, 0, s);
      end;
    cmBlocky:
      begin
        if BlockSize <= 0 then BlockSize := 16;
        if Stride <= 0 then Stride := BlockSize * 2;
        SetLength(blk, BlockSize);
        for i := 1 to BlockSize do blk[i] := UnicodeChar('B');
        for y := 0 to H-1 do
        begin
          used := 0; pos0 := 0;
          while (used < ChangedPerLine) and (pos0 < W) do
          begin
            blen := BlockSize;
            if used + blen > ChangedPerLine then blen := ChangedPerLine - used;
            if blen <= 0 then Break;
            // write a block at pos0
            if blen = BlockSize then
              UiWriteAt(y, pos0, blk)
            else
            begin
              SetLength(s, blen);
              for i := 1 to blen do s[i] := UnicodeChar('B');
              UiWriteAt(y, pos0, s);
            end;
            Inc(used, blen);
            Inc(pos0, Stride); // configurable stride creating sparsity
          end;
        end;
      end;
  end;
  UiFrameEnd;
end;


function ModeToString(M: TChangeMode): string;
begin
  case M of
    cmContiguous: Result := 'contiguous';
    cmBlocky:     Result := 'blocky';
  else
    Result := 'unknown';
  end;
end;

procedure EnsureCSVHeader;
var f: Text;
begin
  if (GOutCSV='') or (not GOutCSVHeader) then Exit;
  if FileExists(GOutCSV) and (FileSize(GOutCSV)>0) then Exit; // already has content
  Assign(f, GOutCSV);
  if FileExists(GOutCSV) then Append(f) else Rewrite(f);
  try
    WriteLn(f, 'title,w,h,iter,mode,blockSize,stride,threshold,ms,writes,bytes,escs,flush');
  finally
    Close(f);
  end;
end;


procedure PrintScenarioRow(const Title: string; ms: Int64);
var effFlush: QWord; f: Text; jsonLine: string;
begin
  // prefer real flush count when available
  if flushCount > 0 then effFlush := flushCount else effFlush := GMetrics.Flushes;
  WriteLn(Format('  %-18s %6d ms   writes=%-6d bytes=%-8d escs=%-6d flush=%-6d',
                 [Title, ms, GMetrics.Writes, GMetrics.Bytes, GMetrics.Escs, effFlush]));
  // CSV append removed: single wide CSV written in RunScenario
  // (JSON NDJSON kept below)
  // JSON lines append (NDJSON)
  if GOutJSON <> '' then
  begin
    Assign(f, GOutJSON);
    if FileExists(GOutJSON) then Append(f) else Rewrite(f);
    try
      jsonLine := Format('{"title":"%s","ms":%d,"writes":%d,"bytes":%d,"escs":%d,"flush":%d}',
                         [Title, ms, GMetrics.Writes, GMetrics.Bytes, GMetrics.Escs, effFlush]);
      WriteLn(f, jsonLine);
    finally
      Close(f);
    end;
  end;
  flushCount := 0; // reset per row group (also used for CSV wide row)
end;

procedure RunScenario(const Title: string; ChangedPercent: Integer; Mode: TChangeMode; BlockSize: Integer);
var i: Integer; t0, t1: TDateTime; changed, stride: Integer; modeStr: string; f: Text; effFlush: QWord; jsonLine: string;
begin
  if GStride > 0 then stride := GStride else stride := 2*BlockSize;
  changed := (W * ChangedPercent) div 100;
  ResetMetrics;
  t0 := Now;
  for i := 1 to Iter do
  begin
    Inc(GMetrics.Frames);
    RenderChange(changed, Mode, BlockSize, stride);
  end;
  t1 := Now;
  PrintScenarioRow(Title, MilliSecondsBetween(t1, t0));

  // Write a single wide CSV row with both context and metrics; JSON still writes separate lines
  modeStr := ModeToString(Mode);
  if (GOutCSV <> '') then
  begin
    if flushCount > 0 then effFlush := flushCount else effFlush := GMetrics.Flushes;
    Assign(f, GOutCSV);
    if FileExists(GOutCSV) then Append(f) else Rewrite(f);
    try
      // Columns: title,w,h,iter,mode,blockSize,stride,threshold,ms,writes,bytes,escs,flush
      WriteLn(f, Format('%s,%d,%d,%d,%s,%d,%d,%s,%d,%d,%d,%d,%d',
        [Title, W, H, Iter, modeStr, BlockSize, stride, FloatToStr(UiGetLineDiffThreshold),
         MilliSecondsBetween(t1, t0), GMetrics.Writes, GMetrics.Bytes, GMetrics.Escs, effFlush]));
    finally
      Close(f);
    end;

  end; // CSV wide row done

  if GOutJSON <> '' then
  begin
    if flushCount > 0 then effFlush := flushCount else effFlush := GMetrics.Flushes;
    Assign(f, GOutJSON);
    if FileExists(GOutJSON) then Append(f) else Rewrite(f);
    try
      jsonLine := Format('{"title":"%s","w":%d,"h":%d,"iter":%d,"mode":"%s","blockSize":%d,"stride":%d,"threshold":%s,"ms":%d,"writes":%d,"bytes":%d,"escs":%d,"flush":%d}',
        [Title, W, H, Iter, modeStr, BlockSize, stride, FloatToStr(UiGetLineDiffThreshold),
         MilliSecondsBetween(t1, t0), GMetrics.Writes, GMetrics.Bytes, GMetrics.Escs, effFlush]);
      WriteLn(f, jsonLine);
    finally
      Close(f);
    end;
  end;
end;

procedure RunWithThreshold(const Name: string; const ThresholdStr: string);
var thr: Double; modeName: string; i, j, p: Integer; title: string;
begin
  Val(ThresholdStr, thr);
  if thr >= 0 then UiSetLineDiffThreshold(thr) else UiSetLineDiffThreshold(-1);
  WriteLn('--- Threshold ', Name, ' (', ThresholdStr, ') ---');
  RenderBaseline;

  // decide modes list
  if Length(GModes)=0 then
  begin
    SetLength(GModes, 2); GModes[0] := 'contiguous'; GModes[1] := 'blocky';
  end;

  for i := 0 to High(GModes) do
  begin
    modeName := LowerCase(Trim(GModes[i]));
    if modeName='contiguous' then
    begin
      WriteLn('  Mode: contiguous');
      // decide percentages list
      if Length(GPercentages)=0 then
      begin
        RunScenario('low-diff 10%', 10, cmContiguous, 0);
        RunScenario('mid-diff 30%', 30, cmContiguous, 0);
        RunScenario('high-diff 50%', 50, cmContiguous, 0);
      end
      else
      begin
        // custom percentages
        for j := 0 to High(GPercentages) do
        begin
          Val(GPercentages[j], p);
          title := Format('custom %d%%',[p]);
          RunScenario(title, p, cmContiguous, 0);
        end;
      end;
    end
    else if modeName='blocky' then
    begin
      WriteLn(Format('  Mode: blocky-%d',[GBlockSize]));
      if Length(GPercentages)=0 then
      begin
        RunScenario('low-diff 10%', 10, cmBlocky, GBlockSize);
        RunScenario('mid-diff 30%', 30, cmBlocky, GBlockSize);
        RunScenario('high-diff 50%', 50, cmBlocky, GBlockSize);
      end
      else
      begin
        for j := 0 to High(GPercentages) do
        begin
          Val(GPercentages[j], p);
          title := Format('custom %d%%',[p]);
          RunScenario(title, p, cmBlocky, GBlockSize);
        end;
      end;
    end;
  end;
end;

var
  backend: IUiBackend;
  useMem: Boolean;
  arg: string;
  i: Integer;
  useBlocky: Boolean;

  procedure OnFlush;
  begin
    Inc(flushCount);
  end;
begin
  // parse CLI args
  for i := 1 to ParamCount do
  begin
    arg := ParamStr(i);
    if StartsText('--w=', arg) then Val(Copy(arg, 5, MaxInt), W)
    else if StartsText('--h=', arg) then Val(Copy(arg, 5, MaxInt), H)
    else if StartsText('--iter=', arg) then Val(Copy(arg, 8, MaxInt), Iter)
    else if StartsText('--mode=', arg) then
    begin
      // support single value or csv
      v := Copy(arg, 8, MaxInt);
      if Pos(',', v)>0 then GModes := SplitCSV(v) else begin SetLength(GModes,1); GModes[0]:=v; end;
      useBlocky := SameText(v, 'blocky');
    end
    else if StartsText('--block-size=', arg) then Val(Copy(arg, 14, MaxInt), GBlockSize)
    else if StartsText('--stride=', arg) then Val(Copy(arg, 10, MaxInt), GStride)
    else if StartsText('--thresholds=', arg) then GThresholds := SplitCSV(Copy(arg, 13, MaxInt))
    else if StartsText('--percentages=', arg) then GPercentages := SplitCSV(Copy(arg, 14, MaxInt))
    else if StartsText('--csv=', arg) then GOutCSV := Copy(arg, 7, MaxInt)
    else if StartsText('--csv-header', arg) then GOutCSVHeader := True
    else if StartsText('--json=', arg) then GOutJSON := Copy(arg, 8, MaxInt);
  end;

  if GOutCSV<>'' then EnsureCSVHeader;
  term_init;
  try
    useMem := GetEnvironmentVariable('FAFAFA_TERM_BENCH_USE_MEMORY') <> '';
    if useMem then backend := ui_backend_memory.CreateMemoryBackend(W,H)
    else backend := ui_backend_terminal.CreateTerminalBackend;
    UiBackendSetCurrent(backend);

    InstallHooks;
    UiDebug_EnableFrameBufferingForBenchmark(True);
    UiDebug_SetFlushHook(@OnFlush);
    try
      RenderBaseline; // init
      // thresholds list
      if Length(GThresholds)=0 then
      begin
        SetLength(GThresholds,3);
        GThresholds[0] := '0.90'; GThresholds[1] := '0.35'; GThresholds[2] := '0.20';
      end;
      // iterate thresholds
      for i := 0 to High(GThresholds) do
      begin
        arg := GThresholds[i];
        if SameText(arg,'0.90') then RunWithThreshold('conservative', arg)
        else if SameText(arg,'0.35') then RunWithThreshold('default', arg)
        else if SameText(arg,'0.20') then RunWithThreshold('aggressive', arg)
        else RunWithThreshold(arg, arg);
      end;
    finally
      UiDebug_EnableFrameBufferingForBenchmark(False);
      UiDebug_SetFlushHook(nil);
      UninstallHooks;
    end;
  finally
    term_done;
  end;
end.

