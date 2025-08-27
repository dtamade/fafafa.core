unit fafafa.core.simd.search.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd, fafafa.core.simd.types;

type
  TTestCase_Search = class(TTestCase)
  private
    procedure RunIndexOfCase(const haySize, nlen: SizeUInt; const posKind: Integer);
  published
    procedure Test_BytesIndexOf_Matrix;
    procedure Test_BytesIndexOf_EmptyNeedle_Returns0;
  end;

implementation

procedure TTestCase_Search.RunIndexOfCase(const haySize, nlen: SizeUInt; const posKind: Integer);
var
  hay, ned: TBytes;
  idxExpected, idxActual: PtrInt;
  i: SizeUInt;
  pos: SizeUInt;
begin
  // posKind: 0=head, 1=middle, 2=tail, 3=notfound
  SetLength(hay, haySize);
  FillChar(hay[0], haySize, 0);

  if nlen = 0 then
  begin
    idxActual := BytesIndexOf(@hay[0], haySize, nil, 0);
    AssertTrue('nlen=0 => 0', idxActual = 0);
    Exit;
  end;

  if nlen > haySize then
  begin
    // Expect -1
    SetLength(ned, nlen);
    for i:=0 to nlen-1 do ned[i] := Byte(1 + (i and $7F));
    idxActual := BytesIndexOf(@hay[0], haySize, @ned[0], nlen);
    AssertTrue('nlen>len => -1', idxActual = -1);
    Exit;
  end;

  SetLength(ned, nlen);
  for i:=0 to nlen-1 do ned[i] := Byte(1 + (i and $7F));

  if posKind = 3 then
  begin
    // not found: hay all zeros, needle non-zero
    idxExpected := -1;
  end
  else
  begin
    case posKind of
      0: pos := 0;
      1: if haySize > nlen then pos := (haySize div 2) - (nlen div 2) else pos := 0;
      2: pos := haySize - nlen;
    else
      pos := 0;
    end;
    // place needle
    Move(ned[0], hay[pos], nlen);
    idxExpected := PtrInt(pos);
  end;

  idxActual := BytesIndexOf(@hay[0], haySize, @ned[0], nlen);
  AssertTrue(Format('IndexOf size=%d nlen=%d kind=%d', [haySize, nlen, posKind]), idxActual = idxExpected);
end;

procedure TTestCase_Search.Test_BytesIndexOf_Matrix;
const
  Sizes: array[0..2] of SizeUInt = (64, 1024, 65536);
  NLens: array[0..11] of SizeUInt = (1,2,3,4,7,8,15,16,17,31,32,33);
var
  si, ni, kind: Integer;
begin
  for si:=0 to High(Sizes) do
    for ni:=0 to High(NLens) do
      for kind:=0 to 3 do
        RunIndexOfCase(Sizes[si], NLens[ni], kind);
end;

procedure TTestCase_Search.Test_BytesIndexOf_EmptyNeedle_Returns0;
var
  hay: array[0..15] of Byte;
  idx: PtrInt;
begin
  FillChar(hay, SizeOf(hay), 0);
  idx := BytesIndexOf(@hay[0], SizeOf(hay), nil, 0);
  AssertTrue('empty needle => 0', idx = 0);
end;

initialization
  RegisterTest(TTestCase_Search);

end.

