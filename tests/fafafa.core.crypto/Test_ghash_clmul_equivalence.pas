{$CODEPAGE UTF8}
unit Test_ghash_clmul_equivalence;

{$mode objfpc}{$H+}

{$IFNDEF FAFAFA_CRYPTO_X86_CLMUL}
{$WARN 6058 OFF} // unit not used
{$ENDIF}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash, fafafa.core.crypto.interfaces;

type
  TTestCase_GHASH_CLMUL_Equivalence = class(TTestCase)
  published
    procedure Test_RandomVectors_Equivalence;
  end;

implementation

{$IFDEF FAFAFA_CRYPTO_X86_CLMUL}
procedure TTestCase_GHASH_CLMUL_Equivalence.Test_RandomVectors_Equivalence;
var i, n: Integer; H, AAD, C: TBytes; GH: IGHash; S0, S1: TBytes; v: string; runClmul: Boolean;
begin
  // 仅当环境变量显式要求时才运行 CLMUL 等价性，以避免影响默认稳定性
  v := GetEnvironmentVariable('FAFAFA_GHASH_IMPL');
  runClmul := SameText(v, 'clmul');
  if not runClmul then Exit;

  Randomize;
  n := 64; // 64 组随机向量
  for i := 1 to n do
  begin
    SetLength(H, 16);   // 128-bit H
    SetLength(AAD, Random(96));
    SetLength(C, Random(256));
    if Length(H)>0 then FillChar(H[0], Length(H), Random(256));
    if Length(AAD)>0 then FillChar(AAD[0], Length(AAD), Random(256));
    if Length(C)>0 then FillChar(C[0], Length(C), Random(256));

    // Pure
    GHash_SelectBackend(0);
    GH := CreateGHash; GH.Init(H); GH.Update(AAD); GH.Update(C); S0 := GH.Finalize(Length(AAD), Length(C)); GH.Reset;

    // CLMUL (若 CPU 不支持，将自动回退 Pure)
    GHash_SelectBackend(1);
    GH := CreateGHash; GH.Init(H); GH.Update(AAD); GH.Update(C); S1 := GH.Finalize(Length(AAD), Length(C)); GH.Reset;

    AssertEquals('len', Length(S0), Length(S1));
    AssertTrue('eq', (Length(S0)=0) or (CompareByte(S0[0], S1[0], Length(S0))=0));
  end;
end;
{$ELSE}
procedure TTestCase_GHASH_CLMUL_Equivalence.Test_RandomVectors_Equivalence;
begin
  // 宏未启用时该测试为空操作，以保持项目可编译
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_GHASH_CLMUL_Equivalence);

end.

