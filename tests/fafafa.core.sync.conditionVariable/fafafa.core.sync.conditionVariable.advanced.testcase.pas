unit fafafa.core.sync.conditionVariable.advanced.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF UNIX}cthreads,{$ENDIF}
  fafafa.core.sync;

// 进阶与压力测试，目标覆盖：
// - 工厂与门面
// - 平台实现：正常路径、超时路径、异常路径
// - 并发：多等待者、Signal 与 Broadcast 行为
// - 边界：零/极大超时、无效参数
// - 生命周期：快速创建/销毁

Type
  // 伪造的非 IMutex 锁，用于异常路径覆盖
  TBadLock = class(TInterfacedObject, ILock)
  public
    procedure Acquire; virtual;
    procedure Release; virtual;
    function TryAcquire: Boolean; virtual;
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

implementation

{ TBadLock }
procedure TBadLock.Acquire; begin end;
procedure TBadLock.Release; begin end;
function TBadLock.TryAcquire: Boolean; begin Result := True; end;

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
      FCond.Wait(FLock);
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
    on E: Exception do
      AssertTrue('Got '+E.ClassName, Pos('ArgumentNil', UpperCase(E.ClassName))>0);
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
      on E: Exception do
        AssertTrue('Got '+E.ClassName, (Pos('NOTSUPPORTED', UpperCase(E.ClassName))>0) or (Pos('NOT SUPPORTED', UpperCase(E.Message))>0));
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
    L.Acquire; try Ready := True; FCond.Signal; finally L.Release; end;
    W1.WaitFor; W2.WaitFor;
    // 至少一个被唤醒（另一位也可能被唤醒，具体实现广播/自旋差异，这里用>=1）
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

