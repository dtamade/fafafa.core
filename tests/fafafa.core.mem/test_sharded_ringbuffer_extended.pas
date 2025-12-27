{
  Extended test suite for fafafa.core.mem.mappedRingBuffer.sharded

  Tests:
  - Boundary conditions (zero shards, single shard, capacity limits)
  - Concurrent multi-threaded push/pop
  - Producer-consumer patterns
  - Memory safety (close/reopen)
}
unit test_sharded_ringbuffer_extended;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.mem.mappedRingBuffer.sharded;

procedure RunAllExtendedTests;

implementation

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;

procedure Check(Condition: Boolean; const TestName: string);
begin
  Inc(TestCount);
  if Condition then
  begin
    Inc(PassCount);
    WriteLn('  [PASS] ', TestName);
  end
  else
    WriteLn('  [FAIL] ', TestName);
end;

// ============================================================
// Boundary Condition Tests
// ============================================================

procedure Test_ZeroShardCount;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Ok: Boolean;
begin
  WriteLn('=== Test_ZeroShardCount ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_zero_' + IntToStr(GetTickCount64);

    // ShardCount = 0 should fail
    Ok := Ring.CreateShared(BaseName, 0, 1024, 64);
    Check(not Ok, 'CreateShared with ShardCount=0 fails');
    Check(Ring.ShardCount = 0, 'ShardCount remains 0');

    // OpenShared with 0 should also fail
    Ok := Ring.OpenShared(BaseName, 0);
    Check(not Ok, 'OpenShared with ShardCount=0 fails');
  finally
    Ring.Free;
  end;
end;

procedure Test_NegativeShardCount;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Ok: Boolean;
begin
  WriteLn('=== Test_NegativeShardCount ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_neg_' + IntToStr(GetTickCount64);

    // ShardCount = -1 should fail
    Ok := Ring.CreateShared(BaseName, -1, 1024, 64);
    Check(not Ok, 'CreateShared with ShardCount=-1 fails');
    Check(Ring.ShardCount = 0, 'ShardCount remains 0');
  finally
    Ring.Free;
  end;
end;

procedure Test_SingleShard;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  RecvData: array[0..63] of Byte;
  I: Integer;
  Ok: Boolean;
  PushCount, PopCount: Integer;
begin
  WriteLn('=== Test_SingleShard ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_single_' + IntToStr(GetTickCount64);

    // Single shard should work (degenerates to single buffer)
    Ok := Ring.CreateShared(BaseName, 1, 32, 64);
    Check(Ok, 'CreateShared with ShardCount=1 succeeds');
    Check(Ring.ShardCount = 1, 'ShardCount = 1');

    // Push/Pop should work normally
    for I := 0 to 63 do
      Data[I] := I;

    PushCount := 0;
    while Ring.Push(@Data[0]) do
      Inc(PushCount);

    Check(PushCount >= 16, Format('Pushed %d items to single shard', [PushCount]));

    PopCount := 0;
    while Ring.Pop(@RecvData[0]) do
      Inc(PopCount);

    Check(PopCount = PushCount, Format('Popped all %d items', [PopCount]));

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_AllShardsFull;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  I: Integer;
  Ok: Boolean;
  PushCount: Integer;
begin
  WriteLn('=== Test_AllShardsFull ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_full_' + IntToStr(GetTickCount64);

    // Small capacity to quickly fill
    Ok := Ring.CreateShared(BaseName, 2, 4, 64);
    Check(Ok, 'CreateShared with 2 shards, 4 capacity each');

    FillChar(Data, SizeOf(Data), $BB);

    // Fill completely (2 shards * 4 = ~8 items)
    PushCount := 0;
    for I := 0 to 99 do
    begin
      if Ring.Push(@Data[0]) then
        Inc(PushCount)
      else
        Break;
    end;

    Check(PushCount >= 4, Format('Filled with %d items', [PushCount]));

    // Next push should fail
    Ok := Ring.Push(@Data[0]);
    Check(not Ok, 'Push on full buffer fails');

    // TryPush should also fail
    Ok := Ring.TryPush(@Data[0], 10);
    Check(not Ok, 'TryPush on full buffer fails');

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_AllShardsEmpty;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  Ok: Boolean;
begin
  WriteLn('=== Test_AllShardsEmpty ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_empty_' + IntToStr(GetTickCount64);

    Ok := Ring.CreateShared(BaseName, 3, 8, 64);
    Check(Ok, 'CreateShared succeeds');

    // Pop on empty should fail
    Ok := Ring.Pop(@Data[0]);
    Check(not Ok, 'Pop on empty buffer fails');

    // TryPop should also fail
    Ok := Ring.TryPop(@Data[0], 10);
    Check(not Ok, 'TryPop on empty buffer fails');

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_CapacityBoundary;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  RecvData: array[0..63] of Byte;
  I: Integer;
  Ok: Boolean;
  ExactCapacity: Integer;
begin
  WriteLn('=== Test_CapacityBoundary ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_boundary_' + IntToStr(GetTickCount64);

    // 2 shards * 8 capacity = 16 total (power of 2 may be different internally)
    Ok := Ring.CreateShared(BaseName, 2, 8, 64);
    Check(Ok, 'CreateShared succeeds');

    FillChar(Data, SizeOf(Data), $CC);

    // Fill to exact capacity
    ExactCapacity := 0;
    for I := 1 to 100 do
    begin
      if Ring.Push(@Data[0]) then
        Inc(ExactCapacity)
      else
        Break;
    end;

    Check(ExactCapacity >= 8, Format('Exact capacity = %d', [ExactCapacity]));

    // Pop all and verify count
    I := 0;
    while Ring.Pop(@RecvData[0]) do
      Inc(I);

    Check(I = ExactCapacity, Format('Pop count = push count (%d)', [I]));

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_UninitializedOperations;
var
  Ring: TMappedRingBufferSharded;
  Data: array[0..63] of Byte;
  Ok: Boolean;
begin
  WriteLn('=== Test_UninitializedOperations ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    // Operations on uninitialized ring should fail gracefully
    Ok := Ring.Push(@Data[0]);
    Check(not Ok, 'Push on uninitialized fails');

    Ok := Ring.Pop(@Data[0]);
    Check(not Ok, 'Pop on uninitialized fails');

    Ok := Ring.TryPush(@Data[0], 5);
    Check(not Ok, 'TryPush on uninitialized fails');

    Ok := Ring.TryPop(@Data[0], 5);
    Check(not Ok, 'TryPop on uninitialized fails');
  finally
    Ring.Free;
  end;
end;

// ============================================================
// Concurrent Tests
// ============================================================

type
  TProducerThread = class(TThread)
  private
    FRing: TMappedRingBufferSharded;
    FItemCount: Integer;
    FSuccessCount: Integer;
    FElemSize: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ARing: TMappedRingBufferSharded; AItemCount, AElemSize: Integer);
    property SuccessCount: Integer read FSuccessCount;
  end;

  TConsumerThread = class(TThread)
  private
    FRing: TMappedRingBufferSharded;
    FMaxItems: Integer;
    FConsumedCount: Integer;
    FElemSize: Integer;
    FStopFlag: PBoolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ARing: TMappedRingBufferSharded; AMaxItems, AElemSize: Integer; AStopFlag: PBoolean);
    property ConsumedCount: Integer read FConsumedCount;
  end;

constructor TProducerThread.Create(ARing: TMappedRingBufferSharded; AItemCount, AElemSize: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FRing := ARing;
  FItemCount := AItemCount;
  FSuccessCount := 0;
  FElemSize := AElemSize;
end;

procedure TProducerThread.Execute;
var
  I, J: Integer;
  Data: array of Byte;
  Retries: Integer;
begin
  SetLength(Data, FElemSize);
  for I := 0 to FItemCount - 1 do
  begin
    // Fill with pattern
    for J := 0 to FElemSize - 1 do
      Data[J] := (I + J) and $FF;

    // Try with retries to handle contention
    Retries := 0;
    while not FRing.TryPush(@Data[0], 4) do
    begin
      Inc(Retries);
      if Retries > 100 then Break;
      Sleep(1);
    end;

    if Retries <= 100 then
      Inc(FSuccessCount);

    if Terminated then Break;
  end;
end;

constructor TConsumerThread.Create(ARing: TMappedRingBufferSharded; AMaxItems, AElemSize: Integer; AStopFlag: PBoolean);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FRing := ARing;
  FMaxItems := AMaxItems;
  FConsumedCount := 0;
  FElemSize := AElemSize;
  FStopFlag := AStopFlag;
end;

procedure TConsumerThread.Execute;
var
  Data: array of Byte;
  EmptyCount: Integer;
begin
  SetLength(Data, FElemSize);
  EmptyCount := 0;

  while (FConsumedCount < FMaxItems) and not Terminated do
  begin
    if FRing.Pop(@Data[0]) then
    begin
      Inc(FConsumedCount);
      EmptyCount := 0;
    end
    else
    begin
      Inc(EmptyCount);
      if (FStopFlag <> nil) and FStopFlag^ and (EmptyCount > 50) then
        Break;
      Sleep(1);
    end;
  end;
end;

procedure Test_ConcurrentPushPop;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Producers: array[0..3] of TProducerThread;
  Consumers: array[0..3] of TConsumerThread;
  I: Integer;
  TotalProduced, TotalConsumed: Integer;
  StopFlag: Boolean;
  Ok: Boolean;
const
  ItemsPerThread = 100;
  ElemSize = 64;
begin
  WriteLn('=== Test_ConcurrentPushPop ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_concurrent_' + IntToStr(GetTickCount64);

    // 4 shards with larger capacity for concurrent access
    Ok := Ring.CreateShared(BaseName, 4, 256, ElemSize);
    Check(Ok, 'CreateShared succeeds');

    StopFlag := False;

    // Create producer and consumer threads
    for I := 0 to 3 do
    begin
      Producers[I] := TProducerThread.Create(Ring, ItemsPerThread, ElemSize);
      Consumers[I] := TConsumerThread.Create(Ring, ItemsPerThread * 2, ElemSize, @StopFlag);
    end;

    // Start all threads
    for I := 0 to 3 do
    begin
      Producers[I].Start;
      Consumers[I].Start;
    end;

    // Wait for producers to finish
    for I := 0 to 3 do
      Producers[I].WaitFor;

    // Signal consumers to stop after draining
    StopFlag := True;

    // Wait for consumers
    for I := 0 to 3 do
      Consumers[I].WaitFor;

    // Calculate totals
    TotalProduced := 0;
    TotalConsumed := 0;
    for I := 0 to 3 do
    begin
      TotalProduced := TotalProduced + Producers[I].SuccessCount;
      TotalConsumed := TotalConsumed + Consumers[I].ConsumedCount;
    end;

    WriteLn(Format('    Produced: %d, Consumed: %d', [TotalProduced, TotalConsumed]));

    Check(TotalProduced > 0, Format('Produced %d items', [TotalProduced]));
    Check(TotalConsumed > 0, Format('Consumed %d items', [TotalConsumed]));
    Check(TotalConsumed <= TotalProduced, 'Consumed <= Produced');

    // Cleanup threads
    for I := 0 to 3 do
    begin
      Producers[I].Free;
      Consumers[I].Free;
    end;

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_ProducerConsumer;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Producer: TProducerThread;
  Consumer: TConsumerThread;
  StopFlag: Boolean;
  Ok: Boolean;
const
  ItemCount = 500;
  ElemSize = 32;
begin
  WriteLn('=== Test_ProducerConsumer ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_prodcons_' + IntToStr(GetTickCount64);

    Ok := Ring.CreateShared(BaseName, 2, 128, ElemSize);
    Check(Ok, 'CreateShared succeeds');

    StopFlag := False;

    Producer := TProducerThread.Create(Ring, ItemCount, ElemSize);
    Consumer := TConsumerThread.Create(Ring, ItemCount, ElemSize, @StopFlag);

    // Start both
    Producer.Start;
    Consumer.Start;

    // Wait for producer
    Producer.WaitFor;
    StopFlag := True;

    // Wait for consumer
    Consumer.WaitFor;

    WriteLn(Format('    Producer sent: %d, Consumer received: %d',
      [Producer.SuccessCount, Consumer.ConsumedCount]));

    Check(Producer.SuccessCount > ItemCount div 2,
      Format('Producer sent %d items (> %d)', [Producer.SuccessCount, ItemCount div 2]));
    Check(Consumer.ConsumedCount > 0, Format('Consumer received %d items', [Consumer.ConsumedCount]));

    Producer.Free;
    Consumer.Free;

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_HighContention;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Threads: array[0..7] of TProducerThread;
  I: Integer;
  TotalSuccess: Integer;
  Ok: Boolean;
const
  ItemsPerThread = 50;
  ElemSize = 64;
begin
  WriteLn('=== Test_HighContention ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_contention_' + IntToStr(GetTickCount64);

    // Small capacity to force contention
    Ok := Ring.CreateShared(BaseName, 2, 32, ElemSize);
    Check(Ok, 'CreateShared succeeds');

    // Create 8 producer threads competing for 2 shards
    for I := 0 to 7 do
      Threads[I] := TProducerThread.Create(Ring, ItemsPerThread, ElemSize);

    // Start all
    for I := 0 to 7 do
      Threads[I].Start;

    // Wait all
    for I := 0 to 7 do
      Threads[I].WaitFor;

    TotalSuccess := 0;
    for I := 0 to 7 do
      TotalSuccess := TotalSuccess + Threads[I].SuccessCount;

    WriteLn(Format('    Total successful pushes: %d/%d', [TotalSuccess, 8 * ItemsPerThread]));

    // Under high contention, not all pushes succeed
    Check(TotalSuccess > 0, Format('Some items pushed under contention (%d)', [TotalSuccess]));

    for I := 0 to 7 do
      Threads[I].Free;

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

// ============================================================
// Memory Safety Tests
// ============================================================

procedure Test_CloseReopen;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  RecvData: array[0..63] of Byte;
  I: Integer;
  Ok: Boolean;
begin
  WriteLn('=== Test_CloseReopen ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_reopen_' + IntToStr(GetTickCount64);

    // First session
    Ok := Ring.CreateShared(BaseName, 2, 16, 64);
    Check(Ok, 'First CreateShared succeeds');

    for I := 0 to 63 do
      Data[I] := I;

    Ok := Ring.Push(@Data[0]);
    Check(Ok, 'First Push succeeds');

    Ring.Close;
    Check(Ring.ShardCount = 0, 'After Close, ShardCount = 0');

    // Second session with different config
    BaseName := 'test_reopen2_' + IntToStr(GetTickCount64);
    Ok := Ring.CreateShared(BaseName, 4, 32, 64);
    Check(Ok, 'Second CreateShared succeeds');
    Check(Ring.ShardCount = 4, 'New ShardCount = 4');

    // Should work normally
    Ok := Ring.Push(@Data[0]);
    Check(Ok, 'Second Push succeeds');

    Ok := Ring.Pop(@RecvData[0]);
    Check(Ok, 'Second Pop succeeds');

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_MultipleCloses;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Ok: Boolean;
begin
  WriteLn('=== Test_MultipleCloses ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_multiclose_' + IntToStr(GetTickCount64);

    Ok := Ring.CreateShared(BaseName, 2, 8, 64);
    Check(Ok, 'CreateShared succeeds');

    // Multiple closes should be safe
    Ring.Close;
    Check(Ring.ShardCount = 0, 'First Close');

    Ring.Close;
    Check(Ring.ShardCount = 0, 'Second Close (no crash)');

    Ring.Close;
    Check(Ring.ShardCount = 0, 'Third Close (no crash)');
  finally
    Ring.Free;
  end;
end;

// ============================================================
// Main Test Runner
// ============================================================

procedure RunAllExtendedTests;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TMappedRingBufferSharded Extended Tests');
  WriteLn('========================================');
  WriteLn('');

  // Boundary tests
  Test_ZeroShardCount;
  Test_NegativeShardCount;
  Test_SingleShard;
  Test_AllShardsFull;
  Test_AllShardsEmpty;
  Test_CapacityBoundary;
  Test_UninitializedOperations;

  // Concurrent tests
  Test_ConcurrentPushPop;
  Test_ProducerConsumer;
  Test_HighContention;

  // Memory safety tests
  Test_CloseReopen;
  Test_MultipleCloses;

  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Results: %d/%d passed', [PassCount, TestCount]));
  WriteLn('========================================');

  if PassCount < TestCount then
    Halt(1);
end;

end.
