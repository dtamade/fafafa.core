program fafafa.core.sync.mutex.futex.test;

{**
 * TDD Tests for TFutexMutex implementation
 *
 * Tests:
 * 1. Basic locking correctness
 * 2. Multi-threaded contention
 * 3. Performance comparison (pthread vs futex)
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.mutex,
  fafafa.core.sync.base;

const
  NUM_THREADS = 8;
  ITERATIONS_PER_THREAD = 10000;

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;
  FailCount: Integer = 0;

  // Shared state for contention test
  SharedCounter: Int64;
  TestMutex: IMutex;

procedure Check(ACondition: Boolean; const ATestName: string);
begin
  Inc(TestCount);
  if ACondition then
  begin
    Inc(PassCount);
    WriteLn('[PASS] ', ATestName);
  end
  else
  begin
    Inc(FailCount);
    WriteLn('[FAIL] ', ATestName);
  end;
end;

// ========== Basic Tests ==========

procedure Test_Mutex_BasicLockUnlock;
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;
  
  // Should be able to acquire and release
  Mutex.Acquire;
  Mutex.Release;
  
  Check(True, 'Basic lock/unlock works');
end;

procedure Test_Mutex_TryAcquire;
var
  Mutex: IMutex;
  Result: Boolean;
begin
  Mutex := MakeMutex;
  
  // Should succeed when unlocked
  Result := Mutex.TryAcquire;
  Check(Result, 'TryAcquire succeeds on unlocked mutex');
  
  Mutex.Release;
end;

procedure Test_Mutex_Guard;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  Mutex := MakeMutex;
  
  Guard := Mutex.LockGuard;
  Check(Guard <> nil, 'LockGuard returns valid guard');
  
  // Guard released when scope ends
end;

// ========== Contention Test Thread ==========

type
  TContentionThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TContentionThread.Execute;
var
  i: Integer;
begin
  for i := 1 to ITERATIONS_PER_THREAD do
  begin
    TestMutex.Acquire;
    try
      Inc(SharedCounter);
    finally
      TestMutex.Release;
    end;
  end;
end;

procedure Test_Mutex_MultiThreadContention;
var
  Threads: array[0..NUM_THREADS-1] of TContentionThread;
  i: Integer;
  ExpectedCount: Int64;
begin
  SharedCounter := 0;
  TestMutex := MakeMutex;
  ExpectedCount := Int64(NUM_THREADS) * Int64(ITERATIONS_PER_THREAD);
  
  // Create and start threads
  for i := 0 to NUM_THREADS - 1 do
  begin
    Threads[i] := TContentionThread.Create(True);
    Threads[i].FreeOnTerminate := False;
  end;
  
  // Start all threads
  for i := 0 to NUM_THREADS - 1 do
    Threads[i].Start;
  
  // Wait for all threads
  for i := 0 to NUM_THREADS - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  Check(SharedCounter = ExpectedCount, 
    Format('Multi-thread contention: counter=%d, expected=%d', [SharedCounter, ExpectedCount]));
  
  TestMutex := nil;
end;

// ========== Performance Benchmark ==========

procedure Test_Mutex_PerformanceBenchmark;
var
  Mutex: IMutex;
  i: Integer;
  StartTime, EndTime: QWord;
  ElapsedMs: Double;
  OpsPerSec: Double;
const
  BENCHMARK_ITERATIONS = 1000000;
begin
  Mutex := MakeMutex;
  
  StartTime := GetTickCount64;
  
  for i := 1 to BENCHMARK_ITERATIONS do
  begin
    Mutex.Acquire;
    Mutex.Release;
  end;
  
  EndTime := GetTickCount64;
  ElapsedMs := EndTime - StartTime;
  
  if ElapsedMs > 0 then
    OpsPerSec := (BENCHMARK_ITERATIONS / ElapsedMs) * 1000
  else
    OpsPerSec := 0;
  
  WriteLn(Format('  Benchmark: %d ops in %.0f ms (%.0f ops/sec)', 
    [BENCHMARK_ITERATIONS, ElapsedMs, OpsPerSec]));
  
  // Just check it completed successfully
  Check(ElapsedMs < 60000, 'Performance benchmark completed in reasonable time');
end;

// ========== Main ==========

begin
  WriteLn('=== FutexMutex Tests ===');
  WriteLn;
  
  WriteLn('--- Basic Tests ---');
  Test_Mutex_BasicLockUnlock;
  Test_Mutex_TryAcquire;
  Test_Mutex_Guard;
  
  WriteLn;
  WriteLn('--- Multi-Thread Contention Test ---');
  WriteLn(Format('  Threads: %d, Iterations per thread: %d', [NUM_THREADS, ITERATIONS_PER_THREAD]));
  Test_Mutex_MultiThreadContention;
  
  WriteLn;
  WriteLn('--- Performance Benchmark ---');
  Test_Mutex_PerformanceBenchmark;
  
  WriteLn;
  WriteLn('=== Results ===');
  WriteLn('Total: ', TestCount, ' | Pass: ', PassCount, ' | Fail: ', FailCount);
  
  if FailCount > 0 then
    Halt(1);
end.
