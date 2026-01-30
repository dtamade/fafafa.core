{
  Test_TemporalAdjusters.pas - TDate TemporalAdjusters 测试
  
  TDD: 先写测试，后写实现
  
  测试覆盖:
  1. Next(DayOfWeek) - 返回指定星期几的下一个日期
  2. Previous(DayOfWeek) - 返回指定星期几的上一个日期
  3. NextOrSame(DayOfWeek) - 当前是则返回自身，否则返回下一个
  4. PreviousOrSame(DayOfWeek) - 当前是则返回自身，否则返回上一个
  5. DayOfWeekIn(OrdinalWeek, DayOfWeek) - 返回月中第N个星期几
}
program Test_TemporalAdjusters;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.date;

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;
  FailCount: Integer = 0;

procedure Check(Condition: Boolean; const TestName: string);
begin
  Inc(TestCount);
  if Condition then
  begin
    Inc(PassCount);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailCount);
    WriteLn('  ✗ ', TestName, ' [FAILED]');
  end;
end;

procedure CheckDate(ExpectedY, ExpectedM, ExpectedD: Integer; const Actual: TDate; const TestName: string);
begin
  Check((Actual.GetYear = ExpectedY) and (Actual.GetMonth = ExpectedM) and (Actual.GetDay = ExpectedD),
    Format('%s (expected=%d-%d-%d, actual=%d-%d-%d)', 
      [TestName, ExpectedY, ExpectedM, ExpectedD, Actual.GetYear, Actual.GetMonth, Actual.GetDay]));
end;

// ============================================================
// 测试: Next(DayOfWeek)
// ============================================================

procedure Test_Next_Monday;
var
  D, R: TDate;
begin
  WriteLn('Test_Next_Monday:');
  
  // 从周日(2024-01-07)找下一个周一
  D := TDate.Create(2024, 1, 7);  // 周日
  R := D.Next(2);  // 2=Monday (1=Sun, 2=Mon, ..., 7=Sat)
  CheckDate(2024, 1, 8, R, 'Sunday -> next Monday = Jan 8');
  
  // 从周一(2024-01-08)找下一个周一（应该跳到下周）
  D := TDate.Create(2024, 1, 8);  // 周一
  R := D.Next(2);  // Monday
  CheckDate(2024, 1, 15, R, 'Monday -> next Monday = Jan 15 (next week)');
  
  // 从周六(2024-01-06)找下一个周一
  D := TDate.Create(2024, 1, 6);  // 周六
  R := D.Next(2);  // Monday
  CheckDate(2024, 1, 8, R, 'Saturday -> next Monday = Jan 8');
end;

procedure Test_Next_Sunday;
var
  D, R: TDate;
begin
  WriteLn('Test_Next_Sunday:');
  
  // 从周一(2024-01-08)找下一个周日
  D := TDate.Create(2024, 1, 8);  // 周一
  R := D.Next(1);  // 1=Sunday
  CheckDate(2024, 1, 14, R, 'Monday -> next Sunday = Jan 14');
  
  // 从周日(2024-01-07)找下一个周日（跳到下周）
  D := TDate.Create(2024, 1, 7);  // 周日
  R := D.Next(1);  // Sunday
  CheckDate(2024, 1, 14, R, 'Sunday -> next Sunday = Jan 14 (next week)');
end;

procedure Test_Next_Friday;
var
  D, R: TDate;
begin
  WriteLn('Test_Next_Friday:');
  
  // 从周一(2024-01-08)找下一个周五
  D := TDate.Create(2024, 1, 8);  // 周一
  R := D.Next(6);  // 6=Friday
  CheckDate(2024, 1, 12, R, 'Monday -> next Friday = Jan 12');
end;

// ============================================================
// 测试: Previous(DayOfWeek)
// ============================================================

procedure Test_Previous_Monday;
var
  D, R: TDate;
begin
  WriteLn('Test_Previous_Monday:');
  
  // 从周日(2024-01-14)找上一个周一
  D := TDate.Create(2024, 1, 14);  // 周日
  R := D.Previous(2);  // Monday
  CheckDate(2024, 1, 8, R, 'Sunday Jan 14 -> previous Monday = Jan 8');
  
  // 从周一(2024-01-08)找上一个周一（跳到上周）
  D := TDate.Create(2024, 1, 8);  // 周一
  R := D.Previous(2);  // Monday
  CheckDate(2024, 1, 1, R, 'Monday Jan 8 -> previous Monday = Jan 1');
  
  // 从周二(2024-01-09)找上一个周一
  D := TDate.Create(2024, 1, 9);  // 周二
  R := D.Previous(2);  // Monday
  CheckDate(2024, 1, 8, R, 'Tuesday Jan 9 -> previous Monday = Jan 8');
end;

procedure Test_Previous_Sunday;
var
  D, R: TDate;
begin
  WriteLn('Test_Previous_Sunday:');
  
  // 从周六(2024-01-13)找上一个周日
  D := TDate.Create(2024, 1, 13);  // 周六
  R := D.Previous(1);  // Sunday
  CheckDate(2024, 1, 7, R, 'Saturday Jan 13 -> previous Sunday = Jan 7');
  
  // 从周日(2024-01-14)找上一个周日（跳到上周）
  D := TDate.Create(2024, 1, 14);  // 周日
  R := D.Previous(1);  // Sunday
  CheckDate(2024, 1, 7, R, 'Sunday Jan 14 -> previous Sunday = Jan 7');
end;

// ============================================================
// 测试: NextOrSame(DayOfWeek)
// ============================================================

procedure Test_NextOrSame_SameDay;
var
  D, R: TDate;
begin
  WriteLn('Test_NextOrSame_SameDay:');
  
  // 从周一(2024-01-08)找下一个或当前周一 -> 返回自身
  D := TDate.Create(2024, 1, 8);  // 周一
  R := D.NextOrSame(2);  // Monday
  CheckDate(2024, 1, 8, R, 'Monday -> NextOrSame Monday = same day Jan 8');
  
  // 从周日(2024-01-07)找下一个或当前周日 -> 返回自身
  D := TDate.Create(2024, 1, 7);  // 周日
  R := D.NextOrSame(1);  // Sunday
  CheckDate(2024, 1, 7, R, 'Sunday -> NextOrSame Sunday = same day Jan 7');
end;

procedure Test_NextOrSame_DifferentDay;
var
  D, R: TDate;
begin
  WriteLn('Test_NextOrSame_DifferentDay:');
  
  // 从周日(2024-01-07)找下一个或当前周一
  D := TDate.Create(2024, 1, 7);  // 周日
  R := D.NextOrSame(2);  // Monday
  CheckDate(2024, 1, 8, R, 'Sunday -> NextOrSame Monday = Jan 8');
  
  // 从周二(2024-01-09)找下一个或当前周一
  D := TDate.Create(2024, 1, 9);  // 周二
  R := D.NextOrSame(2);  // Monday
  CheckDate(2024, 1, 15, R, 'Tuesday -> NextOrSame Monday = Jan 15');
end;

// ============================================================
// 测试: PreviousOrSame(DayOfWeek)
// ============================================================

procedure Test_PreviousOrSame_SameDay;
var
  D, R: TDate;
begin
  WriteLn('Test_PreviousOrSame_SameDay:');
  
  // 从周一(2024-01-08)找上一个或当前周一 -> 返回自身
  D := TDate.Create(2024, 1, 8);  // 周一
  R := D.PreviousOrSame(2);  // Monday
  CheckDate(2024, 1, 8, R, 'Monday -> PreviousOrSame Monday = same day Jan 8');
end;

procedure Test_PreviousOrSame_DifferentDay;
var
  D, R: TDate;
begin
  WriteLn('Test_PreviousOrSame_DifferentDay:');
  
  // 从周二(2024-01-09)找上一个或当前周一
  D := TDate.Create(2024, 1, 9);  // 周二
  R := D.PreviousOrSame(2);  // Monday
  CheckDate(2024, 1, 8, R, 'Tuesday -> PreviousOrSame Monday = Jan 8');
  
  // 从周日(2024-01-14)找上一个或当前周一
  D := TDate.Create(2024, 1, 14);  // 周日
  R := D.PreviousOrSame(2);  // Monday
  CheckDate(2024, 1, 8, R, 'Sunday Jan 14 -> PreviousOrSame Monday = Jan 8');
end;

// ============================================================
// 测试: DayOfWeekInMonth(Ordinal, DayOfWeek)
// ============================================================

procedure Test_DayOfWeekInMonth_First;
var
  D, R: TDate;
begin
  WriteLn('Test_DayOfWeekInMonth_First:');
  
  // 2024年1月第一个周一
  D := TDate.Create(2024, 1, 15);  // 任意一月的日期
  R := D.DayOfWeekInMonth(1, 2);  // 第1个周一
  CheckDate(2024, 1, 1, R, 'First Monday of January 2024 = Jan 1');
  
  // 2024年1月第一个周日
  R := D.DayOfWeekInMonth(1, 1);  // 第1个周日
  CheckDate(2024, 1, 7, R, 'First Sunday of January 2024 = Jan 7');
end;

procedure Test_DayOfWeekInMonth_Second;
var
  D, R: TDate;
begin
  WriteLn('Test_DayOfWeekInMonth_Second:');
  
  // 2024年1月第二个周一
  D := TDate.Create(2024, 1, 15);
  R := D.DayOfWeekInMonth(2, 2);  // 第2个周一
  CheckDate(2024, 1, 8, R, 'Second Monday of January 2024 = Jan 8');
end;

procedure Test_DayOfWeekInMonth_Third;
var
  D, R: TDate;
begin
  WriteLn('Test_DayOfWeekInMonth_Third:');
  
  // 2024年1月第三个周一
  D := TDate.Create(2024, 1, 1);
  R := D.DayOfWeekInMonth(3, 2);  // 第3个周一
  CheckDate(2024, 1, 15, R, 'Third Monday of January 2024 = Jan 15');
end;

procedure Test_DayOfWeekInMonth_Last;
var
  D, R: TDate;
begin
  WriteLn('Test_DayOfWeekInMonth_Last:');
  
  // 2024年1月最后一个周一 (-1 表示最后)
  D := TDate.Create(2024, 1, 1);
  R := D.DayOfWeekInMonth(-1, 2);  // 最后一个周一
  CheckDate(2024, 1, 29, R, 'Last Monday of January 2024 = Jan 29');
  
  // 2024年2月最后一个周五
  D := TDate.Create(2024, 2, 1);
  R := D.DayOfWeekInMonth(-1, 6);  // 最后一个周五
  CheckDate(2024, 2, 23, R, 'Last Friday of February 2024 = Feb 23');
end;

// ============================================================
// 边界测试
// ============================================================

procedure Test_CrossMonth;
var
  D, R: TDate;
begin
  WriteLn('Test_CrossMonth:');
  
  // 从1月31日找下一个周一（跨月）
  D := TDate.Create(2024, 1, 31);  // 周三
  R := D.Next(2);  // Monday
  CheckDate(2024, 2, 5, R, 'Jan 31 -> next Monday = Feb 5');
end;

procedure Test_CrossYear;
var
  D, R: TDate;
begin
  WriteLn('Test_CrossYear:');
  
  // 从12月31日找下一个周一（跨年）
  D := TDate.Create(2023, 12, 31);  // 周日
  R := D.Next(2);  // Monday
  CheckDate(2024, 1, 1, R, 'Dec 31 2023 -> next Monday = Jan 1 2024');
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TemporalAdjusters Unit Tests');
  WriteLn('========================================');
  WriteLn('');
  
  // Next 测试
  Test_Next_Monday;
  Test_Next_Sunday;
  Test_Next_Friday;
  
  // Previous 测试
  Test_Previous_Monday;
  Test_Previous_Sunday;
  
  // NextOrSame 测试
  Test_NextOrSame_SameDay;
  Test_NextOrSame_DifferentDay;
  
  // PreviousOrSame 测试
  Test_PreviousOrSame_SameDay;
  Test_PreviousOrSame_DifferentDay;
  
  // DayOfWeekInMonth 测试
  Test_DayOfWeekInMonth_First;
  Test_DayOfWeekInMonth_Second;
  Test_DayOfWeekInMonth_Third;
  Test_DayOfWeekInMonth_Last;
  
  // 边界测试
  Test_CrossMonth;
  Test_CrossYear;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
