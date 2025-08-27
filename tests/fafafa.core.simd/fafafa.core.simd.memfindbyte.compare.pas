program memfindbyte_compare;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}
uses SysUtils, fafafa.core.simd, fafafa.core.simd.mem;

procedure RunOne;
var a: array[0..63] of Byte; i: Integer; idxSSE2, idxScalar: PtrInt; v: Byte;
begin
  for i:=0 to High(a) do a[i] := i;
  v := 7;
  // 强制 SCALAR
  SimdSetForcedProfile('SCALAR');
  idxScalar := MemFindByte_Scalar(@a[0], Length(a), v);
  // 强制 SSE2
  SimdSetForcedProfile('SSE2');
  idxSSE2 := MemFindByte_SSE2(@a[0], Length(a), v);
  Writeln('scalar=', idxScalar, ' sse2=', idxSSE2);
end;

begin
  RunOne;
end.

