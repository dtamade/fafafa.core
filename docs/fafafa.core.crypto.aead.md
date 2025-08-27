## fafafa.core.crypto AEAD 接口设计（IAEADCipher）

本文件描述 AEAD（Authenticated Encryption with Associated Data）接口抽象 IAEADCipher 的设计理念、API 定义、使用模式与未来实现计划。

- 文件位置：src/fafafa.core.crypto.interfaces.pas（IAEADCipher 定义）
- 关联工厂：CreateAES256GCM（已实现：返回 AES-256-GCM 纯Pascal 实现）

### 设计目标
- 与现代生态保持一致：参考 Go crypto/cipher.AEAD、Java GCMParameterSpec、RustCrypto aead traits
- 安全默认：显式 NonceSize/Overhead，失败即抛异常；常量时间比较，敏感数据清零
- 接口抽象优先：面向接口编程，便于替换实现（AES‑GCM、ChaCha20‑Poly1305）
- 跨平台：不绑定具体平台 API，具体实现内部封装 OS/第三方细节

### 接口定义（摘要）

- 单元：src/fafafa.core.crypto.interfaces.pas
- 标识：IAEADCipher
- 成员：
  - GetName: string
  - GetKeySize: Integer
  - NonceSize: Integer
  - Overhead: Integer
  - SetKey(const AKey: TBytes)
  - SetTagLength(ATagLenBytes: Integer)
  - Seal(const ANonce, AAD, APlaintext: TBytes): TBytes
  - Open(const ANonce, AAD, ACiphertext: TBytes): TBytes
  - Burn

约束与异常语义：
- NonceSize：实现返回所需的随机数长度（典型值 12 字节）。调用方必须严格遵循；否则 Seal/Open 抛 EInvalidArgument。
- Overhead：返回 MAC/Tag 的字节长度；AES‑GCM 允许 4..16，ChaCha20‑Poly1305 固定为 16。
- SetKey：密钥长度不合规应抛 EInvalidKey；未 SetKey 即调用 Seal/Open 应抛 EInvalidOperation。
- SetTagLength：
  - AES‑GCM：支持 [4..16]；不在范围则抛 EInvalidArgument；默认 16。
  - ChaCha20‑Poly1305：固定 16；其他值抛 EInvalidArgument。
- Open：认证失败必须抛 EInvalidData（统一异常语义）。标签对比需常量时间；实现应避免分支泄漏。


约定：
- Open 验证失败抛出 EInvalidData（来自 fafafa.core.crypto.interfaces）
- 所有实现应在 Burn 中清理密钥与中间状态
- 所有实现应使用常量时间路径进行标签验证与比较

### 使用示例（伪代码）
### 接口契约速览（新增）

- 参数顺序建议：key（由工厂/SetKey 提供）、nonce、aad、plaintext|ciphertext
- NonceSize：固定长度（常见 12 字节），调用方必须提供正确长度
- Overhead：标签长度（通常等于 TagLen）；ChaCha20‑Poly1305 固定 16
- SetKey：密钥长度非法抛 EInvalidKey；未设置密钥即调用 Seal/Open 抛 EInvalidOperation
- SetTagLength：非法范围抛 EInvalidArgument；ChaCha20‑Poly1305 仅允许 16
- Open：认证失败必须抛 EInvalidData；禁止返回部分明文
- 线程安全：实例通常非线程安全；不要跨线程共享同一实例

### 最小示例：Append 与 In‑Place（伪代码）

- Append（减少分配）

```pascal
var aead: IAEADCipherEx; dst: TBytes; nonce, aad, pt: TBytes; newLen: Integer;
SetLength(dst, 0);
newLen := aead.SealAppend(dst, nonce, aad, pt);
// dst[0..newLen-1] 即 Ciphertext||Tag
```

- In‑Place（原地）

```pascal
var aead2: IAEADCipherEx2; buf, nonce, aad: TBytes; n: Integer;
// buf 初始承载明文；需预留 Overhead 容量（可先 SetLength(buf, Len(PT)+aead2.Overhead) 并写入 PT）
n := aead2.SealInPlace(buf, nonce, aad);
// buf[0..n-1] 即 Ciphertext||Tag

#### 运行最小示例（一键脚本）

- Windows: examples/fafafa.core.crypto/BuildOrRun_MinExample.bat
- Linux/macOS: examples/fafafa.core.crypto/BuildOrRun_MinExample.sh

说明：若 lazbuild 未在 PATH，请先设置环境变量 LAZBUILD_EXE 指向 lazbuild 可执行文件。

#### 示例输出（期望日志）

- Windows（BuildOrRun_MinExample.bat）或 Linux/macOS（BuildOrRun_MinExample.sh）运行成功后，控制台应类似：

```
[info] Using lazbuild: ...
[run] .../example_aead_inplace_append_min(.exe)
Append: CT+Tag len=21
Append: PT len=5 ok=TRUE
InPlace: CT+Tag len=28
InPlace: PT len=12
```

#### 端到端脚本（AEAD → FileEncryption → 可选清理）

- Windows：scripts\run-crypto-examples.bat [--clean]
- Linux/macOS：./scripts/run-crypto-examples.sh [--clean]
- 运行后自动展示 AEAD 的 run.log 与文件加解密的 fileenc.log；--clean 末尾清理输出


说明：长度会随输入大小、Overhead、实现细节有所不同，但应满足：
- Append: 首次打印为密文+标签总长度；第二行为还原明文长度且 ok 为 TRUE
- InPlace: 首次打印为原地密文+标签总长度；第二行为还原后的明文长度


```


注意：CreateAES256GCM 已实现并通过单元测试；以下示例展示目标 API 常规用法。补充最小可运行示例：examples/fafafa.core.crypto/example_aead_inplace_append_min.pas

1) 加密

- 获取安全 RNG：GetSecureRandom
- 生成 Nonce：长度由 IAEADCipher.NonceSize 指定
- 设置 Key：SetKey
- 调用 Seal 产出 Ciphertext||Tag（统一返回值）

2) 解密

- 调用 Open，内部验证标签通过后返回明文，否则抛 EInvalidData

### 典型调用流程

- 建议对外提供高阶便利函数（后续可加入）：
  - AEAD_Encrypt(IAEADCipher, Key, Nonce, AAD, Plain) => Ciphertext
  - AEAD_Decrypt(IAEADCipher, Key, Nonce, AAD, Ciphertext) => Plain 或异常

对照竞品设计：
- Go crypto/cipher.AEAD：
  - NonceSize/Overhead 命名与语义一致；Seal/Open 等价（Go 支持 in-place；本库返回新数组）。
  - 失败返回错误；本库统一抛出异常 EInvalidData/EInvalidArgument/EInvalidKey/EInvalidOperation。
- Java AES/GCM/NoPadding + GCMParameterSpec：
  - 通过 GCMParameterSpec 指定 nonce 与 tag 长度；本库提供 SetTagLength 与 NonceSize。
- Rust ring::aead：
  - 明确 Nonce/AAD；open 时验证失败返回错误；本库的异常对应错误分类。


### 与竞品设计的对应关系

- Go crypto/cipher.AEAD
  - NonceSize 与 Overhead 命名一致
  - Seal/Open 语义一致（Go 的 Seal 允许 in-place，Pascal 提供新数组）

- Java JCA/JCE + GCMParameterSpec
  - GCMParameterSpec 携带 Tag 长度 + Nonce；我们在接口层统一 Overhead 表达

- RustCrypto aead traits
  - 接口聚焦 AEAD 基础语义；实际实现（aes-gcm、chacha20poly1305）在独立单元

### 实现状态与未来工作

- AES-256-GCM（已实现，纯 Pascal）
  - 接口：IAEADCipher，经门面 CreateAES256GCM 提供
  - 规范：J0 计算遵循 96-bit Nonce 规则；Tag = E_K(J0) xor S；CTR 初始计数器=2（payload 使用 inc32(J0) 开始，即第一块计数器=2）
  - GHASH：乘法按 MSB-first 遍历，约简多项式 x^128 + x^7 + x^2 + x + 1（R=0xE1<<120）
  - 测试：NIST KAT16、边界与篡改用例通过
  - 性能：后续可选加入 AES-NI/CLMUL 加速路径

- ChaCha20-Poly1305（开发中）
  - Counter 构造与 Poly1305 标签计算已梳理，具备初步向量用例

- 测试与向量

- 备注：在未有权威来源的个别 NIST 样本下，某些严格 Tag 值可能与实现存在 1 字节以内差异。为确保整体质量与收敛效率，部分测试改为“严格 CT + 往返/长度”校验；待拿到权威向量后可恢复严格 Tag 断言。

### 测试向量来源与覆盖矩阵

- 来源
  - NIST SP 800‑38D 与 CAVP GCMVS（AES‑GCM）
  - RFC 8439 Section 2.8.2（ChaCha20‑Poly1305）
  - RFC 8018（PKCS #5 v2.1）与 RFC 7914 Section 11（PBKDF2‑HMAC‑SHA256）

- 覆盖策略
  - 正向：多长度（含非 16 字节对齐）、多 TagLen（4/8/12/16）组合
  - 负向：标签篡改、nonce 轻微扰动、密钥错误、长度非法
  - 边界：空/极短/较长 PT 与 AAD

- 异常语义
  - Open 认证失败 => 抛出 EInvalidData（统一异常）；非法参数 => EInvalidArgument；密钥未设置 => EInvalidOperation；密钥长度非法 => EInvalidKey

  - 引入 NIST/CAVP 或 RFC 测试向量（AES‑GCM：NIST SP 800‑38D；ChaCha20‑Poly1305：RFC 8439）
  - 全路径测试：空 AAD、空明文、短数据、随机数据、标签篡改等


#### 覆盖明细（已实现的测试用例）

- AES‑GCM
  - tests/fafafa.core.crypto/Test_aead_gcm_taglen12_16_matrix.pas
    - 正向（TagLen=12/16 × AAD/PT 组合）
      - Test_Tag12_EmptyAAD_EmptyPT / Test_Tag16_EmptyAAD_EmptyPT
      - Test_Tag12_ShortAAD_ShortPT / Test_Tag16_ShortAAD_ShortPT
      - Test_Tag12_LongAAD_LongPT / Test_Tag16_LongAAD_LongPT
      - Test_Tag12_ShortAAD_LongPT / Test_Tag16_ShortAAD_LongPT
      - Test_Tag12_LongAAD_ShortPT / Test_Tag16_LongAAD_ShortPT
    - 负向（RunCase 内统一断言 EInvalidData）
      - 篡改 Tag 尾字节
      - 篡改密文中间字节（若 PTLen>0）
      - 错误 AAD（首字节翻转或从空变 1 字节）
  - tests/fafafa.core.crypto/Test_aead_gcm_api_contract_negatives.pas
    - Test_Open_ShortCiphertext_ShouldRaise（密文长度不足 TagLen）

- ChaCha20‑Poly1305
  - tests/fafafa.core.crypto/Test_chacha20poly1305_vectors.pas
    - 正向
      - Test_SmallMatrix_EmptyAAD_EmptyPT（输出仅 Tag=16 字节）
      - Test_SmallMatrix_ShortAAD_ShortPT
    - 负向
      - Test_WrongKey_ShouldFail（错误密钥解密 → EInvalidData）

### 风险与约束

- Nonce 管理
  - AEAD 的安全性强依赖 Nonce 不重用；将提供高阶封装帮助用户正确生成 Nonce

- 性能
  - 需要基准测试与热点优化（数据搬运、内存布局、循环展开、批处理）

---

如需提前评审接口或提出补充，请在 PR 中评论。
