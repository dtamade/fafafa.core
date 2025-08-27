program test_lockfree_stress;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, syncobjs,
  fafafa.core.lockfree;

type
  { 压力测试统计 }
  TStressStats = record
    ThreadId: TThreadID;
    OperationsCompleted: Int64;
    SuccessfulEnqueues: Int64;
    SuccessfulDequeues: Int64;
    FailedEnqueues: Int64;
    FailedDequeues: Int64;
    StartTime: QWord;
    EndTime: QWord;
    ElapsedMs: Int64;
  end;

  { 混合操作线程 }
  TMixedOperationThread = class(TThread)
  private
    FQueue: specialize TPreAllocMPMCQueue<Integer>;
    FStats: TStressStats;
    FDuration: Integer; // 测试持续时间（毫秒）
    FThreadIndex: Integer;
  public
    constructor Create(AQueue: specialize TPreAllocMPMCQueue<Integer>; 
                      ADuration: Integer; AThreadIndex: Integer);
    procedure Execute; override;
    property Stats: TStressStats read FStats;
  end;

  { 纯生产者线程 }
  TProducerOnlyThread = class(TThread)
  private
    FQueue: specialize TPreAllocMPMCQueue<Integer>;
    FStats: TStressStats;
    FItemCount: Integer;
    FThreadIndex: Integer;
  public
    constructor Create(AQueue: specialize TPreAllocMPMCQueue<Integer>; 
                      AItemCount: Integer; AThreadIndex: Integer);
    procedure Execute; override;
    property Stats: TStressStats read FStats;
  end;

  { 纯消费者线程 }
  TConsumerOnlyThread = class(TThread)
  private
    FQueue: specialize TPreAllocMPMCQueue<Integer>;
    FStats: TStressStats;
    FDuration: Integer;
    FThreadIndex: Integer;
  public
    constructor Create(AQueue: specialize TPreAllocMPMCQueue<Integer>; 
                      ADuration: Integer; AThreadIndex: Integer);
    procedure Execute; override;
    property Stats: TStressStats read FStats;
  end;

{ TMixedOperationThread }

constructor TMixedOperationThread.Create(AQueue: specialize TPreAllocMPMCQueue<Integer>; 
                                        ADuration: Integer; AThreadIndex: Integer);
begin
  inherited Create(False);
  FQueue := AQueue;
  FDuration := ADuration;
  FThreadIndex := AThreadIndex;
  FillChar(FStats, SizeOf(FStats), 0);
  FStats.ThreadId := ThreadID;
end;

procedure TMixedOperationThread.Execute;
var
  LStartTime: QWord;
  LValue: Integer;
  LOperationCount: Int64;
begin
  FStats.StartTime := GetTickCount64;
  LStartTime := FStats.StartTime;
  LOperationCount := 0;
  
  while (GetTickCount64 - LStartTime < FDuration) and not Terminated do
  begin
    Inc(LOperationCount);
    
    // 交替进行入队和出队操作
    if (LOperationCount mod 2) = 0 then
    begin
      // 入队操作
      LValue := FThreadIndex * 1000000 + LOperationCount;
      if FQueue.Enqueue(LValue) then
        Inc(FStats.SuccessfulEnqueues)
      else
        Inc(FStats.FailedEnqueues);
    end
    else
    begin
      // 出队操作
      if FQueue.Dequeue(LValue) then
        Inc(FStats.SuccessfulDequeues)
      else
        Inc(FStats.FailedDequeues);
    end;
    
    Inc(FStats.OperationsCompleted);
    
    // 偶尔让出CPU
    if (LOperationCount mod 1000) = 0 then
      Sleep(0);
  end;
  
  FStats.EndTime := GetTickCount64;
  FStats.ElapsedMs := FStats.EndTime - FStats.StartTime;
end;

{ TProducerOnlyThread }

constructor TProducerOnlyThread.Create(AQueue: specialize TPreAllocMPMCQueue<Integer>; 
                                      AItemCount: Integer; AThreadIndex: Integer);
begin
  inherited Create(False);
  FQueue := AQueue;
  FItemCount := AItemCount;
  FThreadIndex := AThreadIndex;
  FillChar(FStats, SizeOf(FStats), 0);
  FStats.ThreadId := ThreadID;
end;

procedure TProducerOnlyThread.Execute;
var
  I: Integer;
  LValue: Integer;
begin
  FStats.StartTime := GetTickCount64;
  
  for I := 1 to FItemCount do
  begin
    LValue := FThreadIndex * 1000000 + I;
    if FQueue.Enqueue(LValue) then
      Inc(FStats.SuccessfulEnqueues)
    else
      Inc(FStats.FailedEnqueues);
    
    Inc(FStats.OperationsCompleted);
    
    if Terminated then Break;
  end;
  
  FStats.EndTime := GetTickCount64;
  FStats.ElapsedMs := FStats.EndTime - FStats.StartTime;
end;

{ TConsumerOnlyThread }

constructor TConsumerOnlyThread.Create(AQueue: specialize TPreAllocMPMCQueue<Integer>; 
                                      ADuration: Integer; AThreadIndex: Integer);
begin
  inherited Create(False);
  FQueue := AQueue;
  FDuration := ADuration;
  FThreadIndex := AThreadIndex;
  FillChar(FStats, SizeOf(FStats), 0);
  FStats.ThreadId := ThreadID;
end;

procedure TConsumerOnlyThread.Execute;
var
  LStartTime: QWord;
  LValue: Integer;
begin
  FStats.StartTime := GetTickCount64;
  LStartTime := FStats.StartTime;
  
  while (GetTickCount64 - LStartTime < FDuration) and not Terminated do
  begin
    if FQueue.Dequeue(LValue) then
      Inc(FStats.SuccessfulDequeues)
    else
      Inc(FStats.FailedDequeues);
    
    Inc(FStats.OperationsCompleted);
    
    // 偶尔让出CPU
    if (FStats.OperationsCompleted mod 1000) = 0 then
      Sleep(0);
  end;
  
  FStats.EndTime := GetTickCount64;
  FStats.ElapsedMs := FStats.EndTime - FStats.StartTime;
end;

procedure PrintStats(const AStats: TStressStats; const AThreadName: string);
begin
  WriteLn('--- ', AThreadName, ' (ID: ', AStats.ThreadId, ') ---');
  WriteLn('  总操作数: ', AStats.OperationsCompleted);
  WriteLn('  成功入队: ', AStats.SuccessfulEnqueues);
  WriteLn('  失败入队: ', AStats.FailedEnqueues);
  WriteLn('  成功出队: ', AStats.SuccessfulDequeues);
  WriteLn('  失败出队: ', AStats.FailedDequeues);
  WriteLn('  运行时间: ', AStats.ElapsedMs, ' ms');
  if AStats.ElapsedMs > 0 then
    WriteLn('  操作速率: ', Round(AStats.OperationsCompleted * 1000.0 / AStats.ElapsedMs), ' ops/sec');
  WriteLn;
end;

procedure TestMixedOperations;
const
  THREAD_COUNT = 8;
  TEST_DURATION = 5000; // 5秒
  QUEUE_CAPACITY = 10000;
var
  LQueue: specialize TPreAllocMPMCQueue<Integer>;
  LThreads: array[0..THREAD_COUNT-1] of TMixedOperationThread;
  I: Integer;
  LTotalOps: Int64;
  LTotalEnqueues, LTotalDequeues: Int64;
begin
  WriteLn('=== 混合操作压力测试 ===');
  WriteLn('线程数: ', THREAD_COUNT);
  WriteLn('测试时长: ', TEST_DURATION, ' ms');
  WriteLn('队列容量: ', QUEUE_CAPACITY);
  WriteLn;
  
  LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(QUEUE_CAPACITY);
  try
    // 创建线程
    for I := 0 to THREAD_COUNT - 1 do
    begin
      LThreads[I] := TMixedOperationThread.Create(LQueue, TEST_DURATION, I);
    end;
    
    WriteLn('启动所有线程...');
    
    // 等待所有线程完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      LThreads[I].WaitFor;
    end;
    
    WriteLn('所有线程完成，统计结果：');
    WriteLn;
    
    // 统计结果
    LTotalOps := 0;
    LTotalEnqueues := 0;
    LTotalDequeues := 0;
    
    for I := 0 to THREAD_COUNT - 1 do
    begin
      PrintStats(LThreads[I].Stats, Format('混合线程 %d', [I]));
      Inc(LTotalOps, LThreads[I].Stats.OperationsCompleted);
      Inc(LTotalEnqueues, LThreads[I].Stats.SuccessfulEnqueues);
      Inc(LTotalDequeues, LThreads[I].Stats.SuccessfulDequeues);
      LThreads[I].Free;
    end;
    
    WriteLn('=== 总计统计 ===');
    WriteLn('总操作数: ', LTotalOps);
    WriteLn('总入队数: ', LTotalEnqueues);
    WriteLn('总出队数: ', LTotalDequeues);
    WriteLn('队列剩余: ', LQueue.GetSize);
    WriteLn('数据一致性: ', LTotalEnqueues - LTotalDequeues = LQueue.GetSize);
    WriteLn('平均吞吐量: ', Round(LTotalOps * 1000.0 / TEST_DURATION), ' ops/sec');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

procedure TestProducerConsumer;
const
  PRODUCER_COUNT = 4;
  CONSUMER_COUNT = 4;
  ITEMS_PER_PRODUCER = 100000;
  CONSUMER_DURATION = 10000; // 10秒
  QUEUE_CAPACITY = 50000;
var
  LQueue: specialize TPreAllocMPMCQueue<Integer>;
  LProducers: array[0..PRODUCER_COUNT-1] of TProducerOnlyThread;
  LConsumers: array[0..CONSUMER_COUNT-1] of TConsumerOnlyThread;
  I: Integer;
  LTotalProduced, LTotalConsumed: Int64;
begin
  WriteLn('=== 生产者-消费者压力测试 ===');
  WriteLn('生产者数: ', PRODUCER_COUNT);
  WriteLn('消费者数: ', CONSUMER_COUNT);
  WriteLn('每个生产者产生: ', ITEMS_PER_PRODUCER, ' 个元素');
  WriteLn('消费者运行时间: ', CONSUMER_DURATION, ' ms');
  WriteLn('队列容量: ', QUEUE_CAPACITY);
  WriteLn;
  
  LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(QUEUE_CAPACITY);
  try
    // 创建生产者线程
    for I := 0 to PRODUCER_COUNT - 1 do
    begin
      LProducers[I] := TProducerOnlyThread.Create(LQueue, ITEMS_PER_PRODUCER, I);
    end;
    
    // 创建消费者线程
    for I := 0 to CONSUMER_COUNT - 1 do
    begin
      LConsumers[I] := TConsumerOnlyThread.Create(LQueue, CONSUMER_DURATION, I + 100);
    end;
    
    WriteLn('启动所有线程...');
    
    // 等待生产者完成
    for I := 0 to PRODUCER_COUNT - 1 do
    begin
      LProducers[I].WaitFor;
    end;
    
    WriteLn('所有生产者完成，等待消费者...');
    Sleep(2000); // 让消费者继续工作一会儿
    
    // 停止消费者
    for I := 0 to CONSUMER_COUNT - 1 do
    begin
      LConsumers[I].Terminate;
      LConsumers[I].WaitFor;
    end;
    
    WriteLn('统计结果：');
    WriteLn;
    
    // 统计生产者
    LTotalProduced := 0;
    for I := 0 to PRODUCER_COUNT - 1 do
    begin
      PrintStats(LProducers[I].Stats, Format('生产者 %d', [I]));
      Inc(LTotalProduced, LProducers[I].Stats.SuccessfulEnqueues);
      LProducers[I].Free;
    end;
    
    // 统计消费者
    LTotalConsumed := 0;
    for I := 0 to CONSUMER_COUNT - 1 do
    begin
      PrintStats(LConsumers[I].Stats, Format('消费者 %d', [I]));
      Inc(LTotalConsumed, LConsumers[I].Stats.SuccessfulDequeues);
      LConsumers[I].Free;
    end;
    
    WriteLn('=== 最终统计 ===');
    WriteLn('总生产: ', LTotalProduced);
    WriteLn('总消费: ', LTotalConsumed);
    WriteLn('队列剩余: ', LQueue.GetSize);
    WriteLn('数据一致性: ', LTotalProduced = LTotalConsumed + LQueue.GetSize);
    WriteLn('生产效率: ', Round(LTotalProduced / (PRODUCER_COUNT * ITEMS_PER_PRODUCER) * 100), '%');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.lockfree 无锁数据结构压力测试');
    WriteLn('==========================================');
    WriteLn('CPU核心数: ', GetCPUCount);
    WriteLn;
    
    TestMixedOperations;
    TestProducerConsumer;
    
    WriteLn('🎯 压力测试完成！');
    WriteLn;
    WriteLn('注意：这个测试可以揭示：');
    WriteLn('1. 并发安全性问题');
    WriteLn('2. 数据一致性问题');
    WriteLn('3. 性能瓶颈');
    WriteLn('4. 内存竞争问题');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 压力测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
