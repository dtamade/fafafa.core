{
  Test_Period.pas - TPeriod 单元测试
  
  TDD: 先写测试，后写实现
  
  测试覆盖：
  1. 构造函数 - Create, OfYears, OfMonths, OfDays, OfWeeks
  2. 算术运算 - Plus, Minus, Negated, Multiplied
  3. 属性访问 - Years, Months, Days, TotalMonths
  4. 比较运算 - =, <>
  5. 标准化 - Normalized
  6. 特殊值 - Zero, IsZero, IsNegative
  7. 与 TDate 交互 - AddTo, SubtractFrom
}
program Test_Period;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.date,
  fafafa.core.time.period;

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
  Check(Expected = Actual, TestName + Format(' (expected=%d, actual=%d)', [Expected, Actual]));
end;

// ============================================================
// 测试: 构造函数
// ============================================================
procedure Test_Create_Basic;
var
  P: TPeriod;
begin
  WriteLn('Test_Create_Basic:');
  
  // 基本构造
  P := TPeriod.Create(1, 2, 3);
  CheckEquals(1, P.Years, 'Years should be 1');
  CheckEquals(2, P.Months, 'Months should be 2');
  CheckEquals(3, P.Days, 'Days should be 3');
  
  // 零周期
  P := TPeriod.Create(0, 0, 0);
  Check(P.IsZero, 'Zero period should be zero');
  
  // 负值
  P := TPeriod.Create(-1, -2, -3);
  CheckEquals(-1, P.Years, 'Negative years');
  CheckEquals(-2, P.Months, 'Negative months');
  CheckEquals(-3, P.Days, 'Negative days');
end;

procedure Test_OfYears;
var
  P: TPeriod;
begin
  WriteLn('Test_OfYears:');
  
  P := TPeriod.OfYears(5);
  CheckEquals(5, P.Years, 'OfYears(5).Years = 5');
  CheckEquals(0, P.Months, 'OfYears(5).Months = 0');
  CheckEquals(0, P.Days, 'OfYears(5).Days = 0');
  
  P := TPeriod.OfYears(-3);
  CheckEquals(-3, P.Years, 'OfYears(-3).Years = -3');
end;

procedure Test_OfMonths;
var
  P: TPeriod;
begin
  WriteLn('Test_OfMonths:');
  
  P := TPeriod.OfMonths(14);
  CheckEquals(0, P.Years, 'OfMonths(14).Years = 0 (not normalized)');
  CheckEquals(14, P.Months, 'OfMonths(14).Months = 14');
  CheckEquals(0, P.Days, 'OfMonths(14).Days = 0');
end;

procedure Test_OfDays;
var
  P: TPeriod;
begin
  WriteLn('Test_OfDays:');
  
  P := TPeriod.OfDays(45);
  CheckEquals(0, P.Years, 'OfDays(45).Years = 0');
  CheckEquals(0, P.Months, 'OfDays(45).Months = 0');
  CheckEquals(45, P.Days, 'OfDays(45).Days = 45');
end;

procedure Test_OfWeeks;
var
  P: TPeriod;
begin
  WriteLn('Test_OfWeeks:');
  
  P := TPeriod.OfWeeks(2);
  CheckEquals(0, P.Years, 'OfWeeks(2).Years = 0');
  CheckEquals(0, P.Months, 'OfWeeks(2).Months = 0');
  CheckEquals(14, P.Days, 'OfWeeks(2).Days = 14');
end;

procedure Test_Zero;
var
  P: TPeriod;
begin
  WriteLn('Test_Zero:');
  
  P := TPeriod.Zero;
  Check(P.IsZero, 'Zero.IsZero = True');
  CheckEquals(0, P.Years, 'Zero.Years = 0');
  CheckEquals(0, P.Months, 'Zero.Months = 0');
  CheckEquals(0, P.Days, 'Zero.Days = 0');
end;

// ============================================================
// 测试: 算术运算
// ============================================================
procedure Test_Plus;
var
  P1, P2, R: TPeriod;
begin
  WriteLn('Test_Plus:');
  
  P1 := TPeriod.Create(1, 2, 3);
  P2 := TPeriod.Create(4, 5, 6);
  R := P1.Plus(P2);
  
  CheckEquals(5, R.Years, 'Plus: Years 1+4=5');
  CheckEquals(7, R.Months, 'Plus: Months 2+5=7');
  CheckEquals(9, R.Days, 'Plus: Days 3+6=9');
  
  // 与负值相加
  P2 := TPeriod.Create(-1, -1, -1);
  R := P1.Plus(P2);
  CheckEquals(0, R.Years, 'Plus negative: Years 1-1=0');
  CheckEquals(1, R.Months, 'Plus negative: Months 2-1=1');
  CheckEquals(2, R.Days, 'Plus negative: Days 3-1=2');
end;

procedure Test_Minus;
var
  P1, P2, R: TPeriod;
begin
  WriteLn('Test_Minus:');
  
  P1 := TPeriod.Create(5, 7, 9);
  P2 := TPeriod.Create(1, 2, 3);
  R := P1.Minus(P2);
  
  CheckEquals(4, R.Years, 'Minus: Years 5-1=4');
  CheckEquals(5, R.Months, 'Minus: Months 7-2=5');
  CheckEquals(6, R.Days, 'Minus: Days 9-3=6');
end;

procedure Test_Negated;
var
  P, R: TPeriod;
begin
  WriteLn('Test_Negated:');
  
  P := TPeriod.Create(1, 2, 3);
  R := P.Negated;
  
  CheckEquals(-1, R.Years, 'Negated: Years');
  CheckEquals(-2, R.Months, 'Negated: Months');
  CheckEquals(-3, R.Days, 'Negated: Days');
  
  // 双重否定
  R := P.Negated.Negated;
  CheckEquals(1, R.Years, 'Double negated: Years');
  CheckEquals(2, R.Months, 'Double negated: Months');
  CheckEquals(3, R.Days, 'Double negated: Days');
end;

procedure Test_Multiplied;
var
  P, R: TPeriod;
begin
  WriteLn('Test_Multiplied:');
  
  P := TPeriod.Create(1, 2, 3);
  R := P.Multiplied(3);
  
  CheckEquals(3, R.Years, 'Multiplied(3): Years 1*3=3');
  CheckEquals(6, R.Months, 'Multiplied(3): Months 2*3=6');
  CheckEquals(9, R.Days, 'Multiplied(3): Days 3*3=9');
  
  // 乘以 0
  R := P.Multiplied(0);
  Check(R.IsZero, 'Multiplied(0) is zero');
  
  // 乘以负数
  R := P.Multiplied(-2);
  CheckEquals(-2, R.Years, 'Multiplied(-2): Years');
  CheckEquals(-4, R.Months, 'Multiplied(-2): Months');
  CheckEquals(-6, R.Days, 'Multiplied(-2): Days');
end;

// ============================================================
// 测试: 属性访问
// ============================================================
procedure Test_TotalMonths;
var
  P: TPeriod;
begin
  WriteLn('Test_TotalMonths:');
  
  P := TPeriod.Create(2, 5, 10);
  CheckEquals(29, P.TotalMonths, 'TotalMonths: 2*12+5=29');
  
  P := TPeriod.Create(0, 14, 0);
  CheckEquals(14, P.TotalMonths, 'TotalMonths: 0*12+14=14');
  
  P := TPeriod.Create(-1, 3, 0);
  CheckEquals(-9, P.TotalMonths, 'TotalMonths: -1*12+3=-9');
end;

// ============================================================
// 测试: 标准化
// ============================================================
procedure Test_Normalized;
var
  P, R: TPeriod;
begin
  WriteLn('Test_Normalized:');
  
  // 月份超过 12
  P := TPeriod.Create(1, 14, 0);
  R := P.Normalized;
  CheckEquals(2, R.Years, 'Normalized: 1y 14m -> 2y');
  CheckEquals(2, R.Months, 'Normalized: 1y 14m -> 2m');
  
  // 月份为负
  P := TPeriod.Create(2, -3, 0);
  R := P.Normalized;
  CheckEquals(1, R.Years, 'Normalized: 2y -3m -> 1y');
  CheckEquals(9, R.Months, 'Normalized: 2y -3m -> 9m');
  
  // 已标准化不变
  P := TPeriod.Create(1, 6, 15);
  R := P.Normalized;
  CheckEquals(1, R.Years, 'Already normalized: Years');
  CheckEquals(6, R.Months, 'Already normalized: Months');
  CheckEquals(15, R.Days, 'Already normalized: Days (unchanged)');
end;

// ============================================================
// 测试: 比较运算
// ============================================================
procedure Test_Equals;
var
  P1, P2: TPeriod;
begin
  WriteLn('Test_Equals:');
  
  P1 := TPeriod.Create(1, 2, 3);
  P2 := TPeriod.Create(1, 2, 3);
  Check(P1 = P2, 'Equal periods');
  
  P2 := TPeriod.Create(1, 2, 4);
  Check(P1 <> P2, 'Different days');
  
  P2 := TPeriod.Create(1, 3, 3);
  Check(P1 <> P2, 'Different months');
  
  P2 := TPeriod.Create(2, 2, 3);
  Check(P1 <> P2, 'Different years');
end;

// ============================================================
// 测试: IsZero / IsNegative
// ============================================================
procedure Test_IsZero;
var
  P: TPeriod;
begin
  WriteLn('Test_IsZero:');
  
  P := TPeriod.Zero;
  Check(P.IsZero, 'Zero is zero');
  
  P := TPeriod.Create(0, 0, 1);
  Check(not P.IsZero, '0y 0m 1d is not zero');
  
  P := TPeriod.Create(0, 1, 0);
  Check(not P.IsZero, '0y 1m 0d is not zero');
  
  P := TPeriod.Create(1, 0, 0);
  Check(not P.IsZero, '1y 0m 0d is not zero');
end;

procedure Test_IsNegative;
var
  P: TPeriod;
begin
  WriteLn('Test_IsNegative:');
  
  P := TPeriod.Create(-1, 0, 0);
  Check(P.IsNegative, '-1y is negative');
  
  P := TPeriod.Create(0, -1, 0);
  Check(P.IsNegative, '-1m is negative');
  
  P := TPeriod.Create(0, 0, -1);
  Check(P.IsNegative, '-1d is negative');
  
  P := TPeriod.Create(1, 2, 3);
  Check(not P.IsNegative, 'Positive period is not negative');
  
  P := TPeriod.Zero;
  Check(not P.IsNegative, 'Zero is not negative');
  
  // 混合符号 - 总月数为正
  P := TPeriod.Create(1, -3, 0);  // 9 months > 0
  Check(not P.IsNegative, '1y -3m (=9m) is not negative');
end;

// ============================================================
// 测试: 与 TDate 交互
// ============================================================
procedure Test_AddToDate;
var
  P: TPeriod;
  D, R: TDate;
begin
  WriteLn('Test_AddToDate:');
  
  D := TDate.Create(2024, 1, 15);
  
  // 加 1 个月
  P := TPeriod.OfMonths(1);
  R := P.AddTo(D);
  CheckEquals(2024, R.GetYear, 'Add 1m: Year');
  CheckEquals(2, R.GetMonth, 'Add 1m: Month');
  CheckEquals(15, R.GetDay, 'Add 1m: Day');
  
  // 加 1 年
  P := TPeriod.OfYears(1);
  R := P.AddTo(D);
  CheckEquals(2025, R.GetYear, 'Add 1y: Year');
  CheckEquals(1, R.GetMonth, 'Add 1y: Month');
  CheckEquals(15, R.GetDay, 'Add 1y: Day');
  
  // 月末边界: 1月31日 + 1个月 = 2月28/29日
  D := TDate.Create(2024, 1, 31);  // 2024 是闰年
  P := TPeriod.OfMonths(1);
  R := P.AddTo(D);
  CheckEquals(2024, R.GetYear, 'Jan 31 + 1m: Year');
  CheckEquals(2, R.GetMonth, 'Jan 31 + 1m: Month');
  CheckEquals(29, R.GetDay, 'Jan 31 + 1m: Day (leap year Feb 29)');
  
  // 非闰年
  D := TDate.Create(2023, 1, 31);
  R := P.AddTo(D);
  CheckEquals(2023, R.GetYear, 'Jan 31 + 1m (non-leap): Year');
  CheckEquals(2, R.GetMonth, 'Jan 31 + 1m (non-leap): Month');
  CheckEquals(28, R.GetDay, 'Jan 31 + 1m (non-leap): Day (Feb 28)');
end;

procedure Test_SubtractFromDate;
var
  P: TPeriod;
  D, R: TDate;
begin
  WriteLn('Test_SubtractFromDate:');
  
  D := TDate.Create(2024, 3, 15);
  
  // 减 1 个月
  P := TPeriod.OfMonths(1);
  R := P.SubtractFrom(D);
  CheckEquals(2024, R.GetYear, 'Sub 1m: Year');
  CheckEquals(2, R.GetMonth, 'Sub 1m: Month');
  CheckEquals(15, R.GetDay, 'Sub 1m: Day');
  
  // 减 1 年
  P := TPeriod.OfYears(1);
  R := P.SubtractFrom(D);
  CheckEquals(2023, R.GetYear, 'Sub 1y: Year');
  CheckEquals(3, R.GetMonth, 'Sub 1y: Month');
  CheckEquals(15, R.GetDay, 'Sub 1y: Day');
end;

procedure Test_Between;
var
  D1, D2: TDate;
  P: TPeriod;
begin
  WriteLn('Test_Between:');
  
  D1 := TDate.Create(2020, 1, 15);
  D2 := TDate.Create(2024, 3, 20);
  
  P := TPeriod.Between(D1, D2);
  CheckEquals(4, P.Years, 'Between: Years');
  CheckEquals(2, P.Months, 'Between: Months');
  CheckEquals(5, P.Days, 'Between: Days');
  
  // 反向
  P := TPeriod.Between(D2, D1);
  CheckEquals(-4, P.Years, 'Between reversed: Years');
  CheckEquals(-2, P.Months, 'Between reversed: Months');
  CheckEquals(-5, P.Days, 'Between reversed: Days');
  
  // 相同日期
  P := TPeriod.Between(D1, D1);
  Check(P.IsZero, 'Between same dates is zero');
end;

// ============================================================
// 测试: ToString
// ============================================================
procedure Test_ToString;
var
  P: TPeriod;
  S: string;
begin
  WriteLn('Test_ToString:');
  
  P := TPeriod.Create(1, 2, 3);
  S := P.ToString;
  Check(Pos('1', S) > 0, 'ToString contains years');
  Check(Pos('2', S) > 0, 'ToString contains months');
  Check(Pos('3', S) > 0, 'ToString contains days');
  
  P := TPeriod.Zero;
  S := P.ToString;
  Check(Length(S) > 0, 'Zero period has string representation');
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TPeriod Unit Tests');
  WriteLn('========================================');
  WriteLn('');
  
  // 构造函数测试
  Test_Create_Basic;
  Test_OfYears;
  Test_OfMonths;
  Test_OfDays;
  Test_OfWeeks;
  Test_Zero;
  
  // 算术运算测试
  Test_Plus;
  Test_Minus;
  Test_Negated;
  Test_Multiplied;
  
  // 属性访问测试
  Test_TotalMonths;
  
  // 标准化测试
  Test_Normalized;
  
  // 比较运算测试
  Test_Equals;
  
  // IsZero / IsNegative 测试
  Test_IsZero;
  Test_IsNegative;
  
  // 与 TDate 交互测试
  Test_AddToDate;
  Test_SubtractFromDate;
  Test_Between;
  
  // ToString 测试
  Test_ToString;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
