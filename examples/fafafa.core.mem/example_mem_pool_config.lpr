program example_mem_pool_config;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.pool.slab,
  fafafa.core.mem.stats;

procedure PrintPerfCounters(const aPerf: TSlabPerfCounters);
begin
  WriteLn('Perf: alloc_calls=', aPerf.AllocCalls,
          ' free_calls=', aPerf.FreeCalls);
  WriteLn('Perf: alloc_time=', aPerf.AllocTime,
          ' free_time=', aPerf.FreeTime);
  WriteLn('Perf: page_merges=', aPerf.PageMerges,
          ' merged_pages=', aPerf.MergedPages);
end;

procedure DemoCustomSlabConfig(const aShowPerf: Boolean);
var
  LConfig: TSlabConfig;
  LPool: TSlabPool;
  LPtrA: Pointer;
  LPtrB: Pointer;
  LStats: TSlabPoolStats;
  LPerf: TSlabPerfCounters;
  LWarmupUnits: SizeUInt;
begin
  WriteLn('--- TSlabPool Config Demo ---');

  LConfig := CreateDefaultSlabConfig;
  LConfig.EnablePageMerging := True;
  LConfig.EnablePerfMonitoring := True;

  LPool := TSlabPool.Create(32 * 1024, LConfig);
  try
    LWarmupUnits := LPool.Warmup(64, 2);
    WriteLn('Warmup units: ', LWarmupUnits);

    LPtrA := LPool.Alloc(128);
    LPtrB := LPool.Alloc(256);
    if (LPtrA <> nil) and (LPtrB <> nil) then
      WriteLn('Allocated 128 and 256 bytes');

    LPool.ReleasePtr(LPtrB);
    LPool.ReleasePtr(LPtrA);

    LStats := GetSlabPoolStats(LPool);
    WriteLn('Stats: segments=', LStats.SegmentCount,
            ' total_capacity=', LStats.TotalCapacity,
            ' total_used=', LStats.TotalUsed);
    WriteLn('Fallback: allocs=', LStats.FallbackAllocCount,
            ' bytes=', LStats.FallbackBytes);

    if aShowPerf then
    begin
      LPerf := LPool.GetPerfCounters;
      PrintPerfCounters(LPerf);
    end;
  finally
    LPool.Destroy;
  end;
end;

function HasArg(const aName: string): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 1 to ParamCount do
    if SameText(ParamStr(LIndex), aName) then Exit(True);
end;

begin
  try
    DemoCustomSlabConfig(HasArg('--perf'));
    WriteLn('Config demo completed.');
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.
