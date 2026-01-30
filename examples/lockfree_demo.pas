program LockFreeDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  // 原子统一：示例不再引用 fafafa.core.sync
  fafafa.core.lockfree;

{**
 * 演示 SPSC 队列的高性能特性
 *}
procedure DemoSPSCQueue;
type
  TIntQueue = TIntegerSPSCQueue;
var
  LQueue: TIntQueue;
  LStartTime, LEndTime: QWord;
  I: Integer;
  LValue: Integer;
begin
  WriteLn('=== SPSC队列演示 ===');
  
  LQueue := CreateIntSPSCQueue(1024);
  try
    WriteLn('队列容量: ', LQueue.Capacity);
    
    // 性能测试
    WriteLn('执行100万次入队出队操作...');
    LStartTime := GetTickCount64;
    
    for I := 1 to 1000000 do
    begin
      while not LQueue.Enqueue(I) do ; // 等待入队成功
      while not LQueue.Dequeue(LValue) do ; // 等待出队成功
    end;
    
    LEndTime := GetTickCount64;
    
    WriteLn('耗时: ', LEndTime - LStartTime, ' ms');
    WriteLn('平均每次操作: ', ((LEndTime - LStartTime) * 1000) / 2000000:0:3, ' μs');
    WriteLn('✅ SPSC队列性能优秀！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 简单的工作线程类
 *}
type
  TProducerThread = class(TThread)
  private
    FQueue: Pointer; // 指向队列的指针
    FProducedCount: PInteger;
    FWorkerId: Integer;
  public
    constructor Create(AQueue: Pointer; AProducedCount: PInteger; AWorkerId: Integer);
    procedure Execute; override;
  end;

  TConsumerThread = class(TThread)
  private
    FQueue: Pointer;
    FConsumedCount: PInteger;
    FTargetCount: Integer;
  public
    constructor Create(AQueue: Pointer; AConsumedCount: PInteger; ATargetCount: Integer);
    procedure Execute; override;
  end;

constructor TProducerThread.Create(AQueue: Pointer; AProducedCount: PInteger; AWorkerId: Integer);
begin
  FQueue := AQueue;
  FProducedCount := AProducedCount;
  FWorkerId := AWorkerId;
  inherited Create(False);
end;

procedure TProducerThread.Execute;
type
  TIntQueue = TIntMPSCQueue;
var
  LQueue: TIntQueue;
  J: Integer;
begin
  LQueue := TIntQueue(FQueue);
  for J := 1 to 1000 do
  begin
    LQueue.Enqueue(FWorkerId * 1000 + J);
    InterlockedIncrement(FProducedCount^);
    if J mod 200 = 0 then
      WriteLn('生产者', FWorkerId, '已生产', J, '个项目');
  end;
  WriteLn('生产者', FWorkerId, '完成');
end;

constructor TConsumerThread.Create(AQueue: Pointer; AConsumedCount: PInteger; ATargetCount: Integer);
begin
  FQueue := AQueue;
  FConsumedCount := AConsumedCount;
  FTargetCount := ATargetCount;
  inherited Create(False);
end;

procedure TConsumerThread.Execute;
type
  TIntQueue = TIntMPSCQueue;
var
  LQueue: TIntQueue;
  LValue: Integer;
  LCount: Integer;
begin
  LQueue := TIntQueue(FQueue);
  LCount := 0;
  while LCount < FTargetCount do
  begin
    if LQueue.Dequeue(LValue) then
    begin
      Inc(LCount);
      InterlockedIncrement(FConsumedCount^);
      if LCount mod 500 = 0 then
        WriteLn('消费者已消费', LCount, '个项目');
    end
    else
      Sleep(1);
  end;
  WriteLn('消费者完成');
end;

{**
 * 演示多线程生产者-消费者模式
 *}
procedure DemoProducerConsumer;
type
  TIntQueue = TIntMPSCQueue;
var
  LQueue: TIntQueue;
  LProducedCount, LConsumedCount: Integer;
  LProducers: array[0..2] of TProducerThread;
  LConsumer: TConsumerThread;
  I: Integer;
begin
  WriteLn('=== 生产者-消费者演示 ===');

  LQueue := CreateIntMPSCQueue;
  LProducedCount := 0;
  LConsumedCount := 0;

  try
    WriteLn('启动3个生产者线程和1个消费者线程...');

    // 创建3个生产者线程
    for I := 0 to 2 do
      LProducers[I] := TProducerThread.Create(LQueue, @LProducedCount, I + 1);

    // 创建消费者线程
    LConsumer := TConsumerThread.Create(LQueue, @LConsumedCount, 3000);

    // 等待所有线程完成
    for I := 0 to 2 do
      LProducers[I].WaitFor;
    LConsumer.WaitFor;

    WriteLn('生产总数: ', LProducedCount);
    WriteLn('消费总数: ', LConsumedCount);

    if (LProducedCount = 3000) and (LConsumedCount = 3000) then
      WriteLn('✅ 生产者-消费者模式成功！')
    else
      WriteLn('❌ 生产者-消费者模式失败！');

  finally
    // 清理线程
    for I := 0 to 2 do
      if Assigned(LProducers[I]) then
        LProducers[I].Free;
    if Assigned(LConsumer) then
      LConsumer.Free;
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 演示无锁栈的基础功能
 *}
procedure DemoLockFreeStack;
type
  TIntStack = specialize TLockFreeStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 无锁栈演示 ===');

  LStack := TIntStack.Create;

  try
    WriteLn('压栈1000个元素...');
    for I := 1 to 1000 do
      LStack.Push(I);

    WriteLn('栈大小: ', LStack.GetSize);

    WriteLn('弹栈前10个元素: ');
    for I := 1 to 10 do
    begin
      if LStack.Pop(LValue) then
        Write(LValue, ' ');
    end;
    WriteLn;

    WriteLn('剩余栈大小: ', LStack.GetSize);
    WriteLn('✅ 无锁栈基础功能正常！');

  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 演示 MPMC 队列的基础功能
 *}
procedure DemoMPMCQueue;
type
  TIntQueue = TIntMPMCQueue;
var
  LQueue: TIntQueue;
  LValue: Integer;
  LStartTime, LEndTime: QWord;
  I: Integer;
begin
  WriteLn('=== MPMC队列演示 ===');

  LQueue := CreateIntMPMCQueue(1024);

  try
    WriteLn('测试MPMC队列性能...');

    LStartTime := GetTickCount64;

    // 入队1000个元素
    for I := 1 to 1000 do
      while not LQueue.Enqueue(I) do ;

    WriteLn('入队完成，开始出队...');

    // 出队1000个元素
    for I := 1 to 1000 do
      while not LQueue.Dequeue(LValue) do ;

    LEndTime := GetTickCount64;

    WriteLn('2000次操作耗时: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('吞吐量: ', 2000 * 1000 div (LEndTime - LStartTime), ' ops/sec')
    else
      WriteLn('吞吐量: 极高 (操作太快，无法测量)');
    WriteLn('✅ MPMC队列性能测试完成！');

  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('fafafa.core.lockfree 无锁数据结构演示');
  WriteLn('=====================================');
  WriteLn;
  
  try
    DemoSPSCQueue;
    DemoProducerConsumer;
    DemoLockFreeStack;
    DemoMPMCQueue;
    
    WriteLn('🎉 所有无锁数据结构演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('演示过程中发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
