program fafafa.core.simd.public_smoke;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.runtime,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.public_smoke_support;

procedure Fail(const aMessage: string);
begin
  WriteLn('[FAIL] ', aMessage);
  Halt(1);
end;

function PublicSmokeBackendName(const aBackend: TSimdBackend): string;
begin
  Result := GetBackendInfo(aBackend).Name;
end;

var
  LCpuInfo: TCPUInfo;
  LBackend: TSimdBackend;
  LExpectedBackend: TSimdBackend;
  LRuntimeSnapshot: TSimdRuntimeSnapshot;
begin
  LCpuInfo := GetCPUInfo;
  LRuntimeSnapshot := GetCurrentRuntimeSnapshot;
  LBackend := LRuntimeSnapshot.CurrentBackend;

  WriteLn('CPU vendor: ', LCpuInfo.Vendor);
  WriteLn('CPU model:  ', LCpuInfo.Model);
  WriteLn('Backend:    ', PublicSmokeBackendName(LBackend));

  // Expected default backend preference follows the same canonical
  // dispatchable semantics used by the runtime selector.
  LExpectedBackend := GetExpectedPublicSmokeDefaultBackend;

  if LBackend <> LExpectedBackend then
    Fail('Expected default backend ' + PublicSmokeBackendName(LExpectedBackend) +
      ', got ' + PublicSmokeBackendName(LBackend));

  WriteLn('[PASS] Default backend is ', PublicSmokeBackendName(LBackend));
  Halt(0);
end.
