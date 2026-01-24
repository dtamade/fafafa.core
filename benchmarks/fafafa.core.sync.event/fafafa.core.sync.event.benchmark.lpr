program EventBenchmark;
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
  fafafa.core.sync.event,
  fafafa.core.benchmark.utils;

type
  TWaiterThread = class(TThread)
  private
    FEvent: IEvent;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

  TSignalerThread = class(TThread)
  private
    FEvent: IEvent;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

{ TWaiterThread }

constructor TWaiterThread.Create(AEvent: IEvent; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FEvent := AEvent;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TWaiterThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
begin
  LLocalOps := 0;
  
  repeat
    FEvent.WaitFor(10);  // Wait with timeout
    Inc(LLocalOps);

    // Check time every 256 operations
    if (LLocalOps and $FF) = 0 then
    begin
      LCurrentTime := GetHighResTime;
      if CalcElapsedNs(FStartTime, LCurrentTime) >= FDurationNs then
        Break;
    end;
  until Terminated;

  InterlockedExchangeAdd64(FOperations^, LLocalOps);
end;

{ TSignalerThread }

constructor TSignalerThread.Create(AEvent: IEvent; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FEvent := AEvent;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TSignalerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
begin
  LLocalOps := 0;
  
  repeat
    FEvent.SetEvent;
    if not FEvent.IsManualReset then
      FEvent.ResetEvent;
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

function RunBenchmark(const ATestName: string; AThreadCount: Integer; ADurationMs: Integer; AManualReset: Boolean): TBenchmarkResult;
var
  LEvent: IEvent;
  LThreads: array of TThread;
  LOperations: Int64;
  LStartTime, LEndTime: THighResTime;
  LDurationNs: Int64;
  i: Integer;
  LWaiterCount: Integer;
begin
  Result.TestName := ATestName;
  Result.ThreadCount := AThreadCount;
  LOperations := 0;
  
  LEvent := MakeEvent(AManualReset, False);
  LDurationNs := Int64(ADurationMs) * 1000000;
  
  SetLength(LThreads, AThreadCount);
  LWaiterCount := AThreadCount div 2;
  
  LStartTime := GetHighResTime;
  
  // Create waiter threads
  for i := 0 to LWaiterCount - 1 do
    LThreads[i] := TWaiterThread.Create(LEvent, @LOperations, LDurationNs, LStartTime);
  
  // Create signaler threads
  for i := LWaiterCount to AThreadCount - 1 do
    LThreads[i] := TSignalerThread.Create(LEvent, @LOperations, LDurationNs, LStartTime);
  
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
  THREAD_COUNTS: array[0..3] of Integer = (2, 4, 8, 16);
var
  i: Integer;
  LResult: TBenchmarkResult;
  LResults: TBenchmarkResults;
begin
  PrintHeader('Event Performance Benchmark');
  SetLength(LResults, 0);
  
  // Auto-reset event (one waiter wakes up per signal)
  WriteLn('--- Auto-Reset Event (One Waiter Per Signal) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Event/AutoReset', THREAD_COUNTS[i], DURATION_MS, False);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  // Manual-reset event (all waiters wake up per signal)
  WriteLn('--- Manual-Reset Event (All Waiters Per Signal) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Event/ManualReset', THREAD_COUNTS[i], DURATION_MS, True);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  PrintFooter;
  
  // Save results to CSV and JSON
  SaveResultsToCSV(LResults, 'event_benchmark_results.csv');
  SaveResultsToJSON(LResults, 'event_benchmark_results.json');
  WriteLn;
  WriteLn('Results saved to:');
  WriteLn('  - event_benchmark_results.csv');
  WriteLn('  - event_benchmark_results.json');
end;

begin
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}
  
  try
    RunAllBenchmarks;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
