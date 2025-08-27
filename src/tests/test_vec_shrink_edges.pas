unit test_vec_shrink_edges;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.base, fpcunit, testregistry,
  fafafa.core.collections.vec;

procedure RegisterVecShrinkEdgeTests;

implementation

type
  TVecShrinkEdges = class(TTestCase)
  published
    procedure Test_Shrink_NoOp_When_Capacity_Equal_Count;
    procedure Test_ShrinkTo_Not_Allow_Less_Than_Count;
    procedure Test_ShrinkToFit_NoOp_When_Below_Threshold;
  end;

procedure TVecShrinkEdges.Test_Shrink_NoOp_When_Capacity_Equal_Count;
var
  v: specialize TVec<Integer>;
  i: Integer;
  cap0, cap1: SizeUInt;
begin
  v := specialize TVec<Integer>.Create;
  try
    for i := 1 to 100 do v.Push(i);
    v.Shrink; // capacity := count
    cap0 := v.Capacity;
    v.Shrink;
    cap1 := v.Capacity;
    AssertEquals(cap0, cap1);
  finally
    v.Free;
  end;
end;

procedure TVecShrinkEdges.Test_ShrinkTo_Not_Allow_Less_Than_Count;
var
  v: specialize TVec<Integer>;
  i: Integer;
begin
  v := specialize TVec<Integer>.Create;
  try
    for i := 1 to 100 do v.Push(i);
    try
      v.ShrinkTo(99); // less than count
      Fail('Expected EInvalidArgument not raised');
    except
      on E: EInvalidArgument do ;
    end;
  finally
    v.Free;
  end;
end;

procedure TVecShrinkEdges.Test_ShrinkToFit_NoOp_When_Below_Threshold;
var
  v: specialize TVec<Integer>;
  i: Integer;
  cap_before, cap_after: SizeUInt;
begin
  v := specialize TVec<Integer>.Create;
  try
    for i := 1 to 100 do v.Push(i);
    v.Shrink; // capacity := count
    cap_before := v.Capacity;
    v.ShrinkToFit; // below threshold, no-op
    cap_after := v.Capacity;
    AssertEquals(cap_before, cap_after);
  finally
    v.Free;
  end;
end;

procedure RegisterVecShrinkEdgeTests;
begin
  RegisterTest('vec-shrink-edges', TVecShrinkEdges);
end;

end.

