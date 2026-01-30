{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
program bench_blockpool;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.blockpool.growable,
  fafafa.core.mem.blockpool.concurrent,
  fafafa.core.mem.blockpool.sharded;

type
  TBenchThread = class(TThread)
  private
    FPool: IBlockPool;
    FSharded: TShardedBlockPool;
    FIterations: Integer;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aPool: IBlockPool; aSharded: TShardedBlockPool; aIterations: Integer);
    property Error: string read FError;
  end;

constructor TBenchThread.Create(aPool: IBlockPool; aSharded: TShardedBlockPool; aIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := aPool;
  FSharded := aSharded;
  FIterations := aIterations;
  FError := '';
end;

procedure TBenchThread.Execute;
var
  LIdx: Integer;
  LPtr: Pointer;
begin
  try
    for LIdx := 1 to FIterations do
    begin
      LPtr := FPool.Acquire;
      if LPtr = nil then
        raise Exception.Create('Acquire returned nil');
      FPool.Release(LPtr);
    end;
    if FSharded <> nil then
      FSharded.FlushThreadCache;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

function ParseIntArg(const aName: string; aDefault: Integer): Integer;
var
  LIdx: Integer;
  LS: string;
begin
  Result := aDefault;
  for LIdx := 1 to ParamCount do
  begin
    LS := ParamStr(LIdx);
    if Copy(LS, 1, Length(aName) + 1) = aName + '=' then
      Exit(StrToIntDef(Copy(LS, Length(aName) + 2, MaxInt), aDefault));
  end;
end;

function OpsPerSecond(aOps: QWord; aElapsedMs: QWord): Double;
begin
  if aElapsedMs = 0 then
    aElapsedMs := 1;
  Result := (Double(aOps) * 1000.0) / Double(aElapsedMs);
end;

procedure BenchSingle(const aName: string; aPool: IBlockPool; aIterations: Integer);
var
  LIdx: Integer;
  LPtr: Pointer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
begin
  LStartMs := GetTickCount64;
  for LIdx := 1 to aIterations do
  begin
    LPtr := aPool.Acquire;
    aPool.Release(LPtr);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;
  LOps := OpsPerSecond(QWord(aIterations), LElapsedMs);
  Writeln(Format('%-32s %8.2f Mops/s', [aName, LOps / 1e6]));
end;

procedure BenchMulti(const aName: string; aPool: IBlockPool; aSharded: TShardedBlockPool; aThreads, aIterationsPerThread: Integer);
var
  LThreads: array of TBenchThread;
  LIdx: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
begin
  SetLength(LThreads, aThreads);
  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TBenchThread.Create(aPool, aSharded, aIterationsPerThread);

  LStartMs := GetTickCount64;
  try
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;
  finally
    LElapsedMs := GetTickCount64 - LStartMs;
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;

  LOps := OpsPerSecond(QWord(aThreads) * QWord(aIterationsPerThread), LElapsedMs);
  Writeln(Format('%-32s %8.2f Mops/s', [aName, LOps / 1e6]));
end;

procedure Run;
const
  BLOCK_SIZE = 64;
  XTHREAD_BATCH = 32;
var
  LThreads: Integer;
  LIterSingle: Integer;
  LIterPerThread: Integer;
  LPool: IBlockPool;
  LCfg: TShardedBlockPoolConfig;
  LShardedObj: TShardedBlockPool;
  LSharded: IBlockPool;
  LPtr: Pointer;
  LPtrs: array of Pointer;
  LIdx: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
begin
  LThreads := ParseIntArg('--threads', 4);
  if LThreads < 1 then LThreads := 1;
  LIterSingle := ParseIntArg('--iters', 2000000);
  if LIterSingle < 1 then LIterSingle := 1;
  LIterPerThread := LIterSingle div LThreads;
  if LIterPerThread < 1 then LIterPerThread := 1;

  Writeln('fafafa.core.mem blockpool benchmark');
  Writeln(Format('  BlockSize=%d Threads=%d Iters=%d (single) / %d (per-thread)', [BLOCK_SIZE, LThreads, LIterSingle, LIterPerThread]));
  Writeln;

  Writeln('Single-thread');
  LPool := TBlockPool.Create(BLOCK_SIZE, SizeUInt(LIterSingle));
  BenchSingle('TBlockPool', LPool, LIterSingle);

  LPool := TGrowingBlockPool.Create(BLOCK_SIZE, 64);
  BenchSingle('TGrowingBlockPool', LPool, LIterSingle);

  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, 64, LThreads);
  LCfg.ThreadCacheCapacity := 0;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := True;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;
  BenchSingle('TShardedBlockPool cache=0 stats=on', LSharded, LIterSingle);

  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, 64, LThreads);
  LCfg.ThreadCacheCapacity := 64;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := True;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;
  BenchSingle('TShardedBlockPool cache=64 stats=on', LSharded, LIterSingle);
  LShardedObj.FlushThreadCache;

  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, 64, LThreads);
  LCfg.ThreadCacheCapacity := 0;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := False;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;
  BenchSingle('TShardedBlockPool cache=0 stats=off', LSharded, LIterSingle);

  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, 64, LThreads);
  LCfg.ThreadCacheCapacity := 64;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := False;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;
  BenchSingle('TShardedBlockPool cache=64 stats=off', LSharded, LIterSingle);
  LShardedObj.FlushThreadCache;

  Writeln;
  Writeln('Multi-thread');

  LPool := TBlockPoolConcurrent.Create(BLOCK_SIZE, SizeUInt(LThreads) * 1024);
  BenchMulti('TBlockPoolConcurrent', LPool, nil, LThreads, LIterPerThread);

  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, SizeUInt(LThreads) * 1024, LThreads);
  LCfg.ThreadCacheCapacity := 0;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := True;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;
  BenchMulti('TShardedBlockPool cache=0 stats=on', LSharded, LShardedObj, LThreads, LIterPerThread);

  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, SizeUInt(LThreads) * 1024, LThreads);
  LCfg.ThreadCacheCapacity := 64;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := True;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;
  BenchMulti('TShardedBlockPool cache=64 stats=on', LSharded, LShardedObj, LThreads, LIterPerThread);

  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, SizeUInt(LThreads) * 1024, LThreads);
  LCfg.ThreadCacheCapacity := 0;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := False;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;
  BenchMulti('TShardedBlockPool cache=0 stats=off', LSharded, LShardedObj, LThreads, LIterPerThread);

  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, SizeUInt(LThreads) * 1024, LThreads);
  LCfg.ThreadCacheCapacity := 64;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := False;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;
  BenchMulti('TShardedBlockPool cache=64 stats=off', LSharded, LShardedObj, LThreads, LIterPerThread);

  Writeln;
  Writeln('Cross-thread');

  // Cross-thread free: many producer threads acquire, main thread releases.
  // This stresses remote-free routing and batching.
  LCfg := TShardedBlockPoolConfig.Default(BLOCK_SIZE, SizeUInt(LThreads) * 1024, LThreads);
  LCfg.ThreadCacheCapacity := 64;
  LCfg.ThreadCacheCheckDoubleFree := False;
  LCfg.TrackInUse := False;
  LShardedObj := TShardedBlockPool.Create(LCfg);
  LSharded := LShardedObj as IBlockPool;

  SetLength(LPtrs, LIterPerThread * LThreads);
  for LIdx := 0 to High(LPtrs) do
  begin
    LPtr := LSharded.Acquire;
    if LPtr = nil then
      raise Exception.Create('Acquire returned nil');
    LPtrs[LIdx] := LPtr;
  end;

  // Release in main thread, in batches to mimic real-world behavior.
  LStartMs := GetTickCount64;
  for LIdx := 0 to High(LPtrs) do
  begin
    LSharded.Release(LPtrs[LIdx]);
    if ((LIdx + 1) mod XTHREAD_BATCH) = 0 then
      LShardedObj.FlushThreadCache;
  end;
  LShardedObj.FlushThreadCache;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(Length(LPtrs)), LElapsedMs);
  Writeln(Format('%-32s %8.2f Mops/s', ['TShardedBlockPool cross-thread free', LOps / 1e6]));
end;

begin
  Run;
end.
