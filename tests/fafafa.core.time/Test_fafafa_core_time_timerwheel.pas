{$mode objfpc}{$H+}{$J-}
{$I ..\..\src\fafafa.core.settings.inc}

unit Test_fafafa_core_time_timerwheel;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.timerwheel;

type
  { TTestTimerWheel - TTimerWheel 测试 }
  TTestTimerWheel = class(TTestCase)
  private
    FCallbackCount: Integer;
    FLastCallbackData: Pointer;
    
    class var GCallbackCount: Integer;
    class var GLastCallbackData: Pointer;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 构造函数测试
    procedure Test_Create_DefaultParams;
    procedure Test_Create_CustomParams;
    procedure Test_Create_InitialTimerCountZero;
    
    // AddTimer 测试
    procedure Test_AddTimer_ReturnsValidId;
    procedure Test_AddTimer_IncrementsCount;
    procedure Test_AddTimer_MultipleTimers;
    
    // AddRepeatTimer 测试
    procedure Test_AddRepeatTimer_ReturnsValidId;
    procedure Test_AddRepeatTimer_IncrementsCount;
    
    // CancelTimer 测试
    procedure Test_CancelTimer_ValidId_ReturnsTrue;
    procedure Test_CancelTimer_InvalidId_ReturnsFalse;
    procedure Test_CancelTimer_DecrementsCount;
    procedure Test_CancelTimer_SameIdTwice_ReturnsFalse;
    
    // Tick 测试
    procedure Test_Tick_FiresTimerAfterDelay;
    procedure Test_Tick_RepeatingTimerFiresMultipleTimes;
    procedure Test_Tick_TimerNotFiredBeforeDelay;
    
    // 属性测试
    procedure Test_SlotCount_ReturnsConfiguredValue;
    procedure Test_TickInterval_ReturnsConfiguredValue;
    procedure Test_TimerCount_ReflectsActiveTimers;
  end;

var
  GTestCallbackFired: Boolean;
  GTestCallbackData: Pointer;
  GTestCallbackFireCount: Integer;

procedure TestTimerCallback(AData: Pointer);

implementation

procedure TestTimerCallback(AData: Pointer);
begin
  GTestCallbackFired := True;
  GTestCallbackData := AData;
  Inc(GTestCallbackFireCount);
end;

{ TTestTimerWheel }

procedure TTestTimerWheel.SetUp;
begin
  inherited SetUp;
  FCallbackCount := 0;
  FLastCallbackData := nil;
  GCallbackCount := 0;
  GLastCallbackData := nil;
  GTestCallbackFired := False;
  GTestCallbackData := nil;
  GTestCallbackFireCount := 0;
end;

procedure TTestTimerWheel.TearDown;
begin
  inherited TearDown;
end;

procedure TTestTimerWheel.Test_Create_DefaultParams;
var
  Wheel: TTimerWheel;
begin
  Wheel := TTimerWheel.Create;
  try
    CheckEquals(64, Wheel.SlotCount, 'Default slot count should be 64');
    CheckEquals(10, Wheel.TickInterval, 'Default tick interval should be 10ms');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_Create_CustomParams;
var
  Wheel: TTimerWheel;
begin
  Wheel := TTimerWheel.Create(128, 20);
  try
    CheckEquals(128, Wheel.SlotCount, 'Slot count should be 128');
    CheckEquals(20, Wheel.TickInterval, 'Tick interval should be 20ms');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_Create_InitialTimerCountZero;
var
  Wheel: TTimerWheel;
begin
  Wheel := TTimerWheel.Create;
  try
    CheckEquals(0, Wheel.TimerCount, 'Initial timer count should be 0');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_AddTimer_ReturnsValidId;
var
  Wheel: TTimerWheel;
  Id: TTimerId;
begin
  Wheel := TTimerWheel.Create;
  try
    Id := Wheel.AddTimer(100, @TestTimerCallback, nil);
    CheckTrue(Id <> INVALID_TIMER_ID, 'AddTimer should return valid ID');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_AddTimer_IncrementsCount;
var
  Wheel: TTimerWheel;
begin
  Wheel := TTimerWheel.Create;
  try
    CheckEquals(0, Wheel.TimerCount, 'Initial count should be 0');
    Wheel.AddTimer(100, @TestTimerCallback, nil);
    CheckEquals(1, Wheel.TimerCount, 'Count should be 1 after adding timer');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_AddTimer_MultipleTimers;
var
  Wheel: TTimerWheel;
  Id1, Id2, Id3: TTimerId;
begin
  Wheel := TTimerWheel.Create;
  try
    Id1 := Wheel.AddTimer(100, @TestTimerCallback, nil);
    Id2 := Wheel.AddTimer(200, @TestTimerCallback, nil);
    Id3 := Wheel.AddTimer(300, @TestTimerCallback, nil);
    
    CheckTrue(Id1 <> Id2, 'Timer IDs should be unique');
    CheckTrue(Id2 <> Id3, 'Timer IDs should be unique');
    CheckTrue(Id1 <> Id3, 'Timer IDs should be unique');
    CheckEquals(3, Wheel.TimerCount, 'Count should be 3 after adding 3 timers');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_AddRepeatTimer_ReturnsValidId;
var
  Wheel: TTimerWheel;
  Id: TTimerId;
begin
  Wheel := TTimerWheel.Create;
  try
    Id := Wheel.AddRepeatTimer(100, @TestTimerCallback, nil);
    CheckTrue(Id <> INVALID_TIMER_ID, 'AddRepeatTimer should return valid ID');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_AddRepeatTimer_IncrementsCount;
var
  Wheel: TTimerWheel;
begin
  Wheel := TTimerWheel.Create;
  try
    CheckEquals(0, Wheel.TimerCount, 'Initial count should be 0');
    Wheel.AddRepeatTimer(100, @TestTimerCallback, nil);
    CheckEquals(1, Wheel.TimerCount, 'Count should be 1 after adding repeat timer');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_CancelTimer_ValidId_ReturnsTrue;
var
  Wheel: TTimerWheel;
  Id: TTimerId;
  Cancelled: Boolean;
begin
  Wheel := TTimerWheel.Create;
  try
    Id := Wheel.AddTimer(100, @TestTimerCallback, nil);
    Cancelled := Wheel.CancelTimer(Id);
    CheckTrue(Cancelled, 'CancelTimer should return true for valid ID');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_CancelTimer_InvalidId_ReturnsFalse;
var
  Wheel: TTimerWheel;
  Cancelled: Boolean;
begin
  Wheel := TTimerWheel.Create;
  try
    Cancelled := Wheel.CancelTimer(999);
    CheckFalse(Cancelled, 'CancelTimer should return false for invalid ID');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_CancelTimer_DecrementsCount;
var
  Wheel: TTimerWheel;
  Id: TTimerId;
begin
  Wheel := TTimerWheel.Create;
  try
    Id := Wheel.AddTimer(100, @TestTimerCallback, nil);
    CheckEquals(1, Wheel.TimerCount, 'Count should be 1 after adding');
    Wheel.CancelTimer(Id);
    CheckEquals(0, Wheel.TimerCount, 'Count should be 0 after cancelling');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_CancelTimer_SameIdTwice_ReturnsFalse;
var
  Wheel: TTimerWheel;
  Id: TTimerId;
  First, Second: Boolean;
begin
  Wheel := TTimerWheel.Create;
  try
    Id := Wheel.AddTimer(100, @TestTimerCallback, nil);
    First := Wheel.CancelTimer(Id);
    Second := Wheel.CancelTimer(Id);
    CheckTrue(First, 'First cancel should succeed');
    CheckFalse(Second, 'Second cancel should fail');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_Tick_FiresTimerAfterDelay;
var
  Wheel: TTimerWheel;
  I: Integer;
begin
  // 使用小的 tick 间隔和延迟便于测试
  Wheel := TTimerWheel.Create(64, 10);
  try
    // 添加延迟 20ms 的定时器（需要 2 个 tick）
    Wheel.AddTimer(20, @TestTimerCallback, Pointer(123));
    
    CheckFalse(GTestCallbackFired, 'Callback should not fire before ticks');
    
    // 第一个 tick
    Wheel.Tick;
    // 定时器尚未触发（等 1 个 tick 后在下一个槽）
    
    // 第二个 tick
    Wheel.Tick;
    
    CheckTrue(GTestCallbackFired, 'Callback should have fired after sufficient ticks');
    CheckEquals(123, PtrUInt(GTestCallbackData), 'Callback data should match');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_Tick_RepeatingTimerFiresMultipleTimes;
var
  Wheel: TTimerWheel;
  I: Integer;
begin
  // 使用小的 tick 间隔
  Wheel := TTimerWheel.Create(64, 10);
  try
    // 添加间隔 10ms 的重复定时器（每个 tick 触发一次）
    Wheel.AddRepeatTimer(10, @TestTimerCallback, nil);
    
    // 执行多个 tick
    for I := 1 to 5 do
      Wheel.Tick;
    
    // 重复定时器应该触发多次
    CheckTrue(GTestCallbackFireCount >= 1, 'Repeating timer should fire at least once');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_Tick_TimerNotFiredBeforeDelay;
var
  Wheel: TTimerWheel;
begin
  Wheel := TTimerWheel.Create(64, 10);
  try
    // 添加延迟 1000ms 的定时器（需要 100 个 tick）
    Wheel.AddTimer(1000, @TestTimerCallback, nil);
    
    // 只执行 1 个 tick
    Wheel.Tick;
    
    CheckFalse(GTestCallbackFired, 'Callback should not fire before delay elapses');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_SlotCount_ReturnsConfiguredValue;
var
  Wheel: TTimerWheel;
begin
  Wheel := TTimerWheel.Create(256, 5);
  try
    CheckEquals(256, Wheel.SlotCount, 'SlotCount should return configured value');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_TickInterval_ReturnsConfiguredValue;
var
  Wheel: TTimerWheel;
begin
  Wheel := TTimerWheel.Create(64, 25);
  try
    CheckEquals(25, Wheel.TickInterval, 'TickInterval should return configured value');
  finally
    Wheel.Free;
  end;
end;

procedure TTestTimerWheel.Test_TimerCount_ReflectsActiveTimers;
var
  Wheel: TTimerWheel;
  Id1, Id2: TTimerId;
begin
  Wheel := TTimerWheel.Create;
  try
    CheckEquals(0, Wheel.TimerCount, 'Initial count should be 0');
    
    Id1 := Wheel.AddTimer(100, @TestTimerCallback, nil);
    CheckEquals(1, Wheel.TimerCount, 'Count should be 1');
    
    Id2 := Wheel.AddTimer(200, @TestTimerCallback, nil);
    CheckEquals(2, Wheel.TimerCount, 'Count should be 2');
    
    Wheel.CancelTimer(Id1);
    CheckEquals(1, Wheel.TimerCount, 'Count should be 1 after cancel');
    
    Wheel.CancelTimer(Id2);
    CheckEquals(0, Wheel.TimerCount, 'Count should be 0 after all cancelled');
  finally
    Wheel.Free;
  end;
end;

initialization
  RegisterTest(TTestTimerWheel);

end.
