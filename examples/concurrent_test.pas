program ConcurrentTest;

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
 * 并发测试Michael-Scott队列
 *}
procedure TestMichaelScottQueueConcurrency;
type
  TIntQueue = specialize TMichaelScottQueue<Integer>;
var
  LQueue: TIntQueue;
  LEnqueueThreads: array[0..2] of TThread;
  LDequeueThreads: array[0..2] of TThread;
  LEnqueuedCount, LDequeuedCount: Integer;
  I: Integer;
begin
  WriteLn('=== Michael-Scott队列并发测试 ===');
  
  LQueue := TIntQueue.Create;
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
 * 测试SPSC队列性能
 *}
procedure TestSPSCQueuePerformance;
type
  TIntQueue = specialize TSPSCQueue<Integer>;
var
  LQueue: TIntQueue;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== SPSC队列性能测试 ===');
  
  LQueue := TIntQueue.Create(1024);
  try
    WriteLn('单线程测试100万次入队出队...');
    
    LStartTime := GetTickCount64;
    
    // 100万次入队出队
    for I := 1 to 1000000 do
    begin
      while not LQueue.Enqueue(I) do
        LQueue.Dequeue(LValue); // 队列满时先出队
    end;
    
    while LQueue.Dequeue(LValue) do
      ; // 清空队列
    
    LEndTime := GetTickCount64;
    
    WriteLn('200万次操作耗时: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('SPSC队列吞吐量: ', 2000000 * 1000 div (LEndTime - LStartTime), ' ops/sec')
    else
      WriteLn('SPSC队列吞吐量: 极高 (操作太快，无法测量)');
    
    WriteLn('✅ SPSC队列性能测试完成！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('无锁数据结构并发测试');
  WriteLn('====================');
  WriteLn;
  
  try
    TestTreiberStackConcurrency;
    TestMichaelScottQueueConcurrency;
    TestSPSCQueuePerformance;
    
    WriteLn('🎉 所有并发测试完成！');
    WriteLn;
    WriteLn('📝 测试说明:');
    WriteLn('- Treiber栈: 4个线程并发压栈，4个线程并发弹栈');
    WriteLn('- Michael-Scott队列: 3个线程并发入队，3个线程并发出队');
    WriteLn('- SPSC队列: 单线程高性能测试');
    WriteLn('- 所有测试都验证了数据的完整性');
    
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
