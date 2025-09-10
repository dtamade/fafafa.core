{$CODEPAGE UTF8}
program example_sem_complete;

{$mode objfpc}{$H+}

uses
  fafafa.core.sync.sem, fafafa.core.sync.base, fafafa.core.base;

procedure DemoBasicUsage;
var
  Sem: ISem;
begin
  WriteLn('=== 基础信号量使用演示 ===');
  
  // 创建信号量：初始1个许可，最大3个许可
  Sem := MakeSem(1, 3);
  WriteLn('创建信号量: 初始=1, 最大=3');
  WriteLn('当前可用许可: ', Sem.GetAvailableCount);
  
  // 基本获取和释放
  WriteLn('获取许可...');
  Sem.Acquire;
  WriteLn('获取后可用许可: ', Sem.GetAvailableCount);
  
  WriteLn('释放许可...');
  Sem.Release;
  WriteLn('释放后可用许可: ', Sem.GetAvailableCount);
  
  WriteLn;
end;

procedure DemoGuardUsage;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('=== RAII 守卫使用演示 ===');
  
  Sem := MakeSem(2, 3);
  WriteLn('创建信号量: 初始=2, 最大=3');
  
  // 使用守卫自动管理许可
  WriteLn('创建守卫获取1个许可...');
  Guard := Sem.AcquireGuard;
  WriteLn('守卫持有许可数: ', Guard.GetCount);
  WriteLn('信号量可用许可: ', Sem.GetAvailableCount);
  
  // 手动释放
  WriteLn('手动释放守卫...');
  Guard.Release;
  WriteLn('释放后守卫持有许可数: ', Guard.GetCount);
  WriteLn('释放后信号量可用许可: ', Sem.GetAvailableCount);
  
  WriteLn;
end;

procedure DemoBulkOperations;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('=== 批量操作演示 ===');
  
  Sem := MakeSem(3, 5);
  WriteLn('创建信号量: 初始=3, 最大=5');
  
  // 批量获取
  WriteLn('批量获取2个许可...');
  Guard := Sem.AcquireGuard(2);
  WriteLn('守卫持有许可数: ', Guard.GetCount);
  WriteLn('信号量可用许可: ', Sem.GetAvailableCount);
  
  // 守卫超出作用域时自动释放
  Guard := nil;
  WriteLn('守卫析构后信号量可用许可: ', Sem.GetAvailableCount);
  
  WriteLn;
end;

procedure DemoTryOperations;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('=== 非阻塞操作演示 ===');
  
  Sem := MakeSem(1, 2);
  WriteLn('创建信号量: 初始=1, 最大=2');
  
  // 尝试获取
  WriteLn('尝试获取1个许可...');
  Guard := Sem.TryAcquireGuard;
  if Guard <> nil then
  begin
    WriteLn('✓ 获取成功，持有许可数: ', Guard.GetCount);
    WriteLn('信号量可用许可: ', Sem.GetAvailableCount);
    
    // 再次尝试获取
    WriteLn('再次尝试获取1个许可...');
    var Guard2 := Sem.TryAcquireGuard;
    if Guard2 <> nil then
    begin
      WriteLn('✓ 再次获取成功');
      WriteLn('信号量可用许可: ', Sem.GetAvailableCount);
      Guard2 := nil; // 释放
    end
    else
      WriteLn('✗ 再次获取失败 - 无可用许可');
      
    Guard := nil; // 释放第一个守卫
  end
  else
    WriteLn('✗ 获取失败');
    
  WriteLn('最终信号量可用许可: ', Sem.GetAvailableCount);
  WriteLn;
end;

procedure DemoWithStatement;
var
  Sem: ISem;
begin
  WriteLn('=== with 语句演示 ===');
  
  Sem := MakeSem(1, 1);
  WriteLn('创建信号量: 初始=1, 最大=1');
  
  // 使用 with 语句的简洁写法
  with Sem.AcquireGuard do
  begin
    WriteLn('在 with 块中，持有许可数: ', GetCount);
    WriteLn('信号量可用许可: ', Sem.GetAvailableCount);
  end; // 自动释放
  
  WriteLn('with 块结束后信号量可用许可: ', Sem.GetAvailableCount);
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.sync.sem 完整使用示例');
    WriteLn('=====================================');
    WriteLn;
    
    DemoBasicUsage;
    DemoGuardUsage;
    DemoBulkOperations;
    DemoTryOperations;
    DemoWithStatement;
    
    WriteLn('=====================================');
    WriteLn('所有演示完成！');
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
end.
