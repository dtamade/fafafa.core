program benchmark_rwlock;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, DateUtils,
  fafafa.core.sync.rwlock;

type
  TBenchmarkResult = record
    OperationCount: Int64;
    ElapsedMs: Int64;
    OpsPerSec: Double;
  end;

  TBenchmarkThread = class(TThread)
  private
    FRWLock: IRWLock;
    FOperationCount: Integer;
    FResult: TBenchmarkResult;
    FIsReader: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; AOperationCount: Integer; AIsReader: Boolean);
    property Result: TBenchmarkResult read FResult;
  end;

{ TBenchmarkThread }

constructor TBenchmarkThread.Create(ARWLock: IRWLock; AOperationCount: Integer; AIsReader: Boolean);
begin
  inherited Create(False);
  FRWLock := ARWLock;
  FOperationCount := AOperationCount;
  FIsReader := AIsReader;
  FreeOnTerminate := False;
end;

procedure TBenchmarkThread.Execute;
var
  i: Integer;
  StartTime, EndTime: TDateTime;
  SharedValue: Integer;
begin
  SharedValue := 0;
  StartTime := Now;
  
  if FIsReader then
  begin
    // 读操作基准测试
    for i := 1 to FOperationCount do
    begin
      FRWLock.AcquireRead;
      try
        // 模拟读操作
        Inc(SharedValue, 0);
      finally
        FRWLock.ReleaseRead;
      end;
    end;
  end
  else
  begin
    // 写操作基准测试
    for i := 1 to FOperationCount do
    begin
      FRWLock.AcquireWrite;
      try
        // 模拟写操作
        Inc(SharedValue);
      finally
        FRWLock.ReleaseWrite;
      end;
    end;
  end;
  
  EndTime := Now;
  
  FResult.OperationCount := FOperationCount;
  FResult.ElapsedMs := MilliSecondsBetween(EndTime, StartTime);
  if FResult.ElapsedMs > 0 then
    FResult.OpsPerSec := (FOperationCount * 1000.0) / FResult.ElapsedMs
  else
    FResult.OpsPerSec := 0;
end;

// 单线程读锁基准测试
function BenchmarkSingleThreadRead(AOperationCount: Integer): TBenchmarkResult;
var
  RWLock: IRWLock;
  Thread: TBenchmarkThread;
begin
  WriteLn('=== 单线程读锁基准测试 ===');
  WriteLn('操作次数: ', AOperationCount);
  
  RWLock := MakeRWLock;
  Thread := TBenchmarkThread.Create(RWLock, AOperationCount, True);
  try
    Thread.WaitFor;
    Result := Thread.Result;
  finally
    Thread.Free;
  end;
  
  WriteLn('耗时: ', Result.ElapsedMs, ' ms');
  WriteLn('性能: ', Result.OpsPerSec:0:0, ' ops/sec');
  WriteLn;
end;

// 单线程写锁基准测试
function BenchmarkSingleThreadWrite(AOperationCount: Integer): TBenchmarkResult;
var
  RWLock: IRWLock;
  Thread: TBenchmarkThread;
begin
  WriteLn('=== 单线程写锁基准测试 ===');
  WriteLn('操作次数: ', AOperationCount);
  
  RWLock := MakeRWLock;
  Thread := TBenchmarkThread.Create(RWLock, AOperationCount, False);
  try
    Thread.WaitFor;
    Result := Thread.Result;
  finally
    Thread.Free;
  end;
  
  WriteLn('耗时: ', Result.ElapsedMs, ' ms');
  WriteLn('性能: ', Result.OpsPerSec:0:0, ' ops/sec');
  WriteLn;
end;

// 多线程读锁基准测试
function BenchmarkMultiThreadRead(AThreadCount, AOperationsPerThread: Integer): TBenchmarkResult;
var
  RWLock: IRWLock;
  Threads: array of TBenchmarkThread;
  i: Integer;
  StartTime, EndTime: TDateTime;
  TotalOps: Int64;
  TotalElapsed: Int64;
begin
  WriteLn('=== 多线程读锁基准测试 ===');
  WriteLn('线程数: ', AThreadCount);
  WriteLn('每线程操作数: ', AOperationsPerThread);
  
  RWLock := MakeRWLock;
  SetLength(Threads, AThreadCount);
  
  StartTime := Now;
  
  // 启动所有线程
  for i := 0 to AThreadCount - 1 do
    Threads[i] := TBenchmarkThread.Create(RWLock, AOperationsPerThread, True);
  
  // 等待所有线程完成
  for i := 0 to AThreadCount - 1 do
    Threads[i].WaitFor;
  
  EndTime := Now;
  
  // 计算总体性能
  TotalOps := Int64(AThreadCount) * AOperationsPerThread;
  TotalElapsed := MilliSecondsBetween(EndTime, StartTime);
  
  Result.OperationCount := TotalOps;
  Result.ElapsedMs := TotalElapsed;
  if TotalElapsed > 0 then
    Result.OpsPerSec := (TotalOps * 1000.0) / TotalElapsed
  else
    Result.OpsPerSec := 0;
  
  // 清理
  for i := 0 to AThreadCount - 1 do
    Threads[i].Free;
  
  WriteLn('总操作数: ', TotalOps);
  WriteLn('总耗时: ', TotalElapsed, ' ms');
  WriteLn('总性能: ', Result.OpsPerSec:0:0, ' ops/sec');
  WriteLn;
end;

// 混合读写基准测试
function BenchmarkMixedReadWrite(AReaderCount, AWriterCount, AOperationsPerThread: Integer): TBenchmarkResult;
var
  RWLock: IRWLock;
  Threads: array of TBenchmarkThread;
  i: Integer;
  StartTime, EndTime: TDateTime;
  TotalOps: Int64;
  TotalElapsed: Int64;
  ThreadCount: Integer;
begin
  WriteLn('=== 混合读写基准测试 ===');
  WriteLn('读者线程数: ', AReaderCount);
  WriteLn('写者线程数: ', AWriterCount);
  WriteLn('每线程操作数: ', AOperationsPerThread);
  
  ThreadCount := AReaderCount + AWriterCount;
  RWLock := MakeRWLock;
  SetLength(Threads, ThreadCount);
  
  StartTime := Now;
  
  // 启动读者线程
  for i := 0 to AReaderCount - 1 do
    Threads[i] := TBenchmarkThread.Create(RWLock, AOperationsPerThread, True);
  
  // 启动写者线程
  for i := AReaderCount to ThreadCount - 1 do
    Threads[i] := TBenchmarkThread.Create(RWLock, AOperationsPerThread, False);
  
  // 等待所有线程完成
  for i := 0 to ThreadCount - 1 do
    Threads[i].WaitFor;
  
  EndTime := Now;
  
  // 计算总体性能
  TotalOps := Int64(ThreadCount) * AOperationsPerThread;
  TotalElapsed := MilliSecondsBetween(EndTime, StartTime);
  
  Result.OperationCount := TotalOps;
  Result.ElapsedMs := TotalElapsed;
  if TotalElapsed > 0 then
    Result.OpsPerSec := (TotalOps * 1000.0) / TotalElapsed
  else
    Result.OpsPerSec := 0;
  
  // 清理
  for i := 0 to ThreadCount - 1 do
    Threads[i].Free;
  
  WriteLn('总操作数: ', TotalOps);
  WriteLn('总耗时: ', TotalElapsed, ' ms');
  WriteLn('总性能: ', Result.OpsPerSec:0:0, ' ops/sec');
  WriteLn('读写比例: ', AReaderCount, ':', AWriterCount);
  WriteLn;
end;

var
  SingleReadResult, SingleWriteResult: TBenchmarkResult;
  MultiReadResult, MixedResult: TBenchmarkResult;

begin
  WriteLn('fafafa.core.sync.rwlock 性能基准测试');
  WriteLn('=====================================');
  WriteLn;
  
  // 单线程基准测试
  SingleReadResult := BenchmarkSingleThreadRead(1000000);
  SingleWriteResult := BenchmarkSingleThreadWrite(500000);
  
  // 多线程基准测试
  MultiReadResult := BenchmarkMultiThreadRead(4, 250000);
  MixedResult := BenchmarkMixedReadWrite(6, 2, 100000);
  
  // 总结报告
  WriteLn('=== 性能总结 ===');
  WriteLn('单线程读锁: ', SingleReadResult.OpsPerSec:0:0, ' ops/sec');
  WriteLn('单线程写锁: ', SingleWriteResult.OpsPerSec:0:0, ' ops/sec');
  WriteLn('多线程读锁: ', MultiReadResult.OpsPerSec:0:0, ' ops/sec');
  WriteLn('混合读写: ', MixedResult.OpsPerSec:0:0, ' ops/sec');
  WriteLn;
  
  // 与声称性能对比
  WriteLn('=== 与声称性能对比 ===');
  WriteLn('声称读锁性能: 4,000,000 ops/sec');
  WriteLn('实际读锁性能: ', SingleReadResult.OpsPerSec:0:0, ' ops/sec');
  WriteLn('达成率: ', (SingleReadResult.OpsPerSec / 4000000 * 100):0:1, '%');
  WriteLn;
  WriteLn('声称写锁性能: 4,000,000 ops/sec');
  WriteLn('实际写锁性能: ', SingleWriteResult.OpsPerSec:0:0, ' ops/sec');
  WriteLn('达成率: ', (SingleWriteResult.OpsPerSec / 4000000 * 100):0:1, '%');
  WriteLn;
  
  WriteLn('基准测试完成！');
end.
