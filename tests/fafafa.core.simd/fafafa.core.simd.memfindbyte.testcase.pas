unit fafafa.core.simd.memfindbyte.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd, fafafa.core.simd.mem;

type
  TTestCase_MemFindByte_Compare = class(TTestCase)
  private
    procedure AssertSameIdx(const buf: array of Byte; const v: Byte);
  published
    procedure Test_SSE2_vs_Scalar_SweepValues;
    procedure Test_SSE2_vs_Scalar_RandomCases;
  end;

implementation

procedure TTestCase_MemFindByte_Compare.AssertSameIdx(const buf: array of Byte; const v: Byte);
var
  idxScalar, idxSSE2: PtrInt;
  len: SizeUInt;
begin
  len := Length(buf);
  idxScalar := MemFindByte_Scalar(@buf[0], len, v);
  {$IFDEF CPUX86_64}
  idxSSE2 := MemFindByte_SSE2(@buf[0], len, v);
  {$ELSE}
  idxSSE2 := idxScalar;
  {$ENDIF}
  AssertTrue(Format('value=%d scalar=%d sse2=%d', [v, idxScalar, idxSSE2]), idxScalar = idxSSE2);
end;

procedure TTestCase_MemFindByte_Compare.Test_SSE2_vs_Scalar_SweepValues;
var
  a: array[0..255] of Byte;
  i: Integer;
begin
  for i:=0 to High(a) do a[i] := i;
  for i:=0 to 255 do
    AssertSameIdx(a, Byte(i));
end;

procedure TTestCase_MemFindByte_Compare.Test_SSE2_vs_Scalar_RandomCases;
var
  a: array[0..511] of Byte;
  i, t: Integer;
  rnd: QWord;
  v: Byte;
begin
  rnd := 1469598103934665603; // FNV offset as seed
  for t:=1 to 64 do
  begin
    // simple xorshift64*
    rnd := rnd xor (rnd shl 13);
    rnd := rnd xor (rnd shr 7);
    rnd := rnd xor (rnd shl 17);
    for i:=0 to High(a) do
      a[i] := Byte((rnd + QWord(i*1315423911)) and $FF);
    v := Byte(rnd and $FF);
    AssertSameIdx(a, v);
  end;
end;

initialization
  RegisterTest(TTestCase_MemFindByte_Compare);

end.

