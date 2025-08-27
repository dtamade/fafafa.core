unit test_hash_xxh3_64_streaming_vs_oneshot;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.hash.xxh3_64;

procedure RegisterTests_XXH3_64_StreamVsOneShot;

implementation

type
  TXXH3_64_StreamTests = class(TTestCase)
  published
    procedure Test_SmallChunks_Seed0;
    procedure Test_MixedChunks_Seed0;
  end;

function HexToBytesStrict(const S: string): TBytes;
begin
  Result := HexToBytes(S);
end;

procedure ExpectEqHex(const Name: string; const A, B: TBytes);
begin
  fpcunit.TAssert.AssertTrue(Name + ' len', Length(A) = Length(B));
  fpcunit.TAssert.AssertTrue(Name + ' eq', SecureCompare(A, B));
end;

procedure TXXH3_64_StreamTests.Test_SmallChunks_Seed0;
var ctx: IHashAlgorithm; data: TBytes; i: Integer; one, stream: TBytes;
begin
  // 0..127 作为样本（<=240 走 one-shot 路径，先确保等价）
  SetLength(data, 128);
  for i := 0 to 127 do data[i] := Byte(i);
  one := XXH3_64Hash(data, 0);
  ctx := fafafa.core.crypto.hash.xxh3_64.CreateXXH3_64(0);
  // 逐字节喂入
  for i := 0 to High(data) do ctx.Update(data[i], 1);
  stream := ctx.Finalize;
  ExpectEqHex('seed0-1B-chunks', one, stream);
end;

procedure TXXH3_64_StreamTests.Test_MixedChunks_Seed0;
var ctx: IHashAlgorithm; data: TBytes; i, pos, len: Integer; one, stream: TBytes; seed: QWord;
begin
  // 准备 200 字节递增序列（<=240，先保证等价基础）
  SetLength(data, 200);
  for i := 0 to 199 do data[i] := Byte(i);
  seed := 0;
  one := XXH3_64Hash(data, seed);
  ctx := fafafa.core.crypto.hash.xxh3_64.CreateXXH3_64(seed);
  pos := 0;
  // 用不同大小的分块喂入，覆盖 <64, ==64, >64，多次跨越 240 边界
  while pos < Length(data) do
  begin
    if pos < 200 then len := 7
    else if pos < 512 then len := 64
    else if pos < 2048 then len := 127
    else len := 329;
    if pos + len > Length(data) then len := Length(data) - pos;
    ctx.Update(data[pos], len);
    Inc(pos, len);
  end;
  stream := ctx.Finalize;
  ExpectEqHex('seeded-mixed-chunks', one, stream);
end;

procedure RegisterTests_XXH3_64_StreamVsOneShot;
begin
  RegisterTest('crypto-hash-xxh3_64-streamvsone', TXXH3_64_StreamTests.Suite);
end;

end.

