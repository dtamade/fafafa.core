{$CODEPAGE UTF8}
unit test_stats;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.pool.slab,
  fafafa.core.mem.stats,
  fafafa.core.mem.allocator;

type
  TTestCase_Stats = class(TTestCase)
  published
    procedure Test_MemPool_Stats_Basic;
    procedure Test_StackPool_Stats_Basic;
    procedure Test_BlockPool_Stats_Basic;
    procedure Test_SlabPool_Stats_Basic;
    procedure Test_SlabPool_PerfCounters;
  end;

implementation

procedure TTestCase_Stats.Test_MemPool_Stats_Basic;
var
  LPool: TMemPool;
  LStats: TMemPoolStats;
  LPtr: Pointer;
begin
  LPool := TMemPool.Create(16, 4, GetRtlAllocator);
  try
    LStats := GetMemPoolStats(LPool);
    AssertEquals(16, LStats.BlockSize);
    AssertEquals(4, LStats.Capacity);
    AssertEquals(0, LStats.AllocatedCount);

    LPtr := LPool.Alloc;
    AssertNotNull(LPtr);
    LStats := GetMemPoolStats(LPool);
    AssertEquals(1, LStats.AllocatedCount);
    AssertTrue('Utilization > 0', LStats.Utilization > 0.0);

    LPool.ReleasePtr(LPtr);
    LStats := GetMemPoolStats(LPool);
    AssertEquals(0, LStats.AllocatedCount);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_Stats.Test_StackPool_Stats_Basic;
var
  LPool: TStackPool;
  LStats: TStackPoolStats;
  LPtr: Pointer;
begin
  LPool := TStackPool.Create(128, GetRtlAllocator);
  try
    LStats := GetStackPoolStats(LPool);
    AssertEquals(SizeUInt(128), LStats.TotalSize);
    AssertEquals(SizeUInt(0), LStats.UsedSize);

    LPtr := LPool.Alloc(32);
    AssertNotNull(LPtr);
    LStats := GetStackPoolStats(LPool);
    AssertTrue('UsedSize > 0', LStats.UsedSize > 0);
    AssertTrue('Utilization > 0', LStats.Utilization > 0.0);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_Stats.Test_BlockPool_Stats_Basic;
var
  LPool: TBlockPool;
  LStats: TBlockPoolStats;
  LPtr: Pointer;
begin
  LPool := TBlockPool.Create(32, 8);
  try
    LStats := GetBlockPoolStats(LPool);
    AssertEquals(SizeUInt(32), LStats.BlockSize);
    AssertEquals(SizeUInt(8), LStats.Capacity);
    AssertEquals(SizeUInt(0), LStats.InUse);

    LPtr := LPool.Acquire;
    AssertNotNull(LPtr);
    LStats := GetBlockPoolStats(LPool);
    AssertEquals(SizeUInt(1), LStats.InUse);
    AssertTrue('Utilization > 0', LStats.Utilization > 0.0);

    LPool.Release(LPtr);
    LStats := GetBlockPoolStats(LPool);
    AssertEquals(SizeUInt(0), LStats.InUse);
  finally
    LPool.Destroy;
  end;
end;



procedure TTestCase_Stats.Test_SlabPool_Stats_Basic;
var
  LPool: TSlabPool;
  LStats: TSlabPoolStats;
  LPtr: Pointer;
begin
  LPool := TSlabPool.Create(64*1024, GetRtlAllocator);
  try
    LStats := GetSlabPoolStats(LPool);
    AssertTrue('SegmentCount >= 1', LStats.SegmentCount >= 1);
    AssertTrue('TotalCapacity > 0', LStats.TotalCapacity > 0);
    AssertEquals(0, LStats.FallbackAllocCount);

    LPtr := LPool.GetMem(256*1024); // fallback path
    AssertNotNull(LPtr);
    LStats := GetSlabPoolStats(LPool);
    AssertEquals(1, LStats.FallbackAllocCount);
    AssertEquals(SizeUInt(256*1024), LStats.FallbackBytes);

    LPool.FreeMem(LPtr);
    LStats := GetSlabPoolStats(LPool);
    AssertEquals(0, LStats.FallbackAllocCount);
    AssertEquals(SizeUInt(0), LStats.FallbackBytes);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_Stats.Test_SlabPool_PerfCounters;
var
  LConfig: TSlabConfig;
  LPool: TSlabPool;
  LPerf: TSlabPerfCounters;
  LPtr: Pointer;
begin
  LConfig := CreateDefaultSlabConfig;
  LConfig.EnablePerfMonitoring := True;
  LPool := TSlabPool.Create(64 * 1024, LConfig, GetRtlAllocator);
  try
    LPerf := LPool.GetPerfCounters;
    AssertTrue('AllocCalls = 0', LPerf.AllocCalls = 0);
    AssertTrue('FreeCalls = 0', LPerf.FreeCalls = 0);

    LPtr := LPool.GetMem(128);
    AssertNotNull(LPtr);
    LPool.FreeMem(LPtr);

    LPerf := LPool.GetPerfCounters;
    AssertTrue('AllocCalls = 1', LPerf.AllocCalls = 1);
    AssertTrue('FreeCalls = 1', LPerf.FreeCalls = 1);
  finally
    LPool.Destroy;
  end;

  LConfig := CreateDefaultSlabConfig;
  LConfig.EnablePerfMonitoring := False;
  LPool := TSlabPool.Create(64 * 1024, LConfig, GetRtlAllocator);
  try
    LPtr := LPool.GetMem(128);
    if LPtr <> nil then
      LPool.FreeMem(LPtr);

    LPerf := LPool.GetPerfCounters;
    AssertTrue('Perf disabled: AllocCalls = 0', LPerf.AllocCalls = 0);
    AssertTrue('Perf disabled: FreeCalls = 0', LPerf.FreeCalls = 0);
  finally
    LPool.Destroy;
  end;
end;

initialization
  RegisterTest(TTestCase_Stats);

end.
