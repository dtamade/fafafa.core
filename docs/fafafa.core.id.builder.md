# fafafa.core.id.builder 模块说明

Builder 模块提供统一的流式 API 用于配置和生成各种 ID。

## 特性

- 流式 API (Fluent Interface)
- 统一的入口点 `TIdBuilder`
- 类型安全的配置选项
- 支持 UUID、ULID、KSUID、Snowflake
- 对标 Rust Builder 模式

## 快速开始

```pascal
uses fafafa.core.id.builder;

var
  Uuid: TUuid128;
  Ulid: TUlid128;
  Id: TSnowflakeID;
begin
  // UUID v4
  Uuid := TIdBuilder.UUID.V4.Build;

  // UUID v7 单调
  Uuid := TIdBuilder.UUID.V7.Monotonic.Build;

  // ULID 带溢出策略
  Ulid := TIdBuilder.ULID.WaitOnOverflow.Build;

  // Snowflake 带自定义配置
  Id := TIdBuilder.Snowflake.WorkerId(42).DiscordEpoch.Build;
end;
```

## UUID Builder

### 基本使用

```pascal
var
  Uuid: TUuid128;
  S: string;
begin
  // 各版本 UUID
  Uuid := TIdBuilder.UUID.V4.Build;                          // 随机
  Uuid := TIdBuilder.UUID.V6.Build;                          // 时间有序
  Uuid := TIdBuilder.UUID.V7.Build;                          // 时间有序 (推荐)
  Uuid := TIdBuilder.UUID.V7.Monotonic.Build;                // 单调递增

  // 获取字符串
  S := TIdBuilder.UUID.V7.BuildStr;
end;
```

### UUID v5 (命名空间)

```pascal
var
  Uuid: TUuid128;
begin
  // 使用预定义命名空间
  Uuid := TIdBuilder.UUID.V5
    .Namespace(nsDNS)
    .Name('example.com')
    .Build;

  // 使用自定义命名空间
  Uuid := TIdBuilder.UUID.V5
    .CustomNamespace(MyNamespaceUuid)
    .Name('my-entity')
    .Build;
end;
```

## ULID Builder

```pascal
var
  Ulid: TUlid128;
begin
  // 默认单调 ULID
  Ulid := TIdBuilder.ULID.Build;

  // 非单调
  Ulid := TIdBuilder.ULID.Monotonic(False).Build;

  // 溢出策略
  Ulid := TIdBuilder.ULID.WaitOnOverflow.Build;    // 等待下一毫秒
  Ulid := TIdBuilder.ULID.WrapOnOverflow.Build;    // 序列回绕
  Ulid := TIdBuilder.ULID.ErrorOnOverflow.Build;   // 抛出异常
end;
```

## KSUID Builder

```pascal
var
  Ksuid: TKsuid160;
begin
  // 标准 KSUID (秒级精度)
  Ksuid := TIdBuilder.KSUID.Standard.Build;

  // 高精度 KSUID (毫秒级)
  Ksuid := TIdBuilder.KSUID.Millisecond.Build;
  Ksuid := TIdBuilder.KSUID.HighPrecision.Build;
end;
```

## Snowflake Builder

```pascal
var
  Id: TSnowflakeID;
  Gen: ISnowflake;
begin
  // 基本配置
  Id := TIdBuilder.Snowflake
    .WorkerId(1)
    .Build;

  // 使用 Discord 时间纪元
  Id := TIdBuilder.Snowflake
    .WorkerId(42)
    .DiscordEpoch
    .Build;

  // 使用 Twitter 时间纪元
  Id := TIdBuilder.Snowflake
    .WorkerId(1)
    .TwitterEpoch
    .Build;

  // 自定义纪元
  Id := TIdBuilder.Snowflake
    .WorkerId(1)
    .Epoch(1609459200000)  // 2021-01-01
    .Build;

  // 无锁版本 + 时钟回拨策略
  Gen := TIdBuilder.Snowflake
    .WorkerId(1)
    .LockFree
    .ClockPolicy(crpSpinWait)
    .BuildGenerator;
end;
```

## 预定义时间纪元

| 方法 | 时间戳 (ms) | 日期 |
|------|-------------|------|
| `TwitterEpoch` | 1288834974657 | 2010-11-04 |
| `DiscordEpoch` | 1420070400000 | 2015-01-01 |

## 时钟回拨策略

| 策略 | 说明 |
|------|------|
| `crpSpinWait` | 自旋等待时钟追上 |
| `crpError` | 抛出异常 |
| `crpSequenceWrap` | 使用上次时间戳 |

## 完整示例

```pascal
uses fafafa.core.id.builder;

procedure GenerateIds;
var
  UuidV4: TUuid128;
  UuidV7: TUuid128;
  Ulid: TUlid128;
  Ksuid: TKsuid160;
  Snowflake: TSnowflakeID;
begin
  // 各类 ID 生成
  UuidV4 := TIdBuilder.UUID.V4.Build;

  UuidV7 := TIdBuilder.UUID.V7.Monotonic.Build;

  Ulid := TIdBuilder.ULID.WaitOnOverflow.Build;

  Ksuid := TIdBuilder.KSUID.Millisecond.Build;

  Snowflake := TIdBuilder.Snowflake
    .WorkerId(1)
    .DiscordEpoch
    .LockFree
    .Build;

  // 打印字符串格式
  WriteLn('UUID v4: ', TIdBuilder.UUID.V4.BuildStr);
  WriteLn('UUID v7: ', TIdBuilder.UUID.V7.BuildStr);
  WriteLn('ULID: ', TIdBuilder.ULID.BuildStr);
  WriteLn('KSUID: ', TIdBuilder.KSUID.BuildStr);
end;
```

## API 参考

### TIdBuilder (入口点)

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `UUID` | `TUuidBuilder` | 创建 UUID Builder |
| `ULID` | `TUlidBuilder` | 创建 ULID Builder |
| `KSUID` | `TKsuidBuilder` | 创建 KSUID Builder |
| `Snowflake` | `TSnowflakeBuilder` | 创建 Snowflake Builder |

### TUuidBuilder

| 方法 | 说明 |
|------|------|
| `Version(V)` | 设置 UUID 版本 |
| `V4` / `V5` / `V6` / `V7` | 快捷版本设置 |
| `Monotonic(Enabled)` | 启用单调生成 (V7) |
| `Namespace(NS)` | 设置命名空间 (V5) |
| `CustomNamespace(NS)` | 设置自定义命名空间 (V5) |
| `Name(AName)` | 设置名称 (V5) |
| `Build: TUuid128` | 生成 UUID |
| `BuildStr: string` | 生成字符串 |

### TUlidBuilder

| 方法 | 说明 |
|------|------|
| `Monotonic(Enabled)` | 启用单调生成 |
| `OverflowPolicy(Policy)` | 设置溢出策略 |
| `WaitOnOverflow` | 溢出时等待 |
| `WrapOnOverflow` | 溢出时回绕 |
| `ErrorOnOverflow` | 溢出时抛异常 |
| `Build: TUlid128` | 生成 ULID |
| `BuildStr: string` | 生成字符串 |

### TKsuidBuilder

| 方法 | 说明 |
|------|------|
| `HighPrecision(Enabled)` | 启用毫秒精度 |
| `Monotonic(Enabled)` | 启用单调生成 |
| `Standard` | 使用标准 KSUID |
| `Millisecond` | 使用毫秒精度 |
| `Build: TKsuid160` | 生成 KSUID |
| `BuildStr: string` | 生成字符串 |

### TSnowflakeBuilder

| 方法 | 说明 |
|------|------|
| `WorkerId(Id)` | 设置 Worker ID (0-1023) |
| `Epoch(Ms)` | 设置自定义纪元 |
| `TwitterEpoch` | 使用 Twitter 纪元 |
| `DiscordEpoch` | 使用 Discord 纪元 |
| `LockFree(Enabled)` | 启用无锁版本 |
| `ClockPolicy(Policy)` | 设置时钟回拨策略 |
| `Build: TSnowflakeID` | 生成单个 ID |
| `BuildGenerator: ISnowflake` | 创建生成器 |
