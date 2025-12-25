# fafafa.core.time 废弃方法清理时间表

> 最后更新: 2025-12-25

## 概述

本文档记录 `fafafa.core.time` 模块中所有已废弃（deprecated）的方法，以及它们的迁移指南和移除时间表。

## 废弃时间线

| 版本 | 状态 |
|------|------|
| v2.x | 方法标记为 `deprecated`，编译时产生警告 |
| v3.0 | 计划移除所有废弃方法（预计 2026 Q1） |

---

## 1. 比较方法 → 运算符迁移

### 影响范围

以下类型的 `Equal`、`LessThan`、`GreaterThan`、`LessOrEqual`、`GreaterOrEqual` 方法已废弃：

| 类型 | 废弃方法 | 替代运算符 |
|------|----------|------------|
| TInstant | `Equal(B)` | `A = B` |
| TInstant | `LessThan(B)` | `A < B` |
| TInstant | `GreaterThan(B)` | `A > B` |
| TDate | `Equal(B)` | `A = B` |
| TDate | `LessThan(B)` | `A < B` |
| TDate | `LessOrEqual(B)` | `A <= B` |
| TDate | `GreaterThan(B)` | `A > B` |
| TDate | `GreaterOrEqual(B)` | `A >= B` |
| TTimeOfDay | `Equal(B)` | `A = B` |
| TTimeOfDay | `LessThan(B)` | `A < B` |
| TTimeOfDay | `LessOrEqual(B)` | `A <= B` |
| TTimeOfDay | `GreaterThan(B)` | `A > B` |
| TTimeOfDay | `GreaterOrEqual(B)` | `A >= B` |
| TDeadline | `Equal(B)` | `A = B` |
| TDeadline | `LessThan(B)` | `A < B` |
| TDeadline | `GreaterThan(B)` | `A > B` |

### 迁移示例

```pascal
// 旧代码（废弃）
if t1.LessThan(t2) then
  DoSomething;

if d1.Equal(d2) then
  DoSomething;

// 新代码（推荐）
if t1 < t2 then
  DoSomething;

if d1 = d2 then
  DoSomething;
```

### 废弃原因

- 运算符语法更直观、更符合 Pascal 习惯
- 减少 API 表面复杂度
- 运算符与方法功能完全等价

---

## 2. TDuration.CheckedDivBy → CheckedDiv

### 影响范围

| 类型 | 废弃方法 | 替代方法 |
|------|----------|----------|
| TDuration | `CheckedDivBy(Divisor, R)` | `CheckedDiv(Divisor, R)` |

### 迁移示例

```pascal
// 旧代码（废弃）
if d.CheckedDivBy(2, result) then
  WriteLn(result.AsMs);

// 新代码（推荐）
if d.CheckedDiv(2, result) then
  WriteLn(result.AsMs);
```

### 废弃原因

- 命名统一：`CheckedAdd`、`CheckedSub`、`CheckedMul`、`CheckedDiv`、`CheckedModulo`
- `CheckedDivBy` 命名风格与其他 Checked* 方法不一致

---

## 3. Timer TProc 回调 → TTimerCallback

### 影响范围

以下 `ITimerScheduler` 和 `ITimerSchedulerTry` 接口方法中使用 `TProc` 的版本已废弃：

| 接口 | 废弃方法 | 替代方法 |
|------|----------|----------|
| ITimerScheduler | `ScheduleOnce(Delay, TProc)` | `Schedule(Delay, TTimerCallback)` |
| ITimerScheduler | `ScheduleAt(Deadline, TProc)` | `ScheduleAtCb(Deadline, TTimerCallback)` |
| ITimerScheduler | `ScheduleAtFixedRate(InitialDelay, Period, TProc)` | `ScheduleFixedRate(InitialDelay, Period, TTimerCallback)` |
| ITimerScheduler | `ScheduleWithFixedDelay(InitialDelay, Delay, TProc)` | `ScheduleFixedDelay(InitialDelay, Delay, TTimerCallback)` |
| ITimerSchedulerTry | `TrySchedule(Delay, TProc)` | `TrySchedule(Delay, TTimerCallback)` |
| ITimerSchedulerTry | `TryScheduleAt(Deadline, TProc)` | `TryScheduleAtCb(Deadline, TTimerCallback)` |
| ITimerSchedulerTry | `TryScheduleFixedRate(..., TProc)` | `TryScheduleFixedRate(..., TTimerCallback)` |
| ITimerSchedulerTry | `TryScheduleFixedDelay(..., TProc)` | `TryScheduleFixedDelay(..., TTimerCallback)` |

### TTimerCallback 类型

```pascal
TTimerCallbackKind = (
  tckProc,        // procedure
  tckProcData,    // procedure(Data: Pointer)
  tckMethod,      // procedure of object
  tckNested       // procedure is nested
);

TTimerCallback = record
  case Kind: TTimerCallbackKind of
    tckProc: (Proc: TTimerProc);
    tckProcData: (ProcData: TTimerProcData; Data: Pointer);
    tckMethod: (Method: TTimerMethod);
    tckNested: (Nested: TTimerProcNested);
end;
```

### 辅助函数

使用 `fafafa.core.time.timer.callback` 中的辅助函数创建 TTimerCallback：

```pascal
uses fafafa.core.time.timer.callback;

// 从 TProc 创建
var cb: TTimerCallback;
cb := TimerCallback(MyProc);

// 从带数据的过程创建
cb := TimerCallback(MyProcWithData, @MyData);

// 从对象方法创建
cb := TimerCallback(@MyObject.MyMethod);

// 从嵌套过程创建
cb := TimerCallbackNested(@MyNestedProc);
```

### 迁移示例

```pascal
// 旧代码（废弃）
scheduler.ScheduleOnce(TDuration.FromSecs(5), @MyCallback);
scheduler.ScheduleAtFixedRate(TDuration.FromSecs(1), TDuration.FromMs(100), @MyCallback);

// 新代码（推荐）
uses fafafa.core.time.timer.callback;

scheduler.Schedule(TDuration.FromSecs(5), TimerCallback(@MyCallback));
scheduler.ScheduleFixedRate(TDuration.FromSecs(1), TDuration.FromMs(100), TimerCallback(@MyCallback));

// 带数据的回调
scheduler.Schedule(TDuration.FromSecs(5), TimerCallback(@MyDataCallback, @MyData));

// 对象方法回调
scheduler.Schedule(TDuration.FromSecs(5), TimerCallback(@Self.OnTimer));
```

### 废弃原因

- **类型安全**: `TTimerCallback` 支持多种回调类型（过程、带数据过程、对象方法、嵌套过程）
- **统一 API**: 所有定时器方法使用同一回调类型，减少方法重载数量
- **扩展性**: 未来可以轻松添加新的回调类型而不增加接口方法

---

## 4. TStopwatch.LapDuration → Lap

### 影响范围

| 类型 | 废弃方法 | 替代方法 |
|------|----------|----------|
| TStopwatch | `LapDuration` | `Lap` |

### 迁移示例

```pascal
// 旧代码（废弃）
var lapTime: TDuration;
lapTime := sw.LapDuration;

// 新代码（推荐）
var lapTime: TDuration;
lapTime := sw.Lap;
```

### 废弃原因

- 方法名过长，`Lap` 更简洁
- 返回类型已经是 `TDuration`，无需重复命名

---

## 移除计划

### v3.0 移除清单

在 v3.0 版本中，以下方法将被完全移除：

1. **TInstant**
   - `LessThan`
   - `GreaterThan`
   - `Equal`

2. **TDate**
   - `Equal`
   - `LessThan`
   - `LessOrEqual`
   - `GreaterThan`
   - `GreaterOrEqual`

3. **TTimeOfDay**
   - `Equal`
   - `LessThan`
   - `LessOrEqual`
   - `GreaterThan`
   - `GreaterOrEqual`

4. **TDeadline**
   - `Equal`
   - `LessThan`
   - `GreaterThan`

5. **TDuration**
   - `CheckedDivBy`

6. **TStopwatch**
   - `LapDuration`

7. **ITimerScheduler** (TProc 版本)
   - `ScheduleOnce(Delay, TProc)`
   - `ScheduleAt(Deadline, TProc)`
   - `ScheduleAtFixedRate(InitialDelay, Period, TProc)`
   - `ScheduleWithFixedDelay(InitialDelay, Delay, TProc)`

8. **ITimerSchedulerTry** (TProc 版本)
   - `TrySchedule(Delay, TProc)`
   - `TryScheduleAt(Deadline, TProc)`
   - `TryScheduleFixedRate(InitialDelay, Period, TProc)`
   - `TryScheduleFixedDelay(InitialDelay, Delay, TProc)`

### 迁移检查工具

在升级到 v3.0 之前，可以使用编译器警告检测废弃方法：

```bash
# 编译时显示所有警告
fpc -vw -O3 your_project.pas
```

所有使用废弃方法的代码将产生如下警告：

```
Warning: Symbol "LessThan" is deprecated: "Use operator < instead"
Warning: Symbol "CheckedDivBy" is deprecated: "Use CheckedDiv instead"
Warning: Symbol "ScheduleOnce" is deprecated: "Use Schedule(Delay, TimerCallback(Callback)) instead"
Warning: Symbol "ScheduleAtFixedRate" is deprecated: "Use ScheduleFixedRate(InitialDelay, Period, TimerCallback(Callback)) instead"
```

---

## 向后兼容性说明

- **v2.x**: 所有废弃方法仍然可用，但会产生编译警告
- **v3.0**: 废弃方法将被移除，使用这些方法的代码将无法编译

建议在 v2.x 版本周期内完成所有迁移，以确保平滑升级到 v3.0。

---

## 参考

- [fafafa.core.time API 评审报告](fafafa.core.time.api-review.md)
- [fafafa.core.time 模块文档](fafafa.core.time.md)
