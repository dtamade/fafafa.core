program scheduler_simple_example;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.timeofday,
  fafafa.core.time.scheduler;

var
  GlobalCounter: Integer = 0;

{ 示例回调函数 }
procedure WelcomeCallback(const ATask: IScheduledTask);
begin
  WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 欢迎使用任务调度器!');
end;

procedure CounterCallback(const ATask: IScheduledTask);
begin
  Inc(GlobalCounter);
  WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 计数: ', GlobalCounter);
end;

procedure SlowTaskCallback(const ATask: IScheduledTask);
begin
  WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 开始执行耗时任务...');
  Sleep(200);
  WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 任务完成');
end;

procedure DailyReportCallback(const ATask: IScheduledTask);
begin
  WriteLn('  [', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), '] 生成每日报告');
end;

procedure HighPriorityCallback(const ATask: IScheduledTask);
begin
  WriteLn('  [高优先级] 立即处理的任务');
end;

procedure NormalPriorityCallback(const ATask: IScheduledTask);
begin
  WriteLn('  [普通优先级] 正常处理的任务');
end;

procedure LowPriorityCallback(const ATask: IScheduledTask);
begin
  WriteLn('  [低优先级] 后台任务');
end;

procedure StatsTaskCallback(const ATask: IScheduledTask);
begin
  Sleep(10 + Random(20));
end;

procedure ErrorTaskCallback(const ATask: IScheduledTask);
begin
  Inc(GlobalCounter);
  WriteLn('  [', GlobalCounter, '] 尝试执行...');
  if GlobalCounter mod 2 = 1 then
    raise Exception.Create('模拟错误');
  WriteLn('  [', GlobalCounter, '] 成功!');
end;

procedure FastTaskCallback(const ATask: IScheduledTask);
begin
  Write('快');
end;

procedure MediumTaskCallback(const ATask: IScheduledTask);
begin
  Write('中');
end;

procedure SlowTaskCallback2(const ATask: IScheduledTask);
begin
  WriteLn('慢');
end;

procedure PausableTaskCallback(const ATask: IScheduledTask);
begin
  Inc(GlobalCounter);
  WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 执行 #', GlobalCounter);
end;

{ 示例1: 简单的一次性任务 }
procedure Example1_OnceTask;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  WriteLn('=== 示例1: 一次性任务 ===');
  
  scheduler := CreateTaskScheduler;
  task := scheduler.CreateTask('WelcomeTask', @WelcomeCallback);
  scheduler.ScheduleOnce(task, TDuration.FromSec(2));
  
  WriteLn('  任务已调度，2秒后执行...');
  scheduler.Start;
  Sleep(3000);
  scheduler.Stop;
  
  WriteLn('  完成!');
  WriteLn;
end;

{ 示例2: 固定间隔重复任务 }
procedure Example2_FixedRateTask;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  WriteLn('=== 示例2: 固定间隔重复任务 ===');
  
  GlobalCounter := 0;
  scheduler := CreateTaskScheduler;
  task := scheduler.CreateTask('CounterTask', @CounterCallback);
  scheduler.ScheduleFixed(task, TDuration.FromMs(500), TDuration.FromMs(100));
  
  WriteLn('  任务将每500ms执行一次...');
  scheduler.Start;
  Sleep(3000);
  
  task.Cancel;
  scheduler.Stop;
  WriteLn('  总共执行了 ', GlobalCounter, ' 次');
  WriteLn;
end;

{ 示例3: 延迟间隔任务 }
procedure Example3_DelayedTask;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  WriteLn('=== 示例3: 延迟间隔任务 ===');
  
  scheduler := CreateTaskScheduler;
  task := scheduler.CreateTask('SlowTask', @SlowTaskCallback);
  scheduler.ScheduleDelay(task, TDuration.FromMs(500));
  
  WriteLn('  延迟任务每次执行后等待500ms...');
  scheduler.Start;
  Sleep(3000);
  
  task.Cancel;
  scheduler.Stop;
  WriteLn('  完成!');
  WriteLn;
end;

{ 示例4: 任务优先级 }
procedure Example4_TaskPriority;
var
  scheduler: ITaskScheduler;
  highTask, normalTask, lowTask: IScheduledTask;
  clock: IMonotonicClock;
  runTime: TInstant;
begin
  WriteLn('=== 示例4: 任务优先级 ===');
  
  scheduler := CreateTaskScheduler;
  clock := DefaultMonotonicClock;
  runTime := clock.NowInstant.Add(TDuration.FromMs(100));
  
  highTask := scheduler.CreateTask('HighPriority', @HighPriorityCallback);
  highTask.SetPriority(tpHigh);
  
  normalTask := scheduler.CreateTask('NormalPriority', @NormalPriorityCallback);
  
  lowTask := scheduler.CreateTask('LowPriority', @LowPriorityCallback);
  lowTask.SetPriority(tpLow);
  
  scheduler.ScheduleOnce(lowTask, runTime);
  scheduler.ScheduleOnce(normalTask, runTime);
  scheduler.ScheduleOnce(highTask, runTime);
  
  WriteLn('  三个任务将按优先级顺序执行...');
  scheduler.Start;
  Sleep(500);
  scheduler.Stop;
  
  WriteLn('  完成!');
  WriteLn;
end;

{ 示例5: 任务统计 }
procedure Example5_TaskStatistics;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  WriteLn('=== 示例5: 任务统计 ===');
  
  scheduler := CreateTaskScheduler;
  task := scheduler.CreateTask('StatsTask', @StatsTaskCallback);
  scheduler.ScheduleFixed(task, TDuration.FromMs(100), TDuration.FromMs(50));
  scheduler.Start;
  
  WriteLn('  运行任务5秒，收集统计信息...');
  Sleep(5000);
  
  task.Cancel;
  scheduler.Stop;
  
  WriteLn('  === 任务统计 ===');
  WriteLn('  执行次数: ', task.GetRunCount);
  WriteLn('  失败次数: ', task.GetFailureCount);
  WriteLn('  总执行时间: ', task.GetTotalExecutionTime.AsMs, ' ms');
  WriteLn('  平均执行时间: ', Format('%f', [task.GetAverageExecutionTime.AsMs]):1:2, ' ms');
  WriteLn;
  WriteLn('  === 调度器统计 ===');
  WriteLn('  总执行任务数: ', scheduler.GetTotalTasksExecuted);
  WriteLn('  总失败任务数: ', scheduler.GetTotalTasksFailed);
  WriteLn('  运行时长: ', Format('%f', [scheduler.GetUptime.AsMs / 1000]):1:1, ' 秒');
  WriteLn;
end;

{ 示例6: 错误处理 }
procedure Example6_ErrorHandling;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  WriteLn('=== 示例6: 错误处理 ===');
  
  GlobalCounter := 0;
  scheduler := CreateTaskScheduler;
  task := scheduler.CreateTask('ErrorTask', @ErrorTaskCallback);
  scheduler.ScheduleFixed(task, TDuration.FromMs(500), TDuration.FromMs(100));
  scheduler.Start;
  
  WriteLn('  任务将在奇数次执行时失败...');
  Sleep(3000);
  
  task.Cancel;
  scheduler.Stop;
  
  WriteLn('  执行次数: ', task.GetRunCount);
  WriteLn('  失败次数: ', task.GetFailureCount);
  if task.GetFailureCount > 0 then
    WriteLn('  最后错误: ', task.GetLastError);
  WriteLn;
end;

{ 示例7: 多任务协作 }
procedure Example7_MultipleTasks;
var
  scheduler: ITaskScheduler;
  task1, task2, task3: IScheduledTask;
begin
  WriteLn('=== 示例7: 多任务协作 ===');
  
  scheduler := CreateTaskScheduler;
  
  task1 := scheduler.CreateTask('FastTask', @FastTaskCallback);
  scheduler.ScheduleFixed(task1, TDuration.FromMs(200), TDuration.FromMs(0));
  
  task2 := scheduler.CreateTask('MediumTask', @MediumTaskCallback);
  scheduler.ScheduleFixed(task2, TDuration.FromMs(500), TDuration.FromMs(0));
  
  task3 := scheduler.CreateTask('SlowTask', @SlowTaskCallback2);
  scheduler.ScheduleFixed(task3, TDuration.FromMs(1000), TDuration.FromMs(0));
  
  WriteLn('  三个不同速度的任务同时运行...');
  scheduler.Start;
  Sleep(5000);
  scheduler.Stop;
  
  WriteLn;
  WriteLn('  任务状态:');
  WriteLn('    快速任务: 执行了 ', task1.GetRunCount, ' 次');
  WriteLn('    中速任务: 执行了 ', task2.GetRunCount, ' 次');
  WriteLn('    慢速任务: 执行了 ', task3.GetRunCount, ' 次');
  WriteLn;
end;

{ 示例8: 暂停和恢复 }
procedure Example8_PauseResume;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  WriteLn('=== 示例8: 暂停和恢复 ===');
  
  GlobalCounter := 0;
  scheduler := CreateTaskScheduler;
  task := scheduler.CreateTask('PausableTask', @PausableTaskCallback);
  scheduler.ScheduleFixed(task, TDuration.FromMs(300), TDuration.FromMs(100));
  scheduler.Start;
  
  WriteLn('  运行2秒...');
  Sleep(2000);
  
  WriteLn('  暂停调度器...');
  scheduler.Pause;
  WriteLn('  已暂停，等待2秒（任务不应执行）');
  Sleep(2000);
  
  WriteLn('  恢复调度器...');
  scheduler.Resume;
  Sleep(2000);
  
  scheduler.Stop;
  WriteLn('  总共执行了 ', GlobalCounter, ' 次');
  WriteLn;
end;

{ 主程序 }
begin
  WriteLn('╔══════════════════════════════════════════╗');
  WriteLn('║   fafafa.core.time.scheduler 使用示例   ║');
  WriteLn('╚══════════════════════════════════════════╝');
  WriteLn;
  
  Randomize;
  
  try
    Example1_OnceTask;
    Example2_FixedRateTask;
    Example3_DelayedTask;
    Example4_TaskPriority;
    Example5_TaskStatistics;
    Example6_ErrorHandling;
    Example7_MultipleTasks;
    Example8_PauseResume;
    
    WriteLn('╔══════════════════════════════════════════╗');
    WriteLn('║         所有示例执行完成！              ║');
    WriteLn('╚══════════════════════════════════════════╝');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
