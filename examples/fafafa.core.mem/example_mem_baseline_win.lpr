program example_mem_baseline_win;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.tick,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.pool.slab;

procedure WriteCSVHeader;
begin
  Writeln('case,variant,iterations,bytes_per_op,runs,avg_ms,min_ms,max_ms,ops_per_ms_avg');
end;

procedure WriteCSVRow(const aCase, aVariant: string; aIters: QWord; aBytes: QWord; aRuns: Integer; aAvgMs, aMinMs, aMaxMs: QWord);
var
  LOps: Double;
begin
  if aAvgMs = 0 then
    LOps := aIters
  else
    LOps := aIters / aAvgMs;
  Writeln(Format('%s,%s,%d,%d,%d,%d,%d,%d,%.3f', [aCase, aVariant, aIters, aBytes, aRuns, aAvgMs, aMinMs, aMaxMs, LOps]));
end;

var
  GTick: ITick;
  GIterSmall: QWord = 200000;
  GIterSlab: QWord = 150000;
  GRuns: Integer = 5;

procedure ParseArgs;
var
  LIndex: Integer;
  LArg: string;
  LValue: Int64;
begin
  for LIndex := 1 to ParamCount do
  begin
    LArg := ParamStr(LIndex);
    if Pos('--iters=', LArg) = 1 then
    begin
      if TryStrToInt64(Copy(LArg, 8, MaxInt), LValue) and (LValue > 0) then
      begin
        GIterSmall := LValue;
        GIterSlab := LValue;
      end;
    end
    else if Pos('--runs=', LArg) = 1 then
    begin
      if TryStrToInt64(Copy(LArg, 8, MaxInt), LValue) and (LValue > 0) then
        GRuns := LValue;
    end;
  end;
end;

procedure Bench_MemPool;
const
  BlockSize = 64;
  Capacity = 1024;
var
  LIndex: Integer;
  LRun: Integer;
  LPtr: Pointer;
  LPool: TMemPool;
  LStart: UInt64;
  LMs: QWord;
  LMinMs: QWord;
  LMaxMs: QWord;
  LSumMs: QWord;
begin
  LPool := TMemPool.Create(BlockSize, Capacity);
  try
    LMinMs := High(QWord);
    LMaxMs := 0;
    LSumMs := 0;
    for LRun := 1 to GRuns do
    begin
      LStart := GTick.GetCurrentTick;
      for LIndex := 1 to GIterSmall do
      begin
        LPtr := LPool.Alloc;
        LPool.ReleasePtr(LPtr);
      end;
      LMs := Round(GTick.TicksToMilliSeconds(GTick.GetElapsedTicks(LStart)));
      if LMs < LMinMs then LMinMs := LMs;
      if LMs > LMaxMs then LMaxMs := LMs;
      Inc(LSumMs, LMs);
    end;
    WriteCSVRow('MemPool', 'Alloc/Free', GIterSmall, BlockSize, GRuns, LSumMs div GRuns, LMinMs, LMaxMs);
  finally
    LPool.Destroy;
  end;
end;

procedure Bench_StackPool;
const
  TotalSize = 1 shl 20; // 1MB
var
  LIndex: Integer;
  LRun: Integer;
  LPool: TStackPool;
  LPtr: Pointer;
  LStart: UInt64;
  LMs: QWord;
  LMinMs: QWord;
  LMaxMs: QWord;
  LSumMs: QWord;
begin
  LPool := TStackPool.Create(TotalSize);
  try
    // 默认对齐（多轮）
    LMinMs := High(QWord);
    LMaxMs := 0;
    LSumMs := 0;
    for LRun := 1 to GRuns do
    begin
      LStart := GTick.GetCurrentTick;
      for LIndex := 1 to GIterSmall do
      begin
        LPtr := LPool.Alloc(32);
        if LPtr = nil then
          LPool.Reset;
      end;
      LPool.Reset;
      LMs := Round(GTick.TicksToMilliSeconds(GTick.GetElapsedTicks(LStart)));
      if LMs < LMinMs then LMinMs := LMs;
      if LMs > LMaxMs then LMaxMs := LMs;
      Inc(LSumMs, LMs);
    end;
    WriteCSVRow('StackPool', 'Alloc(default)', GIterSmall, 32, GRuns, LSumMs div GRuns, LMinMs, LMaxMs);

    // 显式对齐（多轮）
    LMinMs := High(QWord);
    LMaxMs := 0;
    LSumMs := 0;
    for LRun := 1 to GRuns do
    begin
      LStart := GTick.GetCurrentTick;
      for LIndex := 1 to GIterSmall do
      begin
        LPtr := LPool.AllocAligned(32, 32);
        if LPtr = nil then
          LPool.Reset;
      end;
      LPool.Reset;
      LMs := Round(GTick.TicksToMilliSeconds(GTick.GetElapsedTicks(LStart)));
      if LMs < LMinMs then LMinMs := LMs;
      if LMs > LMaxMs then LMaxMs := LMs;
      Inc(LSumMs, LMs);
    end;
    WriteCSVRow('StackPool', 'AllocAligned(32)', GIterSmall, 32, GRuns, LSumMs div GRuns, LMinMs, LMaxMs);
  finally
    LPool.Destroy;
  end;
end;

procedure Bench_SlabPool;
const
  TotalBytes = 1 shl 20; // 1MB
var
  LIndex: Integer;
  LRun: Integer;
  LPool: TSlabPool;
  LPtr1: Pointer;
  LPtr2: Pointer;
  LStart: UInt64;
  LMs: QWord;
  LMinMs: QWord;
  LMaxMs: QWord;
  LSumMs: QWord;
begin
  LPool := TSlabPool.Create(TotalBytes);
  try
    LMinMs := High(QWord);
    LMaxMs := 0;
    LSumMs := 0;
    for LRun := 1 to GRuns do
    begin
      LStart := GTick.GetCurrentTick;
      for LIndex := 1 to GIterSlab do
      begin
        LPtr1 := LPool.Alloc(64);
        LPtr2 := LPool.Alloc(128);
        LPool.ReleasePtr(LPtr2);
        LPool.ReleasePtr(LPtr1);
      end;
      LMs := Round(GTick.TicksToMilliSeconds(GTick.GetElapsedTicks(LStart)));
      if LMs < LMinMs then LMinMs := LMs;
      if LMs > LMaxMs then LMaxMs := LMs;
      Inc(LSumMs, LMs);
    end;
    WriteCSVRow('SlabPool', 'Alloc/Free 64+128', GIterSlab * 2, 96, GRuns, LSumMs div GRuns, LMinMs, LMaxMs);
  finally
    LPool.Destroy;
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
    on E: Exception do
    begin
      Writeln('error,', E.ClassName, ':', E.Message);
      Halt(1);
    end;
  end;
end.
