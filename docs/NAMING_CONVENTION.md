# fafafa.core.time 命名约定

本文档说明 fafafa.core.time 模块的 API 命名约定。

## 概述

模块遵循三种主要命名模式：

| 前缀 | 用途 | 示例 |
|------|------|------|
| `From*` | 静态工厂方法，从其他格式构造 | `TDuration.FromMs(1000)` |
| `As*` | 单位转换（同概念，不同单位） | `duration.AsMs` |
| `To*` | 类型转换或格式化 | `date.ToISO8601` |

## 详细说明

### `From*` - 静态工厂方法

用于从外部数据创建类型实例。

```pascal
// 从不同单位创建 TDuration
d := TDuration.FromNs(1000000);   // 纳秒
d := TDuration.FromMs(1000);       // 毫秒
d := TDuration.FromSec(60);        // 秒

// 从其他类型创建
d := TDate.FromDateTime(Now);
d := TDate.FromUnixDays(19000);

// 从字符串解析
w := TIsoWeek.FromDate(TDate.Create(2024, 1, 1));
```

### `As*` - 单位转换

返回相同概念的不同单位表示。**不改变类型**。

主要用于 `TDuration` 和 `TInstant`：

```pascal
var
  d: TDuration;
begin
  d := TDuration.FromSec(90);
  
  WriteLn(d.AsNs);   // 90000000000 (纳秒)
  WriteLn(d.AsUs);   // 90000000 (微秒)
  WriteLn(d.AsMs);   // 90000 (毫秒)
  WriteLn(d.AsSec);  // 90 (秒)
  WriteLn(d.AsSecF); // 90.0 (浮点秒)
end;
```

```pascal
var
  i: TInstant;
begin
  i := TInstant.Now;
  
  WriteLn(i.AsNsSinceEpoch);  // 纳秒时间戳
  WriteLn(i.AsUnixMs);        // Unix 毫秒时间戳
  WriteLn(i.AsUnixSec);       // Unix 秒时间戳
end;
```

### `To*` - 类型转换或格式化

转换为不同类型或字符串格式。

```pascal
// 转换为字符串
s := date.ToISO8601;       // "2024-06-15"
s := duration.ToString;    // "1h 30m"

// 转换为其他类型
dt := date.ToDateTime;     // TDate -> TDateTime
d  := timeofday.ToDuration; // TTimeOfDay -> TDuration
```

## 历史原因：`TTimeOfDay` 的 `To*` 方法

`TTimeOfDay` 使用 `To*` 而非 `As*` 获取单位值：

```pascal
t := TTimeOfDay.Create(14, 30, 45);
WriteLn(t.ToMilliseconds);  // 而非 AsMilliseconds
WriteLn(t.ToSeconds);       // 而非 AsSeconds
```

这是为了保持与 `ToTime`（返回 `TTime` 类型）和 `ToDuration`（返回 `TDuration` 类型）的命名一致性。

⚠️ **注意**：这与 `TDuration.AsMs` 等不一致，但修改会导致 Breaking Change，因此保留现状。

## 命名规范总结

### 使用 `From*` 当：
- 创建新实例
- 从外部数据源构造
- 是 `class function`（静态方法）

### 使用 `As*` 当：
- 返回相同概念的不同单位
- 返回值是数值类型（Int64, Double）
- 不改变原始类型的语义

### 使用 `To*` 当：
- 转换为不同类型
- 格式化为字符串
- 返回完全不同的数据结构

## 相关 ISSUE

- ISSUE-11: 记录此命名约定，不做代码修改以避免 Breaking Change
