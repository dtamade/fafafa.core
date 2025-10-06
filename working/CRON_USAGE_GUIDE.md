# 📅 Cron 表达式使用指南

**模块**: `fafafa.core.time.scheduler`  
**版本**: 1.0.0  
**日期**: 2025-10-05

---

## 📋 目录

1. [概述](#概述)
2. [Cron 语法](#cron-语法)
3. [字段说明](#字段说明)
4. [语法示例](#语法示例)
5. [使用示例](#使用示例)
6. [常用表达式](#常用表达式)
7. [API 参考](#api-参考)
8. [最佳实践](#最佳实践)

---

## 概述

Cron 表达式是一种用于描述定时任务执行时间的标准格式。`fafafa.core.time.scheduler` 模块实现了完整的 Cron 表达式解析和调度功能。

### 特性

- ✅ 标准 5 字段 Cron 格式
- ✅ 支持通配符 (`*`)
- ✅ 支持范围 (`1-5`)
- ✅ 支持列表 (`1,3,5`)
- ✅ 支持步长 (`*/5`, `1-10/2`)
- ✅ 自动处理月末和闰年
- ✅ 线程安全

---

## Cron 语法

### 基本格式

```
分钟 小时 日 月 星期
```

5个字段，用空格分隔。

### 字段范围

| 字段 | 范围 | 说明 |
|------|------|------|
| 分钟 | 0-59 | 一小时中的分钟 |
| 小时 | 0-23 | 一天中的小时（24小时制） |
| 日 | 1-31 | 一个月中的第几天 |
| 月 | 1-12 | 一年中的第几月 |
| 星期 | 0-6 | 一周中的第几天（0=周日，1=周一，...，6=周六） |

---

## 字段说明

### 1. 通配符 (`*`)

匹配该字段的所有可能值。

```
* * * * *    # 每分钟执行
```

### 2. 具体值

指定一个具体的值。

```
5 10 * * *   # 每天10:05执行
```

### 3. 范围 (`-`)

指定一个值的范围（包含首尾）。

```
0 9-17 * * *   # 每天9:00到17:00之间每小时执行
```

### 4. 列表 (`,`)

列出多个具体值。

```
0 8,12,18 * * *   # 每天8:00、12:00、18:00执行
```

### 5. 步长 (`/`)

指定间隔步长。

```
*/15 * * * *      # 每15分钟执行（0, 15, 30, 45）
10-50/10 * * * *  # 每小时的10、20、30、40、50分钟执行
```

---

## 语法示例

### 简单示例

```
# 每分钟
* * * * *

# 每小时整点
0 * * * *

# 每天午夜
0 0 * * *

# 每周日午夜
0 0 * * 0

# 每月1号午夜
0 0 1 * *
```

### 组合示例

```
# 每5分钟
*/5 * * * *

# 工作日上午9点
0 9 * * 1-5

# 周末上午10点
0 10 * * 0,6

# 每月1号和15号的中午
0 12 1,15 * *

# 每个工作日的每2小时（9-17点）
0 9-17/2 * * 1-5
```

### 复杂示例

```
# 每天早上8点到晚上8点，每30分钟
0,30 8-20 * * *

# 每周一、三、五的上午10点和下午3点
0 10,15 * * 1,3,5

# 每个季度的第一天（1月、4月、7月、10月的1号）
0 0 1 1,4,7,10 *
```

---

## 使用示例

### 1. 基本使用

```pascal
uses
  fafafa.core.time.scheduler;

var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  // 创建调度器
  scheduler := CreateTaskScheduler;
  scheduler.Start;
  
  // 创建任务
  task := scheduler.CreateTask('MyCronTask', 
    procedure(const ATask: IScheduledTask)
    begin
      WriteLn('Cron task executed at: ', DateTimeToStr(Now));
    end
  );
  
  // 使用 Cron 表达式调度（每5分钟）
  scheduler.ScheduleCron(task, '*/5 * * * *');
  
  // 保持程序运行...
end;
```

### 2. 验证 Cron 表达式

```pascal
var
  cron: ICronExpression;
begin
  // 创建 Cron 表达式
  cron := CreateCronExpression('*/5 * * * *');
  
  // 检查是否有效
  if cron.IsValid then
    WriteLn('Valid cron expression')
  else
    WriteLn('Invalid: ', cron.GetDescription);
end;
```

### 3. 计算下次执行时间

```pascal
var
  cron: ICronExpression;
  nextTime: TInstant;
  nextDT: TDateTime;
begin
  cron := CreateCronExpression('0 9 * * 1-5');
  
  // 获取下次执行时间
  nextTime := cron.GetNextTime;
  
  // 转换为 TDateTime 显示
  nextDT := UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000, False);
  WriteLn('Next execution: ', DateTimeToStr(nextDT));
end;
```

### 4. 获取未来多次执行时间

```pascal
var
  cron: ICronExpression;
  times: specialize TArray<TInstant>;
  i: Integer;
  dt: TDateTime;
begin
  cron := CreateCronExpression('0 */2 * * *'); // 每2小时
  
  // 获取未来10次执行时间
  times := cron.GetNextTimes(10);
  
  for i := 0 to High(times) do
  begin
    dt := UnixToDateTime(times[i].AsNsSinceEpoch div 1000000000, False);
    WriteLn(Format('Execution %d: %s', [i + 1, DateTimeToStr(dt)]));
  end;
end;
```

### 5. 检查时间是否匹配

```pascal
var
  cron: ICronExpression;
  testTime: TInstant;
  testDT: TDateTime;
begin
  cron := CreateCronExpression('0 * * * *'); // 每小时整点
  
  testDT := EncodeDateTime(2025, 1, 1, 10, 0, 0, 0);
  testTime := TInstant.FromNsSinceEpoch(
    UInt64(DateTimeToUnix(testDT, False) * 1000000000)
  );
  
  if cron.Matches(testTime) then
    WriteLn('Time matches cron expression')
  else
    WriteLn('Time does not match');
end;
```

---

## 常用表达式

### 时间间隔

```pascal
const
  // 每分钟
  CRON_EVERY_MINUTE = '* * * * *';
  
  // 每5分钟
  CRON_EVERY_5_MINUTES = '*/5 * * * *';
  
  // 每15分钟
  CRON_EVERY_15_MINUTES = '*/15 * * * *';
  
  // 每30分钟
  CRON_EVERY_30_MINUTES = '0,30 * * * *';
  
  // 每小时
  CRON_EVERY_HOUR = '0 * * * *';
  
  // 每2小时
  CRON_EVERY_2_HOURS = '0 */2 * * *';
```

### 每日任务

```pascal
const
  // 每天午夜
  CRON_MIDNIGHT = '0 0 * * *';
  
  // 每天中午
  CRON_NOON = '0 12 * * *';
  
  // 每天早上8点
  CRON_MORNING_8AM = '0 8 * * *';
  
  // 每天晚上6点
  CRON_EVENING_6PM = '0 18 * * *';
  
  // 每天凌晨2点（常用于备份）
  CRON_BACKUP_TIME = '0 2 * * *';
```

### 每周任务

```pascal
const
  // 每周一早上9点
  CRON_MONDAY_9AM = '0 9 * * 1';
  
  // 工作日早上9点
  CRON_WORKDAYS_9AM = '0 9 * * 1-5';
  
  // 周末早上10点
  CRON_WEEKENDS_10AM = '0 10 * * 0,6';
  
  // 每周五下午5点
  CRON_FRIDAY_5PM = '0 17 * * 5';
```

### 每月任务

```pascal
const
  // 每月1号午夜
  CRON_MONTHLY = '0 0 1 * *';
  
  // 每月最后一天（近似，实际为31号）
  CRON_MONTH_END = '0 0 31 * *';
  
  // 每月15号中午
  CRON_MID_MONTH = '0 12 15 * *';
  
  // 每季度第一天
  CRON_QUARTERLY = '0 0 1 1,4,7,10 *';
```

### 特殊场景

```pascal
const
  // 工作时间（9-17点，每小时）
  CRON_BUSINESS_HOURS = '0 9-17 * * 1-5';
  
  // 非工作时间（18-8点）
  CRON_OFF_HOURS = '0 18-23,0-8 * * *';
  
  // 每天工作时间每30分钟
  CRON_FREQUENT_BUSINESS = '0,30 9-17 * * 1-5';
```

---

## API 参考

### ICronExpression 接口

```pascal
type
  ICronExpression = interface
    // 获取原始表达式字符串
    function GetExpression: string;
    
    // 检查表达式是否有效
    function IsValid: Boolean;
    
    // 获取表达式的描述（用于调试）
    function GetDescription: string;
    
    // 获取下一次执行时间
    function GetNextTime(const AFromTime: TInstant): TInstant; overload;
    function GetNextTime: TInstant; overload;
    
    // 获取上一次执行时间（未实现）
    function GetPreviousTime(const AFromTime: TInstant): TInstant; overload;
    function GetPreviousTime: TInstant; overload;
    
    // 检查给定时间是否匹配表达式
    function Matches(const ATime: TInstant): Boolean;
    
    // 获取未来N次执行时间
    function GetNextTimes(const AFromTime: TInstant; ACount: Integer): specialize TArray<TInstant>; overload;
    function GetNextTimes(ACount: Integer): specialize TArray<TInstant>; overload;
  end;
```

### 工厂函数

```pascal
// 创建 Cron 表达式
function CreateCronExpression(const AExpression: string): ICronExpression;

// 解析 Cron 表达式（带验证）
function ParseCronExpression(const AExpression: string; out ACron: ICronExpression): Boolean;

// 验证 Cron 表达式
function IsValidCronExpression(const AExpression: string): Boolean;

// 获取 Cron 表达式描述
function GetCronDescription(const AExpression: string): string;

// 计算下次执行时间
function GetNextCronTime(const AExpression: string; const AFromTime: TInstant): TInstant; overload;
function GetNextCronTime(const AExpression: string): TInstant; overload;
```

### 调度器集成

```pascal
type
  ITaskScheduler = interface
    // 使用 Cron 表达式调度任务
    function ScheduleCron(const ATask: IScheduledTask; const ACronExpression: string): Boolean;
  end;

// 便捷调度函数
procedure ScheduleCron(const ACronExpression: string; const ACallback: TTaskCallback); overload;
procedure ScheduleCron(const ACronExpression: string; const ACallback: TTaskCallbackProc); overload;
```

---

## 最佳实践

### 1. 验证表达式

始终验证用户输入的 Cron 表达式：

```pascal
function ScheduleUserTask(const ACronExpr: string): Boolean;
var
  cron: ICronExpression;
begin
  Result := False;
  
  if not ParseCronExpression(ACronExpr, cron) then
  begin
    WriteLn('Invalid cron expression: ', ACronExpr);
    Exit;
  end;
  
  // 继续调度任务...
  Result := True;
end;
```

### 2. 预览执行时间

在调度之前，向用户显示未来的执行时间：

```pascal
procedure ShowNextExecutions(const ACronExpr: string; ACount: Integer);
var
  cron: ICronExpression;
  times: specialize TArray<TInstant>;
  i: Integer;
  dt: TDateTime;
begin
  cron := CreateCronExpression(ACronExpr);
  if not cron.IsValid then
  begin
    WriteLn('Invalid cron expression');
    Exit;
  end;
  
  times := cron.GetNextTimes(ACount);
  WriteLn(Format('Next %d executions:', [ACount]));
  
  for i := 0 to High(times) do
  begin
    dt := UnixToDateTime(times[i].AsNsSinceEpoch div 1000000000, False);
    WriteLn(Format('%d. %s', [i + 1, DateTimeToStr(dt)]));
  end;
end;
```

### 3. 错误处理

妥善处理 Cron 解析和执行错误：

```pascal
try
  cron := CreateCronExpression(userInput);
  
  if not cron.IsValid then
    raise Exception.Create('Invalid cron expression');
  
  nextTime := cron.GetNextTime;
  if nextTime = TInstant.Zero then
    raise Exception.Create('Cannot calculate next execution time');
    
  // 使用 nextTime...
except
  on E: Exception do
    WriteLn('Error: ', E.Message);
end;
```

### 4. 性能考虑

- 缓存频繁使用的 Cron 表达式对象
- 避免在循环中重复解析相同的表达式
- 对于大量任务，考虑使用优先队列优化

```pascal
var
  CronCache: TDictionary<string, ICronExpression>;

function GetCachedCron(const AExpr: string): ICronExpression;
begin
  if not CronCache.ContainsKey(AExpr) then
    CronCache.Add(AExpr, CreateCronExpression(AExpr));
  Result := CronCache[AExpr];
end;
```

### 5. 时区处理

当前实现使用本地时间。如需 UTC 时间，需要在计算时进行转换：

```pascal
// 注意：当前实现基于本地时间
// 如需 UTC 时间支持，需要额外处理
```

---

## 已知限制

1. **不支持秒字段**: 最小精度为分钟
2. **月份和星期为 AND 关系**: 必须同时满足日期和星期条件
3. **特殊字符**: 不支持 `L`, `W`, `#` 等高级特殊字符
4. **时区**: 默认使用本地时间，不支持时区指定

---

## 示例项目

### 备份任务

```pascal
// 每天凌晨2点执行备份
scheduler.ScheduleCron(backupTask, '0 2 * * *');
```

### 报告生成

```pascal
// 每周五下午5点生成周报
scheduler.ScheduleCron(reportTask, '0 17 * * 5');
```

### 数据同步

```pascal
// 每15分钟同步一次数据
scheduler.ScheduleCron(syncTask, '*/15 * * * *');
```

### 健康检查

```pascal
// 工作时间每小时检查一次
scheduler.ScheduleCron(healthCheckTask, '0 9-17 * * 1-5');
```

---

## 故障排除

### 表达式无效

**问题**: Cron 表达式被标记为无效

**解决方案**:
- 确保有5个字段，用空格分隔
- 检查每个字段的值是否在有效范围内
- 验证步长语法（`/` 前必须是 `*` 或范围）

### 时间计算不准确

**问题**: GetNextTime 返回意外的时间

**解决方案**:
- 检查是否考虑了时区差异
- 验证月末边界情况（31号在2月）
- 确保理解星期字段（0=周日）

### 任务未执行

**问题**: 调度的 Cron 任务没有执行

**解决方案**:
- 确保调度器已启动 (`scheduler.Start`)
- 检查任务状态是否为 Active
- 验证 Cron 表达式是否正确
- 查看是否有异常日志

---

## 参考资源

- [Cron Wikipedia](https://en.wikipedia.org/wiki/Cron)
- [Crontab Guru](https://crontab.guru/) - 在线 Cron 表达式验证工具
- `fafafa.core.time.scheduler` 模块文档

---

**最后更新**: 2025-10-05  
**维护者**: fafafaStudio
