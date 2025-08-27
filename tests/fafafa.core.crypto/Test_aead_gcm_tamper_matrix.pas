{$CODEPAGE UTF8}
unit Test_aead_gcm_tamper_matrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm;

type
  TTestCase_AES_GCM_TamperMatrix = class(TTestCase)
  private
    procedure RunRoundtrip(const TagLen: Integer; const AADLen, PTLen: Integer);
    procedure ExpectTamperFailure_ModifyTag(const TagLen, AADLen, PTLen: Integer);
    procedure ExpectTamperFailure_ModifyCT(const TagLen, AADLen, PTLen: Integer);
    procedure ExpectTamperFailure_ModifyAAD(const TagLen, AADLen, PTLen: Integer);
    procedure ExpectTamperFailure_ModifyNonce(const TagLen, AADLen, PTLen: Integer);
  published
    // 正向：空/短/长，Tag=12/16
    procedure Test_Roundtrip_Tag12_EmptyAAD_EmptyPT;
    procedure Test_Roundtrip_Tag16_ShortAAD_ShortPT;
    procedure Test_Roundtrip_Tag12_LongAAD_LongPT;

    // 负向：篡改 tag/ct/aad/nonce 均应失败
    procedure Test_Tamper_Tag_ShouldRaise;
    procedure Test_Tamper_CT_ShouldRaise;
    procedure Test_Tamper_AAD_ShouldRaise;
    procedure Test_Tamper_Nonce_ShouldRaise;

    // 边界：Open 输入长度 < TagLen -> 应抛 EInvalidArgument
    procedure Test_Open_CT_LessThan_Tag_ShouldRaise;

    // 边界：PT 为空时（仅 Tag）应成功往返
    procedure Test_Open_EmptyPT_TagOnly_Succeeds_Tag12;
    procedure Test_Open_EmptyPT_TagOnly_Succeeds_Tag16;
  end;

implementation

procedure FillSeqBytes(out B: TBytes; L: Integer; Mul, Add: Integer);
var i: Integer;
begin
  SetLength(B, L);
  for i := 0 to L-1 do B[i] := Byte((i * Mul + Add) and $FF);
end;

procedure TTestCase_AES_GCM_TamperMatrix.RunRoundtrip(const TagLen: Integer; const AADLen, PTLen: Integer);
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT, Dec: TBytes;
begin
  FillSeqBytes(Key, 32, 37, 13);
  FillSeqBytes(Nonce, 12, 17, 7);
  FillSeqBytes(AAD, AADLen, 5, 11);
  FillSeqBytes(PT, PTLen, 9, 3);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT)=|PT|+Tag', PTLen+TagLen, Length(CT));
  Dec := AEAD.Open(Nonce, AAD, CT);
  AssertEquals('len(PT)=roundtrip', PTLen, Length(Dec));
  if PTLen > 0 then AssertTrue('PT equals', CompareByte(Dec[0], PT[0], PTLen) = 0);
end;

procedure TTestCase_AES_GCM_TamperMatrix.ExpectTamperFailure_ModifyTag(const TagLen, AADLen, PTLen: Integer);
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  FillSeqBytes(Key, 32, 37, 13);
  FillSeqBytes(Nonce, 12, 17, 7);
  FillSeqBytes(AAD, AADLen, 5, 11);
  FillSeqBytes(PT, PTLen, 9, 3);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  if Length(CT) > 0 then CT[High(CT)] := CT[High(CT)] xor $01; // flip last tag byte
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('tampered tag should raise');
  except
    on E: EInvalidData do ;
  end;
end;

procedure TTestCase_AES_GCM_TamperMatrix.ExpectTamperFailure_ModifyCT(const TagLen, AADLen, PTLen: Integer);
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; idx: Integer;
begin
  FillSeqBytes(Key, 32, 37, 13);
  FillSeqBytes(Nonce, 12, 17, 7);
  FillSeqBytes(AAD, AADLen, 5, 11);
  FillSeqBytes(PT, PTLen, 9, 3);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // flip a middle ciphertext byte if any PT exists
  if PTLen > 0 then
  begin
    idx := PTLen div 2;
    CT[idx] := CT[idx] xor $80;
  end
  else
  begin
    // if PT empty, modify first tag byte (different from last-byte case)
    if Length(CT) > 0 then CT[PTLen] := CT[PTLen] xor $80;
  end;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('tampered ciphertext should raise');
  except
    on E: EInvalidData do ;
  end;
end;

procedure TTestCase_AES_GCM_TamperMatrix.ExpectTamperFailure_ModifyAAD(const TagLen, AADLen, PTLen: Integer);
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  FillSeqBytes(Key, 32, 37, 13);
  FillSeqBytes(Nonce, 12, 17, 7);
  FillSeqBytes(AAD, AADLen, 5, 11);
  FillSeqBytes(PT, PTLen, 9, 3);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // modify AAD after Seal
  if AADLen > 0 then AAD[0] := AAD[0] xor $FF
  else begin SetLength(AAD,1); AAD[0] := $FF; end;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('tampered AAD should raise');
  except
    on E: EInvalidData do ;
  end;
end;

procedure TTestCase_AES_GCM_TamperMatrix.ExpectTamperFailure_ModifyNonce(const TagLen, AADLen, PTLen: Integer);
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  FillSeqBytes(Key, 32, 37, 13);
  FillSeqBytes(Nonce, 12, 17, 7);
  FillSeqBytes(AAD, AADLen, 5, 11);
  FillSeqBytes(PT, PTLen, 9, 3);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // modify Nonce
  Nonce[0] := Nonce[0] xor $01;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('tampered Nonce should raise');
  except
    on E: EInvalidData do ;
  end;
end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Roundtrip_Tag12_EmptyAAD_EmptyPT;
begin RunRoundtrip(12, 0, 0); end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Roundtrip_Tag16_ShortAAD_ShortPT;
begin RunRoundtrip(16, 8, 8); end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Roundtrip_Tag12_LongAAD_LongPT;
begin RunRoundtrip(12, 2048, 4096); end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Tamper_Tag_ShouldRaise;
begin
  ExpectTamperFailure_ModifyTag(12, 0, 0);
  ExpectTamperFailure_ModifyTag(16, 7, 15);
end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Tamper_CT_ShouldRaise;
begin
  ExpectTamperFailure_ModifyCT(12, 0, 32);
  ExpectTamperFailure_ModifyCT(16, 9, 1);
end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Tamper_AAD_ShouldRaise;
begin
  ExpectTamperFailure_ModifyAAD(12, 16, 0);
  ExpectTamperFailure_ModifyAAD(16, 1, 33);
end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Tamper_Nonce_ShouldRaise;
begin
  ExpectTamperFailure_ModifyNonce(12, 0, 0);
  ExpectTamperFailure_ModifyNonce(16, 10, 10);
end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Open_CT_LessThan_Tag_ShouldRaise;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  FillSeqBytes(Key, 32, 37, 13);
  FillSeqBytes(Nonce, 12, 17, 7);
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CT := AEAD.Seal(Nonce, AAD, PT); // length=16
  // supply shorter than tag
  SetLength(CT, 15);
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('CT shorter than Tag should raise');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Open_EmptyPT_TagOnly_Succeeds_Tag12;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT, Dec: TBytes;
begin
  FillSeqBytes(Key, 32, 1, 2);
  FillSeqBytes(Nonce, 12, 1, 3);
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(12, Length(CT));
  Dec := AEAD.Open(Nonce, AAD, CT);
  AssertEquals(0, Length(Dec));
end;

procedure TTestCase_AES_GCM_TamperMatrix.Test_Open_EmptyPT_TagOnly_Succeeds_Tag16;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT, Dec: TBytes;
begin
  FillSeqBytes(Key, 32, 2, 1);
  FillSeqBytes(Nonce, 12, 3, 1);
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(16, Length(CT));
  Dec := AEAD.Open(Nonce, AAD, CT);
  AssertEquals(0, Length(Dec));
end;

initialization
  RegisterTest(TTestCase_AES_GCM_TamperMatrix);

end.

