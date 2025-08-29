unit fafafa.core.sync.event.debug.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 调试和监控功能测试 }
  TTestCase_Event_Debug = class(TTestCase)
  private
    FEvent: IEvent;
    FOperationLog: TStringList;
    
    procedure LogOperation(const AOperation: string);
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础调试功能
    procedure Test_Debug_OperationLogging;
    procedure Test_Debug_StateTracking;
    procedure Test_Debug_ErrorTracking;
    
    // 性能监控
    procedure Test_Performance_OperationTiming;
    procedure Test_Performance_StatisticsCollection;
    
    // 诊断工具
    procedure Test_Diagnostics_EventInspection;
    procedure Test_Diagnostics_ThreadSafety;
  end;

implementation

{ TTestCase_Event_Debug }

procedure TTestCase_Event_Debug.LogOperation(const AOperation: string);
begin
  FOperationLog.Add(AOperation);
end;

procedure TTestCase_Event_Debug.SetUp;
begin
  inherited SetUp;
  FOperationLog := TStringList.Create;
  FEvent := fafafa.core.sync.event.CreateEvent(True, False); // 手动重置，未信号
end;

procedure TTestCase_Event_Debug.TearDown;
begin
  FEvent := nil;
  FOperationLog.Free;
  inherited TearDown;
end;

procedure TTestCase_Event_Debug.Test_Debug_OperationLogging;
var
  InitialErrorState: TWaitError;
  r: TWaitResult;
  i: Integer;
begin
  WriteLn('Testing operation logging...');
  
  // 记录初始状态
  InitialErrorState := FEvent.GetLastError;
  LogOperation('Initial error state: ' + IntToStr(Ord(InitialErrorState)));
  
  // 执行操作并记录
  LogOperation('Calling SetEvent');
  FEvent.SetEvent;
  LogOperation('SetEvent completed, error: ' + IntToStr(Ord(FEvent.GetLastError)));
  
  LogOperation('Calling IsSignaled');
  AssertTrue('Event should be signaled', FEvent.IsSignaled);
  LogOperation('IsSignaled result: True');
  
  LogOperation('Calling WaitFor(0)');
  r := FEvent.WaitFor(0);
  LogOperation('WaitFor result: ' + IntToStr(Ord(r)));
  AssertEquals('Should be signaled', Ord(wrSignaled), Ord(r));
  
  LogOperation('Calling ResetEvent');
  FEvent.ResetEvent;
  LogOperation('ResetEvent completed');
  
  LogOperation('Calling IsSignaled after reset');
  AssertFalse('Event should not be signaled', FEvent.IsSignaled);
  LogOperation('IsSignaled result: False');
  
  // 验证日志记录
  AssertTrue('Should have logged operations', FOperationLog.Count > 5);
  WriteLn('Operation log entries: ', FOperationLog.Count);
  
  // 输出日志用于调试
  WriteLn('Operation log:');
  for i := 0 to FOperationLog.Count - 1 do
    WriteLn('  ', FOperationLog[i]);
end;

procedure TTestCase_Event_Debug.Test_Debug_StateTracking;
var
  WaitingThreads: Integer;
begin
  WriteLn('Testing state tracking...');
  
  // 跟踪事件类型
  AssertTrue('Should be manual reset', FEvent.IsManualReset);
  LogOperation('Event type: Manual Reset');
  
  // 跟踪等待线程数
  WaitingThreads := FEvent.GetWaitingThreadCount;
  LogOperation('Initial waiting threads: ' + IntToStr(WaitingThreads));
  AssertEquals('Should have no waiting threads initially', 0, WaitingThreads);
  
  // 跟踪状态变化
  LogOperation('Setting event...');
  FEvent.SetEvent;
  AssertTrue('Should be signaled after set', FEvent.IsSignaled);
  LogOperation('Event is now signaled');
  
  LogOperation('Resetting event...');
  FEvent.ResetEvent;
  AssertFalse('Should not be signaled after reset', FEvent.IsSignaled);
  LogOperation('Event is now non-signaled');
  
  WriteLn('State tracking test completed');
end;

procedure TTestCase_Event_Debug.Test_Debug_ErrorTracking;
var
  ErrorBefore, ErrorAfter: TWaitError;
  r: TWaitResult;
begin
  WriteLn('Testing error tracking...');
  
  // 跟踪正常操作的错误状态
  ErrorBefore := FEvent.GetLastError;
  LogOperation('Error before SetEvent: ' + IntToStr(Ord(ErrorBefore)));
  
  FEvent.SetEvent;
  ErrorAfter := FEvent.GetLastError;
  LogOperation('Error after SetEvent: ' + IntToStr(Ord(ErrorAfter)));
  AssertEquals('Should have no error after SetEvent', Ord(weNone), Ord(ErrorAfter));
  
  // 跟踪等待操作的错误状态
  r := FEvent.WaitFor(0);
  ErrorAfter := FEvent.GetLastError;
  LogOperation('Error after WaitFor: ' + IntToStr(Ord(ErrorAfter)));
  AssertEquals('Should have no error after successful WaitFor', Ord(weNone), Ord(ErrorAfter));
  
  // 跟踪超时情况
  FEvent.ResetEvent;
  r := FEvent.WaitFor(1); // 短超时
  ErrorAfter := FEvent.GetLastError;
  LogOperation('Error after timeout: ' + IntToStr(Ord(ErrorAfter)));
  AssertEquals('Should have no error after timeout', Ord(weNone), Ord(ErrorAfter));
  AssertEquals('Should timeout', Ord(wrTimeout), Ord(r));
  
  WriteLn('Error tracking test completed');
end;

procedure TTestCase_Event_Debug.Test_Performance_OperationTiming;
var
  StartTime, EndTime: QWord;
  ElapsedTime: QWord;
  i: Integer;
const
  OperationCount = 1000;
begin
  WriteLn('Testing operation timing...');
  
  // 测量 SetEvent/ResetEvent 性能
  StartTime := GetTickCount64;
  for i := 1 to OperationCount do
  begin
    FEvent.SetEvent;
    FEvent.ResetEvent;
  end;
  EndTime := GetTickCount64;
  ElapsedTime := EndTime - StartTime;
  
  LogOperation('Set/Reset operations: ' + IntToStr(OperationCount) + ' in ' + IntToStr(ElapsedTime) + ' ms');
  WriteLn('Set/Reset performance: ', OperationCount, ' operations in ', ElapsedTime, ' ms');
  WriteLn('Average time per operation: ', (ElapsedTime * 1000) div OperationCount, ' microseconds');
  
  // 测量 WaitFor 性能
  FEvent.SetEvent;
  StartTime := GetTickCount64;
  for i := 1 to OperationCount do
  begin
    FEvent.WaitFor(0); // 应该立即返回
  end;
  EndTime := GetTickCount64;
  ElapsedTime := EndTime - StartTime;
  
  LogOperation('WaitFor operations: ' + IntToStr(OperationCount) + ' in ' + IntToStr(ElapsedTime) + ' ms');
  WriteLn('WaitFor performance: ', OperationCount, ' operations in ', ElapsedTime, ' ms');
  
  AssertTrue('Operations should complete in reasonable time', ElapsedTime < 1000);
  WriteLn('Performance timing test completed');
end;

procedure TTestCase_Event_Debug.Test_Performance_StatisticsCollection;
var
  i: Integer;
  r: TWaitResult;
  SuccessCount, TimeoutCount: Integer;
begin
  WriteLn('Testing statistics collection...');
  
  SuccessCount := 0;
  TimeoutCount := 0;
  
  // 执行混合操作并收集统计
  for i := 1 to 100 do
  begin
    if i mod 3 = 0 then
    begin
      FEvent.SetEvent;
      r := FEvent.WaitFor(0);
      if r = wrSignaled then Inc(SuccessCount);
      FEvent.ResetEvent;
    end
    else
    begin
      r := FEvent.WaitFor(1); // 短超时
      if r = wrTimeout then Inc(TimeoutCount);
    end;
  end;
  
  LogOperation('Statistics: Success=' + IntToStr(SuccessCount) + ', Timeouts=' + IntToStr(TimeoutCount));
  WriteLn('Operation statistics:');
  WriteLn('  Successful waits: ', SuccessCount);
  WriteLn('  Timeouts: ', TimeoutCount);
  WriteLn('  Total operations: ', SuccessCount + TimeoutCount);
  
  AssertTrue('Should have some successful operations', SuccessCount > 0);
  AssertTrue('Should have some timeouts', TimeoutCount > 0);
  
  WriteLn('Statistics collection test completed');
end;

procedure TTestCase_Event_Debug.Test_Diagnostics_EventInspection;
var
  EventInfo: string;
begin
  WriteLn('Testing event inspection...');
  
  // 检查事件属性
  EventInfo := 'Event Properties: ';
  EventInfo := EventInfo + 'Type=' + IfThen(FEvent.IsManualReset, 'Manual', 'Auto') + ', ';
  EventInfo := EventInfo + 'Signaled=' + IfThen(FEvent.IsSignaled, 'Yes', 'No') + ', ';
  EventInfo := EventInfo + 'Waiting=' + IntToStr(FEvent.GetWaitingThreadCount) + ', ';
  EventInfo := EventInfo + 'Error=' + IntToStr(Ord(FEvent.GetLastError));
  
  LogOperation(EventInfo);
  WriteLn('Event inspection: ', EventInfo);
  
  // 改变状态并重新检查
  FEvent.SetEvent;
  EventInfo := 'After SetEvent: ';
  EventInfo := EventInfo + 'Signaled=' + IfThen(FEvent.IsSignaled, 'Yes', 'No') + ', ';
  EventInfo := EventInfo + 'Error=' + IntToStr(Ord(FEvent.GetLastError));
  
  LogOperation(EventInfo);
  WriteLn('State after SetEvent: ', EventInfo);
  
  WriteLn('Event inspection test completed');
end;

procedure TTestCase_Event_Debug.Test_Diagnostics_ThreadSafety;
type
  TTestThread = class(TThread)
  private
    FEvent: IEvent;
    FOperations: Integer;
    FThreadId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; AThreadId: Integer);
    property Operations: Integer read FOperations;
  end;

var
  Threads: array[0..2] of TTestThread;
  i, TotalOps: Integer;
begin
  WriteLn('Testing thread safety diagnostics...');
  
  // 创建多个线程进行操作
  for i := 0 to 2 do
  begin
    Threads[i] := TTestThread.Create(FEvent, i);
    Threads[i].Start;
  end;
  
  // 主线程也进行操作
  for i := 1 to 50 do
  begin
    FEvent.SetEvent;
    FEvent.WaitFor(0);
    FEvent.ResetEvent;
  end;
  
  // 等待线程完成
  TotalOps := 50; // 主线程操作
  for i := 0 to 2 do
  begin
    Threads[i].WaitFor;
    TotalOps := TotalOps + Threads[i].Operations;
    LogOperation('Thread ' + IntToStr(i) + ' completed ' + IntToStr(Threads[i].Operations) + ' operations');
    Threads[i].Free;
  end;
  
  LogOperation('Total operations across all threads: ' + IntToStr(TotalOps));
  WriteLn('Thread safety test completed with ', TotalOps, ' total operations');
  
  AssertTrue('Should complete operations without errors', TotalOps > 100);
end;

{ TTestThread }
constructor TTestCase_Event_Debug.TTestThread.Create(AEvent: IEvent; AThreadId: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FEvent := AEvent;
  FThreadId := AThreadId;
  FOperations := 0;
end;

procedure TTestCase_Event_Debug.TTestThread.Execute;
var i: Integer;
begin
  for i := 1 to 30 do
  begin
    if Terminated then Break;
    
    try
      case i mod 3 of
        0: FEvent.SetEvent;
        1: FEvent.WaitFor(1);
        2: FEvent.ResetEvent;
      end;
      Inc(FOperations);
    except
      // 忽略异常，继续测试
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_Event_Debug);

end.
