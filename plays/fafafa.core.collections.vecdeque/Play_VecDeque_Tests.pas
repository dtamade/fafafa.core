program Play_VecDeque_Tests;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, fpcunit, testregistry, consoletestrunner,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

type
  TPlayVecDeque = class(TTestCase)
  private
    FVec: specialize TVecDeque<Integer>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Smoke_Insert_Write_Remove;
    procedure RemoveCopy_Pointer_Count;
    procedure RemoveCopy_NilPtr_Raises;
    procedure RemoveArray_Index_Array_Count;
    procedure RemoveCopySwap_Pointer_Count;
    procedure RemoveArraySwap_Index_Array_Count;
    procedure RemoveSwap_Index_Var;
    procedure RemoveCopy_Wraparound_Range;
    procedure RemoveArraySwap_Wraparound_Range;
    procedure RemoveCopy_OutOfRange_Raises;
    procedure RemoveArray_CountZero_NoOp;
    procedure RemoveCopySwap_CountZero_NoOp;
  end;

procedure TPlayVecDeque.SetUp;
begin
  FVec := specialize TVecDeque<Integer>.Create;
end;

procedure TPlayVecDeque.TearDown;
begin
  FreeAndNil(FVec);
end;

procedure TPlayVecDeque.Smoke_Insert_Write_Remove;
var
  A: array[0..2] of Integer = (7,8,9);
  Buf: array[0..1] of Integer;
  Removed: Integer;
  C: specialize TVecDeque<Integer>;
begin
  // Insert element
  FVec.PushBack(1);
  FVec.PushBack(2);
  FVec.PushBack(3);
  FVec.Insert(1, 99); // [1,99,2,3]
  AssertEquals(4, FVec.GetCount);
  AssertEquals(99, FVec.Get(1));

  // Write array at tail (grows)
  FVec.Write(4, A);
  AssertEquals(7, FVec.GetCount);
  AssertEquals(7, FVec.Get(4));
  AssertEquals(9, FVec.Get(6));

  // Write from collection with start index
  C := specialize TVecDeque<Integer>.Create;
  try
    C.PushBack(10); C.PushBack(20); C.PushBack(30);
    FVec.Write(2, C, 1); // place 20,30 at index 2
    AssertEquals(7, FVec.GetCount);
    AssertEquals(20, FVec.Get(2));
    AssertEquals(30, FVec.Get(3));
  finally
    C.Free;
  end;

  // Remove by index
  Removed := FVec.Remove(2);
  AssertEquals(20, Removed);
end;



procedure TPlayVecDeque.RemoveCopy_Pointer_Count;
var
  i: Integer;
  Buf: array[0..2] of Integer;
begin
  FVec.Clear;
  for i := 0 to 6 do FVec.PushBack(i); // [0..6]
  FVec.RemoveCopy(2, @Buf[0], 3);      // copy [2,3,4], then delete keeping order -> [0,1,5,6]
  AssertEquals(2, Buf[0]); AssertEquals(3, Buf[1]); AssertEquals(4, Buf[2]);
  AssertEquals(4, FVec.GetCount);
  AssertEquals(5, FVec.Get(2)); AssertEquals(6, FVec.Get(3));
end;

procedure TPlayVecDeque.RemoveCopy_NilPtr_Raises;
var
  raised: Boolean;
  i: Integer;
begin
  FVec.Clear;
  for i := 1 to 3 do FVec.PushBack(i);
  raised := False;
  try
    FVec.RemoveCopy(0, nil, 1);
  except
    on E: EArgumentNil do raised := True;
  end;
  AssertTrue('EArgumentNil expected', raised);
end;

procedure TPlayVecDeque.RemoveArray_Index_Array_Count;
var
  i: Integer;
  A: specialize TGenericArray<Integer>;
begin
  FVec.Clear;
  for i := 10 to 15 do FVec.PushBack(i); // [10..15]
  FVec.RemoveArray(1, A, 3);             // copy [11,12,13], then delete -> [10,14,15]
  AssertEquals(3, Length(A));
  AssertEquals(11, A[0]); AssertEquals(12, A[1]); AssertEquals(13, A[2]);
  AssertEquals(3, FVec.GetCount);
  AssertEquals(10, FVec.Get(0)); AssertEquals(14, FVec.Get(1)); AssertEquals(15, FVec.Get(2));
end;

procedure TPlayVecDeque.RemoveCopySwap_Pointer_Count;
var
  i: Integer;
  Buf: array[0..1] of Integer;
begin
  FVec.Clear;
  for i := 1 to 6 do FVec.PushBack(i); // [1..6]
  FVec.RemoveCopySwap(2, @Buf[0], 2);  // copy [3,4], then swap-delete -> remaining size 4
  AssertEquals(3, Buf[0]); AssertEquals(4, Buf[1]);
  AssertEquals(4, FVec.GetCount);
  // order not guaranteed; just verify removed elements gone, and survivors set size is 4
  AssertEquals(0, FVec.CountOf(3));
  AssertEquals(0, FVec.CountOf(4));
end;

procedure TPlayVecDeque.RemoveArraySwap_Index_Array_Count;
var
  i: Integer;
  A: specialize TGenericArray<Integer>;
begin
  FVec.Clear;
  for i := 0 to 5 do FVec.PushBack(i);   // [0..5]
  FVec.RemoveArraySwap(1, A, 3);         // copy [1,2,3], then swap-delete -> size 3
  AssertEquals(3, Length(A));
  AssertEquals(1, A[0]); AssertEquals(2, A[1]); AssertEquals(3, A[2]);
  AssertEquals(3, FVec.GetCount);
  AssertEquals(0, FVec.CountOf(1));
  AssertEquals(0, FVec.CountOf(2));
  AssertEquals(0, FVec.CountOf(3));
end;

procedure TPlayVecDeque.RemoveSwap_Index_Var;
var
  i, E: Integer;
begin
  FVec.Clear;
  for i := 5 to 9 do FVec.PushBack(i);   // [5..9]
  FVec.RemoveSwap(1, E);                 // remove value 6, swap with last -> size 4
  AssertEquals(6, E);
  AssertEquals(4, FVec.GetCount);
  AssertEquals(0, FVec.CountOf(6));
end;



// Play unit main program ends here. All test methods must be above.

procedure TPlayVecDeque.RemoveCopy_Wraparound_Range;
var
  i: Integer;
  B: array[0..3] of Integer;
begin
  FVec.Clear;
  FVec.ReserveExact(6);
  for i := 1 to 6 do FVec.PushBack(i);       // [1..6]
  for i := 1 to 4 do FVec.Dequeue;           // [5,6]
  for i := 7 to 10 do FVec.PushBack(i);      // [5,6,7,8,9,10] (wraparound in ring)
  FVec.RemoveCopy(1, @B[0], 4);              // copy [6,7,8,9], then ordered delete -> [5,10]
  AssertEquals(6, B[0]); AssertEquals(7, B[1]); AssertEquals(8, B[2]); AssertEquals(9, B[3]);
  AssertEquals(2, FVec.GetCount);
  AssertEquals(5, FVec.Get(0)); AssertEquals(10, FVec.Get(1));
end;

procedure TPlayVecDeque.RemoveArraySwap_Wraparound_Range;
var
  i: Integer;
  A: specialize TGenericArray<Integer>;
begin
  FVec.Clear;
  FVec.ReserveExact(6);
  for i := 1 to 6 do FVec.PushBack(i);       // [1..6]
  for i := 1 to 4 do FVec.Dequeue;           // [5,6]
  for i := 7 to 10 do FVec.PushBack(i);      // [5,6,7,8,9,10]
  FVec.RemoveArraySwap(1, A, 3);             // copy [6,7,8], then swap delete -> size 3
  AssertEquals(3, Length(A));
  AssertEquals(6, A[0]); AssertEquals(7, A[1]); AssertEquals(8, A[2]);
  AssertEquals(3, FVec.GetCount);
  AssertEquals(0, FVec.CountOf(6));
  AssertEquals(0, FVec.CountOf(7));
  AssertEquals(0, FVec.CountOf(8));
end;

procedure TPlayVecDeque.RemoveCopy_OutOfRange_Raises;
var
  i: Integer;
  B: array[0..1] of Integer;
  raised: Boolean;
begin
  FVec.Clear;
  for i := 1 to 3 do FVec.PushBack(i);       // [1,2,3]
  raised := False;
  try
    FVec.RemoveCopy(2, @B[0], 5);
  except
    on E: EOutOfRange do raised := True;
  end;
  AssertTrue('EOutOfRange expected', raised);
end;

procedure TPlayVecDeque.RemoveArray_CountZero_NoOp;
var
  i: Integer;
  A: specialize TGenericArray<Integer>;
begin
  FVec.Clear;
  for i := 1 to 3 do FVec.PushBack(i);       // [1,2,3]
  FVec.RemoveArray(1, A, 0);                 // no-op
  AssertEquals(3, FVec.GetCount);
end;

procedure TPlayVecDeque.RemoveCopySwap_CountZero_NoOp;
var
  i: Integer;
  B: array[0..0] of Integer;
begin
  FVec.Clear;
  for i := 1 to 3 do FVec.PushBack(i);       // [1,2,3]
  FVec.RemoveCopySwap(1, @B[0], 0);          // no-op
  AssertEquals(3, FVec.GetCount);
end;

var
  App: TTestRunner;
begin
  RegisterTest('Play.VecDeque', TPlayVecDeque);
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Run;
  finally
    App.Free;
  end;
end.

