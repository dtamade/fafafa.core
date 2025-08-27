unit fafafa.core.simd.bit.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd;

type
  TTestCase_Bit = class(TTestCase)
  published
    procedure Test_PopCount_TailBits_NotAligned;
  end;

implementation

procedure TTestCase_Bit.Test_PopCount_TailBits_NotAligned;
var
  buf: array[0..1] of Byte; // 16 bits
  c: SizeUInt;
begin
  // 低位优先（与实现一致）：前 3 位为 0b001 => 1 个 1
  buf[0] := $01; buf[1] := $00;
  c := BitsetPopCount(@buf[0], 3);
  AssertTrue('popcount 3 bits', c = 1);

  // 前 9 位：低 8 位含 1 个 1，下一字节最低位也为 1 => 共 2 个 1
  buf[0] := $01; buf[1] := $01;
  c := BitsetPopCount(@buf[0], 9);
  AssertTrue('popcount 9 bits', c = 2);
end;

initialization
  RegisterTest(TTestCase_Bit);

end.

