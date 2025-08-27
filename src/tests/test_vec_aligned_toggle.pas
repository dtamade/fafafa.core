unit test_vec_aligned_toggle;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.vec;

procedure RegisterVecAlignedToggleTests;

implementation

type
  TVecAlignedToggle = class(TTestCase)
  published
    procedure Test_Enable_Disable_AlignedGrowth;
  end;

procedure TVecAlignedToggle.Test_Enable_Disable_AlignedGrowth;
var
  v: specialize TVec<Integer>;
  cap0, cap1: SizeUInt;
begin
  v := specialize TVec<Integer>.Create;
  try
    v.Reserve(10);
    cap0 := v.Capacity;
    AssertFalse(v.IsAlignedGrowthEnabled);

    v.EnableAlignedGrowth(64);
    AssertTrue(v.IsAlignedGrowthEnabled);

    v.Reserve(1000);
    cap1 := v.Capacity;
    AssertTrue(cap1 mod 64 = 0);

    v.DisableAlignedGrowth;
    AssertFalse(v.IsAlignedGrowthEnabled);

    // After disabling, a further reserve should not be forced to alignment
    v.Reserve(cap1 + 1);
    AssertTrue(v.Capacity >= cap1 + 1);
  finally
    v.Free;
  end;
end;

procedure RegisterVecAlignedToggleTests;
begin
  RegisterTest('vec-aligned-toggle', TVecAlignedToggle);
end;

end.

