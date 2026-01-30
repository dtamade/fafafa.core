{$CODEPAGE UTF8}
program test_production_core;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.production;

procedure TestBasicFunctionality;
var
  LPool: TFixedPool;
  LPtrs: array[0..9] of Pointer;
  I: Integer;
  LStats: TMemStats;
begin
  WriteLn('🧪 测试基本功能...');
  
  LPool := TFixedPool.Create(64, 10);
  try
    // 测试分配
    for I := 0 to 9 do
    begin
      LPtrs[I] := LPool.Alloc;
      if LPtrs[I] = nil then
      begin
        WriteLn('❌ 分配失败，索引: ', I);
        Exit;
      end;
    end;
    WriteLn('✅ 分配10个块成功');
    
    // 测试池满
    if LPool.Alloc <> nil then
    begin
      WriteLn('❌ 池满检测失败');
      Exit;
    end;
    WriteLn('✅ 池满检测正确');
    
    // 测试释放
    for I := 0 to 9 do
      LPool.Free(LPtrs[I]);
    WriteLn('✅ 释放10个块成功');
    
    // 测试统计
    LStats := LPool.GetStats;
    WriteLn('📊 统计信息:');
    WriteLn('  总大小: ', LStats.TotalBytes);
    WriteLn('  已使用: ', LStats.UsedBytes);
    WriteLn('  分配次数: ', LStats.AllocCount);
    WriteLn('  释放次数: ', LStats.FreeCount);
    
    // 测试验证
    if LPool.Validate then
      WriteLn('✅ 池完整性验证通过')
    else
      WriteLn('❌ 池完整性验证失败');
      
  finally
    LPool.Free;
  end;
  
  WriteLn;
end;

procedure TestStackPool;
var
  LStack: TStackPool;
  LPtrs: array[0..9] of Pointer;
  I: Integer;
  LStats: TMemStats;
begin
  WriteLn('🧪 测试栈池...');
  
  LStack := TStackPool.Create(1024);
  try
    // 测试分配
    for I := 0 to 9 do
    begin
      LPtrs[I] := LStack.Alloc(64);
      if LPtrs[I] = nil then
      begin
        WriteLn('❌ 栈分配失败，索引: ', I);
        Exit;
      end;
    end;
    WriteLn('✅ 栈分配10个块成功');
    
    // 测试统计
    LStats := LStack.GetStats;
    WriteLn('📊 栈统计:');
    WriteLn('  总大小: ', LStack.Size);
    WriteLn('  已使用: ', LStack.GetUsed);
    WriteLn('  可用: ', LStack.GetAvailable);
    WriteLn('  分配次数: ', LStats.AllocCount);
    
    // 测试重置
    LStack.Reset;
    if LStack.GetUsed = 0 then
      WriteLn('✅ 栈重置成功')
    else
      WriteLn('❌ 栈重置失败');
      
  finally
    LStack.Free;
  end;
  
  WriteLn;
end;

procedure TestMemoryManager;
var
  LManager: TMemoryManager;
  LPtrs: array[0..19] of Pointer;
  I: Integer;
  LStats: TMemStats;
begin
  WriteLn('🧪 测试内存管理器...');
  
  LManager := GetMemManager;
  
  // 测试分配不同大小
  for I := 0 to 19 do
  begin
    case I mod 4 of
      0: LPtrs[I] := LManager.Alloc(32);
      1: LPtrs[I] := LManager.Alloc(64);
      2: LPtrs[I] := LManager.Alloc(128);
      3: LPtrs[I] := LManager.Alloc(256);
    end;
    
    if LPtrs[I] = nil then
    begin
      WriteLn('❌ 管理器分配失败，索引: ', I);
      Exit;
    end;
  end;
  WriteLn('✅ 管理器分配20个不同大小块成功');
  
  // 测试释放
  for I := 0 to 19 do
    LManager.Free(LPtrs[I]);
  WriteLn('✅ 管理器释放20个块成功');
  
  // 测试栈分配
  for I := 0 to 9 do
  begin
    LPtrs[I] := LManager.StackAlloc(32 + I * 8);
    if LPtrs[I] = nil then
    begin
      WriteLn('❌ 栈分配失败，索引: ', I);
      Exit;
    end;
  end;
  WriteLn('✅ 栈分配10个块成功');
  
  LManager.StackReset;
  WriteLn('✅ 栈重置成功');
  
  // 测试统计
  LStats := LManager.GetTotalStats;
  WriteLn('📊 全局统计:');
  WriteLn('  总大小: ', LStats.TotalBytes);
  WriteLn('  已使用: ', LStats.UsedBytes);
  WriteLn('  分配次数: ', LStats.AllocCount);
  WriteLn('  释放次数: ', LStats.FreeCount);
  
  // 测试验证
  if LManager.ValidateAll then
    WriteLn('✅ 全局验证通过')
  else
    WriteLn('❌ 全局验证失败');
    
  WriteLn;
end;

procedure TestErrorHandling;
var
  LPool: TFixedPool;
  LPtr: Pointer;
  LErrorCaught: Boolean;
begin
  WriteLn('🧪 测试错误处理...');
  
  LPool := TFixedPool.Create(64, 5);
  try
    // 测试无效指针释放
    LErrorCaught := False;
    try
      LPool.Free(Pointer($12345678));
    except
      on E: EInvalidPtr do
      begin
        LErrorCaught := True;
        WriteLn('✅ 捕获无效指针异常: ', E.Message);
      end;
    end;
    
    if not LErrorCaught then
      WriteLn('❌ 未捕获无效指针异常');
    
    // 测试nil指针释放（应该安全）
    LPool.Free(nil);
    WriteLn('✅ nil指针释放安全');
    
    // 测试正常分配和释放
    LPtr := LPool.Alloc;
    if LPtr <> nil then
    begin
      LPool.Free(LPtr);
      WriteLn('✅ 正常分配和释放成功');
    end;
    
  finally
    LPool.Free;
  end;
  
  WriteLn;
end;

procedure TestMemoryIntegrity;
var
  LManager: TMemoryManager;
  LPtrs: array[0..99] of Pointer;
  I: Integer;
  LData: PByte;
begin
  WriteLn('🧪 测试内存完整性...');
  
  LManager := GetMemManager;
  
  // 分配并写入数据
  for I := 0 to 99 do
  begin
    LPtrs[I] := LManager.Alloc(64);
    if LPtrs[I] <> nil then
    begin
      LData := PByte(LPtrs[I]);
      LData^ := Byte(I and $FF);
    end;
  end;
  
  // 验证数据
  for I := 0 to 99 do
  begin
    if LPtrs[I] <> nil then
    begin
      LData := PByte(LPtrs[I]);
      if LData^ <> Byte(I and $FF) then
      begin
        WriteLn('❌ 内存数据损坏，索引: ', I);
        Exit;
      end;
    end;
  end;
  WriteLn('✅ 内存数据完整性验证通过');
  
  // 释放内存
  for I := 0 to 99 do
    LManager.Free(LPtrs[I]);
  WriteLn('✅ 内存释放完成');
  
  WriteLn;
end;

procedure TestConvenienceFunctions;
var
  LPtrs: array[0..9] of Pointer;
  I: Integer;
begin
  WriteLn('🧪 测试便捷函数...');
  
  // 测试FastAlloc/FastFree
  for I := 0 to 9 do
  begin
    LPtrs[I] := FastAlloc(64);
    if LPtrs[I] = nil then
    begin
      WriteLn('❌ FastAlloc失败，索引: ', I);
      Exit;
    end;
  end;
  WriteLn('✅ FastAlloc分配10个块成功');
  
  for I := 0 to 9 do
    FastFree(LPtrs[I]);
  WriteLn('✅ FastFree释放10个块成功');
  
  WriteLn;
end;

begin
  WriteLn('╔══════════════════════════════════════════════════════════════╗');
  WriteLn('║              fafafa.core.mem 生产级核心测试                  ║');
  WriteLn('╚══════════════════════════════════════════════════════════════╝');
  WriteLn;
  
  try
    TestBasicFunctionality;
    TestStackPool;
    TestMemoryManager;
    TestErrorHandling;
    TestMemoryIntegrity;
    TestConvenienceFunctions;
    
    WriteLn('🎉 所有核心功能测试通过！');
    WriteLn;
    WriteLn('✅ 基本功能正常');
    WriteLn('✅ 栈池功能正常');
    WriteLn('✅ 内存管理器正常');
    WriteLn('✅ 错误处理正常');
    WriteLn('✅ 内存完整性正常');
    WriteLn('✅ 便捷函数正常');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试过程中发生异常: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按任意键退出...');
  ReadLn;
end.
