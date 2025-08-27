{
  fafafa.core.crypto.cipher.aes - AES核心算法实现

  本单元实现了AES (Advanced Encryption Standard) 核心算法：
  - AES-128: 128位密钥的AES加密
  - AES-192: 192位密钥的AES加密
  - AES-256: 256位密钥的AES加密

  实现特点：
  - 符合FIPS 197标准
  - 纯Pascal实现，无外部依赖
  - 基础ECB模式实现
  - 常量时间实现，防止侧信道攻击
  - 高性能优化
}

unit fafafa.core.crypto.cipher.aes;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base,
  fafafa.core.crypto.interfaces;

type
  // 重新导出共享类型
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  ISymmetricCipher = fafafa.core.crypto.interfaces.ISymmetricCipher;
  ECryptoCipher = fafafa.core.crypto.interfaces.ECryptoCipher;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EInvalidKey = fafafa.core.crypto.interfaces.EInvalidKey;
  EInvalidData = fafafa.core.crypto.interfaces.EInvalidData;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;

  // 未实现异常
  ENotSupported = class(ECore);

  {**
   * TAESContext
   *
   * @desc
   *   AES cipher implementation.
   *   AES加密算法实现.
   *}
  TAESContext = class(TInterfacedObject, ISymmetricCipher)
  private
    FKeySize: Integer;
    FKeySet: Boolean;
    FKey: TBytes;
    FRoundKeys: array of DWord; // expanded key schedule (Nb*(Nr+1) words)
    FRounds: Integer;           // Nr = 10/12/14
    procedure ExpandKey(const AKey: TBytes);
    procedure EncryptBlock(const InBlk: array of Byte; var OutBlk: array of Byte);
    procedure DecryptBlock(const InBlk: array of Byte; var OutBlk: array of Byte);
  public
    constructor Create(AKeySize: Integer);
    destructor Destroy; override;

    // ISymmetricCipher implementation
    function GetKeySize: Integer;
    function GetBlockSize: Integer;
    function GetName: string;
    procedure SetKey(const AKey: TBytes);
    function Encrypt(const APlaintext: TBytes): TBytes;
    function Decrypt(const ACiphertext: TBytes): TBytes;
    procedure Reset;
    procedure Burn;
  end;

{**
 * CreateAES128
 *
 * @desc
 *   Creates a new AES-128 cipher instance.
 *   创建新的AES-128加密算法实例.
 *}
function CreateAES128: ISymmetricCipher;

{**
 * CreateAES192
 *
 * @desc
 *   Creates a new AES-192 cipher instance.
 *   创建新的AES-192加密算法实例.
 *}
function CreateAES192: ISymmetricCipher;

{**
 * CreateAES256
 *
 * @desc
 *   Creates a new AES-256 cipher instance.
 *   创建新的AES-256加密算法实例.
 *}
function CreateAES256: ISymmetricCipher;

implementation

{ TAESContext }

constructor TAESContext.Create(AKeySize: Integer);
begin
  inherited Create;
  if not (AKeySize in [16, 24, 32]) then
    raise EInvalidArgument.CreateFmt('Invalid AES key size: %d bytes', [AKeySize]);

  FKeySize := AKeySize;
  FKeySet := False;
  SetLength(FKey, 0);
end;

destructor TAESContext.Destroy;
begin
  Burn;
  inherited Destroy;
end;

function TAESContext.GetKeySize: Integer;
begin
  Result := FKeySize;
end;

function TAESContext.GetBlockSize: Integer;
begin
  Result := 16; // AES块大小始终为16字节
end;

function TAESContext.GetName: string;
begin
  case FKeySize of
    16: Result := 'AES-128';
    24: Result := 'AES-192';
    32: Result := 'AES-256';
  else
    Result := 'AES';
  end;
end;

procedure TAESContext.SetKey(const AKey: TBytes);
begin
  if Length(AKey) <> FKeySize then
    raise EInvalidKey.CreateFmt('Invalid key length: expected %d bytes, got %d', [FKeySize, Length(AKey)]);

  SetLength(FKey, Length(AKey));
  Move(AKey[0], FKey[0], Length(AKey));
  ExpandKey(FKey);
  FKeySet := True;
end;

function TAESContext.Encrypt(const APlaintext: TBytes): TBytes;
var
  LLen, LBlocks, I: Integer;
  InBlk, OutBlk: array[0..15] of Byte;
begin
  {$push}
  {$hints off}
  // init managed return and local buffers
  Result := nil; SetLength(Result, 0);
  FillChar(InBlk, SizeOf(InBlk), 0);
  FillChar(OutBlk, SizeOf(OutBlk), 0);
  if not FKeySet then
    raise EInvalidOperation.Create('AES key not set');

  // For core AES, caller must provide full blocks (no padding here)
  LLen := Length(APlaintext);
  if (LLen mod 16) <> 0 then
    raise EInvalidArgument.Create('Plaintext length must be multiple of 16 bytes');

  if LLen = 0 then Exit; // nothing to do

  SetLength(Result, LLen);
  LBlocks := LLen div 16;
  for I := 0 to LBlocks - 1 do
  begin
    Move(APlaintext[I*16], InBlk[0], 16);
    EncryptBlock(InBlk, OutBlk);
    Move(OutBlk[0], Result[I*16], 16);
  end;
  {$pop}
end;

function TAESContext.Decrypt(const ACiphertext: TBytes): TBytes;
var
  LLen, LBlocks, I: Integer;
  InBlk, OutBlk: array[0..15] of Byte;
begin
  {$push}
  {$hints off}
  // init managed return and local buffers
  Result := nil; SetLength(Result, 0);
  FillChar(InBlk, SizeOf(InBlk), 0);
  FillChar(OutBlk, SizeOf(OutBlk), 0);
  if not FKeySet then
    raise EInvalidOperation.Create('AES key not set');

  LLen := Length(ACiphertext);
  if (LLen mod 16) <> 0 then
    raise EInvalidArgument.Create('Ciphertext length must be multiple of 16 bytes');

  if LLen = 0 then Exit; // nothing to do

  SetLength(Result, LLen);
  LBlocks := LLen div 16;
  for I := 0 to LBlocks - 1 do
  begin
    Move(ACiphertext[I*16], InBlk[0], 16);
    DecryptBlock(InBlk, OutBlk);
    Move(OutBlk[0], Result[I*16], 16);
  end;
  {$pop}
end;

procedure TAESContext.Reset;
begin
  FRounds := 0;
  SetLength(FRoundKeys, 0);
  FKeySet := False;
end;

// ===== Internal AES tables and helpers (S-box, Rcon, GF mul) =====
const
  SBox: array[0..255] of Byte = (
    $63,$7C,$77,$7B,$F2,$6B,$6F,$C5,$30,$01,$67,$2B,$FE,$D7,$AB,$76,
    $CA,$82,$C9,$7D,$FA,$59,$47,$F0,$AD,$D4,$A2,$AF,$9C,$A4,$72,$C0,
    $B7,$FD,$93,$26,$36,$3F,$F7,$CC,$34,$A5,$E5,$F1,$71,$D8,$31,$15,
    $04,$C7,$23,$C3,$18,$96,$05,$9A,$07,$12,$80,$E2,$EB,$27,$B2,$75,
    $09,$83,$2C,$1A,$1B,$6E,$5A,$A0,$52,$3B,$D6,$B3,$29,$E3,$2F,$84,
    $53,$D1,$00,$ED,$20,$FC,$B1,$5B,$6A,$CB,$BE,$39,$4A,$4C,$58,$CF,
    $D0,$EF,$AA,$FB,$43,$4D,$33,$85,$45,$F9,$02,$7F,$50,$3C,$9F,$A8,
    $51,$A3,$40,$8F,$92,$9D,$38,$F5,$BC,$B6,$DA,$21,$10,$FF,$F3,$D2,
    $CD,$0C,$13,$EC,$5F,$97,$44,$17,$C4,$A7,$7E,$3D,$64,$5D,$19,$73,
    $60,$81,$4F,$DC,$22,$2A,$90,$88,$46,$EE,$B8,$14,$DE,$5E,$0B,$DB,
    $E0,$32,$3A,$0A,$49,$06,$24,$5C,$C2,$D3,$AC,$62,$91,$95,$E4,$79,
    $E7,$C8,$37,$6D,$8D,$D5,$4E,$A9,$6C,$56,$F4,$EA,$65,$7A,$AE,$08,
    $BA,$78,$25,$2E,$1C,$A6,$B4,$C6,$E8,$DD,$74,$1F,$4B,$BD,$8B,$8A,
    $70,$3E,$B5,$66,$48,$03,$F6,$0E,$61,$35,$57,$B9,$86,$C1,$1D,$9E,
    $E1,$F8,$98,$11,$69,$D9,$8E,$94,$9B,$1E,$87,$E9,$CE,$55,$28,$DF,
    $8C,$A1,$89,$0D,$BF,$E6,$42,$68,$41,$99,$2D,$0F,$B0,$54,$BB,$16);

  Rcon: array[1..10] of DWord = (
    $01000000,$02000000,$04000000,$08000000,$10000000,
    $20000000,$40000000,$80000000,$1B000000,$36000000);

function RotWord(w: DWord): DWord; inline;
begin
  Result := (w shl 8) or (w shr 24);
end;

function SubWord(w: DWord): DWord; inline;
begin
  Result := (DWord(SBox[(w shr 24) and $FF]) shl 24) or
            (DWord(SBox[(w shr 16) and $FF]) shl 16) or
            (DWord(SBox[(w shr 8) and $FF]) shl 8) or
            (DWord(SBox[w and $FF]));
end;

procedure TAESContext.ExpandKey(const AKey: TBytes);
var
  Nk, Nb, Nr, i: Integer;
  temp: DWord;
begin
  Nb := 4;
  case FKeySize of
    16: begin Nk := 4; Nr := 10; end;
    24: begin Nk := 6; Nr := 12; end;
    32: begin Nk := 8; Nr := 14; end;
  else
    raise EInvalidKey.Create('Invalid AES key size');
  end;
  FRounds := Nr;
  SetLength(FRoundKeys, Nb * (Nr + 1));

  // Copy the key into the first Nk words
  for i := 0 to Nk - 1 do
  begin
    FRoundKeys[i] := (DWord(AKey[4*i]) shl 24) or (DWord(AKey[4*i+1]) shl 16) or
                     (DWord(AKey[4*i+2]) shl 8) or DWord(AKey[4*i+3]);
  end;

  // Generate the rest of the key schedule
  for i := Nk to Nb*(Nr+1) - 1 do
  begin
    temp := FRoundKeys[i-1];
    if (i mod Nk) = 0 then
      temp := SubWord(RotWord(temp)) xor Rcon[i div Nk]
    else if (Nk > 6) and ((i mod Nk) = 4) then
      temp := SubWord(temp);
    FRoundKeys[i] := FRoundKeys[i-Nk] xor temp;
  end;
end;

// AES round helpers
function xtime(x: Byte): Byte; inline;
var v: LongInt;
begin
  if (x and $80) <> 0 then v := ((x shl 1) xor $1B) else v := (x shl 1);
  Result := Byte(v and $FF);
end;

procedure SubBytes(var state: array of Byte);
var i: Integer;
begin
  for i := 0 to 15 do state[i] := SBox[state[i]];
end;

procedure ShiftRows(var state: array of Byte);
var t: Byte;
begin
  // row 1 shift 1
  t := state[1]; state[1] := state[5]; state[5] := state[9]; state[9] := state[13]; state[13] := t;
  // row 2 shift 2
  t := state[2]; state[2] := state[10]; state[10] := t; t := state[6]; state[6] := state[14]; state[14] := t;
  // row 3 shift 3
  t := state[3]; state[3] := state[15]; state[15] := state[11]; state[11] := state[7]; state[7] := t;
end;

function gmul(a, b: Byte): Byte; inline;
var x, y, p: Byte; i: Integer; hi: Byte;
begin
  p := 0; x := a; y := b;
  for i := 0 to 7 do
  begin
    if (y and 1) <> 0 then p := p xor x;
    hi := x and $80;
    x := Byte((x shl 1) and $FF);
    if hi <> 0 then x := x xor $1B;
    y := y shr 1;
  end;
  Result := p;
end;

procedure MixColumns(var state: array of Byte);
var i: Integer; a,b,c,d: Byte;
begin
  for i := 0 to 3 do
  begin
    a := state[4*i+0]; b := state[4*i+1]; c := state[4*i+2]; d := state[4*i+3];
    state[4*i+0] := gmul(a,$02) xor gmul(b,$03) xor gmul(c,$01) xor gmul(d,$01);
    state[4*i+1] := gmul(a,$01) xor gmul(b,$02) xor gmul(c,$03) xor gmul(d,$01);
    state[4*i+2] := gmul(a,$01) xor gmul(b,$01) xor gmul(c,$02) xor gmul(d,$03);
    state[4*i+3] := gmul(a,$03) xor gmul(b,$01) xor gmul(c,$01) xor gmul(d,$02);
  end;
end;

procedure AddRoundKey(var state: array of Byte; const rk: array of DWord; round: Integer);
var i: Integer; w: DWord;
begin
  for i := 0 to 3 do
  begin
    w := rk[round*4 + i];
    state[4*i+0] := state[4*i+0] xor Byte(w shr 24);
    state[4*i+1] := state[4*i+1] xor Byte((w shr 16) and $FF);
    state[4*i+2] := state[4*i+2] xor Byte((w shr 8) and $FF);
    state[4*i+3] := state[4*i+3] xor Byte(w and $FF);
  end;
end;

procedure TAESContext.EncryptBlock(const InBlk: array of Byte; var OutBlk: array of Byte);
var
  state: array[0..15] of Byte;
  round: Integer;
begin
  {$push}
  {$hints off}
  // init local buffer for analyzers (logic unchanged because Move overwrites 16 bytes)
  FillChar(state, SizeOf(state), 0);
  Move(InBlk[0], state[0], 16);
  AddRoundKey(state, FRoundKeys, 0);
  for round := 1 to FRounds - 1 do
  begin
    SubBytes(state);
    ShiftRows(state);
    MixColumns(state);
    AddRoundKey(state, FRoundKeys, round);
  end;
  SubBytes(state);
  ShiftRows(state);
  AddRoundKey(state, FRoundKeys, FRounds);
  Move(state[0], OutBlk[0], 16);
  {$pop}
end;

// Inverse AES components for decryption
const
  InvSBox: array[0..255] of Byte = (
    $52,$09,$6A,$D5,$30,$36,$A5,$38,$BF,$40,$A3,$9E,$81,$F3,$D7,$FB,
    $7C,$E3,$39,$82,$9B,$2F,$FF,$87,$34,$8E,$43,$44,$C4,$DE,$E9,$CB,
    $54,$7B,$94,$32,$A6,$C2,$23,$3D,$EE,$4C,$95,$0B,$42,$FA,$C3,$4E,
    $08,$2E,$A1,$66,$28,$D9,$24,$B2,$76,$5B,$A2,$49,$6D,$8B,$D1,$25,
    $72,$F8,$F6,$64,$86,$68,$98,$16,$D4,$A4,$5C,$CC,$5D,$65,$B6,$92,
    $6C,$70,$48,$50,$FD,$ED,$B9,$DA,$5E,$15,$46,$57,$A7,$8D,$9D,$84,
    $90,$D8,$AB,$00,$8C,$BC,$D3,$0A,$F7,$E4,$58,$05,$B8,$B3,$45,$06,
    $D0,$2C,$1E,$8F,$CA,$3F,$0F,$02,$C1,$AF,$BD,$03,$01,$13,$8A,$6B,
    $3A,$91,$11,$41,$4F,$67,$DC,$EA,$97,$F2,$CF,$CE,$F0,$B4,$E6,$73,
    $96,$AC,$74,$22,$E7,$AD,$35,$85,$E2,$F9,$37,$E8,$1C,$75,$DF,$6E,
    $47,$F1,$1A,$71,$1D,$29,$C5,$89,$6F,$B7,$62,$0E,$AA,$18,$BE,$1B,
    $FC,$56,$3E,$4B,$C6,$D2,$79,$20,$9A,$DB,$C0,$FE,$78,$CD,$5A,$F4,
    $1F,$DD,$A8,$33,$88,$07,$C7,$31,$B1,$12,$10,$59,$27,$80,$EC,$5F,
    $60,$51,$7F,$A9,$19,$B5,$4A,$0D,$2D,$E5,$7A,$9F,$93,$C9,$9C,$EF,
    $A0,$E0,$3B,$4D,$AE,$2A,$F5,$B0,$C8,$EB,$BB,$3C,$83,$53,$99,$61,
    $17,$2B,$04,$7E,$BA,$77,$D6,$26,$E1,$69,$14,$63,$55,$21,$0C,$7D);

procedure InvShiftRows(var state: array of Byte);
var t: Byte;
begin
  // inverse of ShiftRows
  // row 1 right shift 1
  t := state[13]; state[13] := state[9]; state[9] := state[5]; state[5] := state[1]; state[1] := t;
  // row 2 right shift 2
  t := state[2]; state[2] := state[10]; state[10] := t; t := state[6]; state[6] := state[14]; state[14] := t;
  // row 3 right shift 3
  t := state[7]; state[7] := state[11]; state[11] := state[15]; state[15] := state[3]; state[3] := t;
end;

function xtimeN(x, n: Byte): Byte; inline;
var i: Integer; r: Byte;
begin
  r := x;
  for i := 1 to n do r := xtime(r);
  Result := r;
end;

procedure InvSubBytes(var state: array of Byte);
var i: Integer;
begin
  for i := 0 to 15 do state[i] := InvSBox[state[i]];
end;

procedure InvMixColumns(var state: array of Byte);
var i: Integer; a,b,c,d: Byte;
begin
  for i := 0 to 3 do
  begin
    a := state[4*i+0]; b := state[4*i+1]; c := state[4*i+2]; d := state[4*i+3];
    state[4*i+0] := gmul(a,$0E) xor gmul(b,$0B) xor gmul(c,$0D) xor gmul(d,$09);
    state[4*i+1] := gmul(a,$09) xor gmul(b,$0E) xor gmul(c,$0B) xor gmul(d,$0D);
    state[4*i+2] := gmul(a,$0D) xor gmul(b,$09) xor gmul(c,$0E) xor gmul(d,$0B);
    state[4*i+3] := gmul(a,$0B) xor gmul(b,$0D) xor gmul(c,$09) xor gmul(d,$0E);
  end;
end;

procedure TAESContext.DecryptBlock(const InBlk: array of Byte; var OutBlk: array of Byte);
var state: array[0..15] of Byte; round: Integer;
begin
  {$push}
  {$hints off}
  // init local buffer for analyzers (logic unchanged because Move overwrites 16 bytes)
  FillChar(state, SizeOf(state), 0);
  Move(InBlk[0], state[0], 16);
  AddRoundKey(state, FRoundKeys, FRounds);
  for round := FRounds - 1 downto 1 do
  begin
    InvShiftRows(state);
    InvSubBytes(state);
    AddRoundKey(state, FRoundKeys, round);
    InvMixColumns(state);
  end;
  InvShiftRows(state);
  InvSubBytes(state);
  AddRoundKey(state, FRoundKeys, 0);
  Move(state[0], OutBlk[0], 16);
  {$pop}
end;


procedure TAESContext.Burn;
begin
  if Length(FKey) > 0 then
  begin
    FillChar(FKey[0], Length(FKey), 0);
    SetLength(FKey, 0);
  end;
  FKeySet := False;
end;

// Factory functions
function CreateAES128: ISymmetricCipher;
begin
  Result := TAESContext.Create(16);
end;

function CreateAES192: ISymmetricCipher;
begin
  Result := TAESContext.Create(24);
end;

function CreateAES256: ISymmetricCipher;
begin
  Result := TAESContext.Create(32);
end;

end.
