program example_growth_page_aligned_min;
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
  try
    for i := 1 to 128 do D.PushBack(i);
    BeforeCap := D.GetCapacity;

    Base := TGoldenRatioGrowStrategy.GetGlobal;
    Aligned := TAlignedWrapperStrategy.Create(Base, 4096);
    D.SetGrowStrategy(Aligned);

    for i := 129 to 160000 do D.PushBack(i);
    AfterCap := D.GetCapacity;

    WriteLn('BeforeCap=', BeforeCap, ' AfterCap=', AfterCap);
    if not IsPowerOfTwo(AfterCap) then
      raise Exception.Create('AfterCap not power-of-two');
    if (AfterCap mod 4096) <> 0 then
      raise Exception.Create('AfterCap not multiple of 4096');
    if AfterCap < D.GetCount then
      raise Exception.Create('AfterCap < Count');

    WriteLn('OK');
  finally
    D.Free;
  end;
end.

