{$CODEPAGE UTF8}
unit Test_aead_gcm_kat12_invariants;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm,
  fafafa.core.crypto.utils;

type
  TTestCase_AES_GCM_KAT12_Invariants = class(TTestCase)
  published
    procedure Test_API_Contract_Tag12;
    procedure Test_TamperTag_ShouldFail_Tag12;
  end;

implementation

procedure TTestCase_AES_GCM_KAT12_Invariants.Test_API_Contract_Tag12;
var AEAD: IAEADCipher;
begin
  AEAD := CreateAES256GCM_Impl;
  AEAD.SetTagLength(12);
  AssertEquals('overhead=12', 12, AEAD.Overhead);
end;

procedure TTestCase_AES_GCM_KAT12_Invariants.Test_TamperTag_ShouldFail_Tag12;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 7);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 9);
  SetLength(AAD, 3); AAD[0]:=9; AAD[1]:=8; AAD[2]:=7;
  SetLength(PT, 16); PT[0]:=0; PT[15]:=255;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT||Tag)=|PT|+12', Length(PT)+12, Length(CT));
  // flip last byte of tag
  CT[High(CT)] := CT[High(CT)] xor $01;
  try AEAD.Open(Nonce, AAD, CT); Fail('tampered tag should raise'); except on E: EInvalidData do ; end;
end;

initialization
  RegisterTest(TTestCase_AES_GCM_KAT12_Invariants);

end.

