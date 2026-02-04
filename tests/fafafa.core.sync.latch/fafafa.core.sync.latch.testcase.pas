{$CODEPAGE UTF8}
unit fafafa.core.sync.latch.testcase;

{**
 * fafafa.core.sync.latch 边界测试套件
 *
 * 测试 ILatch（Java 风格倒计数闭锁）的：
 * - 边界条件（count=0, count=1, count=max）
 * - 超时边界（0ms, 1ms, maxint）
 * - 并发场景（多线程 CountDown）
 * - 压力测试（高并发、快速操作）
 *
 * @author fafafaStudio
 * @version 1.0
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.latch,
  TestHelpers_Sync;

type
  // ===== 基础功能测试 =====
  TTestCase_Latch_Basic = class(TTestCase)
  published
    procedure Test_Create_CountOne;
    procedure Test_Create_CountTen;
    procedure Test_GetCount_Initial;
    procedure Test_CountDown_DecrementsCount;
    procedure Test_CountDown_ZeroCount_NoOp;
    procedure Test_Await_ZeroCount_Immediate;
    procedure Test_Await_AfterCountDown;
  end;

  // ===== 边界条件测试 =====
  TTestCase_Latch_Boundary = class(TTestCase)
  published
    // 计数边界
    procedure Test_Create_CountZero;
    procedure Test_Create_CountOne_Await;
    procedure Test_Create_LargeCount;

    // 超时边界
    procedure Test_AwaitTimeout_ZeroMs_NotReady;
    procedure Test_AwaitTimeout_ZeroMs_Ready;
    procedure Test_AwaitTimeout_OneMs_NotReady;
    procedure Test_AwaitTimeout_LargeMs_Ready;

    // 多次 CountDown 边界
    procedure Test_CountDown_MoreThanCount;
    procedure Test_CountDown_Exactly_Count;
  end;

  // ===== 并发测试 =====
  TTestCase_Latch_Concurrent = class(TTestCase)
  published
    // 门控启动模式
    procedure Test_GateStart_SingleThread;
    procedure Test_GateStart_FourThreads;
    procedure Test_GateStart_ManyThreads;

    // 等待完成模式
    procedure Test_WaitCompletion_SingleWorker;
    procedure Test_WaitCompletion_MultipleWorkers;
    procedure Test_WaitCompletion_ManyWorkers;
  end;

  // ===== 压力测试 =====
  TTestCase_Latch_Stress = class(TTestCase)
  published
    procedure Test_RapidCreateDestroy;
    procedure Test_RapidCountDown;
    procedure Test_HighConcurrency_CountDown;
    procedure Test_HighConcurrency_Await;
  end;

  // ===== 辅助线程类 =====

  // 等待 Latch 的工作线程
  TLatchWaiterThread = class(TWorkerThread)
  private
    FLatch: ILatch;
    FTimeoutMs: Cardinal;
    FTimedOut: Boolean;
  protected
    procedure DoWork; override;
  public
    constructor Create(AId: Integer; ALatch: ILatch; ATimeoutMs: Cardinal = High(Cardinal));
    property TimedOut: Boolean read FTimedOut;
  end;

  // 执行 CountDown 的工作线程
  TLatchCountDownThread = class(TWorkerThread)
  private
    FLatch: ILatch;
    FDelayMs: Integer;
  protected
    procedure DoWork; override;
  public
    constructor Create(AId: Integer; ALatch: ILatch; ADelayMs: Integer = 0);
  end;

implementation

{ TLatchWaiterThread }

constructor TLatchWaiterThread.Create(AId: Integer; ALatch: ILatch; ATimeoutMs: Cardinal);
begin
  inherited Create(AId);
  FLatch := ALatch;
  FTimeoutMs := ATimeoutMs;
  FTimedOut := False;
end;

procedure TLatchWaiterThread.DoWork;
begin
  if FTimeoutMs = High(Cardinal) then
  begin
    FLatch.Await;
    FTimedOut := False;
  end
  else
  begin
    FTimedOut := not FLatch.AwaitTimeout(FTimeoutMs);
  end;
end;

{ TLatchCountDownThread }

constructor TLatchCountDownThread.Create(AId: Integer; ALatch: ILatch; ADelayMs: Integer);
begin
  inherited Create(AId);
  FLatch := ALatch;
  FDelayMs := ADelayMs;
end;

procedure TLatchCountDownThread.DoWork;
begin
  if FDelayMs > 0 then
    Sleep(FDelayMs);
  FLatch.CountDown;
end;

{ TTestCase_Latch_Basic }

procedure TTestCase_Latch_Basic.Test_Create_CountOne;
var
  L: ILatch;
begin
  L := MakeLatch(1);
  AssertNotNull('MakeLatch should return non-nil', L);
  AssertEquals('Initial count should be 1', 1, L.GetCount);
end;

procedure TTestCase_Latch_Basic.Test_Create_CountTen;
var
  L: ILatch;
begin
  L := MakeLatch(10);
  AssertEquals('Initial count should be 10', 10, L.GetCount);
end;

procedure TTestCase_Latch_Basic.Test_GetCount_Initial;
var
  L: ILatch;
begin
  L := MakeLatch(5);
  AssertEquals('GetCount should return initial value', 5, L.GetCount);
end;

procedure TTestCase_Latch_Basic.Test_CountDown_DecrementsCount;
var
  L: ILatch;
begin
  L := MakeLatch(3);
  AssertEquals('Initial count', 3, L.GetCount);

  L.CountDown;
  AssertEquals('After first CountDown', 2, L.GetCount);

  L.CountDown;
  AssertEquals('After second CountDown', 1, L.GetCount);

  L.CountDown;
  AssertEquals('After third CountDown', 0, L.GetCount);
end;

procedure TTestCase_Latch_Basic.Test_CountDown_ZeroCount_NoOp;
var
  L: ILatch;
begin
  L := MakeLatch(1);
  L.CountDown;
  AssertEquals('Count should be 0', 0, L.GetCount);

  // 再次 CountDown 不应该导致负数
  L.CountDown;
  AssertTrue('Count should be >= 0', L.GetCount >= 0);
end;

procedure TTestCase_Latch_Basic.Test_Await_ZeroCount_Immediate;
var
  L: ILatch;
  StartTime, ElapsedMs: QWord;
begin
  L := MakeLatch(1);
  L.CountDown;
  AssertEquals('Count should be 0', 0, L.GetCount);

  StartTime := GetCurrentTimeMs;
  L.Await;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertTrue('Await on zero count should return immediately', ElapsedMs < 50);
end;

procedure TTestCase_Latch_Basic.Test_Await_AfterCountDown;
var
  L: ILatch;
  T: TLatchCountDownThread;
begin
  L := MakeLatch(1);

  T := TLatchCountDownThread.Create(0, L, 10);
  try
    T.Start;
    L.Await;
    T.WaitFor;

    AssertTrue('Await should complete after CountDown', T.Success);
    AssertEquals('Count should be 0', 0, L.GetCount);
  finally
    T.Free;
  end;
end;

{ TTestCase_Latch_Boundary }

procedure TTestCase_Latch_Boundary.Test_Create_CountZero;
var
  L: ILatch;
begin
  L := MakeLatch(0);
  AssertEquals('Count should be 0', 0, L.GetCount);

  // Await 应该立即返回
  L.Await;
  AssertTrue('Await on zero-count latch should succeed', True);
end;

procedure TTestCase_Latch_Boundary.Test_Create_CountOne_Await;
var
  L: ILatch;
  T: TLatchCountDownThread;
  StartTime, ElapsedMs: QWord;
begin
  L := MakeLatch(1);

  StartTime := GetCurrentTimeMs;
  T := TLatchCountDownThread.Create(0, L, 50);
  try
    T.Start;
    L.Await;
    ElapsedMs := GetCurrentTimeMs - StartTime;
    T.WaitFor;

    AssertTrue('Should wait for CountDown', ElapsedMs >= 40);
    AssertTrue('CountDown thread should succeed', T.Success);
  finally
    T.Free;
  end;
end;

procedure TTestCase_Latch_Boundary.Test_Create_LargeCount;
var
  L: ILatch;
  i: Integer;
begin
  L := MakeLatch(1000);
  AssertEquals('Initial count', 1000, L.GetCount);

  for i := 1 to 1000 do
    L.CountDown;

  AssertEquals('Count after 1000 CountDowns', 0, L.GetCount);
end;

procedure TTestCase_Latch_Boundary.Test_AwaitTimeout_ZeroMs_NotReady;
var
  L: ILatch;
  StartTime, ElapsedMs: QWord;
  Result: Boolean;
begin
  L := MakeLatch(1);

  StartTime := GetCurrentTimeMs;
  Result := L.AwaitTimeout(0);
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertFalse('AwaitTimeout(0) on non-ready should return False', Result);
  AssertTrue('Should return very quickly', ElapsedMs < 10);
end;

procedure TTestCase_Latch_Boundary.Test_AwaitTimeout_ZeroMs_Ready;
var
  L: ILatch;
  StartTime, ElapsedMs: QWord;
  Result: Boolean;
begin
  L := MakeLatch(1);
  L.CountDown;

  StartTime := GetCurrentTimeMs;
  Result := L.AwaitTimeout(0);
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertTrue('AwaitTimeout(0) on ready should return True', Result);
  AssertTrue('Should return very quickly', ElapsedMs < 10);
end;

procedure TTestCase_Latch_Boundary.Test_AwaitTimeout_OneMs_NotReady;
var
  L: ILatch;
  StartTime, ElapsedMs: QWord;
  Result: Boolean;
begin
  L := MakeLatch(1);

  StartTime := GetCurrentTimeMs;
  Result := L.AwaitTimeout(1);
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertFalse('AwaitTimeout(1) on non-ready should timeout', Result);
  // 允许一些时间误差
  AssertTrue('Should take approximately 1ms', ElapsedMs < 100);
end;

procedure TTestCase_Latch_Boundary.Test_AwaitTimeout_LargeMs_Ready;
var
  L: ILatch;
  T: TLatchCountDownThread;
  StartTime, ElapsedMs: QWord;
  Result: Boolean;
begin
  L := MakeLatch(1);

  T := TLatchCountDownThread.Create(0, L, 20);
  try
    StartTime := GetCurrentTimeMs;
    T.Start;
    Result := L.AwaitTimeout(10000);
    ElapsedMs := GetCurrentTimeMs - StartTime;
    T.WaitFor;

    AssertTrue('Should succeed with large timeout', Result);
    AssertTrue('Should complete quickly when signaled', ElapsedMs < 500);
  finally
    T.Free;
  end;
end;

procedure TTestCase_Latch_Boundary.Test_CountDown_MoreThanCount;
var
  L: ILatch;
  i: Integer;
begin
  L := MakeLatch(3);

  for i := 1 to 10 do
    L.CountDown;

  AssertTrue('Count should not go negative', L.GetCount >= 0);
end;

procedure TTestCase_Latch_Boundary.Test_CountDown_Exactly_Count;
var
  L: ILatch;
  i: Integer;
begin
  L := MakeLatch(5);

  for i := 1 to 5 do
  begin
    L.CountDown;
    AssertEquals(Format('Count after %d CountDowns', [i]), 5 - i, L.GetCount);
  end;
end;

{ TTestCase_Latch_Concurrent }

procedure TTestCase_Latch_Concurrent.Test_GateStart_SingleThread;
var
  StartGate: ILatch;
  Worker: TLatchWaiterThread;
begin
  StartGate := MakeLatch(1);

  Worker := TLatchWaiterThread.Create(0, StartGate);
  try
    Worker.Start;
    Sleep(10); // 让线程开始等待

    StartGate.CountDown; // 打开门
    Worker.WaitFor;

    AssertTrue('Worker should complete', Worker.Success);
    AssertFalse('Worker should not timeout', Worker.TimedOut);
  finally
    Worker.Free;
  end;
end;

procedure TTestCase_Latch_Concurrent.Test_GateStart_FourThreads;
var
  StartGate: ILatch;
  Workers: array[0..3] of TLatchWaiterThread;
  i, SuccessCount: Integer;
begin
  StartGate := MakeLatch(1);

  for i := 0 to 3 do
    Workers[i] := TLatchWaiterThread.Create(i, StartGate);

  try
    // 启动所有工作线程
    for i := 0 to 3 do
      Workers[i].Start;

    Sleep(20); // 让所有线程开始等待

    StartGate.CountDown; // 打开门

    // 等待所有线程完成
    SuccessCount := 0;
    for i := 0 to 3 do
    begin
      Workers[i].WaitFor;
      if Workers[i].Success and (not Workers[i].TimedOut) then
        Inc(SuccessCount);
    end;

    AssertEquals('All 4 threads should succeed', 4, SuccessCount);
  finally
    for i := 0 to 3 do
      Workers[i].Free;
  end;
end;

procedure TTestCase_Latch_Concurrent.Test_GateStart_ManyThreads;
var
  StartGate: ILatch;
  Workers: array of TLatchWaiterThread = nil;
  i, SuccessCount, ThreadCount: Integer;
begin
  ThreadCount := 50;
  SetLength(Workers, ThreadCount);
  StartGate := MakeLatch(1);

  for i := 0 to ThreadCount - 1 do
    Workers[i] := TLatchWaiterThread.Create(i, StartGate);

  try
    for i := 0 to ThreadCount - 1 do
      Workers[i].Start;

    Sleep(50);

    StartGate.CountDown;

    SuccessCount := 0;
    for i := 0 to ThreadCount - 1 do
    begin
      Workers[i].WaitFor;
      if Workers[i].Success and (not Workers[i].TimedOut) then
        Inc(SuccessCount);
    end;

    AssertEquals('All threads should succeed', ThreadCount, SuccessCount);
  finally
    for i := 0 to ThreadCount - 1 do
      Workers[i].Free;
  end;
end;

procedure TTestCase_Latch_Concurrent.Test_WaitCompletion_SingleWorker;
var
  DoneLatch: ILatch;
  Worker: TLatchCountDownThread;
begin
  DoneLatch := MakeLatch(1);

  Worker := TLatchCountDownThread.Create(0, DoneLatch, 10);
  try
    Worker.Start;
    DoneLatch.Await;
    Worker.WaitFor;

    AssertEquals('Count should be 0', 0, DoneLatch.GetCount);
    AssertTrue('Worker should succeed', Worker.Success);
  finally
    Worker.Free;
  end;
end;

procedure TTestCase_Latch_Concurrent.Test_WaitCompletion_MultipleWorkers;
var
  DoneLatch: ILatch;
  Workers: array[0..4] of TLatchCountDownThread;
  i: Integer;
begin
  DoneLatch := MakeLatch(5);

  for i := 0 to 4 do
    Workers[i] := TLatchCountDownThread.Create(i, DoneLatch, i * 5);

  try
    for i := 0 to 4 do
      Workers[i].Start;

    DoneLatch.Await;

    for i := 0 to 4 do
      Workers[i].WaitFor;

    AssertEquals('Count should be 0', 0, DoneLatch.GetCount);
  finally
    for i := 0 to 4 do
      Workers[i].Free;
  end;
end;

procedure TTestCase_Latch_Concurrent.Test_WaitCompletion_ManyWorkers;
var
  DoneLatch: ILatch;
  Workers: array of TLatchCountDownThread = nil;
  i, WorkerCount: Integer;
begin
  WorkerCount := 100;
  SetLength(Workers, WorkerCount);
  DoneLatch := MakeLatch(WorkerCount);

  for i := 0 to WorkerCount - 1 do
    Workers[i] := TLatchCountDownThread.Create(i, DoneLatch, Random(10));

  try
    for i := 0 to WorkerCount - 1 do
      Workers[i].Start;

    DoneLatch.Await;

    for i := 0 to WorkerCount - 1 do
      Workers[i].WaitFor;

    AssertEquals('Count should be 0', 0, DoneLatch.GetCount);
  finally
    for i := 0 to WorkerCount - 1 do
      Workers[i].Free;
  end;
end;

{ TTestCase_Latch_Stress }

procedure TTestCase_Latch_Stress.Test_RapidCreateDestroy;
var
  i: Integer;
  L: ILatch;
  StartTime, ElapsedMs: QWord;
  Iterations: Integer;
begin
  Iterations := 1000;
  StartTime := GetCurrentTimeMs;

  for i := 1 to Iterations do
  begin
    L := MakeLatch(i mod 100 + 1);
    L.CountDown;
    L := nil;
  end;

  ElapsedMs := GetCurrentTimeMs - StartTime;
  WriteLn(Format('%d Latch create/destroy cycles in %d ms', [Iterations, ElapsedMs]));

  AssertTrue('Should complete in reasonable time', ElapsedMs < 5000);
end;

procedure TTestCase_Latch_Stress.Test_RapidCountDown;
var
  L: ILatch;
  i: Integer;
  StartTime, ElapsedMs: QWord;
  Iterations: Integer;
begin
  Iterations := 10000;
  L := MakeLatch(Iterations);

  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
    L.CountDown;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  WriteLn(Format('%d CountDown calls in %d ms', [Iterations, ElapsedMs]));

  AssertEquals('Count should be 0', 0, L.GetCount);
  AssertTrue('Should complete quickly', ElapsedMs < 1000);
end;

procedure TTestCase_Latch_Stress.Test_HighConcurrency_CountDown;
var
  L: ILatch;
  Workers: array of TLatchCountDownThread = nil;
  i, ThreadCount, SuccessCount: Integer;
  StartTime, ElapsedMs: QWord;
begin
  ThreadCount := 100;
  SetLength(Workers, ThreadCount);
  L := MakeLatch(ThreadCount);

  for i := 0 to ThreadCount - 1 do
    Workers[i] := TLatchCountDownThread.Create(i, L, 0);

  try
    StartTime := GetCurrentTimeMs;

    for i := 0 to ThreadCount - 1 do
      Workers[i].Start;

    L.Await;

    SuccessCount := 0;
    for i := 0 to ThreadCount - 1 do
    begin
      Workers[i].WaitFor;
      if Workers[i].Success then
        Inc(SuccessCount);
    end;

    ElapsedMs := GetCurrentTimeMs - StartTime;
    WriteLn(Format('High concurrency CountDown: %d threads in %d ms', [ThreadCount, ElapsedMs]));

    AssertEquals('All threads should succeed', ThreadCount, SuccessCount);
    AssertEquals('Count should be 0', 0, L.GetCount);
  finally
    for i := 0 to ThreadCount - 1 do
      Workers[i].Free;
  end;
end;

procedure TTestCase_Latch_Stress.Test_HighConcurrency_Await;
var
  L: ILatch;
  Waiters: array of TLatchWaiterThread = nil;
  CountDownThread: TLatchCountDownThread;
  i, ThreadCount, SuccessCount: Integer;
  StartTime, ElapsedMs: QWord;
begin
  ThreadCount := 100;
  SetLength(Waiters, ThreadCount);
  L := MakeLatch(1);

  for i := 0 to ThreadCount - 1 do
    Waiters[i] := TLatchWaiterThread.Create(i, L);

  CountDownThread := TLatchCountDownThread.Create(999, L, 50);
  try
    StartTime := GetCurrentTimeMs;

    // 启动所有等待线程
    for i := 0 to ThreadCount - 1 do
      Waiters[i].Start;

    Sleep(20); // 让所有线程开始等待

    // 启动 CountDown 线程
    CountDownThread.Start;

    // 等待所有线程完成
    SuccessCount := 0;
    for i := 0 to ThreadCount - 1 do
    begin
      Waiters[i].WaitFor;
      if Waiters[i].Success and (not Waiters[i].TimedOut) then
        Inc(SuccessCount);
    end;

    CountDownThread.WaitFor;

    ElapsedMs := GetCurrentTimeMs - StartTime;
    WriteLn(Format('High concurrency Await: %d waiters in %d ms', [ThreadCount, ElapsedMs]));

    AssertEquals('All waiters should succeed', ThreadCount, SuccessCount);
  finally
    CountDownThread.Free;
    for i := 0 to ThreadCount - 1 do
      Waiters[i].Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Latch_Basic);
  RegisterTest(TTestCase_Latch_Boundary);
  RegisterTest(TTestCase_Latch_Concurrent);
  RegisterTest(TTestCase_Latch_Stress);

end.
