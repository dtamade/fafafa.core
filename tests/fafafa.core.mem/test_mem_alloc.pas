{
  fafafa.core.mem 新接口集成测试
  Integration tests for new mem interfaces
}

program test_mem_alloc;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  SysUtils,
  fafafa.core.mem.layout,
  fafafa.core.mem.error,
  fafafa.core.mem.alloc,
  fafafa.core.mem.blockpool;

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

procedure TestSystemAlloc;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
  LCaps: TAllocCaps;
begin
  WriteLn('=== TSystemAlloc ===');

  LAlloc := GetSystemAlloc;
  Check(LAlloc <> nil, 'GetSystemAlloc returns non-nil');

  // 检查能力
  LCaps := LAlloc.Caps;
  Check(LCaps.ThreadSafe, 'SystemAlloc is thread-safe');
  Check(LCaps.CanRealloc, 'SystemAlloc supports realloc');

  // 基本分配
  LLayout := TMemLayout.Create(1024, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 1024 bytes succeeded');
  Check(LResult.Ptr <> nil, 'Alloc returned non-nil pointer');

  // 释放
  LAlloc.Dealloc(LResult.Ptr, LLayout);
  Check(True, 'Dealloc completed');

  // 清零分配
  LLayout := TMemLayout.Create(256, 8);
  LResult := LAlloc.AllocZeroed(LLayout);
  Check(LResult.IsOk, 'AllocZeroed succeeded');
  if LResult.IsOk then
  begin
    // 检查前几个字节是否为零
    Check(PByte(LResult.Ptr)^ = 0, 'First byte is zero');
    Check(PByte(LResult.Ptr)[128] = 0, 'Middle byte is zero');
    Check(PByte(LResult.Ptr)[255] = 0, 'Last byte is zero');
    LAlloc.Dealloc(LResult.Ptr, LLayout);
  end;

  // 零大小分配
  LLayout := TMemLayout.Create(0, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Zero-size alloc succeeded');
  Check(LResult.Ptr = nil, 'Zero-size returns nil');
end;

procedure TestAlignedAlloc;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
  LCaps: TAllocCaps;
begin
  WriteLn('=== TAlignedAlloc ===');

  LAlloc := GetAlignedAlloc;
  Check(LAlloc <> nil, 'GetAlignedAlloc returns non-nil');

  // 检查能力
  LCaps := LAlloc.Caps;
  Check(LCaps.NativeAligned, 'AlignedAlloc supports native alignment');

  // 16字节对齐
  LLayout := TMemLayout.Create(100, 16);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc with 16-byte align succeeded');
  Check((PtrUInt(LResult.Ptr) mod 16) = 0, 'Pointer is 16-byte aligned');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 64字节对齐（缓存行）
  LLayout := TMemLayout.Create(256, 64);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc with 64-byte align succeeded');
  Check((PtrUInt(LResult.Ptr) mod 64) = 0, 'Pointer is 64-byte aligned');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 256字节对齐
  LLayout := TMemLayout.Create(1024, 256);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc with 256-byte align succeeded');
  Check((PtrUInt(LResult.Ptr) mod 256) = 0, 'Pointer is 256-byte aligned');
  LAlloc.Dealloc(LResult.Ptr, LLayout);
end;

procedure TestRealloc;
var
  LAlloc: IAlloc;
  LLayout1, LLayout2: TMemLayout;
  LResult: TAllocResult;
  LPtr: Pointer;
  I: Integer;
begin
  WriteLn('=== Realloc ===');

  LAlloc := GetSystemAlloc;

  // 分配并填充数据
  LLayout1 := TMemLayout.Create(100, 8);
  LResult := LAlloc.Alloc(LLayout1);
  Check(LResult.IsOk, 'Initial alloc succeeded');
  LPtr := LResult.Ptr;

  // 填充数据
  for I := 0 to 99 do
    PByte(LPtr)[I] := Byte(I);

  // 扩大
  LLayout2 := TMemLayout.Create(200, 8);
  LResult := LAlloc.Realloc(LPtr, LLayout1, LLayout2);
  Check(LResult.IsOk, 'Realloc to larger size succeeded');

  // 检查数据保留
  Check(PByte(LResult.Ptr)[0] = 0, 'First byte preserved');
  Check(PByte(LResult.Ptr)[50] = 50, 'Middle byte preserved');
  Check(PByte(LResult.Ptr)[99] = 99, 'Last original byte preserved');

  LAlloc.Dealloc(LResult.Ptr, LLayout2);

  // nil 指针 Realloc = Alloc
  LResult := LAlloc.Realloc(nil, TMemLayout.Empty, LLayout1);
  Check(LResult.IsOk, 'Realloc nil = Alloc');
  Check(LResult.Ptr <> nil, 'Realloc nil returns non-nil');
  LAlloc.Dealloc(LResult.Ptr, LLayout1);

  // 零大小 Realloc = Dealloc
  LResult := LAlloc.Alloc(LLayout1);
  LPtr := LResult.Ptr;
  LResult := LAlloc.Realloc(LPtr, LLayout1, TMemLayout.Create(0, 8));
  Check(LResult.IsOk, 'Realloc to zero size succeeded');
  Check(LResult.Ptr = nil, 'Realloc to zero returns nil');
end;

procedure TestSimpleBlockPool;
var
  LPool: IBlockPool;
  LP1, LP2, LP3: Pointer;
begin
  WriteLn('=== TSimpleBlockPool ===');

  LPool := TSimpleBlockPool.Create(64, 10);
  Check(LPool.BlockSize = 64, 'BlockSize = 64');
  Check(LPool.Capacity = 10, 'Capacity = 10');
  Check(LPool.Available = 10, 'Initially all available');
  Check(LPool.InUse = 0, 'Initially none in use');

  // 分配
  LP1 := LPool.Acquire;
  Check(LP1 <> nil, 'First acquire succeeded');
  Check(LPool.Available = 9, 'Available = 9 after first acquire');
  Check(LPool.InUse = 1, 'InUse = 1 after first acquire');

  LP2 := LPool.Acquire;
  Check(LP2 <> nil, 'Second acquire succeeded');
  Check(LP2 <> LP1, 'Different pointers');

  LP3 := LPool.Acquire;
  Check(LP3 <> nil, 'Third acquire succeeded');
  Check(LPool.Available = 7, 'Available = 7 after three acquires');

  // 释放
  LPool.Release(LP2);
  Check(LPool.Available = 8, 'Available = 8 after release');

  // 重新分配应该重用 LP2
  LP2 := LPool.Acquire;
  Check(LP2 <> nil, 'Re-acquire succeeded');
  Check(LPool.Available = 7, 'Available back to 7');

  // 释放所有
  LPool.Release(LP1);
  LPool.Release(LP2);
  LPool.Release(LP3);
  Check(LPool.Available = 10, 'All released');

  // 重置
  LP1 := LPool.Acquire;
  LP2 := LPool.Acquire;
  LPool.Reset;
  Check(LPool.Available = 10, 'Reset restores all');

  // nil 释放安全
  LPool.Release(nil);
  Check(True, 'Release nil is safe');
end;

procedure TestBlockPoolExhaustion;
var
  LPool: IBlockPool;
  LPtrs: array[0..9] of Pointer;
  I: Integer;
  LP: Pointer;
begin
  WriteLn('=== BlockPool Exhaustion ===');

  LPool := TSimpleBlockPool.Create(32, 10);

  // 分配所有
  for I := 0 to 9 do
  begin
    LPtrs[I] := LPool.Acquire;
    Check(LPtrs[I] <> nil, Format('Acquire %d succeeded', [I]));
  end;

  Check(LPool.Available = 0, 'Pool exhausted');

  // 尝试再分配应该失败
  LP := LPool.Acquire;
  Check(LP = nil, 'Acquire from exhausted pool returns nil');

  // TryAcquire 应该返回 False
  Check(not LPool.TryAcquire(LP), 'TryAcquire returns False when exhausted');

  // 释放一个后应该可以分配
  LPool.Release(LPtrs[5]);
  Check(LPool.Available = 1, 'One available after release');

  LP := LPool.Acquire;
  Check(LP <> nil, 'Can acquire after release');

  // 清理
  LPool.Reset;
end;

procedure TestSimpleArena;
var
  LArena: IArena;
  LResult: TAllocResult;
  LP1, LP2, LP3: Pointer;
  LMark: TArenaMarker;
begin
  WriteLn('=== TSimpleArena ===');

  LArena := TSimpleArena.Create(4096);
  Check(LArena.TotalSize = 4096, 'TotalSize = 4096');
  Check(LArena.UsedSize = 0, 'Initially UsedSize = 0');
  Check(LArena.RemainingSize = 4096, 'Initially RemainingSize = 4096');

  // 分配
  LResult := LArena.Alloc(TMemLayout.Create(100, 8));
  Check(LResult.IsOk, 'First alloc succeeded');
  LP1 := LResult.Ptr;
  Check(LP1 <> nil, 'Got non-nil pointer');
  Check(LArena.UsedSize >= 100, 'UsedSize >= 100');

  // 第二个分配
  LResult := LArena.Alloc(TMemLayout.Create(200, 16));
  Check(LResult.IsOk, 'Second alloc succeeded');
  LP2 := LResult.Ptr;
  Check((PtrUInt(LP2) mod 16) = 0, 'Second pointer is 16-byte aligned');
  Check(PtrUInt(LP2) > PtrUInt(LP1), 'Second pointer after first');

  // 保存标记
  LMark := LArena.SaveMark;
  Check(LMark > 0, 'Mark > 0');

  // 第三个分配
  LResult := LArena.Alloc(TMemLayout.Create(300, 8));
  Check(LResult.IsOk, 'Third alloc succeeded');
  LP3 := LResult.Ptr;

  // 恢复到标记
  LArena.RestoreToMark(LMark);
  Check(LArena.UsedSize < LArena.TotalSize, 'UsedSize reduced after restore');

  // 再分配应该重用空间
  LResult := LArena.Alloc(TMemLayout.Create(50, 8));
  Check(LResult.IsOk, 'Alloc after restore succeeded');

  // 重置
  LArena.Reset;
  Check(LArena.UsedSize = 0, 'UsedSize = 0 after reset');
  Check(LArena.RemainingSize = 4096, 'RemainingSize = 4096 after reset');
end;

procedure TestArenaExhaustion;
var
  LArena: IArena;
  LResult: TAllocResult;
begin
  WriteLn('=== Arena Exhaustion ===');

  LArena := TSimpleArena.Create(1024);

  // 分配接近满
  LResult := LArena.Alloc(TMemLayout.Create(900, 8));
  Check(LResult.IsOk, 'Large alloc succeeded');

  // 尝试分配超出剩余空间
  LResult := LArena.Alloc(TMemLayout.Create(200, 8));
  Check(LResult.IsErr, 'Alloc beyond capacity fails');
  Check(LResult.Error = aeOutOfMemory, 'Error is OutOfMemory');

  // 重置后可以重新分配
  LArena.Reset;
  LResult := LArena.Alloc(TMemLayout.Create(1000, 8));
  Check(LResult.IsOk, 'Large alloc after reset succeeded');
end;

procedure TestAllocZeroed;
var
  LArena: IArena;
  LResult: TAllocResult;
  I: Integer;
  LAllZero: Boolean;
begin
  WriteLn('=== AllocZeroed ===');

  LArena := TSimpleArena.Create(4096);

  // 先分配并填充非零数据
  LResult := LArena.Alloc(TMemLayout.Create(256, 8));
  FillChar(LResult.Ptr^, 256, $FF);

  // 重置
  LArena.Reset;

  // AllocZeroed 应该清零
  LResult := LArena.AllocZeroed(TMemLayout.Create(256, 8));
  Check(LResult.IsOk, 'AllocZeroed succeeded');

  LAllZero := True;
  for I := 0 to 255 do
  begin
    if PByte(LResult.Ptr)[I] <> 0 then
    begin
      LAllZero := False;
      Break;
    end;
  end;
  Check(LAllZero, 'All bytes are zero');
end;

begin
  WriteLn('');
  WriteLn('fafafa.core.mem New Interface Tests');
  WriteLn('====================================');
  WriteLn('');

  TestSystemAlloc;
  TestAlignedAlloc;
  TestRealloc;
  TestSimpleBlockPool;
  TestBlockPoolExhaustion;
  TestSimpleArena;
  TestArenaExhaustion;
  TestAllocZeroed;

  WriteLn('');
  WriteLn('====================================');
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
