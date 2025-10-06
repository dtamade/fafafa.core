# Cron Scheduler - Quick Reference Card

## 📋 Cron Syntax

```
┌───────────── minute (0-59)
│ ┌─────────── hour (0-23)
│ │ ┌───────── day of month (1-31)
│ │ │ ┌─────── month (1-12)
│ │ │ │ ┌───── day of week (0-6, 0=Sunday)
│ │ │ │ │
* * * * *
```

## 🎯 Common Patterns

| Pattern | Description | Example Time |
|---------|-------------|--------------|
| `* * * * *` | Every minute | Every min |
| `*/5 * * * *` | Every 5 minutes | :00, :05, :10, ... |
| `0 * * * *` | Every hour | 00:00, 01:00, ... |
| `0 0 * * *` | Every day at midnight | 00:00 daily |
| `0 2 * * *` | Every day at 2am | 02:00 daily |
| `0 9 * * 1-5` | Workdays at 9am | Mon-Fri 09:00 |
| `0 0 * * 0` | Every Sunday | Sun 00:00 |
| `0 0 1 * *` | First day of month | 1st 00:00 |
| `*/15 9-17 * * 1-5` | Every 15min, business hours | Mon-Fri 09:00-17:00 |
| `0 */2 * * *` | Every 2 hours | 00:00, 02:00, ... |

## 💻 API Quick Start

### 1. Basic Usage
```pascal
uses fafafa.core.time.scheduler;

var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
begin
  scheduler := CreateTaskScheduler;
  scheduler.Start;
  
  task := scheduler.CreateTask('MyTask', @MyCallback);
  scheduler.ScheduleCron(task, '0 2 * * *'); // Daily at 2am
end;
```

### 2. Validate Expression
```pascal
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('*/5 * * * *');
  
  if cron.IsValid then
    WriteLn('Valid!')
  else
    WriteLn('Error: ', cron.GetErrorMessage);
end;
```

### 3. Calculate Next Execution
```pascal
var
  cron: ICronExpression;
  nextTime: TInstant;
begin
  cron := CreateCronExpression('0 9 * * 1-5');
  nextTime := cron.GetNextTime(NowInstant);
  
  WriteLn('Next execution: ', DateTimeToStr(
    UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000)
  ));
end;
```

### 4. Multiple Next Times
```pascal
var
  times: TArray<TInstant>;
  i: Integer;
begin
  cron := CreateCronExpression('*/15 * * * *');
  times := cron.GetNextTimes(NowInstant, 5);
  
  for i := 0 to High(times) do
    WriteLn('Execution ', i+1, ': ', ...);
end;
```

## 🔧 Field Syntax

| Symbol | Meaning | Example |
|--------|---------|---------|
| `*` | Any value | `* * * * *` = every minute |
| `n` | Specific value | `5 * * * *` = at :05 every hour |
| `n-m` | Range | `1-5 * * * *` = minutes 1-5 |
| `n,m` | List | `1,3,5 * * * *` = at :01, :03, :05 |
| `*/n` | Step | `*/15 * * * *` = every 15 minutes |
| `n-m/s` | Range with step | `10-50/10 * * * *` = :10, :20, :30, :40, :50 |

## 📅 Real-World Examples

### Daily Tasks
```pascal
// Database backup at 2am
'0 2 * * *'

// Log rotation at midnight
'0 0 * * *'

// Daily report at 6pm
'0 18 * * *'
```

### Workday Tasks
```pascal
// Morning standup notification (9am, Mon-Fri)
'0 9 * * 1-5'

// End of day reminder (5pm, Mon-Fri)
'0 17 * * 1-5'

// Lunch break (noon, Mon-Fri)
'0 12 * * 1-5'
```

### Periodic Tasks
```pascal
// Every 5 minutes
'*/5 * * * *'

// Every 15 minutes during business hours (9am-5pm)
'*/15 9-17 * * *'

// Every 2 hours
'0 */2 * * *'

// Every hour on the half-hour
'30 * * * *'
```

### Weekly Tasks
```pascal
// Monday morning
'0 9 * * 1'

// Friday afternoon
'0 15 * * 5'

// Weekend backup (Saturday midnight)
'0 0 * * 6'

// Weekly report (Sunday 10am)
'0 10 * * 0'
```

### Monthly Tasks
```pascal
// First day of month
'0 0 1 * *'

// Middle of month (15th)
'0 0 15 * *'

// Every 1st and 15th
'0 0 1,15 * *'
```

## ⚠️ Common Mistakes

| ❌ Wrong | ✅ Correct | Note |
|---------|-----------|------|
| `60 * * * *` | `0 * * * *` | Minutes are 0-59 |
| `0 24 * * *` | `0 0 * * *` | Hours are 0-23 |
| `* * 32 * *` | `* * 1-31 * *` | Days are 1-31 |
| `* * * 13 *` | `* * * 1-12 *` | Months are 1-12 |
| `* * * * 7` | `* * * * 0-6` | Weekdays are 0-6 |
| `0 9 * * Mon-Fri` | `0 9 * * 1-5` | Use numbers, not names |

## 🔍 Validation Checklist

Before deploying:
- ✅ Expression has exactly 5 fields
- ✅ All values are within valid ranges
- ✅ Test with `CreateCronExpression().IsValid`
- ✅ Verify next execution time with `GetNextTime()`
- ✅ Check timezone assumptions
- ✅ Consider daylight saving time transitions

## 📊 Performance Tips

1. **Prefer specific patterns** over wildcards when possible
2. **Batch similar schedules** to reduce overhead
3. **Use step values** (`*/n`) for regular intervals
4. **Avoid very frequent tasks** (< 1 minute) for production
5. **Monitor scheduler load** when running 100+ tasks

## 🐛 Debugging

```pascal
// Check if expression is valid
if not cron.IsValid then
  WriteLn('Error: ', cron.GetErrorMessage);

// Verify next execution time
WriteLn('Next run: ', GetNextTimeAsString(cron));

// Test if time matches
if cron.Matches(someInstant) then
  WriteLn('Time matches pattern');

// Get multiple next times to verify pattern
var times := cron.GetNextTimes(NowInstant, 10);
```

## 📚 More Resources

- **Full Guide**: `docs/CRON_USAGE_GUIDE.md`
- **Examples**: `examples/time_scheduler_cron_example.pas`
- **Tests**: `tests/Test_fafafa_core_time_scheduler.pas`
- **Online Tester**: https://crontab.guru

## 🆘 Support

- Email: dtamade@gmail.com
- QQ: 179033731
- QQ Group: 685403987

---

*Quick Reference v1.0 - fafafa.core.time.scheduler*
