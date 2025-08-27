{$CODEPAGE UTF8}
unit Test_aead_gcm_kat_minimal_vectors;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm,
  fafafa.core.crypto;

type
  TTestCase_AES_GCM_KAT_Minimal = class(TTestCase)
  private
    function HexToBytesChecked(const S: string): TBytes;
  published
    // TagLen=16
    procedure Test_T16_EmptyAAD_EmptyPT;
    procedure Test_T16_ShortAAD_ShortPT;
    procedure Test_T16_LongAAD_LongPT;
    // TagLen=12
    procedure Test_T12_EmptyAAD_EmptyPT;
    procedure Test_T12_ShortAAD_ShortPT;
    procedure Test_T12_LongAAD_LongPT;
    // Tamper negative
    procedure Test_T16_Tamper_CipherByte;
    procedure Test_T12_Tamper_TagByte;
  end;

implementation

function TTestCase_AES_GCM_KAT_Minimal.HexToBytesChecked(const S: string): TBytes;
var i, n: Integer;
begin
  if (Length(S) mod 2) <> 0 then
    raise Exception.Create('Invalid hex string length: ' + IntToStr(Length(S)));
  n := Length(S) div 2;
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := StrToInt('$' + Copy(S, i*2 + 1, 2));
end;

// The following small KATs are sourced or constructed to be deterministic;
// they serve as additional anchors in addition to the more complete NIST KAT set.

procedure TTestCase_AES_GCM_KAT_Minimal.Test_T16_EmptyAAD_EmptyPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  Key := HexToBytesChecked('feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308');
  Nonce := HexToBytesChecked('cafebabefacedbaddecaf888');
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // 非严格：仅断言长度与往返
  AssertEquals(16, Length(CT));
  AssertEquals(0, Length(AEAD.Open(Nonce, AAD, CT)));
end;

procedure TTestCase_AES_GCM_KAT_Minimal.Test_T16_ShortAAD_ShortPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  Key := HexToBytesChecked('0000000000000000000000000000000000000000000000000000000000000000');
  Nonce := HexToBytesChecked('000000000000000000000000');
  AAD := HexToBytesChecked('0001020304050607');
  PT := HexToBytesChecked('202122232425262728292a2b2c2d2e2f');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // 非严格：仅断言长度与往返
  AssertEquals(32, Length(CT));
  AssertTrue('roundtrip', SecureCompare(AEAD.Open(Nonce, AAD, CT), PT));
end;

procedure TTestCase_AES_GCM_KAT_Minimal.Test_T16_LongAAD_LongPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := i;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := i+1;
  SetLength(AAD, 1024); for i := 0 to High(AAD) do AAD[i] := i and $FF;
  SetLength(PT, 2048); for i := 0 to High(PT) do PT[i] := (i*7) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(2048+16, Length(CT));
  AssertTrue('roundtrip', SecureCompare(AEAD.Open(Nonce, AAD, CT), PT));
end;

procedure TTestCase_AES_GCM_KAT_Minimal.Test_T12_EmptyAAD_EmptyPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  Key := HexToBytesChecked('feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308');
  Nonce := HexToBytesChecked('cafebabefacedbaddecaf888');
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(12, Length(CT));
  AssertEquals(0, Length(AEAD.Open(Nonce, AAD, CT)));
end;

procedure TTestCase_AES_GCM_KAT_Minimal.Test_T12_ShortAAD_ShortPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  Key := HexToBytesChecked('0000000000000000000000000000000000000000000000000000000000000000');
  Nonce := HexToBytesChecked('000000000000000000000000');
  AAD := HexToBytesChecked('0001020304050607');
  PT := HexToBytesChecked('202122232425262728292a2b2c2d2e2f');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(16+12, Length(CT));
  AssertTrue('roundtrip', SecureCompare(AEAD.Open(Nonce, AAD, CT), PT));
end;

procedure TTestCase_AES_GCM_KAT_Minimal.Test_T12_LongAAD_LongPT;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := i;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := i+1;
  SetLength(AAD, 1024); for i := 0 to High(AAD) do AAD[i] := i and $FF;
  SetLength(PT, 2048); for i := 0 to High(PT) do PT[i] := (i*7) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(2048+12, Length(CT));
  AssertTrue('roundtrip', SecureCompare(AEAD.Open(Nonce, AAD, CT), PT));
end;

procedure TTestCase_AES_GCM_KAT_Minimal.Test_T16_Tamper_CipherByte;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  Key := HexToBytesChecked('feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308');
  Nonce := HexToBytesChecked('cafebabefacedbaddecaf888');
  SetLength(AAD, 0); PT := HexToBytesChecked('000102030405060708090a0b0c0d0e0f');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CT := AEAD.Seal(Nonce, AAD, PT);
  if Length(CT) > 5 then CT[5] := CT[5] xor $80;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('tamper should raise');
  except on E: EInvalidData do ; end;
end;

procedure TTestCase_AES_GCM_KAT_Minimal.Test_T12_Tamper_TagByte;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  Key := HexToBytesChecked('feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308');
  Nonce := HexToBytesChecked('cafebabefacedbaddecaf888');
  SetLength(AAD, 0); PT := HexToBytesChecked('000102030405060708090a0b0c0d0e0f');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  if Length(CT) > 0 then CT[High(CT)] := CT[High(CT)] xor $01;
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('tamper should raise');
  except on E: EInvalidData do ; end;
end;

initialization
  RegisterTest(TTestCase_AES_GCM_KAT_Minimal);

{$POP}
end.

