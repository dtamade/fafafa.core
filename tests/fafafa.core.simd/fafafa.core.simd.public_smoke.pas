program fafafa.core.simd.public_smoke;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.base;

function BackendName(b: TSimdBackend): string;
begin
  case b of
    sbScalar: Result := 'Scalar';
    sbSSE2: Result := 'SSE2';
    sbAVX2: Result := 'AVX2';
    sbAVX512: Result := 'AVX512';
    sbNEON: Result := 'NEON';
    sbRISCVV: Result := 'RISCVV';
  else
    Result := 'Unknown';
  end;
end;

procedure Fail(const msg: string);
begin
  WriteLn('[FAIL] ', msg);
  Halt(1);
end;

var
  C: TCPUInfo;
  expected, backend: TSimdBackend;
begin
  C := GetCPUInformation;
  backend := GetCurrentBackend;

  WriteLn('CPU vendor: ', C.Vendor);
  WriteLn('CPU model:  ', C.Model);
  WriteLn('Backend:    ', Ord(backend), ' (', BackendName(backend), ')');

  // Expected default backend preference (when available): AVX2 > SSE2 > Scalar.
  expected := sbScalar;
  {$IFDEF SIMD_X86_AVAILABLE}
  if HasSSE2 then expected := sbSSE2;
  if HasAVX2 then expected := sbAVX2;
  {$ENDIF}

  if backend <> expected then
    Fail('Expected default backend ' + BackendName(expected) + ', got ' + BackendName(backend));

  WriteLn('[PASS] Default backend is ', BackendName(backend));
  Halt(0);
end.
