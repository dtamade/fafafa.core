unit Test_fafafa_core_time_workday;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.date,
  fafafa.core.time.workday;

type
  TTestCase_Workday = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // IsWeekend 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_IsWeekend_Saturday_ReturnsTrue;
    procedure Test_IsWeekend_Sunday_ReturnsTrue;
    procedure Test_IsWeekend_Monday_ReturnsFalse;
    procedure Test_IsWeekend_Friday_ReturnsFalse;
    
    // ═══════════════════════════════════════════════════════════════
    // IsWorkday 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_IsWorkday_Monday_ReturnsTrue;
    procedure Test_IsWorkday_Friday_ReturnsTrue;
    procedure Test_IsWorkday_Saturday_ReturnsFalse;
    procedure Test_IsWorkday_Sunday_ReturnsFalse;
    
    // ═══════════════════════════════════════════════════════════════
    // GetNextWorkday 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_GetNextWorkday_FromFriday_ReturnsMonday;
    procedure Test_GetNextWorkday_FromSaturday_ReturnsMonday;
    procedure Test_GetNextWorkday_FromSunday_ReturnsMonday;
    procedure Test_GetNextWorkday_FromMonday_ReturnsTuesday;
    procedure Test_GetNextWorkday_FromThursday_ReturnsFriday;
    
    // ═══════════════════════════════════════════════════════════════
    // GetPreviousWorkday 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_GetPreviousWorkday_FromMonday_ReturnsFriday;
    procedure Test_GetPreviousWorkday_FromSaturday_ReturnsFriday;
    procedure Test_GetPreviousWorkday_FromSunday_ReturnsFriday;
    procedure Test_GetPreviousWorkday_FromTuesday_ReturnsMonday;
    procedure Test_GetPreviousWorkday_FromFriday_ReturnsThursday;
    
    // ═══════════════════════════════════════════════════════════════
    // GetWorkdaysBetween 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_GetWorkdaysBetween_SameDay_Workday_Returns1;
    procedure Test_GetWorkdaysBetween_SameDay_Weekend_Returns0;
    procedure Test_GetWorkdaysBetween_FullWeek_Returns5;
    procedure Test_GetWorkdaysBetween_TwoWeeks_Returns10;
    procedure Test_GetWorkdaysBetween_MonToFri_Returns5;
    procedure Test_GetWorkdaysBetween_EndBeforeStart_Returns0;
    
    // ═══════════════════════════════════════════════════════════════
    // AddWorkdays 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_AddWorkdays_Zero_ReturnsSameDate;
    procedure Test_AddWorkdays_Positive_SkipsWeekend;
    procedure Test_AddWorkdays_Negative_SkipsWeekend;
    procedure Test_AddWorkdays_5FromMonday_ReturnsNextMonday;
    procedure Test_AddWorkdays_10FromMonday_ReturnsWeekAfterNextMonday;
  end;

implementation

{ TTestCase_Workday }

// ═══════════════════════════════════════════════════════════════
// IsWeekend 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Workday.Test_IsWeekend_Saturday_ReturnsTrue;
var
  d: TDate;
begin
  // 2024-12-07 是周六
  d := TDate.Create(2024, 12, 7);
  CheckTrue(IsWeekend(d), 'Saturday should be weekend');
end;

procedure TTestCase_Workday.Test_IsWeekend_Sunday_ReturnsTrue;
var
  d: TDate;
begin
  // 2024-12-08 是周日
  d := TDate.Create(2024, 12, 8);
  CheckTrue(IsWeekend(d), 'Sunday should be weekend');
end;

procedure TTestCase_Workday.Test_IsWeekend_Monday_ReturnsFalse;
var
  d: TDate;
begin
  // 2024-12-09 是周一
  d := TDate.Create(2024, 12, 9);
  CheckFalse(IsWeekend(d), 'Monday should not be weekend');
end;

procedure TTestCase_Workday.Test_IsWeekend_Friday_ReturnsFalse;
var
  d: TDate;
begin
  // 2024-12-06 是周五
  d := TDate.Create(2024, 12, 6);
  CheckFalse(IsWeekend(d), 'Friday should not be weekend');
end;

// ═══════════════════════════════════════════════════════════════
// IsWorkday 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Workday.Test_IsWorkday_Monday_ReturnsTrue;
var
  d: TDate;
begin
  // 2024-12-09 是周一
  d := TDate.Create(2024, 12, 9);
  CheckTrue(IsWorkday(d), 'Monday should be workday');
end;

procedure TTestCase_Workday.Test_IsWorkday_Friday_ReturnsTrue;
var
  d: TDate;
begin
  // 2024-12-06 是周五
  d := TDate.Create(2024, 12, 6);
  CheckTrue(IsWorkday(d), 'Friday should be workday');
end;

procedure TTestCase_Workday.Test_IsWorkday_Saturday_ReturnsFalse;
var
  d: TDate;
begin
  // 2024-12-07 是周六
  d := TDate.Create(2024, 12, 7);
  CheckFalse(IsWorkday(d), 'Saturday should not be workday');
end;

procedure TTestCase_Workday.Test_IsWorkday_Sunday_ReturnsFalse;
var
  d: TDate;
begin
  // 2024-12-08 是周日
  d := TDate.Create(2024, 12, 8);
  CheckFalse(IsWorkday(d), 'Sunday should not be workday');
end;

// ═══════════════════════════════════════════════════════════════
// GetNextWorkday 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Workday.Test_GetNextWorkday_FromFriday_ReturnsMonday;
var
  d, r: TDate;
begin
  // 2024-12-06 周五 -> 2024-12-09 周一
  d := TDate.Create(2024, 12, 6);
  r := GetNextWorkday(d);
  CheckEquals(2024, r.GetYear);
  CheckEquals(12, r.GetMonth);
  CheckEquals(9, r.GetDay);
end;

procedure TTestCase_Workday.Test_GetNextWorkday_FromSaturday_ReturnsMonday;
var
  d, r: TDate;
begin
  // 2024-12-07 周六 -> 2024-12-09 周一
  d := TDate.Create(2024, 12, 7);
  r := GetNextWorkday(d);
  CheckEquals(9, r.GetDay);
end;

procedure TTestCase_Workday.Test_GetNextWorkday_FromSunday_ReturnsMonday;
var
  d, r: TDate;
begin
  // 2024-12-08 周日 -> 2024-12-09 周一
  d := TDate.Create(2024, 12, 8);
  r := GetNextWorkday(d);
  CheckEquals(9, r.GetDay);
end;

procedure TTestCase_Workday.Test_GetNextWorkday_FromMonday_ReturnsTuesday;
var
  d, r: TDate;
begin
  // 2024-12-09 周一 -> 2024-12-10 周二
  d := TDate.Create(2024, 12, 9);
  r := GetNextWorkday(d);
  CheckEquals(10, r.GetDay);
end;

procedure TTestCase_Workday.Test_GetNextWorkday_FromThursday_ReturnsFriday;
var
  d, r: TDate;
begin
  // 2024-12-05 周四 -> 2024-12-06 周五
  d := TDate.Create(2024, 12, 5);
  r := GetNextWorkday(d);
  CheckEquals(6, r.GetDay);
end;

// ═══════════════════════════════════════════════════════════════
// GetPreviousWorkday 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Workday.Test_GetPreviousWorkday_FromMonday_ReturnsFriday;
var
  d, r: TDate;
begin
  // 2024-12-09 周一 -> 2024-12-06 周五
  d := TDate.Create(2024, 12, 9);
  r := GetPreviousWorkday(d);
  CheckEquals(6, r.GetDay);
end;

procedure TTestCase_Workday.Test_GetPreviousWorkday_FromSaturday_ReturnsFriday;
var
  d, r: TDate;
begin
  // 2024-12-07 周六 -> 2024-12-06 周五
  d := TDate.Create(2024, 12, 7);
  r := GetPreviousWorkday(d);
  CheckEquals(6, r.GetDay);
end;

procedure TTestCase_Workday.Test_GetPreviousWorkday_FromSunday_ReturnsFriday;
var
  d, r: TDate;
begin
  // 2024-12-08 周日 -> 2024-12-06 周五
  d := TDate.Create(2024, 12, 8);
  r := GetPreviousWorkday(d);
  CheckEquals(6, r.GetDay);
end;

procedure TTestCase_Workday.Test_GetPreviousWorkday_FromTuesday_ReturnsMonday;
var
  d, r: TDate;
begin
  // 2024-12-10 周二 -> 2024-12-09 周一
  d := TDate.Create(2024, 12, 10);
  r := GetPreviousWorkday(d);
  CheckEquals(9, r.GetDay);
end;

procedure TTestCase_Workday.Test_GetPreviousWorkday_FromFriday_ReturnsThursday;
var
  d, r: TDate;
begin
  // 2024-12-06 周五 -> 2024-12-05 周四
  d := TDate.Create(2024, 12, 6);
  r := GetPreviousWorkday(d);
  CheckEquals(5, r.GetDay);
end;

// ═══════════════════════════════════════════════════════════════
// GetWorkdaysBetween 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Workday.Test_GetWorkdaysBetween_SameDay_Workday_Returns1;
var
  d: TDate;
begin
  // 同一个工作日应该返回 1
  d := TDate.Create(2024, 12, 9); // 周一
  CheckEquals(1, GetWorkdaysBetween(d, d));
end;

procedure TTestCase_Workday.Test_GetWorkdaysBetween_SameDay_Weekend_Returns0;
var
  d: TDate;
begin
  // 同一个周末应该返回 0
  d := TDate.Create(2024, 12, 7); // 周六
  CheckEquals(0, GetWorkdaysBetween(d, d));
end;

procedure TTestCase_Workday.Test_GetWorkdaysBetween_FullWeek_Returns5;
var
  startD, endD: TDate;
begin
  // 周一到周日（完整一周）= 5 个工作日
  startD := TDate.Create(2024, 12, 9);  // 周一
  endD := TDate.Create(2024, 12, 15);   // 周日
  CheckEquals(5, GetWorkdaysBetween(startD, endD));
end;

procedure TTestCase_Workday.Test_GetWorkdaysBetween_TwoWeeks_Returns10;
var
  startD, endD: TDate;
begin
  // 两周 = 10 个工作日
  startD := TDate.Create(2024, 12, 9);  // 周一
  endD := TDate.Create(2024, 12, 22);   // 下周日
  CheckEquals(10, GetWorkdaysBetween(startD, endD));
end;

procedure TTestCase_Workday.Test_GetWorkdaysBetween_MonToFri_Returns5;
var
  startD, endD: TDate;
begin
  // 周一到周五 = 5 个工作日
  startD := TDate.Create(2024, 12, 9);  // 周一
  endD := TDate.Create(2024, 12, 13);   // 周五
  CheckEquals(5, GetWorkdaysBetween(startD, endD));
end;

procedure TTestCase_Workday.Test_GetWorkdaysBetween_EndBeforeStart_Returns0;
var
  startD, endD: TDate;
begin
  // 结束日期在开始日期之前应该返回 0
  startD := TDate.Create(2024, 12, 13);
  endD := TDate.Create(2024, 12, 9);
  CheckEquals(0, GetWorkdaysBetween(startD, endD));
end;

// ═══════════════════════════════════════════════════════════════
// AddWorkdays 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Workday.Test_AddWorkdays_Zero_ReturnsSameDate;
var
  d, r: TDate;
begin
  d := TDate.Create(2024, 12, 9);
  r := AddWorkdays(d, 0);
  CheckTrue(d = r, 'Adding 0 workdays should return same date');
end;

procedure TTestCase_Workday.Test_AddWorkdays_Positive_SkipsWeekend;
var
  d, r: TDate;
begin
  // 周五 + 1 工作日 = 周一
  d := TDate.Create(2024, 12, 6);  // 周五
  r := AddWorkdays(d, 1);
  CheckEquals(9, r.GetDay);  // 周一
end;

procedure TTestCase_Workday.Test_AddWorkdays_Negative_SkipsWeekend;
var
  d, r: TDate;
begin
  // 周一 - 1 工作日 = 周五
  d := TDate.Create(2024, 12, 9);  // 周一
  r := AddWorkdays(d, -1);
  CheckEquals(6, r.GetDay);  // 周五
end;

procedure TTestCase_Workday.Test_AddWorkdays_5FromMonday_ReturnsNextMonday;
var
  d, r: TDate;
begin
  // 周一 + 5 工作日 = 下周一
  d := TDate.Create(2024, 12, 9);  // 周一
  r := AddWorkdays(d, 5);
  CheckEquals(16, r.GetDay);  // 下周一
end;

procedure TTestCase_Workday.Test_AddWorkdays_10FromMonday_ReturnsWeekAfterNextMonday;
var
  d, r: TDate;
begin
  // 周一 + 10 工作日 = 两周后的周一
  d := TDate.Create(2024, 12, 9);  // 周一
  r := AddWorkdays(d, 10);
  CheckEquals(23, r.GetDay);  // 两周后的周一
end;

initialization
  RegisterTest(TTestCase_Workday);

end.
