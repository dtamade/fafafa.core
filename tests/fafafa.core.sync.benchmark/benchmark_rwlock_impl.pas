program benchmark_rwlock_impl;

{**
 * RWLock Performance Benchmark
 *
 * 测试 RWLock 在不同读写比例下的性能
 *
 * @author fafafaStudio
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.time,
  fafafa.core.sync.rwlock;

const
  ITERATIONS = 5000000;          // 500 万次迭代
  WARMUP_ITERATIONS = 50000;     // 5 万次预热
  THREAD_COUNT = 4;
  READER_THREAD_COUNT = 6;       // 读者线程数
  WRITER_THREAD_COUNT = 2;       // 写者线程数

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

procedure AddResult(const AName: string; ATotalTime: TDuration; AIterations: Int64);
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

procedure PrintHeader;
begin
  WriteLn;
  WriteLn('================================================================================');
  WriteLn('               fafafa.core.sync RWLock Performance Benchmark');
  WriteLn('================================================================================');
  WriteLn;
  WriteLn(Format('Base Iterations: %d (%.1fM)', [ITERATIONS, ITERATIONS / 1e6]));
  WriteLn(Format('Warmup:          %d', [WARMUP_ITERATIONS]));
  WriteLn(Format('Reader Threads:  %d', [READER_THREAD_COUNT]));
  WriteLn(Format('Writer Threads:  %d', [WRITER_THREAD_COUNT]));
  WriteLn;
end;

procedure PrintResults;
var
  I: Integer;
begin
  WriteLn;
  WriteLn('================================================================================');
  WriteLn('                            Benchmark Results');
  WriteLn('================================================================================');
  WriteLn;
  WriteLn(Format('%-50s %12s %15s', ['Scenario', 'ns/op', 'M ops/sec']));
  WriteLn(StringOfChar('-', 80));

  for I := 0 to ResultCount - 1 do
  begin
    WriteLn(Format('%-50s %12.2f %15.2f', [
      Results[I].Name,
      Results[I].AvgNsPerOp,
      Results[I].OpsPerSec / 1e6
    ]));
  end;

  WriteLn(StringOfChar('-', 80));
  WriteLn;
end;

// ============================================================================
// 单线程基准测试
// ============================================================================

procedure Bench_SingleThread_ReadOnly;
var
  RW: IRWLock;
  I: Int64;
  Start, EndT: TInstant;
begin
  WriteLn('  [1/8] Single Thread - Read Only...');

  RW := MakeRWLock;

  // 预热
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
  AddResult('Single Thread - Read Only', EndT.Diff(Start), ITERATIONS);
end;

procedure Bench_SingleThread_WriteOnly;
var
  RW: IRWLock;
  I: Int64;
  Start, EndT: TInstant;
begin
  WriteLn('  [2/8] Single Thread - Write Only...');

  RW := MakeRWLock;

  // 预热
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
  AddResult('Single Thread - Write Only', EndT.Diff(Start), ITERATIONS);
end;

procedure Bench_SingleThread_Guard;
var
  RW: IRWLock;
  I: Int64;
  Start, EndT: TInstant;
  Guard: IRWLockReadGuard;
begin
  WriteLn('  [3/8] Single Thread - Guard (RAII)...');

  RW := MakeRWLock;

  // 预热
  for I := 1 to WARMUP_ITERATIONS do
  begin
    Guard := RW.Read;
    Guard := nil;
  end;

  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    Guard := RW.Read;
    Guard := nil;
  end;
  EndT := NowInstant;
  AddResult('Single Thread - Guard (RAII)', EndT.Diff(Start), ITERATIONS);
end;

// ============================================================================
// 多线程基准测试 - 读者线程
// ============================================================================

type
  TReaderThread = class(TThread)
  private
    FRWLock: IRWLock;
    FIterations: Int64;
    FReadsCompleted: PInt64;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; AIterations: Int64; AReadsCompleted: PInt64);
  end;

constructor TReaderThread.Create(ARWLock: IRWLock; AIterations: Int64; AReadsCompleted: PInt64);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FIterations := AIterations;
  FReadsCompleted := AReadsCompleted;
  FreeOnTerminate := False;
end;

procedure TReaderThread.Execute;
var
  I: Int64;
begin
  for I := 1 to FIterations do
  begin
    FRWLock.AcquireRead;
    InterlockedIncrement64(FReadsCompleted^);
    FRWLock.ReleaseRead;
  end;
end;

// ============================================================================
// 多线程基准测试 - 写者线程
// ============================================================================

type
  TWriterThread = class(TThread)
  private
    FRWLock: IRWLock;
    FIterations: Int64;
    FWritesCompleted: PInt64;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; AIterations: Int64; AWritesCompleted: PInt64);
  end;

constructor TWriterThread.Create(ARWLock: IRWLock; AIterations: Int64; AWritesCompleted: PInt64);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FIterations := AIterations;
  FWritesCompleted := AWritesCompleted;
  FreeOnTerminate := False;
end;

procedure TWriterThread.Execute;
var
  I: Int64;
begin
  for I := 1 to FIterations do
  begin
    FRWLock.AcquireWrite;
    InterlockedIncrement64(FWritesCompleted^);
    FRWLock.ReleaseWrite;
  end;
end;

procedure Bench_MultiThread_ReadOnly;
const
  MT_ITERATIONS = 1000000;
var
  RW: IRWLock;
  Readers: array[0..READER_THREAD_COUNT-1] of TReaderThread;
  ReadsCompleted: Int64;
  I: Integer;
  Start, EndT: TInstant;
begin
  WriteLn('  [4/8] Multi-Thread - Read Only (', READER_THREAD_COUNT, ' readers)...');

  RW := MakeRWLock;
  ReadsCompleted := 0;

  for I := 0 to READER_THREAD_COUNT - 1 do
    Readers[I] := TReaderThread.Create(RW, MT_ITERATIONS, @ReadsCompleted);

  Start := NowInstant;
  for I := 0 to READER_THREAD_COUNT - 1 do
    Readers[I].Start;
  for I := 0 to READER_THREAD_COUNT - 1 do
  begin
    Readers[I].WaitFor;
    Readers[I].Free;
  end;
  EndT := NowInstant;

  AddResult(Format('%d Readers - Read Only', [READER_THREAD_COUNT]),
            EndT.Diff(Start), Int64(MT_ITERATIONS) * READER_THREAD_COUNT);
end;

procedure Bench_MultiThread_WriteOnly;
const
  MT_ITERATIONS = 500000;
var
  RW: IRWLock;
  Writers: array[0..WRITER_THREAD_COUNT-1] of TWriterThread;
  WritesCompleted: Int64;
  I: Integer;
  Start, EndT: TInstant;
begin
  WriteLn('  [5/8] Multi-Thread - Write Only (', WRITER_THREAD_COUNT, ' writers)...');

  RW := MakeRWLock;
  WritesCompleted := 0;

  for I := 0 to WRITER_THREAD_COUNT - 1 do
    Writers[I] := TWriterThread.Create(RW, MT_ITERATIONS, @WritesCompleted);

  Start := NowInstant;
  for I := 0 to WRITER_THREAD_COUNT - 1 do
    Writers[I].Start;
  for I := 0 to WRITER_THREAD_COUNT - 1 do
  begin
    Writers[I].WaitFor;
    Writers[I].Free;
  end;
  EndT := NowInstant;

  AddResult(Format('%d Writers - Write Only', [WRITER_THREAD_COUNT]),
            EndT.Diff(Start), Int64(MT_ITERATIONS) * WRITER_THREAD_COUNT);
end;

procedure Bench_MultiThread_MixedRW_ReadHeavy;
const
  READER_ITERS = 1000000;
  WRITER_ITERS = 100000;
var
  RW: IRWLock;
  Readers: array[0..5] of TReaderThread;
  Writers: array[0..1] of TWriterThread;
  ReadsCompleted, WritesCompleted: Int64;
  I: Integer;
  Start, EndT: TInstant;
  TotalOps: Int64;
begin
  WriteLn('  [6/8] Multi-Thread - Mixed R/W (Read Heavy: 6R + 2W)...');

  RW := MakeRWLock;
  ReadsCompleted := 0;
  WritesCompleted := 0;

  // 创建 6 个读者线程
  for I := 0 to 5 do
    Readers[I] := TReaderThread.Create(RW, READER_ITERS, @ReadsCompleted);

  // 创建 2 个写者线程
  for I := 0 to 1 do
    Writers[I] := TWriterThread.Create(RW, WRITER_ITERS, @WritesCompleted);

  Start := NowInstant;

  // 启动所有线程
  for I := 0 to 5 do
    Readers[I].Start;
  for I := 0 to 1 do
    Writers[I].Start;

  // 等待完成
  for I := 0 to 5 do
  begin
    Readers[I].WaitFor;
    Readers[I].Free;
  end;
  for I := 0 to 1 do
  begin
    Writers[I].WaitFor;
    Writers[I].Free;
  end;

  EndT := NowInstant;

  TotalOps := Int64(READER_ITERS) * 6 + Int64(WRITER_ITERS) * 2;
  AddResult('Mixed R/W (6 Readers + 2 Writers)', EndT.Diff(Start), TotalOps);
end;

procedure Bench_MultiThread_MixedRW_WriteHeavy;
const
  READER_ITERS = 200000;
  WRITER_ITERS = 500000;
var
  RW: IRWLock;
  Readers: array[0..1] of TReaderThread;
  Writers: array[0..3] of TWriterThread;
  ReadsCompleted, WritesCompleted: Int64;
  I: Integer;
  Start, EndT: TInstant;
  TotalOps: Int64;
begin
  WriteLn('  [7/8] Multi-Thread - Mixed R/W (Write Heavy: 2R + 4W)...');

  RW := MakeRWLock;
  ReadsCompleted := 0;
  WritesCompleted := 0;

  // 创建 2 个读者线程
  for I := 0 to 1 do
    Readers[I] := TReaderThread.Create(RW, READER_ITERS, @ReadsCompleted);

  // 创建 4 个写者线程
  for I := 0 to 3 do
    Writers[I] := TWriterThread.Create(RW, WRITER_ITERS, @WritesCompleted);

  Start := NowInstant;

  // 启动所有线程
  for I := 0 to 1 do
    Readers[I].Start;
  for I := 0 to 3 do
    Writers[I].Start;

  // 等待完成
  for I := 0 to 1 do
  begin
    Readers[I].WaitFor;
    Readers[I].Free;
  end;
  for I := 0 to 3 do
  begin
    Writers[I].WaitFor;
    Writers[I].Free;
  end;

  EndT := NowInstant;

  TotalOps := Int64(READER_ITERS) * 2 + Int64(WRITER_ITERS) * 4;
  AddResult('Mixed R/W (2 Readers + 4 Writers)', EndT.Diff(Start), TotalOps);
end;

procedure Bench_Downgrade;
const
  DG_ITERATIONS = 1000000;
var
  RW: IRWLock;
  I: Int64;
  Start, EndT: TInstant;
  WriteGuard: IRWLockWriteGuard;
  ReadGuard: IRWLockReadGuard;
begin
  WriteLn('  [8/8] Single Thread - Write-to-Read Downgrade...');

  RW := MakeRWLock;

  // 预热
  for I := 1 to WARMUP_ITERATIONS div 10 do
  begin
    WriteGuard := RW.Write;
    ReadGuard := WriteGuard.Downgrade;
    ReadGuard := nil;
  end;

  Start := NowInstant;
  for I := 1 to DG_ITERATIONS do
  begin
    WriteGuard := RW.Write;
    ReadGuard := WriteGuard.Downgrade;
    ReadGuard := nil;
  end;
  EndT := NowInstant;
  AddResult('Write-to-Read Downgrade', EndT.Diff(Start), DG_ITERATIONS);
end;

// ============================================================================
// Main
// ============================================================================

begin
  PrintHeader;

  ResultCount := 0;

  WriteLn('Running benchmarks...');
  WriteLn;

  // 单线程测试
  Bench_SingleThread_ReadOnly;
  Bench_SingleThread_WriteOnly;
  Bench_SingleThread_Guard;

  // 多线程测试
  Bench_MultiThread_ReadOnly;
  Bench_MultiThread_WriteOnly;
  Bench_MultiThread_MixedRW_ReadHeavy;
  Bench_MultiThread_MixedRW_WriteHeavy;

  // 特殊操作
  Bench_Downgrade;

  // 打印结果
  PrintResults;

  WriteLn('Benchmark completed successfully.');
end.
