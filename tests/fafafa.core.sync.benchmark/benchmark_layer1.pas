{$CODEPAGE UTF8}
program benchmark_layer1;

{**
 * fafafa.core Layer 1 综合性能基准测试
 *
 * 测试覆盖：
 * 1. Atomic - CAS 性能、内存序开销
 * 2. Parker - 停放/唤醒延迟
 * 3. Latch - 大量线程等待
 * 4. WaitGroup - 并发 Done/Wait
 * 5. Barrier - 多线程同步
 *
 * @author fafafaStudio
 * @version 1.0
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.time.duration,
  fafafa.core.time.stopwatch,
  fafafa.core.atomic,
  fafafa.core.sync.parker,
  fafafa.core.sync.latch,
  fafafa.core.sync.waitgroup,
  fafafa.core.sync.barrier;

const
  ITERATIONS = 1000000;       // 100 万次迭代
  WARMUP_ITERATIONS = 10000;  // 1 万次预热
  THREAD_COUNT = 8;           // 默认线程数

type
  TBenchmarkResult = record
    Name: string;
    TotalNs: UInt64;
    OpsPerSec: Double;
    AvgNsPerOp: Double;
  end;

var
  Results: array of TBenchmarkResult;
  ResultCount: Integer = 0;

// ===== 辅助函数 =====

procedure AddResult(const AName: string; ATotalNs: UInt64; AIterations: Int64);
var
  R: TBenchmarkResult;
  TotalSec: Double;
begin
  R.Name := AName;
  R.TotalNs := ATotalNs;

  // 计算时间（秒）
  TotalSec := ATotalNs / 1000000000.0;

  // 防止除零
  if (ATotalNs > 0) and (AIterations > 0) then
  begin
    R.OpsPerSec := AIterations / TotalSec;
    R.AvgNsPerOp := Double(ATotalNs) / Double(AIterations);
  end
  else
  begin
    R.OpsPerSec := 0;
    R.AvgNsPerOp := 0;
  end;

  WriteLn(Format('  %-40s %10d ns, %.2f ns/op', [AName, ATotalNs, R.AvgNsPerOp]));

  SetLength(Results, ResultCount + 1);
  Results[ResultCount] := R;
  Inc(ResultCount);
end;

procedure PrintHeader(const ATitle: string);
begin
  WriteLn;
  WriteLn(StringOfChar('=', 80));
  WriteLn('  ', ATitle);
  WriteLn(StringOfChar('=', 80));
  WriteLn;
end;

procedure PrintResults;
var
  I: Integer;
  NsPerOp, MOpsPerSec: Double;
begin
  WriteLn;
  WriteLn(StringOfChar('=', 80));
  WriteLn('  综合结果');
  WriteLn(StringOfChar('=', 80));
  WriteLn;
  WriteLn(Format('%-50s %12s %15s', ['场景', 'ns/op', 'M ops/sec']));
  WriteLn(StringOfChar('-', 80));

  for I := 0 to ResultCount - 1 do
  begin
    NsPerOp := Results[I].AvgNsPerOp;
    if Results[I].OpsPerSec > 0 then
      MOpsPerSec := Results[I].OpsPerSec / 1e6
    else
      MOpsPerSec := 0;
    WriteLn(Format('%-50s %12.2f %15.2f', [
      Results[I].Name,
      NsPerOp,
      MOpsPerSec
    ]));
  end;
end;

// ===== 1. Atomic 基准测试 =====

procedure Benchmark_Atomic_Load;
var
  Value: Int64 = 0;
  I: Integer;
  SW: TStopwatch;
const
  LocalIterations = 10000000; // 1000万次
begin
  // 预热
  for I := 1 to WARMUP_ITERATIONS do
    atomic_load(Value, mo_relaxed);

  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
    atomic_load(Value, mo_relaxed);
  SW.Stop;
  AddResult('Atomic Load (mo_relaxed)', SW.ElapsedNs, LocalIterations);

  // 测试 mo_acquire
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
    atomic_load(Value, mo_acquire);
  SW.Stop;
  AddResult('Atomic Load (mo_acquire)', SW.ElapsedNs, LocalIterations);

  // 测试 mo_seq_cst
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
    atomic_load(Value, mo_seq_cst);
  SW.Stop;
  AddResult('Atomic Load (mo_seq_cst)', SW.ElapsedNs, LocalIterations);
end;

procedure Benchmark_Atomic_Store;
var
  Value: Int64 = 0;
  I: Integer;
  SW: TStopwatch;
const
  LocalIterations = 10000000;
begin
  // mo_relaxed
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
    atomic_store(Value, I, mo_relaxed);
  SW.Stop;
  AddResult('Atomic Store (mo_relaxed)', SW.ElapsedNs, LocalIterations);

  // mo_release
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
    atomic_store(Value, I, mo_release);
  SW.Stop;
  AddResult('Atomic Store (mo_release)', SW.ElapsedNs, LocalIterations);

  // mo_seq_cst
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
    atomic_store(Value, I, mo_seq_cst);
  SW.Stop;
  AddResult('Atomic Store (mo_seq_cst)', SW.ElapsedNs, LocalIterations);
end;

procedure Benchmark_Atomic_CAS;
var
  Value: Int64 = 0;
  Expected: Int64;
  I: Integer;
  SW: TStopwatch;
const
  LocalIterations = 1000000;
begin
  // CAS 成功路径
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
  begin
    Expected := I - 1;
    atomic_compare_exchange_strong(Value, Expected, I, mo_acq_rel, mo_relaxed);
  end;
  SW.Stop;
  AddResult('Atomic CAS (成功路径)', SW.ElapsedNs, LocalIterations);

  // CAS 失败路径
  Value := 0;
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
  begin
    Expected := -1; // 永远不匹配
    atomic_compare_exchange_strong(Value, Expected, I, mo_acq_rel, mo_relaxed);
  end;
  SW.Stop;
  AddResult('Atomic CAS (失败路径)', SW.ElapsedNs, LocalIterations);
end;

procedure Benchmark_Atomic_FetchAdd;
var
  Value: Int64 = 0;
  I: Integer;
  SW: TStopwatch;
const
  LocalIterations = 1000000;
begin
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
    atomic_fetch_add(Value, 1, mo_relaxed);
  SW.Stop;
  AddResult('Atomic FetchAdd (mo_relaxed)', SW.ElapsedNs, LocalIterations);

  Value := 0;
  SW := TStopwatch.StartNew;
  for I := 1 to LocalIterations do
    atomic_fetch_add(Value, 1, mo_acq_rel);
  SW.Stop;
  AddResult('Atomic FetchAdd (mo_acq_rel)', SW.ElapsedNs, LocalIterations);
end;

// ===== 2. Parker 基准测试 =====

type
  TParkerThread = class(TThread)
  private
    FParker: IParker;
    FIterations: Integer;
    FElapsedNs: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(AParker: IParker; AIterations: Integer);
    property ElapsedNs: QWord read FElapsedNs;
  end;

constructor TParkerThread.Create(AParker: IParker; AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FParker := AParker;
  FIterations := AIterations;
  FElapsedNs := 0;
end;

procedure TParkerThread.Execute;
var
  I: Integer;
  SW: TStopwatch;
begin
  SW := TStopwatch.StartNew;
  for I := 1 to FIterations do
    FParker.Park;
  SW.Stop;
  FElapsedNs := SW.ElapsedNs;
end;

procedure Benchmark_Parker;
var
  P: IParker;
  T: TParkerThread;
  I: Integer;
  SW: TStopwatch;
  Iterations: Integer;
begin
  Iterations := 10000;

  // Parker 自唤醒（Unpark 后 Park 立即返回）
  P := MakeParker;
  SW := TStopwatch.StartNew;
  for I := 1 to Iterations do
  begin
    P.Unpark;
    P.Park;
  end;
  SW.Stop;
  AddResult('Parker Unpark+Park (自唤醒)', SW.ElapsedNs, Iterations);

  // Parker 跨线程 Unpark → Park
  P := MakeParker;
  T := TParkerThread.Create(P, Iterations);

  SW := TStopwatch.StartNew;
  T.Start;
  for I := 1 to Iterations do
  begin
    Sleep(0); // 让出 CPU
    P.Unpark;
  end;
  T.WaitFor;
  SW.Stop;
  T.Free;

  AddResult('Parker 跨线程 Unpark->Park', SW.ElapsedNs, Iterations);
end;

// ===== 3. Latch 基准测试 =====

type
  TLatchWaiter = class(TThread)
  private
    FLatch: ILatch;
  protected
    procedure Execute; override;
  public
    constructor Create(ALatch: ILatch);
  end;

constructor TLatchWaiter.Create(ALatch: ILatch);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FLatch := ALatch;
end;

procedure TLatchWaiter.Execute;
begin
  FLatch.Await;
end;

procedure Benchmark_Latch;
var
  L: ILatch;
  I, ThreadCount: Integer;
  Waiters: array of TLatchWaiter = nil;
  SW: TStopwatch;
begin
  // 单线程 CountDown
  L := MakeLatch(ITERATIONS);
  SW := TStopwatch.StartNew;
  for I := 1 to ITERATIONS do
    L.CountDown;
  SW.Stop;
  AddResult('Latch CountDown (单线程)', SW.ElapsedNs, ITERATIONS);

  // 多线程等待 + 释放
  ThreadCount := 100;
  SetLength(Waiters, ThreadCount);
  L := MakeLatch(1);

  for I := 0 to ThreadCount - 1 do
    Waiters[I] := TLatchWaiter.Create(L);

  SW := TStopwatch.StartNew;

  // 启动所有等待线程
  for I := 0 to ThreadCount - 1 do
    Waiters[I].Start;

  Sleep(10); // 让所有线程开始等待

  // 释放门闩
  L.CountDown;

  // 等待所有线程完成
  for I := 0 to ThreadCount - 1 do
  begin
    Waiters[I].WaitFor;
    Waiters[I].Free;
  end;

  SW.Stop;
  AddResult(Format('Latch Await (%d线程唤醒)', [ThreadCount]), SW.ElapsedNs, ThreadCount);
end;

// ===== 4. WaitGroup 基准测试 =====

type
  TWGWorker = class(TThread)
  private
    FWG: IWaitGroup;
  protected
    procedure Execute; override;
  public
    constructor Create(AWG: IWaitGroup);
  end;

constructor TWGWorker.Create(AWG: IWaitGroup);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWG := AWG;
end;

procedure TWGWorker.Execute;
begin
  FWG.Done;
end;

procedure Benchmark_WaitGroup;
var
  WG: IWaitGroup;
  I, ThreadCount: Integer;
  Workers: array of TWGWorker = nil;
  SW: TStopwatch;
begin
  // 单线程 Add/Done
  WG := MakeWaitGroup;
  SW := TStopwatch.StartNew;
  for I := 1 to ITERATIONS do
  begin
    WG.Add(1);
    WG.Done;
  end;
  SW.Stop;
  AddResult('WaitGroup Add+Done (单线程)', SW.ElapsedNs, ITERATIONS);

  // 批量 Add + 并发 Done
  ThreadCount := 100;
  SetLength(Workers, ThreadCount);
  WG := MakeWaitGroup;
  WG.Add(ThreadCount);

  for I := 0 to ThreadCount - 1 do
    Workers[I] := TWGWorker.Create(WG);

  SW := TStopwatch.StartNew;

  for I := 0 to ThreadCount - 1 do
    Workers[I].Start;

  WG.Wait;

  for I := 0 to ThreadCount - 1 do
  begin
    Workers[I].WaitFor;
    Workers[I].Free;
  end;

  SW.Stop;
  AddResult(Format('WaitGroup 并发Done (%d线程)', [ThreadCount]), SW.ElapsedNs, ThreadCount);
end;

// ===== 5. Barrier 基准测试 =====

type
  TBarrierWorker = class(TThread)
  private
    FBarrier: IBarrier;
    FIterations: Integer;
    FId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ABarrier: IBarrier; AId, AIterations: Integer);
  end;

constructor TBarrierWorker.Create(ABarrier: IBarrier; AId, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FBarrier := ABarrier;
  FId := AId;
  FIterations := AIterations;
end;

procedure TBarrierWorker.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
    FBarrier.Wait;
end;

procedure Benchmark_Barrier;
var
  B: IBarrier;
  I, ThreadCount, BarrierIterations: Integer;
  Workers: array of TBarrierWorker = nil;
  SW: TStopwatch;
begin
  // 单线程 Barrier（count=1）
  B := MakeBarrier(1);
  SW := TStopwatch.StartNew;
  for I := 1 to 10000 do
    B.Wait;
  SW.Stop;
  AddResult('Barrier Wait (单线程)', SW.ElapsedNs, 10000);

  // 多线程同步
  ThreadCount := 8;
  BarrierIterations := 1000;
  SetLength(Workers, ThreadCount);
  B := MakeBarrier(ThreadCount);

  for I := 0 to ThreadCount - 1 do
    Workers[I] := TBarrierWorker.Create(B, I, BarrierIterations);

  SW := TStopwatch.StartNew;

  for I := 0 to ThreadCount - 1 do
    Workers[I].Start;

  for I := 0 to ThreadCount - 1 do
  begin
    Workers[I].WaitFor;
    Workers[I].Free;
  end;

  SW.Stop;
  AddResult(Format('Barrier 多线程同步 (%d线程x%d轮)', [ThreadCount, BarrierIterations]),
            SW.ElapsedNs, ThreadCount * BarrierIterations);
end;

// ===== 主程序 =====

begin
  WriteLn;
  WriteLn('================================================================================');
  WriteLn('        fafafa.core Layer 1 综合性能基准测试');
  WriteLn('================================================================================');
  WriteLn;
  WriteLn(Format('迭代次数: %d', [ITERATIONS]));
  WriteLn(Format('线程数:   %d', [THREAD_COUNT]));
  WriteLn;

  // 1. Atomic
  PrintHeader('1. Atomic 操作');
  Benchmark_Atomic_Load;
  Benchmark_Atomic_Store;
  Benchmark_Atomic_CAS;
  Benchmark_Atomic_FetchAdd;

  // 2. Parker
  PrintHeader('2. Parker 停放/唤醒');
  Benchmark_Parker;

  // 3. Latch
  PrintHeader('3. Latch 闭锁');
  Benchmark_Latch;

  // 4. WaitGroup
  PrintHeader('4. WaitGroup 等待组');
  Benchmark_WaitGroup;

  // 5. Barrier
  PrintHeader('5. Barrier 屏障');
  Benchmark_Barrier;

  // 打印综合结果
  PrintResults;

  WriteLn;
  WriteLn('基准测试完成。');
end.
