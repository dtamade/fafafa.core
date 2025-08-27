{$CODEPAGE UTF8}
unit fafafa.core.crypto.xxhash.vectors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, testutils,
  fafafa.core.crypto;

type
  TTestCase_XXHash_Vectors = class(TTestCase)
  published
    procedure Test_XXH32_Spec_Vectors_Seed0;
    procedure Test_XXH32_Spec_Vectors_SeedPrime;
    procedure Test_XXH32_Boundary_Lengths;
    procedure Test_XXH64_Spec_Vectors_Seed0;
    procedure Test_XXH64_Spec_Vectors_SeedPrime32;
    procedure Test_XXH64_Boundary_Lengths;
  end;

implementation

const
  PRIME32 = UInt32(2654435761);
  PRIME64 = QWord(11400714785074694797);
  SEED32_PRIME = UInt32($9E3779B1);
  SEED64_PRIME32EXT = QWord($000000009E3779B1);

procedure FillTestBuffer(var Buf: TBytes; Len: SizeInt);
var i: SizeInt; byteGen: QWord;
begin
  SetLength(Buf, Len);
  if Len = 0 then Exit;
  byteGen := PRIME32;
  for i := 0 to Len-1 do begin
    Buf[i] := Byte(byteGen shr 56);
    byteGen := byteGen * PRIME64;
  end;
end;

procedure ExpectHashHex32(const Len: Integer; Seed: UInt32; const ExpectedHexLower: string);
var buf: TBytes; got: TBytes;
begin
  FillTestBuffer(buf, Len);
  got := XXH32Hash(buf, Seed);
  fpcunit.TAssert.AssertEquals(Format('xxh32 len=%d seed=%u', [Len, Seed]), ExpectedHexLower, BytesToHex(got));
end;

procedure ExpectHashHex64(const Len: Integer; Seed: QWord; const ExpectedHexLower: string);
var buf: TBytes; got: TBytes;
begin
  FillTestBuffer(buf, Len);
  got := XXH64Hash(buf, Seed);
  fpcunit.TAssert.AssertEquals(Format('xxh64 len=%d seed=%s', [Len, IntToHex(Seed, 16)]), ExpectedHexLower, BytesToHex(got));
end;

procedure TTestCase_XXHash_Vectors.Test_XXH32_Spec_Vectors_Seed0;
begin
  // source: reference/xxHash-dev/tests/sanity_test_vectors.h (XSUM_XXH32_testdata)
  ExpectHashHex32(0,  $00000000, '02cc5d05');
  ExpectHashHex32(1,  $00000000, 'cf65b03e');
  ExpectHashHex32(2,  $00000000, '1151bee4');
  ExpectHashHex32(3,  $00000000, 'c23884f5');
  ExpectHashHex32(4,  $00000000, 'a9de7ce9');
  ExpectHashHex32(31, $00000000, '5f40e562');
  ExpectHashHex32(32, $00000000, 'd89829ec');
  ExpectHashHex32(33, $00000000, '31a427e5');
  ExpectHashHex32(64, $00000000, '02e95dbb');
  ExpectHashHex32(256,$00000000, '520cb910');
  ExpectHashHex32(4096,$00000000, '20fc444f');
end;

procedure TTestCase_XXHash_Vectors.Test_XXH32_Spec_Vectors_SeedPrime;
begin
  // seed = 0x9E3779B1 (PRIME32_1)
  ExpectHashHex32(0,  SEED32_PRIME, '36b78ae7');
  ExpectHashHex32(1,  SEED32_PRIME, 'b4545aa4');
  ExpectHashHex32(2,  SEED32_PRIME, '1edb879a');
  ExpectHashHex32(3,  SEED32_PRIME, '1a269947');
  ExpectHashHex32(4,  SEED32_PRIME, '2baafe83');
  ExpectHashHex32(31, SEED32_PRIME, '5c0c3350');
  ExpectHashHex32(32, SEED32_PRIME, 'a5c44467');
end;

procedure TTestCase_XXHash_Vectors.Test_XXH32_Boundary_Lengths;
begin
  // additional boundary checks
  ExpectHashHex32(63, $00000000, 'f1d48fdb');
  ExpectHashHex32(65, $00000000, '16992b3d');
end;

procedure TTestCase_XXHash_Vectors.Test_XXH64_Spec_Vectors_Seed0;
begin
  // source: reference/xxHash-dev/tests/sanity_test_vectors.h (XSUM_XXH64_testdata)
  ExpectHashHex64(0,  QWord(0), 'ef46db3751d8e999');
  ExpectHashHex64(1,  QWord(0), 'e934a84adb052768');
  ExpectHashHex64(2,  QWord(0), '5d48cd60a77e23ff');
  ExpectHashHex64(3,  QWord(0), 'ff7e1959cb50794a');
  ExpectHashHex64(31, QWord(0), '299b39a290e6d783');
  ExpectHashHex64(32, QWord(0), '18b216492bb44b70');
  ExpectHashHex64(33, QWord(0), '55c8dc3e578f5b59');
  ExpectHashHex64(64, QWord(0), 'ef558f8acac2b5cd');
  ExpectHashHex64(256,QWord(0), '5e3f5bf94d574981');
  ExpectHashHex64(4096,QWord(0), 'ab77f4af85f4e70b');
end;

procedure TTestCase_XXHash_Vectors.Test_XXH64_Spec_Vectors_SeedPrime32;
begin
  // seed = 0x000000009E3779B1 (32-bit PRIME in low bits)
  ExpectHashHex64(0,  SEED64_PRIME32EXT, 'ac75fda2929b17ef');
  ExpectHashHex64(1,  SEED64_PRIME32EXT, '5014607643a9b4c3');
  ExpectHashHex64(2,  SEED64_PRIME32EXT, '9e93152232d54a39');
  ExpectHashHex64(3,  SEED64_PRIME32EXT, 'aa8584e83660f7d1');
  ExpectHashHex64(32, SEED64_PRIME32EXT, 'b3f33bdf93ade409');
end;

procedure TTestCase_XXHash_Vectors.Test_XXH64_Boundary_Lengths;
begin
  // additional boundary checks
  ExpectHashHex64(63, QWord(0), 'a9efbe0fa0f3f4e7');
  // 65 的官方值不在 0..4096 序列显式给出，暂不加
end;

initialization
  RegisterTest(TTestCase_XXHash_Vectors);
end.

