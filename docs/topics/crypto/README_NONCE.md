# Nonce 策略最佳实践（AES-GCM/ChaCha20-Poly1305）

本项目推荐 96-bit (12 字节) Nonce 策略，并在门面导出以下助手：

- GenerateNonce12: 使用 CSPRNG 生成 12 字节随机 Nonce（需业务层保证相同 key 下不重复）
- ComposeGCMNonce12(instanceID: UInt32, counter: UInt64): 以 32-bit 实例 ID + 64-bit 计数器（大端）组成 96-bit Nonce
- CreateNonceManager(instanceID, counterStart, historySize): 简易 Nonce 管理器（计数器/随机去重）

> 重要：同一密钥下 Nonce 必须全局唯一，严禁重复。

## 一、计数器策略（推荐生产）

特点：
- 由调用方维护每个 key 的持久化计数器，保证单调递增
- 可跨进程/多实例，结合 instanceID 避免冲突

示例（伪代码）：
```pascal
var
  NM: INonceManager;
  Nonce: TBytes;
begin
  // instanceID: 为每个部署实例分配一个 32-bit 唯一 ID（或从节点ID/租约服务获取）
  // counterStart: 从持久化存储中加载该 key 的上次计数器
  NM := CreateNonceManager(instanceID, counterStart);

  // 每次加密前获取并自增
  Nonce := NM.NextGCMNonce12;
  // 用完后，将 NM.Counter 回写到持久化存储（例如每 N 次批量回写）
end;
```

字节布局（大端）：
- [0..3]   = InstanceID (UInt32, BE)
- [4..11]  = Counter (UInt64, BE)

## 二、随机策略（简便但需去重）

特点：
- 直接使用 GenerateNonce12 产生随机 Nonce
- 必须保证相同 key 下不重复：可用哈希集合/布隆过滤器做去重

示例：
```pascal
var
  NM: INonceManager;
  Nonce: TBytes;
begin
  NM := CreateNonceManager; // historySize 默认 1024
  Nonce := NM.GenerateUniqueRandomNonce12; // 内部以小型历史做基本去重
  // 大规模生产环境：请使用持久化去重结构，或优先采用计数器策略
end;
```

## 三、线程安全版本

- 提供 CreateNonceManagerThreadSafe：内部使用临界区（TCriticalSection）串行化访问
- 适合多线程场景；跨进程仍需依赖外部持久化计数器

示例：
```pascal
var
  NM: INonceManager;
  Nonce: TBytes;
begin
  NM := CreateNonceManagerThreadSafe($01020304, counterStartFromStore);
  Nonce := NM.NextGCMNonce12;
  // 将 NM.Counter 定期持久化回存（例如每 N 次或应用安全退出时）
end;
```

## 四、门面用法一览

```pascal
uses fafafa.core.crypto;

var N1, N2: TBytes; NM: INonceManager;
begin
  N1 := GenerateNonce12;
  N2 := ComposeGCMNonce12($01020304, 42);
  NM := CreateNonceManager($AABBCCDD, 0);
  N2 := NM.NextGCMNonce12;
end;
```

## 四、注意事项
- 切勿在同一密钥下复用 Nonce（GCM/Poly1305 将泄露安全性）
- 避免时间/状态回退导致计数器重用：使用原子计数器 + 定期持久化
- 多线程/多进程：确保访问 NonceManager 时的并发安全（本实现为示例，未内置锁）
- 历史去重队列仅示范用途，生产应使用更可靠的持久化去重方案

