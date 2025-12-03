{
  Test_Adjusters.pas - TDate TemporalAdjusters 测试
  
  测试覆盖:
  1. StartOfMonth / EndOfMonth
  2. StartOfYear / EndOfYear  
  3. NextOrSame / PreviousOrSame
  4. DayOfWeekInMonth (第N个星期几)
}
program Test_Adjusters;

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

procedure CheckDate(ExpY, ExpM, ExpD: Integer; const Actual: TDate; const TestName: string);
begin
  Check((Actual.GetYear = ExpY) and (Actual.GetMonth = ExpM) and (Actual.GetDay = ExpD),
        Format('%s (expected=%d-%d-%d, actual=%d-%d-%d)', 
               [TestName, ExpY, ExpM, ExpD, Actual.GetYear, Actual.GetMonth, Actual.GetDay]));
end;

// ============================================================
// 测试: StartOfMonth / EndOfMonth
// ============================================================

procedure Test_StartOfMonth;
var
  D, R: TDate;
begin
  WriteLn('Test_StartOfMonth:');
  
  // 月中
  D := TDate.Create(2024, 6, 15);
  R := D.StartOfMonth;
  CheckDate(2024, 6, 1, R, '2024-06-15 -> 2024-06-01');
  
  // 月初
  D := TDate.Create(2024, 6, 1);
  R := D.StartOfMonth;
  CheckDate(2024, 6, 1, R, '2024-06-01 -> 2024-06-01');
  
  // 月末
  D := TDate.Create(2024, 6, 30);
  R := D.StartOfMonth;
  CheckDate(2024, 6, 1, R, '2024-06-30 -> 2024-06-01');
end;

procedure Test_EndOfMonth;
var
  D, R: TDate;
begin
  WriteLn('Test_EndOfMonth:');
  
  // 普通月
  D := TDate.Create(2024, 6, 15);
  R := D.EndOfMonth;
  CheckDate(2024, 6, 30, R, '2024-06-15 -> 2024-06-30');
  
  // 31天月
  D := TDate.Create(2024, 7, 1);
  R := D.EndOfMonth;
  CheckDate(2024, 7, 31, R, '2024-07-01 -> 2024-07-31');
  
  // 闰年二月
  D := TDate.Create(2024, 2, 10);
  R := D.EndOfMonth;
  CheckDate(2024, 2, 29, R, '2024-02-10 -> 2024-02-29 (leap year)');
  
  // 非闰年二月
  D := TDate.Create(2023, 2, 10);
  R := D.EndOfMonth;
  CheckDate(2023, 2, 28, R, '2023-02-10 -> 2023-02-28 (non-leap year)');
end;

// ============================================================
// 测试: StartOfYear / EndOfYear
// ============================================================

procedure Test_StartOfYear;
var
  D, R: TDate;
begin
  WriteLn('Test_StartOfYear:');
  
  D := TDate.Create(2024, 6, 15);
  R := D.StartOfYear;
  CheckDate(2024, 1, 1, R, '2024-06-15 -> 2024-01-01');
  
  D := TDate.Create(2024, 1, 1);
  R := D.StartOfYear;
  CheckDate(2024, 1, 1, R, '2024-01-01 -> 2024-01-01');
end;

procedure Test_EndOfYear;
var
  D, R: TDate;
begin
  WriteLn('Test_EndOfYear:');
  
  D := TDate.Create(2024, 6, 15);
  R := D.EndOfYear;
  CheckDate(2024, 12, 31, R, '2024-06-15 -> 2024-12-31');
  
  D := TDate.Create(2024, 12, 31);
  R := D.EndOfYear;
  CheckDate(2024, 12, 31, R, '2024-12-31 -> 2024-12-31');
end;

// ============================================================
// 测试: NextOrSame / PreviousOrSame
// ============================================================

procedure Test_NextOrSame;
var
  D, R: TDate;
begin
  WriteLn('Test_NextOrSame:');
  
  // 2024-06-15 是周六 (DayOfWeek=7)
  D := TDate.Create(2024, 6, 15);
  
  // 当天是周六，NextOrSame(周六) 应返回当天
  R := D.NextOrSame(7);  // 7 = Saturday
  CheckDate(2024, 6, 15, R, 'Saturday NextOrSame(Sat) -> same day');
  
  // NextOrSame(周日) 应返回下一个周日 (6/16)
  R := D.NextOrSame(1);  // 1 = Sunday
  CheckDate(2024, 6, 16, R, 'Saturday NextOrSame(Sun) -> 2024-06-16');
  
  // NextOrSame(周一) 应返回下一个周一 (6/17)
  R := D.NextOrSame(2);  // 2 = Monday
  CheckDate(2024, 6, 17, R, 'Saturday NextOrSame(Mon) -> 2024-06-17');
end;

procedure Test_PreviousOrSame;
var
  D, R: TDate;
begin
  WriteLn('Test_PreviousOrSame:');
  
  // 2024-06-15 是周六 (DayOfWeek=7)
  D := TDate.Create(2024, 6, 15);
  
  // 当天是周六，PreviousOrSame(周六) 应返回当天
  R := D.PreviousOrSame(7);  // 7 = Saturday
  CheckDate(2024, 6, 15, R, 'Saturday PreviousOrSame(Sat) -> same day');
  
  // PreviousOrSame(周五) 应返回上一个周五 (6/14)
  R := D.PreviousOrSame(6);  // 6 = Friday
  CheckDate(2024, 6, 14, R, 'Saturday PreviousOrSame(Fri) -> 2024-06-14');
  
  // PreviousOrSame(周日) 应返回上一个周日 (6/9)
  R := D.PreviousOrSame(1);  // 1 = Sunday
  CheckDate(2024, 6, 9, R, 'Saturday PreviousOrSame(Sun) -> 2024-06-09');
end;

// ============================================================
// 测试: DayOfWeekInMonth (第N个星期几)
// ============================================================

procedure Test_DayOfWeekInMonth;
var
  D, R: TDate;
begin
  WriteLn('Test_DayOfWeekInMonth:');
  
  D := TDate.Create(2024, 6, 15);  // 2024年6月
  
  // 第1个周一 (6/3)
  R := D.DayOfWeekInMonth(1, 2);  // 2 = Monday
  CheckDate(2024, 6, 3, R, 'June 2024 1st Monday -> 2024-06-03');
  
  // 第2个周一 (6/10)
  R := D.DayOfWeekInMonth(2, 2);
  CheckDate(2024, 6, 10, R, 'June 2024 2nd Monday -> 2024-06-10');
  
  // 第3个周一 (6/17)
  R := D.DayOfWeekInMonth(3, 2);
  CheckDate(2024, 6, 17, R, 'June 2024 3rd Monday -> 2024-06-17');
  
  // 第4个周一 (6/24)
  R := D.DayOfWeekInMonth(4, 2);
  CheckDate(2024, 6, 24, R, 'June 2024 4th Monday -> 2024-06-24');
  
  // 最后一个周一 (-1) (6/24)
  R := D.DayOfWeekInMonth(-1, 2);
  CheckDate(2024, 6, 24, R, 'June 2024 last Monday -> 2024-06-24');
  
  // 第1个周日 (6/2)
  R := D.DayOfWeekInMonth(1, 1);  // 1 = Sunday
  CheckDate(2024, 6, 2, R, 'June 2024 1st Sunday -> 2024-06-02');
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TDate TemporalAdjusters Tests');
  WriteLn('========================================');
  WriteLn('');
  
  Test_StartOfMonth;
  Test_EndOfMonth;
  Test_StartOfYear;
  Test_EndOfYear;
  Test_NextOrSame;
  Test_PreviousOrSame;
  Test_DayOfWeekInMonth;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
