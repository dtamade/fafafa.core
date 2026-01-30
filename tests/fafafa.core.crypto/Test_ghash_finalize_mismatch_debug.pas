{$CODEPAGE UTF8}
unit Test_ghash_finalize_mismatch_debug;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_FinalizeMismatchDebug = class(TTestCase)
  published
    procedure Test_Finalize_Mismatch_Throws_In_Debug;
  end;

implementation

procedure TTestCase_GHash_FinalizeMismatchDebug.Test_Finalize_Mismatch_Throws_In_Debug;
var
  GH: IGHash; H, A: TBytes; raisedErr: Boolean; i: Integer;
begin
  SetLength(H, 16); for i := 0 to 15 do H[i] := i;
  SetLength(A, 10); for i := 0 to 9 do A[i] := i;
  GH := CreateGHash; GH.Init(H); GH.Update(A);
  raisedErr := False;
  try
    // deliberately pass wrong AADLen
    // In FPCUnit we don't rely on StartTestTransaction; just assert
    // exception presence below when DEBUG is defined.
    GH.Finalize(0, 0);
  except
    on E: Exception do raisedErr := True;
  end;
  {$IFDEF DEBUG}
  AssertTrue(raisedErr);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_GHash_FinalizeMismatchDebug);

end.

