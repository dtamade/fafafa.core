program example_growth_interface_based_min;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

var
  D: specialize TVecDeque<Integer>;
  Obj: TGrowthStrategy;
  Intf: IGrowthStrategy;
  BeforeCap, AfterCap: SizeUInt;
  i: Integer;

function IsPowerOfTwo(v: QWord): Boolean;
begin
  Result := (v > 0) and ((v and (v - 1)) = 0);
end;

begin
  D := specialize TVecDeque<Integer>.Create;
  Obj := nil;
  try
    for i := 1 to 128 do D.PushBack(i);
    BeforeCap := D.GetCapacity;

    Obj  := TAlignedWrapperStrategy.Create(TGoldenRatioGrowStrategy.GetGlobal, 64);
    Intf := TGrowthStrategyInterfaceView.Create(Obj);
    D.SetGrowStrategyI(Intf);

    for i := 129 to 8000 do D.PushBack(i);
    AfterCap := D.GetCapacity;

    WriteLn('BeforeCap=', BeforeCap, ' AfterCap=', AfterCap);
    if not IsPowerOfTwo(AfterCap) then
      raise Exception.Create('AfterCap not power-of-two');
    if AfterCap < D.GetCount then
      raise Exception.Create('AfterCap < Count');

    WriteLn('OK');
  finally
    D.Free;
    if Assigned(Obj) then Obj.Free;
  end;
end.

