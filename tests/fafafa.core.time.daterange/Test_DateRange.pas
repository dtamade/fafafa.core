{
  Test_DateRange.pas - TDateRange 迭代器测试
  
  测试覆盖:
  1. TDateRange.Create(Start, End)
  2. TDateRange.CreateDays/Weeks/Months/Years
  3. for-in 迭代
  4. Contains, Overlaps
}
program Test_DateRange;

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

procedure CheckEquals(Expected, Actual: Integer; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected=%d, actual=%d)', [TestName, Expected, Actual]));
end;

procedure CheckDate(ExpY, ExpM, ExpD: Integer; const Actual: TDate; const TestName: string);
begin
  Check((Actual.GetYear = ExpY) and (Actual.GetMonth = ExpM) and (Actual.GetDay = ExpD),
        Format('%s (expected=%d-%d-%d, actual=%d-%d-%d)', 
               [TestName, ExpY, ExpM, ExpD, Actual.GetYear, Actual.GetMonth, Actual.GetDay]));
end;

// ============================================================
// 测试: TDateRange 创建
// ============================================================

procedure Test_DateRange_Create;
var
  R: TDateRange;
begin
  WriteLn('Test_DateRange_Create:');
  
  R := TDateRange.Create(TDate.Create(2024, 6, 1), TDate.Create(2024, 6, 10));
  
  CheckDate(2024, 6, 1, R.GetStartDate, 'Start date');
  CheckDate(2024, 6, 10, R.GetEndDate, 'End date');
  CheckEquals(9, R.GetDuration, 'Duration = 9 days');
end;

procedure Test_DateRange_CreateDays;
var
  R: TDateRange;
begin
  WriteLn('Test_DateRange_CreateDays:');
  
  R := TDateRange.CreateDays(TDate.Create(2024, 6, 1), 7);
  
  CheckDate(2024, 6, 1, R.GetStartDate, 'Start date');
  CheckDate(2024, 6, 8, R.GetEndDate, 'End date = Start + 7 days');
end;

procedure Test_DateRange_CreateWeeks;
var
  R: TDateRange;
begin
  WriteLn('Test_DateRange_CreateWeeks:');
  
  R := TDateRange.CreateWeeks(TDate.Create(2024, 6, 1), 2);
  
  CheckDate(2024, 6, 1, R.GetStartDate, 'Start date');
  CheckDate(2024, 6, 15, R.GetEndDate, 'End date = Start + 2 weeks');
end;

procedure Test_DateRange_CreateMonths;
var
  R: TDateRange;
begin
  WriteLn('Test_DateRange_CreateMonths:');
  
  R := TDateRange.CreateMonths(TDate.Create(2024, 6, 1), 3);
  
  CheckDate(2024, 6, 1, R.GetStartDate, 'Start date');
  CheckDate(2024, 9, 1, R.GetEndDate, 'End date = Start + 3 months');
end;

// ============================================================
// 测试: TDateRange 迭代
// ============================================================

procedure Test_DateRange_ForIn;
var
  R: TDateRange;
  D: TDate;
  Count: Integer;
begin
  WriteLn('Test_DateRange_ForIn:');
  
  R := TDateRange.Create(TDate.Create(2024, 6, 1), TDate.Create(2024, 6, 5));
  
  Count := 0;
  for D in R do
  begin
    Inc(Count);
  end;
  
  // 范围是 6/1 到 6/5，应该包含 5 天
  CheckEquals(5, Count, 'Iteration count = 5 days');
end;

procedure Test_DateRange_ForIn_Verify;
var
  R: TDateRange;
  D: TDate;
  Expected: array[0..2] of Integer = (15, 16, 17);
  I: Integer;
begin
  WriteLn('Test_DateRange_ForIn_Verify:');
  
  R := TDateRange.Create(TDate.Create(2024, 6, 15), TDate.Create(2024, 6, 17));
  
  I := 0;
  for D in R do
  begin
    if I < 3 then
    begin
      Check(D.GetDay = Expected[I], Format('Day %d = %d', [I+1, Expected[I]]));
    end;
    Inc(I);
  end;
  
  CheckEquals(3, I, 'Total iteration count = 3');
end;

// ============================================================
// 测试: TDateRange 查询
// ============================================================

procedure Test_DateRange_Contains;
var
  R: TDateRange;
begin
  WriteLn('Test_DateRange_Contains:');
  
  R := TDateRange.Create(TDate.Create(2024, 6, 10), TDate.Create(2024, 6, 20));
  
  Check(R.Contains(TDate.Create(2024, 6, 10)), 'Contains start date');
  Check(R.Contains(TDate.Create(2024, 6, 15)), 'Contains middle date');
  Check(R.Contains(TDate.Create(2024, 6, 20)), 'Contains end date');
  Check(not R.Contains(TDate.Create(2024, 6, 9)), 'Does not contain before start');
  Check(not R.Contains(TDate.Create(2024, 6, 21)), 'Does not contain after end');
end;

procedure Test_DateRange_Overlaps;
var
  R1, R2: TDateRange;
begin
  WriteLn('Test_DateRange_Overlaps:');
  
  R1 := TDateRange.Create(TDate.Create(2024, 6, 10), TDate.Create(2024, 6, 20));
  
  // 完全重叠
  R2 := TDateRange.Create(TDate.Create(2024, 6, 15), TDate.Create(2024, 6, 17));
  Check(R1.Overlaps(R2), 'Complete overlap');
  
  // 部分重叠（前端）
  R2 := TDateRange.Create(TDate.Create(2024, 6, 5), TDate.Create(2024, 6, 12));
  Check(R1.Overlaps(R2), 'Partial overlap (front)');
  
  // 部分重叠（后端）
  R2 := TDateRange.Create(TDate.Create(2024, 6, 18), TDate.Create(2024, 6, 25));
  Check(R1.Overlaps(R2), 'Partial overlap (back)');
  
  // 不重叠
  R2 := TDateRange.Create(TDate.Create(2024, 6, 1), TDate.Create(2024, 6, 9));
  Check(not R1.Overlaps(R2), 'No overlap (before)');
  
  R2 := TDateRange.Create(TDate.Create(2024, 6, 21), TDate.Create(2024, 6, 30));
  Check(not R1.Overlaps(R2), 'No overlap (after)');
end;

// ============================================================
// 测试: TDateRange 操作
// ============================================================

procedure Test_DateRange_Shift;
var
  R1, R2: TDateRange;
begin
  WriteLn('Test_DateRange_Shift:');
  
  R1 := TDateRange.Create(TDate.Create(2024, 6, 10), TDate.Create(2024, 6, 15));
  R2 := R1.Shift(5);  // 向后移动5天
  
  CheckDate(2024, 6, 15, R2.GetStartDate, 'Shifted start');
  CheckDate(2024, 6, 20, R2.GetEndDate, 'Shifted end');
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TDateRange Tests');
  WriteLn('========================================');
  WriteLn('');
  
  Test_DateRange_Create;
  Test_DateRange_CreateDays;
  Test_DateRange_CreateWeeks;
  Test_DateRange_CreateMonths;
  Test_DateRange_ForIn;
  Test_DateRange_ForIn_Verify;
  Test_DateRange_Contains;
  Test_DateRange_Overlaps;
  Test_DateRange_Shift;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
