program ProducerConsumer;

{$mode objfpc}{$H+}

{
  生产者-消费者模式示例
  
  本示例演示：
  1. 使用事件进行线程间通信
  2. 生产者-消费者经典同步模式
  3. 多线程环境下的事件使用
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 简单的线程安全队列 }
  TSimpleQueue = class
  private
    FItems: array[0..99] of Integer;
    FHead, FTail, FCount: Integer;
    FLock: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function Enqueue(AItem: Integer): Boolean;
    function Dequeue(out AItem: Integer): Boolean;
    function Count: Integer;
    function IsFull: Boolean;
    function IsEmpty: Boolean;
  end;

  { 生产者线程 }
  TProducerThread = class(TThread)
  private
    FQueue: TSimpleQueue;
    FDataAvailableEvent: IEvent;
    FProducerId: Integer;
    FItemsProduced: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AQueue: TSimpleQueue; ADataAvailableEvent: IEvent; AProducerId: Integer);
    property ItemsProduced: Integer read FItemsProduced;
  end;

  { 消费者线程 }
  TConsumerThread = class(TThread)
  private
    FQueue: TSimpleQueue;
    FDataAvailableEvent: IEvent;
    FConsumerId: Integer;
    FItemsConsumed: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AQueue: TSimpleQueue; ADataAvailableEvent: IEvent; AConsumerId: Integer);
    property ItemsConsumed: Integer read FItemsConsumed;
  end;

{ TSimpleQueue }
constructor TSimpleQueue.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
  FHead := 0;
  FTail := 0;
  FCount := 0;
end;

destructor TSimpleQueue.Destroy;
begin
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

function TSimpleQueue.Enqueue(AItem: Integer): Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := not IsFull;
    if Result then
    begin
      FItems[FTail] := AItem;
      FTail := (FTail + 1) mod Length(FItems);
      Inc(FCount);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSimpleQueue.Dequeue(out AItem: Integer): Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := not IsEmpty;
    if Result then
    begin
      AItem := FItems[FHead];
      FHead := (FHead + 1) mod Length(FItems);
      Dec(FCount);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSimpleQueue.Count: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSimpleQueue.IsFull: Boolean;
begin
  Result := FCount >= Length(FItems);
end;

function TSimpleQueue.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

{ TProducerThread }
constructor TProducerThread.Create(AQueue: TSimpleQueue; ADataAvailableEvent: IEvent; AProducerId: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FQueue := AQueue;
  FDataAvailableEvent := ADataAvailableEvent;
  FProducerId := AProducerId;
  FItemsProduced := 0;
end;

procedure TProducerThread.Execute;
var
  Item: Integer;
  i: Integer;
begin
  WriteLn('生产者 ', FProducerId, ' 开始工作');
  
  for i := 1 to 20 do
  begin
    if Terminated then Break;
    
    // 生成数据项
    Item := FProducerId * 1000 + i;
    
    // 等待队列有空间
    while not Terminated and FQueue.IsFull do
      Sleep(10);
      
    if Terminated then Break;
    
    // 添加到队列
    if FQueue.Enqueue(Item) then
    begin
      Inc(FItemsProduced);
      WriteLn('生产者 ', FProducerId, ' 生产了项目：', Item);
      
      // 通知消费者有数据可用
      FDataAvailableEvent.SetEvent;
      
      // 模拟生产时间
      Sleep(50 + Random(100));
    end;
  end;
  
  WriteLn('生产者 ', FProducerId, ' 完成，共生产 ', FItemsProduced, ' 个项目');
end;

{ TConsumerThread }
constructor TConsumerThread.Create(AQueue: TSimpleQueue; ADataAvailableEvent: IEvent; AConsumerId: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FQueue := AQueue;
  FDataAvailableEvent := ADataAvailableEvent;
  FConsumerId := AConsumerId;
  FItemsConsumed := 0;
end;

procedure TConsumerThread.Execute;
var
  Item: Integer;
  WaitResult: TWaitResult;
begin
  WriteLn('消费者 ', FConsumerId, ' 开始工作');
  
  while not Terminated do
  begin
    // 等待数据可用信号
    WaitResult := FDataAvailableEvent.WaitFor(1000);
    
    if WaitResult = wrSignaled then
    begin
      // 尝试从队列获取数据
      while not Terminated and FQueue.Dequeue(Item) do
      begin
        Inc(FItemsConsumed);
        WriteLn('消费者 ', FConsumerId, ' 消费了项目：', Item);
        
        // 模拟处理时间
        Sleep(30 + Random(70));
      end;
    end
    else if WaitResult = wrTimeout then
    begin
      // 超时，检查是否应该退出
      if FQueue.IsEmpty then
        Break;
    end;
  end;
  
  WriteLn('消费者 ', FConsumerId, ' 完成，共消费 ', FItemsConsumed, ' 个项目');
end;

procedure RunProducerConsumerDemo;
const
  ProducerCount = 2;
  ConsumerCount = 3;
var
  Queue: TSimpleQueue;
  DataAvailableEvent: IEvent;
  Producers: array[0..ProducerCount-1] of TProducerThread;
  Consumers: array[0..ConsumerCount-1] of TConsumerThread;
  i: Integer;
  TotalProduced, TotalConsumed: Integer;
begin
  WriteLn('=== 生产者-消费者演示 ===');
  WriteLn('生产者数量：', ProducerCount);
  WriteLn('消费者数量：', ConsumerCount);
  WriteLn;
  
  // 创建共享资源
  Queue := TSimpleQueue.Create;
  try
    // 使用手动重置事件，这样多个消费者都能收到信号
    DataAvailableEvent := MakeEvent(True, False);
    
    // 创建生产者线程
    for i := 0 to ProducerCount - 1 do
    begin
      Producers[i] := TProducerThread.Create(Queue, DataAvailableEvent, i + 1);
      Producers[i].Start;
    end;
    
    // 创建消费者线程
    for i := 0 to ConsumerCount - 1 do
    begin
      Consumers[i] := TConsumerThread.Create(Queue, DataAvailableEvent, i + 1);
      Consumers[i].Start;
    end;
    
    // 等待所有生产者完成
    for i := 0 to ProducerCount - 1 do
    begin
      Producers[i].WaitFor;
      Producers[i].Free;
    end;
    
    WriteLn('所有生产者已完成');
    
    // 等待队列清空
    while not Queue.IsEmpty do
    begin
      DataAvailableEvent.SetEvent;
      Sleep(100);
    end;
    
    // 终止消费者
    for i := 0 to ConsumerCount - 1 do
    begin
      Consumers[i].Terminate;
      DataAvailableEvent.SetEvent; // 唤醒等待的消费者
    end;
    
    // 等待所有消费者完成
    for i := 0 to ConsumerCount - 1 do
    begin
      Consumers[i].WaitFor;
      Consumers[i].Free;
    end;
    
    WriteLn('所有消费者已完成');
    
    // 统计结果
    TotalProduced := ProducerCount * 20; // 每个生产者生产20个项目
    TotalConsumed := 0;
    for i := 0 to ConsumerCount - 1 do
      TotalConsumed := TotalConsumed + Consumers[i].ItemsConsumed;
    
    WriteLn;
    WriteLn('=== 统计结果 ===');
    WriteLn('总生产项目：', TotalProduced);
    WriteLn('总消费项目：', TotalConsumed);
    WriteLn('剩余项目：', Queue.Count);
    WriteLn('数据一致性：', IfThen(TotalProduced = TotalConsumed + Queue.Count, '正确', '错误'));
    
  finally
    Queue.Free;
  end;
end;

begin
  WriteLn('fafafa.core 事件同步原语 - 生产者消费者示例');
  WriteLn('==================================================');
  WriteLn;
  
  Randomize;
  
  try
    RunProducerConsumerDemo;
    WriteLn;
    WriteLn('演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生错误：', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
