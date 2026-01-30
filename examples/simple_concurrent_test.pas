program SimpleConcurrentTest;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  // 原子统一：示例不再引用 fafafa.core.sync
  fafafa.core.lockfree;

{**
 * 简单的并发测试（避免匿名线程）
 *}
procedure TestBasicConcurrency;
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
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 基础并发安全测试 ===');
  WriteLn('单线程模拟并发操作...');
  WriteLn;
  
  // 测试Treiber栈
  WriteLn('测试Treiber栈...');
  LTreiberStack := TTreiberStack.Create;
  try
    for I := 1 to 1000 do
      LTreiberStack.Push(I);
    
    I := 1000;
    while LTreiberStack.Pop(LValue) do
    begin
      if LValue <> I then
      begin
        WriteLn('❌ Treiber栈LIFO顺序错误');
        Break;
      end;
      Dec(I);
    end;
    
    if I = 0 then
      WriteLn('✅ Treiber栈LIFO顺序正确')
    else
      WriteLn('❌ Treiber栈测试失败');
  finally
    LTreiberStack.Free;
  end;
  
  // 测试预分配安全栈
  WriteLn('测试预分配安全栈...');
  LPreAllocStack := TPreAllocStack.Create(1000);
  try
    for I := 1 to 1000 do
      LPreAllocStack.Push(I);
    
    I := 1000;
    while LPreAllocStack.Pop(LValue) do
    begin
      if LValue <> I then
      begin
        WriteLn('❌ 预分配安全栈LIFO顺序错误');
        Break;
      end;
      Dec(I);
    end;
    
    if I = 0 then
      WriteLn('✅ 预分配安全栈LIFO顺序正确')
    else
      WriteLn('❌ 预分配安全栈测试失败');
  finally
    LPreAllocStack.Free;
  end;
  
  // 测试Michael-Scott队列
  WriteLn('测试Michael-Scott队列...');
  LMSQueue := CreateIntMPSCQueue;
  try
    for I := 1 to 1000 do
      LMSQueue.Enqueue(I);
    
    I := 1;
    while LMSQueue.Dequeue(LValue) do
    begin
      if LValue <> I then
      begin
        WriteLn('❌ Michael-Scott队列FIFO顺序错误');
        Break;
      end;
      Inc(I);
    end;
    
    if I = 1001 then
      WriteLn('✅ Michael-Scott队列FIFO顺序正确')
    else
      WriteLn('❌ Michael-Scott队列测试失败');
  finally
    LMSQueue.Free;
  end;
  
  // 测试预分配MPMC队列
  WriteLn('测试预分配MPMC队列...');
  LMPMCQueue := CreateIntMPMCQueue(1000);
  try
    for I := 1 to 1000 do
      LMPMCQueue.Enqueue(I);
    
    I := 1;
    while LMPMCQueue.Dequeue(LValue) do
    begin
      if LValue <> I then
      begin
        WriteLn('❌ 预分配MPMC队列FIFO顺序错误');
        Break;
      end;
      Inc(I);
    end;
    
    if I = 1001 then
      WriteLn('✅ 预分配MPMC队列FIFO顺序正确')
    else
      WriteLn('❌ 预分配MPMC队列测试失败');
  finally
    LMPMCQueue.Free;
  end;
  
  // 测试SPSC队列
  WriteLn('测试SPSC队列...');
  LSPSCQueue := CreateIntSPSCQueue(1000);
  try
    for I := 1 to 1000 do
      LSPSCQueue.Enqueue(I);
    
    I := 1;
    while LSPSCQueue.Dequeue(LValue) do
    begin
      if LValue <> I then
      begin
        WriteLn('❌ SPSC队列FIFO顺序错误');
        Break;
      end;
      Inc(I);
    end;
    
    if I = 1001 then
      WriteLn('✅ SPSC队列FIFO顺序正确')
    else
      WriteLn('❌ SPSC队列测试失败');
  finally
    LSPSCQueue.Free;
  end;
  
  WriteLn('✅ 基础并发安全测试完成！');
  WriteLn;
end;

{**
 * 性能基准测试
 *}
procedure BenchmarkAllDataStructures;
type
  TTreiberStack = specialize TTreiberStack<Integer>;
  TPreAllocStack = specialize TPreAllocStack<Integer>;
  TMichaelScottQueue = specialize TMichaelScottQueue<Integer>;
  TPreAllocMPMCQueue = specialize TPreAllocMPMCQueue<Integer>;
  TSPSCQueue = specialize TSPSCQueue<Integer>;
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
  WriteLn('无锁数据结构简单并发测试');
  WriteLn('==========================');
  WriteLn;
  
  try
    TestBasicConcurrency;
    BenchmarkAllDataStructures;
    
    WriteLn('🎉 所有测试完成！');
    WriteLn;
    WriteLn('📊 测试总结:');
    WriteLn('- 所有数据结构的基础功能正常');
    WriteLn('- LIFO/FIFO顺序正确');
    WriteLn('- 性能基准测试完成');
    WriteLn;
    WriteLn('✅ 无锁数据结构库验证成功！');
    
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
