{$CODEPAGE UTF8}
unit Test_ghash_basic_properties;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash,
  fafafa.core.crypto.interfaces;

type
  { TTestCase_GHASH_Basic }
  TTestCase_GHASH_Basic = class(TTestCase)
  published
    procedure Test_EmptyAAD_EmptyC_AnyH_ReturnsZero;
    procedure Test_AnyData_H_Zero_ReturnsZero;
  end;

implementation

procedure TTestCase_GHASH_Basic.Test_EmptyAAD_EmptyC_AnyH_ReturnsZero;
var
  GH: IGHash;
  H, S: TBytes;
begin
  // H 可以是任意 16 字节；此处使用固定非零值
  SetLength(H, 16);
  FillChar(H[0], 16, $A5);
  GH := CreateGHash;
  GH.Init(H);
  // AAD 与 C 均为空；Finalize 长度为 0
  S := GH.Finalize(0, 0);
  AssertEquals('S length', 16, Length(S));
  // 预期 GHASH(H, empty, empty) = 0^128
  AssertTrue('S == 0^128', (
    (S[0]=0) and (S[1]=0) and (S[2]=0) and (S[3]=0) and
    (S[4]=0) and (S[5]=0) and (S[6]=0) and (S[7]=0) and
    (S[8]=0) and (S[9]=0) and (S[10]=0) and (S[11]=0) and
    (S[12]=0) and (S[13]=0) and (S[14]=0) and (S[15]=0)
  ));
end;

procedure TTestCase_GHASH_Basic.Test_AnyData_H_Zero_ReturnsZero;
var
  GH: IGHash;
  H, S, AAD, C: TBytes;
  i: Integer;
begin
  // H = 0^128 时，GHASH 必为 0
  SetLength(H, 16);
  FillChar(H[0], 16, 0);

  // 构造任意 AAD 与 C（包含非 16 对齐长度）
  SetLength(AAD, 24);
  for i := 0 to High(AAD) do AAD[i] := (i * 7 + 3) and $FF;
  SetLength(C, 17);
  for i := 0 to High(C) do C[i] := (i * 11 + 5) and $FF;

  GH := CreateGHash;
  GH.Init(H);
  GH.Update(AAD);
  GH.Update(C);
  S := GH.Finalize(Length(AAD), Length(C));

  AssertEquals('S length', 16, Length(S));
  AssertTrue('S == 0^128', (
    (S[0]=0) and (S[1]=0) and (S[2]=0) and (S[3]=0) and
    (S[4]=0) and (S[5]=0) and (S[6]=0) and (S[7]=0) and
    (S[8]=0) and (S[9]=0) and (S[10]=0) and (S[11]=0) and
    (S[12]=0) and (S[13]=0) and (S[14]=0) and (S[15]=0)
  ));
end;

initialization
  RegisterTest(TTestCase_GHASH_Basic);

{$POP}
end.

