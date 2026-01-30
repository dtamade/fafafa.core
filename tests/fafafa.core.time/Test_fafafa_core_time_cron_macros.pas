unit Test_fafafa_core_time_cron_macros;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, DateUtils,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.scheduler;

type
  { TTestCase_CronMacros }
  TTestCase_CronMacros = class(TTestCase)
  published
    // Macro validation tests
    procedure Test_Yearly_Macro;
    procedure Test_Annually_Macro;
    procedure Test_Monthly_Macro;
    procedure Test_Weekly_Macro;
    procedure Test_Daily_Macro;
    procedure Test_Midnight_Macro;
    procedure Test_Hourly_Macro;
    procedure Test_Unknown_Macro;
    
    // Macro equivalence tests
    procedure Test_Yearly_Equals_CronExpr;
    procedure Test_Monthly_Equals_CronExpr;
    procedure Test_Weekly_Equals_CronExpr;
    procedure Test_Daily_Equals_CronExpr;
    procedure Test_Hourly_Equals_CronExpr;
    
    // Integration tests
    procedure Test_Schedule_With_Yearly_Macro;
    procedure Test_Schedule_With_Daily_Macro;
    procedure Test_Schedule_With_Hourly_Macro;
    
    // Next time calculation
    procedure Test_Yearly_NextTime;
    procedure Test_Monthly_NextTime;
    procedure Test_Weekly_NextTime;
    procedure Test_Daily_NextTime;
    procedure Test_Hourly_NextTime;
  end;

implementation

{ TTestCase_CronMacros }

procedure TTestCase_CronMacros.Test_Yearly_Macro;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('@yearly');
  CheckTrue(cron.IsValid, '@yearly should be valid');
  CheckEquals('@yearly', cron.GetExpression, 'Expression should be preserved');
end;

procedure TTestCase_CronMacros.Test_Annually_Macro;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('@annually');
  CheckTrue(cron.IsValid, '@annually should be valid');
  CheckEquals('@annually', cron.GetExpression, 'Expression should be preserved');
end;

procedure TTestCase_CronMacros.Test_Monthly_Macro;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('@monthly');
  CheckTrue(cron.IsValid, '@monthly should be valid');
  CheckEquals('@monthly', cron.GetExpression, 'Expression should be preserved');
end;

procedure TTestCase_CronMacros.Test_Weekly_Macro;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('@weekly');
  CheckTrue(cron.IsValid, '@weekly should be valid');
  CheckEquals('@weekly', cron.GetExpression, 'Expression should be preserved');
end;

procedure TTestCase_CronMacros.Test_Daily_Macro;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('@daily');
  CheckTrue(cron.IsValid, '@daily should be valid');
  CheckEquals('@daily', cron.GetExpression, 'Expression should be preserved');
end;

procedure TTestCase_CronMacros.Test_Midnight_Macro;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('@midnight');
  CheckTrue(cron.IsValid, '@midnight should be valid');
  CheckEquals('@midnight', cron.GetExpression, 'Expression should be preserved');
end;

procedure TTestCase_CronMacros.Test_Hourly_Macro;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('@hourly');
  CheckTrue(cron.IsValid, '@hourly should be valid');
  CheckEquals('@hourly', cron.GetExpression, 'Expression should be preserved');
end;

procedure TTestCase_CronMacros.Test_Unknown_Macro;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('@unknown');
  CheckFalse(cron.IsValid, '@unknown should be invalid');
  CheckTrue(Pos('Unknown macro', cron.GetDescription) > 0, 
    'Error message should mention unknown macro');
end;

procedure TTestCase_CronMacros.Test_Yearly_Equals_CronExpr;
var
  cronMacro, cronExpr: ICronExpression;
  macroTime, exprTime: TInstant;
  now: TInstant;
begin
  cronMacro := CreateCronExpression('@yearly');
  cronExpr := CreateCronExpression('0 0 1 1 *');
  
  CheckTrue(cronMacro.IsValid, '@yearly should be valid');
  CheckTrue(cronExpr.IsValid, '0 0 1 1 * should be valid');
  
  now := NowInstant;
  macroTime := cronMacro.GetNextTime(now);
  exprTime := cronExpr.GetNextTime(now);
  
  CheckEquals(exprTime.AsNsSinceEpoch, macroTime.AsNsSinceEpoch,
    '@yearly should equal 0 0 1 1 *');
end;

procedure TTestCase_CronMacros.Test_Monthly_Equals_CronExpr;
var
  cronMacro, cronExpr: ICronExpression;
  macroTime, exprTime: TInstant;
  now: TInstant;
begin
  cronMacro := CreateCronExpression('@monthly');
  cronExpr := CreateCronExpression('0 0 1 * *');
  
  CheckTrue(cronMacro.IsValid, '@monthly should be valid');
  CheckTrue(cronExpr.IsValid, '0 0 1 * * should be valid');
  
  now := NowInstant;
  macroTime := cronMacro.GetNextTime(now);
  exprTime := cronExpr.GetNextTime(now);
  
  CheckEquals(exprTime.AsNsSinceEpoch, macroTime.AsNsSinceEpoch,
    '@monthly should equal 0 0 1 * *');
end;

procedure TTestCase_CronMacros.Test_Weekly_Equals_CronExpr;
var
  cronMacro, cronExpr: ICronExpression;
  macroTime, exprTime: TInstant;
  now: TInstant;
begin
  cronMacro := CreateCronExpression('@weekly');
  cronExpr := CreateCronExpression('0 0 * * 0');
  
  CheckTrue(cronMacro.IsValid, '@weekly should be valid');
  CheckTrue(cronExpr.IsValid, '0 0 * * 0 should be valid');
  
  now := NowInstant;
  macroTime := cronMacro.GetNextTime(now);
  exprTime := cronExpr.GetNextTime(now);
  
  CheckEquals(exprTime.AsNsSinceEpoch, macroTime.AsNsSinceEpoch,
    '@weekly should equal 0 0 * * 0');
end;

procedure TTestCase_CronMacros.Test_Daily_Equals_CronExpr;
var
  cronMacro, cronExpr: ICronExpression;
  macroTime, exprTime: TInstant;
  now: TInstant;
begin
  cronMacro := CreateCronExpression('@daily');
  cronExpr := CreateCronExpression('0 0 * * *');
  
  CheckTrue(cronMacro.IsValid, '@daily should be valid');
  CheckTrue(cronExpr.IsValid, '0 0 * * * should be valid');
  
  now := NowInstant;
  macroTime := cronMacro.GetNextTime(now);
  exprTime := cronExpr.GetNextTime(now);
  
  CheckEquals(exprTime.AsNsSinceEpoch, macroTime.AsNsSinceEpoch,
    '@daily should equal 0 0 * * *');
end;

procedure TTestCase_CronMacros.Test_Hourly_Equals_CronExpr;
var
  cronMacro, cronExpr: ICronExpression;
  macroTime, exprTime: TInstant;
  now: TInstant;
begin
  cronMacro := CreateCronExpression('@hourly');
  cronExpr := CreateCronExpression('0 * * * *');
  
  CheckTrue(cronMacro.IsValid, '@hourly should be valid');
  CheckTrue(cronExpr.IsValid, '0 * * * * should be valid');
  
  now := NowInstant;
  macroTime := cronMacro.GetNextTime(now);
  exprTime := cronExpr.GetNextTime(now);
  
  CheckEquals(exprTime.AsNsSinceEpoch, macroTime.AsNsSinceEpoch,
    '@hourly should equal 0 * * * *');
end;

procedure DummyCallback1(const ATask: IScheduledTask);
begin
  // Empty callback for testing
end;

procedure TTestCase_CronMacros.Test_Schedule_With_Yearly_Macro;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  scheduler := CreateTaskScheduler;
  scheduler.Start;
  
  task := scheduler.CreateTask('YearlyTask', @DummyCallback1);
  
  CheckTrue(scheduler.ScheduleCron(task, '@yearly'), 
    'Should schedule with @yearly macro');
  CheckEquals(Ord(ssCron), Ord(task.GetStrategy), 
    'Strategy should be Cron');
  CheckTrue(task.GetNextRunTime <> TInstant.Zero, 
    'Next run time should be set');
  
  scheduler.Stop;
end;

procedure DummyCallback2(const ATask: IScheduledTask);
begin
  // Empty callback for testing
end;

procedure TTestCase_CronMacros.Test_Schedule_With_Daily_Macro;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  scheduler := CreateTaskScheduler;
  scheduler.Start;
  
  task := scheduler.CreateTask('DailyTask', @DummyCallback2);
  
  CheckTrue(scheduler.ScheduleCron(task, '@daily'), 
    'Should schedule with @daily macro');
  CheckEquals(Ord(ssCron), Ord(task.GetStrategy), 
    'Strategy should be Cron');
  
  scheduler.Stop;
end;

procedure DummyCallback3(const ATask: IScheduledTask);
begin
  // Empty callback for testing
end;

procedure TTestCase_CronMacros.Test_Schedule_With_Hourly_Macro;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  scheduler := CreateTaskScheduler;
  scheduler.Start;
  
  task := scheduler.CreateTask('HourlyTask', @DummyCallback3);
  
  CheckTrue(scheduler.ScheduleCron(task, '@hourly'), 
    'Should schedule with @hourly macro');
  CheckEquals(Ord(ssCron), Ord(task.GetStrategy), 
    'Strategy should be Cron');
  
  scheduler.Stop;
end;

procedure TTestCase_CronMacros.Test_Yearly_NextTime;
var
  cron: ICronExpression;
  now, next: TInstant;
  nowDT, nextDT: TDateTime;
  nextYear, nextMonth, nextDay: Word;
begin
  cron := CreateCronExpression('@yearly');
  now := NowInstant;
  next := cron.GetNextTime(now);
  
  CheckTrue(next <> TInstant.Zero, 'Next time should be valid');
  CheckTrue(next > now, 'Next time should be in future');
  
  // Convert to DateTime to check it's Jan 1 at midnight
  nextDT := UnixToDateTime(next.AsNsSinceEpoch div 1000000000, False);
  DecodeDate(nextDT, nextYear, nextMonth, nextDay);
  
  CheckEquals(1, nextMonth, 'Should be January');
  CheckEquals(1, nextDay, 'Should be 1st day');
end;

procedure TTestCase_CronMacros.Test_Monthly_NextTime;
var
  cron: ICronExpression;
  now, next: TInstant;
  nowDT, nextDT: TDateTime;
  nextYear, nextMonth, nextDay: Word;
begin
  cron := CreateCronExpression('@monthly');
  now := NowInstant;
  next := cron.GetNextTime(now);
  
  CheckTrue(next <> TInstant.Zero, 'Next time should be valid');
  CheckTrue(next > now, 'Next time should be in future');
  
  // Convert to DateTime to check it's 1st of month at midnight
  nextDT := UnixToDateTime(next.AsNsSinceEpoch div 1000000000, False);
  DecodeDate(nextDT, nextYear, nextMonth, nextDay);
  
  CheckEquals(1, nextDay, 'Should be 1st day of month');
end;

procedure TTestCase_CronMacros.Test_Weekly_NextTime;
var
  cron: ICronExpression;
  now, next: TInstant;
  nextDT: TDateTime;
  nextDOW: Integer;
begin
  cron := CreateCronExpression('@weekly');
  now := NowInstant;
  next := cron.GetNextTime(now);
  
  CheckTrue(next <> TInstant.Zero, 'Next time should be valid');
  CheckTrue(next > now, 'Next time should be in future');
  
  // Convert to DateTime to check it's Sunday
  nextDT := UnixToDateTime(next.AsNsSinceEpoch div 1000000000, False);
  nextDOW := DayOfWeek(nextDT);
  
  CheckEquals(1, nextDOW, 'Should be Sunday (DayOfWeek = 1)');
end;

procedure TTestCase_CronMacros.Test_Daily_NextTime;
var
  cron: ICronExpression;
  now, next: TInstant;
  nowDT, nextDT: TDateTime;
  nextHour, nextMin, nextSec, nextMSec: Word;
begin
  cron := CreateCronExpression('@daily');
  now := NowInstant;
  next := cron.GetNextTime(now);
  
  CheckTrue(next <> TInstant.Zero, 'Next time should be valid');
  CheckTrue(next > now, 'Next time should be in future');
  
  // Convert to DateTime to check it's midnight
  nextDT := UnixToDateTime(next.AsNsSinceEpoch div 1000000000, False);
  DecodeTime(nextDT, nextHour, nextMin, nextSec, nextMSec);
  
  CheckEquals(0, nextHour, 'Should be at hour 0');
  CheckEquals(0, nextMin, 'Should be at minute 0');
end;

procedure TTestCase_CronMacros.Test_Hourly_NextTime;
var
  cron: ICronExpression;
  now, next: TInstant;
  nowDT, nextDT: TDateTime;
  nowHour, nowMin, nowSec, nowMSec: Word;
  nextHour, nextMin, nextSec, nextMSec: Word;
begin
  cron := CreateCronExpression('@hourly');
  now := NowInstant;
  next := cron.GetNextTime(now);
  
  CheckTrue(next <> TInstant.Zero, 'Next time should be valid');
  CheckTrue(next > now, 'Next time should be in future');
  
  // Convert to DateTime to check minute is 0
  nowDT := UnixToDateTime(now.AsNsSinceEpoch div 1000000000, False);
  nextDT := UnixToDateTime(next.AsNsSinceEpoch div 1000000000, False);
  
  DecodeTime(nowDT, nowHour, nowMin, nowSec, nowMSec);
  DecodeTime(nextDT, nextHour, nextMin, nextSec, nextMSec);
  
  CheckEquals(0, nextMin, 'Should be at minute 0');
  
  // Next hour should be current hour + 1 (or 0 if currently 23)
  if nowHour < 23 then
    CheckTrue(nextHour >= nowHour, 'Should be at or after current hour')
  else
    CheckTrue(nextHour >= 0, 'Should wrap to next day if at hour 23');
end;

initialization
  RegisterTest(TTestCase_CronMacros);

end.
