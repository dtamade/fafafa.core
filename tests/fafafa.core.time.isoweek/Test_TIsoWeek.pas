{$CODEPAGE UTF8}
unit Test_TIsoWeek;

{$I fafafa.core.settings.inc}
{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpcunit,
  testregistry,
  fafafa.core.time.isoweek,
  fafafa.core.time.date;

type
  TTestTIsoWeek = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // 构造函数测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Create_ValidWeek;
    procedure Test_Create_FirstWeek;
    procedure Test_Create_LastWeek;
    procedure Test_FromDate_Jan1;
    procedure Test_FromDate_Dec31;
    procedure Test_FromDate_WeekThursday;
    
    // ═══════════════════════════════════════════════════════════════
    // ISO 周边界测试（关键！）
    // ═══════════════════════════════════════════════════════════════
    
    // 2020-01-01 是周三，属于 2020-W01
    procedure Test_FromDate_2020_01_01;
    // 2019-12-30 是周一，属于 2020-W01（跨年！）
    procedure Test_FromDate_2019_12_30;
    // 2021-01-01 是周五，属于 2020-W53
    procedure Test_FromDate_2021_01_01;
    // 2024-12-30 是周一，属于 2025-W01
    procedure Test_FromDate_2024_12_30;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_GetYear_ReturnsIsoYear;
    procedure Test_GetWeek_ReturnsWeekNumber;
    
    // ═══════════════════════════════════════════════════════════════
    // 日期计算测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Monday_ReturnsFirstDayOfWeek;
    procedure Test_Sunday_ReturnsLastDayOfWeek;
    procedure Test_DayOfWeek_Monday;
    procedure Test_DayOfWeek_Sunday;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Equal_SameWeek;
    procedure Test_Equal_DifferentWeek;
    procedure Test_NotEqual;
    procedure Test_LessThan_SameYear;
    procedure Test_LessThan_DifferentYear;
    procedure Test_GreaterThan;
    
    // ═══════════════════════════════════════════════════════════════
    // 格式化测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ToISO8601_SingleDigitWeek;
    procedure Test_ToISO8601_DoubleDigitWeek;
    procedure Test_TryParse_Valid;
    procedure Test_TryParse_Invalid;
    procedure Test_ToString;
    
    // ═══════════════════════════════════════════════════════════════
    // 周算术测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_AddWeeks_Positive;
    procedure Test_AddWeeks_Negative;
    procedure Test_AddWeeks_CrossYear;
    procedure Test_WeeksBetween_SameYear;
    procedure Test_WeeksBetween_CrossYear;
  end;

implementation

{ TTestTIsoWeek }

// ═══════════════════════════════════════════════════════════════
// 构造函数测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTIsoWeek.Test_Create_ValidWeek;
var
  LWeek: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 25);
  AssertEquals(2024, LWeek.Year);
  AssertEquals(25, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_Create_FirstWeek;
var
  LWeek: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 1);
  AssertEquals(1, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_Create_LastWeek;
var
  LWeek: TIsoWeek;
begin
  // 2020 年有 53 周
  LWeek := TIsoWeek.Create(2020, 53);
  AssertEquals(53, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_FromDate_Jan1;
var
  LDate: TDate;
  LWeek: TIsoWeek;
begin
  // 2024-01-01 是周一，属于 2024-W01
  LDate := TDate.Create(2024, 1, 1);
  LWeek := TIsoWeek.FromDate(LDate);
  AssertEquals(2024, LWeek.Year);
  AssertEquals(1, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_FromDate_Dec31;
var
  LDate: TDate;
  LWeek: TIsoWeek;
begin
  // 2024-12-31 是周二
  LDate := TDate.Create(2024, 12, 31);
  LWeek := TIsoWeek.FromDate(LDate);
  AssertEquals(2025, LWeek.Year); // ISO 年是 2025
  AssertEquals(1, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_FromDate_WeekThursday;
var
  LDate: TDate;
  LWeek: TIsoWeek;
begin
  // 周四决定周的归属
  LDate := TDate.Create(2024, 6, 20); // 2024-06-20 是周四
  LWeek := TIsoWeek.FromDate(LDate);
  AssertEquals(2024, LWeek.Year);
  AssertEquals(25, LWeek.Week);
end;

// ═══════════════════════════════════════════════════════════════
// ISO 周边界测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTIsoWeek.Test_FromDate_2020_01_01;
var
  LDate: TDate;
  LWeek: TIsoWeek;
begin
  LDate := TDate.Create(2020, 1, 1); // 周三
  LWeek := TIsoWeek.FromDate(LDate);
  AssertEquals(2020, LWeek.Year);
  AssertEquals(1, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_FromDate_2019_12_30;
var
  LDate: TDate;
  LWeek: TIsoWeek;
begin
  LDate := TDate.Create(2019, 12, 30); // 周一，属于 2020-W01
  LWeek := TIsoWeek.FromDate(LDate);
  AssertEquals(2020, LWeek.Year);
  AssertEquals(1, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_FromDate_2021_01_01;
var
  LDate: TDate;
  LWeek: TIsoWeek;
begin
  LDate := TDate.Create(2021, 1, 1); // 周五，属于 2020-W53
  LWeek := TIsoWeek.FromDate(LDate);
  AssertEquals(2020, LWeek.Year);
  AssertEquals(53, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_FromDate_2024_12_30;
var
  LDate: TDate;
  LWeek: TIsoWeek;
begin
  LDate := TDate.Create(2024, 12, 30); // 周一，属于 2025-W01
  LWeek := TIsoWeek.FromDate(LDate);
  AssertEquals(2025, LWeek.Year);
  AssertEquals(1, LWeek.Week);
end;

// ═══════════════════════════════════════════════════════════════
// 访问器测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTIsoWeek.Test_GetYear_ReturnsIsoYear;
var
  LWeek: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 10);
  AssertEquals(2024, LWeek.Year);
end;

procedure TTestTIsoWeek.Test_GetWeek_ReturnsWeekNumber;
var
  LWeek: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 42);
  AssertEquals(42, LWeek.Week);
end;

// ═══════════════════════════════════════════════════════════════
// 日期计算测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTIsoWeek.Test_Monday_ReturnsFirstDayOfWeek;
var
  LWeek: TIsoWeek;
  LMonday: TDate;
begin
  LWeek := TIsoWeek.Create(2024, 25);
  LMonday := LWeek.Monday;
  AssertEquals(2024, LMonday.GetYear);
  AssertEquals(6, LMonday.GetMonth);
  AssertEquals(17, LMonday.GetDay); // 2024-06-17 是 2024-W25 的周一
end;

procedure TTestTIsoWeek.Test_Sunday_ReturnsLastDayOfWeek;
var
  LWeek: TIsoWeek;
  LSunday: TDate;
begin
  LWeek := TIsoWeek.Create(2024, 25);
  LSunday := LWeek.Sunday;
  AssertEquals(2024, LSunday.GetYear);
  AssertEquals(6, LSunday.GetMonth);
  AssertEquals(23, LSunday.GetDay); // 2024-06-23 是 2024-W25 的周日
end;

procedure TTestTIsoWeek.Test_DayOfWeek_Monday;
var
  LWeek: TIsoWeek;
  LDate: TDate;
begin
  LWeek := TIsoWeek.Create(2024, 25);
  LDate := LWeek.DayOfWeek(1); // 周一
  AssertEquals(17, LDate.GetDay);
end;

procedure TTestTIsoWeek.Test_DayOfWeek_Sunday;
var
  LWeek: TIsoWeek;
  LDate: TDate;
begin
  LWeek := TIsoWeek.Create(2024, 25);
  LDate := LWeek.DayOfWeek(7); // 周日
  AssertEquals(23, LDate.GetDay);
end;

// ═══════════════════════════════════════════════════════════════
// 比较运算符测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTIsoWeek.Test_Equal_SameWeek;
var
  A, B: TIsoWeek;
begin
  A := TIsoWeek.Create(2024, 25);
  B := TIsoWeek.Create(2024, 25);
  AssertTrue(A = B);
end;

procedure TTestTIsoWeek.Test_Equal_DifferentWeek;
var
  A, B: TIsoWeek;
begin
  A := TIsoWeek.Create(2024, 25);
  B := TIsoWeek.Create(2024, 26);
  AssertFalse(A = B);
end;

procedure TTestTIsoWeek.Test_NotEqual;
var
  A, B: TIsoWeek;
begin
  A := TIsoWeek.Create(2024, 25);
  B := TIsoWeek.Create(2024, 26);
  AssertTrue(A <> B);
end;

procedure TTestTIsoWeek.Test_LessThan_SameYear;
var
  A, B: TIsoWeek;
begin
  A := TIsoWeek.Create(2024, 10);
  B := TIsoWeek.Create(2024, 20);
  AssertTrue(A < B);
  AssertFalse(B < A);
end;

procedure TTestTIsoWeek.Test_LessThan_DifferentYear;
var
  A, B: TIsoWeek;
begin
  A := TIsoWeek.Create(2023, 52);
  B := TIsoWeek.Create(2024, 1);
  AssertTrue(A < B);
end;

procedure TTestTIsoWeek.Test_GreaterThan;
var
  A, B: TIsoWeek;
begin
  A := TIsoWeek.Create(2024, 30);
  B := TIsoWeek.Create(2024, 20);
  AssertTrue(A > B);
end;

// ═══════════════════════════════════════════════════════════════
// 格式化测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTIsoWeek.Test_ToISO8601_SingleDigitWeek;
var
  LWeek: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 1);
  AssertEquals('2024-W01', LWeek.ToISO8601);
end;

procedure TTestTIsoWeek.Test_ToISO8601_DoubleDigitWeek;
var
  LWeek: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 25);
  AssertEquals('2024-W25', LWeek.ToISO8601);
end;

procedure TTestTIsoWeek.Test_TryParse_Valid;
var
  LWeek: TIsoWeek;
begin
  AssertTrue(TIsoWeek.TryParse('2024-W25', LWeek));
  AssertEquals(2024, LWeek.Year);
  AssertEquals(25, LWeek.Week);
end;

procedure TTestTIsoWeek.Test_TryParse_Invalid;
var
  LWeek: TIsoWeek;
begin
  AssertFalse(TIsoWeek.TryParse('invalid', LWeek));
  AssertFalse(TIsoWeek.TryParse('2024-25', LWeek));
  AssertFalse(TIsoWeek.TryParse('W25', LWeek));
end;

procedure TTestTIsoWeek.Test_ToString;
var
  LWeek: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 25);
  AssertEquals('2024-W25', LWeek.ToString);
end;

// ═══════════════════════════════════════════════════════════════
// 周算术测试
// ═══════════════════════════════════════════════════════════════

procedure TTestTIsoWeek.Test_AddWeeks_Positive;
var
  LWeek, LResult: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 10);
  LResult := LWeek.AddWeeks(5);
  AssertEquals(15, LResult.Week);
end;

procedure TTestTIsoWeek.Test_AddWeeks_Negative;
var
  LWeek, LResult: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 10);
  LResult := LWeek.AddWeeks(-5);
  AssertEquals(5, LResult.Week);
end;

procedure TTestTIsoWeek.Test_AddWeeks_CrossYear;
var
  LWeek, LResult: TIsoWeek;
begin
  LWeek := TIsoWeek.Create(2024, 50);
  LResult := LWeek.AddWeeks(5);
  AssertEquals(2025, LResult.Year);
  AssertEquals(3, LResult.Week);
end;

procedure TTestTIsoWeek.Test_WeeksBetween_SameYear;
var
  A, B: TIsoWeek;
begin
  A := TIsoWeek.Create(2024, 10);
  B := TIsoWeek.Create(2024, 25);
  AssertEquals(15, A.WeeksUntil(B));
end;

procedure TTestTIsoWeek.Test_WeeksBetween_CrossYear;
var
  A, B: TIsoWeek;
begin
  A := TIsoWeek.Create(2023, 52);
  B := TIsoWeek.Create(2024, 2);
  // 2023 有 52 周，所以从 W52 到 2024-W02 是 2 周
  AssertTrue(A.WeeksUntil(B) > 0);
end;

initialization
  RegisterTest(TTestTIsoWeek);

end.
