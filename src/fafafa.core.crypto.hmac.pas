{
  fafafa.core.crypto.hmac - HMAC消息认证码实现

  本单元实现了HMAC (Hash-based Message Authentication Code) 算法：
  - HMAC-SHA256: 基于SHA-256的消息认证码
  - HMAC-SHA512: 基于SHA-512的消息认证码

  实现特点：
  - 符合RFC 2104标准
  - 支持任意长度的密钥和消息
  - 常量时间实现，防止时间攻击
  - 高性能优化
}

unit fafafa.core.crypto.hmac;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  Math,
  fafafa.core.base,
  fafafa.core.crypto.interfaces;

type
  // 重新导出共享类型
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  IHashAlgorithm = fafafa.core.crypto.interfaces.IHashAlgorithm;
  IHMAC = fafafa.core.crypto.interfaces.IHMAC;
  ECrypto = fafafa.core.crypto.interfaces.ECrypto;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;

type

  {**
   * THMACContext
   *
   * @desc
   *   Generic HMAC implementation that works with any hash algorithm.
   *   通用HMAC实现，可与任何哈希算法配合使用.
   *}
  THMACContext = class(TInterfacedObject, IHMAC)
  private
    FHashAlgorithm: IHashAlgorithm;
    FOuterKeyPad: TBytes;
    FInnerKeyPad: TBytes;
    FKeySet: Boolean;
    FFinalized: Boolean;

    procedure PrepareKeyPads(const AKey: TBytes);
  public
    constructor Create(AHashAlgorithm: IHashAlgorithm);
    destructor Destroy; override;

    // IHMAC 接口实现
    function GetDigestSize: Integer;
    function GetBlockSize: Integer;
    function GetName: string;
    function GetHashAlgorithmName: string;
    procedure SetKey(const AKey: TBytes); overload;
    procedure SetKey(const AKey: string); overload;
    function IsKeySet: Boolean;
    procedure Update(const AData; ASize: Integer);
    function Finalize: TBytes;
    procedure Reset;
    procedure Burn;
    function ComputeMAC(const AData: TBytes): TBytes; overload;
    function ComputeMAC(const AData: string): TBytes; overload;
    function VerifyMAC(const AData: TBytes; const AMAC: TBytes): Boolean; overload;
    function VerifyMAC(const AData: string; const AMAC: TBytes): Boolean; overload;

    // Legacy method for backward compatibility
    function Compute(const AKey, AData: TBytes): TBytes;
  end;

// 工厂函数
function CreateHMAC_SHA256: IHMAC;
function CreateHMAC_SHA512: IHMAC;
function CreateHMAC_MD5: IHMAC;
function CreateHMAC(AHashAlgorithm: IHashAlgorithm): IHMAC;

// 便利函数
function HMAC_SHA256(const AKey, AData: TBytes): TBytes;
function HMAC_SHA512(const AKey, AData: TBytes): TBytes;

implementation

uses
  fafafa.core.crypto.hash.sha256,
  fafafa.core.crypto.hash.sha512,
  fafafa.core.crypto.hash.md5,
  fafafa.core.crypto.utils;

const
  // HMAC 填充常量
  HMAC_IPAD = $36;  // 内部填充
  HMAC_OPAD = $5C;  // 外部填充

{ THMACContext }

constructor THMACContext.Create(AHashAlgorithm: IHashAlgorithm);
begin
  inherited Create;
  if AHashAlgorithm = nil then
    raise EArgumentNil.Create('Hash algorithm cannot be nil');

  FHashAlgorithm := AHashAlgorithm;
  FKeySet := False;
  FFinalized := False;
end;

destructor THMACContext.Destroy;
begin
  // 安全清零敏感数据
  if Length(FOuterKeyPad) > 0 then
    FillChar(FOuterKeyPad[0], Length(FOuterKeyPad), 0);
  if Length(FInnerKeyPad) > 0 then
    FillChar(FInnerKeyPad[0], Length(FInnerKeyPad), 0);

  FHashAlgorithm := nil;
  inherited Destroy;
end;

function THMACContext.GetDigestSize: Integer;
begin
  Result := FHashAlgorithm.DigestSize;
end;

function THMACContext.GetName: string;
begin
  Result := 'HMAC-' + FHashAlgorithm.Name;
end;

procedure THMACContext.PrepareKeyPads(const AKey: TBytes);
var
  LKey: TBytes;
  LBlockSize: Integer;
  LActualKeyLength: Integer;
  LI: Integer;
begin
  LBlockSize := FHashAlgorithm.BlockSize;

  // 调试输出
  {$IFDEF HMAC_DEBUG}
  WriteLn('HMAC_DEBUG: PrepareKeyPads called');
  WriteLn('HMAC_DEBUG: Input key length: ', Length(AKey));
  if Length(AKey) > 0 then
  begin
    Write('HMAC_DEBUG: Input key bytes: ');
    for LI := 0 to Min(7, Length(AKey) - 1) do
      Write(Format('%.2X ', [AKey[LI]]));
    WriteLn;
  end;
  WriteLn('HMAC_DEBUG: Block size: ', LBlockSize);
  {$ENDIF}

  // 如果密钥长度超过块大小，先哈希密钥
  if Length(AKey) > LBlockSize then
  begin
    FHashAlgorithm.Reset;
    if Length(AKey) > 0 then
      FHashAlgorithm.Update(AKey[0], Length(AKey));
    LKey := FHashAlgorithm.Finalize;
  end
  else
  begin
    LKey := Copy(AKey);
  end;

  // 记住实际密钥长度
  LActualKeyLength := Length(LKey);

  // 将密钥填充到块大小
  SetLength(LKey, LBlockSize);
  // 用零填充剩余部分
  for LI := LActualKeyLength to LBlockSize - 1 do
    LKey[LI] := 0;

  // 准备内部和外部密钥填充
  SetLength(FInnerKeyPad, LBlockSize);
  SetLength(FOuterKeyPad, LBlockSize);

  for LI := 0 to LBlockSize - 1 do
  begin
    FInnerKeyPad[LI] := LKey[LI] xor HMAC_IPAD;
    FOuterKeyPad[LI] := LKey[LI] xor HMAC_OPAD;
  end;

  // 调试输出
  {$IFDEF HMAC_DEBUG}
  WriteLn('HMAC_DEBUG: Final padded key length: ', Length(LKey));
  Write('HMAC_DEBUG: Final padded key (first 8 bytes): ');
  for LI := 0 to Min(7, Length(LKey) - 1) do
    Write(Format('%.2X ', [LKey[LI]]));
  WriteLn;
  Write('HMAC_DEBUG: Inner pad (first 8 bytes): ');
  for LI := 0 to Min(7, Length(FInnerKeyPad) - 1) do
    Write(Format('%.2X ', [FInnerKeyPad[LI]]));
  WriteLn;
  Write('HMAC_DEBUG: Outer pad (first 8 bytes): ');
  for LI := 0 to Min(7, Length(FOuterKeyPad) - 1) do
    Write(Format('%.2X ', [FOuterKeyPad[LI]]));
  WriteLn;
  {$ENDIF}

  // 安全清零临时密钥
  if Length(LKey) > 0 then
    FillChar(LKey[0], Length(LKey), 0);
end;

procedure THMACContext.SetKey(const AKey: TBytes);
begin
  // 允许重新设置密钥，自动重置状态
  FFinalized := False;

  PrepareKeyPads(AKey);
  FKeySet := True;

  // 确保哈希算法状态干净，然后开始内部哈希计算
  FHashAlgorithm.Reset;
  FHashAlgorithm.Update(FInnerKeyPad[0], Length(FInnerKeyPad));
end;

procedure THMACContext.Update(const AData; ASize: Integer);
begin
  if not FKeySet then
    raise EInvalidOperation.Create('Key must be set before updating HMAC');
  if FFinalized then
    raise EInvalidOperation.Create('Cannot update finalized HMAC context');

  if ASize > 0 then
    FHashAlgorithm.Update(AData, ASize);
end;

function THMACContext.Finalize: TBytes;
var
  LInnerHash: TBytes;
begin
  if not FKeySet then
    raise EInvalidOperation.Create('Key must be set before finalizing HMAC');
  if FFinalized then
    raise EInvalidOperation.Create('HMAC context already finalized');

  // 完成内部哈希
  LInnerHash := FHashAlgorithm.Finalize;

  try
    // 计算外部哈希
    FHashAlgorithm.Reset;
    FHashAlgorithm.Update(FOuterKeyPad[0], Length(FOuterKeyPad));
    FHashAlgorithm.Update(LInnerHash[0], Length(LInnerHash));
    Result := FHashAlgorithm.Finalize;

    FFinalized := True;
  finally
    // 安全清零内部哈希
    if Length(LInnerHash) > 0 then
      FillChar(LInnerHash[0], Length(LInnerHash), 0);
  end;
end;

procedure THMACContext.Reset;
begin
  FFinalized := False;
  if FKeySet then
  begin
    // 重新开始内部哈希计算
    FHashAlgorithm.Reset;
    FHashAlgorithm.Update(FInnerKeyPad[0], Length(FInnerKeyPad));
  end;
end;

function THMACContext.Compute(const AKey, AData: TBytes): TBytes;
begin
  SetKey(AKey);
  if Length(AData) > 0 then
    Update(AData[0], Length(AData));
  Result := Finalize;
end;

// Missing method implementations for new IHMAC interface

function THMACContext.GetBlockSize: Integer;
begin
  Result := FHashAlgorithm.BlockSize;
end;

function THMACContext.GetHashAlgorithmName: string;
begin
  Result := FHashAlgorithm.Name;
end;

procedure THMACContext.SetKey(const AKey: string);
{$push}
{$hints off}
var
  LKeyBytes: TBytes;
  U: UTF8String;
begin
  // 允许空密钥（RFC 2104）；按 UTF-8 编码处理字符串密钥
  SetLength(LKeyBytes, 0);
  U := UTF8String(AKey);
  if Length(U) > 0 then
  begin
    SetLength(LKeyBytes, Length(U));
    Move(Pointer(U)^, LKeyBytes[0], Length(U));
  end;
  SetKey(LKeyBytes);
  // 清理临时数据
  if Length(LKeyBytes) > 0 then
    FillChar(LKeyBytes[0], Length(LKeyBytes), 0);
end;
{$pop}


function THMACContext.IsKeySet: Boolean;
begin
  Result := FKeySet;
end;

procedure THMACContext.Burn;
begin
  // 安全清零所有敏感数据
  if Length(FInnerKeyPad) > 0 then
    FillChar(FInnerKeyPad[0], Length(FInnerKeyPad), 0);
  if Length(FOuterKeyPad) > 0 then
    FillChar(FOuterKeyPad[0], Length(FOuterKeyPad), 0);
  SetLength(FInnerKeyPad, 0);
  SetLength(FOuterKeyPad, 0);

  if Assigned(FHashAlgorithm) then
    FHashAlgorithm.Burn;

  FKeySet := False;
  FFinalized := True;
end;

function THMACContext.ComputeMAC(const AData: TBytes): TBytes;
begin
  if not FKeySet then
    raise EInvalidOperation.Create('Key must be set before computing MAC');

  Reset;
  if Length(AData) > 0 then
    Update(AData[0], Length(AData));
  Result := Finalize;
end;

function THMACContext.ComputeMAC(const AData: string): TBytes;
var
  U: UTF8String;
  tmp: TBytes;
begin
  if not FKeySet then
    raise EInvalidOperation.Create('Key must be set before computing MAC');
  SetLength(tmp, 0);
  Reset;
  U := UTF8String(AData);
  if Length(U) > 0 then
  begin
    SetLength(tmp, Length(U));
    Move(Pointer(U)^, tmp[0], Length(U));
    Update(tmp[0], Length(tmp));
  end;
  Result := Finalize;
  if Length(tmp) > 0 then FillChar(tmp[0], Length(tmp), 0);
end;

function THMACContext.VerifyMAC(const AData: TBytes; const AMAC: TBytes): Boolean;
var
  LComputedMAC: TBytes;
begin
  LComputedMAC := ComputeMAC(AData);
  Result := fafafa.core.crypto.utils.ConstantTimeCompare(LComputedMAC, AMAC);
  if Length(LComputedMAC) > 0 then
    FillChar(LComputedMAC[0], Length(LComputedMAC), 0);
end;

function THMACContext.VerifyMAC(const AData: string; const AMAC: TBytes): Boolean;
var
  LComputedMAC: TBytes;
begin
  LComputedMAC := ComputeMAC(AData);
  Result := fafafa.core.crypto.utils.ConstantTimeCompare(LComputedMAC, AMAC);
  if Length(LComputedMAC) > 0 then
    FillChar(LComputedMAC[0], Length(LComputedMAC), 0);
end;

// 工厂函数实现
function CreateHMAC_SHA256: IHMAC;
begin
  Result := THMACContext.Create(fafafa.core.crypto.hash.sha256.CreateSHA256);
end;

function CreateHMAC_SHA512: IHMAC;
begin
  Result := THMACContext.Create(fafafa.core.crypto.hash.sha512.CreateSHA512);
end;

function CreateHMAC_MD5: IHMAC;
begin
  Result := THMACContext.Create(fafafa.core.crypto.hash.md5.CreateMD5);
end;

function CreateHMAC(AHashAlgorithm: IHashAlgorithm): IHMAC;
begin
  Result := THMACContext.Create(AHashAlgorithm);
end;

// 便利函数实现
function HMAC_SHA256(const AKey, AData: TBytes): TBytes;
var
  LHMAC: IHMAC;
begin
  LHMAC := CreateHMAC_SHA256;
  LHMAC.SetKey(AKey);
  Result := LHMAC.ComputeMAC(AData);
  LHMAC.Burn;
end;

function HMAC_SHA512(const AKey, AData: TBytes): TBytes;
var
  LHMAC: IHMAC;
begin
  LHMAC := CreateHMAC_SHA512;
  LHMAC.SetKey(AKey);
  Result := LHMAC.ComputeMAC(AData);
  LHMAC.Burn;
end;

end.
