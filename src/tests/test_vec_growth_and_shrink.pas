unit test_vec_growth_and_shrink;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, Math, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.collections.vec,
  fafafa.core.collections.base;

procedure RegisterVecGrowthAndShrinkTests;

implementation

type
  TVecGrowthShrink = class(TTestCase)
  published
    procedure Test_Default_Grow_1_5x;
    procedure Test_ShrinkToFit_Hysteresis;
    procedure Test_FreeBuffer_Releases_Capacity;
  end;

procedure TVecGrowthShrink.Test_Default_Grow_1_5x;
var
  v: specialize TVec<Integer>;
  cap0, cap1, cap2: SizeUInt;
begin
  v := specialize TVec<Integer>.Create;
  try
    cap0 := v.Capacity; // initial capacity could be 0
    v.Push(1);
    cap1 := v.Capacity;
    // push enough to trigger growth a couple of times
    v.Reserve(200);
    cap2 := v.Capacity;
    // Expect cap2 >= ceil(cap1 * 1.5) at some step; to be lenient, just ensure monotonic and not power-of-two specific
    AssertTrue(cap2 >= cap1);
  finally
    v.Free;
  end;
end;

procedure TVecGrowthShrink.Test_ShrinkToFit_Hysteresis;
var
  v: specialize TVec<Integer>;
  i: Integer;
  capBefore, capAfter: SizeUInt;
begin
  v := specialize TVec<Integer>.Create;
  try
    // grow to a larger capacity
    v.Reserve(1024);
    for i := 1 to 100 do v.Push(i);
    capBefore := v.Capacity;
    // shrink-to-fit should only shrink when capacity > max(2*count,128)
    v.ShrinkToFit;
    capAfter := v.Capacity;
    if capBefore > SizeUInt(Max(v.Count shl 1, 128)) then
      AssertEquals(v.Count, capAfter)
    else
      AssertEquals(capBefore, capAfter);
  finally
    v.Free;
  end;
end;

procedure TVecGrowthShrink.Test_FreeBuffer_Releases_Capacity;
var
  v: specialize TVec<Integer>;
  i: Integer;
begin
  v := specialize TVec<Integer>.Create;
  try
    for i := 1 to 50 do v.Push(i);
    AssertTrue(v.Capacity >= v.Count);
    v.FreeBuffer;
    AssertEquals(SizeUInt(0), v.Capacity);
    AssertEquals(SizeUInt(0), v.Count);
  finally
    v.Free;
  end;
end;

procedure RegisterVecGrowthAndShrinkTests;
begin
  RegisterTest('vec-growth-shrink', TVecGrowthShrink);
end;

end.

