{$CODEPAGE UTF8}
unit Test_ghash_kat_additional;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHASH_KAT_Additional = class(TTestCase)
  published
    procedure Test_KAT_ZeroH_AAD16_C16_ZeroS;
    procedure Test_KAT_ZeroH_AAD1_C0_ZeroS;
  end;

implementation

procedure TTestCase_GHASH_KAT_Additional.Test_KAT_ZeroH_AAD16_C16_ZeroS;
var GH: IGHash; H, AAD, C, S: TBytes; i: Integer;
begin
  SetLength(H, 16); for i := 0 to 15 do H[i] := 0;
  SetLength(AAD, 16); for i := 0 to 15 do AAD[i] := i;
  SetLength(C, 16);   for i := 0 to 15 do C[i] := 255 - i;
  GH := CreateGHash; GH.Init(H); GH.Update(AAD); GH.Update(C);
  S := GH.Finalize(Length(AAD), Length(C));
  AssertEquals(16, Length(S));
  for i := 0 to 15 do AssertEquals(0, S[i]);
end;

procedure TTestCase_GHASH_KAT_Additional.Test_KAT_ZeroH_AAD1_C0_ZeroS;
var GH: IGHash; H, AAD, S: TBytes; i: Integer;
begin
  SetLength(H, 16); for i := 0 to 15 do H[i] := 0;
  SetLength(AAD, 1); AAD[0] := $AA;
  GH := CreateGHash; GH.Init(H); GH.Update(AAD);
  S := GH.Finalize(Length(AAD), 0);
  AssertEquals(16, Length(S));
  for i := 0 to 15 do AssertEquals(0, S[i]);
end;

initialization
  RegisterTest(TTestCase_GHASH_KAT_Additional);

end.

