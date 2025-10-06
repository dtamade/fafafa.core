program scheduler_example;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.timeofday,
  fafafa.core.time.scheduler;

{ 示例1: 简单的一次性任务 }
procedure SimpleTaskCallback(const ATask: IScheduledTask);
begin
  WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 欢迎使用任务调度器!');
end;

procedure Example1_OnceTask;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  WriteLn('=== 示例1: 一次性任务 ===');
  
  scheduler := CreateTaskScheduler;
  
  // 创建任务
  task := scheduler.CreateTask('WelcomeTask', @SimpleTaskCallback);
  
  // 在2秒后执行
  scheduler.ScheduleOnce(task, TDuration.FromSec(2));
  
  WriteLn('  任务已调度，2秒后执行...');
  scheduler.Start;
  
  Sleep(3000); // 等待任务执行
  
  scheduler.Stop;
  WriteLn('  完成!');
  WriteLn;
end;

{ 示例2: 固定间隔重复任务 }
procedure Example2_FixedRateTask;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
  counter: Integer;
begin
  WriteLn('=== 示例2: 固定间隔重复任务 ===');
  
  counter := 0;
  scheduler := CreateTaskScheduler;
  
  // 创建重复任务
  task := scheduler.CreateTask('CounterTask',
    procedure(const ATask: IScheduledTask)
    begin
      Inc(counter);
      WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 计数: ', counter);
    end);
  
  // 每500ms执行一次，初始延迟100ms
  scheduler.ScheduleFixed(task, TDuration.FromMs(500), TDuration.FromMs(100));
  
  WriteLn('  任务将每500ms执行一次，共执行5次...');
  scheduler.Start;
  
  Sleep(3000); // 运行3秒
  
  task.Cancel; // 取消任务
  scheduler.Stop;
  WriteLn('  总共执行了 ', counter, ' 次');
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
  
  // 创建延迟任务（执行完成后才开始计时下一次）
  task := scheduler.CreateTask('SlowTask',
    procedure(const ATask: IScheduledTask)
    begin
      WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 开始执行耗时任务...');
      Sleep(200); // 模拟耗时操作
      WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 任务完成');
    end);
  
  // 延迟500ms后执行，任务完成后等待500ms再执行下次
  scheduler.ScheduleDelay(task, TDuration.FromMs(500));
  
  WriteLn('  延迟任务每次执行后等待500ms...');
  scheduler.Start;
  
  Sleep(3000);
  
  task.Cancel;
  scheduler.Stop;
  WriteLn('  完成!');
  WriteLn;
end;

{ 示例4: 每日定时任务 }
procedure Example4_DailyTask;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
  targetTime: TTimeOfDay;
begin
  WriteLn('=== 示例4: 每日定时任务 ===');
  
  scheduler := CreateTaskScheduler;
  
  // 创建每日任务
  task := scheduler.CreateTask('DailyReport',
    procedure(const ATask: IScheduledTask)
    begin
      WriteLn('  [', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), '] 生成每日报告');
    end);
  
  // 每天上午10:30执行
  targetTime := TTimeOfDay.Create(10, 30, 0);
  scheduler.ScheduleDaily(task, targetTime);
  
  WriteLn('  任务已调度为每天 10:30 执行');
  WriteLn('  下次执行时间: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', 
    task.GetNextRunTime.AsUnixSec)); // 简化显示
  WriteLn;
end;

{ 示例5: 任务优先级 }
procedure Example5_TaskPriority;
var
  scheduler: ITaskScheduler;
  highTask, normalTask, lowTask: IScheduledTask;
  clock: IMonotonicClock;
  runTime: TInstant;
begin
  WriteLn('=== 示例5: 任务优先级 ===');
  
  scheduler := CreateTaskScheduler;
  clock := DefaultMonotonicClock;
  
  // 所有任务都在同一时间执行
  runTime := clock.NowInstant.Add(TDuration.FromMs(100));
  
  // 创建不同优先级的任务
  highTask := scheduler.CreateTask('HighPriority',
    procedure(const ATask: IScheduledTask)
    begin
      WriteLn('  [高优先级] 立即处理的任务');
    end);
  highTask.SetPriority(tpHigh);
  
  normalTask := scheduler.CreateTask('NormalPriority',
    procedure(const ATask: IScheduledTask)
    begin
      WriteLn('  [普通优先级] 正常处理的任务');
    end);
  
  lowTask := scheduler.CreateTask('LowPriority',
    procedure(const ATask: IScheduledTask)
    begin
      WriteLn('  [低优先级] 后台任务');
    end);
  lowTask.SetPriority(tpLow);
  
  // 以相反的顺序添加（低、普通、高）
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

{ 示例6: 任务统计 }
procedure Example6_TaskStatistics;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
  i: Integer;
begin
  WriteLn('=== 示例6: 任务统计 ===');
  
  scheduler := CreateTaskScheduler;
  
  // 创建快速执行的任务
  task := scheduler.CreateTask('StatsTask',
    procedure(const ATask: IScheduledTask)
    begin
      Sleep(10 + Random(20)); // 10-30ms 的随机执行时间
    end);
  
  scheduler.ScheduleFixed(task, TDuration.FromMs(100), TDuration.FromMs(50));
  scheduler.Start;
  
  WriteLn('  运行任务5秒，收集统计信息...');
  Sleep(5000);
  
  task.Cancel;
  scheduler.Stop;
  
  // 显示统计信息
  WriteLn('  === 任务统计 ===');
  WriteLn('  执行次数: ', task.GetRunCount);
  WriteLn('  失败次数: ', task.GetFailureCount);
  WriteLn('  总执行时间: ', task.GetTotalExecutionTime.AsMs, ' ms');
  WriteLn('  平均执行时间: ', task.GetAverageExecutionTime.AsMs:0:2, ' ms');
  
  WriteLn;
  WriteLn('  === 调度器统计 ===');
  WriteLn('  总执行任务数: ', scheduler.GetTotalTasksExecuted);
  WriteLn('  总失败任务数: ', scheduler.GetTotalTasksFailed);
  WriteLn('  运行时长: ', scheduler.GetUptime.AsMs / 1000:0:1, ' 秒');
  WriteLn;
end;

{ 示例7: 错误处理 }
procedure Example7_ErrorHandling;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
  counter: Integer;
begin
  WriteLn('=== 示例7: 错误处理 ===');
  
  counter := 0;
  scheduler := CreateTaskScheduler;
  
  // 创建会抛出异常的任务
  task := scheduler.CreateTask('ErrorTask',
    procedure(const ATask: IScheduledTask)
    begin
      Inc(counter);
      WriteLn('  [', counter, '] 尝试执行...');
      if counter mod 2 = 1 then
        raise Exception.Create('模拟错误');
      WriteLn('  [', counter, '] 成功!');
    end);
  
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

{ 示例8: 多任务协作 }
procedure Example8_MultipleTasks;
var
  scheduler: ITaskScheduler;
  task1, task2, task3: IScheduledTask;
begin
  WriteLn('=== 示例8: 多任务协作 ===');
  
  scheduler := CreateTaskScheduler;
  
  // 快速任务
  task1 := scheduler.CreateTask('FastTask',
    procedure(const ATask: IScheduledTask)
    begin
      Write('快');
    end);
  scheduler.ScheduleFixed(task1, TDuration.FromMs(200), TDuration.FromMs(0));
  
  // 中速任务
  task2 := scheduler.CreateTask('MediumTask',
    procedure(const ATask: IScheduledTask)
    begin
      Write('中');
    end);
  scheduler.ScheduleFixed(task2, TDuration.FromMs(500), TDuration.FromMs(0));
  
  // 慢速任务
  task3 := scheduler.CreateTask('SlowTask',
    procedure(const ATask: IScheduledTask)
    begin
      WriteLn('慢');
    end);
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

{ 示例9: 暂停和恢复 }
procedure Example9_PauseResume;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
  counter: Integer;
begin
  WriteLn('=== 示例9: 暂停和恢复 ===');
  
  counter := 0;
  scheduler := CreateTaskScheduler;
  
  task := scheduler.CreateTask('PausableTask',
    procedure(const ATask: IScheduledTask)
    begin
      Inc(counter);
      WriteLn('  [', FormatDateTime('hh:nn:ss', Now), '] 执行 #', counter);
    end);
  
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
  WriteLn('  总共执行了 ', counter, ' 次');
  WriteLn;
end;

{ 主程序 }
begin
  WriteLn('╔══════════════════════════════════════════╗');
  WriteLn('║   fafafa.core.time.scheduler 使用示例   ║');
  WriteLn('╚══════════════════════════════════════════╝');
  WriteLn;
  
  Randomize; // 初始化随机数生成器
  
  try
    Example1_OnceTask;
    Example2_FixedRateTask;
    Example3_DelayedTask;
    Example4_DailyTask;
    Example5_TaskPriority;
    Example6_TaskStatistics;
    Example7_ErrorHandling;
    Example8_MultipleTasks;
    Example9_PauseResume;
    
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
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
