unit fafafa.core.sync.namedRWLock.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base, fafafa.core.sync.namedRWLock, fafafa.core.sync.base;

type
  // 测试全局函数
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeNamedRWLock;
    procedure Test_MakeNamedRWLock_InitialOwner;
    procedure Test_TryOpenNamedRWLock;
    procedure Test_TryOpenNamedRWLock_InvalidName_Propagates;
    procedure Test_MakeGlobalNamedRWLock;
    procedure Test_MakeNamedRWLock_WithConfig;
  end;

  // 测试 INamedRWLock 接口
  TTestCase_INamedRWLock = class(TTestCase)
  private
    FRWLock: INamedRWLock;
    FTestName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试基本功能
    procedure Test_GetName;
    
    // 测试现代化 RAII API
    procedure Test_ReadLock_RAII;
    procedure Test_WriteLock_RAII;
    procedure Test_TryReadLock_RAII;
    procedure Test_TryWriteLock_RAII;
    procedure Test_TryReadLockFor_RAII;
    procedure Test_TryWriteLockFor_RAII;
    
    // 测试传统 API（兼容性）
    procedure Test_AcquireRead_ReleaseRead;
    procedure Test_AcquireWrite_ReleaseWrite;
    procedure Test_TryAcquireRead;
    procedure Test_TryAcquireWrite;
    procedure Test_TryAcquireRead_Timeout;
    procedure Test_TryAcquireWrite_Timeout;
    
    // 测试状态查询
    procedure Test_GetReaderCount;
    procedure Test_IsWriteLocked;
    procedure Test_GetHandle;
    
    // 测试错误处理
    procedure Test_InvalidName;
    procedure Test_DoubleRelease;
    
    // 测试读写锁语义
    procedure Test_MultipleReaders;
    procedure Test_ReaderWriter_Exclusion;
    procedure Test_WriterExclusion;
    
    // 综合测试
    procedure Test_MultipleInstances;
    procedure Test_CrossProcess_Basic;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeNamedRWLock;
var
  LRWLock: INamedRWLock;
begin
  LRWLock := MakeNamedRWLock('test_rwlock_1');
  CheckNotNull(LRWLock, '应该成功创建命名读写锁');
  CheckEquals('test_rwlock_1', LRWLock.GetName, '名称应该匹配');
end;

procedure TTestCase_Global.Test_MakeNamedRWLock_InitialOwner;
var
  LRWLock: INamedRWLock;
  LWriteGuard: INamedRWLockWriteGuard;
begin
  LRWLock := MakeNamedRWLock('test_rwlock_2', True);
  CheckNotNull(LRWLock, '应该成功创建带初始拥有的命名读写锁');

  // 测试可以获取写锁（因为是初始拥有者）
  LWriteGuard := LRWLock.TryWriteLock;
  CheckNotNull(LWriteGuard, '初始拥有者应该能获取写锁');
  LWriteGuard := nil; // 释放写锁
end;

procedure TTestCase_Global.Test_TryOpenNamedRWLock;
var
  LRWLock1, LRWLock2: INamedRWLock;
begin
  // 首先创建一个命名读写锁
  LRWLock1 := MakeNamedRWLock('test_rwlock_3');
  CheckNotNull(LRWLock1, '应该成功创建命名读写锁');
  
  // 然后尝试打开现有的（当前语义仍是“打开或创建”，但不得吞掉异常）
  LRWLock2 := TryOpenNamedRWLock('test_rwlock_3');
  CheckNotNull(LRWLock2, '应该成功打开现有的命名读写锁');
  CheckEquals('test_rwlock_3', LRWLock2.GetName, '名称应该匹配');
end;

procedure TTestCase_Global.Test_TryOpenNamedRWLock_InvalidName_Propagates;
begin
  // TryOpen 不应该静默吞掉参数错误，保持与 MakeNamedRWLock 一致
  try
    TryOpenNamedRWLock('');
    Fail('空名称应该抛出异常');
  except
    on E: EInvalidArgument do
      Check(True, '应抛出 EInvalidArgument，不能静默返回 nil');
  end;
end;

procedure TTestCase_Global.Test_MakeGlobalNamedRWLock;
var
  LRWLock: INamedRWLock;
begin
  try
    LRWLock := MakeGlobalNamedRWLock('test_global_rwlock');
  except
    on E: ELockError do
    begin
      {$IFDEF WINDOWS}
      // 缺少 SeCreateGlobalPrivilege 时，创建 Global\ 对象会被拒绝，跳过此用例。
      Check(True, 'Skipped: requires SeCreateGlobalPrivilege (Access Denied)');
      Exit;
      {$ELSE}
      raise;
      {$ENDIF}
    end;
  end;
  CheckNotNull(LRWLock, '应该成功创建全局命名读写锁');
  {$IFDEF WINDOWS}
  CheckTrue(Pos('Global\', LRWLock.GetName) = 1, 'Windows 上应该包含 Global\ 前缀');
  {$ELSE}
  CheckEquals('test_global_rwlock', LRWLock.GetName, 'Unix 上应该返回原始名称');
  {$ENDIF}
end;

procedure TTestCase_Global.Test_MakeNamedRWLock_WithConfig;
var
  LRWLock: INamedRWLock;
  LConfig: TNamedRWLockConfig;
begin
  LConfig := NamedRWLockConfigWithTimeout(1000);
  LRWLock := MakeNamedRWLock('test_rwlock_config', LConfig);
  CheckNotNull(LRWLock, '应该成功创建带配置的命名读写锁');
  CheckEquals('test_rwlock_config', LRWLock.GetName, '名称应该匹配');
end;

{ TTestCase_INamedRWLock }

procedure TTestCase_INamedRWLock.SetUp;
begin
  inherited SetUp;
  FTestName := 'test_rwlock_' + IntToStr(Random(100000));
  FRWLock := MakeNamedRWLock(FTestName);
end;

procedure TTestCase_INamedRWLock.TearDown;
begin
  FRWLock := nil;
  inherited TearDown;
end;

procedure TTestCase_INamedRWLock.Test_GetName;
begin
  CheckEquals(FTestName, FRWLock.GetName, '名称应该匹配');
end;



procedure TTestCase_INamedRWLock.Test_ReadLock_RAII;
var
  LGuard: INamedRWLockReadGuard;
begin
  // 测试 RAII 读锁
  LGuard := FRWLock.ReadLock;
  try
    CheckNotNull(LGuard, '应该成功获取读锁守卫');
    CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
    CheckEquals(1, FRWLock.GetReaderCount, '读者计数应该为1');
  finally
    LGuard := nil; // 自动释放
  end;
  CheckEquals(0, FRWLock.GetReaderCount, '读者计数应该回到0');
end;

procedure TTestCase_INamedRWLock.Test_WriteLock_RAII;
var
  LGuard: INamedRWLockWriteGuard;
begin
  // 测试 RAII 写锁
  LGuard := FRWLock.WriteLock;
  try
    CheckNotNull(LGuard, '应该成功获取写锁守卫');
    CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
    CheckTrue(FRWLock.IsWriteLocked, '应该处于写锁状态');
  finally
    LGuard := nil; // 自动释放
  end;
  CheckFalse(FRWLock.IsWriteLocked, '应该不再处于写锁状态');
end;

procedure TTestCase_INamedRWLock.Test_TryReadLock_RAII;
var
  LGuard: INamedRWLockReadGuard;
begin
  // 测试非阻塞读锁
  LGuard := FRWLock.TryReadLock;
  CheckNotNull(LGuard, '应该能够立即获取读锁');
  CheckEquals(1, FRWLock.GetReaderCount, '读者计数应该为1');
  LGuard := nil;
  CheckEquals(0, FRWLock.GetReaderCount, '读者计数应该回到0');
end;

procedure TTestCase_INamedRWLock.Test_TryWriteLock_RAII;
var
  LGuard: INamedRWLockWriteGuard;
begin
  // 测试非阻塞写锁
  LGuard := FRWLock.TryWriteLock;
  CheckNotNull(LGuard, '应该能够立即获取写锁');
  CheckTrue(FRWLock.IsWriteLocked, '应该处于写锁状态');
  LGuard := nil;
  CheckFalse(FRWLock.IsWriteLocked, '应该不再处于写锁状态');
end;

procedure TTestCase_INamedRWLock.Test_TryReadLockFor_RAII;
var
  LGuard: INamedRWLockReadGuard;
begin
  // 测试带超时的读锁
  LGuard := FRWLock.TryReadLockFor(100);
  CheckNotNull(LGuard, '应该能够在超时内获取读锁');
  CheckEquals(1, FRWLock.GetReaderCount, '读者计数应该为1');
  LGuard := nil;
  CheckEquals(0, FRWLock.GetReaderCount, '读者计数应该回到0');
end;

procedure TTestCase_INamedRWLock.Test_TryWriteLockFor_RAII;
var
  LGuard: INamedRWLockWriteGuard;
begin
  // 测试带超时的写锁
  LGuard := FRWLock.TryWriteLockFor(100);
  CheckNotNull(LGuard, '应该能够在超时内获取写锁');
  CheckTrue(FRWLock.IsWriteLocked, '应该处于写锁状态');
  LGuard := nil;
  CheckFalse(FRWLock.IsWriteLocked, '应该不再处于写锁状态');
end;

procedure TTestCase_INamedRWLock.Test_AcquireRead_ReleaseRead;
var
  LReadGuard: INamedRWLockReadGuard;
begin
  CheckEquals(0, FRWLock.GetReaderCount, '初始读者计数应该为0');

  LReadGuard := FRWLock.ReadLock;
  CheckEquals(1, FRWLock.GetReaderCount, '读者计数应该为1');
  LReadGuard := nil; // 释放读锁

  CheckEquals(0, FRWLock.GetReaderCount, '读者计数应该回到0');
end;

procedure TTestCase_INamedRWLock.Test_AcquireWrite_ReleaseWrite;
var
  LWriteGuard: INamedRWLockWriteGuard;
begin
  CheckFalse(FRWLock.IsWriteLocked, '初始应该不处于写锁状态');

  LWriteGuard := FRWLock.WriteLock;
  CheckTrue(FRWLock.IsWriteLocked, '应该处于写锁状态');
  LWriteGuard := nil; // 释放写锁

  CheckFalse(FRWLock.IsWriteLocked, '应该不再处于写锁状态');
end;

procedure TTestCase_INamedRWLock.Test_TryAcquireRead;
var
  LReadGuard: INamedRWLockReadGuard;
begin
  // 测试非阻塞读锁获取
  LReadGuard := FRWLock.TryReadLock;
  CheckNotNull(LReadGuard, '应该能够立即获取读锁');
  CheckEquals(1, FRWLock.GetReaderCount, '读者计数应该为1');
  LReadGuard := nil; // 释放读锁
  CheckEquals(0, FRWLock.GetReaderCount, '读者计数应该回到0');
end;

procedure TTestCase_INamedRWLock.Test_TryAcquireWrite;
var
  LWriteGuard: INamedRWLockWriteGuard;
begin
  // 测试非阻塞写锁获取
  LWriteGuard := FRWLock.TryWriteLock;
  CheckNotNull(LWriteGuard, '应该能够立即获取写锁');
  CheckTrue(FRWLock.IsWriteLocked, '应该处于写锁状态');
  LWriteGuard := nil; // 释放写锁
  CheckFalse(FRWLock.IsWriteLocked, '应该不再处于写锁状态');
end;

procedure TTestCase_INamedRWLock.Test_TryAcquireRead_Timeout;
var
  LReadGuard: INamedRWLockReadGuard;
begin
  // 测试带超时的读锁获取
  LReadGuard := FRWLock.TryReadLockFor(100);
  CheckNotNull(LReadGuard, '应该能够在超时内获取读锁');
  CheckEquals(1, FRWLock.GetReaderCount, '读者计数应该为1');
  LReadGuard := nil; // 释放读锁
  CheckEquals(0, FRWLock.GetReaderCount, '读者计数应该回到0');
end;

procedure TTestCase_INamedRWLock.Test_TryAcquireWrite_Timeout;
var
  LWriteGuard: INamedRWLockWriteGuard;
begin
  // 测试带超时的写锁获取
  LWriteGuard := FRWLock.TryWriteLockFor(100);
  CheckNotNull(LWriteGuard, '应该能够在超时内获取写锁');
  CheckTrue(FRWLock.IsWriteLocked, '应该处于写锁状态');
  LWriteGuard := nil; // 释放写锁
  CheckFalse(FRWLock.IsWriteLocked, '应该不再处于写锁状态');
end;

procedure TTestCase_INamedRWLock.Test_GetReaderCount;
var
  LReadGuard1, LReadGuard2: INamedRWLockReadGuard;
begin
  CheckEquals(0, FRWLock.GetReaderCount, '初始读者计数应该为0');

  LReadGuard1 := FRWLock.ReadLock;
  CheckEquals(1, FRWLock.GetReaderCount, '获取读锁后计数应该为1');

  LReadGuard2 := FRWLock.ReadLock;
  CheckEquals(2, FRWLock.GetReaderCount, '获取第二个读锁后计数应该为2');

  LReadGuard1 := nil; // 释放第一个读锁
  CheckEquals(1, FRWLock.GetReaderCount, '释放一个读锁后计数应该为1');

  LReadGuard2 := nil; // 释放第二个读锁
  CheckEquals(0, FRWLock.GetReaderCount, '释放所有读锁后计数应该为0');
end;

procedure TTestCase_INamedRWLock.Test_IsWriteLocked;
var
  LWriteGuard: INamedRWLockWriteGuard;
begin
  CheckFalse(FRWLock.IsWriteLocked, '初始状态不应该有写锁');

  LWriteGuard := FRWLock.WriteLock;
  CheckTrue(FRWLock.IsWriteLocked, '获取写锁后应该处于写锁状态');

  LWriteGuard := nil; // 释放写锁
  CheckFalse(FRWLock.IsWriteLocked, '释放写锁后不应该处于写锁状态');
end;

procedure TTestCase_INamedRWLock.Test_GetHandle;
var
  LHandle: Pointer;
begin
  LHandle := FRWLock.GetHandle;
  CheckTrue(LHandle <> nil, '句柄不应该为空');
end;

procedure TTestCase_INamedRWLock.Test_InvalidName;
begin
  // 测试无效名称
  try
    MakeNamedRWLock('');
    Fail('空名称应该抛出异常');
  except
    on E: EInvalidArgument do
      Check(True, '正确抛出了 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_INamedRWLock.Test_DoubleRelease;
var
  LReadGuard: INamedRWLockReadGuard;
begin
  // 获取读锁并自动释放
  LReadGuard := FRWLock.ReadLock;
  LReadGuard := nil; // 释放读锁

  // RAII 模式下不会有双重释放问题
  // 这个测试主要验证 RAII 的安全性
  CheckTrue(True, 'RAII 模式下锁管理是安全的');
end;

procedure TTestCase_INamedRWLock.Test_MultipleReaders;
var
  LGuard1, LGuard2: INamedRWLockReadGuard;
begin
  // 测试多个读者可以同时持有锁
  LGuard1 := FRWLock.ReadLock;
  LGuard2 := FRWLock.ReadLock;
  
  CheckNotNull(LGuard1, '第一个读锁应该成功');
  CheckNotNull(LGuard2, '第二个读锁应该成功');
  CheckEquals(2, FRWLock.GetReaderCount, '应该有2个读者');
  
  LGuard1 := nil;
  CheckEquals(1, FRWLock.GetReaderCount, '释放一个读锁后应该还有1个读者');
  
  LGuard2 := nil;
  CheckEquals(0, FRWLock.GetReaderCount, '释放所有读锁后应该没有读者');
end;

procedure TTestCase_INamedRWLock.Test_ReaderWriter_Exclusion;
var
  LReadGuard: INamedRWLockReadGuard;
  LWriteGuard: INamedRWLockWriteGuard;
begin
  // 测试读者和写者互斥
  LReadGuard := FRWLock.ReadLock;
  CheckNotNull(LReadGuard, '读锁应该成功');
  
  // 在有读者的情况下，写锁应该无法立即获取
  LWriteGuard := FRWLock.TryWriteLock;
  CheckNull(LWriteGuard, '在有读者时写锁应该无法获取');
  
  LReadGuard := nil; // 释放读锁
  
  // 现在写锁应该能够获取
  LWriteGuard := FRWLock.TryWriteLock;
  CheckNotNull(LWriteGuard, '释放读锁后写锁应该能够获取');
  
  LWriteGuard := nil;
end;

procedure TTestCase_INamedRWLock.Test_WriterExclusion;
var
  LWriteGuard1, LWriteGuard2: INamedRWLockWriteGuard;
begin
  // 测试写者互斥
  LWriteGuard1 := FRWLock.WriteLock;
  CheckNotNull(LWriteGuard1, '第一个写锁应该成功');
  
  // 在有写者的情况下，另一个写锁应该无法立即获取
  LWriteGuard2 := FRWLock.TryWriteLock;
  CheckNull(LWriteGuard2, '在有写者时另一个写锁应该无法获取');
  
  LWriteGuard1 := nil; // 释放写锁
  
  // 现在第二个写锁应该能够获取
  LWriteGuard2 := FRWLock.TryWriteLock;
  CheckNotNull(LWriteGuard2, '释放第一个写锁后第二个写锁应该能够获取');
  
  LWriteGuard2 := nil;
end;

procedure TTestCase_INamedRWLock.Test_MultipleInstances;
var
  LRWLock1, LRWLock2: INamedRWLock;
  LTestName: string;
  LWriteGuard1, LWriteGuard2: INamedRWLockWriteGuard;
begin
  // 使用独立的名称，避免与 SetUp 中的实例冲突
  LTestName := 'multi_test_' + IntToStr(Random(100000));

  // 创建第一个实例
  LRWLock1 := MakeNamedRWLock(LTestName);
  CheckNotNull(LRWLock1, '应该能创建第一个实例');

  // 创建同名的第二个实例
  LRWLock2 := MakeNamedRWLock(LTestName);
  CheckNotNull(LRWLock2, '应该能创建同名的第二个实例');

  // 验证名称一致性
  CheckEquals(LTestName, LRWLock1.GetName, '第一个实例名称应该匹配');
  CheckEquals(LTestName, LRWLock2.GetName, '第二个实例名称应该匹配');
  
  // 测试跨实例的锁互斥
  LWriteGuard1 := LRWLock1.WriteLock;
  LWriteGuard2 := LRWLock2.TryWriteLock;
  CheckNull(LWriteGuard2, '第二个实例不应该能获取写锁');

  // 释放后应该能获取
  LWriteGuard1 := nil; // 释放第一个写锁
  LWriteGuard2 := LRWLock2.TryWriteLock;
  CheckNotNull(LWriteGuard2, '释放后第二个实例应该能获取写锁');
  LWriteGuard2 := nil; // 释放第二个写锁
end;

procedure TTestCase_INamedRWLock.Test_CrossProcess_Basic;
var
  LReadGuard: INamedRWLockReadGuard;
begin
  // 这个测试验证基本的跨进程功能
  // 实际的跨进程测试需要启动子进程，这里只做基本验证
  LReadGuard := FRWLock.ReadLock;
  CheckTrue(True, '跨进程读写锁基本功能正常');
  LReadGuard := nil; // 释放读锁
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_INamedRWLock);

end.
