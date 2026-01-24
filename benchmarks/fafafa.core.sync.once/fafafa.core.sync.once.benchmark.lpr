program fafafa.core.sync.once.benchmark;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.once,
  fafafa.core.benchmark.utils;

type
  TWorkerThread = class(TThread)
  private
    FOnce: IOnce;
    FOperations: PInt64;
    FSuccessCount: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(AOnce: IOnce; AOperations, ASuccessCount: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

constructor TWorkerThread.Create(AOnce: IOnce; AOperations, ASuccessCount: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(True);
  FOnce := AOnce;
  FOperations := AOperations;
  FSuccessCount := ASuccessCount;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
  FreeOnTerminate := False;
end;

procedure TWorkerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
begin
  LLocalOps := 0;
  
  repeat
    if FOnce.Call then
      InterlockedIncrement64(FSuccessCount^);
    Inc(LLocalOps);
    LCurrentTime := GetHighResTime;
  until CalcElapsedNs(FStartTime, LCurrentTime) >= FDurationNs;
  
  InterlockedExchangeAdd64(FOperations^, LLocalOps);
end;

function RunBenchmark(const ATestName: string; AThreadCount, ADurationMs: Integer): TBenchmarkResult;
var
  LOnce: IOnce;
  LThreads: array of TWorkerThread;
  LOperations, LSuccessCount: Int64;
  LStartTime, LEndTime: THighResTime;
  i: Integer;
begin
  LOnce := MakeOnce;
  LOperations := 0;
  LSuccessCount := 0;
  
  SetLength(LThreads, AThreadCount);
  
  LStartTime := GetHighResTime;
  
  for i := 0 to AThreadCount - 1 do
  begin
    LThreads[i] := TWorkerThread.Create(LOnce, @LOperations, @LSuccessCount, Int64(ADurationMs) * 1000000, LStartTime);
    LThreads[i].Start;
  end;
  
  for i := 0 to AThreadCount - 1 do
  begin
    LThreads[i].WaitFor;
    LThreads[i].Free;
  end;
  
  LEndTime := GetHighResTime;
  
  Result.TestName := ATestName + Format(' (success=%d)', [LSuccessCount]);
  Result.ThreadCount := AThreadCount;
  Result.Operations := LOperations;
  Result.ElapsedNs := CalcElapsedNs(LStartTime, LEndTime);
  Result.OpsPerSecond := (LOperations * 1000000000.0) / Result.ElapsedNs;
  Result.AvgLatencyNs := Result.ElapsedNs / LOperations;
end;

procedure PrintResult(const AResult: TBenchmarkResult);
begin
  WriteLn(Format('%-50s %2d threads: %12d ops | %12.0f ops/sec | %8.2f ns/op',
    [AResult.TestName, AResult.ThreadCount, AResult.Operations,
     AResult.OpsPerSecond, AResult.AvgLatencyNs]));
end;

procedure RunAllBenchmarks;
const
  DURATION_MS = 1000;
  THREAD_COUNTS: array[0..4] of Integer = (1, 2, 4, 8, 16);
var
  i: Integer;
  LResult: TBenchmarkResult;
  LResults: TBenchmarkResults;
begin
  PrintHeader('Once Performance Benchmark');
  SetLength(LResults, 0);
  
  WriteLn('--- Once Initialization (Multiple Threads Competing) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Once/Call', THREAD_COUNTS[i], DURATION_MS);
    PrintResult(LResult);
    SetLength(LResults, Length(LResults) + 1);
    LResults[High(LResults)] := LResult;
  end;
  WriteLn;
  
  PrintFooter;
  
  SaveResultsToCSV(LResults, 'once_benchmark_results.csv');
  SaveResultsToJSON(LResults, 'once_benchmark_results.json');
  WriteLn;
  WriteLn('Results saved to:');
  WriteLn('  - once_benchmark_results.csv');
  WriteLn('  - once_benchmark_results.json');
end;

begin
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}
  
  RunAllBenchmarks;
end.
