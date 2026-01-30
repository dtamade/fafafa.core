program QuickHellTest;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.simple;

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
  LPool: TSimpleFixedPool;
begin
  WriteLn('=== 边界条件测试 ===');
  
  // 测试1：最小值
  try
    LPool := TSimpleFixedPool.Create(1, 1);
    CheckError('创建1字节池', True);
    LPool.Free;
  except
    CheckError('创建1字节池', False);
  end;
  
  // 测试2：零值应该失败
  try
    LPool := TSimpleFixedPool.Create(0, 10);
    CheckError('零大小应该失败', False);
  except
    CheckError('零大小正确失败', True);
  end;
  
  try
    LPool := TSimpleFixedPool.Create(64, 0);
    CheckError('零数量应该失败', False);
  except
    CheckError('零数量正确失败', True);
  end;
end;

procedure TestDoubleFree;
var
  LPool: TSimpleFixedPool;
  LPtr: Pointer;
begin
  WriteLn('=== 重复释放测试 ===');
  
  LPool := TSimpleFixedPool.Create(64, 10);
  try
    LPtr := LPool.Alloc;
    CheckError('分配成功', LPtr <> nil);
    
    LPool.FreeBlock(LPtr);
    CheckError('第一次释放', LPool.AllocatedCount = 0);
    
    // 重复释放 - 这是危险操作，但不应该崩溃
    try
      LPool.FreeBlock(LPtr);
      CheckError('重复释放不崩溃', True);
    except
      CheckError('重复释放崩溃了', False);
    end;
    
    // 释放nil
    try
      LPool.FreeBlock(nil);
      CheckError('释放nil安全', True);
    except
      CheckError('释放nil崩溃', False);
    end;
    
  finally
    LPool.Free;
  end;
end;

procedure TestSlabBasic;
var
  LSlab: TSimpleSlabPool;
  LPtr1, LPtr2: Pointer;
begin
  WriteLn('=== Slab基础测试 ===');
  
  LSlab := TSimpleSlabPool.Create;
  try
    LSlab.AddSlab(32, 10);
    LSlab.AddSlab(64, 10);
    CheckError('添加Slab', LSlab.SlabCount = 2);
    
    LPtr1 := LSlab.Alloc(30); // 应该用32字节slab
    CheckError('分配30字节', LPtr1 <> nil);
    
    LPtr2 := LSlab.Alloc(60); // 应该用64字节slab
    CheckError('分配60字节', LPtr2 <> nil);
    
    LSlab.FreeBlock(LPtr1, 30);
    LSlab.FreeBlock(LPtr2, 60);
    CheckError('释放Slab内存', True);
    
  finally
    LSlab.Free;
  end;
end;

procedure TestObjectPool;
var
  LPool: TSimpleObjectPool;
  LObj1, LObj2: TObject;
begin
  WriteLn('=== 对象池测试 ===');
  
  LPool := TSimpleObjectPool.Create(TObject, 2);
  try
    LObj1 := LPool.Borrow;
    CheckError('借用对象1', LObj1 <> nil);
    
    LObj2 := LPool.Borrow;
    CheckError('借用对象2', LObj2 <> nil);
    
    // 超出池容量，应该创建新对象
    LPool.Borrow;
    CheckError('超出容量借用', True);
    
    LPool.Return(LObj1);
    LPool.Return(LObj2);
    CheckError('归还对象', LPool.AvailableCount = 2);
    
    // 归还nil应该安全
    LPool.Return(nil);
    CheckError('归还nil安全', True);
    
  finally
    LPool.Free;
  end;
end;

procedure TestMemoryCorruption;
var
  LPool: TSimpleFixedPool;
  LPtrs: array[0..99] of Pointer;
  I: Integer;
begin
  WriteLn('=== 内存损坏测试 ===');
  
  LPool := TSimpleFixedPool.Create(64, 100);
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
    
    // 释放所有块
    for I := 0 to 99 do
      LPool.FreeBlock(LPtrs[I]);
      
    CheckError('释放所有块', LPool.IsEmpty);
    
  finally
    LPool.Free;
  end;
end;

procedure TestStressAllocation;
var
  LPool: TSimpleFixedPool;
  LPtr: Pointer;
  I: Integer;
begin
  WriteLn('=== 压力分配测试 ===');
  
  LPool := TSimpleFixedPool.Create(64, 1000);
  try
    // 快速分配释放循环
    for I := 1 to 10000 do
    begin
      LPtr := LPool.Alloc;
      if LPtr = nil then
      begin
        CheckError('压力分配第' + IntToStr(I) + '次', False);
        Exit;
      end;
      LPool.FreeBlock(LPtr);
      
      if I mod 1000 = 0 then
        Write('.');
    end;
    WriteLn;
    
    CheckError('10000次分配释放', True);
    
  finally
    LPool.Free;
  end;
end;

begin
  WriteLn('💀 快速地狱测试 - 专门找bug！');
  WriteLn;
  
  try
    TestBoundaryConditions;
    TestDoubleFree;
    TestSlabBasic;
    TestObjectPool;
    TestMemoryCorruption;
    TestStressAllocation;
    
    WriteLn;
    WriteLn('=== 测试结果 ===');
    if GErrors = 0 then
    begin
      WriteLn('🎉 所有测试通过！你的内存池很健壮！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('💀 发现 ', GErrors, ' 个错误！需要修复！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('💥 严重错误: ', E.Message);
      WriteLn('你的内存池有致命bug！');
      ExitCode := 2;
    end;
  end;
  
  WriteLn;
  WriteLn('测试完成！');
end.
