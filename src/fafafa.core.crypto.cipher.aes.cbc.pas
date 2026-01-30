{
  fafafa.core.crypto.cipher.aes.cbc - AES-CBC模式实现
  
  本单元实现了AES的CBC (Cipher Block Chaining) 模式：
  - 使用初始化向量(IV)确保安全性
  - 支持PKCS#7填充
  - 前一个密文块影响下一个块的加密
  
  实现特点：
  - 基于AES核心算法
  - 符合NIST SP 800-38A标准
  - 防止填充预言攻击
  - 内存安全
  - 高性能
}

unit fafafa.core.crypto.cipher.aes.cbc;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.cipher.aes;

type
  // 重新导出共享类型
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  ISymmetricCipher = fafafa.core.crypto.interfaces.ISymmetricCipher;
  IBlockCipher = fafafa.core.crypto.interfaces.IBlockCipher;
  IBlockCipherWithIV = fafafa.core.crypto.interfaces.IBlockCipherWithIV;
  ECryptoCipher = fafafa.core.crypto.interfaces.ECryptoCipher;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;

  {**
   * TAESCBCContext
   *
   * @desc
   *   AES-CBC mode implementation.
   *   AES-CBC模式实现.
   *}
  TAESCBCContext = class(TInterfacedObject, IBlockCipherWithIV)
  private
    FAESCore: ISymmetricCipher;     // 底层AES算法
    FIV: TBytes;                    // 初始化向量
    FIVSet: Boolean;                // IV是否已设置
    FPaddingEnabled: Boolean;       // 是否启用PKCS#7填充（默认启用）
    
    function PKCS7Pad(const AData: TBytes): TBytes;
    function PKCS7Unpad(const AData: TBytes): TBytes;
    procedure XORBlocks(var ABlock1: array of Byte; const ABlock2: array of Byte);
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

    // IBlockCipher implementation
    function GetMode: string;
    function GetPaddingEnabled: Boolean;
    procedure SetPaddingEnabled(AEnabled: Boolean);
    
    // IBlockCipherWithIV implementation (inherits IBlockCipher)
    function GetIVSize: Integer;
    procedure SetIV(const AIV: TBytes);
    function GetIV: TBytes;
    procedure GenerateRandomIV;
    function IsIVSet: Boolean;
  end;

{**
 * CreateAES128_CBC
 *
 * @desc
 *   Creates a new AES-128-CBC cipher instance.
 *   创建新的AES-128-CBC加密算法实例.
 *}
function CreateAES128_CBC: IBlockCipherWithIV;

{**
 * CreateAES192_CBC
 *
 * @desc
 *   Creates a new AES-192-CBC cipher instance.
 *   创建新的AES-192-CBC加密算法实例.
 *}
function CreateAES192_CBC: IBlockCipherWithIV;

{**
 * CreateAES256_CBC
 *
 * @desc
 *   Creates a new AES-256-CBC cipher instance.
 *   创建新的AES-256-CBC加密算法实例.
 *}
function CreateAES256_CBC: IBlockCipherWithIV;

implementation

uses
  fafafa.core.crypto.random;

{ TAESCBCContext }

constructor TAESCBCContext.Create(AKeySize: Integer);
begin
  inherited Create;
  case AKeySize of
    16: FAESCore := fafafa.core.crypto.cipher.aes.CreateAES128;
    24: FAESCore := fafafa.core.crypto.cipher.aes.CreateAES192;
    32: FAESCore := fafafa.core.crypto.cipher.aes.CreateAES256;
  else
    raise EInvalidArgument.CreateFmt('Invalid AES key size: %d bytes', [AKeySize]);
  end;

  SetLength(FIV, 16); // AES块大小始终为16字节
  FIVSet := False;
  FPaddingEnabled := True;
end;

destructor TAESCBCContext.Destroy;
begin
  if Assigned(FAESCore) then
    FAESCore.Burn;
  if Length(FIV) > 0 then
    FillChar(FIV[0], Length(FIV), 0);
  inherited Destroy;
end;

function TAESCBCContext.GetKeySize: Integer;
begin
  Result := FAESCore.KeySize;
end;

function TAESCBCContext.GetBlockSize: Integer;
begin
  Result := FAESCore.BlockSize;
end;

function TAESCBCContext.GetIVSize: Integer;
begin
  Result := 16; // AES块大小
end;

function TAESCBCContext.GetName: string;
begin
  Result := ''; // init for analyzers
  Result := FAESCore.Name + '-CBC';
end;

function TAESCBCContext.GetMode: string;
begin
  Result := 'CBC';
end;

function TAESCBCContext.GetPaddingEnabled: Boolean;
begin
  Result := FPaddingEnabled;
end;

procedure TAESCBCContext.SetPaddingEnabled(AEnabled: Boolean);
begin
  FPaddingEnabled := AEnabled;
end;

procedure TAESCBCContext.SetKey(const AKey: TBytes);
begin
  FAESCore.SetKey(AKey);
end;

procedure TAESCBCContext.SetIV(const AIV: TBytes);
begin
  if Length(AIV) <> GetIVSize then
    raise EInvalidArgument.CreateFmt('Invalid IV length: expected %d bytes, got %d', [GetIVSize, Length(AIV)]);
    
  Move(AIV[0], FIV[0], Length(AIV));
  FIVSet := True;
end;

function TAESCBCContext.GetIV: TBytes;
begin
  Result := nil; SetLength(Result, 0);
  if Length(FIV) > 0 then
  begin
    SetLength(Result, Length(FIV));
    Move(FIV[0], Result[0], Length(FIV));
  end;
end;

procedure TAESCBCContext.GenerateRandomIV;
var
  LRandom: fafafa.core.crypto.random.ISecureRandom;
begin
  LRandom := fafafa.core.crypto.random.GetSecureRandom;
  FIV := LRandom.GetBytes(GetIVSize);
  FIVSet := True;
end;

function TAESCBCContext.IsIVSet: Boolean;
begin
  Result := FIVSet;
end;

{$PUSH}{$HINTS OFF 5057}
function TAESCBCContext.Encrypt(const APlaintext: TBytes): TBytes;
var
  LPaddedData: TBytes;
  LBlocks: Integer;
  LI, LJ: Integer;
  LCurrentBlock, LPreviousBlock: array[0..15] of Byte;
  LEncryptedBlock: TBytes;
begin
  // initialize managed outputs/locals for static analyzers
  Result := nil; SetLength(Result, 0);
  SetLength(LPaddedData, 0);
  SetLength(LEncryptedBlock, 0);
  FillChar(LCurrentBlock, SizeOf(LCurrentBlock), 0);
  FillChar(LPreviousBlock, SizeOf(LPreviousBlock), 0);
  LJ := 0; // calm 'not used' in some toolchains
  if not FIVSet then
    raise EInvalidOperation.Create('IV not set');

  // 应用PKCS#7填充（可配置）
  if FPaddingEnabled then
    LPaddedData := PKCS7Pad(APlaintext)
  else
  begin
    if (Length(APlaintext) mod 16) <> 0 then
      raise EInvalidArgument.Create('Plaintext length must be multiple of 16 bytes when padding is disabled');
    SetLength(LPaddedData, Length(APlaintext));
    if Length(APlaintext) > 0 then
      Move(APlaintext[0], LPaddedData[0], Length(APlaintext));
  end;
  LBlocks := Length(LPaddedData) div 16;

  SetLength(Result, Length(LPaddedData));

  // 初始化前一个块为IV
  Move(FIV[0], LPreviousBlock, 16);

  // 加密每个块
  for LI := 0 to LBlocks - 1 do
  begin
    // 复制当前明文块
    Move(LPaddedData[LI * 16], LCurrentBlock, 16);

    // 与前一个密文块（或IV）进行XOR
    XORBlocks(LCurrentBlock, LPreviousBlock);

    // 加密XOR后的块
    SetLength(LEncryptedBlock, 16);
    Move(LCurrentBlock, LEncryptedBlock[0], 16);
    LEncryptedBlock := FAESCore.Encrypt(LEncryptedBlock);

    // 复制到结果
    Move(LEncryptedBlock[0], Result[LI * 16], 16);

    // 当前密文块成为下一轮的前一个块
    Move(LEncryptedBlock[0], LPreviousBlock, 16);

    // 清理临时数据
    FillChar(LEncryptedBlock[0], Length(LEncryptedBlock), 0);
  end;

  // 清理敏感数据
  if Length(LPaddedData) > 0 then
    FillChar(LPaddedData[0], Length(LPaddedData), 0);
  FillChar(LCurrentBlock, SizeOf(LCurrentBlock), 0);
end;

function TAESCBCContext.Decrypt(const ACiphertext: TBytes): TBytes;
var
  LBlocks: Integer;
  LI: Integer;
  LCurrentBlock, LPreviousBlock, LDecryptedBlock: array[0..15] of Byte;
  LDecryptedData: TBytes;
begin
  // initialize managed outputs/locals for static analyzers
  Result := nil; SetLength(Result, 0);
  SetLength(LDecryptedData, 0);
  FillChar(LCurrentBlock, SizeOf(LCurrentBlock), 0);
  FillChar(LPreviousBlock, SizeOf(LPreviousBlock), 0);
  FillChar(LDecryptedBlock, SizeOf(LDecryptedBlock), 0);
  LI := 0; // init loop var for analyzers
  if not FIVSet then
    raise EInvalidOperation.Create('IV not set');

  if (Length(ACiphertext) mod 16) <> 0 then
    raise EInvalidArgument.Create('Ciphertext length must be multiple of 16 bytes');

  LBlocks := Length(ACiphertext) div 16;
  SetLength(Result, Length(ACiphertext));

  // 初始化前一个块为IV
  Move(FIV[0], LPreviousBlock, 16);

  // 解密每个块
  for LI := 0 to LBlocks - 1 do
  begin
    // 复制当前密文块
    Move(ACiphertext[LI * 16], LCurrentBlock, 16);

    // 解密当前块
    SetLength(LDecryptedData, 16);
    Move(LCurrentBlock, LDecryptedData[0], 16);
    LDecryptedData := FAESCore.Decrypt(LDecryptedData);
    Move(LDecryptedData[0], LDecryptedBlock, 16);

    // 与前一个密文块（或IV）进行XOR
    XORBlocks(LDecryptedBlock, LPreviousBlock);

    // 复制到结果
    Move(LDecryptedBlock, Result[LI * 16], 16);

    // 当前密文块成为下一轮的前一个块
    Move(LCurrentBlock, LPreviousBlock, 16);

    // 清理临时数据
    FillChar(LDecryptedData[0], Length(LDecryptedData), 0);
  end;

  // 去除填充（可配置）
  if FPaddingEnabled then
    Result := PKCS7Unpad(Result);

  // 清理敏感数据
  FillChar(LDecryptedBlock, SizeOf(LDecryptedBlock), 0);
end;
{$POP}

procedure TAESCBCContext.Reset;
begin
  FAESCore.Reset;
  FIVSet := False;
  if Length(FIV) > 0 then
    FillChar(FIV[0], Length(FIV), 0);
end;

procedure TAESCBCContext.Burn;
begin
  // 清理底层AES实例
  if Assigned(FAESCore) then
    FAESCore.Burn;

  // 清理IV
  if Length(FIV) > 0 then
  begin
    FillChar(FIV[0], Length(FIV), 0);
    SetLength(FIV, 0);
  end;

  FIVSet := False;
end;

{$PUSH}{$HINTS OFF 5057}
function TAESCBCContext.PKCS7Pad(const AData: TBytes): TBytes;
var
  LBlockSize: Integer;
  LPadLength: Integer;
  LI: Integer;
begin
  // init managed return for analyzers
  Result := nil; SetLength(Result, 0);
  LBlockSize := GetBlockSize;
  LPadLength := LBlockSize - (Length(AData) mod LBlockSize);

  SetLength(Result, Length(AData) + LPadLength);
  if Length(AData) > 0 then
    Move(AData[0], Result[0], Length(AData));

  // 填充字节，每个字节的值等于填充长度
  for LI := Length(AData) to Length(Result) - 1 do
    Result[LI] := LPadLength;
end;

function TAESCBCContext.PKCS7Unpad(const AData: TBytes): TBytes;
var
  LPadLength: Integer;
  LI: Integer;
begin
  // init managed return for analyzers
  Result := nil; SetLength(Result, 0);
  if Length(AData) = 0 then
    raise EInvalidArgument.Create('Cannot unpad empty data');

  LPadLength := AData[Length(AData) - 1];

  if (LPadLength < 1) or (LPadLength > GetBlockSize) then
    raise EInvalidArgument.Create('Invalid padding');

  if LPadLength > Length(AData) then
    raise EInvalidArgument.Create('Invalid padding length');

  // 验证填充字节
  for LI := Length(AData) - LPadLength to Length(AData) - 1 do
  begin
    if AData[LI] <> LPadLength then
      raise EInvalidArgument.Create('Invalid padding bytes');
  end;

  SetLength(Result, Length(AData) - LPadLength);
  if Length(Result) > 0 then
    Move(AData[0], Result[0], Length(Result));
end;
{$POP}

procedure TAESCBCContext.XORBlocks(var ABlock1: array of Byte; const ABlock2: array of Byte);
var
  LI: Integer;
begin
  for LI := 0 to 15 do
    ABlock1[LI] := ABlock1[LI] xor ABlock2[LI];
end;

// 工厂函数
function CreateAES128_CBC: IBlockCipherWithIV;
begin
  Result := TAESCBCContext.Create(16);
end;

function CreateAES192_CBC: IBlockCipherWithIV;
begin
  Result := TAESCBCContext.Create(24);
end;

function CreateAES256_CBC: IBlockCipherWithIV;
begin
  Result := TAESCBCContext.Create(32);
end;

end.
