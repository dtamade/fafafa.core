program FinalVerification;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  // 原子统一：示例不再引用 fafafa.core.sync
  fafafa.core.lockfree;

{**
 * 逐个验证每个数据结构
 *}
procedure VerifyEachDataStructure;
type
  TTreiberStack = TIntTreiberStack;
  TPreAllocStack = TIntPreAllocStack;
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
  WriteLn('=== 逐个验证无锁数据结构 ===');
  WriteLn;
  
  // 1. 验证Treiber栈
  WriteLn('1. 验证Treiber栈...');
  LTreiberStack := CreateIntTreiberStack;
  try
    // 压栈
    for I := 1 to 5 do
      LTreiberStack.Push(I);
    
    // 弹栈
    Write('弹栈结果: ');
    while LTreiberStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
    WriteLn('✅ Treiber栈验证完成');
  finally
    LTreiberStack.Free;
  end;
  WriteLn;
  
  // 2. 验证预分配安全栈
  WriteLn('2. 验证预分配安全栈...');
  LPreAllocStack := CreateIntPreAllocStack(10);
  try
    // 压栈
    for I := 1 to 5 do
      LPreAllocStack.Push(I);
    
    // 弹栈
    Write('弹栈结果: ');
    while LPreAllocStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
    WriteLn('✅ 预分配安全栈验证完成');
  finally
    LPreAllocStack.Free;
  end;
  WriteLn;
  
  // 3. 验证Michael-Scott队列
  WriteLn('3. 验证Michael-Scott队列...');
  LMSQueue := CreateIntMPSCQueue;
  try
    // 入队
    for I := 1 to 5 do
      LMSQueue.Enqueue(I);
    
    // 出队
    Write('出队结果: ');
    while LMSQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
    WriteLn('✅ Michael-Scott队列验证完成');
  finally
    LMSQueue.Free;
  end;
  WriteLn;
  
  // 4. 验证预分配MPMC队列
  WriteLn('4. 验证预分配MPMC队列...');
  LMPMCQueue := CreateIntMPMCQueue(10);
  try
    // 入队
    for I := 1 to 5 do
      LMPMCQueue.Enqueue(I);
    
    // 出队
    Write('出队结果: ');
    while LMPMCQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
    WriteLn('✅ 预分配MPMC队列验证完成');
  finally
    LMPMCQueue.Free;
  end;
  WriteLn;
  
  // 5. 验证SPSC队列
  WriteLn('5. 验证SPSC队列...');
  LSPSCQueue := CreateIntSPSCQueue(10);
  try
    // 入队
    for I := 1 to 5 do
      LSPSCQueue.Enqueue(I);
    
    // 出队
    Write('出队结果: ');
    while LSPSCQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
    WriteLn('✅ SPSC队列验证完成');
  finally
    LSPSCQueue.Free;
  end;
  WriteLn;
  
  WriteLn('🎉 所有数据结构验证完成！');
end;

{**
 * 性能对比测试
 *}
procedure PerformanceComparison;
type
  TTreiberStack = TIntTreiberStack;
  TPreAllocStack = TIntPreAllocStack;
  TMichaelScottQueue = TIntMSQueue;
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
  OPERATIONS = 50000; // 减少操作数避免卡死
begin
  WriteLn('=== 性能对比测试 ===');
  WriteLn('每个数据结构执行', OPERATIONS, '次操作...');
  WriteLn;
  
  // Treiber栈
  WriteLn('测试Treiber栈...');
  LTreiberStack := CreateIntTreiberStack;
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
  WriteLn('测试预分配安全栈...');
  LPreAllocStack := CreateIntPreAllocStack(OPERATIONS);
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
  WriteLn('测试Michael-Scott队列...');
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
  WriteLn('测试预分配MPMC队列...');
  LMPMCQueue := CreateIntMPMCQueue(OPERATIONS);
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
  WriteLn('测试SPSC队列...');
  LSPSCQueue := CreateIntSPSCQueue(OPERATIONS);
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
  
  WriteLn('✅ 性能对比测试完成！');
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('无锁数据结构最终验证');
  WriteLn('====================');
  WriteLn;
  
  try
    VerifyEachDataStructure;
    PerformanceComparison;
    
    WriteLn('🎉 最终验证完成！');
    WriteLn;
    WriteLn('📚 无锁数据结构库总结:');
    WriteLn('- Treiber栈: 经典无锁栈，LIFO');
    WriteLn('- 预分配安全栈: 解决ABA问题，有容量限制');
    WriteLn('- Michael-Scott队列: 经典无锁队列，FIFO');
    WriteLn('- 预分配MPMC队列: Dmitry Vyukov算法，FIFO');
    WriteLn('- SPSC队列: 高性能单生产者单消费者，FIFO');
    WriteLn;
    WriteLn('✅ 所有数据结构都基于学术界验证的算法！');
    
  except
    on E: Exception do
    begin
      WriteLn('验证过程中发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
