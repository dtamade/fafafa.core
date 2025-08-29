program example_namedMutex_basic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.namedMutex;

procedure DemoBasicUsage;
var
  LMutex: INamedMutex;
begin
  WriteLn('=== 基本使用演示 ===');
  
  // 创建命名互斥锁
  LMutex := MakeNamedMutex('MyAppMutex');
  WriteLn('创建命名互斥锁: ', LMutex.GetName);
  WriteLn('是否为创建者: ', BoolToStr(LMutex.IsOwner, '是', '否'));
  
  // 获取互斥锁
  WriteLn('正在获取互斥锁...');
  LMutex.Acquire;
  try
    WriteLn('成功获取互斥锁，执行临界区代码');
    Sleep(1000); // 模拟工作
    WriteLn('临界区工作完成');
  finally
    LMutex.Release;
    WriteLn('释放互斥锁');
  end;
  
  WriteLn('');
end;

procedure DemoTryAcquire;
var
  LMutex: INamedMutex;
begin
  WriteLn('=== 非阻塞获取演示 ===');
  
  LMutex := MakeNamedMutex('MyAppMutex2');
  
  // 尝试立即获取
  if LMutex.TryAcquire then
  begin
    WriteLn('立即获取成功');
    try
      WriteLn('执行快速操作...');
      Sleep(500);
    finally
      LMutex.Release;
      WriteLn('释放互斥锁');
    end;
  end
  else
    WriteLn('无法立即获取互斥锁');
  
  // 尝试带超时获取
  WriteLn('尝试带超时获取 (1000ms)...');
  if LMutex.TryAcquire(1000) then
  begin
    WriteLn('在超时内获取成功');
    LMutex.Release;
  end
  else
    WriteLn('超时未能获取');
  
  WriteLn('');
end;

procedure DemoGlobalMutex;
var
  LMutex: INamedMutex;
begin
  WriteLn('=== 全局互斥锁演示 ===');
  
  // 创建全局命名互斥锁（跨会话）
  LMutex := MakeGlobalNamedMutex('MyGlobalMutex');
  WriteLn('创建全局命名互斥锁: ', LMutex.GetName);
  
  LMutex.Acquire;
  try
    WriteLn('获取全局互斥锁成功');
    WriteLn('此互斥锁可以跨进程、跨会话使用');
  finally
    LMutex.Release;
    WriteLn('释放全局互斥锁');
  end;
  
  WriteLn('');
end;

procedure DemoMultipleInstances;
var
  LMutex1, LMutex2: INamedMutex;
begin
  WriteLn('=== 多实例演示 ===');
  
  // 创建两个同名的互斥锁实例
  LMutex1 := MakeNamedMutex('SharedMutex');
  LMutex2 := MakeNamedMutex('SharedMutex');
  
  WriteLn('实例1 是否为创建者: ', BoolToStr(LMutex1.IsOwner, '是', '否'));
  WriteLn('实例2 是否为创建者: ', BoolToStr(LMutex2.IsOwner, '是', '否'));
  
  // 实例1 获取锁
  WriteLn('实例1 获取锁...');
  LMutex1.Acquire;
  try
    WriteLn('实例1 获取成功');
    
    // 实例2 尝试获取（应该失败）
    WriteLn('实例2 尝试立即获取...');
    if LMutex2.TryAcquire then
    begin
      WriteLn('实例2 获取成功（不应该发生）');
      LMutex2.Release;
    end
    else
      WriteLn('实例2 获取失败（正确行为）');
    
  finally
    LMutex1.Release;
    WriteLn('实例1 释放锁');
  end;
  
  // 现在实例2 应该能获取
  WriteLn('实例2 再次尝试获取...');
  if LMutex2.TryAcquire then
  begin
    WriteLn('实例2 获取成功');
    LMutex2.Release;
    WriteLn('实例2 释放锁');
  end
  else
    WriteLn('实例2 获取失败');
  
  WriteLn('');
end;

procedure DemoTimeoutSettings;
var
  LMutex: INamedMutex;
begin
  WriteLn('=== 超时设置演示 ===');
  
  LMutex := MakeNamedMutex('TimeoutMutex');
  
  // 设置默认超时
  LMutex.SetTimeout(2000);
  WriteLn('设置默认超时: ', LMutex.GetTimeout, ' ms');
  
  // 使用默认超时获取
  WriteLn('使用默认超时获取...');
  LMutex.Acquire; // 使用设置的超时值
  try
    WriteLn('获取成功');
  finally
    LMutex.Release;
  end;
  
  WriteLn('');
end;

begin
  try
    WriteLn('fafafa.core.sync.namedMutex 基本使用示例');
    WriteLn('==========================================');
    WriteLn('');
    
    DemoBasicUsage;
    DemoTryAcquire;
    DemoGlobalMutex;
    DemoMultipleInstances;
    DemoTimeoutSettings;
    
    WriteLn('所有演示完成！');
    WriteLn('');
    WriteLn('注意：');
    WriteLn('- 命名互斥锁可以在不同进程间共享');
    WriteLn('- 使用相同名称的互斥锁会引用同一个系统对象');
    WriteLn('- 进程异常退出时，系统会自动释放互斥锁');
    WriteLn('- Windows 平台支持 Global\ 前缀创建跨会话互斥锁');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  {$IFDEF WINDOWS}
  WriteLn('');
  WriteLn('按回车键退出...');
  ReadLn;
  {$ENDIF}
end.
