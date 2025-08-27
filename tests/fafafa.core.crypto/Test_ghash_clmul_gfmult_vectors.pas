{$CODEPAGE UTF8}
unit Test_ghash_clmul_gfmult_vectors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash, fafafa.core.crypto.interfaces;

type
  TTestCase_GHASH_GFMult_Vectors = class(TTestCase)
  published
    procedure Test_Random_GFMult_Equivalence;
  end;

implementation

procedure TTestCase_GHASH_GFMult_Vectors.Test_Random_GFMult_Equivalence;
var i, n: Integer; X, Y, Z0, Z1: TBytes; v: string; GH: IGHash;
begin
  v := GetEnvironmentVariable('FAFAFA_GHASH_IMPL');
  if not SameText(v, 'clmul') then Exit; // only when explicitly enabled

  Randomize;
  n := 256;
  for i := 1 to n do
  begin
    SetLength(X, 16); SetLength(Y, 16);
    FillChar(X[0], 16, Random(256));
    FillChar(Y[0], 16, Random(256));

    // Use API path to exercise GFMult128 via GHASH
    // S = (X * Y) when AAD/C carefully chosen: using single block multiply as proxy
    // For direct multiply, we embed test path into GH.Init/Finalize around single block
    GHash_SelectBackend(0); GH := CreateGHash; GH.Init(Y); GH.Update(X); Z0 := GH.Finalize(Length(X), 0);
    GHash_SelectBackend(1); GH := CreateGHash; GH.Init(Y); GH.Update(X); Z1 := GH.Finalize(Length(X), 0);

    AssertEquals('len', Length(Z0), Length(Z1));
    AssertTrue('eq', CompareByte(Z0[0], Z1[0], 16)=0);
  end;
end;

initialization
  RegisterTest(TTestCase_GHASH_GFMult_Vectors);

end.

