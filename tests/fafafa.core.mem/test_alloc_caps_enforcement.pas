{**
 * test_alloc_caps_enforcement.pas - TAllocCaps 强约束测试
 *
 * @desc 测试 P0-4 修复：分配器入口对 Caps 的强制检查
 *}
program test_alloc_caps_enforcement;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.layout,
  fafafa.core.mem.error,
  fafafa.core.mem.alloc;

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

procedure TestSystemAllocAlignmentRestriction;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
begin
  WriteLn('=== TestSystemAllocAlignmentRestriction ===');
  WriteLn('  SystemAlloc 只支持默认对齐（指针大小）');

  LAlloc := GetSystemAlloc;

  // 默认对齐应该成功
  LLayout := TMemLayout.Create(100, MEM_DEFAULT_ALIGN);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, '默认对齐分配应成功');
  if LResult.IsOk then
    LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 更小的对齐也应该成功
  LLayout := TMemLayout.Create(100, 1);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, '1字节对齐分配应成功');
  if LResult.IsOk then
    LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 超过默认对齐应该返回 aeAlignmentNotSupported（而不是 aeOutOfMemory）
  LLayout := TMemLayout.Create(100, 64);  // 64 > MEM_DEFAULT_ALIGN(8)
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsErr, '超大对齐分配应失败');
  Check(LResult.Error = aeAlignmentNotSupported,
        '错误类型应是 aeAlignmentNotSupported（不是 aeOutOfMemory）');

  LLayout := TMemLayout.Create(100, 4096);  // 页面对齐
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.Error = aeAlignmentNotSupported,
        '页面对齐应返回 aeAlignmentNotSupported');

  WriteLn;
end;

procedure TestAlignedAllocSupportsLargeAlignment;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
begin
  WriteLn('=== TestAlignedAllocSupportsLargeAlignment ===');
  WriteLn('  AlignedAlloc 支持更大的对齐');

  LAlloc := GetAlignedAlloc;

  // 64 字节对齐（缓存行）
  LLayout := TMemLayout.Create(100, 64);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, '64字节对齐分配应成功');
  if LResult.IsOk then
  begin
    Check((PtrUInt(LResult.Ptr) mod 64) = 0, '返回指针应该64字节对齐');
    LAlloc.Dealloc(LResult.Ptr, LLayout);
  end;

  // 256 字节对齐
  LLayout := TMemLayout.Create(100, 256);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, '256字节对齐分配应成功');
  if LResult.IsOk then
  begin
    Check((PtrUInt(LResult.Ptr) mod 256) = 0, '返回指针应该256字节对齐');
    LAlloc.Dealloc(LResult.Ptr, LLayout);
  end;

  // 4096 字节对齐（页面）
  LLayout := TMemLayout.Create(4096, 4096);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, '页面对齐分配应成功');
  if LResult.IsOk then
  begin
    Check((PtrUInt(LResult.Ptr) mod 4096) = 0, '返回指针应该页面对齐');
    LAlloc.Dealloc(LResult.Ptr, LLayout);
  end;

  WriteLn;
end;

procedure TestInvalidLayoutRejection;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
begin
  WriteLn('=== TestInvalidLayoutRejection ===');

  LAlloc := GetSystemAlloc;

  // 无效对齐（0 - 会被转换为默认对齐，所以是有效的）
  LLayout := TMemLayout.Create(100, 0);
  Check(LLayout.IsValid, 'Create(100,0) 应生成有效布局（默认对齐）');

  // 创建一个手工构造的无效布局（对齐为0）
  // 注意：TMemLayout.Create 会自动修正对齐，所以需要直接设置字段
  // 这里我们测试 IsValid 检测
  LLayout := TMemLayout.Empty;
  // Empty 的 Align = 1，是有效的
  Check(LLayout.IsValid, 'Empty 布局应有效');

  WriteLn;
end;

procedure TestZeroSizeAllocation;
var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
begin
  WriteLn('=== TestZeroSizeAllocation ===');

  LAlloc := GetSystemAlloc;

  // 零大小分配应该成功并返回 nil
  LLayout := TMemLayout.Create(0, 8);
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, '零大小分配应成功');
  Check(LResult.Ptr = nil, '零大小分配应返回 nil');

  // 也测试 Empty 布局
  LLayout := TMemLayout.Empty;
  LResult := LAlloc.Alloc(LLayout);
  Check(LResult.IsOk, 'Empty 布局分配应成功');
  Check(LResult.Ptr = nil, 'Empty 布局分配应返回 nil');

  WriteLn;
end;

procedure TestReallocCapsEnforcement;
var
  LAlloc: IAlloc;
  LOldLayout, LNewLayout: TMemLayout;
  LResult: TAllocResult;
  LPtr: Pointer;
begin
  WriteLn('=== TestReallocCapsEnforcement ===');

  LAlloc := GetSystemAlloc;

  // 先分配
  LOldLayout := TMemLayout.Create(100, 8);
  LResult := LAlloc.Alloc(LOldLayout);
  Check(LResult.IsOk, '初始分配应成功');
  LPtr := LResult.Ptr;

  if LPtr <> nil then
  begin
    // Realloc 到超大对齐应失败
    LNewLayout := TMemLayout.Create(200, 64);
    LResult := LAlloc.Realloc(LPtr, LOldLayout, LNewLayout);
    Check(LResult.IsErr, 'Realloc 到超大对齐应失败');
    Check(LResult.Error = aeAlignmentNotSupported,
          'Realloc 错误应是 aeAlignmentNotSupported');

    // 原指针应该仍然有效（Realloc 失败时不释放）
    // 清理
    LAlloc.Dealloc(LPtr, LOldLayout);
  end;

  WriteLn;
end;

procedure TestCapsReporting;
var
  LSysAlloc: IAlloc;
  LAlignAlloc: IAlloc;
  LSysCaps, LAlignCaps: TAllocCaps;
begin
  WriteLn('=== TestCapsReporting ===');

  LSysAlloc := GetSystemAlloc;
  LAlignAlloc := GetAlignedAlloc;

  LSysCaps := LSysAlloc.Caps;
  LAlignCaps := LAlignAlloc.Caps;

  WriteLn('  SystemAlloc Caps:');
  WriteLn('    ThreadSafe: ', LSysCaps.ThreadSafe);
  WriteLn('    NativeAligned: ', LSysCaps.NativeAligned);
  WriteLn('    MaxAlign: ', LSysCaps.MaxAlign);
  WriteLn('    CanRealloc: ', LSysCaps.CanRealloc);

  WriteLn('  AlignedAlloc Caps:');
  WriteLn('    ThreadSafe: ', LAlignCaps.ThreadSafe);
  WriteLn('    NativeAligned: ', LAlignCaps.NativeAligned);
  WriteLn('    MaxAlign: ', LAlignCaps.MaxAlign);
  WriteLn('    CanRealloc: ', LAlignCaps.CanRealloc);

  Check(not LSysCaps.NativeAligned, 'SystemAlloc 不应声明原生对齐支持');
  Check(LAlignCaps.NativeAligned, 'AlignedAlloc 应声明原生对齐支持');
  Check(LSysCaps.CanRealloc, 'SystemAlloc 应支持 Realloc');
  Check(LAlignCaps.CanRealloc, 'AlignedAlloc 应支持 Realloc');

  WriteLn;
end;

begin
  WriteLn('================================================');
  WriteLn('  fafafa.core.mem.alloc Caps 强制检查测试');
  WriteLn('  P0-4 TDD 验证');
  WriteLn('================================================');
  WriteLn;

  TestSystemAllocAlignmentRestriction;
  TestAlignedAllocSupportsLargeAlignment;
  TestInvalidLayoutRejection;
  TestZeroSizeAllocation;
  TestReallocCapsEnforcement;
  TestCapsReporting;

  WriteLn('================================================');
  WriteLn('  测试结果: ', GTestsPassed, ' 通过, ', GTestsFailed, ' 失败');
  WriteLn('================================================');

  if GTestsFailed > 0 then
    Halt(1)
  else
    WriteLn('所有测试通过！');
end.
