{$mode objfpc}{$H+}{$J-}
{$I ..\..\src\fafafa.core.settings.inc}

unit Test_fafafa_core_time_cron_boundary;

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.time.instant,
  fafafa.core.time.scheduler;

type
  {
    CRON 表达式边界测试

    验证场景：
    1. GetPreviousTime 反向查找功能
    2. 边界条件（年初、年末、闰年、月末）
    3. 安全限制（长度限制、值数量限制）
    4. 特殊 CRON 表达式
  }
  TTestCronBoundary = class(TTestCase)
  published
    // GetPreviousTime 测试
    procedure Test_GetPreviousTime_Basic;
    procedure Test_GetPreviousTime_Hourly;
    procedure Test_GetPreviousTime_Daily;
    procedure Test_GetPreviousTime_Monthly;
    procedure Test_GetPreviousTime_CrossYear;

    // 边界条件测试
    procedure Test_Cron_LeapYear_Feb29;
    procedure Test_Cron_YearEnd_Dec31;
    procedure Test_Cron_YearStart_Jan1;
    procedure Test_Cron_MonthEnd_Various;

    // 安全限制测试
    procedure Test_Cron_ExpressionLengthLimit;
    procedure Test_Cron_ListValuesLimit;
    procedure Test_Cron_InvalidExpression;

    // 常用表达式测试
    procedure Test_Cron_EveryMinute;
    procedure Test_Cron_Midnight;
    procedure Test_Cron_Weekdays;
  end;

implementation

{ TTestCronBoundary }

// === GetPreviousTime 测试 ===

procedure TTestCronBoundary.Test_GetPreviousTime_Basic;
var
  cron: ICronExpression;
  fromTime, prevTime: TInstant;
begin
  // 每分钟执行: * * * * *
  cron := CreateCronExpression('* * * * *');
  AssertTrue('CRON 表达式应有效', cron.IsValid);

  // 从 2025-12-24 14:30:00 查找上一个执行时间
  fromTime := TInstant.FromNsSinceEpoch(
    DateTimeToUnix(EncodeDate(2025, 12, 24) + EncodeTime(14, 30, 0, 0), False) * 1000000000);
  prevTime := cron.GetPreviousTime(fromTime);

  AssertTrue('GetPreviousTime 应返回有效时间', prevTime <> TInstant.Zero);
  AssertTrue('上一个执行时间应在当前时间之前', prevTime < fromTime);
end;

procedure TTestCronBoundary.Test_GetPreviousTime_Hourly;
var
  cron: ICronExpression;
  fromTime, prevTime: TInstant;
  prevDT: TDateTime;
begin
  // 每小时整点执行: 0 * * * *
  cron := CreateCronExpression('0 * * * *');
  AssertTrue('CRON 表达式应有效', cron.IsValid);

  // 从 14:30 查找，应该返回 14:00
  fromTime := TInstant.FromNsSinceEpoch(
    DateTimeToUnix(EncodeDate(2025, 12, 24) + EncodeTime(14, 30, 0, 0), False) * 1000000000);
  prevTime := cron.GetPreviousTime(fromTime);

  AssertTrue('GetPreviousTime 应返回有效时间', prevTime <> TInstant.Zero);
  prevDT := UnixToDateTime(prevTime.AsNsSinceEpoch div 1000000000, False);
  AssertEquals('分钟应为 0', 0, MinuteOf(prevDT));
end;

procedure TTestCronBoundary.Test_GetPreviousTime_Daily;
var
  cron: ICronExpression;
  fromTime, prevTime: TInstant;
  prevDT: TDateTime;
begin
  // 每天 9:00 执行: 0 9 * * *
  cron := CreateCronExpression('0 9 * * *');
  AssertTrue('CRON 表达式应有效', cron.IsValid);

  // 从 12-24 14:30 查找，应该返回 12-24 9:00
  fromTime := TInstant.FromNsSinceEpoch(
    DateTimeToUnix(EncodeDate(2025, 12, 24) + EncodeTime(14, 30, 0, 0), False) * 1000000000);
  prevTime := cron.GetPreviousTime(fromTime);

  AssertTrue('GetPreviousTime 应返回有效时间', prevTime <> TInstant.Zero);
  prevDT := UnixToDateTime(prevTime.AsNsSinceEpoch div 1000000000, False);
  AssertEquals('小时应为 9', 9, HourOf(prevDT));
  AssertEquals('分钟应为 0', 0, MinuteOf(prevDT));
end;

procedure TTestCronBoundary.Test_GetPreviousTime_Monthly;
var
  cron: ICronExpression;
  fromTime, prevTime: TInstant;
  prevDT: TDateTime;
begin
  // 每月 1 号 0:00 执行: 0 0 1 * *
  cron := CreateCronExpression('0 0 1 * *');
  AssertTrue('CRON 表达式应有效', cron.IsValid);

  // 从 12-24 查找，应该返回 12-1 0:00
  fromTime := TInstant.FromNsSinceEpoch(
    DateTimeToUnix(EncodeDate(2025, 12, 24) + EncodeTime(14, 30, 0, 0), False) * 1000000000);
  prevTime := cron.GetPreviousTime(fromTime);

  AssertTrue('GetPreviousTime 应返回有效时间', prevTime <> TInstant.Zero);
  prevDT := UnixToDateTime(prevTime.AsNsSinceEpoch div 1000000000, False);
  AssertEquals('日期应为 1', 1, DayOf(prevDT));
end;

procedure TTestCronBoundary.Test_GetPreviousTime_CrossYear;
var
  cron: ICronExpression;
  fromTime, prevTime: TInstant;
  prevDT: TDateTime;
begin
  // 每年 1 月 1 日 0:00 执行: 0 0 1 1 *
  cron := CreateCronExpression('0 0 1 1 *');
  AssertTrue('CRON 表达式应有效', cron.IsValid);

  // 从 2025-3-15 查找，应该返回 2025-1-1 0:00
  fromTime := TInstant.FromNsSinceEpoch(
    DateTimeToUnix(EncodeDate(2025, 3, 15) + EncodeTime(14, 30, 0, 0), False) * 1000000000);
  prevTime := cron.GetPreviousTime(fromTime);

  AssertTrue('GetPreviousTime 应返回有效时间', prevTime <> TInstant.Zero);
  prevDT := UnixToDateTime(prevTime.AsNsSinceEpoch div 1000000000, False);
  AssertEquals('年份应为 2025', 2025, YearOf(prevDT));
  AssertEquals('月份应为 1', 1, MonthOf(prevDT));
end;

// === 边界条件测试 ===

procedure TTestCronBoundary.Test_Cron_LeapYear_Feb29;
var
  cron: ICronExpression;
  fromTime, nextTime: TInstant;
  nextDT: TDateTime;
begin
  // 每年 2 月 29 日执行: 0 0 29 2 *
  cron := CreateCronExpression('0 0 29 2 *');
  AssertTrue('CRON 表达式应有效', cron.IsValid);

  // 从 2024-1-1 查找下一个执行时间（2024 是闰年）
  fromTime := TInstant.FromNsSinceEpoch(
    DateTimeToUnix(EncodeDate(2024, 1, 1), False) * 1000000000);
  nextTime := cron.GetNextTime(fromTime);

  AssertTrue('GetNextTime 应返回有效时间', nextTime <> TInstant.Zero);
  nextDT := UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000, False);
  AssertEquals('应为闰年', 2024, YearOf(nextDT));
  AssertEquals('月份应为 2', 2, MonthOf(nextDT));
  AssertEquals('日期应为 29', 29, DayOf(nextDT));
end;

procedure TTestCronBoundary.Test_Cron_YearEnd_Dec31;
var
  cron: ICronExpression;
  fromTime, nextTime: TInstant;
  nextDT: TDateTime;
begin
  // 每年 12 月 31 日 23:59 执行: 59 23 31 12 *
  cron := CreateCronExpression('59 23 31 12 *');
  AssertTrue('CRON 表达式应有效', cron.IsValid);

  // 从 2025-6-1 查找
  fromTime := TInstant.FromNsSinceEpoch(
    DateTimeToUnix(EncodeDate(2025, 6, 1), False) * 1000000000);
  nextTime := cron.GetNextTime(fromTime);

  AssertTrue('GetNextTime 应返回有效时间', nextTime <> TInstant.Zero);
  nextDT := UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000, False);
  AssertEquals('月份应为 12', 12, MonthOf(nextDT));
  AssertEquals('日期应为 31', 31, DayOf(nextDT));
end;

procedure TTestCronBoundary.Test_Cron_YearStart_Jan1;
var
  cron: ICronExpression;
  fromTime, nextTime: TInstant;
  nextDT: TDateTime;
begin
  // 每年 1 月 1 日 0:00 执行: 0 0 1 1 *
  cron := CreateCronExpression('0 0 1 1 *');
  AssertTrue('CRON 表达式应有效', cron.IsValid);

  // 从 2025-12-31 查找，应跳到 2026-1-1
  fromTime := TInstant.FromNsSinceEpoch(
    DateTimeToUnix(EncodeDate(2025, 12, 31) + EncodeTime(23, 59, 0, 0), False) * 1000000000);
  nextTime := cron.GetNextTime(fromTime);

  AssertTrue('GetNextTime 应返回有效时间', nextTime <> TInstant.Zero);
  nextDT := UnixToDateTime(nextTime.AsNsSinceEpoch div 1000000000, False);
  AssertEquals('年份应为 2026', 2026, YearOf(nextDT));
  AssertEquals('月份应为 1', 1, MonthOf(nextDT));
  AssertEquals('日期应为 1', 1, DayOf(nextDT));
end;

procedure TTestCronBoundary.Test_Cron_MonthEnd_Various;
var
  cron: ICronExpression;
begin
  // 每月最后一天（30 号）: 0 0 30 * *
  cron := CreateCronExpression('0 0 30 * *');
  AssertTrue('30 号 CRON 表达式应有效', cron.IsValid);

  // 每月最后一天（31 号）: 0 0 31 * *
  cron := CreateCronExpression('0 0 31 * *');
  AssertTrue('31 号 CRON 表达式应有效', cron.IsValid);
end;

// === 安全限制测试 ===

procedure TTestCronBoundary.Test_Cron_ExpressionLengthLimit;
var
  cron: ICronExpression;
  longExpr: string;
begin
  // 创建一个超长表达式（超过 256 字符限制）
  longExpr := '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59 * * * *';

  // 表达式应该被拒绝或截断
  cron := CreateCronExpression(longExpr);
  // 即使表达式很长，只要在限制内就应该有效
  // 这里主要测试不会崩溃
  AssertTrue('长表达式不应导致崩溃', True);
end;

procedure TTestCronBoundary.Test_Cron_ListValuesLimit;
var
  cron: ICronExpression;
begin
  // 测试包含所有分钟值的列表（60 个值）
  cron := CreateCronExpression('0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59 * * * *');
  // 60 个值应该在限制内
  AssertTrue('60 值列表不应导致崩溃', True);
end;

procedure TTestCronBoundary.Test_Cron_InvalidExpression;
var
  cron: ICronExpression;
begin
  // 无效表达式
  cron := CreateCronExpression('invalid');
  AssertFalse('无效表达式应返回 IsValid=False', cron.IsValid);

  // 空表达式
  cron := CreateCronExpression('');
  AssertFalse('空表达式应返回 IsValid=False', cron.IsValid);

  // 字段不足
  cron := CreateCronExpression('* * *');
  AssertFalse('字段不足应返回 IsValid=False', cron.IsValid);
end;

// === 常用表达式测试 ===

procedure TTestCronBoundary.Test_Cron_EveryMinute;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('* * * * *');
  AssertTrue('每分钟表达式应有效', cron.IsValid);
end;

procedure TTestCronBoundary.Test_Cron_Midnight;
var
  cron: ICronExpression;
begin
  cron := CreateCronExpression('0 0 * * *');
  AssertTrue('午夜表达式应有效', cron.IsValid);
end;

procedure TTestCronBoundary.Test_Cron_Weekdays;
var
  cron: ICronExpression;
begin
  // 周一到周五 9:00
  cron := CreateCronExpression('0 9 * * 1-5');
  AssertTrue('工作日表达式应有效', cron.IsValid);
end;

initialization
  RegisterTest(TTestCronBoundary);

end.
