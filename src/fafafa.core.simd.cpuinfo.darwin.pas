unit fafafa.core.simd.cpuinfo.darwin;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

// Detect physical and logical core counts on macOS/BSD via sysctl
function DetectCoreCounts(out Physical, Logical: LongInt): Boolean;

implementation

uses
  BaseUnix;

function DetectCoreCounts(out Physical, Logical: LongInt): Boolean;
var
  mib: array[0..1] of Integer;
  len: size_t;
begin
  Physical := 0;
  Logical := 0;

  // Physical cores
  mib[0] := CTL_HW;
  {$IFDEF DARWIN}
  mib[1] := HW_PHYSICALCPU;
  {$ELSE}
  mib[1] := HW_NCPU;
  {$ENDIF}
  len := SizeOf(Physical);
  if fpSysCtl(@mib, 2, @Physical, @len, nil, 0) <> 0 then
    Physical := 0;

  // Logical cores
  mib[0] := CTL_HW;
  {$IFDEF DARWIN}
  mib[1] := HW_LOGICALCPU;
  {$ELSE}
  mib[1] := HW_NCPU;
  {$ENDIF}
  len := SizeOf(Logical);
  if fpSysCtl(@mib, 2, @Logical, @len, nil, 0) <> 0 then
    Logical := 0;

  if Logical = 0 then
    Logical := fpSysConf(_SC_NPROCESSORS_ONLN);
  if Physical = 0 then
    Physical := Logical;

  if Physical < 1 then Physical := 1;
  if Logical < 1 then Logical := 1;
  Result := (Physical > 0) and (Logical > 0);
end;

end.
