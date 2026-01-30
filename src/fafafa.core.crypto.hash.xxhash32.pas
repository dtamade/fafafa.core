{
  fafafa.core.crypto.hash.xxhash32 - XXH32 非加密哈希实现（流式 + 种子）

  说明：
  - 非加密哈希（不可用于安全用途）
  - 提供 IHashAlgorithm 接口兼容的流式 API：Update/Finalize/Reset/Burn
  - 工厂与便利函数：CreateXXH32 / XXH32Hash

  常量参考（与 xxhash 官方实现等价）：
  PRIME32_1 = 2654435761; // $9E3779B1
  PRIME32_2 = 2246822519; // $85EBCA77
  PRIME32_3 = 3266489917; // $C2B2AE3D
  PRIME32_4 =  668265263; // $27D4EB2F
  PRIME32_5 =  374761393; // $165667B1
}

unit fafafa.core.crypto.hash.xxhash32;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base,
  fafafa.core.crypto.interfaces;

type
  // 重新导出共享类型
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  IHashAlgorithm = fafafa.core.crypto.interfaces.IHashAlgorithm;
  ECryptoHash = fafafa.core.crypto.interfaces.ECryptoHash;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;

  { TXXH32Context }
  TXXH32Context = class(TInterfacedObject, IHashAlgorithm)
  private
    FSeed: UInt32;
    FTotalLen: UInt32;
    FAcc1, FAcc2, FAcc3, FAcc4: UInt32;
    FMem: array[0..15] of Byte; // 16-byte buffer for tail between updates
    FMemSize: Integer;          // number of bytes in FMem
    FFinalized: Boolean;

    procedure InitAccumulators;
    class function RotL32(AValue: UInt32; AShift: Integer): UInt32; static; inline;
    class function ReadLE32(const P: PByte): UInt32; static; inline;
  public
    constructor Create(ASeed: UInt32);

    // IHashAlgorithm
    function GetDigestSize: Integer;
    function GetBlockSize: Integer;
    function GetName: string;
    procedure Update(const AData; ASize: Integer);
    function Finalize: TBytes;
    procedure Reset;
    procedure Burn;
  end;

{ 工厂与便利函数 }
function CreateXXH32(ASeed: UInt32 = 0): IHashAlgorithm;
function XXH32Hash(const AData: TBytes; ASeed: UInt32 = 0): TBytes; overload;
function XXH32Hash(const AData: string; ASeed: UInt32 = 0): TBytes; overload;

implementation

const
  PRIME32_1 = UInt32($9E3779B1);
  PRIME32_2 = UInt32($85EBCA77);
  PRIME32_3 = UInt32($C2B2AE3D);
  PRIME32_4 = UInt32($27D4EB2F);
  PRIME32_5 = UInt32($165667B1);

{ TXXH32Context }

constructor TXXH32Context.Create(ASeed: UInt32);
begin
  inherited Create;
  FSeed := ASeed;
  Reset;
end;

procedure TXXH32Context.InitAccumulators;
begin
  // 初始化累加器（参考 xxhash C 实现）
  {$PUSH}{$RANGECHECKS OFF}{$OVERFLOWCHECKS OFF}
  FAcc1 := FSeed + PRIME32_1 + PRIME32_2;
  FAcc2 := FSeed + PRIME32_2;
  FAcc3 := FSeed + 0;
  FAcc4 := FSeed - PRIME32_1;
  {$POP}
end;

class function TXXH32Context.RotL32(AValue: UInt32; AShift: Integer): UInt32;
begin
  Result := (AValue shl AShift) or (AValue shr (32 - AShift));
end;

class function TXXH32Context.ReadLE32(const P: PByte): UInt32;
var
  Q: PByte;
  b0, b1, b2, b3: UInt32;
begin
  // 小端拼装 32 位，避免指针索引触发范围检查
  Q := P;
  b0 := Q^; Inc(Q);
  b1 := Q^; Inc(Q);
  b2 := Q^; Inc(Q);
  b3 := Q^;
  Result := b0 or (b1 shl 8) or (b2 shl 16) or (b3 shl 24);
end;

function TXXH32Context.GetDigestSize: Integer;
begin
  Result := 4;
end;

function TXXH32Context.GetBlockSize: Integer;
begin
  Result := 16;
end;

function TXXH32Context.GetName: string;
begin
  Result := 'XXH32';
end;

procedure TXXH32Context.Reset;
begin
  FTotalLen := 0;
  FMemSize := 0;
  FillChar(FMem[0], SizeOf(FMem), 0);
  FFinalized := False;
  InitAccumulators;
end;

procedure TXXH32Context.Burn;
begin
  // 虽为非加密算法，仍提供清理以保持一致
  FSeed := 0; FTotalLen := 0; FMemSize := 0; FFinalized := True;
  FAcc1 := 0; FAcc2 := 0; FAcc3 := 0; FAcc4 := 0;
  FillChar(FMem[0], SizeOf(FMem), 0);
end;

procedure TXXH32Context.Update(const AData; ASize: Integer);
var
  P: PByte;
  LSize: Integer;
  LRead: Integer;
  V: UInt32;
begin
  if FFinalized then
    raise EInvalidOperation.Create('Cannot update finalized hash context');

  if ASize <= 0 then Exit;
  // ASize 累计到总长度
  {$OVERFLOWCHECKS OFF}
  Inc(FTotalLen, UInt32(ASize));
  {$OVERFLOWCHECKS ON}

  P := @AData;
  LSize := ASize;

  // 如果缓冲区中有历史数据，先凑满 16 字节
  if (FMemSize + LSize) < 16 then
  begin
    Move(P^, FMem[FMemSize], LSize);
    Inc(FMemSize, LSize);
    Exit;
  end;

  {$PUSH}{$RANGECHECKS OFF}{$OVERFLOWCHECKS OFF}

  if FMemSize > 0 then
  begin
    // 补全 16 字节
    LRead := 16 - FMemSize;
    Move(P^, FMem[FMemSize], LRead);
    Inc(P, LRead);
    Dec(LSize, LRead);

    // 处理缓冲块
    V := ReadLE32(@FMem[0]);
    FAcc1 := RotL32(FAcc1 + V * PRIME32_2, 13) * PRIME32_1;
    V := ReadLE32(@FMem[4]);
    FAcc2 := RotL32(FAcc2 + V * PRIME32_2, 13) * PRIME32_1;
    V := ReadLE32(@FMem[8]);
    FAcc3 := RotL32(FAcc3 + V * PRIME32_2, 13) * PRIME32_1;
    V := ReadLE32(@FMem[12]);
    FAcc4 := RotL32(FAcc4 + V * PRIME32_2, 13) * PRIME32_1;

    FMemSize := 0;
  end;

  // 处理主循环中的 16 字节块
  while LSize >= 16 do
  begin
    V := ReadLE32(P);
    FAcc1 := RotL32(FAcc1 + V * PRIME32_2, 13) * PRIME32_1;
    Inc(P, 4);

    V := ReadLE32(P);
    FAcc2 := RotL32(FAcc2 + V * PRIME32_2, 13) * PRIME32_1;
    Inc(P, 4);

    V := ReadLE32(P);
    FAcc3 := RotL32(FAcc3 + V * PRIME32_2, 13) * PRIME32_1;
    Inc(P, 4);

    V := ReadLE32(P);
    FAcc4 := RotL32(FAcc4 + V * PRIME32_2, 13) * PRIME32_1;
    Inc(P, 4);

    Dec(LSize, 16);
  end;

  // 剩余的零头拷入缓冲
  if LSize > 0 then
  begin
    Move(P^, FMem[0], LSize);
    FMemSize := LSize;
  {$POP}

  end;
end;

function TXXH32Context.Finalize: TBytes;
var
  H32: UInt32;
  P: PByte;
  R: Integer;
  K1: UInt32;
begin
  // initialize managed return for conservative analyzers
  Result := nil; SetLength(Result, 0);
  {$PUSH}{$RANGECHECKS OFF}{$OVERFLOWCHECKS OFF}
  if FFinalized then
    raise EInvalidOperation.Create('Hash context already finalized');

  // 初始化 h32
  if FTotalLen >= 16 then
  begin
    H32 := RotL32(FAcc1, 1) + RotL32(FAcc2, 7) + RotL32(FAcc3, 12) + RotL32(FAcc4, 18);
  end
  else
  begin
    H32 := FSeed + PRIME32_5;
  end;

  // 加入长度
  Inc(H32, FTotalLen);

  // 处理剩余 ≤15 字节
  P := @FMem[0];
  R := FMemSize;

  // 4 字节块
  while R >= 4 do
  begin
    K1 := ReadLE32(P) * PRIME32_3;
    K1 := RotL32(K1, 17) * PRIME32_4;
    H32 := H32 xor K1;
    H32 := RotL32(H32, 17) * PRIME32_4 + PRIME32_1; // +P1 per original path
    Inc(P, 4);
    Dec(R, 4);
  end;

  // 剩余字节
  while R > 0 do
  begin
    H32 := H32 xor (UInt32(P^) * PRIME32_5);
    H32 := RotL32(H32, 11) * PRIME32_1;
    Inc(P);
    Dec(R);
  end;

  // avalanche
  H32 := H32 xor (H32 shr 15);
  H32 := H32 * PRIME32_2;
  H32 := H32 xor (H32 shr 13);
  H32 := H32 * PRIME32_3;
  H32 := H32 xor (H32 shr 16);

  // 输出小端 4 字节
  SetLength(Result, 4);
  // 输出大端（MSB-first），与官方向量一致
  Result[0] := Byte((H32 shr 24) and $FF);
  Result[1] := Byte((H32 shr 16) and $FF);
  Result[2] := Byte((H32 shr 8) and $FF);
  Result[3] := Byte(H32 and $FF);

  FFinalized := True;
  {$POP}
end;

function CreateXXH32(ASeed: UInt32): IHashAlgorithm;
begin
  Result := TXXH32Context.Create(ASeed);
end;

function XXH32Hash(const AData: TBytes; ASeed: UInt32): TBytes;
{$push}
{$hints off}

var
  H: IHashAlgorithm;
begin
  H := CreateXXH32(ASeed);
  if Length(AData) > 0 then
    H.Update(AData[0], Length(AData));
  Result := H.Finalize;
  H.Burn;
end;
{$pop}


function XXH32Hash(const AData: string; ASeed: UInt32): TBytes;
var
  Bytes: TBytes;
begin
  SetLength(Bytes, Length(AData));
  if Length(AData) > 0 then
    Move(AData[1], Bytes[0], Length(AData));
  Result := XXH32Hash(Bytes, ASeed);
end;

end.

