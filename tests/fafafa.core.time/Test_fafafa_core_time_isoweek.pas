unit Test_fafafa_core_time_isoweek;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.date,
  fafafa.core.time.isoweek;

type
  TTestCase_IsoWeek = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // 构造函数测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Create_ValidWeek_Success;
    procedure Test_FromDate_MondayOfWeek1_ReturnsWeek1;
    procedure Test_FromDate_SundayOfWeek1_ReturnsWeek1;
    procedure Test_FromDate_Jan1BelongsToPreviousYear_ReturnsWeek53;
    procedure Test_FromDate_Dec31BelongsToNextYear_ReturnsWeek1;
    
    // ═══════════════════════════════════════════════════════════════
    // 日期计算测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Monday_Week1Of2024_ReturnsJan1;
    procedure Test_Sunday_Week1Of2024_ReturnsJan7;
    procedure Test_DayOfWeek_Wednesday_ReturnsCorrectDate;
    
    // ═══════════════════════════════════════════════════════════════
    // 周算术测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_AddWeeks_Positive_ReturnsCorrectWeek;
    procedure Test_AddWeeks_Negative_ReturnsCorrectWeek;
    procedure Test_AddWeeks_CrossYear_ReturnsCorrectWeek;
    procedure Test_WeeksUntil_SameYear_ReturnsCorrectCount;
    procedure Test_WeeksUntil_CrossYear_ReturnsCorrectCount;
    procedure Test_WeeksUntil_Negative_ReturnsNegativeCount;
    
    // ═══════════════════════════════════════════════════════════════
    // 格式化与解析测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ToISO8601_Week1_ReturnsCorrectFormat;
    procedure Test_ToISO8601_Week52_ReturnsCorrectFormat;
    procedure Test_TryParse_ValidFormat_Success;
    procedure Test_TryParse_InvalidFormat_ReturnsFalse;
    procedure Test_TryParse_InvalidWeekNumber_ReturnsFalse;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Equal_SameWeek_ReturnsTrue;
    procedure Test_Equal_DifferentWeek_ReturnsFalse;
    procedure Test_LessThan_EarlierWeek_ReturnsTrue;
    procedure Test_LessThan_LaterWeek_ReturnsFalse;
    procedure Test_LessThan_CrossYear_ReturnsTrue;
    
    // ═══════════════════════════════════════════════════════════════
    // 边界情况测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_FromDate_2020Jan1_ReturnsWeek1Of2020;
    procedure Test_FromDate_2021Jan1_ReturnsWeek53Of2020;
    procedure Test_FromDate_2023Jan1_ReturnsWeek52Of2022;
  end;

implementation

{ TTestCase_IsoWeek }

// ═══════════════════════════════════════════════════════════════
// 构造函数测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_IsoWeek.Test_Create_ValidWeek_Success;
var
  W: TIsoWeek;
begin
  W := TIsoWeek.Create(2024, 1);
  AssertEquals('Year', 2024, W.Year);
  AssertEquals('Week', 1, W.Week);
end;

procedure TTestCase_IsoWeek.Test_FromDate_MondayOfWeek1_ReturnsWeek1;
var
  D: TDate;
  W: TIsoWeek;
begin
  // 2024-01-01 是周一，属于 2024 年第 1 周
  D := TDate.Create(2024, 1, 1);
  W := TIsoWeek.FromDate(D);
  AssertEquals('Year', 2024, W.Year);
  AssertEquals('Week', 1, W.Week);
end;

procedure TTestCase_IsoWeek.Test_FromDate_SundayOfWeek1_ReturnsWeek1;
var
  D: TDate;
  W: TIsoWeek;
begin
  // 2024-01-07 是周日，属于 2024 年第 1 周
  D := TDate.Create(2024, 1, 7);
  W := TIsoWeek.FromDate(D);
  AssertEquals('Year', 2024, W.Year);
  AssertEquals('Week', 1, W.Week);
end;

procedure TTestCase_IsoWeek.Test_FromDate_Jan1BelongsToPreviousYear_ReturnsWeek53;
var
  D: TDate;
  W: TIsoWeek;
begin
  // 2021-01-01 是周五，属于 2020 年第 53 周
  D := TDate.Create(2021, 1, 1);
  W := TIsoWeek.FromDate(D);
  AssertEquals('Year', 2020, W.Year);
  AssertEquals('Week', 53, W.Week);
end;

procedure TTestCase_IsoWeek.Test_FromDate_Dec31BelongsToNextYear_ReturnsWeek1;
var
  D: TDate;
  W: TIsoWeek;
begin
  // 2019-12-30 是周一，属于 2020 年第 1 周
  D := TDate.Create(2019, 12, 30);
  W := TIsoWeek.FromDate(D);
  AssertEquals('Year', 2020, W.Year);
  AssertEquals('Week', 1, W.Week);
end;

// ═══════════════════════════════════════════════════════════════
// 日期计算测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_IsoWeek.Test_Monday_Week1Of2024_ReturnsJan1;
var
  W: TIsoWeek;
  D: TDate;
begin
  W := TIsoWeek.Create(2024, 1);
  D := W.Monday;
  AssertEquals('Year', 2024, D.GetYear);
  AssertEquals('Month', 1, D.GetMonth);
  AssertEquals('Day', 1, D.GetDay);
end;

procedure TTestCase_IsoWeek.Test_Sunday_Week1Of2024_ReturnsJan7;
var
  W: TIsoWeek;
  D: TDate;
begin
  W := TIsoWeek.Create(2024, 1);
  D := W.Sunday;
  AssertEquals('Year', 2024, D.GetYear);
  AssertEquals('Month', 1, D.GetMonth);
  AssertEquals('Day', 7, D.GetDay);
end;

procedure TTestCase_IsoWeek.Test_DayOfWeek_Wednesday_ReturnsCorrectDate;
var
  W: TIsoWeek;
  D: TDate;
begin
  // 2024年第1周的周三应该是 2024-01-03
  W := TIsoWeek.Create(2024, 1);
  D := W.DayOfWeek(3);  // 3 = 周三
  AssertEquals('Year', 2024, D.GetYear);
  AssertEquals('Month', 1, D.GetMonth);
  AssertEquals('Day', 3, D.GetDay);
end;

// ═══════════════════════════════════════════════════════════════
// 周算术测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_IsoWeek.Test_AddWeeks_Positive_ReturnsCorrectWeek;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 1);
  W2 := W1.AddWeeks(4);
  AssertEquals('Year', 2024, W2.Year);
  AssertEquals('Week', 5, W2.Week);
end;

procedure TTestCase_IsoWeek.Test_AddWeeks_Negative_ReturnsCorrectWeek;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 10);
  W2 := W1.AddWeeks(-5);
  AssertEquals('Year', 2024, W2.Year);
  AssertEquals('Week', 5, W2.Week);
end;

procedure TTestCase_IsoWeek.Test_AddWeeks_CrossYear_ReturnsCorrectWeek;
var
  W1, W2: TIsoWeek;
begin
  // 从 2024 年第 52 周加 2 周
  W1 := TIsoWeek.Create(2024, 52);
  W2 := W1.AddWeeks(2);
  AssertEquals('Year', 2025, W2.Year);
  AssertEquals('Week', 2, W2.Week);
end;

procedure TTestCase_IsoWeek.Test_WeeksUntil_SameYear_ReturnsCorrectCount;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 5);
  W2 := TIsoWeek.Create(2024, 15);
  AssertEquals('WeeksUntil', 10, W1.WeeksUntil(W2));
end;

procedure TTestCase_IsoWeek.Test_WeeksUntil_CrossYear_ReturnsCorrectCount;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 50);
  W2 := TIsoWeek.Create(2025, 5);
  // 2024 年有 52 周，所以从第 50 周到下一年第 5 周是 7 周
  AssertEquals('WeeksUntil', 7, W1.WeeksUntil(W2));
end;

procedure TTestCase_IsoWeek.Test_WeeksUntil_Negative_ReturnsNegativeCount;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 15);
  W2 := TIsoWeek.Create(2024, 5);
  AssertEquals('WeeksUntil', -10, W1.WeeksUntil(W2));
end;

// ═══════════════════════════════════════════════════════════════
// 格式化与解析测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_IsoWeek.Test_ToISO8601_Week1_ReturnsCorrectFormat;
var
  W: TIsoWeek;
begin
  W := TIsoWeek.Create(2024, 1);
  AssertEquals('ISO8601', '2024-W01', W.ToISO8601);
end;

procedure TTestCase_IsoWeek.Test_ToISO8601_Week52_ReturnsCorrectFormat;
var
  W: TIsoWeek;
begin
  W := TIsoWeek.Create(2024, 52);
  AssertEquals('ISO8601', '2024-W52', W.ToISO8601);
end;

procedure TTestCase_IsoWeek.Test_TryParse_ValidFormat_Success;
var
  W: TIsoWeek;
  Ok: Boolean;
begin
  Ok := TIsoWeek.TryParse('2024-W15', W);
  AssertTrue('TryParse should succeed', Ok);
  AssertEquals('Year', 2024, W.Year);
  AssertEquals('Week', 15, W.Week);
end;

procedure TTestCase_IsoWeek.Test_TryParse_InvalidFormat_ReturnsFalse;
var
  W: TIsoWeek;
begin
  AssertFalse('Invalid format', TIsoWeek.TryParse('2024-15', W));
  AssertFalse('Too short', TIsoWeek.TryParse('2024-W1', W));
end;

procedure TTestCase_IsoWeek.Test_TryParse_InvalidWeekNumber_ReturnsFalse;
var
  W: TIsoWeek;
begin
  AssertFalse('Week 0', TIsoWeek.TryParse('2024-W00', W));
  AssertFalse('Week 54', TIsoWeek.TryParse('2024-W54', W));
end;

// ═══════════════════════════════════════════════════════════════
// 比较运算符测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_IsoWeek.Test_Equal_SameWeek_ReturnsTrue;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 10);
  W2 := TIsoWeek.Create(2024, 10);
  AssertTrue('Same week should be equal', W1 = W2);
end;

procedure TTestCase_IsoWeek.Test_Equal_DifferentWeek_ReturnsFalse;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 10);
  W2 := TIsoWeek.Create(2024, 11);
  AssertFalse('Different week should not be equal', W1 = W2);
end;

procedure TTestCase_IsoWeek.Test_LessThan_EarlierWeek_ReturnsTrue;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 5);
  W2 := TIsoWeek.Create(2024, 10);
  AssertTrue('Earlier week should be less than', W1 < W2);
end;

procedure TTestCase_IsoWeek.Test_LessThan_LaterWeek_ReturnsFalse;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2024, 15);
  W2 := TIsoWeek.Create(2024, 10);
  AssertFalse('Later week should not be less than', W1 < W2);
end;

procedure TTestCase_IsoWeek.Test_LessThan_CrossYear_ReturnsTrue;
var
  W1, W2: TIsoWeek;
begin
  W1 := TIsoWeek.Create(2023, 52);
  W2 := TIsoWeek.Create(2024, 1);
  AssertTrue('Previous year should be less than', W1 < W2);
end;

// ═══════════════════════════════════════════════════════════════
// 边界情况测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_IsoWeek.Test_FromDate_2020Jan1_ReturnsWeek1Of2020;
var
  D: TDate;
  W: TIsoWeek;
begin
  // 2020-01-01 是周三，属于 2020 年第 1 周
  D := TDate.Create(2020, 1, 1);
  W := TIsoWeek.FromDate(D);
  AssertEquals('Year', 2020, W.Year);
  AssertEquals('Week', 1, W.Week);
end;

procedure TTestCase_IsoWeek.Test_FromDate_2021Jan1_ReturnsWeek53Of2020;
var
  D: TDate;
  W: TIsoWeek;
begin
  // 2021-01-01 是周五，属于 2020 年第 53 周
  D := TDate.Create(2021, 1, 1);
  W := TIsoWeek.FromDate(D);
  AssertEquals('Year', 2020, W.Year);
  AssertEquals('Week', 53, W.Week);
end;

procedure TTestCase_IsoWeek.Test_FromDate_2023Jan1_ReturnsWeek52Of2022;
var
  D: TDate;
  W: TIsoWeek;
begin
  // 2023-01-01 是周日，属于 2022 年第 52 周
  D := TDate.Create(2023, 1, 1);
  W := TIsoWeek.FromDate(D);
  AssertEquals('Year', 2022, W.Year);
  AssertEquals('Week', 52, W.Week);
end;

initialization
  RegisterTest(TTestCase_IsoWeek);

end.
