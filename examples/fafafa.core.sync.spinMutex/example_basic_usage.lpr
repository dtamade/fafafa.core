program example_basic_usage;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spinMutex;

// ===== 基本用法示例 =====
procedure BasicUsageExample;
var
  LMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
begin
  WriteLn('=== 基本用法示例 ===');
  
  // 创建命名自旋互斥锁
  LMutex := CreateSpinMutex('MyAppSpinMutex');
  
  // RAII 模式：自动管理锁生命周期
  LGuard := LMutex.Lock;
  try
    WriteLn('在自旋互斥锁保护下执行临界区代码');
    WriteLn('持锁时间: ', LGuard.GetHoldTimeUs, ' 微秒');
    
    // 模拟一些工作
    Sleep(10);
    
  finally
    LGuard := nil; // 自动释放锁
  end;
  
  WriteLn('锁已自动释放');
  WriteLn;
end;

// ===== 非阻塞尝试示例 =====
procedure TryLockExample;
var
  LMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
begin
  WriteLn('=== 非阻塞尝试示例 ===');
  
  LMutex := CreateSpinMutex('TryLockExample');
  
  // 非阻塞尝试获取锁
  LGuard := LMutex.TryLock;
  if Assigned(LGuard) then
  begin
    WriteLn('成功获取锁，执行临界区代码');
    LGuard := nil; // 释放锁
  end
  else
    WriteLn('锁被其他进程占用');
    
  WriteLn;
end;

// ===== 带超时的获取示例 =====
procedure TimeoutExample;
var
  LMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
begin
  WriteLn('=== 带超时的获取示例 ===');
  
  LMutex := CreateSpinMutex('TimeoutExample');
  
  // 等待最多 100 毫秒
  LGuard := LMutex.TryLockFor(100);
  if Assigned(LGuard) then
  begin
    WriteLn('在超时内获取到锁');
    LGuard := nil;
  end
  else
    WriteLn('超时，未能获取锁');
    
  WriteLn;
end;

// ===== 纯自旋锁示例 =====
procedure SpinLockExample;
var
  LMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
begin
  WriteLn('=== 纯自旋锁示例 ===');
  
  LMutex := CreateSpinMutex('SpinLockExample');
  
  // 纯自旋获取（不降级为阻塞）
  LGuard := LMutex.SpinLock;
  if Assigned(LGuard) then
  begin
    WriteLn('通过纯自旋获取到锁');
    LGuard := nil;
  end
  else
    WriteLn('自旋失败，未获取到锁');
    
  // 限次自旋获取
  LGuard := LMutex.TrySpinLock(500);
  if Assigned(LGuard) then
  begin
    WriteLn('通过限次自旋获取到锁');
    LGuard := nil;
  end
  else
    WriteLn('限次自旋失败');
    
  WriteLn;
end;

// ===== 配置示例 =====
procedure ConfigurationExample;
var
  LMutex: ISpinMutex;
  LConfig: TSpinMutexConfig;
  LGuard: ISpinMutexGuard;
begin
  WriteLn('=== 配置示例 ===');
  
  // 使用自定义配置
  LConfig := DefaultSpinMutexConfig;
  LConfig.MaxSpinCount := 2000;
  LConfig.BackoffStrategy := sbsExponential;
  LConfig.EnableStats := True;
  
  LMutex := CreateSpinMutex('ConfigExample', LConfig);
  
  WriteLn('当前配置:');
  LConfig := LMutex.GetConfig;
  WriteLn('  最大自旋次数: ', LConfig.MaxSpinCount);
  WriteLn('  退避策略: ', Ord(LConfig.BackoffStrategy));
  WriteLn('  启用统计: ', LConfig.EnableStats);
  
  // 执行一些锁操作
  LGuard := LMutex.Lock;
  LGuard := nil;
  
  LGuard := LMutex.TryLock;
  LGuard := nil;
  
  WriteLn;
end;

// ===== 便利工厂函数示例 =====
procedure ConvenienceFactoryExample;
var
  LGlobalMutex: ISpinMutex;
  LHPMutex: ISpinMutex;
  LLLMutex: ISpinMutex;
  LGuard: ISpinMutexGuard;
begin
  WriteLn('=== 便利工厂函数示例 ===');
  
  // 全局自旋互斥锁
  LGlobalMutex := MakeGlobalSpinMutex('GlobalExample');
  WriteLn('全局自旋互斥锁: ', LGlobalMutex.GetName);
  
  // 高性能自旋互斥锁
  LHPMutex := MakeHighPerformanceSpinMutex('HPExample');
  WriteLn('高性能配置 - 自旋次数: ', LHPMutex.GetConfig.MaxSpinCount);
  
  // 低延迟自旋互斥锁
  LLLMutex := MakeLowLatencySpinMutex('LLExample');
  WriteLn('低延迟配置 - 自旋次数: ', LLLMutex.GetConfig.MaxSpinCount);
  
  // 测试高性能锁
  LGuard := LHPMutex.Lock;
  WriteLn('高性能锁获取成功');
  LGuard := nil;
  
  WriteLn;
end;

// ===== 统计信息示例 =====
procedure StatisticsExample;
var
  LMutex: ISpinMutex;
  LConfig: TSpinMutexConfig;
  LStats: TSpinMutexStats;
  LGuard: ISpinMutexGuard;
  i: Integer;
begin
  WriteLn('=== 统计信息示例 ===');
  
  // 启用统计的配置
  LConfig := DefaultSpinMutexConfig;
  LConfig.EnableStats := True;
  
  LMutex := CreateSpinMutex('StatsExample', LConfig);
  
  // 重置统计
  LMutex.ResetStats;
  
  // 执行多次锁操作
  for i := 1 to 5 do
  begin
    LGuard := LMutex.Lock;
    Sleep(1); // 模拟工作
    LGuard := nil;
  end;
  
  // 获取统计信息
  LStats := LMutex.GetStats;
  WriteLn('统计信息:');
  WriteLn('  总获取次数: ', LStats.AcquireCount);
  WriteLn('  自旋成功次数: ', LStats.SpinSuccessCount);
  WriteLn('  阻塞次数: ', LStats.BlockingCount);
  WriteLn('  总自旋次数: ', LStats.TotalSpinCount);
  WriteLn('  平均自旋次数: ', LStats.AvgSpinsPerAcquire:0:2);
  WriteLn('  自旋效率: ', LMutex.GetSpinEfficiency:0:2);
  WriteLn('  竞争率: ', LMutex.GetContentionRate:0:2);
  
  WriteLn;
end;

// ===== 错误处理示例 =====
procedure ErrorHandlingExample;
var
  LMutex: ISpinMutex;
begin
  WriteLn('=== 错误处理示例 ===');
  
  // 测试无效名称
  try
    LMutex := CreateSpinMutex('');
    WriteLn('错误：应该抛出异常');
  except
    on E: EInvalidArgument do
      WriteLn('正确捕获无效参数异常: ', E.Message);
  end;
  
  // 测试过长名称
  try
    LMutex := CreateSpinMutex(StringOfChar('A', 300));
    WriteLn('错误：应该抛出异常');
  except
    on E: EInvalidArgument do
      WriteLn('正确捕获名称过长异常: ', E.Message);
  end;
  
  WriteLn;
end;

// ===== 主程序 =====
begin
  WriteLn('fafafa.core.sync.spinMutex 使用示例');
  WriteLn('=====================================');
  WriteLn;
  
  try
    BasicUsageExample;
    TryLockExample;
    TimeoutExample;
    SpinLockExample;
    ConfigurationExample;
    ConvenienceFactoryExample;
    StatisticsExample;
    ErrorHandlingExample;
    
    WriteLn('所有示例执行完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
