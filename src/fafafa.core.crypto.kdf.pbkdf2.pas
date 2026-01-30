{
  fafafa.core.crypto.kdf.pbkdf2 - PBKDF2密钥派生函数实现

  本单元实现了PBKDF2 (Password-Based Key Derivation Function 2)：
  - 符合RFC 2898标准
  - 支持任意哈希算法作为底层PRF
  - 可配置迭代次数
  - 安全的密码派生

  实现特点：
  - 基于HMAC的伪随机函数
  - 防止彩虹表攻击
  - 可调节计算复杂度
  - 内存安全
}

unit fafafa.core.crypto.kdf.pbkdf2;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base,
  fafafa.core.crypto.interfaces;

type
  // 重新导出共享类型
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  IHMAC = fafafa.core.crypto.interfaces.IHMAC;
  IKeyDerivationFunction = fafafa.core.crypto.interfaces.IKeyDerivationFunction;
  ECrypto = fafafa.core.crypto.interfaces.ECrypto;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;

  // Function type for HMAC factory
  THMACFactory = function: IHMAC;

  {**
   * TPBKDF2Context
   *
   * @desc
   *   PBKDF2 key derivation function implementation.
   *   PBKDF2密钥派生函数实现.
   *}
  TPBKDF2Context = class(TInterfacedObject, IKeyDerivationFunction)
  private
    FHMACFactory: THMACFactory;     // HMAC工厂函数
    FHashAlgorithmName: string;     // 哈希算法名称

    function F(const APassword, ASalt: TBytes; AIterations, ABlockIndex: Integer): TBytes;
  public
    constructor Create(AHMACFactory: THMACFactory; const AHashAlgorithmName: string);

    // IKeyDerivationFunction implementation
    function GetName: string;
    function GetHashAlgorithmName: string;
    function GetMinIterations: Integer;
    function GetMaxKeyLength: Integer;
    function DeriveKey(const APassword: TBytes; const ASalt: TBytes;
      AIterations: Integer; AKeyLength: Integer): TBytes; overload;
    function DeriveKey(const APassword: string; const ASalt: TBytes;
      AIterations: Integer; AKeyLength: Integer): TBytes; overload;
    function DeriveKeyWithRandomSalt(const APassword: string;
      AIterations: Integer; AKeyLength: Integer; out ASalt: TBytes): TBytes;
    function VerifyPassword(const APassword: string; const ASalt: TBytes;
      AIterations: Integer; const ADerivedKey: TBytes): Boolean;
    procedure Burn;
  end;

{**
 * CreatePBKDF2_SHA256
 *
 * @desc
 *   Creates PBKDF2 with HMAC-SHA256.
 *   创建使用HMAC-SHA256的PBKDF2实例.
 *}
function CreatePBKDF2_SHA256: IKeyDerivationFunction;

{**
 * CreatePBKDF2_SHA512
 *
 * @desc
 *   Creates PBKDF2 with HMAC-SHA512.
 *   创建使用HMAC-SHA512的PBKDF2实例.
 *}
function CreatePBKDF2_SHA512: IKeyDerivationFunction;

{**
 * PBKDF2_SHA256
 *
 * @desc
 *   Convenience function for PBKDF2 with SHA-256.
 *   使用SHA-256的PBKDF2便利函数.
 *}
function PBKDF2_SHA256(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes;

{**
 * PBKDF2_SHA512
 *
 * @desc
 *   Convenience function for PBKDF2 with SHA-512.
 *   使用SHA-512的PBKDF2便利函数.
 *}
function PBKDF2_SHA512(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes;

implementation

uses
  fafafa.core.crypto.hmac,
  fafafa.core.crypto.random;

{ TPBKDF2Context }

constructor TPBKDF2Context.Create(AHMACFactory: THMACFactory; const AHashAlgorithmName: string);
begin
  inherited Create;
  if not Assigned(AHMACFactory) then
    raise EInvalidArgument.Create('HMAC factory function cannot be nil');
  if AHashAlgorithmName = '' then
    raise EInvalidArgument.Create('Hash algorithm name cannot be empty');

  FHMACFactory := AHMACFactory;
  FHashAlgorithmName := AHashAlgorithmName;
end;

function TPBKDF2Context.GetName: string;
begin
  Result := 'PBKDF2-' + FHashAlgorithmName;
end;

function TPBKDF2Context.GetHashAlgorithmName: string;
begin
  Result := FHashAlgorithmName;
end;

function TPBKDF2Context.GetMinIterations: Integer;
begin
  Result := 1000; // 最小推荐迭代次数
end;

function TPBKDF2Context.GetMaxKeyLength: Integer;
begin
  Result := $7FFFFFFF; // 理论上的最大长度
end;

function TPBKDF2Context.F(const APassword, ASalt: TBytes; AIterations, ABlockIndex: Integer): TBytes;
{$push}
{$hints off}

var
  LHMAC: IHMAC;
  LU, LPreviousU: TBytes;
  LSaltWithIndex: TBytes;
  LI, LJ: Integer;
begin
  // calm analyzers: init managed result
  Result := nil; SetLength(Result, 0);
  // 创建HMAC实例并设置密钥
  LHMAC := FHMACFactory();
  LHMAC.SetKey(APassword);

  // 准备盐值加上块索引（init managed local first for analyzers）
  SetLength(LSaltWithIndex, 0);
  SetLength(LSaltWithIndex, Length(ASalt) + 4);
  if Length(ASalt) > 0 then
    Move(ASalt[0], LSaltWithIndex[0], Length(ASalt));

  // 大端序添加块索引
  LSaltWithIndex[Length(ASalt)] := (ABlockIndex shr 24) and $FF;
  LSaltWithIndex[Length(ASalt) + 1] := (ABlockIndex shr 16) and $FF;
  LSaltWithIndex[Length(ASalt) + 2] := (ABlockIndex shr 8) and $FF;
  LSaltWithIndex[Length(ASalt) + 3] := ABlockIndex and $FF;

  // 第一次迭代：U1 = PRF(Password, Salt || INT(i))
  LU := LHMAC.ComputeMAC(LSaltWithIndex);
  SetLength(Result, Length(LU));
  Move(LU[0], Result[0], Length(LU));

  // 后续迭代：Ui = PRF(Password, Ui-1)
  for LI := 2 to AIterations do
  begin
    LPreviousU := Copy(LU);
    LU := LHMAC.ComputeMAC(LPreviousU);

    // XOR操作：T = U1 XOR U2 XOR ... XOR Uc
    for LJ := 0 to Length(Result) - 1 do
      Result[LJ] := Result[LJ] xor LU[LJ];

    // 清理前一个U
    if Length(LPreviousU) > 0 then
      FillChar(LPreviousU[0], Length(LPreviousU), 0);
  end;

  // 清理敏感数据
  if Length(LU) > 0 then
    FillChar(LU[0], Length(LU), 0);
  if Length(LSaltWithIndex) > 0 then
    FillChar(LSaltWithIndex[0], Length(LSaltWithIndex), 0);
  LHMAC.Burn;
end;
{$pop}


function TPBKDF2Context.DeriveKey(const APassword: TBytes; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes;
var
  LHMAC: IHMAC;
  LHashLength: Integer;
  LBlockCount: Integer;
  LI: Integer;
  LBlock: TBytes;
  LOffset: Integer;
  LCopyLength: Integer;
begin
  // initialize managed return for all code paths
  Result := nil; SetLength(Result, 0);
  if Length(APassword) = 0 then
    raise EInvalidArgument.Create('Password cannot be empty');
  if Length(ASalt) = 0 then
    raise EInvalidArgument.Create('Salt cannot be empty');
  if AIterations < GetMinIterations then
    raise EInvalidArgument.CreateFmt('Iterations must be at least %d', [GetMinIterations]);
  if AKeyLength <= 0 then
    raise EInvalidArgument.Create('Key length must be positive');
  if AKeyLength > GetMaxKeyLength then
    raise EInvalidArgument.CreateFmt('Key length cannot exceed %d', [GetMaxKeyLength]);

  // 获取哈希长度
  LHMAC := FHMACFactory();
  LHashLength := LHMAC.DigestSize;
  LHMAC.Burn;

  // 计算需要的块数
  LBlockCount := (AKeyLength + LHashLength - 1) div LHashLength;

  SetLength(Result, AKeyLength);

  // 生成每个块
  for LI := 1 to LBlockCount do
  begin
    LBlock := F(APassword, ASalt, AIterations, LI);

    // 复制到结果中
    LOffset := (LI - 1) * LHashLength;
    LCopyLength := LHashLength;
    if LOffset + LCopyLength > AKeyLength then
      LCopyLength := AKeyLength - LOffset;

    Move(LBlock[0], Result[LOffset], LCopyLength);

    // 清理块数据
    if Length(LBlock) > 0 then
      FillChar(LBlock[0], Length(LBlock), 0);
  end;
end;

function TPBKDF2Context.DeriveKey(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes;
var
  LPasswordBytes: TBytes;
  U: UTF8String;
begin
  Result := nil; SetLength(Result, 0);
  if Length(APassword) = 0 then
    raise EInvalidArgument.Create('Password cannot be empty');
  // 转换密码为 UTF-8 字节数组
  SetLength(LPasswordBytes, 0);
  U := UTF8String(APassword);
  if Length(U) > 0 then
  begin
    SetLength(LPasswordBytes, Length(U));
    Move(Pointer(U)^, LPasswordBytes[0], Length(U));
  end;
  try
    Result := DeriveKey(LPasswordBytes, ASalt, AIterations, AKeyLength);
  finally
    if Length(LPasswordBytes) > 0 then
      FillChar(LPasswordBytes[0], Length(LPasswordBytes), 0);
  end;
end;

function TPBKDF2Context.DeriveKeyWithRandomSalt(const APassword: string;
  AIterations: Integer; AKeyLength: Integer; out ASalt: TBytes): TBytes;
var
  LRandom: fafafa.core.crypto.random.ISecureRandom;
begin
  // 生成16字节随机盐值
  LRandom := fafafa.core.crypto.random.GetSecureRandom;
  ASalt := LRandom.GetBytes(16);

  Result := DeriveKey(APassword, ASalt, AIterations, AKeyLength);
end;

function TPBKDF2Context.VerifyPassword(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; const ADerivedKey: TBytes): Boolean;
var
  LComputedKey: TBytes;
  LI: Integer;
begin
  LComputedKey := DeriveKey(APassword, ASalt, AIterations, Length(ADerivedKey));

  // 常量时间比较防止时序攻击
  Result := Length(LComputedKey) = Length(ADerivedKey);
  if Result then
  begin
    for LI := 0 to Length(LComputedKey) - 1 do
      if LComputedKey[LI] <> ADerivedKey[LI] then
        Result := False;
  end;

  // 清理临时数据
  if Length(LComputedKey) > 0 then
    FillChar(LComputedKey[0], Length(LComputedKey), 0);
end;

procedure TPBKDF2Context.Burn;
begin
  // PBKDF2本身不存储敏感数据，只需要清理函数指针
  FHMACFactory := nil;
  FHashAlgorithmName := '';
end;

// 工厂函数
function CreatePBKDF2_SHA256: IKeyDerivationFunction;
begin
  Result := TPBKDF2Context.Create(@fafafa.core.crypto.hmac.CreateHMAC_SHA256, 'SHA-256');
end;

function CreatePBKDF2_SHA512: IKeyDerivationFunction;
begin
  Result := TPBKDF2Context.Create(@fafafa.core.crypto.hmac.CreateHMAC_SHA512, 'SHA-512');
end;

// 便利函数
function PBKDF2_SHA256(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes;
var
  LKDF: IKeyDerivationFunction;
begin
  LKDF := CreatePBKDF2_SHA256;
  Result := LKDF.DeriveKey(APassword, ASalt, AIterations, AKeyLength);
  LKDF.Burn;
end;

function PBKDF2_SHA512(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes;
var
  LKDF: IKeyDerivationFunction;
begin
  LKDF := CreatePBKDF2_SHA512;
  Result := LKDF.DeriveKey(APassword, ASalt, AIterations, AKeyLength);
  LKDF.Burn;
end;

end.
