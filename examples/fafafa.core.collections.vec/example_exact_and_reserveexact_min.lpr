program example_exact_and_reserveexact_min;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vec;

type
  TIntVec = specialize TVec<Integer>;

var
  V: TIntVec;
  Cap0, Cap1, Cap2: SizeUInt;
  Exact: TGrowthStrategy;
  i: Integer;

begin
  V := TIntVec.Create;
  try
    Cap0 := V.GetCapacity;

    // 1) 使用 Exact 策略，确保增长严格等于需求
    Exact := TExactGrowStrategy.GetGlobal;
    V.SetGrowStrategy(Exact);

    // ReserveExact: 尽量满足 Count + n（实现可做最小对齐，但不强制 2 的幂）
    V.ReserveExact(1000);
    Cap1 := V.GetCapacity;

    if Cap1 < V.GetCount then
      raise Exception.Create('Cap1 < Count after ReserveExact');

    // 写入并再次 ReserveExact
    for i := 1 to 1000 do V.Push(i);
    V.ReserveExact(2000 - V.GetCount);
    Cap2 := V.GetCapacity;

    if (Cap2 < 2000) then
      raise Exception.Create('Cap2 does not reach 2000 with ReserveExact');

    WriteLn('Cap0=', Cap0, ' Cap1=', Cap1, ' Cap2=', Cap2, ' Count=', V.GetCount);
    WriteLn('OK');
  finally
    V.Free;
  end;
end.

