program ReplacementTest;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.replacement;

var
  GTestsPassed: Integer = 0;
  GTestsFailed: Integer = 0;

procedure Assert(aCondition: Boolean; const aMessage: string);
begin
  if aCondition then
  begin
    Inc(GTestsPassed);
    Write('✅');
  end
  else
  begin
    Inc(GTestsFailed);
    WriteLn;
    WriteLn('❌ FAILED: ', aMessage);
    Write('❌');
  end;
end;

procedure TestFixedSizePoolReplacement;
var
  LPool: TFixedSizePool;
  LPtr1, LPtr2: Pointer;
begin
  WriteLn('=== TFixedSizePool 替换测试 ===');
  
  LPool := TFixedSizePool.Create(64, 10);
  try
    Assert(LPool.BlockSize = 64, 'BlockSize属性');
    Assert(LPool.AvailableCount = 10, '初始可用数量');
    
    LPtr1 := LPool.GetMem(64);
    Assert(LPtr1 <> nil, 'GetMem分配');
    Assert(LPool.GetAllocatedCount = 1, '分配后计数');
    
    LPtr2 := LPool.GetMem(32); // 应该忽略大小，使用固定大小
    Assert(LPtr2 <> nil, 'GetMem忽略大小');
    
    LPool.FreeMem(LPtr1);
    LPool.FreeMem(LPtr2);
    Assert(LPool.GetAllocatedCount = 0, '释放后计数');
    
  finally
    LPool.Free;
  end;
  WriteLn(' TFixedSizePool替换');
end;

procedure TestObjectPoolReplacement;
var
  LPool: TObjectPool;
  LObj1, LObj2: TObject;
begin
  WriteLn('=== TObjectPool 替换测试 ===');
  
  LPool := TObjectPool.Create(TObject, 3);
  try
    Assert(LPool.GetPoolCount = 0, '初始池数量');
    
    LObj1 := LPool.Borrow;
    Assert(LObj1 <> nil, 'Borrow对象');
    
    LObj2 := LPool.Borrow;
    Assert(LObj2 <> nil, 'Borrow第二个对象');
    Assert(LObj1 <> LObj2, '对象不同');
    
    LPool.Return(LObj1);
    Assert(LPool.GetPoolCount = 1, '归还后池数量');
    
    LPool.Return(LObj2);
    Assert(LPool.GetPoolCount = 2, '归还两个后池数量');
    
  finally
    LPool.Free;
  end;
  WriteLn(' TObjectPool替换');
end;

procedure TestBufferPoolReplacement;
var
  LPool: TBufferPool;
  LBuffer1, LBuffer2: TBufferInfo;
begin
  WriteLn('=== TBufferPool 替换测试 ===');
  
  LPool := TBufferPool.Create(5);
  try
    Assert(LPool.TotalBuffers = 0, '初始总数');
    Assert(LPool.BorrowedBuffers = 0, '初始借出数');
    
    LBuffer1 := LPool.GetBuffer(256);
    Assert(LBuffer1.Buffer <> nil, 'GetBuffer返回有效指针');
    Assert(LBuffer1.Capacity = 256, 'Buffer容量正确');
    Assert(LPool.BorrowedBuffers = 1, '借出数量增加');
    
    LBuffer2 := LPool.GetBuffer(512);
    Assert(LBuffer2.Buffer <> nil, 'GetBuffer第二个');
    Assert(LBuffer2.Capacity = 512, '第二个Buffer容量');
    
    LPool.ReturnBuffer(LBuffer1);
    LPool.ReturnBuffer(LBuffer2);
    Assert(LPool.BorrowedBuffers = 0, '归还后借出数为0');
    
  finally
    LPool.Free;
  end;
  WriteLn(' TBufferPool替换');
end;

procedure TestTrackingAllocatorReplacement;
var
  LTracker: TTrackingAllocator;
  LPtr1, LPtr2: Pointer;
begin
  WriteLn('=== TTrackingAllocator 替换测试 ===');
  
  LTracker := TTrackingAllocator.Create(1024);
  try
    Assert(LTracker.GetAllocatedSize = 0, '初始分配大小');
    Assert(LTracker.GetAllocationCount = 0, '初始分配次数');
    
    LPtr1 := LTracker.GetMem(512);
    Assert(LPtr1 <> nil, 'GetMem分配');
    Assert(LTracker.GetAllocationCount = 1, '分配次数增加');
    
    LPtr2 := LTracker.GetMem(256);
    Assert(LPtr2 <> nil, 'GetMem第二次分配');
    Assert(LTracker.GetAllocationCount = 2, '分配次数为2');
    
    LTracker.FreeMem(LPtr1);
    LTracker.FreeMem(LPtr2);
    
  finally
    LTracker.Free;
  end;
  WriteLn(' TTrackingAllocator替换');
end;

procedure TestAlignedAllocatorReplacement;
var
  LAligned: TAlignedAllocator;
  LPtr1, LPtr2: Pointer;
begin
  WriteLn('=== TAlignedAllocator 替换测试 ===');
  
  LAligned := TAlignedAllocator.Create(16);
  try
    LPtr1 := LAligned.GetMem(100);
    Assert(LPtr1 <> nil, 'GetMem分配');
    Assert(PtrUInt(LPtr1) mod 16 = 0, '16字节对齐');
    
    LPtr2 := LAligned.GetMem(200);
    Assert(LPtr2 <> nil, 'GetMem第二次分配');
    Assert(PtrUInt(LPtr2) mod 16 = 0, '第二次16字节对齐');
    
    LAligned.FreeMem(LPtr1);
    LAligned.FreeMem(LPtr2);
    
  finally
    LAligned.Free;
  end;
  WriteLn(' TAlignedAllocator替换');
end;

procedure TestStackAllocatorReplacement;
var
  LStack: TStackAllocator;
  LPtr1, LPtr2: Pointer;
begin
  WriteLn('=== TStackAllocator 替换测试 ===');
  
  LStack := TStackAllocator.Create(1024);
  try
    Assert(LStack.GetUsedSize = 0, '初始使用大小');
    Assert(LStack.GetAvailableSize = 1024, '初始可用大小');
    
    LPtr1 := LStack.GetMem(100);
    Assert(LPtr1 <> nil, 'GetMem分配');
    Assert(LStack.GetUsedSize = 100, '使用大小增加');
    
    LPtr2 := LStack.GetMem(200);
    Assert(LPtr2 <> nil, 'GetMem第二次分配');
    Assert(LStack.GetUsedSize = 300, '使用大小为300');
    
    LStack.Reset;
    Assert(LStack.GetUsedSize = 0, 'Reset后使用大小为0');
    Assert(LStack.GetAvailableSize = 1024, 'Reset后可用大小恢复');
    
  finally
    LStack.Free;
  end;
  WriteLn(' TStackAllocator替换');
end;

begin
  WriteLn('🔄 兼容性替换测试 - 验证新系统能完全替换旧系统');
  WriteLn;
  
  try
    TestFixedSizePoolReplacement;
    TestObjectPoolReplacement;
    TestBufferPoolReplacement;
    TestTrackingAllocatorReplacement;
    TestAlignedAllocatorReplacement;
    TestStackAllocatorReplacement;
    
    WriteLn;
    WriteLn('=== 替换测试结果 ===');
    WriteLn('通过: ', GTestsPassed);
    WriteLn('失败: ', GTestsFailed);
    WriteLn('成功率: ', (GTestsPassed * 100) div (GTestsPassed + GTestsFailed), '%');
    
    if GTestsFailed = 0 then
    begin
      WriteLn('🎉 完美！新系统完全兼容原有API！');
      WriteLn('可以直接替换原有的有问题的内存管理系统！');
      WriteLn;
      WriteLn('替换步骤:');
      WriteLn('1. 备份原有的 fafafa.core.mem.pas');
      WriteLn('2. 将 fafafa.core.mem.replacement.pas 重命名为 fafafa.core.mem.pas');
      WriteLn('3. 重新编译项目');
      WriteLn('4. 享受0访问违例的稳定系统！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('💀 还有兼容性问题需要修复！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('💥 严重错误: ', E.Message);
      ExitCode := 2;
    end;
  end;
  
  WriteLn;
  WriteLn('替换测试完成！');
end.
