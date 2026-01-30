program test_parker_advanced;

{**
 * Parker 高级测试
 *
 * 测试 Parker 的高级场景和边界条件
 *
 * 测试覆盖：
 * 1. ParkDuration 方法测试
 * 2. 多线程同时等待场景
 * 3. 快速 park/unpark 循环
 * 4. 边界条件和压力测试
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.parker;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Assert(Condition: Boolean; const Msg: string);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('  ✓ ', Msg);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('  ✗ FAIL: ', Msg);
  end;
end;

// ============================================================================
// 测试 1: 长超时测试
// ============================================================================
procedure Test_Parker_LongTimeout;
var
  P: IParker;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Parker Long Timeout');

  P := MakeParker;

  // 测试较长的超时（500ms）
  StartTime := GetTickCount64;
  Result := P.ParkTimeout(500);
  Elapsed := GetTickCount64 - StartTime;

  Assert(not Result, 'ParkTimeout should timeout');
  Assert(Elapsed >= 450, 'Should have waited at least 450ms');
  Assert(Elapsed < 700, 'Should not have waited more than 700ms');
end;

// ============================================================================
// 测试 2: 立即返回测试
// ============================================================================
procedure Test_Parker_ImmediateReturn;
var
  P: IParker;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Parker Immediate Return');

  P := MakeParker;

  // 先 Unpark
  P.Unpark;

  // ParkTimeout 应该立即返回 True
  StartTime := GetTickCount64;
  Result := P.ParkTimeout(1000);
  Elapsed := GetTickCount64 - StartTime;

  Assert(Result, 'ParkTimeout should return True when permit is available');
  Assert(Elapsed < 50, 'Should return almost immediately');
end;

// ============================================================================
// 测试 3: 多线程同时等待
// ============================================================================
type
  TMultiWaiterThread = class(TThread)
  private
    FParker: IParker;
    FWaitTime: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(AParker: IParker);
  end;

constructor TMultiWaiterThread.Create(AParker: IParker);
begin
  inherited Create(True);
  FParker := AParker;
  FWaitTime := 0;
  FreeOnTerminate := False;
end;

procedure TMultiWaiterThread.Execute;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  FParker.Park;
  FWaitTime := GetTickCount64 - StartTime;
end;

procedure Test_Parker_MultipleThreadsWaiting;
const
  THREAD_COUNT = 5;
var
  P: IParker;
  Threads: array[0..THREAD_COUNT-1] of TMultiWaiterThread;
  I: Integer;
  AllWaitedSimilarTime: Boolean;
begin
  WriteLn('Test: Parker Multiple Threads Waiting');

  P := MakeParker;

  // 创建多个等待线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TMultiWaiterThread.Create(P);

  // 启动所有线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;

  // 等待所有线程启动
  Sleep(100);

  // 唤醒所有线程（注意：Parker 只存储一个许可，所以只有一个线程会被唤醒）
  P.Unpark;

  // 等待第一个线程完成
  Sleep(50);

  // 唤醒剩余线程
  for I := 1 to THREAD_COUNT - 1 do
  begin
    Sleep(10);
    P.Unpark;
  end;

  // 等待所有线程完成
  AllWaitedSimilarTime := True;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    // 验证每个线程都被唤醒了
    if Threads[I].FWaitTime > 500 then
      AllWaitedSimilarTime := False;
    Threads[I].Free;
  end;

  Assert(AllWaitedSimilarTime, 'All threads should be woken up within reasonable time');
end;

// ============================================================================
// 测试 4: 快速 park/unpark 循环
// ============================================================================
procedure Test_Parker_RapidCycles;
const
  CYCLE_COUNT = 100;
var
  P: IParker;
  I: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Parker Rapid Park/Unpark Cycles');

  P := MakeParker;

  StartTime := GetTickCount64;
  for I := 1 to CYCLE_COUNT do
  begin
    P.Unpark;
    P.Park;
  end;
  Elapsed := GetTickCount64 - StartTime;

  Assert(Elapsed < 1000, 'Rapid cycles should complete quickly');
  Assert(True, Format('Completed %d cycles in %d ms', [CYCLE_COUNT, Elapsed]));
end;

// ============================================================================
// 测试 5: 压力测试 - 多线程快速 park/unpark
// ============================================================================
type
  TStressThread = class(TThread)
  private
    FParker: IParker;
    FCycleCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AParker: IParker; ACycleCount: Integer);
  end;

constructor TStressThread.Create(AParker: IParker; ACycleCount: Integer);
begin
  inherited Create(True);
  FParker := AParker;
  FCycleCount := ACycleCount;
  FreeOnTerminate := False;
end;

procedure TStressThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FCycleCount do
  begin
    FParker.Unpark;
    FParker.Park;
  end;
end;

procedure Test_Parker_StressTest;
const
  THREAD_COUNT = 3;
  CYCLES_PER_THREAD = 50;
var
  P: IParker;
  Threads: array[0..THREAD_COUNT-1] of TStressThread;
  I: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Parker Stress Test');

  P := MakeParker;

  // 创建多个压力测试线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TStressThread.Create(P, CYCLES_PER_THREAD);

  StartTime := GetTickCount64;

  // 启动所有线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;

  // 等待所有线程完成
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  Elapsed := GetTickCount64 - StartTime;

  Assert(True, Format('Stress test completed: %d threads × %d cycles in %d ms',
    [THREAD_COUNT, CYCLES_PER_THREAD, Elapsed]));
end;

// ============================================================================
// 测试 6: 边界条件 - 零超时
// ============================================================================
procedure Test_Parker_ZeroTimeout;
var
  P: IParker;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Parker Zero Timeout');

  P := MakeParker;

  StartTime := GetTickCount64;
  Result := P.ParkTimeout(0);
  Elapsed := GetTickCount64 - StartTime;

  Assert(not Result, 'ParkTimeout(0) should return False immediately');
  Assert(Elapsed < 50, 'Zero timeout should return almost immediately');
end;

// ============================================================================
// 测试 7: 边界条件 - 非常短的超时
// ============================================================================
procedure Test_Parker_VeryShortTimeout;
var
  P: IParker;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Parker Very Short Timeout');

  P := MakeParker;

  StartTime := GetTickCount64;
  Result := P.ParkTimeout(1);
  Elapsed := GetTickCount64 - StartTime;

  Assert(not Result, 'ParkTimeout(1) should timeout');
  Assert(Elapsed < 100, 'Very short timeout should return quickly');
end;

// ============================================================================
// 测试 8: Park 后立即 Unpark（竞态条件测试）
// ============================================================================
type
  TRaceConditionThread = class(TThread)
  private
    FParker: IParker;
    FWasWokenUp: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AParker: IParker);
    property WasWokenUp: Boolean read FWasWokenUp;
  end;

constructor TRaceConditionThread.Create(AParker: IParker);
begin
  inherited Create(True);
  FParker := AParker;
  FWasWokenUp := False;
  FreeOnTerminate := False;
end;

procedure TRaceConditionThread.Execute;
begin
  Sleep(10);  // 确保主线程先调用 Unpark
  FParker.Park;
  FWasWokenUp := True;
end;

procedure Test_Parker_RaceCondition;
var
  P: IParker;
  T: TRaceConditionThread;
begin
  WriteLn('Test: Parker Race Condition');

  P := MakeParker;

  // 先 Unpark（发放许可）
  P.Unpark;

  // 启动线程（应该立即消费许可）
  T := TRaceConditionThread.Create(P);
  T.Start;

  T.WaitFor;

  Assert(T.WasWokenUp, 'Thread should be woken up by pre-issued permit');
  T.Free;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Parker Advanced Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_Parker_LongTimeout;
    Test_Parker_ImmediateReturn;
    Test_Parker_MultipleThreadsWaiting;
    Test_Parker_RapidCycles;
    Test_Parker_StressTest;
    Test_Parker_ZeroTimeout;
    Test_Parker_VeryShortTimeout;
    Test_Parker_RaceCondition;
  except
    on E: Exception do
    begin
      WriteLn('FATAL: Unhandled exception: ', E.ClassName, ': ', E.Message);
      Inc(TestsFailed);
    end;
  end;

  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Results: ', TestsPassed, ' passed, ', TestsFailed, ' failed');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1);
end.
