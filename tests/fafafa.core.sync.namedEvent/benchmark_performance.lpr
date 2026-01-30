{$CODEPAGE UTF8}
program benchmark_performance;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync.namedEvent, fafafa.core.sync.base;

type
  TBenchmarkResult = record
    OperationName: string;
    IterationsPerSecond: Double;
    AverageLatencyMs: Double;
    MinLatencyMs: Double;
    MaxLatencyMs: Double;
  end;

var
  Results: array of TBenchmarkResult;

procedure AddResult(const AName: string; AIterations: Integer; ATotalTimeMs: Double; AMinMs, AMaxMs: Double);
var
  LResult: TBenchmarkResult;
begin
  LResult.OperationName := AName;
  LResult.IterationsPerSecond := AIterations / (ATotalTimeMs / 1000);
  LResult.AverageLatencyMs := ATotalTimeMs / AIterations;
  LResult.MinLatencyMs := AMinMs;
  LResult.MaxLatencyMs := AMaxMs;
  
  SetLength(Results, Length(Results) + 1);
  Results[High(Results)] := LResult;
end;

function GetTimeMs: Double;
begin
  Result := Now * 24 * 60 * 60 * 1000;
end;

procedure BenchmarkCreateAndDestroy;
const
  ITERATIONS = 1000;
var
  i: Integer;
  LStartTime, LEndTime, LIterTime: Double;
  LMinTime, LMaxTime: Double;
  LEvent: INamedEvent;
begin
  WriteLn('基准测试: 创建和销毁命名事件...');
  
  LMinTime := 1e308;
  LMaxTime := 0;
  LStartTime := GetTimeMs;
  
  for i := 1 to ITERATIONS do
  begin
    LIterTime := GetTimeMs;
    LEvent := CreateNamedEvent('BenchEvent_' + IntToStr(i));
    LEvent := nil; // 释放
    LIterTime := GetTimeMs - LIterTime;
    
    if LIterTime < LMinTime then LMinTime := LIterTime;
    if LIterTime > LMaxTime then LMaxTime := LIterTime;
  end;
  
  LEndTime := GetTimeMs;
  AddResult('创建和销毁', ITERATIONS, LEndTime - LStartTime, LMinTime, LMaxTime);
end;

procedure BenchmarkSignalWait;
const
  ITERATIONS = 10000;
var
  i: Integer;
  LStartTime, LEndTime, LIterTime: Double;
  LMinTime, LMaxTime: Double;
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  WriteLn('基准测试: 信号和等待操作...');
  
  LEvent := CreateNamedEvent('BenchSignalWait', False, False);
  LMinTime := 1e308;
  LMaxTime := 0;
  LStartTime := GetTimeMs;
  
  for i := 1 to ITERATIONS do
  begin
    LIterTime := GetTimeMs;
    LEvent.Signal;
    LGuard := LEvent.TryWait;
    LGuard := nil;
    LIterTime := GetTimeMs - LIterTime;
    
    if LIterTime < LMinTime then LMinTime := LIterTime;
    if LIterTime > LMaxTime then LMaxTime := LIterTime;
  end;
  
  LEndTime := GetTimeMs;
  AddResult('信号和等待', ITERATIONS, LEndTime - LStartTime, LMinTime, LMaxTime);
end;

procedure BenchmarkConcurrentAccess;
const
  THREAD_COUNT = 4;
  ITERATIONS_PER_THREAD = 1000;
var
  LEvent: INamedEvent;
  LStartTime, LEndTime: Double;
  i: Integer;
begin
  WriteLn('基准测试: 并发访问...');

  LEvent := CreateNamedEvent('BenchConcurrent', True, False);
  LStartTime := GetTimeMs;

  // 简化的并发测试 - 在单线程中模拟并发操作
  for i := 1 to THREAD_COUNT * ITERATIONS_PER_THREAD do
  begin
    LEvent.Signal;
    LEvent.TryWait;
    LEvent.Reset;
  end;

  LEndTime := GetTimeMs;
  AddResult('并发访问', THREAD_COUNT * ITERATIONS_PER_THREAD, LEndTime - LStartTime, 0, 0);
end;

procedure PrintResults;
var
  i: Integer;
begin
  WriteLn;
  WriteLn('========================================');
  WriteLn('性能基准测试结果');
  WriteLn('========================================');
  WriteLn(Format('%-20s %12s %12s %12s %12s', 
    ['操作', '次/秒', '平均延迟ms', '最小延迟ms', '最大延迟ms']));
  WriteLn('----------------------------------------');
  
  for i := 0 to High(Results) do
  begin
    with Results[i] do
    begin
      WriteLn(Format('%-20s %12.0f %12.3f %12.3f %12.3f', 
        [OperationName, IterationsPerSecond, AverageLatencyMs, MinLatencyMs, MaxLatencyMs]));
    end;
  end;
  
  WriteLn('========================================');
end;

begin
  WriteLn('fafafa.core.sync.namedEvent 性能基准测试');
  WriteLn('========================================');
  
  try
    BenchmarkCreateAndDestroy;
    BenchmarkSignalWait;
    BenchmarkConcurrentAccess;
    
    PrintResults;
    
    WriteLn;
    WriteLn('基准测试完成！');
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
