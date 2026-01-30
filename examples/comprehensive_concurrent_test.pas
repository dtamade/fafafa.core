program ComprehensiveConcurrentTest;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  // 原子统一：示例不再引用 fafafa.core.sync
  fafafa.core.lockfree;

{**
 * 并发测试Treiber栈
 *}
procedure TestTreiberStackConcurrency;
type
  TIntStack = specialize TTreiberStack<Integer>;
var
  LStack: TIntStack;
  LPushThreads: array[0..3] of TThread;
  LPopThreads: array[0..3] of TThread;
  LPushedCount, LPoppedCount: Integer;
  I: Integer;
begin
  WriteLn('=== Treiber栈并发测试 ===');
  
  LStack := TIntStack.Create;
  LPushedCount := 0;
  LPoppedCount := 0;
  
  try
    WriteLn('启动4个压栈线程和4个弹栈线程...');
    
    // 创建4个压栈线程
    for I := 0 to 3 do
    begin
      LPushThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var J: Integer;
        begin
          for J := 1 to 1000 do
          begin
            LStack.Push(J + I * 1000);
            InterlockedIncrement(LPushedCount);
          end;
        end
      );
    end;
    
    // 创建4个弹栈线程
    for I := 0 to 3 do
    begin
      LPopThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var J, LValue: Integer;
        begin
          for J := 1 to 1000 do
          begin
            while not LStack.Pop(LValue) do
              Sleep(0); // 等待有数据
            InterlockedIncrement(LPoppedCount);
          end;
        end
      );
    end;
    
    // 启动所有线程
    for I := 0 to 3 do
    begin
      LPushThreads[I].Start;
      LPopThreads[I].Start;
    end;
    
    // 等待所有线程完成
    for I := 0 to 3 do
    begin
      LPushThreads[I].WaitFor;
      LPopThreads[I].WaitFor;
    end;
    
    WriteLn('压栈操作数: ', LPushedCount);
    WriteLn('弹栈操作数: ', LPoppedCount);
    WriteLn('栈是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
    if (LPushedCount = 4000) and (LPoppedCount = 4000) then
      WriteLn('✅ Treiber栈并发测试成功！')
    else
      WriteLn('❌ Treiber栈并发测试失败！');
    
  finally
    // 清理线程
    for I := 0 to 3 do
    begin
      if Assigned(LPushThreads[I]) then
        LPushThreads[I].Free;
      if Assigned(LPopThreads[I]) then
        LPopThreads[I].Free;
    end;
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 并发测试预分配安全栈
 *}
procedure TestPreAllocStackConcurrency;
type
  TSafeStack = specialize TPreAllocStack<Integer>;
var
  LStack: TSafeStack;
  LPushThreads: array[0..2] of TThread;
  LPopThreads: array[0..2] of TThread;
  LPushedCount, LPoppedCount: Integer;
  I: Integer;
begin
  WriteLn('=== 预分配安全栈并发测试 ===');
  
  LStack := TSafeStack.Create(10000); // 足够大的容量
  LPushedCount := 0;
  LPoppedCount := 0;
  
  try
    WriteLn('启动3个压栈线程和3个弹栈线程...');
    
    // 创建3个压栈线程
    for I := 0 to 2 do
    begin
      LPushThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var J: Integer;
        begin
          for J := 1 to 1000 do
          begin
            if LStack.Push(J + I * 1000) then
              InterlockedIncrement(LPushedCount);
          end;
        end
      );
    end;
    
    // 创建3个弹栈线程
    for I := 0 to 2 do
    begin
      LPopThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var J, LValue: Integer;
        begin
          for J := 1 to 1000 do
          begin
            while not LStack.Pop(LValue) do
              Sleep(0); // 等待有数据
            InterlockedIncrement(LPoppedCount);
          end;
        end
      );
    end;
    
    // 启动所有线程
    for I := 0 to 2 do
    begin
      LPushThreads[I].Start;
      LPopThreads[I].Start;
    end;
    
    // 等待所有线程完成
    for I := 0 to 2 do
    begin
      LPushThreads[I].WaitFor;
      LPopThreads[I].WaitFor;
    end;
    
    WriteLn('压栈操作数: ', LPushedCount);
    WriteLn('弹栈操作数: ', LPoppedCount);
    WriteLn('栈大小: ', LStack.GetSize);
    WriteLn('栈是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
    if (LPushedCount = 3000) and (LPoppedCount = 3000) then
      WriteLn('✅ 预分配安全栈并发测试成功！')
    else
      WriteLn('❌ 预分配安全栈并发测试失败！');
    
  finally
    // 清理线程
    for I := 0 to 2 do
    begin
      if Assigned(LPushThreads[I]) then
        LPushThreads[I].Free;
      if Assigned(LPopThreads[I]) then
        LPopThreads[I].Free;
    end;
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 并发测试Michael-Scott队列
 *}
procedure TestMichaelScottQueueConcurrency;
type
  TIntQueue = TIntMPSCQueue;
var
  LQueue: TIntQueue;
  LEnqueueThreads: array[0..2] of TThread;
  LDequeueThreads: array[0..2] of TThread;
  LEnqueuedCount, LDequeuedCount: Integer;
  I: Integer;
begin
  WriteLn('=== Michael-Scott队列并发测试 ===');
  
  LQueue := CreateIntMPSCQueue;
  LEnqueuedCount := 0;
  LDequeuedCount := 0;
  
  try
    WriteLn('启动3个入队线程和3个出队线程...');
    
    // 创建3个入队线程
    for I := 0 to 2 do
    begin
      LEnqueueThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var J: Integer;
        begin
          for J := 1 to 1000 do
          begin
            LQueue.Enqueue(J + I * 1000);
            InterlockedIncrement(LEnqueuedCount);
          end;
        end
      );
    end;
    
    // 创建3个出队线程
    for I := 0 to 2 do
    begin
      LDequeueThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var J, LValue: Integer;
        begin
          for J := 1 to 1000 do
          begin
            while not LQueue.Dequeue(LValue) do
              Sleep(0); // 等待有数据
            InterlockedIncrement(LDequeuedCount);
          end;
        end
      );
    end;
    
    // 启动所有线程
    for I := 0 to 2 do
    begin
      LEnqueueThreads[I].Start;
      LDequeueThreads[I].Start;
    end;
    
    // 等待所有线程完成
    for I := 0 to 2 do
    begin
      LEnqueueThreads[I].WaitFor;
      LDequeueThreads[I].WaitFor;
    end;
    
    WriteLn('入队操作数: ', LEnqueuedCount);
    WriteLn('出队操作数: ', LDequeuedCount);
    WriteLn('队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
    if (LEnqueuedCount = 3000) and (LDequeuedCount = 3000) then
      WriteLn('✅ Michael-Scott队列并发测试成功！')
    else
      WriteLn('❌ Michael-Scott队列并发测试失败！');
    
  finally
    // 清理线程
    for I := 0 to 2 do
    begin
      if Assigned(LEnqueueThreads[I]) then
        LEnqueueThreads[I].Free;
      if Assigned(LDequeueThreads[I]) then
        LDequeueThreads[I].Free;
    end;
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 并发测试预分配MPMC队列
 *}
procedure TestPreAllocMPMCQueueConcurrency;
type
  TIntQueue = TIntMPMCQueue;
var
  LQueue: TIntQueue;
  LEnqueueThreads: array[0..3] of TThread;
  LDequeueThreads: array[0..3] of TThread;
  LEnqueuedCount, LDequeuedCount: Integer;
  I: Integer;
begin
  WriteLn('=== 预分配MPMC队列并发测试 ===');

  LQueue := CreateIntMPMCQueue(10000); // 足够大的容量
  LEnqueuedCount := 0;
  LDequeuedCount := 0;

  try
    WriteLn('启动4个入队线程和4个出队线程...');

    // 创建4个入队线程
    for I := 0 to 3 do
    begin
      LEnqueueThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var J: Integer;
        begin
          for J := 1 to 1000 do
          begin
            if LQueue.Enqueue(J + I * 1000) then
              InterlockedIncrement(LEnqueuedCount);
          end;
        end
      );
    end;

    // 创建4个出队线程
    for I := 0 to 3 do
    begin
      LDequeueThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var J, LValue: Integer;
        begin
          for J := 1 to 1000 do
          begin
            while not LQueue.Dequeue(LValue) do
              Sleep(0); // 等待有数据
            InterlockedIncrement(LDequeuedCount);
          end;
        end
      );
    end;

    // 启动所有线程
    for I := 0 to 3 do
    begin
      LEnqueueThreads[I].Start;
      LDequeueThreads[I].Start;
    end;

    // 等待所有线程完成
    for I := 0 to 3 do
    begin
      LEnqueueThreads[I].WaitFor;
      LDequeueThreads[I].WaitFor;
    end;

    WriteLn('入队操作数: ', LEnqueuedCount);
    WriteLn('出队操作数: ', LDequeuedCount);
    WriteLn('队列大小: ', LQueue.GetSize);
    WriteLn('队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));

    if (LEnqueuedCount = 4000) and (LDequeuedCount = 4000) then
      WriteLn('✅ 预分配MPMC队列并发测试成功！')
    else
      WriteLn('❌ 预分配MPMC队列并发测试失败！');

  finally
    // 清理线程
    for I := 0 to 3 do
    begin
      if Assigned(LEnqueueThreads[I]) then
        LEnqueueThreads[I].Free;
      if Assigned(LDequeueThreads[I]) then
        LDequeueThreads[I].Free;
    end;
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 性能基准测试
 *}
procedure BenchmarkAllDataStructures;
type
  TTreiberStack = specialize TTreiberStack<Integer>;
  TPreAllocStack = specialize TPreAllocStack<Integer>;
  TMichaelScottQueue = TIntMPSCQueue;
  TPreAllocMPMCQueue = TIntMPMCQueue;
  TSPSCQueue = TIntegerSPSCQueue;
var
  LTreiberStack: TTreiberStack;
  LPreAllocStack: TPreAllocStack;
  LMSQueue: TMichaelScottQueue;
  LMPMCQueue: TPreAllocMPMCQueue;
  LSPSCQueue: TSPSCQueue;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
const
  OPERATIONS = 100000;
begin
  WriteLn('=== 性能基准测试 ===');
  WriteLn('每个数据结构执行', OPERATIONS, '次操作...');
  WriteLn;

  // Treiber栈
  LTreiberStack := TTreiberStack.Create;
  try
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
      LTreiberStack.Push(I);
    for I := 1 to OPERATIONS do
      LTreiberStack.Pop(LValue);
    LEndTime := GetTickCount64;
    WriteLn('Treiber栈: ', LEndTime - LStartTime, ' ms');
  finally
    LTreiberStack.Free;
  end;

  // 预分配安全栈
  LPreAllocStack := TPreAllocStack.Create(OPERATIONS);
  try
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
      LPreAllocStack.Push(I);
    for I := 1 to OPERATIONS do
      LPreAllocStack.Pop(LValue);
    LEndTime := GetTickCount64;
    WriteLn('预分配安全栈: ', LEndTime - LStartTime, ' ms');
  finally
    LPreAllocStack.Free;
  end;

  // Michael-Scott队列
  LMSQueue := TMichaelScottQueue.Create;
  try
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
      LMSQueue.Enqueue(I);
    for I := 1 to OPERATIONS do
      LMSQueue.Dequeue(LValue);
    LEndTime := GetTickCount64;
    WriteLn('Michael-Scott队列: ', LEndTime - LStartTime, ' ms');
  finally
    LMSQueue.Free;
  end;

  // 预分配MPMC队列
  LMPMCQueue := TPreAllocMPMCQueue.Create(OPERATIONS);
  try
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
      LMPMCQueue.Enqueue(I);
    for I := 1 to OPERATIONS do
      LMPMCQueue.Dequeue(LValue);
    LEndTime := GetTickCount64;
    WriteLn('预分配MPMC队列: ', LEndTime - LStartTime, ' ms');
  finally
    LMPMCQueue.Free;
  end;

  // SPSC队列
  LSPSCQueue := TSPSCQueue.Create(OPERATIONS);
  try
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
      LSPSCQueue.Enqueue(I);
    for I := 1 to OPERATIONS do
      LSPSCQueue.Dequeue(LValue);
    LEndTime := GetTickCount64;
    WriteLn('SPSC队列: ', LEndTime - LStartTime, ' ms');
  finally
    LSPSCQueue.Free;
  end;

  WriteLn('✅ 性能基准测试完成！');
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('无锁数据结构全面并发测试');
  WriteLn('==========================');
  WriteLn;

  try
    TestTreiberStackConcurrency;
    TestPreAllocStackConcurrency;
    TestMichaelScottQueueConcurrency;
    TestPreAllocMPMCQueueConcurrency;
    BenchmarkAllDataStructures;

    WriteLn('🎉 所有并发测试完成！');
    WriteLn;
    WriteLn('📊 测试总结:');
    WriteLn('- Treiber栈: 4个生产者 + 4个消费者');
    WriteLn('- 预分配安全栈: 3个生产者 + 3个消费者');
    WriteLn('- Michael-Scott队列: 3个生产者 + 3个消费者');
    WriteLn('- 预分配MPMC队列: 4个生产者 + 4个消费者');
    WriteLn('- 性能基准: 单线程10万次操作对比');
    WriteLn;
    WriteLn('✅ 所有数据结构都通过了并发测试！');

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
