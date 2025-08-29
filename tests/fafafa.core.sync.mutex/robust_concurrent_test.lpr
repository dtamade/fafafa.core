program robust_concurrent_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.mutex,
  fafafa.core.sync.recMutex;

// 简化的测试，避免复杂的类结构
var
  TestCount: Integer = 0;
  PassCount: Integer = 0;

procedure TestResult(const AName: string; APassed: Boolean);
begin
  Inc(TestCount);
  if APassed then
  begin
    Inc(PassCount);
    WriteLn('✅ ', AName, ' - 通过');
  end
  else
    WriteLn('❌ ', AName, ' - 失败');
end;

// 测试跨线程互斥
procedure TestCrossThreadExclusion;
var
  m: IMutex;
  otherThreadAcquired: Boolean;
  t: TThread;
begin
  WriteLn('=== 测试跨线程互斥 ===');
  
  m := MakeMutex;
  otherThreadAcquired := False;
  
  // 主线程获取锁
  m.Acquire;
  
  // 创建测试线程
  t := TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(50); // 确保主线程先获取锁
      otherThreadAcquired := m.TryAcquire(100);
      if otherThreadAcquired then
        m.Release;
    end);
  
  t.Start;
  Sleep(200); // 让子线程有时间尝试
  t.WaitFor;
  t.Free;
  
  // 释放主线程的锁
  m.Release;
  
  TestResult('跨线程互斥', not otherThreadAcquired);
end;

// 测试多线程竞争
procedure TestMultiThreadContention;
const
  THREAD_COUNT = 2;
  OPERATIONS_PER_THREAD = 5;
var
  m: IMutex;
  threads: array[0..THREAD_COUNT-1] of TThread;
  sharedCounter: Integer;
  totalOperations: Integer;
  i: Integer;
begin
  WriteLn('=== 测试多线程竞争 ===');
  
  m := MakeMutex;
  sharedCounter := 0;
  totalOperations := 0;
  
  // 创建工作线程
  for i := 0 to THREAD_COUNT-1 do
  begin
    threads[i] := TThread.CreateAnonymousThread(
      procedure
      var j, localOps: Integer;
      begin
        localOps := 0;
        for j := 1 to OPERATIONS_PER_THREAD do
        begin
          if m.TryAcquire(100) then
          begin
            try
              Inc(sharedCounter);
              Inc(localOps);
              Sleep(1); // 模拟工作
            finally
              m.Release;
            end;
          end;
        end;
        
        // 原子更新总操作数
        InterLockedExchangeAdd(totalOperations, localOps);
      end);
    threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT-1 do
  begin
    threads[i].WaitFor;
    threads[i].Free;
  end;
  
  WriteLn('共享计数器: ', sharedCounter, ', 总操作数: ', totalOperations);
  TestResult('多线程竞争', sharedCounter = totalOperations);
end;

// 测试可重入互斥锁
procedure TestReentrantMutex;
var
  m: IRecMutex;
  success: Boolean;
begin
  WriteLn('=== 测试可重入互斥锁 ===');
  
  m := MakeRecMutex;
  
  // 第一次获取
  m.Acquire;
  
  // 同线程重入
  success := m.TryAcquire;
  if success then
  begin
    m.Release; // 释放重入
    m.Release; // 释放第一次
  end
  else
    m.Release; // 释放第一次
  
  TestResult('可重入互斥锁', success);
end;

begin
  WriteLn('🚀 开始健壮的并发测试');
  WriteLn('');
  
  try
    TestCrossThreadExclusion;
    WriteLn('');
    
    TestMultiThreadContention;
    WriteLn('');
    
    TestReentrantMutex;
    WriteLn('');
    
    WriteLn('=== 测试结果汇总 ===');
    WriteLn('总测试数: ', TestCount);
    WriteLn('通过数: ', PassCount);
    WriteLn('失败数: ', TestCount - PassCount);
    
    if PassCount = TestCount then
      WriteLn('🎉 所有测试通过！')
    else
      WriteLn('⚠️  有测试失败');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试过程中发生异常: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
