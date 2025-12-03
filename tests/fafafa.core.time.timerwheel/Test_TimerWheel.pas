{
  Test_TimerWheel.pas - 时间轮定时器测试
  
  TDD: 先写测试，后写实现
  
  测试覆盖:
  1. 创建时间轮
  2. 添加定时器
  3. 取消定时器
  4. 定时器触发
  5. 重复定时器
}
program Test_TimerWheel;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.timerwheel;

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;
  FailCount: Integer = 0;
  CallbackCount: Integer = 0;

procedure Check(Condition: Boolean; const TestName: string);
begin
  Inc(TestCount);
  if Condition then
  begin
    Inc(PassCount);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailCount);
    WriteLn('  ✗ ', TestName, ' [FAILED]');
  end;
end;

procedure CheckEquals(Expected, Actual: Integer; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected=%d, actual=%d)', [TestName, Expected, Actual]));
end;

// 测试回调
procedure TestCallback(AData: Pointer);
begin
  Inc(CallbackCount);
end;

// ============================================================
// 测试: 时间轮创建和销毁
// ============================================================

procedure Test_TimerWheel_Create;
var
  Wheel: TTimerWheel;
begin
  WriteLn('Test_TimerWheel_Create:');
  
  // 创建64槽、10ms精度的时间轮
  Wheel := TTimerWheel.Create(64, 10);
  try
    Check(Wheel <> nil, 'Timer wheel created');
    CheckEquals(64, Wheel.SlotCount, 'Slot count = 64');
    CheckEquals(10, Wheel.TickInterval, 'Tick interval = 10ms');
    CheckEquals(0, Wheel.TimerCount, 'Initial timer count = 0');
  finally
    Wheel.Free;
  end;
end;

// ============================================================
// 测试: 添加和取消定时器
// ============================================================

procedure Test_TimerWheel_AddTimer;
var
  Wheel: TTimerWheel;
  TimerId: TTimerId;
begin
  WriteLn('Test_TimerWheel_AddTimer:');
  
  Wheel := TTimerWheel.Create(64, 10);
  try
    // 添加100ms后触发的定时器
    TimerId := Wheel.AddTimer(100, @TestCallback, nil);
    Check(TimerId <> INVALID_TIMER_ID, 'Timer added');
    CheckEquals(1, Wheel.TimerCount, 'Timer count = 1');
  finally
    Wheel.Free;
  end;
end;

procedure Test_TimerWheel_CancelTimer;
var
  Wheel: TTimerWheel;
  TimerId: TTimerId;
  Canceled: Boolean;
begin
  WriteLn('Test_TimerWheel_CancelTimer:');
  
  Wheel := TTimerWheel.Create(64, 10);
  try
    TimerId := Wheel.AddTimer(100, @TestCallback, nil);
    CheckEquals(1, Wheel.TimerCount, 'Timer count before cancel');
    
    Canceled := Wheel.CancelTimer(TimerId);
    Check(Canceled, 'Timer canceled');
    CheckEquals(0, Wheel.TimerCount, 'Timer count after cancel = 0');
    
    // 取消已取消的定时器应该返回False
    Canceled := Wheel.CancelTimer(TimerId);
    Check(not Canceled, 'Cancel already canceled timer returns false');
  finally
    Wheel.Free;
  end;
end;

// ============================================================
// 测试: 定时器触发
// ============================================================

procedure Test_TimerWheel_Tick_SingleTimer;
var
  Wheel: TTimerWheel;
  I: Integer;
begin
  WriteLn('Test_TimerWheel_Tick_SingleTimer:');
  
  CallbackCount := 0;
  
  Wheel := TTimerWheel.Create(64, 10);
  try
    // 添加50ms后触发的定时器 (5个tick)
    Wheel.AddTimer(50, @TestCallback, nil);
    
    // 推进4个tick，定时器不应触发
    for I := 1 to 4 do
      Wheel.Tick;
    CheckEquals(0, CallbackCount, 'Callback not called after 4 ticks');
    
    // 第5个tick，定时器应触发
    Wheel.Tick;
    CheckEquals(1, CallbackCount, 'Callback called after 5 ticks');
  finally
    Wheel.Free;
  end;
end;

procedure Test_TimerWheel_Tick_MultipleTimers;
var
  Wheel: TTimerWheel;
  I: Integer;
begin
  WriteLn('Test_TimerWheel_Tick_MultipleTimers:');
  
  CallbackCount := 0;
  
  Wheel := TTimerWheel.Create(64, 10);
  try
    // 添加多个定时器
    Wheel.AddTimer(20, @TestCallback, nil);  // 2 ticks
    Wheel.AddTimer(30, @TestCallback, nil);  // 3 ticks
    Wheel.AddTimer(50, @TestCallback, nil);  // 5 ticks
    
    CheckEquals(3, Wheel.TimerCount, 'Initial timer count');
    
    // 推进5个tick
    for I := 1 to 5 do
      Wheel.Tick;
    
    CheckEquals(3, CallbackCount, 'All 3 callbacks called');
    CheckEquals(0, Wheel.TimerCount, 'No timers left');
  finally
    Wheel.Free;
  end;
end;

// ============================================================
// 测试: 重复定时器
// ============================================================

procedure Test_TimerWheel_RepeatTimer;
var
  Wheel: TTimerWheel;
  I: Integer;
begin
  WriteLn('Test_TimerWheel_RepeatTimer:');
  
  CallbackCount := 0;
  
  Wheel := TTimerWheel.Create(64, 10);
  try
    // 添加20ms间隔的重复定时器
    Wheel.AddRepeatTimer(20, @TestCallback, nil);
    
    // 推进6个tick (60ms), 应该触发3次 (20ms, 40ms, 60ms)
    for I := 1 to 6 do
      Wheel.Tick;
    
    CheckEquals(3, CallbackCount, 'Repeat timer called 3 times');
    CheckEquals(1, Wheel.TimerCount, 'Repeat timer still active');
  finally
    Wheel.Free;
  end;
end;

// ============================================================
// 测试: 长延迟定时器
// ============================================================

procedure Test_TimerWheel_LongDelay;
var
  Wheel: TTimerWheel;
  I: Integer;
begin
  WriteLn('Test_TimerWheel_LongDelay:');
  
  CallbackCount := 0;
  
  // 64槽 x 10ms = 640ms最大延迟
  Wheel := TTimerWheel.Create(64, 10);
  try
    // 添加超过一轮的定时器 (700ms)
    Wheel.AddTimer(700, @TestCallback, nil);
    
    // 推进69个tick (690ms), 不应触发
    for I := 1 to 69 do
      Wheel.Tick;
    CheckEquals(0, CallbackCount, 'Not called before 700ms');
    
    // 第70个tick, 应触发
    Wheel.Tick;
    CheckEquals(1, CallbackCount, 'Called at 700ms');
  finally
    Wheel.Free;
  end;
end;

// ============================================================
// 主程序
// ============================================================

begin
  WriteLn;
  WriteLn('========================================');
  WriteLn('  Timer Wheel Tests');
  WriteLn('========================================');
  WriteLn;
  
  // 创建和销毁
  Test_TimerWheel_Create;
  
  // 添加和取消
  Test_TimerWheel_AddTimer;
  Test_TimerWheel_CancelTimer;
  
  // 定时器触发
  Test_TimerWheel_Tick_SingleTimer;
  Test_TimerWheel_Tick_MultipleTimers;
  
  // 重复定时器
  Test_TimerWheel_RepeatTimer;
  
  // 长延迟
  Test_TimerWheel_LongDelay;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
