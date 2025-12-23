unit fafafa.core.sync.condvar.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.base, fafafa.core.sync.mutex, fafafa.core.sync.mutex.unix,
  fafafa.core.sync.condvar;

Type
  // 基础功能测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeCondVar;
  end;

  // IConditionVariable 行为测试
  TTestCase_ICondVar = class(TTestCase)
  private
    FCond: ICondVar;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Wait_ZeroTimeout;
    procedure Test_Wait_ShortTimeout;
    procedure Test_Signal_WakesOne;
    procedure Test_Broadcast_WakesAll;
  end;

  // WaitFor (Rust-style API) 测试
  TTestCase_WaitFor = class(TTestCase)
  private
    FCond: ICondVar;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_WaitFor_ZeroTimeout_TimedOut;
    procedure Test_WaitFor_ShortTimeout_TimedOut;
    procedure Test_WaitFor_SignaledBeforeTimeout;
    procedure Test_WaitFor_FlyweightSingleton;
  end;

  { 简单的等待线程 }
  TWaiterThread = class(TThread)
  private
    FCond: ICondVar;
    FLock: ILock;
    FFlag: PBoolean;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACond: ICondVar; const ALock: ILock; AFlag: PBoolean; AIterations: Integer = 1);
  end;

  { WaitFor 测试用的等待线程 }
  TWaitForThread = class(TThread)
  private
    FCond: ICondVar;
    FLock: ILock;
    FFlag: PBoolean;
    FResult: TCondVarWaitResult;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACond: ICondVar; const ALock: ILock; AFlag: PBoolean);
    property WaitResult: TCondVarWaitResult read FResult;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeCondVar;
var
  Cond: ICondVar;
begin
  Cond := MakeCondVar;
  AssertNotNull('MakeConditionVariable should return non-nil', Cond);
end;

{ TTestCase_IConditionVariable }

procedure TTestCase_ICondVar.SetUp;
begin
  inherited SetUp;
  FCond := MakeCondVar;
end;

procedure TTestCase_ICondVar.TearDown;
begin
  FCond := nil;
  inherited TearDown;
end;

procedure TTestCase_ICondVar.Test_Wait_ZeroTimeout;
var
  LLock: ILock;
  LResult: Boolean;
begin
  // 使用 pthread mutex，与 condvar 兼容
  LLock := MakePthreadMutex;

  LLock.Acquire;
  try
    LResult := FCond.Wait(LLock, 0);
    AssertFalse('Zero-timeout wait should return False', LResult);
  finally
    LLock.Release;
  end;
end;

procedure TTestCase_ICondVar.Test_Wait_ShortTimeout;
var
  LLock: ILock;
  LResult: Boolean;
begin
  LLock := MakePthreadMutex;

  LLock.Acquire;
  try
    LResult := FCond.Wait(LLock, 5);
    AssertFalse('Short-timeout wait should return False when no signal', LResult);
  finally
    LLock.Release;
  end;
end;

procedure TTestCase_ICondVar.Test_Signal_WakesOne;
var
  LLock: ILock;
  Ready: Boolean;
  Waiter: TWaiterThread;
begin
  LLock := MakePthreadMutex;

  Ready := False;
  Waiter := TWaiterThread.Create(FCond, LLock, @Ready);
  try
    // 让等待线程进入等待
    Sleep(10);

    // 发出信号
    LLock.Acquire;
    try
      Ready := True;
      FCond.Signal; // 唤醒一个等待者
    finally
      LLock.Release;
    end;

    Waiter.WaitFor;
    AssertTrue('Waiter thread should have finished', Waiter.Finished);
  finally
    Waiter.Free;
  end;
end;

procedure TTestCase_ICondVar.Test_Broadcast_WakesAll;
var
  LLock: ILock;
  Ready: Boolean;
  Waiters: array[0..2] of TWaiterThread;
  i: Integer;
begin
  LLock := MakePthreadMutex;

  Ready := False;
  for i := Low(Waiters) to High(Waiters) do
    Waiters[i] := TWaiterThread.Create(FCond, LLock, @Ready);
  try
    Sleep(10);

    LLock.Acquire;
    try
      Ready := True;
      FCond.Broadcast; // 唤醒所有等待者
    finally
      LLock.Release;
    end;

    for i := Low(Waiters) to High(Waiters) do
      Waiters[i].WaitFor;

    for i := Low(Waiters) to High(Waiters) do
      AssertTrue(Format('Waiter %d should have finished', [i]), Waiters[i].Finished);
  finally
    for i := Low(Waiters) to High(Waiters) do
      Waiters[i].Free;
  end;
end;

{ TWaiterThread }

constructor TWaiterThread.Create(const ACond: ICondVar; const ALock: ILock; AFlag: PBoolean; AIterations: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FCond := ACond;
  FLock := ALock;
  FFlag := AFlag;
  FIterations := AIterations;
end;

procedure TWaiterThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FLock.Acquire;
    try
      while not FFlag^ do
        if not FCond.Wait(FLock, 100) then ; // 超时循环避免测试阻塞
    finally
      FLock.Release;
    end;
  end;
end;

{ TWaitForThread }

constructor TWaitForThread.Create(const ACond: ICondVar; const ALock: ILock; AFlag: PBoolean);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FCond := ACond;
  FLock := ALock;
  FFlag := AFlag;
  // FResult 是 record，自动初始化
end;

procedure TWaitForThread.Execute;
begin
  FLock.Acquire;
  try
    while not FFlag^ do
    begin
      FResult := FCond.WaitFor(FLock, 1000);
      if FResult.TimedOut then Continue; // Spurious wakeup protection
    end;
  finally
    FLock.Release;
  end;
end;

{ TTestCase_WaitFor }

procedure TTestCase_WaitFor.SetUp;
begin
  inherited SetUp;
  FCond := MakeCondVar;
end;

procedure TTestCase_WaitFor.TearDown;
begin
  FCond := nil;
  inherited TearDown;
end;

procedure TTestCase_WaitFor.Test_WaitFor_ZeroTimeout_TimedOut;
var
  LLock: ILock;
  LResult: TCondVarWaitResult;
begin
  LLock := MakePthreadMutex;

  LLock.Acquire;
  try
    LResult := FCond.WaitFor(LLock, 0);
    // Record 类型不需要 nil 检查
    AssertTrue('Zero-timeout WaitFor should return TimedOut=True', LResult.TimedOut);
  finally
    LLock.Release;
  end;
end;

procedure TTestCase_WaitFor.Test_WaitFor_ShortTimeout_TimedOut;
var
  LLock: ILock;
  LResult: TCondVarWaitResult;
begin
  LLock := MakePthreadMutex;

  LLock.Acquire;
  try
    LResult := FCond.WaitFor(LLock, 5);
    // Record 类型不需要 nil 检查
    AssertTrue('Short-timeout WaitFor without signal should return TimedOut=True', LResult.TimedOut);
  finally
    LLock.Release;
  end;
end;

procedure TTestCase_WaitFor.Test_WaitFor_SignaledBeforeTimeout;
var
  LLock: ILock;
  Ready: Boolean;
  Waiter: TWaitForThread;
begin
  LLock := MakePthreadMutex;

  Ready := False;

  Waiter := TWaitForThread.Create(FCond, LLock, @Ready);
  try
    Sleep(10); // Let waiter enter wait state

    LLock.Acquire;
    try
      Ready := True;
      FCond.Signal;
    finally
      LLock.Release;
    end;

    Waiter.WaitFor;
    // Record 类型不需要 nil 检查
    AssertFalse('Signaled wait should return TimedOut=False', Waiter.WaitResult.TimedOut);
  finally
    Waiter.Free;
  end;
end;

procedure TTestCase_WaitFor.Test_WaitFor_FlyweightSingleton;
var
  LLock: ILock;
  R1, R2, R3: TCondVarWaitResult;
begin
  // Test that WaitFor returns consistent results
  // Note: Since TCondVarWaitResult is now a record (value type),
  // there's no Flyweight pattern - each call returns a stack-allocated value
  LLock := MakePthreadMutex;

  LLock.Acquire;
  try
    R1 := FCond.WaitFor(LLock, 0); // TimedOut = True
    R2 := FCond.WaitFor(LLock, 0); // TimedOut = True
    R3 := FCond.WaitFor(LLock, 0); // TimedOut = True

    AssertTrue('R1 should be timed out', R1.TimedOut);
    AssertTrue('R2 should be timed out', R2.TimedOut);
    AssertTrue('R3 should be timed out', R3.TimedOut);

    // Record 是值类型，每次调用返回独立的栈分配值
    // 这比 Interface + Flyweight 更高效（零堆分配）
  finally
    LLock.Release;
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_ICondVar);
  RegisterTest(TTestCase_WaitFor);

end.

