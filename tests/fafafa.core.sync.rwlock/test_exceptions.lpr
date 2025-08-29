{$CODEPAGE UTF8}
program test_exceptions;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.rwlock.base, fafafa.core.sync.rwlock;

procedure TestBasicExceptions;
var
  Ex: ERWLockError;
begin
  WriteLn('=== 测试基础异常类型 ===');
  
  // 测试 ERWLockTimeoutError
  try
    raise ERWLockTimeoutError.Create(5000, 12345);
  except
    on E: ERWLockTimeoutError do
    begin
      WriteLn('ERWLockTimeoutError: ', E.Message);
      WriteLn('  超时时间: ', E.TimeoutMs, ' ms');
      WriteLn('  线程ID: ', E.ThreadId);
    end;
  end;
  
  // 测试 ERWLockStateError
  try
    raise ERWLockStateError.Create('Locked', 'Unlocked', 67890);
  except
    on E: ERWLockStateError do
    begin
      WriteLn('ERWLockStateError: ', E.Message);
      WriteLn('  期望状态: ', E.ExpectedState);
      WriteLn('  实际状态: ', E.ActualState);
    end;
  end;
  
  // 测试 ERWLockDeadlockError
  try
    raise ERWLockDeadlockError.Create(11111, [22222, 33333]);
  except
    on E: ERWLockDeadlockError do
    begin
      WriteLn('ERWLockDeadlockError: ', E.Message);
      WriteLn('  拥有者线程: ', E.OwnerThread);
      WriteLn('  等待线程数: ', Length(E.GetWaitingThreads));
    end;
  end;
  
  WriteLn;
end;

procedure TestExtendedExceptions;
begin
  WriteLn('=== 测试扩展异常类型 ===');
  
  // 测试 ERWLockInterruptedException
  try
    raise ERWLockInterruptedException.Create('用户取消操作', 44444);
  except
    on E: ERWLockInterruptedException do
    begin
      WriteLn('ERWLockInterruptedException: ', E.Message);
      WriteLn('  中断原因: ', E.InterruptReason);
    end;
  end;
  
  // 测试 ERWLockOwnershipException
  try
    raise ERWLockOwnershipException.Create(55555, 66666);
  except
    on E: ERWLockOwnershipException do
    begin
      WriteLn('ERWLockOwnershipException: ', E.Message);
      WriteLn('  期望拥有者: ', E.ExpectedOwner);
      WriteLn('  实际拥有者: ', E.ActualOwner);
    end;
  end;
  
  // 测试 ERWLockCapacityException
  try
    raise ERWLockCapacityException.Create(2000, 1024, 77777);
  except
    on E: ERWLockCapacityException do
    begin
      WriteLn('ERWLockCapacityException: ', E.Message);
      WriteLn('  请求数量: ', E.RequestedCount);
      WriteLn('  最大容量: ', E.MaxCapacity);
    end;
  end;
  
  // 测试 ERWLockConfigurationException
  try
    raise ERWLockConfigurationException.Create('SpinCount', '-100');
  except
    on E: ERWLockConfigurationException do
    begin
      WriteLn('ERWLockConfigurationException: ', E.Message);
      WriteLn('  配置参数: ', E.ConfigParameter);
      WriteLn('  配置值: ', E.ConfigValue);
    end;
  end;
  
  // 测试 ERWLockVersionException
  try
    raise ERWLockVersionException.Create(10, 15, 88888);
  except
    on E: ERWLockVersionException do
    begin
      WriteLn('ERWLockVersionException: ', E.Message);
      WriteLn('  期望版本: ', E.ExpectedVersion);
      WriteLn('  实际版本: ', E.ActualVersion);
    end;
  end;
  
  // 测试 ERWLockCorruptionException
  try
    raise ERWLockCorruptionException.Create('计数器不一致', '读者计数为负数', 99999);
  except
    on E: ERWLockCorruptionException do
    begin
      WriteLn('ERWLockCorruptionException: ', E.Message);
      WriteLn('  损坏类型: ', E.CorruptionType);
      WriteLn('  损坏详情: ', E.CorruptionDetails);
    end;
  end;
  
  WriteLn;
end;

procedure TestSystemExceptions;
begin
  WriteLn('=== 测试系统异常类型 ===');
  
  // 测试 ERWLockResourceError
  try
    raise ERWLockResourceError.Create(1500, 1024, 11111);
  except
    on E: ERWLockResourceError do
    begin
      WriteLn('ERWLockResourceError: ', E.Message);
      WriteLn('  当前计数: ', E.CurrentCount);
      WriteLn('  最大计数: ', E.MaxCount);
    end;
  end;
  
  // 测试 ERWLockSystemError
  try
    raise ERWLockSystemError.Create(22, 'Invalid argument', 22222);
  except
    on E: ERWLockSystemError do
    begin
      WriteLn('ERWLockSystemError: ', E.Message);
      WriteLn('  系统错误码: ', E.SystemErrorCode);
      WriteLn('  系统错误信息: ', E.SystemErrorMessage);
    end;
  end;
  
  // 测试兼容性异常 ELockError
  try
    raise ELockError.Create('兼容性测试异常');
  except
    on E: ELockError do
    begin
      WriteLn('ELockError: ', E.Message);
      WriteLn('  锁结果: ', Ord(E.LockResult));
      WriteLn('  线程ID: ', E.ThreadId);
    end;
  end;
  
  WriteLn;
end;

procedure TestExceptionHierarchy;
var
  Ex: ERWLockError;
begin
  WriteLn('=== 测试异常继承层次 ===');
  
  // 测试异常继承关系
  Ex := ERWLockTimeoutError.Create(1000);
  try
    WriteLn('ERWLockTimeoutError 是 ERWLockError: ', Ex is ERWLockError);
    WriteLn('ERWLockTimeoutError 是 Exception: ', Ex is Exception);
  finally
    Ex.Free;
  end;
  
  Ex := ERWLockInterruptedException.Create('测试中断');
  try
    WriteLn('ERWLockInterruptedException 是 ERWLockError: ', Ex is ERWLockError);
    WriteLn('ERWLockInterruptedException 是 Exception: ', Ex is Exception);
  finally
    Ex.Free;
  end;
  
  Ex := ELockError.Create('兼容性测试');
  try
    WriteLn('ELockError 是 ERWLockError: ', Ex is ERWLockError);
    WriteLn('ELockError 是 Exception: ', Ex is Exception);
  finally
    Ex.Free;
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.rwlock 异常体系测试');
  WriteLn('=====================================');
  WriteLn;
  
  TestBasicExceptions;
  TestExtendedExceptions;
  TestSystemExceptions;
  TestExceptionHierarchy;
  
  WriteLn('异常体系测试完成');
  WriteLn('总计测试了 ', 10, ' 种异常类型');
end.
