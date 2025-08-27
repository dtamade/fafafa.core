{
  fafafa.core.crypto.interfaces - 加密库共享接口定义

  本单元定义了所有加密模块共享的接口：
  - IHashAlgorithm - 哈希算法接口
  - ISymmetricCipher - 对称加密算法接口
  - 其他共享接口和类型

  设计原则：
  - 统一的接口定义
  - 避免类型不兼容问题
  - 清晰的接口继承关系
}

unit fafafa.core.crypto.interfaces;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base;

const
  // PBKDF2 默认迭代次数（门面默认重载使用；现代建议>=100k）
  cPBKDF2DefaultIterations = 100000;


  // AEAD 建议与约束常量（接口层统一文档化约束；具体实现可更严格）
  cAEAD_RecommendedNonceSize_96 = 12; // 96-bit Nonce 常见建议值（GCM、ChaCha20-Poly1305）
  cAEAD_GCM_TagLen_Min = 4;           // GCM 允许的最小标签长度（字节）
  cAEAD_GCM_TagLen_Max = 16;          // GCM 允许的最大标签长度（字节）
  cAEAD_Poly1305_TagLen = 16;         // ChaCha20-Poly1305 固定标签长度（字节）


type
  TBytes = fafafa.core.base.TBytes;

  // 共享异常类型
  ECrypto = class(ECore) end;
  ECryptoHash = class(ECrypto) end;
  ECryptoCipher = class(ECrypto) end;
  EInvalidArgument = class(ECrypto) end;
  EInvalidOperation = class(ECrypto) end;
  EInvalidKey = class(ECryptoCipher) end;
  EInvalidData = class(ECrypto) end;

  {**
   * IHashAlgorithm
   *
   * @desc
   *   Base interface for all hash algorithms.
   *   所有哈希算法的基础接口.
   *}
  IHashAlgorithm = interface
    ['{B8F5E2A1-4C3D-4E5F-8A9B-1C2D3E4F5A6B}']
    function GetDigestSize: Integer;
    function GetBlockSize: Integer;
    function GetName: string;
    procedure Update(const AData; ASize: Integer);
    function Finalize: TBytes;
    procedure Reset;
    procedure Burn;
    property DigestSize: Integer read GetDigestSize;
    property BlockSize: Integer read GetBlockSize;
    property Name: string read GetName;
  end;

  {**
   * ISymmetricCipher
   *
   * @desc
   *   Base interface for all symmetric cipher algorithms.
   *   所有对称加密算法的基础接口.
   *}
  ISymmetricCipher = interface
    ['{C9A6F3B2-5D4E-4F6A-9B8C-2D3E4F5A6B7C}']
    function GetKeySize: Integer;
    function GetBlockSize: Integer;
    function GetName: string;
    procedure SetKey(const AKey: TBytes);
    function Encrypt(const APlaintext: TBytes): TBytes;
    function Decrypt(const ACiphertext: TBytes): TBytes;
    procedure Reset;
    procedure Burn;
    property KeySize: Integer read GetKeySize;
    property BlockSize: Integer read GetBlockSize;
    property Name: string read GetName;
  end;

  {**
   * IBlockCipher
   *
   * @desc
   *   Interface for block cipher algorithms with mode support.
   *   支持模式的块加密算法接口.
   *}
  IBlockCipher = interface(ISymmetricCipher)
    ['{A1B2C3D4-5E6F-4A5B-9C8D-7E6F5A4B3C2D}']
    function GetMode: string;
    function GetPaddingEnabled: Boolean;
    procedure SetPaddingEnabled(AEnabled: Boolean);
    property Mode: string read GetMode;
    property PaddingEnabled: Boolean read GetPaddingEnabled write SetPaddingEnabled;
  end;

  {**
   * IBlockCipherWithIV
   *
   * @desc
   *   Block cipher interface with IV support.
   *   支持IV的块加密算法接口.
   *}
  IBlockCipherWithIV = interface(IBlockCipher)
    ['{D5E6F7A8-9B0C-4D5E-7F8A-9B0C1D2E3F4A}']
    function GetIVSize: Integer;
    procedure SetIV(const AIV: TBytes);
    function GetIV: TBytes;
    procedure GenerateRandomIV;
    function IsIVSet: Boolean;
    property IVSize: Integer read GetIVSize;
  end;

  {**
   * IHMAC
   *
   * @desc
   *   Hash-based Message Authentication Code interface.
   *   基于哈希的消息认证码接口。
   *
   * @contracts
   *   - SetKey: 接受二进制密钥（TBytes）或 string（按 UTF-8 转为字节）。允许空密钥（RFC 2104 允许）。
   *   - Update: 追加消息数据；调用前必须先 SetKey，否则应在实现中抛出 EInvalidOperation。
   *   - Finalize: 返回 MAC（长度等于 DigestSize），不自动 Burn；可配合 Reset/Burn 使用。
   *   - ComputeMAC: 一次性计算，等价于 Reset→SetKey（若需要）→Update→Finalize。
   *   - VerifyMAC: 使用常量时间比较；不因不匹配抛异常，返回 False。
   *
   * @params
   *   - AKey(string): 视为 UTF-8 文本后再参与 HMAC 计算。
   *   - Update(const AData; ASize): ASize 可为 0，表示空块追加。
   *
   * @returns
   *   - Finalize/ComputeMAC: 返回 MAC 字节数组。
   *   - VerifyMAC: 返回 True/False。
   *
   * @errors
   *   - EInvalidOperation: 未设置密钥时调用 Update/Finalize/ComputeMAC/VerifyMAC。
   *   - 其他实现相关错误按需要抛出 ECrypto 派生异常。
   *
   * @thread-safety
   *   - IHMAC 实例通常非线程安全；不要跨线程共享同一实例的可变状态。
   *}
  IHMAC = interface
    ['{D4E5F6A7-8B9C-4D5E-6F7A-8B9C0D1E2F3A}']
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
    property DigestSize: Integer read GetDigestSize;
    property BlockSize: Integer read GetBlockSize;
    property Name: string read GetName;
    property HashAlgorithmName: string read GetHashAlgorithmName;
  end;

  {**
   * IKeyDerivationFunction
   *
   * @desc
   *   Key Derivation Function interface.
   *   密钥派生函数接口。
   *
   * @contracts
   *   - DeriveKey: 从口令（TBytes 或 UTF-8 string）与 Salt 派生定长密钥。
   *   - DeriveKeyWithRandomSalt: 生成随机 Salt 并输出；返回派生键。
   *   - VerifyPassword: 使用常量时间比较验证派生结果。
   *
   * @params
   *   - APassword(string): 按 UTF-8 编码转为字节参与派生。
   *   - ASalt: 允许为空与否取决于具体算法（HKDF 空 Salt 视为 HashLen 个 0；PBKDF2 一般建议非空）。
   *   - AIterations: 迭代次数（PBKDF2 需 >= MinIterations）。
   *   - AKeyLength: 输出长度；不得超过 MaxKeyLength（HKDF 额外要求 L ∈ (0, 255*HashLen]）。
   *
   * @returns
   *   - 派生的密钥字节数组。
   *
   * @errors
   *   - EInvalidArgument: 迭代次数过低/输出长度超界/不支持的参数组合。
   *
   * @thread-safety
   *   - 实例通常非线程安全；不要跨线程共享同一实例的可变状态。
   *}
  IKeyDerivationFunction = interface
    ['{E5F6A7B8-9C0D-4E5F-7A8B-9C0D1E2F3A4B}']
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
    property Name: string read GetName;
    property HashAlgorithmName: string read GetHashAlgorithmName;
    property MinIterations: Integer read GetMinIterations;
    property MaxKeyLength: Integer read GetMaxKeyLength;
  end;

  {**
   * ISecureRandom
   *
   * @desc
   *   Cryptographically secure random number generator interface.
   *   加密安全的随机数生成器接口。
   *
   * @contracts
   *   - GetBytes(var ABuffer; ASize): 向调用方提供的缓冲写入 ASize 个随机字节。
   *   - GetBytes(ASize): 返回新分配的随机字节数组。
   *   - GetBase64String/GetBase64UrlString: 生成由 Base64/Base64Url 字符表随机采样的字符串（无“=”填充）。
   *     注意：这是“随机字符采样”而非“对随机字节进行 Base64 编码”，不保证可逆解码。
   *   - AddEntropy/Reseed: 由实现决定熵混入与重播种策略；失败时应保持安全回退。
   *
   * @params
   *   - Base64Url 采用字符表 [A-Za-z0-9-_]，无填充；Base64 采用 [A-Za-z0-9+/]，无填充。
   *
   * @errors
   *   - EInvalidArgument: 请求长度为负等非法参数。
   *   - 平台 RNG 失败可抛 ECrypto 派生异常；实现需尽量回退至安全来源。
   *
   * @thread-safety
   *   - 除非实现另行声明，ISecureRandom 实例不保证线程安全；建议“每线程一实例”或外部同步。
   *}
  ISecureRandom = interface
    ['{0AEBF7F6-9B8C-7D0E-1F2A-6B7C8D9E0F1A}']
    procedure GetBytes(var ABuffer; ASize: Integer); overload;
    function GetBytes(ASize: Integer): TBytes; overload;
    function GetByte: Byte;
    function GetInteger: Integer;
    function GetInteger(AMin, AMax: Integer): Integer;
    function GetUInt32: UInt32;
    function GetUInt64: UInt64;
    function GetSingle: Single;
    function GetDouble: Double;
    function GetHexString(ALength: Integer): string;
    function GetBase64String(ALength: Integer): string;
    function GetBase64UrlString(ALength: Integer): string; // URL-safe Base64 (no padding)
    function GetAlphanumericString(ALength: Integer): string;
    procedure AddEntropy(const AData: TBytes);
    function GetEntropyEstimate: Integer;
    procedure Reseed;
    function IsInitialized: Boolean;
    procedure Reset;
    procedure Burn;
  end;

  {**
   * IAEADCipher
   *
   * @desc
   *   Authenticated Encryption with Associated Data (AEAD) 抽象；
   *   对齐 Go cipher.AEAD / RustCrypto aead traits 的语义与错误模型。
   *
   * @contracts
   *   - 参数顺序建议：key（由工厂/SetKey 提供）、nonce、aad、plaintext|ciphertext。
   *   - NonceSize: 返回固定 nonce 长度（字节），常见为 12（96-bit）。调用方必须提供正确长度。
   *   - Overhead: 返回标签长度（字节）；通常等于 TagLen。
   *   - SetKey: 若密钥长度不符合实现要求（如 AES-256-GCM 需 32 字节），抛 EInvalidKey。
   *   - SetTagLength: 设置可变标签长度（若实现支持），非法范围抛 EInvalidArgument；
   *     ChaCha20-Poly1305 固定 16 字节，设置其他值应报错。
   *   - Seal: 返回 Ciphertext||Tag；密钥未设置抛 EInvalidOperation；参数非法抛 EInvalidArgument。
   *   - Open: 认证失败必须抛 EInvalidData（禁止返回部分明文）；参数非法抛 EInvalidArgument。
   *   - Burn: 清理密钥与敏感中间状态。
   *
   * @thread-safety
   *   - 实例通常非线程安全；不要跨线程共享同一实例的可变状态。
   *}
  IAEADCipher = interface
    ['{6A1B0D27-8E54-4F5F-9B9C-3F2E7D5C4A1B}']
    function GetName: string;
    function GetKeySize: Integer;
    function NonceSize: Integer;     // 随机数/IV尺寸（字节）
    function Overhead: Integer;      // MAC/Tag 开销（字节）
    procedure SetKey(const AKey: TBytes);
    procedure SetTagLength(ATagLenBytes: Integer); // 可选：默认16；允许范围[4..16]（实现可限制为固定值）
    function Seal(const ANonce, AAD, APlaintext: TBytes): TBytes; // 输出: Ciphertext||Tag
    function Open(const ANonce, AAD, ACiphertext: TBytes): TBytes; // 认证失败必须抛出 EInvalidData
    procedure Burn;
  end;


  {**
   * IAEADCipherEx
   * AEAD 扩展接口：提供“低分配/追加式”API，参考 Go cipher.AEAD 的 dst-append 设计。
   * 向后兼容扩展，不改变 IAEADCipher 语义。
   *
   * @contracts
   *   - SealAppend(OpenAppend): 将输出追加到 ADst 末尾；返回追加后 ADst 的新总长度。
   *   - 调用方可预先 SetLength(ADst, 期望容量) 以减少重分配；实现应在需要时增长 ADst。
   *   - 若 ADst 与输入切片别名冲突，行为未定义；建议调用方使用独立缓冲。
   *}
  IAEADCipherEx = interface(IAEADCipher)
    ['{C1E5B9F2-7D34-4A91-9F2C-6B7D8E9F0A1B}']
    function SealAppend(var ADst: TBytes; const ANonce, AAD, APlaintext: TBytes): Integer;
    function OpenAppend(var ADst: TBytes; const ANonce, AAD, ACiphertext: TBytes): Integer;
  end;

  {**
   * IAEADCipherEx2
   * AEAD 扩展接口（In-Place 变体）。
   *
   * @contracts
   *   - SealInPlace: 在 AData 上原地生成 Ciphertext||Tag；必要时可增长容量；返回新长度。
   *   - OpenInPlace: 认证通过后在 AData 上原地还原为 Plaintext；可收缩长度；返回新长度。
   *   - 调用方应保证 AData 具备足够容量容纳 Seal 后的标签开销（Overhead）。
   *   - 认证失败时 OpenInPlace 抛 EInvalidData，AData 内容不作保证（建议调用方在失败路径丢弃缓冲）。
   *
   * @thread-safety
   *   - 与 IAEADCipher 相同，实例通常非线程安全。
   *}
  IAEADCipherEx2 = interface(IAEADCipher)
    ['{E2B5A1C3-7F22-4D7E-9B1C-5A6C7D8E9F01}']
    function SealInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
    function OpenInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
  end;



implementation

end.
