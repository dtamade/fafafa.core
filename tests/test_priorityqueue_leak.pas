{$mode objfpc}{$H+}
program test_priorityqueue_leak;

uses
  SysUtils,
  fafafa.core.collections.priorityqueue;

type
  TIntPriorityQueue = specialize TPriorityQueue<Integer>;

var
  PQ: TIntPriorityQueue;

function CompareIntegers(const A, B: Integer): Integer;
begin
  if A < B then
    Result := -1
  else if A > B then
    Result := 1
  else
    Result := 0;
end;

procedure Test1_BasicOps;
var
  Item: Integer;
begin
  WriteLn('[Test 1] Basic operations');
  PQ.Initialize(@CompareIntegers);
  try
    PQ.Enqueue(5);
    PQ.Enqueue(2);
    PQ.Enqueue(8);
    Item := PQ.Dequeue;
    WriteLn('  Pass: Dequeued = ', Item, ', Count = ', PQ.Count);
  finally
    PQ.Clear;
  end;
end;

procedure Test2_Peek;
var
  Item: Integer;
  Success: Boolean;
begin
  WriteLn('[Test 2] Peek operations');
  PQ.Initialize(@CompareIntegers, 10);
  try
    PQ.Enqueue(10);
    PQ.Enqueue(1);
    PQ.Enqueue(5);

    Success := PQ.TryPeek(Item);
    WriteLn('  Pass: Peek succeeded = ', Success, ', Item = ', Item);
    WriteLn('  Pass: Count after peek = ', PQ.Count);
  finally
    PQ.Clear;
  end;
end;

procedure Test3_Contains;
begin
  WriteLn('[Test 3] Contains operation');
  PQ.Initialize(@CompareIntegers);
  try
    PQ.Enqueue(1);
    PQ.Enqueue(2);
    PQ.Enqueue(3);

    WriteLn('  Pass: Contains 2 = ', PQ.Contains(2));
    WriteLn('  Pass: Contains 5 = ', PQ.Contains(5));
    WriteLn('  Pass: Count = ', PQ.Count);
  finally
    PQ.Clear;
  end;
end;

procedure Test4_Remove;
begin
  WriteLn('[Test 4] Remove operation');
  PQ.Initialize(@CompareIntegers);
  try
    PQ.Enqueue(1);
    PQ.Enqueue(2);
    PQ.Enqueue(3);

    PQ.Remove(2);
    WriteLn('  Pass: After removing 2, Count = ', PQ.Count);
    WriteLn('  Pass: Contains 2 = ', PQ.Contains(2));

    PQ.Remove(1);
    WriteLn('  Pass: After removing 1, Count = ', PQ.Count);
    WriteLn('  Contains 1 = ', PQ.Contains(1));
  finally
    PQ.Clear;
  end;
end;

procedure Test5_StressTest;
var
  i, Item: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  PQ.Initialize(@CompareIntegers, 100);
  try
    for i := 1000 downto 1 do
      PQ.Enqueue(i);

    WriteLn('  Pass: Inserted 1000, Count = ', PQ.Count);

    for i := 1 to 500 do
      Item := PQ.Dequeue;

    WriteLn('  Pass: Dequeued 500, Count = ', PQ.Count);

    PQ.Clear;
    WriteLn('  Pass: Cleared, Count = ', PQ.Count);
  finally
    // PQ is a record, no Free needed
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TPriorityQueue Memory Leak Detection Test');
  WriteLn('======================================');
  WriteLn;

  try
    Test1_BasicOps;
    WriteLn;
    Test2_Peek;
    WriteLn;
    Test3_Contains;
    WriteLn;
    Test4_Remove;
    WriteLn;
    Test5_StressTest;
    WriteLn;

    WriteLn('======================================');
    WriteLn('All tests completed!');
    WriteLn('Note: TPriorityQueue is a record (value type),');
    WriteLn('so no manual Free/Destroy is needed.');
    WriteLn('Check below for any memory leaks:');
    WriteLn('Look for "0 unfreed memory blocks"');
    WriteLn('======================================');
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
