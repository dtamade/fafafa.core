program test_oncelock_wait;

{**
 * OnceLock Wait 机制测试
 *
 * 测试 OnceLock 的 Wait() 和 WaitTimeout() 方法
 * 验证多线程等待和唤醒机制
 *
 * 测试覆盖：
 * 1. Wait() 阻塞直到值被设置
 * 2. WaitTimeout() 超时行为
 * 3. 多线程等待场景
 * 4. 等待期间的并发设置
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.oncelock;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure AssertTrue(const Cond: Boolean; const Msg: string);
begin
  if not Cond then
  begin
    WriteLn('FAIL: ', Msg);
    Inc(TestsFailed);
  end
  else
  begin
    WriteLn('OK:   ', Msg);
    Inc(TestsPassed);
  end;
end;

procedure AssertEquals(Expected, Actual: Integer; const Msg: string);
begin
  AssertTrue(Expected = Actual, Msg + ' (期望: ' + IntToStr(Expected) + ', 实际: ' + IntToStr(Actual) + ')');
end;

// ===== Wait 基本测试 =====

type
  TTestOnceLockInt = specialize TOnceLock<Integer>;

var
  G_WaitLock: TTestOnceLockInt;
  G_WaitThreadStarted: Boolean;
  G_WaitThreadFinished: Boolean;

type
  TWaitThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TWaitThread.Execute;
begin
  G_WaitThreadStarted := True;
  G_WaitLock.Wait;
  G_WaitThreadFinished := True;
end;

procedure Test_OnceLock_Wait_BlocksUntilSet;
var
  WaitThread: TWaitThread;
begin
  // Arrange
  G_WaitLock := TTestOnceLockInt.Create;
  G_WaitThreadStarted := False;
  G_WaitThreadFinished := False;

  try
    // Act: 启动等待线程
    WaitThread := TWaitThread.Create(True);
    WaitThread.Start;

    // 等待线程启动
    Sleep(100);
    AssertTrue(G_WaitThreadStarted, '等待线程应该已启动');
    AssertTrue(not G_WaitThreadFinished, '等待线程应该被阻塞');

    // 设置值
    G_WaitLock.SetValue(42);

    // 等待线程完成
    WaitThread.WaitFor;
    WaitThread.Free;

    // Assert
    AssertTrue(G_WaitThreadFinished, '等待线程应该在值被设置后完成');
  finally
    G_WaitLock.Free;
  end;
end;

procedure Test_OnceLock_Wait_ImmediateReturnIfSet;
var
  Lock: TTestOnceLockInt;
  StartTime, EndTime: QWord;
begin
  // Arrange
  Lock := TTestOnceLockInt.Create;
  try
    Lock.SetValue(100);

    // Act: 在已设置的 OnceLock 上调用 Wait
    StartTime := GetTickCount64;
    Lock.Wait;
    EndTime := GetTickCount64;

    // Assert: Wait 应该立即返回（不超过 10ms）
    AssertTrue((EndTime - StartTime) < 10, 'Wait 应该立即返回');
  finally
    Lock.Free;
  end;
end;

// ===== WaitTimeout 测试 =====

procedure Test_OnceLock_WaitTimeout_ReturnsTrue_WhenSet;
var
  Lock: TTestOnceLockInt;
  Result: Boolean;
begin
  // Arrange
  Lock := TTestOnceLockInt.Create;
  try
    Lock.SetValue(200);

    // Act
    Result := Lock.WaitTimeout(100);

    // Assert
    AssertTrue(Result, 'WaitTimeout 应该立即返回 True');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_WaitTimeout_ReturnsFalse_OnTimeout;
var
  Lock: TTestOnceLockInt;
  Result: Boolean;
  StartTime, EndTime: QWord;
begin
  // Arrange
  Lock := TTestOnceLockInt.Create;
  try
    // Act: 等待一个未设置的 OnceLock
    StartTime := GetTickCount64;
    Result := Lock.WaitTimeout(100);
    EndTime := GetTickCount64;

    // Assert
    AssertTrue(not Result, 'WaitTimeout 应该返回 False');
    AssertTrue((EndTime - StartTime) >= 100, 'WaitTimeout 应该等待至少 100ms');
    AssertTrue((EndTime - StartTime) < 200, 'WaitTimeout 不应该等待超过 200ms');
  finally
    Lock.Free;
  end;
end;

// ===== 多线程等待测试 =====

var
  G_MultiWaitLock: TTestOnceLockInt;
  G_MultiWaitFinishedCount: Integer;

type
  TMultiWaitThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TMultiWaitThread.Execute;
begin
  G_MultiWaitLock.Wait;
  InterlockedIncrement(G_MultiWaitFinishedCount);
end;

procedure Test_OnceLock_Wait_MultipleThreads;
const
  THREAD_COUNT = 10;
var
  Threads: array[0..THREAD_COUNT-1] of TThread;
  I: Integer;
begin
  // Arrange
  G_MultiWaitLock := TTestOnceLockInt.Create;
  G_MultiWaitFinishedCount := 0;

  try
    // Act: 启动多个等待线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TMultiWaitThread.Create(True);

    // 同时启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;

    // 等待所有线程启动
    Sleep(200);
    AssertEquals(0, G_MultiWaitFinishedCount, '所有线程应该被阻塞');

    // 设置值，唤醒所有线程
    G_MultiWaitLock.SetValue(999);

    // 等待所有线程完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;

    // Assert
    AssertEquals(THREAD_COUNT, G_MultiWaitFinishedCount, '所有线程应该被唤醒');
  finally
    G_MultiWaitLock.Free;
  end;
end;

// ===== 等待期间并发设置测试 =====

var
  G_ConcurrentSetLock: TTestOnceLockInt;
  G_SetterFinished: Boolean;

type
  TSetterThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TSetterThread.Execute;
begin
  Sleep(100);  // 等待 waiter 线程启动
  G_ConcurrentSetLock.SetValue(777);
  G_SetterFinished := True;
end;

type
  TWaiterThread = class(TThread)
  private
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    property Success: Boolean read FSuccess;
  end;

procedure TWaiterThread.Execute;
begin
  FSuccess := G_ConcurrentSetLock.WaitTimeout(500);
end;

procedure Test_OnceLock_Wait_ConcurrentSet;
var
  SetterThread: TSetterThread;
  WaiterThread: TWaiterThread;
begin
  // Arrange
  G_ConcurrentSetLock := TTestOnceLockInt.Create;
  G_SetterFinished := False;

  try
    // Act: 启动 waiter 和 setter 线程
    WaiterThread := TWaiterThread.Create(True);
    SetterThread := TSetterThread.Create(True);

    WaiterThread.Start;
    SetterThread.Start;

    // 等待两个线程完成
    WaiterThread.WaitFor;
    SetterThread.WaitFor;

    // Assert
    AssertTrue(WaiterThread.Success, 'Waiter 应该在值被设置后返回 True');
    AssertTrue(G_SetterFinished, 'Setter 应该成功设置值');
    AssertEquals(777, G_ConcurrentSetLock.GetValue, '值应该被正确设置');

    WaiterThread.Free;
    SetterThread.Free;
  finally
    G_ConcurrentSetLock.Free;
  end;
end;

// ===== Main =====

begin
  WriteLn('=== OnceLock Wait 机制测试 ===');
  WriteLn;

  WriteLn('--- Wait 基本测试 ---');
  Test_OnceLock_Wait_BlocksUntilSet;
  Test_OnceLock_Wait_ImmediateReturnIfSet;

  WriteLn;
  WriteLn('--- WaitTimeout 测试 ---');
  Test_OnceLock_WaitTimeout_ReturnsTrue_WhenSet;
  Test_OnceLock_WaitTimeout_ReturnsFalse_OnTimeout;

  WriteLn;
  WriteLn('--- 多线程等待测试 ---');
  Test_OnceLock_Wait_MultipleThreads;
  Test_OnceLock_Wait_ConcurrentSet;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.
