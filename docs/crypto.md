# fafafa.core.crypto 加密模块设计蓝图 (crypto.md)

本文档旨在规划和指导 `fafafa.core.crypto` 模块的实现。该模块的目标是提供一套现代、易用、跨平台的加密原语，包括哈希、消息认证码和对称加密。

---

## 核心设计哲学

*   **安全第一**: 优先使用业界公认的、安全的加密算法和模式。不实现有已知漏洞或不推荐的算法。
*   **易用性**: 封装复杂的加密 API，提供简单、高级的接口，减少误用的可能性。
*   **流式处理**: 对哈希和加密等操作，支持 `TStream` 输入，以高效处理大文件或数据流。
*   **依赖最小化**: 尽可能利用操作系统自带的加密库 (如 Windows CNG, OpenSSL on Linux)，避免引入庞大的第三方依赖。

---

## 开发路线图

### 阶段一: 哈希函数与安全随机数

*目标: 实现最基础、最常用的哈希计算和加密安全的随机数生成功能。*

- [ ] **1.1. 创建 `fafafa.core.crypto.pas` 单元并设计 `TCrypto` 静态类**

- [ ] **1.2. 实现哈希函数**
    - @desc: 提供一组静态方法，用于计算数据或流的哈希值。
    - **API 设计**:
        ```pascal
        type
          THashType = (htMD5, htSHA1, htSHA256, htSHA512);

          TCrypto = class abstract
          public
            class function Hash(const aBuffer: TBytes; aType: THashType): TBytes; overload;
            class function Hash(aStream: TStream; aType: THashType): TBytes; overload;

            // 为常用算法提供便捷方法
            class function MD5(const aBuffer: TBytes): TBytes;
            class function SHA256(const aBuffer: TBytes): TBytes;
          end;
        ```

- [ ] **1.3. 实现安全随机数生成器**
    - @desc: 提供一个函数，用于从操作系统获取加密安全的随机字节。
    - **API 设计** (在 `TCrypto` 中):
        ```pascal
        class procedure GetRandomBytes(var aBuffer: TBytes; aCount: SizeUInt);
        ```
    - **核心机制**:
        - **Windows**: 使用 `BCryptGenRandom` 或 `CryptGenRandom`。
        - **Linux/POSIX**: 读取 `/dev/urandom`。

---

### 阶段二: 消息认证码 (MAC)

*目标: 提供验证数据完整性和来源真实性的能力。*

- [ ] **2.1. 实现 HMAC**
    - @desc: 提供基于哈希的消息认证码 (HMAC) 功能。
    - **API 设计** (在 `TCrypto` 中):
        ```pascal
        class function HMAC(const aKey, aData: TBytes; aType: THashType): TBytes;

        // 便捷方法
        class function HMAC_SHA256(const aKey, aData: TBytes): TBytes;
        ```

---

### 阶段三: 对称加密

*目标: 提供强大的数据加密和解密功能。*

- [ ] **3.1. 设计 `TAesGcm` 对称加密类**
    - @desc: 封装推荐的 AES-GCM 认证加密模式 (AEAD)。
    - **API 设计** (`fafafa.core.crypto.aes.pas`):
        ```pascal
        type
          TAesGcm = class
          public
            constructor Create(const aKey: TBytes);

            // 返回的 TBytes 将包含 aNonce + aCipherText + aAuthTag
            function Encrypt(const aPlainText, aNonce, aAdditionalData: TBytes): TBytes;

            // aCipherText 格式需与 Encrypt 输出一致
            function Decrypt(const aCipherText, aAdditionalData: TBytes): TBytes;
          end;
        ```
    - @remark: GCM 模式同时提供了保密性、完整性和真实性，是现代应用的首选。

---

### 阶段四: 单元测试

- [ ] **4.1. 编写 `testcase_crypto.pas`**
    - [ ] 使用已知的测试向量 (test vectors) 验证所有哈希算法的正确性。
    - [ ] 验证 HMAC 的正确性。
    - [ ] 验证 AES-GCM 加密和解密的往返一致性，以及认证失败（数据或附加数据被篡改）时能否正确抛出异常。
