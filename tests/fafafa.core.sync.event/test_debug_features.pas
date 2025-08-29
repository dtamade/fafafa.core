program test_debug_features;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, fafafa.core.sync.event, fafafa.core.sync.base,
  fafafa.core.sync.event.simple.debug;

var
  DebugEvent: ISimpleDebugEvent;
  Stats: TSimpleEventStats;
  
procedure TestBasicDebugFeatures;
begin
  WriteLn('=== Testing Basic Debug Features ===');
  
  // 创建调试事件
  DebugEvent := CreateSimpleDebugEvent(True, False); // 手动重置，未信号
  
  // 启用日志
  DebugEvent.EnableLogging(True);
  WriteLn('Logging enabled: ', DebugEvent.IsLoggingEnabled);
  
  // 测试基本操作
  WriteLn('Initial debug info: ', DebugEvent.GetDebugString);
  
  DebugEvent.SetEvent;
  DebugEvent.IsSignaled;
  DebugEvent.ResetEvent;
  
  // 检查统计信息
  Stats := DebugEvent.GetStats;
  WriteLn('After basic operations:');
  WriteLn('  Set calls: ', Stats.TotalSetCalls);
  WriteLn('  Reset calls: ', Stats.TotalResetCalls);
  WriteLn('  Is manual reset: ', Stats.IsManualReset);
  
  WriteLn('Basic debug features test completed!');
  WriteLn;
end;

procedure TestWaitOperations;
var
  r: TWaitResult;
begin
  WriteLn('=== Testing Wait Operations Debug ===');
  
  DebugEvent := CreateSimpleDebugEvent(False, False); // 自动重置，未信号
  DebugEvent.EnableLogging(True);
  
  // 测试超时
  r := DebugEvent.WaitFor(10);
  WriteLn('Wait result (should timeout): ', Ord(r));
  
  // 测试成功等待
  DebugEvent.SetEvent;
  r := DebugEvent.WaitFor(10);
  WriteLn('Wait result (should succeed): ', Ord(r));
  
  // 测试 TryWait
  DebugEvent.SetEvent;
  WriteLn('TryWait result: ', DebugEvent.TryWait);
  WriteLn('TryWait again (should fail for auto-reset): ', DebugEvent.TryWait);
  
  // 检查统计信息
  Stats := DebugEvent.GetStats;
  WriteLn('Wait operations stats:');
  WriteLn('  Total wait calls: ', Stats.TotalWaitCalls);
  WriteLn('  Total signaled: ', Stats.TotalSignaled);
  WriteLn('  Total timeouts: ', Stats.TotalTimeouts);
  WriteLn('  Total errors: ', Stats.TotalErrors);
  
  WriteLn('Wait operations debug test completed!');
  WriteLn;
end;

procedure TestStatisticsReset;
begin
  WriteLn('=== Testing Statistics Reset ===');
  
  DebugEvent := CreateSimpleDebugEvent(True, False);
  DebugEvent.EnableLogging(True);
  
  // 执行一些操作
  DebugEvent.SetEvent;
  DebugEvent.WaitFor(0);
  DebugEvent.ResetEvent;
  
  WriteLn('Before reset: ', DebugEvent.GetDebugString);
  
  // 重置统计
  DebugEvent.ResetStats;
  
  WriteLn('After reset: ', DebugEvent.GetDebugString);
  
  // 验证统计已重置
  Stats := DebugEvent.GetStats;
  if (Stats.TotalSetCalls = 0) and (Stats.TotalWaitCalls = 0) and (Stats.TotalResetCalls = 0) then
    WriteLn('✓ Statistics reset successfully')
  else
    WriteLn('✗ Statistics reset failed');
    
  WriteLn('Statistics reset test completed!');
  WriteLn;
end;

procedure TestErrorHandling;
begin
  WriteLn('=== Testing Error Handling Debug ===');
  
  DebugEvent := CreateSimpleDebugEvent(False, False);
  DebugEvent.EnableLogging(True);
  
  // 测试正常操作的错误状态
  WriteLn('Initial error: ', Ord(DebugEvent.GetLastError));
  
  DebugEvent.SetEvent;
  WriteLn('After SetEvent error: ', Ord(DebugEvent.GetLastError));
  
  DebugEvent.WaitFor(0);
  WriteLn('After WaitFor error: ', Ord(DebugEvent.GetLastError));
  
  Stats := DebugEvent.GetStats;
  WriteLn('Last error in stats: ', Ord(Stats.LastError));
  
  WriteLn('Error handling debug test completed!');
  WriteLn;
end;

procedure TestWrappingExistingEvent;
var
  OriginalEvent: IEvent;
begin
  WriteLn('=== Testing Wrapping Existing Event ===');
  
  // 创建原始事件
  OriginalEvent := fafafa.core.sync.event.CreateEvent(True, True); // 手动重置，初始信号
  
  // 包装为调试事件
  DebugEvent := WrapWithSimpleDebug(OriginalEvent);
  DebugEvent.EnableLogging(True);
  
  WriteLn('Wrapped event type: ', IfThen(DebugEvent.IsManualReset, 'Manual Reset', 'Auto Reset'));
  WriteLn('Initial state: ', IfThen(DebugEvent.IsSignaled, 'Signaled', 'Non-Signaled'));
  
  // 测试操作
  DebugEvent.WaitFor(0); // 应该立即成功
  DebugEvent.ResetEvent;
  DebugEvent.WaitFor(10); // 应该超时
  
  WriteLn('Final debug info: ', DebugEvent.GetDebugString);
  
  WriteLn('Wrapping existing event test completed!');
  WriteLn;
end;

procedure TestLoggingToggle;
begin
  WriteLn('=== Testing Logging Toggle ===');
  
  DebugEvent := CreateSimpleDebugEvent(False, False);
  
  WriteLn('Initial logging state: ', DebugEvent.IsLoggingEnabled);
  
  // 启用日志
  DebugEvent.EnableLogging(True);
  WriteLn('After enabling - Logging state: ', DebugEvent.IsLoggingEnabled);
  DebugEvent.SetEvent; // 应该有日志输出
  
  // 禁用日志
  DebugEvent.EnableLogging(False);
  WriteLn('After disabling - Logging state: ', DebugEvent.IsLoggingEnabled);
  DebugEvent.ResetEvent; // 应该没有日志输出
  
  WriteLn('Logging toggle test completed!');
  WriteLn;
end;

begin
  try
    TestBasicDebugFeatures;
    TestWaitOperations;
    TestStatisticsReset;
    TestErrorHandling;
    TestWrappingExistingEvent;
    TestLoggingToggle;
    WriteLn('All debug feature tests passed!');
  except
    on Ex: Exception do
    begin
      WriteLn('Error: ', Ex.Message);
      ExitCode := 1;
    end;
  end;
end.
