{
  Extended Memory Boundary and Error Handling Tests
  测试 fafafa.core.mem 的边界和错误处理

  这个测试文件补充了 test_mem_utils_extended.pas 中缺失的边界测试：
  - 空指针处理 (3个测试)
  - 零大小处理 (3个测试)
  - 大数值边界 (2个测试)
  - 对齐边界 (2个测试)
}

program test_mem_boundary_extended;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem,
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
  P2.2.1: 空指针处理 (3个测试)
  注意：根据 API 设计，某些函数不检查 nil 指针以提升性能
-----------------------------------------------------------------------------}

procedure Test_Copy_NilSrc_Behavior;
var
  LAlloc: IAllocator;
  LDst: Pointer;
begin
  WriteLn('=== Test_Copy_NilSrc_Behavior ===');
  LAlloc := GetRtlAllocator;
  LDst := LAlloc.GetMem(100);
  try
    // Copy with nil source - behavior is undefined but should not crash
    // Note: This tests the actual behavior, not the expected behavior
    try
      Copy(nil, LDst, 0);  // Zero size should be safe
      Check(True, 'Copy(nil, dst, 0) should not crash');
    except
      Check(False, 'Copy(nil, dst, 0) raised exception');
    end;
  finally
    LAlloc.FreeMem(LDst);
  end;
end;

procedure Test_Fill_NilDst_Behavior;
begin
  WriteLn('=== Test_Fill_NilDst_Behavior ===');

  // Fill with nil destination - behavior is undefined but should not crash with zero size
  try
    Fill(nil, 0, $AA);  // Zero size should be safe
    Check(True, 'Fill(nil, 0, value) should not crash');
  except
    Check(False, 'Fill(nil, 0, value) raised exception');
  end;
end;

procedure Test_Compare_NilPtr_Behavior;
var
  LAlloc: IAllocator;
  LPtr: Pointer;
begin
  WriteLn('=== Test_Compare_NilPtr_Behavior ===');
  LAlloc := GetRtlAllocator;
  LPtr := LAlloc.GetMem(100);
  try
    // Compare with nil pointer - behavior is undefined but should not crash with zero size
    try
      Compare(nil, LPtr, 0);  // Zero size should be safe
      Check(True, 'Compare(nil, ptr, 0) should not crash');
    except
      Check(False, 'Compare(nil, ptr, 0) raised exception');
    end;
  finally
    LAlloc.FreeMem(LPtr);
  end;
end;

{-----------------------------------------------------------------------------
  P2.2.2: 零大小处理 (3个测试)
-----------------------------------------------------------------------------}

procedure Test_Copy_ZeroSize_NoOp;
var
  LAlloc: IAllocator;
  LSrc, LDst: Pointer;
begin
  WriteLn('=== Test_Copy_ZeroSize_NoOp ===');
  LAlloc := GetRtlAllocator;

  LSrc := LAlloc.GetMem(100);
  LDst := LAlloc.GetMem(100);
  try
    // Fill destination with known pattern
    Fill(LDst, 100, $FF);

    // Copy zero bytes
    Copy(LSrc, LDst, 0);

    // Verify destination unchanged
    Check(PByte(LDst)[0] = $FF, 'Zero-size copy should not modify destination');
    Check(PByte(LDst)[99] = $FF, 'Zero-size copy should not modify destination');
  finally
    LAlloc.FreeMem(LSrc);
    LAlloc.FreeMem(LDst);
  end;
end;

procedure Test_Fill_ZeroCount_NoOp;
var
  LAlloc: IAllocator;
  LPtr: Pointer;
begin
  WriteLn('=== Test_Fill_ZeroCount_NoOp ===');
  LAlloc := GetRtlAllocator;
  LPtr := LAlloc.GetMem(100);
  try
    // Fill with known pattern
    Fill(LPtr, 100, $AA);

    // Fill zero bytes
    Fill(LPtr, 0, $BB);

    // Verify unchanged
    Check(PByte(LPtr)[0] = $AA, 'Zero-count fill should not modify memory');
    Check(PByte(LPtr)[99] = $AA, 'Zero-count fill should not modify memory');
  finally
    LAlloc.FreeMem(LPtr);
  end;
end;

procedure Test_Compare_ZeroCount_ReturnsZero;
var
  LAlloc: IAllocator;
  LPtr1, LPtr2: Pointer;
  LResult: Integer;
begin
  WriteLn('=== Test_Compare_ZeroCount_ReturnsZero ===');
  LAlloc := GetRtlAllocator;

  LPtr1 := LAlloc.GetMem(100);
  LPtr2 := LAlloc.GetMem(100);
  try
    // Fill with different patterns
    Fill(LPtr1, 100, $AA);
    Fill(LPtr2, 100, $BB);

    // Compare zero bytes
    LResult := Compare(LPtr1, LPtr2, 0);

    Check(LResult = 0, 'Zero-count compare should return 0');
  finally
    LAlloc.FreeMem(LPtr1);
    LAlloc.FreeMem(LPtr2);
  end;
end;

{-----------------------------------------------------------------------------
  P2.2.3: 大数值边界 (2个测试)
-----------------------------------------------------------------------------}

procedure Test_Copy_LargeSize_Success;
var
  LAlloc: IAllocator;
  LSrc, LDst: Pointer;
  LSize: SizeUInt;
  I: Integer;
  LMatch: Boolean;
begin
  WriteLn('=== Test_Copy_LargeSize_Success ===');
  LAlloc := GetRtlAllocator;

  // Test with 1MB
  LSize := 1024 * 1024;
  LSrc := LAlloc.GetMem(LSize);
  LDst := LAlloc.GetMem(LSize);
  try
    // Fill source with pattern
    for I := 0 to (LSize div 4) - 1 do
      PUInt32(LSrc)[I] := UInt32(I);

    // Copy
    Copy(LSrc, LDst, LSize);

    // Verify
    LMatch := True;
    for I := 0 to (LSize div 4) - 1 do
    begin
      if PUInt32(LDst)[I] <> UInt32(I) then
      begin
        LMatch := False;
        Break;
      end;
    end;

    Check(LMatch, 'Large copy (1MB) should succeed');
  finally
    LAlloc.FreeMem(LSrc);
    LAlloc.FreeMem(LDst);
  end;
end;

procedure Test_Fill_LargeCount_Success;
var
  LAlloc: IAllocator;
  LPtr: Pointer;
  LSize: SizeUInt;
  I: Integer;
  LAllMatch: Boolean;
begin
  WriteLn('=== Test_Fill_LargeCount_Success ===');
  LAlloc := GetRtlAllocator;

  // Test with 1MB
  LSize := 1024 * 1024;
  LPtr := LAlloc.GetMem(LSize);
  try
    // Fill
    Fill(LPtr, LSize, $CC);

    // Verify
    LAllMatch := True;
    for I := 0 to LSize - 1 do
    begin
      if PByte(LPtr)[I] <> $CC then
      begin
        LAllMatch := False;
        Break;
      end;
    end;

    Check(LAllMatch, 'Large fill (1MB) should succeed');
  finally
    LAlloc.FreeMem(LPtr);
  end;
end;

{-----------------------------------------------------------------------------
  P2.2.4: 对齐边界 (2个测试)
-----------------------------------------------------------------------------}

procedure Test_AlignUp_MaxAlignment_Correct;
var
  LPtr: Pointer;
  LAligned: Pointer;
begin
  WriteLn('=== Test_AlignUp_MaxAlignment_Correct ===');

  // Test with large alignment (4096 bytes = page size)
  LPtr := Pointer(1);
  LAligned := AlignUp(LPtr, 4096);
  Check(PtrUInt(LAligned) = 4096, 'AlignUp(1, 4096) should be 4096');

  LPtr := Pointer(4095);
  LAligned := AlignUp(LPtr, 4096);
  Check(PtrUInt(LAligned) = 4096, 'AlignUp(4095, 4096) should be 4096');

  LPtr := Pointer(4096);
  LAligned := AlignUp(LPtr, 4096);
  Check(PtrUInt(LAligned) = 4096, 'AlignUp(4096, 4096) should be 4096');

  LPtr := Pointer(4097);
  LAligned := AlignUp(LPtr, 4096);
  Check(PtrUInt(LAligned) = 8192, 'AlignUp(4097, 4096) should be 8192');
end;

procedure Test_IsAligned_PowerOfTwo_Correct;
var
  LAlloc: IAllocator;
  LPtr: Pointer;
begin
  WriteLn('=== Test_IsAligned_PowerOfTwo_Correct ===');
  LAlloc := GetRtlAllocator;
  LPtr := LAlloc.GetMem(256);
  try
    // Test various power-of-two alignments
    Check(IsAligned(LPtr, 1), 'Any pointer should be 1-byte aligned');

    // Test aligned pointers
    Check(IsAligned(Pointer(0), 1), 'Pointer(0) should be 1-byte aligned');
    Check(IsAligned(Pointer(0), 2), 'Pointer(0) should be 2-byte aligned');
    Check(IsAligned(Pointer(0), 4), 'Pointer(0) should be 4-byte aligned');
    Check(IsAligned(Pointer(0), 8), 'Pointer(0) should be 8-byte aligned');

    Check(IsAligned(Pointer(8), 8), 'Pointer(8) should be 8-byte aligned');
    Check(not IsAligned(Pointer(9), 8), 'Pointer(9) should not be 8-byte aligned');

    Check(IsAligned(Pointer(16), 16), 'Pointer(16) should be 16-byte aligned');
    Check(not IsAligned(Pointer(17), 16), 'Pointer(17) should not be 16-byte aligned');
  finally
    LAlloc.FreeMem(LPtr);
  end;
end;

{-----------------------------------------------------------------------------
  Main
-----------------------------------------------------------------------------}

begin
  WriteLn('');
  WriteLn('Extended Memory Boundary and Error Handling Tests');
  WriteLn('==================================================');
  WriteLn('');

  // P2.2.1: 空指针处理 (3个测试)
  Test_Copy_NilSrc_Behavior;
  Test_Fill_NilDst_Behavior;
  Test_Compare_NilPtr_Behavior;

  // P2.2.2: 零大小处理 (3个测试)
  Test_Copy_ZeroSize_NoOp;
  Test_Fill_ZeroCount_NoOp;
  Test_Compare_ZeroCount_ReturnsZero;

  // P2.2.3: 大数值边界 (2个测试)
  Test_Copy_LargeSize_Success;
  Test_Fill_LargeCount_Success;

  // P2.2.4: 对齐边界 (2个测试)
  Test_AlignUp_MaxAlignment_Correct;
  Test_IsAligned_PowerOfTwo_Correct;

  WriteLn('');
  WriteLn('==================================================');
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
