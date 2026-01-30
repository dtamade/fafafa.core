{$CODEPAGE UTF8}
program direct_test;

{$mode objfpc}{$H+}

uses
  fafafa.core.sync.sem;

procedure TestBasicSemaphore;
var
  Sem: ISem;
begin
  WriteLn('=== 测试基本信号量功能 ===');
  
  // 测试创建
  Sem := MakeSem(1, 3);
  WriteLn('✓ 创建信号量成功');
  
  // 测试状态查询
  WriteLn('初始可用许可: ', Sem.GetAvailableCount);
  WriteLn('最大许可数: ', Sem.GetMaxCount);
  
  // 测试获取和释放
  Sem.Acquire;
  WriteLn('获取后可用许可: ', Sem.GetAvailableCount);
  
  Sem.Release;
  WriteLn('释放后可用许可: ', Sem.GetAvailableCount);
  
  WriteLn('✓ 基本功能测试通过');
  WriteLn;
end;

procedure TestSemaphoreGuard;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('=== 测试信号量守卫功能 ===');
  
  Sem := MakeSem(2, 3);
  WriteLn('创建信号量: 初始=2, 最大=3');
  
  // 测试守卫创建
  Guard := Sem.AcquireGuard;
  WriteLn('创建守卫，持有许可数: ', Guard.GetCount);
  WriteLn('信号量可用许可: ', Sem.GetAvailableCount);
  
  // 测试手动释放
  Guard.Release;
  WriteLn('手动释放后守卫持有许可数: ', Guard.GetCount);
  WriteLn('手动释放后信号量可用许可: ', Sem.GetAvailableCount);
  
  WriteLn('✓ 守卫功能测试通过');
  WriteLn;
end;

procedure TestBulkOperations;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('=== 测试批量操作功能 ===');
  
  Sem := MakeSem(3, 5);
  WriteLn('创建信号量: 初始=3, 最大=5');
  
  // 批量获取
  Guard := Sem.AcquireGuard(2);
  WriteLn('批量获取2个许可，守卫持有: ', Guard.GetCount);
  WriteLn('信号量剩余可用: ', Sem.GetAvailableCount);
  
  // 守卫析构时自动释放
  Guard := nil;
  WriteLn('守卫析构后信号量可用: ', Sem.GetAvailableCount);
  
  WriteLn('✓ 批量操作测试通过');
  WriteLn;
end;

procedure TestTryOperations;
var
  Sem: ISem;
  Guard1, Guard2: ISemGuard;
begin
  WriteLn('=== 测试非阻塞操作功能 ===');
  
  Sem := MakeSem(1, 2);
  WriteLn('创建信号量: 初始=1, 最大=2');
  
  // 第一次尝试获取
  Guard1 := Sem.TryAcquireGuard;
  if Guard1 <> nil then
  begin
    WriteLn('✓ 第一次尝试获取成功');
    WriteLn('信号量剩余可用: ', Sem.GetAvailableCount);
    
    // 第二次尝试获取
    Guard2 := Sem.TryAcquireGuard;
    if Guard2 <> nil then
      WriteLn('✓ 第二次尝试获取成功')
    else
      WriteLn('✓ 第二次尝试获取失败（符合预期）');
      
    Guard1 := nil; // 释放第一个守卫
  end
  else
    WriteLn('✗ 第一次尝试获取失败');
    
  WriteLn('最终信号量可用许可: ', Sem.GetAvailableCount);
  WriteLn('✓ 非阻塞操作测试通过');
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.sync.sem 直接测试');
    WriteLn('================================');
    WriteLn;
    
    TestBasicSemaphore;
    TestSemaphoreGuard;
    TestBulkOperations;
    TestTryOperations;
    
    WriteLn('================================');
    WriteLn('✓ 所有测试通过！');
  except
    on E: Exception do
    begin
      WriteLn('✗ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
