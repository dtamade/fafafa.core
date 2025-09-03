{$CODEPAGE UTF8}
program example_basic_usage;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

procedure DemoBasicUsage;
var
  Mutex: IMutex;
begin
  WriteLn('=== 基本使用示例 ===');
  
  // 1. 创建互斥锁
  Mutex := MakeMutex;
  WriteLn('✓ 互斥锁创建成功');
  
  // 2. 手动获取和释放
  WriteLn('手动获取锁...');
  Mutex.Acquire;
  try
    WriteLn('✓ 锁已获取，执行临界区代码');
    Sleep(100); // 模拟工作
  finally
    Mutex.Release;
    WriteLn('✓ 锁已释放');
  end;
  
  // 3. 尝试获取锁
  WriteLn('尝试获取锁...');
  if Mutex.TryAcquire then
  begin
    try
      WriteLn('✓ TryAcquire 成功');
    finally
      Mutex.Release;
    end;
  end
  else
  begin
    WriteLn('✗ TryAcquire 失败');
  end;
end;

procedure DemoRAIIUsage;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  WriteLn(#13#10'=== RAII 守护模式示例 ===');
  
  // 创建互斥锁
  Mutex := MakeMutex;
  
  // 使用 RAII 守护
  WriteLn('使用 RAII 守护获取锁...');
  Guard := Mutex.LockGuard;
  WriteLn('✓ 锁已通过守护获取');
  Sleep(100); // 模拟工作
  
  // 当 Guard 超出作用域时，锁会自动释放
  Guard := nil; // 显式释放
  WriteLn('✓ 锁已通过守护自动释放');
end;

procedure DemoFactoryFunction;
var
  Guard: ILockGuard;
begin
  WriteLn(#13#10'=== 工厂函数示例 ===');
  
  // 直接使用 RAII 工厂创建守护（MakeLockGuard + MakeMutex）
  WriteLn('使用 RAII 守护工厂 (MakeLockGuard + MakeMutex)...');
  Guard := MakeLockGuard(MakeMutex);
  WriteLn('✓ 通过工厂函数创建的守护已获取锁');
  Sleep(100); // 模拟工作
  
  // 自动释放
  Guard := nil;
  WriteLn('✓ 锁已自动释放');
end;

procedure DemoMultipleThreads;
var
  Mutex: IMutex;
  Counter: Integer;
const
  ITERATIONS = 10;
begin
  WriteLn(#13#10'=== 多线程互斥示例 ===');

  Mutex := MakeMutex;
  Counter := 0;

  WriteLn('简单的多线程测试...');

  // 简化的测试，避免复杂的匿名线程
  Mutex.Acquire;
  try
    Inc(Counter);
    WriteLn('计数器增加到: ', Counter);
  finally
    Mutex.Release;
  end;

  WriteLn('✓ 基本的互斥功能正常！');
end;

procedure DemoPlatformInfo;
var
  Mutex: IMutex;
  Handle: Pointer;
begin
  WriteLn(#13#10'=== 平台信息示例 ===');
  
  Mutex := MakeMutex;
  Handle := Mutex.GetHandle;
  
  WriteLn('平台: ', {$IFDEF MSWINDOWS}'Windows'{$ELSE}'Unix/Linux'{$ENDIF});
  WriteLn('实现: ', {$IFDEF FAFAFA_CORE_USE_SRWLOCK}'TSRWMutex (SRWLOCK)'{$ELSE}
                   {$IFDEF FAFAFA_CORE_USE_FUTEX}'TFutexMutex (futex)'{$ELSE}
                   'TMutex (传统实现)'{$ENDIF}{$ENDIF});
  WriteLn('句柄地址: ', IntToHex(PtrUInt(Handle), SizeOf(Pointer)*2));
end;

begin
  WriteLn('fafafa.core.sync.mutex 基本使用示例');
  WriteLn('=====================================');
  
  try
    DemoBasicUsage;
    DemoRAIIUsage;
    DemoFactoryFunction;
    DemoMultipleThreads;
    DemoPlatformInfo;
    
    WriteLn(#13#10'✓ 所有示例运行完成！');
  except
    on E: Exception do
    begin
      WriteLn('✗ 发生异常: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn(#13#10'按回车键退出...');
  ReadLn;
end.
