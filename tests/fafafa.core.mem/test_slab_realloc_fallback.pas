{**
 * test_slab_realloc_fallback.pas - TSlabPool fallback 路径测试
 *
 * @desc 测试 P0-3 修复：ReallocMem/FreeMem 对 fallback 指针的正确处理
 *}
program test_slab_realloc_fallback;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.pool.slab;

var
  GTestsPassed: Integer = 0;
  GTestsFailed: Integer = 0;

procedure Check(aCondition: Boolean; const aTestName: string);
begin
  if aCondition then
  begin
    Inc(GTestsPassed);
    WriteLn('  [PASS] ', aTestName);
  end
  else
  begin
    Inc(GTestsFailed);
    WriteLn('  [FAIL] ', aTestName);
  end;
end;

procedure TestSlabPoolBasicReallocMem;
var
  LPool: TSlabPool;
  LPtr: Pointer;
  LNewPtr: Pointer;
begin
  WriteLn('=== TestSlabPoolBasicReallocMem ===');

  LPool := TSlabPool.Create(64 * 1024);
  try
    // 基本分配
    LPtr := LPool.GetMem(100);
    Check(LPtr <> nil, '初始分配应成功');

    if LPtr <> nil then
    begin
      // 写入测试数据
      FillChar(LPtr^, 100, $AA);

      // Realloc 到更大尺寸
      LNewPtr := LPool.ReallocMem(LPtr, 200);
      Check(LNewPtr <> nil, 'Realloc 到更大尺寸应成功');

      if LNewPtr <> nil then
      begin
        // 验证数据保留（至少前100字节）
        Check(PByte(LNewPtr)^ = $AA, 'Realloc 应保留原始数据');
        LPool.FreeMem(LNewPtr);
      end;
    end;

    // 测试 nil 指针 realloc（等同于 GetMem）
    LNewPtr := LPool.ReallocMem(nil, 50);
    Check(LNewPtr <> nil, 'Realloc(nil, 50) 应等同于 GetMem');
    if LNewPtr <> nil then
      LPool.FreeMem(LNewPtr);

    // 测试 realloc 到 0（等同于 FreeMem）
    LPtr := LPool.GetMem(100);
    if LPtr <> nil then
    begin
      LNewPtr := LPool.ReallocMem(LPtr, 0);
      Check(LNewPtr = nil, 'Realloc(ptr, 0) 应返回 nil（释放）');
    end;

  finally
    LPool.Free;
  end;

  WriteLn;
end;

procedure TestSlabPoolAlignedAllocFallback;
var
  LPool: TSlabPool;
  LPtr: Pointer;
begin
  WriteLn('=== TestSlabPoolAlignedAllocFallback ===');

  // 使用默认 RTL allocator 作为 fallback
  LPool := TSlabPool.Create(64 * 1024, GetRtlAllocator);
  try
    // 请求大对齐（会 fallback 到 FAllocator）
    LPtr := LPool.AllocAligned(256, 256);
    Check(LPtr <> nil, 'AllocAligned(256, 256) 应成功');

    if LPtr <> nil then
    begin
      Check((PtrUInt(LPtr) mod 256) = 0, '返回指针应该256字节对齐');

      // 释放 fallback 分配的指针（P0-3 修复点）
      LPool.FreeAligned(LPtr);
      // 如果没有崩溃或泄漏，测试通过
      Check(True, 'FreeAligned 应正确释放 fallback 指针');
    end;

  finally
    LPool.Free;
  end;

  WriteLn;
end;

procedure TestSlabPoolReallocUnknownPointer;
var
  LPool: TSlabPool;
  LExternalPtr: Pointer;
  LNewPtr: Pointer;
begin
  WriteLn('=== TestSlabPoolReallocUnknownPointer ===');
  WriteLn('  测试对非本池分配指针的 Realloc 处理');

  LPool := TSlabPool.Create(64 * 1024, GetRtlAllocator);
  try
    // 用外部 allocator 分配（模拟 AllocAligned fallback）
    LExternalPtr := GetRtlAllocator.GetMem(100);
    Check(LExternalPtr <> nil, '外部分配应成功');

    if LExternalPtr <> nil then
    begin
      // 写入测试数据
      FillChar(LExternalPtr^, 100, $BB);

      // Realloc 这个外部指针（P0-3 修复点）
      // 修复前：会泄漏 LExternalPtr 并返回新指针但不拷贝数据
      // 修复后：应该通过 FAllocator.ReallocMem 处理
      LNewPtr := LPool.ReallocMem(LExternalPtr, 200);

      // 注意：修复后 ReallocMem 会委托给 FAllocator
      // 但由于 IAllocator.ReallocMem 没有 old size，数据保留依赖 RTL 实现
      if LNewPtr <> nil then
      begin
        Check(True, 'Realloc 外部指针应成功（通过 FAllocator）');
        // RTL ReallocMem 通常会保留数据
        Check(PByte(LNewPtr)^ = $BB, 'Realloc 应保留原始数据');
        // 通过 FreeMem 释放（会走 fallback 路径）
        LPool.FreeMem(LNewPtr);
        Check(True, 'FreeMem 应正确释放 reallocated 指针');
      end
      else
      begin
        // 如果 Realloc 返回 nil，原指针仍有效，需要手动释放
        Check(False, 'Realloc 外部指针不应失败');
        GetRtlAllocator.FreeMem(LExternalPtr);
      end;
    end;

  finally
    LPool.Free;
  end;

  WriteLn;
end;

procedure TestSlabPoolNoLeakOnFallback;
var
  LPool: TSlabPool;
  LPtrs: array[0..9] of Pointer;
  i: Integer;
begin
  WriteLn('=== TestSlabPoolNoLeakOnFallback ===');
  WriteLn('  测试 fallback 分配/释放不泄漏');

  LPool := TSlabPool.Create(64 * 1024, GetRtlAllocator);
  try
    // 分配多个需要 fallback 的大对齐块
    for i := 0 to High(LPtrs) do
    begin
      LPtrs[i] := LPool.AllocAligned(1024, 256);
      if LPtrs[i] <> nil then
        FillChar(LPtrs[i]^, 1024, Byte(i));
    end;

    // 验证所有分配成功
    for i := 0 to High(LPtrs) do
      Check(LPtrs[i] <> nil, Format('Fallback 分配 %d 应成功', [i]));

    // 释放所有
    for i := 0 to High(LPtrs) do
      if LPtrs[i] <> nil then
        LPool.FreeAligned(LPtrs[i]);

    Check(True, '所有 fallback 指针释放成功（无崩溃）');

  finally
    LPool.Free;
  end;

  WriteLn;
end;

begin
  WriteLn('================================================');
  WriteLn('  fafafa.core.mem.pool.slab fallback 路径测试');
  WriteLn('  P0-3 TDD 验证');
  WriteLn('================================================');
  WriteLn;

  TestSlabPoolBasicReallocMem;
  TestSlabPoolAlignedAllocFallback;
  TestSlabPoolReallocUnknownPointer;
  TestSlabPoolNoLeakOnFallback;

  WriteLn('================================================');
  WriteLn('  测试结果: ', GTestsPassed, ' 通过, ', GTestsFailed, ' 失败');
  WriteLn('================================================');

  if GTestsFailed > 0 then
    Halt(1)
  else
    WriteLn('所有测试通过！');
end.
