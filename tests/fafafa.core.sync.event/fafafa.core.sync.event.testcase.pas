unit fafafa.core.sync.event.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  // 基础功能测试
  TTestCase_Event_Basic = class(TTestCase)
  private
    FEvent: IEvent;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Create_Default;
    procedure Test_Create_ManualReset_Initial;
    procedure Test_Set_Reset;
    procedure Test_Wait_Immediate;
    procedure Test_Wait_TimeoutZero;
    procedure Test_Wait_TimeoutShort;
    procedure Test_AutoReset_Behavior;
    procedure Test_ManualReset_Behavior;
    // ISynchronizable 继承方法
    procedure Test_LockMethods_AutoReset;
    procedure Test_LockMethods_ManualReset;
    // Signal/Clear 别名测试
    procedure Test_Signal_Clear_Aliases;
  end;

  // 并发测试
  TWaitThread = class(TThread)
  private
    FEvent: IEvent;
    FTimeout: Cardinal;
    FResult: TWaitResult;
  protected
    procedure Execute; override;
  public
    constructor Create(const AEvent: IEvent; ATimeout: Cardinal);
    property ResultCode: TWaitResult read FResult;
  end;

  TTestCase_Event_Concurrency = class(TTestCase)
  published
    procedure Test_ManualReset_WakesAll;
    procedure Test_AutoReset_WakesOne;
  end;

implementation

{ TTestCase_Event_Basic }
procedure TTestCase_Event_Basic.SetUp;
begin
  inherited SetUp;
  FEvent := MakeEvent(False, False); // 自动重置，初始未信号
end;

procedure TTestCase_Event_Basic.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_Event_Basic.Test_Create_Default;
var r: TWaitResult;
begin
  AssertNotNull('CreateEvent should return non-nil', FEvent);
  r := FEvent.WaitFor(0);
  AssertEquals('Default event should be non-signaled', Ord(wrTimeout), Ord(r));
end;

procedure TTestCase_Event_Basic.Test_Create_ManualReset_Initial;
var E: IEvent; r: TWaitResult;
begin
  E := MakeEvent(True, True);
  AssertNotNull('MakeEvent(manual,initial) non-nil', E);
  r := E.WaitFor(0);
  AssertEquals('ManualReset initial True should be signaled', Ord(wrSignaled), Ord(r));
end;

procedure TTestCase_Event_Basic.Test_Set_Reset;
var r: TWaitResult;
begin
  // 对自动重置事件，使用 WaitFor(0) 进行探测
  r := FEvent.WaitFor(0);
  AssertEquals('Initially should timeout', Ord(wrTimeout), Ord(r));
  FEvent.SetEvent;
  r := FEvent.WaitFor(0);
  AssertEquals('After SetEvent, WaitFor(0) should be signaled', Ord(wrSignaled), Ord(r));
  // 再次零等待应超时（自动重置已消费）
  r := FEvent.WaitFor(0);
  AssertEquals('Auto-reset consumed signal', Ord(wrTimeout), Ord(r));
end;

procedure TTestCase_Event_Basic.Test_Wait_Immediate;
var r: TWaitResult;
begin
  FEvent.SetEvent;
  r := FEvent.WaitFor(1000);
  AssertEquals('Wait on signaled should return wrSignaled', Ord(wrSignaled), Ord(r));
end;

procedure TTestCase_Event_Basic.Test_Wait_TimeoutZero;
var r: TWaitResult;
begin
  r := FEvent.WaitFor(0);
  AssertEquals('Zero-timeout should time out', Ord(wrTimeout), Ord(r));
end;

procedure TTestCase_Event_Basic.Test_Wait_TimeoutShort;
var r: TWaitResult;
begin
  r := FEvent.WaitFor(10);
  AssertTrue('Short-timeout should be timeout or signaled (both acceptable)', (r = wrTimeout) or (r = wrSignaled));
end;

procedure TTestCase_Event_Basic.Test_AutoReset_Behavior;
var r1, r2: TWaitResult;
begin
  // 自动重置：一次等待后自动返回未信号
  FEvent.SetEvent;
  r1 := FEvent.WaitFor(1000);
  AssertEquals(Ord(wrSignaled), Ord(r1));
  // 第二次应当超时（若没有再次 set）
  r2 := FEvent.WaitFor(0);
  AssertEquals(Ord(wrTimeout), Ord(r2));
end;

procedure TTestCase_Event_Basic.Test_ManualReset_Behavior;
var E: IEvent; r1, r2, r3: TWaitResult;
begin
  E := MakeEvent(True, False);
  E.SetEvent;
  r1 := E.WaitFor(1000);
  AssertEquals(Ord(wrSignaled), Ord(r1));
  // 手动重置：等待后仍旧保持信号
  r2 := E.WaitFor(0);
  AssertEquals(Ord(wrSignaled), Ord(r2));
  E.ResetEvent;
  r3 := E.WaitFor(0);
  AssertEquals('After ResetEvent should timeout', Ord(wrTimeout), Ord(r3));
end;

procedure TTestCase_Event_Basic.Test_LockMethods_AutoReset;
var r: TWaitResult;
begin
  // TryWait 先失败
  AssertFalse('TryWait should fail initially', FEvent.TryWait);
  // Set 后 WaitFor 应成功返回
  FEvent.SetEvent;
  r := FEvent.WaitFor(100); // 替代 Acquire
  AssertEquals('WaitFor should succeed after SetEvent', Ord(wrSignaled), Ord(r));
  // 自动重置已消费，此时再零等待应超时
  r := FEvent.WaitFor(0);
  AssertEquals('Auto-reset consumed after WaitFor', Ord(wrTimeout), Ord(r));
  // 测试重新设置事件
  FEvent.SetEvent;
  r := FEvent.WaitFor(0);
  AssertEquals('Event can be set again', Ord(wrSignaled), Ord(r));
end;

procedure TTestCase_Event_Basic.Test_LockMethods_ManualReset;
var E: IEvent; r: TWaitResult;
begin
  E := MakeEvent(True, False);
  AssertFalse('TryWait should fail initially', E.TryWait);
  E.SetEvent;
  AssertTrue('TryWait should succeed after SetEvent', E.TryWait);
  r := E.WaitFor(100); // 替代 Acquire
  AssertEquals('WaitFor should succeed', Ord(wrSignaled), Ord(r));
  // 手动重置仍保持信号
  r := E.WaitFor(0);
  AssertEquals('ManualReset remains signaled after WaitFor', Ord(wrSignaled), Ord(r));
  // 恢复未信号
  E.ResetEvent;
  r := E.WaitFor(0);
  AssertEquals('After ResetEvent, zero-timeout should timeout', Ord(wrTimeout), Ord(r));
end;

procedure TTestCase_Event_Basic.Test_Signal_Clear_Aliases;
var E: IEvent; r: TWaitResult;
begin
  // 测试 Signal 是 SetEvent 的别名
  E := MakeEvent(True, False);  // 手动重置
  r := E.WaitFor(0);
  AssertEquals('Initially should timeout', Ord(wrTimeout), Ord(r));
  
  E.Signal;  // 使用 Signal 别名
  r := E.WaitFor(0);
  AssertEquals('After Signal, should be signaled', Ord(wrSignaled), Ord(r));
  
  // 测试 Clear 是 ResetEvent 的别名
  E.Clear;  // 使用 Clear 别名
  r := E.WaitFor(0);
  AssertEquals('After Clear, should timeout', Ord(wrTimeout), Ord(r));
  
  // 混合使用
  E.Signal;
  AssertTrue('IsSignaled after Signal', E.IsSignaled);
  E.Clear;
  AssertFalse('Not IsSignaled after Clear', E.IsSignaled);
end;

{ TWaitThread }
constructor TWaitThread.Create(const AEvent: IEvent; ATimeout: Cardinal);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FEvent := AEvent;
  FTimeout := ATimeout;
  Start;
end;

procedure TWaitThread.Execute;
begin
  if FEvent <> nil then
    FResult := FEvent.WaitFor(FTimeout)
  else
    FResult := wrError;
end;

{ TTestCase_Event_Concurrency }
procedure TTestCase_Event_Concurrency.Test_ManualReset_WakesAll;
const N = 4;
var
  E: IEvent;
  i: Integer;
  threads: array[0..N-1] of TWaitThread;
begin
  E := MakeEvent(True, False); // 手动重置
  for i := 0 to N-1 do
    threads[i] := TWaitThread.Create(E, 2000);
  // 让线程进入等待
  Sleep(50);
  // 触发
  E.SetEvent;
  // 等待并断言全部唤醒
  for i := 0 to N-1 do
  begin
    threads[i].WaitFor;
    AssertEquals(Format('Thread %d should be signaled', [i]), Ord(wrSignaled), Ord(threads[i].ResultCode));
    threads[i].Free;
  end;
  // 重置后应超时
  E.ResetEvent;
  AssertEquals(Ord(wrTimeout), Ord(E.WaitFor(0)));
end;

procedure TTestCase_Event_Concurrency.Test_AutoReset_WakesOne;
var
  E: IEvent;
  T1, T2: TWaitThread;
  w1, w2: TWaitResult;
begin
  E := MakeEvent(False, False); // 自动重置
  T1 := TWaitThread.Create(E, 1000);
  T2 := TWaitThread.Create(E, 1000);
  Sleep(50);
  E.SetEvent;
  T1.WaitFor;
  w1 := T1.ResultCode;
  T2.WaitFor;
  w2 := T2.ResultCode;
  // 应当有且仅有一个被唤醒
  AssertTrue('One should be signaled', (w1 = wrSignaled) or (w2 = wrSignaled));
  AssertTrue('One should timeout', (w1 = wrTimeout) or (w2 = wrTimeout));
  T1.Free; T2.Free;
end;

initialization
  RegisterTest(TTestCase_Event_Basic);
  RegisterTest(TTestCase_Event_Concurrency);

end.

