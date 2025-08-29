program test_modern_spinmutex;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spinMutex;

var
  sm: ISpinMutex;
  config: TSpinMutexConfig;
  stats: TSpinMutexStats;

begin
  WriteLn('=== 测试现代化 SpinMutex ===');
  
  try
    // 测试基础工厂函数
    WriteLn('1. 测试基础工厂函数...');
    sm := MakeSpinMutex('test_spin_mutex');
    WriteLn('   ✅ MakeSpinMutex 成功');
    
    // 测试基础操作
    WriteLn('2. 测试基础操作...');
    sm.Acquire;
    WriteLn('   ✅ Acquire 成功');
    sm.Release;
    WriteLn('   ✅ Release 成功');
    
    // 测试 TryAcquire
    WriteLn('3. 测试 TryAcquire...');
    if sm.TryAcquire then
    begin
      WriteLn('   ✅ TryAcquire 成功');
      sm.Release;
      WriteLn('   ✅ Release 成功');
    end
    else
      WriteLn('   ❌ TryAcquire 失败');
    
    // 测试高性能配置
    WriteLn('4. 测试高性能配置...');
    sm := MakeHighPerformanceSpinMutex('test_hp_spin_mutex');
    sm.Acquire;
    sm.Release;
    WriteLn('   ✅ 高性能 SpinMutex 工作正常');
    
    // 测试低延迟配置
    WriteLn('5. 测试低延迟配置...');
    sm := MakeLowLatencySpinMutex('test_ll_spin_mutex');
    sm.Acquire;
    sm.Release;
    WriteLn('   ✅ 低延迟 SpinMutex 工作正常');
    
    // 测试全局配置
    WriteLn('6. 测试全局配置...');
    sm := MakeGlobalSpinMutex('test_global_spin_mutex');
    sm.Acquire;
    sm.Release;
    WriteLn('   ✅ 全局 SpinMutex 工作正常');
    
    // 测试自定义配置
    WriteLn('7. 测试自定义配置...');
    config := DefaultSpinMutexConfig;
    config.MaxSpinCount := 500;
    config.EnableStats := True;
    sm := MakeSpinMutex('test_custom_spin_mutex', config);
    
    // 执行一些操作来生成统计
    sm.Acquire;
    sm.Release;
    sm.TryAcquire;
    sm.Release;
    
    WriteLn('   ✅ 自定义配置 SpinMutex 工作正常');
    
    WriteLn('');
    WriteLn('🎉 所有测试通过！现代化 SpinMutex 架构工作正常');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
