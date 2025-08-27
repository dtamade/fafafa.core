program test_memory_leak;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.slabPool;

var
  LPool: TSlabPool;
  LConfig: TSlabConfig;
  LPtr: Pointer;
  I: Integer;

begin
  WriteLn('Testing SlabPool for memory leaks...');
  
  // 测试1: 基础分配和释放
  WriteLn('Test 1: Basic allocation and deallocation');
  LConfig := CreateDefaultSlabConfig;
  LPool := TSlabPool.Create(64 * 1024, LConfig);
  try
    for I := 1 to 100 do
    begin
      LPtr := LPool.Alloc(64);
      if LPtr <> nil then
        LPool.Free(LPtr);
    end;
    WriteLn('  Basic test completed successfully');
  finally
    LPool.Destroy;
  end;
  
  // 测试2: 线程安全配置
  WriteLn('Test 2: Thread-safe configuration');
  LConfig := CreateSlabConfigWithThreadSafe;
  LPool := TSlabPool.Create(64 * 1024, LConfig);
  try
    for I := 1 to 50 do
    begin
      LPtr := LPool.Alloc(128);
      if LPtr <> nil then
        LPool.Free(LPtr);
    end;
    WriteLn('  Thread-safe test completed successfully');
  finally
    LPool.Destroy;
  end;

  // 测试3: 页面合并配置
  WriteLn('Test 3: Page merging configuration');
  LConfig := CreateSlabConfigWithPageMerging;
  LPool := TSlabPool.Create(64 * 1024, LConfig);
  try
    for I := 1 to 30 do
    begin
      LPtr := LPool.Alloc(256);
      if LPtr <> nil then
        LPool.Free(LPtr);
    end;
    WriteLn('  Page merging test completed successfully');
  finally
    LPool.Destroy;
  end;
  
  WriteLn('All tests completed. Check heaptrc output for leaks.');
end.
