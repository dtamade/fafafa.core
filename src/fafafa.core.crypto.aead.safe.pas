{
  Safe AEAD helpers: nonce-managed one-shot APIs that reduce misuse risk.
  - AES-256-GCM combined format: Nonce(12) || Ciphertext||Tag(tagLen)
  - ChaCha20-Poly1305 combined format: Nonce(12) || Ciphertext||Tag(16)

  These helpers do not change existing AEAD APIs; they provide convenience functions.
}
unit fafafa.core.crypto.aead.safe;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.aead.gcm,
  fafafa.core.crypto.aead.chacha20poly1305,
  fafafa.core.crypto.nonce;

type
  TBytes = array of Byte;

// AES-256-GCM (combined output): Nonce(12) || CT||Tag(tagLen)
function AES256GCM_Seal_Combined(const AKey, AAD, PT: TBytes; const NM: INonceManager): TBytes;
function AES256GCM_Open_Combined(const AKey, AAD, Combined: TBytes): TBytes;
// Overloads with explicit tag length (12..16), default is 16 for above helpers
function AES256GCM_Seal_Combined_TL(const AKey, AAD, PT: TBytes; const NM: INonceManager; TagLen: Integer): TBytes;
function AES256GCM_Open_Combined_TL(const AKey, AAD, Combined: TBytes; TagLen: Integer): TBytes;

// ChaCha20-Poly1305 (combined output): Nonce(12) || CT||Tag(16)
function ChaCha20Poly1305_Seal_Combined(const AKey, AAD, PT: TBytes; const NM: INonceManager): TBytes;
function ChaCha20Poly1305_Open_Combined(const AKey, AAD, Combined: TBytes): TBytes;

implementation

const
  NONCE_LEN = 12;
  TAG_LEN   = 16;

function AES256GCM_Seal_Combined_TL(const AKey, AAD, PT: TBytes; const NM: INonceManager; TagLen: Integer): TBytes;
var
  AEAD: IAEADCipher;
  Nonce, CT: TBytes;
  L, CL: Integer;
begin
  Result := nil;
  Nonce := nil;
  CT := nil;
  if NM = nil then
    raise Exception.Create('NonceManager is required');
  if (TagLen < 4) or (TagLen > 16) then
    raise Exception.Create('invalid GCM tag length');
  Nonce := NM.NextGCMNonce12; // counter-based, monotonic
  if Length(Nonce) <> NONCE_LEN then
    raise Exception.Create('AES-GCM requires 12-byte nonce');

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(AKey);
  AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);

  CL := Length(CT);
  L := NONCE_LEN + CL;
  SetLength(Result, L);
  if NONCE_LEN > 0 then Move(Nonce[0], Result[0], NONCE_LEN);
  if CL > 0 then Move(CT[0], Result[NONCE_LEN], CL);
end;

function AES256GCM_Seal_Combined(const AKey, AAD, PT: TBytes; const NM: INonceManager): TBytes;
begin
  Result := AES256GCM_Seal_Combined_TL(AKey, AAD, PT, NM, TAG_LEN);
end;

function AES256GCM_Open_Combined_TL(const AKey, AAD, Combined: TBytes; TagLen: Integer): TBytes;
var
  AEAD: IAEADCipher;
  Nonce, CT: TBytes;
  L: Integer;
begin
  Result := nil;
  Nonce := nil;
  CT := nil;
  if (TagLen < 4) or (TagLen > 16) then
    raise Exception.Create('invalid GCM tag length');
  L := Length(Combined);
  if L < NONCE_LEN + TagLen then
    raise Exception.Create('combined too short');
  SetLength(Nonce, NONCE_LEN);
  Move(Combined[0], Nonce[0], NONCE_LEN);
  SetLength(CT, L - NONCE_LEN);
  if Length(CT) > 0 then Move(Combined[NONCE_LEN], CT[0], Length(CT));

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(AKey);
  AEAD.SetTagLength(TagLen);
  Result := AEAD.Open(Nonce, AAD, CT);
end;

function AES256GCM_Open_Combined(const AKey, AAD, Combined: TBytes): TBytes;
begin
  Result := AES256GCM_Open_Combined_TL(AKey, AAD, Combined, TAG_LEN);
end;

function ChaCha20Poly1305_Seal_Combined(const AKey, AAD, PT: TBytes; const NM: INonceManager): TBytes;
var
  AEAD: IAEADCipher;
  Nonce, CT: TBytes;
  L, CL: Integer;
begin
  Result := nil;
  Nonce := nil;
  CT := nil;
  if NM = nil then
    raise Exception.Create('NonceManager is required');
  // use random unique nonce with history
  Nonce := NM.GenerateUniqueRandomNonce12;
  if Length(Nonce) <> NONCE_LEN then
    raise Exception.Create('ChaCha20-Poly1305 requires 12-byte nonce');

  AEAD := CreateChaCha20Poly1305_Impl;
  AEAD.SetKey(AKey);
  AEAD.SetTagLength(TAG_LEN);
  CT := AEAD.Seal(Nonce, AAD, PT);

  CL := Length(CT);
  L := NONCE_LEN + CL;
  SetLength(Result, L);
  if NONCE_LEN > 0 then Move(Nonce[0], Result[0], NONCE_LEN);
  if CL > 0 then Move(CT[0], Result[NONCE_LEN], CL);
end;

function ChaCha20Poly1305_Open_Combined(const AKey, AAD, Combined: TBytes): TBytes;
var
  AEAD: IAEADCipher;
  Nonce, CT: TBytes;
  L: Integer;
begin
  Result := nil;
  Nonce := nil;
  CT := nil;
  L := Length(Combined);
  if L < NONCE_LEN + TAG_LEN then
    raise Exception.Create('combined too short');
  SetLength(Nonce, NONCE_LEN);
  Move(Combined[0], Nonce[0], NONCE_LEN);
  SetLength(CT, L - NONCE_LEN);
  if Length(CT) > 0 then Move(Combined[NONCE_LEN], CT[0], Length(CT));

  AEAD := CreateChaCha20Poly1305_Impl;
  AEAD.SetKey(AKey);
  AEAD.SetTagLength(TAG_LEN);
  Result := AEAD.Open(Nonce, AAD, CT);
end;

end.

