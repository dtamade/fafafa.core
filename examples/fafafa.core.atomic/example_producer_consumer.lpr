program example_producer_consumer;

{$APPTYPE CONSOLE}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.atomic;

const
  BUFFER_SIZE = 8;
  ITEM_COUNT = 20;

type
  TRingBuffer = record
    data: array[0..BUFFER_SIZE-1] of Int32;
    write_pos: LongInt;
    read_pos: LongInt;
    count: LongInt;
  end;

var
  buffer: TRingBuffer;
  producer_done: LongInt;
  items_produced: LongInt;
  items_consumed: LongInt;

function TryProduce(item: Int32): Boolean;
var
  current_count, write_idx: Int32;
begin
  // 检查是否有空间
  current_count := atomic_load(buffer.count, mo_acquire);
  if current_count >= BUFFER_SIZE then
  begin
    Result := False;
    Exit;
  end;

  // 获取写入位置
  write_idx := atomic_fetch_add(buffer.write_pos, 1) mod BUFFER_SIZE;

  // 写入数据
  buffer.data[write_idx] := item;

  // 增加计数（使用 release 确保数据写入对消费者可见）
  atomic_fetch_add(buffer.count, 1);
  
  Result := True;
end;

function TryConsume(out item: Int32): Boolean;
var
  current_count, read_idx: Int32;
begin
  // 检查是否有数据
  current_count := atomic_load(buffer.count, mo_acquire);
  if current_count <= 0 then
  begin
    Result := False;
    Exit;
  end;

  // 获取读取位置
  read_idx := atomic_fetch_add(buffer.read_pos, 1) mod BUFFER_SIZE;

  // 读取数据
  item := buffer.data[read_idx];

  // 减少计数
  atomic_fetch_sub(buffer.count, 1);
  
  Result := True;
end;

type
  TProducerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  TConsumerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TProducerThread.Execute;
var
  i: Integer;
  retry_count: Integer;
begin
  for i := 1 to ITEM_COUNT do
  begin
    retry_count := 0;
    while not TryProduce(i) do
    begin
      Inc(retry_count);
      if retry_count > 1000 then
      begin
        Sleep(1);  // 避免忙等
        retry_count := 0;
      end;
    end;
    
    atomic_fetch_add(items_produced, 1);
    Writeln('生产者：生产项目 ', i);
  end;
  
  // 标记生产完成
  atomic_store(producer_done, 1, mo_release);
  Writeln('生产者：完成生产');
end;

procedure TConsumerThread.Execute;
var
  item: Int32;
  retry_count: Integer;
begin
  while True do
  begin
    retry_count := 0;
    while not TryConsume(item) do
    begin
      // 检查生产者是否完成且缓冲区为空
      if (atomic_load(producer_done, mo_acquire) = 1) and 
         (atomic_load(buffer.count, mo_acquire) = 0) then
      begin
        Writeln('消费者：生产者完成且缓冲区为空，退出');
        Exit;
      end;
      
      Inc(retry_count);
      if retry_count > 1000 then
      begin
        Sleep(1);  // 避免忙等
        retry_count := 0;
      end;
    end;
    
    atomic_fetch_add(items_consumed, 1);
    Writeln('消费者：消费项目 ', item);
  end;
end;

var
  producer: TProducerThread;
  consumer: TConsumerThread;

begin
  Writeln('=== 生产者-消费者模式示例 ===');
  Writeln('缓冲区大小：', BUFFER_SIZE);
  Writeln('生产项目数：', ITEM_COUNT);
  Writeln;

  // 初始化
  FillChar(buffer, SizeOf(buffer), 0);
  producer_done := 0;
  items_produced := 0;
  items_consumed := 0;

  // 创建并启动线程
  producer := TProducerThread.Create(False);
  consumer := TConsumerThread.Create(False);

  try
    // 等待完成
    producer.WaitFor;
    consumer.WaitFor;
    
    Writeln;
    Writeln('=== 统计结果 ===');
    Writeln('生产项目数：', atomic_load(items_produced, mo_relaxed));
    Writeln('消费项目数：', atomic_load(items_consumed, mo_relaxed));
    Writeln('缓冲区剩余：', atomic_load(buffer.count, mo_relaxed));
    
    if atomic_load(items_produced, mo_relaxed) = atomic_load(items_consumed, mo_relaxed) then
      Writeln('✓ 生产消费平衡')
    else
      Writeln('✗ 生产消费不平衡');
      
  finally
    producer.Free;
    consumer.Free;
  end;

  Writeln;
  Writeln('=== 示例完成 ===');
end.
