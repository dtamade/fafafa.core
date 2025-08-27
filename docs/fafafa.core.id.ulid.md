# fafafa.core.id.ulid — ULID 生成与编解码（Crockford Base32）

## 概述
- ULID（Universally Unique Lexicographically Sortable Identifier）：128 位（48 位毫秒时间戳 + 80 位随机）
- 文本编码：26 字符，大写 Crockford Base32（无 I、L、O、U）
- 特点：可读性较好、按时间排序；跨语言普及但非 IETF 标准

## 快速开始
```pascal
uses fafafa.core.id.ulid;

var S: string;
begin
  S := Ulid;                // 26 字符，例如 01H9Z8W1JTB3P2Q4R6V8YACDEF
end.
```

## API 摘要
```pascal
// 生成
function UlidNow_Raw: TUlid128;
function Ulid_Raw(ATimestampMs: Int64): TUlid128;
function Ulid: string; overload;
procedure Ulid(out AOut: string); overload;

// 编解码
procedure UlidToString(const A: TUlid128; out S: string);
function UlidToString(const A: TUlid128): string;
function TryParseUlid(const S: string; out A: TUlid128): Boolean;
function Ulid_TimestampMs(const S: string): Int64; // 非法返回 -1
```

## 设计要点
- 时间戳：48 位 Unix 毫秒，文本前 10 个字符；二进制按大端放入字节 0..5
- 随机数：80 位，文本后 16 个字符，每个字符 5 bit，共 80 bit
- 解析：宽容 I/L→1，O→0（常见 Crockford 宽容策略）
- 单调变体：提供 IUlidGenerator（src/fafafa.core.id.ulid.monotonic.pas），同毫秒内对 80-bit 随机区做大端自增，线程安全；80-bit 溢出时等待下一毫秒并重新播种

## 与 UUID v7 的关系
- 都是按时间排序；v7 是 IETF 标准（RFC 9562），ULID 更注重人类可读的文本形态
- 数据库存储：ULID 文本 26 字符；或二进制 16 字节

## 注意
- ULID 不是安全能力，不应用作权限令牌；可结合签名或 HMAC
- 解析时大小写不敏感；输出统一为大写

## 参考
- ULID 规范（GitHub：ulid/spec）
- Crockford Base32 字母表

