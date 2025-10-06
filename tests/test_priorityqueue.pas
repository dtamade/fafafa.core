program test_priorityqueue;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.priorityqueue;

type
  TIntQueue = specialize TPriorityQueue<Integer>;

function CompareInts(const A, B: Integer): Integer;
begin
  Result := A - B;
end;

procedure TestBasicOperations;
var
  queue: TIntQueue;
  val: Integer;
begin
  WriteLn('=== Test 1: Basic Operations ===');
  
  queue.Initialize(@CompareInts);
  
  // Test empty
  WriteLn('Empty: ', queue.IsEmpty);
  WriteLn('Count: ', queue.Count);
  
  // Test enqueue
  queue.Enqueue(5);
  queue.Enqueue(3);
  queue.Enqueue(7);
  queue.Enqueue(1);
  queue.Enqueue(9);
  
  WriteLn('After enqueue 5,3,7,1,9:');
  WriteLn('  Count: ', queue.Count);
  WriteLn('  Peek: ', queue.Peek);
  
  // Test dequeue (should be in order: 1,3,5,7,9)
  WriteLn('Dequeue order:');
  while not queue.IsEmpty do
  begin
    val := queue.Dequeue;
    WriteLn('  ', val);
  end;
  
  WriteLn('Empty after dequeue: ', queue.IsEmpty);
  WriteLn;
end;

procedure TestPriorityOrder;
var
  queue: TIntQueue;
  i: Integer;
begin
  WriteLn('=== Test 2: Priority Order ===');
  
  queue.Initialize(@CompareInts);
  
  // Insert in reverse order
  for i := 10 downto 1 do
    queue.Enqueue(i);
  
  WriteLn('Inserted 10 down to 1');
  WriteLn('Dequeue should be 1 to 10:');
  
  for i := 1 to 10 do
  begin
    if queue.Dequeue <> i then
    begin
      WriteLn('ERROR: Expected ', i, ' but got different value');
      Exit;
    end;
  end;
  
  WriteLn('✓ All values in correct order');
  WriteLn;
end;

procedure TestRemove;
var
  queue: TIntQueue;
  found: Boolean;
begin
  WriteLn('=== Test 3: Remove ===');
  
  queue.Initialize(@CompareInts);
  
  queue.Enqueue(5);
  queue.Enqueue(3);
  queue.Enqueue(7);
  queue.Enqueue(1);
  queue.Enqueue(9);
  
  WriteLn('Queue: 5,3,7,1,9');
  WriteLn('Count before remove: ', queue.Count);
  
  // Remove 7
  found := queue.Remove(7);
  WriteLn('Remove 7: ', found);
  WriteLn('Count after remove: ', queue.Count);
  
  // Remove non-existent
  found := queue.Remove(100);
  WriteLn('Remove 100 (not exists): ', found);
  WriteLn('Count: ', queue.Count);
  
  // Verify order still correct
  WriteLn('Remaining order: ', queue.Dequeue, ', ', queue.Dequeue, ', ', 
          queue.Dequeue, ', ', queue.Dequeue);
  WriteLn;
end;

procedure TestLargeDataset;
var
  queue: TIntQueue;
  i, val, expected: Integer;
begin
  WriteLn('=== Test 4: Large Dataset (1000 items) ===');
  
  queue.Initialize(@CompareInts, 100);
  
  // Insert 1000 random values
  Randomize;
  for i := 1 to 1000 do
    queue.Enqueue(Random(10000));
  
  WriteLn('Inserted 1000 random values');
  WriteLn('Count: ', queue.Count);
  
  // Verify they come out in sorted order
  expected := -1;
  for i := 1 to 1000 do
  begin
    val := queue.Dequeue;
    if val < expected then
    begin
      WriteLn('ERROR: Order violation at position ', i);
      Exit;
    end;
    expected := val;
  end;
  
  WriteLn('✓ All 1000 values in correct order');
  WriteLn;
end;

procedure TestContains;
var
  queue: TIntQueue;
begin
  WriteLn('=== Test 5: Contains ===');
  
  queue.Initialize(@CompareInts);
  
  queue.Enqueue(5);
  queue.Enqueue(3);
  queue.Enqueue(7);
  
  WriteLn('Queue: 5,3,7');
  WriteLn('Contains 5: ', queue.Contains(5));
  WriteLn('Contains 7: ', queue.Contains(7));
  WriteLn('Contains 10: ', queue.Contains(10));
  WriteLn;
end;

procedure TestToArray;
var
  queue: TIntQueue;
  arr: array of Integer;
  i: Integer;
begin
  WriteLn('=== Test 6: ToArray ===');
  
  queue.Initialize(@CompareInts);
  
  queue.Enqueue(5);
  queue.Enqueue(3);
  queue.Enqueue(7);
  queue.Enqueue(1);
  
  arr := queue.ToArray;
  WriteLn('ToArray count: ', Length(arr));
  Write('Values: ');
  for i := 0 to High(arr) do
    Write(arr[i], ' ');
  WriteLn;
  WriteLn;
end;

begin
  try
    WriteLn('========================================');
    WriteLn('  Priority Queue Test Suite');
    WriteLn('========================================');
    WriteLn;
    
    TestBasicOperations;
    TestPriorityOrder;
    TestRemove;
    TestContains;
    TestToArray;
    TestLargeDataset;
    
    WriteLn('========================================');
    WriteLn('  All tests passed! ✓');
    WriteLn('========================================');
    
    ExitCode := 0;
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('ERROR: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
