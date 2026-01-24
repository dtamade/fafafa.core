program fafafa.core.sync.parker.benchmark;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.parker,
  fafafa.core.benchmark.utils;

type
  TParkerThread = class(TThread)
  private
    FParker: IParker;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(AParker: IParker; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

  TUnparkerThread = class(TThread)
  private
    FParker: IParker;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(AParker: IParker; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

constructor TParkerThread.Create(AParker: IParker; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(True);
  FParker := AParker;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
  FreeOnTerminate := False;
end;

procedure TParkerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
begin
  LLocalOps := 0;
  
  repeat
    FParker.Park;
    Inc(LLocalOps);
    LCurrentTime := GetHighResTime;
  until CalcElapsedNs(FStartTime, LCurrentTime) >= FDurationNs;
  
  InterlockedExchangeAdd64(FOperations^, LLocalOps);
end;

constructor TUnparkerThread.Create(AParker: IParker; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(True);
  FParker := AParker;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
  FreeOnTerminate := False;
end;

procedure TUnparkerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
begin
  LLocalOps := 0;
  
  repeat
    FParker.Unpark;
    Inc(LLocalOps);
    LCurrentTime := GetHighResTime;
  until CalcElapsedNs(FStartTime, LCurrentTime) >= FDurationNs;
  
  InterlockedExchangeAdd64(FOperations^, LLocalOps);
end;

function RunBenchmark(const ATestName: string; AParkerCount, AUnparkerCount, ADurationMs: Integer): TBenchmarkResult;
var
  LParker: IParker;
  LParkerThreads: array of TParkerThread;
  LUnparkerThreads: array of TUnparkerThread;
  LOperations: Int64;
  LStartTime, LEndTime: THighResTime;
  i: Integer;
begin
  LParker := MakeParker;
  LOperations := 0;
  
  SetLength(LParkerThreads, AParkerCount);
  SetLength(LUnparkerThreads, AUnparkerCount);
  
  LStartTime := GetHighResTime;
  
  for i := 0 to AParkerCount - 1 do
  begin
    LParkerThreads[i] := TParkerThread.Create(LParker, @LOperations, Int64(ADurationMs) * 1000000, LStartTime);
    LParkerThreads[i].Start;
  end;
  
  for i := 0 to AUnparkerCount - 1 do
  begin
    LUnparkerThreads[i] := TUnparkerThread.Create(LParker, @LOperations, Int64(ADurationMs) * 1000000, LStartTime);
    LUnparkerThreads[i].Start;
  end;
  
  for i := 0 to AParkerCount - 1 do
  begin
    LParkerThreads[i].WaitFor;
    LParkerThreads[i].Free;
  end;
  
  for i := 0 to AUnparkerCount - 1 do
  begin
    LUnparkerThreads[i].WaitFor;
    LUnparkerThreads[i].Free;
  end;
  
  LEndTime := GetHighResTime;
  
  Result.TestName := ATestName;
  Result.ThreadCount := AParkerCount + AUnparkerCount;
  Result.Operations := LOperations;
  Result.ElapsedNs := CalcElapsedNs(LStartTime, LEndTime);
  Result.OpsPerSecond := (LOperations * 1000000000.0) / Result.ElapsedNs;
  Result.AvgLatencyNs := Result.ElapsedNs / LOperations;
end;

procedure PrintResult(const AResult: TBenchmarkResult);
begin
  WriteLn(Format('%-40s %2d threads: %12d ops | %12.0f ops/sec | %8.2f ns/op',
    [AResult.TestName, AResult.ThreadCount, AResult.Operations,
     AResult.OpsPerSecond, AResult.AvgLatencyNs]));
end;

procedure RunAllBenchmarks;
const
  DURATION_MS = 1000;
var
  LResult: TBenchmarkResult;
  LResults: TBenchmarkResults;
begin
  PrintHeader('Parker Performance Benchmark');
  SetLength(LResults, 0);
  
  WriteLn('--- Parker Park/Unpark (1P1U) ---');
  LResult := RunBenchmark('Parker/1P1U', 1, 1, DURATION_MS);
  PrintResult(LResult);
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := LResult;
  
  WriteLn('--- Parker Park/Unpark (2P2U) ---');
  LResult := RunBenchmark('Parker/2P2U', 2, 2, DURATION_MS);
  PrintResult(LResult);
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := LResult;
  
  WriteLn('--- Parker Park/Unpark (4P4U) ---');
  LResult := RunBenchmark('Parker/4P4U', 4, 4, DURATION_MS);
  PrintResult(LResult);
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := LResult;
  WriteLn;
  
  PrintFooter;
  
  SaveResultsToCSV(LResults, 'parker_benchmark_results.csv');
  SaveResultsToJSON(LResults, 'parker_benchmark_results.json');
  WriteLn;
  WriteLn('Results saved to:');
  WriteLn('  - parker_benchmark_results.csv');
  WriteLn('  - parker_benchmark_results.json');
end;

begin
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}
  
  RunAllBenchmarks;
end.
