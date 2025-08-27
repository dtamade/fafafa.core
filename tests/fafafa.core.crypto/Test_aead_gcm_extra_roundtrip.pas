{$CODEPAGE UTF8}
unit Test_aead_gcm_extra_roundtrip;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm, // for CreateAES256GCM_Impl
  fafafa.core.crypto.utils;

type
  TTestCase_AES_GCM_Extra = class(TTestCase)
  published
    procedure Test_AES256GCM_Tag16_PT1024_AAD0_Roundtrip;
    procedure Test_AES256GCM_Tag12_PT0_AAD1024_Roundtrip;
    procedure Test_AES256GCM_Tag12_TamperNonce_ShouldFail;
    procedure Test_AES256GCM_Tag16_TamperCiphertextMiddle_ShouldFail;
  end;

implementation

procedure TTestCase_AES_GCM_Extra.Test_AES256GCM_Tag16_PT1024_AAD0_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, C: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*7 + 3) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i*11 + 5) and $FF;
  SetLength(AAD, 0);
  SetLength(PT, 1024); for i := 0 to High(PT) do PT[i] := (i*13 + 7) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  C := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(Length(PT)+16, Length(C));
  AssertTrue('roundtrip-1024', SecureCompare(AEAD.Open(Nonce, AAD, C), PT));
end;

procedure TTestCase_AES_GCM_Extra.Test_AES256GCM_Tag12_PT0_AAD1024_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, C, OutPT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (255 - i) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i*9) and $FF;
  SetLength(AAD, 1024); for i := 0 to High(AAD) do AAD[i] := i and $FF;
  SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  C := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(12, Length(C));
  OutPT := AEAD.Open(Nonce, AAD, C);
  AssertEquals(0, Length(OutPT));
end;

procedure TTestCase_AES_GCM_Extra.Test_AES256GCM_Tag12_TamperNonce_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, C, WrongNonce: TBytes; i: Integer;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 0);
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := i;
  SetLength(AAD, 16); for i := 0 to 15 do AAD[i] := i*3;
  SetLength(PT, 64); for i := 0 to 63 do PT[i] := (i*5) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  C := AEAD.Seal(Nonce, AAD, PT);
  WrongNonce := Copy(Nonce, 0, 0); SetLength(WrongNonce, 12); Move(Nonce[0], WrongNonce[0], 12);
  WrongNonce[5] := WrongNonce[5] xor $80;
  try
    AEAD.Open(WrongNonce, AAD, C);
    Fail('tampered nonce should raise EInvalidData');
  except on E: EInvalidData do ; else raise; end;
end;

procedure TTestCase_AES_GCM_Extra.Test_AES256GCM_Tag16_TamperCiphertextMiddle_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, C: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := i;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := 255 - i;
  SetLength(AAD, 8); for i := 0 to 7 do AAD[i] := i*7;
  SetLength(PT, 48); for i := 0 to 47 do PT[i] := (i*17 + 1) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  C := AEAD.Seal(Nonce, AAD, PT);
  if Length(C) < (Length(PT)+16) then Fail('unexpected len');
  // flip a byte in ciphertext (not in tag)
  C[Length(PT) div 2] := C[Length(PT) div 2] xor $FF;
  try
    AEAD.Open(Nonce, AAD, C);
    Fail('tampered ciphertext should raise EInvalidData');
  except on E: EInvalidData do ; else raise; end;
end;

initialization
  RegisterTest(TTestCase_AES_GCM_Extra);

end.

