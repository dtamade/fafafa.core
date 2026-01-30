program test_mutex_guard_lifecycle;

{**
 * Mutex Guard 生命周期和异常安全测试
 *
 * 测试 Guard 的生命周期管理和异常安全性
 *
 * 测试覆盖:
 * 1. TryLock/TryLockFor 返回 nil 的安全处理
 * 2. Guard 在异常情况下的 RAII 保证
 * 3. 多个 Guard 同时失效的边界情况
 * 4. Guard 析构器在异常传播时的安全性
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
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
// 测试 1: TryLock 返回 nil 的安全处理
// ============================================================================
procedure Test_TryLock_NilHandling;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
begin
  WriteLn('Test: TryLock Nil Handling');

  M := MakeMutex;

  // 先获取锁
  Guard1 := M.Lock;
  try
    // TryLock 应该返回 nil
    Guard2 := M.TryLock;
    Assert(not Assigned(Guard2), 'TryLock should return nil when lock is held');
    
    // 确保可以安全地检查 nil
    if Assigned(Guard2) then
      Assert(False, 'Guard2 should be nil')
    else
      Assert(True, 'Guard2 is nil as expected');
  finally
    Guard1 := nil;
  end;

  // 释放后 TryLock 应该成功
  Guard1 := M.TryLock;
  try
    Assert(Assigned(Guard1), 'TryLock should succeed after release');
  finally
    Guard1 := nil;
  end;
end;

// ============================================================================
// 测试 2: TryLockFor 返回 nil 的安全处理
// ============================================================================
procedure Test_TryLockFor_NilHandling;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
begin
  WriteLn('Test: TryLockFor Nil Handling');

  M := MakeMutex;

  // 先获取锁
  Guard1 := M.Lock;
  try
    // 零超时应该立即返回 nil
    Guard2 := M.TryLockFor(0);
    Assert(not Assigned(Guard2), 'TryLockFor(0) should return nil when lock is held');
    
    // 短超时也应该返回 nil
    Guard2 := M.TryLockFor(10);
    Assert(not Assigned(Guard2), 'TryLockFor(10) should return nil when lock is held');
  finally
    Guard1 := nil;
  end;

  // 释放后 TryLockFor 应该成功
  Guard1 := M.TryLockFor(100);
  try
    Assert(Assigned(Guard1), 'TryLockFor should succeed after release');
  finally
    Guard1 := nil;
  end;
end;

// ============================================================================
// 测试 3: Guard 在异常情况下的 RAII 保证
// ============================================================================
procedure Test_Guard_RAII_ExceptionSafety;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
  ExceptionRaised: Boolean;
begin
  WriteLn('Test: Guard RAII Exception Safety');

  M := MakeMutex;
  ExceptionRaised := False;

  // 测试异常情况下 Guard 自动释放
  try
    Guard1 := M.Lock;
    try
      Assert(Assigned(Guard1), 'Lock should succeed');
      // 模拟异常
      raise Exception.Create('Test exception');
    finally
      Guard1 := nil;
    end;
  except
    on E: Exception do
      ExceptionRaised := True;
  end;

  Assert(ExceptionRaised, 'Exception should be raised');

  // 验证锁已被释放（应该可以立即获取）
  Guard2 := M.TryLock;
  try
    Assert(Assigned(Guard2), 'Lock should be released after exception');
  finally
    Guard2 := nil;
  end;
end;

// ============================================================================
// 测试 4: 多个 Guard 同时失效的边界情况
// ============================================================================
procedure Test_MultipleGuards_SimultaneousRelease;
var
  M1, M2, M3: IMutex;
  Guard1, Guard2, Guard3: ILockGuard;
  Guard1_2, Guard2_2, Guard3_2: ILockGuard;
begin
  WriteLn('Test: Multiple Guards Simultaneous Release');

  M1 := MakeMutex;
  M2 := MakeMutex;
  M3 := MakeMutex;

  // 获取多个锁
  Guard1 := M1.Lock;
  Guard2 := M2.Lock;
  Guard3 := M3.Lock;

  Assert(Assigned(Guard1), 'Guard1 should be assigned');
  Assert(Assigned(Guard2), 'Guard2 should be assigned');
  Assert(Assigned(Guard3), 'Guard3 should be assigned');

  // 同时释放所有 Guard
  Guard1 := nil;
  Guard2 := nil;
  Guard3 := nil;

  // 验证所有锁都已释放
  Guard1_2 := M1.TryLock;
  Guard2_2 := M2.TryLock;
  Guard3_2 := M3.TryLock;

  try
    Assert(Assigned(Guard1_2), 'M1 should be released');
    Assert(Assigned(Guard2_2), 'M2 should be released');
    Assert(Assigned(Guard3_2), 'M3 should be released');
  finally
    Guard1_2 := nil;
    Guard2_2 := nil;
    Guard3_2 := nil;
  end;
end;

// ============================================================================
// 测试 5: Guard 析构器在异常传播时的安全性
// ============================================================================
procedure Test_Guard_DestructorSafety_ExceptionPropagation;
var
  M: IMutex;
  Guard: ILockGuard;
  ExceptionCaught: Boolean;
  LockReleasedAfterException: Boolean;
begin
  WriteLn('Test: Guard Destructor Safety During Exception Propagation');

  M := MakeMutex;
  ExceptionCaught := False;
  LockReleasedAfterException := False;

  // 测试异常传播时 Guard 析构器的安全性
  try
    Guard := M.Lock;
    try
      Assert(Assigned(Guard), 'Lock should succeed');
      // 在 Guard 作用域内抛出异常
      raise Exception.Create('Test exception in guard scope');
    finally
      // 即使有异常，也应该正常释放
      Guard := nil;
    end;
  except
    on E: Exception do
    begin
      ExceptionCaught := True;
      // 验证锁已被释放
      Guard := M.TryLock;
      LockReleasedAfterException := Assigned(Guard);
      Guard := nil;
    end;
  end;

  Assert(ExceptionCaught, 'Exception should be caught');
  Assert(LockReleasedAfterException, 'Lock should be released after exception');
end;

// ============================================================================
// 测试 6: Guard 重新赋值的安全性
// ============================================================================
procedure Test_Guard_ReassignmentSafety;
var
  M: IMutex;
  Guard: ILockGuard;
  Guard2: ILockGuard;
begin
  WriteLn('Test: Guard Reassignment Safety');

  M := MakeMutex;

  // 第一次获取锁
  Guard := M.Lock;
  Assert(Assigned(Guard), 'First lock should succeed');

  // 重新赋值应该释放旧锁
  Guard := nil;

  // 验证锁已释放
  Guard2 := M.TryLock;
  Assert(Assigned(Guard2), 'Lock should be released after reassignment to nil');
  Guard2 := nil;

  // 再次获取锁
  Guard := M.Lock;
  Assert(Assigned(Guard), 'Second lock should succeed');
  
  // 释放锁
  Guard := nil;
  
  // 验证可以再次获取
  Guard := M.Lock;
  Assert(Assigned(Guard), 'Third lock should succeed');

  Guard := nil;
end;

// ============================================================================
// 测试 7: Guard 在嵌套作用域中的行为
// ============================================================================
procedure Test_Guard_NestedScope;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
  
  procedure NestedProc;
  var
    InnerGuard: ILockGuard;
  begin
    // 尝试在嵌套过程中获取锁（应该失败）
    InnerGuard := M.TryLock;
    Assert(not Assigned(InnerGuard), 'Nested TryLock should fail when outer guard holds lock');
  end;
  
begin
  WriteLn('Test: Guard Nested Scope Behavior');

  M := MakeMutex;

  // 外层获取锁
  Guard1 := M.Lock;
  try
    Assert(Assigned(Guard1), 'Outer lock should succeed');
    
    // 调用嵌套过程
    NestedProc;
    
  finally
    Guard1 := nil;
  end;

  // 验证锁已释放
  Guard2 := M.TryLock;
  try
    Assert(Assigned(Guard2), 'Lock should be released after outer scope');
  finally
    Guard2 := nil;
  end;
end;

// ============================================================================
// 测试 8: Guard 在多线程环境下的异常安全性
// ============================================================================
type
  TExceptionThread = class(TThread)
  private
    FMutex: IMutex;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex);
    property Success: Boolean read FSuccess;
  end;

constructor TExceptionThread.Create(AMutex: IMutex);
begin
  inherited Create(True);
  FMutex := AMutex;
  FSuccess := False;
  FreeOnTerminate := False;
end;

procedure TExceptionThread.Execute;
var
  Guard: ILockGuard;
begin
  try
    Guard := FMutex.Lock;
    try
      // 模拟异常
      raise Exception.Create('Thread exception');
    finally
      Guard := nil;
    end;
  except
    on E: Exception do
      FSuccess := True; // 异常被正确捕获
  end;
end;

procedure Test_Guard_MultiThread_ExceptionSafety;
var
  M: IMutex;
  Thread: TExceptionThread;
  Guard: ILockGuard;
begin
  WriteLn('Test: Guard Multi-Thread Exception Safety');

  M := MakeMutex;

  // 创建线程并在其中抛出异常
  Thread := TExceptionThread.Create(M);
  Thread.Start;
  Thread.WaitFor;

  Assert(Thread.Success, 'Thread exception should be caught');

  // 验证锁已被释放（主线程应该可以获取）
  Guard := M.TryLock;
  try
    Assert(Assigned(Guard), 'Lock should be released after thread exception');
  finally
    Guard := nil;
  end;

  Thread.Free;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Mutex Guard Lifecycle Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_TryLock_NilHandling;
    Test_TryLockFor_NilHandling;
    Test_Guard_RAII_ExceptionSafety;
    Test_MultipleGuards_SimultaneousRelease;
    Test_Guard_DestructorSafety_ExceptionPropagation;
    Test_Guard_ReassignmentSafety;
    Test_Guard_NestedScope;
    Test_Guard_MultiThread_ExceptionSafety;

    WriteLn('');
    WriteLn('========================================');
    WriteLn('  Test Summary');
    WriteLn('========================================');
    WriteLn('  Passed: ', TestsPassed);
    WriteLn('  Failed: ', TestsFailed);
    WriteLn('  Total:  ', TestsPassed + TestsFailed);
    WriteLn('========================================');
    WriteLn('');

    if TestsFailed > 0 then
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
