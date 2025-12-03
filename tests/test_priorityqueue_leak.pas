{$mode objfpc}{$H+}
program test_priorityqueue_leak;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.priorityqueue;

type
  TIntPQ = specialize TPriorityQueue<Integer>;
  TStringPQ = specialize TPriorityQueue<string>;

function IntComparer(const A, B: Integer): Integer;
begin
  Result := A - B;
end;

function StringComparer(const A, B: string): Integer;
begin
  Result := CompareStr(A, B);
end;

procedure Test1_BasicOps;
var
  PQ: TIntPQ;
  V: Integer;
begin
  WriteLn('[Test 1] Basic operations');
  PQ.Initialize(@IntComparer);
  try
    PQ.Enqueue(5);
    PQ.Enqueue(3);
    PQ.Enqueue(7);
    PQ.Enqueue(1);

    if PQ.Dequeue(V) then
      WriteLn('  Dequeued: ', V, ' (expected 1)');
    if PQ.Peek(V) then
      WriteLn('  Peek: ', V, ' (expected 3)');

    WriteLn('  Pass: Count = ', PQ.Count);
  finally
    PQ.Clear;
  end;
end;

procedure Test2_StringPQ;
var
  PQ: TStringPQ;
  S: string;
begin
  WriteLn('[Test 2] String priority queue');
  PQ.Initialize(@StringComparer);
  try
    PQ.Enqueue('zebra');
    PQ.Enqueue('apple');
    PQ.Enqueue('banana');

    if PQ.Dequeue(S) then
      WriteLn('  Dequeued: ', S, ' (expected apple)');
    if PQ.Peek(S) then
      WriteLn('  Peek: ', S, ' (expected banana)');

    WriteLn('  Pass: Count = ', PQ.Count);
  finally
    PQ.Clear;
  end;
end;

procedure Test3_Clear;
var
  PQ: TIntPQ;
  I: Integer;
begin
  WriteLn('[Test 3] Clear operation');
  PQ.Initialize(@IntComparer);
  try
    for I := 1 to 10 do
      PQ.Enqueue(I);
    WriteLn('  Before clear: Count = ', PQ.Count);
    PQ.Clear;
    WriteLn('  Pass: Count after clear = ', PQ.Count);
  finally
    PQ.Clear;
  end;
end;

procedure Test4_FindAndRemove;
var
  PQ: TIntPQ;
  I: Integer;
begin
  WriteLn('[Test 4] Find and remove');
  PQ.Initialize(@IntComparer);
  try
    for I := 1 to 5 do
      PQ.Enqueue(I * 10);

    if PQ.Contains(30) then
      WriteLn('  Found: 30');
    if PQ.Remove(30) then
      WriteLn('  Removed: 30');

    WriteLn('  Pass: Count after remove = ', PQ.Count);
  finally
    PQ.Clear;
  end;
end;

procedure Test5_StressTest;
var
  PQ: TIntPQ;
  I, V: Integer;
  Success: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  PQ.Initialize(@IntComparer);
  try
    // Insert 1000 items
    for I := 1000 downto 1 do
      PQ.Enqueue(I);
    WriteLn('  Pass: Inserted 1000, count = ', PQ.Count);

    // Dequeue first 500
    Success := 0;
    for I := 1 to 500 do
      if PQ.Dequeue(V) then
        Inc(Success);
    WriteLn('  Pass: Dequeued ', Success, ', count = ', PQ.Count);

    // Clear
    PQ.Clear;
    WriteLn('  Pass: Cleared, count = ', PQ.Count);
  finally
    PQ.Clear;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TPriorityQueue Memory Leak Test');
  WriteLn('======================================');
  WriteLn;

  Test1_BasicOps;
  WriteLn;

  Test2_StringPQ;
  WriteLn;

  Test3_Clear;
  WriteLn;

  Test4_FindAndRemove;
  WriteLn;

  Test5_StressTest;
  WriteLn;

  WriteLn('======================================');
  WriteLn('All tests completed!');
  WriteLn('Check below for memory leak report:');
  WriteLn('Look for "0 unfreed memory blocks"');
  WriteLn('======================================');
end.