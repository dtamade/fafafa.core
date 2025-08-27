program RobustHellTest;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.robust;

var
  GErrors: Integer = 0;

procedure CheckError(const aTest: string; aCondition: Boolean);
begin
  if not aCondition then
  begin
    WriteLn('❌ FAILED: ', aTest);
    Inc(GErrors);
  end
  else
    WriteLn('✅ PASSED: ', aTest);
end;

procedure TestBoundaryConditions;
var
  LPool: TRobustFixedPool;
  LPtr: Pointer;
begin
  WriteLn('=== 边界条件测试 ===');
  
  // 测试1：最小值
  try
    LPool := TRobustFixedPool.Create(1, 1);
    LPtr := LPool.Alloc;
    CheckError('1字节池分配', LPtr <> nil);
    LPool.FreeBlock(LPtr);
    CheckError('1字节池释放', LPool.IsEmpty);
    LPool.Free;
    CheckError('1字节池创建销毁', True);
  except
    on E: Exception do
      CheckError('1字节池异常: ' + E.Message, False);
  end;
  
  // 测试2：零值应该失败
  try
    LPool := TRobustFixedPool.Create(0, 10);
    CheckError('零大小应该失败', False);
  except
    CheckError('零大小正确失败', True);
  end;
  
  try
    LPool := TRobustFixedPool.Create(64, 0);
    CheckError('零数量应该失败', False);
  except
    CheckError('零数量正确失败', True);
  end;
  
  // 测试3：大值
  try
    LPool := TRobustFixedPool.Create(64*1024, 10);
    LPtr := LPool.Alloc;
    CheckError('大块分配', LPtr <> nil);
    LPool.FreeBlock(LPtr);
    LPool.Free;
    CheckError('大块池', True);
  except
    on E: Exception do
      CheckError('大块池异常: ' + E.Message, False);
  end;
end;

procedure TestDoubleFree;
var
  LPool: TRobustFixedPool;
  LPtr: Pointer;
begin
  WriteLn('=== 重复释放测试 ===');
  
  LPool := TRobustFixedPool.Create(64, 10);
  try
    LPtr := LPool.Alloc;
    CheckError('分配成功', LPtr <> nil);
    CheckError('指针有效', LPool.IsValidPointer(LPtr));
    
    LPool.FreeBlock(LPtr);
    CheckError('第一次释放', LPool.AllocatedCount = 0);
    
    // 重复释放 - 应该安全
    LPool.FreeBlock(LPtr);
    CheckError('重复释放安全', LPool.AllocatedCount = 0);
    
    // 释放nil
    LPool.FreeBlock(nil);
    CheckError('释放nil安全', True);
    
    // 释放无效指针
    LPool.FreeBlock(Pointer($12345678));
    CheckError('释放无效指针安全', True);
    
  finally
    LPool.Free;
  end;
end;

procedure TestMemoryCorruption;
var
  LPool: TRobustFixedPool;
  LPtrs: array[0..99] of Pointer;
  I: Integer;
begin
  WriteLn('=== 内存损坏测试 ===');
  
  LPool := TRobustFixedPool.Create(64, 100);
  try
    // 分配所有块
    for I := 0 to 99 do
    begin
      LPtrs[I] := LPool.Alloc;
      if LPtrs[I] = nil then
      begin
        CheckError('分配第' + IntToStr(I) + '个块', False);
        Exit;
      end;
      
      // 写入测试数据
      PByte(LPtrs[I])^ := Byte(I and $FF);
    end;
    
    CheckError('分配100个块', LPool.IsFull);
    CheckError('池满后无法分配', LPool.Alloc = nil);
    
    // 验证数据完整性
    for I := 0 to 99 do
    begin
      if PByte(LPtrs[I])^ <> Byte(I and $FF) then
      begin
        CheckError('数据完整性', False);
        Exit;
      end;
    end;
    
    CheckError('数据完整性', True);
    
    // 随机释放一半
    for I := 0 to 49 do
      LPool.FreeBlock(LPtrs[I]);
      
    CheckError('释放一半后计数', LPool.AllocatedCount = 50);
    
    // 重新分配
    for I := 0 to 49 do
    begin
      LPtrs[I] := LPool.Alloc;
      CheckError('重新分配', LPtrs[I] <> nil);
    end;
    
    CheckError('重新分配后满', LPool.IsFull);
    
    // 释放所有块
    for I := 0 to 99 do
      LPool.FreeBlock(LPtrs[I]);
      
    CheckError('释放所有块', LPool.IsEmpty);
    
  finally
    LPool.Free;
  end;
end;

procedure TestSlabPool;
var
  LSlab: TRobustSlabPool;
  LPtrs: array[0..99] of Pointer;
  I: Integer;
  LSize, LAllocated, LAvailable: SizeUInt;
begin
  WriteLn('=== Slab池测试 ===');
  
  LSlab := TRobustSlabPool.Create;
  try
    // 添加不同大小的slab（增加容量）
    LSlab.AddSlab(32, 30);
    LSlab.AddSlab(64, 30);
    LSlab.AddSlab(128, 30);
    LSlab.AddSlab(256, 30);
    
    CheckError('添加4个Slab', LSlab.SlabCount = 4);
    
    // 测试分配
    for I := 0 to 99 do
    begin
      case I mod 4 of
        0: LPtrs[I] := LSlab.Alloc(30);   // 使用32字节slab
        1: LPtrs[I] := LSlab.Alloc(60);   // 使用64字节slab
        2: LPtrs[I] := LSlab.Alloc(120);  // 使用128字节slab
        3: LPtrs[I] := LSlab.Alloc(250);  // 使用256字节slab
      end;
      
      if LPtrs[I] = nil then
      begin
        CheckError('Slab分配第' + IntToStr(I) + '个', False);
        Exit;
      end;
    end;
    
    CheckError('Slab分配100个块', True);
    
    // 检查slab状态
    for I := 0 to 3 do
    begin
      if LSlab.GetSlabInfo(I, LSize, LAllocated, LAvailable) then
      begin
        CheckError('Slab' + IntToStr(I) + '已分配25个', LAllocated = 25);
      end;
    end;
    
    // 释放所有
    for I := 0 to 99 do
    begin
      case I mod 4 of
        0: LSlab.FreeBlock(LPtrs[I], 30);
        1: LSlab.FreeBlock(LPtrs[I], 60);
        2: LSlab.FreeBlock(LPtrs[I], 120);
        3: LSlab.FreeBlock(LPtrs[I], 250);
      end;
    end;
    
    // 检查释放后状态
    for I := 0 to 3 do
    begin
      if LSlab.GetSlabInfo(I, LSize, LAllocated, LAvailable) then
      begin
        CheckError('Slab' + IntToStr(I) + '释放后为空', LAllocated = 0);
      end;
    end;
    
  finally
    LSlab.Free;
  end;
end;

procedure TestStressTest;
var
  LPool: TRobustFixedPool;
  LPtr: Pointer;
  I: Integer;
begin
  WriteLn('=== 压力测试 ===');
  
  LPool := TRobustFixedPool.Create(64, 1000);
  try
    // 快速分配释放循环
    for I := 1 to 50000 do
    begin
      LPtr := LPool.Alloc;
      if LPtr = nil then
      begin
        CheckError('压力测试分配失败', False);
        Exit;
      end;
      LPool.FreeBlock(LPtr);
      
      if I mod 10000 = 0 then
        Write('.');
    end;
    WriteLn;
    
    CheckError('50000次分配释放', True);
    CheckError('压力测试后池为空', LPool.IsEmpty);
    
  finally
    LPool.Free;
  end;
end;

begin
  WriteLn('💪 健壮版本地狱测试 - 看看能不能通过！');
  WriteLn;
  
  try
    TestBoundaryConditions;
    TestDoubleFree;
    TestMemoryCorruption;
    TestSlabPool;
    TestStressTest;
    
    WriteLn;
    WriteLn('=== 最终结果 ===');
    if GErrors = 0 then
    begin
      WriteLn('🎉 所有测试通过！健壮版本成功！');
      WriteLn('这个版本可以用于生产环境！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('💀 还有 ', GErrors, ' 个错误！继续修复！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('💥 严重错误: ', E.Message);
      WriteLn('还有致命bug！');
      ExitCode := 2;
    end;
  end;
  
  WriteLn;
  WriteLn('健壮版本测试完成！');
end.
