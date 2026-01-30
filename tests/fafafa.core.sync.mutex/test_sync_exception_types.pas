program test_sync_exception_types;

{**
 * 同步原语异常类型完整性测试
 *
 * 测试所有同步原语的异常类型和错误场景
 *
 * 测试覆盖:
 * 1. ESyncError - 基础同步异常
 * 2. ELockError - 锁操作异常
 * 3. ESyncTimeoutError - 超时异常
 * 4. EDeadlockError - 死锁检测异常
 * 5. EInvalidArgument - 无效参数异常
 * 6. EOnceRecursiveCall - Once 递归调用异常
 *}

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.once;

var
  LTestsPassed: Integer = 0;
  LTestsFailed: Integer = 0;

procedure Assert(aCondition: Boolean; const aMsg: string);
begin
  if aCondition then
  begin
    Inc(LTestsPassed);
    WriteLn('  ✓ ', aMsg);
  end
  else
  begin
    Inc(LTestsFailed);
    WriteLn('  ✗ FAIL: ', aMsg);
  end;
end;

// ============================================================================
// 测试 1: ESyncError 基础异常类型
// ============================================================================
procedure Test_ESyncError_BaseException;
var
  LException: ESyncError;
begin
  WriteLn('Test: ESyncError Base Exception Type');

  try
    LException := ESyncError.Create('Test sync error');
    try
      Assert(LException is ESyncError, 'Should be ESyncError type');
      Assert(LException.Message = 'Test sync error', 'Message should match');
    finally
      LException.Free;
    end;
  except
    on E: Exception do
      Assert(False, 'Should not raise exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 2: ELockError 锁操作异常
// ============================================================================
procedure Test_ELockError_LockException;
var
  LException: ELockError;
begin
  WriteLn('Test: ELockError Lock Exception Type');

  try
    LException := ELockError.Create('Test lock error');
    try
      Assert(LException is ELockError, 'Should be ELockError type');
      Assert(LException is ESyncError, 'Should inherit from ESyncError');
      Assert(LException.Message = 'Test lock error', 'Message should match');
    finally
      LException.Free;
    end;
  except
    on E: Exception do
      Assert(False, 'Should not raise exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 3: ESyncTimeoutError 超时异常
// ============================================================================
procedure Test_ESyncTimeoutError_TimeoutException;
var
  LException: ESyncTimeoutError;
begin
  WriteLn('Test: ESyncTimeoutError Timeout Exception Type');

  try
    LException := ESyncTimeoutError.Create('Test timeout error');
    try
      Assert(LException is ESyncTimeoutError, 'Should be ESyncTimeoutError type');
      Assert(LException is ESyncError, 'Should inherit from ESyncError');
      Assert(LException.Message = 'Test timeout error', 'Message should match');
    finally
      LException.Free;
    end;
  except
    on E: Exception do
      Assert(False, 'Should not raise exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 4: EDeadlockError 死锁检测异常
// ============================================================================
procedure Test_EDeadlockError_DeadlockException;
var
  LException: EDeadlockError;
begin
  WriteLn('Test: EDeadlockError Deadlock Exception Type');

  try
    LException := EDeadlockError.Create('Test deadlock error');
    try
      Assert(LException is EDeadlockError, 'Should be EDeadlockError type');
      Assert(LException is ESyncError, 'Should inherit from ESyncError');
      Assert(LException.Message = 'Test deadlock error', 'Message should match');
    finally
      LException.Free;
    end;
  except
    on E: Exception do
      Assert(False, 'Should not raise exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 5: EInvalidArgument 无效参数异常
// ============================================================================
procedure Test_EInvalidArgument_InvalidArgumentException;
var
  LException: EInvalidArgument;
begin
  WriteLn('Test: EInvalidArgument Invalid Argument Exception Type');

  try
    LException := EInvalidArgument.Create('Test invalid argument error');
    try
      Assert(LException is EInvalidArgument, 'Should be EInvalidArgument type');
      Assert(LException is ESyncError, 'Should inherit from ESyncError');
      Assert(LException.Message = 'Test invalid argument error', 'Message should match');
    finally
      LException.Free;
    end;
  except
    on E: Exception do
      Assert(False, 'Should not raise exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 6: EOnceRecursiveCall Once 递归调用异常
// ============================================================================
procedure Test_EOnceRecursiveCall_RecursiveCallException;
var
  LException: EOnceRecursiveCall;
begin
  WriteLn('Test: EOnceRecursiveCall Recursive Call Exception Type');

  try
    LException := EOnceRecursiveCall.Create('Test recursive call error');
    try
      Assert(LException is EOnceRecursiveCall, 'Should be EOnceRecursiveCall type');
      Assert(LException is ELockError, 'Should inherit from ELockError');
      Assert(LException is ESyncError, 'Should inherit from ESyncError');
      Assert(LException.Message = 'Test recursive call error', 'Message should match');
    finally
      LException.Free;
    end;
  except
    on E: Exception do
      Assert(False, 'Should not raise exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 7: 异常继承层次验证
// ============================================================================
procedure Test_ExceptionHierarchy;
var
  LLockError: ELockError;
  LTimeoutError: ESyncTimeoutError;
  LDeadlockError: EDeadlockError;
  LInvalidArgument: EInvalidArgument;
  LOnceRecursive: EOnceRecursiveCall;
begin
  WriteLn('Test: Exception Hierarchy Validation');

  // ELockError 继承自 ESyncError
  LLockError := ELockError.Create('Lock error');
  try
    Assert(LLockError is ESyncError, 'ELockError should inherit from ESyncError');
  finally
    LLockError.Free;
  end;

  // ESyncTimeoutError 继承自 ESyncError
  LTimeoutError := ESyncTimeoutError.Create('Timeout error');
  try
    Assert(LTimeoutError is ESyncError, 'ESyncTimeoutError should inherit from ESyncError');
  finally
    LTimeoutError.Free;
  end;

  // EDeadlockError 继承自 ESyncError
  LDeadlockError := EDeadlockError.Create('Deadlock error');
  try
    Assert(LDeadlockError is ESyncError, 'EDeadlockError should inherit from ESyncError');
  finally
    LDeadlockError.Free;
  end;

  // EInvalidArgument 继承自 ESyncError
  LInvalidArgument := EInvalidArgument.Create('Invalid argument');
  try
    Assert(LInvalidArgument is ESyncError, 'EInvalidArgument should inherit from ESyncError');
  finally
    LInvalidArgument.Free;
  end;

  // EOnceRecursiveCall 继承自 ELockError 和 ESyncError
  LOnceRecursive := EOnceRecursiveCall.Create('Recursive call');
  try
    Assert(LOnceRecursive is ELockError, 'EOnceRecursiveCall should inherit from ELockError');
    Assert(LOnceRecursive is ESyncError, 'EOnceRecursiveCall should inherit from ESyncError');
  finally
    LOnceRecursive.Free;
  end;
end;

// ============================================================================
// 测试 8: 异常捕获和处理
// ============================================================================
procedure Test_ExceptionCatchingAndHandling;
var
  LCaught: Boolean;
begin
  WriteLn('Test: Exception Catching and Handling');

  // 测试捕获 ESyncError
  LCaught := False;
  try
    raise ESyncError.Create('Test sync error');
  except
    on E: ESyncError do
      LCaught := True;
  end;
  Assert(LCaught, 'Should catch ESyncError');

  // 测试捕获 ELockError
  LCaught := False;
  try
    raise ELockError.Create('Test lock error');
  except
    on E: ELockError do
      LCaught := True;
  end;
  Assert(LCaught, 'Should catch ELockError');

  // 测试捕获 ESyncTimeoutError
  LCaught := False;
  try
    raise ESyncTimeoutError.Create('Test timeout error');
  except
    on E: ESyncTimeoutError do
      LCaught := True;
  end;
  Assert(LCaught, 'Should catch ESyncTimeoutError');

  // 测试捕获 EDeadlockError
  LCaught := False;
  try
    raise EDeadlockError.Create('Test deadlock error');
  except
    on E: EDeadlockError do
      LCaught := True;
  end;
  Assert(LCaught, 'Should catch EDeadlockError');

  // 测试捕获 EInvalidArgument
  LCaught := False;
  try
    raise EInvalidArgument.Create('Test invalid argument');
  except
    on E: EInvalidArgument do
      LCaught := True;
  end;
  Assert(LCaught, 'Should catch EInvalidArgument');

  // 测试捕获 EOnceRecursiveCall
  LCaught := False;
  try
    raise EOnceRecursiveCall.Create('Test recursive call');
  except
    on E: EOnceRecursiveCall do
      LCaught := True;
  end;
  Assert(LCaught, 'Should catch EOnceRecursiveCall');
end;

// ============================================================================
// 测试 9: 多级异常捕获
// ============================================================================
procedure Test_MultiLevelExceptionCatching;
var
  LCaughtAsBase: Boolean;
  LCaughtAsSpecific: Boolean;
begin
  WriteLn('Test: Multi-Level Exception Catching');

  // 测试 ELockError 可以被 ESyncError 捕获
  LCaughtAsBase := False;
  try
    raise ELockError.Create('Test lock error');
  except
    on E: ESyncError do
      LCaughtAsBase := True;
  end;
  Assert(LCaughtAsBase, 'ELockError should be catchable as ESyncError');

  // 测试 EOnceRecursiveCall 可以被 ELockError 捕获
  LCaughtAsBase := False;
  try
    raise EOnceRecursiveCall.Create('Test recursive call');
  except
    on E: ELockError do
      LCaughtAsBase := True;
  end;
  Assert(LCaughtAsBase, 'EOnceRecursiveCall should be catchable as ELockError');

  // 测试 EOnceRecursiveCall 可以被 ESyncError 捕获
  LCaughtAsBase := False;
  try
    raise EOnceRecursiveCall.Create('Test recursive call');
  except
    on E: ESyncError do
      LCaughtAsBase := True;
  end;
  Assert(LCaughtAsBase, 'EOnceRecursiveCall should be catchable as ESyncError');

  // 测试特定异常优先捕获
  LCaughtAsSpecific := False;
  LCaughtAsBase := False;
  try
    raise EOnceRecursiveCall.Create('Test recursive call');
  except
    on E: EOnceRecursiveCall do
      LCaughtAsSpecific := True;
    on E: ELockError do
      LCaughtAsBase := True;
  end;
  Assert(LCaughtAsSpecific, 'Should catch specific exception first');
  Assert(not LCaughtAsBase, 'Should not reach base exception handler');
end;

// ============================================================================
// 测试 10: 异常消息完整性
// ============================================================================
procedure Test_ExceptionMessageIntegrity;
const
  TEST_MESSAGE = 'Test exception message with special chars: 中文测试 !@#$%^&*()';
var
  LException: ESyncError;
begin
  WriteLn('Test: Exception Message Integrity');

  try
    LException := ESyncError.Create(TEST_MESSAGE);
    try
      Assert(LException.Message = TEST_MESSAGE, 'Message should preserve all characters');
    finally
      LException.Free;
    end;
  except
    on E: Exception do
      Assert(False, 'Should not raise exception: ' + E.Message);
  end;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Sync Exception Types Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_ESyncError_BaseException;
    Test_ELockError_LockException;
    Test_ESyncTimeoutError_TimeoutException;
    Test_EDeadlockError_DeadlockException;
    Test_EInvalidArgument_InvalidArgumentException;
    Test_EOnceRecursiveCall_RecursiveCallException;
    Test_ExceptionHierarchy;
    Test_ExceptionCatchingAndHandling;
    Test_MultiLevelExceptionCatching;
    Test_ExceptionMessageIntegrity;

    WriteLn('');
    WriteLn('========================================');
    WriteLn('  Test Summary');
    WriteLn('========================================');
    WriteLn('  Passed: ', LTestsPassed);
    WriteLn('  Failed: ', LTestsFailed);
    WriteLn('  Total:  ', LTestsPassed + LTestsFailed);
    WriteLn('========================================');
    WriteLn('');

    if LTestsFailed > 0 then
    begin
      WriteLn('FAILED: Some tests did not pass');
      Halt(1);
    end
    else
    begin
      WriteLn('SUCCESS: All tests passed');
      Halt(0);
    end;
  except
    on E: Exception do
    begin
      WriteLn('');
      WriteLn('FATAL ERROR: ', E.Message);
      Halt(2);
    end;
  end;
end.
