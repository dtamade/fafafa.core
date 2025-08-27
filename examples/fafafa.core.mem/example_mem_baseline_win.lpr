{$CODEPAGE UTF8}
program example_mem_baseline_win;

{$mode objfpc}{$H+}

uses
  SysUtils,
  DateUtils,
  fafafa.core.tick,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.slabPool;

procedure WriteCSVHeader;
begin
  Writeln('case,variant,iterations,bytes_per_op,runs,avg_ms,min_ms,max_ms,ops_per_ms_avg');
end;

procedure WriteCSVRow(const ACase, AVariant: string; AIters: QWord; ABytes: QWord; ARuns: Integer; AAvgMs, AMinMs, AMaxMs: QWord);
var ops: Double;
begin
  if AAvgMs = 0 then ops := AIters else ops := AIters / AAvgMs;
  Writeln(Format('%s,%s,%d,%d,%d,%d,%d,%d,%.3f', [ACase, AVariant, AIters, ABytes, ARuns, AAvgMs, AMinMs, AMaxMs, ops]));
end;



var GTick: ITick;
    GIterSmall: QWord = 200000;
    GIterSlab: QWord = 150000;
    GRuns: Integer = 5;

procedure ParseArgs;
var i: Integer; s: string; v: Int64;
begin
  for i := 1 to ParamCount do begin
    s := ParamStr(i);
    if Pos('--iters=', s) = 1 then begin
      if TryStrToInt64(Copy(s, 8, MaxInt), v) and (v > 0) then begin
        GIterSmall := v;
        GIterSlab := v;
      end;
    end else
    if Pos('--runs=', s) = 1 then begin
      if TryStrToInt64(Copy(s, 8, MaxInt), v) and (v > 0) then
        GRuns := v;
    end;
  end;
end;

procedure Bench_MemPool;
const BlockSize = 64; Capacity = 1024;
var i, r: Integer; p: Pointer; mp: TMemPool; tStart: UInt64; ms, minMs, maxMs, sumMs: QWord;
begin
  mp := TMemPool.Create(BlockSize, Capacity);
  try
    minMs := High(QWord); maxMs := 0; sumMs := 0;
    for r := 1 to GRuns do begin
      tStart := GTick.GetCurrentTick;
      for i := 1 to GIterSmall do begin p := mp.Alloc; mp.ReleasePtr(p); end;
      ms := Round(GTick.TicksToMilliSeconds(GTick.GetElapsedTicks(tStart)));
      if ms < minMs then minMs := ms;
      if ms > maxMs then maxMs := ms;
      Inc(sumMs, ms);
    end;
    WriteCSVRow('MemPool','Alloc/Free', GIterSmall, BlockSize, GRuns, sumMs div GRuns, minMs, maxMs);
  finally
    mp.Destroy;
  end;
end;

procedure Bench_StackPool;
const TotalSize = 1 shl 20; // 1MB
var i, r: Integer; sp: TStackPool; p: Pointer; tStart: UInt64; ms, minMs, maxMs, sumMs: QWord;
begin
  sp := TStackPool.Create(TotalSize);
  try
    // 默认对齐（多轮）
    minMs := High(QWord); maxMs := 0; sumMs := 0;
    for r := 1 to GRuns do begin
      tStart := GTick.GetCurrentTick;
      for i := 1 to GIterSmall do begin p := sp.Alloc(32); if p=nil then sp.Reset; end;
      sp.Reset;
      ms := Round(GTick.TicksToMilliSeconds(GTick.GetElapsedTicks(tStart)));
      if ms < minMs then minMs := ms;
      if ms > maxMs then maxMs := ms;
      Inc(sumMs, ms);
    end;
    WriteCSVRow('StackPool','Alloc(default)', GIterSmall, 32, GRuns, sumMs div GRuns, minMs, maxMs);

    // 显式对齐（多轮）
    minMs := High(QWord); maxMs := 0; sumMs := 0;
    for r := 1 to GRuns do begin
      tStart := GTick.GetCurrentTick;
      for i := 1 to GIterSmall do begin p := sp.AllocAligned(32, 32); if p=nil then sp.Reset; end;
      sp.Reset;
      ms := Round(GTick.TicksToMilliSeconds(GTick.GetElapsedTicks(tStart)));
      if ms < minMs then minMs := ms;
      if ms > maxMs then maxMs := ms;
      Inc(sumMs, ms);
    end;
    WriteCSVRow('StackPool','AllocAligned(32)', GIterSmall, 32, GRuns, sumMs div GRuns, minMs, maxMs);
  finally
    sp.Destroy;
  end;
end;

procedure Bench_SlabPool;
const TotalBytes = 1 shl 20; // 1MB
var i, r: Integer; sp: TSlabPool; p1,p2: Pointer; tStart: UInt64; ms, minMs, maxMs, sumMs: QWord;
begin
  sp := TSlabPool.Create(TotalBytes);
  try
    minMs := High(QWord); maxMs := 0; sumMs := 0;
    for r := 1 to GRuns do begin
      tStart := GTick.GetCurrentTick;
      for i := 1 to GIterSlab do begin p1 := sp.Alloc(64); p2 := sp.Alloc(128); sp.ReleasePtr(p2); sp.ReleasePtr(p1); end;
      ms := Round(GTick.TicksToMilliSeconds(GTick.GetElapsedTicks(tStart)));
      if ms < minMs then minMs := ms;
      if ms > maxMs then maxMs := ms;
      Inc(sumMs, ms);
    end;
    WriteCSVRow('SlabPool','Alloc/Free 64+128', GIterSlab*2, 96, GRuns, sumMs div GRuns, minMs, maxMs);
  finally
    sp.Destroy;
  end;
end;

begin
  try
    GTick := CreateDefaultTick;
    ParseArgs;
    WriteCSVHeader;
    Bench_MemPool;
    Bench_StackPool;
    Bench_SlabPool;
  except
    on E: Exception do begin
      Writeln('error,', E.ClassName, ':', E.Message);
      Halt(1);
    end;
  end;
end.

