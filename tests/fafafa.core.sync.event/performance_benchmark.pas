program performance_benchmark;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, DateUtils,
  fafafa.core.sync.event;

type
  { 性能基准测试套件 }
  TPerformanceBenchmark = class
  private
    FEvent: IEvent;
    FIterations: Integer;
    FThreadCount: Integer;
    
    procedure BenchmarkSetReset;
    procedure BenchmarkTryWait;
    procedure BenchmarkIsSignaled;
    procedure BenchmarkConcurrentWait;
    procedure BenchmarkInterrupt;
    
    function GetTimestamp: Int64;
    procedure PrintResult(const TestName: string; StartTime, EndTime: Int64; Operations: Integer);
  public
    constructor Create(AIterations: Integer = 1000000; AThreadCount: Integer = 4);
    procedure RunAllBenchmarks;
  end;

{ 并发等待测试线程 }
type
  TConcurrentWaitThread = class(TThread)
  private
    FEvent: IEvent;
    FIterations: Integer;
    FSuccessCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; AIterations: Integer);
    property SuccessCount: Integer read FSuccessCount;
  end;

{ TPerformanceBenchmark }

constructor TPerformanceBenchmark.Create(AIterations: Integer; AThreadCount: Integer);
begin
  inherited Create;
  FIterations := AIterations;
  FThreadCount := AThreadCount;
end;

function TPerformanceBenchmark.GetTimestamp: Int64;
begin
  Result := GetTickCount64;
end;

procedure TPerformanceBenchmark.PrintResult(const TestName: string; StartTime, EndTime: Int64; Operations: Integer);
var
  ElapsedMs: Int64;
  OpsPerSec: Double;
begin
  ElapsedMs := EndTime - StartTime;
  if ElapsedMs > 0 then
    OpsPerSec := (Operations * 1000.0) / ElapsedMs
  else
    OpsPerSec := 0;
    
  WriteLn(Format('%-25s: %6d ms, %10.0f ops/sec, %8.2f ns/op', 
    [TestName, ElapsedMs, OpsPerSec, (ElapsedMs * 1000000.0) / Operations]));
end;

procedure TPerformanceBenchmark.BenchmarkSetReset;
var
  StartTime, EndTime: Int64;
  i: Integer;
begin
  FEvent := CreateEvent(True, False); // 手动重置事件
  
  StartTime := GetTimestamp;
  for i := 1 to FIterations do
  begin
    FEvent.SetEvent;
    FEvent.ResetEvent;
  end;
  EndTime := GetTimestamp;
  
  PrintResult('SetEvent/ResetEvent', StartTime, EndTime, FIterations * 2);
  FEvent := nil;
end;

procedure TPerformanceBenchmark.BenchmarkTryWait;
var
  StartTime, EndTime: Int64;
  i: Integer;
begin
  FEvent := CreateEvent(True, True); // 手动重置事件，初始信号状态
  
  StartTime := GetTimestamp;
  for i := 1 to FIterations do
  begin
    FEvent.TryWait;
  end;
  EndTime := GetTimestamp;
  
  PrintResult('TryWait (signaled)', StartTime, EndTime, FIterations);
  
  // 测试未信号状态
  FEvent.ResetEvent;
  StartTime := GetTimestamp;
  for i := 1 to FIterations do
  begin
    FEvent.TryWait;
  end;
  EndTime := GetTimestamp;
  
  PrintResult('TryWait (not signaled)', StartTime, EndTime, FIterations);
  FEvent := nil;
end;

procedure TPerformanceBenchmark.BenchmarkIsSignaled;
var
  StartTime, EndTime: Int64;
  i: Integer;
begin
  FEvent := CreateEvent(True, True); // 手动重置事件，初始信号状态
  
  StartTime := GetTimestamp;
  for i := 1 to FIterations do
  begin
    FEvent.IsSignaled;
  end;
  EndTime := GetTimestamp;
  
  PrintResult('IsSignaled (signaled)', StartTime, EndTime, FIterations);
  
  // 测试未信号状态
  FEvent.ResetEvent;
  StartTime := GetTimestamp;
  for i := 1 to FIterations do
  begin
    FEvent.IsSignaled;
  end;
  EndTime := GetTimestamp;
  
  PrintResult('IsSignaled (not signaled)', StartTime, EndTime, FIterations);
  FEvent := nil;
end;

procedure TPerformanceBenchmark.BenchmarkConcurrentWait;
var
  StartTime, EndTime: Int64;
  Threads: array of TConcurrentWaitThread;
  i: Integer;
  TotalSuccess: Integer;
begin
  FEvent := CreateEvent(False, False); // 自动重置事件
  SetLength(Threads, FThreadCount);
  
  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TConcurrentWaitThread.Create(FEvent, FIterations div FThreadCount);
    Threads[i].Start;
  end;
  
  StartTime := GetTimestamp;
  
  // 发送信号
  for i := 1 to FIterations do
  begin
    FEvent.SetEvent;
    if i mod 1000 = 0 then
      Sleep(1); // 偶尔让出CPU
  end;
  
  // 等待所有线程完成
  TotalSuccess := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Inc(TotalSuccess, Threads[i].SuccessCount);
    Threads[i].Free;
  end;
  
  EndTime := GetTimestamp;
  
  PrintResult('Concurrent Wait', StartTime, EndTime, TotalSuccess);
  WriteLn(Format('  Success rate: %.1f%% (%d/%d)', 
    [(TotalSuccess * 100.0) / FIterations, TotalSuccess, FIterations]));
    
  FEvent := nil;
end;

procedure TPerformanceBenchmark.BenchmarkInterrupt;
var
  StartTime, EndTime: Int64;
  i: Integer;
begin
  FEvent := CreateEvent(True, False); // 手动重置事件
  
  StartTime := GetTimestamp;
  for i := 1 to FIterations do
  begin
    FEvent.Interrupt;
    FEvent := CreateEvent(True, False); // 重新创建以重置中断状态
  end;
  EndTime := GetTimestamp;
  
  PrintResult('Interrupt', StartTime, EndTime, FIterations);
  FEvent := nil;
end;

procedure TPerformanceBenchmark.RunAllBenchmarks;
begin
  WriteLn('=== fafafa.core.sync.event 性能基准测试 ===');
  WriteLn(Format('迭代次数: %d, 线程数: %d', [FIterations, FThreadCount]));
  WriteLn;
  
  BenchmarkSetReset;
  BenchmarkTryWait;
  BenchmarkIsSignaled;
  BenchmarkConcurrentWait;
  BenchmarkInterrupt;
  
  WriteLn;
  WriteLn('基准测试完成');
end;

{ TConcurrentWaitThread }

constructor TConcurrentWaitThread.Create(AEvent: IEvent; AIterations: Integer);
begin
  inherited Create(False);
  FEvent := AEvent;
  FIterations := AIterations;
  FSuccessCount := 0;
end;

procedure TConcurrentWaitThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    if FEvent.WaitFor(100) = wrSignaled then
      Inc(FSuccessCount);
  end;
end;

{ 主程序 }
var
  Benchmark: TPerformanceBenchmark;
begin
  try
    Benchmark := TPerformanceBenchmark.Create(100000, 4);
    try
      Benchmark.RunAllBenchmarks;
    finally
      Benchmark.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
