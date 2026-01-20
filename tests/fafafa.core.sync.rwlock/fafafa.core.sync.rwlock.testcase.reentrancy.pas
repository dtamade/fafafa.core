unit fafafa.core.sync.rwlock.testcase.reentrancy;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.sync.rwlock, fafafa.core.sync.base, fafafa.core.sync.rwlock.base;

type
  // 可重入性测试用例
  TTestCase_Reentrancy = class(TTestCase)
  private
    FRWLock: IRWLock;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础可重入性测试
    procedure Test_ReadLock_BasicReentrancy;
    procedure Test_WriteLock_BasicReentrancy;
    procedure Test_ReadLock_NestedReentrancy;
    procedure Test_WriteLock_NestedReentrancy;
    
    // 锁降级测试
    procedure Test_WriteLock_DowngradeToRead;
    
    // 错误情况测试
    procedure Test_ReadLock_CannotUpgradeToWrite;
    procedure Test_ReleaseWithoutAcquire;
    procedure Test_MismatchedRelease;
    
    // 非重入配置（AllowReentrancy = False）
    procedure Test_NonReentrantMode_TryReadWrite_BasicUsage;
    
    // 性能测试
    procedure Test_Reentrancy_Performance;
  end;

implementation

{ TTestCase_Reentrancy }

procedure TTestCase_Reentrancy.SetUp;
begin
  inherited SetUp;
  FRWLock := MakeRWLock;
end;

procedure TTestCase_Reentrancy.TearDown;
begin
  FRWLock := nil;
  inherited TearDown;
end;

// ===== 基础可重入性测试 =====

procedure TTestCase_Reentrancy.Test_ReadLock_BasicReentrancy;
begin
  WriteLn('测试: 读锁基础可重入性');
  
  // 第一次获取读锁
  FRWLock.AcquireRead;
  try
    AssertEquals(1, FRWLock.GetReaderCount);
    AssertTrue(FRWLock.IsReadLocked);
    
    // 同一线程再次获取读锁（可重入）
    FRWLock.AcquireRead;
    try
      AssertEquals(2, FRWLock.GetReaderCount);
      AssertTrue(FRWLock.IsReadLocked);
      
      // 第三次获取读锁
      FRWLock.AcquireRead;
      try
        AssertEquals(3, FRWLock.GetReaderCount);
        AssertTrue(FRWLock.IsReadLocked);
      finally
        FRWLock.ReleaseRead;
      end;
      
      AssertEquals(2, FRWLock.GetReaderCount);
    finally
      FRWLock.ReleaseRead;
    end;
    
    AssertEquals(1, FRWLock.GetReaderCount);
  finally
    FRWLock.ReleaseRead;
  end;
  
  AssertEquals(0, FRWLock.GetReaderCount);
  AssertFalse(FRWLock.IsReadLocked);
end;

procedure TTestCase_Reentrancy.Test_WriteLock_BasicReentrancy;
begin
  WriteLn('测试: 写锁基础可重入性');
  
  // 第一次获取写锁
  FRWLock.AcquireWrite;
  try
    AssertTrue(FRWLock.IsWriteLocked);
    AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
    
    // 同一线程再次获取写锁（可重入）
    FRWLock.AcquireWrite;
    try
      AssertTrue(FRWLock.IsWriteLocked);
      AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
      
      // 第三次获取写锁
      FRWLock.AcquireWrite;
      try
        AssertTrue(FRWLock.IsWriteLocked);
        AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
      finally
        FRWLock.ReleaseWrite;
      end;
      
      AssertTrue(FRWLock.IsWriteLocked);
    finally
      FRWLock.ReleaseWrite;
    end;
    
    AssertTrue(FRWLock.IsWriteLocked);
  finally
    FRWLock.ReleaseWrite;
  end;
  
  AssertFalse(FRWLock.IsWriteLocked);
  AssertEquals(0, FRWLock.GetWriterThread);
end;

procedure TTestCase_Reentrancy.Test_ReadLock_NestedReentrancy;
var
  i: Integer;
const
  NESTING_DEPTH = 10;
begin
  WriteLn('测试: 读锁嵌套可重入性');
  
  // 嵌套获取多个读锁
  for i := 1 to NESTING_DEPTH do
  begin
    FRWLock.AcquireRead;
    AssertEquals(i, FRWLock.GetReaderCount);
    AssertTrue(FRWLock.IsReadLocked);
  end;
  
  // 嵌套释放读锁
  for i := NESTING_DEPTH downto 1 do
  begin
    FRWLock.ReleaseRead;
    AssertEquals(i - 1, FRWLock.GetReaderCount);
    if i > 1 then
      AssertTrue(FRWLock.IsReadLocked)
    else
      AssertFalse(FRWLock.IsReadLocked);
  end;
end;

procedure TTestCase_Reentrancy.Test_WriteLock_NestedReentrancy;
var
  i: Integer;
const
  NESTING_DEPTH = 5;
begin
  WriteLn('测试: 写锁嵌套可重入性');
  
  // 嵌套获取多个写锁
  for i := 1 to NESTING_DEPTH do
  begin
    FRWLock.AcquireWrite;
    AssertTrue(FRWLock.IsWriteLocked);
    AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
  end;
  
  // 嵌套释放写锁
  for i := NESTING_DEPTH downto 1 do
  begin
    FRWLock.ReleaseWrite;
    if i > 1 then
    begin
      AssertTrue(FRWLock.IsWriteLocked);
      AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
    end
    else
    begin
      AssertFalse(FRWLock.IsWriteLocked);
      AssertEquals(0, FRWLock.GetWriterThread);
    end;
  end;
end;

// ===== 锁降级测试 =====

procedure TTestCase_Reentrancy.Test_WriteLock_DowngradeToRead;
begin
  WriteLn('测试: 写锁降级为读锁');
  
  // 获取写锁
  FRWLock.AcquireWrite;
  try
    AssertTrue(FRWLock.IsWriteLocked);
    AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
    
    // 在持有写锁的情况下获取读锁（降级）
    FRWLock.AcquireRead;
    try
      AssertTrue(FRWLock.IsWriteLocked);  // 写锁仍然有效
      AssertEquals(1, FRWLock.GetReaderCount);
      AssertTrue(FRWLock.IsReadLocked);
    finally
      FRWLock.ReleaseRead;
    end;
    
    // 读锁释放后，写锁仍然有效
    AssertTrue(FRWLock.IsWriteLocked);
    AssertEquals(0, FRWLock.GetReaderCount);
    AssertFalse(FRWLock.IsReadLocked);
    
  finally
    FRWLock.ReleaseWrite;
  end;
  
  AssertFalse(FRWLock.IsWriteLocked);
end;

// ===== 错误情况测试 =====

procedure TTestCase_Reentrancy.Test_ReadLock_CannotUpgradeToWrite;
begin
  WriteLn('测试: 读锁不能升级为写锁');
  
  // 获取读锁
  FRWLock.AcquireRead;
  try
    AssertTrue(FRWLock.IsReadLocked);
    AssertEquals(1, FRWLock.GetReaderCount);
    
    // 尝试获取写锁应该抛出死锁异常
    try
      FRWLock.AcquireWrite;
      Fail('应该抛出死锁异常');
    except
      on E: ERWLockError do
      begin
        // 预期的异常 - 消息包含 "deadlock" 或 "upgrade not allowed"
        AssertTrue('应包含死锁相关消息', Pos('deadlock', LowerCase(E.Message)) > 0);
      end;
    end;
    
    // 读锁应该仍然有效
    AssertTrue(FRWLock.IsReadLocked);
    AssertEquals(1, FRWLock.GetReaderCount);
    
  finally
    FRWLock.ReleaseRead;
  end;
end;

procedure TTestCase_Reentrancy.Test_ReleaseWithoutAcquire;
begin
  WriteLn('测试: 未获取锁就释放');

  // 尝试释放未获取的读锁
  try
    FRWLock.ReleaseRead;
    Fail('应该抛出状态错误异常');
  except
    on E: ERWLockError do
    begin
      // 预期的异常 - 消息包含 "not held" 或 "Released"
      AssertTrue('应包含锁未持有的消息', Pos('not held', LowerCase(E.Message)) > 0);
    end;
  end;

  // 尝试释放未获取的写锁
  try
    FRWLock.ReleaseWrite;
    Fail('应该抛出状态错误异常');
  except
    on E: ERWLockError do
    begin
      // 预期的异常 - 消息包含 "not held" 或 "Released"
      AssertTrue('应包含锁未持有的消息', Pos('not held', LowerCase(E.Message)) > 0);
    end;
  end;
end;

procedure TTestCase_Reentrancy.Test_MismatchedRelease;
begin
  WriteLn('测试: 不匹配的锁释放');

  // 获取读锁但尝试释放写锁
  FRWLock.AcquireRead;
  try
    try
      FRWLock.ReleaseWrite;
      Fail('应该抛出状态错误异常');
    except
      on E: ERWLockError do
      begin
        // 预期的异常 - 消息包含 "not held"
        AssertTrue('应包含锁未持有的消息', Pos('not held', LowerCase(E.Message)) > 0);
      end;
    end;
  finally
    FRWLock.ReleaseRead;  // 正确释放读锁
  end;
end;

procedure TTestCase_Reentrancy.Test_NonReentrantMode_TryReadWrite_BasicUsage;
var
  Options: TRWLockOptions;
  Lock: IRWLock;
  ReadGuard: IRWLockReadGuard;
  WriteGuard: IRWLockWriteGuard;
begin
  WriteLn('测试: 非重入模式下 TryRead/TryWrite 的基础用法');

  // 配置为非重入模式
  Options := DefaultRWLockOptions;
  Options.AllowReentrancy := False;
  Lock := MakeRWLock(Options);

  // TryRead 在无竞争场景应能成功返回一个读守卫
  ReadGuard := Lock.TryRead(10);
  AssertTrue('非重入模式下 TryRead 应返回有效守卫', Assigned(ReadGuard));
  AssertTrue(ReadGuard.IsLocked);
  ReadGuard.Release;

  // TryWrite 在无竞争场景应能成功返回一个写守卫
  WriteGuard := Lock.TryWrite(10);
  AssertTrue('非重入模式下 TryWrite 应返回有效守卫', Assigned(WriteGuard));
  AssertTrue(WriteGuard.IsLocked);
  WriteGuard.Release;
end;

// ===== 性能测试 =====

procedure TTestCase_Reentrancy.Test_Reentrancy_Performance;
var
  i: Integer;
  StartTime, EndTime: TDateTime;
  Operations: Integer;
  ElapsedMs: Integer;
const
  ITERATIONS = 10000;
begin
  WriteLn('测试: 可重入性性能');

  Operations := 0;
  StartTime := Now;

  for i := 1 to ITERATIONS do
  begin
    // 嵌套读锁
    FRWLock.AcquireRead;
    try
      FRWLock.AcquireRead;
      try
        FRWLock.AcquireRead;
        try
          Inc(Operations, 3);  // 3次获取
        finally
          FRWLock.ReleaseRead;
        end;
      finally
        FRWLock.ReleaseRead;
      end;
    finally
      FRWLock.ReleaseRead;
    end;
    Inc(Operations, 3);  // 3次释放
  end;

  EndTime := Now;
  ElapsedMs := Round((EndTime - StartTime) * 24 * 60 * 60 * 1000);
  if ElapsedMs = 0 then ElapsedMs := 1;  // 避免除零

  WriteLn(Format('可重入性性能: %d ops, %dms, %d ops/sec',
    [Operations, ElapsedMs, Round(Operations / (ElapsedMs / 1000))]));
end;

initialization
  RegisterTest(TTestCase_Reentrancy);

end.
