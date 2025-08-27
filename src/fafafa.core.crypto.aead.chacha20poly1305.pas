{
  ChaCha20-Poly1305 AEAD (RFC 7539 / RFC 8439) - pure Pascal minimal implementation
}
unit fafafa.core.crypto.aead.chacha20poly1305;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.utils;

function CreateChaCha20Poly1305_Impl: IAEADCipher;

implementation

type
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EInvalidData = fafafa.core.crypto.interfaces.EInvalidData;

const
  TAG_SIZE = 16;
  KEY_SIZE = 32;
  NONCE_SIZE = 12;

function LE32(const B: TBytes; Ofs: Integer): LongWord; inline;
var p: PByte;
begin
  if (Ofs >= 0) and (Ofs + 3 < Length(B)) then begin
    p := @B[Ofs];
    Result := LongWord(p^) or (LongWord((p+1)^) shl 8) or (LongWord((p+2)^) shl 16) or (LongWord((p+3)^) shl 24);
  end else begin
    Result := 0;
  end;
end;

function BE32(const B: TBytes; Ofs: Integer): LongWord; inline;
begin
  if (Ofs >= 0) and (Ofs + 3 < Length(B)) then begin
    Result := (LongWord(B[Ofs]) shl 24) or (LongWord(B[Ofs+1]) shl 16) or (LongWord(B[Ofs+2]) shl 8) or LongWord(B[Ofs+3]);
  end else begin
    Result := 0;
  end;
end;

procedure ST32(var B: TBytes; Ofs: Integer; V: LongWord); inline;
begin
  B[Ofs] := Byte(V);
  B[Ofs+1] := Byte(V shr 8);
  B[Ofs+2] := Byte(V shr 16);
  B[Ofs+3] := Byte(V shr 24);
end;

function LE32A(const A: array of Byte; Ofs: Integer): LongWord;
var p: PByte;
begin
  if (Ofs >= 0) and (Ofs + 3 <= High(A)) then begin
    p := @A[Ofs];
    Result := LongWord(p^) or (LongWord((p+1)^) shl 8) or (LongWord((p+2)^) shl 16) or (LongWord((p+3)^) shl 24);
  end else begin
    Result := 0;
  end;
end;


function RotL32(x: LongWord; n: LongWord): LongWord; inline;
begin
  Result := (x shl n) or (x shr (32 - n));
end;

procedure QuarterRound(var a,b,c,d: LongWord); inline;
begin
  a := a + b; d := d xor a; d := RotL32(d, 16);
  c := c + d; b := b xor c; b := RotL32(b, 12);
  a := a + b; d := d xor a; d := RotL32(d, 8);
  c := c + d; b := b xor c; b := RotL32(b, 7);
end;

procedure QRArr(var S: array of LongWord; a,b,c,d: Integer); inline;
begin
  S[a] := S[a] + S[b]; S[d] := S[d] xor S[a]; S[d] := RotL32(S[d], 16);
  S[c] := S[c] + S[d]; S[b] := S[b] xor S[c]; S[b] := RotL32(S[b], 12);
  S[a] := S[a] + S[b]; S[d] := S[d] xor S[a]; S[d] := RotL32(S[d], 8);
  S[c] := S[c] + S[d]; S[b] := S[b] xor S[c]; S[b] := RotL32(S[b], 7);
end;

procedure ChaCha20Block(const Key, Nonce: TBytes; Counter: LongWord; out Block: TBytes);
{$push}
{$R-}
var
  S, W: array[0..15] of LongWord;
  I: Integer;
begin
  // constants "expand 32-byte k"
  S[0] := $61707865; S[1] := $3320646E; S[2] := $79622D32; S[3] := $6B206574;
  // key 32 bytes little-endian
  for I := 0 to 7 do S[4+I] := LE32(Key, I*4);
  // counter and nonce (12 bytes) little-endian per word
  S[12] := Counter;
  S[13] := LE32(Nonce, 0);
  S[14] := LE32(Nonce, 4);
  S[15] := LE32(Nonce, 8);

  W := S;
  for I := 1 to 10 do begin
    // column rounds
    QRArr(W,0,4,8,12);
    QRArr(W,1,5,9,13);
    QRArr(W,2,6,10,14);
    QRArr(W,3,7,11,15);
    // diagonal rounds
    QRArr(W,0,5,10,15);
    QRArr(W,1,6,11,12);
    QRArr(W,2,7,8,13);
    QRArr(W,3,4,9,14);
  end;

  SetLength(Block, 64);
  for I := 0 to 15 do begin
    W[I] := W[I] + S[I];
    ST32(Block, I*4, W[I]);
  end;
end;
{$pop}

function ChaCha20Xor(const Key, Nonce: TBytes; Counter: LongWord; const InBuf: TBytes): TBytes;
{$push}
{$R-}
var
  I, J, L, Ofs: Integer;
  Block: TBytes;
begin
  // Init managed outputs/locals to satisfy static analysis
  Result := nil; SetLength(Block, 0);
  L := Length(InBuf);
  if L = 0 then Exit; // early return keeps Result=nil -> caller treats as empty
  SetLength(Result, L);
  Ofs := 0;
  J := 0;
  while Ofs < L do begin
    if J = 0 then begin
      ChaCha20Block(Key, Nonce, Counter, Block);
      Inc(Counter);
    end;
    Result[Ofs] := InBuf[Ofs] xor Block[J];
    Inc(Ofs); Inc(J);
    if J = 64 then J := 0;
  end;
{$pop}
end;

procedure Poly1305Clamp(var R: array of LongWord);
begin
  R[0] := R[0] and $0FFFFFFF;
  R[1] := R[1] and $0FFFFFFC;
  R[2] := R[2] and $0FFFFFFC;
  R[3] := R[3] and $0FFFFFFC;
  R[4] := R[4] and $0FFFFFFC;
end;

function Poly1305Tag(const Key: TBytes; const Msg: TBytes): TBytes;
{$push}
{$R-}
{$hints off}
// Key: 32 bytes (r||s), where r is clamped, s added at end. Little-endian limbs 26-bit.
var
  R: array[0..4] of QWord;
  H: array[0..4] of QWord;
  Pad: array[0..1] of QWord; // s-pad (128-bit)
  I, J, N, Ofs: Integer;
  Block: array[0..16] of Byte;
  // temps for block parsing and multiplication
  T0, T1: QWord;
  HR0, HR1, HR2, HR3, HR4: QWord;
  R0, R1, R2, R3, R4: QWord;
  R1_5, R2_5, R3_5, R4_5: QWord;
  // finalize/pack helpers
  g: array[0..4] of QWord; c, mask: QWord;
  f0, f1, f2, f3: QWord; s0, s1, s2, s3: QWord;
  Tag: TBytes;
begin
  // init managed return and zero fixed-size buffers for analyzers
  SetLength(Tag, 0);
  FillChar(R, SizeOf(R), 0);
  FillChar(H, SizeOf(H), 0);
  FillChar(Pad, SizeOf(Pad), 0);
  FillChar(Block, SizeOf(Block), 0);
  // r from Key[0..15], clamp to 26-bit limbs
  T0 := LE32(Key, 0) or (QWord(LE32(Key, 4)) shl 32);
  T1 := LE32(Key, 8) or (QWord(LE32(Key, 12)) shl 32);
  R[0] :=  T0                      and $3FFFFFF; T0 := T0 shr 26;
  R[1] := (T0 or ((T1 and $3F) shl 6)) and $3FFFF03; T1 := T1 shr 6;
  R[2] :=  T1                      and $3FFC0FF; T1 := T1 shr 26;
  R[3] :=  T1                      and $3F03FFF; T1 := T1 shr 26;
  R[4] :=  T1                      and $00FFFFF;
  // s (the pad) little-endian 16 bytes at Key[16..31]
  Pad[0] := LE32(Key,16) or (QWord(LE32(Key,20)) shl 32);
  Pad[1] := LE32(Key,24) or (QWord(LE32(Key,28)) shl 32);
  R0:=R[0]; R1:=R[1]; R2:=R[2]; R3:=R[3]; R4:=R[4];
  R1_5:=R1*5; R2_5:=R2*5; R3_5:=R3*5; R4_5:=R4*5;

  // process 16-byte blocks with hibit (1<<24 when block is full)
  Ofs := 0; N := Length(Msg);
  while Ofs < N do begin
    FillChar(Block, SizeOf(Block), 0);
    J := 0;
    while (J < 16) and (Ofs < N) do begin
      Block[J] := Msg[Ofs];
      Inc(J); Inc(Ofs);
    end;
    // append the mandatory 1 for partial blocks (RFC 7539/8439)
    if J < 16 then Block[J] := 1;
    // parse into 26-bit limbs with hibit
    T0 := QWord(LE32A(Block,0)) or (QWord(LE32A(Block,4)) shl 32);
    T1 := QWord(LE32A(Block,8)) or (QWord(LE32A(Block,12)) shl 32);
    H[0] := H[0] + (T0 and $3FFFFFF); T0 := T0 shr 26;
    H[1] := H[1] + (T0 and $3FFFFFF); T0 := (T0 shr 26) or ((T1 and $3FF) shl 10); T1 := T1 shr 10;
    H[2] := H[2] + (T0 and $3FFFFFF); T0 := T0 shr 26;
    H[3] := H[3] + (T0 and $3FFFFFF); T0 := T0 shr 26;
    H[4] := H[4] + (T1 and $3FFFFFF);
    if J = 16 then H[4] := H[4] + (QWord(1) shl 24); // hibit for full block

    // multiply by r in 26-bit limbs (schoolbook with carries and 5* reduction)
    HR0 := H[0]*R0 + H[1]*R4_5 + H[2]*R3_5 + H[3]*R2_5 + H[4]*R1_5;
    HR1 := H[0]*R1 + H[1]*R0   + H[2]*R4_5 + H[3]*R3_5 + H[4]*R2_5;
    HR2 := H[0]*R2 + H[1]*R1   + H[2]*R0   + H[3]*R4_5 + H[4]*R3_5;
    HR3 := H[0]*R3 + H[1]*R2   + H[2]*R1   + H[3]*R0   + H[4]*R4_5;
    HR4 := H[0]*R4 + H[1]*R3   + H[2]*R2   + H[3]*R1   + H[4]*R0;

    // carry propagation base 2^26 with 5* reduction
    H[0] := HR0 and $3FFFFFF; HR1 := HR1 + (HR0 shr 26);
    H[1] := HR1 and $3FFFFFF; HR2 := HR2 + (HR1 shr 26);
    H[2] := HR2 and $3FFFFFF; HR3 := HR3 + (HR2 shr 26);
    H[3] := HR3 and $3FFFFFF; HR4 := HR4 + (HR3 shr 26);
    H[4] := HR4 and $3FFFFFF; H[0] := H[0] + ((HR4 shr 26) * 5);
    // final carry
    H[1] := H[1] + (H[0] shr 26); H[0] := H[0] and $3FFFFFF;
  end;

  // finalize: fully carry reduce
  H[2] := H[2] + (H[1] shr 26); H[1] := H[1] and $3FFFFFF;
  H[3] := H[3] + (H[2] shr 26); H[2] := H[2] and $3FFFFFF;
  H[4] := H[4] + (H[3] shr 26); H[3] := H[3] and $3FFFFFF;
  H[0] := H[0] + ((H[4] shr 26) * 5); H[4] := H[4] and $3FFFFFF;
  H[1] := H[1] + (H[0] shr 26); H[0] := H[0] and $3FFFFFF;

  // compute g = h + 5 and conditional reduce h if h >= p

  g[0] := H[0] + 5;        c := g[0] shr 26; g[0] := g[0] and $3FFFFFF;
  g[1] := H[1] + c;        c := g[1] shr 26; g[1] := g[1] and $3FFFFFF;
  g[2] := H[2] + c;        c := g[2] shr 26; g[2] := g[2] and $3FFFFFF;
  g[3] := H[3] + c;        c := g[3] shr 26; g[3] := g[3] and $3FFFFFF;
  g[4] := H[4] + c - (QWord(1) shl 26);
  // if g[4] has borrow (top bit set when subtracting), select h; else select g
  // b = 1 means borrow (negative), mask = 0; b = 0 means no borrow, mask = 0xFFFFFFFFFFFFFFFF
  mask := (QWord(((g[4] shr 63) and 1)) - 1);
  H[0] := (H[0] and not mask) or (g[0] and mask);
  H[1] := (H[1] and not mask) or (g[1] and mask);
  H[2] := (H[2] and not mask) or (g[2] and mask);
  H[3] := (H[3] and not mask) or (g[3] and mask);
  H[4] := (H[4] and not mask) or ((g[4] and $3FFFFFF) and mask);

  // pack into 4x32-bit words (little-endian):
  // f0 = h0 + (h1<<26)
  // f1 = (h1>>6) + (h2<<20)
  // f2 = (h2>>12) + (h3<<14)
  // f3 = (h3>>18) + (h4<<8)

  f0 := (H[0]       ) or (H[1] shl 26);
  f1 := (H[1] shr 6 ) or (H[2] shl 20);
  f2 := (H[2] shr 12) or (H[3] shl 14);
  f3 := (H[3] shr 18) or (H[4] shl 8);

  // add s (pad) split into 32-bit limbs

  s0 := Pad[0] and $FFFFFFFF; s1 := (Pad[0] shr 32) and $FFFFFFFF;
  s2 := Pad[1] and $FFFFFFFF; s3 := (Pad[1] shr 32) and $FFFFFFFF;

  f0 := f0 + s0; c := f0 shr 32; f0 := f0 and $FFFFFFFF;
  f1 := f1 + s1 + c; c := f1 shr 32; f1 := f1 and $FFFFFFFF;
  f2 := f2 + s2 + c; c := f2 shr 32; f2 := f2 and $FFFFFFFF;
  f3 := f3 + s3 + c; f3 := f3 and $FFFFFFFF;

  // store tag as 16 bytes LE
  SetLength(Tag, 16);
  // write 32-bit words explicitly
  Tag[0] := Byte(f0 and $FF);
  Tag[1] := Byte((f0 shr 8) and $FF);
  Tag[2] := Byte((f0 shr 16) and $FF);
  Tag[3] := Byte((f0 shr 24) and $FF);
  Tag[4] := Byte(f1 and $FF);
  Tag[5] := Byte((f1 shr 8) and $FF);
  Tag[6] := Byte((f1 shr 16) and $FF);
  Tag[7] := Byte((f1 shr 24) and $FF);
  Tag[8] := Byte(f2 and $FF);
  Tag[9] := Byte((f2 shr 8) and $FF);
  Tag[10] := Byte((f2 shr 16) and $FF);
  Tag[11] := Byte((f2 shr 24) and $FF);
  Tag[12] := Byte(f3 and $FF);
  Tag[13] := Byte((f3 shr 8) and $FF);
  Tag[14] := Byte((f3 shr 16) and $FF);
  Tag[15] := Byte((f3 shr 24) and $FF);

  Result := Tag;
  {$hints on}
end;
{$pop}

function Poly1305Auth(const OneTimeKey, AAD, C: TBytes): TBytes;
{$push}
{$R-}
{$hints off}
var
  Msg: TBytes;
  L1, L2, I, Ofs: Integer;
  LenBlock: array[0..15] of Byte;
begin
  // Build message: AAD || padding || C || padding || len(AAD)||len(C) (each 64-bit LE)
  L1 := Length(AAD); L2 := Length(C);
  SetLength(Msg, 0);
  // proactively zero LenBlock near declaration for conservative analyzers
  FillChar(LenBlock, SizeOf(LenBlock), 0);
  // AAD
  if L1 > 0 then begin
    I := Length(Msg); SetLength(Msg, I+L1); Move(AAD[0], Msg[I], L1);
    if (L1 mod 16) <> 0 then begin
      I := Length(Msg); SetLength(Msg, I + (16 - (L1 mod 16))); // zero padding
    end;
  end;
  // C
  if L2 > 0 then begin
    I := Length(Msg); SetLength(Msg, I+L2); Move(C[0], Msg[I], L2);
    if (L2 mod 16) <> 0 then begin
      I := Length(Msg); SetLength(Msg, I + (16 - (L2 mod 16)));
    end;
  end;
  // lengths
  FillChar(LenBlock, SizeOf(LenBlock), 0);
  // 64-bit LE lengths
  for I := 0 to 7 do begin
    LenBlock[I] := Byte(QWord(L1) shr (8*I));
    LenBlock[8+I] := Byte(QWord(L2) shr (8*I));
  end;
  Ofs := Length(Msg); SetLength(Msg, Ofs + 16); Move(LenBlock[0], Msg[Ofs], 16);

  Result := Poly1305Tag(OneTimeKey, Msg);
end;
{$pop}

type
  TChaCha20Poly1305 = class(TInterfacedObject, IAEADCipher, IAEADCipherEx, IAEADCipherEx2)
  private
    FKey: TBytes;
    FKeySet: Boolean;
  public
    constructor Create;
    // IAEADCipher
    function GetName: string;
    function GetKeySize: Integer;
    function NonceSize: Integer;
    function Overhead: Integer;
    procedure SetKey(const AKey: TBytes);
    procedure SetTagLength(ATagLenBytes: Integer);
    function Seal(const ANonce, AAD, APlaintext: TBytes): TBytes;
    function Open(const ANonce, AAD, ACiphertext: TBytes): TBytes;
    procedure Burn;
    // IAEADCipherEx (append-style)
    function SealAppend(var ADst: TBytes; const ANonce, AAD, APlaintext: TBytes): Integer;
    function OpenAppend(var ADst: TBytes; const ANonce, AAD, ACiphertext: TBytes): Integer;
    // IAEADCipherEx2 (in-place)
    function SealInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
    function OpenInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
  end;

constructor TChaCha20Poly1305.Create;
begin
  inherited Create;
  FKeySet := False;
  SetLength(FKey, 0);
end;

function TChaCha20Poly1305.GetName: string; begin Result := 'ChaCha20-Poly1305'; end;
function TChaCha20Poly1305.GetKeySize: Integer; begin Result := KEY_SIZE; end;
function TChaCha20Poly1305.NonceSize: Integer; begin Result := NONCE_SIZE; end;
function TChaCha20Poly1305.Overhead: Integer; begin Result := TAG_SIZE; end;

procedure TChaCha20Poly1305.SetKey(const AKey: TBytes);
begin
  if Length(AKey) <> KEY_SIZE then
    raise EInvalidArgument.Create('ChaCha20-Poly1305 key must be 32 bytes');
  FKey := Copy(AKey, 0, Length(AKey));
  FKeySet := True;
end;

procedure TChaCha20Poly1305.SetTagLength(ATagLenBytes: Integer);
begin
  if ATagLenBytes <> TAG_SIZE then
    raise EInvalidArgument.Create('ChaCha20-Poly1305 tag length is fixed at 16 bytes');
end;

function TChaCha20Poly1305.Seal(const ANonce, AAD, APlaintext: TBytes): TBytes;
{$push}
{$R-}
var
  OTK, Block0: TBytes;
  C, Tag: TBytes;
  L, I: Integer;
begin
  {$hints off}
  // init managed (explicit for analyzers)
  Result := nil; SetLength(OTK, 0); SetLength(Block0, 0); SetLength(C, 0); SetLength(Tag, 0);
  if not FKeySet then raise EInvalidArgument.Create('key not set');
  if Length(ANonce) <> NONCE_SIZE then raise EInvalidArgument.Create('nonce must be 12 bytes');
  // one-time Poly1305 key = chacha20 block with counter=0
  ChaCha20Block(FKey, ANonce, 0, Block0);
  SetLength(OTK, 32); Move(Block0[0], OTK[0], 32);
  // encrypt with counter=1
  C := ChaCha20Xor(FKey, ANonce, 1, APlaintext);
  // compute tag over AAD and C
  Tag := Poly1305Auth(OTK, AAD, C);
  // output C || Tag
  L := Length(C);
  SetLength(Result, L + Length(Tag));
  if L > 0 then Move(C[0], Result[0], L);
  if Length(Tag) > 0 then begin
    Move(Tag[0], Result[L], Length(Tag));
  end;
  {$hints on}
{$pop}
end;

function TChaCha20Poly1305.Open(const ANonce, AAD, ACiphertext: TBytes): TBytes;
{$push}
{$R-}
var
  OTK, Block0: TBytes;
  C, GivenTag, CalcTag: TBytes;
  PT: TBytes;
  L, CTLen: Integer;
  Equal: Boolean;
  I: Integer;
begin
  {$hints off}
  // init managed
  Result := nil; SetLength(OTK, 0); SetLength(Block0, 0);
  SetLength(C, 0); SetLength(GivenTag, 0); SetLength(CalcTag, 0); SetLength(PT, 0);
  if not FKeySet then raise EInvalidArgument.Create('key not set');
  if Length(ANonce) <> NONCE_SIZE then raise EInvalidArgument.Create('nonce must be 12 bytes');
  L := Length(ACiphertext);
  if L < TAG_SIZE then raise EInvalidData.Create('ciphertext too short');
  CTLen := L - TAG_SIZE;
  SetLength(C, CTLen); if CTLen > 0 then Move(ACiphertext[0], C[0], CTLen);
  SetLength(GivenTag, TAG_SIZE);
  Move(ACiphertext[CTLen], GivenTag[0], TAG_SIZE);
  // derive one-time key
  ChaCha20Block(FKey, ANonce, 0, Block0);
  SetLength(OTK, 32); Move(Block0[0], OTK[0], 32);
  CalcTag := Poly1305Auth(OTK, AAD, C);
  // constant-time compare (unified)
  Equal := fafafa.core.crypto.utils.ConstantTimeCompare(CalcTag, GivenTag);
  if not Equal then raise EInvalidData.Create('authentication tag mismatch');
  // decrypt
  PT := ChaCha20Xor(FKey, ANonce, 1, C);
  Result := PT;
  {$hints on}
{$pop}
end;

procedure TChaCha20Poly1305.Burn;
begin
  if Length(FKey) > 0 then begin FillChar(FKey[0], Length(FKey), 0); SetLength(FKey, 0); end;
  FKeySet := False;
end;

function TChaCha20Poly1305.SealAppend(var ADst: TBytes; const ANonce, AAD, APlaintext: TBytes): Integer;
var
  OTK, Block0: TBytes;
  C, Tag: TBytes;
  OldLen, L: Integer;
begin
  Result := 0;
  if not FKeySet then raise EInvalidArgument.Create('key not set');
  if Length(ANonce) <> NONCE_SIZE then raise EInvalidArgument.Create('nonce must be 12 bytes');
  // derive one-time key from block0
  ChaCha20Block(FKey, ANonce, 0, Block0);
  SetLength(OTK, 32); Move(Block0[0], OTK[0], 32);
  // encrypt PT
  C := ChaCha20Xor(FKey, ANonce, 1, APlaintext);
  // poly1305 over AAD||C
  Tag := Poly1305Auth(OTK, AAD, C);
  // append C||Tag to ADst
  L := Length(C);
  OldLen := Length(ADst);
  SetLength(ADst, OldLen + L + Length(Tag));
  if L > 0 then Move(C[0], ADst[OldLen], L);
  if Length(Tag) > 0 then Move(Tag[0], ADst[OldLen + L], Length(Tag));
  Result := L + Length(Tag);
  // cleanup
  if Length(C) > 0 then FillChar(C[0], Length(C), 0); SetLength(C, 0);
  if Length(Tag) > 0 then FillChar(Tag[0], Length(Tag), 0); SetLength(Tag, 0);
  if Length(OTK) > 0 then FillChar(OTK[0], Length(OTK), 0); SetLength(OTK, 0);
  if Length(Block0) > 0 then FillChar(Block0[0], Length(Block0), 0); SetLength(Block0, 0);
end;

function TChaCha20Poly1305.OpenAppend(var ADst: TBytes; const ANonce, AAD, ACiphertext: TBytes): Integer;
var
  OTK, Block0: TBytes;
  C, GivenTag, CalcTag, PT: TBytes;
  OldLen, L, CTLen: Integer;
begin
  // init managed vars to satisfy static analysis
  SetLength(OTK, 0); SetLength(Block0, 0);
  SetLength(C, 0); SetLength(GivenTag, 0); SetLength(CalcTag, 0); SetLength(PT, 0);
  Result := 0;
  if not FKeySet then raise EInvalidArgument.Create('key not set');
  if Length(ANonce) <> NONCE_SIZE then raise EInvalidArgument.Create('nonce must be 12 bytes');
  L := Length(ACiphertext);
  if L < TAG_SIZE then raise EInvalidData.Create('ciphertext too short');
  CTLen := L - TAG_SIZE;
  // split input
  SetLength(C, CTLen); if CTLen > 0 then Move(ACiphertext[0], C[0], CTLen);
  SetLength(GivenTag, TAG_SIZE); Move(ACiphertext[CTLen], GivenTag[0], TAG_SIZE);
  // derive one-time key
  ChaCha20Block(FKey, ANonce, 0, Block0);
  SetLength(OTK, 32); Move(Block0[0], OTK[0], 32);
  CalcTag := Poly1305Auth(OTK, AAD, C);
  if not fafafa.core.crypto.utils.ConstantTimeCompare(CalcTag, GivenTag) then
    raise EInvalidData.Create('authentication tag mismatch');
  // decrypt and append PT
  PT := ChaCha20Xor(FKey, ANonce, 1, C);
  OldLen := Length(ADst);
  SetLength(ADst, OldLen + Length(PT));
  if Length(PT) > 0 then Move(PT[0], ADst[OldLen], Length(PT));
  Result := Length(PT);
  // cleanup
  if Length(PT) > 0 then FillChar(PT[0], Length(PT), 0); SetLength(PT, 0);
  if Length(C) > 0 then FillChar(C[0], Length(C), 0); SetLength(C, 0);
  if Length(GivenTag) > 0 then FillChar(GivenTag[0], Length(GivenTag), 0); SetLength(GivenTag, 0);
  if Length(CalcTag) > 0 then FillChar(CalcTag[0], Length(CalcTag), 0); SetLength(CalcTag, 0);
  if Length(OTK) > 0 then FillChar(OTK[0], Length(OTK), 0); SetLength(OTK, 0);
  if Length(Block0) > 0 then FillChar(Block0[0], Length(Block0), 0); SetLength(Block0, 0);
end;

function TChaCha20Poly1305.SealInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
var
  OTK, Block0, C, Tag: TBytes;
  L: Integer;
begin
  // init managed vars to satisfy static analysis
  SetLength(OTK, 0); SetLength(Block0, 0);
  SetLength(C, 0); SetLength(Tag, 0);
  if not FKeySet then raise EInvalidArgument.Create('key not set');
  if Length(ANonce) <> NONCE_SIZE then raise EInvalidArgument.Create('nonce must be 12 bytes');
  // derive OTK
  ChaCha20Block(FKey, ANonce, 0, Block0);
  SetLength(OTK, 32); Move(Block0[0], OTK[0], 32);
  // encrypt PT -> C
  C := ChaCha20Xor(FKey, ANonce, 1, AData);
  // compute tag over AAD||C
  Tag := Poly1305Auth(OTK, AAD, C);
  // resize and assemble AData = C||Tag
  L := Length(C);
  SetLength(AData, L + Length(Tag));
  if L > 0 then Move(C[0], AData[0], L);
  if Length(Tag) > 0 then Move(Tag[0], AData[L], Length(Tag));
  Result := Length(AData);
  // cleanup
  if Length(C) > 0 then FillChar(C[0], Length(C), 0); SetLength(C, 0);
  if Length(Tag) > 0 then FillChar(Tag[0], Length(Tag), 0); SetLength(Tag, 0);
  if Length(OTK) > 0 then FillChar(OTK[0], Length(OTK), 0); SetLength(OTK, 0);
  if Length(Block0) > 0 then FillChar(Block0[0], Length(Block0), 0); SetLength(Block0, 0);
end;

function TChaCha20Poly1305.OpenInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
var
  OTK, Block0, C, GivenTag, CalcTag, PT: TBytes;
  L, CTLen: Integer;
begin
  // init managed vars to satisfy static analysis
  SetLength(OTK, 0); SetLength(Block0, 0);
  SetLength(C, 0); SetLength(GivenTag, 0); SetLength(CalcTag, 0); SetLength(PT, 0);
  if not FKeySet then raise EInvalidArgument.Create('key not set');
  if Length(ANonce) <> NONCE_SIZE then raise EInvalidArgument.Create('nonce must be 12 bytes');
  L := Length(AData);
  if L < TAG_SIZE then raise EInvalidData.Create('ciphertext too short');
  CTLen := L - TAG_SIZE;
  // split
  SetLength(C, CTLen); if CTLen > 0 then Move(AData[0], C[0], CTLen);
  SetLength(GivenTag, TAG_SIZE); Move(AData[CTLen], GivenTag[0], TAG_SIZE);
  // derive OTK and verify tag first
  ChaCha20Block(FKey, ANonce, 0, Block0);
  SetLength(OTK, 32); Move(Block0[0], OTK[0], 32);
  CalcTag := Poly1305Auth(OTK, AAD, C);
  if not fafafa.core.crypto.utils.ConstantTimeCompare(CalcTag, GivenTag) then
    raise EInvalidData.Create('authentication tag mismatch');
  // decrypt into PT
  PT := ChaCha20Xor(FKey, ANonce, 1, C);
  SetLength(AData, Length(PT));
  if Length(PT) > 0 then Move(PT[0], AData[0], Length(PT));
  Result := Length(PT);
  // cleanup
  if Length(PT) > 0 then FillChar(PT[0], Length(PT), 0); SetLength(PT, 0);
  if Length(C) > 0 then FillChar(C[0], Length(C), 0); SetLength(C, 0);
  if Length(GivenTag) > 0 then FillChar(GivenTag[0], Length(GivenTag), 0); SetLength(GivenTag, 0);
  if Length(CalcTag) > 0 then FillChar(CalcTag[0], Length(CalcTag), 0); SetLength(CalcTag, 0);
  if Length(OTK) > 0 then FillChar(OTK[0], Length(OTK), 0); SetLength(OTK, 0);
  if Length(Block0) > 0 then FillChar(Block0[0], Length(Block0), 0); SetLength(Block0, 0);
end;


function CreateChaCha20Poly1305_Impl: IAEADCipher;
begin
  Result := TChaCha20Poly1305.Create;
end;

end.
