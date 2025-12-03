program example_growth_hugepage_aligned_min;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

const
  HUGE_PAGE = 2097152; // 2 MiB

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
    for i := 1 to 1024 do D.PushBack(i);
    BeforeCap := D.GetCapacity;

    // TAlignedWrapperStrategy 接受 IGrowthStrategy，生命周期由接口引用计数管理
    D.SetGrowStrategy(TAlignedWrapperStrategy.Create(GoldenRatioGrow, HUGE_PAGE));

    for i := 1025 to (HUGE_PAGE div 2) do D.PushBack(i); // 触发较大扩容
    AfterCap := D.GetCapacity;

    WriteLn('BeforeCap=', BeforeCap, ' AfterCap=', AfterCap);
    if not IsPowerOfTwo(AfterCap) then
      raise Exception.Create('AfterCap not power-of-two');
    if (AfterCap mod HUGE_PAGE) <> 0 then
      raise Exception.Create('AfterCap not multiple of 2MiB');
    if AfterCap < D.GetCount then
      raise Exception.Create('AfterCap < Count');

    WriteLn('OK');
  finally
    D.Free;
  end;
end.

