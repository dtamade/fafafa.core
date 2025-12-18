unit fafafa.core.time.date;


{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.date - 日期类型和操作

📖 概述：
  提供现代化的日期类型和相关操作，支持日期算术、比较、格式化等功能。
  基于公历系统，提供高精度和类型安全的日期处理。

🔧 特性：
  • 类型安全的日期表示
  • 丰富的日期算术运算
  • 日期比较和排序
  • 日期范围和区间
  • 与标准 TDateTime 的互操作

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  StrUtils,
  fafafa.core.time.base;

type
  {**
   * TDate - 日期类型
   *
   * @desc
   *   表示公历日期的记录类型，提供类型安全的日期操作。
   *   内部使用 Julian Day Number 存储，确保计算的准确性。
   *
   * @precision
   *   日级精度，不包含时间信息。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *
   * @range
   *   支持公元前 4713 年到公元后 3268 年的日期范围。
   *}
  TDate = record
  private
    FJulianDay: Integer; // Julian Day Number
    
    class function IsValidDate(AYear, AMonth, ADay: Integer): Boolean; static;
    class function DateToJulianDay(AYear, AMonth, ADay: Integer): Integer; static;
    class procedure JulianDayToDate(AJulianDay: Integer; out AYear, AMonth, ADay: Integer); static;
  public
    // 构造函数
    class function Create(AYear, AMonth, ADay: Integer): TDate; static;
    class function FromJulianDay(AJulianDay: Integer): TDate; static;
    class function FromDateTime(const ADateTime: TDateTime): TDate; static;
    class function FromUnixDays(AUnixDays: Integer): TDate; static; // 自 1970-01-01 的天数
    class function Today: TDate; static;
    class function Yesterday: TDate; static;
    class function Tomorrow: TDate; static;
    
    // 安全构造函数
    class function TryCreate(AYear, AMonth, ADay: Integer; out ADate: TDate): Boolean; static;
    class function TryFromDateTime(const ADateTime: TDateTime; out ADate: TDate): Boolean; static;
    class function TryParse(const ADateStr: string; out ADate: TDate): Boolean; static;
    class function TryParseISO(const ADateStr: string; out ADate: TDate): Boolean; static;
    
    // 常量
    class function MinValue: TDate; static; // 最小日期
    class function MaxValue: TDate; static; // 最大日期
    class function Epoch: TDate; static; // Unix 纪元 (1970-01-01)
    
    // 转换函数
    function ToJulianDay: Integer; inline;
    function ToDateTime: TDateTime;
    function ToUnixDays: Integer; // 自 1970-01-01 的天数
    function ToISO8601: string; // YYYY-MM-DD 格式
    
    // 日期组件
    function GetYear: Integer;
    function GetMonth: Integer;
    function GetDay: Integer;
    function GetDayOfWeek: Integer; // 1=Sunday, 7=Saturday
    function GetDayOfYear: Integer;
    function GetWeekOfYear: Integer;
    function GetQuarter: Integer;
    
    // 日期算术
    function AddDays(ADays: Integer): TDate; inline;
    function AddWeeks(AWeeks: Integer): TDate; inline;
    function AddMonths(AMonths: Integer): TDate;
    function AddYears(AYears: Integer): TDate;
    function SubtractDays(ADays: Integer): TDate; inline;
    function SubtractWeeks(AWeeks: Integer): TDate; inline;
    function SubtractMonths(AMonths: Integer): TDate;
    function SubtractYears(AYears: Integer): TDate;
    
    // 日期差值
    function DaysBetween(const AOther: TDate): Integer; inline;
    function WeeksBetween(const AOther: TDate): Integer;
    function MonthsBetween(const AOther: TDate): Integer;
    function YearsBetween(const AOther: TDate): Integer;
    function DaysUntil(const AOther: TDate): Integer; inline; // 到另一个日期的天数
    function DaysSince(const AOther: TDate): Integer; inline; // 自另一个日期的天数
    
    // 比较操作
    function Compare(const AOther: TDate): Integer; inline;
    function Equal(const AOther: TDate): Boolean; inline; deprecated 'Use operator = instead';
    function LessThan(const AOther: TDate): Boolean; inline; deprecated 'Use operator < instead';
    function LessOrEqual(const AOther: TDate): Boolean; inline; deprecated 'Use operator <= instead';
    function GreaterThan(const AOther: TDate): Boolean; inline; deprecated 'Use operator > instead';
    function GreaterOrEqual(const AOther: TDate): Boolean; inline; deprecated 'Use operator >= instead';
    function IsBetween(const AStart, AEnd: TDate): Boolean; inline;
    
    // 工具函数
    function IsLeapYear: Boolean;
    function DaysInMonth: Integer;
    function DaysInYear: Integer;
    function IsWeekend: Boolean;
    function IsFirstDayOfMonth: Boolean; inline;
    function IsLastDayOfMonth: Boolean;
    function IsFirstDayOfYear: Boolean; inline;
    function IsLastDayOfYear: Boolean;
    
    // 日期范围
    function StartOfWeek: TDate; // 本周第一天（周日）
    function EndOfWeek: TDate; // 本周最后一天（周六）
    function StartOfMonth: TDate; // 本月第一天
    function EndOfMonth: TDate; // 本月最后一天
    function StartOfQuarter: TDate; // 本季度第一天
    function EndOfQuarter: TDate; // 本季度最后一天
    function StartOfYear: TDate; // 本年第一天
    function EndOfYear: TDate; // 本年最后一天
    
    // TemporalAdjusters - 时间调整器
    {** 返回下一个指定星期几的日期（不含当天） *}
    {** @param ADayOfWeek 1=周日, 2=周一, ..., 7=周六 *}
    function Next(ADayOfWeek: Integer): TDate;
    
    {** 返回上一个指定星期几的日期（不含当天） *}
    function Previous(ADayOfWeek: Integer): TDate;
    
    {** 如果当天是指定星期几则返回当天，否则返回下一个 *}
    function NextOrSame(ADayOfWeek: Integer): TDate;
    
    {** 如果当天是指定星期几则返回当天，否则返回上一个 *}
    function PreviousOrSame(ADayOfWeek: Integer): TDate;
    
    {** 返回本月第 N 个指定星期几的日期 *}
    {** @param AOrdinal 正数=第N个, -1=最后一个 *}
    {** @param ADayOfWeek 1=周日, 2=周一, ..., 7=周六 *}
    function DayOfWeekInMonth(AOrdinal: Integer; ADayOfWeek: Integer): TDate;
    
    // With* 修改器方法
    function WithYear(AYear: Integer): TDate;
    function WithMonth(AMonth: Integer): TDate;
    function WithDay(ADay: Integer): TDate;
    
    // TryWith* 安全版本
    function TryWithYear(AYear: Integer; out AResult: TDate): Boolean;
    function TryWithMonth(AMonth: Integer; out AResult: TDate): Boolean;
    function TryWithDay(ADay: Integer; out AResult: TDate): Boolean;
    
    // And* 组合方法在 fafafa.core.time.helpers 单元中提供
    // 使用 TDateHelper record helper
    
    // 工具方法
    function Clamp(const AMin, AMax: TDate): TDate; inline;
    class function Min(const A, B: TDate): TDate; static; inline;
    class function Max(const A, B: TDate): TDate; static; inline;
    
    // 运算符重载
    class operator +(const ADate: TDate; ADays: Integer): TDate; inline;
    class operator -(const ADate: TDate; ADays: Integer): TDate; inline;
    class operator -(const A, B: TDate): Integer; inline; // 返回天数差
    class operator =(const A, B: TDate): Boolean; inline;
    class operator <>(const A, B: TDate): Boolean; inline;
    class operator <(const A, B: TDate): Boolean; inline;
    class operator >(const A, B: TDate): Boolean; inline;
    class operator <=(const A, B: TDate): Boolean; inline;
    class operator >=(const A, B: TDate): Boolean; inline;
    
    // 字符串表示
    function ToString: string; overload;
    function ToString(const AFormat: string): string; overload;
    function ToShortString: string; // 简短格式
    function ToLongString: string; // 详细格式
  end;

  // 日期范围枚举器（避免对 TDateRange 的类型依赖，直接保存起止日期）
  TDateRangeEnumerator = record
  private
    FStart: TDate;
    FEnd: TDate;
    FCurrent: TDate;
    FStarted: Boolean;
  public
    constructor Create(const AStart, AEnd: TDate);
    function MoveNext: Boolean;
    function GetCurrent: TDate; inline;
    property Current: TDate read GetCurrent;
  end;

  {**
   * TDateRange - 日期范围
   *
   * @desc
   *   表示一个日期范围，包含开始日期和结束日期。
   *   提供范围相关的操作和查询功能。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *}
  TDateRange = record
  private
    FStartDate: TDate;
    FEndDate: TDate;
  public
    // 构造函数
    class function Create(const AStart, AEnd: TDate): TDateRange; static;
    class function CreateDays(const AStart: TDate; ADays: Integer): TDateRange; static;
    class function CreateWeeks(const AStart: TDate; AWeeks: Integer): TDateRange; static;
    class function CreateMonths(const AStart: TDate; AMonths: Integer): TDateRange; static;
    class function CreateYears(const AStart: TDate; AYears: Integer): TDateRange; static;
    
    // 属性
    function GetStartDate: TDate; inline;
    function GetEndDate: TDate; inline;
    function GetDuration: Integer; inline; // 天数
    
    // 查询操作
    function Contains(const ADate: TDate): Boolean; inline;
    function Overlaps(const AOther: TDateRange): Boolean;
    function IsEmpty: Boolean; inline;
    function IsValid: Boolean; inline;
    
    // 范围操作
    function Union(const AOther: TDateRange): TDateRange;
    function Intersection(const AOther: TDateRange): TDateRange;
    function Extend(ADays: Integer): TDateRange;
    function Shift(ADays: Integer): TDateRange;
    
    // 迭代支持
    function GetEnumerator: TDateRangeEnumerator;
    
    // 字符串表示
    function ToString: string;
  end;

// 便捷函数
function DateOf(AYear, AMonth, ADay: Integer): TDate; inline;
function Today: TDate; inline;
function Yesterday: TDate; inline;
function Tomorrow: TDate; inline;

// 日期解析
function ParseDate(const ADateStr: string): TDate;
function ParseDateISO(const ADateStr: string): TDate; // ISO 8601 格式
function TryParseDate(const ADateStr: string; out ADate: TDate): Boolean;
function TryParseDateISO(const ADateStr: string; out ADate: TDate): Boolean;

// 日期格式化
function FormatDate(const ADate: TDate; const AFormat: string): string;

// 日期常量
const
  JULIAN_DAY_EPOCH = 2440588; // 1970-01-01 的 Julian Day Number
  DAYS_PER_WEEK = 7;
  MONTHS_PER_YEAR = 12;
  QUARTERS_PER_YEAR = 4;

implementation

uses
  fafafa.core.math;

const
  // 每月天数（非闰年）
  DAYS_IN_MONTH: array[1..12] of Integer = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

function IsLeapYearI(AYear: Integer): Boolean; inline;
begin
  Result := (AYear mod 4 = 0) and ((AYear mod 100 <> 0) or (AYear mod 400 = 0));
end;

{ TDate }

class function TDate.IsValidDate(AYear, AMonth, ADay: Integer): Boolean;
begin
  Result := (AYear >= 1) and (AYear <= 9999) and
            (AMonth >= 1) and (AMonth <= 12) and
            (ADay >= 1);
  
  if Result then
  begin
    if AMonth = 2 then
    begin
      if IsLeapYearI(AYear) then
        Result := ADay <= 29
      else
        Result := ADay <= 28;
    end
    else
      Result := ADay <= DAYS_IN_MONTH[AMonth];
  end;
end;

class function TDate.DateToJulianDay(AYear, AMonth, ADay: Integer): Integer;
var
  a, y, m: Integer;
begin
  // 使用标准的 Julian Day Number 算法
  a := (14 - AMonth) div 12;
  y := AYear + 4800 - a;
  m := AMonth + 12 * a - 3;
  
  Result := ADay + (153 * m + 2) div 5 + 365 * y + y div 4 - y div 100 + y div 400 - 32045;
end;

class procedure TDate.JulianDayToDate(AJulianDay: Integer; out AYear, AMonth, ADay: Integer);
var
  a, b, c, d, e, m: Integer;
begin
  // 使用标准的 Julian Day Number 逆算法
  a := AJulianDay + 32044;
  b := (4 * a + 3) div 146097;
  c := a - (146097 * b) div 4;
  d := (4 * c + 3) div 1461;
  e := c - (1461 * d) div 4;
  m := (5 * e + 2) div 153;
  
  ADay := e - (153 * m + 2) div 5 + 1;
  AMonth := m + 3 - 12 * (m div 10);
  AYear := 100 * b + d - 4800 + m div 10;
end;

class function TDate.Create(AYear, AMonth, ADay: Integer): TDate;
begin
  if not IsValidDate(AYear, AMonth, ADay) then
    raise ETimeError.CreateFmt('Invalid date: %d-%d-%d', [AYear, AMonth, ADay]);
  
  Result.FJulianDay := DateToJulianDay(AYear, AMonth, ADay);
end;

class function TDate.FromJulianDay(AJulianDay: Integer): TDate;
begin
  Result.FJulianDay := AJulianDay;
end;

class function TDate.FromDateTime(const ADateTime: TDateTime): TDate;
var
  year, month, day: Word;
begin
  DecodeDate(ADateTime, year, month, day);
  Result := Create(year, month, day);
end;

class function TDate.FromUnixDays(AUnixDays: Integer): TDate;
begin
  Result.FJulianDay := JULIAN_DAY_EPOCH + AUnixDays;
end;

class function TDate.Today: TDate;
begin
  Result := FromDateTime(Date);
end;

class function TDate.Yesterday: TDate;
begin
  Result := Today.AddDays(-1);
end;

class function TDate.Tomorrow: TDate;
begin
  Result := Today.AddDays(1);
end;

class function TDate.TryCreate(AYear, AMonth, ADay: Integer; out ADate: TDate): Boolean;
begin
  Result := IsValidDate(AYear, AMonth, ADay);
  if Result then
    ADate.FJulianDay := DateToJulianDay(AYear, AMonth, ADay);
end;

class function TDate.TryFromDateTime(const ADateTime: TDateTime; out ADate: TDate): Boolean;
var
  year, month, day: Word;
begin
  try
    DecodeDate(ADateTime, year, month, day);
    Result := TryCreate(year, month, day, ADate);
  except
    Result := False;
  end;
end;

class function TDate.MinValue: TDate;
begin
  Result := Create(1, 1, 1);
end;

class function TDate.MaxValue: TDate;
begin
  Result := Create(9999, 12, 31);
end;

class function TDate.Epoch: TDate;
begin
  Result := Create(1970, 1, 1);
end;

function TDate.ToJulianDay: Integer;
begin
  Result := FJulianDay;
end;

function TDate.ToDateTime: TDateTime;
var
  year, month, day: Integer;
begin
  JulianDayToDate(FJulianDay, year, month, day);
  Result := EncodeDate(year, month, day);
end;

function TDate.ToUnixDays: Integer;
begin
  Result := FJulianDay - JULIAN_DAY_EPOCH;
end;

function TDate.ToISO8601: string;
var
  year, month, day: Integer;
begin
  JulianDayToDate(FJulianDay, year, month, day);
  Result := Format('%.4d-%.2d-%.2d', [year, month, day]);
end;

function TDate.GetWeekOfYear: Integer;
var
  doy: Integer;
begin
  // 简单规则：每7天为一周，从年第一天开始
  doy := GetDayOfYear;
  Result := ((doy - 1) div 7) + 1;
end;

function TDate.GetQuarter: Integer;
var
  m: Integer;
begin
  m := GetMonth;
  Result := ((m - 1) div 3) + 1;
end;

function TDate.DaysInMonth: Integer;
var
  y, m, d: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  if m = 2 then
  begin
    if IsLeapYearI(y) then Result := 29 else Result := 28;
  end
  else
    Result := DAYS_IN_MONTH[m];
end;

function TDate.DaysInYear: Integer;
var
  y, m, d: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  if IsLeapYearI(y) then Result := 366 else Result := 365;
end;

function TDate.IsWeekend: Boolean;
var
  dow: Integer;
begin
  dow := GetDayOfWeek; // 1=Sun .. 7=Sat
  Result := (dow = 1) or (dow = 7);
end;

function TDate.IsFirstDayOfMonth: Boolean;
begin
  Result := GetDay = 1;
end;

function TDate.IsLastDayOfMonth: Boolean;
begin
  Result := GetDay = DaysInMonth;
end;

function TDate.IsFirstDayOfYear: Boolean;
begin
  Result := GetDayOfYear = 1;
end;

function TDate.IsLastDayOfYear: Boolean;
begin
  Result := GetDayOfYear = DaysInYear;
end;

function TDate.StartOfWeek: TDate;
var
  dow: Integer;
begin
  dow := GetDayOfWeek; // 1=Sun..7=Sat
  Result := SubtractDays(dow - 1);
end;

function TDate.EndOfWeek: TDate;
begin
  Result := StartOfWeek.AddDays(6);
end;

function TDate.StartOfMonth: TDate;
var
  y, m, d: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  Result := TDate.Create(y, m, 1);
end;

function TDate.EndOfMonth: TDate;
var
  y, m, d: Integer;
  dim: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  if m = 2 then
  begin
    if IsLeapYearI(y) then dim := 29 else dim := 28;
  end
  else
    dim := DAYS_IN_MONTH[m];
  Result := TDate.Create(y, m, dim);
end;

function TDate.StartOfQuarter: TDate;
var
  y, m, d, qm: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  qm := ((m - 1) div 3) * 3 + 1;
  Result := TDate.Create(y, qm, 1);
end;

function TDate.EndOfQuarter: TDate;
var
  y, m, d, qm, em, dim: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  qm := ((m - 1) div 3) * 3 + 1;
  em := qm + 2;
  if em = 2 then
  begin
    if IsLeapYearI(y) then dim := 29 else dim := 28;
  end
  else
    dim := DAYS_IN_MONTH[em];
  Result := TDate.Create(y, em, dim);
end;

function TDate.StartOfYear: TDate;
var
  y, m, d: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  Result := TDate.Create(y, 1, 1);
end;

function TDate.EndOfYear: TDate;
var
  y, m, d: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  Result := TDate.Create(y, 12, 31);
end;

function TDate.Next(ADayOfWeek: Integer): TDate;
var
  CurrentDow, DaysDiff: Integer;
begin
  // ADayOfWeek: 1=周日, 2=周一, ..., 7=周六
  // GetDayOfWeek 返回: 1=周日, ..., 7=周六
  CurrentDow := GetDayOfWeek;
  DaysDiff := ADayOfWeek - CurrentDow;
  if DaysDiff <= 0 then
    DaysDiff := DaysDiff + 7;  // 跳到下周
  Result := AddDays(DaysDiff);
end;

function TDate.Previous(ADayOfWeek: Integer): TDate;
var
  CurrentDow, DaysDiff: Integer;
begin
  CurrentDow := GetDayOfWeek;
  DaysDiff := CurrentDow - ADayOfWeek;
  if DaysDiff <= 0 then
    DaysDiff := DaysDiff + 7;  // 跳到上周
  Result := AddDays(-DaysDiff);
end;

function TDate.NextOrSame(ADayOfWeek: Integer): TDate;
begin
  if GetDayOfWeek = ADayOfWeek then
    Result := Self
  else
    Result := Next(ADayOfWeek);
end;

function TDate.PreviousOrSame(ADayOfWeek: Integer): TDate;
begin
  if GetDayOfWeek = ADayOfWeek then
    Result := Self
  else
    Result := Previous(ADayOfWeek);
end;

function TDate.DayOfWeekInMonth(AOrdinal: Integer; ADayOfWeek: Integer): TDate;
var
  FirstOfMonth, LastOfMonth: TDate;
  FirstDow, DaysToAdd: Integer;
  TargetDay: Integer;
  y, m, d, dim: Integer;
begin
  JulianDayToDate(FJulianDay, y, m, d);
  
  if AOrdinal > 0 then
  begin
    // 正数：第 N 个
    FirstOfMonth := TDate.Create(y, m, 1);
    FirstDow := FirstOfMonth.GetDayOfWeek;
    
    // 计算从月初到第一个指定星期几的天数
    DaysToAdd := ADayOfWeek - FirstDow;
    if DaysToAdd < 0 then
      DaysToAdd := DaysToAdd + 7;
    
    // 加上 (N-1) 周
    TargetDay := 1 + DaysToAdd + (AOrdinal - 1) * 7;
    Result := TDate.Create(y, m, TargetDay);
  end
  else if AOrdinal = -1 then
  begin
    // -1：最后一个
    // 先获取月末
    if m = 2 then
    begin
      if IsLeapYearI(y) then dim := 29 else dim := 28;
    end
    else
      dim := DAYS_IN_MONTH[m];
    
    LastOfMonth := TDate.Create(y, m, dim);
    // 从月末找上一个指定星期几
    Result := LastOfMonth.PreviousOrSame(ADayOfWeek);
  end
  else
  begin
    // 无效的 ordinal，返回月初
    Result := TDate.Create(y, m, 1);
  end;
end;

function TDate.ToString(const AFormat: string): string;
begin
  Result := SysUtils.FormatDateTime(AFormat, ToDateTime);
end;

function TDate.ToShortString: string;
begin
  Result := SysUtils.FormatDateTime('yyyy-mm-dd', ToDateTime);
end;

function TDate.ToLongString: string;
begin
  Result := SysUtils.FormatDateTime('dddd, mmmm d, yyyy', ToDateTime);
end;

function TDate.GetYear: Integer;
var
  month, day: Integer;
begin
  JulianDayToDate(FJulianDay, Result, month, day);
end;

function TDate.GetMonth: Integer;
var
  year, day: Integer;
begin
  JulianDayToDate(FJulianDay, year, Result, day);
end;

function TDate.GetDay: Integer;
var
  year, month: Integer;
begin
  JulianDayToDate(FJulianDay, year, month, Result);
end;

function TDate.GetDayOfWeek: Integer;
begin
  // Julian Day Number 0 是周一，我们需要转换为周日=1的格式
  Result := ((FJulianDay + 1) mod 7) + 1;
end;

function TDate.AddDays(ADays: Integer): TDate;
begin
  Result.FJulianDay := FJulianDay + ADays;
end;

function TDate.AddWeeks(AWeeks: Integer): TDate;
begin
  Result := AddDays(AWeeks * 7);
end;

function TDate.DaysBetween(const AOther: TDate): Integer;
begin
  Result := Abs(FJulianDay - AOther.FJulianDay);
end;

function TDate.DaysUntil(const AOther: TDate): Integer;
begin
  Result := AOther.FJulianDay - FJulianDay;
end;

function TDate.DaysSince(const AOther: TDate): Integer;
begin
  Result := FJulianDay - AOther.FJulianDay;
end;

function TDate.Compare(const AOther: TDate): Integer;
begin
  if FJulianDay < AOther.FJulianDay then
    Result := -1
  else if FJulianDay > AOther.FJulianDay then
    Result := 1
  else
    Result := 0;
end;

function TDate.Equal(const AOther: TDate): Boolean;
begin
  Result := Self = AOther;  // 弃用方法调用运算符
end;

function TDate.LessThan(const AOther: TDate): Boolean;
begin
  Result := Self < AOther;  // 弃用方法调用运算符
end;

function TDate.GreaterThan(const AOther: TDate): Boolean;
begin
  Result := Self > AOther;  // 弃用方法调用运算符
end;

function TDate.IsLeapYear: Boolean;
var
  year: Integer;
begin
  year := GetYear;
  Result := (year mod 4 = 0) and ((year mod 100 <> 0) or (year mod 400 = 0));
end;

function TDate.ToString: string;
begin
  Result := ToISO8601;
end;

// 运算符重载

class operator TDate.+(const ADate: TDate; ADays: Integer): TDate;
begin
  Result := ADate.AddDays(ADays);
end;

class operator TDate.-(const ADate: TDate; ADays: Integer): TDate;
begin
  Result := ADate.AddDays(-ADays);
end;

class operator TDate.-(const A, B: TDate): Integer;
begin
  Result := A.DaysUntil(B);
end;

class operator TDate.=(const A, B: TDate): Boolean;
begin
  Result := A.FJulianDay = B.FJulianDay;  // 直接比较
end;

class operator TDate.<>(const A, B: TDate): Boolean;
begin
  Result := A.FJulianDay <> B.FJulianDay;  // 直接比较
end;

class operator TDate.<(const A, B: TDate): Boolean;
begin
  Result := A.FJulianDay < B.FJulianDay;  // 直接比较
end;

class operator TDate.>(const A, B: TDate): Boolean;
begin
  Result := A.FJulianDay > B.FJulianDay;  // 直接比较
end;

class operator TDate.<=(const A, B: TDate): Boolean;
begin
  Result := A.FJulianDay <= B.FJulianDay;  // 直接比较
end;

class operator TDate.>=(const A, B: TDate): Boolean;
begin
  Result := A.FJulianDay >= B.FJulianDay;  // 直接比较
end;

function TDate.LessOrEqual(const AOther: TDate): Boolean;
begin
  Result := Self <= AOther;  // 弃用方法调用运算符
end;

function TDate.GreaterOrEqual(const AOther: TDate): Boolean;
begin
  Result := Self >= AOther;  // 弃用方法调用运算符
end;

function TDate.IsBetween(const AStart, AEnd: TDate): Boolean;
begin
  Result := (FJulianDay >= AStart.FJulianDay) and (FJulianDay <= AEnd.FJulianDay);
end;

function TDate.Clamp(const AMin, AMax: TDate): TDate;
begin
  if FJulianDay < AMin.FJulianDay then
    Result := AMin
  else if FJulianDay > AMax.FJulianDay then
    Result := AMax
  else
    Result := Self;
end;

class function TDate.Min(const A, B: TDate): TDate;
begin
  if A.FJulianDay <= B.FJulianDay then
    Result := A
  else
    Result := B;
end;

class function TDate.Max(const A, B: TDate): TDate;
begin
  if A.FJulianDay >= B.FJulianDay then
    Result := A
  else
    Result := B;
end;

function TDate.AddMonths(AMonths: Integer): TDate;
var
  Year, Month, Day: Integer;
  NewYear, NewMonth: Integer;
begin
  JulianDayToDate(FJulianDay, Year, Month, Day);
  
  NewMonth := Month + AMonths;
  NewYear := Year;
  
  // 处理月份溢出
  while NewMonth > 12 do
  begin
    NewMonth := NewMonth - 12;
    Inc(NewYear);
  end;
  
  while NewMonth < 1 do
  begin
    NewMonth := NewMonth + 12;
    Dec(NewYear);
  end;
  
  // 处理天数溢出（例如：1月31日 + 1月 = 2月31日 -> 2月28日）
  if NewMonth = 2 then
  begin
    if IsLeapYearI(NewYear) and (Day > 29) then
      Day := 29
    else if not IsLeapYearI(NewYear) and (Day > 28) then
      Day := 28;
  end
  else if (NewMonth in [4, 6, 9, 11]) and (Day > 30) then
    Day := 30;
    
  Result := TDate.Create(NewYear, NewMonth, Day);
end;

function TDate.AddYears(AYears: Integer): TDate;
var
  Year, Month, Day: Integer;
begin
  JulianDayToDate(FJulianDay, Year, Month, Day);
  
  // 特殊处理闰年的2月29日
  if (Month = 2) and (Day = 29) and not IsLeapYearI(Year + AYears) then
    Day := 28;
    
  Result := TDate.Create(Year + AYears, Month, Day);
end;

function TDate.SubtractDays(ADays: Integer): TDate;
begin
  Result := AddDays(-ADays);
end;

function TDate.SubtractWeeks(AWeeks: Integer): TDate;
begin
  Result := AddWeeks(-AWeeks);
end;

function TDate.SubtractMonths(AMonths: Integer): TDate;
begin
  Result := AddMonths(-AMonths);
end;

function TDate.SubtractYears(AYears: Integer): TDate;
begin
  Result := AddYears(-AYears);
end;

function TDate.WeeksBetween(const AOther: TDate): Integer;
begin
  Result := DaysBetween(AOther) div 7;
end;

function TDate.MonthsBetween(const AOther: TDate): Integer;
var
  Y1, M1, D1, Y2, M2, D2: Integer;
begin
  JulianDayToDate(FJulianDay, Y1, M1, D1);
  JulianDayToDate(AOther.FJulianDay, Y2, M2, D2);
  
  Result := (Y2 - Y1) * 12 + (M2 - M1);
  
  // 如果目标日期的天数小于起始日期，则月数减1
  if D2 < D1 then
    Dec(Result);
end;

function TDate.YearsBetween(const AOther: TDate): Integer;
var
  Y1, M1, D1, Y2, M2, D2: Integer;
begin
  JulianDayToDate(FJulianDay, Y1, M1, D1);
  JulianDayToDate(AOther.FJulianDay, Y2, M2, D2);
  
  Result := Y2 - Y1;
  
  // 如果还没到生日，则年数减1
  if (M2 < M1) or ((M2 = M1) and (D2 < D1)) then
    Dec(Result);
end;

function TDate.GetDayOfYear: Integer;
var
  Year, Month, Day, I: Integer;
begin
  JulianDayToDate(FJulianDay, Year, Month, Day);
  Result := Day;
  
  for I := 1 to Month - 1 do
  begin
    if I = 2 then
    begin
      if IsLeapYearI(Year) then
        Result := Result + 29
      else
        Result := Result + 28;
    end
    else
      Result := Result + DAYS_IN_MONTH[I];
  end;
end;

// With* 修改器方法

function TDate.WithYear(AYear: Integer): TDate;
var
  Year, Month, Day: Integer;
  MaxDay: Integer;
begin
  JulianDayToDate(FJulianDay, Year, Month, Day);
  
  // 处理闰年 2月 29日 的特殊情况
  if (Month = 2) and (Day = 29) and not IsLeapYearI(AYear) then
    Day := 28;
  
  Result := TDate.Create(AYear, Month, Day);
end;

function TDate.WithMonth(AMonth: Integer): TDate;
var
  Year, Month, Day: Integer;
  MaxDay: Integer;
begin
  JulianDayToDate(FJulianDay, Year, Month, Day);
  
  // 确定新月份的最大天数
  if AMonth = 2 then
  begin
    if IsLeapYearI(Year) then
      MaxDay := 29
    else
      MaxDay := 28;
  end
  else if AMonth in [4, 6, 9, 11] then
    MaxDay := 30
  else
    MaxDay := 31;
  
  // 调整天数
  if Day > MaxDay then
    Day := MaxDay;
  
  Result := TDate.Create(Year, AMonth, Day);
end;

function TDate.WithDay(ADay: Integer): TDate;
var
  Year, Month, Day: Integer;
begin
  JulianDayToDate(FJulianDay, Year, Month, Day);
  Result := TDate.Create(Year, Month, ADay); // 如果无效会抛出异常
end;

function TDate.TryWithYear(AYear: Integer; out AResult: TDate): Boolean;
var
  Year, Month, Day: Integer;
  NewDay: Integer;
begin
  // 验证年份范围
  if (AYear < 1) or (AYear > 9999) then
    Exit(False);
  
  JulianDayToDate(FJulianDay, Year, Month, Day);
  NewDay := Day;
  
  // 处理闰年 2月 29日 的特殊情况
  if (Month = 2) and (Day = 29) and not IsLeapYearI(AYear) then
    NewDay := 28;
  
  AResult := TDate.Create(AYear, Month, NewDay);
  Result := True;
end;

function TDate.TryWithMonth(AMonth: Integer; out AResult: TDate): Boolean;
var
  Year, Month, Day: Integer;
  MaxDay, NewDay: Integer;
begin
  // 验证月份范围
  if (AMonth < 1) or (AMonth > 12) then
    Exit(False);
  
  JulianDayToDate(FJulianDay, Year, Month, Day);
  
  // 确定新月份的最大天数
  if AMonth = 2 then
  begin
    if IsLeapYearI(Year) then
      MaxDay := 29
    else
      MaxDay := 28;
  end
  else if AMonth in [4, 6, 9, 11] then
    MaxDay := 30
  else
    MaxDay := 31;
  
  // 调整天数
  NewDay := Day;
  if NewDay > MaxDay then
    NewDay := MaxDay;
  
  AResult := TDate.Create(Year, AMonth, NewDay);
  Result := True;
end;

function TDate.TryWithDay(ADay: Integer; out AResult: TDate): Boolean;
var
  Year, Month, Day: Integer;
begin
  JulianDayToDate(FJulianDay, Year, Month, Day);
  Result := TDate.TryCreate(Year, Month, ADay, AResult);
end;

// 便捷函数

function DateOf(AYear, AMonth, ADay: Integer): TDate;
begin
  Result := TDate.Create(AYear, AMonth, ADay);
end;

function Today: TDate;
begin
  Result := TDate.Today;
end;

function Yesterday: TDate;
begin
  Result := TDate.Yesterday;
end;

function Tomorrow: TDate;
begin
  Result := TDate.Tomorrow;
end;

// 解析与格式化

class function TDate.TryParse(const ADateStr: string; out ADate: TDate): Boolean;
var
  s: string;
  y, m, d: Integer;
  p1, p2: SizeInt;
  n1, n2, n3: string;
begin
  s := Trim(ADateStr);
  ADate := TDate.MinValue;
  Result := False;
  if s = '' then Exit;

  // 统一分隔符为 '-'
  s := StringReplace(s, '/', '-', [rfReplaceAll]);
  s := StringReplace(s, '.', '-', [rfReplaceAll]);

  p1 := Pos('-', s);
  if p1 = 0 then Exit;
  p2 := PosEx('-', s, p1 + 1);
  if p2 = 0 then Exit;

  n1 := Copy(s, 1, p1 - 1);
  n2 := Copy(s, p1 + 1, p2 - p1 - 1);
  n3 := Copy(s, p2 + 1, MaxInt);

  if TryStrToInt(n1, y) and TryStrToInt(n2, m) and TryStrToInt(n3, d) then
  begin
    if TDate.IsValidDate(y, m, d) then
    begin
      ADate := TDate.Create(y, m, d);
      Exit(True);
    end;
  end;

  Result := False;
end;

class function TDate.TryParseISO(const ADateStr: string; out ADate: TDate): Boolean;
var
  s: string;
  y, m, d: Integer;
  n1, n2, n3: string;
begin
  s := Trim(ADateStr);
  ADate := TDate.MinValue;
  Result := False;
  if Length(s) <> 10 then Exit; // YYYY-MM-DD
  if (s[5] <> '-') or (s[8] <> '-') then Exit;

  n1 := Copy(s, 1, 4);
  n2 := Copy(s, 6, 2);
  n3 := Copy(s, 9, 2);

  if TryStrToInt(n1, y) and TryStrToInt(n2, m) and TryStrToInt(n3, d) then
  begin
    if TDate.IsValidDate(y, m, d) then
    begin
      ADate := TDate.Create(y, m, d);
      Exit(True);
    end;
  end;
  Result := False;
end;

function ParseDate(const ADateStr: string): TDate;
begin
  if not TDate.TryParse(ADateStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid date string: %s', [ADateStr]);
end;

function ParseDateISO(const ADateStr: string): TDate;
begin
  if not TDate.TryParseISO(ADateStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid ISO date string: %s', [ADateStr]);
end;

function TryParseDate(const ADateStr: string; out ADate: TDate): Boolean;
begin
  Result := TDate.TryParse(ADateStr, ADate);
end;

function TryParseDateISO(const ADateStr: string; out ADate: TDate): Boolean;
begin
  Result := TDate.TryParseISO(ADateStr, ADate);
end;

function FormatDate(const ADate: TDate; const AFormat: string): string;
begin
  Result := SysUtils.FormatDateTime(AFormat, ADate.ToDateTime);
end;

{ TDateRange }

class function TDateRange.Create(const AStart, AEnd: TDate): TDateRange;
begin
  Result.FStartDate := AStart;
  Result.FEndDate := AEnd;
end;

class function TDateRange.CreateDays(const AStart: TDate; ADays: Integer): TDateRange;
begin
  Result.FStartDate := AStart;
  Result.FEndDate := AStart.AddDays(ADays);
end;

class function TDateRange.CreateWeeks(const AStart: TDate; AWeeks: Integer): TDateRange;
begin
  Result := CreateDays(AStart, AWeeks * 7);
end;

class function TDateRange.CreateMonths(const AStart: TDate; AMonths: Integer): TDateRange;
begin
  Result.FStartDate := AStart;
  Result.FEndDate := AStart.AddMonths(AMonths);
end;

class function TDateRange.CreateYears(const AStart: TDate; AYears: Integer): TDateRange;
begin
  Result.FStartDate := AStart;
  Result.FEndDate := AStart.AddYears(AYears);
end;

function TDateRange.GetStartDate: TDate;
begin
  Result := FStartDate;
end;

function TDateRange.GetEndDate: TDate;
begin
  Result := FEndDate;
end;

function TDateRange.GetDuration: Integer;
begin
  Result := FStartDate.DaysUntil(FEndDate);
end;

function TDateRange.Contains(const ADate: TDate): Boolean;
begin
  Result := (ADate.GreaterOrEqual(FStartDate)) and (ADate.LessOrEqual(FEndDate));
end;

function TDateRange.Overlaps(const AOther: TDateRange): Boolean;
begin
  Result := (FStartDate.LessOrEqual(AOther.FEndDate)) and (FEndDate.GreaterOrEqual(AOther.FStartDate));
end;

function TDateRange.IsEmpty: Boolean;
begin
  Result := FStartDate.GreaterThan(FEndDate);
end;

function TDateRange.IsValid: Boolean;
begin
  Result := FStartDate.LessOrEqual(FEndDate);
end;

function TDateRange.Union(const AOther: TDateRange): TDateRange;
begin
  Result.FStartDate := TDate.Min(FStartDate, AOther.FStartDate);
  Result.FEndDate := TDate.Max(FEndDate, AOther.FEndDate);
end;

function TDateRange.Intersection(const AOther: TDateRange): TDateRange;
begin
  Result.FStartDate := TDate.Max(FStartDate, AOther.FStartDate);
  Result.FEndDate := TDate.Min(FEndDate, AOther.FEndDate);
end;

function TDateRange.Extend(ADays: Integer): TDateRange;
begin
  Result.FStartDate := FStartDate.AddDays(-ADays);
  Result.FEndDate := FEndDate.AddDays(ADays);
end;

function TDateRange.Shift(ADays: Integer): TDateRange;
begin
  Result.FStartDate := FStartDate.AddDays(ADays);
  Result.FEndDate := FEndDate.AddDays(ADays);
end;

function TDateRange.GetEnumerator: TDateRangeEnumerator;
begin
  Result := TDateRangeEnumerator.Create(FStartDate, FEndDate);
end;

function TDateRange.ToString: string;
begin
  Result := Format('%s to %s', [FStartDate.ToString, FEndDate.ToString]);
end;

{ TDateRangeEnumerator }

constructor TDateRangeEnumerator.Create(const AStart, AEnd: TDate);
begin
  FStart := AStart;
  FEnd := AEnd;
  FCurrent := AStart;
  FStarted := False;
end;

function TDateRangeEnumerator.MoveNext: Boolean;
begin
  if not FStarted then
  begin
    FStarted := True;
    FCurrent := FStart;
    Result := not (FStart.GreaterThan(FEnd));
  end
  else
  begin
    FCurrent := FCurrent.AddDays(1);
    Result := FCurrent.LessOrEqual(FEnd);
  end;
end;

function TDateRangeEnumerator.GetCurrent: TDate;
begin
  Result := FCurrent;
end;

end.
