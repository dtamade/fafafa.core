{$CODEPAGE UTF8}
unit Test_aead_inplace_api_minimal;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm,
  fafafa.core.crypto.aead.chacha20poly1305;

type
  TTestCase_AEAD_InPlaceAPI = class(TTestCase)
  published
    procedure Test_AESGCM_SealInPlace_And_OpenInPlace_Roundtrip;
    procedure Test_AESGCM_OpenInPlace_InvalidTag_ShouldNotModify;
    procedure Test_ChaCha_SealInPlace_And_OpenInPlace_Roundtrip;
  end;

implementation

procedure TTestCase_AEAD_InPlaceAPI.Test_AESGCM_SealInPlace_And_OpenInPlace_Roundtrip;
var AEAD: IAEADCipher; Ex2: IAEADCipherEx2; Key, Nonce, AAD, PT, Data: TBytes; L: Integer;
begin
  AEAD := CreateAES256GCM_Impl;
  if not Supports(AEAD, IAEADCipherEx2, Ex2) then Fail('IAEADCipherEx2 not supported');
  SetLength(Key, 32); FillChar(Key[0], 32, 1); AEAD.SetKey(Key);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 2);
  SetLength(AAD, 3); FillChar(AAD[0], 3, 3);
  SetLength(PT, 5); FillChar(PT[0], 5, 7);
  Data := Copy(PT, 0, Length(PT));
  L := Ex2.SealInPlace(Data, Nonce, AAD);
  AssertEquals(Length(PT) + AEAD.Overhead, L);
  L := Ex2.OpenInPlace(Data, Nonce, AAD);
  AssertEquals(Length(PT), L);
  AssertEquals(Length(PT), Length(Data));
  AssertTrue('roundtrip', CompareByte(PT[0], Data[0], Length(PT)) = 0);
end;

procedure TTestCase_AEAD_InPlaceAPI.Test_AESGCM_OpenInPlace_InvalidTag_ShouldNotModify;
var AEAD: IAEADCipher; Ex2: IAEADCipherEx2; Key, Nonce, AAD, PT, Data: TBytes; ok: Boolean; L: Integer;
begin
  AEAD := CreateAES256GCM_Impl;
  if not Supports(AEAD, IAEADCipherEx2, Ex2) then Fail('IAEADCipherEx2 not supported');
  SetLength(Key, 32); FillChar(Key[0], 32, 1); AEAD.SetKey(Key);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 2);
  SetLength(AAD, 0);
  SetLength(PT, 0);
  Data := Copy(PT, 0, Length(PT));
  L := Ex2.SealInPlace(Data, Nonce, AAD);
  AssertEquals(AEAD.Overhead, L);
  // 篡改
  if Length(Data) > 0 then Data[0] := Data[0] xor $AA;
  ok := False;
  try
    Ex2.OpenInPlace(Data, Nonce, AAD);
  except
    on E: EInvalidData do ok := True;
  end;
  AssertTrue('should raise EInvalidData', ok);
  AssertEquals('length not changed after failure', L, Length(Data));
end;

procedure TTestCase_AEAD_InPlaceAPI.Test_ChaCha_SealInPlace_And_OpenInPlace_Roundtrip;
var AEAD: IAEADCipher; Ex2: IAEADCipherEx2; Key, Nonce, AAD, PT, Data: TBytes; L: Integer;
begin
  AEAD := CreateChaCha20Poly1305_Impl;
  if not Supports(AEAD, IAEADCipherEx2, Ex2) then Fail('IAEADCipherEx2 not supported');
  SetLength(Key, 32); FillChar(Key[0], 32, 4); AEAD.SetKey(Key);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 5);
  SetLength(AAD, 7); FillChar(AAD[0], 7, 6);
  SetLength(PT, 9); FillChar(PT[0], 9, 7);
  Data := Copy(PT, 0, Length(PT));
  L := Ex2.SealInPlace(Data, Nonce, AAD);
  AssertEquals(Length(PT) + AEAD.Overhead, L);
  L := Ex2.OpenInPlace(Data, Nonce, AAD);
  AssertEquals(Length(PT), L);
  AssertEquals(Length(PT), Length(Data));
  AssertTrue('roundtrip', CompareByte(PT[0], Data[0], Length(PT)) = 0);
end;

initialization
  RegisterTest(TTestCase_AEAD_InPlaceAPI);

{$POP}
end.

