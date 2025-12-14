program fafafa_core_sync_guard_test;

{**
 * IGuard 统一接口测试
 *
 * 验证所有 Guard 类型都实现统一的 IGuard 基接口
 *
 * 遵循 TDD：先红再绿
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base;

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

// ===== Tests for IGuard unified interface =====

procedure Test_ILockGuard_ImplementsIGuard;
var
  M: IMutex;
  Guard: ILockGuard;
begin
  M := MakeMutex;
  Guard := M.Lock;
  try
    // ILockGuard 继承自 IGuard，所以可以直接调用 IGuard 方法
    AssertTrue(Assigned(Guard), 'ILockGuard 应该被创建');
    AssertTrue(Guard.IsLocked, 'Guard.IsLocked 应该为 True');
  finally
    Guard.Release;
    AssertFalse(Guard.IsLocked, 'Release 后 IsLocked 应该为 False');
  end;
end;

procedure Test_IRWLockReadGuard_ImplementsIGuard;
var
  RW: IRWLock;
  Guard: IRWLockReadGuard;
begin
  RW := MakeRWLock;
  Guard := RW.Read;
  try
    // IRWLockReadGuard 继承自 IGuard，所以可以直接调用 IGuard 方法
    AssertTrue(Assigned(Guard), 'IRWLockReadGuard 应该被创建');
    AssertTrue(Guard.IsLocked, 'ReadGuard.IsLocked 应该为 True');
  finally
    Guard.Release;
    AssertFalse(Guard.IsLocked, 'Release 后 IsLocked 应该为 False');
  end;
end;

procedure Test_IRWLockWriteGuard_ImplementsIGuard;
var
  RW: IRWLock;
  Guard: IRWLockWriteGuard;
begin
  RW := MakeRWLock;
  Guard := RW.Write;
  try
    // IRWLockWriteGuard 继承自 IGuard，所以可以直接调用 IGuard 方法
    AssertTrue(Assigned(Guard), 'IRWLockWriteGuard 应该被创建');
    AssertTrue(Guard.IsLocked, 'WriteGuard.IsLocked 应该为 True');
  finally
    Guard.Release;
    AssertFalse(Guard.IsLocked, 'Release 后 IsLocked 应该为 False');
  end;
end;

procedure Test_Guard_Polymorphism;
var
  M: IMutex;
  MutexGuard: ILockGuard;
begin
  M := MakeMutex;
  
  // 简化测试：只测试 Mutex
  MutexGuard := M.Lock;
  AssertTrue(MutexGuard.IsLocked, 'MutexGuard 应该是锁定状态');
  MutexGuard.Release;
  AssertFalse(MutexGuard.IsLocked, 'MutexGuard 释放后应该是未锁定状态');
end;

// ===== Main =====
begin
  WriteLn('=== fafafa.core.sync.guard (IGuard 统一接口) 测试 ===');
  WriteLn;

  WriteLn('--- IGuard 实现测试 ---');
  Test_ILockGuard_ImplementsIGuard;
  Test_IRWLockReadGuard_ImplementsIGuard;
  Test_IRWLockWriteGuard_ImplementsIGuard;
  
  WriteLn;
  WriteLn('--- 多态性测试 ---');
  Test_Guard_Polymorphism;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then Halt(1) else Halt(0);
end.
