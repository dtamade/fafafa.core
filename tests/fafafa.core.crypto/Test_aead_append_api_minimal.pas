{$CODEPAGE UTF8}
unit Test_aead_append_api_minimal;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm,
  fafafa.core.crypto.aead.chacha20poly1305;

type
  TTestCase_AEAD_AppendAPI = class(TTestCase)
  published
    procedure Test_AESGCM_SealAppend_And_OpenAppend;
    procedure Test_AESGCM_OpenAppend_InvalidTag_ShouldNotPolluteDst;
    procedure Test_ChaCha_SealAppend_And_OpenAppend;
  end;

implementation

procedure TTestCase_AEAD_AppendAPI.Test_AESGCM_SealAppend_And_OpenAppend;
var AEAD: IAEADCipher; AEADx: IAEADCipherEx; Key, Nonce, AAD, PT, CT: TBytes; Dst: TBytes; W: Integer;
begin
  AEAD := CreateAES256GCM_Impl;
  if not Supports(AEAD, IAEADCipherEx, AEADx) then Fail('IAEADCipherEx not supported');
  SetLength(Key, 32); FillChar(Key[0], 32, 1); AEAD.SetKey(Key);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 2);
  SetLength(AAD, 3); FillChar(AAD[0], 3, 3);
  SetLength(PT, 5); FillChar(PT[0], 5, 7);
  SetLength(Dst, 2); Dst[0] := 9; Dst[1] := 8;
  W := AEADx.SealAppend(Dst, Nonce, AAD, PT);
  AssertTrue('w>0', W > 0);
  CT := Copy(Dst, 2, Length(Dst)-2);
  SetLength(Dst, 0);
  W := AEADx.OpenAppend(Dst, Nonce, AAD, CT);
  AssertEquals(Length(PT), W);
  AssertEquals(Length(PT), Length(Dst));
  AssertTrue('roundtrip', CompareByte(PT[0], Dst[0], Length(PT)) = 0);
end;

procedure TTestCase_AEAD_AppendAPI.Test_AESGCM_OpenAppend_InvalidTag_ShouldNotPolluteDst;
var AEAD: IAEADCipher; AEADx: IAEADCipherEx; Key, Nonce, AAD, PT, CT: TBytes; Dst: TBytes; ok: Boolean;
begin
  AEAD := CreateAES256GCM_Impl;
  if not Supports(AEAD, IAEADCipherEx, AEADx) then Fail('IAEADCipherEx not supported');
  SetLength(Key, 32); FillChar(Key[0], 32, 1); AEAD.SetKey(Key);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 2);
  SetLength(AAD, 0);
  SetLength(PT, 0);
  // 生成最小 CT（仅 Tag），并篡改 1 字节
  CT := AEAD.Seal(Nonce, AAD, PT);
  if Length(CT) = 0 then Fail('unexpected empty CT');
  CT[0] := CT[0] xor $FF;
  SetLength(Dst, 4); Dst[0] := 1; Dst[1] := 2; Dst[2] := 3; Dst[3] := 4;
  ok := False;
  try
    AEADx.OpenAppend(Dst, Nonce, AAD, CT);
  except
    on E: EInvalidData do ok := True;
  end;
  AssertTrue('should raise EInvalidData', ok);
  AssertEquals('dst not polluted', 4, Length(Dst));
  AssertEquals(1, Dst[0]); AssertEquals(2, Dst[1]); AssertEquals(3, Dst[2]); AssertEquals(4, Dst[3]);
end;

procedure TTestCase_AEAD_AppendAPI.Test_ChaCha_SealAppend_And_OpenAppend;
var AEAD: IAEADCipher; AEADx: IAEADCipherEx; Key, Nonce, AAD, PT, CT: TBytes; Dst: TBytes; W: Integer;
begin
  AEAD := CreateChaCha20Poly1305_Impl;
  if not Supports(AEAD, IAEADCipherEx, AEADx) then Fail('IAEADCipherEx not supported');
  SetLength(Key, 32); FillChar(Key[0], 32, 4); AEAD.SetKey(Key);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 5);
  SetLength(AAD, 7); FillChar(AAD[0], 7, 6);
  SetLength(PT, 9); FillChar(PT[0], 9, 7);
  SetLength(Dst, 1); Dst[0] := 0;
  W := AEADx.SealAppend(Dst, Nonce, AAD, PT);
  AssertTrue('w>0', W > 0);
  CT := Copy(Dst, 1, Length(Dst)-1);
  SetLength(Dst, 0);
  W := AEADx.OpenAppend(Dst, Nonce, AAD, CT);
  AssertEquals(Length(PT), W);
  AssertEquals(Length(PT), Length(Dst));
  AssertTrue('roundtrip', CompareByte(PT[0], Dst[0], Length(PT)) = 0);
end;

initialization
  RegisterTest(TTestCase_AEAD_AppendAPI);

{$POP}
end.

