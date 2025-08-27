unit test_vec_aligned_growth;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.vec;

procedure RegisterVecAlignedGrowthTests;

implementation

type
  TVecAlignedGrowth = class(TTestCase)
  published
    procedure Test_EnableAlignedGrowth_Aligns_Capacity;
  end;

procedure TVecAlignedGrowth.Test_EnableAlignedGrowth_Aligns_Capacity;
var
  v: specialize TVec<Byte>;
  before, after1, after2: SizeUInt;
begin
  v := specialize TVec<Byte>.Create;
  try
    v.Reserve(10);
    before := v.Capacity;
    v.EnableAlignedGrowth(64);
    v.Reserve(1000);
    after1 := v.Capacity;
    // capacity should be multiple of (alignElements * sizeof(T)) which is 64 for Byte
    AssertTrue(after1 mod 64 = 0);
    // do another reserve to ensure alignment persists
    v.Reserve(37);
    after2 := v.Capacity;
    AssertTrue(after2 mod 64 = 0);
  finally
    v.Free;
  end;
end;

procedure RegisterVecAlignedGrowthTests;
begin
  RegisterTest('vec-aligned-growth', TVecAlignedGrowth);
end;

end.

