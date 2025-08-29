
program simple_test;

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
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Assert(Condition: Boolean; const Message: string);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('✓ PASS: ', Message);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('✗ FAIL: ', Message);
  end;
end;

procedure TestBasicMutexOperations;
var
  Mutex: IMutex;
begin
  WriteLn('=== 测试基本互斥锁操作 ===');
  
  // 测试创建
  Mutex := MakeMutex;
  Assert(Mutex <> nil, '互斥锁创建成功');
  
  // 测试基本获取和释放
  try
    Mutex.Acquire;
    Assert(True, '互斥锁获取成功');
    Mutex.Release;
    Assert(True, '互斥锁释放成功');
  except
    on E: Exception do
      Assert(False, '基本操作失败: ' + E.Message);
  end;
  
  // 测试 TryAcquire
  Assert(Mutex.TryAcquire, 'TryAcquire 成功');
  Assert(not Mutex.TryAcquire, '重入 TryAcquire 正确失败');
  Mutex.Release;
  
  // 测试句柄
  Assert(Mutex.GetHandle <> nil, '获取句柄成功');
  
  WriteLn;
end;

procedure TestLockGuard;
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  WriteLn('=== 测试锁保护器 ===');
  
  Mutex := MakeMutex;
  
  // 测试锁保护器
  Guard := MakeLockGuard(Mutex);
  Assert(Guard <> nil, '锁保护器创建成功');
  Assert(not Mutex.TryAcquire, '锁保护器已获取锁');
  
  Guard.Release;
  Assert(Mutex.TryAcquire, '锁保护器释放后可获取锁');
  Mutex.Release;
  
  // 测试 MutexGuard 便捷函数
  Guard := MutexGuard;
  Assert(Guard <> nil, 'MutexGuard 创建成功');
  
  WriteLn;
end;

procedure TestErrorHandling;
var
  Mutex: IMutex;
  ExceptionCaught: Boolean;
begin
  WriteLn('=== 测试错误处理 ===');
  
  Mutex := MakeMutex;
  
  // 测试重入异常
  Mutex.Acquire;
  try
    ExceptionCaught := False;
    try
      Mutex.Acquire; // 应该抛出异常
    except
      on E: ELockError do
        ExceptionCaught := True;
    end;
    Assert(ExceptionCaught, '重入正确抛出异常');
  finally
    Mutex.Release;
  end;
  
  // 测试无效释放异常
  ExceptionCaught := False;
  try
    Mutex.Release; // 应该抛出异常
  except
    on E: ELockError do
      ExceptionCaught := True;
  end;
  Assert(ExceptionCaught, '无效释放正确抛出异常');
  
  WriteLn;
end;

procedure TestConcurrency;
const
  THREAD_COUNT = 4;
  ITERATIONS = 1000;
var
  Mutex: IMutex;
  SharedCounter: Integer;
  Threads: array[0..THREAD_COUNT-1] of TThread;
  i: Integer;
begin
  WriteLn('=== 测试并发访问 ===');
  
  Mutex := MakeMutex;
  SharedCounter := 0;
  
  // 创建多个线程同时增加计数器
  for i := 0 to THREAD_COUNT-1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
      begin
        for j := 1 to ITERATIONS do
        begin
          Mutex.Acquire;
          try
            Inc(SharedCounter);
          finally
            Mutex.Release;
          end;
        end;
      end);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT-1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  Assert(SharedCounter = THREAD_COUNT * ITERATIONS, 
    Format('并发计数器正确: 期望 %d, 实际 %d', [THREAD_COUNT * ITERATIONS, SharedCounter]));
  
  WriteLn;
end;

procedure TestPerformance;
const
  ITERATIONS = 100000;
var
  Mutex: IMutex;
  StartTime, EndTime: QWord;
  i: Integer;
  ElapsedMs: QWord;
  OpsPerSecond: Double;
begin
  WriteLn('=== 性能测试 ===');
  
  Mutex := MakeMutex;
  
  StartTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    Mutex.Acquire;
    Mutex.Release;
  end;
  EndTime := GetTickCount64;
  
  ElapsedMs := EndTime - StartTime;
  if ElapsedMs > 0 then
    OpsPerSecond := ITERATIONS * 1000.0 / ElapsedMs
  else
    OpsPerSecond := 0;
  
  WriteLn(Format('性能: %d 次操作，耗时 %d ms，%.0f ops/sec', 
    [ITERATIONS, ElapsedMs, OpsPerSecond]));
  
  Assert(ElapsedMs < 5000, '性能在可接受范围内');
  
  WriteLn;
end;

procedure TestTryAcquireContention;
const
  THREAD_COUNT = 4;
  ATTEMPTS = 100;
var
  Mutex: IMutex;
  SuccessCount: Integer;
  Threads: array[0..THREAD_COUNT-1] of TThread;
  i: Integer;
begin
  WriteLn('=== 测试 TryAcquire 竞争 ===');
  
  Mutex := MakeMutex;
  SuccessCount := 0;
  
  // 创建竞争线程
  for i := 0 to THREAD_COUNT-1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
      begin
        for j := 1 to ATTEMPTS do
        begin
          if Mutex.TryAcquire then
          begin
            try
              InterlockedIncrement(SuccessCount);
              Sleep(1); // 短暂持有锁
            finally
              Mutex.Release;
            end;
          end;
        end;
      end);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT-1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  WriteLn(Format('TryAcquire 竞争结果: 成功 %d 次，总尝试 %d 次', 
    [SuccessCount, THREAD_COUNT * ATTEMPTS]));
  
  Assert(SuccessCount > 0, '应该有成功的 TryAcquire');
  Assert(SuccessCount < THREAD_COUNT * ATTEMPTS, '应该有失败的 TryAcquire（由于竞争）');
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.mutex 严格单元测试');
  WriteLn('=====================================');
  WriteLn;
  
  try
    TestBasicMutexOperations;
    TestLockGuard;
    TestErrorHandling;
    TestConcurrency;
    TestPerformance;
    TestTryAcquireContention;
    
    WriteLn('=====================================');
    WriteLn(Format('测试完成: %d 通过, %d 失败', [TestsPassed, TestsFailed]));
    
    if TestsFailed = 0 then
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
      WriteLn('测试过程中发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
