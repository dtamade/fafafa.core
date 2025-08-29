program simple_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.namedConditionVariable,
  fafafa.core.sync.namedMutex;

var
  LCondVar: INamedConditionVariable;
  LMutex: INamedMutex;
  LGuard: INamedMutexGuard;
  LConfig: TNamedConditionVariableConfig;
  LStats: TNamedConditionVariableStats;

begin
  WriteLn('=== fafafa.core.sync.namedConditionVariable 简单测试 ===');
  
  try
    // 测试基本创建
    WriteLn('1. 测试基本创建...');
    LCondVar := MakeNamedConditionVariable('test_simple');
    WriteLn('   ✓ 成功创建命名条件变量: ', LCondVar.GetName);
    
    // 测试配置
    WriteLn('2. 测试配置功能...');
    LConfig := LCondVar.GetConfig;
    WriteLn('   ✓ 默认超时时间: ', LConfig.TimeoutMs, 'ms');
    WriteLn('   ✓ 最大等待者: ', LConfig.MaxWaiters);
    
    // 测试与命名互斥锁配合
    WriteLn('3. 测试与命名互斥锁配合...');
    LMutex := MakeNamedMutex('test_simple_mutex');
    LGuard := LMutex.Lock;
    try
      WriteLn('   ✓ 成功获取互斥锁');
      
      // 测试超时等待
      if LCondVar.Wait(LMutex as ILock, 100) then
        WriteLn('   ! 意外：等待成功（应该超时）')
      else
        WriteLn('   ✓ 等待正确超时');
        
    finally
      LGuard := nil;
    end;
    
    // 测试信号操作
    WriteLn('4. 测试信号操作...');
    LCondVar.Signal;
    WriteLn('   ✓ Signal 操作成功');
    
    LCondVar.Broadcast;
    WriteLn('   ✓ Broadcast 操作成功');
    
    // 测试统计信息
    WriteLn('5. 测试统计信息...');
    LStats := LCondVar.GetStats;
    WriteLn('   ✓ 等待次数: ', LStats.WaitCount);
    WriteLn('   ✓ 信号次数: ', LStats.SignalCount);
    WriteLn('   ✓ 广播次数: ', LStats.BroadcastCount);
    
    // 测试工厂函数
    WriteLn('6. 测试工厂函数...');
    LCondVar := MakeGlobalNamedConditionVariable('test_global');
    WriteLn('   ✓ 全局命名条件变量创建成功');
    
    LCondVar := MakeNamedConditionVariableWithTimeout('test_timeout', 5000);
    LConfig := LCondVar.GetConfig;
    WriteLn('   ✓ 带超时配置创建成功，超时时间: ', LConfig.TimeoutMs, 'ms');
    
    LCondVar := MakeNamedConditionVariableWithStats('test_stats');
    LConfig := LCondVar.GetConfig;
    WriteLn('   ✓ 带统计配置创建成功，统计启用: ', LConfig.EnableStats);
    
    WriteLn;
    WriteLn('🎉 所有基本测试通过！');
    WriteLn('namedConditionVariable 模块工作正常。');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('测试完成。');
end.
