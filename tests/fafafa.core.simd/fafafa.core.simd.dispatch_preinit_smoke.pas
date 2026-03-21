program fafafa.core.simd.dispatch_preinit_smoke;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.scalar
  {$IFDEF CPUX86_64}
  , fafafa.core.simd.sse2
  , fafafa.core.simd.sse3
  , fafafa.core.simd.ssse3
  , fafafa.core.simd.sse41
  , fafafa.core.simd.sse42
  , fafafa.core.simd.avx2
  {$ENDIF}
  {$IFDEF CPU386}
  , fafafa.core.simd.sse2.i386
  , fafafa.core.simd.sse3
  , fafafa.core.simd.ssse3
  , fafafa.core.simd.sse41
  , fafafa.core.simd.sse42
  {$ENDIF}
  ;

procedure Fail(const aMessage: string);
begin
  WriteLn('[FAIL] ', aMessage);
  Halt(1);
end;

function BackendName(aBackend: TSimdBackend): string;
begin
  case aBackend of
    sbScalar: Result := 'Scalar';
    sbSSE2: Result := 'SSE2';
    sbSSE3: Result := 'SSE3';
    sbSSSE3: Result := 'SSSE3';
    sbSSE41: Result := 'SSE4.1';
    sbSSE42: Result := 'SSE4.2';
    sbAVX2: Result := 'AVX2';
    sbAVX512: Result := 'AVX512';
    sbNEON: Result := 'NEON';
    sbRISCVV: Result := 'RISCVV';
  else
    Result := 'Unknown';
  end;
end;

procedure CheckBackendMarkedUnavailable(const aBackend: TSimdBackend);
var
  LTable: TSimdDispatchTable;
begin
  if not TryGetRegisteredBackendDispatchTable(aBackend, LTable) then
    Exit;

  if LTable.BackendInfo.Available then
    Fail(BackendName(aBackend) + ' should not remain marked Available after pre-init SetVectorAsmEnabled(False)');
end;

begin
  SetVectorAsmEnabled(False);

  if IsVectorAsmEnabled then
    Fail('Vector asm should stay disabled before first dispatch initialization');

  if GetBestDispatchableBackend <> sbScalar then
    Fail('Best dispatchable backend should be Scalar after pre-init SetVectorAsmEnabled(False), got ' +
      BackendName(GetBestDispatchableBackend));

  if GetActiveBackend <> sbScalar then
    Fail('Active backend should be Scalar after pre-init SetVectorAsmEnabled(False), got ' +
      BackendName(GetActiveBackend));

  {$IFDEF CPUX86_64}
  CheckBackendMarkedUnavailable(sbAVX2);
  CheckBackendMarkedUnavailable(sbSSE42);
  CheckBackendMarkedUnavailable(sbSSE41);
  CheckBackendMarkedUnavailable(sbSSSE3);
  CheckBackendMarkedUnavailable(sbSSE3);
  CheckBackendMarkedUnavailable(sbSSE2);
  {$ENDIF}
  {$IFDEF CPU386}
  CheckBackendMarkedUnavailable(sbSSE42);
  CheckBackendMarkedUnavailable(sbSSE41);
  CheckBackendMarkedUnavailable(sbSSSE3);
  CheckBackendMarkedUnavailable(sbSSE3);
  CheckBackendMarkedUnavailable(sbSSE2);
  {$ENDIF}

  WriteLn('[PASS] pre-init vector-asm toggle updated dispatchable backend selection');
end.
