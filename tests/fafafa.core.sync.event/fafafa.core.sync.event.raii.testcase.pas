unit fafafa.core.sync.event.raii.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { RAII 守卫模式测试 }
  TTestCase_Event_RAII = class(TTestCase)
  private
    FEvent: IEvent;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础守卫功能测试
    procedure Test_WaitGuard_Success;
    procedure Test_WaitGuard_Timeout;
    procedure Test_TryWaitGuard_Success;
    procedure Test_TryWaitGuard_Fail;
    
    // 守卫生命周期测试
    procedure Test_Guard_AutoRelease;
    procedure Test_Guard_ManualRelease;
    procedure Test_Guard_MultipleRelease;
    
    // 守卫状态测试
    procedure Test_Guard_IsValid;
    procedure Test_Guard_GetEvent;
    
    // 高级守卫测试
    procedure Test_Guard_ManualResetEvent;
    procedure Test_Guard_AutoResetEvent;
    procedure Test_Guard_ConcurrentGuards;
    
    // 错误处理测试
    procedure Test_Guard_ErrorHandling;
    procedure Test_Guard_InvalidState;
  end;

implementation

{ TTestCase_Event_RAII }

procedure TTestCase_Event_RAII.SetUp;
begin
  inherited SetUp;
  FEvent := CreateEvent(False, False); // 自动重置，未信号
end;

procedure TTestCase_Event_RAII.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_Event_RAII.Test_WaitGuard_Success;
var
  Guard: IEventGuard;
  WorkerThread: TThread;
begin
  // 创建工作线程在短时间后设置事件
  WorkerThread := TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(50);
      FEvent.SetEvent;
    end);
  WorkerThread.Start;
  
  try
    // 使用守卫等待事件
    Guard := FEvent.WaitGuard(1000);
    
    AssertTrue('Guard should be valid after successful wait', Guard.IsValid);
    AssertTrue('Guard should reference the same event', Guard.GetEvent = FEvent);
    
  finally
    WorkerThread.WaitFor;
    WorkerThread.Free;
  end;
end;

procedure TTestCase_Event_RAII.Test_WaitGuard_Timeout;
var
  Guard: IEventGuard;
begin
  // 不设置事件，应该超时
  Guard := FEvent.WaitGuard(50);
  
  AssertFalse('Guard should be invalid after timeout', Guard.IsValid);
  AssertTrue('Guard should still reference the event', Guard.GetEvent = FEvent);
end;

procedure TTestCase_Event_RAII.Test_TryWaitGuard_Success;
var
  Guard: IEventGuard;
begin
  // 先设置事件
  FEvent.SetEvent;
  
  // 非阻塞等待应该成功
  Guard := FEvent.TryWaitGuard;
  
  AssertTrue('TryWaitGuard should succeed on signaled event', Guard.IsValid);
  AssertTrue('Guard should reference the same event', Guard.GetEvent = FEvent);
end;

procedure TTestCase_Event_RAII.Test_TryWaitGuard_Fail;
var
  Guard: IEventGuard;
begin
  // 不设置事件，非阻塞等待应该失败
  Guard := FEvent.TryWaitGuard;
  
  AssertFalse('TryWaitGuard should fail on non-signaled event', Guard.IsValid);
  AssertTrue('Guard should still reference the event', Guard.GetEvent = FEvent);
end;

procedure TTestCase_Event_RAII.Test_Guard_AutoRelease;
var
  Guard: IEventGuard;
begin
  FEvent.SetEvent;
  
  // 创建守卫
  Guard := FEvent.TryWaitGuard;
  AssertTrue('Guard should be valid initially', Guard.IsValid);
  
  // 守卫应该在超出作用域时自动释放
  Guard := nil; // 模拟超出作用域
  
  // 重新创建守卫来验证之前的守卫已经释放
  Guard := FEvent.TryWaitGuard;
  // 对于自动重置事件，第二次尝试应该失败（因为事件已被消费）
  AssertFalse('Second guard should fail for auto-reset event', Guard.IsValid);
end;

procedure TTestCase_Event_RAII.Test_Guard_ManualRelease;
var
  Guard: IEventGuard;
begin
  FEvent.SetEvent;
  Guard := FEvent.TryWaitGuard;
  
  AssertTrue('Guard should be valid before manual release', Guard.IsValid);
  
  // 手动释放守卫
  Guard.Release;
  
  AssertFalse('Guard should be invalid after manual release', Guard.IsValid);
end;

procedure TTestCase_Event_RAII.Test_Guard_MultipleRelease;
var
  Guard: IEventGuard;
begin
  FEvent.SetEvent;
  Guard := FEvent.TryWaitGuard;
  
  // 多次释放不应该导致问题
  Guard.Release;
  Guard.Release; // 第二次释放应该是安全的
  
  AssertFalse('Guard should remain invalid after multiple releases', Guard.IsValid);
end;

procedure TTestCase_Event_RAII.Test_Guard_IsValid;
var
  ValidGuard, InvalidGuard: IEventGuard;
begin
  // 有效守卫
  FEvent.SetEvent;
  ValidGuard := FEvent.TryWaitGuard;
  AssertTrue('Valid guard should return true for IsValid', ValidGuard.IsValid);
  
  // 无效守卫
  FEvent.ResetEvent;
  InvalidGuard := FEvent.TryWaitGuard;
  AssertFalse('Invalid guard should return false for IsValid', InvalidGuard.IsValid);
end;

procedure TTestCase_Event_RAII.Test_Guard_GetEvent;
var
  Guard: IEventGuard;
  RetrievedEvent: IEvent;
begin
  Guard := FEvent.TryWaitGuard;
  RetrievedEvent := Guard.GetEvent;
  
  AssertTrue('GetEvent should return the same event object', RetrievedEvent = FEvent);
end;

procedure TTestCase_Event_RAII.Test_Guard_ManualResetEvent;
var
  ManualEvent: IEvent;
  Guard1, Guard2: IEventGuard;
begin
  ManualEvent := CreateEvent(True, False); // 手动重置事件
  ManualEvent.SetEvent;
  
  // 手动重置事件应该允许多个守卫成功
  Guard1 := ManualEvent.TryWaitGuard;
  Guard2 := ManualEvent.TryWaitGuard;
  
  AssertTrue('First guard should be valid for manual reset event', Guard1.IsValid);
  AssertTrue('Second guard should also be valid for manual reset event', Guard2.IsValid);
end;

procedure TTestCase_Event_RAII.Test_Guard_AutoResetEvent;
var
  Guard1, Guard2: IEventGuard;
begin
  FEvent.SetEvent; // 自动重置事件
  
  // 自动重置事件只允许一个守卫成功
  Guard1 := FEvent.TryWaitGuard;
  Guard2 := FEvent.TryWaitGuard;
  
  AssertTrue('First guard should be valid for auto reset event', Guard1.IsValid);
  AssertFalse('Second guard should be invalid for auto reset event', Guard2.IsValid);
end;

procedure TTestCase_Event_RAII.Test_Guard_ConcurrentGuards;
const
  THREAD_COUNT = 4;
var
  ManualEvent: IEvent;
  Guards: array[0..THREAD_COUNT-1] of IEventGuard;
  Threads: array[0..THREAD_COUNT-1] of TThread;
  ValidCount: Integer;
  i: Integer;
begin
  ManualEvent := CreateEvent(True, False); // 手动重置事件
  ManualEvent.SetEvent;
  ValidCount := 0;
  
  // 创建多个线程同时获取守卫
  for i := 0 to THREAD_COUNT - 1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        LocalGuard: IEventGuard;
      begin
        LocalGuard := ManualEvent.TryWaitGuard;
        Guards[i] := LocalGuard;
        if LocalGuard.IsValid then
          InterlockedIncrement(ValidCount);
      end);
  end;
  
  // 启动所有线程
  for i := 0 to THREAD_COUNT - 1 do
    Threads[i].Start;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  // 对于手动重置事件，所有守卫都应该有效
  AssertEquals('All guards should be valid for manual reset event', THREAD_COUNT, ValidCount);
end;

procedure TTestCase_Event_RAII.Test_Guard_ErrorHandling;
var
  Guard: IEventGuard;
begin
  // 测试在错误状态下的守卫行为
  Guard := FEvent.WaitGuard(1); // 很短的超时，应该失败
  
  AssertFalse('Guard should be invalid after timeout', Guard.IsValid);
  AssertTrue('Guard should still provide access to event', Guard.GetEvent <> nil);
  
  // 释放无效守卫应该是安全的
  Guard.Release;
  AssertFalse('Guard should remain invalid after release', Guard.IsValid);
end;

procedure TTestCase_Event_RAII.Test_Guard_InvalidState;
var
  Guard: IEventGuard;
begin
  // 获取无效守卫
  Guard := FEvent.TryWaitGuard;
  AssertFalse('Guard should be invalid initially', Guard.IsValid);
  
  // 即使守卫无效，也应该能安全地调用其方法
  AssertTrue('GetEvent should work even for invalid guard', Guard.GetEvent = FEvent);
  
  // 释放无效守卫应该是安全的
  Guard.Release;
  AssertFalse('Guard should remain invalid', Guard.IsValid);
end;

initialization
  RegisterTest(TTestCase_Event_RAII);

end.
