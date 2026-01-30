{
  fafafa.core.id.base — 统一 ID 类型定义

  集中定义所有 ID 类型，避免循环依赖:
  - TUuid128: 128 位 UUID (v1-v8)
  - TUlid128: 128 位 ULID
  - TKsuid160: 160 位 KSUID
  - TXid96: 96 位 XID
  - TTimeflake: 128 位 Timeflake
  - TObjectId96: 96 位 ObjectId
  - TSnowflakeID: 64 位 Snowflake

  用法:
    uses fafafa.core.id.base;

    var
      Uuid: TUuid128;
      Ulid: TUlid128;
}

unit fafafa.core.id.base;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

const
  { ✅ P3: 统一十六进制字符常量 }
  HEX_CHARS: array[0..15] of Char = '0123456789abcdef';
  HEX_CHARS_UPPER: array[0..15] of Char = '0123456789ABCDEF';

  { Base62 编码字母表 (0-9 A-Z a-z) }
  BASE62_ALPHABET: PChar = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  BASE62_ALPHABET_STR: string = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  { Base58 编码字母表 (Bitcoin 标准，无 0OIl) }
  BASE58_ALPHABET: string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

type
  { 128 位类型 }

  {**
   * TUuid128 - 128 位 UUID (通用唯一标识符)
   *
   * 支持 UUID v1-v8，按 RFC 4122/9562 标准布局:
   * - Bytes 0-3: time_low
   * - Bytes 4-5: time_mid
   * - Bytes 6-7: time_hi_and_version
   * - Byte 8: clock_seq_hi_and_reserved
   * - Byte 9: clock_seq_low
   * - Bytes 10-15: node
   *}
  TUuid128 = array[0..15] of Byte;
  PUuid128 = ^TUuid128;
  TUuid128Array = array of TUuid128;

  {**
   * TUlid128 - 128 位 ULID (Universally Unique Lexicographically Sortable Identifier)
   *
   * 布局:
   * - Bytes 0-5: 48 位时间戳 (毫秒, big-endian)
   * - Bytes 6-15: 80 位随机数 (big-endian)
   *}
  TUlid128 = array[0..15] of Byte;
  PUlid128 = ^TUlid128;
  TUlid128Array = array of TUlid128;

  {**
   * TTimeflake - 128 位 Timeflake
   *
   * 布局:
   * - Bytes 0-5: 48 位时间戳 (毫秒, big-endian)
   * - Bytes 6-15: 80 位随机数 (big-endian)
   *}
  TTimeflake = array[0..15] of Byte;
  PTimeflake = ^TTimeflake;

  { 160 位类型 }

  {**
   * TKsuid160 - 160 位 KSUID (K-Sortable Unique Identifier)
   *
   * 布局:
   * - Bytes 0-3: 32 位时间戳 (秒, KSUID epoch, big-endian)
   * - Bytes 4-19: 128 位随机数
   *}
  TKsuid160 = array[0..19] of Byte;
  PKsuid160 = ^TKsuid160;

  { 96 位类型 }

  {**
   * TXid96 - 96 位 XID
   *
   * 布局:
   * - Bytes 0-3: 32 位时间戳 (秒, Unix epoch, big-endian)
   * - Bytes 4-6: 24 位机器 ID
   * - Bytes 7-8: 16 位进程 ID
   * - Bytes 9-11: 24 位计数器
   *}
  TXid96 = array[0..11] of Byte;
  PXid96 = ^TXid96;

  {**
   * TObjectId96 - 96 位 MongoDB ObjectId
   *
   * 布局:
   * - Bytes 0-3: 32 位时间戳 (秒, Unix epoch, big-endian)
   * - Bytes 4-8: 40 位随机数
   * - Bytes 9-11: 24 位计数器
   *}
  TObjectId96 = array[0..11] of Byte;
  PObjectId96 = ^TObjectId96;

  { 64 位类型 }

  {**
   * TSnowflakeID - 64 位 Twitter Snowflake ID
   *
   * 布局 (默认 Twitter 格式):
   * - Bit 63: 未使用 (符号位)
   * - Bits 22-62: 41 位时间戳 (毫秒, 自定义 epoch)
   * - Bits 12-21: 10 位 Worker ID
   * - Bits 0-11: 12 位序列号
   *}
  TSnowflakeID = Int64;

  {**
   * TSonyflakeID - 64 位 Sony Sonyflake ID
   *
   * 布局:
   * - Bits 24-63: 40 位时间戳 (10ms 精度)
   * - Bits 16-23: 8 位序列号
   * - Bits 0-15: 16 位机器 ID
   *}
  TSonyflakeID = UInt64;

  { ✅ P1/P2: 类型别名 - 向后兼容 }

  {** TObjectId 作为 TObjectId96 的别名 *}
  TObjectId = TObjectId96;
  PObjectId = PObjectId96;
  TObjectIdArray = array of TObjectId;

  {** TTimeflake 数组类型 *}
  TTimeflakeArray = array of TTimeflake;

  {** TXid96 数组类型 *}
  TXid96Array = array of TXid96;

  { 字符串数组类型 }
  TStringArray = array of string;

implementation

end.
