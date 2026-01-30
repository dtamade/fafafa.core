# fafafa.core.id — 现代 ID 生成（UUID v4/v7，RFC 9562）

## 模块概述
- 提供 RFC 9562 规范的 UUID 生成：v4（随机）、v7（按时间排序）
- 依赖 `fafafa.core.crypto.random` 的 CSPRNG，跨平台
- 适用场景：
  - v7：数据库主键/索引，对插入局部性友好（推荐）
  - v4：更强调不可预测性（安全相关上下文）

## 快速开始
```pascal
uses fafafa.core.id;

var S: string;
begin
  S := UuidV7;  // 017f22e2-79b0-7cc3-98c4-dc0c0c07398f
  S := UuidV4;  // 919108f7-52d1-4320-9bac-f847db4148a8
end.
```

## API 摘要
```pascal
// 原始 16 字节
function UuidV4_Raw: TUuid128;
function UuidV7_Raw: TUuid128; overload;
function UuidV7_Raw(ATimestampMs: Int64): TUuid128; overload;

// 文本（8-4-4-4-12，小写十六进制）
function UuidV4: string; overload;
procedure UuidV4(out AOut: string); overload;
function UuidV7: string; overload;
procedure UuidV7(out AOut: string); overload;

// 转换与解析
function UuidToString(const A: TUuid128): string;
procedure UuidToString(const A: TUuid128; out S: string);
function UuidToStringNoDash(const A: TUuid128): string; // 无连字符文本（32 十六进制）
function TryParseUuid(const S: string; out A: TUuid128): Boolean;
function TryParseUuidRelaxed(const S: string; out A: TUuid128): Boolean; // 支持 32 位纯十六进制（无连字符）
function TryParseUuidNoDash(const S: string; out A: TUuid128): Boolean;

// v7 时间戳提取（毫秒；非 v7 返回 -1）
function UuidV7_TimestampMs(const S: string): Int64;
```

// 宽松版（支持 32 位无连字符）
function UuidV7_TimestampMsRelaxed(const S: string): Int64;

// 辅助函数
function UuidVersion(const A: TUuid128): Integer; inline;
function UuidVariantRFC4122(const A: TUuid128): Boolean; inline;
function IsUuidV4(const S: string): Boolean; inline;
function IsUuidV7(const S: string): Boolean; inline;


## 设计要点
- v7 格式（大端）：
  - 48 位 Unix 毫秒时间戳填充字节 0..5
  - 字节 6 高 4 位为版本 0111b（v7）
  - 字节 8 的 variant 位为 10b（RFC 4122/IETF）
  - 其余位随机
- v4 格式：
  - 字节 6 高 4 位为 0100b（v4），字节 8 的 variant 为 10b
- 文本序列化：小写十六进制，固定破折号位置（8-4-4-4-12）

## 与竞品对比
- ULID：Base32 文本，易读；但非 IETF 标准，且实现差异导致兼容性问题
- KSUID：更长（160 位），时间排序，包含 32 位时间偏移；生态多在 Go
- Snowflake 家族：需中心/分片配置，强依赖时钟与节点号；更偏分布式架构组件
- UUIDv7（本模块）：
  - 无中心节点需求，足够低碰撞率
  - 有序插入友好，文本/二进制均保留排序特性
  - IETF RFC 9562 标准，跨语言实现一致

## UUID v7 单调器（Monotonic Generator）

- 作用：同毫秒内严格递增，提升数据库写入局部性与全局可排序性；溢出（12 位 rand_a 满值）等待下一毫秒
- 接口：`IUuidV7Generator`，工厂 `CreateUuidV7Monotonic`
- 线程安全：内部使用临界区保护最后时间戳与计数器
- 示例：
```pascal
uses fafafa.core.id.v7.monotonic, fafafa.core.id;
var g: IUuidV7Generator; s1, s2: string;
begin
  g := CreateUuidV7Monotonic;
  s1 := g.Next; s2 := g.Next; // s1 < s2（同毫秒内严格递增）
end.
```

注意：普通 `UuidV7`（函数式）已具时间分布的排序友好性，但同毫秒内不保证严格递增；当你需要严格递增或避免热点冲突时使用单调器。

## 最佳实践
- DB 主键：优先使用 v7（二进制存储 BINARY(16) 或 BIGINT+VARBINARY 拆列）
- 安全上下文令牌：优先 v4 或 v7 + 额外熵/签名，将 UUID 视为不具备安全能力
- 文本/传输：在 URL/日志中推荐 UUID(Base64URL) 或 UUID 无连字符；二进制优先跨系统传递
- 日志：使用 v7 可直观按时间排序；敏感场景注意时间泄露面

## 数据库存储与索引建议（MySQL / PostgreSQL）

- 二进制优先：更紧凑、比较成本低、排序与前缀过滤友好；文本仅在需要人类可读或跨系统直读时采用
- 排序特性：UUID v7/ULID/KSUID 的二进制按大端时间戳在前，BTREE 索引能自然按时间局部有序

MySQL（InnoDB）
```sql
-- UUID v7 / ULID 二进制存储（推荐）
CREATE TABLE t_uuid_v7 (
  id BINARY(16) NOT NULL,
  -- 其他字段...
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- KSUID 二进制存储（20 字节）
CREATE TABLE t_ksuid (
  id BINARY(20) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Snowflake（64 位）
CREATE TABLE t_snowflake (
  id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- 如果必须用文本：建议 ASCII 定长并使用二进制排序规则
-- UUID（36 字符，含连字符）
CREATE TABLE t_uuid_text (
  id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;
-- ULID（26 字符，Base32） / KSUID（27 字符，Base62） 同理
```

PostgreSQL
```sql
-- UUID v7：直接使用内置 uuid 类型（BTREE 索引按字节序）
CREATE TABLE t_uuid_v7 (
  id UUID PRIMARY KEY
);

-- ULID/UUID 二进制：BYTEA(16) 或者使用 uuid 类型（若坚持 16 字节存储可选 BYTEA）
CREATE TABLE t_ulid (
  id BYTEA NOT NULL CHECK (octet_length(id) = 16),
  PRIMARY KEY (id)
);

-- KSUID 二进制（20 字节）
CREATE TABLE t_ksuid (
  id BYTEA NOT NULL CHECK (octet_length(id) = 20),
  PRIMARY KEY (id)
);

### 解析策略（严格 vs 宽松）
- 严格（TryParseUuid / UuidV7_TimestampMs）：仅接受 36 字符、固定破折号位置的 UUID 文本
- 宽松（TryParseUuidRelaxed / UuidV7_TimestampMsRelaxed）：接受 36 字符（含破折号）或 32 字符（无破折号），大小写不敏感
- 建议：
  - 系统内存储与协议边界：优先严格

## 批量生成（高吞吐场景）

- UUID v4/v7：
  - `function UuidV4_RawN(Count: SizeInt): TUuid128Array`
  - `procedure UuidV4_FillRawN(var OutArr: TUuid128Array)` / `procedure UuidV4_FillRawN(var OutArr: array of TUuid128)`
  - `function UuidV7_RawN(Count: SizeInt): TUuid128Array`
  - `procedure UuidV7_FillRawN(var OutArr: TUuid128Array)` / `procedure UuidV7_FillRawN(var OutArr: array of TUuid128)`
- 单调器：
  - `IUuidV7Generator.NextRawN(var OutArr: array of TUuid128)` — 在同毫秒内严格递增，多线程建议每线程一个生成器以减少锁竞争
- 建议：
  - 复用缓冲（FillRawN）减少分配
  - V7 批量在高速日志/入队写入时有更好插入局部性（配合单调器）

  - 读用户输入 / 宽松日志场景：使用宽松

-- Snowflake（64 位）
CREATE TABLE t_snowflake (
  id BIGINT NOT NULL,
  PRIMARY KEY (id)
);
```

注意事项
- 统一大端布局：本模块的二进制布局已按时间戳在前（大端），可直接受益于索引局部性
- 文本列的排序：保证 ASCII/BINARY 排序规则，避免大小写/区域性排序导致的异常
- 应用层建议：在应用层进行文本⇄二进制转换，避免数据库端函数影响写入路径

## 性能注意事项
- Base64URL 编码/解码 CPU 成本显著低于 Base58，且可利用 SIMD/矢量化；因而在 URL/日志等可接受的场景优先考虑 Base64URL
- Base58 尤其是大整数除/乘环节较重，吞吐较低；仅在字符集限制（不含 +/=/0OIl）且可读友好性必要时采用
- UUID v7/ULID/KSUID 的时间排序特性可减少 B-Tree 索引页分裂与随机 I/O，对写入吞吐有重要正向影响

## Snowflake 配置与部署

- 默认配置
  - epochMs=1288834974657（Twitter epoch）
  - workerId=0
  - backwardPolicy=sbWait（时钟回拨时等待至不倒退）

- 参数与环境变量优先级
  - 命令行参数 > 环境变量 > 默认

- 支持键
  - --worker-id, 环境变量 FA_SF_WORKER_ID
  - --sf-epoch-ms, 环境变量 FA_SF_EPOCH_MS
  - --sf-throw 或 FA_SF_THROW（非 0 值启用 sbThrow，时钟回拨即抛异常）

- 示例
  ```bash
  # 默认运行（Windows 下）：
  examples/fafafa.core.id/BuildOrRun.bat

  # 自定义 worker/epoch：
  examples/fafafa.core.id/bin/example_snowflake_config.exe --worker-id=7 --sf-epoch-ms=1700000000000

  # 启用回拨抛错策略：
  set FA_SF_THROW=1
  examples/fafafa.core.id/bin/example_snowflake_config.exe
  ```

- 参考实现
  - examples/fafafa.core.id/example_snowflake_config.lpr



## 依赖
- `fafafa.core.crypto.random`（CSPRNG），已跨平台实现
- 统一宏：`{$I fafafa.core.settings.inc}`

## 参考
- RFC 9562: Universally Unique IDentifiers (UUIDs)
- IETF 安全文档：RFC 4086, RFC 8937（随机性建议）
- Base58（Bitcoin 字母表）与 Base64URL 编码实践


## 跨语言编码兼容性（Base58 / Base62 / Base32）
- Base58（Bitcoin 字母表）
  - 字母集：123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz（不含 0OIl+/=）
  - 各语言库实现细节不同：前导 0 的处理、大小写、空白忽略、截断/填充差异，建议测试用例覆盖
- Base62
  - 字母集通常为 0-9 A-Z a-z（62 个）
  - KSUID 的 27 字符表示固定长度，应确保编码/解码都按 20 字节大整数进行除/乘，不依赖库内可变长策略
- Base32（Crockford）
  - 字母集：0-9 A-Z 去除 I L O U；大小写不敏感，建议统一输出大写
  - ULID 文本长度固定 26；请避免使用 RFC 4648 的 Base32，与 Crockford 不兼容
- 建议
  - 跨语言交互时，优先使用二进制（BINARY）字段在系统间传递；文本仅在边界或日志使用
  - 若必须使用文本：约定统一字母表和大小写，编写跨语言回归用例

