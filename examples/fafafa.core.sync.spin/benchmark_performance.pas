program benchmark_performance;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

type
  TBenchmarkThread = class(TThread)
  private
    FSpinLock: ISpinLock;
    FIterations: Integer;
    FElapsedMs: QWord;
  public
    constructor Create(ASpinLock: ISpinLock; AIterations: Integer);
    procedure Execute; override;
    property ElapsedMs: QWord read FElapsedMs;
  end;

constructor TBenchmarkThread.Create(ASpinLock: ISpinLock; AIterations: Integer);
begin
  inherited Create(False);
  FSpinLock := ASpinLock;
  FIterations := AIterations;
  FElapsedMs := 0;
end;

procedure TBenchmarkThread.Execute;
var
  i: Integer;
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  
  for i := 1 to FIterations do
  begin
    FSpinLock.Acquire;
    // 模拟极短的工作
    FSpinLock.Release;
  end;
  
  FElapsedMs := GetTickCount64 - StartTime;
end;

procedure RunSingleThreadBenchmark;
const
  ITERATIONS = 1000000;
var
  SpinLock: ISpinLock;
  StartTime, ElapsedTime: QWord;
  i: Integer;
  OpsPerSecond: Double;
begin
  WriteLn('=== 单线程性能基准 ===');
  
  SpinLock := MakeSpinLock;
  StartTime := GetTickCount64;
  
  for i := 1 to ITERATIONS do
  begin
    SpinLock.Acquire;
    SpinLock.Release;
  end;
  
  ElapsedTime := GetTickCount64 - StartTime;
  OpsPerSecond := (ITERATIONS * 1000.0) / ElapsedTime;
  
  WriteLn('迭代次数: ', ITERATIONS);
  WriteLn('执行时间: ', ElapsedTime, ' ms');
  WriteLn('每秒操作数: ', OpsPerSecond:0:0, ' ops/sec');
  WriteLn('每次操作时间: ', (ElapsedTime * 1000.0) / ITERATIONS:0:3, ' μs');
  WriteLn('');
end;

procedure RunMultiThreadBenchmark;
const
  ITERATIONS = 100000;
  THREAD_COUNT = 4;
var
  Policy: TSpinLockPolicy;
  SpinLock: ISpinLock;
  WithStats: ISpinLockWithStats;
  Threads: array[1..THREAD_COUNT] of TBenchmarkThread;
  Stats: TSpinLockStats;
  i: Integer;
  StartTime, ElapsedTime: QWord;
  TotalOps: Integer;
  OpsPerSecond: Double;
  MaxThreadTime, MinThreadTime, AvgThreadTime: QWord;
begin
  WriteLn('=== 多线程性能基准 ===');
  
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  SpinLock := MakeSpinLock(Policy);
  SpinLock.QueryInterface(ISpinLockWithStats, WithStats);
  
  StartTime := GetTickCount64;
  
  // 创建并启动线程
  for i := 1 to THREAD_COUNT do
    Threads[i] := TBenchmarkThread.Create(SpinLock, ITERATIONS);
  
  // 等待所有线程完成
  for i := 1 to THREAD_COUNT do
    Threads[i].WaitFor;
  
  ElapsedTime := GetTickCount64 - StartTime;
  
  // 计算统计信息
  MaxThreadTime := 0;
  MinThreadTime := High(QWord);
  AvgThreadTime := 0;
  
  for i := 1 to THREAD_COUNT do
  begin
    if Threads[i].ElapsedMs > MaxThreadTime then
      MaxThreadTime := Threads[i].ElapsedMs;
    if Threads[i].ElapsedMs < MinThreadTime then
      MinThreadTime := Threads[i].ElapsedMs;
    AvgThreadTime := AvgThreadTime + Threads[i].ElapsedMs;
  end;
  AvgThreadTime := AvgThreadTime div THREAD_COUNT;
  
  TotalOps := THREAD_COUNT * ITERATIONS;
  OpsPerSecond := (TotalOps * 1000.0) / ElapsedTime;
  
  WriteLn('线程数: ', THREAD_COUNT);
  WriteLn('每线程迭代次数: ', ITERATIONS);
  WriteLn('总操作数: ', TotalOps);
  WriteLn('总执行时间: ', ElapsedTime, ' ms');
  WriteLn('最快线程时间: ', MinThreadTime, ' ms');
  WriteLn('最慢线程时间: ', MaxThreadTime, ' ms');
  WriteLn('平均线程时间: ', AvgThreadTime, ' ms');
  WriteLn('每秒操作数: ', OpsPerSecond:0:0, ' ops/sec');
  WriteLn('每次操作时间: ', (ElapsedTime * 1000.0) / TotalOps:0:3, ' μs');
  
  // 显示竞争统计
  Stats := WithStats.GetStats;
  WriteLn('');
  WriteLn('竞争统计:');
  WriteLn('  总获取次数: ', Stats.AcquireCount);
  WriteLn('  竞争次数: ', Stats.ContentionCount);
  WriteLn('  竞争率: ', WithStats.GetContentionRate:0:2, '%');
  WriteLn('  平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
  
  // 清理
  for i := 1 to THREAD_COUNT do
    Threads[i].Free;
  
  WriteLn('');
end;

procedure RunStrategyComparison;
const
  ITERATIONS = 50000;
  THREAD_COUNT = 8;
var
  Strategies: array[1..3] of TSpinBackoffStrategy = (sbsLinear, sbsExponential, sbsAdaptive);
  StrategyNames: array[1..3] of string = ('线性退避', '指数退避', '自适应退避');
  Policy: TSpinLockPolicy;
  SpinLock: ISpinLock;
  WithStats: ISpinLockWithStats;
  Threads: array[1..THREAD_COUNT] of TBenchmarkThread;
  Stats: TSpinLockStats;
  i, j: Integer;
  StartTime, ElapsedTime: QWord;
  TotalOps: Integer;
  OpsPerSecond: Double;
begin
  WriteLn('=== 退避策略性能对比 ===');
  
  TotalOps := THREAD_COUNT * ITERATIONS;
  
  for j := 1 to 3 do
  begin
    WriteLn(StrategyNames[j], ':');
    
    Policy := DefaultSpinLockPolicy;
    Policy.MaxSpins := 32;
    Policy.BackoffStrategy := Strategies[j];
    Policy.MaxBackoffMs := 8;
    Policy.EnableStats := True;
    
    SpinLock := MakeSpinLock(Policy);
    SpinLock.QueryInterface(ISpinLockWithStats, WithStats);
    
    StartTime := GetTickCount64;
    
    // 创建并启动线程
    for i := 1 to THREAD_COUNT do
      Threads[i] := TBenchmarkThread.Create(SpinLock, ITERATIONS);
    
    // 等待所有线程完成
    for i := 1 to THREAD_COUNT do
      Threads[i].WaitFor;
    
    ElapsedTime := GetTickCount64 - StartTime;
    OpsPerSecond := (TotalOps * 1000.0) / ElapsedTime;
    
    Stats := WithStats.GetStats;
    
    WriteLn('  执行时间: ', ElapsedTime, ' ms');
    WriteLn('  每秒操作数: ', OpsPerSecond:0:0, ' ops/sec');
    WriteLn('  竞争率: ', WithStats.GetContentionRate:0:2, '%');
    WriteLn('  平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
    
    // 清理
    for i := 1 to THREAD_COUNT do
      Threads[i].Free;
    
    WriteLn('');
  end;
end;

begin
  WriteLn('自旋锁性能基准测试');
  WriteLn('==================');
  WriteLn('');
  
  RunSingleThreadBenchmark;
  RunMultiThreadBenchmark;
  RunStrategyComparison;
  
  WriteLn('基准测试完成！');
end.
