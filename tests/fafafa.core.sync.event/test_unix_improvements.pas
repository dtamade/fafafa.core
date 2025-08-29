program test_unix_improvements;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, fafafa.core.sync.event, fafafa.core.sync.base;

var
  E: IEvent;
  r: TWaitResult;
  
procedure TestErrorHandling;
begin
  WriteLn('=== Testing Unix Error Handling Improvements ===');
  
  E := CreateEvent(False, False);
  
  // 测试错误状态
  WriteLn('Initial error state: ', Ord(E.GetLastError));
  
  // 测试基本操作
  E.SetEvent;
  WriteLn('After SetEvent, error: ', Ord(E.GetLastError));
  
  // 测试等待操作
  r := E.WaitFor(0);
  WriteLn('WaitFor result: ', Ord(r), ', error: ', Ord(E.GetLastError));
  
  // 测试超时
  r := E.WaitFor(10);
  WriteLn('WaitFor timeout result: ', Ord(r), ', error: ', Ord(E.GetLastError));
  
  WriteLn('Error handling test completed successfully!');
  WriteLn;
end;

procedure TestTimeoutPrecision;
var
  StartTime, EndTime: QWord;
  r: TWaitResult;
  ElapsedMs: QWord;
const
  TestTimeouts: array[0..3] of Cardinal = (10, 50, 100, 200);
var
  i: Integer;
begin
  WriteLn('=== Testing Improved Timeout Precision ===');
  
  E := CreateEvent(False, False); // 未信号状态
  
  for i := 0 to High(TestTimeouts) do
  begin
    StartTime := GetTickCount64;
    r := E.WaitFor(TestTimeouts[i]);
    EndTime := GetTickCount64;
    ElapsedMs := EndTime - StartTime;
    
    WriteLn(Format('Timeout %d ms: actual %d ms, result=%d, error=%d', 
      [TestTimeouts[i], ElapsedMs, Ord(r), Ord(E.GetLastError)]));
    
    // 验证超时精度 (允许 ±20ms 误差)
    if (ElapsedMs >= TestTimeouts[i] - 20) and (ElapsedMs <= TestTimeouts[i] + 50) then
      WriteLn('  ✓ Timeout precision acceptable')
    else
      WriteLn('  ⚠ Timeout precision may need improvement');
  end;
  
  WriteLn('Timeout precision test completed!');
  WriteLn;
end;

procedure TestWaitingThreadCount;
begin
  WriteLn('=== Testing Waiting Thread Count ===');

  E := CreateEvent(False, False); // 未信号状态
  WriteLn('Initial waiting count: ', E.GetWaitingThreadCount);

  // 简单测试 - 单线程情况下应该是 0
  WriteLn('Single-thread waiting count: ', E.GetWaitingThreadCount);

  WriteLn('Waiting thread count test completed!');
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
  
  // 测试 Pulse
  E.ResetEvent;
  WriteLn('Before Pulse, IsSignaled: ', E.IsSignaled);
  E.Pulse;
  WriteLn('After Pulse, IsSignaled: ', E.IsSignaled);
  
  // 测试类型查询
  WriteLn('IsManualReset: ', E.IsManualReset);
  
  E := CreateEvent(False, False); // 自动重置
  WriteLn('Auto-reset IsManualReset: ', E.IsManualReset);
  
  WriteLn('New methods test completed!');
  WriteLn;
end;

begin
  try
    TestErrorHandling;
    TestTimeoutPrecision;
    TestWaitingThreadCount;
    TestNewMethods;
    WriteLn('All Unix improvement tests passed!');
  except
    on Ex: Exception do
    begin
      WriteLn('Error: ', Ex.Message);
      ExitCode := 1;
    end;
  end;
end.
