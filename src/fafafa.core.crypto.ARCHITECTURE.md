# fafafa.core.crypto 细粒度架构文档

## 📋 概述

本文档描述了 `fafafa.core.crypto` 模块的细粒度架构设计，该架构提供了清晰的命名空间分离、按需导入支持和向后兼容性。

## 🏗️ 架构设计原则

### 1. 单一职责原则
- 每个算法都有独立的单元文件
- 每个文件只负责一个特定的算法或功能

### 2. 清晰的命名空间
- 使用点号分隔的命名空间：`fafafa.core.crypto.category.algorithm`
- 命名空间直接对应文件名

### 3. 接口统一性
- 所有模块使用共享的接口定义
- 避免类型不兼容问题

### 4. 向后兼容性
- 统一入口点保持现有API不变
- 支持渐进式迁移到细粒度模块

## 📁 文件结构

```
src/
├── fafafa.core.crypto.interfaces.pas         # 共享接口定义
├── fafafa.core.crypto.hash.sha256.pas        # SHA-256算法
├── fafafa.core.crypto.hash.sha512.pas        # SHA-512算法
├── fafafa.core.crypto.hash.md5.pas           # MD5算法
├── fafafa.core.crypto.cipher.aes.pas         # AES核心算法
├── fafafa.core.crypto.cipher.aes.ecb.pas     # AES-ECB模式
├── fafafa.core.crypto.cipher.aes.cbc.pas     # AES-CBC模式
├── fafafa.core.crypto.hmac.pas               # HMAC实现
├── fafafa.core.crypto.kdf.pbkdf2.pas         # PBKDF2密钥派生
├── fafafa.core.crypto.random.pas             # 随机数生成器
├── fafafa.core.crypto.utils.pas              # 实用工具
└── fafafa.core.crypto.pas                    # 统一入口点
```

## 🔗 模块依赖关系

```
fafafa.core.crypto.interfaces.pas (纯接口定义)
    ↑
    ├── fafafa.core.crypto.hash.*.pas
    ├── fafafa.core.crypto.cipher.*.pas
    ├── fafafa.core.crypto.hmac.pas
    ├── fafafa.core.crypto.kdf.*.pas
    └── fafafa.core.crypto.random.pas
    ↑
fafafa.core.crypto.pas (统一入口点)
```

## 📚 模块详细说明

### 接口模块

#### `fafafa.core.crypto.interfaces.pas`
- **职责**: 定义所有共享接口和类型
- **内容**: 
  - `IHashAlgorithm` - 哈希算法接口
  - `ISymmetricCipher` - 对称加密接口
  - `IBlockCipher` - 块加密接口
  - `IBlockCipherWithIV` - 支持IV的块加密接口
  - `IHMAC` - HMAC接口
  - `IKeyDerivationFunction` - 密钥派生接口
  - `ISecureRandom` - 安全随机数接口
  - 异常类型定义

### 哈希算法模块

#### `fafafa.core.crypto.hash.sha256.pas`
- **职责**: SHA-256哈希算法实现
- **接口**: `IHashAlgorithm`
- **功能**: 
  - 256位输出长度
  - 512位块大小
  - 符合FIPS PUB 180-4标准

#### `fafafa.core.crypto.hash.sha512.pas`
- **职责**: SHA-512哈希算法实现
- **接口**: `IHashAlgorithm`
- **功能**:
  - 512位输出长度
  - 1024位块大小
  - 符合FIPS PUB 180-4标准

#### `fafafa.core.crypto.hash.md5.pas`
- **职责**: MD5哈希算法实现
- **接口**: `IHashAlgorithm`
- **功能**:
  - 128位输出长度
  - 512位块大小
  - 符合RFC 1321标准
  - ⚠️ 仅用于兼容性，不推荐新项目使用

### 对称加密模块

#### `fafafa.core.crypto.cipher.aes.pas`
- **职责**: AES核心算法实现
- **接口**: `ISymmetricCipher`
- **功能**:
  - 支持AES-128/192/256
  - 基础ECB模式实现
  - 符合FIPS 197标准

#### `fafafa.core.crypto.cipher.aes.ecb.pas`
- **职责**: AES-ECB模式实现
- **接口**: `IBlockCipher`
- **功能**:
  - 电子密码本模式
  - 支持PKCS#7填充
  - ⚠️ 不安全，仅用于特殊场景

#### `fafafa.core.crypto.cipher.aes.cbc.pas`
- **职责**: AES-CBC模式实现
- **接口**: `IBlockCipherWithIV`
- **功能**:
  - 密码块链接模式
  - 需要初始化向量(IV)
  - 支持PKCS#7填充
  - 符合NIST SP 800-38A标准

### 消息认证和密钥派生

#### `fafafa.core.crypto.hmac.pas`
- **职责**: HMAC实现
- **接口**: `IHMAC`
- **功能**:
  - 支持任意哈希算法
  - 符合RFC 2104标准
  - 常量时间比较防止时序攻击

#### `fafafa.core.crypto.kdf.pbkdf2.pas`
- **职责**: PBKDF2密钥派生函数
- **接口**: `IKeyDerivationFunction`
- **功能**:
  - 符合RFC 2898标准
  - 基于HMAC的伪随机函数
  - 可配置迭代次数
  - 防止彩虹表攻击

### 随机数生成

#### `fafafa.core.crypto.random.pas`
- **职责**: 安全随机数生成器
- **接口**: `ISecureRandom`
- **功能**:
  - 使用操作系统随机源
  - 支持多种数据类型生成
  - 跨平台兼容

### 统一入口点

#### `fafafa.core.crypto.pas`
- **职责**: 统一入口点，重新导出所有模块
- **功能**:
  - 向后兼容性
  - 工厂函数
  - 便利函数
  - 类型重新导出

## 🚀 使用方式

### 方式1: 统一入口点（推荐用于现有项目）

```pascal
uses fafafa.core.crypto;

var
  Hash: IHashAlgorithm;
  AES: IBlockCipherWithIV;
begin
  Hash := CreateSHA256;
  AES := CreateAES256_CBC;
  // ... 使用
end;
```

### 方式2: 按需导入（推荐用于新项目）

```pascal
uses fafafa.core.crypto.hash.sha256,
     fafafa.core.crypto.cipher.aes.cbc;

var
  Hash: IHashAlgorithm;
  AES: IBlockCipherWithIV;
begin
  Hash := fafafa.core.crypto.hash.sha256.CreateSHA256;
  AES := fafafa.core.crypto.cipher.aes.cbc.CreateAES256_CBC;
  // ... 使用
end;
```

### 方式3: 接口抽象编程

```pascal
uses fafafa.core.crypto.interfaces,
     fafafa.core.crypto.hash.sha256;

function CreateHasher: IHashAlgorithm;
begin
  Result := fafafa.core.crypto.hash.sha256.CreateSHA256;
end;
```

## ✅ 验证和测试

所有模块都通过了以下测试：

1. **单元测试** - 每个算法的功能正确性
2. **集成测试** - 模块间的互操作性
3. **兼容性测试** - 统一入口点的向后兼容性
4. **性能测试** - 算法性能符合预期

## 🔄 迁移指南

### 从旧版本迁移

1. **无需修改** - 继续使用 `fafafa.core.crypto`
2. **渐进式迁移** - 逐步替换为细粒度模块
3. **新功能** - 直接使用细粒度模块

### 最佳实践

1. **新项目** - 优先使用细粒度模块
2. **库开发** - 使用接口抽象
3. **应用开发** - 根据需要选择导入方式

## 📈 未来扩展

架构支持以下扩展：

1. **新算法** - 创建新的细粒度模块
2. **新模式** - 在相应类别下添加
3. **新功能** - 扩展接口定义

---

*本架构设计于2025年，旨在提供清晰、可维护、可扩展的加密库结构。*
