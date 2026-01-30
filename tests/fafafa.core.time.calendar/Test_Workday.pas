{
  Test_Workday.pas - 工作日计算测试
  
  TDD: 先写测试，后写实现
  
  测试覆盖:
  1. IsWorkday - 判断是否工作日
  2. IsWeekend - 判断是否周末
  3. GetNextWorkday - 获取下一个工作日
  4. GetPreviousWorkday - 获取上一个工作日
  5. GetWorkdaysBetween - 计算工作日数量
  6. AddWorkdays - 添加工作日
  7. 节假日处理
}
program Test_Workday;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.date,
  fafafa.core.time.workday;

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

procedure CheckEquals(Expected, Actual: Integer; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected=%d, actual=%d)', [TestName, Expected, Actual]));
end;

// ============================================================
// 测试: IsWorkday / IsWeekend
// ============================================================

procedure Test_IsWorkday_Weekday;
var
  Monday, Tuesday, Wednesday, Thursday, Friday: TDate;
begin
  WriteLn('Test_IsWorkday_Weekday:');
  
  // 2024年12月2日是周一
  Monday := TDate.Create(2024, 12, 2);
  Tuesday := TDate.Create(2024, 12, 3);
  Wednesday := TDate.Create(2024, 12, 4);
  Thursday := TDate.Create(2024, 12, 5);
  Friday := TDate.Create(2024, 12, 6);
  
  Check(IsWorkday(Monday), 'Monday is workday');
  Check(IsWorkday(Tuesday), 'Tuesday is workday');
  Check(IsWorkday(Wednesday), 'Wednesday is workday');
  Check(IsWorkday(Thursday), 'Thursday is workday');
  Check(IsWorkday(Friday), 'Friday is workday');
  
  Check(not IsWeekend(Monday), 'Monday is not weekend');
  Check(not IsWeekend(Friday), 'Friday is not weekend');
end;

procedure Test_IsWorkday_Weekend;
var
  Saturday, Sunday: TDate;
begin
  WriteLn('Test_IsWorkday_Weekend:');
  
  // 2024年12月7日是周六
  Saturday := TDate.Create(2024, 12, 7);
  Sunday := TDate.Create(2024, 12, 8);
  
  Check(not IsWorkday(Saturday), 'Saturday is not workday');
  Check(not IsWorkday(Sunday), 'Sunday is not workday');
  
  Check(IsWeekend(Saturday), 'Saturday is weekend');
  Check(IsWeekend(Sunday), 'Sunday is weekend');
end;

// ============================================================
// 测试: GetNextWorkday / GetPreviousWorkday
// ============================================================

procedure Test_GetNextWorkday;
var
  Friday, NextWorkday: TDate;
begin
  WriteLn('Test_GetNextWorkday:');
  
  // 从周五开始
  Friday := TDate.Create(2024, 12, 6);
  NextWorkday := GetNextWorkday(Friday);
  
  // 下一个工作日应该是下周一
  CheckEquals(2024, NextWorkday.GetYear, 'Next workday year');
  CheckEquals(12, NextWorkday.GetMonth, 'Next workday month');
  CheckEquals(9, NextWorkday.GetDay, 'Next workday day (Monday)');
end;

procedure Test_GetNextWorkday_FromWeekend;
var
  Saturday, Sunday, NextWorkday: TDate;
begin
  WriteLn('Test_GetNextWorkday_FromWeekend:');
  
  Saturday := TDate.Create(2024, 12, 7);
  NextWorkday := GetNextWorkday(Saturday);
  CheckEquals(9, NextWorkday.GetDay, 'From Saturday -> Monday');
  
  Sunday := TDate.Create(2024, 12, 8);
  NextWorkday := GetNextWorkday(Sunday);
  CheckEquals(9, NextWorkday.GetDay, 'From Sunday -> Monday');
end;

// ============================================================
// 测试: GetWorkdaysBetween
// ============================================================

procedure Test_GetWorkdaysBetween_SameWeek;
var
  Monday, Friday: TDate;
  Workdays: Integer;
begin
  WriteLn('Test_GetWorkdaysBetween_SameWeek:');
  
  Monday := TDate.Create(2024, 12, 2);
  Friday := TDate.Create(2024, 12, 6);
  
  Workdays := GetWorkdaysBetween(Monday, Friday);
  CheckEquals(5, Workdays, 'Monday to Friday = 5 workdays');
end;

procedure Test_GetWorkdaysBetween_AcrossWeekend;
var
  Friday, NextMonday: TDate;
  Workdays: Integer;
begin
  WriteLn('Test_GetWorkdaysBetween_AcrossWeekend:');
  
  Friday := TDate.Create(2024, 12, 6);
  NextMonday := TDate.Create(2024, 12, 9);
  
  Workdays := GetWorkdaysBetween(Friday, NextMonday);
  CheckEquals(2, Workdays, 'Friday to Monday = 2 workdays (Fri + Mon)');
end;

procedure Test_GetWorkdaysBetween_TwoWeeks;
var
  Monday1, Friday2: TDate;
  Workdays: Integer;
begin
  WriteLn('Test_GetWorkdaysBetween_TwoWeeks:');
  
  Monday1 := TDate.Create(2024, 12, 2);
  Friday2 := TDate.Create(2024, 12, 13);
  
  Workdays := GetWorkdaysBetween(Monday1, Friday2);
  CheckEquals(10, Workdays, 'Two weeks = 10 workdays');
end;

// ============================================================
// 测试: AddWorkdays
// ============================================================

procedure Test_AddWorkdays_Positive;
var
  Monday, Result: TDate;
begin
  WriteLn('Test_AddWorkdays_Positive:');
  
  Monday := TDate.Create(2024, 12, 2);
  
  // 加1个工作日 -> 周二
  Result := AddWorkdays(Monday, 1);
  CheckEquals(3, Result.GetDay, 'Monday + 1 workday = Tuesday');
  
  // 加5个工作日 -> 下周一
  Result := AddWorkdays(Monday, 5);
  CheckEquals(9, Result.GetDay, 'Monday + 5 workdays = next Monday');
end;

procedure Test_AddWorkdays_Negative;
var
  Friday, Result: TDate;
begin
  WriteLn('Test_AddWorkdays_Negative:');
  
  Friday := TDate.Create(2024, 12, 6);
  
  // 减1个工作日 -> 周四
  Result := AddWorkdays(Friday, -1);
  CheckEquals(5, Result.GetDay, 'Friday - 1 workday = Thursday');
  
  // 减5个工作日 -> 上周五（周一）
  Result := AddWorkdays(Friday, -5);
  CheckEquals(29, Result.GetDay, 'Friday - 5 workdays = previous Friday (Nov 29)');
  CheckEquals(11, Result.GetMonth, 'Month should be November');
end;

procedure Test_AddWorkdays_FromWeekend;
var
  Saturday, Result: TDate;
begin
  WriteLn('Test_AddWorkdays_FromWeekend:');
  
  Saturday := TDate.Create(2024, 12, 7);
  
  // 从周六加1个工作日 -> 下周一
  Result := AddWorkdays(Saturday, 1);
  CheckEquals(9, Result.GetDay, 'Saturday + 1 workday = Monday');
end;

// ============================================================
// 主程序
// ============================================================

begin
  WriteLn;
  WriteLn('========================================');
  WriteLn('  Workday Calculation Tests');
  WriteLn('========================================');
  WriteLn;
  
  // IsWorkday / IsWeekend
  Test_IsWorkday_Weekday;
  Test_IsWorkday_Weekend;
  
  // GetNextWorkday
  Test_GetNextWorkday;
  Test_GetNextWorkday_FromWeekend;
  
  // GetWorkdaysBetween
  Test_GetWorkdaysBetween_SameWeek;
  Test_GetWorkdaysBetween_AcrossWeekend;
  Test_GetWorkdaysBetween_TwoWeeks;
  
  // AddWorkdays
  Test_AddWorkdays_Positive;
  Test_AddWorkdays_Negative;
  Test_AddWorkdays_FromWeekend;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
