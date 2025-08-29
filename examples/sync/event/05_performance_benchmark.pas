program PerformanceBenchmark;

{$mode objfpc}{$H+}

{
  性能基准测试示例
  
  本示例演示：
  1. 事件操作的性能测试
  2. 不同场景下的性能对比
  3. 并发性能测试
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 性能测试结果 }
  TBenchmarkResult = record
    TestName: string;
    Operations: Integer;
    ElapsedTime: QWord;  // 毫秒
    OperationsPerSecond: Double;
    AverageTimePerOperation: Double; // 微秒
  end;

  { 并发测试线程 }
  TConcurrentTestThread = class(TThread)
  private
    FEvent: IEvent;
    FOperations: Integer;
    FOperationsCompleted: Integer;
    FTestType: Integer; // 0=SetEvent, 1=WaitFor, 2=Mixed
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; AOperations, ATestType: Integer);
    property OperationsCompleted: Integer read FOperationsCompleted;
  end;

function RunBenchmark(const ATestName: string; AOperations: Integer; ATestProc: TProcedure): TBenchmarkResult;
var
  StartTime, EndTime: QWord;
begin
  Result.TestName := ATestName;
  Result.Operations := AOperations;
  
  WriteLn('运行测试：', ATestName, ' (', AOperations, ' 次操作)');
  
  StartTime := GetTickCount64;
  ATestProc();
  EndTime := GetTickCount64;
  
  Result.ElapsedTime := EndTime - StartTime;
  Result.OperationsPerSecond := (AOperations * 1000.0) / Result.ElapsedTime;
  Result.AverageTimePerOperation := (Result.ElapsedTime * 1000.0) / AOperations;
  
  WriteLn('  耗时：', Result.ElapsedTime, ' ms');
  WriteLn('  每秒操作数：', Result.OperationsPerSecond:0:0);
  WriteLn('  平均每次操作：', Result.AverageTimePerOperation:0:2, ' μs');
  WriteLn;
end;

procedure PrintBenchmarkResult(const AResult: TBenchmarkResult);
begin
  WriteLn(Format('%-30s %8d %8d %12.0f %10.2f', 
    [AResult.TestName, AResult.Operations, AResult.ElapsedTime, 
     AResult.OperationsPerSecond, AResult.AverageTimePerOperation]));
end;

{ TConcurrentTestThread }
constructor TConcurrentTestThread.Create(AEvent: IEvent; AOperations, ATestType: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FEvent := AEvent;
  FOperations := AOperations;
  FTestType := ATestType;
  FOperationsCompleted := 0;
end;

procedure TConcurrentTestThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FOperations do
  begin
    if Terminated then Break;
    
    case FTestType of
      0: begin // SetEvent
        FEvent.SetEvent;
        Inc(FOperationsCompleted);
      end;
      1: begin // WaitFor
        FEvent.WaitFor(0);
        Inc(FOperationsCompleted);
      end;
      2: begin // Mixed
        if i mod 2 = 0 then
          FEvent.SetEvent
        else
          FEvent.WaitFor(0);
        Inc(FOperationsCompleted);
      end;
    end;
  end;
end;

procedure BenchmarkBasicOperations;
const
  OperationCount = 100000;
var
  Event: IEvent;
  Results: array[0..7] of TBenchmarkResult;
  i: Integer;
begin
  WriteLn('=== 基础操作性能测试 ===');
  
  // 自动重置事件测试
  Event := CreateEvent(False, False);
  
  Results[0] := RunBenchmark('自动重置-SetEvent', OperationCount, procedure
  var i: Integer;
  begin
    for i := 1 to OperationCount do
      Event.SetEvent;
  end);
  
  Results[1] := RunBenchmark('自动重置-ResetEvent', OperationCount, procedure
  var i: Integer;
  begin
    for i := 1 to OperationCount do
      Event.ResetEvent;
  end);
  
  Event.SetEvent; // 确保处于信号状态
  Results[2] := RunBenchmark('自动重置-WaitFor(0)', OperationCount, procedure
  var i: Integer;
  begin
    for i := 1 to OperationCount do
    begin
      Event.SetEvent; // 每次都要重新设置，因为是自动重置
      Event.WaitFor(0);
    end;
  end);
  
  Results[3] := RunBenchmark('自动重置-IsSignaled', OperationCount, procedure
  var i: Integer;
  begin
    for i := 1 to OperationCount do
      Event.IsSignaled;
  end);
  
  // 手动重置事件测试
  Event := CreateEvent(True, False);
  
  Results[4] := RunBenchmark('手动重置-SetEvent', OperationCount, procedure
  var i: Integer;
  begin
    for i := 1 to OperationCount do
      Event.SetEvent;
  end);
  
  Results[5] := RunBenchmark('手动重置-ResetEvent', OperationCount, procedure
  var i: Integer;
  begin
    for i := 1 to OperationCount do
      Event.ResetEvent;
  end);
  
  Event.SetEvent; // 确保处于信号状态
  Results[6] := RunBenchmark('手动重置-WaitFor(0)', OperationCount, procedure
  var i: Integer;
  begin
    for i := 1 to OperationCount do
      Event.WaitFor(0);
  end);
  
  Results[7] := RunBenchmark('手动重置-IsSignaled', OperationCount, procedure
  var i: Integer;
  begin
    for i := 1 to OperationCount do
      Event.IsSignaled;
  end);
  
  // 输出汇总表格
  WriteLn('基础操作性能汇总：');
  WriteLn(Format('%-30s %8s %8s %12s %10s', 
    ['测试名称', '操作数', '耗时(ms)', '操作/秒', '平均(μs)']));
  WriteLn(StringOfChar('-', 70));
  
  for i := 0 to 7 do
    PrintBenchmarkResult(Results[i]);
    
  WriteLn;
end;

procedure BenchmarkConcurrentOperations;
const
  ThreadCount = 4;
  OperationsPerThread = 25000;
var
  Event: IEvent;
  Threads: array[0..ThreadCount-1] of TConcurrentTestThread;
  i: Integer;
  StartTime, EndTime: QWord;
  TotalOperations: Integer;
  Result: TBenchmarkResult;
begin
  WriteLn('=== 并发操作性能测试 ===');
  WriteLn('线程数：', ThreadCount);
  WriteLn('每线程操作数：', OperationsPerThread);
  
  // 测试并发 SetEvent
  Event := CreateEvent(True, False);
  
  WriteLn('测试并发 SetEvent...');
  StartTime := GetTickCount64;
  
  for i := 0 to ThreadCount - 1 do
  begin
    Threads[i] := TConcurrentTestThread.Create(Event, OperationsPerThread, 0);
    Threads[i].Start;
  end;
  
  TotalOperations := 0;
  for i := 0 to ThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    TotalOperations := TotalOperations + Threads[i].OperationsCompleted;
    Threads[i].Free;
  end;
  
  EndTime := GetTickCount64;
  
  Result.TestName := '并发SetEvent';
  Result.Operations := TotalOperations;
  Result.ElapsedTime := EndTime - StartTime;
  Result.OperationsPerSecond := (TotalOperations * 1000.0) / Result.ElapsedTime;
  Result.AverageTimePerOperation := (Result.ElapsedTime * 1000.0) / TotalOperations;
  
  WriteLn('并发SetEvent结果：');
  WriteLn('  总操作数：', TotalOperations);
  WriteLn('  总耗时：', Result.ElapsedTime, ' ms');
  WriteLn('  每秒操作数：', Result.OperationsPerSecond:0:0);
  WriteLn('  平均每次操作：', Result.AverageTimePerOperation:0:2, ' μs');
  WriteLn;
  
  // 测试并发 WaitFor
  Event := CreateEvent(True, True); // 设置为信号状态
  
  WriteLn('测试并发 WaitFor...');
  StartTime := GetTickCount64;
  
  for i := 0 to ThreadCount - 1 do
  begin
    Threads[i] := TConcurrentTestThread.Create(Event, OperationsPerThread, 1);
    Threads[i].Start;
  end;
  
  TotalOperations := 0;
  for i := 0 to ThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    TotalOperations := TotalOperations + Threads[i].OperationsCompleted;
    Threads[i].Free;
  end;
  
  EndTime := GetTickCount64;
  
  WriteLn('并发WaitFor结果：');
  WriteLn('  总操作数：', TotalOperations);
  WriteLn('  总耗时：', EndTime - StartTime, ' ms');
  WriteLn('  每秒操作数：', (TotalOperations * 1000.0) / (EndTime - StartTime):0:0);
  WriteLn('  平均每次操作：', ((EndTime - StartTime) * 1000.0) / TotalOperations:0:2, ' μs');
  WriteLn;
end;

procedure BenchmarkMemoryUsage;
const
  EventCount = 10000;
var
  Events: array of IEvent;
  i: Integer;
  StartTime, EndTime: QWord;
begin
  WriteLn('=== 内存使用测试 ===');
  WriteLn('创建事件数量：', EventCount);
  
  SetLength(Events, EventCount);
  
  WriteLn('创建', EventCount, '个事件...');
  StartTime := GetTickCount64;
  
  for i := 0 to EventCount - 1 do
    Events[i] := CreateEvent(i mod 2 = 0, i mod 3 = 0);
    
  EndTime := GetTickCount64;
  
  WriteLn('创建完成，耗时：', EndTime - StartTime, ' ms');
  WriteLn('平均创建时间：', ((EndTime - StartTime) * 1000.0) / EventCount:0:2, ' μs/事件');
  
  // 测试操作性能
  WriteLn('测试批量操作...');
  StartTime := GetTickCount64;
  
  for i := 0 to EventCount - 1 do
  begin
    Events[i].SetEvent;
    Events[i].IsSignaled;
    Events[i].ResetEvent;
  end;
  
  EndTime := GetTickCount64;
  
  WriteLn('批量操作完成，耗时：', EndTime - StartTime, ' ms');
  WriteLn('平均操作时间：', ((EndTime - StartTime) * 1000.0) / (EventCount * 3):0:2, ' μs/操作');
  
  // 清理
  WriteLn('清理事件...');
  StartTime := GetTickCount64;
  
  for i := 0 to EventCount - 1 do
    Events[i] := nil;
    
  EndTime := GetTickCount64;
  
  WriteLn('清理完成，耗时：', EndTime - StartTime, ' ms');
  WriteLn;
end;

begin
  WriteLn('fafafa.core 事件同步原语 - 性能基准测试');
  WriteLn('============================================');
  WriteLn;
  
  try
    BenchmarkBasicOperations;
    BenchmarkConcurrentOperations;
    BenchmarkMemoryUsage;
    
    WriteLn('所有性能测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生错误：', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
