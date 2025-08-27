unit Test_vec_trimtosize_alias;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.vec;

type
  TTestCase_Vec_TrimToSize_Alias = class(TTestCase)
  published
    procedure Test_TrimToSize_Delegates_To_ShrinkToFit;
  end;

implementation

procedure TTestCase_Vec_TrimToSize_Alias.Test_TrimToSize_Delegates_To_ShrinkToFit;
var
  V: specialize TVec<Integer>;
  CapBefore, CapAfter: SizeUInt;
begin
  V := specialize TVec<Integer>.Create;
  try
    V.ResizeExact(0);
    V.ReserveExact(5000);
    V.ResizeExact(1000);

    CapBefore := V.GetCapacity; // 5000

    V.TrimToSize; // 应与 ShrinkToFit 等效

    CapAfter := V.GetCapacity;
    AssertEquals('TrimToSize should shrink down to Count', Int64(1000), Int64(CapAfter));
    AssertEquals('Precondition: capacity should be 5000 before shrink', Int64(5000), Int64(CapBefore));
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Vec_TrimToSize_Alias);
end.

