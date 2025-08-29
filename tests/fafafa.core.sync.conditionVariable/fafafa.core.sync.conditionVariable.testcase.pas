unit fafafa.core.sync.conditionVariable.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.base, fafafa.core.sync.mutex, fafafa.core.sync.conditionVariable;

Type
  // 基础功能测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeConditionVariable;
  end;

  // IConditionVariable 行为测试
  TTestCase_IConditionVariable = class(TTestCase)
  private
    FCond: IConditionVariable;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Wait_ZeroTimeout;
    procedure Test_Wait_ShortTimeout;
    procedure Test_Signal_WakesOne;
    procedure Test_Broadcast_WakesAll;
  end;

  { 简单的等待线程 }
  TWaiterThread = class(TThread)
  private
    FCond: IConditionVariable;
    FLock: ILock;
    FFlag: PBoolean;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACond: IConditionVariable; const ALock: ILock; AFlag: PBoolean; AIterations: Integer = 1);
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeConditionVariable;
var
  Cond: IConditionVariable;
begin
  Cond := MakeConditionVariable;
  AssertNotNull('MakeConditionVariable should return non-nil', Cond);
end;

{ TTestCase_IConditionVariable }

procedure TTestCase_IConditionVariable.SetUp;
begin
  inherited SetUp;
  FCond := MakeConditionVariable;
end;

procedure TTestCase_IConditionVariable.TearDown;
begin
  FCond := nil;
  inherited TearDown;
end;

procedure TTestCase_IConditionVariable.Test_Wait_ZeroTimeout;
var
  LLock: ILock;
  LResult: Boolean;
begin
  // 使用统一工厂，保持与 mutex 测试一致
  LLock := MakeMutex;

  LLock.Acquire;
  try
    LResult := FCond.Wait(LLock, 0);
    AssertFalse('Zero-timeout wait should return False', LResult);
  finally
    LLock.Release;
  end;
end;

procedure TTestCase_IConditionVariable.Test_Wait_ShortTimeout;
var
  LLock: ILock;
  LResult: Boolean;
begin
  LLock := MakeMutex;

  LLock.Acquire;
  try
    LResult := FCond.Wait(LLock, 5);
    AssertFalse('Short-timeout wait should return False when no signal', LResult);
  finally
    LLock.Release;
  end;
end;

procedure TTestCase_IConditionVariable.Test_Signal_WakesOne;
var
  LLock: ILock;
  Ready: Boolean;
  Waiter: TWaiterThread;
begin
  LLock := MakeMutex;

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

procedure TTestCase_IConditionVariable.Test_Broadcast_WakesAll;
var
  LLock: ILock;
  Ready: Boolean;
  Waiters: array[0..2] of TWaiterThread;
  i: Integer;
begin
  LLock := MakeMutex;

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

constructor TWaiterThread.Create(const ACond: IConditionVariable; const ALock: ILock; AFlag: PBoolean; AIterations: Integer);
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

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IConditionVariable);

end.

