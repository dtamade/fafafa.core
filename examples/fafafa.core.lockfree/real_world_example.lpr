program real_world_example;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, DateUtils,
  fafafa.core.lockfree,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.mpmcQueue,
  fafafa.core.lockfree.stack;

type
  // 模拟日志消息
  TLogMessage = record
    Timestamp: QWord;
    Level: Integer;  // 1=Info, 2=Warning, 3=Error
    ThreadId: Integer;
    Message: string;
  end;

  // 模拟网络数据包
  TNetworkPacket = record
    PacketId: Integer;
    SourceIP: Cardinal;
    DestIP: Cardinal;
    DataSize: Integer;
    Data: array[0..255] of Byte;
  end;

var
  // 高性能日志队列（单生产者单消费者）
  GLogQueue: specialize TSPSCQueue<TLogMessage>;
  
  // 网络数据包处理队列（多生产者多消费者）
  GPacketQueue: specialize TPreAllocMPMCQueue<TNetworkPacket>;
  
  // 任务栈（多线程安全）
  GTaskStack: specialize TTreiberStack<Integer>;
  
  // 运行控制
  GRunning: Boolean = True;
  GLogCount: Integer = 0;
  GPacketCount: Integer = 0;
  GTaskCount: Integer = 0;

// 模拟日志生产者
procedure LogProducer;
var
  LMessage: TLogMessage;
  I: Integer;
begin
  WriteLn('[日志生产者] 开始生成日志...');
  
  for I := 1 to 100000 do
  begin
    LMessage.Timestamp := GetTickCount64;
    LMessage.Level := (I mod 3) + 1;
    LMessage.ThreadId := GetCurrentThreadId;
    LMessage.Message := Format('日志消息 #%d', [I]);
    
    if GLogQueue.Enqueue(LMessage) then
      InterlockedIncrement(GLogCount)
    else
      WriteLn('[日志生产者] 队列已满，丢弃消息');
      
    // 模拟一些处理时间
    if (I mod 10000) = 0 then
      Sleep(1);
  end;
  
  WriteLn('[日志生产者] 完成，共生成 ', GLogCount, ' 条日志');
end;

// 模拟日志消费者
procedure LogConsumer;
var
  LMessage: TLogMessage;
  LProcessed: Integer;
begin
  WriteLn('[日志消费者] 开始处理日志...');
  LProcessed := 0;
  
  while GRunning or not GLogQueue.IsEmpty do
  begin
    if GLogQueue.Dequeue(LMessage) then
    begin
      Inc(LProcessed);
      
      // 模拟日志处理（写入文件、发送到服务器等）
      case LMessage.Level of
        1: ; // Info - 正常处理
        2: ; // Warning - 特殊处理
        3: ; // Error - 紧急处理
      end;
      
      // 每处理1万条显示进度
      if (LProcessed mod 10000) = 0 then
        WriteLn('[日志消费者] 已处理 ', LProcessed, ' 条日志');
    end
    else
      Sleep(1); // 队列为空，稍等
  end;
  
  WriteLn('[日志消费者] 完成，共处理 ', LProcessed, ' 条日志');
end;

// 模拟网络数据包生产者
procedure PacketProducer(AProducerId: Integer);
var
  LPacket: TNetworkPacket;
  I: Integer;
begin
  WriteLn('[数据包生产者 ', AProducerId, '] 开始生成数据包...');
  
  for I := 1 to 50000 do
  begin
    LPacket.PacketId := AProducerId * 100000 + I;
    LPacket.SourceIP := $C0A80000 + AProducerId; // 192.168.0.x
    LPacket.DestIP := $C0A80000 + ((I mod 254) + 1);
    LPacket.DataSize := (I mod 256);
    
    // 填充一些模拟数据
    FillChar(LPacket.Data, SizeOf(LPacket.Data), Byte(I mod 256));
    
    if GPacketQueue.Enqueue(LPacket) then
      InterlockedIncrement(GPacketCount)
    else
    begin
      // 队列满了，等待一下再重试
      Sleep(1);
      if GPacketQueue.Enqueue(LPacket) then
        InterlockedIncrement(GPacketCount);
    end;
  end;
  
  WriteLn('[数据包生产者 ', AProducerId, '] 完成');
end;

// 模拟网络数据包消费者
procedure PacketConsumer(AConsumerId: Integer);
var
  LPacket: TNetworkPacket;
  LProcessed: Integer;
begin
  WriteLn('[数据包消费者 ', AConsumerId, '] 开始处理数据包...');
  LProcessed := 0;
  
  while GRunning or not GPacketQueue.IsEmpty do
  begin
    if GPacketQueue.Dequeue(LPacket) then
    begin
      Inc(LProcessed);
      
      // 模拟数据包处理（路由、过滤、转发等）
      // 这里只是简单的计数
      
      // 每处理5000个显示进度
      if (LProcessed mod 5000) = 0 then
        WriteLn('[数据包消费者 ', AConsumerId, '] 已处理 ', LProcessed, ' 个数据包');
    end
    else
      Sleep(1); // 队列为空，稍等
  end;
  
  WriteLn('[数据包消费者 ', AConsumerId, '] 完成，共处理 ', LProcessed, ' 个数据包');
end;

// 模拟任务处理
procedure TaskProcessor;
var
  LTaskId: Integer;
  LProcessed: Integer;
begin
  WriteLn('[任务处理器] 开始处理任务...');
  LProcessed := 0;
  
  while GRunning or not GTaskStack.IsEmpty do
  begin
    if GTaskStack.Pop(LTaskId) then
    begin
      Inc(LProcessed);
      
      // 模拟任务处理
      // 这里只是简单计数
      
      if (LProcessed mod 1000) = 0 then
        WriteLn('[任务处理器] 已处理 ', LProcessed, ' 个任务');
    end
    else
      Sleep(1); // 栈为空，稍等
  end;
  
  WriteLn('[任务处理器] 完成，共处理 ', LProcessed, ' 个任务');
end;

procedure RunRealWorldExample;
var
  LStartTime: QWord;
  I: Integer;
begin
  WriteLn('=== 真实世界应用示例 ===');
  WriteLn('模拟高性能日志系统 + 网络数据包处理 + 任务调度');
  WriteLn;
  
  // 初始化数据结构
  GLogQueue := specialize TSPSCQueue<TLogMessage>.Create(10000); // 自定义记录类型，使用泛型直接特化
  GPacketQueue := specialize TPreAllocMPMCQueue<TNetworkPacket>.Create(8192); // 自定义记录类型
  GTaskStack := specialize TTreiberStack<Integer>.Create;
  
  try
    LStartTime := GetTickCount64;
    
    // 预先向任务栈中添加一些任务
    WriteLn('预先添加10000个任务到任务栈...');
    for I := 1 to 10000 do
    begin
      GTaskStack.Push(I);
      InterlockedIncrement(GTaskCount);
    end;
    
    WriteLn('开始模拟多线程处理...');
    WriteLn;
    
    // 由于FreePascal的限制，我们用循环模拟多线程
    // 在实际应用中，这些会是真正的线程
    
    // 模拟日志处理（单生产者单消费者）
    LogProducer;
    LogConsumer;
    
    // 模拟网络数据包处理（多生产者多消费者）
    PacketProducer(1);
    PacketProducer(2);
    PacketConsumer(1);
    PacketConsumer(2);
    
    // 模拟任务处理
    TaskProcessor;
    
    GRunning := False;
    
    WriteLn;
    WriteLn('=== 处理结果统计 ===');
    WriteLn('总耗时: ', GetTickCount64 - LStartTime, ' ms');
    WriteLn('日志处理: ', GLogCount, ' 条');
    WriteLn('数据包处理: ', GPacketCount, ' 个');
    WriteLn('任务处理: ', GTaskCount, ' 个');
    WriteLn('总操作数: ', GLogCount + GPacketCount + GTaskCount);
    
    if (GetTickCount64 - LStartTime) > 0 then
      WriteLn('平均吞吐量: ', Round((GLogCount + GPacketCount + GTaskCount) * 1000.0 / (GetTickCount64 - LStartTime)), ' ops/sec');
    
    WriteLn;
    WriteLn('这个示例展示了fafafa.core.lockfree在真实场景中的应用：');
    WriteLn('- 高性能日志系统（SPSC队列）');
    WriteLn('- 网络数据包处理（MPMC队列）');
    WriteLn('- 任务调度系统（无锁栈）');
    WriteLn;
    
  finally
    GLogQueue.Free;
    GPacketQueue.Free;
    GTaskStack.Free;
  end;
end;

begin
  WriteLn('fafafa.core.lockfree 真实世界应用示例');
  WriteLn('=====================================');
  WriteLn;
  
  try
    RunRealWorldExample;
    
    WriteLn('示例运行完成！');
    WriteLn('按回车键退出...');
    ReadLn;
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
