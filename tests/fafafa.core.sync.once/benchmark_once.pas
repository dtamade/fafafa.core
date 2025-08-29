program benchmark_once;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, DateUtils,
  fafafa.core.sync.once;

const
  ITERATIONS = 10000000; // 1000万次迭代
  THREAD_COUNT = 4;      // 4个线程

var
  GlobalOnce: IOnce;
  GlobalCounter: Integer = 0;
  StartTime, EndTime: TDateTime;

procedure BenchmarkCallback;
begin
  Inc(GlobalCounter);
end;

// 单线程基准测试
procedure BenchmarkSingleThread;
var
  i: Integer;
  Once: IOnce;
begin
  WriteLn('=== Single Thread Benchmark ===');

  // Test fast path performance (calls on completed state)
  Once := MakeOnce;
  Once.Execute(@BenchmarkCallback); // Execute once first

  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    Once.Execute(@BenchmarkCallback); // These calls will use fast path
  end;
  EndTime := Now;

  WriteLn(Format('Fast path: %d calls took %.3f seconds',
    [ITERATIONS, MilliSecondsBetween(EndTime, StartTime) / 1000.0]));
  WriteLn(Format('Average per call: %.2f nanoseconds',
    [MilliSecondsBetween(EndTime, StartTime) * 1000000.0 / ITERATIONS]));
  WriteLn(Format('Throughput: %.2f M ops/sec',
    [ITERATIONS / (MilliSecondsBetween(EndTime, StartTime) / 1000.0) / 1000000.0]));
end;

// Multi-thread benchmark test
type
  TBenchmarkThread = class(TThread)
  private
    FIterations: Integer;
    FOnce: IOnce;
  public
    constructor Create(AOnce: IOnce; AIterations: Integer);
    procedure Execute; override;
  end;

constructor TBenchmarkThread.Create(AOnce: IOnce; AIterations: Integer);
begin
  inherited Create(False);
  FOnce := AOnce;
  FIterations := AIterations;
end;

procedure TBenchmarkThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FOnce.Execute(@BenchmarkCallback);
  end;
end;

procedure BenchmarkMultiThread;
var
  Threads: array[0..THREAD_COUNT-1] of TBenchmarkThread;
  i: Integer;
  Once: IOnce;
  IterationsPerThread: Integer;
begin
  WriteLn('=== Multi Thread Benchmark ===');

  // Reset global counter
  GlobalCounter := 0;
  Once := MakeOnce;
  IterationsPerThread := ITERATIONS div THREAD_COUNT;
  
  StartTime := Now;
  
  // Create and start threads
  for i := 0 to THREAD_COUNT-1 do
  begin
    Threads[i] := TBenchmarkThread.Create(Once, IterationsPerThread);
  end;

  // Wait for all threads to complete
  for i := 0 to THREAD_COUNT-1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  EndTime := Now;

  WriteLn(Format('%d threads concurrent: %d calls took %.3f seconds',
    [THREAD_COUNT, ITERATIONS, MilliSecondsBetween(EndTime, StartTime) / 1000.0]));
  WriteLn(Format('Average per call: %.2f nanoseconds',
    [MilliSecondsBetween(EndTime, StartTime) * 1000000.0 / ITERATIONS]));
  WriteLn(Format('Throughput: %.2f M ops/sec',
    [ITERATIONS / (MilliSecondsBetween(EndTime, StartTime) / 1000.0) / 1000000.0]));
  WriteLn(Format('Callback execution count: %d (should be 1)', [GlobalCounter]));
end;

// Memory usage test
procedure BenchmarkMemoryUsage;
var
  OnceArray: array[0..9999] of IOnce;
  i: Integer;
  MemBefore, MemAfter: PtrUInt;
begin
  WriteLn('=== Memory Usage Test ===');

  MemBefore := GetHeapStatus.TotalAllocated;

  // Create 10000 Once instances
  for i := 0 to High(OnceArray) do
  begin
    OnceArray[i] := MakeOnce;
  end;
  
  MemAfter := GetHeapStatus.TotalAllocated;
  
  WriteLn(Format('10000 Once instances memory usage: %d bytes', [MemAfter - MemBefore]));
  WriteLn(Format('Average per instance: %d bytes', [(MemAfter - MemBefore) div 10000]));

  // Cleanup
  for i := 0 to High(OnceArray) do
  begin
    OnceArray[i] := nil;
  end;
end;

begin
  WriteLn('fafafa.core.sync.once Performance Benchmark');
  WriteLn('==========================================');
  WriteLn;

  BenchmarkSingleThread;
  WriteLn;

  BenchmarkMultiThread;
  WriteLn;

  BenchmarkMemoryUsage;
  WriteLn;

  WriteLn('Benchmark completed!');
  WriteLn('Note: These numbers are for reference only, actual performance depends on hardware and system load.');
end.
