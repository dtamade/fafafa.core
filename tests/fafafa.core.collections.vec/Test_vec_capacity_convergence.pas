unit Test_vec_capacity_convergence;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.vec;

type
  TTestCase_Vec_CapacityConvergence = class(TTestCase)
  published
    procedure Test_ShrinkToFit_Converges_Deterministically;
  end;

implementation

procedure TTestCase_Vec_CapacityConvergence.Test_ShrinkToFit_Converges_Deterministically;
var
  V: specialize TVec<Integer>;
  CapBefore, Cap1, Cap2: SizeUInt;
begin
  V := specialize TVec<Integer>.Create;
  try
    // 预留较大容量，然后降低 Count 以触发收缩
    V.ResizeExact(0);
    V.ReserveExact(5000);
    V.ResizeExact(1000);

    CapBefore := V.GetCapacity; // 5000
    V.ShrinkToFit;              // 触发收缩策略，预期收缩到 Count（1000）
    Cap1 := V.GetCapacity;
    V.ShrinkToFit;              // 再次收缩应不再改变容量（确定性收敛）
    Cap2 := V.GetCapacity;

    AssertEquals('Precondition: capacity before shrink', Int64(5000), Int64(CapBefore));
    AssertEquals('First ShrinkToFit should shrink to Count', Int64(1000), Int64(Cap1));
    AssertEquals('Second ShrinkToFit should keep capacity unchanged', Int64(Cap1), Int64(Cap2));
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Vec_CapacityConvergence);
end.

