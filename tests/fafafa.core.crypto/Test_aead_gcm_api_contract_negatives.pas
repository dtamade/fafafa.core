{$CODEPAGE UTF8}
unit Test_aead_gcm_api_contract_negatives;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm;

type
  TTestCase_AES_GCM_API_Negatives = class(TTestCase)
  published
    procedure Test_SetKey_InvalidLen_ShouldRaise;
    procedure Test_SetTagLength_OutOfRange_ShouldRaise;
    procedure Test_Seal_WithoutKey_ShouldRaise;
    procedure Test_Open_WithoutKey_ShouldRaise;
    procedure Test_Seal_InvalidNonceLen_ShouldRaise;
    procedure Test_Open_InvalidNonceLen_ShouldRaise;
  end;

implementation

procedure TTestCase_AES_GCM_API_Negatives.Test_SetKey_InvalidLen_ShouldRaise;
var AEAD: IAEADCipher; BadKey: TBytes;
begin
  AEAD := CreateAES256GCM_Impl;
  SetLength(BadKey, 31);
  try
    AEAD.SetKey(BadKey);
    Fail('expected EInvalidKey');
  except
    on E: EInvalidKey do ;
  end;
end;

procedure TTestCase_AES_GCM_API_Negatives.Test_SetTagLength_OutOfRange_ShouldRaise;
var AEAD: IAEADCipher;
begin
  AEAD := CreateAES256GCM_Impl;
  try
    AEAD.SetTagLength(3);
    Fail('expected EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
  try
    AEAD.SetTagLength(17);
    Fail('expected EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_AES_GCM_API_Negatives.Test_Seal_WithoutKey_ShouldRaise;
var AEAD: IAEADCipher; Nonce, AAD, PT: TBytes;
begin
  AEAD := CreateAES256GCM_Impl;
  SetLength(Nonce, 12);
  SetLength(AAD, 0);
  SetLength(PT, 0);
  try
    AEAD.Seal(Nonce, AAD, PT);
    Fail('expected EInvalidOperation');
  except
    on E: EInvalidOperation do ;
  end;
end;

procedure TTestCase_AES_GCM_API_Negatives.Test_Open_WithoutKey_ShouldRaise;
var AEAD: IAEADCipher; Nonce, AAD, CT: TBytes;
begin
  AEAD := CreateAES256GCM_Impl;
  SetLength(Nonce, 12);
  SetLength(AAD, 0);
  SetLength(CT, 16); // tag-only length to avoid trivial length errors later
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('expected EInvalidOperation');
  except
    on E: EInvalidOperation do ;
  end;
end;

procedure TTestCase_AES_GCM_API_Negatives.Test_Seal_InvalidNonceLen_ShouldRaise;
var AEAD: IAEADCipher; Nonce, AAD, PT, Key: TBytes;
begin
  AEAD := CreateAES256GCM_Impl;
  SetLength(Key, 32); FillChar(Key[0], 32, 7);
  AEAD.SetKey(Key);
  SetLength(Nonce, 11); // invalid
  SetLength(AAD, 0);
  SetLength(PT, 0);
  try
    AEAD.Seal(Nonce, AAD, PT);
    Fail('expected EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_AES_GCM_API_Negatives.Test_Open_InvalidNonceLen_ShouldRaise;
var AEAD: IAEADCipher; Nonce, AAD, CT, Key: TBytes;
begin
  AEAD := CreateAES256GCM_Impl;
  SetLength(Key, 32); FillChar(Key[0], 32, 7);
  AEAD.SetKey(Key);
  SetLength(Nonce, 13); // invalid
  SetLength(AAD, 0);
  SetLength(CT, 0); // ciphertext empty; should still fail on nonce length first
  try
    AEAD.Open(Nonce, AAD, CT);
    Fail('expected EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

initialization
  RegisterTest(TTestCase_AES_GCM_API_Negatives);

{$POP}
end.

