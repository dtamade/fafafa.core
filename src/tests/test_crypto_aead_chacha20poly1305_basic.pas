unit test_crypto_aead_chacha20poly1305_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.crypto;

procedure RegisterTests_ChaCha20Poly1305_Basic;

implementation

type
  TChaCha20Poly1305_Basic = class(TTestCase)
  published
    procedure Test_SealOpen_Roundtrip_Basic;
    procedure Test_Open_TamperedTag_Fails;
    procedure Test_Open_WrongNonce_Fails;
  end;

procedure TChaCha20Poly1305_Basic.Test_SealOpen_Roundtrip_Basic;
var
  C: IAEADCipher;
  Key, Nonce, AAD, PT, CT: TBytes;
  Opened: TBytes;
begin
  // fixed test vectors (not KAT), purpose: roundtrip correctness and non-crash
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000000000000000002');
  AAD := HexToBytes('f33388860000000000004e91');
  PT := HexToBytes('496e7465726f7065726162696c6974792069732061206d616e792073706c656e646f72656420776f7264');

  C := CreateChaCha20Poly1305;
  C.SetKey(Key);
  CT := C.Seal(Nonce, AAD, PT);
  AssertTrue('ciphertext+tag length must be PT+16', Length(CT) = Length(PT) + 16);
  Opened := C.Open(Nonce, AAD, CT);
  AssertTrue('opened plaintext length mismatch', Length(Opened) = Length(PT));
  AssertTrue('roundtrip plaintext mismatch', SecureCompare(Opened, PT));
end;

procedure TChaCha20Poly1305_Basic.Test_Open_TamperedTag_Fails;
var
  C: IAEADCipher;
  Key, Nonce, AAD, PT, CT: TBytes;
  Raised: Boolean;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000000000000000002');
  AAD := HexToBytes('f33388860000000000004e91');
  PT := HexToBytes('4c616469657320616e642047656e746c656d656e206f662074686520636c617373206f662039393a');

  C := CreateChaCha20Poly1305;
  C.SetKey(Key);
  CT := C.Seal(Nonce, AAD, PT);
  // tamper last byte of tag
  CT[High(CT)] := CT[High(CT)] xor $01;
  Raised := False;
  try
    C.Open(Nonce, AAD, CT);
  except
    on E: EInvalidData do Raised := True;
  end;
  AssertTrue('Open must raise EInvalidData on tag mismatch', Raised);
end;

procedure TChaCha20Poly1305_Basic.Test_Open_WrongNonce_Fails;
var
  C: IAEADCipher;
  Key, Nonce, BadNonce, AAD, PT, CT: TBytes;
  Raised: Boolean;
begin
  Key := HexToBytes('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
  Nonce := HexToBytes('000000000000000000000002');
  BadNonce := HexToBytes('000000000000000000000003');
  AAD := HexToBytes('f33388860000000000004e91');
  PT := HexToBytes('746861742069732077687920776520706c6179207468652067616d6520736f206d756368');

  C := CreateChaCha20Poly1305;
  C.SetKey(Key);
  CT := C.Seal(Nonce, AAD, PT);
  Raised := False;
  try
    C.Open(BadNonce, AAD, CT);
  except
    on E: EInvalidData do Raised := True;
  end;
  AssertTrue('Open must raise EInvalidData on wrong nonce', Raised);
end;

procedure RegisterTests_ChaCha20Poly1305_Basic;
begin
  RegisterTest('crypto-aead-chacha20poly1305-basic', TChaCha20Poly1305_Basic);
end;

end.

