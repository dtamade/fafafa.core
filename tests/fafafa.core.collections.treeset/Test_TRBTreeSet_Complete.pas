{$CODEPAGE UTF8}
unit Test_TRBTreeSet_Complete;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.orderedset.rb,
  fafafa.core.collections.base;

type
  TTestCase_TRBTreeSet = class(TTestCase)
  published
    procedure Test_Create_Destroy;
    procedure Test_Insert_Contains_Duplicate;
    procedure Test_Ordered_Iteration;
    procedure Test_LowerBound_UpperBound;
    procedure Test_Min_Max;
    procedure Test_Remove;
    procedure Test_Range_Iter;
    procedure Test_Range_EmptySet;
    procedure Test_Range_LeftEqualsRight;
    procedure Test_AppendUnChecked_Serialize;
    procedure Test_Clear_Zero_Reverse_NoEffect;
    // New edge/safety tests
    procedure Test_Delete_EdgeCases;
    procedure Test_Clear_Idempotent_Safe;
  end;

implementation

procedure TTestCase_TRBTreeSet.Test_Create_Destroy;
var S: specialize TRBTreeSet<Integer>;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    AssertTrue(S <> nil);
    AssertEquals(SizeUInt(0), S.GetCount);
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Insert_Contains_Duplicate;
var S: specialize TRBTreeSet<Integer>;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    AssertTrue(S.Insert(10));
    AssertTrue(S.ContainsKey(10));
    AssertEquals(SizeUInt(1), S.GetCount);
    AssertFalse(S.Insert(10));
    AssertEquals(SizeUInt(1), S.GetCount);
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Ordered_Iteration;
var
  S: specialize TRBTreeSet<Integer>;
  I, Prev, Cur: Integer;
  It: specialize TIter<Integer>;
  HasFirst: Boolean;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    for I := 1 to 100 do S.Insert(Random(50));
    It := S.Iter;
    HasFirst := It.MoveNext;
    if HasFirst then
    begin
      Prev := It.Current;
      while It.MoveNext do
      begin
        Cur := It.Current;
        AssertTrue(Cur > Prev);
        Prev := Cur;
      end;
    end;
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_LowerBound_UpperBound;
var
  S: specialize TRBTreeSet<Integer>;
  v: Integer;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    S.Insert(10); S.Insert(20); S.Insert(30);
    AssertTrue(S.LowerBound(15, v) and (v=20));
    AssertTrue(S.UpperBound(20, v) and (v=30));
    AssertTrue(not S.LowerBound(31, v));
    AssertTrue(S.LowerBound(5, v) and (v=10));
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Min_Max;
var
  S: specialize TRBTreeSet<Integer>;
  v: Integer;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    S.Insert(3); S.Insert(1); S.Insert(2);
    AssertTrue(S.Min(v) and (v=1));
    AssertTrue(S.Max(v) and (v=3));
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Remove;
var
  S: specialize TRBTreeSet<Integer>;
  v: Integer;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    S.Insert(10); S.Insert(20); S.Insert(30);
    AssertTrue(S.Remove(20));
    AssertFalse(S.ContainsKey(20));
    AssertTrue(S.Min(v) and (v=10));
    AssertTrue(S.Max(v) and (v=30));
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_AppendUnChecked_Serialize;
var
  S: specialize TRBTreeSet<Integer>;
  A: array[0..4] of Integer = (5,3,7,1,9);
  OutArr: array of Integer;
  I: SizeInt;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    S.AppendUnChecked(@A[0], Length(A));
    AssertEquals(SizeUInt(5), S.GetCount);
    OutArr := S.ToArray;
    AssertEquals(Length(A), Length(OutArr));
    for I := 1 to High(OutArr) do
      AssertTrue(OutArr[I] > OutArr[I-1]);
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Range_Iter;
var
  S: specialize TRBTreeSet<Integer>;
  It: specialize TIter<Integer>;
  V: Integer;
  Cnt: Integer;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    // prepare data 1..7
    S.Insert(1); S.Insert(2); S.Insert(3); S.Insert(4); S.Insert(5); S.Insert(6); S.Insert(7);

    It := S.IterateRange(3, 6, False); // [3,6)
    Cnt := 0;
    while It.MoveNext do begin
      V := It.Current;
      AssertTrue((V>=3) and (V<6));
      Inc(Cnt);
    end;
    AssertEquals(3, Cnt);

    It := S.IterateRange(3, 6, True); // [3,6]
    Cnt := 0;
    while It.MoveNext do begin
      V := It.Current;
      AssertTrue((V>=3) and (V<=6));
      Inc(Cnt);
    end;
    AssertEquals(4, Cnt);
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Range_EmptySet;
var
  S: specialize TRBTreeSet<Integer>;
  It: specialize TIter<Integer>;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    It := S.IterateRange(1, 10, False);
    AssertFalse(It.MoveNext);
  finally
    S.Free;
  end;
end;



procedure TTestCase_TRBTreeSet.Test_Range_LeftEqualsRight;
var
  S: specialize TRBTreeSet<Integer>;
  It: specialize TIter<Integer>;
  v: Integer;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    S.LoadFrom([1,2,3,4,5]);
    It := S.IterateRange(3, 3, False); // [3,3) -> empty
    AssertFalse(It.MoveNext);
    It := S.IterateRange(3, 3, True);  // [3,3] -> single 3
    AssertTrue(It.MoveNext);
    v := It.Current;
    AssertEquals(3, v);
    AssertFalse(It.MoveNext);
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Clear_Zero_Reverse_NoEffect;
var
  S: specialize TRBTreeSet<Integer>;
  Before: SizeUInt;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    S.Insert(1); S.Insert(2); S.Insert(3);
    Before := S.GetCount;
    S.DoReverse; // no-op
    AssertEquals(Before, S.GetCount);
    S.DoZero;    // equals Clear
    AssertEquals(SizeUInt(0), S.GetCount);
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Delete_EdgeCases;
var S: specialize TRBTreeSet<Integer>;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    // 删除最小、最大、根、单子树情况
    S.Insert(2); S.Insert(1); S.Insert(3);
    AssertTrue(S.Remove(1)); // remove min
    AssertTrue(S.Remove(3)); // remove max
    AssertTrue(S.Remove(2)); // remove root
    AssertEquals(SizeUInt(0), S.GetCount);

    // 右斜树删除
    S.Insert(1); S.Insert(2); S.Insert(3);
    AssertTrue(S.Remove(2)); // remove internal
    AssertTrue(S.Remove(3));
    AssertTrue(S.Remove(1));
    AssertEquals(SizeUInt(0), S.GetCount);

    // 左斜树删除
    S.Insert(3); S.Insert(2); S.Insert(1);
    AssertTrue(S.Remove(2));
    AssertTrue(S.Remove(1));
    AssertTrue(S.Remove(3));
  finally
    S.Free;
  end;
end;

procedure TTestCase_TRBTreeSet.Test_Clear_Idempotent_Safe;
var S: specialize TRBTreeSet<Integer>;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    S.Insert(10); S.Insert(20); S.Insert(30);
    S.Clear;
    S.Clear; // 再次 Clear 不应异常
    AssertEquals(SizeUInt(0), S.GetCount);
  finally
    S.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_TRBTreeSet);
end.

