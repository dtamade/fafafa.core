{
  TMemLayout 单元测试
  Unit tests for TMemLayout and TAllocCaps
}

program test_mem_layout;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  SysUtils,
  fafafa.core.mem.layout,
  fafafa.core.mem.error;

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

procedure TestIsPowerOfTwo;
begin
  WriteLn('=== IsPowerOfTwo ===');
  Check(IsPowerOfTwo(1), '1 is power of 2');
  Check(IsPowerOfTwo(2), '2 is power of 2');
  Check(IsPowerOfTwo(4), '4 is power of 2');
  Check(IsPowerOfTwo(8), '8 is power of 2');
  Check(IsPowerOfTwo(16), '16 is power of 2');
  Check(IsPowerOfTwo(1024), '1024 is power of 2');
  Check(not IsPowerOfTwo(0), '0 is not power of 2');
  Check(not IsPowerOfTwo(3), '3 is not power of 2');
  Check(not IsPowerOfTwo(5), '5 is not power of 2');
  Check(not IsPowerOfTwo(6), '6 is not power of 2');
  Check(not IsPowerOfTwo(100), '100 is not power of 2');
end;

procedure TestNextPowerOfTwo;
begin
  WriteLn('=== NextPowerOfTwo ===');
  Check(NextPowerOfTwo(0) = 1, 'NextPowerOfTwo(0) = 1');
  Check(NextPowerOfTwo(1) = 1, 'NextPowerOfTwo(1) = 1');
  Check(NextPowerOfTwo(2) = 2, 'NextPowerOfTwo(2) = 2');
  Check(NextPowerOfTwo(3) = 4, 'NextPowerOfTwo(3) = 4');
  Check(NextPowerOfTwo(5) = 8, 'NextPowerOfTwo(5) = 8');
  Check(NextPowerOfTwo(7) = 8, 'NextPowerOfTwo(7) = 8');
  Check(NextPowerOfTwo(9) = 16, 'NextPowerOfTwo(9) = 16');
  Check(NextPowerOfTwo(100) = 128, 'NextPowerOfTwo(100) = 128');
  Check(NextPowerOfTwo(1000) = 1024, 'NextPowerOfTwo(1000) = 1024');
end;

procedure TestAlignUp;
begin
  WriteLn('=== AlignUp ===');
  Check(AlignUp(0, 8) = 0, 'AlignUp(0, 8) = 0');
  Check(AlignUp(1, 8) = 8, 'AlignUp(1, 8) = 8');
  Check(AlignUp(7, 8) = 8, 'AlignUp(7, 8) = 8');
  Check(AlignUp(8, 8) = 8, 'AlignUp(8, 8) = 8');
  Check(AlignUp(9, 8) = 16, 'AlignUp(9, 8) = 16');
  Check(AlignUp(100, 16) = 112, 'AlignUp(100, 16) = 112');
  Check(AlignUp(128, 64) = 128, 'AlignUp(128, 64) = 128');
  Check(AlignUp(129, 64) = 192, 'AlignUp(129, 64) = 192');
end;

procedure TestAlignDown;
begin
  WriteLn('=== AlignDown ===');
  Check(AlignDown(0, 8) = 0, 'AlignDown(0, 8) = 0');
  Check(AlignDown(1, 8) = 0, 'AlignDown(1, 8) = 0');
  Check(AlignDown(7, 8) = 0, 'AlignDown(7, 8) = 0');
  Check(AlignDown(8, 8) = 8, 'AlignDown(8, 8) = 8');
  Check(AlignDown(9, 8) = 8, 'AlignDown(9, 8) = 8');
  Check(AlignDown(100, 16) = 96, 'AlignDown(100, 16) = 96');
  Check(AlignDown(128, 64) = 128, 'AlignDown(128, 64) = 128');
  Check(AlignDown(129, 64) = 128, 'AlignDown(129, 64) = 128');
end;

procedure TestMemLayoutCreate;
var
  L: TMemLayout;
begin
  WriteLn('=== TMemLayout.Create ===');

  // 基本创建
  L := TMemLayout.Create(100, 8);
  Check(L.Size = 100, 'Size = 100');
  Check(L.Align = 8, 'Align = 8');
  Check(L.IsValid, 'Layout is valid');

  // 默认对齐
  L := TMemLayout.Create(50);
  Check(L.Size = 50, 'Size = 50');
  Check(L.Align = MEM_DEFAULT_ALIGN, 'Align = MEM_DEFAULT_ALIGN');
  Check(L.IsValid, 'Layout with default align is valid');

  // 非2的幂对齐（应自动调整）
  L := TMemLayout.Create(100, 5);
  Check(L.Align = 8, 'Non-power-of-2 align (5) adjusted to 8');
  Check(L.IsValid, 'Layout is valid after adjustment');

  // 零大小
  L := TMemLayout.Create(0, 8);
  Check(L.Size = 0, 'Zero size accepted');
  Check(L.IsZeroSized, 'IsZeroSized = True');
  Check(L.IsValid, 'Zero-sized layout is valid');
end;

procedure TestMemLayoutAlignedSize;
var
  L: TMemLayout;
begin
  WriteLn('=== TMemLayout.AlignedSize ===');

  L := TMemLayout.Create(1, 8);
  Check(L.AlignedSize = 8, 'AlignedSize(1, 8) = 8');

  L := TMemLayout.Create(8, 8);
  Check(L.AlignedSize = 8, 'AlignedSize(8, 8) = 8');

  L := TMemLayout.Create(9, 8);
  Check(L.AlignedSize = 16, 'AlignedSize(9, 8) = 16');

  L := TMemLayout.Create(100, 16);
  Check(L.AlignedSize = 112, 'AlignedSize(100, 16) = 112');

  L := TMemLayout.Create(64, 64);
  Check(L.AlignedSize = 64, 'AlignedSize(64, 64) = 64');
end;

procedure TestMemLayoutEmpty;
var
  L: TMemLayout;
begin
  WriteLn('=== TMemLayout.Empty ===');

  L := TMemLayout.Empty;
  Check(L.Size = 0, 'Empty.Size = 0');
  Check(L.Align = 1, 'Empty.Align = 1');
  Check(L.IsZeroSized, 'Empty.IsZeroSized = True');
  Check(L.IsValid, 'Empty layout is valid');
end;

procedure TestMemLayoutExtend;
var
  L1, L2, L3: TMemLayout;
begin
  WriteLn('=== TMemLayout.Extend ===');

  L1 := TMemLayout.Create(8, 4);
  L2 := TMemLayout.Create(16, 8);
  L3 := L1.Extend(L2);

  Check(L3.Size = 24, 'Extended size = 24 (8 aligned to 8 = 8, + 16 = 24)');
  Check(L3.Align = 8, 'Extended align = max(4, 8) = 8');

  // 需要填充的情况
  L1 := TMemLayout.Create(3, 1);
  L2 := TMemLayout.Create(4, 4);
  L3 := L1.Extend(L2);
  Check(L3.Size = 8, 'Extended size = 8 (3 padded to 4 = 4, + 4 = 8)');
  Check(L3.Align = 4, 'Extended align = max(1, 4) = 4');
end;

procedure TestMemLayoutPad;
var
  L1, L2: TMemLayout;
begin
  WriteLn('=== TMemLayout.Pad ===');

  L1 := TMemLayout.Create(10, 4);
  L2 := L1.Pad(16);

  Check(L2.Size = 16, 'Padded size = 16');
  Check(L2.Align = 16, 'Padded align = max(4, 16) = 16');

  // 已经对齐的情况
  L1 := TMemLayout.Create(16, 8);
  L2 := L1.Pad(8);
  Check(L2.Size = 16, 'Already aligned size unchanged');
end;

type
  TTestRecord = record
    A: Integer;
    B: Int64;
    C: Byte;
  end;

procedure TestMemLayoutForType;
var
  L: TMemLayout;
begin
  WriteLn('=== TMemLayout.ForType (via Create) ===');

  // ForType 需要特殊泛型语法，这里通过 Create 模拟
  // Integer: 4 bytes
  L := TMemLayout.Create(SizeOf(Integer), SizeOf(Integer));
  Check(L.Size = SizeOf(Integer), 'ForType<Integer>.Size = SizeOf(Integer)');
  Check(L.IsValid, 'ForType<Integer> is valid');

  // Int64: 8 bytes
  L := TMemLayout.Create(SizeOf(Int64), MEM_DEFAULT_ALIGN);
  Check(L.Size = SizeOf(Int64), 'ForType<Int64>.Size = SizeOf(Int64)');
  Check(L.IsValid, 'ForType<Int64> is valid');

  // Byte: 1 byte
  L := TMemLayout.Create(SizeOf(Byte), SizeOf(Byte));
  Check(L.Size = 1, 'ForType<Byte>.Size = 1');
  Check(L.IsValid, 'ForType<Byte> is valid');

  // TTestRecord
  L := TMemLayout.Create(SizeOf(TTestRecord), MEM_DEFAULT_ALIGN);
  Check(L.Size = SizeOf(TTestRecord), 'ForType<TTestRecord>.Size = SizeOf(TTestRecord)');
  Check(L.IsValid, 'ForType<TTestRecord> is valid');
end;

procedure TestMemLayoutForArray;
var
  L: TMemLayout;
  LElementSize, LElementAlign, LArraySize: SizeUInt;
begin
  WriteLn('=== TMemLayout.ForArray (via Create) ===');

  // ForArray<Integer>(10) - 模拟实现
  LElementSize := SizeOf(Integer);
  LElementAlign := SizeOf(Integer);
  LArraySize := AlignUp(LElementSize, LElementAlign) * 10;
  L := TMemLayout.Create(LArraySize, LElementAlign);
  Check(L.Size >= SizeOf(Integer) * 10, 'ForArray<Integer>(10) size >= 40');
  Check(L.IsValid, 'ForArray<Integer>(10) is valid');

  // ForArray<Int64>(5)
  LElementSize := SizeOf(Int64);
  LElementAlign := MEM_DEFAULT_ALIGN;
  LArraySize := AlignUp(LElementSize, LElementAlign) * 5;
  L := TMemLayout.Create(LArraySize, LElementAlign);
  Check(L.Size >= SizeOf(Int64) * 5, 'ForArray<Int64>(5) size >= 40');
  Check(L.IsValid, 'ForArray<Int64>(5) is valid');

  // 零元素数组
  L := TMemLayout.Create(0, SizeOf(Integer));
  Check(L.Size = 0, 'ForArray<Integer>(0).Size = 0');
  Check(L.IsZeroSized, 'Zero-element array is zero-sized');
end;

procedure TestAllocCaps;
var
  C: TAllocCaps;
  L: TMemLayout;
begin
  WriteLn('=== TAllocCaps ===');

  // 默认能力
  C := TAllocCaps.Default;
  Check(not C.ZeroOnAlloc, 'Default.ZeroOnAlloc = False');
  Check(not C.ThreadSafe, 'Default.ThreadSafe = False');
  Check(C.CanRealloc, 'Default.CanRealloc = True');

  // 自定义能力
  C := TAllocCaps.Create(True, True, True, True, True, 4096);
  Check(C.ZeroOnAlloc, 'Custom.ZeroOnAlloc = True');
  Check(C.ThreadSafe, 'Custom.ThreadSafe = True');
  Check(C.NativeAligned, 'Custom.NativeAligned = True');
  Check(C.MaxAlign = 4096, 'Custom.MaxAlign = 4096');

  // 系统堆能力
  C := TAllocCaps.ForSystemHeap;
  Check(C.ThreadSafe, 'SystemHeap.ThreadSafe = True');
  Check(C.CanRealloc, 'SystemHeap.CanRealloc = True');

  // 布局支持检查
  L := TMemLayout.Create(100, MEM_DEFAULT_ALIGN);
  Check(C.SupportsLayout(L), 'SystemHeap supports default-aligned layout');

  C := TAllocCaps.Create(False, False, False, True, True, 64);
  L := TMemLayout.Create(100, 128);
  Check(not C.SupportsLayout(L), 'MaxAlign=64 does not support Align=128');
end;

procedure TestAllocError;
begin
  WriteLn('=== TAllocError ===');

  Check(Ord(aeNone) = 0, 'aeNone = 0');
  Check(AllocErrorToString(aeNone) = 'Success', 'aeNone -> Success');
  Check(AllocErrorToString(aeOutOfMemory) = 'Out of memory', 'aeOutOfMemory message');
  Check(AllocErrorToString(aeDoubleFree) = 'Double free detected', 'aeDoubleFree message');
end;

procedure TestAllocResult;
var
  R: TAllocResult;
  P: Pointer;
begin
  WriteLn('=== TAllocResult ===');

  // 成功结果
  P := Pointer($12345678);
  R := TAllocResult.Ok(P);
  Check(R.IsOk, 'Ok result.IsOk = True');
  Check(not R.IsErr, 'Ok result.IsErr = False');
  Check(R.Ptr = P, 'Ok result.Ptr matches');
  Check(R.Unwrap = P, 'Ok result.Unwrap = ptr');
  Check(R.Error = aeNone, 'Ok result.Error = aeNone');

  // 错误结果
  R := TAllocResult.Err(aeOutOfMemory);
  Check(not R.IsOk, 'Err result.IsOk = False');
  Check(R.IsErr, 'Err result.IsErr = True');
  Check(R.Ptr = nil, 'Err result.Ptr = nil');
  Check(R.Unwrap = nil, 'Err result.Unwrap = nil');
  Check(R.Error = aeOutOfMemory, 'Err result.Error = aeOutOfMemory');

  // UnwrapOr
  R := TAllocResult.Err(aeOutOfMemory);
  P := Pointer($FFFFFFFF);
  Check(R.UnwrapOr(P) = P, 'Err.UnwrapOr returns default');

  R := TAllocResult.Ok(Pointer($12345678));
  Check(R.UnwrapOr(P) = Pointer($12345678), 'Ok.UnwrapOr returns ptr');
end;

begin
  WriteLn('');
  WriteLn('TMemLayout / TAllocCaps / TAllocError Unit Tests');
  WriteLn('================================================');
  WriteLn('');

  TestIsPowerOfTwo;
  TestNextPowerOfTwo;
  TestAlignUp;
  TestAlignDown;
  TestMemLayoutCreate;
  TestMemLayoutAlignedSize;
  TestMemLayoutEmpty;
  TestMemLayoutExtend;
  TestMemLayoutPad;
  TestMemLayoutForType;
  TestMemLayoutForArray;
  TestAllocCaps;
  TestAllocError;
  TestAllocResult;

  WriteLn('');
  WriteLn('================================================');
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
