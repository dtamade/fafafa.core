# fafafa.core.id.timeflake 模块说明

Timeflake 是 128 位、大致有序、URL 安全的 UUID 替代方案。

## 特性

- 128 位 (16 字节)
- 布局: 48 位时间戳 + 80 位随机
- 22 字符 Base62 字符串表示
- 36 字符 UUID 格式兼容
- 时间有序
- 单调生成支持
- 对标: https://github.com/anthonynsimon/timeflake

## 快速开始

```pascal
uses fafafa.core.id.timeflake;

var
  Id: TTimeflake;
  S: string;
begin
  // 生成 Timeflake
  Id := Timeflake;

  // 单调生成 (同毫秒内严格递增)
  Id := TimeflakeMonotonic;

  // 转换为 Base62 字符串
  S := TimeflakeToString(Id);  // 22 字符
end;
```

## Timeflake 结构

```
| 字节 | 位范围 | 内容 |
|------|--------|------|
| 0-5  | 0-47   | Unix 时间戳 (毫秒, 大端) |
| 6-15 | 48-127 | 随机数据 (80 位) |
```

## 单调 vs 非单调

```pascal
var
  Id1, Id2: TTimeflake;
begin
  // 非单调: 每次生成新随机
  Id1 := Timeflake;
  Id2 := Timeflake;
  // Id1 和 Id2 在同毫秒内可能无序

  // 单调: 同毫秒内递增
  Id1 := TimeflakeMonotonic;
  Id2 := TimeflakeMonotonic;
  // 保证 Id2 > Id1 (字节比较)
end;
```

## 字符串格式

```pascal
var
  Id: TTimeflake;
  S: string;
begin
  Id := Timeflake;

  // Base62 格式 (22 字符, 紧凑)
  S := TimeflakeToString(Id);  // "0mL4bR2...XYz"

  // UUID 格式 (36 字符, 带破折号)
  S := TimeflakeToUuidString(Id);  // "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  // 从字符串解析
  Id := TimeflakeFromString(S);
  Id := TimeflakeFromUuidString(S);
end;
```

## 时间戳提取

```pascal
var
  Id: TTimeflake;
  T: TDateTime;
  Ms: Int64;
begin
  Id := Timeflake;

  // 提取为 TDateTime
  T := TimeflakeTimestamp(Id);

  // 提取为 Unix 毫秒
  Ms := TimeflakeUnixMs(Id);

  WriteLn('Created at: ', DateTimeToStr(T), ' (', Ms, ' ms)');
end;
```

## 批量生成

```pascal
var
  Ids: TTimeflakeArray;
begin
  // 批量生成 (使用单调生成器)
  Ids := TimeflakeN(100);
end;
```

## 验证与比较

```pascal
var
  Id1, Id2, NilId: TTimeflake;
begin
  Id1 := TimeflakeMonotonic;
  Id2 := TimeflakeMonotonic;

  // 相等检查
  if TimeflakeEquals(Id1, Id2) then
    WriteLn('相等');

  // 比较 (可用于排序)
  case TimeflakeCompare(Id1, Id2) of
    -1: WriteLn('Id1 < Id2');
     0: WriteLn('Id1 = Id2');
     1: WriteLn('Id1 > Id2');
  end;

  // 空值检查
  NilId := TimeflakeNil;
  if TimeflakeIsNil(NilId) then
    WriteLn('空 Timeflake');
end;
```

## 生成器模式

```pascal
var
  Gen: ITimeflakeGenerator;
  Id: TTimeflake;
  S: string;
  Ids: TTimeflakeArray;
begin
  // 创建生成器 (内置单调保证)
  Gen := CreateTimeflakeGenerator;

  // 生成
  Id := Gen.Next;
  S := Gen.NextString;
  Ids := Gen.NextN(100);
end;
```

## 与其他 ID 的对比

| 特性 | Timeflake | UUID v7 | ULID |
|------|-----------|---------|------|
| 大小 | 16 字节 | 16 字节 | 16 字节 |
| 字符串长度 | 22 | 36 | 26 |
| 编码 | Base62 | Hex | Base32 |
| 时间精度 | 毫秒 | 毫秒 | 毫秒 |
| 时间戳位数 | 48 | 48 | 48 |
| 随机位数 | 80 | 74 | 80 |
| 单调支持 | 是 | 是 | 是 |

## API 参考

### 类型

| 类型 | 说明 |
|------|------|
| `TTimeflake` | Timeflake 原始类型 (16 字节数组) |
| `TTimeflakeArray` | Timeflake 数组 |
| `ITimeflakeGenerator` | Timeflake 生成器接口 |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `TIMEFLAKE_SIZE` | 16 | 字节长度 |
| `TIMEFLAKE_STRING_LENGTH` | 22 | Base62 字符串长度 |

### 函数

| 函数 | 说明 |
|------|------|
| `Timeflake: TTimeflake` | 生成 Timeflake |
| `TimeflakeMonotonic: TTimeflake` | 单调生成 |
| `TimeflakeNil: TTimeflake` | 返回空 Timeflake |
| `TimeflakeN(Count): TTimeflakeArray` | 批量生成 |
| `TimeflakeToString(Id): string` | 转换为 Base62 |
| `TimeflakeFromString(S): TTimeflake` | 从 Base62 解析 |
| `TimeflakeToUuidString(Id): string` | 转换为 UUID 格式 |
| `TimeflakeFromUuidString(S): TTimeflake` | 从 UUID 格式解析 |
| `TimeflakeTimestamp(Id): TDateTime` | 提取时间戳 |
| `TimeflakeUnixMs(Id): Int64` | 提取 Unix 毫秒 |
| `TimeflakeEquals(A, B): Boolean` | 相等检查 |
| `TimeflakeCompare(A, B): Integer` | 比较 |
| `TimeflakeIsNil(Id): Boolean` | 空值检查 |
| `CreateTimeflakeGenerator: ITimeflakeGenerator` | 创建生成器 |
