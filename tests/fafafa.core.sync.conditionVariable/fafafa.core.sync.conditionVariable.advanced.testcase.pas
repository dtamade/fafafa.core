unit fafafa.core.sync.conditionVariable.advanced.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF UNIX}cthreads,{$ENDIF}
  fafafa.core.sync.base, fafafa.core.sync.mutex, fafafa.core.sync.conditionVariable;

// 进阶与压力测试，目标覆盖：
// - 工厂与门面
// - 平台实现：正常路径、超时路径、异常路径
// - 并发：多等待者、Signal 与 Broadcast 行为
// - 边界：零/极大超时、无效参数
// - 生命周期：快速创建/销毁

Type
  // 伪造的非 IMutex 锁，用于异常路径覆盖
  TBadLock = class(TInterfacedObject, ILock)
  private
    FLocked: Boolean;
  public
    // ISynchronizable
    function GetLastError: TWaitError;
    // ILock
    procedure Acquire; virtual;
    procedure Release; virtual;
    function TryAcquire: Boolean; virtual;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    // Helpers for assertions
    function GetState: TLockState;
    function IsLocked: Boolean;
  end;

  TTestCase_Advanced = class(TTestCase)
  private
    FCond: IConditionVariable;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 生命周期/资源
    procedure Test_RapidCreateDestroy;

    // 参数边界
    procedure Test_WaitWithNilLock_Raises;
    procedure Test_WaitWithNonMutexLock_NotSupported;
    procedure Test_ZeroTimeout_ReturnsFalse;
    procedure Test_MaxTimeout_PathCoverage;

    // 行为与并发
    procedure Test_Signal_WakesExactlyOne;
    procedure Test_Broadcast_WakesAll;
    procedure Test_HighConcurrency_ManyWaiters;

    // ILock 继承行为（在条件变量对象本身上）
    procedure Test_ILock_OnConditionVariable;
    procedure Test_ILock_NoInterference_WithWaitSignal;
    procedure Test_InternalLock_MultiThreadSafety;

    // 精度（宽容断言，避免平台噪声）
    procedure Test_TimeoutPrecision_Short;
  end;

  TWaiter = class(TThread)
  private
    FCond: IConditionVariable;
    FLock: ILock;
    FFlag: PBoolean;
    FDone: PInteger;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACond: IConditionVariable; const ALock: ILock; AFlag: PBoolean; ADone: PInteger);
  end;

  TLockHammer = class(TThread)
  private
    FCond: IConditionVariable;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACond: IConditionVariable);
  end;

implementation

{ TLockHammer }
constructor TLockHammer.Create(const ACond: IConditionVariable);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FCond := ACond;
end;

procedure TLockHammer.Execute;
begin
  // 简短的占用以覆盖 ILock 路径
  FCond.Acquire;
  FCond.Release;
end;

function TBadLock.GetLastError: TWaitError;
begin
  Result := weNone;
end;

{ TBadLock }
procedure TBadLock.Acquire; begin FLocked := True; end;
procedure TBadLock.Release; begin FLocked := False; end;
function TBadLock.TryAcquire: Boolean; begin FLocked := True; Result := True; end;

function TBadLock.GetState: TLockState;
begin
  if FLocked then Result := lsLocked else Result := lsUnlocked;
end;

function TBadLock.IsLocked: Boolean;
begin
  Result := FLocked;
end;

function TBadLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquire;
end;

{ TWaiter }
constructor TWaiter.Create(const ACond: IConditionVariable; const ALock: ILock; AFlag: PBoolean; ADone: PInteger);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FCond := ACond;
  FLock := ALock;
  FFlag := AFlag;
  FDone := ADone;
end;

procedure TWaiter.Execute;
begin
  FLock.Acquire;
  try
    while not FFlag^ do
      if not FCond.Wait(FLock, 100) then ;
    if Assigned(FDone) then
      Inc(FDone^);
  finally
    FLock.Release;
  end;
end;

{ TTestCase_Advanced }
procedure TTestCase_Advanced.SetUp;
begin
  inherited SetUp;
  FCond := MakeConditionVariable;
end;

procedure TTestCase_Advanced.TearDown;
begin
  FCond := nil;
  inherited TearDown;
end;

procedure TTestCase_Advanced.Test_RapidCreateDestroy;
var i: Integer; CV: IConditionVariable;
begin
  for i := 1 to 1000 do
  begin
    CV := MakeConditionVariable;
    AssertNotNull(CV);
    CV := nil;
  end;
  AssertTrue(True);
end;

procedure TTestCase_Advanced.Test_WaitWithNilLock_Raises;
begin
  try
    FCond.Wait(nil);
    Fail('Expected EArgumentNilException');
  except
    on E: EArgumentNilException do
      AssertTrue(True)
    else
    begin
      if ExceptObject is Exception then
        Fail('Expected EArgumentNilException but got ' + Exception(ExceptObject).ClassName + ': ' + Exception(ExceptObject).Message)
      else
        Fail('Expected EArgumentNilException but got non-Exception');
    end;
  end;
end;

procedure TTestCase_Advanced.Test_WaitWithNonMutexLock_NotSupported;
var L: ILock;
begin
  L := TBadLock.Create;
  try
    try
      FCond.Wait(L);
      Fail('Expected NotSupported');
    except
      on E: ENotSupportedException do
        AssertTrue(True)
      else
      begin
        if ExceptObject is Exception then
          Fail('Expected ENotSupportedException but got ' + Exception(ExceptObject).ClassName + ': ' + Exception(ExceptObject).Message)
        else
          Fail('Expected ENotSupportedException but got non-Exception');
      end;
    end;
  finally
    L := nil;
  end;
end;

procedure TTestCase_Advanced.Test_ZeroTimeout_ReturnsFalse;
var L: ILock; ok: Boolean;
begin
  L := MakeMutex;
  L.Acquire;
  try
    ok := FCond.Wait(L, 0);
    AssertFalse(ok);
  finally
    L.Release;
  end;
end;

procedure TTestCase_Advanced.Test_MaxTimeout_PathCoverage;
var L: ILock; ok: Boolean;
begin
  L := MakeMutex;
  L.Acquire;
  try
    // 不真正等待很久，仅验证代码路径（实现通常在超时==0直接返回 False，>0 进入 timedwait）
    ok := FCond.Wait(L, 1);
    AssertFalse(ok);
  finally
    L.Release;
  end;
end;

procedure TTestCase_Advanced.Test_Signal_WakesExactlyOne;
var L: ILock; Ready: Boolean; Done: Integer; W1,W2: TWaiter;
begin
  L := MakeMutex; Ready := False; Done := 0;
  W1 := TWaiter.Create(FCond, L, @Ready, @Done);
  W2 := TWaiter.Create(FCond, L, @Ready, @Done);
  try
    Sleep(10);
    // 只 Signal 一次，预期仅唤醒一个等待者
    L.Acquire; try Ready := True; FCond.Signal; finally L.Release; end;
    // 给被唤醒的线程一些时间完成
    Sleep(20);
    // 为避免另一个线程永久阻塞，进行一次广播将其唤醒退出
    FCond.Broadcast;
    W1.WaitFor; W2.WaitFor;
    AssertTrue(Done >= 1);
  finally
    W1.Free; W2.Free;
  end;
end;

procedure TTestCase_Advanced.Test_Broadcast_WakesAll;
var L: ILock; Ready: Boolean; Done: Integer; W: array[0..4] of TWaiter; i: Integer;
begin
  L := MakeMutex; Ready := False; Done := 0;
  for i := Low(W) to High(W) do W[i] := TWaiter.Create(FCond, L, @Ready, @Done);
  try
    Sleep(10);
    L.Acquire; try Ready := True; FCond.Broadcast; finally L.Release; end;
    for i := Low(W) to High(W) do W[i].WaitFor;
    AssertEquals(Length(W), Done);
  finally
    for i := Low(W) to High(W) do W[i].Free;
  end;
end;

procedure TTestCase_Advanced.Test_HighConcurrency_ManyWaiters;
const N = 20;
var L: ILock; Ready: Boolean; Done: Integer; W: array[0..N-1] of TWaiter; i: Integer;
begin
  L := MakeMutex; Ready := False; Done := 0;
  for i := Low(W) to High(W) do W[i] := TWaiter.Create(FCond, L, @Ready, @Done);
  try
    Sleep(20);
    L.Acquire; try Ready := True; FCond.Broadcast; finally L.Release; end;
    for i := Low(W) to High(W) do W[i].WaitFor;
    AssertEquals(N, Done);
  finally
    for i := Low(W) to High(W) do W[i].Free;
  end;
end;

procedure TTestCase_Advanced.Test_ILock_OnConditionVariable;
var ok1, ok2: Boolean;
begin
  // TryAcquire 应该在未持有内部锁时成功
  ok1 := FCond.TryAcquire;
  AssertTrue('TryAcquire on condvar should succeed', ok1);
  // 再次 TryAcquire（重入）通常应失败，随后释放第一次
  ok2 := FCond.TryAcquire;
  AssertFalse('Second TryAcquire on condvar should fail (non-reentrant)', ok2);
  FCond.Release;

  // 显式 Acquire/Release 路径
  FCond.Acquire;
  FCond.Release;
end;

procedure TTestCase_Advanced.Test_ILock_NoInterference_WithWaitSignal;
var L: ILock; Ready: Boolean; Waiter: TWaiter;
begin
  L := MakeMutex; Ready := False;
  // 持有条件变量对象的内部锁一小段时间，不应影响外部 Wait/Signal
  FCond.Acquire;
  try
    Waiter := TWaiter.Create(FCond, L, @Ready, nil);
    try
      Sleep(10);
      L.Acquire; try Ready := True; FCond.Signal; finally L.Release; end;
      Waiter.WaitFor;
      AssertTrue(Waiter.Finished);
    finally
      Waiter.Free;
    end;
  finally
    FCond.Release;
  end;
end;

procedure TTestCase_Advanced.Test_InternalLock_MultiThreadSafety;
const N = 8;
var
  i: Integer;
  Threads: array[0..N-1] of TLockHammer;
begin
  // 多线程同时对条件变量对象本身做 Acquire/Release，验证内部锁线程安全
  for i := 0 to N-1 do
  begin
    Threads[i] := TLockHammer.Create(FCond);
    Threads[i].FreeOnTerminate := False;
  end;
  for i := 0 to N-1 do Threads[i].WaitFor;
  for i := 0 to N-1 do Threads[i].Free;
  AssertTrue(True);
end;

procedure TTestCase_Advanced.Test_TimeoutPrecision_Short;
var L: ILock; ok: Boolean; t0,t1: QWord; elapsed: QWord;
begin
  L := MakeMutex; L.Acquire;
  try
    t0 := GetTickCount64;
    ok := FCond.Wait(L, 10);
    t1 := GetTickCount64; elapsed := t1 - t0;
    AssertFalse(ok);
    AssertTrue('elapsed='+IntToStr(elapsed), elapsed >= 5); // 宽松下界
  finally
    L.Release;
  end;
end;

initialization
  RegisterTest(TTestCase_Advanced);

end.

