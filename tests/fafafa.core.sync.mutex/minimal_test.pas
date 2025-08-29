program minimal_test;

{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;

procedure Test(const TestName: string; Condition: Boolean);
begin
  Inc(TestCount);
  Write(Format('测试 %d: %s ... ', [TestCount, TestName]));
  if Condition then
  begin
    Inc(PassCount);
    WriteLn('通过');
  end
  else
  begin
    WriteLn('失败');
  end;
end;

procedure TestBasicOperations;
var
  Mutex: IMutex;
begin
  WriteLn('=== 基本操作测试 ===');
  
  try
    // 测试创建
    Mutex := MakeMutex;
    Test('创建互斥锁', Mutex <> nil);
    
    // 测试获取和释放
    Mutex.Acquire;
    Mutex.Release;
    Test('基本获取和释放', True);
    
    // 测试 TryAcquire
    Test('TryAcquire 成功', Mutex.TryAcquire);
    Test('重入 TryAcquire 失败', not Mutex.TryAcquire);
    Mutex.Release;
    
    // 测试句柄
    Test('获取句柄', Mutex.GetHandle <> nil);
    
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.Message);
      Test('基本操作异常', False);
    end;
  end;
  
  WriteLn;
end;

procedure TestLockGuard;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  WriteLn('=== 锁保护器测试 ===');
  
  try
    Mutex := MakeMutex;
    
    // 测试锁保护器
    Guard := MakeLockGuard(Mutex);
    Test('创建锁保护器', Guard <> nil);
    Test('锁保护器已获取锁', not Mutex.TryAcquire);
    
    Guard.Release;
    Test('锁保护器释放后可获取锁', Mutex.TryAcquire);
    Mutex.Release;
    
    // 测试 MutexGuard
    Guard := MutexGuard;
    Test('MutexGuard 创建', Guard <> nil);
    
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.Message);
      Test('锁保护器异常', False);
    end;
  end;
  
  WriteLn;
end;

procedure TestErrorHandling;
var
  Mutex: IMutex;
  ExceptionCaught: Boolean;
begin
  WriteLn('=== 错误处理测试 ===');
  
  try
    Mutex := MakeMutex;
    
    // 测试重入异常
    Mutex.Acquire;
    ExceptionCaught := False;
    try
      Mutex.Acquire;
    except
      on E: ELockError do
        ExceptionCaught := True;
    end;
    Mutex.Release;
    Test('重入正确抛出异常', ExceptionCaught);
    
    // 测试无效释放异常
    ExceptionCaught := False;
    try
      Mutex.Release;
    except
      on E: ELockError do
        ExceptionCaught := True;
    end;
    Test('无效释放正确抛出异常', ExceptionCaught);
    
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.Message);
      Test('错误处理异常', False);
    end;
  end;
  
  WriteLn;
end;

procedure TestSimpleConcurrency;
var
  Mutex: IMutex;
  SharedValue: Integer;
  Thread1, Thread2: TThread;
begin
  WriteLn('=== 简单并发测试 ===');
  
  try
    Mutex := MakeMutex;
    SharedValue := 0;
    
    // 创建两个线程
    Thread1 := TThread.CreateAnonymousThread(
      procedure
      var
        i: Integer;
      begin
        for i := 1 to 100 do
        begin
          Mutex.Acquire;
          try
            Inc(SharedValue);
          finally
            Mutex.Release;
          end;
        end;
      end);
    
    Thread2 := TThread.CreateAnonymousThread(
      procedure
      var
        i: Integer;
      begin
        for i := 1 to 100 do
        begin
          Mutex.Acquire;
          try
            Inc(SharedValue);
          finally
            Mutex.Release;
          end;
        end;
      end);
    
    Thread1.Start;
    Thread2.Start;
    
    Thread1.WaitFor;
    Thread2.WaitFor;
    
    Thread1.Free;
    Thread2.Free;
    
    Test('并发计数器正确', SharedValue = 200);
    
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.Message);
      Test('并发测试异常', False);
    end;
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.mutex 最小化严格测试');
  WriteLn('======================================');
  WriteLn;
  
  try
    TestBasicOperations;
    TestLockGuard;
    TestErrorHandling;
    TestSimpleConcurrency;
    
    WriteLn('======================================');
    WriteLn(Format('测试结果: %d/%d 通过', [PassCount, TestCount]));
    
    if PassCount = TestCount then
    begin
      WriteLn('✓ 所有测试通过！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('✗ 有测试失败！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生严重异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('测试完成。');
end.
