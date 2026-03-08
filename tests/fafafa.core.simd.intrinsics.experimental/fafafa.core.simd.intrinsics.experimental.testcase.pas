unit fafafa.core.simd.intrinsics.experimental.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.aes,
  fafafa.core.simd.intrinsics.sha;

type
  TTestCase_SimdIntrinsicsExperimental = class(TTestCase)
  published
    procedure Test_Default_AES_SHA_Rejects;
    procedure Test_Experimental_AES_SHA_PlaceholderSemantics;
  end;

implementation

function GetRepoRoot: string;
begin
  Result := ExpandFileName(
    IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) +
    '..' + DirectorySeparator +
    '..' + DirectorySeparator +
    '..'
  );
end;

function LoadText(const aPath: string): string;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    LStrings.LoadFromFile(aPath);
    Result := LStrings.Text;
  finally
    LStrings.Free;
  end;
end;

procedure InitM128U64(out aValue: TM128; const aLo, aHi: QWord);
begin
  FillChar(aValue, SizeOf(aValue), 0);
  aValue.m128i_u64[0] := aLo;
  aValue.m128i_u64[1] := aHi;
end;

procedure InitM128U32(out aValue: TM128; const a0, a1, a2, a3: DWord);
begin
  FillChar(aValue, SizeOf(aValue), 0);
  aValue.m128i_u32[0] := a0;
  aValue.m128i_u32[1] := a1;
  aValue.m128i_u32[2] := a2;
  aValue.m128i_u32[3] := a3;
end;

procedure TTestCase_SimdIntrinsicsExperimental.Test_Default_AES_SHA_Rejects;
const
  PUBLIC_FILES: array[0..3] of string = (
    'fafafa.core.simd.pas',
    'fafafa.core.simd.api.pas',
    'fafafa.core.simd.direct.pas',
    'fafafa.core.simd.dispatch.pas'
  );
  FORBIDDEN_TOKENS: array[0..2] of string = (
    'fafafa.core.simd.intrinsics.experimental',
    'fafafa.core.simd.intrinsics.aes',
    'fafafa.core.simd.intrinsics.sha'
  );
var
  LRepoRoot: string;
  LPath: string;
  LText: string;
  LFileIndex: Integer;
  LTokenIndex: Integer;
begin
  LRepoRoot := GetRepoRoot;
  for LFileIndex := Low(PUBLIC_FILES) to High(PUBLIC_FILES) do
  begin
    LPath := IncludeTrailingPathDelimiter(LRepoRoot) + 'src' + DirectorySeparator + PUBLIC_FILES[LFileIndex];
    AssertTrue('public entry file missing: ' + LPath, FileExists(LPath));
    LText := LowerCase(LoadText(LPath));
    for LTokenIndex := Low(FORBIDDEN_TOKENS) to High(FORBIDDEN_TOKENS) do
      AssertEquals(
        'public entry should reject experimental AES/SHA reference in ' + PUBLIC_FILES[LFileIndex],
        0,
        Pos(LowerCase(FORBIDDEN_TOKENS[LTokenIndex]), LText)
      );
  end;
end;

procedure TTestCase_SimdIntrinsicsExperimental.Test_Experimental_AES_SHA_PlaceholderSemantics;
var
  LData: TM128;
  LRoundKey: TM128;
  LA: TM128;
  LB: TM128;
  LK: TM128;
  LAesEnc: TM128;
  LAesEncLast: TM128;
  LAesDec: TM128;
  LAesDecLast: TM128;
  LAesKeyGen: TM128;
  LAesImc: TM128;
  LSha1Msg1: TM128;
  LSha1Msg2: TM128;
  LSha1NextE: TM128;
  LSha1Rnds4: TM128;
  LSha256Msg1: TM128;
  LSha256Msg2: TM128;
  LSha256Rnds2: TM128;
  LIndex: Integer;
begin
  InitM128U64(LData,  $0102030405060708, $1112131415161718);
  InitM128U64(LRoundKey, $1010101010101010, $2020202020202020);
  InitM128U32(LA, 1, 2, 3, 4);
  InitM128U32(LB, 10, 20, 30, 40);
  InitM128U32(LK, 100, 200, 300, 400);

  LAesEnc := aes_aesenc_si128(LData, LRoundKey);
  LAesEncLast := aes_aesenclast_si128(LData, LRoundKey);
  LAesDec := aes_aesdec_si128(LData, LRoundKey);
  LAesDecLast := aes_aesdeclast_si128(LData, LRoundKey);
  LAesKeyGen := aes_aeskeygenassist_si128(LData, $5A);
  LAesImc := aes_aesimc_si128(LData);

  AssertTrue('aesenc lo lane mismatch', LAesEnc.m128i_u64[0] = (LData.m128i_u64[0] xor LRoundKey.m128i_u64[0]));
  AssertTrue('aesenc hi lane mismatch', LAesEnc.m128i_u64[1] = (LData.m128i_u64[1] xor LRoundKey.m128i_u64[1]));
  AssertTrue('aesenclast lo lane mismatch', LAesEncLast.m128i_u64[0] = LAesEnc.m128i_u64[0]);
  AssertTrue('aesdec lo lane mismatch', LAesDec.m128i_u64[0] = LAesEnc.m128i_u64[0]);
  AssertTrue('aesdeclast hi lane mismatch', LAesDecLast.m128i_u64[1] = LAesEnc.m128i_u64[1]);
  AssertTrue('aeskeygenassist should xor first byte with rcon', LAesKeyGen.m128i_u8[0] = (LData.m128i_u8[0] xor $5A));
  AssertTrue('aesimc should preserve data', CompareByte(LAesImc, LData, SizeOf(TM128)) = 0);

  LSha1Msg1 := sha_sha1msg1_epu32(LA, LB);
  LSha1Msg2 := sha_sha1msg2_epu32(LA, LB);
  LSha1NextE := sha_sha1nexte_epu32(LA, LB);
  LSha1Rnds4 := sha_sha1rnds4_epu32(LA, LB, 7);
  LSha256Msg1 := sha_sha256msg1_epu32(LA, LB);
  LSha256Msg2 := sha_sha256msg2_epu32(LA, LB);
  LSha256Rnds2 := sha_sha256rnds2_epu32(LA, LB, LK);

  for LIndex := 0 to 3 do
  begin
    AssertTrue('sha1msg1 lane mismatch', LSha1Msg1.m128i_u32[LIndex] = (LA.m128i_u32[LIndex] xor LB.m128i_u32[LIndex]));
    AssertTrue('sha1msg2 lane mismatch', LSha1Msg2.m128i_u32[LIndex] = (LA.m128i_u32[LIndex] + LB.m128i_u32[LIndex]));
    AssertTrue('sha1rnds4 lane mismatch', LSha1Rnds4.m128i_u32[LIndex] = (LA.m128i_u32[LIndex] + LB.m128i_u32[LIndex] + 7));
    AssertTrue('sha256msg1 lane mismatch', LSha256Msg1.m128i_u32[LIndex] = (LA.m128i_u32[LIndex] + LB.m128i_u32[LIndex]));
    AssertTrue('sha256msg2 lane mismatch', LSha256Msg2.m128i_u32[LIndex] = (LA.m128i_u32[LIndex] xor LB.m128i_u32[LIndex]));
    AssertTrue('sha256rnds2 lane mismatch', LSha256Rnds2.m128i_u32[LIndex] = (LA.m128i_u32[LIndex] + LB.m128i_u32[LIndex] + LK.m128i_u32[LIndex]));
  end;

  AssertTrue('sha1nexte lane0 mismatch', LSha1NextE.m128i_u32[0] = (LA.m128i_u32[0] + LB.m128i_u32[3]));
  AssertTrue('sha1nexte lane1 should preserve input', LSha1NextE.m128i_u32[1] = LA.m128i_u32[1]);
end;

initialization
  RegisterTest(TTestCase_SimdIntrinsicsExperimental);

end.
