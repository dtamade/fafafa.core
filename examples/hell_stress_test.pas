program HellStressTest;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.simple;

var
  GTestsPassed: Integer = 0;
  GTestsFailed: Integer = 0;

procedure Assert(aCondition: Boolean; const aMessage: string);
begin
  if aCondition then
  begin
    Inc(GTestsPassed);
    Write('.');
  end
  else
  begin
    Inc(GTestsFailed);
    WriteLn;
    WriteLn('FAILED: ', aMessage);
    Write('F');
  end;
end;

// 地狱测试1：内存泄漏检测
procedure HellTest_MemoryLeaks;
var
  LPool: TSimpleFixedPool;
  LPtrs: array[0..999] of Pointer;
  I: Integer;
begin
  WriteLn('地狱测试1: 内存泄漏检测');
  
  LPool := TSimpleFixedPool.Create(64, 1000);
  try
    // 分配所有内存
    for I := 0 to 999 do
    begin
      LPtrs[I] := LPool.Alloc;
      Assert(LPtrs[I] <> nil, '分配失败 at ' + IntToStr(I));
    end;
    
    // 检查池是否满
    Assert(LPool.IsFull, '池应该满了');
    Assert(LPool.Alloc = nil, '满池还能分配内存');
    
    // 只释放一半内存，故意制造"泄漏"
    for I := 0 to 499 do
      LPool.FreeBlock(LPtrs[I]);
      
    Assert(LPool.AllocatedCount = 500, '释放后计数错误');
    Assert(LPool.AvailableCount = 500, '可用计数错误');
    
    // 剩下的500个不释放，看析构函数能否处理
  finally
    LPool.Free; // 这里应该能正确清理，不崩溃
  end;
end;

// 地狱测试2：边界条件攻击
procedure HellTest_BoundaryAttack;
var
  LPool: TSimpleFixedPool;
  LPtr: Pointer;
begin
  WriteLn('地狱测试2: 边界条件攻击');
  
  // 测试极小值
  try
    LPool := TSimpleFixedPool.Create(1, 1);
    LPtr := LPool.Alloc;
    Assert(LPtr <> nil, '1字节分配失败');
    LPool.FreeBlock(LPtr);
    LPool.Free;
  except
    on E: Exception do
      Assert(False, '1字节池崩溃: ' + E.Message);
  end;
  
  // 测试大值（减小到合理大小）
  try
    LPool := TSimpleFixedPool.Create(64*1024, 5); // 320KB总共
    LPtr := LPool.Alloc;
    Assert(LPtr <> nil, '大块分配失败');
    LPool.FreeBlock(LPtr);
    LPool.Free;
  except
    on E: Exception do
      Assert(False, '大块池崩溃: ' + E.Message);
  end;
  
  // 测试零值（应该抛异常）
  try
    LPool := TSimpleFixedPool.Create(0, 10);
    Assert(False, '零大小应该抛异常');
  except
    on E: Exception do
      Assert(True, '零大小正确抛异常');
  end;
  
  try
    LPool := TSimpleFixedPool.Create(64, 0);
    Assert(False, '零数量应该抛异常');
  except
    on E: Exception do
      Assert(True, '零数量正确抛异常');
  end;
end;

// 地狱测试3：重复释放攻击
procedure HellTest_DoubleFree;
var
  LPool: TSimpleFixedPool;
  LPtr: Pointer;
begin
  WriteLn('地狱测试3: 重复释放攻击');
  
  LPool := TSimpleFixedPool.Create(64, 10);
  try
    LPtr := LPool.Alloc;
    Assert(LPtr <> nil, '分配失败');
    
    // 第一次释放
    LPool.FreeBlock(LPtr);
    Assert(LPool.AllocatedCount = 0, '释放后计数错误');
    
    // 第二次释放同一个指针（危险操作）
    LPool.FreeBlock(LPtr); // 不应该崩溃
    Assert(LPool.AllocatedCount = 0, '重复释放后计数错误');
    
    // 释放nil指针
    LPool.FreeBlock(nil); // 应该安全忽略
    
    // 释放随机指针
    LPool.FreeBlock(Pointer($12345678)); // 应该安全处理
    
  finally
    LPool.Free;
  end;
end;

// 地狱测试4：SlabPool压力测试
procedure HellTest_SlabStress;
var
  LSlab: TSimpleSlabPool;
  LPtrs: array[0..9999] of record
    Ptr: Pointer;
    Size: SizeUInt;
  end;
  I, LSize: Integer;
  LRandomSizes: array[0..7] of SizeUInt = (16, 32, 64, 128, 256, 512, 1024, 2048);
begin
  WriteLn('地狱测试4: SlabPool压力测试');
  
  LSlab := TSimpleSlabPool.Create;
  try
    // 添加各种大小的slab
    for I := 0 to High(LRandomSizes) do
      LSlab.AddSlab(LRandomSizes[I], 100);
    
    // 疯狂随机分配
    for I := 0 to 9999 do
    begin
      LSize := LRandomSizes[Random(Length(LRandomSizes))];
      LPtrs[I].Size := LSize;
      LPtrs[I].Ptr := LSlab.Alloc(LSize);
      
      if I mod 1000 = 0 then
        Write('*'); // 进度指示
    end;
    
    // 检查分配结果
    for I := 0 to 9999 do
      Assert(LPtrs[I].Ptr <> nil, '分配失败 at ' + IntToStr(I));
    
    // 随机释放一半
    for I := 0 to 4999 do
    begin
      if Random(2) = 0 then
      begin
        LSlab.FreeBlock(LPtrs[I].Ptr, LPtrs[I].Size);
        LPtrs[I].Ptr := nil;
      end;
    end;
    
    // 再次分配
    for I := 0 to 4999 do
    begin
      if LPtrs[I].Ptr = nil then
      begin
        LPtrs[I].Ptr := LSlab.Alloc(LPtrs[I].Size);
        Assert(LPtrs[I].Ptr <> nil, '重新分配失败');
      end;
    end;
    
    // 全部释放
    for I := 0 to 9999 do
    begin
      if LPtrs[I].Ptr <> nil then
        LSlab.FreeBlock(LPtrs[I].Ptr, LPtrs[I].Size);
    end;
    
  finally
    LSlab.Free;
  end;
end;

// 地狱测试5：对象池生命周期攻击
procedure HellTest_ObjectLifecycle;
var
  LPool: TSimpleObjectPool;
  LObjs: array[0..99] of TObject;
  I: Integer;
begin
  WriteLn('地狱测试5: 对象池生命周期攻击');
  
  LPool := TSimpleObjectPool.Create(TObject, 10);
  try
    // 借用超过池容量的对象
    for I := 0 to 99 do
    begin
      LObjs[I] := LPool.Borrow;
      Assert(LObjs[I] <> nil, '对象借用失败');
    end;
    
    // 归还部分对象
    for I := 0 to 49 do
      LPool.Return(LObjs[I]);
    
    // 再次借用
    for I := 50 to 99 do
    begin
      LPool.Return(LObjs[I]);
    end;
    
    // 重复归还（应该安全）
    LPool.Return(nil);
    
    // 归还不是从池中借用的对象
    LPool.Return(TObject.Create); // 应该被正确处理
    
  finally
    LPool.Free;
  end;
end;

// 地狱测试6：内存对齐验证
procedure HellTest_MemoryAlignment;
var
  LPool: TSimpleFixedPool;
  LPtrs: array[0..99] of Pointer;
  I: Integer;
begin
  WriteLn('地狱测试6: 内存对齐验证');
  
  LPool := TSimpleFixedPool.Create(64, 100);
  try
    // 分配大量内存块
    for I := 0 to 99 do
    begin
      LPtrs[I] := LPool.Alloc;
      Assert(LPtrs[I] <> nil, '分配失败');
      
      // 检查指针对齐（至少应该是指针大小对齐）
      Assert(PtrUInt(LPtrs[I]) mod SizeOf(Pointer) = 0, '指针未对齐');
      
      // 写入数据测试
      PByte(LPtrs[I])^ := $AA;
      Assert(PByte(LPtrs[I])^ = $AA, '内存写入失败');
    end;
    
    // 释放所有
    for I := 0 to 99 do
      LPool.FreeBlock(LPtrs[I]);
      
  finally
    LPool.Free;
  end;
end;

begin
  WriteLn('=== 地狱级别压力测试开始 ===');
  WriteLn('这个测试会尝试破坏你的内存池，找出所有bug！');
  WriteLn;
  
  Randomize;
  
  try
    HellTest_MemoryLeaks;
    HellTest_BoundaryAttack;
    HellTest_DoubleFree;
    HellTest_SlabStress;
    HellTest_ObjectLifecycle;
    HellTest_MemoryAlignment;
    
    WriteLn;
    WriteLn;
    WriteLn('=== 地狱测试结果 ===');
    WriteLn('通过测试: ', GTestsPassed);
    WriteLn('失败测试: ', GTestsFailed);
    WriteLn('成功率: ', (GTestsPassed * 100) div (GTestsPassed + GTestsFailed), '%');
    
    if GTestsFailed = 0 then
    begin
      WriteLn('🎉 恭喜！你的内存池通过了地狱测试！');
      WriteLn('这是一个非常健壮的实现！');
    end
    else
    begin
      WriteLn('💀 发现了 ', GTestsFailed, ' 个问题！');
      WriteLn('需要修复这些bug才能用于生产环境！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('💥 测试过程中发生严重错误: ', E.Message);
      WriteLn('你的内存池有严重bug！');
      ExitCode := 2;
    end;
  end;
  
  WriteLn;
  WriteLn('=== 地狱测试完成 ===');
end.
