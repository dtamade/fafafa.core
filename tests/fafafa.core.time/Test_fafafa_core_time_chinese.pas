unit Test_fafafa_core_time_chinese;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.date,
  fafafa.core.time.chinese;

type
  TTestCase_ChineseCalendar = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // TChineseDate 创建测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_ChineseDate_Create_NormalMonth_Success;
    procedure Test_ChineseDate_Create_LeapMonth_Success;
    
    // ═══════════════════════════════════════════════════════════════
    // 公历转农历测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_SolarToLunar_SpringFestival2024_ReturnsCorrect;
    procedure Test_SolarToLunar_MidYear_ReturnsCorrect;
    procedure Test_SolarToLunar_EndOfYear_ReturnsCorrect;
    procedure Test_SolarToLunar_BeforeSpringFestival_ReturnsPreviousYear;
    
    // ═══════════════════════════════════════════════════════════════
    // 农历转公历测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_LunarToSolar_FirstDayOfYear_ReturnsSpringFestival;
    procedure Test_LunarToSolar_MidAutumn_ReturnsCorrect;
    procedure Test_LunarToSolar_RoundTrip_Success;
    
    // ═══════════════════════════════════════════════════════════════
    // 传统节日测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_GetSpringFestival_2024_ReturnsCorrect;
    procedure Test_GetSpringFestival_2025_ReturnsCorrect;
    procedure Test_GetMidAutumnFestival_2024_ReturnsCorrect;
    procedure Test_GetDragonBoatFestival_2024_ReturnsCorrect;
    
    // ═══════════════════════════════════════════════════════════════
    // 天干地支测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_GetYearGanZhi_2024_ReturnsJiaChen;
    procedure Test_GetYearGanZhi_2023_ReturnsGuiMao;
    procedure Test_GetYearGanZhi_1984_ReturnsJiaZi;
    
    // ═══════════════════════════════════════════════════════════════
    // 生肖测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_GetZodiac_2024_ReturnsDragon;
    procedure Test_GetZodiac_2023_ReturnsRabbit;
    procedure Test_GetZodiac_2025_ReturnsSnake;
    procedure Test_GetZodiac_AllAnimals_Cycle;
  end;

implementation

{ TTestCase_ChineseCalendar }

// ═══════════════════════════════════════════════════════════════
// TChineseDate 创建测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChineseCalendar.Test_ChineseDate_Create_NormalMonth_Success;
var
  CD: TChineseDate;
begin
  CD := TChineseDate.Create(2024, 1, 1, False);
  AssertEquals('Year', 2024, CD.Year);
  AssertEquals('Month', 1, CD.Month);
  AssertEquals('Day', 1, CD.Day);
  AssertFalse('Not leap month', CD.IsLeapMonth);
end;

procedure TTestCase_ChineseCalendar.Test_ChineseDate_Create_LeapMonth_Success;
var
  CD: TChineseDate;
begin
  CD := TChineseDate.Create(2023, 2, 15, True);  // 2023年有闰二月
  AssertEquals('Year', 2023, CD.Year);
  AssertEquals('Month', 2, CD.Month);
  AssertEquals('Day', 15, CD.Day);
  AssertTrue('Is leap month', CD.IsLeapMonth);
end;

// ═══════════════════════════════════════════════════════════════
// 公历转农历测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChineseCalendar.Test_SolarToLunar_SpringFestival2024_ReturnsCorrect;
var
  Solar: TDate;
  Lunar: TChineseDate;
begin
  // 2024年春节是2月10日，对应农历2024年正月初一
  Solar := TDate.Create(2024, 2, 10);
  Lunar := SolarToLunar(Solar);
  AssertEquals('Year', 2024, Lunar.Year);
  AssertEquals('Month', 1, Lunar.Month);
  AssertEquals('Day', 1, Lunar.Day);
end;

procedure TTestCase_ChineseCalendar.Test_SolarToLunar_MidYear_ReturnsCorrect;
var
  Solar: TDate;
  Lunar: TChineseDate;
begin
  // 2024年6月10日对应农历五月初五（端午节）
  Solar := TDate.Create(2024, 6, 10);
  Lunar := SolarToLunar(Solar);
  AssertEquals('Year', 2024, Lunar.Year);
  AssertEquals('Month', 5, Lunar.Month);
  AssertEquals('Day', 5, Lunar.Day);
end;

procedure TTestCase_ChineseCalendar.Test_SolarToLunar_EndOfYear_ReturnsCorrect;
var
  Solar: TDate;
  Lunar: TChineseDate;
begin
  // 测试年末日期
  Solar := TDate.Create(2024, 12, 31);
  Lunar := SolarToLunar(Solar);
  // 2024年12月31日对应农历十二月初一
  AssertEquals('Year', 2024, Lunar.Year);
  AssertEquals('Month', 12, Lunar.Month);
end;

procedure TTestCase_ChineseCalendar.Test_SolarToLunar_BeforeSpringFestival_ReturnsPreviousYear;
var
  Solar: TDate;
  Lunar: TChineseDate;
begin
  // 2024年1月1日在春节之前，仍属于农历2023年
  Solar := TDate.Create(2024, 1, 1);
  Lunar := SolarToLunar(Solar);
  AssertEquals('Year should be 2023', 2023, Lunar.Year);
  AssertEquals('Month should be 11', 11, Lunar.Month);
end;

// ═══════════════════════════════════════════════════════════════
// 农历转公历测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChineseCalendar.Test_LunarToSolar_FirstDayOfYear_ReturnsSpringFestival;
var
  Lunar: TChineseDate;
  Solar: TDate;
begin
  // 农历2024年正月初一应该是2024年春节
  Lunar := TChineseDate.Create(2024, 1, 1, False);
  Solar := LunarToSolar(Lunar);
  AssertEquals('Year', 2024, Solar.GetYear);
  AssertEquals('Month', 2, Solar.GetMonth);
  AssertEquals('Day', 10, Solar.GetDay);
end;

procedure TTestCase_ChineseCalendar.Test_LunarToSolar_MidAutumn_ReturnsCorrect;
var
  Lunar: TChineseDate;
  Solar: TDate;
begin
  // 农历八月十五是中秋节
  Lunar := TChineseDate.Create(2024, 8, 15, False);
  Solar := LunarToSolar(Lunar);
  // 2024年中秋节是9月17日
  AssertEquals('Year', 2024, Solar.GetYear);
  AssertEquals('Month', 9, Solar.GetMonth);
  AssertEquals('Day', 17, Solar.GetDay);
end;

procedure TTestCase_ChineseCalendar.Test_LunarToSolar_RoundTrip_Success;
var
  OriginalSolar, ResultSolar: TDate;
  Lunar: TChineseDate;
begin
  // 测试公历->农历->公历的往返转换
  OriginalSolar := TDate.Create(2024, 6, 15);
  Lunar := SolarToLunar(OriginalSolar);
  ResultSolar := LunarToSolar(Lunar);
  AssertEquals('Year', OriginalSolar.GetYear, ResultSolar.GetYear);
  AssertEquals('Month', OriginalSolar.GetMonth, ResultSolar.GetMonth);
  AssertEquals('Day', OriginalSolar.GetDay, ResultSolar.GetDay);
end;

// ═══════════════════════════════════════════════════════════════
// 传统节日测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChineseCalendar.Test_GetSpringFestival_2024_ReturnsCorrect;
var
  D: TDate;
begin
  D := GetSpringFestival(2024);
  AssertEquals('Year', 2024, D.GetYear);
  AssertEquals('Month', 2, D.GetMonth);
  AssertEquals('Day', 10, D.GetDay);
end;

procedure TTestCase_ChineseCalendar.Test_GetSpringFestival_2025_ReturnsCorrect;
var
  D: TDate;
begin
  D := GetSpringFestival(2025);
  AssertEquals('Year', 2025, D.GetYear);
  AssertEquals('Month', 1, D.GetMonth);
  AssertEquals('Day', 29, D.GetDay);
end;

procedure TTestCase_ChineseCalendar.Test_GetMidAutumnFestival_2024_ReturnsCorrect;
var
  D: TDate;
begin
  D := GetMidAutumnFestival(2024);
  AssertEquals('Year', 2024, D.GetYear);
  AssertEquals('Month', 9, D.GetMonth);
  AssertEquals('Day', 17, D.GetDay);
end;

procedure TTestCase_ChineseCalendar.Test_GetDragonBoatFestival_2024_ReturnsCorrect;
var
  D: TDate;
begin
  D := GetDragonBoatFestival(2024);
  AssertEquals('Year', 2024, D.GetYear);
  AssertEquals('Month', 6, D.GetMonth);
  AssertEquals('Day', 10, D.GetDay);
end;

// ═══════════════════════════════════════════════════════════════
// 天干地支测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChineseCalendar.Test_GetYearGanZhi_2024_ReturnsJiaChen;
begin
  AssertEquals('2024 is 甲辰', '甲辰', GetYearGanZhi(2024));
end;

procedure TTestCase_ChineseCalendar.Test_GetYearGanZhi_2023_ReturnsGuiMao;
begin
  AssertEquals('2023 is 癸卯', '癸卯', GetYearGanZhi(2023));
end;

procedure TTestCase_ChineseCalendar.Test_GetYearGanZhi_1984_ReturnsJiaZi;
begin
  // 1984年是甲子年（60年一轮的起点）
  AssertEquals('1984 is 甲子', '甲子', GetYearGanZhi(1984));
end;

// ═══════════════════════════════════════════════════════════════
// 生肖测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_ChineseCalendar.Test_GetZodiac_2024_ReturnsDragon;
begin
  AssertEquals('2024 is Dragon', '龙', GetZodiac(2024));
end;

procedure TTestCase_ChineseCalendar.Test_GetZodiac_2023_ReturnsRabbit;
begin
  AssertEquals('2023 is Rabbit', '兔', GetZodiac(2023));
end;

procedure TTestCase_ChineseCalendar.Test_GetZodiac_2025_ReturnsSnake;
begin
  AssertEquals('2025 is Snake', '蛇', GetZodiac(2025));
end;

procedure TTestCase_ChineseCalendar.Test_GetZodiac_AllAnimals_Cycle;
const
  ExpectedZodiacs: array[0..11] of string = (
    '鼠', '牛', '虎', '兔', '龙', '蛇', 
    '马', '羊', '猴', '鸡', '狗', '猪'
  );
var
  BaseYear, I: Integer;
begin
  // 2020年是鼠年，验证12年周期
  BaseYear := 2020;
  for I := 0 to 11 do
    AssertEquals(IntToStr(BaseYear + I) + ' should be ' + ExpectedZodiacs[I],
      ExpectedZodiacs[I], GetZodiac(BaseYear + I));
end;

initialization
  RegisterTest(TTestCase_ChineseCalendar);

end.
