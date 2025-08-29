unit fafafa.core.sync.rwlock.testcase.safety;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.rwlock, fafafa.core.sync.base, fafafa.core.sync.rwlock.base;

type
  // 安全性测试用例
  TTestCase_Safety = class(TTestCase)
  private
    FRWLock: IRWLock;
    FExceptionCount: Integer;
    FMemoryLeakCount: Integer;
    FStateErrorCount: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 异常安全测试
    procedure Test_ExceptionSafety_ReadGuard;
    procedure Test_ExceptionSafety_WriteGuard;
    procedure Test_ExceptionSafety_NestedGuards;
    procedure Test_ExceptionSafety_TimeoutHandling;
    
    // 内存安全测试
    procedure Test_MemorySafety_GuardLifecycle;
    procedure Test_MemorySafety_CircularReference;
    procedure Test_MemorySafety_MultipleRelease;
    
    // 状态验证测试
    procedure Test_StateValidation_Basic;
    procedure Test_StateValidation_Recovery;
    procedure Test_StateValidation_HealthCheck;
    
    // 死锁检测测试
    procedure Test_DeadlockDetection_SameThread;
    procedure Test_DeadlockDetection_CrossThread;
    
    // 错误处理测试
    procedure Test_ErrorHandling_SystemError;
    procedure Test_ErrorHandling_TimeoutError;
    procedure Test_ErrorHandling_StateError;
  end;

implementation

{ TTestCase_Safety }

procedure TTestCase_Safety.SetUp;
begin
  inherited SetUp;
  FRWLock := MakeRWLock;
  FExceptionCount := 0;
  FMemoryLeakCount := 0;
  FStateErrorCount := 0;
end;

procedure TTestCase_Safety.TearDown;
begin
  FRWLock := nil;
  inherited TearDown;
end;

// ===== 异常安全测试 =====

procedure TTestCase_Safety.Test_ExceptionSafety_ReadGuard;
var
  Guard: IRWLockReadGuard;
  i: Integer;
begin
  WriteLn('测试: 读守卫异常安全');
  
  // 测试正常情况
  Guard := FRWLock.Read;
  AssertNotNull(Guard);
  AssertTrue(Guard.IsValid);
  AssertEquals(1, FRWLock.GetReaderCount);
  
  // 手动释放
  Guard.Release;
  AssertFalse(Guard.IsValid);
  AssertEquals(0, FRWLock.GetReaderCount);
  
  // 重复释放应该安全
  Guard.Release;  // 不应该抛出异常
  AssertEquals(0, FRWLock.GetReaderCount);
  
  // 测试多个守卫
  for i := 1 to 10 do
  begin
    Guard := FRWLock.Read;
    AssertNotNull(Guard);
    AssertTrue(Guard.IsValid);
    Guard := nil;  // 自动释放
  end;
  
  AssertEquals(0, FRWLock.GetReaderCount);
end;

procedure TTestCase_Safety.Test_ExceptionSafety_WriteGuard;
var
  Guard: IRWLockWriteGuard;
  i: Integer;
begin
  WriteLn('测试: 写守卫异常安全');
  
  // 测试正常情况
  Guard := FRWLock.Write;
  AssertNotNull(Guard);
  AssertTrue(Guard.IsValid);
  AssertTrue(FRWLock.IsWriteLocked);
  
  // 手动释放
  Guard.Release;
  AssertFalse(Guard.IsValid);
  AssertFalse(FRWLock.IsWriteLocked);
  
  // 重复释放应该安全
  Guard.Release;  // 不应该抛出异常
  AssertFalse(FRWLock.IsWriteLocked);
  
  // 测试多个守卫（顺序获取）
  for i := 1 to 5 do
  begin
    Guard := FRWLock.Write;
    AssertNotNull(Guard);
    AssertTrue(Guard.IsValid);
    AssertTrue(FRWLock.IsWriteLocked);
    Guard := nil;  // 自动释放
    AssertFalse(FRWLock.IsWriteLocked);
  end;
end;

procedure TTestCase_Safety.Test_ExceptionSafety_NestedGuards;
var
  ReadGuard1, ReadGuard2: IRWLockReadGuard;
  WriteGuard: IRWLockWriteGuard;
begin
  WriteLn('测试: 嵌套守卫异常安全');

  // 测试嵌套读守卫
  WriteLn('获取第一个读守卫...');
  ReadGuard1 := FRWLock.Read;
  try
    WriteLn('第一个读守卫获取成功, ReaderCount=', FRWLock.GetReaderCount);
    AssertEquals(1, FRWLock.GetReaderCount);

    WriteLn('获取第二个读守卫...');
    ReadGuard2 := FRWLock.Read;
    try
      WriteLn('第二个读守卫获取成功, ReaderCount=', FRWLock.GetReaderCount);
      AssertEquals(2, FRWLock.GetReaderCount);
    finally
      WriteLn('释放第二个读守卫...');
      ReadGuard2 := nil;
      Sleep(1);  // 确保析构完成
    end;

    WriteLn('第二个读守卫释放后, ReaderCount=', FRWLock.GetReaderCount);
    AssertEquals(1, FRWLock.GetReaderCount);
  finally
    WriteLn('释放第一个读守卫...');
    ReadGuard1 := nil;
    Sleep(1);  // 确保析构完成
  end;

  WriteLn('所有读守卫释放后, ReaderCount=', FRWLock.GetReaderCount);
  AssertEquals(0, FRWLock.GetReaderCount);
  
  // 测试写守卫后可以获取读守卫（锁降级，可重入性特性）
  WriteLn('获取写守卫...');
  WriteGuard := FRWLock.Write;
  try
    WriteLn('写守卫获取成功, IsWriteLocked=', FRWLock.IsWriteLocked);
    AssertTrue(FRWLock.IsWriteLocked);

    // 在可重入锁中，持有写锁的线程可以获取读锁（锁降级）
    WriteLn('尝试获取读守卫（锁降级）...');
    ReadGuard1 := FRWLock.TryRead(10);  // 10ms 超时
    WriteLn('读守卫获取结果: ', Assigned(ReadGuard1));
    AssertNotNull(ReadGuard1);  // 应该成功，因为支持锁降级

    // 验证状态
    WriteLn('验证状态: IsWriteLocked=', FRWLock.IsWriteLocked, ', IsReadLocked=', FRWLock.IsReadLocked, ', ReaderCount=', FRWLock.GetReaderCount);
    AssertTrue(FRWLock.IsWriteLocked);  // 写锁仍然有效
    AssertTrue(FRWLock.IsReadLocked);   // 读锁也有效
    AssertEquals(1, FRWLock.GetReaderCount);

    // 释放读守卫
    WriteLn('释放读守卫...');
    ReadGuard1 := nil;
    Sleep(1);  // 确保析构完成
    WriteLn('读守卫释放后: IsWriteLocked=', FRWLock.IsWriteLocked, ', IsReadLocked=', FRWLock.IsReadLocked);
    AssertTrue(FRWLock.IsWriteLocked);   // 写锁仍然有效
    AssertFalse(FRWLock.IsReadLocked);   // 读锁已释放

  finally
    WriteLn('释放写守卫...');
    WriteGuard := nil;
    Sleep(1);  // 确保析构完成
  end;

  WriteLn('写守卫释放后: IsWriteLocked=', FRWLock.IsWriteLocked);
  AssertFalse(FRWLock.IsWriteLocked);
end;

procedure TTestCase_Safety.Test_ExceptionSafety_TimeoutHandling;
var
  WriteGuard1, WriteGuard2: IRWLockWriteGuard;
  ReadGuard: IRWLockReadGuard;
begin
  WriteLn('测试: 超时处理异常安全（可重入性版本）');

  // 获取写锁
  WriteLn('获取第一个写锁...');
  WriteGuard1 := FRWLock.Write;
  try
    WriteLn('第一个写锁获取成功, IsWriteLocked=', FRWLock.IsWriteLocked);
    AssertTrue(FRWLock.IsWriteLocked);

    // 在可重入锁中，同一线程的第二个写锁会成功（可重入）
    WriteLn('尝试获取第二个写锁（可重入）...');
    WriteGuard2 := FRWLock.TryWrite(50);  // 50ms 超时
    WriteLn('第二个写锁结果: ', Assigned(WriteGuard2));
    AssertNotNull(WriteGuard2);  // 应该成功，因为可重入

    // 在可重入锁中，持有写锁的线程可以获取读锁（锁降级）
    WriteLn('尝试获取读锁（锁降级）...');
    ReadGuard := FRWLock.TryRead(50);  // 50ms 超时
    WriteLn('读锁结果: ', Assigned(ReadGuard));
    AssertNotNull(ReadGuard);  // 应该成功，因为支持锁降级

    // 验证状态
    WriteLn('验证状态: IsWriteLocked=', FRWLock.IsWriteLocked, ', IsReadLocked=', FRWLock.IsReadLocked);
    AssertTrue(FRWLock.IsWriteLocked);   // 写锁仍然有效
    AssertTrue(FRWLock.IsReadLocked);    // 读锁也有效

    // 释放读锁和第二个写锁
    WriteLn('释放读锁...');
    ReadGuard := nil;
    Sleep(1);
    WriteLn('释放第二个写锁...');
    WriteGuard2 := nil;
    Sleep(1);

    WriteLn('部分释放后: IsWriteLocked=', FRWLock.IsWriteLocked);
    AssertTrue(FRWLock.IsWriteLocked);   // 第一个写锁仍然有效

  finally
    WriteLn('释放第一个写锁...');
    WriteGuard1 := nil;
    Sleep(1);
  end;

  WriteLn('所有锁释放后: IsWriteLocked=', FRWLock.IsWriteLocked);
  AssertFalse(FRWLock.IsWriteLocked);

  // 现在应该能正常获取锁
  WriteLn('验证锁完全释放后可以重新获取...');
  ReadGuard := FRWLock.TryRead(50);
  WriteLn('重新获取读锁结果: ', Assigned(ReadGuard));
  AssertNotNull(ReadGuard);
  ReadGuard := nil;
  WriteLn('测试完成');
end;

// ===== 内存安全测试 =====

procedure TTestCase_Safety.Test_MemorySafety_GuardLifecycle;
var
  Guard1, Guard2: IRWLockReadGuard;
begin
  WriteLn('测试: 守卫生命周期内存安全');

  // 测试单个守卫
  WriteLn('=== 测试单个守卫 ===');
  Guard1 := FRWLock.Read;
  WriteLn('创建第一个守卫后读者数: ', FRWLock.GetReaderCount);
  AssertEquals(1, FRWLock.GetReaderCount);

  WriteLn('释放第一个守卫');
  Guard1 := nil;
  WriteLn('释放后读者数: ', FRWLock.GetReaderCount);
  AssertEquals(0, FRWLock.GetReaderCount);
  WriteLn('单个守卫测试通过');

  // 测试两个守卫
  WriteLn('=== 测试两个守卫 ===');
  Guard1 := FRWLock.Read;
  WriteLn('创建第一个守卫后读者数: ', FRWLock.GetReaderCount);
  AssertEquals(1, FRWLock.GetReaderCount);

  Guard2 := FRWLock.Read;
  WriteLn('创建第二个守卫后读者数: ', FRWLock.GetReaderCount);
  AssertEquals(2, FRWLock.GetReaderCount);

  WriteLn('释放第一个守卫');
  Guard1 := nil;
  WriteLn('释放第一个守卫后读者数: ', FRWLock.GetReaderCount);
  AssertEquals(1, FRWLock.GetReaderCount);

  WriteLn('释放第二个守卫');
  Guard2 := nil;
  WriteLn('释放第二个守卫后读者数: ', FRWLock.GetReaderCount);
  AssertEquals(0, FRWLock.GetReaderCount);
  WriteLn('两个守卫测试通过');

end;

procedure TTestCase_Safety.Test_MemorySafety_CircularReference;
var
  Guard: IRWLockReadGuard;
  WeakRef: Pointer;
begin
  WriteLn('测试: 循环引用内存安全');
  
  // 创建守卫
  Guard := FRWLock.Read;
  AssertNotNull(Guard);
  
  // 保存弱引用
  WeakRef := Pointer(Guard);
  
  // 释放强引用
  Guard := nil;
  
  // 验证锁已释放
  AssertEquals(0, FRWLock.GetReaderCount);
  
  // 注意：WeakRef 现在可能指向已释放的内存，不应该访问
end;

procedure TTestCase_Safety.Test_MemorySafety_MultipleRelease;
var
  Guard: IRWLockReadGuard;
begin
  WriteLn('测试: 多次释放内存安全');
  
  Guard := FRWLock.Read;
  AssertNotNull(Guard);
  AssertTrue(Guard.IsValid);
  AssertEquals(1, FRWLock.GetReaderCount);
  
  // 第一次释放
  Guard.Release;
  AssertFalse(Guard.IsValid);
  AssertEquals(0, FRWLock.GetReaderCount);
  
  // 多次释放应该安全
  Guard.Release;
  Guard.Release;
  Guard.Release;
  
  // 状态应该保持一致
  AssertFalse(Guard.IsValid);
  AssertEquals(0, FRWLock.GetReaderCount);
end;

// ===== 状态验证测试 =====

procedure TTestCase_Safety.Test_StateValidation_Basic;
begin
  WriteLn('测试: 基础状态验证');

  // 初始状态应该有效
  AssertTrue(FRWLock.ValidateState);
  AssertTrue(FRWLock.IsHealthy);
  AssertEquals(Ord(TLockResult.lrSuccess), Ord(FRWLock.GetLastLockResult));

  // 获取读锁后状态应该有效
  FRWLock.AcquireRead;
  try
    AssertTrue(FRWLock.ValidateState);
    AssertTrue(FRWLock.IsHealthy);
    AssertEquals(1, FRWLock.GetReaderCount);
  finally
    FRWLock.ReleaseRead;
  end;

  // 获取写锁后状态应该有效
  FRWLock.AcquireWrite;
  try
    AssertTrue(FRWLock.ValidateState);
    AssertTrue(FRWLock.IsHealthy);
    AssertTrue(FRWLock.IsWriteLocked);
  finally
    FRWLock.ReleaseWrite;
  end;

  // 最终状态应该有效
  AssertTrue(FRWLock.ValidateState);
  AssertTrue(FRWLock.IsHealthy);
end;

procedure TTestCase_Safety.Test_StateValidation_Recovery;
begin
  WriteLn('测试: 状态恢复');

  // 初始状态
  AssertTrue(FRWLock.ValidateState);

  // 尝试恢复（应该是无操作）
  FRWLock.RecoverState;
  AssertTrue(FRWLock.ValidateState);
  AssertTrue(FRWLock.IsHealthy);

  // 模拟一些操作后恢复
  FRWLock.AcquireRead;
  FRWLock.ReleaseRead;

  FRWLock.RecoverState;
  AssertTrue(FRWLock.ValidateState);
  AssertTrue(FRWLock.IsHealthy);
end;

procedure TTestCase_Safety.Test_StateValidation_HealthCheck;
var
  Guard: IRWLockReadGuard;
begin
  WriteLn('测试: 健康检查');

  // 初始状态应该健康
  AssertTrue(FRWLock.IsHealthy);

  // 正常操作后应该仍然健康
  Guard := FRWLock.Read;
  try
    AssertTrue(FRWLock.IsHealthy);
  finally
    Guard := nil;
  end;

  AssertTrue(FRWLock.IsHealthy);
end;

// ===== 死锁检测测试 =====

procedure TTestCase_Safety.Test_DeadlockDetection_SameThread;
var
  Guard1, Guard2: IRWLockWriteGuard;
  ReadGuard: IRWLockReadGuard;
begin
  WriteLn('测试: 同线程死锁检测（可重入性版本）');

  // 获取第一个写锁
  WriteLn('获取第一个写锁...');
  Guard1 := FRWLock.Write;
  AssertNotNull(Guard1);
  AssertTrue(FRWLock.IsWriteLocked);

  // 在可重入锁中，同一线程的第二个写锁会成功（可重入）
  WriteLn('尝试获取第二个写锁（可重入）...');
  Guard2 := FRWLock.TryWrite(10);  // 10ms 超时
  WriteLn('第二个写锁结果: ', Assigned(Guard2));
  AssertNotNull(Guard2);  // 应该成功，因为可重入

  // 验证两个锁都有效
  WriteLn('验证锁状态...');
  AssertTrue(Guard1.IsValid);
  AssertTrue(Guard2.IsValid);
  AssertTrue(FRWLock.IsWriteLocked);

  // 测试真正的死锁场景：读锁升级为写锁
  WriteLn('释放写锁，测试读锁升级死锁...');
  Guard1 := nil;
  Guard2 := nil;
  Sleep(1);

  // 获取读锁
  ReadGuard := FRWLock.Read;
  try
    AssertTrue(FRWLock.IsReadLocked);

    // 尝试将读锁升级为写锁应该抛出死锁异常
    WriteLn('尝试读锁升级为写锁（应该失败）...');
    try
      Guard1 := FRWLock.Write;
      Fail('应该抛出死锁异常');
    except
      on E: ERWLockDeadlockError do
      begin
        WriteLn('正确捕获死锁异常: ', E.Message);
        // 预期的异常
      end;
    end;

  finally
    ReadGuard := nil;
  end;

  WriteLn('验证锁完全释放...');
  AssertFalse(FRWLock.IsWriteLocked);
  AssertFalse(FRWLock.IsReadLocked);
  WriteLn('测试完成');
end;

// 全局变量用于线程通信
var
  GTestRWLock: IRWLock;
  GThreadResult: Boolean;

function TestDeadlockThread(Data: Pointer): PtrInt;
var
  Guard2: IRWLockWriteGuard;
begin
  try
    // 尝试获取写锁（应该超时）
    Guard2 := GTestRWLock.TryWrite(100);  // 100ms 超时
    GThreadResult := Assigned(Guard2);
    if Assigned(Guard2) then
      Guard2 := nil;
  except
    GThreadResult := False;
  end;
  Result := 0;
end;

procedure TTestCase_Safety.Test_DeadlockDetection_CrossThread;
var
  Guard1: IRWLockWriteGuard;
  ThreadID: TThreadID;
begin
  WriteLn('测试: 跨线程死锁检测');

  // 设置全局变量
  GTestRWLock := FRWLock;
  GThreadResult := True;  // 初始化为 True

  // 主线程获取写锁
  Guard1 := FRWLock.Write;
  try
    AssertTrue(FRWLock.IsWriteLocked);

    // 启动另一个线程尝试获取写锁
    ThreadID := BeginThread(@TestDeadlockThread, nil);
    WaitForThreadTerminate(ThreadID, 1000);

    // 另一个线程应该获取失败
    AssertFalse(GThreadResult);

    // 主线程的锁应该仍然有效
    AssertTrue(FRWLock.IsWriteLocked);

  finally
    Guard1 := nil;
    GTestRWLock := nil;  // 清理全局变量
  end;

  AssertFalse(FRWLock.IsWriteLocked);
end;

// ===== 错误处理测试 =====

procedure TTestCase_Safety.Test_ErrorHandling_SystemError;
begin
  WriteLn('测试: 系统错误处理');

  // 这个测试主要验证错误处理机制存在
  // 实际的系统错误很难模拟
  AssertTrue(FRWLock.IsHealthy);
  AssertEquals(Ord(TLockResult.lrSuccess), Ord(FRWLock.GetLastLockResult));
end;

procedure TTestCase_Safety.Test_ErrorHandling_TimeoutError;
var
  Guard1, Guard2: IRWLockWriteGuard;
  ReadGuard: IRWLockReadGuard;
  Result: TLockResult;
begin
  WriteLn('测试: 超时错误处理（可重入性版本）');

  // 在可重入锁中，同一线程的写锁不会超时，所以我们需要测试其他场景
  // 测试 TryAcquireWriteEx 的超时功能
  WriteLn('测试 TryAcquireWriteEx 超时...');

  // 先获取读锁
  ReadGuard := FRWLock.Read;
  try
    // 尝试升级为写锁应该立即失败（死锁预防）
    Result := FRWLock.TryAcquireWriteEx(50);  // 50ms 超时
    WriteLn('TryAcquireWriteEx 结果: ', Ord(Result));
    AssertEquals(Ord(TLockResult.lrWouldBlock), Ord(Result));  // 应该是 WouldBlock，不是超时

    // 检查错误状态
    AssertTrue(FRWLock.IsHealthy);
    AssertEquals(Ord(Result), Ord(FRWLock.GetLastLockResult));

  finally
    ReadGuard := nil;
  end;

  // 测试正常的可重入写锁
  WriteLn('测试可重入写锁...');
  Guard1 := FRWLock.Write;
  try
    // 在可重入锁中，第二个写锁会成功
    Guard2 := FRWLock.TryWrite(50);  // 50ms 超时
    WriteLn('第二个写锁结果: ', Assigned(Guard2));
    AssertNotNull(Guard2);  // 应该成功，因为可重入

    // 检查健康状态
    AssertTrue(FRWLock.IsHealthy);

  finally
    Guard2 := nil;
    Guard1 := nil;
  end;

  WriteLn('测试完成');
end;

procedure TTestCase_Safety.Test_ErrorHandling_StateError;
var
  Guard: IRWLockReadGuard;
begin
  WriteLn('测试: 状态错误处理');

  Guard := FRWLock.Read;
  try
    AssertTrue(Guard.IsValid);
    AssertEquals(1, FRWLock.GetReaderCount);

    // 手动释放
    Guard.Release;
    AssertFalse(Guard.IsValid);

    // 多次释放应该安全（不抛出异常）
    Guard.Release;
    AssertFalse(Guard.IsValid);

  finally
    // 确保清理
    if Guard.IsValid then
      Guard.Release;
  end;

  AssertEquals(0, FRWLock.GetReaderCount);
end;

initialization
  RegisterTest(TTestCase_Safety);

end.
