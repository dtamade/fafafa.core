{$CODEPAGE UTF8}
unit fafafa.core.sync.notify.testcase;

{**
 * fafafa.core.sync.notify 测试套件
 *
 * 测试 INotify（轻量级线程通知原语）的：
 * - 基础功能（Wait、NotifyOne、NotifyAll）
 * - 边界条件（超时测试）
 * - 并发场景（多等待者）
 * - 压力测试
 *
 * @author fafafaStudio
 * @version 1.0
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.notify,
  fafafa.core.sync.notify.base,
  TestHelpers_Sync;

type
  // ===== 基础功能测试 =====
  TTestCase_Notify_Basic = class(TTestCase)
  published
    procedure Test_Create;
    procedure Test_NotifyOne_NoWaiters;
    procedure Test_NotifyAll_NoWaiters;
    procedure Test_GetWaiterCount_Initial;
  end;

  // ===== 单线程通知测试 =====
  TTestCase_Notify_SingleWaiter = class(TTestCase)
  published
    procedure Test_NotifyOne_WakesWaiter;
    procedure Test_NotifyAll_WakesWaiter;
    procedure Test_WaitTimeout_Succeeds;
    procedure Test_WaitTimeout_TimesOut;
    procedure Test_WaitTimeout_ZeroMs;
  end;

  // ===== 多线程通知测试 =====
  TTestCase_Notify_MultiWaiter = class(TTestCase)
  published
    procedure Test_NotifyOne_WakesOneWaiter;
    procedure Test_NotifyAll_WakesAllWaiters;
    procedure Test_SequentialNotifyOne;
  end;

  // ===== 压力测试 =====
  TTestCase_Notify_Stress = class(TTestCase)
  published
    procedure Test_RapidNotify;
    procedure Test_HighConcurrency_Waiters;
    procedure Test_RapidCreateDestroy;
  end;

  // ===== 辅助线程类 =====

  // 等待 Notify 的线程
  TNotifyWaiterThread = class(TWorkerThread)
  private
    FNotify: INotify;
    FTimeoutMs: Cardinal;
    FTimedOut: Boolean;
  protected
    procedure DoWork; override;
  public
    constructor Create(AId: Integer; ANotify: INotify; ATimeoutMs: Cardinal = High(Cardinal));
    property TimedOut: Boolean read FTimedOut;
  end;

implementation

{ TNotifyWaiterThread }

constructor TNotifyWaiterThread.Create(AId: Integer; ANotify: INotify; ATimeoutMs: Cardinal);
begin
  inherited Create(AId);
  FNotify := ANotify;
  FTimeoutMs := ATimeoutMs;
  FTimedOut := False;
end;

procedure TNotifyWaiterThread.DoWork;
begin
  if FTimeoutMs = High(Cardinal) then
  begin
    FNotify.Wait;
    FTimedOut := False;
  end
  else
  begin
    FTimedOut := not FNotify.WaitTimeout(FTimeoutMs);
  end;
end;

{ TTestCase_Notify_Basic }

procedure TTestCase_Notify_Basic.Test_Create;
var
  N: INotify;
begin
  N := MakeNotify;
  AssertNotNull('MakeNotify should return non-nil', N);
  AssertEquals('Initial waiter count should be 0', 0, N.GetWaiterCount);
end;

procedure TTestCase_Notify_Basic.Test_NotifyOne_NoWaiters;
var
  N: INotify;
begin
  N := MakeNotify;
  // 没有等待者时，通知应该安全地丢失
  N.NotifyOne;
  AssertTrue('NotifyOne with no waiters should be safe', True);
end;

procedure TTestCase_Notify_Basic.Test_NotifyAll_NoWaiters;
var
  N: INotify;
begin
  N := MakeNotify;
  // 没有等待者时，通知应该安全地丢失
  N.NotifyAll;
  AssertTrue('NotifyAll with no waiters should be safe', True);
end;

procedure TTestCase_Notify_Basic.Test_GetWaiterCount_Initial;
var
  N: INotify;
begin
  N := MakeNotify;
  AssertEquals('GetWaiterCount should return 0 initially', 0, N.GetWaiterCount);
end;

{ TTestCase_Notify_SingleWaiter }

procedure TTestCase_Notify_SingleWaiter.Test_NotifyOne_WakesWaiter;
var
  N: INotify;
  Waiter: TNotifyWaiterThread;
begin
  N := MakeNotify;
  Waiter := TNotifyWaiterThread.Create(0, N);
  try
    Waiter.Start;
    Sleep(20); // 让线程开始等待

    AssertTrue('Should have waiter', N.GetWaiterCount > 0);

    N.NotifyOne;
    Waiter.WaitFor;

    AssertTrue('Waiter should succeed', Waiter.Success);
    AssertFalse('Waiter should not timeout', Waiter.TimedOut);
  finally
    Waiter.Free;
  end;
end;

procedure TTestCase_Notify_SingleWaiter.Test_NotifyAll_WakesWaiter;
var
  N: INotify;
  Waiter: TNotifyWaiterThread;
begin
  N := MakeNotify;
  Waiter := TNotifyWaiterThread.Create(0, N);
  try
    Waiter.Start;
    Sleep(20);

    N.NotifyAll;
    Waiter.WaitFor;

    AssertTrue('Waiter should succeed', Waiter.Success);
    AssertFalse('Waiter should not timeout', Waiter.TimedOut);
  finally
    Waiter.Free;
  end;
end;

procedure TTestCase_Notify_SingleWaiter.Test_WaitTimeout_Succeeds;
var
  N: INotify;
  Waiter: TNotifyWaiterThread;
begin
  N := MakeNotify;
  Waiter := TNotifyWaiterThread.Create(0, N, 5000);
  try
    Waiter.Start;
    Sleep(20);

    N.NotifyOne;
    Waiter.WaitFor;

    AssertTrue('Waiter should succeed', Waiter.Success);
    AssertFalse('Waiter should not timeout', Waiter.TimedOut);
  finally
    Waiter.Free;
  end;
end;

procedure TTestCase_Notify_SingleWaiter.Test_WaitTimeout_TimesOut;
var
  N: INotify;
  Waiter: TNotifyWaiterThread;
  StartTime, ElapsedMs: QWord;
begin
  N := MakeNotify;
  Waiter := TNotifyWaiterThread.Create(0, N, 50);
  try
    StartTime := GetCurrentTimeMs;
    Waiter.Start;
    Waiter.WaitFor;
    ElapsedMs := GetCurrentTimeMs - StartTime;

    AssertTrue('Waiter should succeed (no exception)', Waiter.Success);
    AssertTrue('Waiter should timeout', Waiter.TimedOut);
    AssertTrue('Should take at least 40ms', ElapsedMs >= 40);
    AssertTrue('Should not take too long', ElapsedMs < 200);
  finally
    Waiter.Free;
  end;
end;

procedure TTestCase_Notify_SingleWaiter.Test_WaitTimeout_ZeroMs;
var
  N: INotify;
  StartTime, ElapsedMs: QWord;
  R: Boolean;
begin
  N := MakeNotify;

  StartTime := GetCurrentTimeMs;
  R := N.WaitTimeout(0);
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertFalse('WaitTimeout(0) should return False immediately', R);
  AssertTrue('Should return very quickly', ElapsedMs < 10);
end;

{ TTestCase_Notify_MultiWaiter }

procedure TTestCase_Notify_MultiWaiter.Test_NotifyOne_WakesOneWaiter;
var
  N: INotify;
  Waiters: array[0..2] of TNotifyWaiterThread;
  i, WokenCount, TimeoutCount: Integer;
begin
  N := MakeNotify;

  for i := 0 to 2 do
    Waiters[i] := TNotifyWaiterThread.Create(i, N, 200);

  try
    // 启动所有等待线程
    for i := 0 to 2 do
      Waiters[i].Start;

    Sleep(30); // 让所有线程开始等待

    AssertTrue('Should have multiple waiters', N.GetWaiterCount >= 2);

    // 只通知一个
    N.NotifyOne;

    // 等待所有线程完成（其他会超时）
    for i := 0 to 2 do
      Waiters[i].WaitFor;

    WokenCount := 0;
    TimeoutCount := 0;
    for i := 0 to 2 do
    begin
      if Waiters[i].Success and (not Waiters[i].TimedOut) then
        Inc(WokenCount)
      else if Waiters[i].TimedOut then
        Inc(TimeoutCount);
    end;

    AssertEquals('Only one waiter should be woken', 1, WokenCount);
    AssertEquals('Two waiters should timeout', 2, TimeoutCount);
  finally
    for i := 0 to 2 do
      Waiters[i].Free;
  end;
end;

procedure TTestCase_Notify_MultiWaiter.Test_NotifyAll_WakesAllWaiters;
var
  N: INotify;
  Waiters: array of TNotifyWaiterThread = nil;
  i, ThreadCount, SuccessCount: Integer;
begin
  ThreadCount := 10;
  SetLength(Waiters, ThreadCount);
  N := MakeNotify;

  for i := 0 to ThreadCount - 1 do
    Waiters[i] := TNotifyWaiterThread.Create(i, N);

  try
    for i := 0 to ThreadCount - 1 do
      Waiters[i].Start;

    Sleep(50); // 让所有线程开始等待

    AssertTrue('Should have multiple waiters', N.GetWaiterCount >= ThreadCount - 2);

    N.NotifyAll;

    SuccessCount := 0;
    for i := 0 to ThreadCount - 1 do
    begin
      Waiters[i].WaitFor;
      if Waiters[i].Success and (not Waiters[i].TimedOut) then
        Inc(SuccessCount);
    end;

    AssertEquals('All waiters should be woken', ThreadCount, SuccessCount);
  finally
    for i := 0 to ThreadCount - 1 do
      Waiters[i].Free;
  end;
end;

procedure TTestCase_Notify_MultiWaiter.Test_SequentialNotifyOne;
var
  N: INotify;
  Waiters: array[0..4] of TNotifyWaiterThread;
  i, WokenCount: Integer;
begin
  N := MakeNotify;

  for i := 0 to 4 do
    Waiters[i] := TNotifyWaiterThread.Create(i, N, 500);

  try
    for i := 0 to 4 do
      Waiters[i].Start;

    Sleep(30);

    // 逐个通知
    for i := 0 to 4 do
    begin
      N.NotifyOne;
      Sleep(10);
    end;

    WokenCount := 0;
    for i := 0 to 4 do
    begin
      Waiters[i].WaitFor;
      if Waiters[i].Success and (not Waiters[i].TimedOut) then
        Inc(WokenCount);
    end;

    AssertEquals('All waiters should be woken sequentially', 5, WokenCount);
  finally
    for i := 0 to 4 do
      Waiters[i].Free;
  end;
end;

{ TTestCase_Notify_Stress }

procedure TTestCase_Notify_Stress.Test_RapidNotify;
var
  N: INotify;
  i, Iterations: Integer;
  StartTime, ElapsedMs: QWord;
begin
  Iterations := 10000;
  N := MakeNotify;

  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
  begin
    N.NotifyOne;
    N.NotifyAll;
  end;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  WriteLn(Format('Rapid notify: %d iterations in %d ms', [Iterations * 2, ElapsedMs]));
  AssertTrue('Should complete quickly', ElapsedMs < 1000);
end;

procedure TTestCase_Notify_Stress.Test_HighConcurrency_Waiters;
var
  N: INotify;
  Waiters: array of TNotifyWaiterThread = nil;
  i, ThreadCount, SuccessCount: Integer;
  StartTime, ElapsedMs: QWord;
begin
  ThreadCount := 50;
  SetLength(Waiters, ThreadCount);
  N := MakeNotify;

  for i := 0 to ThreadCount - 1 do
    Waiters[i] := TNotifyWaiterThread.Create(i, N);

  try
    StartTime := GetCurrentTimeMs;

    for i := 0 to ThreadCount - 1 do
      Waiters[i].Start;

    Sleep(50);

    N.NotifyAll;

    SuccessCount := 0;
    for i := 0 to ThreadCount - 1 do
    begin
      Waiters[i].WaitFor;
      if Waiters[i].Success and (not Waiters[i].TimedOut) then
        Inc(SuccessCount);
    end;

    ElapsedMs := GetCurrentTimeMs - StartTime;
    WriteLn(Format('High concurrency: %d waiters in %d ms', [ThreadCount, ElapsedMs]));

    AssertEquals('All waiters should succeed', ThreadCount, SuccessCount);
  finally
    for i := 0 to ThreadCount - 1 do
      Waiters[i].Free;
  end;
end;

procedure TTestCase_Notify_Stress.Test_RapidCreateDestroy;
var
  N: INotify;
  i, Iterations: Integer;
  StartTime, ElapsedMs: QWord;
begin
  Iterations := 1000;

  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
  begin
    N := MakeNotify;
    N.NotifyOne;
    N := nil;
  end;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  WriteLn(Format('Rapid create/destroy: %d iterations in %d ms', [Iterations, ElapsedMs]));
  AssertTrue('Should complete in reasonable time', ElapsedMs < 5000);
end;

initialization
  RegisterTest(TTestCase_Notify_Basic);
  RegisterTest(TTestCase_Notify_SingleWaiter);
  RegisterTest(TTestCase_Notify_MultiWaiter);
  RegisterTest(TTestCase_Notify_Stress);

end.
