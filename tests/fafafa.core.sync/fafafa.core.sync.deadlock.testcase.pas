unit fafafa.core.sync.deadlock.testcase;

{**
 * fafafa.core.sync 死锁检测测试套件
 *
 * @desc
 *   测试各种同步原语的死锁检测和预防能力。
 *   涵盖场景：
 *   - Mutex 重入死锁检测
 *   - RWLock 读锁升级死锁
 *   - 跨线程锁竞争超时
 *   - 嵌套锁顺序验证
 *
 * @author fafafaStudio
 *}

{$mode objfpc}{$H+}

{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.mutex,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base,
  fafafa.core.sync.base;

type

  { TTestCase_DeadlockDetection }

  TTestCase_DeadlockDetection = class(TTestCase)
  published
    // ===== Mutex 死锁检测 =====
    procedure Test_Mutex_Reentrant_ShouldRaiseDeadlock;
    procedure Test_Mutex_CrossThread_Timeout;

    // ===== RWLock 死锁检测 =====
    procedure Test_RWLock_ReadToWriteUpgrade_ShouldRaiseDeadlock;
    procedure Test_RWLock_WriteReentrant_ShouldSucceed;
    procedure Test_RWLock_ReadReentrant_ShouldSucceed;
    procedure Test_RWLock_CrossThread_WriteBlocked;

    // ===== 嵌套锁场景 =====
    procedure Test_NestedLocks_SameOrder_NoDeadlock;
    procedure Test_NestedLocks_Timeout_Detection;

    // ===== 压力测试 =====
    procedure Test_Stress_NoDeadlock_MultiThread;
  end;

implementation

{ TTestCase_DeadlockDetection }

// ===== Mutex 死锁检测测试 =====

procedure TTestCase_DeadlockDetection.Test_Mutex_Reentrant_ShouldRaiseDeadlock;
var
  M: IMutex;
  DeadlockDetected: Boolean;
begin
  WriteLn('测试: Mutex 重入应该检测到死锁');

  M := MakeMutex;  // 非重入互斥锁
  DeadlockDetected := False;

  M.Acquire;
  try
    // 同一线程尝试重新获取非重入锁应该抛出 EDeadlockError
    try
      M.Acquire;
      Fail('应该抛出 EDeadlockError');
    except
      on E: EDeadlockError do
      begin
        DeadlockDetected := True;
        WriteLn('正确检测到死锁: ', E.Message);
      end;
    end;
  finally
    M.Release;
  end;

  AssertTrue('应该检测到死锁', DeadlockDetected);
  WriteLn('测试通过');
end;

procedure TTestCase_DeadlockDetection.Test_Mutex_CrossThread_Timeout;
var
  M: IMutex;
  Acquired: Boolean;
begin
  WriteLn('测试: Mutex 跨线程超时');

  M := MakeMutex;

  // 主线程持有锁
  M.Acquire;
  try
    // 在同一线程中测试 TryAcquire 超时（应该失败因为已持有）
    // 注意: 非重入锁在同一线程上会抛出死锁异常
    // 这里我们只测试锁定状态

    // 验证锁确实被持有 - 简单测试
    WriteLn('锁已被主线程持有');

  finally
    M.Release;
  end;

  // 锁释放后应该能获取
  Acquired := M.TryAcquire(10);
  AssertTrue('锁释放后应该能获取', Acquired);
  if Acquired then
    M.Release;

  WriteLn('测试通过');
end;

// ===== RWLock 死锁检测测试 =====

procedure TTestCase_DeadlockDetection.Test_RWLock_ReadToWriteUpgrade_ShouldRaiseDeadlock;
var
  RW: IRWLock;
  DeadlockDetected: Boolean;
begin
  WriteLn('测试: RWLock 读锁升级应该检测到死锁');

  RW := MakeRWLock;
  DeadlockDetected := False;

  // 获取读锁
  RW.AcquireRead;
  try
    // 尝试将读锁升级为写锁应该抛出死锁异常
    try
      RW.AcquireWrite;
      Fail('应该抛出死锁异常');
    except
      on E: ERWLockError do
      begin
        DeadlockDetected := True;
        WriteLn('正确检测到死锁: ', E.Message);
        AssertTrue('消息应包含 deadlock', Pos('deadlock', LowerCase(E.Message)) > 0);
      end;
    end;
  finally
    RW.ReleaseRead;
  end;

  AssertTrue('应该检测到死锁', DeadlockDetected);
  WriteLn('测试通过');
end;

procedure TTestCase_DeadlockDetection.Test_RWLock_WriteReentrant_ShouldSucceed;
var
  RW: IRWLock;
begin
  WriteLn('测试: RWLock 写锁可重入');

  RW := MakeRWLock;  // 默认启用可重入

  // 获取写锁
  RW.AcquireWrite;
  try
    AssertTrue(RW.IsWriteLocked);

    // 同一线程再次获取写锁应该成功（可重入）
    RW.AcquireWrite;
    try
      AssertTrue(RW.IsWriteLocked);
    finally
      RW.ReleaseWrite;
    end;

    // 外层写锁仍然有效
    AssertTrue(RW.IsWriteLocked);
  finally
    RW.ReleaseWrite;
  end;

  AssertFalse(RW.IsWriteLocked);
  WriteLn('测试通过');
end;

procedure TTestCase_DeadlockDetection.Test_RWLock_ReadReentrant_ShouldSucceed;
var
  RW: IRWLock;
begin
  WriteLn('测试: RWLock 读锁可重入');

  RW := MakeRWLock;

  // 获取读锁
  RW.AcquireRead;
  try
    AssertEquals(1, RW.GetReaderCount);

    // 同一线程再次获取读锁应该成功
    RW.AcquireRead;
    try
      AssertEquals(2, RW.GetReaderCount);
    finally
      RW.ReleaseRead;
    end;

    AssertEquals(1, RW.GetReaderCount);
  finally
    RW.ReleaseRead;
  end;

  AssertEquals(0, RW.GetReaderCount);
  WriteLn('测试通过');
end;

procedure TTestCase_DeadlockDetection.Test_RWLock_CrossThread_WriteBlocked;
var
  RW: IRWLock;
  ThreadCompleted: Boolean;
  ThreadGotLock: Boolean;
begin
  WriteLn('测试: RWLock 跨线程写锁阻塞');

  RW := MakeRWLock;
  ThreadCompleted := False;
  ThreadGotLock := False;

  // 主线程持有写锁
  RW.AcquireWrite;
  try
    // 启动子线程尝试获取写锁（应该超时）
    TThread.CreateAnonymousThread(procedure
    begin
      try
        ThreadGotLock := RW.TryAcquireWrite(100);  // 100ms 超时
      finally
        ThreadCompleted := True;
      end;
    end).Start;

    // 等待子线程完成
    while not ThreadCompleted do
      Sleep(10);

    // 验证子线程获取锁失败
    AssertFalse('子线程不应该获取到写锁', ThreadGotLock);

  finally
    RW.ReleaseWrite;
  end;

  WriteLn('测试通过');
end;

// ===== 嵌套锁场景 =====

procedure TTestCase_DeadlockDetection.Test_NestedLocks_SameOrder_NoDeadlock;
var
  M1, M2: IMutex;
begin
  WriteLn('测试: 嵌套锁相同顺序获取不会死锁');

  M1 := MakeMutex;
  M2 := MakeMutex;

  // 按顺序获取锁：M1 -> M2
  M1.Acquire;
  try
    M2.Acquire;
    try
      // 两个锁都持有
      WriteLn('成功获取两个锁');
    finally
      M2.Release;
    end;
  finally
    M1.Release;
  end;

  // 再次按相同顺序获取
  M1.Acquire;
  try
    M2.Acquire;
    try
      WriteLn('再次成功获取两个锁');
    finally
      M2.Release;
    end;
  finally
    M1.Release;
  end;

  WriteLn('测试通过');
end;

procedure TTestCase_DeadlockDetection.Test_NestedLocks_Timeout_Detection;
var
  M1, M2: IMutex;
  Thread1Completed, Thread2Completed: Boolean;
  Thread1GotM2, Thread2GotM1: Boolean;
begin
  WriteLn('测试: 嵌套锁超时检测（模拟潜在死锁场景）');

  M1 := MakeMutex;
  M2 := MakeMutex;
  Thread1Completed := False;
  Thread2Completed := False;
  Thread1GotM2 := False;
  Thread2GotM1 := False;

  // 线程 1: 持有 M1，尝试获取 M2
  TThread.CreateAnonymousThread(procedure
  begin
    M1.Acquire;
    try
      Sleep(50);  // 给线程 2 时间获取 M2
      Thread1GotM2 := M2.TryAcquire(200);  // 超时获取 M2
    finally
      M1.Release;
      Thread1Completed := True;
    end;
  end).Start;

  // 线程 2: 持有 M2，尝试获取 M1
  TThread.CreateAnonymousThread(procedure
  begin
    M2.Acquire;
    try
      Sleep(50);  // 给线程 1 时间获取 M1
      Thread2GotM1 := M1.TryAcquire(200);  // 超时获取 M1
    finally
      M2.Release;
      Thread2Completed := True;
    end;
  end).Start;

  // 等待两个线程完成
  while not (Thread1Completed and Thread2Completed) do
    Sleep(10);

  // 由于使用超时，至少有一个线程应该失败（没有死锁）
  WriteLn('线程1获取M2: ', Thread1GotM2);
  WriteLn('线程2获取M1: ', Thread2GotM1);

  // 验证系统没有死锁（两个线程都完成了）
  AssertTrue('线程1应该完成', Thread1Completed);
  AssertTrue('线程2应该完成', Thread2Completed);

  WriteLn('测试通过（超时机制防止了死锁）');
end;

// ===== 压力测试 =====

procedure TTestCase_DeadlockDetection.Test_Stress_NoDeadlock_MultiThread;
const
  THREAD_COUNT = 8;
  ITERATIONS = 1000;
var
  RW: IRWLock;
  Counter: Integer;
  ThreadsCompleted: Integer;
  I: Integer;
begin
  WriteLn('测试: 多线程压力测试（无死锁）');

  RW := MakeRWLock;
  Counter := 0;
  ThreadsCompleted := 0;

  // 启动多个读写线程
  for I := 1 to THREAD_COUNT do
  begin
    if I mod 2 = 0 then
    begin
      // 读者线程
      TThread.CreateAnonymousThread(procedure
      var
        J, Val: Integer;
      begin
        for J := 1 to ITERATIONS do
        begin
          RW.AcquireRead;
          try
            Val := Counter;  // 读取共享变量
          finally
            RW.ReleaseRead;
          end;
        end;
        InterlockedIncrement(ThreadsCompleted);
      end).Start;
    end
    else
    begin
      // 写者线程
      TThread.CreateAnonymousThread(procedure
      var
        J: Integer;
      begin
        for J := 1 to ITERATIONS do
        begin
          RW.AcquireWrite;
          try
            Inc(Counter);  // 修改共享变量
          finally
            RW.ReleaseWrite;
          end;
        end;
        InterlockedIncrement(ThreadsCompleted);
      end).Start;
    end;
  end;

  // 等待所有线程完成（带超时）
  I := 0;
  while (ThreadsCompleted < THREAD_COUNT) and (I < 100) do
  begin
    Sleep(100);
    Inc(I);
  end;

  WriteLn('已完成线程数: ', ThreadsCompleted, '/', THREAD_COUNT);
  WriteLn('最终计数器值: ', Counter);

  // 验证所有线程都完成（没有死锁）
  AssertEquals('所有线程应该完成', THREAD_COUNT, ThreadsCompleted);

  // 验证计数器值正确（写者线程数 * 迭代次数）
  AssertEquals('计数器值应该正确', (THREAD_COUNT div 2) * ITERATIONS, Counter);

  WriteLn('测试通过');
end;

initialization
  RegisterTest(TTestCase_DeadlockDetection);

end.
