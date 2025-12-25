# fafafa.core.time API 重复评估报告

## 1. 概述

本报告评估 `fafafa.core.time` 模块的 API 表面，识别潜在的重复和优化机会。

## 2. TDuration API 分析

### 2.1 当前 API 统计

| 分类 | 数量 | 方法示例 |
|------|------|----------|
| 单位常量 | 8 | `Nanosecond`, `Microsecond`, `Millisecond`, `Second`, `Minute`, `Hour`, `Day`, `Week` |
| TryFrom* 工厂 | 4 | `TryFromNs`, `TryFromUs`, `TryFromMs`, `TryFromSec` |
| From* 工厂 | 10 | `Zero`, `FromNs`, `FromUs`, `FromMs`, `FromSec`, `FromSecF`, `FromMinutes`, `FromHours`, `FromDays`, `FromWeeks` |
| As* 转换 | 5 | `AsNs`, `AsUs`, `AsMs`, `AsSec`, `AsSecF` |
| Whole* 分解 | 4 | `WholeDays`, `WholeHours`, `WholeMinutes`, `WholeSeconds` |
| Subsec* 分解 | 3 | `SubsecNanos`, `SubsecMicros`, `SubsecMillis` |
| 舍入方法 | 4 | `TruncToUs`, `FloorToUs`, `CeilToUs`, `RoundToUs` |
| 算术运算符 | 8 | `+`, `-`(二元/一元), `*`, `div`, `/` |
| Checked* 方法 | 5 | `CheckedAdd`, `CheckedSub`, `CheckedMul`, `CheckedDiv`, `CheckedModulo` |
| Saturating* 方法 | 2 | `SaturatingMul`, `SaturatingDiv` |
| 查询方法 | 5 | `IsZero`, `IsPositive`, `IsNegative`, `Abs`, `Neg` |
| 约束方法 | 3 | `Clamp`, `Min`, `Max` |
| 序列化 | 2 | `ToISO8601`, `TryParseISO8601` |

### 2.2 评估结论

**状态: ✅ 无需合并**

Duration API 设计合理，遵循以下原则：
1. **一致性**: `From*/As*/TryFrom*` 命名规范统一
2. **安全性**: 提供 `Checked*` 和 `Saturating*` 两种溢出处理策略
3. **可发现性**: 单位常量便于自动补全（`TDuration.Hour`）
4. **对标 Rust**: 与 `std::time::Duration` API 风格一致

唯一的小问题是 `CheckedDivBy` 已标记 `deprecated`，建议在下个主版本移除。

---

## 3. Timer/Scheduler API 分析

### 3.1 ITimerScheduler 方法统计

**TProc 版本（向后兼容）:**
```
ScheduleOnce(Delay, TProc)
ScheduleAt(Deadline, TProc)
ScheduleAtFixedRate(InitialDelay, Period, TProc)
ScheduleWithFixedDelay(InitialDelay, Delay, TProc)
```

**TTimerCallback 版本（v2.0 推荐）:**
```
Schedule(Delay, TTimerCallback)
ScheduleAtCb(Deadline, TTimerCallback)
ScheduleFixedRate(InitialDelay, Period, TTimerCallback)
ScheduleFixedDelay(InitialDelay, Delay, TTimerCallback)
```

**带取消令牌版本（v2.0）:**
```
ScheduleWithToken(Delay, TTimerCallback, Token)
ScheduleFixedRateWithToken(InitialDelay, Period, TTimerCallback, Token)
ScheduleFixedDelayWithToken(InitialDelay, Delay, TTimerCallback, Token)
```

**总计: 11 个调度方法**

### 3.2 ITimerSchedulerTry 方法统计

```
TrySchedule(Delay, TTimerCallback)      -- 2 overloads
TryScheduleAt(Deadline, TProc)
TryScheduleAtCb(Deadline, TTimerCallback)
TryScheduleFixedRate(...)               -- 2 overloads
TryScheduleFixedDelay(...)              -- 2 overloads
```

**总计: 8 个 TrySchedule 方法**

### 3.3 评估结论

**状态: ⚠️ 可以优化但不阻塞**

#### 问题识别

1. **TProc vs TTimerCallback 重复**:
   - 每个调度操作都有两个版本
   - 原因：向后兼容 v1.x 用户

2. **ScheduleAtCb 命名不一致**:
   - `Schedule` vs `ScheduleAtCb` 命名风格不统一
   - 建议：`ScheduleAt(Deadline, TTimerCallback)` 更自然

3. **WithToken 方法可合并**:
   - 可以使用可选参数 `Token: ICancellationToken = nil`
   - 但 FreePascal 接口方法不支持默认参数

#### 推荐方案

**短期（维持现状）:**
- 保持向后兼容
- 在文档中推荐使用 `TTimerCallback` 版本
- 标记 `TProc` 版本为 `deprecated`（下个主版本）

**长期（v3.0）:**
- 移除 `TProc` 版本，统一使用 `TTimerCallback`
- 合并 `WithToken` 版本为默认版本（Token 默认 nil）

---

## 4. 调度器接口分析

### 4.1 当前接口层次

```
ITimerScheduler          -- 基础定时器调度
  └─ ITimerSchedulerTry  -- 添加 Result 风格 API

ITicker                  -- 简化的周期定时器

ITaskScheduler           -- 高级任务调度器
IScheduledTask           -- 调度任务抽象
ICronExpression          -- Cron 表达式
```

### 4.2 评估结论

**状态: ✅ 设计合理**

三层接口各有职责：
- `ITimerScheduler`: 底层定时器，适合简单超时/周期任务
- `ITaskScheduler`: 高级调度，支持优先级/重试/Cron
- `ITicker`: 便捷封装，简化周期任务使用

**不建议合并**：
- 合并会增加接口复杂度
- 用户可根据需求选择合适抽象层

---

## 5. 行动建议

### 5.1 立即执行

- [x] 文档中标注 `TTimerCallback` 为推荐 API
- [ ] 考虑在 v2.1 标记 `TProc` 版本为 `deprecated`

### 5.2 下个主版本 (v3.0)

- [ ] 移除 `TProc` 版本调度方法
- [ ] 移除 `CheckedDivBy`（已 deprecated）
- [ ] 统一 `ScheduleAt` 方法签名

### 5.3 不建议执行

- ❌ 合并 Duration 工厂方法（会降低可读性）
- ❌ 合并 ITimerScheduler 和 ITaskScheduler（职责不同）
- ❌ 移除单位常量（`TDuration.Hour` 等）

---

## 6. 总结

| 模块 | 状态 | 说明 |
|------|------|------|
| TDuration | ✅ 良好 | API 设计规范，无重复 |
| ITimer* | ⚠️ 可优化 | TProc 重复可在 v3.0 清理 |
| ITaskScheduler | ✅ 良好 | 与 ITimerScheduler 职责分离 |
| ICronExpression | ✅ 良好 | 独立接口设计合理 |

**整体评估**: API 表面经过良好设计，当前的"重复"主要是为了向后兼容。建议在 v3.0 版本进行清理，而不是破坏现有用户代码。

---

## 7. 废弃方法统计

> 详细的废弃方法清单和迁移指南请参考：[fafafa.core.time.DEPRECATIONS.md](fafafa.core.time.DEPRECATIONS.md)

### 7.1 当前废弃方法汇总

| 类型 | 废弃数量 | 类别 |
|------|----------|------|
| TInstant | 3 | 比较方法 → 运算符 |
| TDate | 5 | 比较方法 → 运算符 |
| TTimeOfDay | 5 | 比较方法 → 运算符 |
| TDeadline | 3 | 比较方法 → 运算符 |
| TDuration | 1 | 方法重命名 (CheckedDivBy → CheckedDiv) |
| TStopwatch | 1 | 方法重命名 (LapDuration → Lap) |
| **总计** | **18** | |

### 7.2 移除时间表

| 版本 | 动作 |
|------|------|
| v2.x (当前) | 方法标记 `deprecated`，编译产生警告 |
| v3.0 (2026 Q1) | 移除所有废弃方法 |

### 7.3 迁移优先级

1. **高优先级**: `CheckedDivBy` → `CheckedDiv`（命名一致性）
2. **高优先级**: `LapDuration` → `Lap`（简化 API）
3. **中优先级**: 比较方法 → 运算符（功能等价，但运算符更惯用）
