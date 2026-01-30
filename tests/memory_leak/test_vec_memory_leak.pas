program test_vec_memory_leak;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vec;

type
  TIntVec = specialize TVec<Integer>;
  TStringVec = specialize TVec<String>;

procedure TestIntegerVec;
var
  V: TIntVec;
  i: Integer;
begin
  WriteLn('Testing Integer Vec...');
  V := TIntVec.Create;
  try
    // Test 1: Basic operations
    for i := 1 to 1000 do
      V.PushBack(i);

    WriteLn('  - Pushed 1000 integers');

    // Test 2: Remove operations
    for i := 1 to 500 do
      V.PopBack;

    WriteLn('  - Popped 500 integers');

    // Test 3: Clear and refill
    V.Clear;
    WriteLn('  - Cleared vec');

    for i := 1 to 100 do
      V.PushBack(i * 2);

    WriteLn('  - Refilled with 100 integers');

  finally
    V.Free;
    WriteLn('  - Freed vec');
  end;

  WriteLn('Integer Vec test completed');
end;

procedure TestStringVec;
var
  V: TStringVec;
  i: Integer;
begin
  WriteLn('Testing String Vec...');
  V := TStringVec.Create;
  try
    // Test 1: Basic operations
    for i := 1 to 500 do
      V.PushBack('String_' + IntToStr(i));

    WriteLn('  - Pushed 500 strings');

    // Test 2: Remove operations
    for i := 1 to 250 do
      V.PopBack;

    WriteLn('  - Popped 250 strings');

    // Test 3: Clear
    V.Clear;
    WriteLn('  - Cleared vec');

  finally
    V.Free;
    WriteLn('  - Freed vec');
  end;

  WriteLn('String Vec test completed');
end;

procedure TestCapacityGrowth;
var
  V: TIntVec;
  i: Integer;
begin
  WriteLn('Testing Capacity Growth...');
  V := TIntVec.Create;
  try
    // Force multiple reallocations
    for i := 1 to 10000 do
      V.PushBack(i);

    WriteLn('  - Pushed 10000 integers (multiple reallocations)');
    WriteLn('  - Final capacity: ', V.Capacity);
    WriteLn('  - Final count: ', V.Count);

  finally
    V.Free;
    WriteLn('  - Freed vec');
  end;

  WriteLn('Capacity growth test completed');
end;

procedure TestReserve;
var
  V: TIntVec;
  i: Integer;
begin
  WriteLn('Testing Reserve...');
  V := TIntVec.Create;
  try
    // Pre-allocate capacity
    V.Reserve(5000);
    WriteLn('  - Reserved capacity for 5000 elements');

    for i := 1 to 3000 do
      V.PushBack(i);

    WriteLn('  - Pushed 3000 integers');
    WriteLn('  - Capacity: ', V.Capacity);
    WriteLn('  - Count: ', V.Count);

  finally
    V.Free;
    WriteLn('  - Freed vec');
  end;

  WriteLn('Reserve test completed');
end;

begin
  WriteLn('========================================');
  WriteLn('TVec Memory Leak Test');
  WriteLn('========================================');
  WriteLn;

  try
    TestIntegerVec;
    WriteLn;

    TestStringVec;
    WriteLn;

    TestCapacityGrowth;
    WriteLn;

    TestReserve;
    WriteLn;

    WriteLn('========================================');
    WriteLn('All tests completed successfully');
    WriteLn('========================================');
    WriteLn;
    WriteLn('Check HeapTrc output below for memory leaks.');
    WriteLn('Expected: "0 unfreed memory blocks : 0"');
    WriteLn;

  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.