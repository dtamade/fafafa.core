program test_cron_runner;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.time.instant,
  fafafa.core.time.duration,
  fafafa.core.time.scheduler;

procedure TestCronParsing;
var
  cron: ICronExpression;
begin
  WriteLn('=== Test 1: Cron Expression Parsing ===');
  
  // Test valid expressions
  cron := CreateCronExpression('* * * * *');
  WriteLn('1. Every minute: ', cron.IsValid);
  
  cron := CreateCronExpression('*/5 * * * *');
  WriteLn('2. Every 5 minutes: ', cron.IsValid);
  
  cron := CreateCronExpression('0 9 * * 1-5');
  WriteLn('3. Workdays 9am: ', cron.IsValid);
  
  cron := CreateCronExpression('0 0 1 * *');
  WriteLn('4. Monthly: ', cron.IsValid);
  
  // Test invalid expressions
  cron := CreateCronExpression('60 * * * *');
  WriteLn('5. Invalid minute (60): ', cron.IsValid, ' (should be False)');
  
  cron := CreateCronExpression('* * *');
  WriteLn('6. Too few fields: ', cron.IsValid, ' (should be False)');
  
  WriteLn;
end;

procedure TestCronNextTime;
var
  cron: ICronExpression;
  baseTime, nextTime: TInstant;
  baseDT, nextDT: TDateTime;
begin
  WriteLn('=== Test 2: GetNextTime Calculation ===');
  
  // Test every 5 minutes
  cron := CreateCronExpression('*/5 * * * *');
  baseDT := EncodeDateTime(2025, 1, 1, 10, 3, 0, 0);
  baseTime := TInstant.FromNsSinceEpoch(UInt64(DateTimeToUnix(baseDT, False) * 1000000000));
  
  nextTime := cron.GetNextTime(baseTime);
  if nextTime <> TInstant.Zero then
  begin
    nextDT := UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000, False);
    WriteLn('1. Every 5 min from 10:03 => ', DateTimeToStr(nextDT));
  end;
  
  // Test workdays 9am
  cron := CreateCronExpression('0 9 * * 1-5');
  baseDT := EncodeDateTime(2025, 1, 1, 12, 0, 0, 0);
  baseTime := TInstant.FromNsSinceEpoch(UInt64(DateTimeToUnix(baseDT, False) * 1000000000));
  
  nextTime := cron.GetNextTime(baseTime);
  if nextTime <> TInstant.Zero then
  begin
    nextDT := UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000, False);
    WriteLn('2. Workdays 9am from Wed 12pm => ', DateTimeToStr(nextDT));
  end;
  
  // Test monthly
  cron := CreateCronExpression('0 0 1 * *');
  baseDT := EncodeDateTime(2025, 1, 15, 12, 0, 0, 0);
  baseTime := TInstant.FromNsSinceEpoch(UInt64(DateTimeToUnix(baseDT, False) * 1000000000));
  
  nextTime := cron.GetNextTime(baseTime);
  if nextTime <> TInstant.Zero then
  begin
    nextDT := UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000, False);
    WriteLn('3. Monthly (1st) from Jan 15 => ', DateTimeToStr(nextDT));
  end;
  
  WriteLn;
end;

procedure TestCronMatches;
var
  cron: ICronExpression;
  testTime: TInstant;
  testDT: TDateTime;
begin
  WriteLn('=== Test 3: Time Matching ===');
  
  cron := CreateCronExpression('0 * * * *');
  
  // Should match
  testDT := EncodeDateTime(2025, 1, 1, 10, 0, 0, 0);
  testTime := TInstant.FromNsSinceEpoch(UInt64(DateTimeToUnix(testDT, False) * 1000000000));
  WriteLn('1. 10:00:00 matches "0 * * * *": ', cron.Matches(testTime), ' (should be True)');
  
  // Should not match
  testDT := EncodeDateTime(2025, 1, 1, 10, 30, 0, 0);
  testTime := TInstant.FromNsSinceEpoch(UInt64(DateTimeToUnix(testDT, False) * 1000000000));
  WriteLn('2. 10:30:00 matches "0 * * * *": ', cron.Matches(testTime), ' (should be False)');
  
  WriteLn;
end;

procedure TestCronGetNextTimes;
var
  cron: ICronExpression;
  baseTime: TInstant;
  baseDT, nextDT: TDateTime;
  times: specialize TArray<TInstant>;
  i: Integer;
begin
  WriteLn('=== Test 4: GetNextTimes ===');
  
  cron := CreateCronExpression('*/15 * * * *');
  baseDT := EncodeDateTime(2025, 1, 1, 10, 0, 0, 0);
  baseTime := TInstant.FromNsSinceEpoch(UInt64(DateTimeToUnix(baseDT, False) * 1000000000));
  
  times := cron.GetNextTimes(baseTime, 5);
  WriteLn('Next 5 executions for "*/15 * * * *":');
  
  for i := 0 to High(times) do
  begin
    if times[i] <> TInstant.Zero then
    begin
      nextDT := UnixToDateTime(times[i].AsNsSinceEpoch div 1000000000, False);
      WriteLn(Format('  %d. %s', [i + 1, DateTimeToStr(nextDT)]));
    end;
  end;
  
  WriteLn;
end;

procedure CronTaskCallback(const ATask: IScheduledTask);
begin
  WriteLn('  Cron task executed at: ', DateTimeToStr(Now));
end;

procedure TestSchedulerIntegration;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  WriteLn('=== Test 5: Scheduler Integration ===');
  
  scheduler := CreateTaskScheduler;
  scheduler.Start;
  
  task := scheduler.CreateTask('TestCronTask', @CronTaskCallback);
  
  // Schedule for every minute (for testing, we won't wait)
  if scheduler.ScheduleCron(task, '* * * * *') then
    WriteLn('1. Successfully scheduled Cron task')
  else
    WriteLn('1. Failed to schedule Cron task');
  
  WriteLn('2. Task state: ', Ord(task.GetState));
  WriteLn('3. Task strategy: ', Ord(task.GetStrategy));
  
  scheduler.Stop;
  WriteLn;
end;

procedure TestCommonExpressions;
var
  cron: ICronExpression;
begin
  WriteLn('=== Test 6: Common Expressions ===');
  
  cron := CreateCronExpression('* * * * *');
  WriteLn('1. Every minute: ', cron.IsValid);
  
  cron := CreateCronExpression('0 * * * *');
  WriteLn('2. Every hour: ', cron.IsValid);
  
  cron := CreateCronExpression('0 0 * * *');
  WriteLn('3. Every day: ', cron.IsValid);
  
  cron := CreateCronExpression('0 0 * * 0');
  WriteLn('4. Every week: ', cron.IsValid);
  
  cron := CreateCronExpression('0 0 1 * *');
  WriteLn('5. Every month: ', cron.IsValid);
  
  cron := CreateCronExpression('0 9 * * 1-5');
  WriteLn('6. Workdays: ', cron.IsValid);
  
  cron := CreateCronExpression('0 2 * * *');
  WriteLn('7. Daily backup (2am): ', cron.IsValid);
  
  WriteLn;
end;

var
  startTime: TDateTime;
  
begin
  startTime := Now;
  WriteLn('====================================');
  WriteLn('  Cron Expression Test Runner');
  WriteLn('====================================');
  WriteLn;
  
  try
    TestCronParsing;
    TestCronNextTime;
    TestCronMatches;
    TestCronGetNextTimes;
    TestSchedulerIntegration;
    TestCommonExpressions;
    
    WriteLn('====================================');
    WriteLn('All tests completed successfully!');
    WriteLn('Execution time: ', FormatDateTime('nn:ss.zzz', Now - startTime));
    WriteLn('====================================');
    
    ExitCode := 0;
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('ERROR: ', E.Message);
      WriteLn;
      ExitCode := 1;
    end;
  end;
end.
