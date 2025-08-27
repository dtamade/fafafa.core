program Play_VecDeque_Tests;

{$mode objfpc}{$H+}

uses
  SysUtils, fpcunit, testregistry,
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
  var C: specialize TVecDeque<Integer>;
  begin
    C := specialize TVecDeque<Integer>.Create;
  end;
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

var
  R: TTestResult;
begin
  RegisterTest('Play.VecDeque', specialize TPlayVecDeque);
  R := RunRegisteredTests;
  if (R <> nil) and (R.ErrorCount = 0) and (R.Failures = 0) then
    Halt(0)
  else
    Halt(1);
end.

