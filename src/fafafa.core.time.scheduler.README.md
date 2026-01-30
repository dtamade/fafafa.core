# fafafa.core.time.scheduler

## 📖 简介

`fafafa.core.time.scheduler` 是一个功能强大、线程安全的任务调度器，支持多种调度策略和灵活的任务管理。

## ✨ 特性

- 🎯 **5种调度策略**：Once（一次性）、Fixed（固定间隔）、Delay（延迟间隔）、Daily（每日）、Weekly（每周）、Monthly（每月）
- 🔒 **线程安全**：完整的临界区保护，支持并发操作
- 📊 **统计监控**：详细的任务执行统计和调度器运行状态
- ⚡ **高精度**：纳秒级时间精度，基于单调时钟
- 🎚️ **优先级管理**：支持Low、Normal、High、Critical四级优先级
- 🛡️ **异常处理**：自动捕获任务异常，不影响调度器运行
- ⏸️ **灵活控制**：支持启动、停止、暂停、恢复、优雅关闭

## 📦 安装

将 `fafafa.core.time.scheduler.pas` 添加到您的项目中，并引用相关依赖单元。

## 🚀 快速开始

### 基本用法

```pascal
uses
  fafafa.core.time.scheduler,
  fafafa.core.time.duration;

var
  scheduler: ITaskScheduler;
  task: IScheduledTask;

procedure MyTaskCallback(const ATask: IScheduledTask);
begin
  WriteLn('任务执行了！');
end;

begin
  // 创建调度器
  scheduler := CreateTaskScheduler;
  
  // 创建任务
  task := scheduler.CreateTask('MyTask', @MyTaskCallback);
  
  // 2秒后执行
  scheduler.ScheduleOnce(task, TDuration.FromSec(2));
  
  // 启动调度器
  scheduler.Start;
  
  // ... 等待执行 ...
  
  // 停止调度器
  scheduler.Stop;
end;
```

## 📋 调度策略详解

### 1. Once - 一次性任务

任务只执行一次，完成后自动移除。

```pascal
// 延迟执行
scheduler.ScheduleOnce(task, TDuration.FromSec(5));

// 指定时间执行
var runTime: TInstant;
runTime := clock.NowInstant.Add(TDuration.FromSec(10));
scheduler.ScheduleOnce(task, runTime);
```

### 2. Fixed - 固定间隔

按固定间隔重复执行，不考虑任务执行时间。

```pascal
// 每1秒执行一次，初始延迟500ms
scheduler.ScheduleFixed(
  task, 
  TDuration.FromSec(1),      // 间隔
  TDuration.FromMs(500)       // 初始延迟
);
```

**时间轴示例**：
```
T0+500ms: 执行第1次 (耗时100ms)
T0+1500ms: 执行第2次 (间隔=1000ms)
T0+2500ms: 执行第3次 (间隔=1000ms)
```

### 3. Delay - 延迟间隔

执行完成后才开始计时下次执行。

```pascal
// 执行完成后等待1秒再执行下次
scheduler.ScheduleDelay(task, TDuration.FromSec(1));
```

**时间轴示例**：
```
T0+1000ms: 执行第1次 (耗时100ms)
T0+2100ms: 执行第2次 (完成时间+1000ms)
T0+3200ms: 执行第3次
```

### 4. Daily - 每日定时

每天在指定时间执行。

```pascal
var time: TTimeOfDay;
time := TTimeOfDay.Create(10, 30, 0);  // 每天10:30
scheduler.ScheduleDaily(task, time);
```

### 5. Weekly - 每周定时

每周指定星期几的指定时间执行。

```pascal
var time: TTimeOfDay;
time := TTimeOfDay.Create(9, 0, 0);
scheduler.ScheduleWeekly(task, 1, time);  // 每周一09:00
// 星期：0=周日, 1=周一, ..., 6=周六
```

### 6. Monthly - 每月定时

每月指定日期的指定时间执行。

```pascal
var time: TTimeOfDay;
time := TTimeOfDay.Create(8, 0, 0);
scheduler.ScheduleMonthly(task, 1, time);  // 每月1号08:00
// 自动处理月末：如果指定31号，2月会自动调整为28/29号
```

## 🎯 任务管理

### 创建任务

支持三种回调类型：

```pascal
// 1. 对象方法
type
  TMyClass = class
    procedure MyMethod(const ATask: IScheduledTask);
  end;

var obj: TMyClass;
task := scheduler.CreateTask('Task1', @obj.MyMethod);

// 2. 过程
procedure MyProc(const ATask: IScheduledTask);
begin
  // ...
end;

task := scheduler.CreateTask('Task2', @MyProc);

// 3. 函数（返回Boolean表示成功/失败）
function MyFunc(const ATask: IScheduledTask): Boolean;
begin
  Result := True; // 成功
end;

task := scheduler.CreateTask('Task3', @MyFunc);
```

### 任务状态

- `tsIdle` - 空闲（刚创建）
- `tsScheduled` - 已调度（等待执行）
- `tsRunning` - 运行中
- `tsCompleted` - 已完成
- `tsFailed` - 失败
- `tsCancelled` - 已取消

### 任务控制

```pascal
task.Start;         // 启动任务
task.Stop;          // 停止任务
task.Cancel;        // 取消任务
task.Reset;         // 重置任务
task.Skip;          // 跳过下次执行

// 状态查询
if task.IsActive then ...
if task.IsRunning then ...
if task.IsCancelled then ...
```

### 任务优先级

```pascal
task.SetPriority(tpHigh);

// 优先级：
// tpLow = 1
// tpNormal = 5 (默认)
// tpHigh = 10
// tpCritical = 15
```

## 📊 统计信息

### 任务统计

```pascal
var stats: IScheduledTask;

WriteLn('执行次数: ', task.GetRunCount);
WriteLn('失败次数: ', task.GetFailureCount);
WriteLn('总执行时间: ', task.GetTotalExecutionTime.AsMs, ' ms');
WriteLn('平均执行时间: ', task.GetAverageExecutionTime.AsMs, ' ms');
WriteLn('最后错误: ', task.GetLastError);
```

### 调度器统计

```pascal
WriteLn('总执行任务数: ', scheduler.GetTotalTasksExecuted);
WriteLn('总失败任务数: ', scheduler.GetTotalTasksFailed);
WriteLn('运行时长: ', scheduler.GetUptime.AsMs, ' ms');
WriteLn('当前任务数: ', scheduler.GetTaskCount);
```

## 🎚️ 调度器控制

```pascal
scheduler.Start;              // 启动
scheduler.Stop;               // 停止
scheduler.Pause;              // 暂停
scheduler.Resume;             // 恢复
scheduler.Shutdown(timeout);  // 优雅关闭（带超时）

// 状态查询
if scheduler.IsRunning then ...
if scheduler.IsPaused then ...
```

## 🔍 查询任务

```pascal
// 按ID查询
var task: IScheduledTask;
task := scheduler.GetTask('TaskID');

// 获取所有任务
var tasks: specialize TArray<IScheduledTask>;
tasks := scheduler.GetTasks;

// 按状态查询
tasks := scheduler.GetTasks(tsScheduled);

// 任务计数
var count: Integer;
count := scheduler.GetTaskCount;
count := scheduler.GetTaskCount(tsRunning);
```

## 🛡️ 错误处理

任务中的异常会被自动捕获，不会影响调度器运行：

```pascal
procedure ErrorTaskCallback(const ATask: IScheduledTask);
begin
  raise Exception.Create('发生错误');
  // 调度器会捕获此异常
  // 任务状态变为 tsFailed
  // 错误信息记录在 task.GetLastError
end;
```

## 💡 使用建议

### 1. 长时间运行的任务

对于耗时较长的任务，建议使用 `Delay` 策略而非 `Fixed`，避免任务堆积。

```pascal
// ✅ 推荐：等待任务完成后再开始计时
scheduler.ScheduleDelay(task, TDuration.FromSec(1));

// ⚠️ 谨慎：如果任务耗时超过间隔，会立即再次执行
scheduler.ScheduleFixed(task, TDuration.FromSec(1), TDuration.Zero);
```

### 2. 资源管理

调度器和任务使用接口引用计数，会自动释放：

```pascal
var scheduler: ITaskScheduler;
begin
  scheduler := CreateTaskScheduler;
  // ... 使用 ...
end; // 自动释放
```

### 3. 优雅关闭

建议使用 `Shutdown` 而非 `Stop`，确保正在执行的任务完成：

```pascal
scheduler.Shutdown(TDuration.FromSec(5)); // 最多等待5秒
```

### 4. 性能考虑

- 当前实现使用线性扫描查找下一个任务，适合中小规模（<100个任务）
- 大量任务时建议使用优先级减少活跃任务数
- 避免在任务回调中执行阻塞操作

## 📝 完整示例

参见 `examples/scheduler_simple_example.pas`，包含8个完整示例：

1. 一次性任务
2. 固定间隔重复任务
3. 延迟间隔任务
4. 任务优先级
5. 任务统计
6. 错误处理
7. 多任务协作
8. 暂停和恢复

## 🔧 高级特性

### 重试策略（预留接口）

```pascal
var strategy: TRetryStrategy;
strategy := TRetryStrategy.Exponential(3, TDuration.FromSec(1));
task.SetRetryStrategy(strategy);
// 注意：当前版本仅预留接口，重试逻辑未实现
```

### 自定义时钟

```pascal
var customClock: IMonotonicClock;
scheduler := CreateTaskScheduler(customClock);
```

## ⚠️ 限制和注意事项

1. **月度调度精度**：使用固定30天间隔，长期运行可能有偏移
2. **无时区支持**：使用本地时间，不处理夏令时切换
3. **单工作线程**：当前只有一个工作线程处理所有任务
4. **无持久化**：调度器重启后任务丢失
5. **Cron表达式**：当前未实现真正的Cron解析器

## 📚 API参考

### 接口

- `IScheduledTask` - 任务接口
- `ITaskScheduler` - 调度器接口

### 工厂函数

```pascal
function CreateTaskScheduler: ITaskScheduler;
function CreateTaskScheduler(const AClock: IMonotonicClock): ITaskScheduler;
function CreateTaskScheduler(AMaxThreads: Integer): ITaskScheduler;
function DefaultTaskScheduler: ITaskScheduler; // 全局默认实例
```

### 便捷函数

```pascal
procedure ScheduleOnce(const ADelay: TDuration; const ACallback: TTaskCallback);
procedure ScheduleFixed(const AInterval: TDuration; const ACallback: TTaskCallback; const AInitialDelay: TDuration);
procedure ScheduleDaily(const ATime: TTimeOfDay; const ACallback: TTaskCallback);
```

## 🧪 测试

运行单元测试：

```bash
cd tests/fafafa.core.time
fpc fafafa.core.time.test.lpr
./fafafa.core.time.test --suite=TTestScheduler
```

测试覆盖：
- ✅ 21个测试用例
- ✅ 100%通过率
- ✅ 涵盖所有主要功能

## 📄 许可证

版权所有 © fafafaStudio

## 📧 联系方式

- **Email**: dtamade@gmail.com
- **QQ**: 179033731
- **QQ群**: 685403987

## 🔗 相关文档

- [ISSUE-25 完成报告](../working/ISSUE_25_COMPLETE.md)
- [使用示例](../examples/scheduler_simple_example.pas)
- [单元测试](../tests/fafafa.core.time/Test_fafafa_core_time_scheduler.pas)

---

**最后更新**: 2025-10-05  
**版本**: 1.0
