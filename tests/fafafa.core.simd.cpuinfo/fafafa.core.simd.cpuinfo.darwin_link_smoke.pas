program fafafa_core_simd_cpuinfo_darwin_link_smoke;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.base;

var
  LInfo: TCPUInfo;
begin
  LInfo := GetCPUInfo;
  if LInfo.Arch = caUnknown then
    Halt(0);
end.
