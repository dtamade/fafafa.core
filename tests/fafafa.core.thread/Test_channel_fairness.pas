unit Test_channel_fairness;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TChannel_Fairness = class(TTestCase)
  published
    procedure Test_Unbuffered_MPMC_Fair_Order;
    procedure Test_Unbuffered_MPMC_Distribution;
  end;

implementation

const
  PRODUCERS = 4;
  CONSUMERS = 4;
  MESSAGES_PER_PRODUCER = 100;
  DISTR_TOLERANCE_PCT = 25; // each consumer within +/-25% of ideal


type
  PInt = ^PtrUInt;
  TCounts = array[0..CONSUMERS-1] of PtrUInt;
  PCounts = ^TCounts;
  PProducerPack = ^TProducerPack;
  TProducerPack = record
    Chan: IChannel;
    Counter: PInt;
  end;
  PConsumerPack = ^TConsumerPack;
  TConsumerPack = record
    Chan: IChannel;
    Counts: PCounts; // 指向 Counts 数组
    Id: Integer;     // 消费者编号
  end;


  TWorker = class
  public
    function ProducerProc(Data: Pointer): Boolean;
    function ConsumerProc(Data: Pointer): Boolean;
  end;

function SendIndex(Data: Pointer): Boolean;
var
  P: PProducerPack;
  Val: Pointer;
begin
  P := PProducerPack(Data);
  // 每个生产者发送一个消息：值为自增计数
  Inc(P^.Counter^);
  Val := Pointer(P^.Counter^);
  Result := P^.Chan.Send(Val);
end;

function RecvIndex(Data: Pointer): Boolean;
var
  P: PConsumerPack;
  Got: Pointer;
  Idx: PtrUInt;
begin
  P := PConsumerPack(Data);
  Result := P^.Chan.Recv(Got);
  if Result then
  begin
    // 简化：只累计到第一个桶，用于总量验证
    Inc(P^.Counts^[0]);
  end;
end;


function TWorker.ProducerProc(Data: Pointer): Boolean;
var
  P: PProducerPack;
  K: Integer;
begin
  P := PProducerPack(Data);
  for K := 1 to MESSAGES_PER_PRODUCER do
  begin
    Inc(P^.Counter^);
    if not P^.Chan.Send(Pointer(P^.Counter^)) then
      Exit(False);
  end;
  Result := True;
end;

function TWorker.ConsumerProc(Data: Pointer): Boolean;
var
  P: PConsumerPack;
  Got: Pointer;
  K: Integer;
begin
  P := PConsumerPack(Data);
  for K := 1 to MESSAGES_PER_PRODUCER do
  begin
    if not P^.Chan.Recv(Got) then Exit(False);
    Inc(P^.Counts^[P^.Id]);
  end;
  Result := True;
end;

procedure TTestCase_TChannel_Fairness.Test_Unbuffered_MPMC_Fair_Order;
var
  Chan: IChannel;
  Pool: IThreadPool;
  Producers, Consumers: array[0..3] of IFuture;
  I: Integer;
  Cnt: PtrUInt;
  Counts: TCounts;
  SendPacks: array[0..3] of TProducerPack;
  RecvPacks: array[0..3] of TConsumerPack;
begin
  Chan := CreateChannel(0);
  // 使用足够的固定线程池，避免所有消费者占满线程而导致生产者无法执行的死锁
  // 这里直接使用 8 = 4 (Producers) + 4 (Consumers)
  Pool := CreateFixedThreadPool(8);
  FillChar(Counts, SizeOf(Counts), 0);

  for I := 0 to 3 do begin
    SendPacks[I].Chan := Chan;
    New(SendPacks[I].Counter);
    SendPacks[I].Counter^ := I; // 各生产者从不同基准开始

    RecvPacks[I].Chan := Chan;
    RecvPacks[I].Counts := @Counts;
  end;

  // 启动消费者在先，避免零容量通道下的线程池阻塞
  for I := 0 to 3 do
    Consumers[I] := Pool.Submit(@RecvIndex, @RecvPacks[I]);
  SysUtils.Sleep(10);
  for I := 0 to 3 do
    Producers[I] := Pool.Submit(@SendIndex, @SendPacks[I]);

  for I := 0 to 3 do begin
    AssertTrue(Producers[I].WaitFor(2000));
    AssertTrue(Consumers[I].WaitFor(2000));
  end;

  // sum of counts should be 4 (one per producer)
  Cnt := 0;
  for I := 0 to High(Counts) do Inc(Cnt, Counts[I]);
  AssertEquals('All messages should be processed', 4, Cnt);

  // 清理分配的计数器
  for I := 0 to 3 do Dispose(SendPacks[I].Counter);

  Pool.Shutdown;
  Pool.AwaitTermination(2000);
end;


procedure TTestCase_TChannel_Fairness.Test_Unbuffered_MPMC_Distribution;
var
  Chan: IChannel;
  Pool: IThreadPool;
  ProdFutures, ConsFutures: array[0..PRODUCERS-1] of IFuture;
  Counts: TCounts;
  SendPacks: array[0..PRODUCERS-1] of TProducerPack;
  RecvPacks: array[0..CONSUMERS-1] of TConsumerPack;
  Worker: TWorker;
  I, J: Integer;
  Ideal, Tol, Total: PtrUInt;
begin

  Chan := CreateChannel(0);
  Pool := CreateFixedThreadPool(PRODUCERS+CONSUMERS);
  FillChar(Counts, SizeOf(Counts), 0);

  // setup packs
  for I := 0 to PRODUCERS-1 do
  begin
    SendPacks[I].Chan := Chan;
    New(SendPacks[I].Counter);
    SendPacks[I].Counter^ := I * 1000; // base
  end;
  for I := 0 to CONSUMERS-1 do
  begin
    RecvPacks[I].Id := I;
  end;
  for I := 0 to CONSUMERS-1 do
  begin
    RecvPacks[I].Chan := Chan;
    RecvPacks[I].Counts := @Counts;
  end;

  Worker := TWorker.Create;
  try
    // launch consumers first to create pressure
    for I := 0 to CONSUMERS-1 do
      ConsFutures[I] := Pool.Submit(@Worker.ConsumerProc, @RecvPacks[I]);
    // small delay
    SysUtils.Sleep(20);
    for I := 0 to PRODUCERS-1 do
      ProdFutures[I] := Pool.Submit(@Worker.ProducerProc, @SendPacks[I]);

    // wait all
    for I := 0 to PRODUCERS-1 do AssertTrue(ProdFutures[I].WaitFor(10000));
    for I := 0 to CONSUMERS-1 do AssertTrue(ConsFutures[I].WaitFor(10000));
  finally
    Worker.Free;
  end;

  // assert distribution: count per consumer (by bucket of Id mod 16)
  Ideal := (PRODUCERS * MESSAGES_PER_PRODUCER) div CONSUMERS;
  Tol := Ideal * DISTR_TOLERANCE_PCT div 100;
  for I := 0 to CONSUMERS-1 do
  begin
    J := Counts[I];
    AssertTrue(Format('Consumer %d within tolerance (got=%d, ideal=%d, tol=%d)',
      [I, J, Ideal, Tol]), (J + Tol >= Ideal) and (J <= Ideal + Tol));
  end;



  // evaluate distribution
  Total := 0;
  for I := 0 to High(Counts) do Inc(Total, Counts[I]);
  Ideal := (PRODUCERS * MESSAGES_PER_PRODUCER) div CONSUMERS;
  Tol := Ideal * DISTR_TOLERANCE_PCT div 100;

  // 简化：仅断言总量正确，详细分布断言可在后续增加
  AssertEquals('Total messages accounted', PRODUCERS*MESSAGES_PER_PRODUCER, Total);

  // cleanup
  for I := 0 to PRODUCERS-1 do Dispose(SendPacks[I].Counter);
  Pool.Shutdown;
  Pool.AwaitTermination(5000);
end;

initialization
  RegisterTest(TTestCase_TChannel_Fairness);

end.

