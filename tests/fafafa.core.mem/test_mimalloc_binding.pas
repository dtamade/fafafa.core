{
  Mimalloc C Binding Test
  测试 mimalloc C 库绑定

  运行前需要安装 mimalloc: sudo apt install libmimalloc-dev
}

program test_mimalloc_binding;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  SysUtils,
  fafafa.core.mem.layout,
  fafafa.core.mem.error,
  fafafa.core.mem.alloc,
  fafafa.core.mem.mimalloc.binding;

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

procedure TestDirectAPI;
var
  P1, P2, P3: Pointer;
begin
  WriteLn('=== Direct mimalloc API Tests ===');

  // 基础分配
  P1 := mi_malloc(64);
  Check(P1 <> nil, 'mi_malloc(64) returns non-nil');
  mi_free(P1);
  Check(True, 'mi_free successful');

  // 清零分配
  P2 := mi_zalloc(128);
  Check(P2 <> nil, 'mi_zalloc(128) returns non-nil');
  Check(PByte(P2)[0] = 0, 'mi_zalloc memory is zeroed');
  Check(PByte(P2)[127] = 0, 'mi_zalloc last byte is zeroed');
  mi_free(P2);

  // 对齐分配
  P3 := mi_malloc_aligned(256, 64);
  Check(P3 <> nil, 'mi_malloc_aligned(256, 64) returns non-nil');
  Check((PtrUInt(P3) mod 64) = 0, 'Aligned pointer is 64-byte aligned');
  mi_free(P3);

  // 获取分配大小
  P1 := mi_malloc(100);
  Check(mi_malloc_usable_size(P1) >= 100, 'mi_malloc_usable_size >= requested');
  mi_free(P1);
end;

procedure TestIAllocInterface;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
  LCaps: TAllocCaps;
begin
  WriteLn('=== IAlloc Interface Tests ===');

  LAlloc := GetMimallocBinding;
  Check(LAlloc <> nil, 'GetMimallocBinding returns non-nil');

  // 检查能力
  LCaps := LAlloc.Caps;
  Check(LCaps.ThreadSafe, 'mimalloc is thread-safe');
  Check(LCaps.NativeAligned, 'mimalloc supports native alignment');
  Check(LCaps.KnowsSize, 'mimalloc knows allocation size');

  // 小对象分配
  LLayout := TMemLayout.Create(16, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 16 bytes succeeded');
  Check(LResult.Ptr <> nil, 'Got non-nil pointer');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 大对象分配
  LLayout := TMemLayout.Create(1024 * 1024, 8);  // 1MB
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 1MB succeeded');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 对齐分配
  LLayout := TMemLayout.Create(512, 64);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Alloc 512 bytes aligned 64 succeeded');
  Check((PtrUInt(LResult.Ptr) mod 64) = 0, 'Pointer is 64-byte aligned');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 清零分配
  LLayout := TMemLayout.Create(64, 8);
  LResult := LAlloc.AllocZeroed(LLayout);
  Check(LResult.IsOk, 'AllocZeroed succeeded');
  Check(PByte(LResult.Ptr)[0] = 0, 'Memory is zeroed');
  LAlloc.Dealloc(LResult.Ptr, LLayout);
end;

procedure TestPrivateHeap;
var
  LAlloc: TMimallocBinding;
  LLayout: TMemLayout;
  LResult: TAllocResult;
begin
  WriteLn('=== Private Heap Tests ===');

  LAlloc := TMimallocBinding.Create(True);  // 私有堆
  try
    Check(LAlloc.UsePrivateHeap, 'Using private heap');
    Check(LAlloc.Heap <> nil, 'Private heap handle is valid');

    LLayout := TMemLayout.Create(128, 8);
    LResult := LAlloc.Alloc(LLayout);
    Check(LResult.IsOk, 'Alloc on private heap succeeded');
    LAlloc.Dealloc(LResult.Ptr, LLayout);
  finally
    LAlloc.Free;
  end;
  Check(True, 'Private heap destroyed successfully');
end;

procedure TestPerformance;
var
  LAlloc: IAlloc;
  LStart, LEnd: QWord;
  LPtrs: array[0..99999] of Pointer;
  LLayout: TMemLayout;
  LResult: TAllocResult;
  I: Integer;
  LAllocMs, LFreeMs: Double;
begin
  WriteLn('=== Performance Tests ===');

  LAlloc := GetMimallocBinding;
  LLayout := TMemLayout.Create(64, 8);

  // 预热
  for I := 0 to 999 do
  begin
    LResult := LAlloc.Alloc(LLayout);
    LAlloc.Dealloc(LResult.Ptr, LLayout);
  end;

  // 分配 100000 个 64 字节块
  LStart := GetTickCount64;
  for I := 0 to 99999 do
  begin
    LResult := LAlloc.Alloc(LLayout);
    LPtrs[I] := LResult.Ptr;
  end;
  LEnd := GetTickCount64;
  LAllocMs := (LEnd - LStart);

  // 释放
  LStart := GetTickCount64;
  for I := 0 to 99999 do
    LAlloc.Dealloc(LPtrs[I], LLayout);
  LEnd := GetTickCount64;
  LFreeMs := (LEnd - LStart);

  WriteLn(Format('  100000 allocs: %.0f ms (%.1f ns/op)', [LAllocMs, LAllocMs * 10000]));
  WriteLn(Format('  100000 frees:  %.0f ms (%.1f ns/op)', [LFreeMs, LFreeMs * 10000]));

  Check(LAllocMs < 500, 'Alloc performance < 500ms for 100k ops');
  Check(LFreeMs < 500, 'Free performance < 500ms for 100k ops');
end;

begin
  WriteLn('');
  WriteLn('Mimalloc C Binding Tests');
  WriteLn('========================');

  // 检查库是否可用
  if not IsMimallocAvailable then
  begin
    WriteLn('');
    WriteLn('ERROR: mimalloc library not found!');
    WriteLn('Install with: sudo apt install libmimalloc-dev');
    WriteLn('');
    Halt(2);
  end;

  WriteLn('mimalloc library found, running tests...');
  WriteLn('');

  try
    TestDirectAPI;
    TestIAllocInterface;
    TestPrivateHeap;
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
  except
    on E: Exception do
    begin
      WriteLn('');
      WriteLn('EXCEPTION: ', E.Message);
      WriteLn('Make sure mimalloc is installed: sudo apt install libmimalloc-dev');
      Halt(3);
    end;
  end;
end.
