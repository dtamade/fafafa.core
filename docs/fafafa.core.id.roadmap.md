# fafafa.core.id 模块分析与发展路线图

> 对标 Rust 生态系统，制定详细的修复和推进计划

## 1. 当前架构概览

### 1.1 现有文件结构

```
src/fafafa.core.id/
├── fafafa.core.id.pas              # UUID v4/v7 核心实现
├── fafafa.core.id.uuid.pas         # TUUID 强类型记录封装
├── fafafa.core.id.ulid.pas         # ULID 核心实现
├── fafafa.core.id.ulid.record.pas  # TULID 强类型记录封装
├── fafafa.core.id.ulid.monotonic.pas # ULID 单调生成器
├── fafafa.core.id.ksuid.pas        # KSUID 核心实现
├── fafafa.core.id.ksuid.record.pas # TKSUID 强类型记录封装
├── fafafa.core.id.ksuid.monotonic.pas # KSUID 单调生成器 (新增)
├── fafafa.core.id.snowflake.pas    # Snowflake 核心实现
├── fafafa.core.id.snowflake.record.pas # TSnowflakeIDRec 封装 (新增)
├── fafafa.core.id.v7.monotonic.pas # UUID v7 单调生成器
├── fafafa.core.id.codec.pas        # 编码转换 (Base64URL, Base58)
├── fafafa.core.id.time.pas         # 统一时间源 (UTC)
└── fafafa.core.id.uuid.batch.examples.pas # 批量示例
```

### 1.2 现有功能矩阵 (更新于 2024-12-22)

| ID 类型 | 生成 | 解析 | 格式化 | 单调 | 记录封装 | 运算符 | 批量 | JSON |
|---------|------|------|--------|------|----------|--------|------|------|
| UUID v4 | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | ✅ | ✅ |
| UUID v5 | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | ✅ | ✅ |
| UUID v6 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| UUID v7 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| UUID v8 | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | ✅ | ✅ |
| ULID | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| KSUID | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| KSUIDms | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Snowflake | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Sonyflake | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 2. Rust 生态系统对标分析

### 2.1 Rust uuid crate (1.9+)

**核心特性：**
- UUID v1/v3/v4/v5/v6/v7/v8 全版本支持
- `ContextV7` 保证同毫秒内单调递增 (1.9.0+)
- `no_std` 支持
- Serde 序列化
- 特性开关 (feature flags) 细粒度控制

**我们缺失的：**
- ❌ UUID v1 (MAC + 时间戳)
- ❌ UUID v3/v5 (命名空间 + MD5/SHA1)
- ❌ UUID v6 (v1 重排序，时间排序友好)
- ❌ UUID v8 (自定义布局)
- ⚠️ v7 计数器保证同毫秒排序 (部分实现)

### 2.2 Rust ulid crate

**核心特性：**
- `Generator` 单调生成器
- `MonotonicError` 错误处理
- `next_monotonic` / `next_strictly_monotonic`
- 随机部分溢出策略选择

**我们的状态：**
- ✅ 基本单调生成
- ❌ 溢出策略可配置
- ❌ `MonotonicError` 专用错误类型

### 2.3 Rust svix-ksuid crate

**核心特性：**
- 标准 1 秒精度
- 高精度模式 (4ms)
- Serde 支持

**我们的状态：**
- ✅ 标准精度
- ❌ 高精度模式 (KsuidMs)
- ❌ Serde 等效支持

### 2.4 Rust Snowflake 生态

**核心特性 (snowflake_me, rs-snowflake)：**
- 无锁 CAS 实现
- 可配置位分配 (时间戳/机器ID/序列号)
- 时钟回退策略 (等待/抛异常/自旋)
- Sonyflake 变体 (10ms 精度)

**我们的状态：**
- ✅ 基本生成
- ⚠️ 时钟回退处理 (有异常，但策略固定)
- ❌ 无锁实现
- ❌ 可配置位分配
- ❌ Sonyflake 变体

---

## 3. Gap 分析与优先级 (更新于 2024-12-22)

### P0 - 关键缺失 ✅ 已完成

| ID | 问题 | 影响 | 状态 |
|----|------|------|------|
| G-01 | UUID v7 同毫秒无序 | 数据库索引效率 | ✅ ContextV7 已实现 |
| G-02 | Snowflake 无锁 | 高并发性能 | ✅ AtomicU64 + CAS |
| G-03 | 缺少 UUID v5 | 确定性 ID 需求 | ✅ 命名空间哈希已实现 |

### P1 - 重要增强 ✅ 已完成

| ID | 问题 | 影响 | 状态 |
|----|------|------|------|
| G-04 | 无 UUID v6 | 向后兼容 v1 场景 | ✅ v6 已实现 |
| G-05 | ULID 溢出策略固定 | 灵活性不足 | ✅ 策略枚举已添加 |
| G-06 | KSUID 无高精度模式 | 4ms 精度需求 | ✅ KsuidMs 已实现 |
| G-07 | 无统一 Builder 模式 | API 不一致 | ✅ Builder API 已添加 |
| G-08 | 缺少批量 ULID/KSUID | 性能优化场景 | ✅ 批量 API 已添加 |

### P2 - 未来增强 ✅ 大部分完成

| ID | 问题 | 状态 |
|----|------|------|
| G-09 | 无 UUID v8 | ✅ 自定义布局已实现 |
| G-10 | 无 Sonyflake | ✅ 10ms 变体已实现 |
| G-11 | 无序列化框架集成 | ✅ JSON 序列化已添加 |
| G-12 | 无 no_std 模式 | ⏳ 嵌入式场景（按需）|

---

## 4. 详细修复计划

### Phase 1: P0 关键修复 (1-2 周)

#### 4.1.1 UUID v7 ContextV7 计数器

**目标：** 保证同毫秒内生成的 v7 UUID 严格递增

**实现方案：**
```pascal
type
  TContextV7 = record
  private
    FLastMs: Int64;
    FCounter: UInt16;  // 12-bit counter (rand_a field)
    FLock: TCriticalSection;
  public
    function Next: TUuid128;
    class function Global: TContextV7; static;
  end;
```

**关键点：**
- 使用 rand_a 字段 (bits 48-59) 作为计数器
- 同毫秒递增，新毫秒重置并随机化
- 溢出时等待下一毫秒

**文件：** `fafafa.core.id.v7.context.pas`

#### 4.1.2 Snowflake 无锁实现

**目标：** 使用 AtomicU64 替代 CriticalSection

**实现方案：**
```pascal
type
  TLockFreeSnowflake = class(TInterfacedObject, ISnowflake)
  private
    FState: QWord;  // packed: timestamp(41) | sequence(12) | padding
    FWorkerId: Word;
    FEpochMs: Int64;
    function CAS(var Target: QWord; OldVal, NewVal: QWord): Boolean; inline;
  public
    function NextID: TSnowflakeID;
  end;
```

**关键点：**
- 状态打包到单个 QWord
- CAS 循环更新
- 失败时自旋或 yield

**文件：** `fafafa.core.id.snowflake.lockfree.pas`

#### 4.1.3 UUID v5 (SHA1 命名空间)

**目标：** 支持确定性 UUID 生成

**实现方案：**
```pascal
function UuidV5(const Namespace: TUuid128; const Name: string): TUuid128;
function UuidV5_DNS(const Name: string): TUuid128;
function UuidV5_URL(const Name: string): TUuid128;
function UuidV5_OID(const Name: string): TUuid128;
function UuidV5_X500(const Name: string): TUuid128;
```

**文件：** `fafafa.core.id.v5.pas`

---

### Phase 2: P1 重要增强 (2-3 周)

#### 4.2.1 UUID v6 支持

**目标：** v1 的时间排序友好版本

**实现方案：**
```pascal
function UuidV6_Raw(ATimestamp100ns: Int64; AClockSeq: Word; const ANode: array of Byte): TUuid128;
function UuidV6: TUuid128;  // 使用系统时间和随机节点
```

#### 4.2.2 ULID 溢出策略

**目标：** 可配置的溢出行为

```pascal
type
  TUlidOverflowPolicy = (
    opWrapToZero,      // 溢出到 0，继续生成
    opWaitNextMs,      // 等待下一毫秒
    opRaiseError       // 抛出异常
  );

  IUlidGenerator = interface
    function Next: string;
    function NextRaw: TUlid128;
    procedure SetOverflowPolicy(Policy: TUlidOverflowPolicy);
  end;
```

#### 4.2.3 KSUID 高精度模式

**目标：** 4ms 精度的 KSUID

```pascal
type
  TKsuidMs = record
    // 牺牲 1 字节随机性换取 4ms 精度
    function TimestampMs: Int64;
  end;

function KsuidMsNow: TKsuidMs;
function KsuidMsToString(const K: TKsuidMs): string;
```

#### 4.2.4 统一 Builder 模式

**目标：** 流式 API 构建 ID

```pascal
type
  TIdBuilder = record
    class function UUID: TUuidBuilder; static;
    class function ULID: TUlidBuilder; static;
    class function KSUID: TKsuidBuilder; static;
    class function Snowflake: TSnowflakeBuilder; static;
  end;

// 使用示例
var id: TUUID;
begin
  id := TIdBuilder.UUID
    .Version(7)
    .Monotonic(True)
    .Build;
end;
```

#### 4.2.5 批量 ULID/KSUID

**目标：** 高效批量生成

```pascal
function UlidNow_RawN(Count: SizeInt): TUlid128Array;
procedure Ulid_FillRawN(var OutArr: array of TUlid128);
function KsuidNow_RawN(Count: SizeInt): TKsuid160Array;
procedure Ksuid_FillRawN(var OutArr: array of TKsuid160);
```

---

### Phase 3: P2 未来增强 (按需)

#### 4.3.1 UUID v8 自定义

```pascal
function UuidV8_Custom(const CustomData: array of Byte): TUuid128;
```

#### 4.3.2 Sonyflake 变体

```pascal
type
  ISonyflake = interface
    function NextID: QWord;
    function MachineID: Word;
    function TimestampMs: Int64;  // 10ms 单位
  end;
```

#### 4.3.3 序列化支持

```pascal
// JSON 序列化
function UuidToJson(const U: TUUID): string;
function JsonToUuid(const S: string): TUUID;

// 通用序列化接口
type
  IIdSerializer = interface
    procedure Serialize(const Id: TUUID; Writer: IWriter);
    function Deserialize(Reader: IReader): TUUID;
  end;
```

---

## 5. API 设计对齐 Rust

### 5.1 命名约定

| Rust | fafafa.core | 说明 |
|------|-------------|------|
| `Uuid::new_v4()` | `TUUID.NewV4` | 静态构造 |
| `Uuid::now_v7()` | `TUUID.NewV7` | 当前时间 v7 |
| `Uuid::parse_str()` | `TUUID.TryParse` | 解析 |
| `uuid.to_string()` | `TUUID.ToString` | 格式化 |
| `uuid.get_version()` | `TUUID.Version` | 版本号 |
| `uuid.get_variant()` | `TUUID.IsRfc4122` | 变体检查 |
| `Generator::generate()` | `IUlidGenerator.Next` | 单调生成 |

### 5.2 错误处理

```pascal
type
  // 统一 ID 异常层次
  EIdError = class(Exception);
  EIdParseError = class(EIdError);
  EIdOverflowError = class(EIdError);
  EIdClockRollbackError = class(EIdError);
  EIdInvalidConfigError = class(EIdError);
```

### 5.3 接口统一

```pascal
type
  // 所有 ID 类型的通用接口
  IId = interface
    function ToString: string;
    function ToBytes: TBytes;
    function Hash: UInt32;
    function CompareTo(const Other: IId): Integer;
  end;

  // 时间戳 ID 接口
  ITimestampId = interface(IId)
    function TimestampMs: Int64;
  end;

  // 单调生成器接口
  IMonotonicGenerator<T> = interface
    function Next: T;
    function NextRaw: T;
  end;
```

---

## 6. 实施路线图

```
2024 Q4                    2025 Q1                    2025 Q2
   │                          │                          │
   ▼                          ▼                          ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ Phase 1 (P0)     │  │ Phase 2 (P1)     │  │ Phase 3 (P2)     │
│                  │  │                  │  │                  │
│ • ContextV7      │  │ • UUID v6        │  │ • UUID v8        │
│ • LockFree Snow  │  │ • ULID 策略      │  │ • Sonyflake      │
│ • UUID v5        │  │ • KsuidMs        │  │ • 序列化框架     │
│                  │  │ • Builder API    │  │ • no_std 模式    │
│ 预计: 2周        │  │ • 批量 API       │  │                  │
│                  │  │                  │  │ 预计: 按需       │
│                  │  │ 预计: 3周        │  │                  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 7. 测试计划

### 7.1 单元测试

- [ ] ContextV7 同毫秒排序测试
- [ ] LockFree Snowflake 并发测试
- [ ] UUID v5 命名空间向量测试
- [ ] ULID 溢出策略测试
- [ ] KsuidMs 精度测试

### 7.2 性能基准

- [ ] v7 生成吞吐量 (ops/sec)
- [ ] Snowflake 无锁 vs 有锁对比
- [ ] 批量生成 vs 单个循环

### 7.3 兼容性测试

- [ ] 与 Rust uuid crate 输出互操作
- [ ] 与 Segment KSUID 兼容
- [ ] 与 Twitter Snowflake 兼容

---

## 8. 参考资源

- [Rust uuid crate](https://docs.rs/uuid/latest/uuid/struct.Uuid.html)
- [uuid v7 counters 博客](https://kodraus.github.io/rust/2024/06/24/uuid-v7-counters.html)
- [Rust ulid crate](https://docs.rs/ulid)
- [rusty_ulid](https://github.com/huxi/rusty_ulid)
- [svix-ksuid](https://docs.rs/svix-ksuid/latest/svix_ksuid/)
- [snowflake_me](https://lib.rs/crates/snowflake_me)
- [RFC 9562 - UUID](https://www.rfc-editor.org/rfc/rfc9562)
- [ULID Spec](https://github.com/ulid/spec)
- [KSUID Spec](https://github.com/segmentio/ksuid)

---

**文档版本:** 1.0
**创建日期:** 2024-12-22
**作者:** Claude Code
