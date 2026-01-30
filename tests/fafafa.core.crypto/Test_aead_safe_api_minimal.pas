{$CODEPAGE UTF8}
unit Test_aead_safe_api_minimal;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces;

type
  TTestCase_AEAD_SafeAPI_Minimal = class(TTestCase)
  published
    procedure Test_AESGCM_Combined_Roundtrip;
    procedure Test_ChaCha20Poly1305_Combined_Roundtrip;
    procedure Test_Invalid_Combined_TooShort;
  end;

implementation

procedure TTestCase_AEAD_SafeAPI_Minimal.Test_AESGCM_Combined_Roundtrip;
var
  NM: INonceManager; Key, AAD, PT, C, PT2: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*17 + 3) and $FF;
  SetLength(AAD, 8); for i := 0 to 7 do AAD[i] := i;
  SetLength(PT, 64); for i := 0 to 63 do PT[i] := (i*11 + 5) and $FF;
  NM := CreateNonceManagerThreadSafe(1234, 0);
  C := AES256GCM_Seal_Combined(Key, AAD, PT, NM);
  PT2 := AES256GCM_Open_Combined(Key, AAD, C);
  AssertEquals(Length(PT), Length(PT2));
  AssertTrue(CompareByte(PT[0], PT2[0], Length(PT)) = 0);
end;

procedure TTestCase_AEAD_SafeAPI_Minimal.Test_ChaCha20Poly1305_Combined_Roundtrip;
var
  NM: INonceManager; Key, AAD, PT, C, PT2: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*7 + 9) and $FF;
  SetLength(AAD, 4); for i := 0 to 3 do AAD[i] := i*2;
  SetLength(PT, 33); for i := 0 to 32 do PT[i] := (i*13 + 1) and $FF;
  NM := CreateNonceManagerThreadSafe(1, 0);
  C := ChaCha20Poly1305_Seal_Combined(Key, AAD, PT, NM);
  PT2 := ChaCha20Poly1305_Open_Combined(Key, AAD, C);
  AssertEquals(Length(PT), Length(PT2));
  AssertTrue(CompareByte(PT[0], PT2[0], Length(PT)) = 0);
end;

procedure TTestCase_AEAD_SafeAPI_Minimal.Test_Invalid_Combined_TooShort;
var
  Key, AAD, Bad: TBytes;
begin
  SetLength(Key, 32); SetLength(AAD, 0); SetLength(Bad, 10);
  try
    AES256GCM_Open_Combined(Key, AAD, Bad);
    Fail('expected Exception');
  except
    on E: Exception do ;
  end;
end;

initialization
  RegisterTest(TTestCase_AEAD_SafeAPI_Minimal);

end.

{$POP}

