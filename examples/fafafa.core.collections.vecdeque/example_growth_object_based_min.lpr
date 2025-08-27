program example_growth_object_based_min;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

var
  D: specialize TVecDeque<Integer>;
  Base: TGrowthStrategy;
  Aligned: TGrowthStrategy;
  BeforeCap, AfterCap: SizeUInt;
  i: Integer;

function IsPowerOfTwo(v: QWord): Boolean;
begin
  Result := (v > 0) and ((v and (v - 1)) = 0);
end;

begin
  D := specialize TVecDeque<Integer>.Create;
  Aligned := nil;
  try
    for i := 1 to 64 do D.PushBack(i);
    BeforeCap := D.GetCapacity;

    Base := TGoldenRatioGrowStrategy.GetGlobal;
    Aligned := TAlignedWrapperStrategy.Create(Base, 64);
    D.SetGrowStrategy(Aligned);

    for i := 65 to 6000 do D.PushBack(i);
    AfterCap := D.GetCapacity;

    WriteLn('BeforeCap=', BeforeCap, ' AfterCap=', AfterCap);
    if not IsPowerOfTwo(AfterCap) then
      raise Exception.Create('AfterCap not power-of-two');
    if AfterCap < D.GetCount then
      raise Exception.Create('AfterCap < Count');

    WriteLn('OK');
  finally
    D.Free;
    if Assigned(Aligned) then Aligned.Free;
  end;
end.

