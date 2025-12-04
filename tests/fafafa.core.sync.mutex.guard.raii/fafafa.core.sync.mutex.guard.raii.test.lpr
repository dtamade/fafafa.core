program fafafa_core_sync_mutex_guard_raii_test;

{**
 * TMutexGuard<T> 扩展 API 测试
 *
 * 验证新增的 API：
 *   - LockPtr
 *   - GetMut 无锁访问
 *
 * TDD: 红 → 绿 → 重构
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.mutex.guard;

type
  TIntegerMutexGuard = specialize TMutexGuard<Integer>;

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

// ===== LockPtr 测试 =====

procedure Test_LockPtr_ReturnsDataPointer;
var
  MG: TIntegerMutexGuard;
  Ptr: ^Integer;
begin
  // Arrange
  MG := TIntegerMutexGuard.Create(42);
  try
    // Act
    Ptr := MG.LockPtr;

    // Assert
    AssertTrue(Assigned(Ptr), 'LockPtr 应该返回有效指针');
    AssertEquals(42, Ptr^, 'LockPtr 应该返回正确的值');
    AssertTrue(MG.IsLocked, 'LockPtr 后应该已锁定');

    // Cleanup
    MG.Unlock;
  finally
    MG.Free;
  end;
end;

procedure Test_LockPtr_CanModifyValue;
var
  MG: TIntegerMutexGuard;
  Ptr: ^Integer;
begin
  // Arrange
  MG := TIntegerMutexGuard.Create(10);
  try
    // Act: 使用 LockPtr 修改值
    Ptr := MG.LockPtr;
    Ptr^ := Ptr^ + 5;
    MG.Unlock;

    // Assert
    AssertEquals(15, MG.GetValue, 'LockPtr 应该能够修改值');
  finally
    MG.Free;
  end;
end;

procedure Test_Lock_EqualsLockPtr;
var
  MG: TIntegerMutexGuard;
  Ptr1, Ptr2: ^Integer;
begin
  // Arrange
  MG := TIntegerMutexGuard.Create(42);
  try
    // Act
    {$PUSH}{$WARN 6058 OFF} // 忽略 deprecated 警告
    Ptr1 := MG.Lock;
    MG.Unlock;
    Ptr2 := MG.LockPtr;
    MG.Unlock;
    {$POP}

    // Assert: Lock 和 LockPtr 返回相同的指针
    AssertTrue(Ptr1 = Ptr2, 'Lock 和 LockPtr 应该返回相同的指针');
  finally
    MG.Free;
  end;
end;

// ===== GetMut 测试 =====

procedure Test_GetMut_ReturnsPointerWithoutLocking;
var
  MG: TIntegerMutexGuard;
  Ptr: ^Integer;
begin
  // Arrange
  MG := TIntegerMutexGuard.Create(42);
  try
    // Act
    Ptr := MG.GetMut;

    // Assert
    AssertTrue(Assigned(Ptr), 'GetMut 应该返回有效指针');
    AssertEquals(42, Ptr^, 'GetMut 应该返回正确的值');
    AssertTrue(not MG.IsLocked, 'GetMut 不应该获取锁');
  finally
    MG.Free;
  end;
end;

procedure Test_GetMut_CanModifyValueWithoutLock;
var
  MG: TIntegerMutexGuard;
  Ptr: ^Integer;
begin
  // Arrange
  MG := TIntegerMutexGuard.Create(42);
  try
    // Act: 无锁修改
    Ptr := MG.GetMut;
    Ptr^ := 100;

    // Assert
    AssertEquals(100, MG.GetValue, 'GetMut 应该能够无锁修改值');
  finally
    MG.Free;
  end;
end;

// ===== Main =====

begin
  WriteLn('=== TMutexGuard<T> 扩展 API 测试 ===');
  WriteLn;

  WriteLn('--- LockPtr 测试 ---');
  Test_LockPtr_ReturnsDataPointer;
  Test_LockPtr_CanModifyValue;
  Test_Lock_EqualsLockPtr;

  WriteLn;
  WriteLn('--- GetMut 测试 ---');
  Test_GetMut_ReturnsPointerWithoutLocking;
  Test_GetMut_CanModifyValueWithoutLock;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.
