{$CODEPAGE UTF8}
unit fafafa.core.sync.waitgroup.testcase;

{**
 * fafafa.core.sync.waitgroup 边界测试套件
 *
 * 测试 IWaitGroup（Go 风格等待组）的：
 * - 边界条件（count=0, count=1, Add正负值）
 * - 超时边界（0ms, 1ms, maxint）
 * - 并发场景（多线程 Add/Done）
 * - 错误处理（负计数检测）
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
  fafafa.core.sync.waitgroup,
  TestHelpers_Sync;

type
  // ===== 基础功能测试 =====
  TTestCase_WaitGroup_Basic = class(TTestCase)
  published
    procedure Test_Create;
    procedure Test_Add_Positive;
    procedure Test_Add_Negative;
    procedure Test_Done;
    procedure Test_GetCount_Initial;
    procedure Test_Wait_ZeroCount;
  end;

  // ===== 边界条件测试 =====
  TTestCase_WaitGroup_Boundary = class(TTestCase)
  published
    // 计数边界
    procedure Test_Add_Zero;
    procedure Test_Add_Large;
    procedure Test_Done_ToZero;

    // 超时边界
    procedure Test_WaitTimeout_ZeroMs_NotReady;
    procedure Test_WaitTimeout_ZeroMs_Ready;
    procedure Test_WaitTimeout_OneMs_NotReady;
    procedure Test_WaitTimeout_LargeMs_Ready;

    // 错误处理
    procedure Test_Done_NegativeCount_Raises;
    procedure Test_Add_ResultsNegative_Raises;
  end;

  // ===== 并发测试 =====
  TTestCase_WaitGroup_Concurrent = class(TTestCase)
  published
    procedure Test_SingleWorker;
    procedure Test_MultipleWorkers;
    procedure Test_ManyWorkers;
    procedure Test_ConcurrentAdd;
    procedure Test_AddDuringWait;
  end;

  // ===== 压力测试 =====
  TTestCase_WaitGroup_Stress = class(TTestCase)
  published
    procedure Test_RapidAddDone;
    procedure Test_RapidCreateDestroy;
    procedure Test_HighConcurrency_Workers;
    procedure Test_HighConcurrency_Waiters;
  end;

  // ===== 辅助线程类 =====

  // 等待 WaitGroup 的线程
  TWaitGroupWaiterThread = class(TWorkerThread)
  private
    FWaitGroup: IWaitGroup;
    FTimeoutMs: Cardinal;
    FTimedOut: Boolean;
  protected
    procedure DoWork; override;
  public
    constructor Create(AId: Integer; AWG: IWaitGroup; ATimeoutMs: Cardinal = High(Cardinal));
    property TimedOut: Boolean read FTimedOut;
  end;

  // 执行 Done 的工作线程
  TWaitGroupWorkerThread = class(TWorkerThread)
  private
    FWaitGroup: IWaitGroup;
    FDelayMs: Integer;
    FWorkDurationMs: Integer;
  protected
    procedure DoWork; override;
  public
    constructor Create(AId: Integer; AWG: IWaitGroup; ADelayMs: Integer = 0; AWorkDurationMs: Integer = 0);
  end;

  // 执行 Add 的线程
  TWaitGroupAdderThread = class(TWorkerThread)
  private
    FWaitGroup: IWaitGroup;
    FDelta: Integer;
    FDelayMs: Integer;
  protected
    procedure DoWork; override;
  public
    constructor Create(AId: Integer; AWG: IWaitGroup; ADelta: Integer; ADelayMs: Integer = 0);
  end;

implementation

{ TWaitGroupWaiterThread }

constructor TWaitGroupWaiterThread.Create(AId: Integer; AWG: IWaitGroup; ATimeoutMs: Cardinal);
begin
  inherited Create(AId);
  FWaitGroup := AWG;
  FTimeoutMs := ATimeoutMs;
  FTimedOut := False;
end;

procedure TWaitGroupWaiterThread.DoWork;
begin
  if FTimeoutMs = High(Cardinal) then
  begin
    FWaitGroup.Wait;
    FTimedOut := False;
  end
  else
  begin
    FTimedOut := not FWaitGroup.WaitTimeout(FTimeoutMs);
  end;
end;

{ TWaitGroupWorkerThread }

constructor TWaitGroupWorkerThread.Create(AId: Integer; AWG: IWaitGroup; ADelayMs: Integer; AWorkDurationMs: Integer);
begin
  inherited Create(AId);
  FWaitGroup := AWG;
  FDelayMs := ADelayMs;
  FWorkDurationMs := AWorkDurationMs;
end;

procedure TWaitGroupWorkerThread.DoWork;
begin
  if FDelayMs > 0 then
    Sleep(FDelayMs);
  if FWorkDurationMs > 0 then
    Sleep(FWorkDurationMs);
  FWaitGroup.Done;
end;

{ TWaitGroupAdderThread }

constructor TWaitGroupAdderThread.Create(AId: Integer; AWG: IWaitGroup; ADelta: Integer; ADelayMs: Integer);
begin
  inherited Create(AId);
  FWaitGroup := AWG;
  FDelta := ADelta;
  FDelayMs := ADelayMs;
end;

procedure TWaitGroupAdderThread.DoWork;
begin
  if FDelayMs > 0 then
    Sleep(FDelayMs);
  FWaitGroup.Add(FDelta);
end;

{ TTestCase_WaitGroup_Basic }

procedure TTestCase_WaitGroup_Basic.Test_Create;
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  AssertNotNull('MakeWaitGroup should return non-nil', WG);
  AssertEquals('Initial count should be 0', 0, WG.GetCount);
end;

procedure TTestCase_WaitGroup_Basic.Test_Add_Positive;
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  WG.Add(5);
  AssertEquals('Count after Add(5)', 5, WG.GetCount);

  WG.Add(3);
  AssertEquals('Count after Add(3)', 8, WG.GetCount);
end;

procedure TTestCase_WaitGroup_Basic.Test_Add_Negative;
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  WG.Add(5);
  WG.Add(-2);
  AssertEquals('Count after Add(5) and Add(-2)', 3, WG.GetCount);
end;

procedure TTestCase_WaitGroup_Basic.Test_Done;
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  WG.Add(3);
  WG.Done;
  AssertEquals('Count after Add(3) and Done', 2, WG.GetCount);

  WG.Done;
  AssertEquals('Count after second Done', 1, WG.GetCount);
end;

procedure TTestCase_WaitGroup_Basic.Test_GetCount_Initial;
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  AssertEquals('GetCount should return 0 initially', 0, WG.GetCount);
end;

procedure TTestCase_WaitGroup_Basic.Test_Wait_ZeroCount;
var
  WG: IWaitGroup;
  StartTime, ElapsedMs: QWord;
begin
  WG := MakeWaitGroup;

  StartTime := GetCurrentTimeMs;
  WG.Wait;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertTrue('Wait on zero count should return immediately', ElapsedMs < 50);
end;

{ TTestCase_WaitGroup_Boundary }

procedure TTestCase_WaitGroup_Boundary.Test_Add_Zero;
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  WG.Add(0);
  AssertEquals('Add(0) should not change count', 0, WG.GetCount);

  WG.Add(5);
  WG.Add(0);
  AssertEquals('Add(0) should not change count (after Add(5))', 5, WG.GetCount);
end;

procedure TTestCase_WaitGroup_Boundary.Test_Add_Large;
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  WG.Add(10000);
  AssertEquals('Large Add should work', 10000, WG.GetCount);
end;

procedure TTestCase_WaitGroup_Boundary.Test_Done_ToZero;
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  WG.Add(1);
  WG.Done;
  AssertEquals('Done should bring count to 0', 0, WG.GetCount);
end;

procedure TTestCase_WaitGroup_Boundary.Test_WaitTimeout_ZeroMs_NotReady;
var
  WG: IWaitGroup;
  StartTime, ElapsedMs: QWord;
  Result: Boolean;
begin
  WG := MakeWaitGroup;
  WG.Add(1);

  StartTime := GetCurrentTimeMs;
  Result := WG.WaitTimeout(0);
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertFalse('WaitTimeout(0) on non-ready should return False', Result);
  AssertTrue('Should return very quickly', ElapsedMs < 10);
end;

procedure TTestCase_WaitGroup_Boundary.Test_WaitTimeout_ZeroMs_Ready;
var
  WG: IWaitGroup;
  StartTime, ElapsedMs: QWord;
  Result: Boolean;
begin
  WG := MakeWaitGroup;
  // Count is already 0

  StartTime := GetCurrentTimeMs;
  Result := WG.WaitTimeout(0);
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertTrue('WaitTimeout(0) on ready should return True', Result);
  AssertTrue('Should return very quickly', ElapsedMs < 10);
end;

procedure TTestCase_WaitGroup_Boundary.Test_WaitTimeout_OneMs_NotReady;
var
  WG: IWaitGroup;
  StartTime, ElapsedMs: QWord;
  Result: Boolean;
begin
  WG := MakeWaitGroup;
  WG.Add(1);

  StartTime := GetCurrentTimeMs;
  Result := WG.WaitTimeout(1);
  ElapsedMs := GetCurrentTimeMs - StartTime;

  AssertFalse('WaitTimeout(1) on non-ready should timeout', Result);
  AssertTrue('Should take approximately 1ms', ElapsedMs < 100);
end;

procedure TTestCase_WaitGroup_Boundary.Test_WaitTimeout_LargeMs_Ready;
var
  WG: IWaitGroup;
  Worker: TWaitGroupWorkerThread;
  StartTime, ElapsedMs: QWord;
  Result: Boolean;
begin
  WG := MakeWaitGroup;
  WG.Add(1);

  Worker := TWaitGroupWorkerThread.Create(0, WG, 20);
  try
    StartTime := GetCurrentTimeMs;
    Worker.Start;
    Result := WG.WaitTimeout(10000);
    ElapsedMs := GetCurrentTimeMs - StartTime;
    Worker.WaitFor;

    AssertTrue('Should succeed with large timeout', Result);
    AssertTrue('Should complete quickly when signaled', ElapsedMs < 500);
  finally
    Worker.Free;
  end;
end;

procedure TTestCase_WaitGroup_Boundary.Test_Done_NegativeCount_Raises;
var
  WG: IWaitGroup;
  ExceptionRaised: Boolean;
begin
  WG := MakeWaitGroup;
  ExceptionRaised := False;

  try
    WG.Done; // Count is 0, Done would make it -1
  except
    ExceptionRaised := True;
  end;

  AssertTrue('Done on zero count should raise exception', ExceptionRaised);
end;

procedure TTestCase_WaitGroup_Boundary.Test_Add_ResultsNegative_Raises;
var
  WG: IWaitGroup;
  ExceptionRaised: Boolean;
begin
  WG := MakeWaitGroup;
  WG.Add(2);
  ExceptionRaised := False;

  try
    WG.Add(-5); // Would result in -3
  except
    ExceptionRaised := True;
  end;

  AssertTrue('Add resulting in negative count should raise exception', ExceptionRaised);
end;

{ TTestCase_WaitGroup_Concurrent }

procedure TTestCase_WaitGroup_Concurrent.Test_SingleWorker;
var
  WG: IWaitGroup;
  Worker: TWaitGroupWorkerThread;
begin
  WG := MakeWaitGroup;
  WG.Add(1);

  Worker := TWaitGroupWorkerThread.Create(0, WG, 10);
  try
    Worker.Start;
    WG.Wait;
    Worker.WaitFor;

    AssertEquals('Count should be 0', 0, WG.GetCount);
    AssertTrue('Worker should succeed', Worker.Success);
  finally
    Worker.Free;
  end;
end;

procedure TTestCase_WaitGroup_Concurrent.Test_MultipleWorkers;
var
  WG: IWaitGroup;
  Workers: array[0..4] of TWaitGroupWorkerThread;
  i, SuccessCount: Integer;
begin
  WG := MakeWaitGroup;
  WG.Add(5);

  for i := 0 to 4 do
    Workers[i] := TWaitGroupWorkerThread.Create(i, WG, i * 5);

  try
    for i := 0 to 4 do
      Workers[i].Start;

    WG.Wait;

    SuccessCount := 0;
    for i := 0 to 4 do
    begin
      Workers[i].WaitFor;
      if Workers[i].Success then
        Inc(SuccessCount);
    end;

    AssertEquals('Count should be 0', 0, WG.GetCount);
    AssertEquals('All workers should succeed', 5, SuccessCount);
  finally
    for i := 0 to 4 do
      Workers[i].Free;
  end;
end;

procedure TTestCase_WaitGroup_Concurrent.Test_ManyWorkers;
var
  WG: IWaitGroup;
  Workers: array of TWaitGroupWorkerThread = nil;
  i, WorkerCount, SuccessCount: Integer;
begin
  WorkerCount := 100;
  SetLength(Workers, WorkerCount);
  WG := MakeWaitGroup;
  WG.Add(WorkerCount);

  for i := 0 to WorkerCount - 1 do
    Workers[i] := TWaitGroupWorkerThread.Create(i, WG, Random(10));

  try
    for i := 0 to WorkerCount - 1 do
      Workers[i].Start;

    WG.Wait;

    SuccessCount := 0;
    for i := 0 to WorkerCount - 1 do
    begin
      Workers[i].WaitFor;
      if Workers[i].Success then
        Inc(SuccessCount);
    end;

    AssertEquals('Count should be 0', 0, WG.GetCount);
    AssertEquals('All workers should succeed', WorkerCount, SuccessCount);
  finally
    for i := 0 to WorkerCount - 1 do
      Workers[i].Free;
  end;
end;

procedure TTestCase_WaitGroup_Concurrent.Test_ConcurrentAdd;
var
  WG: IWaitGroup;
  Adders: array[0..9] of TWaitGroupAdderThread;
  Workers: array[0..9] of TWaitGroupWorkerThread;
  i: Integer;
begin
  WG := MakeWaitGroup;

  // 先创建 Adder 线程
  for i := 0 to 9 do
    Adders[i] := TWaitGroupAdderThread.Create(i, WG, 1);

  try
    // 启动所有 Adder
    for i := 0 to 9 do
      Adders[i].Start;

    // 等待所有 Adder 完成
    for i := 0 to 9 do
      Adders[i].WaitFor;

    AssertEquals('Count after concurrent Add', 10, WG.GetCount);

    // 创建 Worker 线程
    for i := 0 to 9 do
      Workers[i] := TWaitGroupWorkerThread.Create(i, WG);

    // 启动所有 Worker
    for i := 0 to 9 do
      Workers[i].Start;

    WG.Wait;

    // 等待所有 Worker 完成
    for i := 0 to 9 do
      Workers[i].WaitFor;

    AssertEquals('Count should be 0', 0, WG.GetCount);
  finally
    for i := 0 to 9 do
    begin
      Adders[i].Free;
      Workers[i].Free;
    end;
  end;
end;

procedure TTestCase_WaitGroup_Concurrent.Test_AddDuringWait;
var
  WG: IWaitGroup;
  Worker1, Worker2: TWaitGroupWorkerThread;
  Adder: TWaitGroupAdderThread;
  Waiter: TWaitGroupWaiterThread;
begin
  WG := MakeWaitGroup;
  WG.Add(1);

  Worker1 := TWaitGroupWorkerThread.Create(0, WG, 50);
  Worker2 := nil;
  Adder := TWaitGroupAdderThread.Create(1, WG, 1, 20);
  Waiter := TWaitGroupWaiterThread.Create(2, WG);

  try
    // 启动等待线程
    Waiter.Start;
    Sleep(5);

    // 启动第一个工作线程
    Worker1.Start;

    // 在 Wait 期间 Add
    Adder.Start;
    Adder.WaitFor;

    // 现在 count 应该是 1 (Worker1 还没 Done)
    // 创建第二个工作线程
    Worker2 := TWaitGroupWorkerThread.Create(3, WG, 30);
    Worker2.Start;

    // Worker1 完成后，count = 1
    Worker1.WaitFor;

    // Worker2 完成后，count = 0
    Worker2.WaitFor;

    // 等待 Waiter 完成
    Waiter.WaitFor;

    AssertEquals('Count should be 0', 0, WG.GetCount);
    AssertTrue('Waiter should succeed', Waiter.Success);
  finally
    Worker1.Free;
    if Worker2 <> nil then Worker2.Free;
    Adder.Free;
    Waiter.Free;
  end;
end;

{ TTestCase_WaitGroup_Stress }

procedure TTestCase_WaitGroup_Stress.Test_RapidAddDone;
var
  WG: IWaitGroup;
  i: Integer;
  StartTime, ElapsedMs: QWord;
  Iterations: Integer;
begin
  Iterations := 10000;
  WG := MakeWaitGroup;

  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
  begin
    WG.Add(1);
    WG.Done;
  end;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  WriteLn(Format('%d Add/Done pairs in %d ms', [Iterations, ElapsedMs]));

  AssertEquals('Count should be 0', 0, WG.GetCount);
  AssertTrue('Should complete quickly', ElapsedMs < 1000);
end;

procedure TTestCase_WaitGroup_Stress.Test_RapidCreateDestroy;
var
  WG: IWaitGroup;
  i: Integer;
  StartTime, ElapsedMs: QWord;
  Iterations: Integer;
begin
  Iterations := 1000;

  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
  begin
    WG := MakeWaitGroup;
    WG.Add(i mod 100 + 1);
    WG := nil;
  end;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  WriteLn(Format('%d WaitGroup create/destroy in %d ms', [Iterations, ElapsedMs]));
  AssertTrue('Should complete in reasonable time', ElapsedMs < 5000);
end;

procedure TTestCase_WaitGroup_Stress.Test_HighConcurrency_Workers;
var
  WG: IWaitGroup;
  Workers: array of TWaitGroupWorkerThread = nil;
  i, ThreadCount, SuccessCount: Integer;
  StartTime, ElapsedMs: QWord;
begin
  ThreadCount := 200;
  SetLength(Workers, ThreadCount);
  WG := MakeWaitGroup;
  WG.Add(ThreadCount);

  for i := 0 to ThreadCount - 1 do
    Workers[i] := TWaitGroupWorkerThread.Create(i, WG, 0, Random(5));

  try
    StartTime := GetCurrentTimeMs;

    for i := 0 to ThreadCount - 1 do
      Workers[i].Start;

    WG.Wait;

    SuccessCount := 0;
    for i := 0 to ThreadCount - 1 do
    begin
      Workers[i].WaitFor;
      if Workers[i].Success then
        Inc(SuccessCount);
    end;

    ElapsedMs := GetCurrentTimeMs - StartTime;
    WriteLn(Format('High concurrency workers: %d threads in %d ms', [ThreadCount, ElapsedMs]));

    AssertEquals('All workers should succeed', ThreadCount, SuccessCount);
    AssertEquals('Count should be 0', 0, WG.GetCount);
  finally
    for i := 0 to ThreadCount - 1 do
      Workers[i].Free;
  end;
end;

procedure TTestCase_WaitGroup_Stress.Test_HighConcurrency_Waiters;
var
  WG: IWaitGroup;
  Waiters: array of TWaitGroupWaiterThread = nil;
  Worker: TWaitGroupWorkerThread;
  i, ThreadCount, SuccessCount: Integer;
  StartTime, ElapsedMs: QWord;
begin
  ThreadCount := 100;
  SetLength(Waiters, ThreadCount);
  WG := MakeWaitGroup;
  WG.Add(1);

  for i := 0 to ThreadCount - 1 do
    Waiters[i] := TWaitGroupWaiterThread.Create(i, WG);

  Worker := TWaitGroupWorkerThread.Create(999, WG, 50);
  try
    StartTime := GetCurrentTimeMs;

    // 启动所有等待线程
    for i := 0 to ThreadCount - 1 do
      Waiters[i].Start;

    Sleep(20);

    // 启动工作线程
    Worker.Start;

    // 等待所有线程完成
    SuccessCount := 0;
    for i := 0 to ThreadCount - 1 do
    begin
      Waiters[i].WaitFor;
      if Waiters[i].Success and (not Waiters[i].TimedOut) then
        Inc(SuccessCount);
    end;

    Worker.WaitFor;

    ElapsedMs := GetCurrentTimeMs - StartTime;
    WriteLn(Format('High concurrency waiters: %d waiters in %d ms', [ThreadCount, ElapsedMs]));

    AssertEquals('All waiters should succeed', ThreadCount, SuccessCount);
  finally
    Worker.Free;
    for i := 0 to ThreadCount - 1 do
      Waiters[i].Free;
  end;
end;

initialization
  RegisterTest(TTestCase_WaitGroup_Basic);
  RegisterTest(TTestCase_WaitGroup_Boundary);
  RegisterTest(TTestCase_WaitGroup_Concurrent);
  RegisterTest(TTestCase_WaitGroup_Stress);

end.
