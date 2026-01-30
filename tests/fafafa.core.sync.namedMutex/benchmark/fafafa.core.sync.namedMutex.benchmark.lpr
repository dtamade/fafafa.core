{$CODEPAGE UTF8}
program fafafa.core.sync.namedMutex.benchmark;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, DateUtils,
  fafafa.core.sync.namedMutex;

const
  MUTEX_NAME = 'fafafa_benchmark_test';
  ITERATIONS = 10000;

type
  TBenchmarkResult = record
    TestName: string;
    Iterations: Integer;
    TotalTimeMs: Int64;
    AvgTimeUs: Double;
    OpsPerSecond: Double;
  end;

var
  LMutex: INamedMutex;

procedure PrintResult(const AResult: TBenchmarkResult);
begin
  WriteLn(Format('=== %s ===', [AResult.TestName]));
  WriteLn(Format('迭代次数: %d', [AResult.Iterations]));
  WriteLn(Format('总时间: %d ms', [AResult.TotalTimeMs]));
  WriteLn(Format('平均时间: %.2f μs', [AResult.AvgTimeUs]));
  WriteLn(Format('每秒操作数: %.0f ops/sec', [AResult.OpsPerSecond]));
  WriteLn;
end;

function BenchmarkLockUnlock: TBenchmarkResult;
var
  LStartTime, LEndTime: TDateTime;
  i: Integer;
  LGuard: INamedMutexGuard;
begin
  Result.TestName := 'Lock/Unlock 性能测试';
  Result.Iterations := ITERATIONS;
  
  WriteLn('开始 Lock/Unlock 性能测试...');
  
  LStartTime := Now;
  
  for i := 1 to ITERATIONS do
  begin
    LGuard := LMutex.Lock;
    LGuard := nil; // 立即释放
  end;
  
  LEndTime := Now;
  
  Result.TotalTimeMs := MilliSecondsBetween(LEndTime, LStartTime);
  Result.AvgTimeUs := (Result.TotalTimeMs * 1000.0) / Result.Iterations;
  Result.OpsPerSecond := Result.Iterations / (Result.TotalTimeMs / 1000.0);
end;

function BenchmarkTryLock: TBenchmarkResult;
var
  LStartTime, LEndTime: TDateTime;
  i: Integer;
  LGuard: INamedMutexGuard;
begin
  Result.TestName := 'TryLock 性能测试';
  Result.Iterations := ITERATIONS;
  
  WriteLn('开始 TryLock 性能测试...');
  
  LStartTime := Now;
  
  for i := 1 to ITERATIONS do
  begin
    LGuard := LMutex.TryLock;
    if Assigned(LGuard) then
      LGuard := nil; // 立即释放
  end;
  
  LEndTime := Now;
  
  Result.TotalTimeMs := MilliSecondsBetween(LEndTime, LStartTime);
  Result.AvgTimeUs := (Result.TotalTimeMs * 1000.0) / Result.Iterations;
  Result.OpsPerSecond := Result.Iterations / (Result.TotalTimeMs / 1000.0);
end;

function BenchmarkTryLockWithTimeout: TBenchmarkResult;
var
  LStartTime, LEndTime: TDateTime;
  i: Integer;
  LGuard: INamedMutexGuard;
begin
  Result.TestName := 'TryLockFor(100ms) 性能测试';
  Result.Iterations := 100; // 减少迭代次数，因为有超时
  
  WriteLn('开始 TryLockFor 性能测试...');
  
  LStartTime := Now;
  
  for i := 1 to Result.Iterations do
  begin
    LGuard := LMutex.TryLockFor(100);
    if Assigned(LGuard) then
      LGuard := nil; // 立即释放
  end;
  
  LEndTime := Now;
  
  Result.TotalTimeMs := MilliSecondsBetween(LEndTime, LStartTime);
  Result.AvgTimeUs := (Result.TotalTimeMs * 1000.0) / Result.Iterations;
  Result.OpsPerSecond := Result.Iterations / (Result.TotalTimeMs / 1000.0);
end;

function BenchmarkMutexCreation: TBenchmarkResult;
var
  LStartTime, LEndTime: TDateTime;
  i: Integer;
  LTempMutex: INamedMutex;
  LMutexName: string;
begin
  Result.TestName := '互斥锁创建性能测试';
  Result.Iterations := 1000; // 减少迭代次数
  
  WriteLn('开始互斥锁创建性能测试...');
  
  LStartTime := Now;
  
  for i := 1 to Result.Iterations do
  begin
    LMutexName := Format('benchmark_mutex_%d', [i]);
    LTempMutex := CreateNamedMutex(LMutexName);
    LTempMutex := nil; // 释放
  end;
  
  LEndTime := Now;
  
  Result.TotalTimeMs := MilliSecondsBetween(LEndTime, LStartTime);
  Result.AvgTimeUs := (Result.TotalTimeMs * 1000.0) / Result.Iterations;
  Result.OpsPerSecond := Result.Iterations / (Result.TotalTimeMs / 1000.0);
end;

begin
  WriteLn('=== fafafa.core.sync.namedMutex 性能基准测试 ===');
  WriteLn;
  
  try
    // 创建测试用的互斥锁
    LMutex := CreateNamedMutex(MUTEX_NAME);
    WriteLn('成功创建测试互斥锁');
    WriteLn;
    
    // 执行各种性能测试
    PrintResult(BenchmarkLockUnlock);
    PrintResult(BenchmarkTryLock);
    PrintResult(BenchmarkTryLockWithTimeout);
    PrintResult(BenchmarkMutexCreation);
    
    WriteLn('=== 性能基准测试完成 ===');
    
  except
    on E: Exception do
    begin
      WriteLn(Format('错误: %s', [E.Message]));
      ExitCode := 1;
    end;
  end;
end.
