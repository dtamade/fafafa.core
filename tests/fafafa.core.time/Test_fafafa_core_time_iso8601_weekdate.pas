{$mode objfpc}{$H+}{$J-}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

unit Test_fafafa_core_time_iso8601_weekdate;

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.time.iso8601;

type
  {
    测试 ISSUE-41 修复：ISO 8601周日期边界情况
    
    验证：
    1. 12月29-31日可能属于下一年的W01
    2. 1月1-3日可能属于上一年的W52/W53  
    3. 周一为一周开始（Monday=1, Sunday=7）
    4. 第一周包含1月4日
    5. 格式化和解析的往返一致性
  }
  TTestISO8601WeekDate = class(TTestCase)
  published
    // 基本功能测试
    procedure Test_WeekDate_MondayIsDay1;
    procedure Test_WeekDate_SundayIsDay7;
    procedure Test_WeekDate_Week01_Contains_Jan4;
    
    // 边界情况测试 - 12月末属于下一年
    procedure Test_WeekDate_2024Dec30_Is_2025W01;
    procedure Test_WeekDate_2024Dec31_Is_2025W01;
    procedure Test_WeekDate_2020Dec28_Is_2020W53;  // 闰年
    procedure Test_WeekDate_2020Dec31_Is_2020W53;
    
    // 边界情况测试 - 1月初属于上一年
    procedure Test_WeekDate_2025Jan01_Is_2025W01;
    procedure Test_WeekDate_2021Jan01_Is_2020W53;
    procedure Test_WeekDate_2021Jan03_Is_2020W53;
    procedure Test_WeekDate_2021Jan04_Is_2021W01;
    
    // 往返测试
    procedure Test_WeekDate_RoundTrip_Format_Parse;
    procedure Test_WeekDate_RoundTrip_Multiple_Years;
    
    // 格式化测试
    procedure Test_FormatWeekDate_BasicFormat;
    procedure Test_FormatWeekDate_ExtendedFormat;
    
    // 解析测试
    procedure Test_ParseWeekDate_BasicFormat;
    procedure Test_ParseWeekDate_ExtendedFormat;
    procedure Test_ParseWeekDate_InvalidFormats;
  end;

implementation

{ TTestISO8601WeekDate }

procedure TTestISO8601WeekDate.Test_WeekDate_MondayIsDay1;
var
  date: TDateTime;
  formatted: string;
begin
  // 2024-01-01 是周一
  date := EncodeDate(2024, 1, 1);
  formatted := ISO8601WeekDateToString(date);
  
  // 应该是 2024-W01-1（周一）
  CheckTrue(Pos('W01-1', formatted) > 0, 
    Format('周一应该是Day 1: %s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_SundayIsDay7;
var
  date: TDateTime;
  formatted: string;
begin
  // 2024-01-07 是周日
  date := EncodeDate(2024, 1, 7);
  formatted := ISO8601WeekDateToString(date);
  
  // 应该是 2024-W01-7（周日）
  CheckTrue(Pos('W01-7', formatted) > 0, 
    Format('周日应该是Day 7: %s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_Week01_Contains_Jan4;
var
  jan4_2024, jan4_2025: TDateTime;
  formatted_2024, formatted_2025: string;
begin
  // 2024-01-04（周四）应该在W01
  jan4_2024 := EncodeDate(2024, 1, 4);
  formatted_2024 := ISO8601WeekDateToString(jan4_2024);
  CheckTrue(Pos('2024-W01', formatted_2024) > 0, 
    Format('2024-01-04 应该在 2024-W01: %s', [formatted_2024]));
  
  // 2025-01-04（周六）应该在W01
  jan4_2025 := EncodeDate(2025, 1, 4);
  formatted_2025 := ISO8601WeekDateToString(jan4_2025);
  CheckTrue(Pos('2025-W01', formatted_2025) > 0, 
    Format('2025-01-04 应该在 2025-W01: %s', [formatted_2025]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_2024Dec30_Is_2025W01;
var
  date: TDateTime;
  formatted: string;
begin
  // 2024-12-30 (Monday) → 2025-W01-1
  date := EncodeDate(2024, 12, 30);
  formatted := ISO8601WeekDateToString(date);
  
  CheckTrue(Pos('2025-W01-1', formatted) > 0, 
    Format('2024-12-30（周一）应该是 2025-W01-1，实际：%s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_2024Dec31_Is_2025W01;
var
  date: TDateTime;
  formatted: string;
begin
  // 2024-12-31 (Tuesday) → 2025-W01-2
  date := EncodeDate(2024, 12, 31);
  formatted := ISO8601WeekDateToString(date);
  
  CheckTrue(Pos('2025-W01-2', formatted) > 0, 
    Format('2024-12-31（周二）应该是 2025-W01-2，实际：%s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_2020Dec28_Is_2020W53;
var
  date: TDateTime;
  formatted: string;
begin
  // 2020是闰年，2020-12-28 (Monday) → 2020-W53-1
  date := EncodeDate(2020, 12, 28);
  formatted := ISO8601WeekDateToString(date);
  
  CheckTrue(Pos('2020-W53-1', formatted) > 0, 
    Format('2020-12-28（闰年，周一）应该是 2020-W53-1，实际：%s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_2020Dec31_Is_2020W53;
var
  date: TDateTime;
  formatted: string;
begin
  // 2020-12-31 (Thursday) → 2020-W53-4
  date := EncodeDate(2020, 12, 31);
  formatted := ISO8601WeekDateToString(date);
  
  CheckTrue(Pos('2020-W53-4', formatted) > 0, 
    Format('2020-12-31（闰年，周四）应该是 2020-W53-4，实际：%s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_2025Jan01_Is_2025W01;
var
  date: TDateTime;
  formatted: string;
begin
  // 2025-01-01 (Wednesday) → 2025-W01-3
  date := EncodeDate(2025, 1, 1);
  formatted := ISO8601WeekDateToString(date);
  
  CheckTrue(Pos('2025-W01-3', formatted) > 0, 
    Format('2025-01-01（周三）应该是 2025-W01-3，实际：%s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_2021Jan01_Is_2020W53;
var
  date: TDateTime;
  formatted: string;
begin
  // 2021-01-01 (Friday) → 2020-W53-5
  date := EncodeDate(2021, 1, 1);
  formatted := ISO8601WeekDateToString(date);
  
  CheckTrue(Pos('2020-W53-5', formatted) > 0, 
    Format('2021-01-01（周五）应该是 2020-W53-5，实际：%s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_2021Jan03_Is_2020W53;
var
  date: TDateTime;
  formatted: string;
begin
  // 2021-01-03 (Sunday) → 2020-W53-7
  date := EncodeDate(2021, 1, 3);
  formatted := ISO8601WeekDateToString(date);
  
  CheckTrue(Pos('2020-W53-7', formatted) > 0, 
    Format('2021-01-03（周日）应该是 2020-W53-7，实际：%s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_2021Jan04_Is_2021W01;
var
  date: TDateTime;
  formatted: string;
begin
  // 2021-01-04 (Monday) → 2021-W01-1
  date := EncodeDate(2021, 1, 4);
  formatted := ISO8601WeekDateToString(date);
  
  CheckTrue(Pos('2021-W01-1', formatted) > 0, 
    Format('2021-01-04（周一，是1月4日）应该是 2021-W01-1，实际：%s', [formatted]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_RoundTrip_Format_Parse;
var
  originalDate, parsedDate: TDateTime;
  formatted: string;
  success: Boolean;
begin
  // 测试边界日期的往返
  originalDate := EncodeDate(2024, 12, 30);
  
  // 格式化
  formatted := ISO8601WeekDateToString(originalDate);
  
  // 解析
  success := TryISO8601StringToDateTime(formatted, parsedDate);
  
  CheckTrue(success, Format('解析失败：%s', [formatted]));
  CheckEquals(Trunc(originalDate), Trunc(parsedDate), 
    Format('往返不一致：%s → %s → %s', 
      [DateToStr(originalDate), formatted, DateToStr(parsedDate)]));
end;

procedure TTestISO8601WeekDate.Test_WeekDate_RoundTrip_Multiple_Years;
var
  year, month, day: Integer;
  testDate, parsedDate: TDateTime;
  formatted: string;
  success: Boolean;
  testCount, failCount: Integer;
begin
  testCount := 0;
  failCount := 0;
  
  // 测试多个年份的边界日期
  for year := 2020 to 2025 do
  begin
    // 12月28-31日
    for day := 28 to 31 do
    begin
      if TryEncodeDate(year, 12, day, testDate) then
      begin
        Inc(testCount);
        formatted := ISO8601WeekDateToString(testDate);
        success := TryISO8601StringToDateTime(formatted, parsedDate);
        
        if not success or (Trunc(testDate) <> Trunc(parsedDate)) then
        begin
          Inc(failCount);
          WriteLn(Format('失败：%d-12-%d → %s → %s', 
            [year, day, formatted, DateToStr(parsedDate)]));
        end;
      end;
    end;
    
    // 1月1-7日
    for day := 1 to 7 do
    begin
      testDate := EncodeDate(year, 1, day);
      Inc(testCount);
      formatted := ISO8601WeekDateToString(testDate);
      success := TryISO8601StringToDateTime(formatted, parsedDate);
      
      if not success or (Trunc(testDate) <> Trunc(parsedDate)) then
      begin
        Inc(failCount);
        WriteLn(Format('失败：%d-01-%d → %s → %s', 
          [year, day, formatted, DateToStr(parsedDate)]));
      end;
    end;
  end;
  
  CheckEquals(0, failCount, 
    Format('往返测试：%d/%d 失败', [failCount, testCount]));
end;

procedure TTestISO8601WeekDate.Test_FormatWeekDate_BasicFormat;
var
  date: TDateTime;
  formatted: string;
begin
  date := EncodeDate(2024, 1, 15);
  formatted := TISO8601Formatter.FormatWeekDate(date, True);  // Basic format
  
  // 基本格式：YYYYWwwD（无分隔符）
  CheckTrue(Length(formatted) = 8, 
    Format('基本格式应该是8字符，实际：%d (%s)', [Length(formatted), formatted]));
  CheckTrue(Pos('-', formatted) = 0, 
    '基本格式不应包含分隔符');
  CheckTrue(Pos('W', formatted) > 0, 
    '应包含W标记');
end;

procedure TTestISO8601WeekDate.Test_FormatWeekDate_ExtendedFormat;
var
  date: TDateTime;
  formatted: string;
begin
  date := EncodeDate(2024, 1, 15);
  formatted := TISO8601Formatter.FormatWeekDate(date, False);  // Extended format
  
  // 扩展格式：YYYY-Www-D
  CheckTrue(Length(formatted) = 10, 
    Format('扩展格式应该是10字符，实际：%d (%s)', [Length(formatted), formatted]));
  CheckTrue((Pos('-', formatted) > 0), 
    '扩展格式应包含分隔符');
  CheckTrue(Pos('W', formatted) > 0, 
    '应包含W标记');
end;

procedure TTestISO8601WeekDate.Test_ParseWeekDate_BasicFormat;
var
  date: TDateTime;
  success: Boolean;
begin
  // 基本格式：YYYYWwwD
  success := TISO8601Parser.ParseWeekDate('2024W011', date);
  
  CheckTrue(success, '应该成功解析基本格式 2024W011');
  CheckEquals(2024, YearOf(date), '年份应该是2024');
end;

procedure TTestISO8601WeekDate.Test_ParseWeekDate_ExtendedFormat;
var
  date: TDateTime;
  success: Boolean;
begin
  // 扩展格式：YYYY-Www-D
  success := TISO8601Parser.ParseWeekDate('2024-W01-1', date);
  
  CheckTrue(success, '应该成功解析扩展格式 2024-W01-1');
  CheckEquals(2024, YearOf(date), '年份应该是2024');
end;

procedure TTestISO8601WeekDate.Test_ParseWeekDate_InvalidFormats;
var
  date: TDateTime;
  success: Boolean;
begin
  // 周数超出范围
  success := TISO8601Parser.ParseWeekDate('2024-W54-1', date);
  CheckFalse(success, '应该拒绝W54（超出范围）');
  
  // 周内日超出范围
  success := TISO8601Parser.ParseWeekDate('2024-W01-8', date);
  CheckFalse(success, '应该拒绝Day 8（超出范围）');
  
  // 无效格式
  success := TISO8601Parser.ParseWeekDate('2024-W1-1', date);
  CheckFalse(success, '应该拒绝单数字周数');
  
  success := TISO8601Parser.ParseWeekDate('2024W1', date);
  CheckFalse(success, '应该拒绝不完整格式');
end;

initialization
  RegisterTest(TTestISO8601WeekDate);

end.
