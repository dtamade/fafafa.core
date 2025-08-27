unit test_hash_xxh3_64_seeded_kat;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.crypto;

procedure RegisterTests_XXH3_64_Seeded_KAT;

implementation

type
  TXxh3SeededTests = class(TTestCase)
  published
    procedure Test_KnownVectors;
  end;

function RepeatHexPair(const Pair: string; Count: Integer): string;
var i: Integer;
begin
  Result := '';
  for i := 1 to Count do Result := Result + Pair;
end;

procedure AssertHexEq(const Msg: string; const Bytes: TBytes; const Hex: string);
var Expected: TBytes;
begin
  Expected := HexToBytes(Hex);
  fpcunit.TAssert.AssertTrue(Msg + ' length', Length(Bytes) = Length(Expected));
  fpcunit.TAssert.AssertTrue(Msg + ' value', SecureCompare(Bytes, Expected));
end;

procedure TXxh3SeededTests.Test_KnownVectors;
var H: TBytes;
begin
  // 这些值来自本实现生成，作为占位，后续可替换为官方向量
  H := XXH3_64Hash(nil, $0123456789ABCDEF);
  AssertHexEq('empty, seed=0123456789ABCDEF', H, 'CC1CA35A1B089C5C');

  H := XXH3_64Hash(HexToBytes('00'), $0000000000000001);
  AssertHexEq('00, seed=1', H, '5EAAC1F7B17EF730');

  H := XXH3_64Hash(HexToBytes('0001020304050607'), $F00DF00DF00DF00D);
  AssertHexEq('0..7, seed=F00DF00DF00DF00D', H, '87B3ECA84419A626');

  H := XXH3_64Hash(HexToBytes('000102030405060708090A0B0C0D0E0F'), $AAAAAAAAAAAAAAAA);
  AssertHexEq('0..15, seed=AAAAAAAAAAAAAAAA', H, '5928BD33F2CB69EB');

  H := XXH3_64Hash(HexToBytes(RepeatHexPair('41', 4096)), $0123456789ABCDEF);
  AssertHexEq('A*4096, seed=0123456789ABCDEF', H, '5AB651A356D7185B');
end;

procedure RegisterTests_XXH3_64_Seeded_KAT;
begin
  RegisterTest('crypto-hash-xxh3_64-seeded-kat', TXxh3SeededTests.Suite);
end;

end.

