{
  HKDF test vectors for fafafa.core.crypto (RFC 5869)
}

unit Test_hkdf_vectors;

{$mode objfpc}{$H+}
{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}


interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.crypto;

type
  { TTestCase_HKDF_Vectors }
  TTestCase_HKDF_Vectors = class(TTestCase)
  published
    procedure Test_HKDF_SHA256_RFC5869_TC1; // Full vector
    procedure Test_HKDF_SHA256_RFC5869_TC2; // Full vector

  end;

implementation

function HexToBytes(const S: string): TBytes;
var
  I, N: Integer;
  H: string;
begin
  H := LowerCase(Trim(StringReplace(S, ' ', '', [rfReplaceAll])));
  N := Length(H) div 2;
  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := StrToInt('$' + Copy(H, I * 2 + 1, 2));
end;

procedure AssertBytesEqual(const ExpectedHex: string; const Actual: TBytes);
var
  Expected: TBytes;
  I: Integer;
begin
  Expected := HexToBytes(ExpectedHex);
  if Length(Expected) <> Length(Actual) then
    raise Exception.CreateFmt('len mismatch: exp=%d got=%d', [Length(Expected), Length(Actual)]);
  for I := 0 to High(Expected) do
    if Expected[I] <> Actual[I] then
      raise Exception.CreateFmt('byte[%d] mismatch: exp=%d got=%d', [I, Expected[I], Actual[I]]);
end;

procedure TTestCase_HKDF_Vectors.Test_HKDF_SHA256_RFC5869_TC1;
var
  IKM, Salt, Info, OKM: TBytes;
begin
  // RFC 5869 Appendix A.1 Test Case 1 (SHA-256)
  // IKM: 0x0b repeated 22 times
  IKM := HexToBytes('0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b');
  Salt := HexToBytes('000102030405060708090a0b0c');
  Info := HexToBytes('f0f1f2f3f4f5f6f7f8f9');
  OKM := HKDF_SHA256(IKM, Salt, Info, 42);
  AssertBytesEqual(
    '3cb25f25faacd57a90434f64d0362f2a'
  + '2d2d0a90cf1a5a4c5db02d56ecc4c5bf'
  + '34007208d5b887185865',
    OKM);
end;

procedure TTestCase_HKDF_Vectors.Test_HKDF_SHA256_RFC5869_TC2;
var
  IKM, Salt, Info, OKM: TBytes;
begin
  // RFC 5869 Appendix A.2 Test Case 2 (SHA-256)
  // IKM: 0x00..0x4f (80 bytes)
  IKM := HexToBytes(
    '000102030405060708090a0b0c0d0e0f'
  + '101112131415161718191a1b1c1d1e1f'
  + '202122232425262728292a2b2c2d2e2f'
  + '303132333435363738393a3b3c3d3e3f'
  + '404142434445464748494a4b4c4d4e4f');
  // Salt: 0x60..0x7f (20 bytes?) -> RFC A.2 uses 80 bytes 0x60..0x7f
  Salt := HexToBytes(
    '606162636465666768696a6b6c6d6e6f'
  + '707172737475767778797a7b7c7d7e7f'
  + '808182838485868788898a8b8c8d8e8f'
  + '909192939495969798999a9b9c9d9e9f'
  + 'a0a1a2a3a4a5a6a7a8a9aaabacadaeaf');
  // Info: 0xb0..0xbf repeated to 80 bytes per RFC
  Info := HexToBytes(
    'b0b1b2b3b4b5b6b7b8b9babbbcbdbebf'
  + 'c0c1c2c3c4c5c6c7c8c9cacbcccdcecf'
  + 'd0d1d2d3d4d5d6d7d8d9dadbdcdddedf'
  + 'e0e1e2e3e4e5e6e7e8e9eaebecedeeef'
  + 'f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff');
  OKM := HKDF_SHA256(IKM, Salt, Info, 82);
  AssertBytesEqual(
    'b11e398dc80327a1c8e7f78c596a4934'
  + '4f012eda2d4efad8a050cc4c19afa97c'
  + '59045a99cac7827271cb41c65e590e09'
  + 'da3275600c2f09b8367793a9aca3db71'
  + 'cc30c58179ec3e87c14c01d5c1f3434f'
  + '1d87',
    OKM);
end;


initialization
  RegisterTest(TTestCase_HKDF_Vectors);

end.

{$POP}

