{
  fafafa.core.crypto.hash.sha512 - SHA-512哈希算法实现
  
  本单元实现了SHA-512安全哈希算法：
  - 符合FIPS PUB 180-4标准
  - 512位输出长度
  - 1024位块大小
  - 纯Pascal实现，无外部依赖
  
  实现特点：
  - 高性能优化
  - 内存安全
  - 跨平台兼容
  - 支持流式处理
}

unit fafafa.core.crypto.hash.sha512;

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
   * TSHA512Context
   *
   * @desc
   *   SHA-512 hash algorithm implementation.
   *   SHA-512哈希算法实现.
   *}
  TSHA512Context = class(TInterfacedObject, IHashAlgorithm)
  private
    FState: array[0..7] of UInt64;      // 哈希状态
    FBuffer: array[0..127] of UInt8;    // 输入缓冲区
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
 * CreateSHA512
 *
 * @desc
 *   Creates a new SHA-512 hash algorithm instance.
 *   创建新的SHA-512哈希算法实例.
 *}
function CreateSHA512: IHashAlgorithm;

{**
 * SHA512Hash
 *
 * @desc
 *   Computes SHA-512 hash of data in one call.
 *   一次性计算数据的SHA-512哈希.
 *}
function SHA512Hash(const AData: TBytes): TBytes; overload;
function SHA512Hash(const AData: string): TBytes; overload;

implementation

// SHA-512常量
{$PUSH}
{$R-} // 禁用范围检查以避免常量溢出错误
const
  SHA512_K: array[0..79] of UInt64 = (
    UInt64($428a2f98d728ae22), UInt64($7137449123ef65cd), UInt64($b5c0fbcfec4d3b2f), UInt64($e9b5dba58189dbbc),
    UInt64($3956c25bf348b538), UInt64($59f111f1b605d019), UInt64($923f82a4af194f9b), UInt64($ab1c5ed5da6d8118),
    UInt64($d807aa98a3030242), UInt64($12835b0145706fbe), UInt64($243185be4ee4b28c), UInt64($550c7dc3d5ffb4e2),
    UInt64($72be5d74f27b896f), UInt64($80deb1fe3b1696b1), UInt64($9bdc06a725c71235), UInt64($c19bf174cf692694),
    UInt64($e49b69c19ef14ad2), UInt64($efbe4786384f25e3), UInt64($0fc19dc68b8cd5b5), UInt64($240ca1cc77ac9c65),
    UInt64($2de92c6f592b0275), UInt64($4a7484aa6ea6e483), UInt64($5cb0a9dcbd41fbd4), UInt64($76f988da831153b5),
    UInt64($983e5152ee66dfab), UInt64($a831c66d2db43210), UInt64($b00327c898fb213f), UInt64($bf597fc7beef0ee4),
    UInt64($c6e00bf33da88fc2), UInt64($d5a79147930aa725), UInt64($06ca6351e003826f), UInt64($142929670a0e6e70),
    UInt64($27b70a8546d22ffc), UInt64($2e1b21385c26c926), UInt64($4d2c6dfc5ac42aed), UInt64($53380d139d95b3df),
    UInt64($650a73548baf63de), UInt64($766a0abb3c77b2a8), UInt64($81c2c92e47edaee6), UInt64($92722c851482353b),
    UInt64($a2bfe8a14cf10364), UInt64($a81a664bbc423001), UInt64($c24b8b70d0f89791), UInt64($c76c51a30654be30),
    UInt64($d192e819d6ef5218), UInt64($d69906245565a910), UInt64($f40e35855771202a), UInt64($106aa07032bbd1b8),
    UInt64($19a4c116b8d2d0c8), UInt64($1e376c085141ab53), UInt64($2748774cdf8eeb99), UInt64($34b0bcb5e19b48a8),
    UInt64($391c0cb3c5c95a63), UInt64($4ed8aa4ae3418acb), UInt64($5b9cca4f7763e373), UInt64($682e6ff3d6b2b8a3),
    UInt64($748f82ee5defb2fc), UInt64($78a5636f43172f60), UInt64($84c87814a1f0ab72), UInt64($8cc702081a6439ec),
    UInt64($90befffa23631e28), UInt64($a4506cebde82bde9), UInt64($bef9a3f7b2c67915), UInt64($c67178f2e372532b),
    UInt64($ca273eceea26619c), UInt64($d186b8c721c0c207), UInt64($eada7dd6cde0eb1e), UInt64($f57d4f7fee6ed178),
    UInt64($06f067aa72176fba), UInt64($0a637dc5a2c898a6), UInt64($113f9804bef90dae), UInt64($1b710b35131c471b),
    UInt64($28db77f523047d84), UInt64($32caab7b40c72493), UInt64($3c9ebe0a15c9bebc), UInt64($431d67c49c100d4c),
    UInt64($4cc5d4becb3e42b6), UInt64($597f299cfc657e2a), UInt64($5fcb6fab3ad6faec), UInt64($6c44198c4a475817)
  );
{$POP}

// 辅助函数
function RightRotate64(AValue: UInt64; AShift: Integer): UInt64; inline;
begin
  Result := (AValue shr AShift) or (AValue shl (64 - AShift));
end;

function BigEndianToHost64(AValue: UInt64): UInt64; inline;
begin
  {$IFDEF ENDIAN_LITTLE}
  Result := ((AValue and $FF) shl 56) or
            (((AValue shr 8) and $FF) shl 48) or
            (((AValue shr 16) and $FF) shl 40) or
            (((AValue shr 24) and $FF) shl 32) or
            (((AValue shr 32) and $FF) shl 24) or
            (((AValue shr 40) and $FF) shl 16) or
            (((AValue shr 48) and $FF) shl 8) or
            ((AValue shr 56) and $FF);
  {$ELSE}
  Result := AValue;
  {$ENDIF}
end;

function HostToBigEndian64(AValue: UInt64): UInt64; inline;
begin
  {$IFDEF ENDIAN_LITTLE}
  Result := ((AValue and $FF) shl 56) or
            (((AValue shr 8) and $FF) shl 48) or
            (((AValue shr 16) and $FF) shl 40) or
            (((AValue shr 24) and $FF) shl 32) or
            (((AValue shr 32) and $FF) shl 24) or
            (((AValue shr 40) and $FF) shl 16) or
            (((AValue shr 48) and $FF) shl 8) or
            ((AValue shr 56) and $FF);
  {$ELSE}
  Result := AValue;
  {$ENDIF}
end;

{ TSHA512Context }

constructor TSHA512Context.Create;
begin
  inherited Create;
  Reset;
end;

function TSHA512Context.GetDigestSize: Integer;
begin
  Result := 64; // SHA-512 产生64字节摘要
end;

function TSHA512Context.GetBlockSize: Integer;
begin
  Result := 128; // SHA-512 块大小为128字节
end;

function TSHA512Context.GetName: string;
begin
  Result := 'SHA-512';
end;

procedure TSHA512Context.Reset;
begin
  // SHA-512 初始哈希值
  {$PUSH}
  {$R-} // 禁用范围检查
  FState[0] := UInt64($6a09e667f3bcc908);
  FState[1] := UInt64($bb67ae8584caa73b);
  FState[2] := UInt64($3c6ef372fe94f82b);
  FState[3] := UInt64($a54ff53a5f1d36f1);
  FState[4] := UInt64($510e527fade682d1);
  FState[5] := UInt64($9b05688c2b3e6c1f);
  FState[6] := UInt64($1f83d9abfb41bd6b);
  FState[7] := UInt64($5be0cd19137e2179);
  {$POP}
  
  FBitLength := 0;
  FBufferLength := 0;
  FFinalized := False;
  FillChar(FBuffer, SizeOf(FBuffer), 0);
end;

procedure TSHA512Context.Burn;
begin
  // 安全清零所有敏感数据
  FillChar(FState, SizeOf(FState), 0);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  FBitLength := 0;
  FBufferLength := 0;
  FFinalized := True;
end;

procedure TSHA512Context.Update(const AData; ASize: Integer);
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
    if (128 - FBufferLength) <= LRemaining then
    begin
      // 填满缓冲区并处理
      if FBufferLength < 128 then
        Move(LData^, FBuffer[FBufferLength], 128 - FBufferLength);
      Dec(LRemaining, 128 - FBufferLength);
      Inc(LData, 128 - FBufferLength);
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

procedure TSHA512Context.ProcessBlock;
var
  LW: array[0..79] of UInt64;
  LA, LB, LC, LD, LE, LF, LG, LH: UInt64;
  LS0, LS1, LCh, LMaj, LTemp1, LTemp2: UInt64;
  LI: Integer;
begin
  // 准备消息调度数组 - 安全地读取8个字节并组合成64位字
  for LI := 0 to 15 do
  begin
    LW[LI] := (UInt64(FBuffer[LI * 8]) shl 56) or
              (UInt64(FBuffer[LI * 8 + 1]) shl 48) or
              (UInt64(FBuffer[LI * 8 + 2]) shl 40) or
              (UInt64(FBuffer[LI * 8 + 3]) shl 32) or
              (UInt64(FBuffer[LI * 8 + 4]) shl 24) or
              (UInt64(FBuffer[LI * 8 + 5]) shl 16) or
              (UInt64(FBuffer[LI * 8 + 6]) shl 8) or
              UInt64(FBuffer[LI * 8 + 7]);
  end;

  for LI := 16 to 79 do
  begin
    LS0 := RightRotate64(LW[LI-15], 1) xor RightRotate64(LW[LI-15], 8) xor (LW[LI-15] shr 7);
    LS1 := RightRotate64(LW[LI-2], 19) xor RightRotate64(LW[LI-2], 61) xor (LW[LI-2] shr 6);
    {$OVERFLOWCHECKS OFF}
    LW[LI] := LW[LI-16] + LS0 + LW[LI-7] + LS1;
    {$OVERFLOWCHECKS ON}
  end;

  // 初始化工作变量
  LA := FState[0]; LB := FState[1]; LC := FState[2]; LD := FState[3];
  LE := FState[4]; LF := FState[5]; LG := FState[6]; LH := FState[7];

  // 主循环
  for LI := 0 to 79 do
  begin
    LS1 := RightRotate64(LE, 14) xor RightRotate64(LE, 18) xor RightRotate64(LE, 41);
    LCh := (LE and LF) xor ((not LE) and LG);
    {$OVERFLOWCHECKS OFF}
    LTemp1 := LH + LS1 + LCh + SHA512_K[LI] + LW[LI];
    {$OVERFLOWCHECKS ON}
    LS0 := RightRotate64(LA, 28) xor RightRotate64(LA, 34) xor RightRotate64(LA, 39);
    LMaj := (LA and LB) xor (LA and LC) xor (LB and LC);
    {$OVERFLOWCHECKS OFF}
    LTemp2 := LS0 + LMaj;

    LH := LG; LG := LF; LF := LE; LE := LD + LTemp1;
    LD := LC; LC := LB; LB := LA; LA := LTemp1 + LTemp2;
    {$OVERFLOWCHECKS ON}
  end;

  // 添加到哈希值
  {$OVERFLOWCHECKS OFF}
  Inc(FState[0], LA); Inc(FState[1], LB); Inc(FState[2], LC); Inc(FState[3], LD);
  Inc(FState[4], LE); Inc(FState[5], LF); Inc(FState[6], LG); Inc(FState[7], LH);
  {$OVERFLOWCHECKS ON}
end;



function TSHA512Context.Finalize: TBytes;
var
  LI: Integer;
begin
  Result := nil;
  if FFinalized then
    raise EInvalidOperation.Create('Hash context already finalized');

  // 严格按照DCPcrypt的模式实现
  FBuffer[FBufferLength] := $80;
  Inc(FBufferLength);

  if FBufferLength > 112 then
  begin
    // 填充剩余部分为零
    FillChar(FBuffer[FBufferLength], 128 - FBufferLength, 0);
    ProcessBlock;
    // 清空缓冲区，为长度字段准备新的块
    FillChar(FBuffer, 112, 0);
    FBufferLength := 0;
  end
  else
  begin
    // 填充到位置112之前
    FillChar(FBuffer[FBufferLength], 112 - FBufferLength, 0);
  end;

  // 添加长度（大端序，128位）
  // SHA-512使用128位长度字段，但我们只使用低64位
  // 高64位为0
  FBuffer[112] := 0; FBuffer[113] := 0; FBuffer[114] := 0; FBuffer[115] := 0;
  FBuffer[116] := 0; FBuffer[117] := 0; FBuffer[118] := 0; FBuffer[119] := 0;
  // 低64位
  FBuffer[120] := (FBitLength shr 56) and $FF;
  FBuffer[121] := (FBitLength shr 48) and $FF;
  FBuffer[122] := (FBitLength shr 40) and $FF;
  FBuffer[123] := (FBitLength shr 32) and $FF;
  FBuffer[124] := (FBitLength shr 24) and $FF;
  FBuffer[125] := (FBitLength shr 16) and $FF;
  FBuffer[126] := (FBitLength shr 8) and $FF;
  FBuffer[127] := FBitLength and $FF;

  // 处理最后的块
  ProcessBlock;

  FFinalized := True;

  // 转换为字节数组（大端序）
  SetLength(Result, 64);
  for LI := 0 to 7 do
  begin
    Result[LI*8] := (FState[LI] shr 56) and $FF;
    Result[LI*8+1] := (FState[LI] shr 48) and $FF;
    Result[LI*8+2] := (FState[LI] shr 40) and $FF;
    Result[LI*8+3] := (FState[LI] shr 32) and $FF;
    Result[LI*8+4] := (FState[LI] shr 24) and $FF;
    Result[LI*8+5] := (FState[LI] shr 16) and $FF;
    Result[LI*8+6] := (FState[LI] shr 8) and $FF;
    Result[LI*8+7] := FState[LI] and $FF;
  end;
end;

// 工厂函数和便利函数
function CreateSHA512: IHashAlgorithm;
begin
  Result := TSHA512Context.Create;
end;

function SHA512Hash(const AData: TBytes): TBytes;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateSHA512;
  if Length(AData) > 0 then
    LHash.Update(AData[0], Length(AData));
  Result := LHash.Finalize;
  LHash.Burn;
end;

function SHA512Hash(const AData: string): TBytes;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateSHA512;
  if Length(AData) > 0 then
    LHash.Update(AData[1], Length(AData));
  Result := LHash.Finalize;
  LHash.Burn;
end;

end.
