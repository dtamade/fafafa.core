{
  Extended FixedSlab Pool Tests
  测试 fafafa.core.mem.pool.fixedSlab 的详细功能

  这个测试文件补充了 fixed_slab_smoke_test.pas 中缺失的详细测试：
  - Basic IAllocator operations (6个测试)
  - Boundary tests (6个测试)
  - Error handling (6个测试)
  - Statistics and memory tracking (6个测试)
}

program test_fixedslab_extended;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.pool,
  fafafa.core.mem.allocator;

var
  GTestCount: Integer = 0;
  GPassCount: Integer = 0;
  GFailCount: Integer = 0;

procedure Check(aCondition: Boolean; const aName: string);
begin
  Inc(GTestCount);
  if aCondition then
  begin
    Inc(GPassCount);
    WriteLn('  [PASS] ', aName);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('  [FAIL] ', aName);
  end;
end;

{-----------------------------------------------------------------------------
  P2.1.1: Basic IAllocator Operations (6个测试)
-----------------------------------------------------------------------------}

procedure Test_GetMem_Basic;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_GetMem_Basic ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  P := Pool.GetMem(64);
  Check(P <> nil, 'GetMem should return non-nil pointer');
  Check(Pool.Used > 0, 'Used should be > 0 after allocation');

  Pool.FreeMem(P);
  Check(Pool.Used = 0, 'Used should be 0 after free');
end;

procedure Test_AllocMem_ZeroInitialized;
var
  Pool: IFixedSlabPool;
  P: Pointer;
  I: Integer;
  AllZero: Boolean;
begin
  WriteLn('=== Test_AllocMem_ZeroInitialized ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  P := Pool.AllocMem(256);
  Check(P <> nil, 'AllocMem should return non-nil pointer');

  // Verify zero initialization
  AllZero := True;
  for I := 0 to 255 do
  begin
    if PByte(P)[I] <> 0 then
    begin
      AllZero := False;
      Break;
    end;
  end;

  Check(AllZero, 'AllocMem should zero-initialize memory');
  Pool.FreeMem(P);
end;

procedure Test_ReallocMem_Grow;
var
  Pool: IFixedSlabPool;
  P: Pointer;
  I: Integer;
  DataPreserved: Boolean;
begin
  WriteLn('=== Test_ReallocMem_Grow ===');
  Pool := MakeFixedSlabPool(8192, GetRtlAllocator, 3);

  // Allocate and fill with data
  P := Pool.GetMem(128);
  for I := 0 to 127 do
    PByte(P)[I] := Byte(I);

  // Realloc to larger size
  P := Pool.ReallocMem(P, 256);
  Check(P <> nil, 'ReallocMem grow should succeed');

  // Verify original data preserved
  DataPreserved := True;
  for I := 0 to 127 do
  begin
    if PByte(P)[I] <> Byte(I) then
    begin
      DataPreserved := False;
      Break;
    end;
  end;
  Check(DataPreserved, 'Data should be preserved after grow');

  Pool.FreeMem(P);
end;

procedure Test_ReallocMem_Shrink;
var
  Pool: IFixedSlabPool;
  P: Pointer;
  I: Integer;
  DataPreserved: Boolean;
begin
  WriteLn('=== Test_ReallocMem_Shrink ===');
  Pool := MakeFixedSlabPool(8192, GetRtlAllocator, 3);

  // Allocate and fill with data
  P := Pool.GetMem(256);
  for I := 0 to 255 do
    PByte(P)[I] := Byte(I);

  // Realloc to smaller size
  P := Pool.ReallocMem(P, 128);
  Check(P <> nil, 'ReallocMem shrink should succeed');

  // Verify data preserved (first 128 bytes)
  DataPreserved := True;
  for I := 0 to 127 do
  begin
    if PByte(P)[I] <> Byte(I) then
    begin
      DataPreserved := False;
      Break;
    end;
  end;
  Check(DataPreserved, 'Data should be preserved after shrink');

  Pool.FreeMem(P);
end;

procedure Test_Multiple_Allocations;
var
  Pool: IFixedSlabPool;
  Ptrs: array[0..9] of Pointer;
  I: Integer;
  UsedMax: SizeUInt;
begin
  WriteLn('=== Test_Multiple_Allocations ===');
  Pool := MakeFixedSlabPool(16384, GetRtlAllocator, 3);

  // Allocate 10 blocks
  for I := 0 to 9 do
  begin
    Ptrs[I] := Pool.GetMem(256);
    Check(Ptrs[I] <> nil, 'Allocation should succeed');
  end;

  UsedMax := Pool.Used;
  Check(UsedMax > 0, 'Used should be > 0 after allocations');

  // Free all
  for I := 0 to 9 do
    Pool.FreeMem(Ptrs[I]);

  Check(Pool.Used = 0, 'Used should be 0 after freeing all');
end;

procedure Test_Capacity_Tracking;
var
  Pool: IFixedSlabPool;
  Cap: SizeUInt;
begin
  WriteLn('=== Test_Capacity_Tracking ===');
  Pool := MakeFixedSlabPool(8192, GetRtlAllocator, 3);

  Cap := Pool.Capacity;
  Check(Cap > 0, 'Capacity should be > 0');
  // Note: Capacity may be larger than requested due to page alignment
  Check(Cap >= 4096, 'Capacity should be at least one page (4096 bytes)');
end;

{-----------------------------------------------------------------------------
  P2.1.2: Boundary Tests (6个测试)
-----------------------------------------------------------------------------}

procedure Test_MinSize_Allocation;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_MinSize_Allocation ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  // MinShift = 3 means minimum allocation is 2^3 = 8 bytes
  P := Pool.GetMem(1);  // Request 1 byte, should get at least 8
  Check(P <> nil, 'Should allocate even for 1 byte request');

  Pool.FreeMem(P);
end;

procedure Test_LargeAllocation_MultiPage;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_LargeAllocation_MultiPage ===');
  Pool := MakeFixedSlabPool(16384, GetRtlAllocator, 3);

  // Allocate > 4096 bytes (multi-page allocation)
  P := Pool.GetMem(8192);
  Check(P <> nil, 'Should handle multi-page allocation');
  Check((PtrUInt(P) and (4096-1)) = 0, 'Large alloc should be page-aligned');

  Pool.FreeMem(P);
end;

procedure Test_ZeroSize_Allocation;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_ZeroSize_Allocation ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  P := Pool.GetMem(0);
  // Zero-size allocation behavior: may return nil or minimum size
  Check(True, 'Zero-size allocation should not crash');

  if P <> nil then
    Pool.FreeMem(P);
end;

procedure Test_Exhaustion_Behavior;
var
  Pool: IFixedSlabPool;
  Ptrs: array[0..999] of Pointer;
  I, Count: Integer;
begin
  WriteLn('=== Test_Exhaustion_Behavior ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  // Fill pool to exhaustion
  Count := 0;
  for I := 0 to 999 do
  begin
    Ptrs[I] := Pool.GetMem(64);
    if Ptrs[I] = nil then
      Break;
    Inc(Count);
  end;

  Check(Count > 0, 'Should allocate at least some blocks');

  // Try to allocate when exhausted
  Check(Pool.GetMem(64) = nil, 'Should return nil when exhausted');

  // Free all
  for I := 0 to Count - 1 do
    Pool.FreeMem(Ptrs[I]);
end;

procedure Test_Reset_ClearsAll;
var
  Pool: IFixedSlabPool;
  Ptrs: array[0..4] of Pointer;
  I: Integer;
begin
  WriteLn('=== Test_Reset_ClearsAll ===');
  Pool := MakeFixedSlabPool(8192, GetRtlAllocator, 3);

  // Allocate multiple blocks
  for I := 0 to 4 do
    Ptrs[I] := Pool.GetMem(128);

  Check(Pool.Used > 0, 'Used should be > 0 before reset');

  // Reset pool
  Pool.Reset;
  Check(Pool.Used = 0, 'Used should be 0 after reset');

  // Should be able to allocate again
  Check(Pool.GetMem(128) <> nil, 'Should allocate after reset');
end;

procedure Test_Alignment_Boundary;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_Alignment_Boundary ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  P := Pool.GetMem(64);
  Check(P <> nil, 'Allocation should succeed');

  // Check alignment (should be at least 8-byte aligned for MinShift=3)
  Check((PtrUInt(P) and 7) = 0, 'Pointer should be 8-byte aligned');

  Pool.FreeMem(P);
end;

{-----------------------------------------------------------------------------
  P2.1.3: Error Handling (6个测试)
-----------------------------------------------------------------------------}

procedure Test_FreeMem_NilPointer;
var
  Pool: IFixedSlabPool;
begin
  WriteLn('=== Test_FreeMem_NilPointer ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  // FreeMem(nil) should not crash
  Pool.FreeMem(nil);
  Check(True, 'FreeMem(nil) should not crash');
end;

procedure Test_FreeMem_ForeignPointer;
var
  Pool: IFixedSlabPool;
  Alloc: IAllocator;
  ForeignPtr: Pointer;
begin
  WriteLn('=== Test_FreeMem_ForeignPointer ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);
  Alloc := GetRtlAllocator;

  // Allocate from different allocator
  ForeignPtr := Alloc.GetMem(128);
  try
    // FreeMem foreign pointer should not crash (based on smoke test)
    Pool.FreeMem(ForeignPtr);
    Check(True, 'FreeMem(foreign) should not crash');
  finally
    Alloc.FreeMem(ForeignPtr);
  end;
end;

procedure Test_DoubleFree;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_DoubleFree ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  P := Pool.GetMem(64);
  Pool.FreeMem(P);

  // Double free should not crash (based on smoke test)
  Pool.FreeMem(P);
  Check(True, 'Double free should not crash');
end;

procedure Test_ReallocMem_NilPointer;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_ReallocMem_NilPointer ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  // ReallocMem(nil, size) should behave like GetMem
  P := Pool.ReallocMem(nil, 128);
  Check(P <> nil, 'ReallocMem(nil, size) should allocate');

  Pool.FreeMem(P);
end;

procedure Test_ReallocMem_ZeroSize;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_ReallocMem_ZeroSize ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  P := Pool.GetMem(128);

  // ReallocMem(ptr, 0) should behave like FreeMem
  P := Pool.ReallocMem(P, 0);
  Check(P = nil, 'ReallocMem(ptr, 0) should return nil');
end;

procedure Test_FreeMem_AfterReset;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  WriteLn('=== Test_FreeMem_AfterReset ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  P := Pool.GetMem(64);
  Pool.Reset;

  // FreeMem after reset should not crash (pointer is now invalid)
  Pool.FreeMem(P);
  Check(True, 'FreeMem after reset should not crash');
end;

{-----------------------------------------------------------------------------
  P2.1.4: Statistics and Memory Tracking (6个测试)
-----------------------------------------------------------------------------}

procedure Test_Used_Tracking_Single;
var
  Pool: IFixedSlabPool;
  P: Pointer;
  Used1: SizeUInt;
begin
  WriteLn('=== Test_Used_Tracking_Single ===');
  Pool := MakeFixedSlabPool(8192, GetRtlAllocator, 3);

  Check(Pool.Used = 0, 'Initial used should be 0');

  P := Pool.GetMem(128);
  Used1 := Pool.Used;
  Check(Used1 > 0, 'Used should increase after allocation');

  Pool.FreeMem(P);
  Check(Pool.Used = 0, 'Used should be 0 after free');
end;

procedure Test_Used_Tracking_Multiple;
var
  Pool: IFixedSlabPool;
  P1, P2: Pointer;
  Used1, Used2: SizeUInt;
begin
  WriteLn('=== Test_Used_Tracking_Multiple ===');
  Pool := MakeFixedSlabPool(8192, GetRtlAllocator, 3);

  P1 := Pool.GetMem(128);
  Used1 := Pool.Used;
  Check(Used1 > 0, 'Used should increase after first allocation');

  P2 := Pool.GetMem(256);
  Used2 := Pool.Used;
  Check(Used2 > Used1, 'Used should increase after second allocation');

  Pool.FreeMem(P1);
  Check(Pool.Used < Used2, 'Used should decrease after first free');

  Pool.FreeMem(P2);
  Check(Pool.Used = 0, 'Used should be 0 after freeing all');
end;

procedure Test_Capacity_Remains_Constant;
var
  Pool: IFixedSlabPool;
  P: Pointer;
  Cap1, Cap2: SizeUInt;
begin
  WriteLn('=== Test_Capacity_Remains_Constant ===');
  Pool := MakeFixedSlabPool(8192, GetRtlAllocator, 3);

  Cap1 := Pool.Capacity;

  P := Pool.GetMem(128);
  Cap2 := Pool.Capacity;
  Check(Cap2 = Cap1, 'Capacity should remain constant after allocation');

  Pool.FreeMem(P);
  Check(Pool.Capacity = Cap1, 'Capacity should remain constant after free');
end;

procedure Test_Statistics_AfterReset;
var
  Pool: IFixedSlabPool;
  P: Pointer;
  CapBefore, CapAfter: SizeUInt;
begin
  WriteLn('=== Test_Statistics_AfterReset ===');
  Pool := MakeFixedSlabPool(8192, GetRtlAllocator, 3);

  CapBefore := Pool.Capacity;

  P := Pool.GetMem(128);
  Check(Pool.Used > 0, 'Used should be > 0 before reset');

  Pool.Reset;
  Check(Pool.Used = 0, 'Used should be 0 after reset');

  CapAfter := Pool.Capacity;
  Check(CapAfter = CapBefore, 'Capacity should remain same after reset');
end;

procedure Test_Memory_Accounting_Accuracy;
var
  Pool: IFixedSlabPool;
  Ptrs: array[0..9] of Pointer;
  I: Integer;
  UsedBefore: SizeUInt;
begin
  WriteLn('=== Test_Memory_Accounting_Accuracy ===');
  Pool := MakeFixedSlabPool(16384, GetRtlAllocator, 3);

  // Allocate 10 blocks
  for I := 0 to 9 do
    Ptrs[I] := Pool.GetMem(256);

  UsedBefore := Pool.Used;
  Check(UsedBefore > 0, 'Used should be > 0 after allocations');

  // Free all blocks
  for I := 0 to 9 do
    Pool.FreeMem(Ptrs[I]);

  // Note: Used may not decrease immediately after partial frees due to page-level accounting
  // But it should be 0 after freeing all blocks
  Check(Pool.Used = 0, 'Used should be 0 after freeing all');
end;

procedure Test_Capacity_Used_Relationship;
var
  Pool: IFixedSlabPool;
  Ptrs: array[0..99] of Pointer;
  I, Count: Integer;
begin
  WriteLn('=== Test_Capacity_Used_Relationship ===');
  Pool := MakeFixedSlabPool(4096, GetRtlAllocator, 3);

  // Fill pool
  Count := 0;
  for I := 0 to 99 do
  begin
    Ptrs[I] := Pool.GetMem(64);
    if Ptrs[I] = nil then
      Break;
    Inc(Count);
  end;

  // Used should never exceed Capacity
  Check(Pool.Used <= Pool.Capacity, 'Used should never exceed Capacity');

  // Free all
  for I := 0 to Count - 1 do
    Pool.FreeMem(Ptrs[I]);
end;

{-----------------------------------------------------------------------------
  Main
-----------------------------------------------------------------------------}

begin
  WriteLn('');
  WriteLn('Extended FixedSlab Pool Tests');
  WriteLn('==============================');
  WriteLn('');

  // P2.1.1: Basic IAllocator Operations (6个测试)
  Test_GetMem_Basic;
  Test_AllocMem_ZeroInitialized;
  Test_ReallocMem_Grow;
  Test_ReallocMem_Shrink;
  Test_Multiple_Allocations;
  Test_Capacity_Tracking;

  // P2.1.2: Boundary Tests (6个测试)
  Test_MinSize_Allocation;
  Test_LargeAllocation_MultiPage;
  Test_ZeroSize_Allocation;
  Test_Exhaustion_Behavior;
  Test_Reset_ClearsAll;
  Test_Alignment_Boundary;

  // P2.1.3: Error Handling (6个测试)
  Test_FreeMem_NilPointer;
  Test_FreeMem_ForeignPointer;
  Test_DoubleFree;
  Test_ReallocMem_NilPointer;
  Test_ReallocMem_ZeroSize;
  Test_FreeMem_AfterReset;

  // P2.1.4: Statistics and Memory Tracking (6个测试)
  Test_Used_Tracking_Single;
  Test_Used_Tracking_Multiple;
  Test_Capacity_Remains_Constant;
  Test_Statistics_AfterReset;
  Test_Memory_Accounting_Accuracy;
  Test_Capacity_Used_Relationship;

  WriteLn('');
  WriteLn('==============================');
  WriteLn(Format('Total: %d  Passed: %d  Failed: %d', [GTestCount, GPassCount, GFailCount]));

  if GFailCount = 0 then
  begin
    WriteLn('All tests PASSED!');
    Halt(0);
  end
  else
  begin
    WriteLn('Some tests FAILED!');
    Halt(1);
  end;
end.
