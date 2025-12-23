program benchmark_mutex_impl;

{**
 * pthread vs futex Mutex Implementation Benchmark
 *
 * 对比 pthread_mutex 和 futex 实现的性能差异
 *
 * @author fafafaStudio
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.time,
  fafafa.core.sync.mutex,
  fafafa.core.sync.mutex.unix,
  fafafa.core.sync.spin;

const
  ITERATIONS = 10000000;       // 1000 万次迭代
  WARMUP_ITERATIONS = 100000;  // 10 万次预热
  THREAD_COUNT = 4;

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
  WriteLn('            fafafa.core.sync Mutex Implementation Benchmark');
  WriteLn('================================================================================');
  WriteLn;
  WriteLn(Format('Iterations: %d (%.1fM)', [ITERATIONS, ITERATIONS / 1e6]));
  WriteLn(Format('Warmup:     %d', [WARMUP_ITERATIONS]));
  WriteLn(Format('Threads:    %d', [THREAD_COUNT]));
  WriteLn;
end;

procedure PrintResults;
var
  I: Integer;
  PthreadNs, FutexNs, Speedup: Double;
begin
  WriteLn;
  WriteLn('================================================================================');
  WriteLn('                            Benchmark Results');
  WriteLn('================================================================================');
  WriteLn;
  WriteLn(Format('%-45s %12s %15s %10s', ['Scenario', 'ns/op', 'M ops/sec', 'Speedup']));
  WriteLn(StringOfChar('-', 85));

  I := 0;
  while I < ResultCount do
  begin
    // 处理成对的 pthread/futex 结果
    if (I + 1 < ResultCount) and
       (Pos('pthread', Results[I].Name) > 0) and
       (Pos('futex', Results[I + 1].Name) > 0) then
    begin
      PthreadNs := Results[I].AvgNsPerOp;
      FutexNs := Results[I + 1].AvgNsPerOp;
      Speedup := PthreadNs / FutexNs;

      // pthread 行
      WriteLn(Format('%-45s %12.2f %15.2f %10s', [
        Results[I].Name,
        Results[I].AvgNsPerOp,
        Results[I].OpsPerSec / 1e6,
        '-'
      ]));

      // futex 行 (带 speedup)
      WriteLn(Format('%-45s %12.2f %15.2f %9.2fx', [
        Results[I + 1].Name,
        Results[I + 1].AvgNsPerOp,
        Results[I + 1].OpsPerSec / 1e6,
        Speedup
      ]));
      WriteLn;
      Inc(I, 2);
    end
    else
    begin
      // 单独的结果 (如 SpinLock)
      WriteLn(Format('%-45s %12.2f %15.2f %10s', [
        Results[I].Name,
        Results[I].AvgNsPerOp,
        Results[I].OpsPerSec / 1e6,
        '-'
      ]));
      Inc(I);
    end;
  end;

  WriteLn('================================================================================');
  WriteLn;
end;

// ============================================================================
// 单线程基准测试
// ============================================================================

procedure Bench_SingleThread_NoContention;
var
  MPthread, MFutex: IMutex;
  I: Int64;
  Start, EndT: TInstant;
begin
  WriteLn('  [1/6] Single Thread - No Contention...');

  // pthread 版本
  MPthread := MakePthreadMutex;
  for I := 1 to WARMUP_ITERATIONS do
  begin
    MPthread.Acquire;
    MPthread.Release;
  end;

  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    MPthread.Acquire;
    MPthread.Release;
  end;
  EndT := NowInstant;
  AddResult('Single Thread (pthread)', EndT.Diff(Start), ITERATIONS);

  // futex 版本
  MFutex := MakeFutexMutex;
  for I := 1 to WARMUP_ITERATIONS do
  begin
    MFutex.Acquire;
    MFutex.Release;
  end;

  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    MFutex.Acquire;
    MFutex.Release;
  end;
  EndT := NowInstant;
  AddResult('Single Thread (futex)', EndT.Diff(Start), ITERATIONS);
end;

procedure Bench_SingleThread_RapidAcquire;
const
  RAPID_ITERATIONS = 5000000;
var
  MPthread, MFutex: IMutex;
  I: Int64;
  Start, EndT: TInstant;
begin
  WriteLn('  [2/6] Single Thread - Rapid Acquire/Release...');

  // pthread 版本 - 快速连续获取释放
  MPthread := MakePthreadMutex;

  Start := NowInstant;
  for I := 1 to RAPID_ITERATIONS do
  begin
    MPthread.Acquire;
    MPthread.Release;
    MPthread.Acquire;
    MPthread.Release;
  end;
  EndT := NowInstant;
  AddResult('Rapid Acquire/Release (pthread)', EndT.Diff(Start), RAPID_ITERATIONS * 2);

  // futex 版本
  MFutex := MakeFutexMutex;

  Start := NowInstant;
  for I := 1 to RAPID_ITERATIONS do
  begin
    MFutex.Acquire;
    MFutex.Release;
    MFutex.Acquire;
    MFutex.Release;
  end;
  EndT := NowInstant;
  AddResult('Rapid Acquire/Release (futex)', EndT.Diff(Start), RAPID_ITERATIONS * 2);
end;

// ============================================================================
// 多线程基准测试
// ============================================================================

type
  TMutexBenchThread = class(TThread)
  private
    FMutex: IMutex;
    FIterations: Int64;
    FCounter: PInt64;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex; AIterations: Int64; ACounter: PInt64);
  end;

constructor TMutexBenchThread.Create(AMutex: IMutex; AIterations: Int64; ACounter: PInt64);
begin
  inherited Create(True);
  FMutex := AMutex;
  FIterations := AIterations;
  FCounter := ACounter;
  FreeOnTerminate := False;
end;

procedure TMutexBenchThread.Execute;
var
  I: Int64;
begin
  for I := 1 to FIterations do
  begin
    FMutex.Acquire;
    Inc(FCounter^);  // 短临界区
    FMutex.Release;
  end;
end;

procedure Bench_MultiThread_LowContention;
const
  MT_ITERATIONS = 2500000;  // 每线程 250 万次
var
  MPthread, MFutex: IMutex;
  Threads: array[0..THREAD_COUNT-1] of TMutexBenchThread;
  Counter: Int64;
  I: Integer;
  Start, EndT: TInstant;
begin
  WriteLn('  [3/6] Multi-Thread - Low Contention (short critical section)...');

  // pthread 版本
  MPthread := MakePthreadMutex;
  Counter := 0;

  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TMutexBenchThread.Create(MPthread, MT_ITERATIONS, @Counter);

  Start := NowInstant;
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  EndT := NowInstant;
  AddResult(Format('%d Threads Low Contention (pthread)', [THREAD_COUNT]),
            EndT.Diff(Start), Int64(MT_ITERATIONS) * THREAD_COUNT);

  // futex 版本
  MFutex := MakeFutexMutex;
  Counter := 0;

  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TMutexBenchThread.Create(MFutex, MT_ITERATIONS, @Counter);

  Start := NowInstant;
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  EndT := NowInstant;
  AddResult(Format('%d Threads Low Contention (futex)', [THREAD_COUNT]),
            EndT.Diff(Start), Int64(MT_ITERATIONS) * THREAD_COUNT);
end;

type
  TMutexHighContentionThread = class(TThread)
  private
    FMutex: IMutex;
    FIterations: Int64;
    FCounter: PInt64;
    FWorkload: Integer;  // 临界区内工作量
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex; AIterations: Int64; ACounter: PInt64; AWorkload: Integer);
  end;

constructor TMutexHighContentionThread.Create(AMutex: IMutex; AIterations: Int64;
  ACounter: PInt64; AWorkload: Integer);
begin
  inherited Create(True);
  FMutex := AMutex;
  FIterations := AIterations;
  FCounter := ACounter;
  FWorkload := AWorkload;
  FreeOnTerminate := False;
end;

procedure TMutexHighContentionThread.Execute;
var
  I, J: Int64;
  Dummy: Int64;
begin
  Dummy := 0;
  for I := 1 to FIterations do
  begin
    FMutex.Acquire;
    // 长临界区 - 模拟工作负载
    for J := 1 to FWorkload do
      Inc(Dummy);
    Inc(FCounter^);
    FMutex.Release;
  end;
end;

procedure Bench_MultiThread_HighContention;
const
  HC_ITERATIONS = 500000;  // 每线程 50 万次
  WORKLOAD = 100;          // 临界区内循环次数
var
  MPthread, MFutex: IMutex;
  Threads: array[0..THREAD_COUNT-1] of TMutexHighContentionThread;
  Counter: Int64;
  I: Integer;
  Start, EndT: TInstant;
begin
  WriteLn('  [4/6] Multi-Thread - High Contention (long critical section)...');

  // pthread 版本
  MPthread := MakePthreadMutex;
  Counter := 0;

  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TMutexHighContentionThread.Create(MPthread, HC_ITERATIONS, @Counter, WORKLOAD);

  Start := NowInstant;
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  EndT := NowInstant;
  AddResult(Format('%d Threads High Contention (pthread)', [THREAD_COUNT]),
            EndT.Diff(Start), Int64(HC_ITERATIONS) * THREAD_COUNT);

  // futex 版本
  MFutex := MakeFutexMutex;
  Counter := 0;

  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TMutexHighContentionThread.Create(MFutex, HC_ITERATIONS, @Counter, WORKLOAD);

  Start := NowInstant;
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  EndT := NowInstant;
  AddResult(Format('%d Threads High Contention (futex)', [THREAD_COUNT]),
            EndT.Diff(Start), Int64(HC_ITERATIONS) * THREAD_COUNT);
end;

// ============================================================================
// SpinLock 对比
// ============================================================================

procedure Bench_SpinLock_SingleThread;
var
  S: ISpin;
  I: Int64;
  Start, EndT: TInstant;
begin
  WriteLn('  [5/6] SpinLock - Single Thread...');

  S := MakeSpin;

  for I := 1 to WARMUP_ITERATIONS do
  begin
    S.Acquire;
    S.Release;
  end;

  Start := NowInstant;
  for I := 1 to ITERATIONS do
  begin
    S.Acquire;
    S.Release;
  end;
  EndT := NowInstant;
  AddResult('SpinLock Single Thread', EndT.Diff(Start), ITERATIONS);
end;

type
  TSpinBenchThread = class(TThread)
  private
    FSpin: ISpin;
    FIterations: Int64;
    FCounter: PInt64;
  protected
    procedure Execute; override;
  public
    constructor Create(ASpin: ISpin; AIterations: Int64; ACounter: PInt64);
  end;

constructor TSpinBenchThread.Create(ASpin: ISpin; AIterations: Int64; ACounter: PInt64);
begin
  inherited Create(True);
  FSpin := ASpin;
  FIterations := AIterations;
  FCounter := ACounter;
  FreeOnTerminate := False;
end;

procedure TSpinBenchThread.Execute;
var
  I: Int64;
begin
  for I := 1 to FIterations do
  begin
    FSpin.Acquire;
    Inc(FCounter^);
    FSpin.Release;
  end;
end;

procedure Bench_SpinLock_MultiThread;
const
  SPIN_MT_ITERATIONS = 2500000;
var
  S: ISpin;
  Threads: array[0..THREAD_COUNT-1] of TSpinBenchThread;
  Counter: Int64;
  I: Integer;
  Start, EndT: TInstant;
begin
  WriteLn('  [6/6] SpinLock - Multi-Thread...');

  S := MakeSpin;
  Counter := 0;

  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TSpinBenchThread.Create(S, SPIN_MT_ITERATIONS, @Counter);

  Start := NowInstant;
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  EndT := NowInstant;
  AddResult(Format('SpinLock %d Threads', [THREAD_COUNT]),
            EndT.Diff(Start), Int64(SPIN_MT_ITERATIONS) * THREAD_COUNT);
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
  Bench_SingleThread_NoContention;
  Bench_SingleThread_RapidAcquire;

  // 多线程测试
  Bench_MultiThread_LowContention;
  Bench_MultiThread_HighContention;

  // SpinLock 对比
  Bench_SpinLock_SingleThread;
  Bench_SpinLock_MultiThread;

  // 打印结果
  PrintResults;

  WriteLn('Benchmark completed successfully.');
end.
