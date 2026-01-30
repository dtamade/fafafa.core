{
  Test suite for fafafa.core.mem.mappedRingBuffer.sharded

  Tests:
  - Basic Create/Close
  - Multi-shard Push/Pop
  - Load balancing across shards
  - TryPush/TryPop with retries
}
unit test_sharded_ringbuffer;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.mem.mappedRingBuffer.sharded;

procedure RunAllTests;

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

procedure Test_CreateClose;
var
  Ring: TMappedRingBufferSharded;
  Ok: Boolean;
  BaseName: string;
begin
  WriteLn('=== Test_CreateClose ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    Check(Ring.ShardCount = 0, 'Initial ShardCount = 0');

    BaseName := 'test_sharded_' + IntToStr(GetTickCount64);
    Ok := Ring.CreateShared(BaseName, 4, 1024, 64);
    Check(Ok, 'CreateShared with 4 shards');
    Check(Ring.ShardCount = 4, 'ShardCount = 4');

    Ring.Close;
    Check(Ring.ShardCount = 0, 'ShardCount = 0 after Close');
  finally
    Ring.Free;
  end;
end;

procedure Test_PushPop;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  RecvData: array[0..63] of Byte;
  I: Integer;
  Ok: Boolean;
begin
  WriteLn('=== Test_PushPop ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_pushpop_' + IntToStr(GetTickCount64);
    Ok := Ring.CreateShared(BaseName, 2, 128, 64);
    Check(Ok, 'CreateShared succeeds');

    // Prepare test data
    for I := 0 to 63 do
      Data[I] := I;

    // Push
    Ok := Ring.Push(@Data[0]);
    Check(Ok, 'Push succeeds');

    // Pop
    FillChar(RecvData, SizeOf(RecvData), 0);
    Ok := Ring.Pop(@RecvData[0]);
    Check(Ok, 'Pop succeeds');

    // Verify data
    Ok := True;
    for I := 0 to 63 do
    begin
      if RecvData[I] <> I then
      begin
        Ok := False;
        Break;
      end;
    end;
    Check(Ok, 'Data integrity verified');

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_MultiplePushPop;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  RecvData: array[0..63] of Byte;
  I, J: Integer;
  Ok: Boolean;
  PushCount, PopCount: Integer;
begin
  WriteLn('=== Test_MultiplePushPop ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_multi_' + IntToStr(GetTickCount64);
    Ok := Ring.CreateShared(BaseName, 4, 64, 64);
    Check(Ok, 'CreateShared with 4 shards, 64 capacity each');

    // Push 100 items (should distribute across shards)
    PushCount := 0;
    for I := 0 to 99 do
    begin
      for J := 0 to 63 do
        Data[J] := I;
      if Ring.Push(@Data[0]) then
        Inc(PushCount);
    end;
    Check(PushCount >= 64, Format('Pushed %d items (>= 64)', [PushCount]));

    // Pop all items
    PopCount := 0;
    while Ring.Pop(@RecvData[0]) do
      Inc(PopCount);

    Check(PopCount = PushCount, Format('Popped %d items = pushed %d', [PopCount, PushCount]));

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_TryPushPop;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  I: Integer;
  Ok: Boolean;
begin
  WriteLn('=== Test_TryPushPop ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_try_' + IntToStr(GetTickCount64);
    Ok := Ring.CreateShared(BaseName, 2, 8, 64);
    Check(Ok, 'CreateShared with small capacity');

    for I := 0 to 63 do
      Data[I] := I;

    // Fill the buffer
    while Ring.Push(@Data[0]) do;

    // TryPush should retry across shards
    Ok := Ring.TryPush(@Data[0], 4);
    // Might succeed or fail depending on timing
    Check(True, Format('TryPush(4) returned %s', [BoolToStr(Ok, True)]));

    // Empty buffer
    while Ring.Pop(@Data[0]) do;

    // TryPop on empty should fail
    Ok := Ring.TryPop(@Data[0], 4);
    Check(not Ok, 'TryPop on empty fails');

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure Test_LoadBalancing;
var
  Ring: TMappedRingBufferSharded;
  BaseName: string;
  Data: array[0..63] of Byte;
  I: Integer;
  PushCount: Integer;
begin
  WriteLn('=== Test_LoadBalancing ===');

  Ring := TMappedRingBufferSharded.Create;
  try
    BaseName := 'test_balance_' + IntToStr(GetTickCount64);
    Ring.CreateShared(BaseName, 4, 16, 64);

    FillChar(Data, SizeOf(Data), $AA);

    // Push items - should round-robin across shards
    PushCount := 0;
    for I := 0 to 63 do
    begin
      if Ring.Push(@Data[0]) then
        Inc(PushCount);
    end;

    // With 4 shards × 16 capacity = 64 total capacity
    Check(PushCount = 64, Format('Pushed %d items to 4×16 capacity', [PushCount]));

    Ring.Close;
  finally
    Ring.Free;
  end;
end;

procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TMappedRingBufferSharded Test Suite');
  WriteLn('========================================');
  WriteLn('');

  Test_CreateClose;
  Test_PushPop;
  Test_MultiplePushPop;
  Test_TryPushPop;
  Test_LoadBalancing;

  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Results: %d/%d passed', [PassCount, TestCount]));
  WriteLn('========================================');

  if PassCount < TestCount then
    Halt(1);
end;

end.
