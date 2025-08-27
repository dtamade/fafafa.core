unit test_hash_xxh3_64_seed0_kat;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.crypto;

procedure RegisterTests_XXH3_64_Seed0_KAT;

implementation

type
  TXxh3Seed0Tests = class(TTestCase)
  published
    procedure Test_Basic;
  end;

function RepeatHexPair(const Pair: string; Count: Integer): string;
var
  i: Integer;
begin
  SetLength(Result, Length(Pair) * Count);
  Result := '';
  for i := 1 to Count do
    Result := Result + Pair;
end;

procedure AssertHexEq(const Msg: string; const Bytes: TBytes; const Hex: string);
var
  Expected: TBytes;
begin
  Expected := HexToBytes(Hex);
  fpcunit.TAssert.AssertTrue(Msg + ' length', Length(Bytes) = Length(Expected));
  fpcunit.TAssert.AssertTrue(Msg + ' value', SecureCompare(Bytes, Expected));
end;

procedure Case_OneShot(const HexData: string; const ExpectedHex: string);
var
  Data: TBytes;
  H: TBytes;
begin
  if HexData = '' then
    SetLength(Data, 0)
  else
    Data := HexToBytes(HexData);
  H := XXH3_64Hash(Data, 0);
  AssertHexEq('xxh3_64(seed=0)', H, ExpectedHex);
end;

// Minimal KATs (seed=0). Values taken from known-good reference vectors for coverage buckets.
procedure TXxh3Seed0Tests.Test_Basic;
begin
  // Empty
  Case_OneShot('', '2D06800538D394C2');
  // 1 byte
  Case_OneShot('00', 'C44BDFF4074EECDB');
  // 3 bytes
  Case_OneShot('000102', '5F4299FC161C9CBB');
  // 7 bytes
  Case_OneShot('00010203040506', '0CD2084A62406B69');
  // 15 bytes
  Case_OneShot('000102030405060708090A0B0C0D0E', '55ECEDC2B87BB042');
  // 32 bytes
  Case_OneShot('000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F', '3523581FE96E4C05');
  // 64 bytes
  Case_OneShot(
    '000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F'
    + '202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F',
    '6187EB9089B0ED55');
  // 129 bytes (boundary)
  Case_OneShot(RepeatHexPair('41', 129), '6C88819702F4296A');
  // 240 bytes (boundary)
  Case_OneShot(RepeatHexPair('42', 240), '88487A7B78EA761C');
  // 241 bytes (long path)
  Case_OneShot(RepeatHexPair('43', 241), 'F7925B0694F0FA0E');
  // 4096 bytes
  Case_OneShot(RepeatHexPair('44', 4096), 'DFC8C3AFB85395CD');
end;

procedure RegisterTests_XXH3_64_Seed0_KAT;
begin
  RegisterTest('crypto-hash-xxh3_64-seed0-kat', TXxh3Seed0Tests.Suite);
end;

end.

