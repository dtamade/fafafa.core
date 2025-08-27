{$CODEPAGE UTF8}
unit Test_aead_tamper_more;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm,
  fafafa.core.crypto.aead.chacha20poly1305;

type
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
  { TTestCase_AEAD_TamperMore }
  TTestCase_AEAD_TamperMore = class(TTestCase)
  published
    // AES-GCM
    procedure Test_AESGCM_AAD_LastByte_Tamper_ShouldFail;
    procedure Test_AESGCM_TagLen_Switch_Independence;
    procedure Test_AESGCM_Tag12_EmptyPT_TamperFirstTagByte_ShouldFail;
    procedure Test_AESGCM_Tag12_TamperFirstAndLastTagBytes_ShouldFail;
    procedure Test_AESGCM_Tag12_TamperCT_NearTagBoundary_ShouldFail;
    // ChaCha20-Poly1305
    procedure Test_ChaCha_Open_TooShort_ShouldRaise;
    procedure Test_ChaCha_OpenAppend_TamperCT_ShouldNotPolluteDst;
    procedure Test_ChaCha_OpenAppend_AAD_Modified_ShouldNotPolluteLen;
    procedure Test_ChaCha_OpenInPlace_TagTamper_NoModify;
    procedure Test_ChaCha_OpenInPlace_AAD_Modified_LenUnchanged;
    // New: non-16-aligned AAD cases
    procedure Test_ChaCha_OpenAppend_AAD_NonAligned_ShouldNotPolluteLen;
    procedure Test_ChaCha_OpenInPlace_AAD_NonAligned_LenUnchanged;
    // New: GCM TagLen=12 boundary cases
    procedure Test_AESGCM_Tag12_Boundary_AAD1_PT0_TamperTag_ShouldFail;
    procedure Test_AESGCM_Tag12_Boundary_AAD17_PT15_TamperCTLast_ShouldFail;

  end;


procedure TTestCase_AEAD_TamperMore.Test_AESGCM_AAD_LastByte_Tamper_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  FillSeqBytes(Key, 32, 7, 3);
  FillSeqBytes(Nonce, 12, 11, 5);
  FillSeqBytes(AAD, 33, 5, 1);
  FillSeqBytes(PT, 64, 17, 1);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // tamper last AAD byte
  AAD[High(AAD)] := AAD[High(AAD)] xor $FF;
  AssertTrue('tamper AAD last byte should raise', Expect_Open_Raises(AEAD, Nonce, AAD, CT));
end;

procedure TTestCase_AEAD_TamperMore.Test_AESGCM_TagLen_Switch_Independence;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT, Dec: TBytes;
begin
  FillSeqBytes(Key, 32, 3, 1);
  FillSeqBytes(Nonce, 12, 1, 3);
  SetLength(AAD, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key);
  // Round 1: TagLen=12
  AEAD.SetTagLength(12);
  FillSeqBytes(PT, 5, 9, 7);
  CT := AEAD.Seal(Nonce, AAD, PT);
  Dec := AEAD.Open(Nonce, AAD, CT);
  AssertEquals(Length(PT), Length(Dec));
  // Round 2: TagLen=16
  AEAD.SetTagLength(16);
  FillSeqBytes(PT, 8, 11, 2);
  CT := AEAD.Seal(Nonce, AAD, PT);
  Dec := AEAD.Open(Nonce, AAD, CT);
  AssertEquals(Length(PT), Length(Dec));
end;

procedure TTestCase_AEAD_TamperMore.Test_AESGCM_Tag12_EmptyPT_TamperFirstTagByte_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  FillSeqBytes(Key, 32, 2, 2);
  FillSeqBytes(Nonce, 12, 3, 1);
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(12, Length(CT));
  CT[0] := CT[0] xor $01;
  AssertTrue('tamper first tag byte should raise', Expect_Open_Raises(AEAD, Nonce, AAD, CT));
end;

procedure TTestCase_AEAD_TamperMore.Test_ChaCha_Open_TooShort_ShouldRaise;
var AEAD: IAEADCipher; Key, Nonce, AAD, CT: TBytes;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 0); SetLength(CT, 15);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('expected EInvalidData');
  except on E:EInvalidData do ; end;
end;

procedure TTestCase_AEAD_TamperMore.Test_ChaCha_OpenAppend_TamperCT_ShouldNotPolluteDst;
var AEAD: IAEADCipher; AEADx: IAEADCipherEx; Key, Nonce, AAD, PT, CT: TBytes; Dst, DstCopy: TBytes; L, W: Integer;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 3); AAD[0]:=1; AAD[1]:=2; AAD[2]:=3;
  SetLength(PT, 10); FillChar(PT[0], 10, 7);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  if not Supports(AEAD, IAEADCipherEx, AEADx) then Fail('append API not supported');
  // produce CT||Tag
  SetLength(Dst, 0);
  W := AEADx.SealAppend(Dst, Nonce, AAD, PT);
  AssertTrue('w>0', W > 0);
  CT := Copy(Dst, 0, Length(Dst));
  // tamper middle ciphertext byte
  L := Length(PT);
  if L > 0 then CT[L div 2] := CT[L div 2] xor $FF;
  // prepare dst and copy
  SetLength(Dst, 4); Dst[0]:=1; Dst[1]:=2; Dst[2]:=3; Dst[3]:=4;
  DstCopy := Copy(Dst, 0, Length(Dst));
  try
    AEADx.OpenAppend(Dst, Nonce, AAD, CT);
    Fail('expected EInvalidData');
  except
    on E:EInvalidData do begin
      AssertEquals(Length(DstCopy), Length(Dst));
      AssertTrue('dst not polluted', CompareByte(DstCopy[0], Dst[0], Length(Dst)) = 0);
    end;
  end;
end;

procedure TTestCase_AEAD_TamperMore.Test_ChaCha_OpenInPlace_TagTamper_NoModify;
var AEAD: IAEADCipher; AEADp: IAEADCipherEx2; Key, Nonce, AAD, PT, CTag: TBytes; L, OldLen: Integer;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 0); SetLength(PT, 5); FillChar(PT[0], 5, 9);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  if not Supports(AEAD, IAEADCipherEx2, AEADp) then Fail('in-place API not supported');
  // build C||Tag into buffer
  CTag := PT;
  L := AEADp.SealInPlace(CTag, Nonce, AAD);
  AssertTrue('out length >= tag', L >= 16);
  OldLen := Length(CTag);
  // tamper tag
  CTag[High(CTag)] := CTag[High(CTag)] xor $01;
  try
    AEADp.OpenInPlace(CTag, Nonce, AAD);
    Fail('expected EInvalidData');
  except
    on E:EInvalidData do begin
      // for in-place API,仅保证失败后长度不变（不承诺内容不变）
      AssertEquals('length not changed after failure', OldLen, Length(CTag));
    end;
  end;
end;
procedure TTestCase_AEAD_TamperMore.Test_AESGCM_Tag12_TamperFirstAndLastTagBytes_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  FillSeqBytes(Key, 32, 2, 5);
  FillSeqBytes(Nonce, 12, 7, 1);
  SetLength(AAD, 0); SetLength(PT, 4);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(Length(PT)+12, Length(CT));
  CT[High(CT)] := CT[High(CT)] xor $80;
  CT[Length(PT)] := CT[Length(PT)] xor $01;
  AssertTrue('first/last tag bytes tamper should raise', Expect_Open_Raises(AEAD, Nonce, AAD, CT));
end;

procedure TTestCase_AEAD_TamperMore.Test_AESGCM_Tag12_TamperCT_NearTagBoundary_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; L: Integer;
begin
  FillSeqBytes(Key, 32, 3, 7);
  FillSeqBytes(Nonce, 12, 5, 3);
  SetLength(AAD, 1); AAD[0] := 1;
  SetLength(PT, 15);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  L := Length(PT);
  if L > 0 then begin
    CT[L-1] := CT[L-1] xor $01; // 密文最后一字节
  end;
  AssertTrue('tamper ct at boundary should raise', Expect_Open_Raises(AEAD, Nonce, AAD, CT));
end;

procedure TTestCase_AEAD_TamperMore.Test_ChaCha_OpenAppend_AAD_Modified_ShouldNotPolluteLen;
var AEAD: IAEADCipher; Ex: IAEADCipherEx; Key, Nonce, AAD, PT, CT: TBytes; Dst: TBytes; OldLen: Integer;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 4); AAD[0]:=1; AAD[1]:=2; AAD[2]:=3; AAD[3]:=4;
  SetLength(PT, 8); FillChar(PT[0], 8, 9);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  if not Supports(AEAD, IAEADCipherEx, Ex) then Fail('append API not supported');
  // 生成 CT
  CT := AEAD.Seal(Nonce, AAD, PT);
  // 修改 AAD
  AAD[2] := AAD[2] xor $FF;
  SetLength(Dst, 3); Dst[0]:=7; Dst[1]:=8; Dst[2]:=9; OldLen := Length(Dst);
  try
    Ex.OpenAppend(Dst, Nonce, AAD, CT);
    Fail('expected EInvalidData');
  except
    on E:EInvalidData do AssertEquals('len unchanged', OldLen, Length(Dst));
  end;
end;

procedure TTestCase_AEAD_TamperMore.Test_ChaCha_OpenInPlace_AAD_Modified_LenUnchanged;
var AEAD: IAEADCipher; Ex2: IAEADCipherEx2; Key, Nonce, AAD, PT, Buf: TBytes; L, OldLen: Integer;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 2); AAD[0]:=5; AAD[1]:=6;
  SetLength(PT, 6); FillChar(PT[0], 6, 1);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  if not Supports(AEAD, IAEADCipherEx2, Ex2) then Fail('in-place API not supported');
  Buf := Copy(PT, 0, Length(PT));
  L := Ex2.SealInPlace(Buf, Nonce, AAD);
  AssertTrue('sealed len >= PT', L >= Length(PT)+16);
  OldLen := Length(Buf);
  AAD[1] := AAD[1] xor $33; // 修改 AAD
  try
    Ex2.OpenInPlace(Buf, Nonce, AAD);
    Fail('expected EInvalidData');
  except
    on E:EInvalidData do AssertEquals('len unchanged', OldLen, Length(Buf));
  end;
end;

// New tests: non-16-aligned AAD for ChaCha Append/InPlace
procedure TTestCase_AEAD_TamperMore.Test_ChaCha_OpenAppend_AAD_NonAligned_ShouldNotPolluteLen;
var AEAD: IAEADCipher; Ex: IAEADCipherEx; Key, Nonce, AAD, PT, CT: TBytes; Dst, DstCopy: TBytes; L, OldLen: Integer;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 5); AAD[0]:=1; AAD[1]:=2; AAD[2]:=3; AAD[3]:=4; AAD[4]:=5; // 非16对齐
  SetLength(PT, 9); FillChar(PT[0], 9, 7);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  if not Supports(AEAD, IAEADCipherEx, Ex) then Fail('append API not supported');
  // 生成正确 CT
  CT := AEAD.Seal(Nonce, AAD, PT);
  // 篡改 AAD
  AAD[1] := AAD[1] xor $AA;
  // 准备 Dst
  SetLength(Dst, 2); Dst[0]:=11; Dst[1]:=22; DstCopy := Copy(Dst, 0, Length(Dst)); OldLen := Length(Dst);
  try
    Ex.OpenAppend(Dst, Nonce, AAD, CT);
    Fail('expected EInvalidData');
  except
    on E:EInvalidData do begin
      AssertEquals('len unchanged', OldLen, Length(Dst));
      AssertTrue('content unchanged', CompareByte(DstCopy[0], Dst[0], OldLen) = 0);
    end;
  end;
end;

procedure TTestCase_AEAD_TamperMore.Test_ChaCha_OpenInPlace_AAD_NonAligned_LenUnchanged;
var AEAD: IAEADCipher; Ex2: IAEADCipherEx2; Key, Nonce, AAD, PT, Buf: TBytes; L, OldLen: Integer;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 3); AAD[0]:=9; AAD[1]:=8; AAD[2]:=7; // 非16对齐
  SetLength(PT, 7); FillChar(PT[0], 7, 1);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  if not Supports(AEAD, IAEADCipherEx2, Ex2) then Fail('in-place API not supported');
  Buf := Copy(PT, 0, Length(PT));
  L := Ex2.SealInPlace(Buf, Nonce, AAD);
  AssertTrue('sealed', L >= Length(PT)+16);
  OldLen := Length(Buf);
  // 篡改 AAD
  AAD[0] := AAD[0] xor $5A;
  try
    Ex2.OpenInPlace(Buf, Nonce, AAD);
    Fail('expected EInvalidData');
  except
    on E:EInvalidData do AssertEquals('len unchanged', OldLen, Length(Buf));
  end;
end;

// New tests: AES-GCM TagLen=12 boundaries
procedure TTestCase_AEAD_TamperMore.Test_AESGCM_Tag12_Boundary_AAD1_PT0_TamperTag_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  FillSeqBytes(Key, 32, 5, 1); FillSeqBytes(Nonce, 12, 2, 9);
  SetLength(AAD, 1); AAD[0] := 1; SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // 翻转 Tag 首尾字节
  CT[0] := CT[0] xor $01; CT[High(CT)] := CT[High(CT)] xor $80;
  AssertTrue('tamper tag should raise', Expect_Open_Raises(AEAD, Nonce, AAD, CT));
end;

procedure TTestCase_AEAD_TamperMore.Test_AESGCM_Tag12_Boundary_AAD17_PT15_TamperCTLast_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; L: Integer;
begin
  FillSeqBytes(Key, 32, 7, 3); FillSeqBytes(Nonce, 12, 1, 7);
  SetLength(AAD, 17); FillChar(AAD[0], 17, 2);
  SetLength(PT, 15); FillChar(PT[0], 15, 4);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  L := Length(PT); if L > 0 then CT[L-1] := CT[L-1] xor $FF; // 紧邻 Tag 边界
  AssertTrue('tamper ct last should raise', Expect_Open_Raises(AEAD, Nonce, AAD, CT));
end;



procedure RegisterTests;
begin
  RegisterTest(TTestCase_AEAD_TamperMore);
end;

initialization
  RegisterTests;

end.

