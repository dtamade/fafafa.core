{$mode objfpc}{$H+}
program test_vec_leak;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.vec;

type
  TStringVec = specialize TVec<string>;
  TIntVec = specialize TVec<Integer>;

procedure Test1_BasicOps;
var
  V: TStringVec;
begin
  WriteLn('[Test 1] Basic operations');
  V := TStringVec.Create;
  try
    V.Push('hello');
    V.Push('world');
    V.Delete(0);
    WriteLn('  Pass: Count = ', V.Count);
  finally
    V.Free;
  end;
end;

procedure Test2_Clear;
var
  V: TStringVec;
begin
  WriteLn('[Test 2] Clear operation');
  V := TStringVec.Create;
  try
    V.Push('x');
    V.Push('y');
    V.Push('z');
    V.Clear;
    WriteLn('  Pass: Count after clear = ', V.Count);
  finally
    V.Free;
  end;
end;

procedure Test3_GrowShrink;
var
  V: TIntVec;
  i: Integer;
begin
  WriteLn('[Test 3] Grow and shrink');
  V := TIntVec.Create;
  try
    for i := 1 to 100 do
      V.Push(i);
    WriteLn('  Pass: Added 100 items, count = ', V.Count);

    for i := 1 to 50 do
      V.Delete(0);
    WriteLn('  Pass: Removed 50 items, count = ', V.Count);

    V.Clear;
    WriteLn('  Pass: Cleared, count = ', V.Count);
  finally
    V.Free;
  end;
end;

procedure Test4_Overwrite;
var
  V: TStringVec;
begin
  WriteLn('[Test 4] Overwrite by index');
  V := TStringVec.Create;
  try
    V.Push('initial');
    V[0] := 'updated';
    V.Push('second');
    V[1] := 'modified';
    WriteLn('  Pass: Count = ', V.Count);
    WriteLn('  Pass: V[0] = ', V[0]);
    WriteLn('  Pass: V[1] = ', V[1]);
  finally
    V.Free;
  end;
end;

procedure Test5_StressTest;
var
  V: TIntVec;
  i: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  V := TIntVec.Create;
  try
    for i := 1 to 1000 do
      V.Push(i);
    WriteLn('  Pass: Inserted 1000, count = ', V.Count);

    for i := V.Count - 1 downto 0 do
      if (i mod 2) = 0 then
        V.Delete(i);
    WriteLn('  Pass: Removed evens, count = ', V.Count);

    V.Clear;
    WriteLn('  Pass: Cleared, count = ', V.Count);
  finally
    V.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TVec Memory Leak Detection Test');
  WriteLn('======================================');
  WriteLn;

  try
    Test1_BasicOps;
    WriteLn;
    Test2_Clear;
    WriteLn;
    Test3_GrowShrink;
    WriteLn;
    Test4_Overwrite;
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
