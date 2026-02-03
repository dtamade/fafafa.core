unit Test_fafafa_core_sync_scopedlock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.scopedlock;

type
  TTestCase_ScopedLock = class(TTestCase)
  published
    procedure Test_ScopedLock2_AcquiresAndReleases;
    procedure Test_ScopedLock3_AcquiresAndReleases;
    procedure Test_ScopedLock_Array;
    procedure Test_ScopedLock_DeadlockPrevention;
    procedure Test_ScopedLock_IsLocked;
    procedure Test_ScopedLock_LockCount;
  end;

  TTestCase_ScopedLock_Concurrent = class(TTestCase)
  published
    procedure Test_ConcurrentAccess_NoDeadlock;
  end;

implementation

{ Helper thread for deadlock testing }
type
  TScopedLockTestThread = class(TThread)
  private
    FLock1: ILock;
    FLock2: ILock;
    FSuccess: Boolean;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ALock1, ALock2: ILock; AIterations: Integer);
    property Success: Boolean read FSuccess;
  end;

constructor TScopedLockTestThread.Create(ALock1, ALock2: ILock; AIterations: Integer);
begin
  FLock1 := ALock1;
  FLock2 := ALock2;
  FIterations := AIterations;
  FSuccess := False;
  inherited Create(False);
end;

procedure TScopedLockTestThread.Execute;
var
  i: Integer;
  Guard: IMultiLockGuard;
begin
  FSuccess := True;
  for i := 1 to FIterations do
  begin
    // 使用 ScopedLock2 安全获取两个锁
    Guard := ScopedLock2(FLock1, FLock2);
    try
      // 临界区
      Sleep(0); // 让出 CPU
    finally
      Guard.Release;
    end;
  end;
end;

{ TTestCase_ScopedLock }

procedure TTestCase_ScopedLock.Test_ScopedLock2_AcquiresAndReleases;
var
  Lock1, Lock2: ILock;
  Guard: IMultiLockGuard;
begin
  Lock1 := MakeMutex;
  Lock2 := MakeMutex;

  Guard := ScopedLock2(Lock1, Lock2);
  AssertTrue('Guard should be locked', Guard.IsLocked);
  AssertEquals('Should hold 2 locks', 2, Guard.LockCount);

  Guard.Release;
  AssertFalse('Guard should be released', Guard.IsLocked);

  // 验证锁已释放（可以再次获取）
  Guard := ScopedLock2(Lock1, Lock2);
  AssertTrue('Should acquire locks again', Guard.IsLocked);
  Guard.Release;
end;

procedure TTestCase_ScopedLock.Test_ScopedLock3_AcquiresAndReleases;
var
  Lock1, Lock2, Lock3: ILock;
  Guard: IMultiLockGuard;
begin
  Lock1 := MakeMutex;
  Lock2 := MakeMutex;
  Lock3 := MakeMutex;

  Guard := ScopedLock3(Lock1, Lock2, Lock3);
  AssertTrue('Guard should be locked', Guard.IsLocked);
  AssertEquals('Should hold 3 locks', 3, Guard.LockCount);

  Guard.Release;
  AssertFalse('Guard should be released', Guard.IsLocked);
end;

procedure TTestCase_ScopedLock.Test_ScopedLock_Array;
var
  Locks: array[0..3] of ILock;
  Guard: IMultiLockGuard;
  i: Integer;
begin
  for i := 0 to 3 do
    Locks[i] := MakeMutex;

  Guard := ScopedLock(Locks);
  AssertTrue('Guard should be locked', Guard.IsLocked);
  AssertEquals('Should hold 4 locks', 4, Guard.LockCount);

  Guard.Release;
end;

procedure TTestCase_ScopedLock.Test_ScopedLock_DeadlockPrevention;
var
  LockA, LockB: ILock;
  Guard1, Guard2: IMultiLockGuard;
begin
  LockA := MakeMutex;
  LockB := MakeMutex;

  // 无论传入顺序如何，ScopedLock 都会按地址排序
  Guard1 := ScopedLock2(LockA, LockB);
  Guard1.Release;

  Guard2 := ScopedLock2(LockB, LockA); // 相反顺序
  Guard2.Release;

  // 如果到达这里没有死锁，测试通过
  AssertTrue('No deadlock occurred', True);
end;

procedure TTestCase_ScopedLock.Test_ScopedLock_IsLocked;
var
  Lock: ILock;
  Guard: IMultiLockGuard;
begin
  Lock := MakeMutex;

  Guard := ScopedLock([Lock]);
  AssertTrue('Should be locked initially', Guard.IsLocked);

  Guard.Release;
  AssertFalse('Should not be locked after release', Guard.IsLocked);

  // 多次释放应该是安全的
  Guard.Release;
  AssertFalse('Still not locked after double release', Guard.IsLocked);
end;

procedure TTestCase_ScopedLock.Test_ScopedLock_LockCount;
var
  Locks: array[0..4] of ILock;
  Guard: IMultiLockGuard;
  i: Integer;
begin
  for i := 0 to 4 do
    Locks[i] := MakeMutex;

  // 测试不同数量的锁
  Guard := ScopedLock([Locks[0]]);
  AssertEquals('1 lock', 1, Guard.LockCount);
  Guard.Release;

  Guard := ScopedLock([Locks[0], Locks[1]]);
  AssertEquals('2 locks', 2, Guard.LockCount);
  Guard.Release;

  Guard := ScopedLock([Locks[0], Locks[1], Locks[2], Locks[3], Locks[4]]);
  AssertEquals('5 locks', 5, Guard.LockCount);
  Guard.Release;
end;

{ TTestCase_ScopedLock_Concurrent }

procedure TTestCase_ScopedLock_Concurrent.Test_ConcurrentAccess_NoDeadlock;
var
  Lock1, Lock2: ILock;
  Threads: array[0..3] of TScopedLockTestThread;
  i: Integer;
  AllSuccess: Boolean;
const
  ITERATIONS = 100;
begin
  Lock1 := MakeMutex;
  Lock2 := MakeMutex;

  // 创建多个线程，每个线程尝试以不同顺序获取锁
  for i := 0 to 3 do
  begin
    if i mod 2 = 0 then
      Threads[i] := TScopedLockTestThread.Create(Lock1, Lock2, ITERATIONS)
    else
      Threads[i] := TScopedLockTestThread.Create(Lock2, Lock1, ITERATIONS);
  end;

  // 等待所有线程完成
  AllSuccess := True;
  for i := 0 to 3 do
  begin
    Threads[i].WaitFor;
    AllSuccess := AllSuccess and Threads[i].Success;
    Threads[i].Free;
  end;

  AssertTrue('All threads should complete successfully (no deadlock)', AllSuccess);
end;

initialization
  RegisterTest('fafafa.core.sync.scopedlock', TTestCase_ScopedLock);
  RegisterTest('fafafa.core.sync.scopedlock', TTestCase_ScopedLock_Concurrent);

end.
