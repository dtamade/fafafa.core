{
  fafafa.core.crypto.hash.xxhash64 - XXH64 非加密哈希实现（流式 + 种子）

  说明：
  - 非加密哈希（不可用于安全用途）
  - IHashAlgorithm 兼容；DigestSize=8；BlockSize=32
}

unit fafafa.core.crypto.hash.xxhash64;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.crypto.interfaces;

type
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  IHashAlgorithm = fafafa.core.crypto.interfaces.IHashAlgorithm;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;

  { TXXH64Context }
  TXXH64Context = class(TInterfacedObject, IHashAlgorithm)
  private
    FSeed: QWord;
    FTotalLen: QWord;
    FAcc1, FAcc2, FAcc3, FAcc4: QWord;
    FMem: array[0..31] of Byte; // 32-byte buffer
    FMemSize: Integer;
    FFinalized: Boolean;

    procedure InitAccumulators;
    class function RotL64(AValue: QWord; AShift: Integer): QWord; static; inline;
    class function ReadLE64(const P: PByte): QWord; static;
  public
    constructor Create(ASeed: QWord);

    // IHashAlgorithm
    function GetDigestSize: Integer;
    function GetBlockSize: Integer;
    function GetName: string;
    procedure Update(const AData; ASize: Integer);
    function Finalize: TBytes;
    procedure Reset;
    procedure Burn;
  end;

function CreateXXH64(ASeed: QWord = 0): IHashAlgorithm;
function XXH64Hash(const AData: TBytes; ASeed: QWord = 0): TBytes; overload;
function XXH64Hash(const AData: string; ASeed: QWord = 0): TBytes; overload;

implementation

const
  PRIME64_1 = QWord($9E3779B185EBCA87);
  PRIME64_2 = QWord($C2B2AE3D27D4EB4F);
  PRIME64_3 = QWord($165667B19E3779F9);
  PRIME64_4 = QWord($85EBCA77C2B2AE63);
  PRIME64_5 = QWord($27D4EB2F165667C5);

constructor TXXH64Context.Create(ASeed: QWord);
begin
  inherited Create;
  FSeed := ASeed;
  Reset;
end;

procedure TXXH64Context.InitAccumulators;
begin
  // avoid overflow check in constant arithmetic
  {$OVERFLOWCHECKS OFF}
  FAcc1 := FSeed + PRIME64_1;
  FAcc1 := FAcc1 + PRIME64_2;
  FAcc2 := FSeed + PRIME64_2;
  FAcc3 := FSeed;
  FAcc4 := FSeed - PRIME64_1;
  {$OVERFLOWCHECKS ON}
end;

class function TXXH64Context.RotL64(AValue: QWord; AShift: Integer): QWord;
begin
  Result := (AValue shl AShift) or (AValue shr (64 - AShift));
end;

class function TXXH64Context.ReadLE64(const P: PByte): QWord;
var Q: PByte; b0,b1,b2,b3,b4,b5,b6,b7: QWord;
begin
  Q := P;
  b0 := Q^; Inc(Q);
  b1 := Q^; Inc(Q);
  b2 := Q^; Inc(Q);
  b3 := Q^; Inc(Q);
  b4 := Q^; Inc(Q);
  b5 := Q^; Inc(Q);
  b6 := Q^; Inc(Q);
  b7 := Q^;
  Result := b0 or (b1 shl 8) or (b2 shl 16) or (b3 shl 24)
         or (b4 shl 32) or (b5 shl 40) or (b6 shl 48) or (b7 shl 56);
end;

function TXXH64Context.GetDigestSize: Integer; begin Result := 8; end;
function TXXH64Context.GetBlockSize: Integer; begin Result := 32; end;
function TXXH64Context.GetName: string; begin Result := 'XXH64'; end;

procedure TXXH64Context.Reset;
begin
  FTotalLen := 0; FMemSize := 0; FillChar(FMem[0], SizeOf(FMem), 0); FFinalized := False;
  InitAccumulators;
end;

procedure TXXH64Context.Burn;
begin
  FSeed := 0; FTotalLen := 0; FMemSize := 0; FFinalized := True;
  FAcc1 := 0; FAcc2 := 0; FAcc3 := 0; FAcc4 := 0;
  FillChar(FMem[0], SizeOf(FMem), 0);
end;

procedure TXXH64Context.Update(const AData; ASize: Integer);
var P: PByte; LSize,LRead: Integer; V: QWord;
begin
  if FFinalized then raise EInvalidOperation.Create('Cannot update finalized hash context');
  if ASize <= 0 then Exit;
  {$OVERFLOWCHECKS OFF}
  Inc(FTotalLen, QWord(ASize));
  {$OVERFLOWCHECKS ON}

  P := @AData; LSize := ASize;

  if (FMemSize + LSize) < 32 then
  begin
    Move(P^, FMem[FMemSize], LSize);
    Inc(FMemSize, LSize);
    Exit;
  end;

  if FMemSize > 0 then
  begin
    LRead := 32 - FMemSize;
    Move(P^, FMem[FMemSize], LRead);
    Inc(P, LRead); Dec(LSize, LRead);
    // consume buffer
    {$PUSH}{$Q-}{$R-}{$OVERFLOWCHECKS OFF}{$RANGECHECKS OFF}

    V := ReadLE64(@FMem[0]);  FAcc1 := RotL64(FAcc1 + V * PRIME64_2, 31) * PRIME64_1;
    V := ReadLE64(@FMem[8]);  FAcc2 := RotL64(FAcc2 + V * PRIME64_2, 31) * PRIME64_1;
    V := ReadLE64(@FMem[16]); FAcc3 := RotL64(FAcc3 + V * PRIME64_2, 31) * PRIME64_1;
    V := ReadLE64(@FMem[24]); FAcc4 := RotL64(FAcc4 + V * PRIME64_2, 31) * PRIME64_1;
    {$POP}

    FMemSize := 0;
  end;

  while LSize >= 32 do
  begin
    {$PUSH}{$Q-}{$R-}{$OVERFLOWCHECKS OFF}{$RANGECHECKS OFF}
    V := ReadLE64(P);   FAcc1 := RotL64(FAcc1 + V * PRIME64_2, 31) * PRIME64_1; Inc(P,8);
    V := ReadLE64(P);   FAcc2 := RotL64(FAcc2 + V * PRIME64_2, 31) * PRIME64_1; Inc(P,8);
    V := ReadLE64(P);   FAcc3 := RotL64(FAcc3 + V * PRIME64_2, 31) * PRIME64_1; Inc(P,8);
    V := ReadLE64(P);   FAcc4 := RotL64(FAcc4 + V * PRIME64_2, 31) * PRIME64_1; Inc(P,8);
    {$POP}
    Dec(LSize, 32);
  end;

  if LSize > 0 then
  begin
    Move(P^, FMem[0], LSize);
    FMemSize := LSize;
  end;
end;

function TXXH64Context.Finalize: TBytes;
var H64: QWord; P: PByte; R: Integer; K1: QWord;
begin
  // initialize managed return for conservative analyzers
  Result := nil; SetLength(Result, 0);
  if FFinalized then raise EInvalidOperation.Create('Hash context already finalized');

  if FTotalLen >= 32 then
  {$PUSH}{$Q-}{$R-}{$OVERFLOWCHECKS OFF}{$RANGECHECKS OFF}

  begin
    H64 := RotL64(FAcc1, 1) + RotL64(FAcc2, 7) + RotL64(FAcc3, 12) + RotL64(FAcc4, 18);
  end
  else
  {$POP}

    H64 := FSeed + PRIME64_5;

  Inc(H64, FTotalLen);

  {$PUSH}{$Q-}{$R-}{$OVERFLOWCHECKS OFF}{$RANGECHECKS OFF}

  P := @FMem[0]; R := FMemSize;

  while R >= 8 do
  begin
    K1 := ReadLE64(P) * PRIME64_2; K1 := RotL64(K1,31) * PRIME64_1; H64 := (H64 xor K1) * PRIME64_1 + PRIME64_4;
    Inc(P, 8); Dec(R, 8);
  end;

  if R >= 4 then
  begin
    H64 := H64 xor (QWord(P[0]) or (QWord(P[1]) shl 8) or (QWord(P[2]) shl 16) or (QWord(P[3]) shl 24)) * PRIME64_1;
    H64 := RotL64(H64, 23) * PRIME64_2 + PRIME64_3;
    Inc(P, 4); Dec(R, 4);
  end;

  while R > 0 do
  begin
    H64 := H64 xor (QWord(P^) * PRIME64_5);
    H64 := RotL64(H64, 11) * PRIME64_1;
    Inc(P); Dec(R);
  {$POP}

  end;

  // avalanche
  {$PUSH}{$Q-}{$R-}{$OVERFLOWCHECKS OFF}{$RANGECHECKS OFF}
  H64 := H64 xor (H64 shr 33); H64 := H64 * PRIME64_2;
  H64 := H64 xor (H64 shr 29); H64 := H64 * PRIME64_3;
  H64 := H64 xor (H64 shr 32);
  {$POP}

  SetLength(Result, 8);
  // 输出大端（MSB-first），与官方向量一致
  Result[0] := Byte((H64 shr 56) and $FF);
  Result[1] := Byte((H64 shr 48) and $FF);
  Result[2] := Byte((H64 shr 40) and $FF);
  Result[3] := Byte((H64 shr 32) and $FF);
  Result[4] := Byte((H64 shr 24) and $FF);
  Result[5] := Byte((H64 shr 16) and $FF);
  Result[6] := Byte((H64 shr 8) and $FF);
  Result[7] := Byte(H64 and $FF);

  FFinalized := True;
end;

function CreateXXH64(ASeed: QWord): IHashAlgorithm;
begin
  Result := TXXH64Context.Create(ASeed);
end;

function XXH64Hash(const AData: TBytes; ASeed: QWord): TBytes;
{$push}
{$hints off}

var H: IHashAlgorithm;
begin
  H := CreateXXH64(ASeed);
  if Length(AData) > 0 then H.Update(AData[0], Length(AData));
  Result := H.Finalize; H.Burn;
end;
{$pop}


function XXH64Hash(const AData: string; ASeed: QWord): TBytes;
var Bytes: TBytes;
begin
  SetLength(Bytes, Length(AData));
  if Length(AData) > 0 then Move(AData[1], Bytes[0], Length(AData));
  Result := XXH64Hash(Bytes, ASeed);
end;

end.

