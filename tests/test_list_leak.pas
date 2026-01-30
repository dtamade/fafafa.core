{$mode objfpc}{$H+}
program test_list_leak;

uses
  SysUtils,
  fafafa.core.collections.list;

type
  TStringList = specialize TList<string>;
  TIntList = specialize TList<Integer>;

procedure Test1_BasicOps;
var
  L: TStringList;
begin
  WriteLn('[Test 1] Basic operations');
  L := TStringList.Create;
  try
    L.PushFront('front');
    L.PushBack('back');
    L.PopFront;
    WriteLn('  Pass: Count = ', L.Count);
  finally
    L.Free;
  end;
end;

procedure Test2_Clear;
var
  L: TStringList;
begin
  WriteLn('[Test 2] Clear operation');
  L := TStringList.Create;
  try
    L.PushBack('x');
    L.PushBack('y');
    L.PushBack('z');
    L.Clear;
    WriteLn('  Pass: Count after clear = ', L.Count);
  finally
    L.Free;
  end;
end;

procedure Test3_FrontBackOps;
var
  L: TIntList;
  i: Integer;
begin
  WriteLn('[Test 3] Front/Back operations');
  L := TIntList.Create;
  try
    for i := 1 to 10 do
      L.PushBack(i);
    for i := 1 to 5 do
      L.PopFront;
    for i := 1 to 3 do
      L.PushFront(i * 10);

    WriteLn('  Pass: Count = ', L.Count);
    WriteLn('  Front = ', L.Front);
    WriteLn('  Back = ', L.Back);
  finally
    L.Free;
  end;
end;

procedure Test4_InsertRemove;
var
  L: TStringList;
begin
  WriteLn('[Test 4] Insert/Remove operations');
  L := TStringList.Create;
  try
    L.PushBack('1');
    L.PushBack('2');
    L.PushBack('3');
    L.PushFront('0');
    WriteLn('  Pass: After push, count = ', L.Count);

    L.PopFront;
    L.PopBack;
    WriteLn('  Pass: After pop, count = ', L.Count);
  finally
    L.Free;
  end;
end;

procedure Test5_StressTest;
var
  L: TIntList;
  i: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  L := TIntList.Create;
  try
    for i := 1 to 1000 do
      L.PushBack(i);

    WriteLn('  Pass: Inserted 1000, count = ', L.Count);

    for i := 1 to 500 do
      L.PopFront;

    WriteLn('  Pass: Popped 500, count = ', L.Count);

    L.Clear;
    WriteLn('  Pass: Cleared, count = ', L.Count);
  finally
    L.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TList Memory Leak Detection Test');
  WriteLn('======================================');
  WriteLn;

  try
    Test1_BasicOps;
    WriteLn;
    Test2_Clear;
    WriteLn;
    Test3_FrontBackOps;
    WriteLn;
    Test4_InsertRemove;
    WriteLn;
    Test5_StressTest;
    WriteLn;

    WriteLn('======================================');
    WriteLn('All tests completed!');
    WriteLn('Check below for memory leak report:');
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
