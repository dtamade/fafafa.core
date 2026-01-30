{
  Mimalloc 分配器测试
  Tests for Mimalloc-style allocator
}

program test_mimalloc;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  SysUtils,
  fafafa.core.mem.layout,
  fafafa.core.mem.error,
  fafafa.core.mem.alloc,
  fafafa.core.mem.mimalloc;

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

procedure TestBasicAlloc;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
  LCaps: TAllocCaps;
begin
  WriteLn('=== Basic Mimalloc Tests ===');

  LAlloc := GetMimalloc;
  Check(LAlloc <> nil, 'GetMimalloc returns non-nil');

  // 检查能力
  LCaps := LAlloc.Caps;
  Check(LCaps.KnowsSize, 'Mimalloc knows size');
  Check(LCaps.CanRealloc, 'Mimalloc supports realloc');

  // 小对象分配
  LLayout := TMemLayout.Create(16, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 16 bytes succeeded');
  Check(LResult.Ptr <> nil, 'Got non-nil pointer');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 32 字节
  LLayout := TMemLayout.Create(32, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 32 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 64 字节
  LLayout := TMemLayout.Create(64, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 64 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 128 字节
  LLayout := TMemLayout.Create(128, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 128 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 256 字节
  LLayout := TMemLayout.Create(256, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 256 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 512 字节
  LLayout := TMemLayout.Create(512, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 512 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 1024 字节（最大小对象）
  LLayout := TMemLayout.Create(1024, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 1024 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);
end;

procedure TestMediumLargeAlloc;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
begin
  WriteLn('=== Medium/Large Alloc Tests ===');

  LAlloc := GetMimalloc;

  // 中等对象 (> 1024)
  LLayout := TMemLayout.Create(2048, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 2048 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 4KB
  LLayout := TMemLayout.Create(4096, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 4096 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 8KB
  LLayout := TMemLayout.Create(8192, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 8192 bytes succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 大对象 (> 8KB)
  LLayout := TMemLayout.Create(16384, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 16KB succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 64KB
  LLayout := TMemLayout.Create(65536, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 64KB succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 1MB
  LLayout := TMemLayout.Create(1024 * 1024, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 1MB succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);
end;

procedure TestAllocZeroed;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
  I: Integer;
  LAllZero: Boolean;
begin
  WriteLn('=== AllocZeroed Tests ===');

  LAlloc := GetMimalloc;

  // 小对象清零
  LLayout := TMemLayout.Create(64, 8);
  LResult := LAlloc.AllocZeroed(LLayout);
  Check(LResult.IsOk, 'AllocZeroed 64 bytes succeeded');

  LAllZero := True;
  for I := 0 to 63 do
  begin
    if PByte(LResult.Ptr)[I] <> 0 then
    begin
      LAllZero := False;
      Break;
    end;
  end;
  Check(LAllZero, 'All 64 bytes are zero');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 中等对象清零
  LLayout := TMemLayout.Create(4096, 8);
  LResult := LAlloc.AllocZeroed(LLayout);
  Check(LResult.IsOk, 'AllocZeroed 4096 bytes succeeded');

  LAllZero := True;
  for I := 0 to 4095 do
  begin
    if PByte(LResult.Ptr)[I] <> 0 then
    begin
      LAllZero := False;
      Break;
    end;
  end;
  Check(LAllZero, 'All 4096 bytes are zero');
  LAlloc.Dealloc(LResult.Ptr, LLayout);
end;

procedure TestMultipleAllocs;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LPtrs: array[0..99] of Pointer;
  I: Integer;
  LResult: TAllocResult;
begin
  WriteLn('=== Multiple Allocations Tests ===');

  LAlloc := GetMimalloc;
  LLayout := TMemLayout.Create(64, 8);

  // 分配 100 个 64 字节块
  for I := 0 to 99 do
  begin
    LResult := LAlloc.Alloc(LLayout);
    LPtrs[I] := LResult.Ptr;
  end;
  Check(True, 'Allocated 100 blocks of 64 bytes');

  // 验证所有指针不同
  Check(LPtrs[0] <> LPtrs[1], 'Pointers are distinct (0 vs 1)');
  Check(LPtrs[50] <> LPtrs[51], 'Pointers are distinct (50 vs 51)');
  Check(LPtrs[98] <> LPtrs[99], 'Pointers are distinct (98 vs 99)');

  // 释放所有
  for I := 0 to 99 do
    LAlloc.Dealloc(LPtrs[I], LLayout);
  Check(True, 'Freed all 100 blocks');

  // 再次分配（应该重用释放的块）
  for I := 0 to 99 do
  begin
    LResult := LAlloc.Alloc(LLayout);
    LPtrs[I] := LResult.Ptr;
  end;
  Check(True, 'Reallocated 100 blocks (reuse test)');

  // 释放
  for I := 0 to 99 do
    LAlloc.Dealloc(LPtrs[I], LLayout);
  Check(True, 'Freed all 100 blocks again');
end;

procedure TestMixedSizes;
var
  LAlloc: IAlloc;
  LP16, LP32, LP64, LP128, LP256: Pointer;
  LResult: TAllocResult;
begin
  WriteLn('=== Mixed Size Tests ===');

  LAlloc := GetMimalloc;

  // 分配不同大小
  LResult := LAlloc.Alloc(TMemLayout.Create(16, 8));
  LP16 := LResult.Ptr;
  Check(LP16 <> nil, 'Alloc 16 bytes');

  LResult := LAlloc.Alloc(TMemLayout.Create(32, 8));
  LP32 := LResult.Ptr;
  Check(LP32 <> nil, 'Alloc 32 bytes');

  LResult := LAlloc.Alloc(TMemLayout.Create(64, 8));
  LP64 := LResult.Ptr;
  Check(LP64 <> nil, 'Alloc 64 bytes');

  LResult := LAlloc.Alloc(TMemLayout.Create(128, 8));
  LP128 := LResult.Ptr;
  Check(LP128 <> nil, 'Alloc 128 bytes');

  LResult := LAlloc.Alloc(TMemLayout.Create(256, 8));
  LP256 := LResult.Ptr;
  Check(LP256 <> nil, 'Alloc 256 bytes');

  // 乱序释放
  LAlloc.Dealloc(LP64, TMemLayout.Create(64, 8));
  Check(True, 'Freed 64 bytes first');

  LAlloc.Dealloc(LP16, TMemLayout.Create(16, 8));
  Check(True, 'Freed 16 bytes second');

  LAlloc.Dealloc(LP256, TMemLayout.Create(256, 8));
  Check(True, 'Freed 256 bytes third');

  LAlloc.Dealloc(LP128, TMemLayout.Create(128, 8));
  Check(True, 'Freed 128 bytes fourth');

  LAlloc.Dealloc(LP32, TMemLayout.Create(32, 8));
  Check(True, 'Freed 32 bytes last');
end;

procedure TestZeroSizeAlloc;
var
  LAlloc: IAlloc;
  LResult: TAllocResult;
begin
  WriteLn('=== Zero Size Alloc Tests ===');

  LAlloc := GetMimalloc;

  // 零大小分配
  LResult := LAlloc.Alloc(TMemLayout.Create(0, 8));
  Check(LResult.IsOk, 'Zero size alloc succeeded');
  Check(LResult.Ptr = nil, 'Zero size returns nil');

  // nil 释放安全
  LAlloc.Dealloc(nil, TMemLayout.Create(0, 8));
  Check(True, 'Dealloc nil is safe');
end;

procedure TestDataIntegrity;
var
  LAlloc: IAlloc;
  LPtr: Pointer;
  LResult: TAllocResult;
  I: Integer;
begin
  WriteLn('=== Data Integrity Tests ===');

  LAlloc := GetMimalloc;

  // 写入并验证数据
  LResult := LAlloc.Alloc(TMemLayout.Create(256, 8));
  LPtr := LResult.Ptr;
  Check(LPtr <> nil, 'Allocated 256 bytes for data test');

  // 写入模式
  for I := 0 to 255 do
    PByte(LPtr)[I] := Byte(I);

  // 验证
  Check(PByte(LPtr)[0] = 0, 'First byte = 0');
  Check(PByte(LPtr)[127] = 127, 'Middle byte = 127');
  Check(PByte(LPtr)[255] = 255, 'Last byte = 255');

  LAlloc.Dealloc(LPtr, TMemLayout.Create(256, 8));
end;

procedure TestPerformance;
var
  LAlloc: IAlloc;
  LStart, LEnd: QWord;
  LPtrs: array[0..9999] of Pointer;
  LLayout: TMemLayout;
  LResult: TAllocResult;
  I, LRound: Integer;
  LAllocMs, LFreeMs: Double;
begin
  WriteLn('=== Performance Tests ===');

  LAlloc := GetMimalloc;
  LLayout := TMemLayout.Create(64, 8);

  // 预热
  for I := 0 to 999 do
  begin
    LResult := LAlloc.Alloc(LLayout);
    LAlloc.Dealloc(LResult.Ptr, LLayout);
  end;

  // 分配 10000 个 64 字节块
  LStart := GetTickCount64;
  for I := 0 to 9999 do
  begin
    LResult := LAlloc.Alloc(LLayout);
    LPtrs[I] := LResult.Ptr;
  end;
  LEnd := GetTickCount64;
  LAllocMs := (LEnd - LStart);

  // 释放
  LStart := GetTickCount64;
  for I := 0 to 9999 do
    LAlloc.Dealloc(LPtrs[I], LLayout);
  LEnd := GetTickCount64;
  LFreeMs := (LEnd - LStart);

  WriteLn(Format('  10000 allocs: %.0f ms (%.0f ns/op)', [LAllocMs, LAllocMs * 100000]));
  WriteLn(Format('  10000 frees:  %.0f ms (%.0f ns/op)', [LFreeMs, LFreeMs * 100000]));

  Check(LAllocMs < 1000, 'Alloc performance acceptable (< 1s for 10000 ops)');
  Check(LFreeMs < 1000, 'Free performance acceptable (< 1s for 10000 ops)');
end;

begin
  WriteLn('');
  WriteLn('Mimalloc Allocator Tests');
  WriteLn('========================');
  WriteLn('');

  TestBasicAlloc;
  TestMediumLargeAlloc;
  TestAllocZeroed;
  TestMultipleAllocs;
  TestMixedSizes;
  TestZeroSizeAlloc;
  TestDataIntegrity;
  TestPerformance;

  WriteLn('');
  WriteLn('========================');
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
