program test_timer_async_simple;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.duration,
  fafafa.core.time.timer,
  fafafa.core.thread in '..\..\src\fafafa.core.thread.pas';

var
  Counter: Integer = 0;
  Scheduler: ITimerScheduler;
  Timer: ITimer;
  Pool: IThreadPool;

procedure OnTimer;
begin
  Inc(Counter);
  WriteLn('Timer fired! Counter = ', Counter);
end;

begin
  WriteLn('=== Timer Async Callback Test ===');
  WriteLn;
  
  // 测试 1: 同步回调（默认）
  WriteLn('Test 1: Synchronous callback (default)');
  Counter := 0;
  Scheduler := CreateTimerScheduler(nil);
  Timer := Scheduler.ScheduleOnce(TDuration.FromMs(100), @OnTimer);
  Sleep(200);
  WriteLn('Expected: 1, Got: ', Counter);
  if Counter = 1 then
    WriteLn('PASS')
  else
    WriteLn('FAIL');
  Scheduler.Shutdown;
  WriteLn;
  
  // 测试 2: 异步回调（使用默认线程池）
  WriteLn('Test 2: Asynchronous callback (with default thread pool)');
  Counter := 0;
  Pool := GetDefaultThreadPool;
  Scheduler := CreateTimerScheduler(nil, Pool);
  Timer := Scheduler.ScheduleOnce(TDuration.FromMs(100), @OnTimer);
  Sleep(300); // 给异步回调更多时间
  WriteLn('Expected: 1, Got: ', Counter);
  if Counter = 1 then
    WriteLn('PASS')
  else
    WriteLn('FAIL');
  Scheduler.Shutdown;
  // 注意：不 shutdown 全局线程池
  WriteLn;
  
  // 测试 3: 周期性定时器（异步）
  WriteLn('Test 3: Periodic timer (asynchronous, 5 times)');
  Counter := 0;
  Pool := GetDefaultThreadPool;
  Scheduler := CreateTimerScheduler(nil, Pool);
  Timer := Scheduler.ScheduleAtFixedRate(TDuration.FromMs(50), TDuration.FromMs(50), @OnTimer);
  Sleep(300);
  Timer.Cancel;
  WriteLn('Expected: ~5, Got: ', Counter);
  if (Counter >= 4) and (Counter <= 6) then
    WriteLn('PASS')
  else
    WriteLn('FAIL');
  Scheduler.Shutdown;
  // 注意：不 shutdown 全局线程池
  WriteLn;
  
  WriteLn('=== All Tests Complete ===');
end.
