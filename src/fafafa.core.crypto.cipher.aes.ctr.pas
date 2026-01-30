{
  fafafa.core.crypto.cipher.aes.ctr - AES-CTR mode (skeleton)

  NOTE:
  - This is a minimal skeleton to support upcoming AES-GCM.
  - CTR uses AES block encrypt as keystream; no padding, any length.
}
unit fafafa.core.crypto.cipher.aes.ctr;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.cipher.aes;

type
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  ISymmetricCipher = fafafa.core.crypto.interfaces.ISymmetricCipher;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;

  { IAESCTR }
  IAESCTR = interface
    ['{9E9F0B43-1A0A-4A8E-9B22-0997B4D9C2C4}']
    function GetBlockCipher: ISymmetricCipher;
    procedure SetKey(const AKey: TBytes);
    procedure SetNonceAndCounter(const ANonce: TBytes; const AInitialCounter: UInt32 = 1);
    function Process(const AInput: TBytes): TBytes; // XOR with keystream
    procedure Reset;
    procedure Burn;
  end;

function CreateAESCTR(AKeySizeBytes: Integer = 32): IAESCTR; // default 256-bit

implementation

type
  TAESCTRContext = class(TInterfacedObject, IAESCTR)
  private
    FAES: ISymmetricCipher;
    FNonce: array[0..11] of Byte; // 96-bit recommended
    FCounter: UInt32;
    FNonceSet: Boolean;
    FKS: array[0..15] of Byte;    // buffered keystream block
    FKSPos: Integer;               // 0..16; 16 means empty
  public
    constructor Create(AKeySizeBytes: Integer);
    // IAESCTR
    function GetBlockCipher: ISymmetricCipher;
    procedure SetKey(const AKey: TBytes);
    procedure SetNonceAndCounter(const ANonce: TBytes; const AInitialCounter: UInt32 = 1);
    function Process(const AInput: TBytes): TBytes;
    procedure Reset;
    procedure Burn;
  end;

constructor TAESCTRContext.Create(AKeySizeBytes: Integer);
begin
  inherited Create;
  case AKeySizeBytes of
    16: FAES := fafafa.core.crypto.cipher.aes.CreateAES128;
    24: FAES := fafafa.core.crypto.cipher.aes.CreateAES192;
    32: FAES := fafafa.core.crypto.cipher.aes.CreateAES256;
  else
    raise EInvalidArgument.CreateFmt('Invalid AES key size: %d', [AKeySizeBytes]);
  end;
  Reset;
end;

function TAESCTRContext.GetBlockCipher: ISymmetricCipher;
begin
  Result := FAES;
end;

procedure TAESCTRContext.SetKey(const AKey: TBytes);
begin
  FAES.SetKey(AKey);
end;

procedure TAESCTRContext.SetNonceAndCounter(const ANonce: TBytes; const AInitialCounter: UInt32);
begin
  if Length(ANonce) <> 12 then
    raise EInvalidArgument.Create('CTR nonce must be 12 bytes for this constructor');
  Move(ANonce[0], FNonce[0], 12);
  FCounter := AInitialCounter;
  FNonceSet := True;
  // reset keystream buffer state for new (nonce,counter)
  FKSPos := 16;
end;

function TAESCTRContext.Process(const AInput: TBytes): TBytes;
var
  LLen, Offset, Need, i: Integer;
  CounterBlk, KS: TBytes;
begin
  Result := nil; CounterBlk := nil; KS := nil;
  if not FNonceSet then
    raise EInvalidOperation.Create('CTR nonce/counter not set');
  LLen := Length(AInput);
  SetLength(Result, LLen);
  Offset := 0;
  SetLength(CounterBlk, 16);

  while Offset < LLen do
  begin
    // refill keystream block if empty
    if FKSPos >= 16 then
    begin
      Move(FNonce[0], CounterBlk[0], 12);
      CounterBlk[12] := Byte((FCounter shr 24) and $FF);
      CounterBlk[13] := Byte((FCounter shr 16) and $FF);
      CounterBlk[14] := Byte((FCounter shr 8) and $FF);
      CounterBlk[15] := Byte(FCounter and $FF);
      KS := FAES.Encrypt(CounterBlk);
      // copy to buffer and reset position
      for i := 0 to 15 do FKS[i] := KS[i];
      FKSPos := 0;
      Inc(FCounter);
    end;

    // consume as much as possible from current keystream block
    Need := 16 - FKSPos;
    if Need > (LLen - Offset) then Need := LLen - Offset;
    for i := 0 to Need - 1 do
      Result[Offset + i] := AInput[Offset + i] xor FKS[FKSPos + i];
    Inc(Offset, Need);
    Inc(FKSPos, Need);
  end;
end;

procedure TAESCTRContext.Reset;
begin
  FillChar(FNonce, SizeOf(FNonce), 0);
  FCounter := 0;
  FNonceSet := False;
  // mark keystream buffer empty
  FKSPos := 16;
  FillChar(FKS, SizeOf(FKS), 0);
end;

procedure TAESCTRContext.Burn;
begin
  if Assigned(FAES) then FAES.Burn;
  Reset;
end;

function CreateAESCTR(AKeySizeBytes: Integer): IAESCTR;
begin
  Result := TAESCTRContext.Create(AKeySizeBytes);
end;

end.

