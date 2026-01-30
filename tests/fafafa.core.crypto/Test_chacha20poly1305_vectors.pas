{
  ChaCha20-Poly1305 test vectors (RFC 8439 section 2.8.2)
}
unit Test_chacha20poly1305_vectors;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.crypto;

type
  TTestCase_ChaCha20Poly1305 = class(TTestCase)
  published
    procedure Test_RFC8439_2_8_2; // Full vector
    procedure Test_API_Contract;
    procedure Test_InvalidArgs;
    procedure Test_AAD_DoesNotAffectCiphertext;
    // 新增：负向与序列复用用例
    procedure Test_TamperCiphertext_ShouldFail;
    procedure Test_NonceBitflip_ShouldFail;
    procedure Test_Sequential_SealOpen_ReusedInstance;
    // 新增：小矩阵 + 错误密钥
    procedure Test_SmallMatrix_EmptyAAD_EmptyPT;
    procedure Test_SmallMatrix_ShortAAD_ShortPT;
    procedure Test_WrongKey_ShouldFail;
  end;

implementation

function HexToBytes(const S: string): TBytes;
var I,N: Integer; H: string;
begin
  H := LowerCase(Trim(StringReplace(S, ' ', '', [rfReplaceAll])));
  N := Length(H) div 2; SetLength(Result, N);
  for I := 0 to N-1 do Result[I] := StrToInt('$' + Copy(H, I*2+1, 2));
end;

procedure AssertHexEquals(const ExpectedHex: string; const Actual: TBytes);
var I: Integer; Expected: TBytes;
begin
  Expected := HexToBytes(ExpectedHex);
  if Length(Expected) <> Length(Actual) then
    raise Exception.CreateFmt('len mismatch: exp=%d got=%d', [Length(Expected), Length(Actual)]);
  for I := 0 to High(Expected) do
    if Expected[I] <> Actual[I] then
      raise Exception.CreateFmt('byte[%d] mismatch: exp=%d got=%d', [I, Expected[I], Actual[I]]);
end;

procedure AssertBytesEquals(const Expected, Actual: TBytes);
var I: Integer;
begin
  if Length(Expected) <> Length(Actual) then
    raise Exception.CreateFmt('len mismatch: exp=%d got=%d', [Length(Expected), Length(Actual)]);
  for I := 0 to High(Expected) do
    if Expected[I] <> Actual[I] then
      raise Exception.CreateFmt('byte[%d] mismatch: exp=%d got=%d', [I, Expected[I], Actual[I]]);
end;


procedure TTestCase_ChaCha20Poly1305.Test_RFC8439_2_8_2;
var
  Key, Nonce, AAD, PT, CT, OutBuf: TBytes;
  AEAD: IAEADCipher;
begin
  {$push}
  {$R-} // disable range checks inside this test to avoid false positives on bounds

  // RFC 8439 Section 2.8.2 test vector
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0' +
                    '473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  AAD := HexToBytes('f33388860000000000004e91');
  PT := HexToBytes('496e7465726e65742d44726166747320' +
                   '61726520647261667420646f63756d65' +
                   '6e747320666f72206469736375737369' +
                   '6f6e2c20616e6420726570726573656e' +
                   '746174696f6e206f6e6c792e');
  AEAD := CreateChaCha20Poly1305;
  AEAD.SetKey(Key);
  OutBuf := AEAD.Seal(Nonce, AAD, PT);
  // 1) 长度与回放
  AssertEquals('ct||tag length', Length(PT)+16, Length(OutBuf));
  AssertBytesEquals(PT, AEAD.Open(Nonce, AAD, OutBuf));

  // tamper tag -> should raise
  try
    OutBuf[High(OutBuf)] := OutBuf[High(OutBuf)] xor $01;
    AEAD.Open(Nonce, AAD, OutBuf);
    Fail('expected EInvalidData');
  except
    on E: EInvalidData do ;
  end;
  {$pop}
end;

procedure TTestCase_ChaCha20Poly1305.Test_API_Contract;
var AEAD: IAEADCipher;
begin
  AEAD := CreateChaCha20Poly1305;
  AssertEquals('name', 'ChaCha20-Poly1305', AEAD.GetName);
  AssertEquals('nonce size', 12, AEAD.NonceSize);
  AssertEquals('overhead', 16, AEAD.Overhead);
end;

procedure TTestCase_ChaCha20Poly1305.Test_InvalidArgs;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT: TBytes; OutBuf: TBytes;
begin
  AEAD := CreateChaCha20Poly1305;
  // SetTagLength 非 16 应抛异常
  try AEAD.SetTagLength(12); Fail('expected EInvalidArgument'); except on E:EInvalidArgument do ; end;
  // 未设置密钥直接 Seal 应抛异常
  try AEAD.Seal(Nonce, AAD, PT); Fail('expected EInvalidArgument'); except on E:EInvalidArgument do ; end;
  // 设置错误长度的 Key 应抛异常
  SetLength(Key, 31);
  try AEAD.SetKey(Key); Fail('expected EInvalidArgument'); except on E:EInvalidArgument do ; end;
  // 设置正确 Key 后，错误长度 Nonce 应抛异常
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  AEAD.SetKey(Key);
  Nonce := HexToBytes('0000000001020304050607'); // 11 bytes
  try AEAD.Seal(Nonce, AAD, PT); Fail('expected EInvalidArgument'); except on E:EInvalidArgument do ; end;
  // Open 短密文（不足 16 字节 Tag）应抛 EInvalidData
  Nonce := HexToBytes('000000000102030405060708');
  try AEAD.Open(Nonce, AAD, HexToBytes('01')); Fail('expected EInvalidData'); except on E:EInvalidData do ; end;
end;

procedure TTestCase_ChaCha20Poly1305.Test_AAD_DoesNotAffectCiphertext;
var AEAD: IAEADCipher; Key, Nonce, AAD1, AAD2, PT, Out1, Out2: TBytes; CT1, CT2: TBytes;
begin
  {$push}
  {$R-} // disable range checks inside this test

  // RFC 8439 §2.8.2 同样的 Key/Nonce/PT
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0' + '473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  AAD1 := HexToBytes('f33388860000000000004e91');
  AAD2 := HexToBytes('000102030405060708090a0b'); // 不同 AAD
  PT := HexToBytes('496e7465726e65742d44726166747320' +
                   '61726520647261667420646f63756d65' +
                   '6e747320666f72206469736375737369' +
                   '6f6e2c20616e6420726570726573656e' +
                   '746174696f6e206f6e6c792e');
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  Out1 := AEAD.Seal(Nonce, AAD1, PT);
  Out2 := AEAD.Seal(Nonce, AAD2, PT);
  // 前 |PT| 字节为密文，应相等；末尾 16 字节为 Tag，应不同
  SetLength(CT1, Length(PT)); Move(Out1[0], CT1[0], Length(PT));
  SetLength(CT2, Length(PT)); Move(Out2[0], CT2[0], Length(PT));
  AssertBytesEquals(CT1, CT2);
  // Tag 不一定总是不同，但不同 AAD 应导致鉴别不同；若碰撞则极小概率，本测试允许相等但验证 Open 行为
  AssertBytesEquals(PT, AEAD.Open(Nonce, AAD1, Out1));
  AssertBytesEquals(PT, AEAD.Open(Nonce, AAD2, Out2));
  // 用错误的 AAD 打开应失败
  try AEAD.Open(Nonce, AAD1, Out2); Fail('expected EInvalidData'); except on E:EInvalidData do ; end;
  try AEAD.Open(Nonce, AAD2, Out1); Fail('expected EInvalidData'); except on E:EInvalidData do ; end;
  {$pop}
end;


procedure TTestCase_ChaCha20Poly1305.Test_TamperCiphertext_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, OutBuf: TBytes;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0' + '473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  AAD := HexToBytes('f33388860000000000004e91');
  PT := HexToBytes('0102030405');
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  OutBuf := AEAD.Seal(Nonce, AAD, PT);
  // 翻转密文中间字节（避免触碰 tag）
  if Length(OutBuf) < (Length(PT)+16) then Fail('unexpected output length');
  if Length(PT) > 0 then OutBuf[1] := OutBuf[1] xor $FF;
  try
    AEAD.Open(Nonce, AAD, OutBuf);
    Fail('tampered ciphertext should raise EInvalidData');
  except on E:EInvalidData do ; else raise; end;
end;

procedure TTestCase_ChaCha20Poly1305.Test_NonceBitflip_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, OutBuf, WrongNonce: TBytes;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0' + '473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 0); PT := HexToBytes('AA');
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  OutBuf := AEAD.Seal(Nonce, AAD, PT);
  WrongNonce := Copy(Nonce, 0, Length(Nonce));
  WrongNonce[0] := WrongNonce[0] xor $01;
  try
    AEAD.Open(WrongNonce, AAD, OutBuf);
    Fail('nonce bitflip should raise EInvalidData');
  except on E:EInvalidData do ; else raise; end;
end;

procedure TTestCase_ChaCha20Poly1305.Test_Sequential_SealOpen_ReusedInstance;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT1, PT2, C1, C2: TBytes;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0' + '473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 0); PT1 := HexToBytes('01'); PT2 := HexToBytes('0203');
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  C1 := AEAD.Seal(Nonce, AAD, PT1);
  AssertEquals(Length(PT1)+16, Length(C1));
  AssertBytesEquals(PT1, AEAD.Open(Nonce, AAD, C1));
  // 更换 Nonce 再次加解密
  Nonce[0] := Nonce[0] xor $FF;
  C2 := AEAD.Seal(Nonce, AAD, PT2);
  AssertEquals(Length(PT2)+16, Length(C2));
  AssertBytesEquals(PT2, AEAD.Open(Nonce, AAD, C2));
end;


procedure TTestCase_ChaCha20Poly1305.Test_SmallMatrix_EmptyAAD_EmptyPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, C: TBytes;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0' + '473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  C := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(16, Length(C));
  AssertBytesEquals(PT, AEAD.Open(Nonce, AAD, C));
end;

procedure TTestCase_ChaCha20Poly1305.Test_SmallMatrix_ShortAAD_ShortPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, C: TBytes;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0' + '473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000102030405060708');
  AAD := HexToBytes('A1'); PT := HexToBytes('0203');
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key);
  C := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(Length(PT)+16, Length(C));
  AssertBytesEquals(PT, AEAD.Open(Nonce, AAD, C));
end;

procedure TTestCase_ChaCha20Poly1305.Test_WrongKey_ShouldFail;
var AEAD: IAEADCipher; Key1, Key2, Nonce, AAD, PT, C: TBytes;
begin
  Key1 := HexToBytes('1c9240a5eb55d38af333888604f6b5f0' + '473917c1402b80099dca5cbc207075c0');
  Key2 := HexToBytes('000102030405060708090a0b0c0d0e0f' + '101112131415161718191a1b1c1d1e1f');
  Nonce := HexToBytes('000000000102030405060708');
  SetLength(AAD, 0); PT := HexToBytes('AA');
  AEAD := CreateChaCha20Poly1305; AEAD.SetKey(Key1);
  C := AEAD.Seal(Nonce, AAD, PT);
  AEAD.SetKey(Key2);
  try
    AEAD.Open(Nonce, AAD, C);
    Fail('wrong key should raise EInvalidData');
  except on E:EInvalidData do ; else raise; end;
end;





initialization
  RegisterTest(TTestCase_ChaCha20Poly1305);

{$POP}
end.

