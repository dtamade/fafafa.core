program RWLockBenchmark;
{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.sync.base,
  fafafa.core.sync.rwlock,
  fafafa.core.benchmark.utils;

type
  TReadWorkerThread = class(TThread)
  private
    FRWLock: IRWLock;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

  TWriteWorkerThread = class(TThread)
  private
    FRWLock: IRWLock;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

{ TReadWorkerThread }

constructor TReadWorkerThread.Create(ARWLock: IRWLock; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FRWLock := ARWLock;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TReadWorkerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
  LGuard: IRWLockReadGuard;
begin
  LLocalOps := 0;
  
  repeat
    LGuard := FRWLock.Read;
    LGuard := nil;  // Release read lock
    Inc(LLocalOps);

    // Check time every 1024 operations
    if (LLocalOps and $3FF) = 0 then
    begin
      LCurrentTime := GetHighResTime;
      if CalcElapsedNs(FStartTime, LCurrentTime) >= FDurationNs then
        Break;
    end;
  until Terminated;

  InterlockedExchangeAdd64(FOperations^, LLocalOps);
end;

{ TWriteWorkerThread }

constructor TWriteWorkerThread.Create(ARWLock: IRWLock; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FRWLock := ARWLock;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TWriteWorkerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
  LGuard: IRWLockWriteGuard;
begin
  LLocalOps := 0;
  
  repeat
    LGuard := FRWLock.Write;
    LGuard := nil;  // Release write lock
    Inc(LLocalOps);

    // Check time every 1024 operations
    if (LLocalOps and $3FF) = 0 then
    begin
      LCurrentTime := GetHighResTime;
      if CalcElapsedNs(FStartTime, LCurrentTime) >= FDurationNs then
        Break;
    end;
  until Terminated;

  InterlockedExchangeAdd64(FOperations^, LLocalOps);
end;

function RunBenchmark(const ATestName: string; AThreadCount: Integer; ADurationMs: Integer; AReadRatio: Double): TBenchmarkResult;
var
  LRWLock: IRWLock;
  LThreads: array of TThread;
  LOperations: Int64;
  LStartTime, LEndTime: THighResTime;
  LDurationNs: Int64;
  i: Integer;
  LReadThreads: Integer;
begin
  Result.TestName := ATestName;
  Result.ThreadCount := AThreadCount;
  LOperations := 0;
  
  LRWLock := MakeRWLock;
  LDurationNs := Int64(ADurationMs) * 1000000;
  
  SetLength(LThreads, AThreadCount);
  LReadThreads := Round(AThreadCount * AReadRatio);
  
  LStartTime := GetHighResTime;
  
  // Create read threads
  for i := 0 to LReadThreads - 1 do
    LThreads[i] := TReadWorkerThread.Create(LRWLock, @LOperations, LDurationNs, LStartTime);
  
  // Create write threads
  for i := LReadThreads to AThreadCount - 1 do
    LThreads[i] := TWriteWorkerThread.Create(LRWLock, @LOperations, LDurationNs, LStartTime);
  
  // Wait for all threads
  for i := 0 to High(LThreads) do
    LThreads[i].WaitFor;
  
  LEndTime := GetHighResTime;
  
  // Clean up
  for i := 0 to High(LThreads) do
    LThreads[i].Free;
  
  Result.Operations := LOperations;
  Result.ElapsedNs := CalcElapsedNs(LStartTime, LEndTime);
  Result.OpsPerSecond := (LOperations * 1000000000.0) / Result.ElapsedNs;
  Result.AvgLatencyNs := Result.ElapsedNs / LOperations;
end;

procedure PrintResult(const AResult: TBenchmarkResult);
begin
  WriteLn(Format('%-40s %2d threads: %12d ops in %8.3f ms | %12.0f ops/sec | %8.2f ns/op',
    [AResult.TestName, AResult.ThreadCount, AResult.Operations,
     AResult.ElapsedNs / 1000000.0, AResult.OpsPerSecond, AResult.AvgLatencyNs]));
end;

procedure RunAllBenchmarks;
const
  DURATION_MS = 1000;  // 1 second per test
  THREAD_COUNTS: array[0..3] of Integer = (1, 2, 4, 8);
var
  i: Integer;
  LResult: TBenchmarkResult;
  LResults: TBenchmarkResults;
begin
  PrintHeader('RWLock Performance Benchmark');
  SetLength(LResults, 0);
  
  // 100% Read (no contention)
  WriteLn('--- 100% Read (No Write Contention) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('RWLock/Read100%', THREAD_COUNTS[i], DURATION_MS, 1.0);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  // 90% Read, 10% Write
  WriteLn('--- 90% Read, 10% Write ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('RWLock/Read90%Write10%', THREAD_COUNTS[i], DURATION_MS, 0.9);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  // 50% Read, 50% Write
  WriteLn('--- 50% Read, 50% Write ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('RWLock/Read50%Write50%', THREAD_COUNTS[i], DURATION_MS, 0.5);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  // 100% Write (maximum contention)
  WriteLn('--- 100% Write (Maximum Contention) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('RWLock/Write100%', THREAD_COUNTS[i], DURATION_MS, 0.0);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  PrintFooter;
  
  // Save results to CSV and JSON
  SaveResultsToCSV(LResults, 'rwlock_benchmark_results.csv');
  SaveResultsToJSON(LResults, 'rwlock_benchmark_results.json');
  WriteLn;
  WriteLn('Results saved to:');
  WriteLn('  - rwlock_benchmark_results.csv');
  WriteLn('  - rwlock_benchmark_results.json');
end;

begin
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}
  
  RunAllBenchmarks;
end.
