{$CODEPAGE UTF8}
program benchmark_performance;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, DateUtils,
  fafafa.core.sync.namedEvent;

type
  TBenchmarkResult = record
    TestName: string;
    Operations: Integer;
    TotalTimeMs: Double;
    OperationsPerSecond: Double;
    AverageLatencyUs: Double;
    MinLatencyUs: Double;
    MaxLatencyUs: Double;
  end;

  TWorkerThread = class(TThread)
  private
    FEvent: INamedEvent;
    FOperations: Integer;
    FResult: TBenchmarkResult;
    FStartBarrier: INamedEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: INamedEvent; AOperations: Integer; AStartBarrier: INamedEvent);
    property Result: TBenchmarkResult read FResult;
  end;

constructor TWorkerThread.Create(AEvent: INamedEvent; AOperations: Integer; AStartBarrier: INamedEvent);
begin
  FEvent := AEvent;
  FOperations := AOperations;
  FStartBarrier := AStartBarrier;
  inherited Create(False);
end;

procedure TWorkerThread.Execute;
var
  I: Integer;
  LStartTime, LEndTime, LOpStart: TDateTime;
  LGuard: INamedEventGuard;
  LLatencies: array of Double;
  LTotalTime: Double;
begin
  SetLength(LLatencies, FOperations);
  
  // 等待开始信号
  LGuard := FStartBarrier.Wait;
  LGuard := nil;
  
  LStartTime := Now;
  
  for I := 0 to FOperations - 1 do
  begin
    LOpStart := Now;
    
    // 等待事件
    LGuard := FEvent.TryWaitFor(5000);
    if Assigned(LGuard) then
    begin
      LGuard := nil;
      LLatencies[I] := (Now - LOpStart) * 24 * 60 * 60 * 1000 * 1000; // 微秒
    end
    else
    begin
      LLatencies[I] := 5000000; // 超时，5秒 = 5,000,000微秒
    end;
  end;
  
  LEndTime := Now;
  LTotalTime := (LEndTime - LStartTime) * 24 * 60 * 60 * 1000; // 毫秒
  
  // 计算统计信息
  FResult.TestName := 'Worker-' + IntToStr(ThreadID);
  FResult.Operations := FOperations;
  FResult.TotalTimeMs := LTotalTime;
  FResult.OperationsPerSecond := FOperations / (LTotalTime / 1000);
  
  // 计算延迟统计
  FResult.AverageLatencyUs := 0;
  FResult.MinLatencyUs := LLatencies[0];
  FResult.MaxLatencyUs := LLatencies[0];
  
  for I := 0 to High(LLatencies) do
  begin
    FResult.AverageLatencyUs := FResult.AverageLatencyUs + LLatencies[I];
    if LLatencies[I] < FResult.MinLatencyUs then
      FResult.MinLatencyUs := LLatencies[I];
    if LLatencies[I] > FResult.MaxLatencyUs then
      FResult.MaxLatencyUs := LLatencies[I];
  end;
  
  FResult.AverageLatencyUs := FResult.AverageLatencyUs / Length(LLatencies);
end;

function BenchmarkSingleThreaded(AOperations: Integer): TBenchmarkResult;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  I: Integer;
  LStartTime, LEndTime, LOpStart: TDateTime;
  LLatencies: array of Double;
  LTotalTime: Double;
begin
  WriteLn('运行单线程基准测试 (', AOperations, ' 次操作)...');
  
  LEvent := MakeAutoResetNamedEvent('SingleThreadBench', False);
  SetLength(LLatencies, AOperations);
  
  LStartTime := Now;
  
  for I := 0 to AOperations - 1 do
  begin
    LOpStart := Now;
    
    // 触发事件
    LEvent.SetEvent;
    
    // 立即等待
    LGuard := LEvent.TryWait;
    if Assigned(LGuard) then
    begin
      LGuard := nil;
      LLatencies[I] := (Now - LOpStart) * 24 * 60 * 60 * 1000 * 1000; // 微秒
    end
    else
    begin
      LLatencies[I] := 1000000; // 1秒超时
    end;
  end;
  
  LEndTime := Now;
  LTotalTime := (LEndTime - LStartTime) * 24 * 60 * 60 * 1000; // 毫秒
  
  // 计算统计信息
  Result.TestName := 'SingleThreaded';
  Result.Operations := AOperations;
  Result.TotalTimeMs := LTotalTime;
  Result.OperationsPerSecond := AOperations / (LTotalTime / 1000);
  
  // 计算延迟统计
  Result.AverageLatencyUs := 0;
  Result.MinLatencyUs := LLatencies[0];
  Result.MaxLatencyUs := LLatencies[0];
  
  for I := 0 to High(LLatencies) do
  begin
    Result.AverageLatencyUs := Result.AverageLatencyUs + LLatencies[I];
    if LLatencies[I] < Result.MinLatencyUs then
      Result.MinLatencyUs := LLatencies[I];
    if LLatencies[I] > Result.MaxLatencyUs then
      Result.MaxLatencyUs := LLatencies[I];
  end;
  
  Result.AverageLatencyUs := Result.AverageLatencyUs / Length(LLatencies);
  
  WriteLn('✓ 单线程测试完成');
end;

function BenchmarkMultiThreaded(AThreadCount, AOperationsPerThread: Integer): TBenchmarkResult;
var
  LEvent: INamedEvent;
  LStartBarrier: INamedEvent;
  LThreads: array of TWorkerThread;
  I: Integer;
  LStartTime, LEndTime: TDateTime;
  LTotalOperations: Integer;
  LTotalTime: Double;
  LTotalOpsPerSec: Double;
  LAvgLatency, LMinLatency, LMaxLatency: Double;
begin
  WriteLn('运行多线程基准测试 (', AThreadCount, ' 线程, 每线程 ', AOperationsPerThread, ' 次操作)...');
  
  LEvent := MakeManualResetNamedEvent('MultiThreadBench', False);
  LStartBarrier := MakeManualResetNamedEvent('StartBarrier', False);
  
  SetLength(LThreads, AThreadCount);
  
  // 创建工作线程
  for I := 0 to AThreadCount - 1 do
  begin
    LThreads[I] := TWorkerThread.Create(LEvent, AOperationsPerThread, LStartBarrier);
  end;
  
  Sleep(100); // 让线程准备好
  
  LStartTime := Now;
  
  // 启动所有线程
  LStartBarrier.SetEvent;
  
  // 定期触发事件
  for I := 1 to AOperationsPerThread * 2 do
  begin
    LEvent.SetEvent;
    Sleep(1); // 1ms间隔
    LEvent.ResetEvent;
  end;
  
  // 等待所有线程完成
  for I := 0 to AThreadCount - 1 do
  begin
    LThreads[I].WaitFor;
  end;
  
  LEndTime := Now;
  LTotalTime := (LEndTime - LStartTime) * 24 * 60 * 60 * 1000; // 毫秒
  
  // 聚合结果
  LTotalOperations := 0;
  LTotalOpsPerSec := 0;
  LAvgLatency := 0;
  LMinLatency := LThreads[0].Result.MinLatencyUs;
  LMaxLatency := LThreads[0].Result.MaxLatencyUs;
  
  for I := 0 to AThreadCount - 1 do
  begin
    LTotalOperations := LTotalOperations + LThreads[I].Result.Operations;
    LTotalOpsPerSec := LTotalOpsPerSec + LThreads[I].Result.OperationsPerSecond;
    LAvgLatency := LAvgLatency + LThreads[I].Result.AverageLatencyUs;
    
    if LThreads[I].Result.MinLatencyUs < LMinLatency then
      LMinLatency := LThreads[I].Result.MinLatencyUs;
    if LThreads[I].Result.MaxLatencyUs > LMaxLatency then
      LMaxLatency := LThreads[I].Result.MaxLatencyUs;
      
    LThreads[I].Free;
  end;
  
  Result.TestName := Format('MultiThreaded-%dT', [AThreadCount]);
  Result.Operations := LTotalOperations;
  Result.TotalTimeMs := LTotalTime;
  Result.OperationsPerSecond := LTotalOpsPerSec;
  Result.AverageLatencyUs := LAvgLatency / AThreadCount;
  Result.MinLatencyUs := LMinLatency;
  Result.MaxLatencyUs := LMaxLatency;
  
  WriteLn('✓ 多线程测试完成');
end;

procedure PrintResult(const AResult: TBenchmarkResult);
begin
  WriteLn('========================================');
  WriteLn('测试名称: ', AResult.TestName);
  WriteLn('总操作数: ', AResult.Operations);
  WriteLn('总耗时: ', FormatFloat('0.00', AResult.TotalTimeMs), ' ms');
  WriteLn('吞吐量: ', FormatFloat('0.00', AResult.OperationsPerSecond), ' ops/sec');
  WriteLn('平均延迟: ', FormatFloat('0.00', AResult.AverageLatencyUs), ' μs');
  WriteLn('最小延迟: ', FormatFloat('0.00', AResult.MinLatencyUs), ' μs');
  WriteLn('最大延迟: ', FormatFloat('0.00', AResult.MaxLatencyUs), ' μs');
  WriteLn('========================================');
  WriteLn;
end;

procedure RunBenchmarks;
var
  LResult: TBenchmarkResult;
begin
  WriteLn('fafafa.core.sync.namedEvent 性能基准测试');
  WriteLn('==========================================');
  WriteLn;
  
  // 单线程基准测试
  LResult := BenchmarkSingleThreaded(10000);
  PrintResult(LResult);
  
  // 多线程基准测试
  LResult := BenchmarkMultiThreaded(2, 5000);
  PrintResult(LResult);
  
  LResult := BenchmarkMultiThreaded(4, 2500);
  PrintResult(LResult);
  
  LResult := BenchmarkMultiThreaded(8, 1250);
  PrintResult(LResult);
  
  WriteLn('🎉 所有基准测试完成！');
end;

begin
  try
    RunBenchmarks;
  except
    on E: Exception do
    begin
      WriteLn('❌ 基准测试出错: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
