unit Test_vec_growstrategy_interface_regression;
{$MODE OBJFPC}{$H+}

interface
uses
  fpcunit, testregistry,
  fafafa.core.collections.vec,
  fafafa.core.collections.base;

type
  TTestCase_Vec_GrowStrategy_Interface_Regression = class(TTestCase)
  published
    procedure Test_FirstReserve_Respects_CustomInterfaceLowerBound;
  end;

implementation

type
  // 自定义 IGrowthStrategy：返回 aRequiredSize + 7 的下界
  TTestIGrowthStrategy = class(TInterfacedObject, IGrowthStrategy)
  public
    function GetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt;
  end;

function TTestIGrowthStrategy.GetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt;
begin
  if aRequiredSize + 7 > aRequiredSize then
    Result := aRequiredSize + 7
  else
    Result := High(SizeUInt); // 防溢出保护（理论上到不了）
end;

procedure TTestCase_Vec_GrowStrategy_Interface_Regression.Test_FirstReserve_Respects_CustomInterfaceLowerBound;
var
  V: specialize TVec<Integer>;
  OldCap: SizeUInt;
begin
  V := specialize TVec<Integer>.Create;
  try
    // 显式转换为 IGrowthStrategy，避免编译器在不同构建模式下的隐式解析差异
    V.SetGrowStrategy(IGrowthStrategy(TTestIGrowthStrategy.Create));
    OldCap := V.Capacity;
    V.Reserve(10);
    AssertTrue('Capacity should increase by at least required (10)', V.Capacity >= OldCap + 10);
    AssertTrue('Custom IGrowthStrategy lower bound should be respected (>= 17 for first reserve of 10)', V.Capacity >= 17);
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Vec_GrowStrategy_Interface_Regression);
end.

