{
  fafafa.core.crypto.hash.sha256 - SHA-256哈希算法实现
  
  本单元实现了SHA-256安全哈希算法：
  - 符合FIPS PUB 180-4标准
  - 256位输出长度
  - 512位块大小
  - 纯Pascal实现，无外部依赖
  
  实现特点：
  - 高性能优化
  - 内存安全
  - 跨平台兼容
  - 支持流式处理
}

unit fafafa.core.crypto.hash.sha256;

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
   * TSHA256Context
   *
   * @desc
   *   SHA-256 hash algorithm implementation.
   *   SHA-256哈希算法实现.
   *}
  TSHA256Context = class(TInterfacedObject, IHashAlgorithm)
  private
    FState: array[0..7] of UInt32;      // 哈希状态
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
 * CreateSHA256
 *
 * @desc
 *   Creates a new SHA-256 hash algorithm instance.
 *   创建新的SHA-256哈希算法实例.
 *}
function CreateSHA256: IHashAlgorithm;

{**
 * SHA256Hash
 *
 * @desc
 *   Computes SHA-256 hash of data in one call.
 *   一次性计算数据的SHA-256哈希.
 *}
function SHA256Hash(const AData: TBytes): TBytes; overload;
function SHA256Hash(const AData: string): TBytes; overload;

implementation

// SHA-256常量
const
  SHA256_K: array[0..63] of UInt32 = (
    $428a2f98, $71374491, $b5c0fbcf, $e9b5dba5, $3956c25b, $59f111f1, $923f82a4, $ab1c5ed5,
    $d807aa98, $12835b01, $243185be, $550c7dc3, $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174,
    $e49b69c1, $efbe4786, $0fc19dc6, $240ca1cc, $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da,
    $983e5152, $a831c66d, $b00327c8, $bf597fc7, $c6e00bf3, $d5a79147, $06ca6351, $14292967,
    $27b70a85, $2e1b2138, $4d2c6dfc, $53380d13, $650a7354, $766a0abb, $81c2c92e, $92722c85,
    $a2bfe8a1, $a81a664b, $c24b8b70, $c76c51a3, $d192e819, $d6990624, $f40e3585, $106aa070,
    $19a4c116, $1e376c08, $2748774c, $34b0bcb5, $391c0cb3, $4ed8aa4a, $5b9cca4f, $682e6ff3,
    $748f82ee, $78a5636f, $84c87814, $8cc70208, $90befffa, $a4506ceb, $bef9a3f7, $c67178f2
  );

// 辅助函数
function RightRotate(AValue: UInt32; AShift: Integer): UInt32; inline;
begin
  Result := (AValue shr AShift) or (AValue shl (32 - AShift));
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

{ TSHA256Context }

constructor TSHA256Context.Create;
begin
  inherited Create;
  Reset;
end;

function TSHA256Context.GetDigestSize: Integer;
begin
  Result := 32; // SHA-256 产生32字节摘要
end;

function TSHA256Context.GetBlockSize: Integer;
begin
  Result := 64; // SHA-256 块大小为64字节
end;

function TSHA256Context.GetName: string;
begin
  Result := 'SHA-256';
end;

procedure TSHA256Context.Reset;
begin
  // SHA-256 初始哈希值
  FState[0] := $6a09e667;
  FState[1] := $bb67ae85;
  FState[2] := $3c6ef372;
  FState[3] := $a54ff53a;
  FState[4] := $510e527f;
  FState[5] := $9b05688c;
  FState[6] := $1f83d9ab;
  FState[7] := $5be0cd19;
  
  FBitLength := 0;
  FBufferLength := 0;
  FFinalized := False;
  FillChar(FBuffer, SizeOf(FBuffer), 0);
end;

procedure TSHA256Context.Burn;
begin
  // 安全清零所有敏感数据
  FillChar(FState, SizeOf(FState), 0);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  FBitLength := 0;
  FBufferLength := 0;
  FFinalized := True; // 标记为已销毁，防止进一步使用
end;

procedure TSHA256Context.Update(const AData; ASize: Integer);
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

procedure TSHA256Context.ProcessBlock;
var
  LW: array[0..63] of UInt32;
  LA, LB, LC, LD, LE, LF, LG, LH: UInt32;
  LS0, LS1, LCh, LMaj, LTemp1, LTemp2: UInt32;
  LI: Integer;
begin
  {$RANGECHECKS OFF}
  {$OVERFLOWCHECKS OFF}
  // 准备消息调度数组
  for LI := 0 to 15 do
  begin
    // 安全地读取4个字节并组合成32位字
    LW[LI] := (UInt32(FBuffer[LI * 4]) shl 24) or
              (UInt32(FBuffer[LI * 4 + 1]) shl 16) or
              (UInt32(FBuffer[LI * 4 + 2]) shl 8) or
              UInt32(FBuffer[LI * 4 + 3]);
  end;

  for LI := 16 to 63 do
  begin
    LS0 := RightRotate(LW[LI-15], 7) xor RightRotate(LW[LI-15], 18) xor (LW[LI-15] shr 3);
    LS1 := RightRotate(LW[LI-2], 17) xor RightRotate(LW[LI-2], 19) xor (LW[LI-2] shr 10);
    LW[LI] := LW[LI-16] + LS0 + LW[LI-7] + LS1;
  end;

  // 初始化工作变量
  LA := FState[0]; LB := FState[1]; LC := FState[2]; LD := FState[3];
  LE := FState[4]; LF := FState[5]; LG := FState[6]; LH := FState[7];

  // 主循环
  for LI := 0 to 63 do
  begin
    LS1 := RightRotate(LE, 6) xor RightRotate(LE, 11) xor RightRotate(LE, 25);
    LCh := (LE and LF) xor ((not LE) and LG);
    LTemp1 := LH + LS1 + LCh + SHA256_K[LI] + LW[LI];
    LS0 := RightRotate(LA, 2) xor RightRotate(LA, 13) xor RightRotate(LA, 22);
    LMaj := (LA and LB) xor (LA and LC) xor (LB and LC);
    LTemp2 := LS0 + LMaj;

    LH := LG; LG := LF; LF := LE; LE := LD + LTemp1;
    LD := LC; LC := LB; LB := LA; LA := LTemp1 + LTemp2;
  end;

  // 添加到哈希值
  Inc(FState[0], LA); Inc(FState[1], LB); Inc(FState[2], LC); Inc(FState[3], LD);
  Inc(FState[4], LE); Inc(FState[5], LF); Inc(FState[6], LG); Inc(FState[7], LH);

  {$RANGECHECKS ON}
  {$OVERFLOWCHECKS ON}
end;



function TSHA256Context.Finalize: TBytes;
var
  LI: Integer;
begin
  Result := nil;
  if FFinalized then
    raise EInvalidOperation.Create('Hash context already finalized');

  // 严格按照DCPcrypt的模式实现
  FBuffer[FBufferLength] := $80;
  Inc(FBufferLength);

  if FBufferLength > 56 then
  begin
    // 填充剩余部分为零
    FillChar(FBuffer[FBufferLength], 64 - FBufferLength, 0);
    ProcessBlock;
    // 清空缓冲区，为长度字段准备新的块
    FillChar(FBuffer, 56, 0);
    FBufferLength := 0;
  end
  else
  begin
    // 填充到位置56之前
    FillChar(FBuffer[FBufferLength], 56 - FBufferLength, 0);
  end;

  // 添加长度（大端序）
  // 高32位
  FBuffer[56] := (FBitLength shr 56) and $FF;
  FBuffer[57] := (FBitLength shr 48) and $FF;
  FBuffer[58] := (FBitLength shr 40) and $FF;
  FBuffer[59] := (FBitLength shr 32) and $FF;
  // 低32位
  FBuffer[60] := (FBitLength shr 24) and $FF;
  FBuffer[61] := (FBitLength shr 16) and $FF;
  FBuffer[62] := (FBitLength shr 8) and $FF;
  FBuffer[63] := FBitLength and $FF;

  // 处理最后的块
  ProcessBlock;

  FFinalized := True;

  // 转换为字节数组（大端序）
  SetLength(Result, 32);
  for LI := 0 to 7 do
  begin
    Result[LI*4] := (FState[LI] shr 24) and $FF;
    Result[LI*4+1] := (FState[LI] shr 16) and $FF;
    Result[LI*4+2] := (FState[LI] shr 8) and $FF;
    Result[LI*4+3] := FState[LI] and $FF;
  end;
end;

// 工厂函数和便利函数
function CreateSHA256: IHashAlgorithm;
begin
  Result := TSHA256Context.Create;
end;

function SHA256Hash(const AData: TBytes): TBytes;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateSHA256;
  if Length(AData) > 0 then
    LHash.Update(AData[0], Length(AData));
  Result := LHash.Finalize;
  LHash.Burn;
end;

function SHA256Hash(const AData: string): TBytes;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateSHA256;
  if Length(AData) > 0 then
    LHash.Update(AData[1], Length(AData));
  Result := LHash.Finalize;
  LHash.Burn;
end;

end.
