{$mode objfpc}{$H+}
program test_vecdeque_leak;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.vecdeque;

type
  TStringVecDeque = specialize TVecDeque<string>;
  TIntVecDeque = specialize TVecDeque<Integer>;

procedure Test1_BasicOps;
var
  D: TStringVecDeque;
begin
  WriteLn('[Test 1] Basic operations');
  D := TStringVecDeque.Create;
  try
    D.PushFront('front');
    D.PushBack('back');
    D.PopFront;
    WriteLn('  Pass: Count = ', D.Count);
  finally
    D.Free;
  end;
end;

procedure Test2_Clear;
var
  D: TStringVecDeque;
begin
  WriteLn('[Test 2] Clear operation');
  D := TStringVecDeque.Create;
  try
    D.Add('x');
    D.Add('y');
    D.Add('z');
    D.Clear;
    WriteLn('  Pass: Count after clear = ', D.Count);
  finally
    D.Free;
  end;
end;

procedure Test3_FrontBackOps;
var
  D: TIntVecDeque;
  i: Integer;
begin
  WriteLn('[Test 3] Front/Back operations');
  D := TIntVecDeque.Create;
  try
    for i := 1 to 10 do
      D.PushBack(i);
    for i := 1 to 5 do
      D.PopFront;
    for i := 1 to 3 do
      D.PushFront(i * 10);

    WriteLn('  Pass: Count = ', D.Count);
    WriteLn('  Front = ', D.PeekFront);
    WriteLn('  Back = ', D.PeekBack);
  finally
    D.Free;
  end;
end;

procedure Test4_GrowShrink;
var
  D: TStringVecDeque;
  i: Integer;
begin
  WriteLn('[Test 4] Grow and shrink');
  D := TStringVecDeque.Create;
  try
    for i := 1 to 100 do
      D.Add('item' + IntToStr(i));
    WriteLn('  Pass: Added 100 items, count = ', D.Count);

    for i := 1 to 50 do
      D.PopFront;
    WriteLn('  Pass: Removed 50 items, count = ', D.Count);

    D.Clear;
    WriteLn('  Pass: Cleared, count = ', D.Count);
  finally
    D.Free;
  end;
end;

procedure Test5_StressTest;
var
  D: TIntVecDeque;
  i: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  D := TIntVecDeque.Create;
  try
    for i := 1 to 1000 do
      D.Add(i);

    WriteLn('  Pass: Inserted 1000, count = ', D.Count);

    for i := 1 to 500 do
      if (i mod 2) = 0 then
        D.PopFront;

    WriteLn('  Pass: Removed 250 items, count = ', D.Count);

    D.Clear;
    WriteLn('  Pass: Cleared, count = ', D.Count);
  finally
    D.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TVecDeque Memory Leak Detection Test');
  WriteLn('======================================');
  WriteLn;

  try
    Test1_BasicOps;
    WriteLn;
    Test2_Clear;
    WriteLn;
    Test3_FrontBackOps;
    WriteLn;
    Test4_GrowShrink;
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
