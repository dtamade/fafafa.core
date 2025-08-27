# fafafa.core.id.ksuid — KSUID（base62）

## 概述
- 结构：32 位相对秒（自 KSUID epoch：2014-05-13 UTC）+ 128 位随机，共 20 字节
- 文本：27 个 base62 字符（0-9 A-Z a-z），跨语言生态较多（Go 常见）
- 特点：按时间排序、人类可读、无集中式节点配置

## 快速开始
```pascal
uses fafafa.core.id.ksuid;
var S: string;
begin
  S := Ksuid; // 27 字符
end.
```

## API 摘要
```pascal
function KsuidNow_Raw: TKsuid160;
function Ksuid_Raw(AUnixSeconds: Int64): TKsuid160;
function Ksuid: string; overload;
procedure Ksuid(out AOut: string); overload;

procedure KsuidToString(const A: TKsuid160; out S: string);
function KsuidToString(const A: TKsuid160): string;
function TryParseKsuid(const S: string; out A: TKsuid160): Boolean;
function Ksuid_TimestampUnixSeconds(const S: string): Int64;
```

## 实现要点
- 时间戳：4 字节大端，值为 UnixSeconds-KSUID_EPOCH_UNIX（如果早于 epoch 则归零）
- base62：实现了 20 字节大数 ÷ 62 编码与累计 × 62 解码
- 注意：本实现遵循常见社区 epoch（1400000000）

## 与 UUID v7 / ULID 的取舍
- UUID v7：IETF 标准，二进制/文本均时间排序；适合默认主键
- ULID：26 字符 Base32，更通用可读
- KSUID：更长（base62 文本），生态偏 Go；如果团队已有既有规范，可选



## 数据库存储与索引建议

- 二进制优先：BINARY(20) 紧凑、索引更高效；文本 27 字符仅在需要直接阅读时采用
- 文本列排序：采用 ASCII/BINARY 排序规则，避免区域性排序影响

MySQL（InnoDB）
```sql
CREATE TABLE t_ksuid (
  id BINARY(20) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;
```

PostgreSQL
```sql
CREATE TABLE t_ksuid (
  id BYTEA NOT NULL CHECK (octet_length(id) = 20),
  PRIMARY KEY (id)
);
```

- 如果必须使用文本：
```sql
-- MySQL
CREATE TABLE t_ksuid_text (
  id CHAR(27) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- PostgreSQL
CREATE TABLE t_ksuid_text (
  id CHAR(27) NOT NULL,
  PRIMARY KEY (id)
);
```
