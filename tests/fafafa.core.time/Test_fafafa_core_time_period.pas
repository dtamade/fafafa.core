unit Test_fafafa_core_time_period;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.date,
  fafafa.core.time.period;

type
  TTestCase_Period = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // 构造函数测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Create_AllComponents_Success;
    procedure Test_OfYears_CreatesYearsOnly;
    procedure Test_OfMonths_CreatesMonthsOnly;
    procedure Test_OfDays_CreatesDaysOnly;
    procedure Test_OfWeeks_ConvertsToDays;
    procedure Test_Zero_CreatesZeroPeriod;
    procedure Test_Between_SameDate_ReturnsZero;
    procedure Test_Between_PositivePeriod_ReturnsCorrect;
    procedure Test_Between_NegativePeriod_ReturnsCorrect;
    
    // ═══════════════════════════════════════════════════════════════
    // 属性访问测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_GetYears_ReturnsCorrectValue;
    procedure Test_GetMonths_ReturnsCorrectValue;
    procedure Test_GetDays_ReturnsCorrectValue;
    procedure Test_TotalMonths_CalculatesCorrectly;
    
    // ═══════════════════════════════════════════════════════════════
    // 算术运算测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Plus_AddsPeriods;
    procedure Test_Minus_SubtractsPeriods;
    procedure Test_Negated_NegatesAllComponents;
    procedure Test_Multiplied_MultipliesAllComponents;
    
    // ═══════════════════════════════════════════════════════════════
    // 标准化测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Normalized_MonthsOver12_ConvertsToYears;
    procedure Test_Normalized_NegativeMonths_Adjusts;
    procedure Test_Normalized_DaysUnchanged;
    
    // ═══════════════════════════════════════════════════════════════
    // 查询方法测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_IsZero_ZeroPeriod_ReturnsTrue;
    procedure Test_IsZero_NonZeroPeriod_ReturnsFalse;
    procedure Test_IsNegative_PositivePeriod_ReturnsFalse;
    procedure Test_IsNegative_NegativePeriod_ReturnsTrue;
    
    // ═══════════════════════════════════════════════════════════════
    // 日期交互测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_AddTo_AddsToDate;
    procedure Test_AddTo_MonthEndHandling;
    procedure Test_SubtractFrom_SubtractsFromDate;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Equal_SamePeriod_ReturnsTrue;
    procedure Test_Equal_DifferentPeriod_ReturnsFalse;
    procedure Test_NotEqual_DifferentPeriod_ReturnsTrue;
    
    // ═══════════════════════════════════════════════════════════════
    // 字符串转换测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ToString_AllComponents_ReturnsISO;
    procedure Test_ToString_YearsOnly_ReturnsISO;
    procedure Test_ToString_Zero_ReturnsP0D;
    procedure Test_TryParse_ValidFormat_Success;
    procedure Test_TryParse_InvalidFormat_ReturnsFalse;
  end;

implementation

{ TTestCase_Period }

// ═══════════════════════════════════════════════════════════════
// 构造函数测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Period.Test_Create_AllComponents_Success;
var
  P: TPeriod;
begin
  P := TPeriod.Create(1, 2, 3);
  AssertEquals('Years', 1, P.Years);
  AssertEquals('Months', 2, P.Months);
  AssertEquals('Days', 3, P.Days);
end;

procedure TTestCase_Period.Test_OfYears_CreatesYearsOnly;
var
  P: TPeriod;
begin
  P := TPeriod.OfYears(5);
  AssertEquals('Years', 5, P.Years);
  AssertEquals('Months', 0, P.Months);
  AssertEquals('Days', 0, P.Days);
end;

procedure TTestCase_Period.Test_OfMonths_CreatesMonthsOnly;
var
  P: TPeriod;
begin
  P := TPeriod.OfMonths(14);
  AssertEquals('Years', 0, P.Years);
  AssertEquals('Months', 14, P.Months);  // 不自动规范化
  AssertEquals('Days', 0, P.Days);
end;

procedure TTestCase_Period.Test_OfDays_CreatesDaysOnly;
var
  P: TPeriod;
begin
  P := TPeriod.OfDays(45);
  AssertEquals('Years', 0, P.Years);
  AssertEquals('Months', 0, P.Months);
  AssertEquals('Days', 45, P.Days);
end;

procedure TTestCase_Period.Test_OfWeeks_ConvertsToDays;
var
  P: TPeriod;
begin
  P := TPeriod.OfWeeks(3);
  AssertEquals('Years', 0, P.Years);
  AssertEquals('Months', 0, P.Months);
  AssertEquals('Days', 21, P.Days);
end;

procedure TTestCase_Period.Test_Zero_CreatesZeroPeriod;
var
  P: TPeriod;
begin
  P := TPeriod.Zero;
  AssertTrue('IsZero', P.IsZero);
end;

procedure TTestCase_Period.Test_Between_SameDate_ReturnsZero;
var
  D: TDate;
  P: TPeriod;
begin
  D := TDate.Create(2024, 6, 15);
  P := TPeriod.Between(D, D);
  AssertTrue('Same date should return zero period', P.IsZero);
end;

procedure TTestCase_Period.Test_Between_PositivePeriod_ReturnsCorrect;
var
  D1, D2: TDate;
  P: TPeriod;
begin
  D1 := TDate.Create(2024, 1, 15);
  D2 := TDate.Create(2025, 3, 20);
  P := TPeriod.Between(D1, D2);
  AssertEquals('Years', 1, P.Years);
  AssertEquals('Months', 2, P.Months);
  AssertEquals('Days', 5, P.Days);
end;

procedure TTestCase_Period.Test_Between_NegativePeriod_ReturnsCorrect;
var
  D1, D2: TDate;
  P: TPeriod;
begin
  D1 := TDate.Create(2025, 3, 20);
  D2 := TDate.Create(2024, 1, 15);
  P := TPeriod.Between(D1, D2);
  AssertTrue('Should be negative', P.IsNegative);
end;

// ═══════════════════════════════════════════════════════════════
// 属性访问测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Period.Test_GetYears_ReturnsCorrectValue;
var
  P: TPeriod;
begin
  P := TPeriod.Create(3, 0, 0);
  AssertEquals('Years', 3, P.GetYears);
end;

procedure TTestCase_Period.Test_GetMonths_ReturnsCorrectValue;
var
  P: TPeriod;
begin
  P := TPeriod.Create(0, 7, 0);
  AssertEquals('Months', 7, P.GetMonths);
end;

procedure TTestCase_Period.Test_GetDays_ReturnsCorrectValue;
var
  P: TPeriod;
begin
  P := TPeriod.Create(0, 0, 15);
  AssertEquals('Days', 15, P.GetDays);
end;

procedure TTestCase_Period.Test_TotalMonths_CalculatesCorrectly;
var
  P: TPeriod;
begin
  P := TPeriod.Create(2, 5, 10);
  AssertEquals('TotalMonths', 29, P.TotalMonths);  // 2*12 + 5
end;

// ═══════════════════════════════════════════════════════════════
// 算术运算测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Period.Test_Plus_AddsPeriods;
var
  P1, P2, R: TPeriod;
begin
  P1 := TPeriod.Create(1, 2, 3);
  P2 := TPeriod.Create(2, 3, 4);
  R := P1.Plus(P2);
  AssertEquals('Years', 3, R.Years);
  AssertEquals('Months', 5, R.Months);
  AssertEquals('Days', 7, R.Days);
end;

procedure TTestCase_Period.Test_Minus_SubtractsPeriods;
var
  P1, P2, R: TPeriod;
begin
  P1 := TPeriod.Create(3, 5, 10);
  P2 := TPeriod.Create(1, 2, 3);
  R := P1.Minus(P2);
  AssertEquals('Years', 2, R.Years);
  AssertEquals('Months', 3, R.Months);
  AssertEquals('Days', 7, R.Days);
end;

procedure TTestCase_Period.Test_Negated_NegatesAllComponents;
var
  P, R: TPeriod;
begin
  P := TPeriod.Create(1, 2, 3);
  R := P.Negated;
  AssertEquals('Years', -1, R.Years);
  AssertEquals('Months', -2, R.Months);
  AssertEquals('Days', -3, R.Days);
end;

procedure TTestCase_Period.Test_Multiplied_MultipliesAllComponents;
var
  P, R: TPeriod;
begin
  P := TPeriod.Create(1, 2, 3);
  R := P.Multiplied(3);
  AssertEquals('Years', 3, R.Years);
  AssertEquals('Months', 6, R.Months);
  AssertEquals('Days', 9, R.Days);
end;

// ═══════════════════════════════════════════════════════════════
// 标准化测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Period.Test_Normalized_MonthsOver12_ConvertsToYears;
var
  P, R: TPeriod;
begin
  P := TPeriod.Create(1, 14, 5);  // 1年14月5天
  R := P.Normalized;
  AssertEquals('Years', 2, R.Years);
  AssertEquals('Months', 2, R.Months);
  AssertEquals('Days', 5, R.Days);
end;

procedure TTestCase_Period.Test_Normalized_NegativeMonths_Adjusts;
var
  P, R: TPeriod;
begin
  P := TPeriod.Create(2, -3, 0);  // 2年-3月
  R := P.Normalized;
  AssertEquals('Years', 1, R.Years);
  AssertEquals('Months', 9, R.Months);
end;

procedure TTestCase_Period.Test_Normalized_DaysUnchanged;
var
  P, R: TPeriod;
begin
  P := TPeriod.Create(0, 0, 45);
  R := P.Normalized;
  AssertEquals('Days should not be normalized', 45, R.Days);
end;

// ═══════════════════════════════════════════════════════════════
// 查询方法测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Period.Test_IsZero_ZeroPeriod_ReturnsTrue;
var
  P: TPeriod;
begin
  P := TPeriod.Zero;
  AssertTrue('Zero period', P.IsZero);
end;

procedure TTestCase_Period.Test_IsZero_NonZeroPeriod_ReturnsFalse;
var
  P: TPeriod;
begin
  P := TPeriod.OfDays(1);
  AssertFalse('Non-zero period', P.IsZero);
end;

procedure TTestCase_Period.Test_IsNegative_PositivePeriod_ReturnsFalse;
var
  P: TPeriod;
begin
  P := TPeriod.Create(1, 2, 3);
  AssertFalse('Positive period', P.IsNegative);
end;

procedure TTestCase_Period.Test_IsNegative_NegativePeriod_ReturnsTrue;
var
  P: TPeriod;
begin
  P := TPeriod.Create(-1, 0, 0);
  AssertTrue('Negative period', P.IsNegative);
end;

// ═══════════════════════════════════════════════════════════════
// 日期交互测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Period.Test_AddTo_AddsToDate;
var
  D, R: TDate;
  P: TPeriod;
begin
  D := TDate.Create(2024, 1, 15);
  P := TPeriod.Create(1, 2, 5);  // 1年2月5天
  R := P.AddTo(D);
  AssertEquals('Year', 2025, R.GetYear);
  AssertEquals('Month', 3, R.GetMonth);
  AssertEquals('Day', 20, R.GetDay);
end;

procedure TTestCase_Period.Test_AddTo_MonthEndHandling;
var
  D, R: TDate;
  P: TPeriod;
begin
  // 1月31日 + 1个月 应该是 2月最后一天
  D := TDate.Create(2024, 1, 31);
  P := TPeriod.OfMonths(1);
  R := P.AddTo(D);
  AssertEquals('Year', 2024, R.GetYear);
  AssertEquals('Month', 2, R.GetMonth);
  AssertEquals('Day', 29, R.GetDay);  // 2024 是闰年
end;

procedure TTestCase_Period.Test_SubtractFrom_SubtractsFromDate;
var
  D, R: TDate;
  P: TPeriod;
begin
  D := TDate.Create(2025, 3, 20);
  P := TPeriod.Create(1, 2, 5);
  R := P.SubtractFrom(D);
  AssertEquals('Year', 2024, R.GetYear);
  AssertEquals('Month', 1, R.GetMonth);
  AssertEquals('Day', 15, R.GetDay);
end;

// ═══════════════════════════════════════════════════════════════
// 比较运算符测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Period.Test_Equal_SamePeriod_ReturnsTrue;
var
  P1, P2: TPeriod;
begin
  P1 := TPeriod.Create(1, 2, 3);
  P2 := TPeriod.Create(1, 2, 3);
  AssertTrue('Same period', P1 = P2);
end;

procedure TTestCase_Period.Test_Equal_DifferentPeriod_ReturnsFalse;
var
  P1, P2: TPeriod;
begin
  P1 := TPeriod.Create(1, 2, 3);
  P2 := TPeriod.Create(1, 2, 4);
  AssertFalse('Different period', P1 = P2);
end;

procedure TTestCase_Period.Test_NotEqual_DifferentPeriod_ReturnsTrue;
var
  P1, P2: TPeriod;
begin
  P1 := TPeriod.Create(1, 2, 3);
  P2 := TPeriod.Create(2, 2, 3);
  AssertTrue('Not equal', P1 <> P2);
end;

// ═══════════════════════════════════════════════════════════════
// 字符串转换测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Period.Test_ToString_AllComponents_ReturnsISO;
var
  P: TPeriod;
begin
  P := TPeriod.Create(1, 2, 3);
  AssertEquals('ISO format', 'P1Y2M3D', P.ToString);
end;

procedure TTestCase_Period.Test_ToString_YearsOnly_ReturnsISO;
var
  P: TPeriod;
begin
  P := TPeriod.OfYears(5);
  AssertEquals('ISO format', 'P5Y', P.ToString);
end;

procedure TTestCase_Period.Test_ToString_Zero_ReturnsP0D;
var
  P: TPeriod;
begin
  P := TPeriod.Zero;
  AssertEquals('Zero period', 'P0D', P.ToString);
end;

procedure TTestCase_Period.Test_TryParse_ValidFormat_Success;
var
  P: TPeriod;
  Ok: Boolean;
begin
  Ok := TPeriod.TryParse('P1Y2M3D', P);
  AssertTrue('TryParse should succeed', Ok);
  AssertEquals('Years', 1, P.Years);
  AssertEquals('Months', 2, P.Months);
  AssertEquals('Days', 3, P.Days);
end;

procedure TTestCase_Period.Test_TryParse_InvalidFormat_ReturnsFalse;
var
  P: TPeriod;
begin
  AssertFalse('Missing P prefix', TPeriod.TryParse('1Y2M3D', P));
  AssertFalse('Empty string', TPeriod.TryParse('', P));
end;

initialization
  RegisterTest(TTestCase_Period);

end.
