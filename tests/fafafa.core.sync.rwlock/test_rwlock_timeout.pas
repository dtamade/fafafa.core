program test_rwlock_timeout;

{**
 * RWLock 超时测试
 *
 * 测试 RWLock 的超时获取功能（TryAcquireRead/TryAcquireWrite with timeout）
 *
 * 测试覆盖：
 * 1. 读锁零超时测试
 * 2. 写锁零超时测试
 * 3. 读锁正常超时测试
 * 4. 写锁正常超时测试
 * 5. 读锁超时前成功获取
 * 6. 写锁超时前成功获取
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base,
  fafafa.core.sync.base;

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
// 测试 1: 读锁零超时测试（使用多线程）
// ============================================================================
type
  TReadZeroTimeoutThread = class(TThread)
  private
    FRWLock: IRWLock;
    FResult: TLockResult;
    FElapsed: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property Result: TLockResult read FResult;
    property Elapsed: QWord read FElapsed;
  end;

constructor TReadZeroTimeoutThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FResult := lrSuccess;
  FElapsed := 0;
  FreeOnTerminate := False;
end;

procedure TReadZeroTimeoutThread.Execute;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  FResult := FRWLock.TryAcquireReadEx(0);
  FElapsed := GetTickCount64 - StartTime;
  if FResult = lrSuccess then
    FRWLock.ReleaseRead;
end;

procedure Test_RWLock_ReadZeroTimeout;
var
  RW: IRWLock;
  T: TReadZeroTimeoutThread;
  LockResult: TLockResult;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Read Zero Timeout');

  RW := MakeRWLock;

  // 先获取写锁
  RW.AcquireWrite;
  try
    // 在另一个线程尝试获取读锁（零超时应该立即返回失败）
    T := TReadZeroTimeoutThread.Create(RW);
    T.Start;
    T.WaitFor;

    Assert(T.Result = lrWouldBlock, 'TryAcquireRead(0) should return lrWouldBlock when write lock is held');
    Assert(T.Elapsed < 50, 'Zero timeout should return almost immediately');
    T.Free;
  finally
    RW.ReleaseWrite;
  end;

  // 测试无竞争情况下的零超时
  StartTime := GetTickCount64;
  LockResult := RW.TryAcquireReadEx(0);
  Elapsed := GetTickCount64 - StartTime;

  if LockResult = lrSuccess then
  begin
    RW.ReleaseRead;
    Assert(True, 'TryAcquireRead(0) should succeed when no write lock is held');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately even on success');
  end
  else
    Assert(False, 'TryAcquireRead(0) should succeed when no write lock is held');
end;

// ============================================================================
// 测试 2: 写锁零超时测试
// ============================================================================
procedure Test_RWLock_WriteZeroTimeout;
var
  RW: IRWLock;
  LockResult: TLockResult;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Write Zero Timeout');

  RW := MakeRWLock;

  // 先获取读锁
  RW.AcquireRead;
  try
    // 尝试获取写锁（零超时应该立即返回失败）
    StartTime := GetTickCount64;
    LockResult := RW.TryAcquireWriteEx(0);
    Elapsed := GetTickCount64 - StartTime;

    Assert(LockResult = lrWouldBlock, 'TryAcquireWrite(0) should return lrWouldBlock when read lock is held');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately');
  finally
    RW.ReleaseRead;
  end;

  // 测试无竞争情况下的零超时
  StartTime := GetTickCount64;
  LockResult := RW.TryAcquireWriteEx(0);
  Elapsed := GetTickCount64 - StartTime;

  if LockResult = lrSuccess then
  begin
    RW.ReleaseWrite;
    Assert(True, 'TryAcquireWrite(0) should succeed when no lock is held');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately even on success');
  end
  else
    Assert(False, 'TryAcquireWrite(0) should succeed when no lock is held');
end;

// ============================================================================
// 测试 3: 读锁正常超时测试（使用多线程）
// ============================================================================
type
  TReadTimeoutThread = class(TThread)
  private
    FRWLock: IRWLock;
    FTimeout: Cardinal;
    FResult: TLockResult;
    FElapsed: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; ATimeout: Cardinal);
    property Result: TLockResult read FResult;
    property Elapsed: QWord read FElapsed;
  end;

constructor TReadTimeoutThread.Create(ARWLock: IRWLock; ATimeout: Cardinal);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FTimeout := ATimeout;
  FResult := lrSuccess;
  FElapsed := 0;
  FreeOnTerminate := False;
end;

procedure TReadTimeoutThread.Execute;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  FResult := FRWLock.TryAcquireReadEx(FTimeout);
  FElapsed := GetTickCount64 - StartTime;
  if FResult = lrSuccess then
    FRWLock.ReleaseRead;
end;

procedure Test_RWLock_ReadNormalTimeout;
var
  RW: IRWLock;
  T: TReadTimeoutThread;
begin
  WriteLn('Test: RWLock Read Normal Timeout');

  RW := MakeRWLock;

  // 先获取写锁
  RW.AcquireWrite;
  try
    // 测试 100ms 超时
    T := TReadTimeoutThread.Create(RW, 100);
    T.Start;
    T.WaitFor;

    Assert(T.Result = lrTimeout, 'TryAcquireRead(100) should timeout');
    Assert(T.Elapsed >= 50, 'Should wait at least 50ms');
    T.Free;

    // 测试 500ms 超时
    T := TReadTimeoutThread.Create(RW, 500);
    T.Start;
    T.WaitFor;

    Assert(T.Result = lrTimeout, 'TryAcquireRead(500) should timeout');
    Assert(T.Elapsed >= 450, 'Should wait at least 450ms');
    T.Free;
  finally
    RW.ReleaseWrite;
  end;
end;

// ============================================================================
// 测试 4: 写锁正常超时测试（使用多线程）
// ============================================================================
type
  TWriteTimeoutThread = class(TThread)
  private
    FRWLock: IRWLock;
    FTimeout: Cardinal;
    FResult: TLockResult;
    FElapsed: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; ATimeout: Cardinal);
    property Result: TLockResult read FResult;
    property Elapsed: QWord read FElapsed;
  end;

constructor TWriteTimeoutThread.Create(ARWLock: IRWLock; ATimeout: Cardinal);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FTimeout := ATimeout;
  FResult := lrSuccess;
  FElapsed := 0;
  FreeOnTerminate := False;
end;

procedure TWriteTimeoutThread.Execute;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  FResult := FRWLock.TryAcquireWriteEx(FTimeout);
  FElapsed := GetTickCount64 - StartTime;
  if FResult = lrSuccess then
    FRWLock.ReleaseWrite;
end;

procedure Test_RWLock_WriteNormalTimeout;
var
  RW: IRWLock;
  T: TWriteTimeoutThread;
begin
  WriteLn('Test: RWLock Write Normal Timeout');

  RW := MakeRWLock;

  // 先获取读锁
  RW.AcquireRead;
  try
    // 测试 100ms 超时
    T := TWriteTimeoutThread.Create(RW, 100);
    T.Start;
    T.WaitFor;

    Assert(T.Result = lrTimeout, 'TryAcquireWrite(100) should timeout');
    Assert(T.Elapsed >= 50, 'Should wait at least 50ms');
    T.Free;

    // 测试 500ms 超时
    T := TWriteTimeoutThread.Create(RW, 500);
    T.Start;
    T.WaitFor;

    Assert(T.Result = lrTimeout, 'TryAcquireWrite(500) should timeout');
    Assert(T.Elapsed >= 450, 'Should wait at least 450ms');
    T.Free;
  finally
    RW.ReleaseRead;
  end;
end;

// ============================================================================
// 测试 5: 读锁超时前成功获取
// ============================================================================
type
  TReadTimeoutSuccessThread = class(TThread)
  private
    FRWLock: IRWLock;
    FSuccess: Boolean;
    FElapsed: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property Success: Boolean read FSuccess;
    property Elapsed: QWord read FElapsed;
  end;

constructor TReadTimeoutSuccessThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FSuccess := False;
  FElapsed := 0;
  FreeOnTerminate := False;
end;

procedure TReadTimeoutSuccessThread.Execute;
var
  StartTime: QWord;
  LockResult: TLockResult;
begin
  StartTime := GetTickCount64;
  LockResult := FRWLock.TryAcquireReadEx(1000);  // 1秒超时
  FElapsed := GetTickCount64 - StartTime;
  FSuccess := (LockResult = lrSuccess);
  if FSuccess then
    FRWLock.ReleaseRead;
end;

procedure Test_RWLock_ReadTimeoutSuccess;
var
  RW: IRWLock;
  T: TReadTimeoutSuccessThread;
begin
  WriteLn('Test: RWLock Read Timeout Success');

  RW := MakeRWLock;

  // 先获取写锁
  RW.AcquireWrite;

  // 启动线程（会等待）
  T := TReadTimeoutSuccessThread.Create(RW);
  T.Start;

  // 等待 200ms 后释放写锁
  Sleep(200);
  RW.ReleaseWrite;

  // 等待线程完成
  T.WaitFor;

  Assert(T.Success, 'Should acquire read lock before timeout');
  Assert(T.Elapsed >= 150, 'Should have waited at least 150ms');
  Assert(T.Elapsed < 500, 'Should not have waited more than 500ms');

  T.Free;
end;

// ============================================================================
// 测试 6: 写锁超时前成功获取
// ============================================================================
type
  TWriteTimeoutSuccessThread = class(TThread)
  private
    FRWLock: IRWLock;
    FSuccess: Boolean;
    FElapsed: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property Success: Boolean read FSuccess;
    property Elapsed: QWord read FElapsed;
  end;

constructor TWriteTimeoutSuccessThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FSuccess := False;
  FElapsed := 0;
  FreeOnTerminate := False;
end;

procedure TWriteTimeoutSuccessThread.Execute;
var
  StartTime: QWord;
  LockResult: TLockResult;
begin
  StartTime := GetTickCount64;
  LockResult := FRWLock.TryAcquireWriteEx(1000);  // 1秒超时
  FElapsed := GetTickCount64 - StartTime;
  FSuccess := (LockResult = lrSuccess);
  if FSuccess then
    FRWLock.ReleaseWrite;
end;

procedure Test_RWLock_WriteTimeoutSuccess;
var
  RW: IRWLock;
  T: TWriteTimeoutSuccessThread;
begin
  WriteLn('Test: RWLock Write Timeout Success');

  RW := MakeRWLock;

  // 先获取读锁
  RW.AcquireRead;

  // 启动线程（会等待）
  T := TWriteTimeoutSuccessThread.Create(RW);
  T.Start;

  // 等待 200ms 后释放读锁
  Sleep(200);
  RW.ReleaseRead;

  // 等待线程完成
  T.WaitFor;

  Assert(T.Success, 'Should acquire write lock before timeout');
  Assert(T.Elapsed >= 150, 'Should have waited at least 150ms');
  Assert(T.Elapsed < 500, 'Should not have waited more than 500ms');

  T.Free;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  RWLock Timeout Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_RWLock_ReadZeroTimeout;
    Test_RWLock_WriteZeroTimeout;
    Test_RWLock_ReadNormalTimeout;
    Test_RWLock_WriteNormalTimeout;
    Test_RWLock_ReadTimeoutSuccess;
    Test_RWLock_WriteTimeoutSuccess;
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
