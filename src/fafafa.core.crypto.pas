{


  fafafa.core.crypto - 加密模块主单元

  本模块提供现代化的加密功能，包括：
  - 哈希算法 (SHA-256, SHA-512, MD5)
  - AEAD/对称加密 (AES-GCM, ChaCha20-Poly1305)
  - 分组模式 (AES-ECB/CBC/CTR)
  - 消息认证 (HMAC-SHA256/SHA512)
  - 密钥派生 (PBKDF2-SHA256/SHA512)
  - 安全随机数生成

  规划中（未实现/未公开）：
  - RSA、ECDSA、Ed25519、Argon2 等

  设计理念：
  - 安全优先：默认使用安全的算法和参数
  - 接口抽象：优先使用接口，支持可替换实现
  - 跨平台：支持 Windows/Linux/macOS
  - 易于使用：清晰的 API 设计
}

unit fafafa.core.crypto;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes,
  SysUtils,
  fafafa.core.base,

  // 共享接口定义
  fafafa.core.crypto.interfaces,

  // 细粒度哈希算法模块
  fafafa.core.crypto.hash.sha256,
  fafafa.core.crypto.hash.sha512,
  fafafa.core.crypto.hash.md5,
  fafafa.core.crypto.hash.xxhash32,
  fafafa.core.crypto.hash.xxhash64,
  {$IFDEF FAFAFA_CRYPTO_ENABLE_XXH3}
  fafafa.core.crypto.hash.xxh3_64,
  fafafa.core.crypto.hash.xxh3_128,
  {$ENDIF}

  // 细粒度对称加密模块
  fafafa.core.crypto.cipher.aes,
  fafafa.core.crypto.cipher.aes.cbc,

  // 消息认证和密钥派生
  fafafa.core.crypto.hmac,
  fafafa.core.crypto.kdf.pbkdf2,

  // 随机数生成和工具
  fafafa.core.crypto.random,
  fafafa.core.crypto.utils,
  fafafa.core.crypto.nonce,

  // 便捷安全 AEAD 接口
  fafafa.core.crypto.aead.safe;

type
  // ============================================================================
  // 重新导出共享类型和接口
  // ============================================================================

  TBytes = fafafa.core.crypto.interfaces.TBytes;

  // 异常类型
  ECrypto = fafafa.core.crypto.interfaces.ECrypto;
  ECryptoHash = fafafa.core.crypto.interfaces.ECryptoHash;
  ECryptoCipher = fafafa.core.crypto.interfaces.ECryptoCipher;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;
  EInvalidKey = fafafa.core.crypto.interfaces.EInvalidKey;
  EInvalidData = fafafa.core.crypto.interfaces.EInvalidData;

  // 核心接口
  IHashAlgorithm = fafafa.core.crypto.interfaces.IHashAlgorithm;
  ISymmetricCipher = fafafa.core.crypto.interfaces.ISymmetricCipher;
  IBlockCipher = fafafa.core.crypto.interfaces.IBlockCipher;
  IBlockCipherWithIV = fafafa.core.crypto.interfaces.IBlockCipherWithIV;
  IHMAC = fafafa.core.crypto.interfaces.IHMAC;
  IKeyDerivationFunction = fafafa.core.crypto.interfaces.IKeyDerivationFunction;
  ISecureRandom = fafafa.core.crypto.interfaces.ISecureRandom;
  IAEADCipher = fafafa.core.crypto.interfaces.IAEADCipher;

  // Legacy exception types for backward compatibility
  EDecryptionFailed = class(ECrypto) end;
  EVerificationFailed = class(ECrypto) end;

  // 未实现异常
  ENotSupported = class(ECore) end;

  // 重新导出utils模块的类型
  TPasswordStrength = fafafa.core.crypto.utils.TPasswordStrength;
  TPasswordPolicy = fafafa.core.crypto.utils.TPasswordPolicy;


  // Nonce Manager API
  type INonceManager = fafafa.core.crypto.nonce.INonceManager;
  function CreateNonceManager(AInstanceID: UInt32 = 0; ACounterStart: UInt64 = 0; AHistorySize: Integer = 1024): INonceManager;

  // 线程安全工厂（带内部锁）
  function CreateNonceManagerThreadSafe(AInstanceID: UInt32 = 0; ACounterStart: UInt64 = 0; AHistorySize: Integer = 1024): INonceManager;


  // Nonce helpers re-export
  function GenerateNonce12: TBytes;
  function ComposeGCMNonce12(AInstanceID: UInt32; ACounter: UInt64): TBytes;

  // AEAD safe combined helpers (re-export)
  function AES256GCM_Seal_Combined(const AKey, AAD, PT: TBytes; const NM: INonceManager): TBytes;
  function AES256GCM_Open_Combined(const AKey, AAD, Combined: TBytes): TBytes;
  function ChaCha20Poly1305_Seal_Combined(const AKey, AAD, PT: TBytes; const NM: INonceManager): TBytes;
  function ChaCha20Poly1305_Open_Combined(const AKey, AAD, Combined: TBytes): TBytes;
  function AES256GCM_Seal_Combined_TL(const AKey, AAD, PT: TBytes; const NM: INonceManager; TagLen: Integer): TBytes;
  function AES256GCM_Open_Combined_TL(const AKey, AAD, Combined: TBytes; TagLen: Integer): TBytes;










{**
 * 哈希算法工厂函数
 * Hash Algorithm Factory Functions
 *}

{**
 * CreateSHA256
 *
 * @desc
 *   Creates a new SHA-256 hash algorithm instance.
 *   创建新的SHA-256哈希算法实例.
 *
 * @returns
 *   A SHA-256 hash algorithm interface.
 *   SHA-256哈希算法接口.
 *}
function CreateSHA256: IHashAlgorithm;

{**
 * CreateSHA512
 *
 * @desc
 *   Creates a new SHA-512 hash algorithm instance.
 *   创建新的SHA-512哈希算法实例.
 *
 * @returns
 *   A SHA-512 hash algorithm interface.
 *   SHA-512哈希算法接口.
 *}
function CreateSHA512: IHashAlgorithm;

{**
 * CreateMD5
 *
 * @desc
 *   Creates an MD5 hash algorithm instance.
 *   创建MD5哈希算法实例.
 *}
function CreateMD5: IHashAlgorithm;

{**
 * CreateXXH32
 * 非加密哈希（校验/分片/哈希表用途），默认 seed=0
 *}
function CreateXXH32(ASeed: UInt32 = 0): IHashAlgorithm;

{**
 * CreateXXH64
 * 非加密哈希（校验/分片/哈希表用途），默认 seed=0
 *}
function CreateXXH64(ASeed: UInt64 = 0): IHashAlgorithm;
{$IFDEF FAFAFA_CRYPTO_ENABLE_XXH3}
function CreateXXH3_64(ASeed: UInt64 = 0): IHashAlgorithm;
function XXH3_64Hash(const AData: TBytes; ASeed: QWord = 0): TBytes;
function XXH3_128Hash(const AData: TBytes; ASeed: QWord = 0): TBytes;
{$ENDIF}

{**
 * 便利函数：一次性哈希计算
 * Convenience Functions: One-shot Hash Computation
 *}

{**
 * HashSHA256
 *
 * @desc
 *   Computes SHA-256 hash of the given data.
 *   计算给定数据的SHA-256哈希.
 *
 * @params
 *   AData - The data to hash.
 *          要哈希的数据.
 *
 * @returns
 *   The SHA-256 hash digest.
 *   SHA-256哈希摘要.
 *}
function HashSHA256(const AData: TBytes): TBytes; overload;
function HashSHA256(const AData: string): TBytes; overload;

{**
 * HashSHA512
 *
 * @desc
 *   Computes SHA-512 hash of the given data.
 *   计算给定数据的SHA-512哈希.
 *
 * @params
 *   AData - The data to hash.
 *          要哈希的数据.
 *
 * @returns
 *   The SHA-512 hash digest.
 *   SHA-512哈希摘要.
 *}
function HashSHA512(const AData: TBytes): TBytes; overload;
function HashSHA512(const AData: string): TBytes; overload;

{**
 * XXH32 便利函数（非加密哈希）
 *}
function XXH32Hash(const AData: TBytes; ASeed: UInt32 = 0): TBytes; overload;
function XXH32Hash(const AData: string; ASeed: UInt32 = 0): TBytes; overload;

{**
 * XXH64 便利函数（非加密哈希）
 *}
function XXH64Hash(const AData: TBytes; ASeed: UInt64 = 0): TBytes; overload;

  {$IFDEF FAFAFA_CRYPTO_ENABLE_XXH3}
  {**
   * XXH3-64 便利函数（当前仅 seed=0 支持；后续扩展）
   *}
  function XXH3_64Hash(const AData: TBytes; ASeed: UInt64 = 0): TBytes; overload;
  {$ENDIF}

function XXH64Hash(const AData: string; ASeed: UInt64 = 0): TBytes; overload;

{**
 * HMAC工厂函数
 * HMAC Factory Functions
 *}

{**
 * CreateHMAC_SHA256
 *
 * @desc
 *   Creates a new HMAC-SHA256 instance.
 *   创建新的HMAC-SHA256实例.
 *
 * @returns
 *   An HMAC-SHA256 interface.
 *   HMAC-SHA256接口.
 *}
function CreateHMAC_SHA256: IHMAC;

{**
 * CreateHMAC_SHA512
 *
 * @desc
 *   Creates a new HMAC-SHA512 instance.
 *   创建新的HMAC-SHA512实例.
 *
 * @returns
 *   An HMAC-SHA512 interface.
 *   HMAC-SHA512接口.
 *}
function CreateHMAC_SHA512: IHMAC;

{**
 * 便利函数：一次性HMAC计算
 * Convenience Functions: One-shot HMAC Computation
 *}

{**
 * HMAC_SHA256
 *
 * @desc
 *   Computes HMAC-SHA256 of the given key and data.
 *   计算给定密钥和数据的HMAC-SHA256.
 *
 * @params
 *   AKey - The secret key.
 *         密钥.
 *   AData - The data to authenticate.
 *          要认证的数据.
 *
 * @returns
 *   The HMAC-SHA256 authentication code.
 *   HMAC-SHA256认证码.
 *}
function HMAC_SHA256(const AKey, AData: TBytes): TBytes;

{**
 * HMAC_SHA512
 *
 * @desc
 *   Computes HMAC-SHA512 of the given key and data.
 *   计算给定密钥和数据的HMAC-SHA512.
 *
 * @params
 *   AKey - The secret key.
 *         密钥.
 *   AData - The data to authenticate.
 *          要认证的数据.
 *
 * @returns
 *   The HMAC-SHA512 authentication code.
 *   HMAC-SHA512认证码.
 *}
function HMAC_SHA512(const AKey, AData: TBytes): TBytes;

{**
 * 对称加密工厂函数
 * Symmetric Encryption Factory Functions
 *}

{**
 * CreateAES256GCM
 *
 * @desc
 *   创建 RFC 5116 风格的 AEAD(AES-256-GCM) 实例。
 *   - NonceSize: 12 bytes（推荐；务必确保相同 key 下 nonce 全局唯一，严禁重复）
 *   - TagSize: 16 bytes；Seal 返回 Ciphertext||Tag，长度 = |PT| + 16
 *   - Open 需要输入 Ciphertext||Tag；若鉴别失败抛 EInvalidData
 *
 * @returns
 *   IAEADCipher 接口；需先 SetKey，再可用 Seal/Open。
 *
 * @raises
 *   EInvalidArgument - 密钥/Nonce/AAD 参数非法（如长度不符）
 *   EInvalidData     - Open 鉴别失败
 *}
function CreateAES256GCM: IAEADCipher;

{**
 * CreateAES128
 *
 * @desc
 *   Creates a new AES-128 cipher instance.
 *   创建新的AES-128加密实例.
 *
 * @returns
 *   An AES-128 cipher interface.
 *   AES-128加密接口.
 *}
function CreateAES128: ISymmetricCipher;

{**
 * CreateAES256
 *
 * @desc
 *   Creates a new AES-256 cipher instance.
 *   创建新的AES-256加密实例.
 *
 * @returns
 *   An AES-256 cipher interface.
 *   AES-256加密接口.
 *}
function CreateAES256: ISymmetricCipher;

{**
 * CreateAES128_CBC
 *
 * @desc
 *   Creates a new AES-128-CBC cipher instance.
 *   创建新的AES-128-CBC加密实例.
 *
 * @returns
 *   An AES-128-CBC cipher interface.
 *   AES-128-CBC加密接口.
 *}
function CreateAES128_CBC: IBlockCipherWithIV;

{**
 * CreateAES256_CBC
 *
 * @desc
 *   Creates a new AES-256-CBC cipher instance.
 *   创建新的AES-256-CBC加密实例.
 *
 * @returns
 *   An AES-256-CBC cipher interface.
 *   AES-256-CBC加密接口.
 *}
function CreateAES256_CBC: IBlockCipherWithIV;

{**
 * 密钥派生工厂函数
 * Key Derivation Factory Functions
 *}

{**
 * CreatePBKDF2
 *
 * @desc
 *   Creates a new PBKDF2 key derivation function instance.
 *   创建新的PBKDF2密钥派生函数实例.
 *
 * @returns
 *   A PBKDF2 key derivation function interface.
 *   PBKDF2密钥派生函数接口.
 *}
function CreatePBKDF2: IKeyDerivationFunction;

{**
 * CreatePBKDF2_SHA256
 *
 * @desc
 *   Creates a new PBKDF2-SHA256 key derivation function instance.
 *   创建新的PBKDF2-SHA256密钥派生函数实例.
 *
 * @returns
 *   A PBKDF2-SHA256 key derivation function interface.
 *   PBKDF2-SHA256密钥派生函数接口.
 *}
function CreatePBKDF2_SHA256: IKeyDerivationFunction;

{**
 * CreatePBKDF2_SHA512
 *
 * @desc
 *   Creates a new PBKDF2-SHA512 key derivation function instance.
 *   创建新的PBKDF2-SHA512密钥派生函数实例.
 *
 * @returns
 *   A PBKDF2-SHA512 key derivation function interface.
 *   PBKDF2-SHA512密钥派生函数接口.
 *}
function CreatePBKDF2_SHA512: IKeyDerivationFunction;

{**
 * 便利函数：PBKDF2密钥派生
 * Convenience Functions: PBKDF2 Key Derivation
 *}

{**
 * PBKDF2_SHA256
 *
 * @desc
 *   Derives a key using PBKDF2-SHA256.
 *   使用PBKDF2-SHA256派生密钥.
 *
 * @params
 *   APassword - The password string.
 *              密码字符串.
 *   ASalt - The salt bytes.
 *          盐值字节.
 *   AIterations - Number of iterations.
 *                迭代次数.
 *   AKeyLength - Desired key length in bytes.
 *               期望的密钥长度（字节）.
 *
 * @returns
 *   The derived key.
 *   派生的密钥.
 *}
function PBKDF2_SHA256(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes; overload;

{**
 * PBKDF2_SHA512
 *
 * @desc
 *   Derives a key using PBKDF2-SHA512.
 *   使用PBKDF2-SHA512派生密钥.
 *
 * @params
 *   APassword - The password string.
 *              密码字符串.
 *   ASalt - The salt bytes.
 *          盐值字节.
 *   AIterations - Number of iterations.
 *                迭代次数.
 *   AKeyLength - Desired key length in bytes.
 *               期望的密钥长度（字节）.
 *
 * @returns
 *   The derived key.
 *   派生的密钥.
 *}
function PBKDF2_SHA512(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes; overload;

{**
 * PBKDF2_SHA256
 *
 * @desc
 *   Derives a key using PBKDF2-SHA256 with a default recommended configuration.
 *   使用PBKDF2-SHA256派生密钥（默认推荐参数）.
 *
 * @params
 *   APassword - The password string. 密码字符串.
 *   ASalt     - The salt bytes. 盐值字节（建议>=16字节）.
 *   AKeyLength- Desired key length in bytes. 期望的密钥长度（字节）.
 *
 * @returns
 *   The derived key. 派生的密钥.
 *
 * @raises
 *   EInvalidArgument - when password/salt is empty, key length <= 0, or
 *   iterations below minimum defined by implementation. Default iterations in facade overload = cPBKDF2DefaultIterations (see settings).
 *}
function PBKDF2_SHA256(const APassword: string; const ASalt: TBytes; AKeyLength: Integer): TBytes; overload;

{**
 * PBKDF2_SHA512
 *
 * @desc
 *   Derives a key using PBKDF2-SHA512 with a default recommended configuration.
 *   使用PBKDF2-SHA512派生密钥（默认推荐参数）.
 *
 * @params
 *   APassword - The password string. 密码字符串.
 *   ASalt     - The salt bytes. 盐值字节（建议>=16字节）.
 *   AKeyLength- Desired key length in bytes. 期望的密钥长度（字节）.
 *
 * @returns
 *   The derived key. 派生的密钥.
 *
 * @raises
 *   EInvalidArgument - when password/salt is empty, key length <= 0, or
 *   iterations below minimum defined by implementation. Default iterations in facade overload = cPBKDF2DefaultIterations (see settings).
 *}
function PBKDF2_SHA512(const APassword: string; const ASalt: TBytes; AKeyLength: Integer): TBytes; overload;


  {**
   * HKDF_SHA256
   *
   * @desc
   *   HMAC-based Extract-and-Expand Key Derivation Function (RFC 5869), SHA-256.
   *   使用 HMAC-SHA256 的 HKDF（提取+扩展）。
   *
   * @params
   *   IKM  - Input keying material. 输入密钥材料。
   *   Salt - 可选盐值；为空时按 RFC 以 HashLen 个 0 代替。
   *   Info - 可选上下文信息；可为空。
   *   L    - 输出 OKM 长度（字节）。范围 (0, 255*HashLen]。
   *
   * @raises
   *   EInvalidArgument - 当 L<=0 或 L>255*HashLen 时。
   *}
  function HKDF_SHA256(const IKM, Salt, Info: TBytes; L: Integer): TBytes;

  {**
   * HKDF_SHA512
   * @see HKDF_SHA256 描述，底层哈希改为 SHA-512。
   *}
  function HKDF_SHA512(const IKM, Salt, Info: TBytes; L: Integer): TBytes;

  {**
   * CreateChaCha20Poly1305
   *
   * @desc
   *   创建 RFC 7539/8439 的 AEAD(ChaCha20-Poly1305) 实例。
   *   - NonceSize: 12 bytes（RFC 8439 建议；务必确保相同 key 下 nonce 全局唯一，严禁重复）
   *   - TagSize: 16 bytes；Seal 返回 Ciphertext||Tag，长度 = |PT| + 16
   *   - Open 需要输入 Ciphertext||Tag；若鉴别失败抛 EInvalidData
   *
   * @returns
   *   IAEADCipher 接口；需先 SetKey，再可用 Seal/Open。
   *
   * @raises
   *   EInvalidArgument - 密钥/Nonce/AAD 参数非法（如长度不符）
   *   EInvalidData     - Open 鉴别失败
   *}
  function CreateChaCha20Poly1305: IAEADCipher;


{**
 * 安全随机数生成器
 * Secure Random Number Generator
 *}

{**
 * GetSecureRandom
 *
 * @desc
 *   Returns the global secure random number generator instance.
 *   返回全局安全随机数生成器实例.
 *
 * @returns
 *   A secure random number generator interface.
 *   安全随机数生成器接口.
 *}
function GetSecureRandom: ISecureRandom;

{**
 * 便利函数：安全随机数生成
 * Convenience Functions: Secure Random Generation
 *}

{**
 * GenerateRandomBytes
 *
 * @desc
 *   Generates cryptographically secure random bytes.
 *   生成加密安全的随机字节.
 *
 * @params
 *   ASize - The number of bytes to generate.
 *          要生成的字节数.
 *
 * @returns
 *   Random bytes.
 *   随机字节.
 *}
function GenerateRandomBytes(ASize: Integer): TBytes;

{**
 * GenerateRandomInteger
 *
 * @desc
 *   Generates a cryptographically secure random integer.
 *   生成加密安全的随机整数.
 *
 * @params
 *   AMin - Minimum value (inclusive).
 *         最小值（包含）.
 *   AMax - Maximum value (inclusive).
 *         最大值（包含）.
 *
 * @returns
 *   A random integer.
 *   随机整数.
 *}
function GenerateRandomInteger(AMin, AMax: Integer): Integer;

{**
 * GenerateBase64UrlString
 *
 * @desc
 *   Generates a URL-safe Base64-character random string (no padding), suitable for tokens.
 *   生成 URL-safe Base64 字符集的随机字符串（无填充），适合作为令牌/标识符。
 *
 * @params
 *   ALength - Desired string length.
 *            目标字符串长度。
 *
 * @returns
 *   Random Base64-URL string.
 *   随机的 Base64-URL 字符串。
 *}
function GenerateBase64UrlString(ALength: Integer): string;

{**
 * 工具函数
 * Utility Functions
 *}

{**
 * BytesToHex
 *
 * @desc
 *   Converts bytes to hexadecimal string.
 *   将字节转换为十六进制字符串.
 *
 * @params
 *   ABytes - The bytes to convert.
 *           要转换的字节.
 *
 * @returns
 *   Hexadecimal string representation.
 *   十六进制字符串表示.
 *}
function BytesToHex(const ABytes: TBytes): string;

{**
 * HexToBytes
 *
 * @desc
 *   Converts hexadecimal string to bytes.
 *   将十六进制字符串转换为字节.
 *
 * @params
 *   AHex - The hexadecimal string.
 *         十六进制字符串.
 *
 * @returns
 *   The bytes.
 *   字节数组.
 *}
function HexToBytes(const AHex: string): TBytes;

{**
 * SecureCompare
 *
 * @desc
 *   Performs constant-time comparison of two byte arrays.
 *   对两个字节数组进行常量时间比较.
 *
 * @params
 *   ABytes1 - First byte array.
 *            第一个字节数组.
 *   ABytes2 - Second byte array.
 *            第二个字节数组.
 *
 * @returns
 *   True if arrays are equal, false otherwise.
 *   如果数组相等返回True，否则返回False.
 *}
function SecureCompare(const ABytes1, ABytes2: TBytes): Boolean;

{**
 * SecureZero
 *
 * @desc
 *   Securely zeros out memory to prevent data leakage.
 *   安全地清零内存以防止数据泄露.
 *
 * @params
 *   ABuffer - The buffer to zero.
 *            要清零的缓冲区.
 *   ASize - The size of the buffer.
 *          缓冲区大小.
 *}
procedure SecureZero(var ABuffer; ASize: Integer);

{**
 * 安全工具函数
 * Security Utility Functions
 *}

function ConstantTimeCompare(const AData1, AData2: TBytes): Boolean;
function ConstantTimeStringCompare(const AStr1, AStr2: string): Boolean;
procedure SecureZeroMemory(ABuffer: Pointer; ASize: Integer);
procedure SecureZeroBytes(var AData: TBytes);
procedure SecureZeroString(var AStr: string);
{**
 * 密码与口令工具（可能抛出的异常）
 * - GenerateSecurePassword: 当长度<=0；未启用任何字符类别；长度<启用类别数时抛 EInvalidArgument
 * - GeneratePassphrase: 当词数<=0 时抛 EInvalidArgument
 *}
function CheckPasswordStrength(const APassword: string): TPasswordStrength;
function ValidatePassword(const APassword: string; const APolicy: TPasswordPolicy): Boolean;
function GetPasswordStrengthDescription(AStrength: TPasswordStrength): string;
function GenerateSecurePassword(ALength: Integer;
  AIncludeUppercase: Boolean = True;
  AIncludeLowercase: Boolean = True;
  AIncludeDigits: Boolean = True;
  AIncludeSymbols: Boolean = True): string;
function GeneratePassphrase(AWordCount: Integer = 4; const ASeparator: string = '-'): string;
function GetDefaultPasswordPolicy: TPasswordPolicy;
function GetStrictPasswordPolicy: TPasswordPolicy;

implementation

uses
  fafafa.core.bytes,
  fafafa.core.crypto.aead.gcm,
  fafafa.core.crypto.aead.chacha20poly1305
  {$IFDEF FAFAFA_CRYPTO_ENABLE_XXH3}
  , fafafa.core.crypto.hash.xxh3_64
  , fafafa.core.crypto.hash.xxh3_128
  {$ENDIF}
  ;
// Re-exported AEAD safe helpers
function AES256GCM_Seal_Combined(const AKey, AAD, PT: TBytes; const NM: INonceManager): TBytes;
begin
  Result := fafafa.core.crypto.aead.safe.AES256GCM_Seal_Combined(AKey, AAD, PT, NM);
end;

function AES256GCM_Open_Combined(const AKey, AAD, Combined: TBytes): TBytes;
begin
  Result := fafafa.core.crypto.aead.safe.AES256GCM_Open_Combined(AKey, AAD, Combined);
end;

function ChaCha20Poly1305_Seal_Combined(const AKey, AAD, PT: TBytes; const NM: INonceManager): TBytes;
begin
  Result := fafafa.core.crypto.aead.safe.ChaCha20Poly1305_Seal_Combined(AKey, AAD, PT, NM);
end;

function AES256GCM_Seal_Combined_TL(const AKey, AAD, PT: TBytes; const NM: INonceManager; TagLen: Integer): TBytes;
begin
  Result := fafafa.core.crypto.aead.safe.AES256GCM_Seal_Combined_TL(AKey, AAD, PT, NM, TagLen);
end;

function AES256GCM_Open_Combined_TL(const AKey, AAD, Combined: TBytes; TagLen: Integer): TBytes;
begin
  Result := fafafa.core.crypto.aead.safe.AES256GCM_Open_Combined_TL(AKey, AAD, Combined, TagLen);
end;


function ChaCha20Poly1305_Open_Combined(const AKey, AAD, Combined: TBytes): TBytes;
begin
  Result := fafafa.core.crypto.aead.safe.ChaCha20Poly1305_Open_Combined(AKey, AAD, Combined);
end;


function GenerateNonce12: TBytes;
begin
  Result := fafafa.core.crypto.utils.GenerateNonce12;
end;

function CreateNonceManager(AInstanceID: UInt32; ACounterStart: UInt64; AHistorySize: Integer): INonceManager;
begin
  Result := fafafa.core.crypto.nonce.CreateNonceManager_Impl(AInstanceID, ACounterStart, AHistorySize);
end;


function CreateNonceManagerThreadSafe(AInstanceID: UInt32; ACounterStart: UInt64; AHistorySize: Integer): INonceManager;
begin
  Result := fafafa.core.crypto.nonce.CreateNonceManagerThreadSafe_Impl(AInstanceID, ACounterStart, AHistorySize);
end;

function ComposeGCMNonce12(AInstanceID: UInt32; ACounter: UInt64): TBytes;
begin
  Result := fafafa.core.crypto.utils.ComposeGCMNonce12(AInstanceID, ACounter);
end;

{**
 * 哈希算法工厂函数实现
 *}

function CreateSHA256: IHashAlgorithm;
begin
  Result := fafafa.core.crypto.hash.sha256.CreateSHA256;
end;

function CreateSHA512: IHashAlgorithm;
begin
  Result := fafafa.core.crypto.hash.sha512.CreateSHA512;
end;

function CreateMD5: IHashAlgorithm;
begin
  Result := fafafa.core.crypto.hash.md5.CreateMD5;
end;

function CreateXXH32(ASeed: UInt32): IHashAlgorithm;
begin
  Result := fafafa.core.crypto.hash.xxhash32.CreateXXH32(ASeed);
end;

function CreateXXH64(ASeed: UInt64): IHashAlgorithm;
begin
  Result := fafafa.core.crypto.hash.xxhash64.CreateXXH64(ASeed);
end;

{$IFDEF FAFAFA_CRYPTO_ENABLE_XXH3}
function CreateXXH3_64(ASeed: UInt64): IHashAlgorithm;
begin
  Result := fafafa.core.crypto.hash.xxh3_64.CreateXXH3_64(ASeed);
end;
{$ENDIF}

{**
 * 便利函数：一次性哈希计算实现
 *}

function HashSHA256(const AData: TBytes): TBytes;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateSHA256;
  if Length(AData) > 0 then
    LHash.Update(AData[0], Length(AData));
  Result := LHash.Finalize;
end;

function HashSHA256(const AData: string): TBytes;
var
  U: UTF8String;
  LBytes: TBytes;
begin
  SetLength(LBytes, 0);
  U := UTF8String(AData);
  if Length(U) > 0 then
  begin
    SetLength(LBytes, Length(U));
    Move(Pointer(U)^, LBytes[0], Length(U));
  end;
  Result := HashSHA256(LBytes);
  if Length(LBytes) > 0 then FillChar(LBytes[0], Length(LBytes), 0);
end;

function HashSHA512(const AData: TBytes): TBytes;
var
  LHash: IHashAlgorithm;
begin
  LHash := CreateSHA512;
  if Length(AData) > 0 then
    LHash.Update(AData[0], Length(AData));
  Result := LHash.Finalize;
end;

function HashSHA512(const AData: string): TBytes;
var
  U: UTF8String;
  LBytes: TBytes;
begin
  SetLength(LBytes, 0);
  U := UTF8String(AData);
  if Length(U) > 0 then
  begin
    SetLength(LBytes, Length(U));
    Move(Pointer(U)^, LBytes[0], Length(U));
  end;
  Result := HashSHA512(LBytes);
  if Length(LBytes) > 0 then FillChar(LBytes[0], Length(LBytes), 0);
end;

function XXH32Hash(const AData: TBytes; ASeed: UInt32): TBytes;
begin
  Result := fafafa.core.crypto.hash.xxhash32.XXH32Hash(AData, ASeed);
end;

function XXH32Hash(const AData: string; ASeed: UInt32): TBytes;
begin
  Result := fafafa.core.crypto.hash.xxhash32.XXH32Hash(AData, ASeed);
end;

function XXH64Hash(const AData: TBytes; ASeed: UInt64): TBytes;
begin
  Result := fafafa.core.crypto.hash.xxhash64.XXH64Hash(AData, ASeed);
end;

{$IFDEF FAFAFA_CRYPTO_ENABLE_XXH3}
function XXH3_64Hash(const AData: TBytes; ASeed: UInt64): TBytes;
begin
  Result := fafafa.core.crypto.hash.xxh3_64.XXH3_64Hash(AData, ASeed);
end;

function XXH3_128Hash(const AData: TBytes; ASeed: UInt64): TBytes;
begin
  Result := fafafa.core.crypto.hash.xxh3_128.XXH3_128Hash(AData, ASeed);
end;
{$ENDIF}


function XXH64Hash(const AData: string; ASeed: UInt64): TBytes;
begin
  Result := fafafa.core.crypto.hash.xxhash64.XXH64Hash(AData, ASeed);
end;



{**
 * HMAC工厂函数实现
 *}

function CreateHMAC_SHA256: IHMAC;
begin
  Result := fafafa.core.crypto.hmac.CreateHMAC_SHA256;
end;

function CreateHMAC_SHA512: IHMAC;
begin
  Result := fafafa.core.crypto.hmac.CreateHMAC_SHA512;
end;

{**
 * 便利函数：一次性HMAC计算实现
 *}

function HMAC_SHA256(const AKey, AData: TBytes): TBytes;
begin
  Result := fafafa.core.crypto.hmac.HMAC_SHA256(AKey, AData);
end;

function HMAC_SHA512(const AKey, AData: TBytes): TBytes;
begin
  Result := fafafa.core.crypto.hmac.HMAC_SHA512(AKey, AData);
end;

{**
 * 对称加密工厂函数实现
 * 注意：门面仅做工厂转发，不暴露 *_Impl，不包含任何算法逻辑或平台细节。
 *}

{**
 * CreateAES256GCM
 * NonceSize = 12 字节；Tag 长度固定 16 字节（Overhead=16）。
 * 使用顺序：SetKey -> Seal/Open；Open 鉴别失败时抛 EInvalidData。
 *}
function CreateAES256GCM: IAEADCipher;
begin
  Result := fafafa.core.crypto.aead.gcm.CreateAES256GCM_Impl;
end;

{**
 * AES工厂函数实现
 *}

function CreateAES128: ISymmetricCipher;
begin
  Result := fafafa.core.crypto.cipher.aes.CreateAES128;
end;


{**
 * CreateChaCha20Poly1305
 * NonceSize = 12 字节；Tag 长度固定 16 字节（Overhead=16）。
 * 使用顺序：SetKey -> Seal/Open；Open 鉴别失败时抛 EInvalidData。
 *}
function CreateChaCha20Poly1305: IAEADCipher;
begin
  Result := fafafa.core.crypto.aead.chacha20poly1305.CreateChaCha20Poly1305_Impl;
end;

function CreateAES256: ISymmetricCipher;
begin
  Result := fafafa.core.crypto.cipher.aes.CreateAES256;
end;

function CreateAES128_CBC: IBlockCipherWithIV;
begin
  Result := fafafa.core.crypto.cipher.aes.cbc.CreateAES128_CBC;
end;


function PBKDF2_SHA256(const APassword: string; const ASalt: TBytes; AKeyLength: Integer): TBytes; overload;
begin
  // 默认推荐迭代次数（更安全的推荐值）
  Result := fafafa.core.crypto.kdf.pbkdf2.PBKDF2_SHA256(APassword, ASalt, cPBKDF2DefaultIterations, AKeyLength);
end;

function PBKDF2_SHA512(const APassword: string; const ASalt: TBytes; AKeyLength: Integer): TBytes; overload;
begin
  // 默认推荐迭代次数（更安全的推荐值）
  Result := fafafa.core.crypto.kdf.pbkdf2.PBKDF2_SHA512(APassword, ASalt, cPBKDF2DefaultIterations, AKeyLength);
end;



function HKDF_SHA256(const IKM, Salt, Info: TBytes; L: Integer): TBytes;
var
  PRK, T, OKM, Block: TBytes;
  H: IHMAC;
  HashLen, N, I: Integer;
  SaltUsed: TBytes;
  LPos: Integer;
begin
  // 初始化受管类型，避免未初始化警告
  PRK := nil; T := nil; OKM := nil; Block := nil; SaltUsed := nil;
  // 参数校验：L in (0, 255*HashLen]
  H := fafafa.core.crypto.hmac.CreateHMAC_SHA256;
  HashLen := H.GetDigestSize;
  if (L <= 0) or (L > 255 * HashLen) then
    raise EInvalidArgument.Create('HKDF: invalid length');

  // Extract: PRK = HMAC(Salt, IKM) ; Salt 为空 -> HashLen 个 0
  if Length(Salt) = 0 then begin
    SetLength(SaltUsed, HashLen);
    FillChar(SaltUsed[0], HashLen, 0);
  end else
    SaltUsed := Copy(Salt, 0, Length(Salt));
  H.SetKey(SaltUsed);
  PRK := H.ComputeMAC(IKM);

  // Expand: OKM = T(1) || T(2) || ... ; T(i) = HMAC(PRK, T(i-1) || Info || i)
  N := (L + HashLen - 1) div HashLen;
  SetLength(OKM, 0); SetLength(T, 0);
  H.SetKey(PRK);
  for I := 1 to N do begin
    // 组合数据
    SetLength(Block, Length(T) + Length(Info) + 1);
    if Length(T) > 0 then Move(T[0], Block[0], Length(T));
    if Length(Info) > 0 then Move(Info[0], Block[Length(T)], Length(Info));
    Block[Length(T) + Length(Info)] := Byte(I);

    T := H.ComputeMAC(Block);
    // append T to OKM
    LPos := Length(OKM);
    SetLength(OKM, LPos + Length(T));
    if Length(T) > 0 then Move(T[0], OKM[LPos], Length(T));
  end;

  SetLength(OKM, L);
  Result := OKM;

  // 清理敏感材料
  H.Burn;
  if Length(PRK) > 0 then FillChar(PRK[0], Length(PRK), 0);
  if Length(T) > 0 then FillChar(T[0], Length(T), 0);
  if Length(Block) > 0 then FillChar(Block[0], Length(Block), 0);
end;

function HKDF_SHA512(const IKM, Salt, Info: TBytes; L: Integer): TBytes;
var
  PRK, T, OKM, Block: TBytes;
  H: IHMAC;
  HashLen, N, I: Integer;
  SaltUsed: TBytes;
  LPos2: Integer;
begin
  // 初始化受管类型，避免未初始化警告
  PRK := nil; T := nil; OKM := nil; Block := nil; SaltUsed := nil;
  // 参数校验：L in (0, 255*HashLen]
  H := fafafa.core.crypto.hmac.CreateHMAC_SHA512;
  HashLen := H.GetDigestSize;
  if (L <= 0) or (L > 255 * HashLen) then
    raise EInvalidArgument.Create('HKDF: invalid length');

  if Length(Salt) = 0 then begin
    SetLength(SaltUsed, HashLen);
    FillChar(SaltUsed[0], HashLen, 0);
  end else
    SaltUsed := Copy(Salt, 0, Length(Salt));
  H.SetKey(SaltUsed);
  PRK := H.ComputeMAC(IKM);

  N := (L + HashLen - 1) div HashLen;
  SetLength(OKM, 0); SetLength(T, 0);
  H.SetKey(PRK);
  for I := 1 to N do begin
    SetLength(Block, Length(T) + Length(Info) + 1);
    if Length(T) > 0 then Move(T[0], Block[0], Length(T));
    if Length(Info) > 0 then Move(Info[0], Block[Length(T)], Length(Info));
    Block[Length(T) + Length(Info)] := Byte(I);

    T := H.ComputeMAC(Block);
    // append T to OKM
    LPos2 := Length(OKM);
    SetLength(OKM, LPos2 + Length(T));
    if Length(T) > 0 then Move(T[0], OKM[LPos2], Length(T));
  end;

  SetLength(OKM, L);
  Result := OKM;

  H.Burn;
  if Length(PRK) > 0 then FillChar(PRK[0], Length(PRK), 0);
  if Length(T) > 0 then FillChar(T[0], Length(T), 0);
  if Length(Block) > 0 then FillChar(Block[0], Length(Block), 0);
end;

function CreateAES256_CBC: IBlockCipherWithIV;
begin
  Result := fafafa.core.crypto.cipher.aes.cbc.CreateAES256_CBC;
end;



{**
 * 密钥派生工厂函数实现
 *}

function CreatePBKDF2: IKeyDerivationFunction;
begin
  Result := CreatePBKDF2_SHA256; // 默认使用SHA-256
end;

{**
 * PBKDF2工厂函数实现
 *}

function CreatePBKDF2_SHA256: IKeyDerivationFunction;
begin
  Result := fafafa.core.crypto.kdf.pbkdf2.CreatePBKDF2_SHA256;
end;

function CreatePBKDF2_SHA512: IKeyDerivationFunction;
begin
  Result := fafafa.core.crypto.kdf.pbkdf2.CreatePBKDF2_SHA512;
end;

{**
 * 便利函数：PBKDF2密钥派生实现
 *}

function PBKDF2_SHA256(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes; overload;
begin
  Result := fafafa.core.crypto.kdf.pbkdf2.PBKDF2_SHA256(APassword, ASalt, AIterations, AKeyLength);
end;

function PBKDF2_SHA512(const APassword: string; const ASalt: TBytes;
  AIterations: Integer; AKeyLength: Integer): TBytes; overload;
begin
  Result := fafafa.core.crypto.kdf.pbkdf2.PBKDF2_SHA512(APassword, ASalt, AIterations, AKeyLength);
end;

{**
 * 安全随机数生成器实现
 *}

function GetSecureRandom: ISecureRandom;
begin
  Result := fafafa.core.crypto.random.GetSecureRandom;
end;

{**
 * 便利函数：安全随机数生成实现
 *}

function GenerateRandomBytes(ASize: Integer): TBytes;
begin
  Result := GetSecureRandom.GetBytes(ASize);
end;

function GenerateRandomInteger(AMin, AMax: Integer): Integer;
begin
  Result := GetSecureRandom.GetInteger(AMin, AMax);
end;

function GenerateBase64UrlString(ALength: Integer): string;
begin
  Result := GetSecureRandom.GetBase64UrlString(ALength);
end;

{**
 * 工具函数实现
 *}

function BytesToHex(const ABytes: TBytes): string;
begin
  // Delegate to core.bytes for single source of truth
  Result := fafafa.core.bytes.BytesToHex(ABytes);
end;

function HexToBytes(const AHex: string): TBytes;
begin
  // Fast pre-check to guarantee exact exception class per crypto API contract
  if (Length(AHex) and 1) <> 0 then
    raise EInvalidArgument.Create('Hex string must have even length');
  // Delegate to core.bytes for strict hex parsing; map argument errors to crypto-layer
  try
    Result := fafafa.core.bytes.HexToBytes(AHex);
  except
    on E: fafafa.core.bytes.EInvalidArgument do
      raise EInvalidArgument.Create(E.Message);
  end;
end;

function SecureCompare(const ABytes1, ABytes2: TBytes): Boolean;
begin
  // Delegate to utils for a robust constant-time compare that also guards against length side-channels
  Result := fafafa.core.crypto.utils.ConstantTimeCompare(ABytes1, ABytes2);
end;

procedure SecureZero(var ABuffer; ASize: Integer);
begin
  if ASize > 0 then
    FillChar(ABuffer, ASize, 0);
end;

{**
 * 安全工具函数实现
 *}

function ConstantTimeCompare(const AData1, AData2: TBytes): Boolean;
begin
  Result := fafafa.core.crypto.utils.ConstantTimeCompare(AData1, AData2);
end;

function ConstantTimeStringCompare(const AStr1, AStr2: string): Boolean;
begin
  Result := fafafa.core.crypto.utils.ConstantTimeStringCompare(AStr1, AStr2);
end;

procedure SecureZeroMemory(ABuffer: Pointer; ASize: Integer);
begin
  fafafa.core.crypto.utils.SecureZeroMemory(ABuffer, ASize);
end;

procedure SecureZeroBytes(var AData: TBytes);
begin
  fafafa.core.crypto.utils.SecureZeroBytes(AData);
end;

procedure SecureZeroString(var AStr: string);
begin
  fafafa.core.crypto.utils.SecureZeroString(AStr);
end;

function CheckPasswordStrength(const APassword: string): TPasswordStrength;
begin
  Result := fafafa.core.crypto.utils.CheckPasswordStrength(APassword);
end;

function ValidatePassword(const APassword: string; const APolicy: TPasswordPolicy): Boolean;
begin
  Result := fafafa.core.crypto.utils.ValidatePassword(APassword, APolicy);
end;

function GetPasswordStrengthDescription(AStrength: TPasswordStrength): string;
begin
  Result := fafafa.core.crypto.utils.GetPasswordStrengthDescription(AStrength);
end;

function GenerateSecurePassword(ALength: Integer;
  AIncludeUppercase: Boolean = True;
  AIncludeLowercase: Boolean = True;
  AIncludeDigits: Boolean = True;
  AIncludeSymbols: Boolean = True): string;
begin
  Result := fafafa.core.crypto.utils.GenerateSecurePassword(ALength,
    AIncludeUppercase, AIncludeLowercase, AIncludeDigits, AIncludeSymbols);
end;

function GeneratePassphrase(AWordCount: Integer = 4; const ASeparator: string = '-'): string;
begin
  Result := fafafa.core.crypto.utils.GeneratePassphrase(AWordCount, ASeparator);
end;

function GetDefaultPasswordPolicy: TPasswordPolicy;
begin
  Result := fafafa.core.crypto.utils.GetDefaultPasswordPolicy;
end;

function GetStrictPasswordPolicy: TPasswordPolicy;
begin
  Result := fafafa.core.crypto.utils.GetStrictPasswordPolicy;
end;

end.
