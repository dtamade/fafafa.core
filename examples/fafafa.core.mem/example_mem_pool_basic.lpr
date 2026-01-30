program example_mem_pool_basic;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.pool.slab,
  fafafa.core.mem.stats;

procedure DemoMemPool;
var
  LPool: TMemPool;
  LPtr1: Pointer;
  LPtr2: Pointer;
  LStats: TMemPoolStats;
begin
  WriteLn('--- TMemPool Demo ---');
  LPool := TMemPool.Create(64, 4);
  try
    LPtr1 := LPool.Alloc;
    LPtr2 := LPool.Alloc;
    if (LPtr1 <> nil) and (LPtr2 <> nil) then
      WriteLn('Allocated 2 blocks of 64 bytes');
    LStats := GetMemPoolStats(LPool);
    WriteLn('MemPool: ', LStats.AllocatedCount, '/', LStats.Capacity);
    LPool.ReleasePtr(LPtr2);
    LPool.ReleasePtr(LPtr1);
    LPool.Reset;
    WriteLn('TMemPool reset complete');
  finally
    LPool.Destroy;
  end;
end;

procedure DemoStackPool;
var
  LPool: TStackPool;
  LPtr1: Pointer;
  LPtr2: Pointer;
  LStats: TStackPoolStats;
begin
  WriteLn('--- TStackPool Demo ---');
  LPool := TStackPool.Create(1024);
  try
    LPtr1 := LPool.Alloc(128);
    LPtr2 := LPool.Alloc(256, 16);
    if (LPtr1 <> nil) and (LPtr2 <> nil) then
      WriteLn('Allocated 128 and 256 bytes (aligned)');
    LStats := GetStackPoolStats(LPool);
    WriteLn('StackPool: ', LStats.UsedSize, '/', LStats.TotalSize);
    LPool.Reset;
    WriteLn('TStackPool reset complete');
  finally
    LPool.Destroy;
  end;
  { 可选：也可使用作用域守卫风格 }
  //var LGuard: TStackScopeGuard;
  //LGuard := TStackScopeGuard.Enter(LPool);
  //try
  //  LPtr1 := LPool.Alloc(128);
  //  LPtr2 := LPool.Alloc(256, 16);
  //finally
  //  LGuard.Leave;
  //end;
end;

procedure DemoBlockPool;
var
  LPool: TBlockPool;
  LPtr1: Pointer;
  LPtr2: Pointer;
  LStats: TBlockPoolStats;
begin
  WriteLn('--- TBlockPool Demo ---');
  LPool := TBlockPool.Create(32, 8);
  try
    LPtr1 := LPool.Acquire;
    LPtr2 := LPool.Acquire;
    if (LPtr1 <> nil) and (LPtr2 <> nil) then
      WriteLn('Acquired 2 blocks of 32 bytes');
    LStats := GetBlockPoolStats(LPool);
    WriteLn('BlockPool: ', LStats.InUse, '/', LStats.Capacity);
    LPool.Release(LPtr2);
    LPool.Release(LPtr1);
    WriteLn('BlockPool release complete');
  finally
    LPool.Destroy;
  end;
end;

procedure DemoSlabPool;
var
  LPool: TSlabPool;
  LPtr1: Pointer;
  LPtr2: Pointer;
  LStats: TSlabPoolStats;
  LPerf: TSlabPerfCounters;
begin
  WriteLn('--- TSlabPool Demo ---');
  LPool := TSlabPool.Create(64*1024);
  try
    LPtr1 := LPool.Alloc(128);
    LPtr2 := LPool.Alloc(64);
    if (LPtr1 <> nil) and (LPtr2 <> nil) then
      WriteLn('Allocated 128 and 64 bytes from SlabPool');
    LStats := GetSlabPoolStats(LPool);
    LPerf := LPool.GetPerfCounters;
    WriteLn('Slab: ', LStats.TotalUsed, '/', LStats.TotalCapacity,
      ', allocs: ', LPerf.AllocCalls);
    LPool.ReleasePtr(LPtr2);
    LPool.ReleasePtr(LPtr1);
    LPerf := LPool.GetPerfCounters;
    WriteLn('Slab frees: ', LPerf.FreeCalls);
  finally
    LPool.Destroy;
  end;
end;

begin
  try
    DemoMemPool;
    DemoStackPool;
    DemoBlockPool;
    DemoSlabPool;
    WriteLn('All pool demos completed.');
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.
