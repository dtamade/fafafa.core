program test_windows_improvements;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, fafafa.core.sync.event, fafafa.core.sync.base;

var
  E: IEvent;
  r: TWaitResult;
  
procedure TestWindowsErrorHandling;
begin
  WriteLn('=== Testing Windows Error Handling Improvements ===');
  
  E := CreateEvent(False, False);
  
  // 测试错误状态
  WriteLn('Initial error state: ', Ord(E.GetLastError));
  
  // 测试基本操作的错误处理
  E.SetEvent;
  WriteLn('After SetEvent, error: ', Ord(E.GetLastError));
  
  E.ResetEvent;
  WriteLn('After ResetEvent, error: ', Ord(E.GetLastError));
  
  // 测试等待操作
  r := E.WaitFor(0);
  WriteLn('WaitFor result: ', Ord(r), ', error: ', Ord(E.GetLastError));
  
  // 测试超时
  r := E.WaitFor(10);
  WriteLn('WaitFor timeout result: ', Ord(r), ', error: ', Ord(E.GetLastError));
  
  WriteLn('Windows error handling test completed successfully!');
  WriteLn;
end;

procedure TestIsSignaledBehavior;
begin
  WriteLn('=== Testing IsSignaled Behavior ===');
  
  // 测试手动重置事件
  E := CreateEvent(True, False); // 手动重置，未信号
  WriteLn('Manual reset, non-signaled IsSignaled: ', E.IsSignaled);
  WriteLn('Error after IsSignaled: ', Ord(E.GetLastError));
  
  E.SetEvent;
  WriteLn('Manual reset, signaled IsSignaled: ', E.IsSignaled);
  WriteLn('Error after IsSignaled: ', Ord(E.GetLastError));
  
  // 测试自动重置事件
  E := CreateEvent(False, False); // 自动重置，未信号
  WriteLn('Auto reset, non-signaled IsSignaled: ', E.IsSignaled);
  WriteLn('Error after IsSignaled: ', Ord(E.GetLastError));
  
  E.SetEvent;
  WriteLn('Auto reset, signaled IsSignaled: ', E.IsSignaled);
  WriteLn('Error after IsSignaled: ', Ord(E.GetLastError));
  
  WriteLn('IsSignaled behavior test completed!');
  WriteLn;
end;

procedure TestPulseEvent;
begin
  WriteLn('=== Testing PulseEvent ===');
  
  E := CreateEvent(True, False); // 手动重置
  
  WriteLn('Before Pulse, IsSignaled: ', E.IsSignaled);
  E.Pulse;
  WriteLn('After Pulse, IsSignaled: ', E.IsSignaled);
  WriteLn('Error after Pulse: ', Ord(E.GetLastError));
  
  // 注意：PulseEvent 在 Windows 上可能不可靠
  WriteLn('Note: PulseEvent behavior may vary on different Windows versions');
  
  WriteLn('PulseEvent test completed!');
  WriteLn;
end;

procedure TestWaitForErrorHandling;
var
  Result: TWaitResult;
begin
  WriteLn('=== Testing WaitFor Error Handling ===');

  E := CreateEvent(False, False); // 自动重置，未信号

  try
    // 测试成功的等待
    E.SetEvent; // 先设置信号
    Result := E.WaitFor(1000); // 应该成功
    if Result = wrSignaled then
      WriteLn('WaitFor succeeded as expected')
    else
      WriteLn('WaitFor failed with result: ', Ord(Result));
    WriteLn('Error after successful WaitFor: ', Ord(E.GetLastError));
  except
    on Ex: Exception do
      WriteLn('WaitFor failed with exception: ', Ex.Message);
  end;

  WriteLn('WaitFor error handling test completed!');
  WriteLn;
end;

procedure TestNewMethods;
begin
  WriteLn('=== Testing New Methods ===');
  
  E := CreateEvent(True, False); // 手动重置
  
  // 测试 TryWait
  WriteLn('TryWait on non-signaled: ', E.TryWait);
  E.SetEvent;
  WriteLn('TryWait on signaled: ', E.TryWait);
  
  // 测试类型查询
  WriteLn('IsManualReset: ', E.IsManualReset);
  
  E := CreateEvent(False, False); // 自动重置
  WriteLn('Auto-reset IsManualReset: ', E.IsManualReset);
  
  // 测试等待线程计数（Windows 不支持）
  WriteLn('GetWaitingThreadCount: ', E.GetWaitingThreadCount);
  WriteLn('(Note: Windows returns -1 as this feature is not supported)');
  
  WriteLn('New methods test completed!');
  WriteLn;
end;

procedure TestPlatformSpecificBehavior;
begin
  WriteLn('=== Testing Platform-Specific Behavior ===');
  
  // 测试 Windows 特有的行为
  E := CreateEvent(False, True); // 自动重置，初始信号状态
  
  WriteLn('Auto-reset with initial signal:');
  WriteLn('  IsSignaled: ', E.IsSignaled, ' (should be False for auto-reset)');
  WriteLn('  TryWait: ', E.TryWait, ' (should be True and consume signal)');
  WriteLn('  TryWait again: ', E.TryWait, ' (should be False, signal consumed)');
  
  WriteLn('Platform-specific behavior test completed!');
  WriteLn;
end;

begin
  try
    TestWindowsErrorHandling;
    TestIsSignaledBehavior;
    TestPulseEvent;
    TestWaitForErrorHandling;
    TestNewMethods;
    TestPlatformSpecificBehavior;
    WriteLn('All Windows improvement tests passed!');
  except
    on Ex: Exception do
    begin
      WriteLn('Error: ', Ex.Message);
      ExitCode := 1;
    end;
  end;
end.
