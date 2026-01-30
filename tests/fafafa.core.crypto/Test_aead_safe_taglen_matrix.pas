{$CODEPAGE UTF8}
unit Test_aead_safe_taglen_matrix;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces;

type
  TTestCase_AEAD_Safe_TagLen = class(TTestCase)
  published
    procedure Test_AESGCM_Safe_TL_12_16_Roundtrip;
  end;

implementation

procedure TTestCase_AEAD_Safe_TagLen.Test_AESGCM_Safe_TL_12_16_Roundtrip;
var
  NM: INonceManager; Key, AAD, PT, C, PT2: TBytes;
  i, t: Integer;
begin
  // deterministic key/aad/pt
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*29 + 7) and $FF;
  SetLength(AAD, 5);  for i := 0 to 4  do AAD[i] := i*3;

  // test multiple PT sizes
  for i := 0 to 3 do
  begin
    SetLength(PT, i*17 + 1);
    if Length(PT) > 0 then FillChar(PT[0], Length(PT), Byte(77+i));
    NM := CreateNonceManagerThreadSafe($A1B2C3D4, 0);
    for t := 12 to 16 do
    begin
      C := AES256GCM_Seal_Combined_TL(Key, AAD, PT, NM, t);
      PT2 := AES256GCM_Open_Combined_TL(Key, AAD, C, t);
      AssertEquals(Length(PT), Length(PT2));
      if Length(PT) > 0 then
        AssertTrue(CompareByte(PT[0], PT2[0], Length(PT)) = 0);
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_AEAD_Safe_TagLen);

end.

{$POP}

