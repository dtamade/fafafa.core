program test_named_sync_stress;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedOnce,
  fafafa.core.sync.namedLatch,
  fafafa.core.sync.namedWaitGroup,
  fafafa.core.sync.namedSharedCounter,
  fafafa.core.sync.base;

const
  TEST_NAME_PREFIX = 'stress_test_';
  NUM_THREADS = 8;
  ITERATIONS_PER_THREAD = 10000;

var
  GTestsPassed: Integer = 0;
  GTestsFailed: Integer = 0;
  GBarrier: Integer = 0;  // 简单屏障

procedure Check(ACondition: Boolean; const ATestName: string);
begin
  if ACondition then
  begin
    WriteLn('[PASS] ', ATestName);
    Inc(GTestsPassed);
  end
  else
  begin
    WriteLn('[FAIL] ', ATestName);
    Inc(GTestsFailed);
  end;
end;

// ====== NamedSharedCounter 压力测试 ======
type
  TCounterThread = class(TThread)
  private
    FCounterName: string;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACounterName: string; AIterations: Integer);
  end;

constructor TCounterThread.Create(const ACounterName: string; AIterations: Integer);
begin
  inherited Create(True);
  FCounterName := ACounterName;
  FIterations := AIterations;
  FreeOnTerminate := False;
end;

procedure TCounterThread.Execute;
var
  Counter: INamedSharedCounter;
  I: Integer;
begin
  Counter := MakeNamedSharedCounter(FCounterName);
  // 等待所有线程准备好
  InterlockedIncrement(GBarrier);
  while GBarrier < NUM_THREADS do
    Sleep(1);

  for I := 1 to FIterations do
    Counter.Increment;
end;

procedure TestSharedCounter_Stress;
var
  Counter: INamedSharedCounter;
  CounterName: string;
  Threads: array[0..NUM_THREADS-1] of TCounterThread;
  I: Integer;
  ExpectedValue: Int64;
  StartTime: QWord;
begin
  WriteLn('');
  WriteLn('=== Testing NamedSharedCounter Stress ===');

  CounterName := TEST_NAME_PREFIX + 'counter_' + IntToStr(Random(100000));
  Counter := MakeNamedSharedCounter(CounterName);
  Counter.SetValue(0);
  GBarrier := 0;

  StartTime := GetTickCount64;

  // 创建并启动所有线程
  for I := 0 to NUM_THREADS - 1 do
    Threads[I] := TCounterThread.Create(CounterName, ITERATIONS_PER_THREAD);

  for I := 0 to NUM_THREADS - 1 do
    Threads[I].Start;

  // 等待所有线程完成
  for I := 0 to NUM_THREADS - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  ExpectedValue := Int64(NUM_THREADS) * Int64(ITERATIONS_PER_THREAD);
  Check(Counter.GetValue = ExpectedValue,
    Format('Counter should be %d (got %d)', [ExpectedValue, Counter.GetValue]));

  WriteLn(Format('  %d threads x %d iterations = %d ops in %d ms',
    [NUM_THREADS, ITERATIONS_PER_THREAD, NUM_THREADS * ITERATIONS_PER_THREAD,
     GetTickCount64 - StartTime]));
end;

// ====== NamedSharedCounter Add/Sub 压力测试 ======
type
  TCounterAddSubThread = class(TThread)
  private
    FCounterName: string;
    FIterations: Integer;
    FIsAdder: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACounterName: string; AIterations: Integer; AIsAdder: Boolean);
  end;

constructor TCounterAddSubThread.Create(const ACounterName: string;
  AIterations: Integer; AIsAdder: Boolean);
begin
  inherited Create(True);
  FCounterName := ACounterName;
  FIterations := AIterations;
  FIsAdder := AIsAdder;
  FreeOnTerminate := False;
end;

procedure TCounterAddSubThread.Execute;
var
  Counter: INamedSharedCounter;
  I: Integer;
begin
  Counter := MakeNamedSharedCounter(FCounterName);
  // 等待所有线程准备好
  InterlockedIncrement(GBarrier);
  while GBarrier < NUM_THREADS do
    Sleep(1);

  for I := 1 to FIterations do
  begin
    if FIsAdder then
      Counter.Add(1)
    else
      Counter.Sub(1);
  end;
end;

procedure TestSharedCounter_AddSub_Stress;
var
  Counter: INamedSharedCounter;
  CounterName: string;
  Threads: array[0..NUM_THREADS-1] of TCounterAddSubThread;
  I: Integer;
  StartTime: QWord;
begin
  WriteLn('');
  WriteLn('=== Testing NamedSharedCounter Add/Sub Stress ===');

  CounterName := TEST_NAME_PREFIX + 'addsub_' + IntToStr(Random(100000));
  Counter := MakeNamedSharedCounter(CounterName);
  Counter.SetValue(0);
  GBarrier := 0;

  StartTime := GetTickCount64;

  // 一半线程加，一半线程减
  for I := 0 to NUM_THREADS - 1 do
    Threads[I] := TCounterAddSubThread.Create(CounterName, ITERATIONS_PER_THREAD, I < NUM_THREADS div 2);

  for I := 0 to NUM_THREADS - 1 do
    Threads[I].Start;

  for I := 0 to NUM_THREADS - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  // 加减相等，最终应为 0
  Check(Counter.GetValue = 0,
    Format('Counter should be 0 after equal add/sub (got %d)', [Counter.GetValue]));

  WriteLn(Format('  Completed in %d ms', [GetTickCount64 - StartTime]));
end;

// ====== NamedWaitGroup 压力测试 ======
type
  TWaitGroupWorkerThread = class(TThread)
  private
    FWGName: string;
    FCounterName: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const AWGName, ACounterName: string);
  end;

constructor TWaitGroupWorkerThread.Create(const AWGName, ACounterName: string);
begin
  inherited Create(True);
  FWGName := AWGName;
  FCounterName := ACounterName;
  FreeOnTerminate := False;
end;

procedure TWaitGroupWorkerThread.Execute;
var
  WG: INamedWaitGroup;
  Counter: INamedSharedCounter;
begin
  WG := MakeNamedWaitGroup(FWGName);
  Counter := MakeNamedSharedCounter(FCounterName);

  // 模拟工作
  Sleep(Random(10));
  Counter.Increment;

  WG.Done;
end;

procedure TestWaitGroup_Stress;
var
  WG: INamedWaitGroup;
  Counter: INamedSharedCounter;
  WGName, CounterName: string;
  Threads: array[0..NUM_THREADS-1] of TWaitGroupWorkerThread;
  I: Integer;
  StartTime: QWord;
begin
  WriteLn('');
  WriteLn('=== Testing NamedWaitGroup Stress ===');

  WGName := TEST_NAME_PREFIX + 'wg_' + IntToStr(Random(100000));
  CounterName := TEST_NAME_PREFIX + 'wg_cnt_' + IntToStr(Random(100000));

  WG := MakeNamedWaitGroup(WGName);
  Counter := MakeNamedSharedCounter(CounterName);
  Counter.SetValue(0);

  // 添加任务计数
  WG.Add(NUM_THREADS);

  StartTime := GetTickCount64;

  // 创建工作线程
  for I := 0 to NUM_THREADS - 1 do
    Threads[I] := TWaitGroupWorkerThread.Create(WGName, CounterName);

  for I := 0 to NUM_THREADS - 1 do
    Threads[I].Start;

  // 等待所有任务完成
  Check(WG.Wait(5000), 'WaitGroup should complete within timeout');
  Check(WG.IsZero, 'WaitGroup count should be zero');
  Check(Counter.GetValue = NUM_THREADS,
    Format('Counter should be %d (got %d)', [NUM_THREADS, Counter.GetValue]));

  WriteLn(Format('  Completed in %d ms', [GetTickCount64 - StartTime]));

  for I := 0 to NUM_THREADS - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
end;

// ====== NamedLatch 压力测试 ======
type
  TLatchWaiterThread = class(TThread)
  private
    FLatchName: string;
    FCounterName: string;
  protected
    procedure Execute; override;
  public
    WaitResult: Boolean;
    constructor Create(const ALatchName, ACounterName: string);
  end;

constructor TLatchWaiterThread.Create(const ALatchName, ACounterName: string);
begin
  inherited Create(True);
  FLatchName := ALatchName;
  FCounterName := ACounterName;
  FreeOnTerminate := False;
  WaitResult := False;
end;

procedure TLatchWaiterThread.Execute;
var
  Latch: INamedLatch;
  Counter: INamedSharedCounter;
begin
  Latch := MakeNamedLatch(FLatchName, 0);
  Counter := MakeNamedSharedCounter(FCounterName);

  // 等待 latch 打开
  WaitResult := Latch.Wait(5000);
  if WaitResult then
    Counter.Increment;
end;

procedure TestLatch_Stress;
var
  Latch: INamedLatch;
  Counter: INamedSharedCounter;
  LatchName, CounterName: string;
  Threads: array[0..NUM_THREADS-1] of TLatchWaiterThread;
  I: Integer;
  AllWaited: Boolean;
  StartTime: QWord;
begin
  WriteLn('');
  WriteLn('=== Testing NamedLatch Stress ===');

  LatchName := TEST_NAME_PREFIX + 'latch_' + IntToStr(Random(100000));
  CounterName := TEST_NAME_PREFIX + 'latch_cnt_' + IntToStr(Random(100000));

  // 创建 latch，计数为 1
  Latch := MakeNamedLatch(LatchName, 1);
  Counter := MakeNamedSharedCounter(CounterName);
  Counter.SetValue(0);

  StartTime := GetTickCount64;

  // 创建等待线程
  for I := 0 to NUM_THREADS - 1 do
    Threads[I] := TLatchWaiterThread.Create(LatchName, CounterName);

  for I := 0 to NUM_THREADS - 1 do
    Threads[I].Start;

  // 让所有线程开始等待
  Sleep(50);

  // 打开 latch
  Latch.CountDown;

  // 等待所有线程完成
  AllWaited := True;
  for I := 0 to NUM_THREADS - 1 do
  begin
    Threads[I].WaitFor;
    if not Threads[I].WaitResult then
      AllWaited := False;
    Threads[I].Free;
  end;

  Check(AllWaited, 'All threads should have waited successfully');
  Check(Counter.GetValue = NUM_THREADS,
    Format('All %d threads should have incremented counter (got %d)',
      [NUM_THREADS, Counter.GetValue]));

  WriteLn(Format('  Completed in %d ms', [GetTickCount64 - StartTime]));
end;

// ====== NamedOnce 压力测试 ======
var
  GOnceCounter: INamedSharedCounter;

procedure OnceCallback;
begin
  GOnceCounter.Increment;
  Sleep(50); // 模拟耗时初始化
end;

type
  TOnceThread = class(TThread)
  private
    FOnceName: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOnceName: string);
  end;

constructor TOnceThread.Create(const AOnceName: string);
begin
  inherited Create(True);
  FOnceName := AOnceName;
  FreeOnTerminate := False;
end;

procedure TOnceThread.Execute;
var
  Once: INamedOnce;
begin
  Once := MakeNamedOnce(FOnceName);
  // 等待所有线程准备好
  InterlockedIncrement(GBarrier);
  while GBarrier < NUM_THREADS do
    Sleep(1);

  Once.Execute(@OnceCallback);
end;

procedure TestOnce_Stress;
var
  Once: INamedOnce;
  OnceName, CounterName: string;
  Threads: array[0..NUM_THREADS-1] of TOnceThread;
  I: Integer;
  StartTime: QWord;
begin
  WriteLn('');
  WriteLn('=== Testing NamedOnce Stress ===');

  OnceName := TEST_NAME_PREFIX + 'once_' + IntToStr(Random(100000));
  CounterName := TEST_NAME_PREFIX + 'once_cnt_' + IntToStr(Random(100000));

  GOnceCounter := MakeNamedSharedCounter(CounterName);
  GOnceCounter.SetValue(0);
  GBarrier := 0;

  Once := MakeNamedOnce(OnceName);

  StartTime := GetTickCount64;

  // 创建所有线程同时尝试 Execute
  for I := 0 to NUM_THREADS - 1 do
    Threads[I] := TOnceThread.Create(OnceName);

  for I := 0 to NUM_THREADS - 1 do
    Threads[I].Start;

  // 等待所有线程完成
  for I := 0 to NUM_THREADS - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  Check(GOnceCounter.GetValue = 1,
    Format('Once should execute exactly once (got %d)', [GOnceCounter.GetValue]));
  Check(Once.IsDone, 'Once should be done');

  WriteLn(Format('  Completed in %d ms', [GetTickCount64 - StartTime]));
end;

// ====== CompareExchange 压力测试 ======
type
  TCASThread = class(TThread)
  private
    FCounterName: string;
    FSuccessCount: Integer;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    property SuccessCount: Integer read FSuccessCount;
    constructor Create(const ACounterName: string; AIterations: Integer);
  end;

constructor TCASThread.Create(const ACounterName: string; AIterations: Integer);
begin
  inherited Create(True);
  FCounterName := ACounterName;
  FIterations := AIterations;
  FSuccessCount := 0;
  FreeOnTerminate := False;
end;

procedure TCASThread.Execute;
var
  Counter: INamedSharedCounter;
  I: Integer;
  OldVal, NewVal: Int64;
begin
  Counter := MakeNamedSharedCounter(FCounterName);

  // 等待所有线程准备好
  InterlockedIncrement(GBarrier);
  while GBarrier < NUM_THREADS do
    Sleep(1);

  for I := 1 to FIterations do
  begin
    repeat
      OldVal := Counter.GetValue;
      NewVal := OldVal + 1;
    until Counter.CompareExchange(OldVal, NewVal) = OldVal;
    Inc(FSuccessCount);
  end;
end;

procedure TestSharedCounter_CAS_Stress;
var
  Counter: INamedSharedCounter;
  CounterName: string;
  Threads: array[0..NUM_THREADS-1] of TCASThread;
  I: Integer;
  TotalSuccess: Integer;
  ExpectedValue: Int64;
  StartTime: QWord;
const
  CAS_ITERATIONS = 1000;  // 较少迭代因为 CAS 循环较慢
begin
  WriteLn('');
  WriteLn('=== Testing NamedSharedCounter CAS Stress ===');

  CounterName := TEST_NAME_PREFIX + 'cas_' + IntToStr(Random(100000));
  Counter := MakeNamedSharedCounter(CounterName);
  Counter.SetValue(0);
  GBarrier := 0;

  StartTime := GetTickCount64;

  for I := 0 to NUM_THREADS - 1 do
    Threads[I] := TCASThread.Create(CounterName, CAS_ITERATIONS);

  for I := 0 to NUM_THREADS - 1 do
    Threads[I].Start;

  TotalSuccess := 0;
  for I := 0 to NUM_THREADS - 1 do
  begin
    Threads[I].WaitFor;
    TotalSuccess := TotalSuccess + Threads[I].SuccessCount;
    Threads[I].Free;
  end;

  ExpectedValue := Int64(NUM_THREADS) * Int64(CAS_ITERATIONS);
  Check(Counter.GetValue = ExpectedValue,
    Format('Counter should be %d (got %d)', [ExpectedValue, Counter.GetValue]));
  Check(TotalSuccess = ExpectedValue,
    Format('Total successful CAS ops should be %d (got %d)', [ExpectedValue, TotalSuccess]));

  WriteLn(Format('  %d CAS operations in %d ms', [TotalSuccess, GetTickCount64 - StartTime]));
end;

begin
  Randomize;
  WriteLn('================================================');
  WriteLn('  Named Sync Primitives Stress Tests');
  WriteLn(Format('  %d threads, %d iterations per thread', [NUM_THREADS, ITERATIONS_PER_THREAD]));
  WriteLn('================================================');

  try
    TestSharedCounter_Stress;
    TestSharedCounter_AddSub_Stress;
    TestSharedCounter_CAS_Stress;
    TestWaitGroup_Stress;
    TestLatch_Stress;
    TestOnce_Stress;
  except
    on E: Exception do
    begin
      WriteLn('[ERROR] Unhandled exception: ', E.Message);
      Inc(GTestsFailed);
    end;
  end;

  WriteLn('');
  WriteLn('================================================');
  WriteLn('  Results: ', GTestsPassed, ' passed, ', GTestsFailed, ' failed');
  WriteLn('================================================');

  if GTestsFailed > 0 then
    ExitCode := 1
  else
    ExitCode := 0;
end.
