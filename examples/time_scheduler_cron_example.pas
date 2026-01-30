program time_scheduler_cron_example;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils, Classes,
  fafafa.core.time.instant,
  fafafa.core.time.duration,
  fafafa.core.time.scheduler,
  fafafa.core.time.clock;

var
  Scheduler: ITaskScheduler;
  BackupTask, ReportTask, CleanupTask, HealthCheckTask: IScheduledTask;
  Running: Boolean = True;

// Simulated database backup task
procedure DatabaseBackup(const ATask: IScheduledTask);
begin
  WriteLn('[', DateTimeToStr(Now), '] Running daily backup...');
  Sleep(100); // Simulate backup work
  WriteLn('[', DateTimeToStr(Now), '] Backup completed successfully');
end;

// Simulated report generation task
procedure GenerateReport(const ATask: IScheduledTask);
begin
  WriteLn('[', DateTimeToStr(Now), '] Generating weekly report...');
  Sleep(50); // Simulate report generation
  WriteLn('[', DateTimeToStr(Now), '] Report generated and emailed');
end;

// Simulated cleanup task
procedure CleanupOldFiles(const ATask: IScheduledTask);
begin
  WriteLn('[', DateTimeToStr(Now), '] Cleaning up old files...');
  Sleep(30); // Simulate cleanup
  WriteLn('[', DateTimeToStr(Now), '] Cleanup completed');
end;

// Simulated health check task
procedure HealthCheck(const ATask: IScheduledTask);
var
  status: string;
begin
  // Randomly simulate healthy/unhealthy status
  if Random(10) > 2 then
    status := 'HEALTHY'
  else
    status := 'WARNING';
  
  WriteLn('[', DateTimeToStr(Now), '] Health check: ', status);
end;

// Demo scenario 1: Basic daily backup at 2am
procedure DemoScenario1_DailyBackup;
var
  cron: ICronExpression;
  now: TInstant;
  nextTimes: specialize TArray<TInstant>;
  i: Integer;
  dt: TDateTime;
begin
  WriteLn;
  WriteLn('=== Scenario 1: Daily Backup at 2am ===');
  WriteLn('Cron: "0 2 * * *" - Every day at 2:00am');
  WriteLn;
  
  Scheduler := CreateTaskScheduler;
  Scheduler.Start;
  
  BackupTask := Scheduler.CreateTask('DailyBackup', @DatabaseBackup);
  
  if Scheduler.ScheduleCron(BackupTask, '0 2 * * *') then
  begin
    WriteLn('✓ Backup scheduled successfully');
    WriteLn('  State: ', Ord(BackupTask.GetState));
    WriteLn('  Strategy: ', Ord(BackupTask.GetStrategy));
    
    // Show next 5 scheduled times
    cron := CreateCronExpression('0 2 * * *');
    // 使用系统时钟的 Unix 纳秒构造 TInstant，避免与单调时钟混用
    now := TInstant.FromNsSinceEpoch(UInt64(DefaultSystemClock.NowUnixNs));
    nextTimes := cron.GetNextTimes(now, 5);
    
    WriteLn;
    WriteLn('Next 5 scheduled executions:');
    for i := 0 to High(nextTimes) do
    begin
      dt := UnixToDateTime(nextTimes[i].AsNsSinceEpoch div 1000000000, False);
      WriteLn('  ', i+1, '. ', DateTimeToStr(dt));
    end;
  end
  else
    WriteLn('✗ Failed to schedule backup');
  
  Sleep(1000);
  Scheduler.Stop;
end;

// Demo scenario 2: Workday reports at 9am Mon-Fri
procedure DemoScenario2_WorkdayReports;
var
  cron: ICronExpression;
  now: TInstant;
  nextTimes: specialize TArray<TInstant>;
  i: Integer;
  dt: TDateTime;
  dow: Integer;
begin
  WriteLn;
  WriteLn('=== Scenario 2: Workday Reports at 9am ===');
  WriteLn('Cron: "0 9 * * 1-5" - Monday to Friday at 9:00am');
  WriteLn;
  
  Scheduler := CreateTaskScheduler;
  Scheduler.Start;
  
  ReportTask := Scheduler.CreateTask('WorkdayReport', @GenerateReport);
  
  if Scheduler.ScheduleCron(ReportTask, '0 9 * * 1-5') then
  begin
    WriteLn('✓ Report scheduled successfully');
    
    // Show next 5 workday executions
    cron := CreateCronExpression('0 9 * * 1-5');
    now := TInstant.FromNsSinceEpoch(UInt64(DefaultSystemClock.NowUnixNs));
    nextTimes := cron.GetNextTimes(now, 5);
    
    WriteLn;
    WriteLn('Next 5 workday executions:');
    for i := 0 to High(nextTimes) do
    begin
      dt := UnixToDateTime(nextTimes[i].AsNsSinceEpoch div 1000000000, False);
      dow := DayOfWeek(dt);
      WriteLn('  ', i+1, '. ', FormatDateTime('yyyy-mm-dd (ddd) hh:nn', dt));
    end;
  end
  else
    WriteLn('✗ Failed to schedule report');
  
  Sleep(1000);
  Scheduler.Stop;
end;

// Demo scenario 3: Multiple tasks with different schedules
procedure DemoScenario3_MultipleTasksComposite;
begin
  WriteLn;
  WriteLn('=== Scenario 3: Multiple Tasks Running Together ===');
  WriteLn;
  
  Scheduler := CreateTaskScheduler;
  Scheduler.Start;
  
  // Daily backup at 2am
  BackupTask := Scheduler.CreateTask('DailyBackup', @DatabaseBackup);
  if Scheduler.ScheduleCron(BackupTask, '0 2 * * *') then
    WriteLn('✓ Daily backup scheduled (2am)');
  
  // Weekly cleanup on Sundays at midnight
  CleanupTask := Scheduler.CreateTask('WeeklyCleanup', @CleanupOldFiles);
  if Scheduler.ScheduleCron(CleanupTask, '0 0 * * 0') then
    WriteLn('✓ Weekly cleanup scheduled (Sun 00:00)');
  
  // Health check every 15 minutes
  HealthCheckTask := Scheduler.CreateTask('HealthCheck', @HealthCheck);
  if Scheduler.ScheduleCron(HealthCheckTask, '*/15 * * * *') then
    WriteLn('✓ Health check scheduled (every 15 min)');
  
  WriteLn;
  WriteLn('All tasks scheduled. Running health checks for 2 minutes...');
  WriteLn('(Press Ctrl+C to stop)');
  WriteLn;
  
  // Let it run for 2 minutes to see health checks executing
  Sleep(120000);
  
  WriteLn;
  WriteLn('Stopping scheduler...');
  Scheduler.Stop;
end;

// Demo scenario 4: Advanced Cron patterns
procedure DemoScenario4_AdvancedPatterns;
type
  TPattern = record
    pattern: string;
    description: string;
  end;
const
  patterns: array[1..10] of TPattern = (
    (pattern: '*/5 * * * *'; description: 'Every 5 minutes'),
    (pattern: '0 */2 * * *'; description: 'Every 2 hours'),
    (pattern: '0 0 1 * *'; description: 'First day of every month'),
    (pattern: '0 0 * * 0'; description: 'Every Sunday at midnight'),
    (pattern: '0 9-17 * * 1-5'; description: 'Every hour 9am-5pm on weekdays'),
    (pattern: '*/30 9-17 * * 1-5'; description: 'Every 30 min, 9am-5pm, weekdays'),
    (pattern: '0 0 1,15 * *'; description: '1st and 15th of every month'),
    (pattern: '0 8 * * 1,3,5'; description: 'Mon, Wed, Fri at 8am'),
    (pattern: '0 22 * * 1-5'; description: 'Weekdays at 10pm'),
    (pattern: '0 0 * * 6'; description: 'Every Saturday at midnight')
  );
var
  i: Integer;
  cron: ICronExpression;
  now: TInstant;
  nextTime: TInstant;
  dt: TDateTime;
begin
  WriteLn;
  WriteLn('=== Scenario 4: Advanced Cron Patterns ===');
  WriteLn;
  
  for i := 1 to 10 do
  begin
    cron := CreateCronExpression(patterns[i].pattern);
      if cron.IsValid then
      begin
        WriteLn('✓ ', patterns[i].pattern:20, ' - ', patterns[i].description);
        
        // Show next execution
        now := TInstant.FromNsSinceEpoch(UInt64(DefaultSystemClock.NowUnixNs));
        nextTime := cron.GetNextTime(now);
      if nextTime <> TInstant.Zero then
      begin
        dt := UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000, False);
        WriteLn('  Next: ', DateTimeToStr(dt));
      end;
    end
    else
      WriteLn('✗ ', patterns[i].pattern:20, ' - INVALID');
    
    WriteLn;
  end;
end;

// Demo scenario 5: Task lifecycle management
procedure DemoScenario5_TaskLifecycle;
begin
  WriteLn;
  WriteLn('=== Scenario 5: Task Lifecycle Management ===');
  WriteLn;
  
  Scheduler := CreateTaskScheduler;
  Scheduler.Start;
  
  // Create and schedule a task
  HealthCheckTask := Scheduler.CreateTask('HealthCheckTask', @HealthCheck);
  WriteLn('1. Task created, state: ', Ord(HealthCheckTask.GetState));
  
  if Scheduler.ScheduleCron(HealthCheckTask, '*/1 * * * *') then
  begin
    WriteLn('2. Task scheduled (every minute)');
    WriteLn('   State: ', Ord(HealthCheckTask.GetState));
    WriteLn('   Strategy: ', Ord(HealthCheckTask.GetStrategy));
  end;
  
  WriteLn;
  WriteLn('3. Running for 5 seconds...');
  Sleep(5000);
  
  // Cancel the task
  WriteLn;
  WriteLn('4. Cancelling task...');
  HealthCheckTask.Cancel;
  WriteLn('   Task cancelled successfully');
  WriteLn('   State: ', Ord(HealthCheckTask.GetState));
  
  WriteLn;
  WriteLn('5. Attempting to reschedule same task...');
  if Scheduler.ScheduleCron(HealthCheckTask, '*/2 * * * *') then
    WriteLn('   Task rescheduled (every 2 minutes)')
  else
    WriteLn('   Cannot reschedule cancelled task');
  
  Sleep(2000);
  
  WriteLn;
  WriteLn('6. Stopping scheduler...');
  Scheduler.Stop;
  WriteLn('   Scheduler stopped');
end;

// Demo scenario 6: Error handling
procedure DemoScenario6_ErrorHandling;
const
  invalidPatterns: array[1..6] of string = (
    '60 * * * *',    // Invalid minute (>59)
    '* 24 * * *',    // Invalid hour (>23)
    '* * 32 * *',    // Invalid day (>31)
    '* * * 13 *',    // Invalid month (>12)
    '* * * * 7',     // Invalid weekday (>6)
    '* * *'          // Too few fields
  );
var
  i: Integer;
  cron: ICronExpression;
  task: IScheduledTask;
begin
  WriteLn;
  WriteLn('=== Scenario 6: Error Handling ===');
  WriteLn;
  
  Scheduler := CreateTaskScheduler;
  Scheduler.Start;
  
  // Test invalid Cron expressions
  WriteLn('Testing invalid Cron expressions:');
  
  for i := 1 to 6 do
  begin
    cron := CreateCronExpression(invalidPatterns[i]);
    if not cron.IsValid then
      WriteLn('  ✓ Correctly rejected: ', invalidPatterns[i])
    else
      WriteLn('  ✗ Should have rejected: ', invalidPatterns[i]);
  end;
  
  WriteLn;
  WriteLn('Testing task scheduling edge cases:');
  
  // Try to schedule with invalid expression
  task := Scheduler.CreateTask('TestTask', @HealthCheck);
  if not Scheduler.ScheduleCron(task, '60 * * * *') then
    WriteLn('  ✓ Invalid expression rejected during scheduling');
  
  // Try to schedule empty task
  if not Scheduler.ScheduleCron(nil, '* * * * *') then
    WriteLn('  ✓ Nil task rejected');
  
  Scheduler.Stop;
end;

var
  choice: Integer;

begin
  Randomize;
  
  WriteLn('============================================');
  WriteLn('  Cron Scheduler Integration Examples');
  WriteLn('============================================');
  WriteLn;
  WriteLn('Select a scenario to run:');
  WriteLn('  1. Daily Backup at 2am');
  WriteLn('  2. Workday Reports at 9am (Mon-Fri)');
  WriteLn('  3. Multiple Tasks Running Together');
  WriteLn('  4. Advanced Cron Patterns');
  WriteLn('  5. Task Lifecycle Management');
  WriteLn('  6. Error Handling');
  WriteLn('  0. Run all scenarios');
  WriteLn;
  Write('Enter choice: ');
  ReadLn(choice);
  
  case choice of
    1: DemoScenario1_DailyBackup;
    2: DemoScenario2_WorkdayReports;
    3: DemoScenario3_MultipleTasksComposite;
    4: DemoScenario4_AdvancedPatterns;
    5: DemoScenario5_TaskLifecycle;
    6: DemoScenario6_ErrorHandling;
    0: begin
         DemoScenario1_DailyBackup;
         DemoScenario2_WorkdayReports;
         DemoScenario4_AdvancedPatterns;
         DemoScenario5_TaskLifecycle;
         DemoScenario6_ErrorHandling;
         // Skip scenario 3 (long-running)
       end;
  else
    WriteLn('Invalid choice');
  end;
  
  WriteLn;
  WriteLn('============================================');
  WriteLn('Examples completed. Press Enter to exit...');
  WriteLn('============================================');
  ReadLn;
end.
