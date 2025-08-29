program simple_spinmutex_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync.spinMutex, fafafa.core.sync.spinMutex.base;

var
  Mutex: ISpinMutex;
  Guard: ISpinMutexGuard;
  Config: TSpinMutexConfig;
  Stats: TSpinMutexStats;
  i: Integer;
  TimeoutGuard: ISpinMutexGuard;

begin
  WriteLn('=== SpinMutex 简单测试 ===');
  
  try
    // 测试 1: 基本创建和配置
    WriteLn('测试 1: 基本创建和配置');
    Mutex := MakeSpinMutex('test_mutex');
    if Mutex = nil then
    begin
      WriteLn('错误: 无法创建 SpinMutex');
      Halt(1);
    end;
    
    Config := Mutex.GetConfig;
    WriteLn('  默认配置:');
    WriteLn('    MaxSpinCount: ', Config.MaxSpinCount);
    WriteLn('    BackoffStrategy: ', Ord(Config.BackoffStrategy));
    WriteLn('    DefaultTimeoutMs: ', Config.DefaultTimeoutMs);
    WriteLn('  ✓ 基本创建成功');
    
    // 测试 2: RAII 锁守卫
    WriteLn('测试 2: RAII 锁守卫');
    Guard := Mutex.Lock('test_guard');
    if Guard = nil then
    begin
      WriteLn('错误: 无法获取锁守卫');
      Halt(1);
    end;
    
    WriteLn('  守卫名称: ', Guard.GetName);
    WriteLn('  持锁时间: ', Guard.GetHoldTimeUs, ' μs');
    WriteLn('  守卫有效: ', Guard.IsValid);
    
    // 手动释放
    Guard.Release;
    WriteLn('  ✓ RAII 守卫测试成功');
    
    // 测试 3: 自旋锁性能
    WriteLn('测试 3: 自旋锁性能');
    Config := Mutex.GetConfig;
    Config.EnableStats := True;
    Mutex.UpdateConfig(Config);
    Mutex.ResetStats;
    
    // 执行多次锁操作
    for i := 1 to 100 do
    begin
      Guard := Mutex.TryLock('perf_test');
      if Guard <> nil then
      begin
        // 模拟一些工作
        Sleep(1);
        Guard.Release;
      end;
    end;
    
    Stats := Mutex.GetStats;
    WriteLn('  性能统计:');
    WriteLn('    获取次数: ', Stats.AcquireCount);
    WriteLn('    自旋成功次数: ', Stats.SpinSuccessCount);
    WriteLn('    平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
    WriteLn('    自旋效率: ', (Stats.SpinEfficiency * 100):0:1, '%');
    WriteLn('  ✓ 性能测试成功');
    
    // 测试 4: 不同配置
    WriteLn('测试 4: 不同配置');
    
    // 高性能配置
    Mutex := MakeHighPerformanceSpinMutex('high_perf_mutex');
    Config := Mutex.GetConfig;
    WriteLn('  高性能配置:');
    WriteLn('    MaxSpinCount: ', Config.MaxSpinCount);
    WriteLn('    BackoffStrategy: ', Ord(Config.BackoffStrategy));
    WriteLn('    EnableStats: ', Config.EnableStats);

    // 低延迟配置
    Mutex := MakeLowLatencySpinMutex('low_latency_mutex');
    Config := Mutex.GetConfig;
    WriteLn('  低延迟配置:');
    WriteLn('    MaxSpinCount: ', Config.MaxSpinCount);
    WriteLn('    BackoffStrategy: ', Ord(Config.BackoffStrategy));
    WriteLn('    DefaultTimeoutMs: ', Config.DefaultTimeoutMs);
    WriteLn('  ✓ 配置测试成功');
    
    // 测试 5: 超时测试
    WriteLn('测试 5: 超时测试');
    Mutex := MakeSpinMutex('timeout_test');
    
    // 先获取锁
    Guard := Mutex.Lock('holder');
    if Guard = nil then
    begin
      WriteLn('错误: 无法获取初始锁');
      Halt(1);
    end;
    
    // 尝试带超时的获取（应该失败）
    TimeoutGuard := Mutex.TryLockFor(100, 'timeout_attempt');
    if TimeoutGuard <> nil then
    begin
      WriteLn('警告: 超时测试意外成功');
      TimeoutGuard.Release;
    end
    else
    begin
      WriteLn('  ✓ 超时测试正确失败');
    end;
    
    // 释放初始锁
    Guard.Release;
    
    // 现在应该能够获取
    Guard := Mutex.TryLockFor(100, 'success_attempt');
    if Guard = nil then
    begin
      WriteLn('错误: 释放后无法获取锁');
      Halt(1);
    end;
    Guard.Release;
    WriteLn('  ✓ 超时测试成功');
    
    // 测试 6: 兼容性测试
    WriteLn('测试 6: 兼容性测试（已弃用接口）');
    Mutex := MakeSpinMutex(500);
    if Mutex = nil then
    begin
      WriteLn('错误: 兼容接口创建失败');
      Halt(1);
    end;
    
    // 使用传统接口
    Mutex.Acquire;
    Mutex.Release;
    WriteLn('  ✓ 兼容性测试成功');
    
    WriteLn('');
    WriteLn('=== 所有测试通过! ===');
    
  except
    on E: Exception do
    begin
      WriteLn('测试失败: ', E.Message);
      Halt(1);
    end;
  end;
end.
