{$CODEPAGE UTF8}
unit Test_ghash_kat_vectors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash,
  fafafa.core.crypto.interfaces;

type
  TTestCase_GHASH_KAT = class(TTestCase)
  published
    procedure Test_KAT_AllZero_H_AAD_C_Zero;
  end;

implementation

procedure TTestCase_GHASH_KAT.Test_KAT_AllZero_H_AAD_C_Zero;
var GH: IGHash; H, S: TBytes;
begin
  // Authoritative trivial KAT from definition:
  // H = 0^128, AAD = empty, C = empty -> S must be 0^128
  SetLength(H, 16); FillChar(H[0], 16, 0);
  GH := CreateGHash; GH.Init(H);
  S := GH.Finalize(0, 0);
  AssertEquals('S length', 16, Length(S));
  AssertTrue('S == 0^128',
    (S[0]=0) and (S[1]=0) and (S[2]=0) and (S[3]=0) and
    (S[4]=0) and (S[5]=0) and (S[6]=0) and (S[7]=0) and
    (S[8]=0) and (S[9]=0) and (S[10]=0) and (S[11]=0) and
    (S[12]=0) and (S[13]=0) and (S[14]=0) and (S[15]=0));
end;

initialization
  RegisterTest(TTestCase_GHASH_KAT);

end.

