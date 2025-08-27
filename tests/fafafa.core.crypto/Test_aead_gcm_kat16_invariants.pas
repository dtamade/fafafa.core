{$CODEPAGE UTF8}
unit Test_aead_gcm_kat16_invariants;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm, // for CreateAES256GCM_Impl
  fafafa.core.crypto.utils,
  Test_aead_gcm_vectors; // reuse HexToBytesChecked

type
  TTestCase_AES_GCM_KAT16_Invariants = class(TTestCase)
  published
    procedure Test_API_Contract_Defaults_Tag16;
    procedure Test_Roundtrip_VarLengths_Tag16;
    procedure Test_InvalidNonceSizes_Tag16;
    procedure Test_CiphertextTooShort_Tag16;
    procedure Test_TamperTag_ShouldFail_Tag16;
  end;

implementation

function HexToBytesChecked(const S: string): TBytes;
var
  i, n: Integer;
begin
  if (Length(S) mod 2) <> 0 then
    raise Exception.Create('Invalid hex string length: ' + IntToStr(Length(S)));
  n := Length(S) div 2;
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := StrToInt('$' + Copy(S, i*2 + 1, 2));
end;


procedure TTestCase_AES_GCM_KAT16_Invariants.Test_API_Contract_Defaults_Tag16;
var AEAD: IAEADCipher;
begin
  AEAD := CreateAES256GCM_Impl;
  AssertEquals('name', 'AES-256-GCM', AEAD.GetName);
  AssertEquals('nonce size', 12, AEAD.NonceSize);
  // 默认 TagLen=16 -> Overhead=16
  AssertEquals('overhead=16 by default', 16, AEAD.Overhead);
end;

procedure TTestCase_AES_GCM_KAT16_Invariants.Test_Roundtrip_VarLengths_Tag16;
const PT_LEN: array[0..5] of Integer = (0,1,16,31,32,255);
      AAD_LEN: array[0..2] of Integer = (0,3,16);
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i,j,k: Integer;
begin
  // fixed key/nonce for deterministic KAT-style checks
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*7 + 3) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i*11 + 5) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  for i := Low(PT_LEN) to High(PT_LEN) do
  begin
    SetLength(PT, PT_LEN[i]); for j := 0 to High(PT) do PT[j] := (j*13 + 7) and $FF;
    for j := Low(AAD_LEN) to High(AAD_LEN) do
    begin
      SetLength(AAD, AAD_LEN[j]); for k := 0 to High(AAD) do AAD[k] := (k*3) and $FF;
      CT := AEAD.Seal(Nonce, AAD, PT);
      AssertEquals(Format('len(CT||Tag)=|PT|+16 (pt=%d,aad=%d)', [Length(PT), Length(AAD)]), Length(PT)+16, Length(CT));
      AssertTrue('roundtrip', SecureCompare(AEAD.Open(Nonce, AAD, CT), PT));
    end;
  end;
end;

procedure TTestCase_AES_GCM_KAT16_Invariants.Test_InvalidNonceSizes_Tag16;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  SetLength(PT, 0); SetLength(AAD, 0);
  // Nonce too short (8)
  SetLength(Nonce, 8); FillChar(Nonce[0], 8, 0);
  try AEAD.Seal(Nonce, AAD, PT); Fail('nonce size 8 should raise'); except on E: EInvalidArgument do ; end;
  // Nonce too long (13)
  SetLength(Nonce, 13); FillChar(Nonce[0], 13, 0);
  try AEAD.Seal(Nonce, AAD, PT); Fail('nonce size 13 should raise'); except on E: EInvalidArgument do ; end;
end;

procedure TTestCase_AES_GCM_KAT16_Invariants.Test_CiphertextTooShort_Tag16;
var AEAD: IAEADCipher; Key, Nonce, AAD, ShortBuf: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 0);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 0);
  SetLength(AAD, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  // Open buffer shorter than tag size should fail
  SetLength(ShortBuf, 15);
  try AEAD.Open(Nonce, AAD, ShortBuf); Fail('too short'); except on E: EInvalidData do ; end;
end;

procedure TTestCase_AES_GCM_KAT16_Invariants.Test_TamperTag_ShouldFail_Tag16;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 1);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 2);
  SetLength(AAD, 4); AAD[0]:=1; AAD[1]:=2; AAD[2]:=3; AAD[3]:=4;
  PT := HexToBytesChecked('000102030405060708090A0B0C0D0E0F');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CT := AEAD.Seal(Nonce, AAD, PT);
  // flip last byte of tag
  CT[High(CT)] := CT[High(CT)] xor $01;
  try AEAD.Open(Nonce, AAD, CT); Fail('tampered tag should raise'); except on E: EInvalidData do ; end;
end;

initialization
  RegisterTest(TTestCase_AES_GCM_KAT16_Invariants);

{$POP}
end.

