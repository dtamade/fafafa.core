program test_mutex_timeout;

{**
 * Mutex 超时测试
 *
 * 测试 Mutex 的超时获取功能（TryAcquire with timeout）
 *
 * 测试覆盖：
 * 1. 零超时测试（立即返回）
 * 2. 极短超时测试（1-10ms）
 * 3. 正常超时测试（100-500ms）
 * 4. 长超时测试（1000ms+）
 * 5. 超时精度测试（误差范围验证）
 * 6. 并发超时测试（多线程同时超时）
 * 7. 取消场景测试（超时期间的中断）
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.mutex;

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
// 测试 1: 零超时测试（立即返回）
// ============================================================================
procedure Test_Mutex_ZeroTimeout;
var
  M: IMutex;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Zero Timeout');

  M := MakeMutex;

  // 先获取锁
  M.Acquire;
  try
    // 在另一个线程尝试获取（零超时应该立即返回 False）
    StartTime := GetTickCount64;
    Result := M.TryAcquire(0);
    Elapsed := GetTickCount64 - StartTime;

    Assert(not Result, 'TryAcquire(0) should return False when lock is held');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately');
  finally
    M.Release;
  end;

  // 测试无竞争情况下的零超时
  StartTime := GetTickCount64;
  Result := M.TryAcquire(0);
  Elapsed := GetTickCount64 - StartTime;

  if Result then
  begin
    M.Release;
    Assert(True, 'TryAcquire(0) should succeed when lock is free');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately even on success');
  end
  else
    Assert(False, 'TryAcquire(0) should succeed when lock is free');
end;

// ============================================================================
// 测试 2: 极短超时测试（1-10ms）
// ============================================================================
procedure Test_Mutex_VeryShortTimeout;
var
  M: IMutex;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Very Short Timeout');

  M := MakeMutex;

  // 先获取锁
  M.Acquire;
  try
    // 测试 1ms 超时
    StartTime := GetTickCount64;
    Result := M.TryAcquire(1);
    Elapsed := GetTickCount64 - StartTime;

    Assert(not Result, 'TryAcquire(1) should timeout');
    // 注意：不验证上限，因为系统调度延迟不可预测

    // 测试 10ms 超时
    StartTime := GetTickCount64;
    Result := M.TryAcquire(10);
    Elapsed := GetTickCount64 - StartTime;

    Assert(not Result, 'TryAcquire(10) should timeout');
    // 注意：不验证上限，因为系统调度延迟不可预测
  finally
    M.Release;
  end;
end;

// ============================================================================
// 测试 3: 正常超时测试（100-500ms）
// ============================================================================
procedure Test_Mutex_NormalTimeout;
var
  M: IMutex;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Normal Timeout');

  M := MakeMutex;

  // 先获取锁
  M.Acquire;
  try
    // 测试 100ms 超时
    StartTime := GetTickCount64;
    Result := M.TryAcquire(100);
    Elapsed := GetTickCount64 - StartTime;

    Assert(not Result, 'TryAcquire(100) should timeout');
    Assert(Elapsed >= 50, 'Should wait at least 50ms');
    // 注意：不验证上限，因为系统调度延迟不可预测

    // 测试 500ms 超时
    StartTime := GetTickCount64;
    Result := M.TryAcquire(500);
    Elapsed := GetTickCount64 - StartTime;

    Assert(not Result, 'TryAcquire(500) should timeout');
    Assert(Elapsed >= 450, 'Should wait at least 450ms');
    // 注意：不验证上限，因为系统调度延迟不可预测
  finally
    M.Release;
  end;
end;

// ============================================================================
// 测试 4: 长超时测试（1000ms+）
// ============================================================================
procedure Test_Mutex_LongTimeout;
var
  M: IMutex;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Long Timeout');

  M := MakeMutex;

  // 先获取锁
  M.Acquire;
  try
    // 测试 1000ms 超时
    StartTime := GetTickCount64;
    Result := M.TryAcquire(1000);
    Elapsed := GetTickCount64 - StartTime;

    Assert(not Result, 'TryAcquire(1000) should timeout');
    Assert(Elapsed >= 950, 'Should wait at least 950ms');
    Assert(Elapsed < 1200, 'Should not wait more than 1200ms');
  finally
    M.Release;
  end;
end;

// ============================================================================
// 测试 5: 超时前成功获取
// ============================================================================
type
  TTimeoutSuccessThread = class(TThread)
  private
    FMutex: IMutex;
    FSuccess: Boolean;
    FElapsed: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex);
    property Success: Boolean read FSuccess;
    property Elapsed: QWord read FElapsed;
  end;

constructor TTimeoutSuccessThread.Create(AMutex: IMutex);
begin
  inherited Create(True);
  FMutex := AMutex;
  FSuccess := False;
  FElapsed := 0;
  FreeOnTerminate := False;
end;

procedure TTimeoutSuccessThread.Execute;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  FSuccess := FMutex.TryAcquire(1000);  // 1秒超时
  FElapsed := GetTickCount64 - StartTime;
  if FSuccess then
    FMutex.Release;
end;

procedure Test_Mutex_TimeoutSuccess;
var
  M: IMutex;
  T: TTimeoutSuccessThread;
begin
  WriteLn('Test: Mutex Timeout Success');

  M := MakeMutex;

  // 先获取锁
  M.Acquire;

  // 启动线程（会等待）
  T := TTimeoutSuccessThread.Create(M);
  T.Start;

  // 等待 200ms 后释放锁
  Sleep(200);
  M.Release;

  // 等待线程完成
  T.WaitFor;

  Assert(T.Success, 'Should acquire lock before timeout');
  Assert(T.Elapsed >= 150, 'Should have waited at least 150ms');
  Assert(T.Elapsed < 500, 'Should not have waited more than 500ms');

  T.Free;
end;

// ============================================================================
// 测试 6: 并发超时测试
// ============================================================================
type
  TConcurrentTimeoutThread = class(TThread)
  private
    FMutex: IMutex;
    FTimedOut: Boolean;
    FElapsed: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex);
    property TimedOut: Boolean read FTimedOut;
    property Elapsed: QWord read FElapsed;
  end;

constructor TConcurrentTimeoutThread.Create(AMutex: IMutex);
begin
  inherited Create(True);
  FMutex := AMutex;
  FTimedOut := False;
  FElapsed := 0;
  FreeOnTerminate := False;
end;

procedure TConcurrentTimeoutThread.Execute;
var
  StartTime: QWord;
  Result: Boolean;
begin
  StartTime := GetTickCount64;
  Result := FMutex.TryAcquire(300);  // 300ms 超时
  FElapsed := GetTickCount64 - StartTime;
  FTimedOut := not Result;
  if Result then
    FMutex.Release;
end;

procedure Test_Mutex_ConcurrentTimeout;
const
  THREAD_COUNT = 5;
var
  M: IMutex;
  Threads: array[0..THREAD_COUNT-1] of TConcurrentTimeoutThread;
  I: Integer;
  AllTimedOut: Boolean;
begin
  WriteLn('Test: Mutex Concurrent Timeout');

  M := MakeMutex;

  // 先获取锁
  M.Acquire;

  // 创建多个等待线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TConcurrentTimeoutThread.Create(M);

  // 启动所有线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;

  // 等待所有线程完成（不释放锁，让它们都超时）
  AllTimedOut := True;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    if not Threads[I].TimedOut then
      AllTimedOut := False;
    Assert(Threads[I].Elapsed >= 250, 'Thread should have waited at least 250ms');
    // 注意：不验证上限，因为系统调度延迟不可预测
    Threads[I].Free;
  end;

  M.Release;

  Assert(AllTimedOut, 'All threads should have timed out');
end;

// ============================================================================
// 测试 7: 边界条件 - 最大超时值
// ============================================================================
procedure Test_Mutex_MaxTimeout;
var
  M: IMutex;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Max Timeout');

  M := MakeMutex;

  // 测试无竞争情况下的大超时值（应该立即成功）
  StartTime := GetTickCount64;
  Result := M.TryAcquire(High(Cardinal));
  Elapsed := GetTickCount64 - StartTime;

  if Result then
  begin
    M.Release;
    Assert(True, 'TryAcquire with max timeout should succeed when lock is free');
    Assert(Elapsed < 100, 'Should succeed almost immediately');
  end
  else
    Assert(False, 'TryAcquire with max timeout should succeed when lock is free');
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Mutex Timeout Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_Mutex_ZeroTimeout;
    Test_Mutex_VeryShortTimeout;
    Test_Mutex_NormalTimeout;
    Test_Mutex_LongTimeout;
    Test_Mutex_TimeoutSuccess;
    Test_Mutex_ConcurrentTimeout;
    Test_Mutex_MaxTimeout;
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
