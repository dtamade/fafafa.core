program fafafa_core_sync_mutex_poison_test;

{**
 * IMutex Poisoning 测试
 *
 * TDD: 红 → 绿 → 重构
 * 测试 Mutex 的 Poisoning 机制 (Rust-style panic safety)
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync, fafafa.core.sync.base, fafafa.core.sync.mutex.base;

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

procedure AssertFalse(const Cond: Boolean; const Msg: string);
begin
  AssertTrue(not Cond, Msg);
end;

// ===== Test Cases =====

procedure Test_Mutex_IsPoisoned_InitiallyFalse;
var
  M: IMutex;
begin
  M := MakeMutex;
  AssertFalse(M.IsPoisoned, 'Mutex should not be poisoned initially');
end;

procedure Test_Mutex_ClearPoison;
var
  M: IMutex;
begin
  M := MakeMutex;
  // 获取锁并手动标记为 poisoned (模拟异常)
  M.Acquire;
  M.MarkPoisoned('Test exception');
  M.Release;
  
  AssertTrue(M.IsPoisoned, 'Mutex should be poisoned after MarkPoisoned');
  
  M.ClearPoison;
  AssertFalse(M.IsPoisoned, 'Mutex should not be poisoned after ClearPoison');
end;

procedure Test_Mutex_Acquire_PoisonedThrows;
var
  M: IMutex;
  ExceptionCaught: Boolean;
begin
  M := MakeMutex;
  
  // 标记为 poisoned
  M.Acquire;
  M.MarkPoisoned('Test exception');
  M.Release;
  
  // 再次获取应抛异常
  ExceptionCaught := False;
  try
    M.Acquire;
  except
    on E: EMutexPoisonError do
      ExceptionCaught := True;
  end;
  
  AssertTrue(ExceptionCaught, 'Acquire on poisoned mutex should throw EMutexPoisonError');
end;

procedure Test_Mutex_TryAcquire_PoisonedThrows;
var
  M: IMutex;
  ExceptionCaught: Boolean;
begin
  M := MakeMutex;
  
  // 标记为 poisoned
  M.Acquire;
  M.MarkPoisoned('Test exception');
  M.Release;
  
  // TryAcquire 成功后也应抛异常
  ExceptionCaught := False;
  try
    M.TryAcquire;
  except
    on E: EMutexPoisonError do
      ExceptionCaught := True;
  end;
  
  AssertTrue(ExceptionCaught, 'TryAcquire on poisoned mutex should throw EMutexPoisonError');
end;

procedure Test_Mutex_TryLock_PoisonedReturnsNil;
var
  M: IMutex;
  G: ILockGuard;
  CaughtException: Boolean;
begin
  M := MakeMutex;
  
  // 标记为 poisoned
  M.Acquire;
  M.MarkPoisoned('Test exception');
  M.Release;
  
  // TryLock() 应返回 nil 或抛异常取决于实现
  // 当前实现: TryLock 调用 TryAcquire，成功后检查 poison 并抛异常
  CaughtException := False;
  try
    G := M.TryLock;
    // 如果获取锁失败（但当前锁未被占用，应得到锁）
    if G <> nil then
      AssertTrue(False, 'Should not reach here - TryLock returned guard on poisoned mutex');
  except
    on E: EMutexPoisonError do
      CaughtException := True;
  end;
  
  AssertTrue(CaughtException, 'TryLock on poisoned mutex should throw EMutexPoisonError');
end;

// ===== Main =====

begin
  WriteLn('=== IMutex Poisoning Test ===');
  WriteLn;

  Test_Mutex_IsPoisoned_InitiallyFalse;
  Test_Mutex_ClearPoison;
  Test_Mutex_Acquire_PoisonedThrows;
  Test_Mutex_TryAcquire_PoisonedThrows;
  Test_Mutex_TryLock_PoisonedReturnsNil;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.
