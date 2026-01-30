{$CODEPAGE UTF8}
unit fafafa.core.crypto.xxhash3.vectors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, testutils,
  fafafa.core.crypto,
  fafafa.core.crypto.hash.xxh3_128;

type
  TTestCase_XXH3_Vectors = class(TTestCase)
  published
    procedure Test_XXH3_64_Short_Seed0_0to16;
    procedure Test_XXH3_64_Mid_Seed0_17to128;
    procedure Test_XXH3_64_Mid_Seed0_129to240;
    procedure Test_XXH3_64_Long_Seed0_256_4096;
    procedure Test_XXH3_64_SliceEquivalence;
    procedure Test_XXH3_128_Vectors_Basic;
  end;

implementation

const
  PRIME32 = UInt32(2654435761);
  PRIME64 = QWord(11400714785074694797);

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

procedure TTestCase_XXH3_Vectors.Test_XXH3_64_Short_Seed0_0to16;
  procedure ExpectHashHex64_X3(const Len: Integer; const ExpectedHexLower: string);
  var buf, got: TBytes;
  begin
    FillTestBuffer(buf, Len);
    got := XXH3_64Hash(buf, 0);
    Self.AssertEquals(Format('xxh3_64 len=%d seed=0', [Len]), ExpectedHexLower, BytesToHex(got));
  end;
begin
  // source: reference/xxHash-dev/tests/sanity_test_vectors.h (XSUM_XXH3_testdata)
  ExpectHashHex64_X3(0,  '2d06800538d394c2');
  ExpectHashHex64_X3(1,  'c44bdff4074eecdb');
  ExpectHashHex64_X3(2,  '7a9978044cb8a8bb');
  ExpectHashHex64_X3(3,  '54247382a8d6b94d');
  ExpectHashHex64_X3(4,  'e5dc74bc51848a51');
  ExpectHashHex64_X3(5,  'e4243f00720306bb');
  ExpectHashHex64_X3(6,  '27b56a84cd2d7325');
  ExpectHashHex64_X3(7,  '9941e0007f555e50');
  ExpectHashHex64_X3(8,  '24ccc9acaa9f65e4');
  ExpectHashHex64_X3(9,  '14d5001c15dd3f2b');
  ExpectHashHex64_X3(16, '981b17d36c7498c9');
end;

procedure TTestCase_XXH3_Vectors.Test_XXH3_64_Mid_Seed0_17to128;
  procedure ExpectHashHex64_X3(const Len: Integer; const ExpectedHexLower: string);
  var buf, got: TBytes;
  begin
    FillTestBuffer(buf, Len);
    got := XXH3_64Hash(buf, 0);
    Self.AssertEquals(Format('xxh3_64 len=%d seed=0', [Len]), ExpectedHexLower, BytesToHex(got));
  end;
begin
  ExpectHashHex64_X3(31, '5d516692ca764c50');
  ExpectHashHex64_X3(32, '9feaddbdbf57eed3');
  ExpectHashHex64_X3(33, 'abfb2d081b400a10');
  ExpectHashHex64_X3(64, '9cb48487720ec49d');

procedure TTestCase_XXH3_Vectors.Test_XXH3_64_Mid_Seed0_129to240;
  procedure ExpectHashHex64_X3(const Len: Integer; const ExpectedHexLower: string);
  var buf, got: TBytes;
  begin
    FillTestBuffer(buf, Len);
    got := XXH3_64Hash(buf, 0);
    Self.AssertEquals(Format('xxh3_64 len=%d seed=0', [Len]), ExpectedHexLower, BytesToHex(got));
  end;
begin
  ExpectHashHex64_X3(129, '98f1b0a679a2ca29');
  ExpectHashHex64_X3(240, '81c3c2b67f568ccf');
end;

procedure TTestCase_XXH3_Vectors.Test_XXH3_64_Long_Seed0_256_4096;
  procedure ExpectHashHex64_X3(const Len: Integer; const ExpectedHexLower: string);
  var buf, got: TBytes;
  begin
    FillTestBuffer(buf, Len);
    got := XXH3_64Hash(buf, 0);
    Self.AssertEquals(Format('xxh3_64 len=%d seed=0', [Len]), ExpectedHexLower, BytesToHex(got));
  end;
begin
  ExpectHashHex64_X3(256,  '55de574ad89d0ac5');
  ExpectHashHex64_X3(4096, 'e91206429d1f48f9');
end;


// 片段等价性测试：分片 Update/Finalize 应与 one-shot 一致（seed=0）
procedure TTestCase_XXH3_Vectors.Test_XXH3_64_SliceEquivalence;
var
  Data: TBytes;
  H: IHashAlgorithm;
  B1, B2: TBytes;
  i, off, step, n: Integer;
  Slices: array[0..6] of Integer = (1,2,3,7,16,32,64);
  procedure RunCase(Len: Integer);
  begin
    SetLength(Data, Len);
    if Len>0 then FillTestBuffer(Data, Len);
    B1 := XXH3_64Hash(Data, 0);
    for i := 0 to High(Slices) do
    begin
      H := CreateXXH3_64(0);
      if Length(Data) > 0 then
      begin
        off := 0; step := Slices[i];
        while off < Length(Data) do
        begin
          n := step; if off + n > Length(Data) then n := Length(Data) - off;
          H.Update(Data[off], n);
          Inc(off, n);
        end;
      end;
      B2 := H.Finalize;
      AssertEquals(Format('len=%d slice=%d', [Len, Slices[i]]), BytesToHex(B1), BytesToHex(B2));
    end;
  end;
begin
  RunCase(0);
  RunCase(1);
  RunCase(8);
  RunCase(9);
  RunCase(16);
  RunCase(31);
  RunCase(32);
  RunCase(33);
  RunCase(64);
  RunCase(129);
  RunCase(240);
  RunCase(256);
end;

// XXH3-128 向量（选取关键长度，seed=0）
procedure TTestCase_XXH3_Vectors.Test_XXH3_128_Vectors_Basic;
var
  got: TBytes;
  buf: TBytes;
  function Hex128(lo, hi: QWord): string;
  begin
    Result := LowerCase(Format('%.16x%.16x', [hi, lo]));
  end;
begin
  // 0
  got := XXH3_128Hash([]);
  AssertEquals('xxh3_128 len=0', '6001c324468d497f99aa06d3014798d8', BytesToHex(got));
  // 16
  FillTestBuffer(buf, 16);
  got := XXH3_128Hash(buf);
  AssertEquals('xxh3_128 len=16', '562980258a998629c68c368ecf8a9c05', BytesToHex(got));
  // 32
  FillTestBuffer(buf, 32);
  got := XXH3_128Hash(buf);
  AssertEquals('xxh3_128 len=32', '278410a17595e3f998fc6458710dc2e8', BytesToHex(got));
  // 64
  FillTestBuffer(buf, 64);
  got := XXH3_128Hash(buf);
  AssertEquals('xxh3_128 len=64', 'efdb6a44690721a96d90e81a9b0fd622', BytesToHex(got));
  // 256
  FillTestBuffer(buf, 256);
  got := XXH3_128Hash(buf);
  AssertEquals('xxh3_128 len=256', '55de574ad89d0ac58b1c66091423d288', BytesToHex(got));
  // 4096
  FillTestBuffer(buf, 4096);
  got := XXH3_128Hash(buf);
  AssertEquals('xxh3_128 len=4096', 'e91206429d1f48f9b9cfaea2ca5626a4', BytesToHex(got));
end;

      H := CreateXXH3_64(0);
      if Length(Data) > 0 then
      begin
        off := 0; step := Slices[i];
        while off < Length(Data) do
        begin
          n := step; if off + n > Length(Data) then n := Length(Data) - off;
          H.Update(Data[off], n);
          Inc(off, n);
        end;
      end;
      B2 := H.Finalize;
      AssertEquals(Format('len=%d slice=%d', [Len, Slices[i]]), BytesToHex(B1), BytesToHex(B2));
    end;
  end;
begin
  RunCase(0);
  RunCase(1);
  RunCase(8);
  RunCase(9);
  RunCase(16);
  RunCase(31);
  RunCase(32);
  RunCase(33);
  RunCase(64);
  RunCase(129);
  RunCase(240);
  RunCase(256);
end;


end;

initialization
  RegisterTest(TTestCase_XXH3_Vectors);
end.

