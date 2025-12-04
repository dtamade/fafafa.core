program fafafa_core_sync_rwlock_guard_raii_test;

{**
 * TRwLockGuard<T> 扩展 API 测试
 *
 * 验证新增的 API：
 *   - ReadLockPtr / WriteLockPtr
 *   - GetMut 无锁访问
 *   - IntoInner 消费获取值
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
  fafafa.core.sync.rwlock.guard;

type
  TIntegerRwLockGuard = specialize TRwLockGuard<Integer>;

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

// ===== ReadLockPtr 测试 =====

procedure Test_ReadLockPtr_ReturnsDataPointer;
var
  RG: TIntegerRwLockGuard;
  Ptr: ^Integer;
begin
  RG := TIntegerRwLockGuard.Create(42);
  try
    Ptr := RG.ReadLockPtr;
    AssertTrue(Assigned(Ptr), 'ReadLockPtr 应该返回有效指针');
    AssertEquals(42, Ptr^, 'ReadLockPtr 应该返回正确的值');
    AssertTrue(RG.IsReadLocked, 'ReadLockPtr 后应该已读锁定');
    RG.ReadUnlock;
  finally
    RG.Free;
  end;
end;

procedure Test_ReadLock_EqualsReadLockPtr;
var
  RG: TIntegerRwLockGuard;
  Ptr1, Ptr2: ^Integer;
begin
  RG := TIntegerRwLockGuard.Create(42);
  try
    Ptr1 := RG.ReadLock;
    RG.ReadUnlock;
    Ptr2 := RG.ReadLockPtr;
    RG.ReadUnlock;
    AssertTrue(Ptr1 = Ptr2, 'ReadLock 和 ReadLockPtr 应该返回相同的指针');
  finally
    RG.Free;
  end;
end;

// ===== WriteLockPtr 测试 =====

procedure Test_WriteLockPtr_ReturnsDataPointer;
var
  RG: TIntegerRwLockGuard;
  Ptr: ^Integer;
begin
  RG := TIntegerRwLockGuard.Create(42);
  try
    Ptr := RG.WriteLockPtr;
    AssertTrue(Assigned(Ptr), 'WriteLockPtr 应该返回有效指针');
    AssertEquals(42, Ptr^, 'WriteLockPtr 应该返回正确的值');
    AssertTrue(RG.IsWriteLocked, 'WriteLockPtr 后应该已写锁定');
    RG.WriteUnlock;
  finally
    RG.Free;
  end;
end;

procedure Test_WriteLockPtr_CanModifyValue;
var
  RG: TIntegerRwLockGuard;
  Ptr: ^Integer;
begin
  RG := TIntegerRwLockGuard.Create(10);
  try
    Ptr := RG.WriteLockPtr;
    Ptr^ := Ptr^ + 5;
    RG.WriteUnlock;
    AssertEquals(15, RG.GetValue, 'WriteLockPtr 应该能够修改值');
  finally
    RG.Free;
  end;
end;

// ===== GetMut 测试 =====

procedure Test_GetMut_ReturnsPointerWithoutLocking;
var
  RG: TIntegerRwLockGuard;
  Ptr: ^Integer;
begin
  RG := TIntegerRwLockGuard.Create(42);
  try
    Ptr := RG.GetMut;
    AssertTrue(Assigned(Ptr), 'GetMut 应该返回有效指针');
    AssertEquals(42, Ptr^, 'GetMut 应该返回正确的值');
    AssertTrue(not RG.IsReadLocked, 'GetMut 不应该获取读锁');
    AssertTrue(not RG.IsWriteLocked, 'GetMut 不应该获取写锁');
  finally
    RG.Free;
  end;
end;

procedure Test_GetMut_CanModifyValueWithoutLock;
var
  RG: TIntegerRwLockGuard;
  Ptr: ^Integer;
begin
  RG := TIntegerRwLockGuard.Create(42);
  try
    Ptr := RG.GetMut;
    Ptr^ := 100;
    AssertEquals(100, RG.GetValue, 'GetMut 应该能够无锁修改值');
  finally
    RG.Free;
  end;
end;

// ===== IntoInner 测试 =====

procedure Test_IntoInner_ReturnsValueAndClears;
var
  RG: TIntegerRwLockGuard;
  Value: Integer;
begin
  RG := TIntegerRwLockGuard.Create(42);
  try
    Value := RG.IntoInner;
    AssertEquals(42, Value, 'IntoInner 应该返回正确的值');
    // 注意：调用 IntoInner 后内部值被清空，但容器仍可用
    AssertEquals(0, RG.GetValue, 'IntoInner 后内部值应该被清空');
  finally
    RG.Free;
  end;
end;

// ===== Main =====

begin
  WriteLn('=== TRwLockGuard<T> 扩展 API 测试 ===');
  WriteLn;

  WriteLn('--- ReadLockPtr 测试 ---');
  Test_ReadLockPtr_ReturnsDataPointer;
  Test_ReadLock_EqualsReadLockPtr;

  WriteLn;
  WriteLn('--- WriteLockPtr 测试 ---');
  Test_WriteLockPtr_ReturnsDataPointer;
  Test_WriteLockPtr_CanModifyValue;

  WriteLn;
  WriteLn('--- GetMut 测试 ---');
  Test_GetMut_ReturnsPointerWithoutLocking;
  Test_GetMut_CanModifyValueWithoutLock;

  WriteLn;
  WriteLn('--- IntoInner 测试 ---');
  Test_IntoInner_ReturnsValueAndClears;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.
