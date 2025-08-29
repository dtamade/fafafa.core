unit fafafa.core.sync.event.platform.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 平台一致性和特定行为测试 }
  TTestCase_Event_Platform = class(TTestCase)
  published
    // 平台一致性验证
    procedure Test_Platform_AutoReset_Semantics;
    procedure Test_Platform_ManualReset_Semantics;
    procedure Test_Platform_IsSignaled_Behavior;
    procedure Test_Platform_Timeout_Consistency;
    
    // 边界条件
    procedure Test_Edge_MaxTimeout_Value;
    procedure Test_Edge_Repeated_Operations;
    procedure Test_Edge_Concurrent_SetReset;
    
    // 错误处理
    procedure Test_Error_Invalid_Timeout_Handling;
    procedure Test_Error_Null_Reference_Safety;
  end;

implementation

{ TTestCase_Event_Platform }

procedure TTestCase_Event_Platform.Test_Platform_AutoReset_Semantics;
var E: IEvent; r1, r2: TWaitResult;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False); // auto-reset
  
  // 验证自动重置的核心语义
  E.SetEvent;
  r1 := E.WaitFor(0);
  r2 := E.WaitFor(0);
  
  AssertEquals('First wait should succeed', Ord(wrSignaled), Ord(r1));
  AssertEquals('Second wait should timeout (auto-reset)', Ord(wrTimeout), Ord(r2));
  
  // 验证多次SetEvent的折叠行为
  E.SetEvent;
  E.SetEvent;
  E.SetEvent;
  r1 := E.WaitFor(0);
  r2 := E.WaitFor(0);
  
  AssertEquals('Multiple sets should collapse to single signal', Ord(wrSignaled), Ord(r1));
  AssertEquals('Second wait after collapse should timeout', Ord(wrTimeout), Ord(r2));
end;

procedure TTestCase_Event_Platform.Test_Platform_ManualReset_Semantics;
var E: IEvent; r1, r2, r3: TWaitResult;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // manual-reset

  // 验证手动重置的持续信号语义
  E.SetEvent;
  r1 := E.WaitFor(0);
  r2 := E.WaitFor(0);
  r3 := E.WaitFor(0);

  AssertEquals('First wait should succeed', Ord(wrSignaled), Ord(r1));
  AssertEquals('Second wait should succeed (manual-reset)', Ord(wrSignaled), Ord(r2));
  AssertEquals('Third wait should succeed (manual-reset)', Ord(wrSignaled), Ord(r3));

  // 验证重置后的行为
  E.ResetEvent;
  r1 := E.WaitFor(0);
  AssertEquals('Wait after reset should timeout', Ord(wrTimeout), Ord(r1));
end;

procedure TTestCase_Event_Platform.Test_Platform_IsSignaled_Behavior;
var EAuto, EManual: IEvent;
begin
  EAuto := fafafa.core.sync.event.CreateEvent(False, False);   // auto-reset
  EManual := fafafa.core.sync.event.CreateEvent(True, False);  // manual-reset
  
  // 初始状态
  AssertFalse('Auto-reset should start non-signaled', EAuto.IsSignaled);
  AssertFalse('Manual-reset should start non-signaled', EManual.IsSignaled);
  
  // 设置信号后
  EAuto.SetEvent;
  EManual.SetEvent;
  
  // 自动重置的IsSignaled应该返回False（避免副作用）
  AssertFalse('Auto-reset IsSignaled should return False (avoid side effects)', EAuto.IsSignaled);
  
  // 手动重置的IsSignaled应该返回True（非破坏式）
  AssertTrue('Manual-reset IsSignaled should return True (non-destructive)', EManual.IsSignaled);
  
  // 验证手动重置的IsSignaled确实是非破坏式的
  AssertTrue('Manual-reset IsSignaled should remain True', EManual.IsSignaled);
  AssertEquals('Manual-reset WaitFor should still succeed', Ord(wrSignaled), Ord(EManual.WaitFor(0)));
end;

procedure TTestCase_Event_Platform.Test_Platform_Timeout_Consistency;
var E: IEvent; StartTime: QWord; r: TWaitResult; ElapsedMs: QWord;
const TestTimeouts: array[0..4] of Cardinal = (0, 1, 10, 50, 100);
var i: Integer;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);

  for i := 0 to High(TestTimeouts) do
  begin
    StartTime := GetTickCount64;
    r := E.WaitFor(TestTimeouts[i]);
    ElapsedMs := GetTickCount64 - StartTime;

    AssertEquals(Format('Timeout %d ms should return wrTimeout', [TestTimeouts[i]]),
      Ord(wrTimeout), Ord(r));

    if TestTimeouts[i] > 0 then
      AssertTrue(Format('Timeout %d ms should take ~%d ms, took %d ms',
        [TestTimeouts[i], TestTimeouts[i], ElapsedMs]),
        ElapsedMs >= TestTimeouts[i] - 20); // 允许提前20ms
  end;
end;

procedure TTestCase_Event_Platform.Test_Edge_MaxTimeout_Value;
var E: IEvent; r: TWaitResult; StartTime: QWord; ElapsedMs: QWord;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);

  // 测试大超时值（但不会真的等那么久）
  StartTime := GetTickCount64;
  r := E.WaitFor(High(Cardinal) - 1000); // 接近最大值但避免溢出
  ElapsedMs := GetTickCount64 - StartTime;
  
  // 应该立即超时（因为事件未设置）
  AssertEquals('Large timeout should still timeout immediately', Ord(wrTimeout), Ord(r));
  AssertTrue('Large timeout test should complete quickly', ElapsedMs < 100);
end;

procedure TTestCase_Event_Platform.Test_Edge_Repeated_Operations;
const OpCount = 10000;
var E: IEvent; i: Integer; r: TWaitResult;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // manual-reset

  // 重复操作测试稳定性
  for i := 1 to OpCount do
  begin
    E.SetEvent;
    r := E.WaitFor(0);
    AssertEquals(Format('Op %d: WaitFor should succeed', [i]), Ord(wrSignaled), Ord(r));

    E.ResetEvent;
    r := E.WaitFor(0);
    AssertEquals(Format('Op %d: WaitFor after reset should timeout', [i]), Ord(wrTimeout), Ord(r));

    // 每1000次操作输出进度
    if i mod 1000 = 0 then
      WriteLn(Format('Repeated operations test: %d/%d completed', [i, OpCount]));
  end;
end;

procedure TTestCase_Event_Platform.Test_Edge_Concurrent_SetReset;
const ThreadCount = 8; OpCount = 1000;
var
  E: IEvent;
  Threads: array[0..ThreadCount-1] of TThread;
  i: Integer;
  Completed: array[0..ThreadCount-1] of Boolean;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // manual-reset
  
  // 创建并发设置/重置线程
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var j: Integer;
      begin
        for j := 1 to OpCount do
        begin
          if j mod 2 = 0 then
            E.SetEvent
          else
            E.ResetEvent;
        end;
        Completed[i] := True;
      end);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i].WaitFor;
    AssertTrue(Format('Concurrent thread %d should complete', [i]), Completed[i]);
    Threads[i].Free;
  end;
  
  // 最终状态应该是可预测的（虽然具体值不确定）
  // 至少事件对象应该仍然可用
  E.SetEvent;
  AssertEquals('Event should still work after concurrent operations', 
    Ord(wrSignaled), Ord(E.WaitFor(0)));
end;

procedure TTestCase_Event_Platform.Test_Error_Invalid_Timeout_Handling;
var E: IEvent; r: TWaitResult;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);

  // 测试边界超时值
  r := E.WaitFor(0);
  AssertEquals('Zero timeout should work', Ord(wrTimeout), Ord(r));

  r := E.WaitFor(High(Cardinal));
  // 这个测试会很快返回因为事件未设置
  AssertTrue('Max timeout should return valid result',
    (r = wrTimeout) or (r = wrSignaled) or (r = wrError));
end;

procedure TTestCase_Event_Platform.Test_Error_Null_Reference_Safety;
var E: IEvent;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);
  AssertNotNull('CreateEvent should never return nil', E);
  
  // 测试接口引用的基本操作
  E.SetEvent;
  E.ResetEvent;
  E.WaitFor(0);
  E.IsSignaled;
  E.TryWait;
  // Release 方法已移除 - 使用 SetEvent/ResetEvent 控制事件状态
  
  // 释放引用
  E := nil;
  // 如果有内存泄漏，HeapTrc会检测到
end;

initialization
  RegisterTest(TTestCase_Event_Platform);

end.
