program fafafa.core.sync.benchmark;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.time,
  fafafa.core.sync.mutex,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base,
  fafafa.core.sync.namedMutex,
  fafafa.core.sync.namedEvent;

const
  ITERATIONS = 1000000;
  WARMUP_ITERATIONS = 10000;

type
  TBenchmarkResult = record
    Name: string;
    TotalTime: TDuration;
    OpsPerSec: Double;
    AvgNsPerOp: Double;
  end;

var
  Results: array of TBenchmarkResult;
  ResultCount: Integer;

procedure AddResult(const AName: string; ATotalTime: TDuration; AIterations: Integer);
var
  R: TBenchmarkResult;
begin
  R.Name := AName;
  R.TotalTime := ATotalTime;
  R.OpsPerSec := AIterations / (ATotalTime.AsNs / 1e9);
  R.AvgNsPerOp := ATotalTime.AsNs / AIterations;
  
  SetLength(Results, ResultCount + 1);
  Results[ResultCount] := R;
  Inc(ResultCount);
end;

procedure PrintResults;
var
  I: Integer;
begin
  WriteLn;
  WriteLn('=== Benchmark Results ===');
  WriteLn(Format('%-40s %12s %15s %12s', ['Name', 'Total(ms)', 'Ops/sec', 'ns/op']));
  WriteLn(StringOfChar('-', 82));
  
  for I := 0 to ResultCount - 1 do
  begin
  WriteLn(Format('%-40s %12.2f %15.0f %12.2f', [
      Results[I].Name,
      Results[I].TotalTime.AsMs * 1.0,
      Results[I].OpsPerSec,
      Results[I].AvgNsPerOp
    ]));
  end;
  WriteLn;
end;

// ============================================================================
// Mutex Benchmarks
// ============================================================================

procedure BenchMutex_SingleThread;
var
  M: IMutex;
  I: Integer;
  Start, EndT: TInstant;
begin
  M := TMutex.Create;
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
  begin
    M.Acquire;
    M.Release;
  end;
  
  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    M.Acquire;
    M.Release;
  end;
  EndT := NowInstant;
  
  AddResult('Mutex: Acquire/Release (single thread)', EndT.Diff(Start), ITERATIONS);
end;

// ============================================================================
// RWLock Benchmarks
// ============================================================================

procedure BenchRWLock_ReadOnly_SingleThread;
var
  RW: IRWLock;
  I: Integer;
  Start, EndT: TInstant;
begin
  RW := TRWLock.Create;  // Default: AllowReentrancy=True
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  
  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  EndT := NowInstant;
  
  AddResult('RWLock: Read (single thread, default)', EndT.Diff(Start), ITERATIONS);
end;

// Fast path test: Non-reentrant RWLock
procedure BenchRWLock_ReadOnly_NoReentry;
var
  RW: IRWLock;
  Opts: TRWLockOptions;
  I: Integer;
  Start, EndT: TInstant;
begin
  // Non-reentrant mode - uses fast path
  Opts.AllowReentrancy := False;
  Opts.FairMode := False;
  Opts.WriterPriority := False;
  Opts.MaxReaders := 1024;
  Opts.SpinCount := 4000;
  Opts.EnablePoisoning := True;
  Opts.ReaderBiasEnabled := True;
  RW := TRWLock.Create(Opts);
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  
  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  EndT := NowInstant;
  
  AddResult('RWLock: Read (single, NoReentry)', EndT.Diff(Start), ITERATIONS);
end;

procedure BenchRWLock_ReadOnly_ReaderBias;
var
  RW: IRWLock;
  Opts: TRWLockOptions;
  I: Integer;
  Start, EndT: TInstant;
begin
  // Initialize with reasonable defaults, not Default() which zeroes everything
  Opts.AllowReentrancy := True;
  Opts.FairMode := False;
  Opts.WriterPriority := False;
  Opts.MaxReaders := 1024;
  Opts.SpinCount := 4000;
  Opts.EnablePoisoning := True;
  Opts.ReaderBiasEnabled := True;  // This is what we're testing
  RW := TRWLock.Create(Opts);
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  
  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  EndT := NowInstant;
  
  AddResult('RWLock: Read (single thread, ReaderBias=True)', EndT.Diff(Start), ITERATIONS);
end;

procedure BenchRWLock_ReadOnly_NoReaderBias;
var
  RW: IRWLock;
  Opts: TRWLockOptions;
  I: Integer;
  Start, EndT: TInstant;
begin
  // Initialize with reasonable defaults, not Default() which zeroes everything
  Opts.AllowReentrancy := True;
  Opts.FairMode := False;
  Opts.WriterPriority := False;
  Opts.MaxReaders := 1024;
  Opts.SpinCount := 4000;
  Opts.EnablePoisoning := True;
  Opts.ReaderBiasEnabled := False;  // This is what we're testing
  RW := TRWLock.Create(Opts);
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  
  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  EndT := NowInstant;
  
  AddResult('RWLock: Read (single thread, ReaderBias=False)', EndT.Diff(Start), ITERATIONS);
end;

procedure BenchRWLock_WriteOnly_SingleThread;
var
  RW: IRWLock;
  I: Integer;
  Start, EndT: TInstant;
begin
  RW := TRWLock.Create;
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
  begin
    RW.AcquireWrite;
    RW.ReleaseWrite;
  end;
  
  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    RW.AcquireWrite;
    RW.ReleaseWrite;
  end;
  EndT := NowInstant;
  
  AddResult('RWLock: Write (single thread)', EndT.Diff(Start), ITERATIONS);
end;

procedure BenchRWLock_WithGuard_Read;
var
  RW: IRWLock;
  G: IRWLockReadGuard;
  I: Integer;
  Start, EndT: TInstant;
begin
  RW := TRWLock.Create;
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
  begin
    G := RW.Read;
    G := nil;
  end;
  
  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    G := RW.Read;
    G := nil;
  end;
  EndT := NowInstant;
  
  AddResult('RWLock: Read with Guard (single thread)', EndT.Diff(Start), ITERATIONS);
end;

procedure BenchRWLock_WithGuard_Write;
var
  RW: IRWLock;
  G: IRWLockWriteGuard;
  I: Integer;
  Start, EndT: TInstant;
begin
  RW := TRWLock.Create;
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
  begin
    G := RW.Write;
    G := nil;
  end;
  
  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    G := RW.Write;
    G := nil;
  end;
  EndT := NowInstant;
  
  AddResult('RWLock: Write with Guard (single thread)', EndT.Diff(Start), ITERATIONS);
end;

// ============================================================================
// Comparison: No Lock
// ============================================================================

procedure BenchNoLock_Baseline;
var
  Counter: Integer;
  I: Integer;
  Start, EndT: TInstant;
begin
  Counter := 0;
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
    Inc(Counter);
  
  Counter := 0;
  Start := NowInstant;
  for I := 1 to ITERATIONS do
    Inc(Counter);
  EndT := NowInstant;
  
  AddResult('Baseline: Inc (no lock)', EndT.Diff(Start), ITERATIONS);
end;

// ============================================================================
// Multi-threaded Benchmarks
// ============================================================================

type
  TMutexBenchThread = class(TThread)
  private
    FMutex: IMutex;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex; AIterations: Integer);
  end;

constructor TMutexBenchThread.Create(AMutex: IMutex; AIterations: Integer);
begin
  inherited Create(True);
  FMutex := AMutex;
  FIterations := AIterations;
  FreeOnTerminate := False;
end;

procedure TMutexBenchThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
  begin
    FMutex.Acquire;
    FMutex.Release;
  end;
end;

procedure BenchMutex_MultiThread(ThreadCount: Integer);
var
  M: IMutex;
  Threads: array of TMutexBenchThread;
  I: Integer;
  Start, EndT: TInstant;
  IterPerThread: Integer;
begin
  M := TMutex.Create;
  IterPerThread := ITERATIONS div ThreadCount;
  
  SetLength(Threads, ThreadCount);
  for I := 0 to ThreadCount - 1 do
    Threads[I] := TMutexBenchThread.Create(M, IterPerThread);
  
  Start := NowInstant;
  
  for I := 0 to ThreadCount - 1 do
    Threads[I].Start;
  
  for I := 0 to ThreadCount - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  EndT := NowInstant;
  
  AddResult(Format('Mutex: Acquire/Release (%d threads)', [ThreadCount]), 
            EndT.Diff(Start), IterPerThread * ThreadCount);
end;

type
  TRWLockReadBenchThread = class(TThread)
  private
    FRWLock: IRWLock;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; AIterations: Integer);
  end;

constructor TRWLockReadBenchThread.Create(ARWLock: IRWLock; AIterations: Integer);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FIterations := AIterations;
  FreeOnTerminate := False;
end;

procedure TRWLockReadBenchThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
  begin
    FRWLock.AcquireRead;
    FRWLock.ReleaseRead;
  end;
end;

procedure BenchRWLock_ReadOnly_MultiThread(ThreadCount: Integer; ReaderBias: Boolean);
var
  RW: IRWLock;
  Opts: TRWLockOptions;
  Threads: array of TRWLockReadBenchThread;
  I: Integer;
  Start, EndT: TInstant;
  IterPerThread: Integer;
  BenchName: string;
begin
  // Initialize with reasonable defaults
  Opts.AllowReentrancy := True;
  Opts.FairMode := False;
  Opts.WriterPriority := False;
  Opts.MaxReaders := 1024;
  Opts.SpinCount := 4000;
  Opts.EnablePoisoning := True;
  Opts.ReaderBiasEnabled := ReaderBias;
  RW := TRWLock.Create(Opts);
  
  IterPerThread := ITERATIONS div ThreadCount;
  
  SetLength(Threads, ThreadCount);
  for I := 0 to ThreadCount - 1 do
    Threads[I] := TRWLockReadBenchThread.Create(RW, IterPerThread);
  
  Start := NowInstant;
  
  for I := 0 to ThreadCount - 1 do
    Threads[I].Start;
  
  for I := 0 to ThreadCount - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  EndT := NowInstant;
  
  if ReaderBias then
    BenchName := Format('RWLock: Read (%d threads, ReaderBias=True)', [ThreadCount])
  else
    BenchName := Format('RWLock: Read (%d threads, ReaderBias=False)', [ThreadCount]);
    
  AddResult(BenchName, EndT.Diff(Start), IterPerThread * ThreadCount);
end;

// ============================================================================
// Named Sync Primitives Benchmarks
// ============================================================================

const
  NAMED_ITERATIONS = 100000;  // Fewer iterations for Named (more overhead)

procedure BenchNamedMutex_SingleThread;
var
  M: INamedMutex;
  I: Integer;
  Start, EndT: TInstant;
begin
  M := CreateNamedMutex('bench_mutex_' + IntToStr(Random(100000)));
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS div 10 do
  begin
    M.Acquire;
    M.Release;
  end;
  
  Start := NowInstant;
  for I := 1 to NAMED_ITERATIONS do
  begin
    M.Acquire;
    M.Release;
  end;
  EndT := NowInstant;
  
  AddResult('NamedMutex: Acquire/Release (single thread)', EndT.Diff(Start), NAMED_ITERATIONS);
end;

procedure BenchNamedEvent_SingleThread;
var
  E: INamedEvent;
  I: Integer;
  Start, EndT: TInstant;
begin
  E := CreateNamedEvent('bench_event_' + IntToStr(Random(100000)), True, False);  // ManualReset=True for Reset to work
  
  // Warmup
  for I := 1 to WARMUP_ITERATIONS div 10 do
  begin
    E.Signal;
    E.Reset;
  end;
  
  Start := NowInstant;
  for I := 1 to NAMED_ITERATIONS do
  begin
    E.Signal;
    E.Reset;
  end;
  EndT := NowInstant;
  
  AddResult('NamedEvent: Signal/Reset (single thread)', EndT.Diff(Start), NAMED_ITERATIONS);
end;

procedure BenchNamedMutex_Creation;
var
  I: Integer;
  Start, EndT: TInstant;
  M: INamedMutex;
const
  CREATE_ITERATIONS = 1000;
begin
  Start := NowInstant;
  for I := 1 to CREATE_ITERATIONS do
  begin
    M := CreateNamedMutex('bench_create_mutex_' + IntToStr(I));
    M := nil;  // Force cleanup
  end;
  EndT := NowInstant;
  
  AddResult('NamedMutex: Create/Destroy', EndT.Diff(Start), CREATE_ITERATIONS);
end;

// ============================================================================
// Main
// ============================================================================

begin
  WriteLn('fafafa.core.sync Benchmark');
  WriteLn('==========================');
  WriteLn(Format('Iterations: %d', [ITERATIONS]));
  WriteLn(Format('Warmup: %d', [WARMUP_ITERATIONS]));
  WriteLn;
  
  ResultCount := 0;
  
  // Baseline
  WriteLn('Running baseline...');
  BenchNoLock_Baseline;
  
  // Single-threaded benchmarks
  WriteLn('Running Mutex benchmarks...');
  BenchMutex_SingleThread;
  
  WriteLn('Running RWLock benchmarks...');
  BenchRWLock_ReadOnly_SingleThread;
  BenchRWLock_ReadOnly_NoReentry;
  BenchRWLock_ReadOnly_ReaderBias;
  BenchRWLock_ReadOnly_NoReaderBias;
  BenchRWLock_WriteOnly_SingleThread;
  BenchRWLock_WithGuard_Read;
  BenchRWLock_WithGuard_Write;
  
  // Multi-threaded benchmarks
  WriteLn('Running multi-threaded benchmarks...');
  BenchMutex_MultiThread(2);
  BenchMutex_MultiThread(4);
  
  BenchRWLock_ReadOnly_MultiThread(2, True);
  BenchRWLock_ReadOnly_MultiThread(2, False);
  BenchRWLock_ReadOnly_MultiThread(4, True);
  BenchRWLock_ReadOnly_MultiThread(4, False);
  
  // Named primitives benchmarks
  WriteLn('Running Named sync benchmarks...');
  BenchNamedMutex_SingleThread;
  BenchNamedEvent_SingleThread;
  BenchNamedMutex_Creation;
  
  // Print results
  PrintResults;
  
  WriteLn('Benchmark completed.');
end.
