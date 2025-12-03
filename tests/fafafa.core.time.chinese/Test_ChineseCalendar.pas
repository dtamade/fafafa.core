{
  Test_ChineseCalendar.pas - 农历 TChineseDate 测试
  
  TDD: 先写测试，后写实现
  
  测试覆盖:
  1. TChineseDate 基本创建和属性
  2. 公历 -> 农历转换
  3. 农历 -> 公历转换
  4. 农历节日（春节、中秋等）
  5. 闰月处理
}
program Test_ChineseCalendar;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.date,
  fafafa.core.time.chinese;

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

procedure CheckEqualsStr(const Expected, Actual: string; const TestName: string);
begin
  Check(Expected = Actual, Format('%s (expected="%s", actual="%s")', [TestName, Expected, Actual]));
end;

// ============================================================
// 测试: TChineseDate 基本功能
// ============================================================

procedure Test_ChineseDate_Create;
var
  CD: TChineseDate;
begin
  WriteLn('Test_ChineseDate_Create:');
  
  // 创建农历日期：2024年正月初一
  CD := TChineseDate.Create(2024, 1, 1, False);
  CheckEquals(2024, CD.Year, 'Year = 2024');
  CheckEquals(1, CD.Month, 'Month = 1');
  CheckEquals(1, CD.Day, 'Day = 1');
  Check(not CD.IsLeapMonth, 'Not leap month');
end;

procedure Test_ChineseDate_LeapMonth;
var
  CD: TChineseDate;
begin
  WriteLn('Test_ChineseDate_LeapMonth:');
  
  // 2023年有闰二月
  CD := TChineseDate.Create(2023, 2, 15, True);  // 闰二月十五
  CheckEquals(2023, CD.Year, 'Year = 2023');
  CheckEquals(2, CD.Month, 'Month = 2');
  CheckEquals(15, CD.Day, 'Day = 15');
  Check(CD.IsLeapMonth, 'Is leap month');
end;

// ============================================================
// 测试: 公历 -> 农历转换
// ============================================================

procedure Test_SolarToLunar_SpringFestival2024;
var
  Solar: TDate;
  Lunar: TChineseDate;
begin
  WriteLn('Test_SolarToLunar_SpringFestival2024:');
  
  // 2024年春节是公历2024年2月10日 = 农历甲辰年正月初一
  Solar := TDate.Create(2024, 2, 10);
  Lunar := SolarToLunar(Solar);
  
  CheckEquals(2024, Lunar.Year, 'Lunar year = 2024');
  CheckEquals(1, Lunar.Month, 'Lunar month = 1');
  CheckEquals(1, Lunar.Day, 'Lunar day = 1');
  Check(not Lunar.IsLeapMonth, 'Not leap month');
end;

procedure Test_SolarToLunar_MidAutumn2024;
var
  Solar: TDate;
  Lunar: TChineseDate;
begin
  WriteLn('Test_SolarToLunar_MidAutumn2024:');
  
  // 2024年中秋是公历2024年9月17日 = 农历八月十五
  Solar := TDate.Create(2024, 9, 17);
  Lunar := SolarToLunar(Solar);
  
  CheckEquals(2024, Lunar.Year, 'Lunar year = 2024');
  CheckEquals(8, Lunar.Month, 'Lunar month = 8');
  CheckEquals(15, Lunar.Day, 'Lunar day = 15');
end;

procedure Test_SolarToLunar_LeapMonth2023;
var
  Solar: TDate;
  Lunar: TChineseDate;
begin
  WriteLn('Test_SolarToLunar_LeapMonth2023:');
  
  // 2023年闰二月从March 22到April 19
  // 2023年4月5日应该在闰二月中 (March 22 + 14天 = April 5 = 闰二月十五)
  Solar := TDate.Create(2023, 4, 5);
  Lunar := SolarToLunar(Solar);
  
  CheckEquals(2023, Lunar.Year, 'Lunar year = 2023');
  CheckEquals(2, Lunar.Month, 'Lunar month = 2 (leap)');
  Check(Lunar.IsLeapMonth, 'Is leap month');
end;

// ============================================================
// 测试: 农历 -> 公历转换
// ============================================================

procedure Test_LunarToSolar_SpringFestival2024;
var
  Lunar: TChineseDate;
  Solar: TDate;
begin
  WriteLn('Test_LunarToSolar_SpringFestival2024:');
  
  // 农历2024年正月初一 = 公历2024年2月10日
  Lunar := TChineseDate.Create(2024, 1, 1, False);
  Solar := LunarToSolar(Lunar);
  
  CheckEquals(2024, Solar.GetYear, 'Solar year = 2024');
  CheckEquals(2, Solar.GetMonth, 'Solar month = 2');
  CheckEquals(10, Solar.GetDay, 'Solar day = 10');
end;

procedure Test_LunarToSolar_MidAutumn2024;
var
  Lunar: TChineseDate;
  Solar: TDate;
begin
  WriteLn('Test_LunarToSolar_MidAutumn2024:');
  
  // 农历2024年八月十五 = 公历2024年9月17日
  Lunar := TChineseDate.Create(2024, 8, 15, False);
  Solar := LunarToSolar(Lunar);
  
  CheckEquals(2024, Solar.GetYear, 'Solar year = 2024');
  CheckEquals(9, Solar.GetMonth, 'Solar month = 9');
  CheckEquals(17, Solar.GetDay, 'Solar day = 17');
end;

// ============================================================
// 测试: 往返一致性
// ============================================================

procedure Test_Roundtrip;
var
  OriginalSolar, RestoredSolar: TDate;
  Lunar: TChineseDate;
begin
  WriteLn('Test_Roundtrip:');
  
  // 公历 -> 农历 -> 公历
  OriginalSolar := TDate.Create(2024, 6, 15);
  Lunar := SolarToLunar(OriginalSolar);
  RestoredSolar := LunarToSolar(Lunar);
  
  Check(OriginalSolar = RestoredSolar, 'Solar -> Lunar -> Solar roundtrip');
end;

// ============================================================
// 测试: 农历节日
// ============================================================

procedure Test_GetSpringFestival;
var
  SF: TDate;
begin
  WriteLn('Test_GetSpringFestival:');
  
  SF := GetSpringFestival(2024);
  CheckEquals(2024, SF.GetYear, '2024 Spring Festival year');
  CheckEquals(2, SF.GetMonth, '2024 Spring Festival month');
  CheckEquals(10, SF.GetDay, '2024 Spring Festival day');
  
  SF := GetSpringFestival(2025);
  CheckEquals(2025, SF.GetYear, '2025 Spring Festival year');
  CheckEquals(1, SF.GetMonth, '2025 Spring Festival month');
  CheckEquals(29, SF.GetDay, '2025 Spring Festival day');
end;

procedure Test_GetMidAutumnFestival;
var
  MAF: TDate;
begin
  WriteLn('Test_GetMidAutumnFestival:');
  
  MAF := GetMidAutumnFestival(2024);
  CheckEquals(2024, MAF.GetYear, '2024 Mid-Autumn year');
  CheckEquals(9, MAF.GetMonth, '2024 Mid-Autumn month');
  CheckEquals(17, MAF.GetDay, '2024 Mid-Autumn day');
end;

procedure Test_GetDragonBoatFestival;
var
  DBF: TDate;
begin
  WriteLn('Test_GetDragonBoatFestival:');
  
  // 端午节 = 农历五月初五
  DBF := GetDragonBoatFestival(2024);
  CheckEquals(2024, DBF.GetYear, '2024 Dragon Boat year');
  CheckEquals(6, DBF.GetMonth, '2024 Dragon Boat month');
  CheckEquals(10, DBF.GetDay, '2024 Dragon Boat day');
end;

// ============================================================
// 测试: 天干地支
// ============================================================

procedure Test_GetGanZhi;
var
  GZ: string;
begin
  WriteLn('Test_GetGanZhi:');
  
  // 2024年是甲辰年
  GZ := GetYearGanZhi(2024);
  CheckEqualsStr('甲辰', GZ, '2024 = 甲辰');
  
  // 2023年是癸卯年
  GZ := GetYearGanZhi(2023);
  CheckEqualsStr('癸卯', GZ, '2023 = 癸卯');
end;

procedure Test_GetZodiac;
var
  Z: string;
begin
  WriteLn('Test_GetZodiac:');
  
  // 2024年是龙年
  Z := GetZodiac(2024);
  CheckEqualsStr('龙', Z, '2024 = 龙');
  
  // 2023年是兔年
  Z := GetZodiac(2023);
  CheckEqualsStr('兔', Z, '2023 = 兔');
end;

// ============================================================
// 主程序
// ============================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Chinese Calendar (农历) Tests');
  WriteLn('========================================');
  WriteLn('');
  
  Test_ChineseDate_Create;
  Test_ChineseDate_LeapMonth;
  
  Test_SolarToLunar_SpringFestival2024;
  Test_SolarToLunar_MidAutumn2024;
  Test_SolarToLunar_LeapMonth2023;
  
  Test_LunarToSolar_SpringFestival2024;
  Test_LunarToSolar_MidAutumn2024;
  
  Test_Roundtrip;
  
  Test_GetSpringFestival;
  Test_GetMidAutumnFestival;
  Test_GetDragonBoatFestival;
  
  Test_GetGanZhi;
  Test_GetZodiac;
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Total: %d  Passed: %d  Failed: %d', [TestCount, PassCount, FailCount]));
  WriteLn('========================================');
  
  if FailCount > 0 then
    Halt(1);
end.
