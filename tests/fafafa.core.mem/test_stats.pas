{$CODEPAGE UTF8}
unit test_stats;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.stats,
  fafafa.core.mem.allocator;

type
  TTestCase_Stats = class(TTestCase)
  published
    procedure Test_MemPool_Stats_Basic;
    procedure Test_StackPool_Stats_Basic;
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

    LPool.Free(LPtr);
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

initialization
  RegisterTest(TTestCase_Stats);

end.

