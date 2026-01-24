program SemaphoreBenchmark;
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
  fafafa.core.sync.sem,
  fafafa.core.benchmark.utils;

type
  TWorkerThread = class(TThread)
  private
    FSem: ISem;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(ASem: ISem; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

{ TWorkerThread }

constructor TWorkerThread.Create(ASem: ISem; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FSem := ASem;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TWorkerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
  LGuard: ISemGuard;
begin
  LLocalOps := 0;
  
  repeat
    LGuard := FSem.AcquireGuard;
    LGuard := nil;  // Release semaphore
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

function RunBenchmark(const ATestName: string; AThreadCount: Integer; ADurationMs: Integer; AMaxCount: Integer): TBenchmarkResult;
var
  LSem: ISem;
  LThreads: array of TThread;
  LOperations: Int64;
  LStartTime, LEndTime: THighResTime;
  LDurationNs: Int64;
  i: Integer;
begin
  Result.TestName := ATestName;
  Result.ThreadCount := AThreadCount;
  LOperations := 0;
  
  LSem := MakeSem(AMaxCount, AMaxCount);  // Initial count = Max count (all permits available)
  LDurationNs := Int64(ADurationMs) * 1000000;
  
  SetLength(LThreads, AThreadCount);
  
  LStartTime := GetHighResTime;
  
  // Create worker threads
  for i := 0 to AThreadCount - 1 do
    LThreads[i] := TWorkerThread.Create(LSem, @LOperations, LDurationNs, LStartTime);
  
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
  PrintHeader('Semaphore Performance Benchmark');
  SetLength(LResults, 0);
  
  // Binary semaphore (max count = 1, like mutex)
  WriteLn('--- Binary Semaphore (Max Count = 1) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Semaphore/Binary', THREAD_COUNTS[i], DURATION_MS, 1);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  // Counting semaphore (max count = 4)
  WriteLn('--- Counting Semaphore (Max Count = 4) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Semaphore/Count4', THREAD_COUNTS[i], DURATION_MS, 4);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  // Counting semaphore (max count = 8)
  WriteLn('--- Counting Semaphore (Max Count = 8) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Semaphore/Count8', THREAD_COUNTS[i], DURATION_MS, 8);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  // High concurrency (max count = 16)
  WriteLn('--- High Concurrency (Max Count = 16) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Semaphore/Count16', THREAD_COUNTS[i], DURATION_MS, 16);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  PrintFooter;
  
  // Save results to CSV and JSON
  SaveResultsToCSV(LResults, 'semaphore_benchmark_results.csv');
  SaveResultsToJSON(LResults, 'semaphore_benchmark_results.json');
  WriteLn;
  WriteLn('Results saved to:');
  WriteLn('  - semaphore_benchmark_results.csv');
  WriteLn('  - semaphore_benchmark_results.json');
end;

begin
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}
  
  RunAllBenchmarks;
end.
