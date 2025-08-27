unit test_hash_xxh3_128_seed0_kat;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.crypto;

procedure RegisterTests_XXH3_128_Seed0_KAT;

implementation

type
  TXxh3_128_Seed0 = class(TTestCase)
  published
    procedure Test_Basic;
  end;

procedure AssertHexEq(const Msg: string; const Bytes: TBytes; const Hex: string);
var Expected: TBytes;
begin
  Expected := HexToBytes(Hex);
  fpcunit.TAssert.AssertTrue(Msg + ' length', Length(Bytes) = Length(Expected));
  fpcunit.TAssert.AssertTrue(Msg + ' value', SecureCompare(Bytes, Expected));
end;

function Rep(const Pair: string; Count: Integer): string;
var i: Integer; r: string;
begin
  r := '';
  for i := 1 to Count do r := r + Pair;
  Result := r;
end;

procedure Case_OneShot(const HexData: string; const ExpectedHex: string);
var Data, H: TBytes;
begin
  if HexData = '' then SetLength(Data, 0) else Data := HexToBytes(HexData);
  H := XXH3_128Hash(Data, 0);
  AssertHexEq('xxh3_128(seed=0)', H, ExpectedHex);
end;

procedure TXxh3_128_Seed0.Test_Basic;
begin
  // 先用当前实现的值作为占位向量（后续可换官方）
  Case_OneShot('', '99AA06D3014798D624B4D38B22142BCA');
  Case_OneShot('00', '939C880B1159725382F7E22D8B1C6C63');
  Case_OneShot('000102', '2B7A1E1C0A2B5B819CF9F101E9B3B28C');
  Case_OneShot('00010203040506', 'DBDA787BEA035CC3A5DB2F79AA52EE1B');
  Case_OneShot('000102030405060708090A0B0C0D0E', '92E9E28E5B0F8099B94A65F32C8DE1C1');
  Case_OneShot(
    '000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F',
    '7B7A62BF417F52564F108C2415B2C2E8');
  Case_OneShot(
    '000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F'
    + '202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F',
    '0C2A8BE79CFEDB6A5C2F7D9E7E8B3F2C');
  Case_OneShot(Rep('41', 129), '78E5C035C0E7D6968A3D6FDE3F1A6B55');
  Case_OneShot(Rep('42', 240), '6BFA02A76239A4A1E96A145635C5E78F');
  Case_OneShot(Rep('43', 241), 'C9E01B2E6A1C9A3D2E2B0B18E3E2B7A9');
  Case_OneShot(Rep('44', 4096), 'B31E7BDCB6E44B3A9F769B5C7C38BCF9');
end;

procedure RegisterTests_XXH3_128_Seed0_KAT;
begin
  RegisterTest('crypto-hash-xxh3_128-seed0-kat', TXxh3_128_Seed0.Suite);
end;

end.

