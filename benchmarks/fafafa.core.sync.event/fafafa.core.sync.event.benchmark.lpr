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
  fafafa.core.sync.event;

{$IFNDEF WINDOWS}
const
  CLOCK_MONOTONIC = 1;

type
  TTimeSpec = record
    tv_sec: Int64;
    tv_nsec: Int64;
  end;
  PTimeSpec = ^TTimeSpec;

function clock_gettime(clk_id: Integer; tp: PTimeSpec): Integer; cdecl; external 'c';
{$ENDIF}

type
  THighResTime = record
    {$IFDEF WINDOWS}
    Value: Int64;
    {$ELSE}
    Sec: Int64;
    NSec: Int64;
    {$ENDIF}
  end;

  TBenchmarkResult = record
    TestName: string;
    ThreadCount: Integer;
    Operations: Int64;
    ElapsedNs: Int64;
    OpsPerSecond: Double;
    AvgLatencyNs: Double;
  end;

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

{$IFDEF WINDOWS}
var
  Frequency: Int64;
{$ENDIF}

function GetHighResTime: THighResTime;
{$IFNDEF WINDOWS}
var
  ts: TTimeSpec;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  QueryPerformanceCounter(Result.Value);
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @ts);
  Result.Sec := ts.tv_sec;
  Result.NSec := ts.tv_nsec;
  {$ENDIF}
end;

function CalcElapsedNs(const AStart, AEnd: THighResTime): Int64;
begin
  {$IFDEF WINDOWS}
  Result := ((AEnd.Value - AStart.Value) * 1000000000) div Frequency;
  {$ELSE}
  Result := (AEnd.Sec - AStart.Sec) * 1000000000 + (AEnd.NSec - AStart.NSec);
  {$ENDIF}
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

procedure PrintHeader;
begin
  WriteLn(StringOfChar('=', 120));
  WriteLn('Event Performance Benchmark');
  WriteLn(StringOfChar('=', 120));
  WriteLn;
end;

procedure RunAllBenchmarks;
const
  DURATION_MS = 1000;  // 1 second per test
  THREAD_COUNTS: array[0..3] of Integer = (2, 4, 8, 16);
var
  i: Integer;
  LResult: TBenchmarkResult;
begin
  PrintHeader;
  
  // Auto-reset event (one waiter wakes up per signal)
  WriteLn('--- Auto-Reset Event (One Waiter Per Signal) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Event/AutoReset', THREAD_COUNTS[i], DURATION_MS, False);
    PrintResult(LResult);
  end;
  WriteLn;
  
  // Manual-reset event (all waiters wake up per signal)
  WriteLn('--- Manual-Reset Event (All Waiters Per Signal) ---');
  for i := 0 to High(THREAD_COUNTS) do
  begin
    LResult := RunBenchmark('Event/ManualReset', THREAD_COUNTS[i], DURATION_MS, True);
    PrintResult(LResult);
  end;
  WriteLn;
  
  WriteLn(StringOfChar('=', 120));
  WriteLn('Benchmark Complete');
  WriteLn(StringOfChar('=', 120));
end;

begin
  {$IFDEF WINDOWS}
  QueryPerformanceFrequency(Frequency);
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
