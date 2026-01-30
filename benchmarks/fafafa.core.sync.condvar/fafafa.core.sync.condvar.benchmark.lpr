program CondVarBenchmark;
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
  fafafa.core.sync.condvar,
  fafafa.core.sync.mutex;

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

  TProducerThread = class(TThread)
  private
    FCondVar: ICondVar;
    FMutex: IMutex;
    FCounter: PInteger;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(ACondVar: ICondVar; AMutex: IMutex; ACounter: PInteger; 
                      AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

  TConsumerThread = class(TThread)
  private
    FCondVar: ICondVar;
    FMutex: IMutex;
    FCounter: PInteger;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(ACondVar: ICondVar; AMutex: IMutex; ACounter: PInteger;
                      AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
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

{ TProducerThread }

constructor TProducerThread.Create(ACondVar: ICondVar; AMutex: IMutex; ACounter: PInteger;
                                  AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FCondVar := ACondVar;
  FMutex := AMutex;
  FCounter := ACounter;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TProducerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
  LGuard: ILockGuard;
begin
  LLocalOps := 0;
  
  repeat
    LGuard := FMutex.Lock;
    Inc(FCounter^);
    FCondVar.Signal;
    LGuard := nil;
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

{ TConsumerThread }

constructor TConsumerThread.Create(ACondVar: ICondVar; AMutex: IMutex; ACounter: PInteger;
                                  AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FCondVar := ACondVar;
  FMutex := AMutex;
  FCounter := ACounter;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TConsumerThread.Execute;
var
  LLocalOps: Int64;
  LCurrentTime: THighResTime;
begin
  LLocalOps := 0;
  
  repeat
    FMutex.Acquire;
    try
      // 修复：在等待前检查时间,避免永久阻塞
      LCurrentTime := GetHighResTime;
      if CalcElapsedNs(FStartTime, LCurrentTime) >= FDurationNs then
      begin
        FMutex.Release;
        Break;
      end;
      
      while FCounter^ = 0 do
      begin
        // 使用超时等待,避免永久阻塞
        if not FCondVar.Wait(FMutex, 10) then  // 10ms 超时
        begin
          // 超时后检查时间
          LCurrentTime := GetHighResTime;
          if CalcElapsedNs(FStartTime, LCurrentTime) >= FDurationNs then
          begin
            FMutex.Release;
            Exit;  // 直接退出
          end;
        end;
      end;
      Dec(FCounter^);
    finally
      FMutex.Release;
    end;
    Inc(LLocalOps);
  until Terminated;

  InterlockedExchangeAdd64(FOperations^, LLocalOps);
end;

function RunBenchmark(const ATestName: string; AProducerCount, AConsumerCount: Integer; ADurationMs: Integer): TBenchmarkResult;
var
  LCondVar: ICondVar;
  LMutex: IMutex;
  LThreads: array of TThread;
  LOperations: Int64;
  LCounter: Integer;
  LStartTime, LEndTime: THighResTime;
  LDurationNs: Int64;
  i: Integer;
begin
  Result.TestName := ATestName;
  Result.ThreadCount := AProducerCount + AConsumerCount;
  LOperations := 0;
  LCounter := 0;
  
  LCondVar := MakeCondVar;
  {$IFDEF UNIX}
  LMutex := MakePthreadMutex;  // 修复：使用与 pthread_cond_* 兼容的 mutex
  {$ELSE}
  LMutex := MakeMutex;
  {$ENDIF}
  LDurationNs := Int64(ADurationMs) * 1000000;
  
  SetLength(LThreads, AProducerCount + AConsumerCount);
  
  LStartTime := GetHighResTime;
  
  // Create producer threads
  for i := 0 to AProducerCount - 1 do
    LThreads[i] := TProducerThread.Create(LCondVar, LMutex, @LCounter, @LOperations, LDurationNs, LStartTime);
  
  // Create consumer threads
  for i := AProducerCount to AProducerCount + AConsumerCount - 1 do
    LThreads[i] := TConsumerThread.Create(LCondVar, LMutex, @LCounter, @LOperations, LDurationNs, LStartTime);
  
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
  WriteLn('CondVar Performance Benchmark (Producer-Consumer Pattern)');
  WriteLn(StringOfChar('=', 120));
  WriteLn;
end;

procedure RunAllBenchmarks;
const
  DURATION_MS = 1000;  // 1 second per test
var
  LResult: TBenchmarkResult;
begin
  PrintHeader;
  
  // 1 Producer, 1 Consumer
  WriteLn('--- 1 Producer, 1 Consumer ---');
  LResult := RunBenchmark('CondVar/1P1C', 1, 1, DURATION_MS);
  PrintResult(LResult);
  WriteLn;
  
  // 2 Producers, 2 Consumers
  WriteLn('--- 2 Producers, 2 Consumers ---');
  LResult := RunBenchmark('CondVar/2P2C', 2, 2, DURATION_MS);
  PrintResult(LResult);
  WriteLn;
  
  // 4 Producers, 4 Consumers
  WriteLn('--- 4 Producers, 4 Consumers ---');
  LResult := RunBenchmark('CondVar/4P4C', 4, 4, DURATION_MS);
  PrintResult(LResult);
  WriteLn;
  
  // 1 Producer, 4 Consumers (fan-out)
  WriteLn('--- 1 Producer, 4 Consumers (Fan-Out) ---');
  LResult := RunBenchmark('CondVar/1P4C', 1, 4, DURATION_MS);
  PrintResult(LResult);
  WriteLn;
  
  // 4 Producers, 1 Consumer (fan-in)
  WriteLn('--- 4 Producers, 1 Consumer (Fan-In) ---');
  LResult := RunBenchmark('CondVar/4P1C', 4, 1, DURATION_MS);
  PrintResult(LResult);
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
