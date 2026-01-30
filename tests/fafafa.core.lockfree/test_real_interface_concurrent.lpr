program test_real_interface_concurrent;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, syncobjs,
  fafafa.core.lockfree,
  fafafa.core.collections.queue;

type
  { 真正实现 IQueue 接口的无锁队列 }
  TRealLockFreeQueue = class(specialize TPreAllocMPMCQueue<Integer>, specialize IQueue<Integer>)
  public
    // 实现 IQueue 接口
    procedure Enqueue(const aElement: Integer); overload;
    procedure Push(const aElement: Integer); overload;
    function Dequeue: Integer; overload;
    function Pop: Integer; overload;
    function Dequeue(var aElement: Integer): Boolean; overload;
    function Pop(var aElement: Integer): Boolean; overload;
    function Peek: Integer; overload;
    function Peek(var aElement: Integer): Boolean; overload;
    
    // 继承自 IGenericCollection 的方法需要实现
    function GetCount: Integer;
    function IsEmpty: Boolean; override;
    procedure Clear;
    function ToArray: specialize TArray<Integer>;
    function GetEnumerator: specialize IEnumerator<Integer>;
  end;

  { 生产者线程 }
  TProducerThread = class(TThread)
  private
    FQueue: TRealLockFreeQueue;
    FStartValue: Integer;
    FCount: Integer;
    FProduced: Integer;
  public
    constructor Create(AQueue: TRealLockFreeQueue; AStartValue, ACount: Integer);
    procedure Execute; override;
    property Produced: Integer read FProduced;
  end;

  { 消费者线程 }
  TConsumerThread = class(TThread)
  private
    FQueue: TRealLockFreeQueue;
    FConsumed: Integer;
    FValues: array of Integer;
  public
    constructor Create(AQueue: TRealLockFreeQueue);
    procedure Execute; override;
    property Consumed: Integer read FConsumed;
    property Values: array of Integer read FValues;
  end;

{ TRealLockFreeQueue }

procedure TRealLockFreeQueue.Enqueue(const aElement: Integer);
begin
  if not inherited Enqueue(aElement) then
    raise Exception.Create('Queue is full');
end;

procedure TRealLockFreeQueue.Push(const aElement: Integer);
begin
  Enqueue(aElement);
end;

function TRealLockFreeQueue.Dequeue: Integer;
begin
  if not inherited Dequeue(Result) then
    raise Exception.Create('Queue is empty');
end;

function TRealLockFreeQueue.Pop: Integer;
begin
  Result := Dequeue;
end;

function TRealLockFreeQueue.Dequeue(var aElement: Integer): Boolean;
begin
  Result := inherited Dequeue(aElement);
end;

function TRealLockFreeQueue.Pop(var aElement: Integer): Boolean;
begin
  Result := Dequeue(aElement);
end;

function TRealLockFreeQueue.Peek: Integer;
begin
  raise Exception.Create('Peek not supported by lock-free queue');
end;

function TRealLockFreeQueue.Peek(var aElement: Integer): Boolean;
begin
  Result := False; // 不支持
end;

function TRealLockFreeQueue.GetCount: Integer;
begin
  Result := GetSize;
end;

procedure TRealLockFreeQueue.Clear;
var
  LDummy: Integer;
begin
  while Dequeue(LDummy) do
    ; // 清空队列
end;

function TRealLockFreeQueue.ToArray: specialize TArray<Integer>;
var
  LResult: specialize TArray<Integer>;
  LCount, I: Integer;
  LValue: Integer;
begin
  // 注意：这个实现不是线程安全的，仅用于演示
  LCount := GetCount;
  SetLength(LResult, LCount);
  I := 0;
  while (I < LCount) and Dequeue(LValue) do
  begin
    LResult[I] := LValue;
    Inc(I);
  end;
  SetLength(LResult, I);
  Result := LResult;
end;

function TRealLockFreeQueue.GetEnumerator: specialize IEnumerator<Integer>;
begin
  raise Exception.Create('Enumerator not implemented for lock-free queue');
end;

{ TProducerThread }

constructor TProducerThread.Create(AQueue: TRealLockFreeQueue; AStartValue, ACount: Integer);
begin
  inherited Create(False);
  FQueue := AQueue;
  FStartValue := AStartValue;
  FCount := ACount;
  FProduced := 0;
end;

procedure TProducerThread.Execute;
var
  I: Integer;
begin
  for I := FStartValue to FStartValue + FCount - 1 do
  begin
    try
      FQueue.Enqueue(I);
      Inc(FProduced);
    except
      // 队列满了，跳过
    end;
    if Terminated then Break;
  end;
end;

{ TConsumerThread }

constructor TConsumerThread.Create(AQueue: TRealLockFreeQueue);
begin
  inherited Create(False);
  FQueue := AQueue;
  FConsumed := 0;
  SetLength(FValues, 10000); // 预分配空间
end;

procedure TConsumerThread.Execute;
var
  LValue: Integer;
begin
  while not Terminated do
  begin
    if FQueue.Dequeue(LValue) then
    begin
      if FConsumed < Length(FValues) then
        FValues[FConsumed] := LValue;
      Inc(FConsumed);
    end
    else
      Sleep(1); // 队列空，稍等
  end;
end;

procedure TestRealInterfaceImplementation;
var
  LQueue: TRealLockFreeQueue;
  LIntf: specialize IQueue<Integer>;
begin
  WriteLn('=== 测试真正的接口实现 ===');
  
  LQueue := TRealLockFreeQueue.Create(100);
  try
    // 测试接口赋值
    LIntf := LQueue;
    WriteLn('✅ 成功赋值给 IQueue 接口');
    
    // 通过接口调用方法
    LIntf.Enqueue(1);
    LIntf.Enqueue(2);
    LIntf.Enqueue(3);
    WriteLn('✅ 通过接口成功入队');
    
    var LValue: Integer;
    while LIntf.Dequeue(LValue) do
      WriteLn('  通过接口出队: ', LValue);
    
    WriteLn('✅ 真正的接口实现测试完成');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

procedure TestConcurrentSafety;
const
  PRODUCER_COUNT = 4;
  CONSUMER_COUNT = 2;
  ITEMS_PER_PRODUCER = 1000;
var
  LQueue: TRealLockFreeQueue;
  LProducers: array[0..PRODUCER_COUNT-1] of TProducerThread;
  LConsumers: array[0..CONSUMER_COUNT-1] of TConsumerThread;
  I: Integer;
  LTotalProduced, LTotalConsumed: Integer;
begin
  WriteLn('=== 测试并发安全性 ===');
  WriteLn('生产者线程: ', PRODUCER_COUNT);
  WriteLn('消费者线程: ', CONSUMER_COUNT);
  WriteLn('每个生产者产生: ', ITEMS_PER_PRODUCER, ' 个元素');
  
  LQueue := TRealLockFreeQueue.Create(10000);
  try
    // 创建生产者线程
    for I := 0 to PRODUCER_COUNT - 1 do
    begin
      LProducers[I] := TProducerThread.Create(LQueue, I * ITEMS_PER_PRODUCER + 1, ITEMS_PER_PRODUCER);
    end;
    
    // 创建消费者线程
    for I := 0 to CONSUMER_COUNT - 1 do
    begin
      LConsumers[I] := TConsumerThread.Create(LQueue);
    end;
    
    WriteLn('启动所有线程...');
    
    // 等待生产者完成
    for I := 0 to PRODUCER_COUNT - 1 do
    begin
      LProducers[I].WaitFor;
    end;
    
    WriteLn('所有生产者完成');
    
    // 等待队列清空
    Sleep(1000);
    
    // 停止消费者
    for I := 0 to CONSUMER_COUNT - 1 do
    begin
      LConsumers[I].Terminate;
      LConsumers[I].WaitFor;
    end;
    
    // 统计结果
    LTotalProduced := 0;
    for I := 0 to PRODUCER_COUNT - 1 do
    begin
      WriteLn('生产者 ', I, ' 产生了 ', LProducers[I].Produced, ' 个元素');
      Inc(LTotalProduced, LProducers[I].Produced);
    end;
    
    LTotalConsumed := 0;
    for I := 0 to CONSUMER_COUNT - 1 do
    begin
      WriteLn('消费者 ', I, ' 消费了 ', LConsumers[I].Consumed, ' 个元素');
      Inc(LTotalConsumed, LConsumers[I].Consumed);
    end;
    
    WriteLn('总计产生: ', LTotalProduced);
    WriteLn('总计消费: ', LTotalConsumed);
    WriteLn('队列剩余: ', LQueue.GetSize);
    
    if LTotalProduced = LTotalConsumed + LQueue.GetSize then
      WriteLn('✅ 并发测试通过：没有数据丢失')
    else
      WriteLn('❌ 并发测试失败：数据不一致');
    
    // 清理
    for I := 0 to PRODUCER_COUNT - 1 do
      LProducers[I].Free;
    for I := 0 to CONSUMER_COUNT - 1 do
      LConsumers[I].Free;
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.lockfree 真正的接口实现和并发测试');
    WriteLn('===============================================');
    WriteLn;
    
    TestRealInterfaceImplementation;
    TestConcurrentSafety;
    
    WriteLn('🎯 测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
