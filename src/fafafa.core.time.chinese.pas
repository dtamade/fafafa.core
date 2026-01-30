{
  fafafa.core.time.chinese - 中国农历支持
  
  提供公历与农历转换、传统节日计算、天干地支、生肖等功能。
  
  农历数据覆盖范围: 1900-2100年
}
unit fafafa.core.time.chinese;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, fafafa.core.time.date;

type
  { TChineseDate - 农历日期 }
  TChineseDate = record
  private
    FYear: Integer;
    FMonth: Integer;
    FDay: Integer;
    FIsLeapMonth: Boolean;
  public
    property Year: Integer read FYear;
    property Month: Integer read FMonth;
    property Day: Integer read FDay;
    property IsLeapMonth: Boolean read FIsLeapMonth;
    
    class function Create(AYear, AMonth, ADay: Integer; AIsLeapMonth: Boolean = False): TChineseDate; static;
  end;

{ 公历转农历 }
function SolarToLunar(const ASolarDate: TDate): TChineseDate;

{ 农历转公历 }
function LunarToSolar(const ALunarDate: TChineseDate): TDate;

{ 获取指定年份的春节公历日期 }
function GetSpringFestival(AYear: Integer): TDate;

{ 获取指定年份的中秋节公历日期 }
function GetMidAutumnFestival(AYear: Integer): TDate;

{ 获取指定年份的端午节公历日期 }
function GetDragonBoatFestival(AYear: Integer): TDate;

{ 获取农历年的天干地支 (如: 甲辰) }
function GetYearGanZhi(AYear: Integer): string;

{ 获取农历年的生肖 }
function GetZodiac(AYear: Integer): string;

implementation

const
  { 天干 }
  Gan: array[0..9] of string = ('甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸');
  
  { 地支 }
  Zhi: array[0..11] of string = ('子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥');
  
  { 生肖 }
  Zodiac: array[0..11] of string = ('鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪');

  { 
    农历数据表 (1900-2100)
    每个元素为 24 位数据:
    - 低 4 位: 闰月月份 (0 表示无闰月)
    - 第 5-16 位: 每月大小 (1=大月30天, 0=小月29天), 从正月到十二月
    - 第 17-20 位: 闰月大小 (如果有闰月)
    
    数据格式: $XLMMMM
    X: 闰月大小 (1=30天, 0=29天)
    L: 闰月月份 (1-12, 0表示无闰月)  
    MMMM: 12个月的大小月信息
  }
  LunarData: array[0..200] of Cardinal = (
    // 1900-1909
    $04bd8, $04ae0, $0a570, $054d5, $0d260, $0d950, $16554, $056a0, $09ad0, $055d2,
    // 1910-1919
    $04ae0, $0a5b6, $0a4d0, $0d250, $1d255, $0b540, $0d6a0, $0ada2, $095b0, $14977,
    // 1920-1929
    $04970, $0a4b0, $0b4b5, $06a50, $06d40, $1ab54, $02b60, $09570, $052f2, $04970,
    // 1930-1939
    $06566, $0d4a0, $0ea50, $16a95, $05ad0, $02b60, $186e3, $092e0, $1c8d7, $0c950,
    // 1940-1949
    $0d4a0, $1d8a6, $0b550, $056a0, $1a5b4, $025d0, $092d0, $0d2b2, $0a950, $0b557,
    // 1950-1959
    $06ca0, $0b550, $15355, $04da0, $0a5b0, $14573, $052b0, $0a9a8, $0e950, $06aa0,
    // 1960-1969
    $0aea6, $0ab50, $04b60, $0aae4, $0a570, $05260, $0f263, $0d950, $05b57, $056a0,
    // 1970-1979
    $096d0, $04dd5, $04ad0, $0a4d0, $0d4d4, $0d250, $0d558, $0b540, $0b6a0, $195a6,
    // 1980-1989
    $095b0, $049b0, $0a974, $0a4b0, $0b27a, $06a50, $06d40, $0af46, $0ab60, $09570,
    // 1990-1999
    $04af5, $04970, $064b0, $074a3, $0ea50, $06b58, $05ac0, $0ab60, $096d5, $092e0,
    // 2000-2009
    $0c960, $0d954, $0d4a0, $0da50, $07552, $056a0, $0abb7, $025d0, $092d0, $0cab5,
    // 2010-2019
    $0a950, $0b4a0, $0baa4, $0ad50, $055d9, $04ba0, $0a5b0, $15176, $052b0, $0a930,
    // 2020-2029
    $07954, $06aa0, $0ad50, $05b52, $04b60, $0a6e6, $0a4e0, $0d260, $0ea65, $0d530,
    // 2030-2039
    $05aa0, $076a3, $096d0, $04afb, $04ad0, $0a4d0, $1d0b6, $0d250, $0d520, $0dd45,
    // 2040-2049
    $0b5a0, $056d0, $055b2, $049b0, $0a577, $0a4b0, $0aa50, $1b255, $06d20, $0ada0,
    // 2050-2059
    $14b63, $09370, $049f8, $04970, $064b0, $168a6, $0ea50, $06aa0, $1a6c4, $0aae0,
    // 2060-2069
    $092e0, $0d2e3, $0c960, $0d557, $0d4a0, $0da50, $05d55, $056a0, $0a6d0, $055d4,
    // 2070-2079
    $052d0, $0a9b8, $0a950, $0b4a0, $0b6a6, $0ad50, $055a0, $0aba4, $0a5b0, $052b0,
    // 2080-2089
    $0b273, $06930, $07337, $06aa0, $0ad50, $14b55, $04b60, $0a570, $054e4, $0d160,
    // 2090-2099
    $0e968, $0d520, $0daa0, $16aa6, $056d0, $04ae0, $0a9d4, $0a2d0, $0d150, $0f252,
    // 2100
    $0d520
  );

  { 农历1900年正月初一对应的公历日期 (1900-01-31) 的儒略日 }
  LunarBaseJD = 2415051;
  
  { 基准年 }
  BaseYear = 1900;

{ 计算指定年份的闰月月份 (0表示无闰月) }
function GetLeapMonth(AYear: Integer): Integer;
var
  Idx: Integer;
begin
  Idx := AYear - BaseYear;
  if (Idx < 0) or (Idx > High(LunarData)) then
    Result := 0
  else
    Result := LunarData[Idx] and $F;
end;

{ 计算指定农历年份的总天数 }
function GetLunarYearDays(AYear: Integer): Integer;
var
  Idx, LeapMonth: Integer;
  Data, Mask: Cardinal;
begin
  Idx := AYear - BaseYear;
  if (Idx < 0) or (Idx > High(LunarData)) then
    Exit(0);
    
  Data := LunarData[Idx];
  LeapMonth := Data and $F;
  Result := 348; // 12个月×29天 = 348天基础
  
  // 检查每个月是否为大月(30天)
  // bit 15-4 对应1-12月，bit=1表示大月(+1天)
  Mask := $8000;
  while Mask > $8 do
  begin
    if (Data and Mask) <> 0 then
      Inc(Result);
    Mask := Mask shr 1;
  end;
  
  // 加上闰月天数
  if LeapMonth > 0 then
  begin
    if (Data and $10000) <> 0 then
      Inc(Result, 30)
    else
      Inc(Result, 29);
  end;
end;

{ 计算指定农历月份的天数 }
function GetLunarMonthDays(AYear, AMonth: Integer; AIsLeapMonth: Boolean): Integer;
var
  Idx: Integer;
  Data: Cardinal;
  LeapMonth: Integer;
begin
  Idx := AYear - BaseYear;
  if (Idx < 0) or (Idx > High(LunarData)) then
    Exit(0);
    
  Data := LunarData[Idx];
  LeapMonth := Data and $F;
  
  if AIsLeapMonth then
  begin
    // 闰月大小由 bit 16 决定
    if LeapMonth <> AMonth then
      Exit(0); // 该年没有这个闰月
    if (Data and $10000) <> 0 then
      Result := 30
    else
      Result := 29;
  end
  else
  begin
    // 普通月份: bit 15=1月, bit 14=2月, ... bit 4=12月
    // 即 $8000 shr (AMonth-1)
    if (Data and ($8000 shr (AMonth - 1))) <> 0 then
      Result := 30
    else
      Result := 29;
  end;
end;

{ 计算公历日期的儒略日 - Fliegel & van Flandern algorithm }
function DateToJD(const ADate: TDate): Integer;
var
  Y, M, D: Integer;
begin
  Y := ADate.GetYear;
  M := ADate.GetMonth;
  D := ADate.GetDay;
  
  Result := (1461 * (Y + 4800 + (M - 14) div 12)) div 4 +
            (367 * (M - 2 - 12 * ((M - 14) div 12))) div 12 -
            (3 * ((Y + 4900 + (M - 14) div 12) div 100)) div 4 +
            D - 32075;
end;

{ 儒略日转公历日期 - Fliegel & van Flandern algorithm }
function JDToDate(AJD: Integer): TDate;
var
  L, N, I, J, K: Integer;
  Day, Month, Year: Integer;
begin
  L := AJD + 68569;
  N := (4 * L) div 146097;
  L := L - (146097 * N + 3) div 4;
  I := (4000 * (L + 1)) div 1461001;
  L := L - (1461 * I) div 4 + 31;
  J := (80 * L) div 2447;
  K := L - (2447 * J) div 80;
  L := J div 11;
  J := J + 2 - 12 * L;
  I := 100 * (N - 49) + I + L;
  
  Year := I;
  Month := J;
  Day := K;
  
  Result := TDate.Create(Year, Month, Day);
end;

{ 获取指定农历年正月初一的儒略日 }
function GetLunarNewYearJD(AYear: Integer): Integer;
var
  I: Integer;
begin
  Result := LunarBaseJD; // 1900年正月初一
  for I := BaseYear to AYear - 1 do
    Inc(Result, GetLunarYearDays(I));
end;

class function TChineseDate.Create(AYear, AMonth, ADay: Integer; AIsLeapMonth: Boolean): TChineseDate;
begin
  Result.FYear := AYear;
  Result.FMonth := AMonth;
  Result.FDay := ADay;
  Result.FIsLeapMonth := AIsLeapMonth;
end;

function SolarToLunar(const ASolarDate: TDate): TChineseDate;
var
  JD, LunarNewYearJD: Integer;
  Year, Month, Day, Offset: Integer;
  LeapMonth, MonthDays: Integer;
  IsLeapMonth: Boolean;
begin
  JD := DateToJD(ASolarDate);
  
  // 找到对应的农历年
  Year := ASolarDate.GetYear;
  if ASolarDate.GetMonth < 2 then
    Dec(Year); // 春节前属于上一年
    
  // 调整到正确的年份
  LunarNewYearJD := GetLunarNewYearJD(Year);
  while JD < LunarNewYearJD do
  begin
    Dec(Year);
    LunarNewYearJD := GetLunarNewYearJD(Year);
  end;
  
  while JD >= GetLunarNewYearJD(Year + 1) do
  begin
    Inc(Year);
    LunarNewYearJD := GetLunarNewYearJD(Year);
  end;
  
  Offset := JD - LunarNewYearJD;
  LeapMonth := GetLeapMonth(Year);
  
  // 逐月累计找到对应的月份
  Month := 1;
  IsLeapMonth := False;
  
  while Offset >= 0 do
  begin
    MonthDays := GetLunarMonthDays(Year, Month, False);
    if Offset < MonthDays then
      Break;
    Dec(Offset, MonthDays);
    
    // 检查闰月
    if (LeapMonth = Month) and not IsLeapMonth then
    begin
      MonthDays := GetLunarMonthDays(Year, Month, True);
      if Offset < MonthDays then
      begin
        IsLeapMonth := True;
        Break;
      end;
      Dec(Offset, MonthDays);
    end;
    
    Inc(Month);
  end;
  
  Day := Offset + 1;
  
  Result := TChineseDate.Create(Year, Month, Day, IsLeapMonth);
end;

function LunarToSolar(const ALunarDate: TChineseDate): TDate;
var
  JD, I: Integer;
  LeapMonth: Integer;
begin
  JD := GetLunarNewYearJD(ALunarDate.Year);
  LeapMonth := GetLeapMonth(ALunarDate.Year);
  
  // 累加月份天数
  for I := 1 to ALunarDate.Month - 1 do
  begin
    Inc(JD, GetLunarMonthDays(ALunarDate.Year, I, False));
    // 如果经过了闰月，加上闰月天数
    if LeapMonth = I then
      Inc(JD, GetLunarMonthDays(ALunarDate.Year, I, True));
  end;
  
  // 如果是闰月，先加上该月的普通月天数
  if ALunarDate.IsLeapMonth then
    Inc(JD, GetLunarMonthDays(ALunarDate.Year, ALunarDate.Month, False));
  
  // 加上日期偏移
  Inc(JD, ALunarDate.Day - 1);
  
  Result := JDToDate(JD);
end;

function GetSpringFestival(AYear: Integer): TDate;
var
  Lunar: TChineseDate;
begin
  Lunar := TChineseDate.Create(AYear, 1, 1, False);
  Result := LunarToSolar(Lunar);
end;

function GetMidAutumnFestival(AYear: Integer): TDate;
var
  Lunar: TChineseDate;
begin
  Lunar := TChineseDate.Create(AYear, 8, 15, False);
  Result := LunarToSolar(Lunar);
end;

function GetDragonBoatFestival(AYear: Integer): TDate;
var
  Lunar: TChineseDate;
begin
  Lunar := TChineseDate.Create(AYear, 5, 5, False);
  Result := LunarToSolar(Lunar);
end;

function GetYearGanZhi(AYear: Integer): string;
var
  GanIdx, ZhiIdx: Integer;
begin
  // 以1984年(甲子年)为基准
  GanIdx := (AYear - 4) mod 10;
  if GanIdx < 0 then Inc(GanIdx, 10);
  
  ZhiIdx := (AYear - 4) mod 12;
  if ZhiIdx < 0 then Inc(ZhiIdx, 12);
  
  Result := Gan[GanIdx] + Zhi[ZhiIdx];
end;

function GetZodiac(AYear: Integer): string;
var
  Idx: Integer;
begin
  Idx := (AYear - 4) mod 12;
  if Idx < 0 then Inc(Idx, 12);
  Result := Zodiac[Idx];
end;

end.
