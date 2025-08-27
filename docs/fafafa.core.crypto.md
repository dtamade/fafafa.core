# fafafa.core.crypto 模块文档

> Version: v0.6.0-AEAD-Ready · Date: 2025-08-14 · Status: AEAD ready (AES-GCM/ChaCha20-Poly1305), security hardening applied
> See also: docs/RELEASE-NOTES-crypto-AEAD.md


## 概述

`fafafa.core.crypto` 是 fafafa.core 框架中的加密模块，提供现代化的加密功能，包括哈希算法、对称加密、非对称加密、密钥派生和安全随机数生成。

### 设计理念

- **安全优先**: 默认使用安全的算法和参数
- **接口抽象**: 优先使用接口，支持可替换实现
- **跨平台**: 支持 Windows/Linux/macOS
- **易于使用**: 清晰的API设计
- **高性能**: 关键路径优化

## 功能特性

### 已实现功能

- ✅ **AEAD**: AES‑256‑GCM（含 GHASH），ChaCha20‑Poly1305
- ✅ **哈希算法**: SHA‑256, SHA‑512
- ✅ **安全随机数生成**: 跨平台安全随机数生成器
- ✅ **工具函数**: 字节转换、常量时间比较（SecureCompare/ConstantTimeCompare）、安全清零

### 计划功能

- 🔄 **非对称加密**: RSA, ECDSA, Ed25519
- 🔄 **高级 KDF**: Argon2（PBKDF2 已提供）
- 🔄 **数字签名**: RSA‑PSS, ECDSA, Ed25519

## 快速开始

### 基本用法

```pascal
uses
  fafafa.core.crypto;

var
  LHash: TBytes;
  LRandom: TBytes;
begin
  // 计算SHA-256哈希
  LHash := HashSHA256('Hello World');
  WriteLn('SHA-256: ', BytesToHex(LHash));

  // 生成安全随机数
  LRandom := GenerateRandomBytes(16);
  WriteLn('Random: ', BytesToHex(LRandom));
WriteLn('Token (B64URL): ', GenerateBase64UrlString(24));
end;
```

### 流式哈希计算

```pascal
var
  LHasher: IHashAlgorithm;
  LResult: TBytes;
begin
  LHasher := CreateSHA256;
  LHasher.Update(PChar('Hello ')^, 6);
  LHasher.Update(PChar('World')^, 5);
  LResult := LHasher.Finalize;
  WriteLn('Hash: ', BytesToHex(LResult));
end;
```


### 示例入口
- 模块示例导航：examples/fafafa.core.crypto/README.md（最小示例/基准/文件加解密与一键脚本）

## API 参考
### Facade 导出工厂一览

- AEAD
  - `CreateAES256GCM: IAEADCipher`
  - `CreateChaCha20Poly1305: IAEADCipher`
- 分组密码（兼容/传统）
  - `CreateAES128, CreateAES256: ISymmetricCipher`
  - `CreateAES128_CBC, CreateAES256_CBC: IBlockCipherWithIV`
  - 注意：`AES-ECB`/`AES-CTR` 实现在细粒度单元（`src/fafafa.core.crypto.cipher.aes.ecb/.ctr`），主要用于测试/兼容/内部实现；默认不通过门面导出，推荐优先使用 AEAD 模式。
- KDF
  - `CreatePBKDF2` / `CreatePBKDF2_SHA256` / `CreatePBKDF2_SHA512`
  - 便利函数：`HKDF_SHA256` / `HKDF_SHA512`（RFC 5869）
- 随机数
  - `GetSecureRandom`，以及 `GenerateRandomBytes/Integer/Base64UrlString`
- Nonce 与安全组合 API
  - `CreateNonceManager` / `CreateNonceManagerThreadSafe`
  - 便捷方法：`AES256GCM_Seal_Combined/Open_Combined`、`ChaCha20Poly1305_Seal_Combined/Open_Combined`（来自 `fafafa.core.crypto.aead.safe`）


### 接口契约速览（核心接口）

- IAEADCipher（见 docs/fafafa.core.crypto.aead.md 与 src/fafafa.core.crypto.interfaces.pas）
  - NonceSize 固定；Overhead=TagLen；Open 失败抛 EInvalidData；SetTagLength 非法抛 EInvalidArgument
  - Append/In‑Place 变体：IAEADCipherEx/Ex2 提供低分配与原地能力
- ISecureRandom
  - Base64/Base64Url 便捷函数为“字符集随机采样（无填充）”，非“真实 Base64 编码”；如需编码请使用单独 API
- IHMAC
  - string 视为 UTF‑8；VerifyMAC 常量时间比较，不抛异常（返回 False）
- IKeyDerivationFunction
  - PBKDF2/HKDF 统一边界：迭代/长度/空盐（HKDF 空盐→HashLen 个 0），错误抛 EInvalidArgument

### AEAD Append 与 In‑Place 示例（简）

```pascal
var aead: IAEADCipherEx; dst: TBytes; newLen: Integer;
SetLength(dst, 0);
newLen := aead.SealAppend(dst, nonce, aad, pt);
```

```pascal
var aead2: IAEADCipherEx2; n: Integer;
// 预留容量: SetLength(buf, Len(PT)+aead2.Overhead)
n := aead2.SealInPlace(buf, nonce, aad);
```


### 哈希算法

#### 工厂函数

- `CreateSHA256(): IHashAlgorithm` - 创建SHA-256哈希算法实例
- `CreateSHA512(): IHashAlgorithm` - 创建SHA-512哈希算法实例

#### 便利函数

- `HashSHA256(const AData: TBytes): TBytes` - 计算数据的SHA-256哈希
- `HashSHA256(const AData: string): TBytes` - 计算字符串的SHA-256哈希
- `HashSHA512(const AData: TBytes): TBytes` - 计算数据的SHA-512哈希
- `HashSHA512(const AData: string): TBytes` - 计算字符串的SHA-512哈希

#### IHashAlgorithm 接口

```pascal
IHashAlgorithm = interface
  function GetDigestSize: Integer;      // 获取摘要大小
  function GetBlockSize: Integer;       // 获取块大小
  function GetName: string;             // 获取算法名称
  procedure Update(const AData; ASize: Integer);  // 更新数据
  function Finalize: TBytes;            // 完成计算
  procedure Reset;                      // 重置状态
end;
```

### 安全随机数生成

#### 全局函数

- `GetSecureRandom(): ISecureRandom` - 获取全局安全随机数生成器实例
- `GenerateRandomBytes(ASize: Integer): TBytes` - 生成随机字节
- `GenerateRandomInteger(AMin, AMax: Integer): Integer` - 生成随机整数
- `GenerateBase64UrlString(ALength: Integer): string` - 生成 URL‑safe Base64 字符串（无填充）

#### ISecureRandom 接口

```pascal
ISecureRandom = interface
  procedure GetBytes(var ABuffer; ASize: Integer);  // 填充缓冲区
  function GetBytes(ASize: Integer): TBytes;        // 返回随机字节
  function GetInteger(AMin, AMax: Integer): Integer; // 生成随机整数
  function GetBase64String(ALength: Integer): string; // 标准 Base64 字符集（无填充）
  function GetBase64UrlString(ALength: Integer): string; // URL-safe Base64 字符集（无填充）
  function GetHexString(ALength: Integer): string; // 十六进制字符集（小写）
  function GetDouble: Double; // 返回 [0,1) 区间均匀分布的 Double
end;
```

#### RNG 平台后端与策略

- Windows：默认使用 BCryptGenRandom（bcrypt.dll，系统首选 RNG）；仅当设置环境变量 `FAFAFA_CRYPTO_RNG_FORCE_LEGACY=1` 时，才回退至 CryptGenRandom（advapi32.dll）用于兼容/诊断。
- Linux：优先使用 `getrandom(2)`；当不可用或返回未满足长度时，回退 `/dev/urandom` 继续补齐。
- macOS：使用 `SecRandomCopyBytes`（Security.framework）。

说明：以上策略在不改变对外接口的前提下提升跨平台一致性与安全性；`GenerateRandomBytes(n)` 在所有平台上均保证返回恰好 n 字节（n=0 返回空数组）。

### 工具函数

- `BytesToHex(const ABytes: TBytes): string` - 字节转十六进制字符串
- `HexToBytes(const AHex: string): TBytes` - 十六进制字符串转字节
- `SecureCompare(const ABytes1, ABytes2: TBytes): Boolean` - 常量时间比较
- `SecureZero(var ABuffer; ASize: Integer)` - 安全清零内存

## 安全注意事项

### 哈希算法

1. **选择合适的算法**:
   - 优先使用 SHA-256 或 SHA-512
   - 避免使用 MD5 或 SHA-1（已知存在安全问题）

2. **密码哈希**:
   - 不要直接使用哈希算法存储密码
   - 使用专门的密码哈希函数（如 PBKDF2, Argon2）

### 随机数生成

1. **使用安全随机数生成器**:
   - 始终使用 `GetSecureRandom()` 或相关函数
   - 不要使用标准库的 `Random()` 函数进行安全相关操作

2. **密钥生成**:
   - 使用足够长度的随机密钥
   - AES-256 需要 32 字节密钥
   - RSA 建议使用 2048 位或更长

### 时间攻击防护（AEAD/GHASH）
### GHASH 后端与模式（开发者快速参考）

- 运行时后端切换（可选）：`FAFAFA_GHASH_IMPL=auto|pure|clmul`
- 纯 Pascal 模式（调试场景）：`FAFAFA_GHASH_PURE_MODE=bit|nibble|byte`（默认 byte），也可调用 `GHash_SetPureMode(...)`
- 诊断与调优（Debug）：
  - 一次性后端日志：`FAFAFA_GHASH_LOG_BACKEND=1|true`
  - 表清零（影响首用代价）：`FAFAFA_GHASH_ZEROIZE_TABLES=1|true`
  - per‑H 微缓存（≤4）：`FAFAFA_GHASH_CACHE_PER_H=1|true`
- 详细说明见：docs/crypto_ghash_quick_ref.md


- Open 鉴别：统一使用 SecureCompare 进行常量时间标签比较
- 敏感中间值：Seal/Open/GHASH 关键路径对 ZeroBlock/EJ0/H/S/C/局部缓冲显式清零
- 失败分支：在抛出异常前先清理敏感数据

## 性能指南

### 哈希算法性能

- SHA-256: 适合大多数应用场景，性能良好
- SHA-512: 在64位系统上可能比SHA-256更快


## Heavy Test Execution

- 定义 FAFAFA_CORE_PBKDF2_HEAVY 以启用 PBKDF2 极限 dkLen（如 1024 字节）测试：
  - IDE/Project Options 或命令行添加：-dFAFAFA_CORE_PBKDF2_HEAVY
  - 这些测试可能较耗时，默认关闭，仅在性能/极限验证时启用

## 测试向量来源与覆盖矩阵（摘要）

- 来源
  - NIST SP 800-38D / CAVP GCMVS（AES-GCM）
  - RFC 8439 §2.8.2（ChaCha20-Poly1305）
  - RFC 8018（PBKDF2）与 RFC 7914 §11（PBKDF2-HMAC-SHA256）

- 覆盖策略
  - 正向：多长度（含非 16 字节对齐/非 8 字节倍数）、多 TagLen
  - 负向：标签篡改、nonce 微扰、密钥错误、长度非法
  - 边界：空/极短/较长 PT 与 AAD；极端 dkLen

- 异常语义
  - Open 认证失败 => 抛出 EInvalidData；参数非法 => EInvalidArgument；密钥未设置 => EInvalidOperation；密钥长度非法 => EInvalidKey


  - AEAD 失败语义（补充示例）
    - 篡改 Tag：EInvalidData（例如翻转最后一字节或中间字节）
    - 篡改 Ciphertext：EInvalidData（任意有效范围内的字节翻转）
    - 篡改 AAD：EInvalidData（包括原为 0 长度改为非 0 的情况）
    - 篡改 Nonce：EInvalidData（Nonce 任意位翻转）
    - Open 输入长度 < TagLen：EInvalidArgument
    - PT 为空（仅 Tag）时，Seal/Open 仍应成功（len(CT)=TagLen, len(PT)=0）
    - 参考用例：Test_aead_gcm_tamper_matrix.pas（正/负向与边界示例）

### 优化建议

1. **批量处理**: 对于大量数据，使用流式接口而不是多次调用便利函数
2. **重用实例**: 可以重用哈希算法实例（调用Reset()重置）
3. **内存对齐**: 确保数据按适当边界对齐以获得最佳性能

## 错误处理

### 异常类型

- `ECrypto` - 所有加密相关错误的基类
- `EInvalidKey` - 无效密钥错误
- `EInvalidData` - 无效数据错误
- `EDecryptionFailed` - 解密失败错误
- `EVerificationFailed` - 签名验证失败错误

### 常见错误

1. **重复调用 Finalize()**:
   ```pascal
   // 错误示例
   LHasher := CreateSHA256;
   LResult1 := LHasher.Finalize;
   LResult2 := LHasher.Finalize; // 抛出 EInvalidOperation
   ```

2. **在 Finalize 后调用 Update()**:
   ```pascal
   // 错误示例
   LHasher := CreateSHA256;
   LResult := LHasher.Finalize;
   LHasher.Update(Data, Size); // 抛出 EInvalidOperation
   ```

## 最佳实践

### 1. 选择合适的算法

```pascal
// 推荐：使用现代安全算法
LHash := HashSHA256(Data);

// 不推荐：使用已知不安全的算法
// LHash := HashMD5(Data); // MD5已不安全
```

### 2. 正确处理敏感数据

```pascal
var
  LPassword: TBytes;
  LKey: TBytes;
begin
  try
    LPassword := TEncoding.UTF8.GetBytes(UserInput);
    LKey := GenerateRandomBytes(32);

    // 使用密钥进行加密操作...

  finally
    // 清零敏感数据
    if Length(LPassword) > 0 then
      SecureZero(LPassword[0], Length(LPassword));
    if Length(LKey) > 0 then
      SecureZero(LKey[0], Length(LKey));
  end;
end;
```

### 3. 使用流式接口处理大数据

```pascal
procedure HashLargeFile(const AFileName: string);
var
  LFile: TFileStream;
  LHasher: IHashAlgorithm;
  LBuffer: array[0..8191] of Byte;
  LBytesRead: Integer;
  LResult: TBytes;
begin
  LFile := TFileStream.Create(AFileName, fmOpenRead);
  try
    LHasher := CreateSHA256;

    repeat
      LBytesRead := LFile.Read(LBuffer, SizeOf(LBuffer));
      if LBytesRead > 0 then
        LHasher.Update(LBuffer, LBytesRead);
    until LBytesRead = 0;

    LResult := LHasher.Finalize;
    WriteLn('File hash: ', BytesToHex(LResult));
  finally
    LFile.Free;
  end;
end;
```

## 兼容性

### 支持的平台

- Windows (x86, x64)
- Linux (x86, x64, ARM)
- macOS (x64, ARM64)

### FreePascal 版本要求

- 最低版本: FPC 3.2.0
- 推荐版本: FPC 3.2.2 或更高
- 匿名函数支持: FPC 3.3.1+ (可选)

### 依赖关系

- `fafafa.core.base` - 基础类型和异常
- 系统库:
  - Windows: `bcrypt.dll` (BCryptGenRandom 首选)，回退 `advapi32.dll` (CryptGenRandom)
  - Linux/Unix: `getrandom(2)`（优先），回退 `/dev/urandom`
  - macOS: Security.framework（SecRandomCopyBytes）

## 示例代码

- 推荐直接使用最小示例与微基准：
  - examples/fafafa.core.crypto/example_crypto_gcm_basic.lpr
  - examples/fafafa.core.crypto/example_crypto_gcm_tag12.lpr
  - examples/fafafa.core.crypto/example_gcm_bench.lpr
- 一键脚本：
  - Windows: scripts\\build_or_test_crypto.bat examples | plays
  - Linux/macOS: scripts/build_or_test_crypto.sh examples | plays

## 测试

运行测试用例：

```bash
# Windows
cd tests\fafafa.core.crypto
BuildOrTest.bat test

# Linux/macOS
cd tests/fafafa.core.crypto
./BuildOrTest.sh test
```

### 构建脚本与排错说明（lazbuild）

- 本仓库提供一键脚本：tests/fafafa.core.crypto/BuildOrTest.bat（Windows）与 BuildOrTest.sh（Linux/macOS）。
- 构建脚本依赖 tools/lazbuild.bat 作为统一入口：
  - 优先使用环境变量 LAZBUILD_EXE 指向的 lazbuild.exe 路径
  - 若未设置或路径不存在，则自动回退使用 PATH 中可用的 lazbuild
  - 如仍未找到，将输出清晰错误提示与修复建议

常见问题：
- 提示“lazbuild not found”：
  - 设置环境变量 LAZBUILD_EXE（示例：set LAZBUILD_EXE=C:\Lazarus\lazbuild.exe）
  - 或将 lazbuild.exe 所在目录加入 PATH
- 脚本在哪个目录执行都可以吗？
  - 可以。BuildOrTest.bat 会规范化相对路径，支持任意当前目录执行

### 断言与兼容性

- 测试代码对异常断言采用“匿名函数 + 方法指针回退”的双分支：
  - 在启用 FAFAFA_CORE_ANONYMOUS_REFERENCES 的编译器上使用 AssertException + 匿名过程
  - 在不支持匿名函数的编译器上，使用方法指针或 try..except 回退，确保异常类型与消息一致
- 这样可以保证在不同 FPC 版本或编译宏配置下的测试稳定性



### 极简示例：AES‑GCM Roundtrip（≤10 行）

注意：示例为最小片段，真实项目应使用 GetSecureRandom 生成 Key/Nonce。

```
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes;
AEAD := CreateAES256GCM;
Key := HexToBytes('000102030405060708090A0B0C0D0E0F000102030405060708090A0B0C0D0E0F');
Nonce := HexToBytes('00112233445566778899AABB'); SetLength(AAD,0);
AEAD.SetKey(Key);
CT := AEAD.Seal(Nonce, AAD, PT);
PT := AEAD.Open(Nonce, AAD, CT);
```

- NonceSize 固定 12 字节；默认 Tag=16 字节，可用 SetTagLength(4..16) 调整
- 参数非法 → EInvalidArgument；认证失败 → EInvalidData

## 许可证

本模块遵循与 fafafa.core 框架相同的许可证。
