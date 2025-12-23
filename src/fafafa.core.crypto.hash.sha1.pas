{
  fafafa.core.crypto.hash.sha1 - SHA-1哈希算法实现

  本单元实现了SHA-1安全哈希算法：
  - 符合FIPS PUB 180-4标准
  - 160位输出长度
  - 512位块大小
  - 纯Pascal实现，无外部依赖

  注意：SHA-1已不推荐用于安全敏感场景，
  但仍用于兼容性目的（如UUID v5）。
}

unit fafafa.core.crypto.hash.sha1;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.crypto.interfaces;

type
  // 重新导出共享类型
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  IHashAlgorithm = fafafa.core.crypto.interfaces.IHashAlgorithm;

  {**
   * TSHA1Context
   *
   * @desc
   *   SHA-1 hash algorithm implementation.
   *   SHA-1哈希算法实现.
   *}
  TSHA1Context = class(TInterfacedObject, IHashAlgorithm)
  private
    FState: array[0..4] of UInt32;      // 哈希状态 (5 x 32位)
    FBuffer: array[0..63] of Byte;      // 输入缓冲区
    FBitLength: UInt64;                 // 总位长度
    FBufferLength: Integer;             // 缓冲区当前长度
    FFinalized: Boolean;                // 是否已完成

    procedure ProcessBlock;
  public
    constructor Create;

    // IHashAlgorithm implementation
    function GetDigestSize: Integer;
    function GetBlockSize: Integer;
    function GetName: string;
    procedure Update(const AData; ASize: Integer);
    function Finalize: TBytes;
    procedure Reset;
    procedure Burn;
  end;

{**
 * CreateSHA1
 *
 * @desc
 *   Creates a new SHA-1 hash algorithm instance.
 *   创建新的SHA-1哈希算法实例.
 *}
function CreateSHA1: IHashAlgorithm;

{**
 * SHA1Hash
 *
 * @desc
 *   Computes SHA-1 hash of data in one call.
 *   一次性计算数据的SHA-1哈希.
 *}
function SHA1Hash(const AData: TBytes): TBytes; overload;
function SHA1Hash(const AData: string): TBytes; overload;
function SHA1Hash(const AData; ASize: Integer): TBytes; overload;

{**
 * SHA1HashHex
 *
 * @desc
 *   Computes SHA-1 hash and returns as hex string.
 *   计算SHA-1哈希并返回十六进制字符串.
 *}
function SHA1HashHex(const AData: TBytes): string; overload;
function SHA1HashHex(const AData: string): string; overload;

implementation

// 辅助函数
function LeftRotate(AValue: UInt32; AShift: Integer): UInt32; inline;
begin
  Result := (AValue shl AShift) or (AValue shr (32 - AShift));
end;

function BigEndianToHost(AValue: UInt32): UInt32; inline;
begin
  {$IFDEF ENDIAN_LITTLE}
  Result := ((AValue and $FF) shl 24) or
            (((AValue shr 8) and $FF) shl 16) or
            (((AValue shr 16) and $FF) shl 8) or
            ((AValue shr 24) and $FF);
  {$ELSE}
  Result := AValue;
  {$ENDIF}
end;

function HostToBigEndian(AValue: UInt32): UInt32; inline;
begin
  {$IFDEF ENDIAN_LITTLE}
  Result := ((AValue and $FF) shl 24) or
            (((AValue shr 8) and $FF) shl 16) or
            (((AValue shr 16) and $FF) shl 8) or
            ((AValue shr 24) and $FF);
  {$ELSE}
  Result := AValue;
  {$ENDIF}
end;

{ TSHA1Context }

constructor TSHA1Context.Create;
begin
  inherited Create;
  Reset;
end;

function TSHA1Context.GetDigestSize: Integer;
begin
  Result := 20; // SHA-1 产生20字节摘要
end;

function TSHA1Context.GetBlockSize: Integer;
begin
  Result := 64; // SHA-1 块大小为64字节
end;

function TSHA1Context.GetName: string;
begin
  Result := 'SHA-1';
end;

procedure TSHA1Context.Reset;
begin
  // SHA-1 初始哈希值
  FState[0] := $67452301;
  FState[1] := $EFCDAB89;
  FState[2] := $98BADCFE;
  FState[3] := $10325476;
  FState[4] := $C3D2E1F0;

  FBitLength := 0;
  FBufferLength := 0;
  FFinalized := False;
  FillChar(FBuffer, SizeOf(FBuffer), 0);
end;

procedure TSHA1Context.Burn;
begin
  // 安全清零所有敏感数据
  FillChar(FState, SizeOf(FState), 0);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  FBitLength := 0;
  FBufferLength := 0;
  FFinalized := True;
end;

procedure TSHA1Context.ProcessBlock;
var
  W: array[0..79] of UInt32;
  A, B, C, D, E, F, K, Temp: UInt32;
  I: Integer;
  PBlock: PUInt32;
begin
  PBlock := @FBuffer[0];

  // 准备消息调度数组
  for I := 0 to 15 do
    W[I] := BigEndianToHost(PBlock[I]);

  for I := 16 to 79 do
    W[I] := LeftRotate(W[I-3] xor W[I-8] xor W[I-14] xor W[I-16], 1);

  // 初始化工作变量
  A := FState[0];
  B := FState[1];
  C := FState[2];
  D := FState[3];
  E := FState[4];

  // 主循环 (80轮)
  for I := 0 to 79 do
  begin
    case I of
      0..19:
        begin
          F := (B and C) or ((not B) and D);
          K := $5A827999;
        end;
      20..39:
        begin
          F := B xor C xor D;
          K := $6ED9EBA1;
        end;
      40..59:
        begin
          F := (B and C) or (B and D) or (C and D);
          K := $8F1BBCDC;
        end;
      60..79:
        begin
          F := B xor C xor D;
          K := $CA62C1D6;
        end;
    end;

    Temp := LeftRotate(A, 5) + F + E + K + W[I];
    E := D;
    D := C;
    C := LeftRotate(B, 30);
    B := A;
    A := Temp;
  end;

  // 更新状态
  FState[0] := FState[0] + A;
  FState[1] := FState[1] + B;
  FState[2] := FState[2] + C;
  FState[3] := FState[3] + D;
  FState[4] := FState[4] + E;
end;

procedure TSHA1Context.Update(const AData; ASize: Integer);
var
  PData: PByte;
  BytesToCopy: Integer;
begin
  if FFinalized then
    raise Exception.Create('Cannot update finalized hash');

  if ASize <= 0 then
    Exit;

  PData := @AData;
  Inc(FBitLength, UInt64(ASize) * 8);

  // 处理缓冲区中的数据
  while ASize > 0 do
  begin
    BytesToCopy := 64 - FBufferLength;
    if BytesToCopy > ASize then
      BytesToCopy := ASize;

    Move(PData^, FBuffer[FBufferLength], BytesToCopy);
    Inc(FBufferLength, BytesToCopy);
    Inc(PData, BytesToCopy);
    Dec(ASize, BytesToCopy);

    if FBufferLength = 64 then
    begin
      ProcessBlock;
      FBufferLength := 0;
    end;
  end;
end;

function TSHA1Context.Finalize: TBytes;
var
  BitLen: UInt64;
  I: Integer;
  PResult: PUInt32;
begin
  Result := nil;
  if FFinalized then
    raise Exception.Create('Hash already finalized');

  // 添加填充位 (1后跟0)
  FBuffer[FBufferLength] := $80;
  Inc(FBufferLength);

  // 如果没有足够空间放长度，处理当前块并开始新块
  if FBufferLength > 56 then
  begin
    FillChar(FBuffer[FBufferLength], 64 - FBufferLength, 0);
    ProcessBlock;
    FBufferLength := 0;
  end;

  // 用0填充到56字节
  FillChar(FBuffer[FBufferLength], 56 - FBufferLength, 0);

  // 添加原始消息长度（大端序，64位）
  BitLen := FBitLength;
  FBuffer[56] := (BitLen shr 56) and $FF;
  FBuffer[57] := (BitLen shr 48) and $FF;
  FBuffer[58] := (BitLen shr 40) and $FF;
  FBuffer[59] := (BitLen shr 32) and $FF;
  FBuffer[60] := (BitLen shr 24) and $FF;
  FBuffer[61] := (BitLen shr 16) and $FF;
  FBuffer[62] := (BitLen shr 8) and $FF;
  FBuffer[63] := BitLen and $FF;

  ProcessBlock;

  // 生成最终哈希值
  SetLength(Result, 20);
  PResult := @Result[0];
  for I := 0 to 4 do
    PResult[I] := HostToBigEndian(FState[I]);

  FFinalized := True;
end;

{ 公共函数 }

function CreateSHA1: IHashAlgorithm;
begin
  Result := TSHA1Context.Create;
end;

function SHA1Hash(const AData: TBytes): TBytes;
var
  Hash: IHashAlgorithm;
begin
  Hash := CreateSHA1;
  if Length(AData) > 0 then
    Hash.Update(AData[0], Length(AData));
  Result := Hash.Finalize;
end;

function SHA1Hash(const AData: string): TBytes;
var
  Hash: IHashAlgorithm;
begin
  Hash := CreateSHA1;
  if Length(AData) > 0 then
    Hash.Update(AData[1], Length(AData));
  Result := Hash.Finalize;
end;

function SHA1Hash(const AData; ASize: Integer): TBytes;
var
  Hash: IHashAlgorithm;
begin
  Hash := CreateSHA1;
  if ASize > 0 then
    Hash.Update(AData, ASize);
  Result := Hash.Finalize;
end;

function SHA1HashHex(const AData: TBytes): string;
const
  HexChars: array[0..15] of Char = '0123456789abcdef';
var
  Hash: TBytes;
  I: Integer;
begin
  Result := '';
  Hash := SHA1Hash(AData);
  SetLength(Result, 40);
  for I := 0 to 19 do
  begin
    Result[I * 2 + 1] := HexChars[Hash[I] shr 4];
    Result[I * 2 + 2] := HexChars[Hash[I] and $0F];
  end;
end;

function SHA1HashHex(const AData: string): string;
const
  HexChars: array[0..15] of Char = '0123456789abcdef';
var
  Hash: TBytes;
  I: Integer;
begin
  Result := '';
  Hash := SHA1Hash(AData);
  SetLength(Result, 40);
  for I := 0 to 19 do
  begin
    Result[I * 2 + 1] := HexChars[Hash[I] shr 4];
    Result[I * 2 + 2] := HexChars[Hash[I] and $0F];
  end;
end;

end.
