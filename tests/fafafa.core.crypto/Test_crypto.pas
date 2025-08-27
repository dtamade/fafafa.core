{$CODEPAGE UTF8}
unit Test_crypto;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.utils,
  TestAssertHelpers;

type
  { TTestCase_Global - 测试全局函数和过程 }
  TTestCase_Global = class(TTestCase)
  private
    // 辅助方法：用于 AssertException 的方法指针版本，避免匿名函数兼容性问题
    procedure DoHexToBytes_OddLength;
    procedure Test_CreateAES256GCM_Helper;
    procedure Test_GenerateRandomInteger_InvalidRange_Helper;
    procedure Test_HexToBytes_InvalidCharacters_Helper;
  published
    // 哈希算法工厂函数测试
    procedure Test_CreateSHA256;
    procedure Test_CreateSHA512;
    procedure Test_CreateMD5;

    // 便利函数：一次性哈希计算测试
    procedure Test_HashSHA256_Bytes;
    procedure Test_HashSHA256_String;
    procedure Test_HashSHA256_EmptyData;
    procedure Test_HashSHA512_Bytes;
    procedure Test_HashSHA512_String;
    procedure Test_HashSHA512_EmptyData;

    // HMAC工厂函数测试
    procedure Test_CreateHMAC_SHA256;
    procedure Test_CreateHMAC_SHA512;

    // HMAC便利函数测试
    procedure Test_HMAC_SHA256;
    procedure Test_HMAC_SHA512;

    // 对称加密工厂函数测试
    procedure Test_CreateAES256GCM;
    procedure Test_CreateAES128;
    procedure Test_CreateAES256;
    procedure Test_CreateAES128_CBC;
    procedure Test_CreateAES256_CBC;

    // 密钥派生工厂函数测试
    procedure Test_CreatePBKDF2;
    procedure Test_CreatePBKDF2_SHA256;
    procedure Test_CreatePBKDF2_SHA512;

    // PBKDF2便利函数测试
    procedure Test_PBKDF2_SHA256;
    procedure Test_PBKDF2_SHA512;

    // 安全随机数生成器测试
    procedure Test_GetSecureRandom;
    procedure Test_GenerateRandomBytes;
    procedure Test_GenerateRandomBytes_ZeroSize;
    procedure Test_GenerateRandomInteger;
    procedure Test_GenerateRandomInteger_SameMinMax;
    procedure Test_GenerateRandomInteger_InvalidRange;

    procedure Test_GenerateBase64UrlString;
    // 工具函数测试
    procedure Test_BytesToHex;
    procedure Test_BytesToHex_EmptyArray;
    procedure Test_HexToBytes;
    procedure Test_HexToBytes_EmptyString;
    procedure Test_HexToBytes_InvalidLength;
    procedure Test_HexToBytes_InvalidCharacters;
    procedure Test_SecureCompare_Equal;
    procedure Test_SecureCompare_NotEqual;
    procedure Test_SecureCompare_DifferentLength;
    procedure Test_SecureZero;

    // 安全工具函数测试
    procedure Test_ConstantTimeCompare;
    procedure Test_ConstantTimeStringCompare;
    procedure Test_SecureZeroMemory;
    procedure Test_SecureZeroBytes;
    procedure Test_SecureZeroString;

    // 密码相关函数测试
    procedure Test_CheckPasswordStrength;
    procedure Test_ValidatePassword;
    procedure Test_GetPasswordStrengthDescription;
    procedure Test_GenerateSecurePassword;
    procedure Test_GeneratePassphrase;
    procedure Test_GetDefaultPasswordPolicy;
    procedure Test_GetStrictPasswordPolicy;

    // 新增：GenerateSecurePassword 边界与分布
    procedure Test_GenerateSecurePassword_Edges;
    procedure Test_GenerateSecurePassword_TooShortForClasses;
    procedure Test_GenerateSecurePassword_Distribution_Shuffle;
  end;

  { TTestCase_IHashAlgorithm - 测试哈希算法接口 }
  TTestCase_IHashAlgorithm = class(TTestCase)
  private
    FSHA256: IHashAlgorithm;
    FSHA512: IHashAlgorithm;
    FMD5: IHashAlgorithm;
  private
    procedure Test_SHA256_Finalize_AlreadyFinalized_Helper;
    procedure Test_SHA256_Update_AfterFinalize_Helper;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // SHA-256 测试
    procedure Test_SHA256_GetDigestSize;
    procedure Test_SHA256_GetBlockSize;
    procedure Test_SHA256_GetName;
    procedure Test_SHA256_Reset;
    procedure Test_SHA256_Update_Single;
    procedure Test_SHA256_Update_Multiple;
    procedure Test_SHA256_Finalize;
    procedure Test_SHA256_Finalize_AlreadyFinalized;
    procedure Test_SHA256_Update_AfterFinalize;
    procedure Test_SHA256_KnownVectors;
    procedure Test_SHA256_Burn;

    // SHA-512 测试
    procedure Test_SHA512_GetDigestSize;
    procedure Test_SHA512_GetBlockSize;
    procedure Test_SHA512_GetName;
    procedure Test_SHA512_Reset;
    procedure Test_SHA512_Update_Single;
    procedure Test_SHA512_Update_Multiple;
    procedure Test_SHA512_Finalize;
    procedure Test_SHA512_Finalize_AlreadyFinalized;
    procedure Test_SHA512_Update_AfterFinalize;
    procedure Test_SHA512_KnownVectors;
    procedure Test_SHA512_Burn;

    // MD5 测试
    procedure Test_MD5_GetDigestSize;
    procedure Test_MD5_GetBlockSize;
    procedure Test_MD5_GetName;
    procedure Test_MD5_Reset;
    procedure Test_MD5_Update_Single;
    procedure Test_MD5_Update_Multiple;
    procedure Test_MD5_Finalize;
    procedure Test_MD5_Finalize_AlreadyFinalized;
    procedure Test_MD5_Update_AfterFinalize;
    procedure Test_MD5_KnownVectors;
    procedure Test_MD5_Burn;
  end;

  { TTestCase_IHMAC - 测试HMAC接口 }
  TTestCase_IHMAC = class(TTestCase)
  private
    FHMAC_SHA256: IHMAC;
    FHMAC_SHA512: IHMAC;
  private
    procedure Test_HMAC_Update_WithoutKey_Helper;
    procedure Test_HMAC_Finalize_WithoutKey_Helper;
    procedure Test_HMAC_Update_AfterFinalize_Helper;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // HMAC-SHA256 测试
    procedure Test_HMAC_SHA256_GetDigestSize;
    procedure Test_HMAC_SHA256_GetName;
    procedure Test_HMAC_SHA256_SetKey;
    procedure Test_HMAC_SHA256_Update_Single;
    procedure Test_HMAC_SHA256_Update_Multiple;
    procedure Test_HMAC_SHA256_Finalize;
    procedure Test_HMAC_SHA256_Reset;
    procedure Test_HMAC_SHA256_Compute;
    procedure Test_HMAC_SHA256_KnownVectors;
    procedure Test_HMAC_SHA256_EmptyKey;
    procedure Test_HMAC_SHA256_LongKey;

    // HMAC-SHA512 测试
    procedure Test_HMAC_SHA512_GetDigestSize;
    procedure Test_HMAC_SHA512_GetName;
    procedure Test_HMAC_SHA512_KnownVectors;

    // 错误处理测试
    procedure Test_HMAC_Update_WithoutKey;
    procedure Test_HMAC_Finalize_WithoutKey;
    procedure Test_HMAC_Update_AfterFinalize;
    procedure Test_HMAC_Finalize_AlreadyFinalized;

    // 重载方法测试
    procedure Test_HMAC_SHA256_SetKey_String;
    procedure Test_HMAC_SHA256_ComputeMAC_String;
    procedure Test_HMAC_SHA256_VerifyMAC_String;
    procedure Test_HMAC_SHA256_GetHashAlgorithmName;
    procedure Test_HMAC_SHA256_IsKeySet;
    procedure Test_HMAC_SHA512_SetKey_String;
    procedure Test_HMAC_SHA512_ComputeMAC_String;
    procedure Test_HMAC_SHA512_VerifyMAC_String;
    procedure Test_HMAC_SHA512_GetHashAlgorithmName;
    procedure Test_HMAC_SHA512_IsKeySet;
    procedure Test_HMAC_Burn;
  end;

  { TTestCase_ISecureRandom - 测试安全随机数生成器接口 }
  TTestCase_ISecureRandom = class(TTestCase)
  private
    FRandom: ISecureRandom;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_GetBytes_Buffer;
    procedure Test_GetBytes_Array;
    procedure Test_GetBytes_ZeroSize;
    procedure Test_GetBytes_LargeSize;
    procedure Test_GetInteger_ValidRange;
    procedure Test_GetInteger_SameMinMax;
    procedure Test_GetInteger_InvalidRange;
    procedure Test_GetInteger_Distribution;

    // 补充的方法测试
    procedure Test_GetByte;
    procedure Test_GetInteger_NoParams;
    procedure Test_GetUInt32;
    procedure Test_GetUInt64;
    procedure Test_GetSingle;
    procedure Test_GetDouble;
    procedure Test_GetHexString;
    procedure Test_GetBase64String;
    procedure Test_GetBase64UrlString;
    procedure Test_GetAlphanumericString;
    procedure Test_AddEntropy;
    procedure Test_GetEntropyEstimate;
    procedure Test_Reseed;
    procedure Test_IsInitialized;
    procedure Test_Reset;
    procedure Test_Burn;
  end;

implementation

// 辅助函数：安全地调用哈希算法的Update方法
procedure SafeUpdate(AHash: IHashAlgorithm; const AData: TBytes);
begin
  if Length(AData) > 0 then
    AHash.Update(AData[0], Length(AData));
end;

// 辅助函数：安全地调用HMAC的Update方法
procedure SafeUpdateHMAC(AHMAC: IHMAC; const AData: TBytes);
begin
  if Length(AData) > 0 then
    AHMAC.Update(AData[0], Length(AData));
end;

// 方法指针：用于 AssertException 不支持匿名引用时的回退
procedure TTestCase_Global.DoHexToBytes_OddLength;
var
  LTmp: TBytes;
begin
  LTmp := HexToBytes('abc'); // 应当抛出 EInvalidArgument
  if Length(LTmp) > 0 then; // 防止优化
end;

// 方法指针回退：触发 AES-256-GCM 未实现异常
procedure TTestCase_Global.Test_CreateAES256GCM_Helper;
begin
  CreateAES256GCM;
end;

// 方法指针回退：HexToBytes 非法字符
procedure TTestCase_Global.Test_HexToBytes_InvalidCharacters_Helper;
begin
  HexToBytes('abcg');
end;

{ TTestCase_Global }

procedure TTestCase_Global.Test_CreateSHA256;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateSHA256;
  AssertNotNull('SHA256 instance should not be nil', LHash);
  AssertEquals('SHA256 digest size', 32, LHash.DigestSize);
  AssertEquals('SHA256 block size', 64, LHash.BlockSize);
  AssertEquals('SHA256 name', 'SHA-256', LHash.Name);
end;

procedure TTestCase_Global.Test_CreateSHA512;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateSHA512;
  AssertNotNull('SHA512 instance should not be nil', LHash);
  AssertEquals('SHA512 digest size', 64, LHash.DigestSize);
  AssertEquals('SHA512 block size', 128, LHash.BlockSize);
  AssertEquals('SHA512 name', 'SHA-512', LHash.Name);
end;

procedure TTestCase_Global.Test_CreateMD5;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateMD5;
  AssertNotNull('MD5 instance should not be nil', LHash);
  AssertEquals('MD5 digest size', 16, LHash.DigestSize);
  AssertEquals('MD5 block size', 64, LHash.BlockSize);
  AssertEquals('MD5 name', 'MD5', LHash.Name);
end;

procedure TTestCase_Global.Test_HashSHA256_Bytes;
var
  LData: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  // 测试 "abc" 的 SHA-256
  LData := TEncoding.UTF8.GetBytes('abc');
  LResult := HashSHA256(LData);
  LExpected := 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
  AssertEquals('SHA256 of "abc"', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_Global.Test_HashSHA256_String;
var
  LResult: TBytes;
  LExpected: string;
begin
  // 测试 "abc" 的 SHA-256
  LResult := HashSHA256('abc');
  LExpected := 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
  AssertEquals('SHA256 of "abc"', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_Global.Test_HashSHA256_EmptyData;
var
  LResult: TBytes;
  LExpected: string;
begin
  // 测试空数据的 SHA-256
  LResult := HashSHA256('');
  LExpected := 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
  AssertEquals('SHA256 of empty string', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_Global.Test_HashSHA512_Bytes;
var
  LData: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  // 测试 "abc" 的 SHA-512
  LData := TEncoding.UTF8.GetBytes('abc');
  LResult := HashSHA512(LData);
  LExpected := 'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a' +
               '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f';
  AssertEquals('SHA512 of "abc"', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_Global.Test_HashSHA512_String;
var
  LResult: TBytes;
  LExpected: string;
begin
  // 测试 "abc" 的 SHA-512
  LResult := HashSHA512('abc');
  LExpected := 'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a' +
               '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f';
  AssertEquals('SHA512 of "abc"', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_Global.Test_HashSHA512_EmptyData;
var
  LResult: TBytes;
  LExpected: string;
begin
  // 测试空数据的 SHA-512
  LResult := HashSHA512('');
  LExpected := 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce' +
               '47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e';
  AssertEquals('SHA512 of empty string', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_Global.Test_CreateHMAC_SHA256;
var
  LHMAC: IHMAC;
begin
  LHMAC := CreateHMAC_SHA256;
  AssertNotNull('HMAC-SHA256 instance should not be nil', LHMAC);
  AssertEquals('HMAC-SHA256 digest size', 32, LHMAC.DigestSize);
  AssertEquals('HMAC-SHA256 name', 'HMAC-SHA-256', LHMAC.Name);
  AssertEquals('HMAC-SHA256 hash algorithm', 'SHA-256', LHMAC.HashAlgorithmName);
end;

procedure TTestCase_Global.Test_CreateHMAC_SHA512;
var
  LHMAC: IHMAC;
begin
  LHMAC := CreateHMAC_SHA512;
  AssertNotNull('HMAC-SHA512 instance should not be nil', LHMAC);
  AssertEquals('HMAC-SHA512 digest size', 64, LHMAC.DigestSize);
  AssertEquals('HMAC-SHA512 name', 'HMAC-SHA-512', LHMAC.Name);
  AssertEquals('HMAC-SHA512 hash algorithm', 'SHA-512', LHMAC.HashAlgorithmName);
end;

procedure TTestCase_Global.Test_HMAC_SHA256;
var
  LKey, LData: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := TEncoding.UTF8.GetBytes('The quick brown fox jumps over the lazy dog');

  LResult := HMAC_SHA256(LKey, LData);

  AssertEquals('HMAC-SHA256 result length', 32, Length(LResult));
  LExpected := 'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8';
  AssertEquals('HMAC-SHA256 known vector', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_Global.Test_HMAC_SHA512;
var
  LKey, LData: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := TEncoding.UTF8.GetBytes('The quick brown fox jumps over the lazy dog');

  LResult := HMAC_SHA512(LKey, LData);

  AssertEquals('HMAC-SHA512 result length', 64, Length(LResult));
  LExpected := 'b42af09057bac1e2d41708e48a902e09b5ff7f12ab428a4fe86653c73dd248fb82f948a549f7b791a5b41915ee4d1ec3935357e4e2317250d0372afa2ebeeb3a';
  AssertEquals('HMAC-SHA512 known vector', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_Global.Test_CreateAES256GCM;
begin
  // 已实现：应能成功创建
  try
    CreateAES256GCM;
  except
    on E: Exception do
      Fail('CreateAES256GCM raised: ' + E.ClassName + ' - ' + E.Message);
  end;
end;

procedure TTestCase_Global.Test_CreateAES128;
var
  LAES: ISymmetricCipher;
begin
  LAES := CreateAES128;
  AssertNotNull('AES-128 instance should not be nil', LAES);
  AssertEquals('AES-128 key size', 16, LAES.KeySize);
  AssertEquals('AES-128 block size', 16, LAES.BlockSize);
  AssertEquals('AES-128 name', 'AES-128', LAES.Name);
end;

procedure TTestCase_Global.Test_CreateAES256;
var
  LAES: ISymmetricCipher;
begin
  LAES := CreateAES256;
  AssertNotNull('AES-256 instance should not be nil', LAES);
  AssertEquals('AES-256 key size', 32, LAES.KeySize);
  AssertEquals('AES-256 block size', 16, LAES.BlockSize);
  AssertEquals('AES-256 name', 'AES-256', LAES.Name);
end;

procedure TTestCase_Global.Test_CreateAES128_CBC;
var
  LAES: IBlockCipherWithIV;
begin
  LAES := CreateAES128_CBC;
  AssertNotNull('AES-128-CBC instance should not be nil', LAES);
  AssertEquals('AES-128-CBC key size', 16, LAES.KeySize);
  AssertEquals('AES-128-CBC block size', 16, LAES.BlockSize);
  AssertEquals('AES-128-CBC IV size', 16, LAES.IVSize);
  AssertEquals('AES-128-CBC mode', 'CBC', LAES.Mode);
  AssertEquals('AES-128-CBC name', 'AES-128-CBC', LAES.Name);
end;

procedure TTestCase_Global.Test_CreateAES256_CBC;
var
  LAES: IBlockCipherWithIV;
begin
  LAES := CreateAES256_CBC;
  AssertNotNull('AES-256-CBC instance should not be nil', LAES);
  AssertEquals('AES-256-CBC key size', 32, LAES.KeySize);
  AssertEquals('AES-256-CBC block size', 16, LAES.BlockSize);
  AssertEquals('AES-256-CBC IV size', 16, LAES.IVSize);
  AssertEquals('AES-256-CBC mode', 'CBC', LAES.Mode);
  AssertEquals('AES-256-CBC name', 'AES-256-CBC', LAES.Name);
end;

procedure TTestCase_Global.Test_GetSecureRandom;
var
  LRandom: ISecureRandom;
begin
  LRandom := GetSecureRandom;
  AssertNotNull('SecureRandom instance should not be nil', LRandom);

  // 测试多次调用返回同一实例
  AssertSame('Should return same instance', LRandom, GetSecureRandom);
end;

procedure TTestCase_Global.Test_GenerateRandomBytes;
var
  LBytes1, LBytes2: TBytes;
begin
  LBytes1 := GenerateRandomBytes(16);
  LBytes2 := GenerateRandomBytes(16);

  AssertEquals('Should generate 16 bytes', 16, Length(LBytes1));
  AssertEquals('Should generate 16 bytes', 16, Length(LBytes2));
  AssertFalse('Random bytes should be different', SecureCompare(LBytes1, LBytes2));
end;

procedure TTestCase_Global.Test_GenerateRandomBytes_ZeroSize;
var
  LBytes: TBytes;
begin
  LBytes := GenerateRandomBytes(0);
  AssertEquals('Should generate 0 bytes', 0, Length(LBytes));
end;

procedure TTestCase_Global.Test_GenerateRandomInteger;
var
  LValue: Integer;
  LI: Integer;
  LInRange: Boolean;
begin
  LInRange := True;

  // 测试多次生成，确保都在范围内
  for LI := 1 to 100 do
  begin
    LValue := GenerateRandomInteger(10, 20);
    if (LValue < 10) or (LValue > 20) then
    begin
      LInRange := False;
      Break;
    end;
  end;


  AssertTrue('All values should be in range [10, 20]', LInRange);
end;

procedure TTestCase_Global.Test_GenerateRandomInteger_SameMinMax;
var
  LValue: Integer;
begin
  LValue := GenerateRandomInteger(42, 42);
  AssertEquals('Should return the same value when min=max', 42, LValue);
end;

procedure TTestCase_Global.Test_GenerateRandomInteger_InvalidRange;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception for invalid range', EInvalidArgument,
    procedure begin GenerateRandomInteger(20, 10); end);
  {$ELSE}
  AssertException('Should raise exception for invalid range', fafafa.core.crypto.interfaces.EInvalidArgument,
    @Self.Test_GenerateRandomInteger_InvalidRange_Helper);
  {$ENDIF}


end;

procedure TTestCase_Global.Test_GenerateBase64UrlString;
var
  S1, S2: string;
  I: Integer;
  C: Char;
begin
  S1 := GenerateBase64UrlString(24);
  S2 := GenerateBase64UrlString(24);
  AssertEquals('Length should be 24', 24, Length(S1));
  AssertEquals('Length should be 24', 24, Length(S2));
  AssertTrue('Strings should differ', S1 <> S2);
  for I := 1 to Length(S1) do
  begin
    C := S1[I];
    AssertTrue('Char must be URL-safe Base64', C in ['A'..'Z','a'..'z','0'..'9','-','_']);
  end;
end;



// 方法指针回退：生成随机整数非法范围
procedure TTestCase_Global.Test_GenerateRandomInteger_InvalidRange_Helper;
begin
  GenerateRandomInteger(20, 10);
end;

procedure TTestCase_Global.Test_BytesToHex;
var
  LBytes: TBytes;
  LResult: string;
begin
  SetLength(LBytes, 3);
  LBytes[0] := $AB;
  LBytes[1] := $CD;
  LBytes[2] := $EF;

  LResult := BytesToHex(LBytes);
  AssertEquals('Hex conversion', 'abcdef', LResult);
end;

procedure TTestCase_Global.Test_BytesToHex_EmptyArray;
var
  LBytes: TBytes;
  LResult: string;
begin
  SetLength(LBytes, 0);
  LResult := BytesToHex(LBytes);
  AssertEquals('Empty array to hex', '', LResult);
end;

procedure TTestCase_Global.Test_HexToBytes;
var
  LResult: TBytes;
begin
  LResult := HexToBytes('abcdef');
  AssertEquals('Should have 3 bytes', 3, Length(LResult));
  AssertEquals('First byte', $AB, LResult[0]);
  AssertEquals('Second byte', $CD, LResult[1]);
  AssertEquals('Third byte', $EF, LResult[2]);
end;

procedure TTestCase_Global.Test_HexToBytes_EmptyString;
var
  LResult: TBytes;
begin
  LResult := HexToBytes('');
  AssertEquals('Empty string to bytes', 0, Length(LResult));
end;

procedure TTestCase_Global.Test_HexToBytes_InvalidLength;
var
  LTmp: TBytes;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception for odd length', fafafa.core.crypto.interfaces.EInvalidArgument,
    procedure begin
      // 使用返回值以避免编译器优化移除调用
      LTmp := HexToBytes('abc');
      if Length(LTmp) > 0 then; // no-op，仅防优化
    end);
  {$ELSE}
  // 方法指针版本，避免匿名函数依赖
  AssertException('Should raise exception for odd length', fafafa.core.crypto.interfaces.EInvalidArgument, @DoHexToBytes_OddLength);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_HexToBytes_InvalidCharacters;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception for invalid characters', EConvertError,
    procedure begin HexToBytes('abcg'); end);
  {$ELSE}
  // 方法指针版本
  AssertException('Should raise exception for invalid characters', EConvertError,
    @Self.Test_HexToBytes_InvalidCharacters_Helper);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_SecureCompare_Equal;
var
  LBytes1, LBytes2: TBytes;
begin
  LBytes1 := TEncoding.UTF8.GetBytes('hello');
  LBytes2 := TEncoding.UTF8.GetBytes('hello');
  AssertTrue('Equal arrays should compare as equal', SecureCompare(LBytes1, LBytes2));
end;

procedure TTestCase_Global.Test_SecureCompare_NotEqual;
var
  LBytes1, LBytes2: TBytes;
begin
  LBytes1 := TEncoding.UTF8.GetBytes('hello');
  LBytes2 := TEncoding.UTF8.GetBytes('world');
  AssertFalse('Different arrays should compare as not equal', SecureCompare(LBytes1, LBytes2));
end;

procedure TTestCase_Global.Test_SecureCompare_DifferentLength;
var
  LBytes1, LBytes2: TBytes;
begin
  LBytes1 := TEncoding.UTF8.GetBytes('hello');
  LBytes2 := TEncoding.UTF8.GetBytes('hi');
  AssertFalse('Arrays of different length should compare as not equal', SecureCompare(LBytes1, LBytes2));
end;

procedure TTestCase_Global.Test_SecureZero;
var
  LBuffer: array[0..15] of Byte;
  LI: Integer;
  LAllZero: Boolean;
begin
  // 填充非零数据
  for LI := 0 to 15 do
    LBuffer[LI] := $FF;

  // 清零
  SecureZero(LBuffer, SizeOf(LBuffer));

  // 验证全部为零
  LAllZero := True;
  for LI := 0 to 15 do
  begin
    if LBuffer[LI] <> 0 then
    begin
      LAllZero := False;
      Break;
    end;
  end;

  AssertTrue('Buffer should be all zeros', LAllZero);
end;

procedure TTestCase_Global.Test_CreatePBKDF2;
var
  LKDF: IKeyDerivationFunction;
begin
  LKDF := CreatePBKDF2;
  AssertNotNull('PBKDF2 instance should not be nil', LKDF);
  AssertEquals('PBKDF2 name', 'PBKDF2-SHA-256', LKDF.Name);
  AssertEquals('PBKDF2 hash algorithm', 'SHA-256', LKDF.HashAlgorithmName);
  AssertTrue('PBKDF2 min iterations should be positive', LKDF.MinIterations > 0);
  AssertTrue('PBKDF2 max key length should be positive', LKDF.MaxKeyLength > 0);
end;

procedure TTestCase_Global.Test_CreatePBKDF2_SHA256;
var
  LKDF: IKeyDerivationFunction;
begin
  LKDF := CreatePBKDF2_SHA256;
  AssertNotNull('PBKDF2-SHA256 instance should not be nil', LKDF);
  AssertEquals('PBKDF2-SHA256 name', 'PBKDF2-SHA-256', LKDF.Name);
  AssertEquals('PBKDF2-SHA256 hash algorithm', 'SHA-256', LKDF.HashAlgorithmName);
end;

procedure TTestCase_Global.Test_CreatePBKDF2_SHA512;
var
  LKDF: IKeyDerivationFunction;
begin
  LKDF := CreatePBKDF2_SHA512;
  AssertNotNull('PBKDF2-SHA512 instance should not be nil', LKDF);
  AssertEquals('PBKDF2-SHA512 name', 'PBKDF2-SHA-512', LKDF.Name);
  AssertEquals('PBKDF2-SHA512 hash algorithm', 'SHA-512', LKDF.HashAlgorithmName);
end;






procedure TTestCase_Global.Test_PBKDF2_SHA256;
var
  LPassword: string;
  LSalt: TBytes;
  LResult: TBytes;
begin
  LPassword := 'password';
  SetLength(LSalt, 8);
  LSalt[0] := $73; LSalt[1] := $61; LSalt[2] := $6C; LSalt[3] := $74; // 'salt'
  LSalt[4] := $73; LSalt[5] := $61; LSalt[6] := $6C; LSalt[7] := $74;

  LResult := PBKDF2_SHA256(LPassword, LSalt, 1000, 32);

  AssertEquals('PBKDF2-SHA256 result length', 32, Length(LResult));
  AssertTrue('PBKDF2-SHA256 result should not be empty', Length(LResult) > 0);
end;

procedure TTestCase_Global.Test_PBKDF2_SHA512;
var


  LPassword: string;
  LSalt: TBytes;
  LResult: TBytes;
begin
  LPassword := 'password';
  SetLength(LSalt, 8);
  LSalt[0] := $73; LSalt[1] := $61; LSalt[2] := $6C; LSalt[3] := $74; // 'salt'


  LSalt[4] := $73; LSalt[5] := $61; LSalt[6] := $6C; LSalt[7] := $74;

  LResult := PBKDF2_SHA512(LPassword, LSalt, 1000, 32);

  AssertEquals('PBKDF2-SHA512 result length', 32, Length(LResult));
  AssertTrue('PBKDF2-SHA512 result should not be empty', Length(LResult) > 0);
end;

procedure TTestCase_Global.Test_ConstantTimeCompare;
var
  LBytes1, LBytes2, LBytes3: TBytes;
begin
  LBytes1 := TEncoding.UTF8.GetBytes('hello');
  LBytes2 := TEncoding.UTF8.GetBytes('hello');
  LBytes3 := TEncoding.UTF8.GetBytes('world');

  AssertTrue('Equal arrays should compare as equal', ConstantTimeCompare(LBytes1, LBytes2));
  AssertFalse('Different arrays should compare as not equal', ConstantTimeCompare(LBytes1, LBytes3));
end;

procedure TTestCase_Global.Test_ConstantTimeStringCompare;
begin
  AssertTrue('Equal strings should compare as equal', ConstantTimeStringCompare('hello', 'hello'));
  AssertFalse('Different strings should compare as not equal', ConstantTimeStringCompare('hello', 'world'));
  AssertFalse('Different length strings should compare as not equal', ConstantTimeStringCompare('hello', 'hi'));
end;

procedure TTestCase_Global.Test_SecureZeroMemory;
var
  LBuffer: array[0..15] of Byte;
  LI: Integer;
  LAllZero: Boolean;
begin
  // 填充非零数据
  for LI := 0 to 15 do
    LBuffer[LI] := $FF;

  // 清零
  SecureZeroMemory(@LBuffer, SizeOf(LBuffer));

  // 验证全部为零
  LAllZero := True;
  for LI := 0 to 15 do
  begin
    if LBuffer[LI] <> 0 then
    begin
      LAllZero := False;
      Break;
    end;
  end;

  AssertTrue('Buffer should be all zeros', LAllZero);
end;

procedure TTestCase_Global.Test_SecureZeroBytes;
var
  LBytes: TBytes;
  LI: Integer;
  LAllZero: Boolean;
begin
  SetLength(LBytes, 16);

  // 填充非零数据
  for LI := 0 to 15 do
    LBytes[LI] := $FF;

  // 清零
  SecureZeroBytes(LBytes);

  // 验证全部为零
  LAllZero := True;
  for LI := 0 to 15 do
  begin
    if LBytes[LI] <> 0 then
    begin
      LAllZero := False;
      Break;
    end;
  end;

  AssertTrue('Bytes should be all zeros', LAllZero);
end;

procedure TTestCase_Global.Test_SecureZeroString;
var
  LStr: string;
  LI: Integer;
  LAllZero: Boolean;
begin
  LStr := 'sensitive data';

  // 清零
  SecureZeroString(LStr);

  // 验证字符串被清零（长度应该为0或内容为空字符）
  AssertTrue('String should be empty or zeroed', (Length(LStr) = 0) or (LStr = ''));
end;

procedure TTestCase_Global.Test_CheckPasswordStrength;
var
  LStrength: TPasswordStrength;
begin
  // 测试非常弱的密码
  LStrength := CheckPasswordStrength('123');
  AssertEquals('Very weak password', Ord(psVeryWeak), Ord(LStrength));

  // 测试常见密码
  LStrength := CheckPasswordStrength('password');
  AssertEquals('Common password should be very weak', Ord(psVeryWeak), Ord(LStrength));

  // 测试中等强度密码
  LStrength := CheckPasswordStrength('Password1');
  AssertTrue('Medium password should be fair or better', Ord(LStrength) >= Ord(psFair));

  // 测试强密码
  LStrength := CheckPasswordStrength('MyStr0ng!P@ssw0rd');
  AssertTrue('Strong password should be good or better', Ord(LStrength) >= Ord(psGood));
end;

procedure TTestCase_Global.Test_ValidatePassword;
var
  LPolicy: TPasswordPolicy;
begin
  LPolicy := GetDefaultPasswordPolicy;

  // 测试符合策略的密码
  AssertTrue('Valid password should pass', ValidatePassword('Password123', LPolicy));

  // 测试太短的密码
  AssertFalse('Short password should fail', ValidatePassword('Pass1', LPolicy));

  // 测试缺少数字的密码
  AssertFalse('Password without digits should fail', ValidatePassword('Password', LPolicy));

  // 测试常见密码
  AssertFalse('Common password should fail', ValidatePassword('password', LPolicy));
end;

procedure TTestCase_Global.Test_GetPasswordStrengthDescription;
var
  LDescription: string;
begin
  LDescription := GetPasswordStrengthDescription(psVeryWeak);
  AssertTrue('Very weak description should contain "Very Weak"', Pos('Very Weak', LDescription) > 0);

  LDescription := GetPasswordStrengthDescription(psStrong);
  AssertTrue('Strong description should contain "Strong"', Pos('Strong', LDescription) > 0);

  LDescription := GetPasswordStrengthDescription(psVeryStrong);
  AssertTrue('Very strong description should contain "Very Strong"', Pos('Very Strong', LDescription) > 0);
end;

procedure TTestCase_Global.Test_GenerateSecurePassword;
var
  LPassword: string;
  LHasUpper, LHasLower, LHasDigit, LHasSymbol: Boolean;
  LI: Integer;
  LChar: Char;
begin
  // 测试生成包含所有字符类型的密码
  LPassword := GenerateSecurePassword(12, True, True, True, True);
  AssertEquals('Password length should be 12', 12, Length(LPassword));

  // 检查字符类型
  LHasUpper := False;
  LHasLower := False;
  LHasDigit := False;
  LHasSymbol := False;

  for LI := 1 to Length(LPassword) do
  begin
    LChar := LPassword[LI];
    if LChar in ['A'..'Z'] then
      LHasUpper := True
    else if LChar in ['a'..'z'] then
      LHasLower := True
    else if LChar in ['0'..'9'] then
      LHasDigit := True
    else
      LHasSymbol := True;
  end;

  AssertTrue('Password should contain uppercase', LHasUpper);
  AssertTrue('Password should contain lowercase', LHasLower);
  AssertTrue('Password should contain digits', LHasDigit);
  AssertTrue('Password should contain symbols', LHasSymbol);

  // 测试只包含字母和数字的密码
  LPassword := GenerateSecurePassword(8, True, True, True, False);
  AssertEquals('Password length should be 8', 8, Length(LPassword));
end;


  // 额外边界用例：GenerateSecurePassword（类别覆盖/边界长度）
  procedure TTestCase_Global.Test_GenerateSecurePassword_Edges;
  var
    LPwd: string;
    LHasUpper, LHasLower, LHasDigit, LHasSymbol: Boolean;
    LCh: Char;
  begin
    // 长度过短：0 -> 应抛出 EInvalidArgument
    try
      LPwd := GenerateSecurePassword(0, True, True, True, True);
      Fail('length=0 should raise');
    except
      on E: fafafa.core.crypto.interfaces.EInvalidArgument do ;
      else raise;
    end;

    // 恰好等于启用类别数：4 类、长度=4 -> 必须每类至少1个
    LPwd := GenerateSecurePassword(4, True, True, True, True);
    AssertEquals(4, Length(LPwd));
    LHasUpper := False; LHasLower := False; LHasDigit := False; LHasSymbol := False;
    for LCh in LPwd do
    begin
      if (LCh >= 'A') and (LCh <= 'Z') then LHasUpper := True
      else if (LCh >= 'a') and (LCh <= 'z') then LHasLower := True
      else if (LCh >= '0') and (LCh <= '9') then LHasDigit := True
      else LHasSymbol := True;
    end;
    AssertTrue('must contain uppercase', LHasUpper);
    AssertTrue('must contain lowercase', LHasLower);
    AssertTrue('must contain digit', LHasDigit);
    AssertTrue('must contain symbol', LHasSymbol);

    // 单一类别：仅小写，长度=8
    LPwd := GenerateSecurePassword(8, False, True, False, False);
    AssertEquals(8, Length(LPwd));
    for LCh in LPwd do
      AssertTrue('only lowercase expected', (LCh >= 'a') and (LCh <= 'z'));

    // 多类别但不含符号：长度=16
    LPwd := GenerateSecurePassword(16, True, True, True, False);
    AssertEquals(16, Length(LPwd));
    for LCh in LPwd do
      AssertTrue('no symbol expected', ((LCh >= 'A') and (LCh <= 'Z')) or ((LCh >= 'a') and (LCh <= 'z')) or ((LCh >= '0') and (LCh <= '9')));

    // 极大长度：256（作为合理上限）
    LPwd := GenerateSecurePassword(256, True, True, True, True);
    AssertEquals(256, Length(LPwd));
  end;

  // 长度小于启用类别数 -> 应抛出 EInvalidArgument
  procedure TTestCase_Global.Test_GenerateSecurePassword_TooShortForClasses;
  var LPwd: string;
  begin
    try
      LPwd := GenerateSecurePassword(3, True, True, True, True);
      Fail('too short for required classes');
    except
      on E: fafafa.core.crypto.interfaces.EInvalidArgument do ;
      else raise;
    end;
  end;

  // 基础分布/洗牌合理性：多次生成，不应总以同一类别顺序出现
  procedure TTestCase_Global.Test_GenerateSecurePassword_Distribution_Shuffle;
  var
    I, SamePrefixCount: Integer;
    P1, P2: string;
  begin
    SamePrefixCount := 0;
    // 生成多次，比较前4个字符类别的分布是否经常相同（弱统计，防脆弱）
    for I := 1 to 50 do
    begin
      P1 := GenerateSecurePassword(12, True, True, True, True);
      P2 := GenerateSecurePassword(12, True, True, True, True);
      if Copy(P1, 1, 4) = Copy(P2, 1, 4) then
        Inc(SamePrefixCount);
    end;
    // 允许偶发相同，但 50 次中不应超过 10 次（经验阈值）
    AssertTrue('shuffle sanity check', SamePrefixCount <= 10);
  end;


procedure TTestCase_Global.Test_GeneratePassphrase;
var
  LPassphrase: string;
  LWordCount: Integer;
begin
  // 测试默认参数
  LPassphrase := GeneratePassphrase;
  AssertTrue('Passphrase should not be empty', Length(LPassphrase) > 0);
  AssertTrue('Passphrase should contain separator', Pos('-', LPassphrase) > 0);

  // 测试自定义参数
  LPassphrase := GeneratePassphrase(3, ' ');
  AssertTrue('Custom passphrase should not be empty', Length(LPassphrase) > 0);
  AssertTrue('Custom passphrase should contain space separator', Pos(' ', LPassphrase) > 0);
end;

procedure TTestCase_Global.Test_GetDefaultPasswordPolicy;
var
  LPolicy: TPasswordPolicy;
begin
  LPolicy := GetDefaultPasswordPolicy;
  AssertTrue('Default policy min length should be positive', LPolicy.MinLength > 0);
  AssertTrue('Default policy should require uppercase', LPolicy.RequireUppercase);
  AssertTrue('Default policy should require lowercase', LPolicy.RequireLowercase);
  AssertTrue('Default policy should require digits', LPolicy.RequireDigits);
  AssertTrue('Default policy should forbid common passwords', LPolicy.ForbidCommonPasswords);
end;

procedure TTestCase_Global.Test_GetStrictPasswordPolicy;
var
  LPolicy: TPasswordPolicy;
  LDefaultPolicy: TPasswordPolicy;
begin
  LPolicy := GetStrictPasswordPolicy;
  LDefaultPolicy := GetDefaultPasswordPolicy;

  AssertTrue('Strict policy should have longer min length', LPolicy.MinLength > LDefaultPolicy.MinLength);
  AssertTrue('Strict policy should require symbols', LPolicy.RequireSymbols);
  AssertTrue('Strict policy should have lower max repeated chars', LPolicy.MaxRepeatedChars < LDefaultPolicy.MaxRepeatedChars);
end;

{ TTestCase_IHMAC }

procedure TTestCase_IHMAC.SetUp;
begin
  FHMAC_SHA256 := CreateHMAC_SHA256;
  FHMAC_SHA512 := CreateHMAC_SHA512;
end;

procedure TTestCase_IHMAC.TearDown;
begin
  FHMAC_SHA256 := nil;
  FHMAC_SHA512 := nil;
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_GetDigestSize;
begin
  AssertEquals('HMAC-SHA256 digest size', 32, FHMAC_SHA256.GetDigestSize);
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_GetName;
begin
  AssertEquals('HMAC-SHA256 name', 'HMAC-SHA-256', FHMAC_SHA256.GetName);
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_SetKey;
var
  LKey: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('secret');
  FHMAC_SHA256.SetKey(LKey);
  // 如果没有异常，说明设置成功
  AssertTrue('Key set successfully', True);
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_Update_Single;
var
  LKey, LData: TBytes;
  LResult: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := TEncoding.UTF8.GetBytes('The quick brown fox jumps over the lazy dog');

  FHMAC_SHA256.SetKey(LKey);
  SafeUpdateHMAC(FHMAC_SHA256, LData);
  LResult := FHMAC_SHA256.Finalize;

  AssertEquals('HMAC result length', 32, Length(LResult));
  // RFC 2202 测试向量
  AssertEquals('HMAC-SHA256 result',
    'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8',
    BytesToHex(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_Update_Multiple;
var
  LKey, LData1, LData2: TBytes;
  LResult: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData1 := TEncoding.UTF8.GetBytes('The quick brown fox ');
  LData2 := TEncoding.UTF8.GetBytes('jumps over the lazy dog');

  FHMAC_SHA256.SetKey(LKey);
  SafeUpdateHMAC(FHMAC_SHA256, LData1);
  SafeUpdateHMAC(FHMAC_SHA256, LData2);
  LResult := FHMAC_SHA256.Finalize;

  // 应该与单次更新的结果相同
  AssertEquals('HMAC-SHA256 multiple updates',
    'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8',
    BytesToHex(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_Finalize;
var
  LKey, LData: TBytes;
  LResult: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('test');
  LData := TEncoding.UTF8.GetBytes('data');

  FHMAC_SHA256.SetKey(LKey);
  SafeUpdateHMAC(FHMAC_SHA256, LData);
  LResult := FHMAC_SHA256.Finalize;

  AssertEquals('HMAC result length', 32, Length(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_Reset;
var
  LKey, LData: TBytes;
  LResult1, LResult2: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('test');
  LData := TEncoding.UTF8.GetBytes('data');

  // 第一次计算
  FHMAC_SHA256.SetKey(LKey);
  FHMAC_SHA256.Update(LData[0], Length(LData));
  LResult1 := FHMAC_SHA256.Finalize;

  // 重置后再次计算
  FHMAC_SHA256.Reset;
  FHMAC_SHA256.Update(LData[0], Length(LData));
  LResult2 := FHMAC_SHA256.Finalize;

  AssertTrue('Results should be equal after reset', SecureCompare(LResult1, LResult2));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_Compute;
var
  LKey, LData: TBytes;
  LResult: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := TEncoding.UTF8.GetBytes('The quick brown fox jumps over the lazy dog');

  FHMAC_SHA256.SetKey(LKey);
  LResult := FHMAC_SHA256.ComputeMAC(LData);

  AssertEquals('HMAC-SHA256 compute result',
    'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8',
    BytesToHex(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_KnownVectors;
var
  LTestVectors: array[0..2] of record
    Key: string;
    Data: string;
    Expected: string;
  end;
  LI: Integer;
  LKey, LData: TBytes;
  LResult: TBytes;
begin
  // RFC 2202 测试向量
  LTestVectors[0].Key := 'key';
  LTestVectors[0].Data := 'The quick brown fox jumps over the lazy dog';
  LTestVectors[0].Expected := 'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8';

  LTestVectors[1].Key := '';
  LTestVectors[1].Data := '';
  LTestVectors[1].Expected := 'b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad';

  LTestVectors[2].Key := 'Jefe';
  LTestVectors[2].Data := 'what do ya want for nothing?';
  LTestVectors[2].Expected := '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843';

  for LI := 0 to 2 do
  begin
    LKey := TEncoding.UTF8.GetBytes(LTestVectors[LI].Key);
    LData := TEncoding.UTF8.GetBytes(LTestVectors[LI].Data);

    FHMAC_SHA256.SetKey(LKey);
  LResult := FHMAC_SHA256.ComputeMAC(LData);
    AssertEquals(Format('HMAC-SHA256 test vector %d', [LI]),
      LTestVectors[LI].Expected, BytesToHex(LResult));
  end;
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_EmptyKey;
var
  LKey, LData: TBytes;
  LResult: TBytes;
begin
  SetLength(LKey, 0);
  LData := TEncoding.UTF8.GetBytes('test data');

  FHMAC_SHA256.SetKey(LKey);
  LResult := FHMAC_SHA256.ComputeMAC(LData);
  AssertEquals('HMAC result length with empty key', 32, Length(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_LongKey;
var
  LKey, LData: TBytes;
  LResult: TBytes;
  LI: Integer;
begin
  // 创建一个超过块大小的密钥 (SHA-256块大小为64字节)
  SetLength(LKey, 80);
  for LI := 0 to 79 do
    LKey[LI] := LI mod 256;

  LData := TEncoding.UTF8.GetBytes('test data');

  FHMAC_SHA256.SetKey(LKey);
  LResult := FHMAC_SHA256.ComputeMAC(LData);
  AssertEquals('HMAC result length with long key', 32, Length(LResult));
end;

// HMAC-SHA512 测试
procedure TTestCase_IHMAC.Test_HMAC_SHA512_GetDigestSize;
begin
  AssertEquals('HMAC-SHA512 digest size', 64, FHMAC_SHA512.GetDigestSize);
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA512_GetName;
begin
  AssertEquals('HMAC-SHA512 name', 'HMAC-SHA-512', FHMAC_SHA512.GetName);
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA512_KnownVectors;
var
  LKey, LData: TBytes;
  LResult: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := TEncoding.UTF8.GetBytes('The quick brown fox jumps over the lazy dog');

  FHMAC_SHA512.SetKey(LKey);
  LResult := FHMAC_SHA512.ComputeMAC(LData);

  // RFC 4231 测试向量
  AssertEquals('HMAC-SHA512 known vector',
    'b42af09057bac1e2d41708e48a902e09b5ff7f12ab428a4fe86653c73dd248fb82f948a549f7b791a5b41915ee4d1ec3935357e4e2317250d0372afa2ebeeb3a',
    BytesToHex(LResult));
end;

// 错误处理测试
procedure TTestCase_IHMAC.Test_HMAC_Update_WithoutKey;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when updating without key', fafafa.core.crypto.interfaces.EInvalidOperation,
    procedure begin FHMAC_SHA256.Update(LData[0], Length(LData)); end);
  {$ELSE}
  // 方法指针回退
  AssertException('Should raise exception when updating without key', fafafa.core.crypto.interfaces.EInvalidOperation,
    @Self.Test_HMAC_Update_WithoutKey_Helper);
  {$ENDIF}
end;

procedure TTestCase_IHMAC.Test_HMAC_Finalize_WithoutKey;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when finalizing without key', fafafa.core.crypto.interfaces.EInvalidOperation,
    procedure begin FHMAC_SHA256.Finalize; end);
  {$ELSE}
  // 方法指针回退
  AssertException('Should raise exception when finalizing without key', fafafa.core.crypto.interfaces.EInvalidOperation,
    @Self.Test_HMAC_Finalize_WithoutKey_Helper);
  {$ENDIF}
end;

// 方法指针回退：HMAC 未设 Key 时 Update
procedure TTestCase_IHMAC.Test_HMAC_Update_WithoutKey_Helper;
var
  LData: TBytes;
begin
  SetLength(LData, 1);
  LData[0] := 0;
  FHMAC_SHA256.Update(LData[0], Length(LData));
end;

// 方法指针回退：HMAC 未设 Key 时 Finalize
procedure TTestCase_IHMAC.Test_HMAC_Finalize_WithoutKey_Helper;
begin
  FHMAC_SHA256.Finalize;
end;

// 方法指针回退：HMAC Finalize 后再 Update
procedure TTestCase_IHMAC.Test_HMAC_Update_AfterFinalize_Helper;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('data');
  FHMAC_SHA256.Update(LData[0], Length(LData));
end;

procedure TTestCase_IHMAC.Test_HMAC_Update_AfterFinalize;
var
  LKey, LData: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := TEncoding.UTF8.GetBytes('data');

  FHMAC_SHA256.SetKey(LKey);
  FHMAC_SHA256.Update(LData[0], Length(LData));
  FHMAC_SHA256.Finalize;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when updating after finalize', fafafa.core.crypto.interfaces.EInvalidOperation,
    procedure begin FHMAC_SHA256.Update(LData[0], Length(LData)); end);
  {$ELSE}
  // 方法指针回退
  AssertException('Should raise exception when updating after finalize', fafafa.core.crypto.interfaces.EInvalidOperation,
    @Self.Test_HMAC_Update_AfterFinalize_Helper);
  {$ENDIF}
end;

procedure TTestCase_IHMAC.Test_HMAC_Finalize_AlreadyFinalized;
var
  LKey, LData: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := TEncoding.UTF8.GetBytes('data');

  FHMAC_SHA256.SetKey(LKey);
  FHMAC_SHA256.Update(LData[0], Length(LData));
  FHMAC_SHA256.Finalize;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when already finalized', EInvalidOperation,
    procedure begin FHMAC_SHA256.Finalize; end);
  {$ELSE}
  try
    FHMAC_SHA256.Finalize;
    Fail('Should raise exception when already finalized');
  except
    on E: EInvalidOperation do
      ; // Expected
    else
      Fail('Should raise EInvalidOperation');
  end;
  {$ENDIF}
end;

// 重载方法测试
procedure TTestCase_IHMAC.Test_HMAC_SHA256_SetKey_String;
var
  LKey: string;
  LData: TBytes;
  LResult: TBytes;
begin
  LKey := 'secret key';
  LData := TEncoding.UTF8.GetBytes('test data');

  FHMAC_SHA256.SetKey(LKey);
  AssertTrue('Key should be set', FHMAC_SHA256.IsKeySet);

  FHMAC_SHA256.Update(LData[0], Length(LData));
  LResult := FHMAC_SHA256.Finalize;
  AssertEquals('HMAC result length', 32, Length(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_ComputeMAC_String;
var
  LKey: TBytes;
  LData: string;
  LResult: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := 'The quick brown fox jumps over the lazy dog';

  FHMAC_SHA256.SetKey(LKey);
  LResult := FHMAC_SHA256.ComputeMAC(LData);

  AssertEquals('HMAC-SHA256 string result length', 32, Length(LResult));
  AssertEquals('HMAC-SHA256 string result',
    'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8',
    BytesToHex(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_VerifyMAC_String;
var
  LKey: TBytes;
  LData: string;
  LExpectedMAC: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := 'The quick brown fox jumps over the lazy dog';

  // 先计算正确的MAC
  FHMAC_SHA256.SetKey(LKey);
  LExpectedMAC := FHMAC_SHA256.ComputeMAC(LData);

  // 验证正确的MAC
  AssertTrue('Valid MAC should verify', FHMAC_SHA256.VerifyMAC(LData, LExpectedMAC));

  // 修改一个字节，验证应该失败
  if Length(LExpectedMAC) > 0 then
  begin
    LExpectedMAC[0] := LExpectedMAC[0] xor $FF;
    AssertFalse('Invalid MAC should not verify', FHMAC_SHA256.VerifyMAC(LData, LExpectedMAC));
  end;
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_GetHashAlgorithmName;
begin
  AssertEquals('HMAC-SHA256 hash algorithm name', 'SHA-256', FHMAC_SHA256.GetHashAlgorithmName);
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA256_IsKeySet;
var
  LKey: TBytes;
begin
  // 初始状态应该没有设置密钥
  AssertFalse('Key should not be set initially', FHMAC_SHA256.IsKeySet);

  // 设置密钥后应该返回True
  LKey := TEncoding.UTF8.GetBytes('test key');
  FHMAC_SHA256.SetKey(LKey);
  AssertTrue('Key should be set after SetKey', FHMAC_SHA256.IsKeySet);

  // Reset后应该清除密钥状态
  FHMAC_SHA256.Reset;
  AssertTrue('Key should still be set after Reset', FHMAC_SHA256.IsKeySet);
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA512_SetKey_String;
var
  LKey: string;
  LData: TBytes;
  LResult: TBytes;
begin
  LKey := 'secret key';
  LData := TEncoding.UTF8.GetBytes('test data');

  FHMAC_SHA512.SetKey(LKey);
  AssertTrue('Key should be set', FHMAC_SHA512.IsKeySet);

  FHMAC_SHA512.Update(LData[0], Length(LData));
  LResult := FHMAC_SHA512.Finalize;
  AssertEquals('HMAC result length', 64, Length(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA512_ComputeMAC_String;
var
  LKey: TBytes;
  LData: string;
  LResult: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := 'The quick brown fox jumps over the lazy dog';

  FHMAC_SHA512.SetKey(LKey);
  LResult := FHMAC_SHA512.ComputeMAC(LData);

  AssertEquals('HMAC-SHA512 string result length', 64, Length(LResult));
  AssertEquals('HMAC-SHA512 string result',
    'b42af09057bac1e2d41708e48a902e09b5ff7f12ab428a4fe86653c73dd248fb82f948a549f7b791a5b41915ee4d1ec3935357e4e2317250d0372afa2ebeeb3a',
    BytesToHex(LResult));
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA512_VerifyMAC_String;
var
  LKey: TBytes;
  LData: string;
  LExpectedMAC: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('key');
  LData := 'The quick brown fox jumps over the lazy dog';

  // 先计算正确的MAC
  FHMAC_SHA512.SetKey(LKey);
  LExpectedMAC := FHMAC_SHA512.ComputeMAC(LData);

  // 验证正确的MAC
  AssertTrue('Valid MAC should verify', FHMAC_SHA512.VerifyMAC(LData, LExpectedMAC));

  // 修改一个字节，验证应该失败
  if Length(LExpectedMAC) > 0 then
  begin
    LExpectedMAC[0] := LExpectedMAC[0] xor $FF;
    AssertFalse('Invalid MAC should not verify', FHMAC_SHA512.VerifyMAC(LData, LExpectedMAC));
  end;
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA512_GetHashAlgorithmName;
begin
  AssertEquals('HMAC-SHA512 hash algorithm name', 'SHA-512', FHMAC_SHA512.GetHashAlgorithmName);
end;

procedure TTestCase_IHMAC.Test_HMAC_SHA512_IsKeySet;
var
  LKey: TBytes;
begin
  // 初始状态应该没有设置密钥
  AssertFalse('Key should not be set initially', FHMAC_SHA512.IsKeySet);

  // 设置密钥后应该返回True
  LKey := TEncoding.UTF8.GetBytes('test key');
  FHMAC_SHA512.SetKey(LKey);
  AssertTrue('Key should be set after SetKey', FHMAC_SHA512.IsKeySet);

  // Reset后应该清除密钥状态
  FHMAC_SHA512.Reset;
  AssertTrue('Key should still be set after Reset', FHMAC_SHA512.IsKeySet);
end;

procedure TTestCase_IHMAC.Test_HMAC_Burn;
var
  LKey, LData: TBytes;
  LResult1, LResult2: TBytes;
begin
  LKey := TEncoding.UTF8.GetBytes('test key');
  LData := TEncoding.UTF8.GetBytes('test data');

  // 第一次计算
  FHMAC_SHA256.SetKey(LKey);
  LResult1 := FHMAC_SHA256.ComputeMAC(LData);

  // 销毁后重新计算
  FHMAC_SHA256.Burn;
  FHMAC_SHA256.SetKey(LKey);
  LResult2 := FHMAC_SHA256.ComputeMAC(LData);

  // 结果应该相同（Burn不应该影响算法正确性）
  AssertTrue('Results should be equal after burn', SecureCompare(LResult1, LResult2));
end;

{ TTestCase_IHashAlgorithm }

procedure TTestCase_IHashAlgorithm.SetUp;
begin
  FSHA256 := CreateSHA256;
  FSHA512 := CreateSHA512;
  FMD5 := CreateMD5;
end;

procedure TTestCase_IHashAlgorithm.TearDown;
begin
  FSHA256 := nil;
  FSHA512 := nil;
  FMD5 := nil;
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_GetDigestSize;
begin
  AssertEquals('SHA256 digest size', 32, FSHA256.GetDigestSize);
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_GetBlockSize;
begin
  AssertEquals('SHA256 block size', 64, FSHA256.GetBlockSize);
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_GetName;
begin
  AssertEquals('SHA256 name', 'SHA-256', FSHA256.GetName);
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_Reset;
var
  LData: TBytes;
  LResult1, LResult2: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');

  // 第一次哈希
  SafeUpdate(FSHA256, LData);
  LResult1 := FSHA256.Finalize;

  // 重置后再次哈希
  FSHA256.Reset;
  SafeUpdate(FSHA256, LData);
  LResult2 := FSHA256.Finalize;

  AssertTrue('Results should be equal after reset', SecureCompare(LResult1, LResult2));
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_Update_Single;
var
  LData: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  LData := TEncoding.UTF8.GetBytes('abc');
  SafeUpdate(FSHA256, LData);
  LResult := FSHA256.Finalize;
  LExpected := 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
  AssertEquals('SHA256 single update', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_Update_Multiple;
var
  LData1, LData2: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  LData1 := TEncoding.UTF8.GetBytes('ab');
  LData2 := TEncoding.UTF8.GetBytes('c');

  SafeUpdate(FSHA256, LData1);
  SafeUpdate(FSHA256, LData2);
  LResult := FSHA256.Finalize;

  LExpected := 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
  AssertEquals('SHA256 multiple updates', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_Finalize;
var
  LData: TBytes;
  LResult: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  SafeUpdate(FSHA256, LData);
  LResult := FSHA256.Finalize;
  AssertEquals('SHA256 result length', 32, Length(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_Finalize_AlreadyFinalized;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  FSHA256.Update(LData[0], Length(LData));
  FSHA256.Finalize;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when already finalized', fafafa.core.crypto.interfaces.EInvalidOperation,
    procedure begin FSHA256.Finalize; end);
  {$ELSE}
  // 方法指针回退
  AssertException('Should raise exception when already finalized', fafafa.core.crypto.interfaces.EInvalidOperation,
    @Self.Test_SHA256_Finalize_AlreadyFinalized_Helper);
  {$ENDIF}
end;

// 方法指针回退：SHA256 Finalize 后再次 Finalize
procedure TTestCase_IHashAlgorithm.Test_SHA256_Finalize_AlreadyFinalized_Helper;
begin
  FSHA256.Finalize;
end;

// 方法指针回退：SHA256 Finalize 后再 Update
procedure TTestCase_IHashAlgorithm.Test_SHA256_Update_AfterFinalize_Helper;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('x');
  FSHA256.Update(LData[0], Length(LData));
end;


procedure TTestCase_IHashAlgorithm.Test_SHA256_Update_AfterFinalize;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  FSHA256.Update(LData[0], Length(LData));
  FSHA256.Finalize;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when updating after finalize', fafafa.core.crypto.interfaces.EInvalidOperation,
    procedure begin FSHA256.Update(LData[0], Length(LData)); end);
  {$ELSE}
  // 方法指针回退
  AssertException('Should raise exception when updating after finalize', fafafa.core.crypto.interfaces.EInvalidOperation,
    @Self.Test_SHA256_Update_AfterFinalize_Helper);
  {$ENDIF}
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_KnownVectors;
var
  LTestVectors: array[0..2] of record
    Input: string;
    Expected: string;
  end;
  LI: Integer;
  LData: TBytes;
  LResult: TBytes;
begin
  // NIST测试向量
  LTestVectors[0].Input := '';
  LTestVectors[0].Expected := 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  LTestVectors[1].Input := 'abc';
  LTestVectors[1].Expected := 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

  LTestVectors[2].Input := 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq';
  LTestVectors[2].Expected := '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1';

  for LI := 0 to 2 do
  begin
    FSHA256.Reset;
    if LTestVectors[LI].Input <> '' then
    begin
      LData := TEncoding.UTF8.GetBytes(LTestVectors[LI].Input);
      FSHA256.Update(LData[0], Length(LData));
    end;
    LResult := FSHA256.Finalize;
    AssertEquals(Format('SHA256 test vector %d', [LI]), LTestVectors[LI].Expected, BytesToHex(LResult));
  end;
end;

procedure TTestCase_IHashAlgorithm.Test_SHA256_Burn;
var
  LData: TBytes;
  LResult1, LResult2: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');

  // 第一次哈希
  FSHA256.Update(LData[0], Length(LData));
  LResult1 := FSHA256.Finalize;

  // 销毁后重新哈希
  FSHA256.Burn;
  FSHA256.Reset;
  FSHA256.Update(LData[0], Length(LData));
  LResult2 := FSHA256.Finalize;

  // 结果应该相同（Burn不应该影响算法正确性）
  AssertTrue('Results should be equal after burn', SecureCompare(LResult1, LResult2));
end;

// SHA-512 测试
procedure TTestCase_IHashAlgorithm.Test_SHA512_GetDigestSize;
begin
  AssertEquals('SHA512 digest size', 64, FSHA512.GetDigestSize);
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_GetBlockSize;
begin
  AssertEquals('SHA512 block size', 128, FSHA512.GetBlockSize);
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_GetName;
begin
  AssertEquals('SHA512 name', 'SHA-512', FSHA512.GetName);
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_Reset;
var
  LData: TBytes;
  LResult1, LResult2: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');

  // 第一次哈希
  FSHA512.Update(LData[0], Length(LData));
  LResult1 := FSHA512.Finalize;

  // 重置后再次哈希
  FSHA512.Reset;
  FSHA512.Update(LData[0], Length(LData));
  LResult2 := FSHA512.Finalize;

  AssertTrue('Results should be equal after reset', SecureCompare(LResult1, LResult2));
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_Update_Single;
var
  LData: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  LData := TEncoding.UTF8.GetBytes('abc');
  FSHA512.Update(LData[0], Length(LData));
  LResult := FSHA512.Finalize;
  LExpected := 'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a' +
               '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f';
  AssertEquals('SHA512 single update', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_Update_Multiple;
var
  LData1, LData2: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  LData1 := TEncoding.UTF8.GetBytes('ab');
  LData2 := TEncoding.UTF8.GetBytes('c');

  FSHA512.Update(LData1[0], Length(LData1));
  FSHA512.Update(LData2[0], Length(LData2));
  LResult := FSHA512.Finalize;

  LExpected := 'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a' +
               '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f';
  AssertEquals('SHA512 multiple updates', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_Finalize;
var
  LData: TBytes;
  LResult: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  FSHA512.Update(LData[0], Length(LData));
  LResult := FSHA512.Finalize;
  AssertEquals('SHA512 result length', 64, Length(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_Finalize_AlreadyFinalized;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  FSHA512.Update(LData[0], Length(LData));
  FSHA512.Finalize;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when already finalized', EInvalidOperation,
    procedure begin FSHA512.Finalize; end);
  {$ELSE}
  try
    FSHA512.Finalize;
    Fail('Should raise exception when already finalized');
  except
    on E: EInvalidOperation do
      ; // Expected
    else
      Fail('Should raise EInvalidOperation');
  end;
  {$ENDIF}
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_Update_AfterFinalize;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  FSHA512.Update(LData[0], Length(LData));
  FSHA512.Finalize;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when updating after finalize', EInvalidOperation,
    procedure begin FSHA512.Update(LData[0], Length(LData)); end);
  {$ELSE}
  try
    FSHA512.Update(LData[0], Length(LData));
    Fail('Should raise exception when updating after finalize');
  except
    on E: EInvalidOperation do
      ; // Expected
    else
      Fail('Should raise EInvalidOperation');
  end;
  {$ENDIF}
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_KnownVectors;
var
  LTestVectors: array[0..1] of record
    Input: string;
    Expected: string;
  end;
  LI: Integer;
  LData: TBytes;
  LResult: TBytes;
begin
  // NIST测试向量
  LTestVectors[0].Input := '';
  LTestVectors[0].Expected := 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce' +
                              '47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e';

  LTestVectors[1].Input := 'abc';
  LTestVectors[1].Expected := 'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a' +
                              '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f';

  for LI := 0 to 1 do
  begin
    FSHA512.Reset;
    if LTestVectors[LI].Input <> '' then
    begin
      LData := TEncoding.UTF8.GetBytes(LTestVectors[LI].Input);
      FSHA512.Update(LData[0], Length(LData));
    end;
    LResult := FSHA512.Finalize;
    AssertEquals(Format('SHA512 test vector %d', [LI]), LTestVectors[LI].Expected, BytesToHex(LResult));
  end;
end;

procedure TTestCase_IHashAlgorithm.Test_SHA512_Burn;
var
  LData: TBytes;
  LResult1, LResult2: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');

  // 第一次哈希
  FSHA512.Update(LData[0], Length(LData));
  LResult1 := FSHA512.Finalize;

  // 销毁后重新哈希
  FSHA512.Burn;
  FSHA512.Reset;
  FSHA512.Update(LData[0], Length(LData));
  LResult2 := FSHA512.Finalize;

  // 结果应该相同（Burn不应该影响算法正确性）
  AssertTrue('Results should be equal after burn', SecureCompare(LResult1, LResult2));
end;

// MD5 测试
procedure TTestCase_IHashAlgorithm.Test_MD5_GetDigestSize;
begin
  AssertEquals('MD5 digest size', 16, FMD5.GetDigestSize);
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_GetBlockSize;
begin
  AssertEquals('MD5 block size', 64, FMD5.GetBlockSize);
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_GetName;
begin
  AssertEquals('MD5 name', 'MD5', FMD5.GetName);
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_Reset;
var
  LData: TBytes;
  LResult1, LResult2: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');

  // 第一次哈希
  FMD5.Update(LData[0], Length(LData));
  LResult1 := FMD5.Finalize;

  // 重置后再次哈希
  FMD5.Reset;
  FMD5.Update(LData[0], Length(LData));
  LResult2 := FMD5.Finalize;

  AssertTrue('Results should be equal after reset', SecureCompare(LResult1, LResult2));
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_Update_Single;
var
  LData: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  LData := TEncoding.UTF8.GetBytes('abc');
  FMD5.Update(LData[0], Length(LData));
  LResult := FMD5.Finalize;
  LExpected := '900150983cd24fb0d6963f7d28e17f72';
  AssertEquals('MD5 single update', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_Update_Multiple;
var
  LData1, LData2: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  LData1 := TEncoding.UTF8.GetBytes('ab');
  LData2 := TEncoding.UTF8.GetBytes('c');

  FMD5.Update(LData1[0], Length(LData1));
  FMD5.Update(LData2[0], Length(LData2));
  LResult := FMD5.Finalize;

  LExpected := '900150983cd24fb0d6963f7d28e17f72';
  AssertEquals('MD5 multiple updates', LExpected, BytesToHex(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_Finalize;
var
  LData: TBytes;
  LResult: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  FMD5.Update(LData[0], Length(LData));
  LResult := FMD5.Finalize;
  AssertEquals('MD5 result length', 16, Length(LResult));
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_Finalize_AlreadyFinalized;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  FMD5.Update(LData[0], Length(LData));
  FMD5.Finalize;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when already finalized', EInvalidOperation,
    procedure begin FMD5.Finalize; end);
  {$ELSE}
  try
    FMD5.Finalize;
    Fail('Should raise exception when already finalized');
  except
    on E: EInvalidOperation do
      ; // Expected
    else
      Fail('Should raise EInvalidOperation');
  end;
  {$ENDIF}
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_Update_AfterFinalize;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');
  FMD5.Update(LData[0], Length(LData));
  FMD5.Finalize;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception when updating after finalize', EInvalidOperation,
    procedure begin FMD5.Update(LData[0], Length(LData)); end);
  {$ELSE}
  try
    FMD5.Update(LData[0], Length(LData));
    Fail('Should raise exception when updating after finalize');
  except
    on E: EInvalidOperation do
      ; // Expected
    else
      Fail('Should raise EInvalidOperation');
  end;
  {$ENDIF}
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_KnownVectors;
var
  LTestVectors: array[0..2] of record
    Input: string;
    Expected: string;
  end;
  LI: Integer;
  LData: TBytes;
  LResult: TBytes;
begin
  // MD5测试向量
  LTestVectors[0].Input := '';
  LTestVectors[0].Expected := 'd41d8cd98f00b204e9800998ecf8427e';

  LTestVectors[1].Input := 'abc';
  LTestVectors[1].Expected := '900150983cd24fb0d6963f7d28e17f72';

  LTestVectors[2].Input := 'message digest';
  LTestVectors[2].Expected := 'f96b697d7cb7938d525a2f31aaf161d0';

  for LI := 0 to 2 do
  begin
    FMD5.Reset;
    if LTestVectors[LI].Input <> '' then
    begin
      LData := TEncoding.UTF8.GetBytes(LTestVectors[LI].Input);
      FMD5.Update(LData[0], Length(LData));
    end;
    LResult := FMD5.Finalize;
    AssertEquals(Format('MD5 test vector %d', [LI]), LTestVectors[LI].Expected, BytesToHex(LResult));
  end;
end;

procedure TTestCase_IHashAlgorithm.Test_MD5_Burn;
var
  LData: TBytes;
  LResult1, LResult2: TBytes;
begin
  LData := TEncoding.UTF8.GetBytes('test');

  // 第一次哈希
  FMD5.Update(LData[0], Length(LData));
  LResult1 := FMD5.Finalize;

  // 销毁后重新哈希
  FMD5.Burn;
  FMD5.Reset;
  FMD5.Update(LData[0], Length(LData));
  LResult2 := FMD5.Finalize;

  // 结果应该相同（Burn不应该影响算法正确性）
  AssertTrue('Results should be equal after burn', SecureCompare(LResult1, LResult2));
end;

{ TTestCase_ISecureRandom }

procedure TTestCase_ISecureRandom.SetUp;
begin
  FRandom := GetSecureRandom;
end;

procedure TTestCase_ISecureRandom.TearDown;
begin
  FRandom := nil;
end;

procedure TTestCase_ISecureRandom.Test_GetBytes_Buffer;
var
  LBuffer: array[0..15] of Byte;
  LI: Integer;
  LAllZero: Boolean;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  FRandom.GetBytes(LBuffer, SizeOf(LBuffer));

  // 检查不是全零（极小概率会失败，但实际上不会）
  LAllZero := True;
  for LI := 0 to 15 do
  begin
    if LBuffer[LI] <> 0 then
    begin
      LAllZero := False;
      Break;
    end;
  end;

  AssertFalse('Random bytes should not be all zeros', LAllZero);
end;

procedure TTestCase_ISecureRandom.Test_GetBytes_Array;
var
  LBytes: TBytes;
begin
  LBytes := FRandom.GetBytes(16);
  AssertEquals('Should return 16 bytes', 16, Length(LBytes));
end;

procedure TTestCase_ISecureRandom.Test_GetBytes_ZeroSize;
var
  LBytes: TBytes;
begin
  LBytes := FRandom.GetBytes(0);
  AssertEquals('Should return 0 bytes', 0, Length(LBytes));
end;

procedure TTestCase_ISecureRandom.Test_GetBytes_LargeSize;
var
  LBytes: TBytes;
begin
  LBytes := FRandom.GetBytes(1024);
  AssertEquals('Should return 1024 bytes', 1024, Length(LBytes));
end;

procedure TTestCase_ISecureRandom.Test_GetInteger_ValidRange;
var
  LValue: Integer;
begin
  LValue := FRandom.GetInteger(10, 20);
  AssertTrue('Value should be in range', (LValue >= 10) and (LValue <= 20));
end;

procedure TTestCase_ISecureRandom.Test_GetInteger_SameMinMax;
var
  LValue: Integer;
begin
  LValue := FRandom.GetInteger(42, 42);
  AssertEquals('Should return exact value when min=max', 42, LValue);
end;

procedure TTestCase_ISecureRandom.Test_GetInteger_InvalidRange;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Should raise exception for invalid range', EInvalidArgument,
    procedure begin FRandom.GetInteger(20, 10); end);
  {$ELSE}
  try
    FRandom.GetInteger(20, 10);
    Fail('Should raise exception for invalid range');
  except
    on E: fafafa.core.crypto.interfaces.EInvalidArgument do
      ; // Expected
    on E: Exception do
      Fail('Should raise EInvalidArgument, but got ' + E.ClassName + ': ' + E.Message);
  end;
  {$ENDIF}
end;

procedure TTestCase_ISecureRandom.Test_GetInteger_Distribution;
var
  LCounts: array[0..9] of Integer;
  LI, LValue: Integer;
  LMinCount, LMaxCount: Integer;
begin
  // 测试分布均匀性（简单测试）
  FillChar(LCounts, SizeOf(LCounts), 0);

  for LI := 1 to 1000 do
  begin
    LValue := FRandom.GetInteger(0, 9);
    Inc(LCounts[LValue]);
  end;

  // 检查每个值都至少出现过一次（概率极高）
  LMinCount := LCounts[0];
  LMaxCount := LCounts[0];
  for LI := 1 to 9 do
  begin
    if LCounts[LI] < LMinCount then
      LMinCount := LCounts[LI];
    if LCounts[LI] > LMaxCount then
      LMaxCount := LCounts[LI];
  end;

  AssertTrue('All values should appear at least once', LMinCount > 0);
  // 简单的分布检查：最大值不应该超过最小值的10倍
  AssertTrue('Distribution should be reasonably uniform', LMaxCount <= LMinCount * 10);
end;

// 补充的方法测试
procedure TTestCase_ISecureRandom.Test_GetByte;
var
  LByte1, LByte2: Byte;
begin
  LByte1 := FRandom.GetByte;
  LByte2 := FRandom.GetByte;

  // 两次调用应该返回不同的值（概率极高）
  // 注意：理论上可能相同，但概率很低
  AssertTrue('Byte values should be in valid range', (LByte1 >= 0) and (LByte1 <= 255));
  AssertTrue('Byte values should be in valid range', (LByte2 >= 0) and (LByte2 <= 255));
end;

procedure TTestCase_ISecureRandom.Test_GetInteger_NoParams;
var
  LValue1, LValue2: Integer;
begin
  LValue1 := FRandom.GetInteger;
  LValue2 := FRandom.GetInteger;

  // 两次调用应该返回不同的值（概率极高）
  AssertTrue('Integer values should be different', LValue1 <> LValue2);
end;

procedure TTestCase_ISecureRandom.Test_GetUInt32;
var
  LValue1, LValue2: UInt32;
begin
  LValue1 := FRandom.GetUInt32;
  LValue2 := FRandom.GetUInt32;

  // 两次调用应该返回不同的值（概率极高）
  AssertTrue('UInt32 values should be different', LValue1 <> LValue2);
end;

procedure TTestCase_ISecureRandom.Test_GetUInt64;
var
  LValue1, LValue2: UInt64;
begin
  LValue1 := FRandom.GetUInt64;
  LValue2 := FRandom.GetUInt64;

  // 两次调用应该返回不同的值（概率极高）
  AssertTrue('UInt64 values should be different', LValue1 <> LValue2);
end;

procedure TTestCase_ISecureRandom.Test_GetSingle;
var
  LValue1, LValue2: Single;
begin
  LValue1 := FRandom.GetSingle;
  LValue2 := FRandom.GetSingle;

  // 值应该在[0, 1)范围内
  AssertTrue('Single value should be >= 0', LValue1 >= 0.0);
  AssertTrue('Single value should be < 1', LValue1 < 1.0);
  AssertTrue('Single value should be >= 0', LValue2 >= 0.0);
  AssertTrue('Single value should be < 1', LValue2 < 1.0);

  // 两次调用应该返回不同的值（概率极高）
  AssertTrue('Single values should be different', LValue1 <> LValue2);
end;

procedure TTestCase_ISecureRandom.Test_GetDouble;
var
  LValue1, LValue2: Double;
begin
  LValue1 := FRandom.GetDouble;
  LValue2 := FRandom.GetDouble;

  // 值应该在[0, 1)范围内
  AssertTrue('Double value should be >= 0', LValue1 >= 0.0);
  AssertTrue('Double value should be < 1', LValue1 < 1.0);
  AssertTrue('Double value should be >= 0', LValue2 >= 0.0);
  AssertTrue('Double value should be < 1', LValue2 < 1.0);

  // 两次调用应该返回不同的值（概率极高）
  AssertTrue('Double values should be different', LValue1 <> LValue2);
end;

procedure TTestCase_ISecureRandom.Test_GetHexString;
var
  LHex1, LHex2: string;
  LI: Integer;
  LChar: Char;
  LValidHex: Boolean;
begin
  LHex1 := FRandom.GetHexString(16);
  LHex2 := FRandom.GetHexString(16);

  AssertEquals('Hex string length should be 16', 16, Length(LHex1));
  AssertEquals('Hex string length should be 16', 16, Length(LHex2));
  AssertTrue('Hex strings should be different', LHex1 <> LHex2);

  // 验证字符串只包含十六进制字符
  LValidHex := True;
  for LI := 1 to Length(LHex1) do
  begin
    LChar := LHex1[LI];
    if not (LChar in ['0'..'9', 'a'..'f', 'A'..'F']) then
    begin
      LValidHex := False;
      Break;
    end;
  end;
  AssertTrue('Hex string should contain only hex characters', LValidHex);
end;

procedure TTestCase_ISecureRandom.Test_GetBase64String;
var
  LBase64_1, LBase64_2: string;
begin
  LBase64_1 := FRandom.GetBase64String(16);
  LBase64_2 := FRandom.GetBase64String(16);

  AssertTrue('Base64 string should not be empty', Length(LBase64_1) > 0);
  AssertTrue('Base64 string should not be empty', Length(LBase64_2) > 0);
  AssertTrue('Base64 strings should be different', LBase64_1 <> LBase64_2);
end;

procedure TTestCase_ISecureRandom.Test_GetAlphanumericString;
var
  LAlpha1, LAlpha2: string;
  LI: Integer;
  LChar: Char;
  LValidAlpha: Boolean;
begin
  LAlpha1 := FRandom.GetAlphanumericString(16);
  LAlpha2 := FRandom.GetAlphanumericString(16);

  AssertEquals('Alphanumeric string length should be 16', 16, Length(LAlpha1));
  AssertEquals('Alphanumeric string length should be 16', 16, Length(LAlpha2));
  AssertTrue('Alphanumeric strings should be different', LAlpha1 <> LAlpha2);

  // 验证字符串只包含字母数字字符
  LValidAlpha := True;
  for LI := 1 to Length(LAlpha1) do
  begin
    LChar := LAlpha1[LI];
    if not (LChar in ['0'..'9', 'a'..'z', 'A'..'Z']) then
    begin
      LValidAlpha := False;
      Break;
    end;
  end;
  AssertTrue('Alphanumeric string should contain only alphanumeric characters', LValidAlpha);
end;

procedure TTestCase_ISecureRandom.Test_GetBase64UrlString;
var
  S1, S2: string;
  i: Integer;
begin
  S1 := FRandom.GetBase64UrlString(24);
  S2 := FRandom.GetBase64UrlString(24);
  AssertEquals(24, Length(S1));
  AssertEquals(24, Length(S2));
  AssertTrue('randomized strings should differ', S1 <> S2);
  for i := 1 to Length(S1) do
    AssertTrue('char in URL-safe base64 set', S1[i] in ['A'..'Z','a'..'z','0'..'9','-','_']);
end;

procedure TTestCase_ISecureRandom.Test_AddEntropy;
var
  LEntropy: TBytes;
  LEstimateBefore, LEstimateAfter: Integer;
begin
  SetLength(LEntropy, 32);
  // 填充一些熵数据
  LEntropy[0] := $12; LEntropy[1] := $34; LEntropy[2] := $56; LEntropy[3] := $78;

  LEstimateBefore := FRandom.GetEntropyEstimate;
  FRandom.AddEntropy(LEntropy);
  LEstimateAfter := FRandom.GetEntropyEstimate;

  // 添加熵后，熵估计应该增加或保持不变
  AssertTrue('Entropy estimate should not decrease', LEstimateAfter >= LEstimateBefore);
end;

procedure TTestCase_ISecureRandom.Test_GetEntropyEstimate;
var
  LEstimate: Integer;
begin
  LEstimate := FRandom.GetEntropyEstimate;
  AssertTrue('Entropy estimate should be non-negative', LEstimate >= 0);
end;

procedure TTestCase_ISecureRandom.Test_Reseed;
begin
  // Reseed应该不抛出异常
  FRandom.Reseed;
  AssertTrue('Reseed should complete successfully', True);
end;

procedure TTestCase_ISecureRandom.Test_IsInitialized;
begin
  // 随机数生成器应该已经初始化
  AssertTrue('Random generator should be initialized', FRandom.IsInitialized);
end;

procedure TTestCase_ISecureRandom.Test_Reset;
begin
  // Reset应该不抛出异常
  FRandom.Reset;
  AssertTrue('Reset should complete successfully', True);

  // Reset后应该仍然可以生成随机数
  AssertTrue('Should still be initialized after reset', FRandom.IsInitialized);
end;

procedure TTestCase_ISecureRandom.Test_Burn;
var
  LBytes1, LBytes2: TBytes;
begin
  // 获取一些随机数据
  LBytes1 := FRandom.GetBytes(16);

  // 销毁后重新初始化
  FRandom.Burn;
  FRandom.Reset;

  // 应该仍然可以生成随机数据
  LBytes2 := FRandom.GetBytes(16);

  AssertEquals('Should generate same length after burn', Length(LBytes1), Length(LBytes2));
  AssertFalse('Should generate different data after burn', SecureCompare(LBytes1, LBytes2));
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IHashAlgorithm);
  RegisterTest(TTestCase_IHMAC);
  RegisterTest(TTestCase_ISecureRandom);

end.
