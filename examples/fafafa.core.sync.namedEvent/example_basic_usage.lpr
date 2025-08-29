{$CODEPAGE UTF8}
program example_basic_usage;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync.namedEvent;

procedure DemoBasicUsage;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  WriteLn('=== 基本使用示例 ===');
  
  // 创建命名事件
  LEvent := MakeNamedEvent('BasicExample');
  WriteLn('✓ 创建事件: ', LEvent.GetName);
  if LEvent.IsManualReset then
    WriteLn('  事件类型: 手动重置')
  else
    WriteLn('  事件类型: 自动重置');
  
  // 非阻塞检查（应该返回 nil）
  LGuard := LEvent.TryWait;
  if Assigned(LGuard) then
    WriteLn('❌ 意外：事件应该未触发')
  else
    WriteLn('✓ 事件未触发（符合预期）');
  
  // 触发事件
  LEvent.SetEvent;
  WriteLn('✓ 事件已触发');
  
  // 现在应该能获取到事件
  LGuard := LEvent.TryWait;
  if Assigned(LGuard) then
  begin
    WriteLn('✓ 成功获取事件');
    WriteLn('  守卫名称: ', LGuard.GetName);
    if LGuard.IsSignaled then
      WriteLn('  守卫状态: 已触发')
    else
      WriteLn('  守卫状态: 未触发');
    LGuard := nil; // 释放守卫
  end
  else
    WriteLn('❌ 获取事件失败');
    
  WriteLn;
end;

procedure DemoManualResetEvent;
var
  LEvent: INamedEvent;
  LGuard1, LGuard2: INamedEventGuard;
begin
  WriteLn('=== 手动重置事件示例 ===');
  
  // 创建手动重置事件
  LEvent := MakeManualResetNamedEvent('ManualExample', False);
  WriteLn('✓ 创建手动重置事件: ', LEvent.GetName);
  
  // 触发事件
  LEvent.SetEvent;
  WriteLn('✓ 事件已触发');
  
  // 多个等待者都能获取
  LGuard1 := LEvent.TryWait;
  LGuard2 := LEvent.TryWait;
  
  if Assigned(LGuard1) and Assigned(LGuard2) then
    WriteLn('✓ 多个等待者都成功获取事件（手动重置特性）')
  else
    WriteLn('❌ 手动重置事件行为异常');
    
  // 重置事件
  LEvent.ResetEvent;
  WriteLn('✓ 事件已重置');
  
  // 现在应该获取不到
  LGuard1 := LEvent.TryWait;
  if not Assigned(LGuard1) then
    WriteLn('✓ 重置后无法获取事件（符合预期）')
  else
    WriteLn('❌ 重置后仍能获取事件');
    
  WriteLn;
end;

procedure DemoAutoResetEvent;
var
  LEvent: INamedEvent;
  LGuard1, LGuard2: INamedEventGuard;
begin
  WriteLn('=== 自动重置事件示例 ===');
  
  // 创建自动重置事件
  LEvent := MakeAutoResetNamedEvent('AutoExample', False);
  WriteLn('✓ 创建自动重置事件: ', LEvent.GetName);
  
  // 触发事件
  LEvent.SetEvent;
  WriteLn('✓ 事件已触发');
  
  // 第一个等待者能获取
  LGuard1 := LEvent.TryWait;
  if Assigned(LGuard1) then
    WriteLn('✓ 第一个等待者成功获取事件')
  else
    WriteLn('❌ 第一个等待者获取失败');
    
  // 第二个等待者应该获取不到（自动重置）
  LGuard2 := LEvent.TryWait;
  if not Assigned(LGuard2) then
    WriteLn('✓ 第二个等待者无法获取（自动重置特性）')
  else
    WriteLn('❌ 自动重置事件行为异常');
    
  WriteLn;
end;

procedure DemoTimeoutUsage;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LStartTime: TDateTime;
  LElapsed: Double;
begin
  WriteLn('=== 超时机制示例 ===');
  
  LEvent := MakeNamedEvent('TimeoutExample');
  WriteLn('✓ 创建事件: ', LEvent.GetName);
  
  // 测试短超时
  WriteLn('测试 100ms 超时...');
  LStartTime := Now;
  LGuard := LEvent.TryWaitFor(100);
  LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000;
  
  if not Assigned(LGuard) then
    WriteLn('✓ 超时返回 nil，耗时: ', FormatFloat('0.0', LElapsed), ' ms')
  else
    WriteLn('❌ 应该超时但返回了守卫');
    
  // 测试零超时
  WriteLn('测试零超时...');
  LStartTime := Now;
  LGuard := LEvent.TryWaitFor(0);
  LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000;
  
  if not Assigned(LGuard) then
    WriteLn('✓ 零超时立即返回，耗时: ', FormatFloat('0.0', LElapsed), ' ms')
  else
    WriteLn('❌ 零超时应该立即返回 nil');
    
  WriteLn;
end;

procedure DemoErrorHandling;
begin
  WriteLn('=== 错误处理示例 ===');
  
  try
    MakeNamedEvent('');
    WriteLn('❌ 应该抛出异常但没有');
  except
    on E: Exception do
      WriteLn('✓ 空名称正确抛出异常: ', E.Message);
  end;
  
  try
    MakeNamedEvent('Test/Invalid');
    WriteLn('❌ 应该抛出异常但没有');
  except
    on E: Exception do
      WriteLn('✓ 无效字符正确抛出异常: ', E.Message);
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.namedEvent 基本使用示例');
  WriteLn('==========================================');
  WriteLn;
  
  try
    DemoBasicUsage;
    DemoManualResetEvent;
    DemoAutoResetEvent;
    DemoTimeoutUsage;
    DemoErrorHandling;
    
    WriteLn('🎉 所有示例运行完成！');
  except
    on E: Exception do
    begin
      WriteLn('❌ 示例运行出错: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
