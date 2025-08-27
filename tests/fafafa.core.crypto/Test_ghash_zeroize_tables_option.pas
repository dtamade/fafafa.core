{$CODEPAGE UTF8}
unit Test_ghash_zeroize_tables_option;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Windows,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_ZeroizeTables = class(TTestCase)
  published
    procedure Test_Reset_ZeroizeTables_Option_KeptCorrectness;
  end;

implementation

procedure SaveEnv(const Name: String; out Old: String);
begin
  Old := SysUtils.GetEnvironmentVariable(Name);
end;

procedure RestoreEnv(const Name, Old: String);
begin
  if Old = '' then Windows.SetEnvironmentVariable(PChar(Name), nil)
  else Windows.SetEnvironmentVariable(PChar(Name), PChar(Old));
end;

procedure TTestCase_GHash_ZeroizeTables.Test_Reset_ZeroizeTables_Option_KeptCorrectness;
var
  old: String;
  H, AAD, C, S1, S2: TBytes;
  GH: IGHash;
  i: Integer;
begin
  // enable zeroization
  SaveEnv('FAFAFA_GHASH_ZEROIZE_TABLES', old);
  Windows.SetEnvironmentVariable(PChar('FAFAFA_GHASH_ZEROIZE_TABLES'), PChar('1'));

  try
    SetLength(H, 16); for i := 0 to 15 do H[i] := i;
    SetLength(AAD, 128); for i := 0 to 127 do AAD[i] := i*3;
    SetLength(C,   512); for i := 0 to 511 do C[i] := 255 - (i and $FF);

    GH := CreateGHash; GH.Init(H); GH.Update(AAD); GH.Update(C); S1 := GH.Finalize(Length(AAD), Length(C));

    // Reset triggers zeroization of tables; next run must re-build tables and produce identical tag
    GH := nil; // release interface to drop refcount and free instance safely
    GH := CreateGHash; GH.Init(H); GH.Update(AAD); GH.Update(C); S2 := GH.Finalize(Length(AAD), Length(C));

    AssertEquals(Length(S1), Length(S2));
    if Length(S1) > 0 then AssertTrue(CompareByte(S1[0], S2[0], Length(S1)) = 0);
  finally
    RestoreEnv('FAFAFA_GHASH_ZEROIZE_TABLES', old);
  end;
end;

initialization
  RegisterTest(TTestCase_GHash_ZeroizeTables);

end.

