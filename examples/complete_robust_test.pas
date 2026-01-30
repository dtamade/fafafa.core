program CompleteRobustTest;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.robust;

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

procedure TestFixedPool;
var
  LPool: TRobustFixedPool;
  LPtrs: array[0..9] of Pointer;
  I: Integer;
begin
  WriteLn('=== TRobustFixedPool 测试 ===');
  
  LPool := TRobustFixedPool.Create(64, 10);
  try
    // 基础功能测试
    Assert(LPool.BlockSize = 64, 'BlockSize');
    Assert(LPool.BlockCount = 10, 'BlockCount');
    Assert(LPool.IsEmpty, 'IsEmpty初始状态');
    Assert(not LPool.IsFull, 'IsFull初始状态');
    
    // 分配测试
    for I := 0 to 9 do
    begin
      LPtrs[I] := LPool.Alloc;
      Assert(LPtrs[I] <> nil, '分配第' + IntToStr(I) + '个块');
      Assert(LPool.IsValidPointer(LPtrs[I]), '指针有效性' + IntToStr(I));
    end;
    
    Assert(LPool.IsFull, '池满状态');
    Assert(LPool.AllocatedCount = 10, '分配计数');
    Assert(LPool.Alloc = nil, '满池分配返回nil');
    
    // 释放测试
    for I := 0 to 9 do
      LPool.FreeBlock(LPtrs[I]);
      
    Assert(LPool.IsEmpty, '释放后为空');
    Assert(LPool.AllocatedCount = 0, '释放后计数为0');
    
    // 重复释放测试
    LPool.FreeBlock(LPtrs[0]); // 应该安全
    LPool.FreeBlock(nil); // 应该安全
    Assert(LPool.AllocatedCount = 0, '重复释放后计数仍为0');
    
  finally
    LPool.Free;
  end;
  WriteLn(' TRobustFixedPool');
end;

procedure TestObjectPool;
var
  LPool: TRobustObjectPool;
  LObjs: array[0..4] of TObject;
  I: Integer;
begin
  WriteLn('=== TRobustObjectPool 测试 ===');
  
  LPool := TRobustObjectPool.Create(TObject, 3);
  try
    Assert(LPool.CreatedCount = 0, '初始创建数为0');
    Assert(LPool.AvailableCount = 0, '初始可用数为0');
    
    // 借用对象
    for I := 0 to 4 do
    begin
      LObjs[I] := LPool.Borrow;
      Assert(LObjs[I] <> nil, '借用对象' + IntToStr(I));
    end;
    
    Assert(LPool.CreatedCount = 3, '池中创建3个对象');
    Assert(LPool.BorrowedCount = 3, '池中借出3个对象');
    
    // 归还对象
    for I := 0 to 2 do
      LPool.Return(LObjs[I]);
      
    Assert(LPool.AvailableCount = 3, '归还后可用3个');
    
    // 归还池外对象
    LPool.Return(LObjs[3]); // 应该被释放
    LPool.Return(LObjs[4]); // 应该被释放
    LPool.Return(nil); // 应该安全
    
    Assert(LPool.AvailableCount = 3, '归还池外对象后仍为3');
    
  finally
    LPool.Free;
  end;
  WriteLn(' TRobustObjectPool');
end;

procedure TestBufferPool;
var
  LPool: TRobustBufferPool;
  LBufs: array[0..4] of Pointer;
  I: Integer;
begin
  WriteLn('=== TRobustBufferPool 测试 ===');
  
  LPool := TRobustBufferPool.Create(5);
  try
    Assert(LPool.TotalCount = 0, '初始总数为0');
    Assert(LPool.UsedCount = 0, '初始使用数为0');
    
    // 获取不同大小的缓冲区
    LBufs[0] := LPool.GetBuffer(256);
    LBufs[1] := LPool.GetBuffer(512);
    LBufs[2] := LPool.GetBuffer(1024);
    
    for I := 0 to 2 do
      Assert(LBufs[I] <> nil, '获取缓冲区' + IntToStr(I));
      
    Assert(LPool.TotalCount = 3, '总数为3');
    Assert(LPool.UsedCount = 3, '使用数为3');
    
    // 归还缓冲区
    LPool.ReturnBuffer(LBufs[0]);
    LPool.ReturnBuffer(LBufs[1]);
    
    Assert(LPool.UsedCount = 1, '归还后使用数为1');
    
    // 重新获取（应该复用）
    LBufs[3] := LPool.GetBuffer(200); // 应该复用256字节的
    Assert(LBufs[3] <> nil, '复用缓冲区');
    Assert(LPool.UsedCount = 2, '复用后使用数为2');
    
    // 归还所有
    LPool.ReturnBuffer(LBufs[2]);
    LPool.ReturnBuffer(LBufs[3]);
    LPool.ReturnBuffer(nil); // 应该安全
    
    Assert(LPool.UsedCount = 0, '全部归还后使用数为0');
    
  finally
    LPool.Free;
  end;
  WriteLn(' TRobustBufferPool');
end;

procedure TestSlabPool;
var
  LSlab: TRobustSlabPool;
  LPtrs: array[0..19] of Pointer;
  I: Integer;
  LSize, LAllocated, LAvailable: SizeUInt;
begin
  WriteLn('=== TRobustSlabPool 测试 ===');
  
  LSlab := TRobustSlabPool.Create;
  try
    // 添加不同大小的slab
    LSlab.AddSlab(32, 10);
    LSlab.AddSlab(64, 10);
    LSlab.AddSlab(128, 10);
    
    Assert(LSlab.SlabCount = 3, 'Slab数量为3');
    
    // 测试分配
    for I := 0 to 19 do
    begin
      case I mod 3 of
        0: LPtrs[I] := LSlab.Alloc(30);   // 32字节slab
        1: LPtrs[I] := LSlab.Alloc(60);   // 64字节slab
        2: LPtrs[I] := LSlab.Alloc(120);  // 128字节slab
      end;
      Assert(LPtrs[I] <> nil, 'Slab分配' + IntToStr(I));
    end;
    
    // 检查slab状态
    for I := 0 to 2 do
    begin
      if LSlab.GetSlabInfo(I, LSize, LAllocated, LAvailable) then
      begin
        Assert(LAllocated > 0, 'Slab' + IntToStr(I) + '有分配');
      end;
    end;
    
    // 释放所有
    for I := 0 to 19 do
    begin
      case I mod 3 of
        0: LSlab.FreeBlock(LPtrs[I], 30);
        1: LSlab.FreeBlock(LPtrs[I], 60);
        2: LSlab.FreeBlock(LPtrs[I], 120);
      end;
    end;
    
    // 检查释放后状态
    for I := 0 to 2 do
    begin
      if LSlab.GetSlabInfo(I, LSize, LAllocated, LAvailable) then
      begin
        Assert(LAllocated = 0, 'Slab' + IntToStr(I) + '释放后为0');
      end;
    end;
    
  finally
    LSlab.Free;
  end;
  WriteLn(' TRobustSlabPool');
end;

procedure TestStressTest;
var
  LPool: TRobustFixedPool;
  LPtr: Pointer;
  I: Integer;
begin
  WriteLn('=== 压力测试 ===');
  
  LPool := TRobustFixedPool.Create(64, 100);
  try
    // 快速分配释放
    for I := 1 to 10000 do
    begin
      LPtr := LPool.Alloc;
      Assert(LPtr <> nil, '压力测试分配');
      LPool.FreeBlock(LPtr);
      
      if I mod 1000 = 0 then
        Write('.');
    end;
    
    Assert(LPool.IsEmpty, '压力测试后为空');
    
  finally
    LPool.Free;
  end;
  WriteLn(' 压力测试');
end;

begin
  WriteLn('🚀 完整健壮内存管理系统测试');
  WriteLn;
  
  try
    TestFixedPool;
    TestObjectPool;
    TestBufferPool;
    TestSlabPool;
    TestStressTest;
    
    WriteLn;
    WriteLn('=== 测试结果 ===');
    WriteLn('通过: ', GTestsPassed);
    WriteLn('失败: ', GTestsFailed);
    WriteLn('成功率: ', (GTestsPassed * 100) div (GTestsPassed + GTestsFailed), '%');
    
    if GTestsFailed = 0 then
    begin
      WriteLn('🎉 所有测试通过！健壮内存管理系统完美运行！');
      WriteLn('这个系统可以替代原有的有问题的内存管理系统！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('💀 还有问题需要修复！');
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
  WriteLn('测试完成！');
end.
