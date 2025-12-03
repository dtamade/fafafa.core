program example_growth_page_aligned_min;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

var
  D: specialize TVecDeque<Integer>;
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

    // TAlignedWrapperStrategy 接受 IGrowthStrategy，生命周期由接口引用计数管理
    D.SetGrowStrategy(TAlignedWrapperStrategy.Create(GoldenRatioGrow, 4096));

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

