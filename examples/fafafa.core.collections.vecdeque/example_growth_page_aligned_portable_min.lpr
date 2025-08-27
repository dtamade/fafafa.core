program example_growth_page_aligned_portable_min;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

function GetPreferredPageAlign: SizeUInt;
begin
  {$IFDEF WINDOWS}
  // Windows 常见分配粒度 64KiB（VirtualAlloc 区域对齐）
  Result := 64 * 1024;
  {$ELSE}
  // 其他平台默认 4KiB 页面对齐
  Result := 4096;
  {$ENDIF}
end;

function IsPowerOfTwo(v: QWord): Boolean;
begin
  Result := (v > 0) and ((v and (v - 1)) = 0);
end;

var
  D: specialize TVecDeque<Integer>;
  Base: TGrowthStrategy;
  Aligned: TGrowthStrategy;
  AlignSize: SizeUInt;
  BeforeCap, AfterCap: SizeUInt;
  i: Integer;
begin
  AlignSize := GetPreferredPageAlign;

  D := specialize TVecDeque<Integer>.Create;
  try
    for i := 1 to 256 do D.PushBack(i);
    BeforeCap := D.GetCapacity;

    Base := TGoldenRatioGrowStrategy.GetGlobal;
    Aligned := TAlignedWrapperStrategy.Create(Base, AlignSize);
    D.SetGrowStrategy(Aligned);

    for i := 257 to 200000 do D.PushBack(i);
    AfterCap := D.GetCapacity;

    WriteLn('AlignSize=', AlignSize, ' BeforeCap=', BeforeCap, ' AfterCap=', AfterCap);
    if not IsPowerOfTwo(AfterCap) then
      raise Exception.Create('AfterCap not power-of-two');
    if (AfterCap mod AlignSize) <> 0 then
      raise Exception.Create('AfterCap not multiple of preferred align');
    if AfterCap < D.GetCount then
      raise Exception.Create('AfterCap < Count');

    WriteLn('OK');
  finally
    D.Free;
  end;
end.

