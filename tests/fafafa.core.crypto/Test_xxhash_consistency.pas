{
  XXHash consistency tests: one-shot vs streaming, chunk splits, reset behavior, seed effect
}
unit Test_xxhash_consistency;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}


interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto;

type
  // 全局函数测试（XXH32Hash/XXH64Hash 等）
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_XXH32Hash_Bytes_OneShot_vs_Streaming;
    procedure Test_XXH32Hash_StringEqualsBytes_ASCII;
    procedure Test_XXH64Hash_Bytes_OneShot_vs_Streaming;
    procedure Test_XXH64Hash_StringEqualsBytes_ASCII;
  end;

  TTestCase_XXH32 = class(TTestCase)
  published
    procedure Test_CreateXXH32_BasicProperties;
    procedure Test_Streaming_SameAs_OneShot_ZeroSeed;
    procedure Test_Streaming_SameAs_OneShot_NonZeroSeed;
    procedure Test_SplitChunks_Equivalence;
    procedure Test_Reset_Reproducible;
  end;

  TTestCase_XXH64 = class(TTestCase)
  published
    procedure Test_CreateXXH64_BasicProperties;
    procedure Test_Streaming_SameAs_OneShot_ZeroSeed;
    procedure Test_Streaming_SameAs_OneShot_NonZeroSeed;
    procedure Test_SplitChunks_Equivalence;
    procedure Test_Reset_Reproducible;
  end;

implementation

function BytesOf(const S: AnsiString): TBytes;
begin
  SetLength(Result, Length(S));
  if Length(S) > 0 then Move(S[1], Result[0], Length(S));
end;

procedure TTestCase_Global.Test_XXH32Hash_Bytes_OneShot_vs_Streaming;
var
  Data: TBytes; H1,H2: TBytes; H: IHashAlgorithm;
begin
  Data := BytesOf('The quick brown fox jumps over the lazy dog');
  // one-shot
  H1 := XXH32Hash(Data, 0);
  // streaming
  H := CreateXXH32(0);
  if Length(Data) > 0 then H.Update(Data[0], Length(Data));
  H2 := H.Finalize;
  CheckEquals(Length(H1), 4, 'XXH32 digest length');
  CheckEquals(Length(H2), 4, 'XXH32 digest length');
  CheckTrue(ConstantTimeCompare(H1, H2), 'XXH32 one-shot vs streaming mismatch');
end;

procedure TTestCase_Global.Test_XXH32Hash_StringEqualsBytes_ASCII;
var
  S: string; B: TBytes; Hs,Hb: TBytes;
begin
  S := 'abc0123';
  SetLength(B, Length(S)); if Length(S) > 0 then Move(S[1], B[0], Length(S));
  Hs := XXH32Hash(S, 0);
  Hb := XXH32Hash(B, 0);
  CheckTrue(ConstantTimeCompare(Hs, Hb), 'XXH32 string vs bytes (ASCII) mismatch');
end;

procedure TTestCase_Global.Test_XXH64Hash_Bytes_OneShot_vs_Streaming;
var
  Data: TBytes; H1,H2: TBytes; H: IHashAlgorithm;
begin
  Data := BytesOf('Pack my box with five dozen liquor jugs');
  H1 := XXH64Hash(Data, 0);
  H := CreateXXH64(0);
  if Length(Data) > 0 then H.Update(Data[0], Length(Data));
  H2 := H.Finalize;
  CheckEquals(Length(H1), 8, 'XXH64 digest length');
  CheckEquals(Length(H2), 8, 'XXH64 digest length');
  CheckTrue(ConstantTimeCompare(H1, H2), 'XXH64 one-shot vs streaming mismatch');
end;

procedure TTestCase_Global.Test_XXH64Hash_StringEqualsBytes_ASCII;
var
  S: string; B: TBytes; Hs,Hb: TBytes;
begin
  S := 'abcXYZ123';
  SetLength(B, Length(S)); if Length(S) > 0 then Move(S[1], B[0], Length(S));
  Hs := XXH64Hash(S, 0);
  Hb := XXH64Hash(B, 0);
  CheckTrue(ConstantTimeCompare(Hs, Hb), 'XXH64 string vs bytes (ASCII) mismatch');
end;

procedure TTestCase_XXH32.Test_CreateXXH32_BasicProperties;
var H: IHashAlgorithm;
begin
  H := CreateXXH32(0);
  CheckEquals(4, H.GetDigestSize, 'XXH32 digest size');
  CheckEquals(16, H.GetBlockSize, 'XXH32 block size');
  CheckEquals('XXH32', H.GetName, 'XXH32 name');
end;

procedure TTestCase_XXH32.Test_Streaming_SameAs_OneShot_ZeroSeed;
var D,H1,H2: TBytes; H: IHashAlgorithm;
begin
  D := BytesOf('abc');
  H1 := XXH32Hash(D, 0);
  H := CreateXXH32(0);
  if Length(D) > 0 then H.Update(D[0], Length(D));
  H2 := H.Finalize;
  CheckTrue(ConstantTimeCompare(H1, H2));
end;

procedure TTestCase_XXH32.Test_Streaming_SameAs_OneShot_NonZeroSeed;
var D,H1,H2: TBytes; H: IHashAlgorithm;
begin
  D := BytesOf('split across chunks');
  H1 := XXH32Hash(D, 12345);
  H := CreateXXH32(12345);
  if Length(D) > 0 then H.Update(D[0], Length(D));
  H2 := H.Finalize;
  CheckTrue(ConstantTimeCompare(H1, H2));
end;

procedure TTestCase_XXH32.Test_SplitChunks_Equivalence;
var D,H1,H2: TBytes; H: IHashAlgorithm; mid: Integer;
begin
  D := BytesOf('0123456789abcdefghijklmnopqrstuvwxyz');
  H1 := XXH32Hash(D, 0);
  H := CreateXXH32(0);
  mid := 5;
  if Length(D) > 0 then H.Update(D[0], mid);
  if Length(D) > mid then H.Update(D[mid], Length(D) - mid);
  H2 := H.Finalize;
  CheckTrue(ConstantTimeCompare(H1, H2));
end;

procedure TTestCase_XXH32.Test_Reset_Reproducible;
var D,H1,H2: TBytes; H: IHashAlgorithm;
begin
  D := BytesOf('repeatable');
  H := CreateXXH32(0);
  if Length(D) > 0 then H.Update(D[0], Length(D));
  H1 := H.Finalize;
  H.Reset;
  if Length(D) > 0 then H.Update(D[0], Length(D));
  H2 := H.Finalize;
  CheckTrue(ConstantTimeCompare(H1, H2), 'Reset should reproduce same result');
end;

procedure TTestCase_XXH64.Test_CreateXXH64_BasicProperties;
var H: IHashAlgorithm;
begin
  H := CreateXXH64(0);
  CheckEquals(8, H.GetDigestSize, 'XXH64 digest size');
  CheckEquals(32, H.GetBlockSize, 'XXH64 block size');
  CheckEquals('XXH64', H.GetName, 'XXH64 name');
end;

procedure TTestCase_XXH64.Test_Streaming_SameAs_OneShot_ZeroSeed;
var D,H1,H2: TBytes; H: IHashAlgorithm;
begin
  D := BytesOf('abc');
  H1 := XXH64Hash(D, 0);
  H := CreateXXH64(0);
  if Length(D) > 0 then H.Update(D[0], Length(D));
  H2 := H.Finalize;
  CheckTrue(ConstantTimeCompare(H1, H2));
end;

procedure TTestCase_XXH64.Test_Streaming_SameAs_OneShot_NonZeroSeed;
var D,H1,H2: TBytes; H: IHashAlgorithm;
begin
  D := BytesOf('split across chunks');
  H1 := XXH64Hash(D, 9876543210);
  H := CreateXXH64(9876543210);
  if Length(D) > 0 then H.Update(D[0], Length(D));
  H2 := H.Finalize;
  CheckTrue(ConstantTimeCompare(H1, H2));
end;

procedure TTestCase_XXH64.Test_SplitChunks_Equivalence;
var D,H1,H2: TBytes; H: IHashAlgorithm; c1,c2,c3: Integer;
begin
  D := BytesOf('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ');
  H1 := XXH64Hash(D, 0);
  H := CreateXXH64(0);
  c1 := 7; c2 := 19; c3 := Length(D) - (c1 + c2);
  if c1 > 0 then H.Update(D[0], c1);
  if c2 > 0 then H.Update(D[c1], c2);
  if c3 > 0 then H.Update(D[c1 + c2], c3);
  H2 := H.Finalize;
  CheckTrue(ConstantTimeCompare(H1, H2));
end;

procedure TTestCase_XXH64.Test_Reset_Reproducible;
var D,H1,H2: TBytes; H: IHashAlgorithm;
begin
  D := BytesOf('repeatable');
  H := CreateXXH64(0);
  if Length(D) > 0 then H.Update(D[0], Length(D));
  H1 := H.Finalize;
  H.Reset;
  if Length(D) > 0 then H.Update(D[0], Length(D));
  H2 := H.Finalize;
  CheckTrue(ConstantTimeCompare(H1, H2), 'Reset should reproduce same result');
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_XXH32);
  RegisterTest(TTestCase_XXH64);
end.
{$POP}


