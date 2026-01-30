# ISO 8601 日期时间处理 - 使用指南

## 概述

`fafafa.core.time.iso8601` 单元提供完整的 ISO 8601 标准支持，包括日期、时间、持续时间的格式化和解析功能。

## 功能特性

✅ **完整的 ISO 8601:2004 标准支持**
- 日期格式：基本日期、周日期、序数日期
- 时间格式：带时区、小数秒、UTC
- 持续时间格式：P notation (例如：P1Y2M3DT4H5M6S)
- 时区支持：±HH:MM、±HHMM、±HH、Z
- 格式化和解析双向支持

## 快速开始

### 引用单元

```pascal
uses
  fafafa.core.time,
  fafafa.core.time.iso8601;
```

## 日期时间格式化

### 基本日期时间格式化

```pascal
var
  DT: TDateTime;
  S: string;
begin
  DT := Now;
  
  // 使用默认选项（扩展格式，无时区）
  S := TISO8601Formatter.FormatDateTime(DT);
  // 输出: 2023-12-25T14:30:45.123
  
  // 使用 UTC 格式
  S := TISO8601Formatter.FormatDateTime(DT, TISO8601Options.UTC);
  // 输出: 2023-12-25T14:30:45.123Z
  
  // 使用时区
  S := TISO8601Formatter.FormatDateTime(DT, TISO8601Options.WithTimeZone);
  // 输出: 2023-12-25T14:30:45.123+08:00
end;
```

### 只格式化日期

```pascal
var
  D: TDateTime;
  S: string;
begin
  D := EncodeDate(2023, 12, 25);
  
  // 扩展格式
  S := TISO8601Formatter.FormatDate(D, idfExtended);
  // 输出: 2023-12-25
  
  // 基本格式
  S := TISO8601Formatter.FormatDate(D, idfBasic);
  // 输出: 20231225
  
  // 周日期格式
  S := TISO8601Formatter.FormatWeekDate(D, False); // 扩展
  // 输出: 2023-W52-1
  
  S := TISO8601Formatter.FormatWeekDate(D, True);  // 基本
  // 输出: 2023W521
  
  // 序数日期格式
  S := TISO8601Formatter.FormatOrdinalDate(D, False);
  // 输出: 2023-359
end;
```

### 只格式化时间

```pascal
var
  T: TDateTime;
  S: string;
begin
  T := EncodeTime(14, 30, 45, 123);
  
  // 扩展格式，无小数秒
  S := TISO8601Formatter.FormatTime(T, itfExtended, 0);
  // 输出: 14:30:45
  
  // 扩展格式，3位小数秒
  S := TISO8601Formatter.FormatTime(T, itfExtended, 3);
  // 输出: 14:30:45.123
  
  // 基本格式
  S := TISO8601Formatter.FormatTime(T, itfBasic, 0);
  // 输出: 143045
end;
```

## 日期时间解析

### 解析日期时间

```pascal
var
  DT: TDateTime;
  Success: Boolean;
begin
  // 解析完整的日期时间
  Success := TISO8601Parser.ParseDateTime('2023-12-25T14:30:45', DT);
  if Success then
    WriteLn('解析成功: ', DateTimeToStr(DT));
  
  // 解析带时区的日期时间
  Success := TISO8601Parser.ParseDateTime('2023-12-25T14:30:45+08:00', DT);
  
  // 解析 UTC 日期时间
  Success := TISO8601Parser.ParseDateTime('2023-12-25T14:30:45Z', DT);
end;
```

### 解析日期

```pascal
var
  D: TDateTime;
  Success: Boolean;
begin
  // 解析扩展格式日期
  Success := TISO8601Parser.ParseDate('2023-12-25', D);
  
  // 解析基本格式日期
  Success := TISO8601Parser.ParseDate('20231225', D);
  
  // 解析周日期
  Success := TISO8601Parser.ParseWeekDate('2023-W52-1', D);
  
  // 解析序数日期
  Success := TISO8601Parser.ParseOrdinalDate('2023-359', D);
end;
```

### 解析时间

```pascal
var
  T: TDateTime;
  Success: Boolean;
begin
  // 解析扩展格式时间
  Success := TISO8601Parser.ParseTime('14:30:45', T);
  
  // 解析基本格式时间
  Success := TISO8601Parser.ParseTime('143045', T);
  
  // 解析带小数秒的时间
  Success := TISO8601Parser.ParseTime('14:30:45.123', T);
end;
```

## 持续时间（Duration）

### 格式化持续时间

```pascal
var
  D: TDuration;
  S: string;
begin
  // 简单持续时间
  D := TDuration.FromHours(2) + TDuration.FromMinutes(30);
  S := TISO8601Formatter.FormatDuration(D);
  // 输出: PT2H30M
  
  // 复杂持续时间
  D := TDuration.FromDays(1) + TDuration.FromHours(2) + 
       TDuration.FromMinutes(30) + TDuration.FromSec(45);
  S := TISO8601Formatter.FormatDuration(D);
  // 输出: P1DT2H30M45S
  
  // 带小数秒的持续时间
  D := TDuration.FromSec(45) + TDuration.FromMs(500);
  S := TISO8601Formatter.FormatDuration(D);
  // 输出: PT45.5S
end;
```

### 解析持续时间

```pascal
var
  D: TDuration;
  Success: Boolean;
begin
  // 解析简单持续时间
  Success := TISO8601Parser.ParseDuration('PT2H30M', D);
  if Success then
    WriteLn('持续时间（秒）: ', D.AsSec);
  
  // 解析复杂持续时间
  Success := TISO8601Parser.ParseDuration('P1DT2H30M45S', D);
  
  // 解析带小数的持续时间
  Success := TISO8601Parser.ParseDuration('PT1.5S', D);
  // 结果: 1500 毫秒
end;
```

## 时区处理

### 格式化时区

```pascal
var
  S: string;
begin
  // UTC
  S := TISO8601Formatter.FormatTimeZone(0, itzUTC);
  // 输出: Z
  
  // 扩展格式时区偏移
  S := TISO8601Formatter.FormatTimeZone(480, itzExtended);  // +8:00
  // 输出: +08:00
  
  S := TISO8601Formatter.FormatTimeZone(-300, itzExtended); // -5:00
  // 输出: -05:00
  
  // 基本格式时区偏移
  S := TISO8601Formatter.FormatTimeZone(480, itzBasic);
  // 输出: +0800
  
  // 只有小时的时区偏移
  S := TISO8601Formatter.FormatTimeZone(480, itzHourOnly);
  // 输出: +08
end;
```

### 解析时区

```pascal
var
  Offset, Pos: Integer;
  Success: Boolean;
begin
  // 从完整的日期时间字符串中解析时区
  Success := TISO8601Parser.ParseTimeZone('2023-12-25T14:30:45+08:00', Offset, Pos);
  if Success then
  begin
    WriteLn('时区偏移（分钟）: ', Offset);  // 输出: 480
    WriteLn('时区开始位置: ', Pos);        // 输出: 20
  end;
  
  // 解析 UTC
  Success := TISO8601Parser.ParseTimeZone('2023-12-25T14:30:45Z', Offset, Pos);
  // Offset = 0
  
  // 解析负时区
  Success := TISO8601Parser.ParseTimeZone('2023-12-25T14:30:45-05:00', Offset, Pos);
  // Offset = -300
end;
```

## 便捷函数

单元还提供了一些便捷函数，用于常见操作：

```pascal
var
  DT: TDateTime;
  D: TDuration;
  S: string;
begin
  // 日期时间转 ISO 8601 字符串
  S := ISO8601DateTimeToString(Now);
  S := ISO8601DateTimeToStringUTC(Now);
  S := ISO8601DateTimeToStringWithTZ(Now);
  
  // 日期转 ISO 8601 字符串
  S := ISO8601DateToString(Date);
  S := ISO8601WeekDateToString(Date);
  S := ISO8601OrdinalDateToString(Date);
  
  // 时间转 ISO 8601 字符串
  S := ISO8601TimeToString(Time);
  S := ISO8601TimeToStringWithFraction(Time, 3);
  
  // 持续时间转 ISO 8601 字符串
  D := TDuration.FromHours(2);
  S := ISO8601DurationToString(D);
  
  // ISO 8601 字符串转日期时间
  DT := ISO8601StringToDateTime('2023-12-25T14:30:45');
  if TryISO8601StringToDateTime('2023-12-25T14:30:45', DT) then
    WriteLn('解析成功');
  
  // ISO 8601 字符串转持续时间
  D := ISO8601StringToDuration('PT2H30M');
  if TryISO8601StringToDuration('PT2H30M', D) then
    WriteLn('解析成功');
end;
```

## 高级配置

### 自定义格式选项

```pascal
var
  DT: TDateTime;
  Opts: TISO8601Options;
  S: string;
begin
  DT := Now;
  
  // 创建自定义选项
  Opts := TISO8601Options.Default;
  Opts.DateFormat := idfBasic;        // 基本日期格式
  Opts.TimeFormat := itfBasicFraction; // 基本时间格式 + 小数秒
  Opts.FractionalSeconds := 6;        // 6 位小数秒
  Opts.TimeZoneFormat := itzExtended;  // 扩展时区格式
  Opts.UseUTC := False;
  
  S := TISO8601Formatter.FormatDateTime(DT, Opts);
  // 输出: 20231225T143045.123456+08:00
end;
```

## 支持的格式

### 日期格式
- **基本日期**: `YYYYMMDD` (例如：20231225)
- **扩展日期**: `YYYY-MM-DD` (例如：2023-12-25)
- **周日期（基本）**: `YYYYWwwD` (例如：2023W521)
- **周日期（扩展）**: `YYYY-Www-D` (例如：2023-W52-1)
- **序数日期（基本）**: `YYYYDDD` (例如：2023359)
- **序数日期（扩展）**: `YYYY-DDD` (例如：2023-359)

### 时间格式
- **基本时间**: `HHmmss` (例如：143045)
- **扩展时间**: `HH:mm:ss` (例如：14:30:45)
- **带小数秒**: `HH:mm:ss.fff` (例如：14:30:45.123)

### 时区格式
- **UTC**: `Z`
- **扩展偏移**: `±HH:MM` (例如：+08:00, -05:00)
- **基本偏移**: `±HHMM` (例如：+0800, -0500)
- **仅小时**: `±HH` (例如：+08, -05)

### 持续时间格式 (P Notation)
- **年月周天**: `P1Y2M3W4D`
- **时分秒**: `PT1H2M3S`
- **组合**: `P1Y2M3DT4H5M6S`
- **带小数**: `PT1.5H`, `PT30.5S`

## 测试覆盖

✅ 所有 60 个 ISO 8601 测试全部通过：
- 日期时间测试：34 个
- 持续时间测试：18 个
- 边界情况测试：8 个

包括：
- 闰年处理
- 第 53 周
- 第 366 天
- 极端时区偏移
- 往返转换（格式化 → 解析 → 格式化）

## 注意事项

1. **时区处理**: 解析带时区的日期时间时，结果会自动转换为本地时间
2. **持续时间精度**: 年和月的转换使用近似值（1年 ≈ 365.25天，1月 ≈ 30.44天）
3. **周日期**: ISO 8601 周从星期一开始（1=星期一，7=星期日）
4. **往返精度**: 对于带时区的日期时间，往返转换可能有小的舍入误差

## 相关资源

- [ISO 8601 标准](https://en.wikipedia.org/wiki/ISO_8601)
- [fafafa.core.time 模块文档](./TIME_MODULE.md)
- [TDuration API 参考](./DURATION_API.md)

## 示例项目

完整的示例代码请参考：
- `tests/fafafa.core.time/Test_iso8601.pas` - 所有 ISO 8601 功能的测试用例
- `tests/fafafa.core.time/Test_iso8601_examples.pas` - 实用示例集合

---

**版本**: 1.0.0  
**最后更新**: 2025-01-02  
**作者**: fafafaStudio
