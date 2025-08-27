# fafafa.core.crypto 最佳实践

## 架构与接口
- 接口优先：以 IAEADCipher/ISymmetricCipher/IHashAlgorithm 等抽象接口为中心；具体类通过工厂暴露（如 CreateAES256GCM），便于替换实现（纯 Pascal → AES‑NI/CLMUL）。
- 语义一致（异常契约）：
  - 参数非法：EInvalidArgument；密钥不合规：EInvalidKey；状态非法（未 SetKey/重复 Finalize）：EInvalidOperation；认证失败：EInvalidData。
  - IAEADCipher：NonceSize 固定（GCM/ChaCha20‑Poly1305=12）；Overhead=TagLen；SetTagLength（GCM）允许 4..16（默认 16）；Open 认证失败必须抛 EInvalidData。

## AES‑GCM / GHASH 规范要点（SP 800‑38D）
- 96‑bit Nonce：J0 = Nonce || 0x00000001；payload 计数器从 2 开始（inc32）。
- 非 96‑bit Nonce：J0 = GHASH(H, {}, Nonce)（可按需扩展；当前实现限定 12 字节）。
- GHASH 乘法：GF(2^128) 上 MSB‑first 遍历；约简常量 R = 0xE1 << 120。
- 验证顺序：先 GHASH + E(K,J0) 计算 tag，常量时间比较通过后才解密/返回明文。

## 安全编码
- 常量时间比较：统一使用 SecureCompare/ConstantTimeCompare，避免短路分支。
- 敏感数据清理：Burn 清零密钥与中间态；临时缓冲使用后 SecureZeroBytes；异常路径不泄露数据内容。
- Managed 类型：显式初始化 Result，减少 5093/5091 提示；热路径尽量复用缓冲，避免频繁分配。

## 随机数与 Nonce
- RNG 后端优先级：
  - Windows：BCryptGenRandom → RtlGenRandom（回退）
  - Linux：getrandom(2) → /dev/urandom（回退）
  - macOS：SecRandomCopyBytes
  - 永远保留纯 Pascal 回退与负向测试
- Nonce 管理：同一密钥下严格避免 Nonce 重用；提供线程安全的 NonceManager，保证跨线程单调。

## 测试驱动
- 向量与矩阵：
  - KAT：AES‑ECB（NIST）、AES‑GCM（NIST KAT16/Minimal）、HKDF/PBKDF2、ChaCha20‑Poly1305
  - 组合：TagLen 12/16 × PT/AAD 空/短/长
  - 篡改：nonce/aad/ct/tag 多位点与多字节
- 结构与规范：
  - 单元命名：命名空间+.test.pas；TTestCase_Global 放置全局函数；类对象建独立 TTestCase
  - 测试过程命名：Test_函数名 或 Test_函数名_参数1_参数2
  - UTF‑8 输出：{$CODEPAGE UTF8}；生成 JUnit 报告
- 构建与运行：
  - 全量：tests\fafafa.core.crypto\BuildOrTest.bat test（脚本自动跑 anon=ON/OFF）
  - 仅 AEAD：tests\fafafa.core.crypto\BuildOrTest.bat aead test
  - CI 建议：使用 BuildOrTest.strict.bat，以 anon=OFF 作为最终 RC

## 性能与工程
- 热路径：CTR/GHASH 按块处理，减少分支与分配；预留硬件加速开关（接口不变，工厂可替换）。
- 诊断：以环境变量/编译宏控制（如 FAFAFA_CORE_AEAD_DIAG），默认关闭。
- 编译配置：仅使用 src/fafafa.core.settings.inc 作为宏配置；避免内联变量写法；遵循现有代码风格。
- 文档与追踪：每轮更新 report/ 与 todos/；模块文档放 docs/fafafa.core.模块名.md，记录接口/异常/限制。

## 何时“严格 Tag 比对”
- 向量来源权威且参数一致（密钥/nonce/tagLen/aad/pt）时，优先密文+标签全严格校验。
- 若历史向量混杂或标注差异，先采用“密文严格 + 往返校验 TAG”的工程策略，待权威向量到位后再收紧。

## 快速检查清单
- 实现：
  - [ ] NonceSize/Overhead/SetTagLength 行为与规范一致
  - [ ] Open 在认证失败时抛 EInvalidData，不返回明文
  - [ ] 敏感缓冲清零；比较常量时间
- 测试：
  - [ ] KAT/矩阵/篡改用例覆盖完整
  - [ ] JUnit 报告生成且全绿
- 工程：
  - [ ] report/ 与 todos/ 已更新
  - [ ] 诊断宏默认关闭（发布配置）

