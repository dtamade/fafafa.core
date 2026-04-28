unit fafafa.core.simd.intrinsics.aes;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.intrinsics.base;

{
  Experimental status:
  - This unit stays opt-in only and is isolated from the default entry surface.
  - When enabled, the exported helpers now implement AES round semantics in
    scalar form so tests can assert behavior without requiring AES-NI.
}

// AES round operations
function aes_aesenc_si128(const data, round_key: TM128): TM128;
function aes_aesenclast_si128(const data, round_key: TM128): TM128;

// AES inverse round operations
function aes_aesdec_si128(const data, round_key: TM128): TM128;
function aes_aesdeclast_si128(const data, round_key: TM128): TM128;

// AES key schedule helper
function aes_aeskeygenassist_si128(const key: TM128; rcon: Byte): TM128;

// AES inverse mix columns
function aes_aesimc_si128(const data: TM128): TM128;

implementation

uses
  SysUtils;

const
  AES_SBOX: array[0..255] of Byte = (
    $63, $7C, $77, $7B, $F2, $6B, $6F, $C5, $30, $01, $67, $2B, $FE, $D7, $AB, $76,
    $CA, $82, $C9, $7D, $FA, $59, $47, $F0, $AD, $D4, $A2, $AF, $9C, $A4, $72, $C0,
    $B7, $FD, $93, $26, $36, $3F, $F7, $CC, $34, $A5, $E5, $F1, $71, $D8, $31, $15,
    $04, $C7, $23, $C3, $18, $96, $05, $9A, $07, $12, $80, $E2, $EB, $27, $B2, $75,
    $09, $83, $2C, $1A, $1B, $6E, $5A, $A0, $52, $3B, $D6, $B3, $29, $E3, $2F, $84,
    $53, $D1, $00, $ED, $20, $FC, $B1, $5B, $6A, $CB, $BE, $39, $4A, $4C, $58, $CF,
    $D0, $EF, $AA, $FB, $43, $4D, $33, $85, $45, $F9, $02, $7F, $50, $3C, $9F, $A8,
    $51, $A3, $40, $8F, $92, $9D, $38, $F5, $BC, $B6, $DA, $21, $10, $FF, $F3, $D2,
    $CD, $0C, $13, $EC, $5F, $97, $44, $17, $C4, $A7, $7E, $3D, $64, $5D, $19, $73,
    $60, $81, $4F, $DC, $22, $2A, $90, $88, $46, $EE, $B8, $14, $DE, $5E, $0B, $DB,
    $E0, $32, $3A, $0A, $49, $06, $24, $5C, $C2, $D3, $AC, $62, $91, $95, $E4, $79,
    $E7, $C8, $37, $6D, $8D, $D5, $4E, $A9, $6C, $56, $F4, $EA, $65, $7A, $AE, $08,
    $BA, $78, $25, $2E, $1C, $A6, $B4, $C6, $E8, $DD, $74, $1F, $4B, $BD, $8B, $8A,
    $70, $3E, $B5, $66, $48, $03, $F6, $0E, $61, $35, $57, $B9, $86, $C1, $1D, $9E,
    $E1, $F8, $98, $11, $69, $D9, $8E, $94, $9B, $1E, $87, $E9, $CE, $55, $28, $DF,
    $8C, $A1, $89, $0D, $BF, $E6, $42, $68, $41, $99, $2D, $0F, $B0, $54, $BB, $16
  );

  AES_INV_SBOX: array[0..255] of Byte = (
    $52, $09, $6A, $D5, $30, $36, $A5, $38, $BF, $40, $A3, $9E, $81, $F3, $D7, $FB,
    $7C, $E3, $39, $82, $9B, $2F, $FF, $87, $34, $8E, $43, $44, $C4, $DE, $E9, $CB,
    $54, $7B, $94, $32, $A6, $C2, $23, $3D, $EE, $4C, $95, $0B, $42, $FA, $C3, $4E,
    $08, $2E, $A1, $66, $28, $D9, $24, $B2, $76, $5B, $A2, $49, $6D, $8B, $D1, $25,
    $72, $F8, $F6, $64, $86, $68, $98, $16, $D4, $A4, $5C, $CC, $5D, $65, $B6, $92,
    $6C, $70, $48, $50, $FD, $ED, $B9, $DA, $5E, $15, $46, $57, $A7, $8D, $9D, $84,
    $90, $D8, $AB, $00, $8C, $BC, $D3, $0A, $F7, $E4, $58, $05, $B8, $B3, $45, $06,
    $D0, $2C, $1E, $8F, $CA, $3F, $0F, $02, $C1, $AF, $BD, $03, $01, $13, $8A, $6B,
    $3A, $91, $11, $41, $4F, $67, $DC, $EA, $97, $F2, $CF, $CE, $F0, $B4, $E6, $73,
    $96, $AC, $74, $22, $E7, $AD, $35, $85, $E2, $F9, $37, $E8, $1C, $75, $DF, $6E,
    $47, $F1, $1A, $71, $1D, $29, $C5, $89, $6F, $B7, $62, $0E, $AA, $18, $BE, $1B,
    $FC, $56, $3E, $4B, $C6, $D2, $79, $20, $9A, $DB, $C0, $FE, $78, $CD, $5A, $F4,
    $1F, $DD, $A8, $33, $88, $07, $C7, $31, $B1, $12, $10, $59, $27, $80, $EC, $5F,
    $60, $51, $7F, $A9, $19, $B5, $4A, $0D, $2D, $E5, $7A, $9F, $93, $C9, $9C, $EF,
    $A0, $E0, $3B, $4D, $AE, $2A, $F5, $B0, $C8, $EB, $BB, $3C, $83, $53, $99, $61,
    $17, $2B, $04, $7E, $BA, $77, $D6, $26, $E1, $69, $14, $63, $55, $21, $0C, $7D
  );

procedure EnsureExperimentalIntrinsicsEnabled(const aFunctionName: string); inline;
begin
  {$IFNDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  raise ENotSupportedException.CreateFmt(
    '%s requires FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS opt-in.',
    [aFunctionName]
  );
  {$ELSE}
  if aFunctionName = '' then
    ;
  {$ENDIF}
end;

function GFMul(aLeft, aRight: Byte): Byte; inline;
var
  LValue: Byte;
  LMultiplier: Byte;
  LProduct: Byte;
  LCarry: Byte;
  LIndex: Integer;
begin
  LValue := aLeft;
  LMultiplier := aRight;
  LProduct := 0;
  for LIndex := 0 to 7 do
  begin
    if (LMultiplier and 1) <> 0 then
      LProduct := LProduct xor LValue;
    LCarry := LValue and $80;
    LValue := Byte((LValue shl 1) and $FF);
    if LCarry <> 0 then
      LValue := LValue xor $1B;
    LMultiplier := LMultiplier shr 1;
  end;
  Result := LProduct;
end;

procedure AESAddRoundKey(var aState: TM128; const aRoundKey: TM128); inline;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    aState.m128i_u8[LIndex] := aState.m128i_u8[LIndex] xor aRoundKey.m128i_u8[LIndex];
end;

procedure AESSubBytes(var aState: TM128); inline;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    aState.m128i_u8[LIndex] := AES_SBOX[aState.m128i_u8[LIndex]];
end;

procedure AESInvSubBytes(var aState: TM128); inline;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    aState.m128i_u8[LIndex] := AES_INV_SBOX[aState.m128i_u8[LIndex]];
end;

procedure AESShiftRows(var aState: TM128); inline;
var
  LTemp: Byte;
begin
  LTemp := aState.m128i_u8[1];
  aState.m128i_u8[1] := aState.m128i_u8[5];
  aState.m128i_u8[5] := aState.m128i_u8[9];
  aState.m128i_u8[9] := aState.m128i_u8[13];
  aState.m128i_u8[13] := LTemp;

  LTemp := aState.m128i_u8[2];
  aState.m128i_u8[2] := aState.m128i_u8[10];
  aState.m128i_u8[10] := LTemp;
  LTemp := aState.m128i_u8[6];
  aState.m128i_u8[6] := aState.m128i_u8[14];
  aState.m128i_u8[14] := LTemp;

  LTemp := aState.m128i_u8[3];
  aState.m128i_u8[3] := aState.m128i_u8[15];
  aState.m128i_u8[15] := aState.m128i_u8[11];
  aState.m128i_u8[11] := aState.m128i_u8[7];
  aState.m128i_u8[7] := LTemp;
end;

procedure AESInvShiftRows(var aState: TM128); inline;
var
  LTemp: Byte;
begin
  LTemp := aState.m128i_u8[13];
  aState.m128i_u8[13] := aState.m128i_u8[9];
  aState.m128i_u8[9] := aState.m128i_u8[5];
  aState.m128i_u8[5] := aState.m128i_u8[1];
  aState.m128i_u8[1] := LTemp;

  LTemp := aState.m128i_u8[2];
  aState.m128i_u8[2] := aState.m128i_u8[10];
  aState.m128i_u8[10] := LTemp;
  LTemp := aState.m128i_u8[6];
  aState.m128i_u8[6] := aState.m128i_u8[14];
  aState.m128i_u8[14] := LTemp;

  LTemp := aState.m128i_u8[7];
  aState.m128i_u8[7] := aState.m128i_u8[11];
  aState.m128i_u8[11] := aState.m128i_u8[15];
  aState.m128i_u8[15] := aState.m128i_u8[3];
  aState.m128i_u8[3] := LTemp;
end;

procedure AESMixColumns(var aState: TM128); inline;
var
  LColumn: Integer;
  LA: Byte;
  LB: Byte;
  LC: Byte;
  LD: Byte;
begin
  for LColumn := 0 to 3 do
  begin
    LA := aState.m128i_u8[(LColumn * 4) + 0];
    LB := aState.m128i_u8[(LColumn * 4) + 1];
    LC := aState.m128i_u8[(LColumn * 4) + 2];
    LD := aState.m128i_u8[(LColumn * 4) + 3];
    aState.m128i_u8[(LColumn * 4) + 0] := GFMul(LA, $02) xor GFMul(LB, $03) xor LC xor LD;
    aState.m128i_u8[(LColumn * 4) + 1] := LA xor GFMul(LB, $02) xor GFMul(LC, $03) xor LD;
    aState.m128i_u8[(LColumn * 4) + 2] := LA xor LB xor GFMul(LC, $02) xor GFMul(LD, $03);
    aState.m128i_u8[(LColumn * 4) + 3] := GFMul(LA, $03) xor LB xor LC xor GFMul(LD, $02);
  end;
end;

procedure AESInvMixColumns(var aState: TM128); inline;
var
  LColumn: Integer;
  LA: Byte;
  LB: Byte;
  LC: Byte;
  LD: Byte;
begin
  for LColumn := 0 to 3 do
  begin
    LA := aState.m128i_u8[(LColumn * 4) + 0];
    LB := aState.m128i_u8[(LColumn * 4) + 1];
    LC := aState.m128i_u8[(LColumn * 4) + 2];
    LD := aState.m128i_u8[(LColumn * 4) + 3];
    aState.m128i_u8[(LColumn * 4) + 0] := GFMul(LA, $0E) xor GFMul(LB, $0B) xor GFMul(LC, $0D) xor GFMul(LD, $09);
    aState.m128i_u8[(LColumn * 4) + 1] := GFMul(LA, $09) xor GFMul(LB, $0E) xor GFMul(LC, $0B) xor GFMul(LD, $0D);
    aState.m128i_u8[(LColumn * 4) + 2] := GFMul(LA, $0D) xor GFMul(LB, $09) xor GFMul(LC, $0E) xor GFMul(LD, $0B);
    aState.m128i_u8[(LColumn * 4) + 3] := GFMul(LA, $0B) xor GFMul(LB, $0D) xor GFMul(LC, $09) xor GFMul(LD, $0E);
  end;
end;

procedure CopySubWord(const aInput: TM128; aSourceOffset, aDestOffset: Integer; var aOutput: TM128); inline;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aOutput.m128i_u8[aDestOffset + LIndex] := AES_SBOX[aInput.m128i_u8[aSourceOffset + LIndex]];
end;

procedure CopyRotSubWordXorRcon(const aInput: TM128; aSourceOffset, aDestOffset: Integer; aRcon: Byte; var aOutput: TM128); inline;
begin
  aOutput.m128i_u8[aDestOffset + 0] := AES_SBOX[aInput.m128i_u8[aSourceOffset + 1]] xor aRcon;
  aOutput.m128i_u8[aDestOffset + 1] := AES_SBOX[aInput.m128i_u8[aSourceOffset + 2]];
  aOutput.m128i_u8[aDestOffset + 2] := AES_SBOX[aInput.m128i_u8[aSourceOffset + 3]];
  aOutput.m128i_u8[aDestOffset + 3] := AES_SBOX[aInput.m128i_u8[aSourceOffset + 0]];
end;

function aes_aesenc_si128(const data, round_key: TM128): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('aes_aesenc_si128');
  Result := data;
  AESSubBytes(Result);
  AESShiftRows(Result);
  AESMixColumns(Result);
  AESAddRoundKey(Result, round_key);
end;

function aes_aesenclast_si128(const data, round_key: TM128): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('aes_aesenclast_si128');
  Result := data;
  AESSubBytes(Result);
  AESShiftRows(Result);
  AESAddRoundKey(Result, round_key);
end;

function aes_aesdec_si128(const data, round_key: TM128): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('aes_aesdec_si128');
  Result := data;
  AESInvSubBytes(Result);
  AESInvShiftRows(Result);
  AESInvMixColumns(Result);
  AESAddRoundKey(Result, round_key);
end;

function aes_aesdeclast_si128(const data, round_key: TM128): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('aes_aesdeclast_si128');
  Result := data;
  AESInvSubBytes(Result);
  AESInvShiftRows(Result);
  AESAddRoundKey(Result, round_key);
end;

function aes_aeskeygenassist_si128(const key: TM128; rcon: Byte): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('aes_aeskeygenassist_si128');
  FillChar(Result, SizeOf(Result), 0);
  CopySubWord(key, 4, 0, Result);
  CopyRotSubWordXorRcon(key, 4, 4, rcon, Result);
  CopySubWord(key, 12, 8, Result);
  CopyRotSubWordXorRcon(key, 12, 12, rcon, Result);
end;

function aes_aesimc_si128(const data: TM128): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('aes_aesimc_si128');
  Result := data;
  AESInvMixColumns(Result);
end;

end.
