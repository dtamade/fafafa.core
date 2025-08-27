program example_windows_spincount;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.sync.mutex;

var
  Mutex: IMutex;
  Counter: Integer = 0;

procedure DemoBasicUsage;
begin
  WriteLn('=== 基本互斥锁使用 ===');
  
  Mutex := MakeMutex;
  
  WriteLn('获取锁...');
  Mutex.Acquire;
  
  WriteLn('执行临界区代码...');
  Inc(Counter);
  WriteLn('计数器值: ', Counter);
  
  WriteLn('释放锁...');
  Mutex.Release;
  
  WriteLn('基本使用演示完成');
  WriteLn;
end;

procedure DemoRecursiveLocking;
begin
  WriteLn('=== 递归锁定演示 ===');
  
  Mutex := MakeMutex;
  
  WriteLn('第一次获取锁...');
  Mutex.Acquire;
  
  WriteLn('递归获取锁（同一线程）...');
  Mutex.Acquire;
  
  WriteLn('执行嵌套临界区代码...');
  Inc(Counter);
  WriteLn('计数器值: ', Counter);
  
  WriteLn('释放第一层锁...');
  Mutex.Release;
  
  WriteLn('释放第二层锁...');
  Mutex.Release;
  
  WriteLn('递归锁定演示完成');
  WriteLn;
end;

procedure DemoTryAcquire;
begin
  WriteLn('=== TryAcquire 演示 ===');
  
  Mutex := MakeMutex;
  
  WriteLn('尝试获取锁（应该成功）...');
  if Mutex.TryAcquire then
  begin
    WriteLn('✓ 成功获取锁');
    
    WriteLn('再次尝试获取锁（递归，应该成功）...');
    if Mutex.TryAcquire then
    begin
      WriteLn('✓ 递归获取成功');
      Mutex.Release;
    end
    else
      WriteLn('✗ 递归获取失败');
    
    Mutex.Release;
  end
  else
    WriteLn('✗ 获取锁失败');
  
  WriteLn('TryAcquire 演示完成');
  WriteLn;
end;



{$IFDEF WINDOWS}
procedure DemoWindowsSpinCount;
var
  WindowsMutex: IMutex;
  WindowsImpl: fafafa.core.sync.mutex.windows.TMutex;
  OldSpinCount: DWORD;
begin
  WriteLn('=== Windows 自旋计数优化演示 ===');
  
  // 创建带自定义自旋计数的互斥锁
  WriteLn('创建带自定义自旋计数 (8000) 的互斥锁...');
  WindowsMutex := MakeMutex(8000);
  
  // 如果需要访问 Windows 特有功能，需要类型转换
  if WindowsMutex is fafafa.core.sync.mutex.windows.TMutex then
  begin
    WindowsImpl := WindowsMutex as fafafa.core.sync.mutex.windows.TMutex;
    
    WriteLn('调整自旋计数为 2000...');
    OldSpinCount := WindowsImpl.SetSpinCount(2000);
    WriteLn('之前的自旋计数: ', OldSpinCount);
  end;
  
  WriteLn('使用优化后的互斥锁...');
  WindowsMutex.Acquire;
  Inc(Counter);
  WriteLn('计数器值: ', Counter);
  WindowsMutex.Release;
  
  WriteLn('Windows 优化演示完成');
  WriteLn;
end;
{$ENDIF}

begin
  try
    WriteLn('fafafa.core.sync.mutex 使用示例');
    WriteLn('================================');
    WriteLn;
    
    DemoBasicUsage;
    DemoRecursiveLocking;
    DemoTryAcquire;
    
    {$IFDEF WINDOWS}
    DemoWindowsSpinCount;
    {$ELSE}
    WriteLn('注意: Windows 特有功能仅在 Windows 平台可用');
    WriteLn;
    {$ENDIF}
    
    WriteLn('所有演示完成！最终计数器值: ', Counter);
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
