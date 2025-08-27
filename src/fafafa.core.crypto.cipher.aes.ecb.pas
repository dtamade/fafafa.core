{
  fafafa.core.crypto.cipher.aes.ecb - AES-ECB模式实现
  
  本单元实现了AES的ECB (Electronic Codebook) 模式：
  - 最简单的块加密模式
  - 每个块独立加密
  - 不需要初始化向量(IV)
  
  注意：ECB模式不安全，相同的明文块会产生相同的密文块
  仅用于特殊场景或作为其他模式的基础
  
  实现特点：
  - 基于AES核心算法
  - 支持PKCS#7填充
  - 内存安全
  - 高性能
}

unit fafafa.core.crypto.cipher.aes.ecb;

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
  ECryptoCipher = fafafa.core.crypto.interfaces.ECryptoCipher;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;

  {**
   * TAESECBContext
   *
   * @desc
   *   AES-ECB mode implementation.
   *   AES-ECB模式实现.
   *}
  TAESECBContext = class(TInterfacedObject, IBlockCipher)
  private
    FAESCore: ISymmetricCipher;     // 底层AES算法
    FPaddingEnabled: Boolean;       // 是否启用填充
    
    function PKCS7Pad(const AData: TBytes): TBytes;
    function PKCS7Unpad(const AData: TBytes): TBytes;
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
  end;

{**
 * CreateAES128_ECB
 *
 * @desc
 *   Creates a new AES-128-ECB cipher instance.
 *   创建新的AES-128-ECB加密算法实例.
 *}
function CreateAES128_ECB: IBlockCipher;

{**
 * CreateAES192_ECB
 *
 * @desc
 *   Creates a new AES-192-ECB cipher instance.
 *   创建新的AES-192-ECB加密算法实例.
 *}
function CreateAES192_ECB: IBlockCipher;

{**
 * CreateAES256_ECB
 *
 * @desc
 *   Creates a new AES-256-ECB cipher instance.
 *   创建新的AES-256-ECB加密算法实例.
 *}
function CreateAES256_ECB: IBlockCipher;

implementation

{ TAESECBContext }

constructor TAESECBContext.Create(AKeySize: Integer);
begin
  inherited Create;
  case AKeySize of
    16: FAESCore := fafafa.core.crypto.cipher.aes.CreateAES128;
    24: FAESCore := fafafa.core.crypto.cipher.aes.CreateAES192;
    32: FAESCore := fafafa.core.crypto.cipher.aes.CreateAES256;
  else
    raise EInvalidArgument.CreateFmt('Invalid AES key size: %d bytes', [AKeySize]);
  end;
  
  FPaddingEnabled := True; // 默认启用PKCS#7填充
end;

destructor TAESECBContext.Destroy;
begin
  if Assigned(FAESCore) then
    FAESCore.Burn;
  inherited Destroy;
end;

function TAESECBContext.GetKeySize: Integer;
begin
  Result := FAESCore.KeySize;
end;

function TAESECBContext.GetBlockSize: Integer;
begin
  Result := FAESCore.BlockSize;
end;

function TAESECBContext.GetName: string;
begin
  Result := FAESCore.Name + '-ECB';
end;

function TAESECBContext.GetMode: string;
begin
  Result := 'ECB';
end;

function TAESECBContext.GetPaddingEnabled: Boolean;
begin
  Result := FPaddingEnabled;
end;

procedure TAESECBContext.SetPaddingEnabled(AEnabled: Boolean);
begin
  FPaddingEnabled := AEnabled;
end;

procedure TAESECBContext.SetKey(const AKey: TBytes);
begin
  FAESCore.SetKey(AKey);
end;

function TAESECBContext.Encrypt(const APlaintext: TBytes): TBytes;
var
  LPaddedData: TBytes;
begin
  if FPaddingEnabled then
    LPaddedData := PKCS7Pad(APlaintext)
  else
  begin
    if (Length(APlaintext) mod GetBlockSize) <> 0 then
      raise EInvalidArgument.Create('Plaintext length must be multiple of block size when padding is disabled');
    LPaddedData := Copy(APlaintext);
  end;
  
  // ECB模式：直接使用底层AES加密
  Result := FAESCore.Encrypt(LPaddedData);
  
  // 清理临时数据
  if Length(LPaddedData) > 0 then
    FillChar(LPaddedData[0], Length(LPaddedData), 0);
end;

function TAESECBContext.Decrypt(const ACiphertext: TBytes): TBytes;
begin
  if (Length(ACiphertext) mod GetBlockSize) <> 0 then
    raise EInvalidArgument.Create('Ciphertext length must be multiple of block size');
  
  // ECB模式：直接使用底层AES解密
  Result := FAESCore.Decrypt(ACiphertext);
  
  // 如果启用了填充，去除填充
  if FPaddingEnabled then
    Result := PKCS7Unpad(Result);
end;

procedure TAESECBContext.Reset;
begin
  FAESCore.Reset;
end;

procedure TAESECBContext.Burn;
begin
  if Assigned(FAESCore) then
    FAESCore.Burn;
  FPaddingEnabled := True;
end;

function TAESECBContext.PKCS7Pad(const AData: TBytes): TBytes;
var
  LBlockSize: Integer;
  LPadLength: Integer;
  LI: Integer;
begin
  LBlockSize := GetBlockSize;
  LPadLength := LBlockSize - (Length(AData) mod LBlockSize);
  
  SetLength(Result, Length(AData) + LPadLength);
  if Length(AData) > 0 then
    Move(AData[0], Result[0], Length(AData));
  
  // 填充字节，每个字节的值等于填充长度
  for LI := Length(AData) to Length(Result) - 1 do
    Result[LI] := LPadLength;
end;

function TAESECBContext.PKCS7Unpad(const AData: TBytes): TBytes;
var
  LPadLength: Integer;
  LI: Integer;
begin
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

// 工厂函数
function CreateAES128_ECB: IBlockCipher;
begin
  Result := TAESECBContext.Create(16);
end;

function CreateAES192_ECB: IBlockCipher;
begin
  Result := TAESECBContext.Create(24);
end;

function CreateAES256_ECB: IBlockCipher;
begin
  Result := TAESECBContext.Create(32);
end;

end.
