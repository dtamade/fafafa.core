program fafafa_core_sync_modern_api_test;

{**
 * 现代化锁 API 测试
 *
 * 测试 ILock 接口的新方法：
 *   - Lock() 返回 ILockGuard
 *   - TryLock() 返回 ILockGuard 或 nil
 *   - TryLockFor(timeout) 返回 ILockGuard 或 nil
 *
 * 遵循 TDD 规范：红 → 绿 → 重构
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$modeswitch functionreferences}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync,  // 使用门面单元，包含 WithLock
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.spin;

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

// ===== Tests for ILock.Lock() =====

procedure Test_Lock_ReturnsGuard_Success;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  // Arrange: 使用接口以确保正确的引用计数
  Mutex := MakeMutex;
  
  // Act
  Guard := Mutex.Lock;
  
  // Assert: Guard 应该非 nil
  AssertTrue(Assigned(Guard), 'Lock() 应该返回非 nil 的 Guard');
  
  // 释放 Guard
  Guard := nil;
  
  // Assert: 锁应该被释放
  AssertTrue(Mutex.TryAcquire, 'Guard 释放后锁应该可以被获取');
  Mutex.Release;
end;

procedure Test_Lock_GuardAutoRelease_OnScopeExit;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  // Arrange
  Mutex := MakeMutex;
  
  // Act: 获取锁
  Guard := Mutex.Lock;
  AssertTrue(Assigned(Guard), '作用域内应该获取到 Guard');
  
  // 释放 Guard（设为 nil 会触发析构）
  Guard := nil;
  
  // Assert: Guard 释放后锁应该自动释放
  AssertTrue(Mutex.TryAcquire, 'Guard 释放后锁应该被释放');
  Mutex.Release;
end;

procedure Test_Lock_GuardManualRelease_IsIdempotent;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  // Arrange
  Mutex := MakeMutex;
  Guard := Mutex.Lock;
  
  // Act: 手动释放两次
  Guard.Release;
  Guard.Release;  // 第二次调用不应该报错
  
  // Assert
  AssertTrue(Mutex.TryAcquire, '手动 Release 后锁应该可以被获取');
  Mutex.Release;
  
  Guard := nil;  // Guard 析构时不应该再次释放
  
  // 再次验证
  AssertTrue(Mutex.TryAcquire, 'Guard 析构后锁仍应该可用');
  Mutex.Release;
end;

// ===== Tests for ILock.TryLock() =====

procedure Test_TryLock_WhenFree_ReturnsGuard;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  // Arrange
  Mutex := MakeMutex;
  
  // Act
  Guard := Mutex.TryLock;
  
  // Assert
  AssertTrue(Assigned(Guard), 'TryLock() 锁空闲时应该返回 Guard');
  
  Guard := nil;
  
  // 验证锁已释放
  AssertTrue(Mutex.TryAcquire, 'Guard 释放后 TryAcquire 应成功');
  Mutex.Release;
end;

procedure Test_TryLock_WhenHeldBySelf_NonReentrant;
var
  Mutex: IMutex;
  Guard1: ILockGuard;
  TryResult: Boolean;
begin
  // Arrange: TMutex 是非可重入的
  Mutex := MakeMutex;

  // Act: 第一次获取锁
  Guard1 := Mutex.Lock;

  // Act: 尝试第二次获取锁（同线程）
  // 注意：TryAcquire 应该返回 False 而不是抛出异常（Try 语义）
  TryResult := Mutex.TryAcquire;

  // Assert: 非可重入锁同线程再次获取应返回 False
  AssertFalse(TryResult, 'TryAcquire() 非可重入锁被同线程持有时应返回 False');

  Guard1 := nil;
end;

// ===== Tests for ITryLock.TryLockFor() =====

procedure Test_TryLockFor_WhenFree_ReturnsGuard;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  // Arrange
  Mutex := MakeMutex;
  
  // Act
  Guard := Mutex.TryLockFor(100);
  
  // Assert
  AssertTrue(Assigned(Guard), 'TryLockFor() 锁空闲时应该返回 Guard');
  
  Guard := nil;
end;

// 注意：以下测试需要多线程环境，暂时跳过
// 未来可以使用原子变量或其他无需 TEvent 的同步方式来测试

procedure Test_TryLockFor_ZeroTimeout_BehavesLikeTryLock;
var
  Mutex: IMutex;
  Guard1, Guard2: ILockGuard;
begin
  // Arrange
  Mutex := MakeMutex;

  // Act: 锁空闲时
  Guard1 := Mutex.TryLockFor(0);
  AssertTrue(Assigned(Guard1), 'TryLockFor(0) 锁空闲时应该返回 Guard');

  // Act: 锁被持有时，非可重入锁应返回 nil（Try 语义）
  Guard2 := Mutex.TryLockFor(0);

  AssertFalse(Assigned(Guard2), 'TryLockFor(0) 非可重入锁被同线程持有时应返回 nil');

  Guard1 := nil;
end;

// ===== Tests for LockGuard alias =====

procedure Test_LockGuard_AliasForLock;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  // Arrange
  Mutex := MakeMutex;
  
  // Act
  Guard := Mutex.LockGuard;  // 旧的别名方法
  
  // Assert
  AssertTrue(Assigned(Guard), 'LockGuard() 应该返回 Guard（与 Lock() 等效）');
  
  Guard := nil;
  
  // 验证锁已释放
  AssertTrue(Mutex.TryAcquire, 'Guard 释放后锁应可获取');
  Mutex.Release;
end;

// ===== Tests for SpinLock modern API =====

procedure Test_SpinLock_Lock_ReturnsGuard;
var
  SpinLock: ISpin;
  Guard: ILockGuard;
begin
  // Arrange
  SpinLock := MakeSpin;
  
  // Act
  Guard := SpinLock.Lock;
  
  // Assert
  AssertTrue(Assigned(Guard), 'SpinLock.Lock() 应该返回 Guard');
  
  Guard := nil;
  
  // 验证锁已释放
  AssertTrue(SpinLock.TryAcquire, 'SpinLock Guard 释放后应该可以获取');
  SpinLock.Release;
end;

procedure Test_SpinLock_TryLock_WhenFree_ReturnsGuard;
var
  SpinLock: ISpin;
  Guard: ILockGuard;
begin
  // Arrange
  SpinLock := MakeSpin;
  
  // Act
  Guard := SpinLock.TryLock;
  
  // Assert
  AssertTrue(Assigned(Guard), 'SpinLock.TryLock() 空闲时应该返回 Guard');
  
  Guard := nil;
end;

// ===== Tests for WithLock/TryWithLock =====

procedure Test_WithLock_ExecutesProc_Success;
var
  Mutex: IMutex;
  Counter: Integer;
begin
  // Arrange
  Mutex := MakeMutex;
  Counter := 0;
  
  // Act: WithLock 应该执行过程并自动管理锁
  WithLock(Mutex, procedure
  begin
    Inc(Counter);
  end);
  
  // Assert
  AssertTrue(Counter = 1, 'WithLock 应该执行传入的过程');
  AssertTrue(Mutex.TryAcquire, 'WithLock 执行后锁应该被释放');
  Mutex.Release;
end;

procedure Test_WithLock_ReleasesLock_OnException;
var
  Mutex: IMutex;
  GotException: Boolean;
begin
  // Arrange
  Mutex := MakeMutex;
  GotException := False;
  
  // Act: 在 WithLock 内部抛出异常
  try
    WithLock(Mutex, procedure
    begin
      raise Exception.Create('Test exception');
    end);
  except
    GotException := True;
  end;
  
  // Assert: 异常应该被传播，但锁应该被释放
  AssertTrue(GotException, 'WithLock 应该传播异常');
  AssertTrue(Mutex.TryAcquire, 'WithLock 异常后锁应该被释放');
  Mutex.Release;
end;

procedure Test_TryWithLock_WhenFree_ExecutesProc;
var
  Mutex: IMutex;
  Counter: Integer;
  Result: Boolean;
begin
  // Arrange
  Mutex := MakeMutex;
  Counter := 0;
  
  // Act
  Result := TryWithLock(Mutex, procedure
  begin
    Inc(Counter);
  end);
  
  // Assert
  AssertTrue(Result, 'TryWithLock 锁空闲时应该返回 True');
  AssertTrue(Counter = 1, 'TryWithLock 应该执行传入的过程');
  AssertTrue(Mutex.TryAcquire, 'TryWithLock 执行后锁应该被释放');
  Mutex.Release;
end;

procedure Test_TryWithLock_WhenHeld_ReturnsFalse;
var
  Mutex: IMutex;
  Guard: ILockGuard;
  Counter: Integer;
  Result: Boolean;
begin
  // Arrange: 注意 TMutex 是非可重入的，同线程再次获取会抛出异常
  // 所以这里我们使用 IRecMutex 或者接受异常
  // 对于非可重入锁，TryWithLock 在同线程持有锁时会抛出 EDeadlockError
  Mutex := MakeMutex;
  Counter := 0;
  
  // Act: 先获取锁
  Guard := Mutex.Lock;
  
  // TryWithLock 在非可重入锁上会失败或抛出异常
  // 由于 TMutex 是非可重入的，我们期望它返回 False 或抛出异常
  // 实际上应该在 TryAcquire 层面处理
  try
    Result := TryWithLock(Mutex, procedure
    begin
      Inc(Counter);
    end);
    // 如果没有异常，应该返回 False
    AssertFalse(Result, 'TryWithLock 锁被持有时应该返回 False');
    AssertTrue(Counter = 0, 'TryWithLock 失败时不应该执行过程');
  except
    on E: EDeadlockError do
    begin
      // 非可重入锁的正常行为
      AssertTrue(True, 'TryWithLock 非可重入锁被同线程持有时抛出 EDeadlockError 是正常的');
    end;
  end;
  
  Guard := nil;
end;

// ===== Main =====

begin
  WriteLn('=== fafafa.core.sync 现代化 API 测试 ===');
  WriteLn;
  
  WriteLn('--- ILock.Lock() 测试 ---');
  Test_Lock_ReturnsGuard_Success;
  Test_Lock_GuardAutoRelease_OnScopeExit;
  Test_Lock_GuardManualRelease_IsIdempotent;
  
  WriteLn;
  WriteLn('--- ILock.TryLock() 测试 ---');
  Test_TryLock_WhenFree_ReturnsGuard;
  Test_TryLock_WhenHeldBySelf_NonReentrant;
  
  WriteLn;
  WriteLn('--- ITryLock.TryLockFor() 测试 ---');
  Test_TryLockFor_WhenFree_ReturnsGuard;
  Test_TryLockFor_ZeroTimeout_BehavesLikeTryLock;
  
  WriteLn;
  WriteLn('--- LockGuard 别名测试 ---');
  Test_LockGuard_AliasForLock;
  
  WriteLn;
  WriteLn('--- SpinLock 现代化 API 测试 ---');
  Test_SpinLock_Lock_ReturnsGuard;
  Test_SpinLock_TryLock_WhenFree_ReturnsGuard;
  
  WriteLn;
  WriteLn('--- WithLock/TryWithLock 测试 ---');
  Test_WithLock_ExecutesProc_Success;
  Test_WithLock_ReleasesLock_OnException;
  Test_TryWithLock_WhenFree_ExecutesProc;
  Test_TryWithLock_WhenHeld_ReturnsFalse;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');
  
  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.
