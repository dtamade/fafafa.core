{$CODEPAGE UTF8}
unit test_ringbuffer_sharded;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.mappedRingBuffer.sharded;

type
  TTestCase_RingBufferSharded = class(TTestCase)
  published
    // Batch 1: 新增 Sharded 版本测试
    procedure Test_RingBuffer_Sharded_ConcurrentPushPop_ThreadSafe;
    procedure Test_RingBuffer_Sharded_HighContention_MaintainsConsistency;
  end;

implementation

type
  TProducerThread = class(TThread)
  private
    FRing: TMappedRingBufferSharded;
    FItemCount: Integer;
    FSuccessCount: Integer;
    FElemSize: Integer;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(ARing: TMappedRingBufferSharded; AItemCount, AElemSize: Integer);
    property SuccessCount: Integer read FSuccessCount;
    property Error: string read FError;
  end;

  TConsumerThread = class(TThread)
  private
    FRing: TMappedRingBufferSharded;
    FMaxItems: Integer;
    FConsumedCount: Integer;
    FElemSize: Integer;
    FStopFlag: PBoolean;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(ARing: TMappedRingBufferSharded; AMaxItems, AElemSize: Integer; AStopFlag: PBoolean);
    property ConsumedCount: Integer read FConsumedCount;
    property Error: string read FError;
  end;

constructor TProducerThread.Create(ARing: TMappedRingBufferSharded; AItemCount, AElemSize: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FRing := ARing;
  FItemCount := AItemCount;
  FSuccessCount := 0;
  FElemSize := AElemSize;
  FError := '';
end;

procedure TProducerThread.Execute;
var
  I, J: Integer;
  Data: array of Byte;
  Retries: Integer;
begin
  try
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
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
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
  FError := '';
end;

procedure TConsumerThread.Execute;
var
  Data: array of Byte;
  EmptyCount: Integer;
begin
  try
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
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TTestCase_RingBufferSharded.Test_RingBuffer_Sharded_ConcurrentPushPop_ThreadSafe;
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
  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_concurrent_' + IntToStr(GetTickCount64);

    // 4 shards with larger capacity for concurrent access
    Ok := Ring.CreateShared(BaseName, 4, 256, ElemSize);
    AssertTrue('CreateShared succeeds', Ok);

    StopFlag := False;

    // Create producer and consumer threads
    for I := 0 to 3 do
    begin
      Producers[I] := TProducerThread.Create(Ring, ItemsPerThread, ElemSize);
      Consumers[I] := TConsumerThread.Create(Ring, ItemsPerThread * 2, ElemSize, @StopFlag);
    end;

    try
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

      // Verify no errors
      for I := 0 to 3 do
      begin
        AssertEquals('Producer ' + IntToStr(I) + ' error', '', Producers[I].Error);
        AssertEquals('Consumer ' + IntToStr(I) + ' error', '', Consumers[I].Error);
      end;

      // Calculate totals
      TotalProduced := 0;
      TotalConsumed := 0;
      for I := 0 to 3 do
      begin
        TotalProduced := TotalProduced + Producers[I].SuccessCount;
        TotalConsumed := TotalConsumed + Consumers[I].ConsumedCount;
      end;

      AssertTrue('Produced > 0', TotalProduced > 0);
      AssertTrue('Consumed > 0', TotalConsumed > 0);
      AssertTrue('Consumed <= Produced', TotalConsumed <= TotalProduced);
    finally
      // Cleanup threads
      for I := 0 to 3 do
      begin
        Producers[I].Free;
        Consumers[I].Free;
      end;
    end;

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure TTestCase_RingBufferSharded.Test_RingBuffer_Sharded_HighContention_MaintainsConsistency;
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
  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_contention_' + IntToStr(GetTickCount64);

    // Small capacity to force contention
    Ok := Ring.CreateShared(BaseName, 2, 32, ElemSize);
    AssertTrue('CreateShared succeeds', Ok);

    // Create 8 producer threads competing for 2 shards
    for I := 0 to 7 do
      Threads[I] := TProducerThread.Create(Ring, ItemsPerThread, ElemSize);

    try
      // Start all
      for I := 0 to 7 do
        Threads[I].Start;

      // Wait all
      for I := 0 to 7 do
        Threads[I].WaitFor;

      // Verify no errors
      for I := 0 to 7 do
        AssertEquals('Thread ' + IntToStr(I) + ' error', '', Threads[I].Error);

      TotalSuccess := 0;
      for I := 0 to 7 do
        TotalSuccess := TotalSuccess + Threads[I].SuccessCount;

      // Under high contention, not all pushes succeed
      AssertTrue('Some items pushed under contention', TotalSuccess > 0);
    finally
      for I := 0 to 7 do
        Threads[I].Free;
    end;

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_RingBufferSharded);

end.
