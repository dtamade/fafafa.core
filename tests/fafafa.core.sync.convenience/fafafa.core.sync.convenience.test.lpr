program fafafa_core_sync_convenience_test;

{**
 * 读写锁便捷方法测试
 *
 * 验证新增的便捷方法：
 *   - WithReadLock
 *   - WithWriteLock
 *   - TryWithReadLock
 *   - TryWithWriteLock
 *
 * TDD: 红 → 绿 → 重构
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$modeswitch functionreferences}
{$modeswitch advancedrecords}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base,
  fafafa.core.sync;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;
  // 全局变量用于测试回调
  GCallbackExecuted: Boolean;
  GValue: Integer;

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

procedure AssertEquals(const Expected, Actual: Integer; const Msg: string);
begin
  if Expected <> Actual then
  begin
    WriteLn('FAIL: ', Msg, ' (expected: ', Expected, ', got: ', Actual, ')');
    Inc(TestsFailed);
  end
  else
  begin
    WriteLn('OK:   ', Msg);
    Inc(TestsPassed);
  end;
end;

// ===== WithReadLock 测试 =====

procedure Test_WithReadLock_ExecutesCallback;
var
  RWLock: IRWLock;
begin
  // Arrange
  RWLock := MakeRWLock;
  GCallbackExecuted := False;

  // Act
  WithReadLock(RWLock, procedure begin GCallbackExecuted := True; end);

  // Assert
  AssertTrue(GCallbackExecuted, 'WithReadLock 应该执行回调');
end;

procedure Test_WithReadLock_ReleasesLockAfterCallback;
var
  RWLock: IRWLock;
begin
  // Arrange
  RWLock := MakeRWLock;
  GValue := 0;

  // Act
  WithReadLock(RWLock, procedure begin GValue := 42; end);

  // Assert: 应该能够获取写锁（说明读锁已释放）
  AssertTrue(RWLock.TryAcquireWrite(0), 'WithReadLock 之后应该能获取写锁');
  RWLock.ReleaseWrite;
  AssertEquals(42, GValue, 'WithReadLock 应该正确修改值');
end;

// ===== WithWriteLock 测试 =====

procedure Test_WithWriteLock_ExecutesCallback;
var
  RWLock: IRWLock;
begin
  // Arrange
  RWLock := MakeRWLock;
  GCallbackExecuted := False;

  // Act
  WithWriteLock(RWLock, procedure begin GCallbackExecuted := True; end);

  // Assert
  AssertTrue(GCallbackExecuted, 'WithWriteLock 应该执行回调');
end;

procedure Test_WithWriteLock_ReleasesLockAfterCallback;
var
  RWLock: IRWLock;
begin
  // Arrange
  RWLock := MakeRWLock;
  GValue := 0;

  // Act
  WithWriteLock(RWLock, procedure begin GValue := 100; end);

  // Assert: 应该能够获取读锁（说明写锁已释放）
  AssertTrue(RWLock.TryAcquireRead(0), 'WithWriteLock 之后应该能获取读锁');
  RWLock.ReleaseRead;
  AssertEquals(100, GValue, 'WithWriteLock 应该正确修改值');
end;

// ===== TryWithReadLock 测试 =====

procedure Test_TryWithReadLock_Success_ExecutesCallback;
var
  RWLock: IRWLock;
  Success: Boolean;
begin
  // Arrange
  RWLock := MakeRWLock;
  GCallbackExecuted := False;

  // Act
  Success := TryWithReadLock(RWLock, procedure begin GCallbackExecuted := True; end);

  // Assert
  AssertTrue(Success, 'TryWithReadLock 应该返回 True');
  AssertTrue(GCallbackExecuted, 'TryWithReadLock 成功时应该执行回调');
end;

procedure Test_TryWithReadLock_SucceedsWithReentrantLock;
var
  RWLock: IRWLock;
  Success: Boolean;
begin
  // Arrange
  // RWLock 默认支持可重入，同一线程持有写锁后可以获取读锁（写锁降级）
  RWLock := MakeRWLock;
  RWLock.AcquireWrite;  // 先持有写锁
  GCallbackExecuted := False;

  // Act
  Success := TryWithReadLock(RWLock, procedure begin GCallbackExecuted := True; end, 0);

  // Assert: 可重入锁应该允许这种情况
  AssertTrue(Success, 'TryWithReadLock 在可重入锁上应该成功（写锁降级）');
  AssertTrue(GCallbackExecuted, 'TryWithReadLock 成功时应该执行回调');

  // Cleanup
  RWLock.ReleaseWrite;
end;

// ===== TryWithWriteLock 测试 =====

procedure Test_TryWithWriteLock_Success_ExecutesCallback;
var
  RWLock: IRWLock;
  Success: Boolean;
begin
  // Arrange
  RWLock := MakeRWLock;
  GCallbackExecuted := False;

  // Act
  Success := TryWithWriteLock(RWLock, procedure begin GCallbackExecuted := True; end);

  // Assert
  AssertTrue(Success, 'TryWithWriteLock 应该返回 True');
  AssertTrue(GCallbackExecuted, 'TryWithWriteLock 成功时应该执行回调');
end;

procedure Test_TryWithWriteLock_Fails_WhenReadLocked;
var
  RWLock: IRWLock;
  Success: Boolean;
begin
  // Arrange
  RWLock := MakeRWLock;
  RWLock.AcquireRead;  // 先持有读锁
  GCallbackExecuted := False;

  // Act
  Success := TryWithWriteLock(RWLock, procedure begin GCallbackExecuted := True; end, 0);

  // Assert
  AssertTrue(not Success, 'TryWithWriteLock 在读锁被持有时应该返回 False');
  AssertTrue(not GCallbackExecuted, 'TryWithWriteLock 失败时不应该执行回调');

  // Cleanup
  RWLock.ReleaseRead;
end;

// ===== 异常安全测试 =====

procedure Test_WithReadLock_ReleasesLockOnException;
var
  RWLock: IRWLock;
  ExceptionCaught: Boolean;
begin
  // Arrange
  RWLock := MakeRWLock;
  ExceptionCaught := False;

  // Act
  try
    WithReadLock(RWLock, procedure begin raise Exception.Create('Test exception'); end);
  except
    on E: Exception do
      ExceptionCaught := True;
  end;

  // Assert
  AssertTrue(ExceptionCaught, 'WithReadLock 应该传播异常');
  AssertTrue(RWLock.TryAcquireWrite(0), 'WithReadLock 异常后应该释放锁');
  RWLock.ReleaseWrite;
end;

procedure Test_WithWriteLock_ReleasesLockOnException;
var
  RWLock: IRWLock;
  ExceptionCaught: Boolean;
begin
  // Arrange
  RWLock := MakeRWLock;
  ExceptionCaught := False;

  // Act
  try
    WithWriteLock(RWLock, procedure begin raise Exception.Create('Test exception'); end);
  except
    on E: Exception do
      ExceptionCaught := True;
  end;

  // Assert
  AssertTrue(ExceptionCaught, 'WithWriteLock 应该传播异常');
  AssertTrue(RWLock.TryAcquireRead(0), 'WithWriteLock 异常后应该释放锁');
  RWLock.ReleaseRead;
end;

// 毒化语义：WithWriteLock 在回调抛异常后，应导致 TryWithReadLock 抛出 ERWLockPoisonError

procedure Test_TryWithReadLock_RaisesPoisonErrorAfterException;
var
  RWLock: IRWLock;
  RaisedPoison: Boolean;
  Success: Boolean;
begin
  RWLock := MakeRWLock;
  RaisedPoison := False;

  // 先通过 WithWriteLock 制造毒化状态
  try
    WithWriteLock(RWLock, procedure begin raise Exception.Create('poison'); end);
  except
    on E: Exception do ;
  end;

  // 然后调用 TryWithReadLock，应抛出 ERWLockPoisonError，而不是简单返回 False
  Success := False;
  try
    Success := TryWithReadLock(RWLock, procedure begin GCallbackExecuted := True; end, 0);
  except
    on E: ERWLockPoisonError do
      RaisedPoison := True;
  end;

  AssertTrue(RaisedPoison, 'TryWithReadLock 在锁已毒化时应抛出 ERWLockPoisonError');
  AssertTrue(not Success, 'TryWithReadLock 在锁已毒化时不应报告成功');
end;

// ===== Main =====

begin
  WriteLn('=== fafafa.core.sync 便捷方法测试 ===');
  WriteLn;

  WriteLn('--- WithReadLock 测试 ---');
  Test_WithReadLock_ExecutesCallback;
  Test_WithReadLock_ReleasesLockAfterCallback;

  WriteLn;
  WriteLn('--- WithWriteLock 测试 ---');
  Test_WithWriteLock_ExecutesCallback;
  Test_WithWriteLock_ReleasesLockAfterCallback;

  WriteLn;
  WriteLn('--- TryWithReadLock 测试 ---');
  Test_TryWithReadLock_Success_ExecutesCallback;
  Test_TryWithReadLock_SucceedsWithReentrantLock;

  WriteLn;
  WriteLn('--- TryWithWriteLock 测试 ---');
  Test_TryWithWriteLock_Success_ExecutesCallback;
  Test_TryWithWriteLock_Fails_WhenReadLocked;

  WriteLn;
  WriteLn('--- 异常安全测试 ---');
  Test_WithReadLock_ReleasesLockOnException;
  Test_WithWriteLock_ReleasesLockOnException;
  Test_TryWithReadLock_RaisesPoisonErrorAfterException;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.
