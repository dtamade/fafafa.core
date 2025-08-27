{$CODEPAGE UTF8}
unit Test_ghash_mini_kat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash,
  fafafa.core.crypto.interfaces;

type
  TTestCase_GHASH_MiniKAT = class(TTestCase)
  published
    // H=0^128, 任意 AAD/C => S 应恒为 0^128
    procedure Test_ZeroH_AAD32_C48_ZeroS;
    procedure Test_ZeroH_AAD3_C7_ZeroS;
  end;

implementation

procedure TTestCase_GHASH_MiniKAT.Test_ZeroH_AAD32_C48_ZeroS;
var
  GH: IGHash;
  H, S, AAD, C: TBytes;
  i: Integer;
begin
  // H = 0^128
  SetLength(H, 16);
  for i := 0 to 15 do H[i] := 0;

  // AAD = 32 字节，固定模式
  SetLength(AAD, 32);
  for i := 0 to High(AAD) do AAD[i] := (i * 7 + 3) and $FF;

  // C = 48 字节，固定模式
  SetLength(C, 48);
  for i := 0 to High(C) do C[i] := (i * 11 + 9) and $FF;

  GH := CreateGHash;
  GH.Init(H);
  GH.Update(AAD);
  GH.Update(C);
  S := GH.Finalize(Length(AAD), Length(C));

  AssertEquals('S length', 16, Length(S));
  for i := 0 to 15 do
    AssertEquals('S['+IntToStr(i)+']', 0, S[i]);
end;

procedure TTestCase_GHASH_MiniKAT.Test_ZeroH_AAD3_C7_ZeroS;
var
  GH: IGHash;
  H, S, AAD, C: TBytes;
  i: Integer;
begin
  // 非 16 对齐的边界：AAD=3、C=7，验证 padding 路径
  SetLength(H, 16);
  for i := 0 to 15 do H[i] := 0;

  SetLength(AAD, 3); AAD[0] := $AA; AAD[1] := $BB; AAD[2] := $CC;
  SetLength(C, 7);
  for i := 0 to High(C) do C[i] := (i * 5 + 1) and $FF;

  GH := CreateGHash;
  GH.Init(H);
  GH.Update(AAD);
  GH.Update(C);
  S := GH.Finalize(Length(AAD), Length(C));

  AssertEquals('S length', 16, Length(S));
  for i := 0 to 15 do
    AssertEquals('S['+IntToStr(i)+']', 0, S[i]);
end;

initialization
  RegisterTest(TTestCase_GHASH_MiniKAT);

end.

