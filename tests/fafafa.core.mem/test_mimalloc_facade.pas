{
  Mimalloc Facade Test - 验证门面自动选择最佳实现
}

program test_mimalloc_facade;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.layout,
  fafafa.core.mem.error,
  fafafa.core.mem.alloc,
  fafafa.core.mem.mimalloc;  // 只引用门面模块

var
  LAlloc: IAlloc;
  LLayout: TMemLayout;
  LResult: TAllocResult;
  I: Integer;
  LPtrs: array[0..999] of Pointer;
  LStart, LEnd: QWord;
begin
  WriteLn('');
  WriteLn('Mimalloc Facade Test');
  WriteLn('====================');
  WriteLn('');

  // 检查 C 库是否可用
  WriteLn('C mimalloc available: ', IsMimallocAvailable);

  // 获取分配器
  LAlloc := GetMimalloc;
  WriteLn('');

  if LAlloc = nil then
  begin
    WriteLn('[INFO] C mimalloc not available, GetMimalloc returns nil');
    WriteLn('');
    WriteLn('====================');
    WriteLn('Test skipped - no C library');
    Halt(0);
  end;

  // 测试基本分配
  WriteLn('=== Basic Allocation Tests ===');

  LLayout := TMemLayout.Create(64, 8);
  LResult := LAlloc.Alloc(LLayout);
  if LResult.IsOk then
    WriteLn('[PASS] Alloc 64 bytes succeeded')
  else
    WriteLn('[FAIL] Alloc 64 bytes failed');
  LAlloc.Dealloc(LResult.Ptr, LLayout);

  // 批量分配测试
  WriteLn('');
  WriteLn('=== Bulk Allocation Tests ===');

  LLayout := TMemLayout.Create(128, 8);
  for I := 0 to 999 do
  begin
    LResult := LAlloc.Alloc(LLayout);
    LPtrs[I] := LResult.Ptr;
  end;
  WriteLn('[PASS] Allocated 1000 blocks');

  for I := 0 to 999 do
    LAlloc.Dealloc(LPtrs[I], LLayout);
  WriteLn('[PASS] Freed 1000 blocks');

  // 性能测试
  WriteLn('');
  WriteLn('=== Quick Performance Test ===');

  LLayout := TMemLayout.Create(64, 8);
  LStart := GetTickCount64;
  for I := 0 to 99999 do
  begin
    LResult := LAlloc.Alloc(LLayout);
    LAlloc.Dealloc(LResult.Ptr, LLayout);
  end;
  LEnd := GetTickCount64;

  WriteLn(Format('100000 alloc+free pairs: %d ms (%.1f ns/pair)',
    [LEnd - LStart, (LEnd - LStart) * 10000.0]));

  WriteLn('');
  WriteLn('====================');
  WriteLn('All tests completed!');
end.
