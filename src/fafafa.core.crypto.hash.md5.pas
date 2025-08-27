{
  fafafa.core.crypto.hash.md5 - MD5哈希算法实现
  
  本单元实现了MD5消息摘要算法：
  - 符合RFC 1321标准
  - 128位输出长度
  - 512位块大小
  - 纯Pascal实现，无外部依赖
  
  注意：MD5已被认为是不安全的，仅用于兼容性目的
  
  实现特点：
  - 高性能优化
  - 内存安全
  - 跨平台兼容
  - 支持流式处理
}

unit fafafa.core.crypto.hash.md5;

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

  {**
   * TMD5Context
   *
   * @desc
   *   MD5 hash algorithm implementation.
   *   MD5哈希算法实现.
   *}
  TMD5Context = class(TInterfacedObject, IHashAlgorithm)
  private
    FState: array[0..3] of UInt32;      // 哈希状态
    FBuffer: array[0..63] of UInt8;     // 输入缓冲区
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
 * CreateMD5
 *
 * @desc
 *   Creates a new MD5 hash algorithm instance.
 *   创建新的MD5哈希算法实例.
 *}
function CreateMD5: IHashAlgorithm;

{**
 * MD5Hash
 *
 * @desc
 *   Computes MD5 hash of data in one call.
 *   一次性计算数据的MD5哈希.
 *}
function MD5Hash(const AData: TBytes): TBytes; overload;
function MD5Hash(const AData: string): TBytes; overload;

implementation

// MD5辅助函数
function F(X, Y, Z: UInt32): UInt32; inline;
begin
  Result := (X and Y) or ((not X) and Z);
end;

function G(X, Y, Z: UInt32): UInt32; inline;
begin
  Result := (X and Z) or (Y and (not Z));
end;

function H(X, Y, Z: UInt32): UInt32; inline;
begin
  Result := X xor Y xor Z;
end;

function I(X, Y, Z: UInt32): UInt32; inline;
begin
  Result := Y xor (X or (not Z));
end;

function LeftRotate(AValue: UInt32; AShift: Integer): UInt32; inline;
begin
  Result := (AValue shl AShift) or (AValue shr (32 - AShift));
end;

function LittleEndianToHost(AValue: UInt32): UInt32; inline;
begin
  {$IFDEF ENDIAN_BIG}
  Result := ((AValue and $FF) shl 24) or
            (((AValue shr 8) and $FF) shl 16) or
            (((AValue shr 16) and $FF) shl 8) or
            ((AValue shr 24) and $FF);
  {$ELSE}
  Result := AValue;
  {$ENDIF}
end;

function HostToLittleEndian(AValue: UInt32): UInt32; inline;
begin
  {$IFDEF ENDIAN_BIG}
  Result := ((AValue and $FF) shl 24) or
            (((AValue shr 8) and $FF) shl 16) or
            (((AValue shr 16) and $FF) shl 8) or
            ((AValue shr 24) and $FF);
  {$ELSE}
  Result := AValue;
  {$ENDIF}
end;

{ TMD5Context }

constructor TMD5Context.Create;
begin
  inherited Create;
  Reset;
end;

function TMD5Context.GetDigestSize: Integer;
begin
  Result := 16; // MD5 产生16字节摘要
end;

function TMD5Context.GetBlockSize: Integer;
begin
  Result := 64; // MD5 块大小为64字节
end;

function TMD5Context.GetName: string;
begin
  Result := 'MD5';
end;

procedure TMD5Context.Reset;
begin
  // MD5 初始哈希值
  FState[0] := $67452301;
  FState[1] := $efcdab89;
  FState[2] := $98badcfe;
  FState[3] := $10325476;
  
  FBitLength := 0;
  FBufferLength := 0;
  FFinalized := False;
  FillChar(FBuffer, SizeOf(FBuffer), 0);
end;

procedure TMD5Context.Burn;
begin
  // 安全清零所有敏感数据
  FillChar(FState, SizeOf(FState), 0);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  FBitLength := 0;
  FBufferLength := 0;
  FFinalized := True;
end;

procedure TMD5Context.Update(const AData; ASize: Integer);
var
  LData: PByte;
  LRemaining: Integer;
begin
  if FFinalized then
    raise EInvalidOperation.Create('Cannot update finalized hash context');

  if ASize <= 0 then
    Exit;

  // 更新总位长度
  {$OVERFLOWCHECKS OFF}
  Inc(FBitLength, UInt64(ASize) * 8);
  {$OVERFLOWCHECKS ON}

  LData := @AData;
  LRemaining := ASize;

  // 基于DCPcrypt的安全实现
  while LRemaining > 0 do
  begin
    if (64 - FBufferLength) <= LRemaining then
    begin
      // 填满缓冲区并处理
      if FBufferLength < 64 then
        Move(LData^, FBuffer[FBufferLength], 64 - FBufferLength);
      Dec(LRemaining, 64 - FBufferLength);
      Inc(LData, 64 - FBufferLength);
      ProcessBlock;
      FBufferLength := 0;
    end
    else
    begin
      // 将剩余数据存入缓冲区
      Move(LData^, FBuffer[FBufferLength], LRemaining);
      Inc(FBufferLength, LRemaining);
      LRemaining := 0;
    end;
  end;
end;

procedure TMD5Context.ProcessBlock;
const
  // MD5常量表
  K: array[0..63] of UInt32 = (
    $d76aa478, $e8c7b756, $242070db, $c1bdceee, $f57c0faf, $4787c62a, $a8304613, $fd469501,
    $698098d8, $8b44f7af, $ffff5bb1, $895cd7be, $6b901122, $fd987193, $a679438e, $49b40821,
    $f61e2562, $c040b340, $265e5a51, $e9b6c7aa, $d62f105d, $02441453, $d8a1e681, $e7d3fbc8,
    $21e1cde6, $c33707d6, $f4d50d87, $455a14ed, $a9e3e905, $fcefa3f8, $676f02d9, $8d2a4c8a,
    $fffa3942, $8771f681, $6d9d6122, $fde5380c, $a4beea44, $4bdecfa9, $f6bb4b60, $bebfbc70,
    $289b7ec6, $eaa127fa, $d4ef3085, $04881d05, $d9d4d039, $e6db99e5, $1fa27cf8, $c4ac5665,
    $f4292244, $432aff97, $ab9423a7, $fc93a039, $655b59c3, $8f0ccc92, $ffeff47d, $85845dd1,
    $6fa87e4f, $fe2ce6e0, $a3014314, $4e0811a1, $f7537e82, $bd3af235, $2ad7d2bb, $eb86d391
  );

  // 轮转量表
  S: array[0..63] of Integer = (
    7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
    5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
    4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
    6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
  );

var
  LW: array[0..15] of UInt32;
  LA, LB, LC, LD: UInt32;
  LF, LG: UInt32;
  LTemp: UInt32;
  LI: Integer;
begin
  {$RANGECHECKS OFF}
  {$OVERFLOWCHECKS OFF}
  // 将块转换为32位字（小端序） - 安全地读取4个字节并组合
  for LI := 0 to 15 do
  begin
    LW[LI] := UInt32(FBuffer[LI * 4]) or
              (UInt32(FBuffer[LI * 4 + 1]) shl 8) or
              (UInt32(FBuffer[LI * 4 + 2]) shl 16) or
              (UInt32(FBuffer[LI * 4 + 3]) shl 24);
  end;

  // 初始化工作变量
  LA := FState[0]; LB := FState[1]; LC := FState[2]; LD := FState[3];

  // 主循环
  for LI := 0 to 63 do
  begin
    if LI < 16 then
    begin
      LF := F(LB, LC, LD);
      LG := LI;
    end
    else if LI < 32 then
    begin
      LF := G(LB, LC, LD);
      LG := (5 * LI + 1) mod 16;
    end
    else if LI < 48 then
    begin
      LF := H(LB, LC, LD);
      LG := (3 * LI + 5) mod 16;
    end
    else
    begin
      LF := I(LB, LC, LD);
      LG := (7 * LI) mod 16;
    end;

    LTemp := LD;
    LD := LC;
    LC := LB;
    LB := LB + LeftRotate(LA + LF + K[LI] + LW[LG], S[LI]);
    LA := LTemp;
  end;

  // 添加到哈希值
  Inc(FState[0], LA);
  Inc(FState[1], LB);
  Inc(FState[2], LC);
  Inc(FState[3], LD);

  {$RANGECHECKS ON}
  {$OVERFLOWCHECKS ON}
end;



function TMD5Context.Finalize: TBytes;
var
  LI: Integer;
begin
  Result := nil;
  if FFinalized then
    raise EInvalidOperation.Create('Hash context already finalized');

  // 严格按照DCPcrypt的模式实现
  FBuffer[FBufferLength] := $80;

  if FBufferLength >= 56 then
  begin
    ProcessBlock;
    // 清空缓冲区，为长度字段准备新的块
    FillChar(FBuffer, 64, 0);
  end;

  // 添加长度（小端序）
  // 低32位
  FBuffer[56] := FBitLength and $FF;
  FBuffer[57] := (FBitLength shr 8) and $FF;
  FBuffer[58] := (FBitLength shr 16) and $FF;
  FBuffer[59] := (FBitLength shr 24) and $FF;
  // 高32位
  FBuffer[60] := (FBitLength shr 32) and $FF;
  FBuffer[61] := (FBitLength shr 40) and $FF;
  FBuffer[62] := (FBitLength shr 48) and $FF;
  FBuffer[63] := (FBitLength shr 56) and $FF;

  // 处理最后的块
  ProcessBlock;

  FFinalized := True;

  // 转换为字节数组（小端序）
  SetLength(Result, 16);
  for LI := 0 to 3 do
  begin
    Result[LI*4] := FState[LI] and $FF;
    Result[LI*4+1] := (FState[LI] shr 8) and $FF;
    Result[LI*4+2] := (FState[LI] shr 16) and $FF;
    Result[LI*4+3] := (FState[LI] shr 24) and $FF;
  end;
end;

// 工厂函数和便利函数
function CreateMD5: IHashAlgorithm;
begin
  Result := TMD5Context.Create;
end;

function MD5Hash(const AData: TBytes): TBytes;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateMD5;
  if Length(AData) > 0 then
    LHash.Update(AData[0], Length(AData));
  Result := LHash.Finalize;
  LHash.Burn;
end;

function MD5Hash(const AData: string): TBytes;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateMD5;
  if Length(AData) > 0 then
    LHash.Update(AData[1], Length(AData));
  Result := LHash.Finalize;
  LHash.Burn;
end;

end.
