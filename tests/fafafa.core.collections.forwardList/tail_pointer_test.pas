program tail_pointer_test;

{$mode objfpc}{$H+}
{$DEFINE DEBUG}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.forwardList;

type
  TIntFL = specialize TForwardList<Integer>;

procedure AssertTrue(const Msg: string; Cond: Boolean);
begin
  if not Cond then
  begin
    WriteLn('ASSERT FAIL: ', Msg);
    Halt(1);
  end;
end;

procedure Test_PushFrontRangeUnChecked_SetsTail;
var
  L: TIntFL;
  A: array of Integer;
begin
  L := TIntFL.Create;
  try
    SetLength(A, 3);
    A[0] := 1; A[1] := 2; A[2] := 3;
    L.PushFrontRangeUnChecked(A);
    AssertTrue('tail validate after PushFrontRangeUnChecked(empty)', L.DebugValidateTail);
  finally
    L.Free;
  end;
end;

procedure Test_Unique_RefreshTail;
var
  L: TIntFL;
begin
  L := TIntFL.Create;
  try
    L.PushFront(1);
    L.PushFront(1);
    L.PushFront(1);
    L.Unique;
    AssertTrue('tail validate after Unique', L.DebugValidateTail);
  finally
    L.Free;
  end;
end;

procedure Test_RemoveIfRef_RefreshTail;
var
  L: TIntFL;
  v: Integer;
  function Pred(const x: Integer): Boolean; begin Exit(x = 2); end;
begin
  L := TIntFL.Create;
  try
    L.PushFront(1);
    L.PushFront(2);
    L.PushFront(3);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    L.RemoveIf(@Pred);
    {$ELSE}
    // Skip if no anonymous refs
    {$ENDIF}
    AssertTrue('tail validate after RemoveIf', L.DebugValidateTail);
    if L.DebugGetTailValue(v) then
      WriteLn('Tail=', v);
  finally
    L.Free;
  end;
end;

procedure Test_Merge_RefreshTail;
var
  A, B: TIntFL;
begin
  A := TIntFL.Create;
  B := TIntFL.Create;
  try
    A.PushFront(5); A.PushFront(3); A.PushFront(1); // 1,3,5
    B.PushFront(6); B.PushFront(4); B.PushFront(2); // 2,4,6
    A.Sort; B.Sort;
    A.Merge(B);
    AssertTrue('tail validate after Merge', A.DebugValidateTail);
    AssertTrue('source cleared after Merge (head)', B.GetCount = 0);
  finally
    A.Free; B.Free;
  end;
end;

procedure Test_Splice_Range_RefreshTail;
var
  A, B: TIntFL;
  first, last, pos: specialize TIter<Integer>;
begin
  A := TIntFL.Create;
  B := TIntFL.Create;
  try
    // A: 1,2,3  B: 4,5,6
    A.PushFront(3); A.PushFront(2); A.PushFront(1);
    B.PushFront(6); B.PushFront(5); B.PushFront(4);

    // 取 B 的区间 [begin+1, end) => 5,6
    first := B.Iter; first.MoveNext; // 6 (头)
    first.MoveNext; // 5
    last := B.CEnd; // end

    pos := A.CEnd; // 在 A 末尾后 splice
    A.Splice(pos, B, first, last);

    AssertTrue('tail validate after Splice range', A.DebugValidateTail);
  finally
    A.Free; B.Free;
  end;
end;

begin
  try
    Test_PushFrontRangeUnChecked_SetsTail;
    Test_Unique_RefreshTail;
    Test_RemoveIfRef_RefreshTail;
    Test_Merge_RefreshTail;
    Test_Splice_Range_RefreshTail;
    WriteLn('All tail pointer tests passed');
  except
    on E: Exception do
    begin
      WriteLn('Test failed: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

