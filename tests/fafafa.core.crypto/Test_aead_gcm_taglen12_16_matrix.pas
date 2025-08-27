{$CODEPAGE UTF8}
unit Test_aead_gcm_taglen12_16_matrix;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm;

type
  TTestCase_AES_GCM_TagMatrix = class(TTestCase)
  private
    procedure RunCase(const TagLen: Integer; const AADLen, PTLen: Integer; const ShouldFailTamper: Boolean);
  published
    // 基础往返与单字节篡改
    procedure Test_Tag12_EmptyAAD_EmptyPT;
    procedure Test_Tag12_ShortAAD_ShortPT;
    procedure Test_Tag12_LongAAD_LongPT;
    procedure Test_Tag16_EmptyAAD_EmptyPT;
    procedure Test_Tag16_ShortAAD_ShortPT;
    procedure Test_Tag16_LongAAD_LongPT;
    // 扩展：多字节篡改与 AAD/Nonce 篡改
    procedure Test_Tamper_Tag_Middle3_Bytes_Tag12_LongPT;
    procedure Test_Tamper_CT_FirstAndLast_Tag12_LongPT;
    procedure Test_Tamper_AAD_AppendByte_Tag16_Short;
    procedure Test_Tamper_Nonce_MultiBit_Tag16_Short;
  end;

implementation

procedure TTestCase_AES_GCM_TagMatrix.RunCase(const TagLen: Integer; const AADLen, PTLen: Integer; const ShouldFailTamper: Boolean);
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i * 37 + 13) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i * 17 + 7) and $FF;
  SetLength(AAD, AADLen); for i := 0 to High(AAD) do AAD[i] := (i * 5 + 11) and $FF;
  SetLength(PT, PTLen); for i := 0 to High(PT) do PT[i] := (i * 9 + 3) and $FF;

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT)=|PT|+Tag', PTLen+TagLen, Length(CT));

  // 正常解密
  if PTLen = 0 then
    AssertEquals('Open ok (empty PT)', 0, Length(AEAD.Open(Nonce, AAD, CT)))
  else
    AssertTrue('Open ok', CompareByte(AEAD.Open(Nonce, AAD, CT)[0], PT[0], PTLen) = 0);

  // 篡改最后一字节的 Tag 应失败
  if ShouldFailTamper and (Length(CT) > 0) then
  begin
    CT[High(CT)] := CT[High(CT)] xor $01;
    try
      AEAD.Open(Nonce, AAD, CT);
      Fail('tampered should raise');
    except
      on E: EInvalidData do ;
    end;
  end;
end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tag12_EmptyAAD_EmptyPT;
begin RunCase(12, 0, 0, True); end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tag12_ShortAAD_ShortPT;
begin RunCase(12, 7, 15, True); end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tag12_LongAAD_LongPT;
begin RunCase(12, 4097, 8193, True); end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tag16_EmptyAAD_EmptyPT;
begin RunCase(16, 0, 0, True); end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tag16_ShortAAD_ShortPT;
begin RunCase(16, 9, 5, True); end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tag16_LongAAD_LongPT;
begin RunCase(16, 12289, 16385, True); end;

// 扩展用例实现
procedure TTestCase_AES_GCM_TagMatrix.Test_Tamper_Tag_Middle3_Bytes_Tag12_LongPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i, TagStart: Integer; TagLen: Integer;
begin
  TagLen := 12;
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i * 37 + 13) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i * 17 + 7) and $FF;
  SetLength(AAD, 1024); for i := 0 to High(AAD) do AAD[i] := (i * 5 + 11) and $FF;
  SetLength(PT, 8192); for i := 0 to High(PT) do PT[i] := (i * 9 + 3) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  TagStart := Length(CT) - TagLen;
  if TagStart >= 5 then
  begin
    CT[TagStart+4] := CT[TagStart+4] xor $AA;
    CT[TagStart+5] := CT[TagStart+5] xor $55;
    CT[TagStart+6] := CT[TagStart+6] xor $FF;
  end
  else
    CT[High(CT)] := CT[High(CT)] xor $01;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('multi-byte tag tamper should raise');
  except
    on E: EInvalidData do ;
  end;
end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tamper_CT_FirstAndLast_Tag12_LongPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i, LastCTIdx, TagLen: Integer;
begin
  TagLen := 12;
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i * 37 + 13) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i * 17 + 7) and $FF;
  SetLength(AAD, 64); for i := 0 to High(AAD) do AAD[i] := (i * 5 + 11) and $FF;
  SetLength(PT, 8192); for i := 0 to High(PT) do PT[i] := (i * 9 + 3) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  LastCTIdx := Length(CT) - TagLen - 1; // 最后一个密文字节索引（不含 Tag）
  if LastCTIdx >= 0 then
  begin
    CT[0] := CT[0] xor $20;
    CT[LastCTIdx] := CT[LastCTIdx] xor $40;
  end;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('ciphertext tamper should raise');
  except
    on E: EInvalidData do ;
  end;
end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tamper_AAD_AppendByte_Tag16_Short;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i: Integer; TagLen: Integer;
begin
  TagLen := 16;
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i * 37 + 13) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i * 17 + 7) and $FF;
  SetLength(AAD, 15); for i := 0 to High(AAD) do AAD[i] := (i * 5 + 11) and $FF;
  SetLength(PT, 128); for i := 0 to High(PT) do PT[i] := (i * 9 + 3) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // 篡改：AAD 末尾追加一个字节
  SetLength(AAD, Length(AAD)+1); AAD[High(AAD)] := $7B;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('aad changed should raise');
  except
    on E: EInvalidData do ;
  end;
end;

procedure TTestCase_AES_GCM_TagMatrix.Test_Tamper_Nonce_MultiBit_Tag16_Short;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i: Integer; TagLen: Integer;
begin
  TagLen := 16;
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i * 37 + 13) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i * 17 + 7) and $FF;
  SetLength(AAD, 0);
  SetLength(PT, 256); for i := 0 to High(PT) do PT[i] := (i * 9 + 3) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // 篡改 Nonce 多位
  if Length(Nonce) >= 2 then
  begin
    Nonce[0] := Nonce[0] xor $11;
    Nonce[1] := Nonce[1] xor $80;
  end
  else if Length(Nonce) = 1 then
    Nonce[0] := Nonce[0] xor $01;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('nonce changed should raise');
  except
    on E: EInvalidData do ;
  end;
end;

initialization
  RegisterTest(TTestCase_AES_GCM_TagMatrix);

{$POP}
end.

