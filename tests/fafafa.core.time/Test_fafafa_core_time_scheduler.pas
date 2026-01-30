unit Test_fafafa_core_time_scheduler;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.timeofday,
  fafafa.core.time.scheduler;

type
  { TTestScheduler }
  TTestScheduler = class(TTestCase)
  private
    FScheduler: ITaskScheduler;
    FExecutionCount: Integer;
    FLastExecutedTask: IScheduledTask;
    
    procedure TaskCallback(const ATask: IScheduledTask);
    procedure TaskCallbackProc(const ATask: IScheduledTask);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // Basic task creation and management
    procedure Test_CreateTask;
    procedure Test_TaskState;
    procedure Test_TaskPriority;
    
    // Scheduler control
    procedure Test_StartStop;
    procedure Test_PauseResume;
    
    // Once strategy
    procedure Test_ScheduleOnce_Delay;
    procedure Test_ScheduleOnce_RunTime;
    procedure Test_ScheduleOnce_Execution;
    
    // Fixed strategy
    procedure Test_ScheduleFixed_Basic;
    procedure Test_ScheduleFixed_Repeat;
    
    // Delay strategy
    procedure Test_ScheduleDelay_Basic;
    procedure Test_ScheduleDelay_Repeat;
    
    // Daily strategy
    procedure Test_ScheduleDaily_Basic;
    procedure Test_ScheduleDaily_NextDay;
    
    // Weekly strategy
    procedure Test_ScheduleWeekly_Basic;
    
    // Monthly strategy
    procedure Test_ScheduleMonthly_Basic;
    
    // Task management
    procedure Test_RemoveTask;
    procedure Test_GetTasks;
    procedure Test_TaskCount;
    
    // Statistics
    procedure Test_ExecutionStatistics;
    procedure Test_SchedulerStatistics;
  end;

implementation

{ TTestScheduler }

procedure TTestScheduler.TaskCallback(const ATask: IScheduledTask);
begin
  Inc(FExecutionCount);
  FLastExecutedTask := ATask;
end;

procedure TTestScheduler.TaskCallbackProc(const ATask: IScheduledTask);
begin
  Inc(FExecutionCount);
  FLastExecutedTask := ATask;
end;

procedure TTestScheduler.SetUp;
begin
  FScheduler := CreateTaskScheduler;
  FExecutionCount := 0;
  FLastExecutedTask := nil;
end;

procedure TTestScheduler.TearDown;
begin
  if Assigned(FScheduler) then
  begin
    if FScheduler.IsRunning then
      FScheduler.Stop;
    FScheduler := nil;
  end;
end;

procedure TTestScheduler.Test_CreateTask;
var
  task: IScheduledTask;
begin
  task := FScheduler.CreateTask('TestTask', @TaskCallback);
  CheckNotNull(task, 'Task should be created');
  CheckEquals('TestTask', task.GetName, 'Task name should match');
  CheckEquals(Ord(tsIdle), Ord(task.GetState), 'New task should be idle');
end;

procedure TTestScheduler.Test_TaskState;
var
  task: IScheduledTask;
begin
  task := FScheduler.CreateTask('StateTest', @TaskCallback);
  
  CheckEquals(Ord(tsIdle), Ord(task.GetState), 'Initial state should be idle');
  
  task.Start;
  CheckTrue(task.IsActive, 'Task should be active after start');
  
  task.Cancel;
  CheckTrue(task.IsCancelled, 'Task should be cancelled');
  CheckFalse(task.IsActive, 'Cancelled task should not be active');
end;

procedure TTestScheduler.Test_TaskPriority;
var
  task: IScheduledTask;
begin
  task := FScheduler.CreateTask('PriorityTest', @TaskCallback);
  
  CheckEquals(Ord(tpNormal), Ord(task.GetPriority), 'Default priority should be normal');
  
  task.SetPriority(tpHigh);
  CheckEquals(Ord(tpHigh), Ord(task.GetPriority), 'Priority should be changed to high');
end;

procedure TTestScheduler.Test_StartStop;
begin
  CheckFalse(FScheduler.IsRunning, 'Scheduler should not be running initially');
  
  FScheduler.Start;
  CheckTrue(FScheduler.IsRunning, 'Scheduler should be running after start');
  
  FScheduler.Stop;
  CheckFalse(FScheduler.IsRunning, 'Scheduler should not be running after stop');
end;

procedure TTestScheduler.Test_PauseResume;
begin
  FScheduler.Start;
  CheckFalse(FScheduler.IsPaused, 'Scheduler should not be paused initially');
  
  FScheduler.Pause;
  CheckTrue(FScheduler.IsPaused, 'Scheduler should be paused');
  
  FScheduler.Resume;
  CheckFalse(FScheduler.IsPaused, 'Scheduler should not be paused after resume');
  
  FScheduler.Stop;
end;

procedure TTestScheduler.Test_ScheduleOnce_Delay;
var
  task: IScheduledTask;
  delay: TDuration;
  beforeTime, taskTime: TInstant;
  clock: IMonotonicClock;
begin
  clock := DefaultMonotonicClock;
  task := FScheduler.CreateTask('OnceDelay', @TaskCallback);
  delay := TDuration.FromMs(100);
  
  beforeTime := clock.NowInstant;
  CheckTrue(FScheduler.ScheduleOnce(task, delay), 'Should schedule successfully');
  taskTime := task.GetNextRunTime;
  
  // Verify the task is scheduled for approximately 100ms in the future
  CheckTrue(taskTime > beforeTime, 'Next run time should be in the future');
end;

procedure TTestScheduler.Test_ScheduleOnce_RunTime;
var
  task: IScheduledTask;
  runTime: TInstant;
  clock: IMonotonicClock;
begin
  clock := DefaultMonotonicClock;
  task := FScheduler.CreateTask('OnceRunTime', @TaskCallback);
  runTime := clock.NowInstant.Add(TDuration.FromMs(200));
  
  CheckTrue(FScheduler.ScheduleOnce(task, runTime), 'Should schedule successfully');
  CheckEquals(runTime.AsNsSinceEpoch, task.GetNextRunTime.AsNsSinceEpoch, 
    'Next run time should match scheduled time');
end;

procedure TTestScheduler.Test_ScheduleOnce_Execution;
var
  task: IScheduledTask;
  delay: TDuration;
begin
  task := FScheduler.CreateTask('OnceExecution', @TaskCallback);
  delay := TDuration.FromMs(50);
  
  FScheduler.Start;
  CheckTrue(FScheduler.ScheduleOnce(task, delay), 'Should schedule successfully');
  
  // Wait for execution
  Sleep(200);
  
  CheckEquals(1, FExecutionCount, 'Task should be executed once');
  CheckEquals(1, task.GetRunCount, 'Task run count should be 1');
  
  FScheduler.Stop;
end;

procedure TTestScheduler.Test_ScheduleFixed_Basic;
var
  task: IScheduledTask;
  interval, initialDelay: TDuration;
begin
  task := FScheduler.CreateTask('FixedBasic', @TaskCallback);
  interval := TDuration.FromMs(100);
  initialDelay := TDuration.FromMs(50);
  
  CheckTrue(FScheduler.ScheduleFixed(task, interval, initialDelay), 
    'Should schedule successfully');
  CheckEquals(Ord(ssFixed), Ord(task.GetStrategy), 'Strategy should be fixed');
end;

procedure TTestScheduler.Test_ScheduleFixed_Repeat;
var
  task: IScheduledTask;
  interval, initialDelay: TDuration;
begin
  task := FScheduler.CreateTask('FixedRepeat', @TaskCallback);
  interval := TDuration.FromMs(100);
  initialDelay := TDuration.FromMs(50);
  
  FScheduler.Start;
  CheckTrue(FScheduler.ScheduleFixed(task, interval, initialDelay), 
    'Should schedule successfully');
  
  // Wait for multiple executions
  Sleep(500);
  
  // Should execute at least 3 times (50ms + 100ms + 100ms + 100ms = 350ms)
  CheckTrue(FExecutionCount >= 3, 
    Format('Task should execute at least 3 times, but executed %d times', [FExecutionCount]));
  
  FScheduler.Stop;
end;

procedure TTestScheduler.Test_ScheduleDelay_Basic;
var
  task: IScheduledTask;
  delay: TDuration;
begin
  task := FScheduler.CreateTask('DelayBasic', @TaskCallback);
  delay := TDuration.FromMs(100);
  
  CheckTrue(FScheduler.ScheduleDelay(task, delay), 'Should schedule successfully');
  CheckEquals(Ord(ssDelay), Ord(task.GetStrategy), 'Strategy should be delay');
end;

procedure TTestScheduler.Test_ScheduleDelay_Repeat;
var
  task: IScheduledTask;
  delay: TDuration;
begin
  task := FScheduler.CreateTask('DelayRepeat', @TaskCallback);
  delay := TDuration.FromMs(100);
  
  FScheduler.Start;
  CheckTrue(FScheduler.ScheduleDelay(task, delay), 'Should schedule successfully');
  
  // Wait for multiple executions
  Sleep(500);
  
  // Should execute at least 3 times
  CheckTrue(FExecutionCount >= 3, 
    Format('Task should execute at least 3 times, but executed %d times', [FExecutionCount]));
  
  FScheduler.Stop;
end;

procedure TTestScheduler.Test_ScheduleDaily_Basic;
var
  task: IScheduledTask;
  time: TTimeOfDay;
begin
  task := FScheduler.CreateTask('DailyBasic', @TaskCallback);
  time := TTimeOfDay.Create(10, 30, 0);
  
  CheckTrue(FScheduler.ScheduleDaily(task, time), 'Should schedule successfully');
  CheckEquals(Ord(ssCron), Ord(task.GetStrategy), 
    'Strategy should be cron for daily scheduling');
end;

procedure TTestScheduler.Test_ScheduleDaily_NextDay;
var
  task: IScheduledTask;
  time: TTimeOfDay;
  now: TDateTime;
  nowHour, nowMin, nowSec, nowMSec: Word;
begin
  task := FScheduler.CreateTask('DailyNextDay', @TaskCallback);
  
  // Schedule for 1 minute ago (should schedule for tomorrow)
  now := Now;
  DecodeTime(now, nowHour, nowMin, nowSec, nowMSec);
  if nowMin > 0 then
    time := TTimeOfDay.Create(nowHour, nowMin - 1, 0)
  else if nowHour > 0 then
    time := TTimeOfDay.Create(nowHour - 1, 59, 0)
  else
    time := TTimeOfDay.Create(23, 59, 0); // 处理 00:00 的情况
  
  CheckTrue(FScheduler.ScheduleDaily(task, time), 'Should schedule successfully');
  
  // Next run time should be in the future (tomorrow)
  CheckTrue(task.GetNextRunTime > DefaultMonotonicClock.NowInstant, 
    'Next run time should be in the future');
end;

procedure TTestScheduler.Test_ScheduleWeekly_Basic;
var
  task: IScheduledTask;
  time: TTimeOfDay;
  dayOfWeek: Integer;
begin
  task := FScheduler.CreateTask('WeeklyBasic', @TaskCallback);
  time := TTimeOfDay.Create(9, 0, 0);
  dayOfWeek := 1; // Monday
  
  CheckTrue(FScheduler.ScheduleWeekly(task, dayOfWeek, time), 
    'Should schedule successfully');
  CheckEquals(Ord(ssCron), Ord(task.GetStrategy), 
    'Strategy should be cron for weekly scheduling');
end;

procedure TTestScheduler.Test_ScheduleMonthly_Basic;
var
  task: IScheduledTask;
  time: TTimeOfDay;
  day: Integer;
begin
  task := FScheduler.CreateTask('MonthlyBasic', @TaskCallback);
  time := TTimeOfDay.Create(8, 0, 0);
  day := 15;
  
  CheckTrue(FScheduler.ScheduleMonthly(task, day, time), 
    'Should schedule successfully');
  CheckEquals(Ord(ssCron), Ord(task.GetStrategy), 
    'Strategy should be cron for monthly scheduling');
end;

procedure TTestScheduler.Test_RemoveTask;
var
  task1, task2: IScheduledTask;
begin
  task1 := FScheduler.CreateTask('Task1', @TaskCallback);
  task2 := FScheduler.CreateTask('Task2', @TaskCallback);
  
  FScheduler.ScheduleOnce(task1, TDuration.FromSec(10));
  FScheduler.ScheduleOnce(task2, TDuration.FromSec(10));
  
  CheckEquals(2, FScheduler.GetTaskCount, 'Should have 2 tasks');
  
  FScheduler.RemoveTask(task1);
  CheckEquals(1, FScheduler.GetTaskCount, 'Should have 1 task after removal');
  
  FScheduler.RemoveTask(task2.GetId);
  CheckEquals(0, FScheduler.GetTaskCount, 'Should have 0 tasks after removal');
end;

procedure TTestScheduler.Test_GetTasks;
var
  task1, task2, task3: IScheduledTask;
  allTasks: specialize TArray<IScheduledTask>;
begin
  task1 := FScheduler.CreateTask('Task1', @TaskCallback);
  task2 := FScheduler.CreateTask('Task2', @TaskCallback);
  task3 := FScheduler.CreateTask('Task3', @TaskCallback);
  
  FScheduler.ScheduleOnce(task1, TDuration.FromSec(10));
  FScheduler.ScheduleOnce(task2, TDuration.FromSec(10));
  task3.Cancel;
  FScheduler.AddTask(task3);
  
  allTasks := FScheduler.GetTasks;
  CheckEquals(3, Length(allTasks), 'Should have 3 tasks total');
end;

procedure TTestScheduler.Test_TaskCount;
var
  task1, task2: IScheduledTask;
begin
  task1 := FScheduler.CreateTask('Task1', @TaskCallback);
  task2 := FScheduler.CreateTask('Task2', @TaskCallback);
  
  CheckEquals(0, FScheduler.GetTaskCount, 'Should have 0 tasks initially');
  
  FScheduler.ScheduleOnce(task1, TDuration.FromSec(10));
  CheckEquals(1, FScheduler.GetTaskCount, 'Should have 1 task');
  
  FScheduler.ScheduleOnce(task2, TDuration.FromSec(10));
  CheckEquals(2, FScheduler.GetTaskCount, 'Should have 2 tasks');
  
  task1.Cancel;
  CheckEquals(1, FScheduler.GetTaskCount(tsScheduled), 'Should have 1 scheduled task');
  CheckEquals(1, FScheduler.GetTaskCount(tsCancelled), 'Should have 1 cancelled task');
end;

procedure TTestScheduler.Test_ExecutionStatistics;
var
  task: IScheduledTask;
begin
  task := FScheduler.CreateTask('StatsTask', @TaskCallback);
  
  FScheduler.Start;
  FScheduler.ScheduleFixed(task, TDuration.FromMs(100), TDuration.FromMs(50));
  
  // Wait for some executions
  Sleep(500);
  
  CheckTrue(task.GetRunCount > 0, 'Task should have run at least once');
  CheckTrue(task.GetTotalExecutionTime.AsMs >= 0, 
    'Total execution time should be non-negative');
  
  if task.GetRunCount > 0 then
    CheckTrue(task.GetAverageExecutionTime.AsMs >= 0, 
      'Average execution time should be non-negative');
  
  FScheduler.Stop;
end;

procedure TTestScheduler.Test_SchedulerStatistics;
var
  task: IScheduledTask;
  uptime: TDuration;
begin
  task := FScheduler.CreateTask('SchedulerStats', @TaskCallback);
  
  FScheduler.Start;
  FScheduler.ScheduleOnce(task, TDuration.FromMs(50));
  
  Sleep(200);
  
  CheckTrue(FScheduler.GetTotalTasksExecuted > 0, 
    'Should have executed at least one task');
  
  uptime := FScheduler.GetUptime;
  CheckTrue(uptime.AsMs > 0, 'Uptime should be positive');
  
  FScheduler.Stop;
end;

initialization
  RegisterTest(TTestScheduler);

end.
