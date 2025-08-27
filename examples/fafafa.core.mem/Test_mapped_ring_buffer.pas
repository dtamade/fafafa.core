{$CODEPAGE UTF8}
unit Test_mapped_ring_buffer;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry, fafafa.core.mem.mappedRingBuffer;

type
  TTestCase_MappedRingBuffer = class(TTestCase)
  private
    function MakeTempFile(const prefix, suffix: string): string;
    function MakeSharedName(const prefix: string): string;
  published
    procedure Test_CreateFile_Basic;
    procedure Test_CreateShared_Basic;
    procedure Test_Push_Pop_Single;
    procedure Test_Push_Pop_Batch;
    procedure Test_Producer_Consumer_Mode;
    procedure Test_Buffer_Full_Empty;
    procedure Test_Peek_Operation;
    procedure Test_Clear_Operation;
    procedure Test_CrossProcess_Communication;
  end;

implementation

uses
  Process;

function TTestCase_MappedRingBuffer.MakeTempFile(const prefix, suffix: string): string;
begin
  Result := GetTempDir + prefix + IntToHex(Random(MaxInt), 8) + suffix;
end;

function TTestCase_MappedRingBuffer.MakeSharedName(const prefix: string): string;
begin
  Result := prefix + IntToHex(Random(MaxInt), 8);
end;

procedure TTestCase_MappedRingBuffer.Test_CreateFile_Basic;
var
  filePath: string;
  rb: TMappedRingBuffer;
const
  CAPACITY = 100;
  ELEMENT_SIZE = 4;
begin
  filePath := MakeTempFile('mrb_basic_', '.dat');
  try
    rb := TMappedRingBuffer.Create;
    try
      AssertTrue('CreateFile should succeed',
        rb.CreateFile(filePath, CAPACITY, ELEMENT_SIZE));

      AssertEquals('Capacity should match', CAPACITY, rb.Capacity);
      AssertEquals('ElementSize should match', ELEMENT_SIZE, rb.ElementSize);
      AssertTrue('Should be creator', rb.IsCreator);
      AssertTrue('Should be valid', rb.IsValid);
      AssertTrue('Should be empty initially', rb.IsEmpty);
      AssertFalse('Should not be full initially', rb.IsFull);
      AssertEquals('AvailableSpace should be capacity-1', CAPACITY-1, rb.AvailableSpace);
      AssertEquals('UsedSpace should be 0', 0, rb.UsedSpace);
    finally
      rb.Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

procedure TTestCase_MappedRingBuffer.Test_CreateShared_Basic;
var
  name: string;
  rb: TMappedRingBuffer;
const
  CAPACITY = 50;
  ELEMENT_SIZE = 8;
begin
  name := MakeSharedName('MRB_Basic_');

  rb := TMappedRingBuffer.Create;
  try
    AssertTrue('CreateShared should succeed',
      rb.CreateShared(name, CAPACITY, ELEMENT_SIZE));

    AssertEquals('Capacity should match', CAPACITY, rb.Capacity);
    AssertEquals('ElementSize should match', ELEMENT_SIZE, rb.ElementSize);
    AssertTrue('Should be valid', rb.IsValid);
    AssertTrue('Should be empty initially', rb.IsEmpty);
    AssertFalse('Should not be full initially', rb.IsFull);
  finally
    rb.Free;
  end;
end;

procedure TTestCase_MappedRingBuffer.Test_Push_Pop_Single;
var
  rb: TMappedRingBuffer;
  name: string;
  writeData, readData: Integer;
  i: Integer;
const
  CAPACITY = 10;
  ELEMENT_SIZE = SizeOf(Integer);
begin
  name := MakeSharedName('MRB_PushPop_');

  rb := TMappedRingBuffer.Create;
  try
    AssertTrue('CreateShared should succeed',
      rb.CreateShared(name, CAPACITY, ELEMENT_SIZE));

    // 测试单个元素推入/弹出
    writeData := 42;
    AssertTrue('Push should succeed', rb.Push(@writeData));
    AssertFalse('Should not be empty after push', rb.IsEmpty);
    AssertEquals('UsedSpace should be 1', 1, rb.UsedSpace);

    readData := 0;
    AssertTrue('Pop should succeed', rb.Pop(@readData));
    AssertEquals('Read data should match written data', writeData, readData);
    AssertTrue('Should be empty after pop', rb.IsEmpty);
    AssertEquals('UsedSpace should be 0', 0, rb.UsedSpace);

    // 测试多个元素
    for i := 1 to CAPACITY - 1 do
    begin
      writeData := i * 10;
      AssertTrue(Format('Push %d should succeed', [i]), rb.Push(@writeData));
    end;

    AssertTrue('Should be full', rb.IsFull);
    AssertEquals('UsedSpace should be capacity-1', CAPACITY-1, rb.UsedSpace);

    // 再推入一个应该失败（缓冲区满）
    writeData := 999;
    AssertFalse('Push to full buffer should fail', rb.Push(@writeData));

    // 弹出所有元素
    for i := 1 to CAPACITY - 1 do
    begin
      AssertTrue(Format('Pop %d should succeed', [i]), rb.Pop(@readData));
      AssertEquals(Format('Read data %d should match', [i]), i * 10, readData);
    end;

    AssertTrue('Should be empty after popping all', rb.IsEmpty);

    // 从空缓冲区弹出应该失败
    AssertFalse('Pop from empty buffer should fail', rb.Pop(@readData));

  finally
    rb.Free;
  end;
end;

procedure TTestCase_MappedRingBuffer.Test_Push_Pop_Batch;
var
  rb: TMappedRingBuffer;
  name: string;
  writeData, readData: array[0..9] of Integer;
  i, pushed, popped: Integer;
const
  CAPACITY = 20;
  ELEMENT_SIZE = SizeOf(Integer);
  BATCH_SIZE = 10;
begin
  name := MakeSharedName('MRB_Batch_');

  rb := TMappedRingBuffer.Create;
  try
    AssertTrue('CreateShared should succeed',
      rb.CreateShared(name, CAPACITY, ELEMENT_SIZE));

    // 准备测试数据
    for i := 0 to BATCH_SIZE - 1 do
      writeData[i] := (i + 1) * 100;

    // 批量推入
    pushed := rb.PushBatch(@writeData[0], BATCH_SIZE);
    AssertEquals('Should push all elements', BATCH_SIZE, pushed);
    AssertEquals('UsedSpace should match', BATCH_SIZE, rb.UsedSpace);

    // 批量弹出
    FillChar(readData, SizeOf(readData), 0);
    popped := rb.PopBatch(@readData[0], BATCH_SIZE);
    AssertEquals('Should pop all elements', BATCH_SIZE, popped);

    // 验证数据
    for i := 0 to BATCH_SIZE - 1 do
      AssertEquals(Format('Batch data %d should match', [i]),
        writeData[i], readData[i]);

    AssertTrue('Should be empty after batch pop', rb.IsEmpty);

  finally
    rb.Free;
  end;
end;

procedure TTestCase_MappedRingBuffer.Test_Producer_Consumer_Mode;
var
  producer, consumer: TMappedRingBuffer;
  name: string;
  data: Integer;
const
  CAPACITY = 5;
  ELEMENT_SIZE = SizeOf(Integer);
begin
  name := MakeSharedName('MRB_ProdCons_');

  producer := TMappedRingBuffer.Create;
  consumer := TMappedRingBuffer.Create;
  try
    // 创建生产者
    AssertTrue('Producer CreateShared should succeed',
      producer.CreateShared(name, CAPACITY, ELEMENT_SIZE, mrbProducer));

    // 打开消费者
    AssertTrue('Consumer OpenShared should succeed',
      consumer.OpenShared(name, mrbConsumer));

    // 生产者写入
    data := 123;
    AssertTrue('Producer push should succeed', producer.Push(@data));

    // 消费者不能写入
    data := 456;
    AssertFalse('Consumer push should fail', consumer.Push(@data));

    // 消费者读取
    data := 0;
    AssertTrue('Consumer pop should succeed', consumer.Pop(@data));
    AssertEquals('Consumer should read correct data', 123, data);

    // 生产者不能读取
    AssertFalse('Producer pop should fail', producer.Pop(@data));

  finally
    consumer.Free;
    producer.Free;
  end;
end;

procedure TTestCase_MappedRingBuffer.Test_Buffer_Full_Empty;
var
  rb: TMappedRingBuffer;
  name: string;
  data: Integer;
  i: Integer;
const
  CAPACITY = 3; // 小容量便于测试
  ELEMENT_SIZE = SizeOf(Integer);
begin
  name := MakeSharedName('MRB_FullEmpty_');

  rb := TMappedRingBuffer.Create;
  try
    AssertTrue('CreateShared should succeed',
      rb.CreateShared(name, CAPACITY, ELEMENT_SIZE));

    // 初始状态
    AssertTrue('Should be empty initially', rb.IsEmpty);
    AssertFalse('Should not be full initially', rb.IsFull);

    // 填满缓冲区（容量-1）
    for i := 1 to CAPACITY - 1 do
    begin
      data := i;
      AssertTrue(Format('Push %d should succeed', [i]), rb.Push(@data));
    end;

    AssertFalse('Should not be empty when full', rb.IsEmpty);
    AssertTrue('Should be full', rb.IsFull);

    // 再推入应该失败
    data := 999;
    AssertFalse('Push to full buffer should fail', rb.Push(@data));

    // 弹出一个元素
    AssertTrue('Pop should succeed', rb.Pop(@data));
    AssertFalse('Should not be full after pop', rb.IsFull);
    AssertFalse('Should not be empty after single pop', rb.IsEmpty);

    // 弹出剩余元素
    for i := 2 to CAPACITY - 1 do
    begin
      AssertTrue(Format('Pop %d should succeed', [i]), rb.Pop(@data));
    end;

    AssertTrue('Should be empty after popping all', rb.IsEmpty);
    AssertFalse('Should not be full when empty', rb.IsFull);

    // 从空缓冲区弹出应该失败
    AssertFalse('Pop from empty should fail', rb.Pop(@data));

  finally
    rb.Free;
  end;
end;

procedure TTestCase_MappedRingBuffer.Test_Peek_Operation;
var
  rb: TMappedRingBuffer;
  name: string;
  writeData, peekData, popData: Integer;
const
  CAPACITY = 5;
  ELEMENT_SIZE = SizeOf(Integer);
begin
  name := MakeSharedName('MRB_Peek_');

  rb := TMappedRingBuffer.Create;
  try
    AssertTrue('CreateShared should succeed',
      rb.CreateShared(name, CAPACITY, ELEMENT_SIZE));

    // 空缓冲区 Peek 应该失败
    AssertFalse('Peek empty buffer should fail', rb.Peek(@peekData));

    // 推入数据
    writeData := 789;
    AssertTrue('Push should succeed', rb.Push(@writeData));

    // Peek 应该成功且不改变缓冲区状态
    peekData := 0;
    AssertTrue('Peek should succeed', rb.Peek(@peekData));
    AssertEquals('Peek data should match', writeData, peekData);
    AssertFalse('Buffer should not be empty after peek', rb.IsEmpty);
    AssertEquals('UsedSpace should remain 1 after peek', 1, rb.UsedSpace);

    // 再次 Peek 应该返回相同数据
    peekData := 0;
    AssertTrue('Second peek should succeed', rb.Peek(@peekData));
    AssertEquals('Second peek data should match', writeData, peekData);

    // Pop 应该返回相同数据
    popData := 0;
    AssertTrue('Pop should succeed', rb.Pop(@popData));
    AssertEquals('Pop data should match peek data', peekData, popData);
    AssertTrue('Buffer should be empty after pop', rb.IsEmpty);

  finally
    rb.Free;
  end;
end;

procedure TTestCase_MappedRingBuffer.Test_Clear_Operation;
var
  rb: TMappedRingBuffer;
  name: string;
  data: Integer;
  i: Integer;
const
  CAPACITY = 10;
  ELEMENT_SIZE = SizeOf(Integer);
begin
  name := MakeSharedName('MRB_Clear_');

  rb := TMappedRingBuffer.Create;
  try
    AssertTrue('CreateShared should succeed',
      rb.CreateShared(name, CAPACITY, ELEMENT_SIZE));

    // 推入一些数据
    for i := 1 to 5 do
    begin
      data := i * 10;
      AssertTrue(Format('Push %d should succeed', [i]), rb.Push(@data));
    end;

    AssertFalse('Should not be empty before clear', rb.IsEmpty);
    AssertEquals('UsedSpace should be 5', 5, rb.UsedSpace);

    // 清空缓冲区
    rb.Clear;

    AssertTrue('Should be empty after clear', rb.IsEmpty);
    AssertEquals('UsedSpace should be 0 after clear', 0, rb.UsedSpace);
    AssertEquals('AvailableSpace should be capacity-1 after clear',
      CAPACITY-1, rb.AvailableSpace);

    // 清空后应该可以正常推入
    data := 999;
    AssertTrue('Push after clear should succeed', rb.Push(@data));

  finally
    rb.Free;
  end;
end;

procedure TTestCase_MappedRingBuffer.Test_CrossProcess_Communication;
var
  name: string;
  // 这个测试需要启动子进程，暂时简化为基本验证
  rb1, rb2: TMappedRingBuffer;
  data: Integer;
const
  CAPACITY = 10;
  ELEMENT_SIZE = SizeOf(Integer);
begin
  name := MakeSharedName('MRB_CrossProc_');

  rb1 := TMappedRingBuffer.Create;
  rb2 := TMappedRingBuffer.Create;
  try
    // 第一个进程创建
    AssertTrue('First process CreateShared should succeed',
      rb1.CreateShared(name, CAPACITY, ELEMENT_SIZE));

    // 第二个进程打开（模拟跨进程）
    AssertTrue('Second process OpenShared should succeed',
      rb2.OpenShared(name));

    // 第一个进程写入
    data := 12345;
    AssertTrue('First process push should succeed', rb1.Push(@data));

    // 第二个进程读取
    data := 0;
    AssertTrue('Second process pop should succeed', rb2.Pop(@data));
    AssertEquals('Cross-process data should match', 12345, data);


procedure TTestCase_MappedRingBuffer.Test_CrossProcess_Communication_Bidirectional;
var
  name: string;
  rbCreator, rbOpener: TMappedRingBuffer;
  sendV, recvV: Integer;
  i: Integer;
const
  CAPACITY = 64;
  ELEMENT_SIZE = SizeOf(Integer);
begin
  name := MakeSharedName('MRB_Bidir_');
  rbCreator := TMappedRingBuffer.Create;
  rbOpener := TMappedRingBuffer.Create;
  try
    AssertTrue('Creator CreateShared', rbCreator.CreateShared(name, CAPACITY, ELEMENT_SIZE));
    AssertTrue('Opener OpenShared', rbOpener.OpenShared(name));
    // A->B
    for i := 1 to 10 do
    begin
      sendV := i;
      AssertTrue('creator push', rbCreator.Push(@sendV));
      AssertTrue('opener pop', rbOpener.Pop(@recvV));
      AssertEquals('recv matches', sendV, recvV);
      // B->A (reply)
      Inc(recvV);
      AssertTrue('opener push', rbOpener.Push(@recvV));
      AssertTrue('creator pop', rbCreator.Pop(@recvV));
      AssertEquals('reply matches', sendV+1, recvV);
    end;
  finally
    rbOpener.Free;
    rbCreator.Free;
  end;
end;

  finally
    rb2.Free;
    rb1.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_MappedRingBuffer);

end.
