{$CODEPAGE UTF8}
unit Test_aead_tamper_extras;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm; // for CreateAES256GCM_Impl

Type
  TBytes = fafafa.core.crypto.interfaces.TBytes;

procedure RegisterTests;

implementation

function HexToBytes(const S: string): TBytes;
var I,N: Integer; H: string;
begin
  H := LowerCase(Trim(StringReplace(S, ' ', '', [rfReplaceAll])));
  N := Length(H) div 2; SetLength(Result, N);
  for I := 0 to N-1 do Result[I] := StrToInt('$' + Copy(H, I*2+1, 2));
end;

procedure FillSeqBytes(out B: TBytes; L: Integer; Mul, Add: Integer);
var i: Integer;
begin
  SetLength(B, L);
  for i := 0 to L-1 do B[i] := Byte((i * Mul + Add) and $FF);
end;

function Expect_Open_Raises(const AEAD: IAEADCipher; const Nonce, AAD, CT: TBytes): Boolean;
begin
  Result := False;
  try
    AEAD.Open(Nonce, AAD, CT);
  except
    on E: EInvalidData do Exit(True);
  end;
end;

Type
  { TTestCase_AEAD_TamperExtras }
  TTestCase_AEAD_TamperExtras = class(TTestCase)
  published
    // AES-GCM: 多字节篡改（Tag 与 CT）
    procedure Test_AESGCM_Tamper_Tag_MultiBytes;
    procedure Test_AESGCM_Tamper_CT_MultiBytes;
    procedure Test_AESGCM_Swap_Tags_ShouldFail;
    // ChaCha20-Poly1305: 多字节篡改 + OpenAppend 负向不污染
    procedure Test_ChaCha_Tamper_Tag_MultiBytes;
    procedure Test_ChaCha_OpenAppend_InvalidTag_ShouldNotPolluteDst;
  end;

procedure TTestCase_AEAD_TamperExtras.Test_AESGCM_Tamper_Tag_MultiBytes;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; TagLen: Integer;
begin
  FillSeqBytes(Key, 32, 37, 13);
  FillSeqBytes(Nonce, 12, 17, 7);
  FillSeqBytes(AAD, 17, 5, 11);
  FillSeqBytes(PT, 31, 9, 3);
  for TagLen in [12,16] do
  begin
    AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
    CT := AEAD.Seal(Nonce, AAD, PT);
    // flip 最后 3 个 tag 字节
    if Length(CT) >= TagLen then
    begin
      CT[High(CT)] := CT[High(CT)] xor $01;
      CT[High(CT)-1] := CT[High(CT)-1] xor $02;
      CT[High(CT)-2] := CT[High(CT)-2] xor $04;
      AssertTrue('tampered tag (multi) should raise', Expect_Open_Raises(AEAD, Nonce, AAD, CT));
    end;
  end;
end;

procedure TTestCase_AEAD_TamperExtras.Test_AESGCM_Tamper_CT_MultiBytes;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; TagLen, L, mid: Integer;
begin
  FillSeqBytes(Key, 32, 7, 3);
  FillSeqBytes(Nonce, 12, 11, 5);
  FillSeqBytes(AAD, 1, 1, 1);
  FillSeqBytes(PT, 64, 17, 1);
  for TagLen in [12,16] do
  begin
    AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
    CT := AEAD.Seal(Nonce, AAD, PT);
    L := Length(PT);
    if L > 3 then
    begin
      // flip 3 个位置：首/中/尾（密文字节部分）
      CT[0] := CT[0] xor $80;
      mid := L div 2; CT[mid] := CT[mid] xor $40;
      CT[L-1] := CT[L-1] xor $20;
    end
    else if L > 0 then
      CT[0] := CT[0] xor $FF
    else
      CT[0] := CT[0] xor $FF; // PT=0 时，index 0 即 tag 起点，仍应失败
    AssertTrue('tampered ct (multi) should raise', Expect_Open_Raises(AEAD, Nonce, AAD, CT));
  end;
end;

procedure TTestCase_AEAD_TamperExtras.Test_AESGCM_Swap_Tags_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD1, AAD2, PT, CT1, CT2, S: TBytes; TagLen: Integer; L: Integer;
begin
  FillSeqBytes(Key, 32, 5, 7);
  FillSeqBytes(Nonce, 12, 1, 3);
  FillSeqBytes(PT, 32, 3, 1);
  FillSeqBytes(AAD1, 8, 2, 2);
  FillSeqBytes(AAD2, 8, 9, 9);
  for TagLen in [12,16] do
  begin
    AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
    CT1 := AEAD.Seal(Nonce, AAD1, PT);
    CT2 := AEAD.Seal(Nonce, AAD2, PT);
    // 交换 tag 尾部
    L := Length(PT);
    S := Copy(CT1, 0, Length(CT1));
    Move(CT2[L], S[L], TagLen);
    AssertTrue('swap tag should raise', Expect_Open_Raises(AEAD, Nonce, AAD1, S));
  end;
end;

procedure TTestCase_AEAD_TamperExtras.Test_ChaCha_Tamper_Tag_MultiBytes;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, OutBuf: TBytes;
begin
  // 使用 RFC 8439 的 key/nonce 格式
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 0);
  FillSeqBytes(PT, 16, 1, 2);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  OutBuf := AEAD.Seal(Nonce, AAD, PT);
  // flip 3 个 tag 字节
  OutBuf[High(OutBuf)] := OutBuf[High(OutBuf)] xor $01;
  OutBuf[High(OutBuf)-1] := OutBuf[High(OutBuf)-1] xor $02;
  OutBuf[High(OutBuf)-2] := OutBuf[High(OutBuf)-2] xor $04;
  AssertTrue('chacha tampered tag should raise', Expect_Open_Raises(AEAD, Nonce, AAD, OutBuf));
end;

procedure TTestCase_AEAD_TamperExtras.Test_ChaCha_OpenAppend_InvalidTag_ShouldNotPolluteDst;
var AEAD: IAEADCipher; AEADx: IAEADCipherEx; Dst: TBytes; Key, Nonce, AAD, PT, C: TBytes; OldLen: Integer;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 0); PT := HexToBytes('010203');
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  C := AEAD.Seal(Nonce, AAD, PT);
  // 篡改 tag
  C[High(C)] := C[High(C)] xor $FF;
  SetLength(Dst, 5); FillChar(Dst[0], 5, 0);
  OldLen := Length(Dst);
  try
    // 使用 IAEADCipherEx 的 OpenAppend，如果鉴别失败不得污染 Dst
    if not Supports(AEAD, IAEADCipherEx, AEADx) then
      Fail('AEAD does not support append API');
    AEADx.OpenAppend(Dst, Nonce, AAD, C);
    Fail('expected EInvalidData');
  except
    on E: EInvalidData do begin
      AssertEquals('dst length unchanged', OldLen, Length(Dst));
    end;
  end;
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_AEAD_TamperExtras);
end;

initialization
  RegisterTests;

end.

