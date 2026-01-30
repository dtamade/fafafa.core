unit fafafa.core.time.locale.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.locale,
  fafafa.core.time.strftime;

type
  TTestCase_Locale = class(TTestCase)
  published
    // TLocale 基础测试
    procedure Test_English_WeekdayNames;
    procedure Test_English_MonthNames;
    procedure Test_Chinese_WeekdayNames;
    procedure Test_Chinese_MonthNames;
    procedure Test_Japanese_WeekdayNames;
    procedure Test_Japanese_MonthNames;
    
    // strftime with locale
    procedure Test_Strftime_English_Weekday;
    procedure Test_Strftime_Chinese_Weekday;
    procedure Test_Strftime_Japanese_Weekday;
    procedure Test_Strftime_English_Month;
    procedure Test_Strftime_Chinese_Month;
    procedure Test_Strftime_Japanese_Month;
    procedure Test_Strftime_Chinese_AMPM;
    procedure Test_Strftime_Japanese_AMPM;
    
    // strptime with locale
    procedure Test_Strptime_Chinese_Weekday;
    procedure Test_Strptime_Chinese_Month;
    procedure Test_Strptime_Japanese_Month;
    
    // More locales
    procedure Test_Korean_WeekdayNames;
    procedure Test_German_MonthNames;
    procedure Test_French_Weekday;
    procedure Test_Spanish_Month;
    procedure Test_Russian_Weekday;
    procedure Test_TraditionalChinese;
  end;

implementation

{ TTestCase_Locale }

procedure TTestCase_Locale.Test_English_WeekdayNames;
begin
  AssertEquals('Sunday', LOCALE_EN.WeekdayNames[1]);
  AssertEquals('Monday', LOCALE_EN.WeekdayNames[2]);
  AssertEquals('Saturday', LOCALE_EN.WeekdayNames[7]);
  AssertEquals('Sun', LOCALE_EN.WeekdayAbbrs[1]);
  AssertEquals('Mon', LOCALE_EN.WeekdayAbbrs[2]);
end;

procedure TTestCase_Locale.Test_English_MonthNames;
begin
  AssertEquals('January', LOCALE_EN.MonthNames[1]);
  AssertEquals('December', LOCALE_EN.MonthNames[12]);
  AssertEquals('Jan', LOCALE_EN.MonthAbbrs[1]);
  AssertEquals('Dec', LOCALE_EN.MonthAbbrs[12]);
end;

procedure TTestCase_Locale.Test_Chinese_WeekdayNames;
begin
  AssertEquals('星期日', LOCALE_ZH_CN.WeekdayNames[1]);
  AssertEquals('星期一', LOCALE_ZH_CN.WeekdayNames[2]);
  AssertEquals('星期六', LOCALE_ZH_CN.WeekdayNames[7]);
  AssertEquals('日', LOCALE_ZH_CN.WeekdayAbbrs[1]);
  AssertEquals('一', LOCALE_ZH_CN.WeekdayAbbrs[2]);
end;

procedure TTestCase_Locale.Test_Chinese_MonthNames;
begin
  AssertEquals('一月', LOCALE_ZH_CN.MonthNames[1]);
  AssertEquals('十二月', LOCALE_ZH_CN.MonthNames[12]);
  AssertEquals('1月', LOCALE_ZH_CN.MonthAbbrs[1]);
  AssertEquals('12月', LOCALE_ZH_CN.MonthAbbrs[12]);
end;

procedure TTestCase_Locale.Test_Japanese_WeekdayNames;
begin
  AssertEquals('日曜日', LOCALE_JA.WeekdayNames[1]);
  AssertEquals('月曜日', LOCALE_JA.WeekdayNames[2]);
  AssertEquals('土曜日', LOCALE_JA.WeekdayNames[7]);
  AssertEquals('日', LOCALE_JA.WeekdayAbbrs[1]);
  AssertEquals('月', LOCALE_JA.WeekdayAbbrs[2]);
end;

procedure TTestCase_Locale.Test_Japanese_MonthNames;
begin
  AssertEquals('1月', LOCALE_JA.MonthNames[1]);
  AssertEquals('12月', LOCALE_JA.MonthNames[12]);
  // 日语月份没有缩写，使用相同值
  AssertEquals('1月', LOCALE_JA.MonthAbbrs[1]);
end;

// strftime with locale tests

procedure TTestCase_Locale.Test_Strftime_English_Weekday;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);  // Tuesday
  AssertEquals('Tuesday', StrftimeDateLocale(D, '%A', LOCALE_EN));
  AssertEquals('Tue', StrftimeDateLocale(D, '%a', LOCALE_EN));
end;

procedure TTestCase_Locale.Test_Strftime_Chinese_Weekday;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);  // Tuesday = 星期二
  AssertEquals('星期二', StrftimeDateLocale(D, '%A', LOCALE_ZH_CN));
  AssertEquals('二', StrftimeDateLocale(D, '%a', LOCALE_ZH_CN));
end;

procedure TTestCase_Locale.Test_Strftime_Japanese_Weekday;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);  // Tuesday = 火曜日
  AssertEquals('火曜日', StrftimeDateLocale(D, '%A', LOCALE_JA));
  AssertEquals('火', StrftimeDateLocale(D, '%a', LOCALE_JA));
end;

procedure TTestCase_Locale.Test_Strftime_English_Month;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);
  AssertEquals('December', StrftimeDateLocale(D, '%B', LOCALE_EN));
  AssertEquals('Dec', StrftimeDateLocale(D, '%b', LOCALE_EN));
end;

procedure TTestCase_Locale.Test_Strftime_Chinese_Month;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);
  AssertEquals('十二月', StrftimeDateLocale(D, '%B', LOCALE_ZH_CN));
  AssertEquals('12月', StrftimeDateLocale(D, '%b', LOCALE_ZH_CN));
end;

procedure TTestCase_Locale.Test_Strftime_Japanese_Month;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);
  AssertEquals('12月', StrftimeDateLocale(D, '%B', LOCALE_JA));
end;

procedure TTestCase_Locale.Test_Strftime_Chinese_AMPM;
var
  T1, T2: TTimeOfDay;
begin
  T1 := TTimeOfDay.Create(9, 30, 0);   // 上午
  T2 := TTimeOfDay.Create(15, 30, 0);  // 下午
  AssertEquals('上午', StrftimeTimeLocale(T1, '%p', LOCALE_ZH_CN));
  AssertEquals('下午', StrftimeTimeLocale(T2, '%p', LOCALE_ZH_CN));
end;

procedure TTestCase_Locale.Test_Strftime_Japanese_AMPM;
var
  T1, T2: TTimeOfDay;
begin
  T1 := TTimeOfDay.Create(9, 30, 0);   // 午前
  T2 := TTimeOfDay.Create(15, 30, 0);  // 午後
  AssertEquals('午前', StrftimeTimeLocale(T1, '%p', LOCALE_JA));
  AssertEquals('午後', StrftimeTimeLocale(T2, '%p', LOCALE_JA));
end;

// strptime with locale tests

procedure TTestCase_Locale.Test_Strptime_Chinese_Weekday;
var
  D: TDate;
begin
  // 解析中文星期 (作为验证，不影响日期值)
  AssertTrue(StrptimeDateLocale('2024年12月03日 星期二', '%Y年%m月%d日 %A', D, LOCALE_ZH_CN));
  AssertEquals(2024, D.GetYear);
  AssertEquals(12, D.GetMonth);
  AssertEquals(3, D.GetDay);
end;

procedure TTestCase_Locale.Test_Strptime_Chinese_Month;
var
  D: TDate;
begin
  AssertTrue(StrptimeDateLocale('2024年十二月03日', '%Y年%B%d日', D, LOCALE_ZH_CN));
  AssertEquals(2024, D.GetYear);
  AssertEquals(12, D.GetMonth);
  AssertEquals(3, D.GetDay);
end;

procedure TTestCase_Locale.Test_Strptime_Japanese_Month;
var
  D: TDate;
begin
  AssertTrue(StrptimeDateLocale('2024年12月03日', '%Y年%B%d日', D, LOCALE_JA));
  AssertEquals(2024, D.GetYear);
  AssertEquals(12, D.GetMonth);
  AssertEquals(3, D.GetDay);
end;

// More locale tests

procedure TTestCase_Locale.Test_Korean_WeekdayNames;
var
  D: TDate;
begin
  AssertEquals('일요일', LOCALE_KO.WeekdayNames[1]);
  AssertEquals('월요일', LOCALE_KO.WeekdayNames[2]);
  D := TDate.Create(2024, 12, 3);  // Tuesday = 화요일
  AssertEquals('화요일', StrftimeDateLocale(D, '%A', LOCALE_KO));
end;

procedure TTestCase_Locale.Test_German_MonthNames;
var
  D: TDate;
begin
  AssertEquals('Januar', LOCALE_DE.MonthNames[1]);
  AssertEquals('März', LOCALE_DE.MonthNames[3]);
  D := TDate.Create(2024, 12, 3);
  AssertEquals('Dezember', StrftimeDateLocale(D, '%B', LOCALE_DE));
end;

procedure TTestCase_Locale.Test_French_Weekday;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);  // Tuesday = mardi
  AssertEquals('mardi', StrftimeDateLocale(D, '%A', LOCALE_FR));
  AssertEquals('mar.', StrftimeDateLocale(D, '%a', LOCALE_FR));
end;

procedure TTestCase_Locale.Test_Spanish_Month;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);
  AssertEquals('diciembre', StrftimeDateLocale(D, '%B', LOCALE_ES));
  AssertEquals('dic.', StrftimeDateLocale(D, '%b', LOCALE_ES));
end;

procedure TTestCase_Locale.Test_Russian_Weekday;
var
  D: TDate;
begin
  D := TDate.Create(2024, 12, 3);  // Tuesday = вторник
  AssertEquals('вторник', StrftimeDateLocale(D, '%A', LOCALE_RU));
  AssertEquals('вт', StrftimeDateLocale(D, '%a', LOCALE_RU));
end;

procedure TTestCase_Locale.Test_TraditionalChinese;
var
  D: TDate;
  T: TTimeOfDay;
begin
  D := TDate.Create(2024, 12, 3);
  AssertEquals('星期二', StrftimeDateLocale(D, '%A', LOCALE_ZH_TW));
  AssertEquals('十二月', StrftimeDateLocale(D, '%B', LOCALE_ZH_TW));
  
  T := TTimeOfDay.Create(9, 0, 0);
  AssertEquals('上午', StrftimeTimeLocale(T, '%p', LOCALE_ZH_TW));
end;

initialization
  RegisterTest(TTestCase_Locale);

end.
